page 55021 "Customer Refunds API"
{
    PageType = API;
    Caption = 'Customer Posted Refunds';
    APIPublisher = 'squire';
    APIGroup = 'squire';
    APIVersion = 'v2.0';
    EntityName = 'customerPostedRefund';
    EntitySetName = 'customerPostedRefunds';
    SourceTable = "Cust. Ledger Entry";
    DelayedInsert = true;




    SourceTableView = where("Document Type" = const(Refund));

    layout
    {
        area(Content)
        {
            field(id; rec."Entry No.")
            {
                Caption = 'ID';
                Editable = false;
            }
            field(customerNumber; rec."Customer No.")
            {
                Caption = 'Customer Number';
            }
            field(documentNumber; rec."Document No.")
            {
                Caption = 'Document Number';
            }
            field(postingDate; rec."Posting Date")
            {
                Caption = 'Posting Date';
            }
            field(amount; rec.Amount)
            {
                Caption = 'Amount';
            }
            field(remainingAmount; rec."Remaining Amount")
            {
                Caption = 'Remaining Amount';
            }
            field(currencyCode; rec."Currency Code")
            {
                Caption = 'Currency Code';
            }
            field(externalDocumentNo; rec."External Document No.")
            {
                Caption = 'External Document No.';
            }
            field(description; rec.Description)
            {
                Caption = 'Description';
            }
            field("CreatedDate"; Rec.SystemCreatedAt)
            {
                Caption = 'Created Date';
            }
        }
    }
}
