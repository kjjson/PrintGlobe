pageextension 55009 CustomerCardExtension extends "Customer Card"
{
    layout
    {
        addlast(General)
        {
            group("Parent/Revenue Info")
            {
                field("Parent Company"; Rec."Parent Company")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the parent company for this customer.';
                }

                field("Revenue Share"; Rec."Revenue Share")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the revenue share percentage for this customer.';
                }
                field("Profit Multiplier"; Rec."Profit Multiplier")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enter the Profit Multiplier percentage for this customer.';
                }
                field("Summary Invoice"; Rec."Summary Invoice")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable if customer should receive summary invoices.';
                }
                field("Summary Invoice by PO"; Rec."Summary Invoice by PO")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable if customer should receive summary invoices by PO.';
                }
                field("Shipping in Rev Share"; Rec."Shipping in Rev Share")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable if shipping should be included with Rev Share.';
                }
            }
        }
    }
}