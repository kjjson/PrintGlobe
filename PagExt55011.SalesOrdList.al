pageextension 55011 "SQU Sales Order List" extends "Sales Order List"
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
            field("Printed Pro Forma"; Rec."Printed Pro Forma")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action("Create Credit Memos for Neg Orders")
            {
                ApplicationArea = All;
                Caption = 'Create Credit Memos for Neg Orders';
                Image = CreditMemo;
                trigger OnAction()
                var
                    CreditMemos: Codeunit "Create CM From Neg Orders";
                begin
                    CreditMemos.Run();
                end;
            }
        }
    }


}