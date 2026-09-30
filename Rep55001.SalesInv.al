report 55001 "SQU Standard Sales - Invoice"
{
    ApplicationArea = All;
    Caption = 'Sales - Invoice Summary';
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
            column(RevenueShareAmount; "Revenue Share Amount") { }

            //          column(SourceType; Text[20]) { }
        }
    }

    requestpage
    {
        SaveValues = true;

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
                        // <-- No TableRelation here, user manually enters the code
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
                        ToolTip = 'Specifies if you want notes about additional fees to be shown on the document.';
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
    }

    var
        SummaryInvoiceNo: Code[20];
        LogInteraction: Boolean;
        LogInteractionEnable: Boolean;
        DisplayAssemblyInformation: Boolean;
        DisplayShipmentInformation: Boolean;
        DisplayAdditionalFeeNote: Boolean;
        HideLinesWithZeroQuantity: Boolean;

        SummaryQuery: Query "Summary-Invoice Query";
        CreditMemoQuery: Query "Summary-Invoice CreditMemos";
        SegManagement: Codeunit SegManagement;


        SummaryInvoiceNoFilter: Code[20];

    trigger OnPreReport()
    begin
        PopulateBuffer();
    end;

    local procedure PopulateBuffer()
    begin
        Buffer.DeleteAll();

        // Populate Invoice Rows
        if SummaryInvoiceNo <> '' then
            SummaryQuery.SetRange(SummaryInvoiceNo, SummaryInvoiceNo);

        SummaryQuery.Open();
        while SummaryQuery.Read() do begin
            Buffer.Init();
            Buffer."Summary Invoice No." := SummaryQuery.SummaryInvoiceNo;
            Buffer."Document No." := SummaryQuery.DocNo;
            Buffer."Invoice No." := SummaryQuery.Header_No;
            Buffer."Document Date" := SummaryQuery.Document_Date;
            Buffer."Sell-to Customer No." := SummaryQuery.Header_CustomerNo;
            Buffer."Line No." := SummaryQuery.Line_No;
            Buffer.Description := SummaryQuery.Line_Description;
            Buffer.Quantity := SummaryQuery.Line_Quantity;
            Buffer.Amount := SummaryQuery.Line_Amount;
            Buffer."External Doc" := SummaryQuery.External_Document_No_;
            Buffer."Sell-to Address." := SummaryQuery.Cust_Address;
            Buffer."Sell-to Address 2" := SummaryQuery.Cust_Address_2;
            Buffer."Sell-to City" := SummaryQuery.Cust_City;
            Buffer."Sell-to County" := SummaryQuery.Cust_County;
            Buffer."SQU PO Number" := SummaryQuery.SQU_PO_Number;
            Buffer."Sell-to Post Code" := SummaryQuery.Cust_Post_Code;
            Buffer."Revenue Share Amount" := SummaryQuery.Revenue_Share_Amount;

            //          Buffer.SourceType := 'Invoice';
            Buffer.Insert();
        end;
        SummaryQuery.Close();

        // Populate Credit Memo Rows
        if SummaryInvoiceNo <> '' then
            CreditMemoQuery.SetRange(SummaryInvoiceNo, SummaryInvoiceNo);

        CreditMemoQuery.Open();
        while CreditMemoQuery.Read() do begin
            Buffer.Init();
            Buffer."Summary Invoice No." := CreditMemoQuery.SummaryInvoiceNo;
            Buffer."Document No." := CreditMemoQuery.CrMemo_No;
            Buffer."Invoice No." := CreditMemoQuery.CrMemo_No;
            Buffer."Document Date" := CreditMemoQuery.CrMemo_Date;
            Buffer."Sell-to Customer No." := CreditMemoQuery.CrMemo_CustomerNo;
            Buffer.Amount := CreditMemoQuery.Amount;
            //            Buffer.SourceType := 'Credit Memo';
            Buffer."External Doc" := CreditMemoQuery.CrMemo_External_Doc_No;
            Buffer.Insert();
        end;
        CreditMemoQuery.Close();
    end;

    local procedure LogInteractionTemplateExists(): Boolean
    begin
        exit(SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Sales Inv.") <> '');
    end;

    procedure SetSummaryInvoiceNo(SummaryNo: Code[20])
    begin

        SummaryInvoiceNoFilter := SummaryNo;
    end;

    // procedure SetSummaryInvoiceNo(SummaryInvoiceNo: Code[20])
    // begin
    //     SummaryInvoiceNoFilter := SummaryInvoiceNo;
    // end;
}