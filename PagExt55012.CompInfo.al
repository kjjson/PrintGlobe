pageextension 55012 "SQU Comp info" extends "Company Information"
{
    layout
    {
        // addlast(content) confirmed the field itself renders (previous
        // step), but placed bare/ungrouped it showed up completely inert -
        // no click response at all - while every other field on the page
        // (which all live inside FastTab groups) is fully editable. Wrapping
        // it in its own group gives it the same FastTab-section context the
        // rest of the page's interactive fields have, which is the standard
        // AL pattern anyway (a bare field directly under area(content),
        // outside any group, is unusual and apparently doesn't pick up the
        // normal edit/upload wiring for a Media-type control).
        addlast(content)
        {
            group(SQUInvoiceEmailLogo)
            {
                Caption = 'Invoice Email Logo';

                field("Invoice Email Logo"; Rec."Invoice Email Logo")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Email Logo';
                    ToolTip = 'Specifies the logo shown in the footer of invoice emails sent from Invoice Printing Management (Email All Summary Invoices, Email This Summary Invoice, Email Single Invoices). Upload any common image format (PNG, JPEG, GIF, BMP). This can be different from the company logo (Picture) used on reports.';
                }
            }
        }
    }
}