page 55019 "Invoice Printing Mgmt List"
{
    PageType = List;
    SourceTable = "Invoice Printing Management";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Invoice Printing Management';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        SalesInvHdr: Record "Sales Invoice Header";
                    begin
                        if not SalesInvHdr.Get(Rec."Document No.") then
                            Error('Posted Sales Invoice %1 not found.', Rec."Document No.");
                        Page.Run(Page::"Posted Sales Invoice", SalesInvHdr);
                    end;
                }
                field("Document Type"; Rec."Document Type") { ApplicationArea = All; }
                field("Job No."; Rec."External Document No.") { ApplicationArea = All; }
                field("Invoice Amount"; Rec."Invoice Amount") { ApplicationArea = All; }
                field("Remaining Amount"; RemainingAmountDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Remaining Amount';
                }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Customer Name"; Rec."Customer Name") { ApplicationArea = All; }
                field("Parent Customer No."; Rec."Parent Customer No.") { ApplicationArea = All; }
                field("Parent Customer Name"; Rec."Parent Customer Name") { ApplicationArea = All; }
                field("PO Number"; Rec."SQU PO Number")
                {
                    ApplicationArea = All;
                    Caption = 'PO Number';
                }
                field("CM Closed Date"; Rec."CM Closed Date") { ApplicationArea = All; }
                field("Summary Invoice"; Rec."Summary Invoice") { ApplicationArea = All; }
                field("Summary Invoice No."; Rec."Summary Invoice No.") { ApplicationArea = All; }
                field("Revenue Share Amount"; Rec."Revenue Share Amount") { ApplicationArea = All; }
                field("Profit Multiplier Amount"; Rec."Profit Multiplier Amount") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Emailed"; Rec."Emailed")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Emailed Date"; Rec."Emailed Date") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AssignGroupedSummaryInvoiceNos)
            {
                Caption = 'Assign Summary Invoice Nos by Parent Customer';
                Image = NumberSeries;
                ApplicationArea = All;

                trigger OnAction()
                var
                    SummaryMgmt: Record "Invoice Printing Management";
                    GroupedMgmt: Record "Invoice Printing Management";
                    NoSeriesMgt: Codeunit "No. Series";
                    AssignedNo: Code[20];
                    GroupKey: Text;
                    ProcessedGroups: Dictionary of [Text, Code[20]];
                begin
                    SummaryMgmt.Reset();
                    SummaryMgmt.SetRange("Summary Invoice", true);
                    SummaryMgmt.SetRange("Summary Invoice No.", '');

                    if not SummaryMgmt.FindSet() then begin
                        Message('No records found to assign.');
                        exit;
                    end;

                    repeat
                        GroupKey := GetGroupKey(SummaryMgmt);

                        if not ProcessedGroups.ContainsKey(GroupKey) then begin
                            AssignedNo := NoSeriesMgt.GetNextNo('SUMINV', Today, true);
                            ProcessedGroups.Add(GroupKey, AssignedNo);

                            GroupedMgmt.Reset();
                            GroupedMgmt.SetRange("Summary Invoice", true);
                            GroupedMgmt.SetRange("Summary Invoice No.", '');

                            if SummaryMgmt."Parent Customer No." <> '' then
                                GroupedMgmt.SetRange("Parent Customer No.", SummaryMgmt."Parent Customer No.")
                            else
                                GroupedMgmt.SetRange("Customer No.", SummaryMgmt."Customer No.");

                            if GroupedMgmt.FindSet() then
                                repeat
                                    if GetGroupKey(GroupedMgmt) = GroupKey then begin
                                        GroupedMgmt."Summary Invoice No." := AssignedNo;
                                        GroupedMgmt.Modify(true);
                                    end;
                                until GroupedMgmt.Next() = 0;
                        end;
                    until SummaryMgmt.Next() = 0;

                    Message('Summary Invoice Numbers assigned successfully.');
                end;
            }

            action(RefreshAmounts)
            {
                Caption = 'Refresh Invoice Amounts';
                Image = Refresh;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SalesInvUpdate: Codeunit "Sales Invoice Update";
                begin
                    SalesInvUpdate.RefreshAmounts();
                    CurrPage.Update(false);
                end;
            }
            action(UpdateInvoicePrintingManagement)
            {
                Caption = 'Update Invoices';
                Image = Refresh;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Report.RunModal(Report::"Update Invoice Print Mgmt");
                end;
            }

            action(ArchiveRecords)
            {
                Caption = 'Archive Records';
                Image = Archive;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Report.RunModal(Report::"Archive Printed Inv Print Mgmt");
                end;
            }

            action(EmailAllSummaryInvoices)
            {
                Caption = 'Email All Summary Invoices';
                Image = SendMail;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    AllRec: Record "Invoice Printing Management";
                begin
                    AllRec.CopyFilters(Rec);
                    AllRec.SetRange("Summary Invoice", true);
                    AllRec.SetFilter("Summary Invoice No.", '<>%1', '');

                    ProcessSummaryInvoiceEmails(
                        AllRec,
                        'This will email ALL summary invoices in the current filtered view. Continue?',
                        'No summary invoice records found in the current view.',
                        'Finished processing all summary invoices in the current view.');
                end;
            }

            action(EmailOneSummaryInvoice)
            {
                Caption = 'Email This Summary Invoice';
                Image = Email;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    OneRec: Record "Invoice Printing Management";
                begin
                    if (not Rec."Summary Invoice") or (Rec."Summary Invoice No." = '') then
                        Error('The current record is not part of a summary invoice.');

                    OneRec.SetRange("Summary Invoice", true);
                    OneRec.SetRange("Summary Invoice No.", Rec."Summary Invoice No.");

                    ProcessSummaryInvoiceEmails(
                        OneRec,
                        StrSubstNo('This will email Summary Invoice %1. Continue?', Rec."Summary Invoice No."),
                        StrSubstNo('No records found for Summary Invoice %1.', Rec."Summary Invoice No."),
                        StrSubstNo('Finished processing Summary Invoice %1.', Rec."Summary Invoice No."));
                end;
            }

            action(EmailSingleInvoices)
            {
                Caption = 'Email Single Invoices';
                Image = Email;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    SelRec: Record "Invoice Printing Management";
                    SalesInvHdr: Record "Sales Invoice Header";
                    Cust: Record Customer;
                    TempBlob: Codeunit "Temp Blob";
                    OutS: OutStream;
                    InS: InStream;
                    EmailMsg: Codeunit "Email Message";
                    Email: Codeunit Email;
                    FileName: Text;
                    EmailAction: Enum "Email Action";
                    RecRef: RecordRef;
                begin
                    CurrPage.SetSelectionFilter(SelRec);
                    if SelRec.IsEmpty() then
                        Error('Please select at least one invoice to email.');

                    if SelRec.FindSet() then
                        repeat
                            if (not SelRec."Summary Invoice") or (SelRec."Summary Invoice No." = '') then
                                if SalesInvHdr.Get(SelRec."Document No.") then
                                    if Cust.Get(SelRec."Customer No.") then
                                        if Cust."E-Mail" <> '' then begin

                                            Clear(TempBlob);
                                            TempBlob.CreateOutStream(OutS);
                                            SalesInvHdr.SetRecFilter();

                                            RecRef.GetTable(SalesInvHdr);
                                            Report.SaveAs(
                                                Report::"Standard Sales - Invoice",
                                                '',
                                                ReportFormat::Pdf,
                                                OutS,
                                                RecRef);

                                            TempBlob.CreateInStream(InS);
                                            FileName := StrSubstNo('%1 - %2.pdf', SelRec."Document No.", SanitizeFileNamePart(Cust.Name));
                                            DownloadFromStream(InS, 'Summary Invoice Export', '', 'PDF Files (*.pdf)|*.pdf', FileName);
                                            TempBlob.CreateInStream(InS);

                                            EmailMsg.Create(
                                                Cust."E-Mail",
                                                StrSubstNo('PrintGlobe Invoice %1', SelRec."Document No."),
                                                GetEmailBodyHtml(),
                                                true);
                                            EmailMsg.AddAttachment(FileName, 'application/pdf', InS);

                                            EmailAction := Email.OpenInEditorModally(EmailMsg);

                                            if EmailAction = Enum::"Email Action"::Sent then begin
                                                SelRec."Printed Count" += 1;
                                                SelRec."Emailed" := true;
                                                SelRec."Emailed Date" := CurrentDateTime();
                                                SelRec.Modify(true);
                                            end;

                                        end;
                        until SelRec.Next() = 0;

                    Message('Finished processing selected invoices.');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CustLedger: Record "Cust. Ledger Entry";
    begin
        CustLedger.Reset();
        CustLedger.SetRange("Document Type", CustLedger."Document Type"::Invoice);
        CustLedger.SetRange("Document No.", Rec."Document No.");
        RemainingAmountDisplay := 0;
        if CustLedger.FindSet() then
            repeat
                CustLedger.CalcFields("Remaining Amount");
                RemainingAmountDisplay += CustLedger."Remaining Amount";
            until CustLedger.Next() = 0;
    end;

    var
        RemainingAmountDisplay: Decimal;

    local procedure GetGroupKey(var Mgmt: Record "Invoice Printing Management"): Text
    var
        Cust: Record Customer;
    begin
        Cust.Get(Mgmt."Customer No.");

        if Cust."Summary Invoice by PO" then begin
            if Mgmt."Parent Customer No." <> '' then
                exit(StrSubstNo('%1|%2', Mgmt."Parent Customer No.", Mgmt."SQU PO Number"));
            exit(StrSubstNo('%1|%2', Mgmt."Customer No.", Mgmt."SQU PO Number"));
        end;

        if Mgmt."Parent Customer No." <> '' then
            exit(Mgmt."Parent Customer No.");

        exit(Mgmt."Customer No.");
    end;

    /// <summary>
    /// Strips characters that are not valid in Windows file names (\ / : * ? " < > |)
    /// from a text value so it can safely be used as part of a generated file name,
    /// e.g. a customer name embedded in a PDF attachment file name.
    /// </summary>
    local procedure SanitizeFileNamePart(Value: Text): Text
    var
        InvalidChars: Text;
        Ch: Text[1];
        i: Integer;
    begin
        InvalidChars := '\/:*?"<>|';
        for i := 1 to StrLen(InvalidChars) do begin
            Ch := CopyStr(InvalidChars, i, 1);
            Value := Value.Replace(Ch, '');
        end;
        exit(Value.Trim());
    end;

    /// <summary>
    /// Shared HTML body used for ALL THREE email actions (All Summary Invoices,
    /// This Summary Invoice, and Single Invoices) so the wording and branded
    /// footer stay identical no matter which action sent the email.
    /// The logo <img> markup comes from GetPrintGlobeLogoImgTag() - see that
    /// procedure for why this is a base64 data URI rather than a cid: inline
    /// attachment reference.
    /// TODO: swap the teal hex (#0F6E7A) for PrintGlobe's exact brand color if this is off.
    /// </summary>
    local procedure GetEmailBodyHtml(): Text
    var
        Body: TextBuilder;
    begin
        Body.Append('<div style="font-family:Calibri,Arial,sans-serif; font-size:11pt; color:#000000;">');
        Body.Append('<p>Please find the attached invoice for the period.</p>');
        Body.Append('<p>Please arrange payment at your convenience. If you would like to make payment or have any questions about your invoice please contact 1-800-989-2181 x383 or you can email ');
        Body.Append('<a href="mailto:accounting@PrintGlobe.com">accounting@PrintGlobe.com</a>.</p>');
        Body.Append('<p>If you would like to place a reorder of these items, or if we can help with any new printing needs please contact your Account Manager.</p>');
        Body.Append(GetPrintGlobeLogoImgTag());
        Body.Append('<p style="margin-top:0;">');
        Body.Append('<a href="tel:+18009892181,331" style="color:#0F6E7A; text-decoration:none;">(800) 989-2181 x331</a><br/>');
        Body.Append('<a href="https://www.printglobe.com" style="color:#0F6E7A; text-decoration:underline;">www.printglobe.com</a><br/>');
        Body.Append('2512 S I-35 Frontage Rd, Suite 100<br/>');
        Body.Append('Austin, Texas 78704');
        Body.Append('</p>');
        Body.Append('</div>');
        exit(Body.ToText());
    end;

    /// <summary>
    /// Returns the "<p><img ...></p>" markup for the invoice-email logo, with
    /// the image embedded directly as a base64 data URI instead of a cid:
    /// reference to a separate inline attachment.
    ///
    /// LOGO SOURCE: reads the "Invoice Email Logo" field added to Company
    /// Information by the SQU Invoice Email Logo Ext table/page extensions -
    /// a dedicated logo just for these invoice emails, set on the existing
    /// Company Information card right next to the standard "Picture" (company
    /// logo) field, so there's no separate setup page to find. If nothing has
    /// been uploaded there yet, no image is shown (the footer text still
    /// prints normally). Note this field is Media, not BLOB like "Picture",
    /// so - unlike CompanyInfo.Picture - it does NOT need CalcFields() first.
    ///
    /// WHY A DATA URI, NOT cid: EmailMsg.AddAttachment(..., InLine := true,
    /// ContentId := 'printglobelogo') plus <img src="cid:printglobelogo"> is
    /// the textbook-correct MIME pattern, but in practice the logo showed up
    /// as a plain attachment while the body still rendered an empty box -
    /// something between the Email Message codeunit and whatever connector/
    /// SMTP path is actually sending these isn't reliably wiring the
    /// Content-ID through to the body reference. A base64 data URI has no
    /// such dependency: the image bytes live directly inside the HTML, so
    /// there's no separate MIME part to link up and nothing for a connector
    /// to drop.
    ///
    /// Trade-off: this inflates the email's HTML by roughly 4/3 of the image's
    /// byte size - a non-issue for a small logo, but don't reuse this pattern
    /// for anything large (e.g. a full-page PDF preview image).
    ///
    /// NOTE ON Media FIELDS: unlike a BLOB field, a Media field has no
    /// CreateInStream() of its own - its API is ExportStream(OutStream) /
    /// ImportStream(InStream, MimeType). So the bytes are exported into a
    /// Temp Blob first, and everything downstream (the format sniff, the
    /// base64 conversion) reads InStreams from that Temp Blob instead.
    /// </summary>
    local procedure GetPrintGlobeLogoImgTag(): Text
    var
        CompanyInfo: Record "Company Information";
        LogoBlob: Codeunit "Temp Blob";
        LogoOutStream: OutStream;
        SniffInStream: InStream;
        LogoInStream: InStream;
        Base64Convert: Codeunit "Base64 Convert";
        ContentType: Text;
        FileExtension: Text;
        Base64Logo: Text;
    begin
        if not CompanyInfo.Get() then
            exit('');

        if not CompanyInfo."Invoice Email Logo".HasValue() then
            exit('');

        LogoBlob.CreateOutStream(LogoOutStream);
        CompanyInfo."Invoice Email Logo".ExportStream(LogoOutStream);

        LogoBlob.CreateInStream(SniffInStream);
        DetectImageContentType(SniffInStream, ContentType, FileExtension);

        // Fresh InStream for the actual base64 conversion - the sniff pass
        // above already read the first one to the end.
        LogoBlob.CreateInStream(LogoInStream);
        Base64Logo := Base64Convert.ToBase64(LogoInStream);

        exit(StrSubstNo(
            '<p><img src="data:%1;base64,%2" alt="PrintGlobe" style="max-width:220px; height:auto;"></p>',
            ContentType, Base64Logo));
    end;

    /// <summary>
    /// Sniffs an image stream's real format from its file-signature bytes
    /// (checked via the equivalent Base64 prefix, since AL doesn't give easy
    /// raw-byte peeking on an InStream) rather than trusting a filename or
    /// an assumed format. Defaults to PNG if the signature isn't recognized.
    /// </summary>
    local procedure DetectImageContentType(var InStr: InStream; var ContentType: Text; var FileExtension: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        Base64Text: Text;
    begin
        Base64Text := Base64Convert.ToBase64(InStr);

        case true of
            Base64Text.StartsWith('iVBORw0KGgo'): // PNG signature 89 50 4E 47 ...
                begin
                    ContentType := 'image/png';
                    FileExtension := 'png';
                end;
            Base64Text.StartsWith('/9j/'): // JPEG signature FF D8 FF ...
                begin
                    ContentType := 'image/jpeg';
                    FileExtension := 'jpg';
                end;
            Base64Text.StartsWith('R0lGOD'): // GIF signature "GIF87a"/"GIF89a"
                begin
                    ContentType := 'image/gif';
                    FileExtension := 'gif';
                end;
            Base64Text.StartsWith('Qk'): // BMP signature "BM"
                begin
                    ContentType := 'image/bmp';
                    FileExtension := 'bmp';
                end;
            else begin
                ContentType := 'image/png';
                FileExtension := 'png';
            end;
        end;
    end;

    local procedure ProcessSummaryInvoiceEmails(var AllRec: Record "Invoice Printing Management"; ConfirmMessage: Text; NoRecordsMessage: Text; DoneMessage: Text)
    var
        Cust: Record Customer;
        ParentCust: Record Customer;
        TempBlob: Codeunit "Temp Blob";
        TempBlobWL: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        EmailMsg: Codeunit "Email Message";
        Email: Codeunit Email;
        SummaryReport: Report "SQU Sum Sales - Invoice New";
        WLReport: Report "SQU Sum Sales - Invoice no Rev";
        FileName: Text;
        FileNameWL: Text;
        DisplayName: Text;
        PrintMgmt: Record "Invoice Printing Management";
        ProcessedSummaryNos: Dictionary of [Code[20], Boolean];
        EmailAction: Enum "Email Action";
        CsvBlob: Codeunit "Temp Blob";
        CsvOutS: OutStream;
        CsvInS: InStream;
        CsvFileName: Text;
        CsvNoRevBlob: Codeunit "Temp Blob";
        CsvNoRevOutS: OutStream;
        CsvNoRevInS: InStream;
        CsvNoRevFileName: Text;
        CsvBuilder: Codeunit "Summary Invoice CSV Builder";
        BaseReqParams: Text;
        WLBaseReqParams: Text;
        LoopReqParams: Text;
        WLLoopReqParams: Text;
        IsWLCustomer: Boolean;
    begin
        if not AllRec.FindSet() then begin
            Message(NoRecordsMessage);
            exit;
        end;

        if not Confirm(ConfirmMessage) then
            exit;

        // ── Capture base request params for report 55003 ──────────
        Clear(SummaryReport);
        SummaryReport.SetSummaryInvoiceNo('ZZTOKEN99');
        BaseReqParams := SummaryReport.RunRequestPage();
        if BaseReqParams = '' then
            exit;
        if StrPos(BaseReqParams, 'ZZTOKEN99') = 0 then begin
            Message('Unable to inject summary invoice number into report parameters. Please contact your administrator.');
            exit;
        end;

        // ── Capture base request params for report 55009 (WL) ─────
        Clear(WLReport);
        WLReport.SetSummaryInvoiceNo('ZZTOKEN99');
        WLBaseReqParams := WLReport.RunRequestPage();
        if WLBaseReqParams = '' then
            exit;
        if StrPos(WLBaseReqParams, 'ZZTOKEN99') = 0 then begin
            Message('Unable to inject summary invoice number into WL report parameters. Please contact your administrator.');
            exit;
        end;

        AllRec.FindSet();

        repeat
            if not ProcessedSummaryNos.ContainsKey(AllRec."Summary Invoice No.") then begin
                ProcessedSummaryNos.Add(AllRec."Summary Invoice No.", true);

                if Cust.Get(AllRec."Customer No.") then
                    if Cust."E-Mail" <> '' then begin

                        IsWLCustomer := CopyStr(AllRec."Parent Customer No.", 1, 2) = 'WL';
                        LoopReqParams := BaseReqParams.Replace('ZZTOKEN99', AllRec."Summary Invoice No.");

                        // Prefer the Parent Customer's name (this summary invoice is grouped
                        // under it); fall back to the invoice's own customer when there is
                        // no parent customer on this group, same fallback GetGroupKey uses.
                        DisplayName := Cust.Name;
                        if AllRec."Parent Customer No." <> '' then
                            if ParentCust.Get(AllRec."Parent Customer No.") then
                                DisplayName := ParentCust.Name;

                        // ── Generate standard PDF (rep 55003) ────────
                        Clear(TempBlob);
                        TempBlob.CreateOutStream(OutS);
                        Report.SaveAs(
                            Report::"SQU Sum Sales - Invoice New",
                            LoopReqParams,
                            ReportFormat::Pdf,
                            OutS);

                        TempBlob.CreateInStream(InS);
                        FileName := StrSubstNo('%1 - %2.pdf', AllRec."Summary Invoice No.", SanitizeFileNamePart(DisplayName));
                        DownloadFromStream(InS, 'Summary Invoice Export', '', 'PDF Files (*.pdf)|*.pdf', FileName);
                        TempBlob.CreateInStream(InS);

                        EmailMsg.Create(
                            Cust."E-Mail",
                            StrSubstNo('PrintGlobe Invoice %1', AllRec."Summary Invoice No."),
                            GetEmailBodyHtml(),
                            true);
                        EmailMsg.AddAttachment(FileName, 'application/pdf', InS);

                        // ── WL: attach rev share PDF (rep 55009) ─────
                        if IsWLCustomer then begin
                            WLLoopReqParams := WLBaseReqParams.Replace('ZZTOKEN99', AllRec."Summary Invoice No.");

                            Clear(TempBlobWL);
                            TempBlobWL.CreateOutStream(OutS);
                            Report.SaveAs(
                                Report::"SQU Sum Sales - Invoice no Rev",
                                WLLoopReqParams,
                                ReportFormat::Pdf,
                                OutS);

                            TempBlobWL.CreateInStream(InS);
                            FileNameWL := StrSubstNo('%1 - %2 RevShare.pdf', AllRec."Summary Invoice No.", SanitizeFileNamePart(DisplayName));
                            EmailMsg.AddAttachment(FileNameWL, 'application/pdf', InS);
                        end;

                        // ── Generate CSV with Revenue Share (file name now carries
                        // "RevShare" so it's distinguishable from the no-Revenue-Share
                        // CSV below, which took over the original plain file name) ──
                        Clear(CsvBlob);
                        CsvBlob.CreateOutStream(CsvOutS);
                        CsvBuilder.BuildCSV(AllRec."Summary Invoice No.", CsvOutS, true);
                        CsvBlob.CreateInStream(CsvInS);
                        CsvFileName := StrSubstNo('%1 - %2 RevShare.csv', AllRec."Summary Invoice No.", SanitizeFileNamePart(DisplayName));
                        EmailMsg.AddAttachment(CsvFileName, 'text/csv', CsvInS);

                        // ── Generate CSV without Revenue Share (uses the original
                        // plain file name) ────────────────────────────────────────
                        Clear(CsvNoRevBlob);
                        CsvNoRevBlob.CreateOutStream(CsvNoRevOutS);
                        CsvBuilder.BuildCSV(AllRec."Summary Invoice No.", CsvNoRevOutS, false);
                        CsvNoRevBlob.CreateInStream(CsvNoRevInS);
                        CsvNoRevFileName := StrSubstNo('%1 - %2.csv', AllRec."Summary Invoice No.", SanitizeFileNamePart(DisplayName));
                        EmailMsg.AddAttachment(CsvNoRevFileName, 'text/csv', CsvNoRevInS);

                        EmailAction := Email.OpenInEditorModally(EmailMsg);

                        if EmailAction = Enum::"Email Action"::Sent then begin
                            PrintMgmt.Reset();
                            PrintMgmt.SetRange("Summary Invoice No.", AllRec."Summary Invoice No.");
                            if PrintMgmt.FindSet() then
                                repeat
                                    PrintMgmt."Printed Count" += 1;
                                    PrintMgmt."Emailed" := true;
                                    PrintMgmt."Emailed Date" := CurrentDateTime();
                                    PrintMgmt.Modify(true);
                                until PrintMgmt.Next() = 0;
                        end;

                    end;
            end;
        until AllRec.Next() = 0;

        Message(DoneMessage);
    end;
}