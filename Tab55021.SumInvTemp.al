table 55002 "Temp Summary Invoice Filter"
{
    Caption = 'Temporary Summary Invoice Filter';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Summary Invoice No."; Code[20])
        {
            Caption = 'Summary Invoice No.';
        }
    }

    keys
    {
        key(PK; "Summary Invoice No.")
        {
            Clustered = true;
        }
    }

    // This table will always be temporary when used in the report
}
