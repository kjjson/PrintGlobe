// ============================================================================
// PJ Cash Receipt Import
// ----------------------------------------------------------------------------
// Imports a PayJunction "Cash Receipts" export (the CashReceipts_PayJunction.csv
// format) into a Cash Receipt Journal batch.
//
// For each "Charge" row with a non-zero Amount:
//   1. Parses the leading numeric token off the "Invoice" column
//      (e.g. "653161 8/6/2026 3:53:53PM" -> "653161").
//   2. Looks that number up against Sales Invoice Header."External Document No."
//      on POSTED sales invoices to identify the customer. If there's no
//      posted match, falls back to open Sales Orders (Sales Header,
//      Document Type = Order) with the same "External Document No." match.
//   3. Creates a Gen. Journal Line (Document Type = Payment, Account Type =
//      Customer) with:
//        - Account No.               = Bill-to Customer No. of the matched invoice/order
//        - External Document No.     = the parsed number
//        - Shortcut Dimension 2 Code = the parsed number
//        - Amount                    = -CSV Amount (credit to the customer)
//        - Applies-to Doc. No.       = the matched invoice's "No." - only when
//                                       matched against a POSTED invoice (an
//                                       open Sales Order has no Cust. Ledger
//                                       Entry yet to apply against), and only
//                                       when ApplyToInvoice is true
//
// Rows matched only against an open Sales Order are still imported (customer
// set, no auto-apply) but are flagged in the log for review, since you'll
// likely want to apply the payment manually once that order is invoiced and
// posted. Rows with no match at all, an ambiguous (multiple) match, or an
// unparsable invoice number are skipped entirely and written to the same
// downloadable log rather than silently posted against the wrong customer.
//
// NOTES / THINGS TO VERIFY BEFORE USE
// ----------------------------------------------------------------------------
// * Object ID 55010 - adjust if it collides with anything else in your range.
// * Customer match uses Bill-to Customer No. off the posted Sales Invoice
//   Header. Swap to Sell-to Customer No. if that's the field you actually
//   want to post the payment against.
// * Line No. is assigned manually (LastGenJournalLine."Line No." + 10000) -
//   in this BC version, SetUpNewLine() does not assign it itself.
// * GenJournalLine.SetUpNewLine() is still called for its other defaults
//   (dates, currency, etc.), as SetUpNewLine(LastGenJournalLine, Balance,
//   SuppressCommit) - Balance passed as 0 (only feeds the suggested
//   running-balance display), SuppressCommit as false. Confirm the resulting
//   Document No. behaves as expected against your batch's No. Series setup -
//   some BC versions/configs want the No. Series pulled and assigned
//   explicitly instead (NoSeriesManagement.TryGetNextNo / "No. Series"."Get Next No.").
// * SplitCsvLine() is a simple RFC4180-style splitter (handles quoted fields
//   containing commas). PayJunction's own export does NOT quote its Amount
//   fields, so an amount of $1,234.56 or higher would itself contain an
//   unquoted comma and misalign columns. Worth a spot check against a fuller
//   export before trusting this on volume - the sample file had no 4-figure
//   amounts to confirm one way or the other.
// * Only rows where Action = 'Charge' are considered; 'Verify' rows (card
//   tokenization, $0.00) are ignored automatically.
// ============================================================================

codeunit 55010 "PJ Cash Receipt Import"
{
    Permissions = tabledata "Gen. Journal Line" = rim,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Sales Header" = r;

    procedure ImportFile(GenJournalBatch: Record "Gen. Journal Batch"; ApplyToInvoice: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        LastGenJournalLine: Record "Gen. Journal Line";
        FileInStream: InStream;
        FileName: Text;
        Line: Text;
        Fields: List of [Text];
        LineNo: Integer;
        ActionText: Text;
        Amount: Decimal;
        ExternalDocNo: Code[20];
        CustomerNo: Code[20];
        InvoiceDocNo: Code[20];
        MatchCount: Integer;
        UnpostedCount: Integer;
        CustomerFound: Boolean;
        MatchedUnposted: Boolean;
        PostingDate: Date;
        CreatedCount: Integer;
        UnpostedMatchNoticeCount: Integer;
        NoMatchCount: Integer;
        AmbiguousCount: Integer;
        ZeroAmountCount: Integer;
        SkipLog: TextBuilder;
    begin
        if not GuiAllowed() then
            exit;

        if not UploadIntoStream('Select PayJunction Cash Receipts CSV', '', 'CSV Files (*.csv)|*.csv', FileName, FileInStream) then
            exit;

        LastGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        LastGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if LastGenJournalLine.FindLast() then;

        while not FileInStream.EOS do begin
            FileInStream.ReadText(Line);
            LineNo += 1;

            // if-guard instead of "continue" (not available in AL) to skip the header row
            if (LineNo > 1) and (Line <> '') then begin
                Fields := SplitCsvLine(Line);

                if Fields.Count() >= 16 then begin
                    ActionText := Fields.Get(6);

                    if ActionText = 'Charge' then begin
                        Amount := ParseAmount(Fields.Get(16));

                        if Amount <> 0 then begin
                            ExternalDocNo := ParseExternalDocNo(Fields.Get(13));

                            if ExternalDocNo <> '' then begin
                                CustomerFound := false;
                                MatchedUnposted := false;

                                SalesInvoiceHeader.Reset();
                                SalesInvoiceHeader.SetRange("External Document No.", ExternalDocNo);
                                MatchCount := SalesInvoiceHeader.Count();

                                if MatchCount = 1 then begin
                                    SalesInvoiceHeader.FindFirst();
                                    CustomerNo := SalesInvoiceHeader."Bill-to Customer No.";
                                    InvoiceDocNo := SalesInvoiceHeader."No.";
                                    CustomerFound := true;
                                end else
                                    if MatchCount = 0 then begin
                                        // Fall back to open Sales Orders (Sales Header) when no posted
                                        // invoice match exists.
                                        SalesHeader.Reset();
                                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                                        SalesHeader.SetRange("External Document No.", ExternalDocNo);
                                        UnpostedCount := SalesHeader.Count();

                                        if UnpostedCount = 1 then begin
                                            SalesHeader.FindFirst();
                                            CustomerNo := SalesHeader."Bill-to Customer No.";
                                            InvoiceDocNo := SalesHeader."No.";
                                            CustomerFound := true;
                                            MatchedUnposted := true;
                                        end else
                                            if UnpostedCount = 0 then begin
                                                NoMatchCount += 1;
                                                SkipLog.AppendLine(StrSubstNo('Line %1: no posted sales invoice or open sales order found with External Document No. = "%2"', LineNo, ExternalDocNo));
                                            end else begin
                                                AmbiguousCount += 1;
                                                SkipLog.AppendLine(StrSubstNo('Line %1: %2 open sales orders found with External Document No. = "%3" (ambiguous, skipped)', LineNo, UnpostedCount, ExternalDocNo));
                                            end;
                                    end else begin
                                        AmbiguousCount += 1;
                                        SkipLog.AppendLine(StrSubstNo('Line %1: %2 posted sales invoices found with External Document No. = "%3" (ambiguous, skipped)', LineNo, MatchCount, ExternalDocNo));
                                    end;

                                if CustomerFound then begin
                                    PostingDate := ParseTransactionDate(Fields.Get(10));

                                    GenJournalLine.Init();
                                    GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
                                    GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
                                    // SetUpNewLine() (this BC version) doesn't assign Line No. itself -
                                    // increment off the last line the same way the journal page does.
                                    GenJournalLine."Line No." := LastGenJournalLine."Line No." + 10000;
                                    GenJournalLine.SetUpNewLine(LastGenJournalLine, 0, false);

                                    GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
                                    GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
                                    GenJournalLine.Validate("Account No.", CustomerNo);
                                    if PostingDate <> 0D then
                                        GenJournalLine.Validate("Posting Date", PostingDate);
                                    GenJournalLine.Validate(Amount, -Amount);
                                    GenJournalLine."External Document No." := ExternalDocNo;
                                    GenJournalLine.Validate("Shortcut Dimension 2 Code", ExternalDocNo);

                                    // Applies-to Doc. No. only makes sense against a POSTED invoice -
                                    // an open Sales Order hasn't created a Cust. Ledger Entry yet,
                                    // so there's nothing to apply the payment to.
                                    if ApplyToInvoice and not MatchedUnposted then begin
                                        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
                                        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceDocNo);
                                    end;

                                    GenJournalLine.Insert(true);
                                    LastGenJournalLine := GenJournalLine;
                                    CreatedCount += 1;

                                    if MatchedUnposted then begin
                                        UnpostedMatchNoticeCount += 1;
                                        SkipLog.AppendLine(StrSubstNo('Line %1: matched to open SALES ORDER %2 (External Document No. = "%3") - customer set, but NOT auto-applied (no posted invoice/ledger entry exists yet)', LineNo, InvoiceDocNo, ExternalDocNo));
                                    end;
                                end;
                            end else begin
                                NoMatchCount += 1;
                                SkipLog.AppendLine(StrSubstNo('Line %1: could not parse an invoice number out of the Invoice field', LineNo));
                            end;
                        end else
                            ZeroAmountCount += 1;
                    end;
                end;
            end;
        end;

        Message('Import complete.\Lines created: %1 (of which %2 matched an open SALES ORDER - not auto-applied)\No customer match: %3\Ambiguous matches: %4\Zero-amount/non-charge rows skipped: %5',
            CreatedCount, UnpostedMatchNoticeCount, NoMatchCount, AmbiguousCount, ZeroAmountCount);

        if (NoMatchCount + AmbiguousCount + UnpostedMatchNoticeCount > 0) and GuiAllowed() then
            if Confirm('%1 row(s) were skipped, ambiguous, or matched to an open sales order and need review. Download the log?', true, NoMatchCount + AmbiguousCount + UnpostedMatchNoticeCount) then
                DownloadSkipLog(SkipLog);
    end;

    /// <summary>
    /// Splits one CSV line into fields, honoring double-quoted fields that may
    /// contain commas (RFC4180-style). Does NOT handle escaped ("") quotes
    /// inside a quoted field - none appear in the PayJunction export.
    /// </summary>
    local procedure SplitCsvLine(CsvLine: Text): List of [Text]
    var
        Result: List of [Text];
        CurrentField: TextBuilder;
        CurrentChar: Text[1];
        InQuotes: Boolean;
        i: Integer;
    begin
        InQuotes := false;
        for i := 1 to StrLen(CsvLine) do begin
            CurrentChar := CopyStr(CsvLine, i, 1);

            if CurrentChar = '"' then
                InQuotes := not InQuotes
            else
                if (CurrentChar = ',') and not InQuotes then begin
                    Result.Add(CurrentField.ToText());
                    Clear(CurrentField);
                end else
                    CurrentField.Append(CurrentChar);
        end;
        Result.Add(CurrentField.ToText());
        exit(Result);
    end;

    /// <summary>
    /// Pulls the leading numeric token off the Invoice column, e.g.
    /// "653161 8/6/2026 3:53:53PM" -> "653161". Returns '' if the field is
    /// blank or doesn't start with a digit.
    /// </summary>
    local procedure ParseExternalDocNo(InvoiceText: Text): Code[20]
    var
        Trimmed: Text;
        SpacePos: Integer;
        NoText: Text;
    begin
        Trimmed := DelChr(InvoiceText, '<>', ' ');
        if Trimmed = '' then
            exit('');

        if not (CopyStr(Trimmed, 1, 1) in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) then
            exit('');

        SpacePos := StrPos(Trimmed, ' ');
        if SpacePos = 0 then
            NoText := Trimmed
        else
            NoText := CopyStr(Trimmed, 1, SpacePos - 1);

        // Code[20] to match Shortcut Dimension Code's field length (the tighter
        // of the two target fields - External Document No. allows more).
        exit(CopyStr(NoText, 1, 20));
    end;

    /// <summary>
    /// Parses the leading date portion of "08/06/2026 03:53 PM CDT" (MM/DD/YYYY)
    /// into a Date. Returns 0D if it can't be parsed, in which case the caller
    /// falls back to the journal line's default Posting Date.
    /// </summary>
    local procedure ParseTransactionDate(DateText: Text): Date
    var
        DatePart: Text;
        SpacePos: Integer;
        Slash1: Integer;
        Slash2: Integer;
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        SpacePos := StrPos(DateText, ' ');
        if SpacePos = 0 then
            DatePart := DateText
        else
            DatePart := CopyStr(DateText, 1, SpacePos - 1);

        Slash1 := StrPos(DatePart, '/');
        if Slash1 = 0 then
            exit(0D);
        Slash2 := StrPos(CopyStr(DatePart, Slash1 + 1), '/');
        if Slash2 = 0 then
            exit(0D);
        Slash2 += Slash1;

        if not Evaluate(Month, CopyStr(DatePart, 1, Slash1 - 1)) then
            exit(0D);
        if not Evaluate(Day, CopyStr(DatePart, Slash1 + 1, Slash2 - Slash1 - 1)) then
            exit(0D);
        if not Evaluate(Year, CopyStr(DatePart, Slash2 + 1)) then
            exit(0D);

        if (Month < 1) or (Month > 12) or (Day < 1) or (Day > 31) then
            exit(0D);

        exit(DMY2Date(Day, Month, Year));
    end;

    /// <summary>
    /// Parses "$653.57 " (or "$1,234.56 ") into a Decimal.
    /// </summary>
    local procedure ParseAmount(AmountText: Text): Decimal
    var
        CleanText: Text;
        Result: Decimal;
    begin
        CleanText := DelChr(AmountText, '=', '$ ,');
        if CleanText = '' then
            exit(0);
        if not Evaluate(Result, CleanText, 9) then
            exit(0);
        exit(Result);
    end;

    local procedure DownloadSkipLog(SkipLog: TextBuilder)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        ToFileName: Text;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(SkipLog.ToText());
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        ToFileName := 'PJ_CashReceipt_Import_SkipLog.txt';
        DownloadFromStream(InStr, 'Skipped Rows', '', 'Text Files (*.txt)|*.txt', ToFileName);
    end;
}