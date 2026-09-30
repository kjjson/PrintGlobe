report 55000 "SQU Summary Invoice"
{
    Caption = 'Sales - Invoice';
     ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    EnableHyperlinks = true;
    Permissions = TableData "Sales Shipment Buffer" = rimd;
    PreviewMode = PrintLayout;
    WordMergeDataItem = Header;


    dataset
    {
        dataitem(Header; "Sales Invoice Header")
        {
            DataItemTableView = sorting("No.");

            // Include "No." so running from a selected Posted Sales Invoice passes its No. as a filter
            RequestFilterFields = "No.", "Sell-to Customer No.", "Posting Date";
            RequestFilterHeading = 'Posted Sales Invoice';

            // expose these so your RDLC can group/show top header
            column(Customer_No_; "Sell-to Customer No.") { }
            column(Customer_Name; "Sell-to Customer Name") { }
            column(Posting_Date; "Posting Date") { }

            // (keep your existing columns ...)
            

            dataitem(Line; "Sales Invoice Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemLinkReference = Header;
                DataItemTableView = sorting("Document No.", "Line No.");

                // (your line columns...)
            }

            trigger OnPreDataItem()
            var
                SelHeader: Record "Sales Invoice Header";
            begin
                // If user ran from a selected invoice (No. filter present)
                // and they did NOT fill Customer/Date on request page,
                // derive both from that invoice, then clear the No. filter
                // so we include all invoices for that customer/date.
                if (CustomerNo = '') and (PostingDate = 0D) and (GetFilter("No.") <> '') then begin
                    SelHeader.SetView(GetView()); // copy current filters (incl. No.)
                    if SelHeader.FindFirst() then begin
                        CustomerNo := SelHeader."Sell-to Customer No.";
                        PostingDate := SelHeader."Posting Date";
                        SetRange("No."); // clear the "No." filter
                    end;
                end;

                // Now constrain to the target customer/date
                if CustomerNo <> '' then
                    SetRange("Sell-to Customer No.", CustomerNo);
                if PostingDate <> 0D then
                    SetRange("Posting Date", PostingDate);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(FilterGroup)
                {
                    field(CustomerNo; CustomerNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Customer No.';
                        TableRelation = Customer."No.";
                        ToolTip = 'Leave blank when running from a selected posted invoice to auto-derive.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date';
                        ToolTip = 'Leave blank when running from a selected posted invoice to auto-derive.';
                    }
                }
            }
        }
    }

    var
        CustomerNo: Code[20];
        PostingDate: Date;
}
