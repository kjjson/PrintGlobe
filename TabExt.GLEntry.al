tableextension 55000 "SQU General Ledger" extends "G/L Entry"
{
    fields
    {
        field(50100; Description2; text[50])
        {
            Caption = 'Description 2';
            Editable = false;
            DataClassification = ToBeClassified;
        }
         field(50101; "Pay Desc 2"; text[50])
        {
            Description = 'Pay Desc 2';
            Caption = 'Payables Desc 2';
            FieldClass = FlowField;
            CalcFormula = lookup("Purch. Inv. Line"."Description 2" WHERE(
                "Buy-from Vendor No." = FIELD("Source No."),
                "Document No." = FIELD("Document No."), 
                "No." = FIELD("G/L Account No.")
            ));
            Editable = false;
        }
    }
    
    keys
    {
        // Add changes to keys here
    }
    
    fieldgroups
    {
        // Add changes to field groups here
    }
    
    var
        myInt: Integer;
}