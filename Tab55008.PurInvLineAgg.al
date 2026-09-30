tableextension 55009 "SQU Purch Invoice Line Agg." extends "Purch. Inv. Line Aggregate"
{
    fields
    {
       field(55002; "SQU Exported to CM"; Boolean)
        {
            Caption = 'Exported to CM';
            Description = 'Exported to CM';
            DataClassification = CustomerContent;
        }
       field(55003; "CM Line Number"; Integer)
        {
            Description = 'CM Line Number';
            Caption = 'CM Line Number';
            DataClassification = CustomerContent;
    }
    field(55004; "SQU Shortcut Dim 1"; code[40])
    {
        Description = 'Shortcut Dim 1';
        DataClassification = SystemMetadata;
    }
    field(55005; "SQU Shortcut Dim 2"; code[40])
    {
        Description = 'Shortcut Dim 2';
        DataClassification = SystemMetadata;
    }
    }

}