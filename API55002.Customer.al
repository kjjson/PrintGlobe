page 55002 "API - Customers"
{
    PageType = API;
    APIVersion = 'v2.0';
    APIGroup = 'squire';
    APIPublisher = 'squire';
    EntityName = 'customer';
    EntitySetName = 'customers';
    SourceTable = Customer;
    DelayedInsert = true;
    ODataKeyFields = "No.";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // Standard customer fields
                field(No; Rec."No.") { Editable = false; }
                field(Name; Rec.Name) { }
                field(Address; Rec.Address) { }
                field(City; Rec.City) { }
                field(PostCode; Rec."Post Code") { }
                field(PhoneNo; Rec."Phone No.") { }
                field(Email; Rec."E-Mail") { }
                field(CustomerPostingGroup; Rec."Customer Posting Group") { }
                field("GenBusPostingGroup"; Rec."Gen. Bus. Posting Group") { }
                field("PaymentMethodCode"; Rec."Payment Method Code") { }
                field("PaymentTermsCode"; Rec."Payment Terms Code") { }
                field("CFDICustomerName"; Rec."CFDI Customer Name") { }
                field("Address2"; Rec."Address 2") { }
                field(County; Rec.County) { }
                field("CountryCode"; Rec."Country/Region Code") { }
                field("RevenueShare"; Rec."Revenue Share") { }
                field("CreditLimit"; Rec."Credit Limit (LCY)") { }
                field("ParentCompany"; Rec."Parent Company") { }






                // Extended fields

            }
        }
    }
}
