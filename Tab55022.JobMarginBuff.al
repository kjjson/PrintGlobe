table 55022 "Job Margin Buffer"
{
    Caption = 'Job Margin Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job Code"; Code[20])
        {
            Caption = 'Job Code';
        }
        field(2; Costs; Decimal)
        {
            Caption = 'Costs';
            DecimalPlaces = 0 : 2;
        }
        field(3; Revenue; Decimal)
        {
            Caption = 'Revenue';
            DecimalPlaces = 0 : 2;
        }
        field(4; WIP; Decimal)
        {
            Caption = 'WIP';
            DecimalPlaces = 0 : 2;
        }
        field(5; Margin; Decimal)
        {
            Caption = 'Margin';
            DecimalPlaces = 0 : 2;
        }
    }

    keys
    {
        key(PK; "Job Code")
        {
            Clustered = true;
        }
    }
}