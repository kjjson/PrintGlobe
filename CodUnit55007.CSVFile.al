codeunit 55007 "Summary Invoice CSV Builder"
{
    procedure BuildCSV(SummaryInvoiceNo: Code[20]; var OutS: OutStream; IncludeRevShare: Boolean)
    var
        InvPrint: Record "Invoice Printing Management";
        SalesInvHdr: Record "Sales Invoice Header";
        Cust, ParentCust : Record Customer;
        TotalAmtTxt: Text;
        RevShareTxt: Text;
        ProfitMultiplierTxt: Text;
        PaymentsTxt: Text;
        AmtDueTxt: Text;
        JobNameTxt: Text;
        PaymentsAmt: Decimal;
        AmtDue: Decimal;
        EmailTxt: Text;
        HasProfitMultiplier: Boolean;
        HeaderTxt: Text;
        RowFields: List of [Text];
    begin
        // Only show the Profit Multiplier column at all if at least one invoice
        // in this summary invoice batch actually has an amount > 0; otherwise
        // the column is left off entirely (header and rows).
        HasProfitMultiplier := AnyProfitMultiplier(SummaryInvoiceNo);

        // Header row. Revenue Share and Profit Multiplier are each included
        // only when relevant (IncludeRevShare / HasProfitMultiplier), so the
        // two CSVs this codeunit produces - one with Revenue Share, one
        // without (see callers of BuildCSV) - can have different column
        // layouts without duplicating this whole procedure.
        HeaderTxt := 'Customer Name,Job,Job Name,Contact,Contact Email,Phone,PO Number,Order_Date,Completion_Date,TotalPrice';
        if IncludeRevShare then
            HeaderTxt += ',Revenue Share';
        if HasProfitMultiplier then
            HeaderTxt += ',Profit Multiplier';
        HeaderTxt += ',Payments,Amount Due';
        OutS.WriteText(HeaderTxt);
        OutS.WriteText();

        InvPrint.Reset();
        InvPrint.SetRange("Summary Invoice No.", SummaryInvoiceNo);
        InvPrint.SetRange("Document Type", InvPrint."Document Type"::Invoice);

        if not InvPrint.FindSet() then
            exit;

        repeat
            if SalesInvHdr.Get(InvPrint."Document No.") then begin
                SalesInvHdr.CalcFields(Amount);
                Cust.Get(SalesInvHdr."Sell-to Customer No.");

                if InvPrint."Parent Customer No." <> '' then
                    ParentCust.Get(InvPrint."Parent Customer No.")
                else
                    ParentCust := Cust;

                // ── Resolve email from parent customer card ───────────────────
                EmailTxt := ParentCust."E-Mail";
                // ─────────────────────────────────────────────────────────────

                TotalAmtTxt := Format(SalesInvHdr.Amount, 0, '<Precision,2><Standard Format,1>');

                PaymentsAmt := SumAppliedPayments(SalesInvHdr);
                PaymentsTxt := Format(PaymentsAmt, 0, '<Precision,2><Standard Format,1>');

                // Amount Due nets out Profit Multiplier the same as before
                // regardless of column visibility. Revenue Share is only
                // netted out when this file is including that column at all -
                // the no-Revenue-Share CSV shows Amount Due without that
                // deduction, matching the fact that it doesn't disclose the
                // Revenue Share Amount anywhere else in the row either.
                AmtDue := SalesInvHdr.Amount - InvPrint."Profit Multiplier Amount" - PaymentsAmt;
                if IncludeRevShare then
                    AmtDue -= InvPrint."Revenue Share Amount";
                AmtDueTxt := Format(AmtDue, 0, '<Precision,2><Standard Format,1>');

                JobNameTxt := GetJobName(SalesInvHdr."External Document No.");

                Clear(RowFields);
                RowFields.Add(Cust.Name);
                RowFields.Add(SalesInvHdr."External Document No.");
                RowFields.Add(JobNameTxt);
                RowFields.Add(Cust.Contact);
                RowFields.Add(EmailTxt);
                RowFields.Add(Cust."Phone No.");
                RowFields.Add(SalesInvHdr."SQU PO Number");
                RowFields.Add(Format(SalesInvHdr."Order Date"));
                RowFields.Add(Format(SalesInvHdr."Posting Date"));
                RowFields.Add(TotalAmtTxt);

                if IncludeRevShare then begin
                    RevShareTxt := Format(InvPrint."Revenue Share Amount", 0, '<Precision,2><Standard Format,1>');
                    RowFields.Add(RevShareTxt);
                end;

                if HasProfitMultiplier then begin
                    ProfitMultiplierTxt := Format(InvPrint."Profit Multiplier Amount", 0, '<Precision,2><Standard Format,1>');
                    RowFields.Add(ProfitMultiplierTxt);
                end;

                RowFields.Add(PaymentsTxt);
                RowFields.Add(AmtDueTxt);

                OutS.WriteText(BuildCsvRow(RowFields));
                OutS.WriteText();
            end;
        until InvPrint.Next() = 0;
    end;

    /// <summary>
    /// Joins a variable number of fields into one quoted, comma-separated CSV
    /// row, doubling any embedded quote characters per the CSV escaping
    /// convention. Replaces the old fixed-arity StrSubstNo row templates,
    /// which can't cleanly express the four possible column combinations
    /// (Revenue Share on/off × Profit Multiplier on/off) BuildCSV can now
    /// produce.
    /// </summary>
    local procedure BuildCsvRow(Fields: List of [Text]): Text
    var
        RowBuilder: TextBuilder;
        FieldValue: Text;
        IsFirst: Boolean;
    begin
        IsFirst := true;
        foreach FieldValue in Fields do begin
            if not IsFirst then
                RowBuilder.Append(',');
            RowBuilder.Append('"' + FieldValue.Replace('"', '""') + '"');
            IsFirst := false;
        end;
        exit(RowBuilder.ToText());
    end;

    local procedure AnyProfitMultiplier(SummaryInvoiceNo: Code[20]): Boolean
    var
        InvPrint: Record "Invoice Printing Management";
    begin
        InvPrint.Reset();
        InvPrint.SetRange("Summary Invoice No.", SummaryInvoiceNo);
        InvPrint.SetRange("Document Type", InvPrint."Document Type"::Invoice);
        InvPrint.SetFilter("Profit Multiplier Amount", '>0');
        exit(not InvPrint.IsEmpty());
    end;

    local procedure GetJobName(ExternalDocNo: Text): Text
    var
        DimValue: Record "Dimension Value";
    begin
        if ExternalDocNo = '' then
            exit('');

        DimValue.SetRange("Dimension Code", 'JOB');
        DimValue.SetRange(Code, CopyStr(ExternalDocNo, 1, MaxStrLen(DimValue.Code)));
        if DimValue.FindFirst() then
            exit(DimValue.Name);

        exit('');
    end;

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
}