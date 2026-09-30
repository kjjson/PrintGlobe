report 55004 "Recalc Revenue Share"
{
    Caption = 'Recalculate Revenue Share';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(InvPrintMgmt; "Invoice Printing Management")
        {
            DataItemTableView =
                where("Document Type" = const(Invoice));

            trigger OnAfterGetRecord()
            var
                SalesInvHeader: Record "Sales Invoice Header";
                SalesInvLine: Record "Sales Invoice Line";
                Cust, ParentCust : Record Customer;
                ParentCustomerNo: Code[20];
                SummaryInvoiceFlag: Boolean;
                TotalShareBase: Decimal;
            begin
                // ----------------------------------------------------
                // Validate posted invoice exists
                // ----------------------------------------------------
                if not SalesInvHeader.Get("Document No.") then
                    exit;

                if not Cust.Get(SalesInvHeader."Sell-to Customer No.") then
                    exit;

                // ----------------------------------------------------
                // Parent / Summary Invoice logic (same as posting)
                // ----------------------------------------------------
                if Cust."Parent Company" <> '' then begin
                    ParentCustomerNo := Cust."Parent Company";
                    if ParentCust.Get(ParentCustomerNo) then
                        SummaryInvoiceFlag := ParentCust."Summary Invoice"
                    else
                        SummaryInvoiceFlag := Cust."Summary Invoice";
                end else begin
                    ParentCustomerNo := Cust."No.";
                    SummaryInvoiceFlag := Cust."Summary Invoice";
                end;

                // ----------------------------------------------------
                // Revenue Share validation
                // ----------------------------------------------------
                if Cust."Revenue Share" <= 0 then begin
                    ClearRevenueFields();
                    exit;
                end;

                TotalShareBase := 0;

                // ----------------------------------------------------
                // G/L Account 40010
                // ----------------------------------------------------
                SalesInvLine.Reset();
                SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
                SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
                SalesInvLine.SetRange("No.", '40010');

                if SalesInvLine.FindSet() then
                    repeat
                        if StrPos(UpperCase(SalesInvLine.Description), 'FEE') = 0 then
                            TotalShareBase += SalesInvLine."Line Amount";
                    until SalesInvLine.Next() = 0;

                // ----------------------------------------------------
                // G/L Account 40020 (Shipping)
                // ----------------------------------------------------
                if Cust."Shipping in Rev Share" then begin
                    SalesInvLine.Reset();
                    SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
                    SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
                    SalesInvLine.SetRange("No.", '40020');

                    if SalesInvLine.FindSet() then
                        repeat
                            if StrPos(UpperCase(SalesInvLine.Description), 'FEE') = 0 then
                                TotalShareBase += SalesInvLine."Line Amount";
                        until SalesInvLine.Next() = 0;
                end;

                if TotalShareBase = 0 then begin
                    ClearRevenueFields();
                    exit;
                end;

                // ----------------------------------------------------
                // Update Invoice Printing Management
                // ----------------------------------------------------
                "Customer No." := Cust."No.";
                "Parent Customer No." := ParentCustomerNo;
                "Summary Invoice" := SummaryInvoiceFlag;

                "Revenue Share Percent" := Cust."Revenue Share";
                "Revenue Share Base Amount" := TotalShareBase;
                "Revenue Share Amount" :=
                    Round(TotalShareBase * Cust."Revenue Share");

                Modify(true);
            end;
        }
    }

    local procedure ClearRevenueFields()
    begin

    end;
}
