pageextension 55007 "SQ Sales Inv Lines Ad" extends "Sales Invoice Subform" //OriginalId
{
    layout
    {
      
        addafter(Description)
        {
             field("Exported To CM";Rec."Exported To CM")
            {
                Caption = 'Exported to CM';
                ApplicationArea = all;
                Editable = false;
            }
            field("CM Line Number";Rec."CM Line Number")
            {
                Caption = 'CM Line Number';
                ApplicationArea = all;
                Editable = false;
            }
        }
    }
}