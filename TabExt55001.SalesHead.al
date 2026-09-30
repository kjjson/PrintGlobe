tableextension 55004 "SalesHeaderExt" extends "Sales Header"
{
    fields
    {
        modify("Prepayment %")
        {
            trigger OnAfterValidate()
            begin

            end;
        }
        field(50001; "Exported To CM"; Boolean)
        {
            Description = 'Exported to CM';
            Caption = 'Exported to CM';
            DataClassification = CustomerContent;
        }// Add changes to table fields here


        field(55001; "SQU PaymentPercentage"; Integer)
        {
            Caption = 'Payment Percentage';
            DataClassification = SystemMetadata;
        }
        field(55003; "CM Status"; text[10])
        {
            Caption = 'CM Status';
            DataClassification = SystemMetadata;
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
        field(55008; "Summary Invoice"; Boolean)
        {
            Caption = 'Summary Invoice';
            DataClassification = CustomerContent;
        }

        field(55009; "Summary Invoice by PO"; Boolean)
        {
            Caption = 'Summary Invoice by PO';
            DataClassification = CustomerContent;
        }
        field(55010; "Master Job"; text[20])
        {
            Caption = 'Master Job';
            DataClassification = CustomerContent;
        }
        field(55030; "Printed Pro Forma"; Boolean)
        {
            Caption = 'Printed Pro Forma';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies that a pro forma invoice has been printed, emailed or saved for this document. Set automatically by the pro forma report (not set on preview).';
        }

    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}