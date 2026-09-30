query 55001 "Summary-Invoice Query"
{
    Caption = 'Summary Invoice PrintManagement with Invoices and Lines';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(InvPrint; "Invoice Printing Management")
        {
            column(SummaryInvoiceNo; "Summary Invoice No.") { }
            column(DocNo; "Document No.") { }
            column(Parent_Customer_No_; "Parent Customer No.") { }
            column(Revenue_Share_Amount; "Revenue Share Amount") { }
            column(Profit_Multiplier_Amount; "Profit Multiplier Amount") { }
            column(Parent_Customer_Name; "Parent Customer Name") { }
            column(Customer_Name; "Customer Name") { }

            dataitem(SalesInvHead; "Sales Invoice Header")
            {
                DataItemLink = "No." = InvPrint."Document No.";
                SqlJoinType = InnerJoin;

                // Header fields
                column(Header_No; "No.") { }
                column(Document_Date; "Document Date") { }
                column(Header_CustomerNo; "Sell-to Customer No.") { }
                column(External_Document_No_; "External Document No.") { }
                column(SQU_PO_Number; "SQU PO Number") { }


                dataitem(SalesInvLine; "Sales Invoice Line")
                {
                    DataItemLink = "Document No." = SalesInvHead."No.";
                    SqlJoinType = InnerJoin;

                    // Line fields
                    column(Line_No; "Line No.") { }
                    column(Line_Description; Description) { }
                    column(Line_Quantity; Quantity) { }
                    column(Line_Amount; Amount) { }
                    column(Unit_Price; "Unit Price") { }
                    column(GLNo; "No.") { }

                    dataitem(Cust; Customer)
                    {
                        // ✔ Corrected - no extra quote
                        DataItemLink = "No." = SalesInvLine."Sell-to Customer No.";
                        SqlJoinType = InnerJoin;

                        column(Cust_No; "No.") { }
                        column(Cust_Name; Name) { }
                        column(Cust_Address; Address) { }
                        column(Cust_Address_2; "Address 2") { }
                        column(Cust_City; City) { }
                        column(Cust_County; County) { }
                        column(Cust_Post_Code; "Post Code") { }
                        column(Cust_Email; "E-Mail") { }
                        column(Cust_Phone; "Phone No.") { }
                    }
                }
            }
        }
    }
}