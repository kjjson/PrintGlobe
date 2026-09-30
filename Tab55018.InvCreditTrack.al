table 55018 "Revenue Share Tracking"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Customer No."; Code[20])
        {
            DataClassification = CustomerContent;
        }

        field(3; "Invoice No."; Code[20])
        {
            DataClassification = CustomerContent;
        }

        field(4; "Revenue Credit Created"; Boolean)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
