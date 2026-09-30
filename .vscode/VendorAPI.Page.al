
page 55000 VendorAPI
{
    APIGroup = 'Squire';
    APIPublisher = 'Squire';
    APIVersion = 'v2.0';
    ApplicationArea = All;
    Caption = 'vendorAPI';
    DelayedInsert = true;
    EntityName = 'Vendor';
    EntitySetName = 'Vendors';
    PageType = API;
    SourceTable = Vendor;
    
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(address; Rec.Address)
                {
                    Caption = 'Address';
                }
                field(address2; Rec."Address 2")
                {
                    Caption = 'Address 2';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(postCode; Rec."Post Code")
                {
                    Caption = 'Post Code';
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    Caption = 'Country/Region Code';
                }
                field(county; Rec.County)
                {
                    Caption = 'County';
                }
                field(phoneNo; Rec."Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(defaultGLAccount; Rec."Default GL Account")
                {
                    Caption = 'Default GL Account';
                }
                field(Department; Rec."Global Dimension 2 Code")
                {
                    Caption = 'Department';
                }
            }
        }
    }
}
