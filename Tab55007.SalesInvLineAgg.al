tableextension 55007 "SQU Sales Invoice Line Agg." extends "Sales Invoice Line Aggregate"
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
    }

}