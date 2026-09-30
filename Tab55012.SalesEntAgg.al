tableextension 55012 "SQU Sales Inv Entity Agg" extends "Sales Invoice Entity Aggregate"
{
    fields
    {
        field(55002; "SQU Exported to CM"; Boolean)
        {
            Caption = 'Exported to CM';
            Description = 'Exported to CM';
            DataClassification = CustomerContent;
        }
        field(55003; "SQU CM Status"; Text[10])
        {
            Caption = 'CM Status';
            Description = 'CM Status';
            DataClassification = CustomerContent;
        }
        field(55004; "SQU Payment Reference"; Code[50]) // ✅ Renamed
        {
            Caption = 'SQU Payment Reference';
            DataClassification = SystemMetadata;
        }
        field(55005; "SQU Created"; DateTime)
        {
            Caption = 'Created Date';
            DataClassification = SystemMetadata;
        }
        field(55006; "CM Closed Date"; Date) // ✅ Matches Sales Header type
        {
            Caption = 'CM Closed Date';
            DataClassification = SystemMetadata;
        }
        field(55007; "SQU PO Number"; text[200])
        {
            Caption = 'PO Number';
            Description = 'PO Number';
            DataClassification = CustomerContent;
        }
        field(55010; "Master Job"; text[20])
        {
            Caption = 'Master Job';
            DataClassification = CustomerContent;
        }

    }
}
