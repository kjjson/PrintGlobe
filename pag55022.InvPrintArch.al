page 55023 "Invoice Print Mgmt Archive"
{
    PageType = List;
    SourceTable = "Invoice Print Mgmt Archive";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Invoice Printing Management Archive';
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document No."; Rec."Document No.") { ApplicationArea = All; }
                field("Document Type"; Rec."Document Type") { ApplicationArea = All; }
                field("External Document No."; Rec."External Document No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Customer Name"; Rec."Customer Name") { ApplicationArea = All; }
                field("Parent Customer No."; Rec."Parent Customer No.") { ApplicationArea = All; }
                field("Parent Customer Name"; Rec."Parent Customer Name") { ApplicationArea = All; }
                field("Summary Invoice"; Rec."Summary Invoice") { ApplicationArea = All; }
                field("Summary Invoice No."; Rec."Summary Invoice No.") { ApplicationArea = All; }
                field("Posting Date"; Rec."Posting Date") { ApplicationArea = All; }
                field("Emailed"; Rec."Emailed") { ApplicationArea = All; }
                field("Emailed Date"; Rec."Emailed Date") { ApplicationArea = All; }
                field("Archived Date"; Rec."Archived Date") { ApplicationArea = All; }
                field("Revenue Share Amount"; Rec."Revenue Share Amount") { ApplicationArea = All; }
                field("Profit Multiplier Amount"; Rec."Profit Multiplier Amount") { ApplicationArea = All; }
                field("Printed Count"; Rec."Printed Count") { ApplicationArea = All; }
            }
        }
    }
}