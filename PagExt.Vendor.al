pageextension 55003 VendorCardExt extends "Vendor Card"
{
    layout
    {
        addlast(General)
        {
            field("Default GL Account"; Rec."Default GL Account")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default G/L Account for this vendor.';
              
            }
        }
    }
}
