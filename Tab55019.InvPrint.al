table 55019 "Invoice Printing Management"
{
    Caption = 'Invoice Printing Management';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document Number';
            DataClassification = CustomerContent;
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = "Invoice","Credit Memo","Return Order","Order","Quote";
            DataClassification = CustomerContent;
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer Number';
            TableRelation = Customer."No.";
            DataClassification = CustomerContent;
        }
        field(4; "Summary Invoice"; Boolean)
        {
            Caption = 'Summary Invoice';
            DataClassification = CustomerContent;
        }
        field(5; "Summary Invoice No."; Code[20])
        {
            Caption = 'Summary Invoice Number';
            DataClassification = CustomerContent;
        }
        field(6; "Parent Customer No."; Code[20])
        {
            Caption = 'Parent Customer Number';
            TableRelation = Customer."No.";
            DataClassification = CustomerContent;
        }
        field(7; "Printed Count"; Integer)
        {
            Caption = 'Printed Count';
            DataClassification = CustomerContent;
        }
        field(8; "Revenue Share Amount"; Decimal)
        {
            Caption = 'Revenue Share Amount';
            DataClassification = CustomerContent;
        }
        field(9; "Revenue Share Base Amount"; Decimal)
        {
            Caption = 'Revenue Share Base Amount';
            DataClassification = CustomerContent;
        }
        field(10; "Revenue Share Percent"; Decimal)
        {
            Caption = 'Revenue Share Percent';
            DataClassification = CustomerContent;
        }
        field(11; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Editable = false;
        }
        field(12; "Parent Customer Name"; Text[100])
        {
            Caption = 'Parent Customer Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Customer.Name where("No." = field("Parent Customer No.")));
            Editable = false;
        }
        field(13; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            FieldClass = FlowField;
            CalcFormula = lookup("Sales Invoice Header"."External Document No."
                where("No." = field("Document No.")));
            Editable = false;
        }
        field(14; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            FieldClass = FlowField;
            CalcFormula = lookup("Sales Invoice Header"."Posting Date"
                where("No." = field("Document No.")));
            Editable = false;
        }
        field(15; "Emailed"; Boolean)
        {
            Caption = 'Emailed';
            DataClassification = CustomerContent;
        }
        field(16; "Emailed Date"; DateTime)
        {
            Caption = 'Emailed Date';
            DataClassification = CustomerContent;
        }
        field(17; "Invoice Amount"; Decimal)
        {
            Caption = 'Invoice Amount';

            Editable = false;
        }

        field(18; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            Editable = false;
        }
        field(19; "SQU PO Number"; Code[200])
        {
            Caption = 'SQU PO Number';
            DataClassification = CustomerContent;
        }
        field(20; "CM Closed Date"; Date)
        {
            Caption = 'CM Closed Date';
            DataClassification = CustomerContent;
        }
        field(21; "Profit Multiplier Amount"; Decimal)
        {
            Caption = 'Profit Multiplier Amount';
            DataClassification = CustomerContent;
        }
        field(22; "Profit Multiplier Base Amount"; Decimal)
        {
            Caption = 'Profit Multiplier Base Amount';
            DataClassification = CustomerContent;
        }
        field(23; "Profit Multiplier Percent"; Decimal)
        {
            Caption = 'Profit Multiplier Percent';
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        key(PK; "Document No.", "Document Type")
        {
            Clustered = true;
        }
        key(K2; "Summary Invoice No.") { }
        key(K3; "Emailed") { }
    }
}