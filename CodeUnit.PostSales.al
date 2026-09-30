codeunit 55001 "Sales Invoice Update"
{
    // ============================================================
    // PAGE: Posted Sales Invoice Update
    // ============================================================
    [EventSubscriber(
        ObjectType::Page,
        Page::"Posted Sales Inv. - Update",
        'OnAfterRecordChanged',
        '',
        false,
        false)]
    local procedure RunOnAfterRecordChanged(
        var IsChanged: Boolean;
        var SalesInvoiceHeader: Record "Sales Invoice Header";
        xSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if IsChanged then
            exit;

        if xSalesInvoiceHeader."Exported To CM" <>
           SalesInvoiceHeader."Exported To CM" then
            IsChanged := true;
    end;

    // ============================================================
    // CODEUNIT: Sales Invoice Header - Edit
    // ============================================================
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Sales Inv. Header - Edit",
        'OnOnRunOnBeforeTestFieldNo',
        '',
        false,
        false)]
    local procedure RunOnBeforeTestFieldNo(
        var SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."Exported To CM" :=
            SalesInvoiceHeaderRec."Exported To CM";
    end;

    // ============================================================
    // POSTING: Invoice Printing Management + Revenue Share Calc
    // ============================================================
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Sales-Post",
        'OnAfterPostSalesDoc',
        '',
        false,
        false)]
    local procedure OnAfterPostSalesDoc(
        SalesHeader: Record "Sales Header";
        var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        SalesShptHdrNo: Code[20];
        SalesInvHdrNo: Code[20];
        SalesCrMemoHdrNo: Code[20];
        CommitIsSuppressed: Boolean)
    var
        InvPrintMgmt: Record "Invoice Printing Management";
        SalesInvHeader: Record "Sales Invoice Header";
        Cust, ParentCust : Record Customer;
        ParentCustomerNo: Code[20];
        SummaryInvoiceFlag: Boolean;
        RevSharePercent: Decimal;
        RevShareBase: Decimal;
        RevShareAmount: Decimal;
        ProfitMultiplierPercent: Decimal;
        ProfitMultiplierBase: Decimal;
        ProfitMultiplierAmount: Decimal;
    begin
        //    message('here');
        if SalesInvHdrNo = '' then
            exit;

        if not Cust.Get(SalesHeader."Sell-to Customer No.") then
            exit;

        // ============================================================
        // Determine Parent / Summary Invoice flags
        // ============================================================
        if Cust."Parent Company" <> '' then begin
            ParentCustomerNo := Cust."Parent Company";
            if ParentCust.Get(ParentCustomerNo) then
                SummaryInvoiceFlag := ParentCust."Summary Invoice"
            else
                SummaryInvoiceFlag := Cust."Summary Invoice";
        end else begin
            ParentCustomerNo := Cust."No.";
            SummaryInvoiceFlag := Cust."Summary Invoice";
        end;

        // ============================================================
        // Insert Invoice Printing Management record
        // ============================================================
        if not SalesInvHeader.Get(SalesInvHdrNo) then
            exit;
        SalesInvHeader.CalcFields("Amount Including VAT");

        InvPrintMgmt.Init();
        InvPrintMgmt."Document No." := SalesInvHdrNo;
        InvPrintMgmt."Document Type" :=
            InvPrintMgmt."Document Type"::Invoice;
        InvPrintMgmt."Customer No." := Cust."No.";
        InvPrintMgmt."Parent Customer No." := ParentCustomerNo;
        InvPrintMgmt."Summary Invoice" := SummaryInvoiceFlag;
        InvPrintMgmt."Invoice Amount" := SalesInvHeader."Amount Including VAT";
        InvPrintMgmt."SQU PO Number" := SalesHeader."SQU PO Number";
        if InvPrintMgmt."SQU PO Number" = '' then
            InvPrintMgmt."SQU PO Number" := SalesInvHeader."SQU PO Number";

        InvPrintMgmt."CM Closed Date" := SalesHeader."CM Closed Date";
        if InvPrintMgmt."CM Closed Date" = 0D then
            InvPrintMgmt."CM Closed Date" := SalesInvHeader."CM Closed Date";


        InvPrintMgmt."Summary Invoice No." := '';
        //  InvPrintMgmt."External Document No." := SalesInvHeader."External Document No.";
        InvPrintMgmt.Insert(true);

        // ============================================================
        // Revenue Share Calculation
        // ============================================================
        if CalcRevenueShareAmounts(SalesInvHdrNo, Cust, RevSharePercent, RevShareBase, RevShareAmount) then begin
            InvPrintMgmt."Revenue Share Percent" := RevSharePercent;
            InvPrintMgmt."Revenue Share Base Amount" := RevShareBase;
            InvPrintMgmt."Revenue Share Amount" := RevShareAmount;
            InvPrintMgmt.Modify(true);
        end;

        // ============================================================
        // Profit Multiplier Calculation
        // ============================================================
        if CalcProfitMultiplierAmounts(SalesInvHdrNo, Cust, ProfitMultiplierPercent, ProfitMultiplierBase, ProfitMultiplierAmount) then begin
            InvPrintMgmt."Profit Multiplier Percent" := ProfitMultiplierPercent;
            InvPrintMgmt."Profit Multiplier Base Amount" := ProfitMultiplierBase;
            InvPrintMgmt."Profit Multiplier Amount" := ProfitMultiplierAmount;
            InvPrintMgmt.Modify(true);
        end;
    end;

    // ============================================================
    // REORDER: Move fee lines (40020 / 20165) to the bottom of the
    // document before posting, so the posted invoice - and any
    // report that sorts by Line No. - naturally prints them last.
    // ============================================================
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Sales-Post",
        'OnBeforePostSalesDoc',
        '',
        false,
        false)]
    local procedure OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        MoveFeeLinesToBottom(SalesHeader);
    end;

    local procedure MoveFeeLinesToBottom(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        TargetLine: Record "Sales Line";
        NewLine: Record "Sales Line";
        TargetLineNos: List of [Integer];
        LineNo: Integer;
        MaxLineNo: Integer;
        NewLineNo: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if not SalesLine.FindLast() then
            exit;
        MaxLineNo := SalesLine."Line No.";

        // Collect the target lines' current Line Nos, in their existing order
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetFilter("No.", '%1|%2', '40020', '20165');
        SalesLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        SalesLine.Ascending(true);
        if SalesLine.FindSet() then
            repeat
                TargetLineNos.Add(SalesLine."Line No.");
            until SalesLine.Next() = 0;

        if TargetLineNos.Count() = 0 then
            exit;

        // Sales Line blocks Rename (too many dependent tables key off
        // "Line No." without a rename cascade), so relocate each line
        // via delete + reinsert instead: copy its field values onto a
        // new record at the higher Line No., insert it raw, then
        // delete the original. Insert(false)/Delete(false) skip the
        // table triggers so we don't re-run validation, re-derive
        // dimensions, etc. on a line that's already valid.
        NewLineNo := MaxLineNo;
        foreach LineNo in TargetLineNos do begin
            NewLineNo += 1000;
            TargetLine.Get(SalesHeader."Document Type", SalesHeader."No.", LineNo);

            NewLine := TargetLine;
            NewLine."Line No." := NewLineNo;
            NewLine.Insert(false);

            TargetLine.Delete(false);
        end;
    end;

    // ============================================================
    // RELEASE SALES DOCUMENT
    // ============================================================
    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Release Sales Document",
        'OnAfterReleaseSalesDoc',
        '',
        false,
        false)]
    local procedure OnAfterReleaseSalesDoc(
        var SalesHeader: Record "Sales Header")
    var
        Cust: Record Customer;
    begin
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;

        if Cust.Get(SalesHeader."Sell-to Customer No.") then begin
            SalesHeader."Summary Invoice" := Cust."Summary Invoice";
            SalesHeader."Summary Invoice by PO" :=
                Cust."Summary Invoice by PO";
            SalesHeader.Modify(true);
        end;
    end;

    // ============================================================
    // SHARED: Revenue Share calculation (used at posting + recalc)
    // ============================================================
    procedure CalcRevenueShareAmounts(
        SalesInvHdrNo: Code[20];
        Cust: Record Customer;
        var RevSharePercent: Decimal;
        var RevShareBase: Decimal;
        var RevShareAmount: Decimal): Boolean
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        RevSharePercent := 0;
        RevShareBase := 0;
        RevShareAmount := 0;

        if Cust."Revenue Share" <= 0 then
            exit(false);

        // ---- G/L 40010 ----
        SalesInvLine.SetRange("Document No.", SalesInvHdrNo);
        SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
        SalesInvLine.SetRange("No.", '40010');

        if SalesInvLine.FindSet() then
            repeat
                if StrPos(UpperCase(SalesInvLine.Description), 'FEE') = 0 then
                    RevShareBase += SalesInvLine."Line Amount";
            until SalesInvLine.Next() = 0;

        // ---- G/L 40020 (Optional) ----
        if Cust."Shipping in Rev Share" then begin
            SalesInvLine.Reset();
            SalesInvLine.SetRange("Document No.", SalesInvHdrNo);
            SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
            SalesInvLine.SetRange("No.", '40020');

            if SalesInvLine.FindSet() then
                repeat
                    if StrPos(UpperCase(SalesInvLine.Description), 'FEE') = 0 then
                        RevShareBase += SalesInvLine."Line Amount";
                until SalesInvLine.Next() = 0;
        end;

        if RevShareBase = 0 then
            exit(false);

        RevSharePercent := Cust."Revenue Share";
        RevShareAmount := Round(RevShareBase * (Cust."Revenue Share" / 100), 0.01);
        exit(true);
    end;

    // ============================================================
    // SHARED: Profit Multiplier calculation (used at posting + recalc)
    // Mirrors CalcRevenueShareAmounts exactly, but keys off the
    // Customer's "Profit Multiplier" % instead of "Revenue Share",
    // and stores into its own set of Invoice Printing Management
    // fields. Uses the same G/L 40010 / 40020 base and the same
    // "Shipping in Rev Share" gate as Revenue Share, since there is
    // no separate shipping flag defined for Profit Multiplier.
    // ============================================================
    procedure CalcProfitMultiplierAmounts(
        SalesInvHdrNo: Code[20];
        Cust: Record Customer;
        var ProfitMultiplierPercent: Decimal;
        var ProfitMultiplierBase: Decimal;
        var ProfitMultiplierAmount: Decimal): Boolean
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        ProfitMultiplierPercent := 0;
        ProfitMultiplierBase := 0;
        ProfitMultiplierAmount := 0;

        if Cust."Profit Multiplier" <= 0 then
            exit(false);

        // ---- G/L 40010 ----
        SalesInvLine.SetRange("Document No.", SalesInvHdrNo);
        SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
        SalesInvLine.SetRange("No.", '40010');

        if SalesInvLine.FindSet() then
            repeat
                if StrPos(UpperCase(SalesInvLine.Description), 'FEE') = 0 then
                    ProfitMultiplierBase += SalesInvLine."Line Amount";
            until SalesInvLine.Next() = 0;

        // ---- G/L 40020 (Optional) ----
        if Cust."Shipping in Rev Share" then begin
            SalesInvLine.Reset();
            SalesInvLine.SetRange("Document No.", SalesInvHdrNo);
            SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
            SalesInvLine.SetRange("No.", '40020');

            if SalesInvLine.FindSet() then
                repeat
                    if StrPos(UpperCase(SalesInvLine.Description), 'FEE') = 0 then
                        ProfitMultiplierBase += SalesInvLine."Line Amount";
                until SalesInvLine.Next() = 0;
        end;

        if ProfitMultiplierBase = 0 then
            exit(false);

        ProfitMultiplierPercent := Cust."Profit Multiplier";
        ProfitMultiplierAmount := Round(ProfitMultiplierBase * (Cust."Profit Multiplier" / 100), 0.01);
        exit(true);
    end;

    // ============================================================
    // SHARED: Recalculate Revenue Share on an existing
    // Invoice Printing Management record (used by report 55002
    // and RefreshAmounts)
    // ============================================================
    procedure RecalcRevenueShare(var InvPrintMgmt: Record "Invoice Printing Management")
    var
        Cust: Record Customer;
        RevSharePercent: Decimal;
        RevShareBase: Decimal;
        RevShareAmount: Decimal;
    begin
        // Only Invoice-type records are supported today; Credit Memo
        // would need a parallel calc against Sales Cr.Memo Line.
        if InvPrintMgmt."Document Type" <> InvPrintMgmt."Document Type"::Invoice then
            exit;

        if not Cust.Get(InvPrintMgmt."Customer No.") then
            exit;

        // Ignore the return value - if Revenue Share no longer applies,
        // CalcRevenueShareAmounts already zeroes out the var parameters,
        // and we want that reflected below.
        CalcRevenueShareAmounts(InvPrintMgmt."Document No.", Cust, RevSharePercent, RevShareBase, RevShareAmount);

        if (InvPrintMgmt."Revenue Share Percent" <> RevSharePercent) or
           (InvPrintMgmt."Revenue Share Base Amount" <> RevShareBase) or
           (InvPrintMgmt."Revenue Share Amount" <> RevShareAmount)
        then begin
            InvPrintMgmt."Revenue Share Percent" := RevSharePercent;
            InvPrintMgmt."Revenue Share Base Amount" := RevShareBase;
            InvPrintMgmt."Revenue Share Amount" := RevShareAmount;
            InvPrintMgmt.Modify(true);
        end;
    end;

    // ============================================================
    // SHARED: Recalculate Profit Multiplier on an existing
    // Invoice Printing Management record (used by RefreshAmounts,
    // mirrors RecalcRevenueShare)
    // ============================================================
    procedure RecalcProfitMultiplier(var InvPrintMgmt: Record "Invoice Printing Management")
    var
        Cust: Record Customer;
        ProfitMultiplierPercent: Decimal;
        ProfitMultiplierBase: Decimal;
        ProfitMultiplierAmount: Decimal;
    begin
        // Only Invoice-type records are supported today; Credit Memo
        // would need a parallel calc against Sales Cr.Memo Line.
        if InvPrintMgmt."Document Type" <> InvPrintMgmt."Document Type"::Invoice then
            exit;

        if not Cust.Get(InvPrintMgmt."Customer No.") then
            exit;

        // Ignore the return value - if Profit Multiplier no longer applies,
        // CalcProfitMultiplierAmounts already zeroes out the var parameters,
        // and we want that reflected below.
        CalcProfitMultiplierAmounts(InvPrintMgmt."Document No.", Cust, ProfitMultiplierPercent, ProfitMultiplierBase, ProfitMultiplierAmount);

        if (InvPrintMgmt."Profit Multiplier Percent" <> ProfitMultiplierPercent) or
           (InvPrintMgmt."Profit Multiplier Base Amount" <> ProfitMultiplierBase) or
           (InvPrintMgmt."Profit Multiplier Amount" <> ProfitMultiplierAmount)
        then begin
            InvPrintMgmt."Profit Multiplier Percent" := ProfitMultiplierPercent;
            InvPrintMgmt."Profit Multiplier Base Amount" := ProfitMultiplierBase;
            InvPrintMgmt."Profit Multiplier Amount" := ProfitMultiplierAmount;
            InvPrintMgmt.Modify(true);
        end;
    end;

    procedure RefreshAmounts()
    var
        InvPrintMgmt: Record "Invoice Printing Management";
        SalesInvHdr: Record "Sales Invoice Header";
        CustLedger: Record "Cust. Ledger Entry";
    begin
        InvPrintMgmt.Reset();
        if not InvPrintMgmt.FindSet(true) then
            exit;

        repeat
            if SalesInvHdr.Get(InvPrintMgmt."Document No.") then begin
                SalesInvHdr.CalcFields("Amount Including VAT");
                InvPrintMgmt."Invoice Amount" := SalesInvHdr."Amount Including VAT"
            end else
                InvPrintMgmt."Invoice Amount" := 0;

            CustLedger.Reset();
            CustLedger.SetRange("Document Type", CustLedger."Document Type"::Invoice);
            CustLedger.SetRange("Document No.", InvPrintMgmt."Document No.");
            InvPrintMgmt."Remaining Amount" := 0;
            if CustLedger.FindSet() then
                repeat
                    CustLedger.CalcFields("Remaining Amount");
                    InvPrintMgmt."Remaining Amount" += CustLedger."Remaining Amount";
                until CustLedger.Next() = 0;

            InvPrintMgmt.Modify(true);

            // Keep Revenue Share fields in sync with current Customer setup
            // and G/L line data whenever amounts are refreshed.
            RecalcRevenueShare(InvPrintMgmt);

            // Keep Profit Multiplier fields in sync with current Customer
            // setup and G/L line data whenever amounts are refreshed.
            RecalcProfitMultiplier(InvPrintMgmt);
        until InvPrintMgmt.Next() = 0;
    end;

}

report 55020 "Refresh Invoice Print Amounts"
{
    Caption = 'Refresh Invoice Print Amounts';
    ProcessingOnly = true;

    trigger OnPreReport()
    var
        SalesInvUpdate: Codeunit "Sales Invoice Update";
    begin
        SalesInvUpdate.RefreshAmounts();
        Message('Invoice amounts refreshed successfully.');
    end;
}