report 55005 "Summary Invoice CSV Export"
{
    Caption = 'Summary Invoice CSV Export';
    ProcessingOnly = true;
    UsageCategory = Administration;
    ApplicationArea = All;

    dataset
    {
        dataitem(InvPrint; "Invoice Printing Management")
        {
            trigger OnPreDataItem()
            var
                CheckRec: Record "Invoice Printing Management";
            begin
                // Only show the Profit Multiplier column at all if at least one
                // record in the current export scope has an amount > 0;
                // otherwise the column is left off entirely (header and rows).
                CheckRec.CopyFilters(InvPrint);
                CheckRec.SetFilter("Profit Multiplier Amount", '>0');
                HasProfitMultiplier := not CheckRec.IsEmpty();
            end;

            trigger OnAfterGetRecord()
            var
                SalesInvHdr: Record "Sales Invoice Header";
                Cust, ParentCust : Record Customer;
                TotalAmtTxt: Text;
                RevShareTxt: Text;
                ProfitMultiplierTxt: Text;
                PaymentsTxt: Text;
                AmtDueTxt: Text;
                PaymentsAmt: Decimal;
                AmtDue: Decimal;
            begin
                if not SalesInvHdr.Get("Document No.") then
                    exit;

                SalesInvHdr.CalcFields(Amount);

                Cust.Get(SalesInvHdr."Sell-to Customer No.");

                if "Parent Customer No." <> '' then
                    ParentCust.Get("Parent Customer No.")
                else
                    ParentCust := Cust;

                TotalAmtTxt :=
                    Format(SalesInvHdr.Amount, 0, '<Precision,2><Standard Format,1>');

                RevShareTxt :=
                    Format("Revenue Share Amount", 0, '<Precision,2><Standard Format,1>');

                if HasProfitMultiplier then
                    ProfitMultiplierTxt :=
                        Format("Profit Multiplier Amount", 0, '<Precision,2><Standard Format,1>');

                // ── Sum applied payments for Amount Due calculation ──
                PaymentsAmt := SumAppliedPayments(SalesInvHdr);
                PaymentsTxt := Format(PaymentsAmt, 0, '<Precision,2><Standard Format,1>');

                AmtDue := SalesInvHdr.Amount - "Revenue Share Amount" - "Profit Multiplier Amount" - PaymentsAmt;
                AmtDueTxt := Format(AmtDue, 0, '<Precision,2><Standard Format,1>');

                // ── Main invoice line ──
                WriteLine(
                    'Invoice',
                    SalesInvHdr."No.",
                    ParentCust.Name,
                    SalesInvHdr."External Document No.",
                    Cust.Contact,
                    Cust."E-Mail",
                    Cust."Phone No.",
                    SalesInvHdr."SQU PO Number",
                    Format(SalesInvHdr."Order Date"),
                    Format(SalesInvHdr."Posting Date"),
                    TotalAmtTxt,
                    RevShareTxt,
                    ProfitMultiplierTxt,
                    PaymentsTxt,
                    AmtDueTxt);

                // ── Applied credit memos ──
                WriteAppliedCreditMemos(SalesInvHdr, ParentCust, Cust);

                // ── Applied payments ──
                WriteAppliedPayments(SalesInvHdr, ParentCust, Cust);
            end;
        }
    }

    trigger OnPreReport()
    begin
        InitCSV();
        WriteHeader();
    end;

    trigger OnPostReport()
    begin
        DownloadCSV();
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        HasProfitMultiplier: Boolean;

    local procedure InitCSV()
    begin
        TempBlob.CreateOutStream(OutS);
    end;

    local procedure WriteHeader()
    begin
        if HasProfitMultiplier then
            OutS.WriteText(
                'Line Type,Document No,Parent Customer Name,Job,' +
                'Contact,Contact Email,Phone,PO Number,Order_Date,Completion_Date,' +
                'TotalPrice,Revenue Share,Profit Multiplier,Payments,Amount Due')
        else
            OutS.WriteText(
                'Line Type,Document No,Parent Customer Name,Job,' +
                'Contact,Contact Email,Phone,PO Number,Order_Date,Completion_Date,' +
                'TotalPrice,Revenue Share,Payments,Amount Due');
        OutS.WriteText();
    end;

    local procedure WriteLine(
        LineType: Text;
        DocumentNo: Text;
        ParentName: Text;
        ExternalDocNo: Text;
        Contact: Text;
        Email: Text;
        Phone: Text;
        PONo: Text;
        DocDate: Text;
        PostDate: Text;
        TotalAmt: Text;
        RevShare: Text;
        ProfitMultiplier: Text;
        Payments: Text;
        AmountDue: Text)
    begin
        if HasProfitMultiplier then
            OutS.WriteText(
                StrSubstNo(
                    '"%1","%2","%3","%4","%5","%6","%7","%8","%9","%10","%11","%12","%13","%14","%15"',
                    LineType, DocumentNo, ParentName, ExternalDocNo,
                    Contact, Email, Phone, PONo, DocDate, PostDate,
                    TotalAmt, RevShare, ProfitMultiplier, Payments, AmountDue))
        else
            OutS.WriteText(
                StrSubstNo(
                    '"%1","%2","%3","%4","%5","%6","%7","%8","%9","%10","%11","%12","%13","%14"',
                    LineType, DocumentNo, ParentName, ExternalDocNo,
                    Contact, Email, Phone, PONo, DocDate, PostDate,
                    TotalAmt, RevShare, Payments, AmountDue));
        OutS.WriteText();
    end;

    /// <summary>
    /// Returns the sum of all payment amounts applied against the given invoice.
    /// Used to pre-calculate Payments before writing the main invoice line.
    /// </summary>
    local procedure SumAppliedPayments(SalesInvHdr: Record "Sales Invoice Header"): Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        AppliedEntry: Record "Cust. Ledger Entry";
        DetailedEntry: Record "Detailed Cust. Ledg. Entry";
        Total: Decimal;
    begin
        Total := 0;

        CustLedgEntry.SetRange("Customer No.", SalesInvHdr."Sell-to Customer No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", SalesInvHdr."No.");
        if not CustLedgEntry.FindFirst() then
            exit(0);

        DetailedEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedEntry.SetRange("Entry Type", DetailedEntry."Entry Type"::Application);
        DetailedEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', CustLedgEntry."Entry No.");

        if not DetailedEntry.FindSet() then
            exit(0);

        repeat
            if AppliedEntry.Get(DetailedEntry."Applied Cust. Ledger Entry No.") then
                if AppliedEntry."Document Type" = AppliedEntry."Document Type"::Payment then begin
                    AppliedEntry.CalcFields(Amount);
                    // Payments are negative on the ledger; negate to get the positive applied amount
                    Total -= AppliedEntry.Amount;
                end;
        until DetailedEntry.Next() = 0;

        exit(Total);
    end;

    local procedure WriteAppliedCreditMemos(
        SalesInvHdr: Record "Sales Invoice Header";
        ParentCust: Record Customer;
        Cust: Record Customer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        AppliedEntry: Record "Cust. Ledger Entry";
        DetailedEntry: Record "Detailed Cust. Ledg. Entry";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        AmtTxt: Text;
    begin
        // Find the invoice ledger entry
        CustLedgEntry.SetRange("Customer No.", SalesInvHdr."Sell-to Customer No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", SalesInvHdr."No.");
        if not CustLedgEntry.FindFirst() then
            exit;

        // Find detailed entries that represent applications TO this invoice
        DetailedEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedEntry.SetRange(
            "Entry Type",
            DetailedEntry."Entry Type"::Application);
        DetailedEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', CustLedgEntry."Entry No.");

        if not DetailedEntry.FindSet() then
            exit;

        repeat
            if AppliedEntry.Get(DetailedEntry."Applied Cust. Ledger Entry No.") then
                if AppliedEntry."Document Type" = AppliedEntry."Document Type"::"Credit Memo" then begin
                    AppliedEntry.CalcFields(Amount);
                    AmtTxt := Format(AppliedEntry.Amount, 0, '<Precision,2><Standard Format,1>');

                    // Try to get External Doc No from the posted credit memo header
                    if SalesCrMemoHdr.Get(AppliedEntry."Document No.") then;

                    WriteLine(
                        'Credit Memo',
                        AppliedEntry."Document No.",
                        ParentCust.Name,
                        SalesCrMemoHdr."External Document No.",
                        Cust.Contact,
                        Cust."E-Mail",
                        Cust."Phone No.",
                        '',
                        Format(AppliedEntry."Posting Date"),
                        Format(AppliedEntry."Posting Date"),
                        AmtTxt,
                        '',
                        '',
                        '',
                        '');
                end;
        until DetailedEntry.Next() = 0;
    end;

    local procedure WriteAppliedPayments(
        SalesInvHdr: Record "Sales Invoice Header";
        ParentCust: Record Customer;
        Cust: Record Customer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        AppliedEntry: Record "Cust. Ledger Entry";
        DetailedEntry: Record "Detailed Cust. Ledg. Entry";
        AmtTxt: Text;
    begin
        // Find the invoice ledger entry
        CustLedgEntry.SetRange("Customer No.", SalesInvHdr."Sell-to Customer No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", SalesInvHdr."No.");
        if not CustLedgEntry.FindFirst() then
            exit;

        // Find detailed entries that represent applications TO this invoice
        DetailedEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedEntry.SetRange(
            "Entry Type",
            DetailedEntry."Entry Type"::Application);
        DetailedEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', CustLedgEntry."Entry No.");

        if not DetailedEntry.FindSet() then
            exit;

        repeat
            if AppliedEntry.Get(DetailedEntry."Applied Cust. Ledger Entry No.") then
                if AppliedEntry."Document Type" = AppliedEntry."Document Type"::Payment then begin
                    AppliedEntry.CalcFields(Amount);
                    AmtTxt := Format(AppliedEntry.Amount, 0, '<Precision,2><Standard Format,1>');

                    WriteLine(
                        'Payment',
                        AppliedEntry."Document No.",
                        ParentCust.Name,
                        AppliedEntry."External Document No.",
                        Cust.Contact,
                        Cust."E-Mail",
                        Cust."Phone No.",
                        '',
                        Format(AppliedEntry."Posting Date"),
                        Format(AppliedEntry."Posting Date"),
                        AmtTxt,
                        '',
                        '',
                        '',
                        '');
                end;
        until DetailedEntry.Next() = 0;
    end;

    local procedure DownloadCSV()
    var
        FileName: Text;
    begin
        FileName := 'SummaryInvoice.csv';
        TempBlob.CreateInStream(InS);
        DownloadFromStream(InS, 'Summary Invoice Export', '', '', FileName);
    end;
}