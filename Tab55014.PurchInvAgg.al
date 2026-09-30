tableextension 55014 "SQU Purch Inv Entity Agg" extends "Purch. Inv. Entity Aggregate"
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
       
        field(55005; "SQU Created"; DateTime)
        {
            Caption = 'Created Date';
            DataClassification = SystemMetadata;
        }
    }

}