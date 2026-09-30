pageextension 55010 ItemCardExt extends "Item Card"
{
    layout
    {
        addafter(Warehouse)
        {
           
                

                field("Revenue Share"; Rec."Revenue Share")
                {
                    ApplicationArea = All;
                    ToolTip = 'Is this item included for Revenue Share.';
                }
            }
        }
    }
