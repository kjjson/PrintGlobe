tableextension 55005 "MNB Sales Order Entity Buffer" extends "Sales Order Entity Buffer"
{
    fields
    {

        field(55001; "SQU PaymentPercentage"; Integer)
        {
            Caption = 'Payment Percentage';
            DataClassification = SystemMetadata;
        }
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
        field(55006; "CM Closed Date"; Date)
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