query 55002 "Summary-Invoice CreditMemos"
{
    Caption = 'Credit Memos Related to Invoices by Job No.';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(InvPrint; "Invoice Printing Management")
        {
            column(SummaryInvoiceNo; "Summary Invoice No.") { }
            column(DocNo; "Document No.") { }

            dataitem(SalesInvHead; "Sales Invoice Header")
            {
                DataItemLink = "No." = InvPrint."Document No.";
                SqlJoinType = InnerJoin;

                column(External_Document_No_;"External Document No.") { }

                dataitem(SalesCrMemoHead; "Sales Cr.Memo Header")
                {
                    DataItemLink = "External Document No." = SalesInvHead."External Document No.";
                    SqlJoinType = InnerJoin;

                    column(CrMemo_No; "No.") { }
                    column(CrMemo_Date; "Posting Date") { }
                    column(CrMemo_CustomerNo; "Sell-to Customer No.") { }
                    column(CrMemo_External_Doc_No; "External Document No.") { }
                    column(Amount;Amount){}
                }
            }
        }
    }
}
