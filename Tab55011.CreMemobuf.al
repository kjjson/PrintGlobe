tableextension 55011 "SQU Cre Memo Entity Buffer" extends "Sales Cr. Memo Entity Buffer"
{
    fields
    {
        
        
        field(55002; "SQU Exported to CM"; Boolean)
        {
            Caption = 'Exported to CM';
            Description = 'Exported to CM';
            DataClassification = CustomerContent;
        }
        field(55003; "SQU CM Status"; text[10])
        {
            Caption = 'CM Status';
            Description = 'CM Status';
            DataClassification = CustomerContent;
        }
         field(55004; "SQU Created Date"; DateTime)
        {
            Caption = 'Created Date';
            Description = 'Created Date';
            DataClassification = CustomerContent;
        }
    }

}