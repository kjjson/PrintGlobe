tableextension 55001 "SQU General Ledger Journal" extends "Gen. Journal Line"
{
    fields
    {
        field(50100; Description2; text[50])
        {
            Caption = 'Description 2';
            Editable = false;
            DataClassification = ToBeClassified;
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