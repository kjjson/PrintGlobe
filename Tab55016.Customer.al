tableextension 55016 CustomerExtension extends Customer
{
    fields
    {
        field(50100; "Parent Company"; Code[20])
        {
            Caption = 'Parent Company';
            TableRelation = Customer."No."; // Lookup to Customer List
        }

        field(50101; "Revenue Share"; Decimal)
        {
            Caption = 'Revenue Share %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
        }

        field(50102; "Summary Invoice"; Boolean)
        {
            Caption = 'Summary Invoice';
        }
        field(50103; "Summary Invoice by PO"; Boolean)
        {
            Caption = 'Summary Invoice by PO';
        }
        field(50104; "Shipping in Rev Share"; Boolean)
        {
            Caption = 'Include Shipping in Rev Share';
        }
        field(50105; "Profit Multiplier"; Decimal)
        {
            Caption = 'Profit Multiplier %';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 100;
        }

    }
}