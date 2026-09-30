pageextension 55008 "SQU Sales Inv" extends "Sales Invoice"
{
    layout
    {
        addafter("External Document No.")
        {
            field("CM Status"; Rec."CM Status")
            {
                ToolTip = 'CM Status';
                ApplicationArea = All;
            }
            field("Exported To CM"; Rec."Exported To CM")
            {
                ToolTip = 'Exported to CM';
                ApplicationArea = All;
            }
            field("CM Closed Date"; Rec."CM Closed Date")
            {
                Caption = 'CM Closed Date';
                ApplicationArea = All;
            }
            field("PO Number"; Rec."SQU PO Number")
            {
                ToolTip = 'PO Number';
                ApplicationArea = All;
            }
            field("Master Job"; Rec."Master Job")
            {
                ToolTip = 'Master Job';
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}