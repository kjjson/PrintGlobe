page 55024 "Invoice Email Setup"
{
    PageType = Card;
    SourceTable = "Invoice Email Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Invoice Email Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Email Logo"; Rec."Email Logo")
                {
                    ApplicationArea = All;
                    Caption = 'Email Logo';
                    ToolTip = 'Specifies the logo shown in the footer of invoice emails sent from Invoice Printing Management (Email All Summary Invoices, Email This Summary Invoice, Email Single Invoices). Upload any common image format (PNG, JPEG, GIF, BMP) - the actual file format is auto-detected when the email is built.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetRecordOnce();
    end;

    // A BLOB field, unlike Media, is never auto-loaded - without this the
    // page control has nothing to show or edit even though the field exists.
    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Email Logo");
    end;
}