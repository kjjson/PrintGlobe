report 55009 "SQU Sum Sales - Invoice no Rev"

{
    ApplicationArea = All;
    Caption = 'Sales - Invoice Summary New';
    UsageCategory = ReportsAndAnalysis;
    EnableHyperlinks = true;
    Permissions = TableData "Sales Shipment Buffer" = rimd;
    PreviewMode = PrintLayout;
    DefaultRenderingLayout = "StandardSalesInvoice.rdlc";

    dataset
    {
        dataitem(Buffer; "Summary Invoice Buffer")
        {
            DataItemTableView = SORTING("Summary Invoice No.", "Document No.", "Line No.");
            UseTemporary = true;

            column(SummaryInvoiceNo; "Summary Invoice No.") { }
            column(DocumentNo; "Document No.") { }
            column(InvoiceNo; "Invoice No.") { }
            column(DocumentDate; "Document Date") { }
            column(CustomerNo; "Sell-to Customer No.") { }
            column(LineNo; "Line No.") { }
            column(Description; Description) { }
            column(Quantity; Quantity) { }
            column(Amount; Amount) { }
            column(External_Doc; "External Doc") { }
            column(Sell_to_Address_; "Sell-to Address.") { }
            column(Sell_to_Address_2; "Sell-to Address 2") { }
            column(Sell_to_City; "Sell-to City") { }
            column(Sell_to_County; "Sell-to County") { }
            column(Sell_to_E_Mail; "Sell-to E-Mail") { }
            column(Sell_to_Post_Code; "Sell-to Post Code") { }
            column(SQU_PO_Number; "SQU PO Number") { }
            column(SQU_RevShare; "Revenue Share Amount") { }
            column(SQU_ProfitMultiplier; "Profit Multiplier Amount") { }
            column(UnitPrice; "Unit Price") { }
            column(RowType; "Row Type") { }
            column(CityStateZip; CityStateZip) { }
            column(ParentCustomerName; "Parent Customer Name") { }
            column(InvoiceLinkURL; InvoiceLinkURL) { }
            // Actual (non-parent) customer name, shown above the PO line
            column(CustomerName; "Customer Name") { }
            // G/L Account of the invoice line, used to override Description for specific accounts
            column(GLAccountNo; "GLNo") { }

            trigger OnAfterGetRecord()
            begin
                CityStateZip := '';
                if "Sell-to City" <> '' then
                    CityStateZip := "Sell-to City";
                if "Sell-to County" <> '' then
                    CityStateZip += ', ' + "Sell-to County";
                if "Sell-to Post Code" <> '' then
                    CityStateZip += ' ' + "Sell-to Post Code";

                InvoiceLinkURL := BaseURLTxt + "Summary Invoice No.";
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

        layout
        {
            area(content)
            {
                group(FilterGroup)
                {
                    Caption = 'Filter';

                    field(SummaryInvoiceNo; SummaryInvoiceNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Summary Invoice No.';
                        ToolTip = 'Enter a Summary Invoice No. to print all related invoices and credit memos.';
                    }
                }

                group(Options)
                {
                    Caption = 'Options';

                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record related interactions with the contact person in the Interaction Log Entry table.';
                    }

                    field(DisplayAsmInformation; DisplayAssemblyInformation)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Show Assembly Components';
                        ToolTip = 'Specifies if you want the report to include information about components that were used in linked assembly orders.';
                    }

                    field(DisplayShipmentInformation; DisplayShipmentInformation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Shipments';
                        ToolTip = 'Specifies that shipments are shown on the document.';
                    }

                    field(DisplayAdditionalFeeNote; DisplayAdditionalFeeNote)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Additional Fee Note';
                        ToolTip = 'Specifies if you want notes about additional fees to be shown on the environment.';
                    }

                    field(HideLinesWithZeroQuantityControl; HideLinesWithZeroQuantity)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Hide lines with zero quantity';
                        ToolTip = 'Specifies if the lines with zero quantity are printed.';
                    }
                }
            }
        }

        actions { }

        trigger OnInit()
        begin
            LogInteraction := LogInteractionTemplateExists();
            LogInteractionEnable := LogInteraction;
        end;
    }

    rendering
    {
        layout("StandardSalesInvoice.rdlc")
        {
            Type = RDLC;
            LayoutFile = 'StandardSalesInvoice.rdlc';
        }
        layout("StandardSalesInvoiceWL.rdlc")
        {
            Type = RDLC;
            LayoutFile = 'StandardSalesInvoiceWL.rdlc';
            Caption = 'WL (No Revenue Share)';
        }
    }

    var
        SummaryInvoiceNo: Code[20];
        LogInteraction: Boolean;
        LogInteractionEnable: Boolean;
        DisplayAssemblyInformation: Boolean;
        DisplayShipmentInformation: Boolean;
        DisplayAdditionalFeeNote: Boolean;
        HideLinesWithZeroQuantity: Boolean;
        SegManagement: Codeunit SegManagement;
        CityStateZip: Text[100];
        BaseURLTxt: Label 'https://white-water-0543e061e.3.azurestaticapps.net/?tenantId=41a9b9ae-0cba-4b3a-9677-35259c6be3c4&environment=sandbox_May26&companyid=240fde62-6ace-ed11-a7c7-0022482870c6&invoice=', Locked = true;
        InvoiceLinkURL: Text;

    trigger OnPreReport()
    begin

        PopulateBuffer();
    end;

    local procedure PopulateBuffer()
    var
        InvPrintMgmt: Record "Invoice Printing Management";
        SalesInvHdr: Record "Sales Invoice Header";
        ParentCust: Record Customer;          // ADD
        LocalSummaryQuery: Query "Summary-Invoice Query";
        LocalCreditMemoQuery: Query "Summary-Invoice CreditMemos";
        InvPrintMgmtFound: Boolean;
    begin
        Buffer.DeleteAll();

        // Populate Invoice Rows
        if SummaryInvoiceNo <> '' then
            LocalSummaryQuery.SetRange(SummaryInvoiceNo, SummaryInvoiceNo);

        LocalSummaryQuery.Open();
        while LocalSummaryQuery.Read() do begin
            Buffer.Init();
            Buffer."Summary Invoice No." := LocalSummaryQuery.SummaryInvoiceNo;
            Buffer."Document No." := LocalSummaryQuery.DocNo;
            Buffer."Invoice No." := LocalSummaryQuery.Header_No;
            Buffer."Document Date" := LocalSummaryQuery.Document_Date;
            Buffer."Sell-to Customer No." := LocalSummaryQuery.Header_CustomerNo;
            Buffer."Parent Customer Name" := LocalSummaryQuery.Parent_Customer_Name;
            Buffer."Line No." := LocalSummaryQuery.Line_No;
            // GL 40020 and 20165 are fee lines with a fixed customer-facing description
            // regardless of the underlying G/L account's actual description.
            case LocalSummaryQuery.GLNo of
                '40020':
                    Buffer.Description := 'Shipping & Handling';
                '20165':
                    Buffer.Description := 'Sales Tax Collected';
                else
                    Buffer.Description := LocalSummaryQuery.Line_Description;
            end;
            Buffer.Quantity := LocalSummaryQuery.Line_Quantity;
            Buffer.Amount := LocalSummaryQuery.Line_Amount;
            Buffer."External Doc" := LocalSummaryQuery.External_Document_No_;
            Buffer."SQU PO Number" := LocalSummaryQuery.SQU_PO_Number;
            Buffer."Revenue Share Amount" := LocalSummaryQuery.Revenue_Share_Amount;
            Buffer."Profit Multiplier Amount" := LocalSummaryQuery.Profit_Multiplier_Amount;
            Buffer."Unit Price" := LocalSummaryQuery.Unit_Price;
            Buffer."Row Type" := Buffer."Row Type"::Invoice;
            // G/L Account of the line
            Buffer."GLNo" := LocalSummaryQuery.GLNo;

            // ── Resolve parent customer address ──────────────────────────────
            // InvPrintMgmt carries the Parent Customer No. for this invoice;
            // fall back to the sell-to customer if no parent is set.
            InvPrintMgmt.Reset();
            InvPrintMgmt.SetRange("Document No.", LocalSummaryQuery.DocNo);
            InvPrintMgmt.SetRange("Document Type", InvPrintMgmt."Document Type"::Invoice);
            InvPrintMgmtFound := InvPrintMgmt.FindFirst();

            // "Customer Name" and "Parent Customer Name" on Invoice Printing Management
            // are FlowFields — they are NOT populated by FindFirst()/FindSet() and must
            // be explicitly calculated, otherwise they read back blank.
            if InvPrintMgmtFound then
                InvPrintMgmt.CalcFields("Customer Name");

            // Actual customer name (not parent), printed above the PO line
            if InvPrintMgmtFound then
                Buffer."Customer Name" := InvPrintMgmt."Customer Name";

            if InvPrintMgmtFound and
               (InvPrintMgmt."Parent Customer No." <> '') and
               ParentCust.Get(InvPrintMgmt."Parent Customer No.")
            then begin
                Buffer."Sell-to Address." := ParentCust.Address;
                Buffer."Sell-to Address 2" := ParentCust."Address 2";
                Buffer."Sell-to City" := ParentCust.City;
                Buffer."Sell-to County" := ParentCust.County;
                Buffer."Sell-to Post Code" := ParentCust."Post Code";
                Buffer."Sell-to E-Mail" := ParentCust."E-Mail";
            end else begin
                // Fallback: use sell-to address from query + email from customer card
                Buffer."Sell-to Address." := LocalSummaryQuery.Cust_Address;
                Buffer."Sell-to Address 2" := LocalSummaryQuery.Cust_Address_2;
                Buffer."Sell-to City" := LocalSummaryQuery.Cust_City;
                Buffer."Sell-to County" := LocalSummaryQuery.Cust_County;
                Buffer."Sell-to Post Code" := LocalSummaryQuery.Cust_Post_Code;
                if ParentCust.Get(LocalSummaryQuery.Header_CustomerNo) then
                    Buffer."Sell-to E-Mail" := ParentCust."E-Mail";
            end;
            // ─────────────────────────────────────────────────────────────────

            Buffer.Insert();
        end;
        LocalSummaryQuery.Close();

        // Populate Credit Memo Rows
        if SummaryInvoiceNo <> '' then
            LocalCreditMemoQuery.SetRange(SummaryInvoiceNo, SummaryInvoiceNo);

        LocalCreditMemoQuery.Open();
        while LocalCreditMemoQuery.Read() do begin
            Buffer.Init();
            Buffer."Summary Invoice No." := LocalCreditMemoQuery.SummaryInvoiceNo;
            Buffer."Document No." := LocalCreditMemoQuery.CrMemo_No;
            Buffer."Invoice No." := LocalCreditMemoQuery.CrMemo_No;
            Buffer."Document Date" := LocalCreditMemoQuery.CrMemo_Date;
            Buffer."Sell-to Customer No." := LocalCreditMemoQuery.CrMemo_CustomerNo;
            Buffer.Amount := LocalCreditMemoQuery.Amount;
            Buffer."External Doc" := LocalCreditMemoQuery.CrMemo_External_Doc_No;
            Buffer."Row Type" := Buffer."Row Type"::"Credit Memo";
            Buffer.Insert();
        end;
        LocalCreditMemoQuery.Close();

        // Populate Payment Rows (via applied ledger entries)
        InvPrintMgmt.Reset();
        if SummaryInvoiceNo <> '' then
            InvPrintMgmt.SetRange("Summary Invoice No.", SummaryInvoiceNo);
        InvPrintMgmt.SetRange("Document Type", InvPrintMgmt."Document Type"::Invoice);

        if InvPrintMgmt.FindSet() then
            repeat
                if SalesInvHdr.Get(InvPrintMgmt."Document No.") then
                    WriteAppliedPaymentRows(InvPrintMgmt, SalesInvHdr);
            until InvPrintMgmt.Next() = 0;
    end;

    local procedure WriteAppliedPaymentRows(
        InvPrintMgmt: Record "Invoice Printing Management";
        SalesInvHdr: Record "Sales Invoice Header")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        AppliedEntry: Record "Cust. Ledger Entry";
        DetailedEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Find the invoice's own ledger entry
        CustLedgEntry.SetRange("Customer No.", SalesInvHdr."Sell-to Customer No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", SalesInvHdr."No.");
        if not CustLedgEntry.FindFirst() then
            exit;

        // Find all application detail entries posted against this invoice
        DetailedEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DetailedEntry.SetRange("Entry Type", DetailedEntry."Entry Type"::Application);
        DetailedEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', CustLedgEntry."Entry No.");
        if not DetailedEntry.FindSet() then
            exit;

        repeat
            if AppliedEntry.Get(DetailedEntry."Applied Cust. Ledger Entry No.") then begin
                // Write a payment row for every applied entry (no Document Type filter —
                // BC stores some payments with a blank Document Type)
                AppliedEntry.CalcFields(Amount);

                Buffer.Init();
                Buffer."Summary Invoice No." := InvPrintMgmt."Summary Invoice No.";
                Buffer."Document No." := InvPrintMgmt."Document No.";
                Buffer."Invoice No." := AppliedEntry."Document No.";
                Buffer."Document Date" := AppliedEntry."Posting Date";
                Buffer."Sell-to Customer No." := AppliedEntry."Customer No.";
                Buffer.Amount := AppliedEntry.Amount;
                Buffer."External Doc" := AppliedEntry."External Document No.";
                Buffer.Description := StrSubstNo('Payment %1', AppliedEntry."Document No.");
                Buffer."Row Type" := Buffer."Row Type"::Payment;
                Buffer."Line No." := 900000 + AppliedEntry."Entry No." mod 100000;
                Buffer.Insert();
            end;
        until DetailedEntry.Next() = 0;
    end;

    local procedure LogInteractionTemplateExists(): Boolean
    begin
        exit(SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Sales Inv.") <> '');
    end;

    procedure SetSummaryInvoiceNo(NewSummaryInvoiceNo: Code[20])
    begin
        SummaryInvoiceNo := NewSummaryInvoiceNo;
    end;
}