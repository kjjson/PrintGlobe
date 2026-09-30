tableextension 55010 "SQU Purch Line" extends "Purchase Line"
{
    fields
    {
       field(55002; "Exported To CM"; Boolean)
        {
            Description = 'Exported to CM';
            Caption = 'Exported to CM';
            DataClassification = CustomerContent;
        }// Add changes to table fields here
        field(55003; "CM Line Number"; Integer)
        {
            Description = 'CM Line Number';
            Caption = 'CM Line Number';
            DataClassification = CustomerContent;
        }
      
    }

}