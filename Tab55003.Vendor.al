tableextension 55003 VendorExt extends Vendor
{
    fields
    {
        field(50100; "Default GL Account"; Code[20])
        {
            Caption = 'Default GL Account';
            TableRelation = "G/L Account"."No.";  // Lookup from Chart of Accounts
            DataClassification = ToBeClassified;
        }
    }
}