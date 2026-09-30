table 55020 "Summary Invoice Buffer"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Summary Invoice No."; Code[20]) { }
        field(2; "Document No."; Code[20]) { }
        field(3; "Invoice No."; Code[20]) { }
        field(4; "Document Date"; Date) { }
        field(5; "Sell-to Customer No."; Code[20]) { }
        field(6; "Line No."; Integer) { }
        field(7; Description; Text[100]) { }
        field(8; Quantity; Decimal) { }
        field(9; Amount; Decimal) { }
        field(10; "Source Type"; Code[20]) // <-- add this
        {
            Caption = 'Source Type';
        }
        field(11; "External Doc"; code[35]) { }
        field(12; "Sell-to Address."; Text[100]) { }
        field(13; "Sell-to Address 2"; Text[50]) { }
        field(14; "Sell-to City"; Text[30]) { }
        field(15; "Sell-to County"; Text[30]) { }
        field(16; "Sell-to E-Mail"; Text[80]) { }
        field(17; "SQU PO Number"; Text[200]) { }
        field(18; "Sell-to Post Code"; code[20]) { }
        field(19; "Revenue Share Amount"; decimal) { }
        field(20; "Row Type"; Option)
        {
            Caption = 'Row Type';
            OptionMembers = Invoice,"Credit Memo",Payment;
            DataClassification = CustomerContent;
        }
        field(21; "Unit Price"; Decimal) { }
        field(22; "Parent Customer Name"; Text[100]) { }
        field(23; "Profit Multiplier Amount"; Decimal) { }
        field(24; "GLNo"; code[20]) { }
        field(25; "Customer Name"; text[100]) { }

    }

    keys
    {
        key(PK; "Summary Invoice No.", "Document No.", "Line No.") { Clustered = true; }
    }
}