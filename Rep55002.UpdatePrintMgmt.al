report 55002 "Update Invoice Print Mgmt"
{
    Caption = 'Update Invoice Printing Management';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(InvPrintMgmt; "Invoice Printing Management")
        {
            trigger OnAfterGetRecord()
            var
                Cust, ParentCust : Record Customer;
                SalesInvHdr: Record "Sales Invoice Header";
                NewParentNo: Code[20];
                NewSummaryInvoice: Boolean;
                SalesInvUpdate: Codeunit "Sales Invoice Update";
            begin
                if not Cust.Get(InvPrintMgmt."Customer No.") then
                    exit;

                if Cust."Parent Company" <> '' then begin
                    NewParentNo := Cust."Parent Company";
                    if ParentCust.Get(NewParentNo) then
                        NewSummaryInvoice := ParentCust."Summary Invoice"
                    else
                        NewSummaryInvoice := Cust."Summary Invoice";
                end else begin
                    NewParentNo := Cust."No.";
                    NewSummaryInvoice := Cust."Summary Invoice";
                end;

                if (InvPrintMgmt."Parent Customer No." <> NewParentNo) or
                   (InvPrintMgmt."Summary Invoice" <> NewSummaryInvoice)
                then begin
                    InvPrintMgmt."Parent Customer No." := NewParentNo;
                    InvPrintMgmt."Summary Invoice" := NewSummaryInvoice;
                    InvPrintMgmt.Modify(true);
                end;

                if (InvPrintMgmt."Document Type" = InvPrintMgmt."Document Type"::Invoice) and
                   SalesInvHdr.Get(InvPrintMgmt."Document No.")
                then
                    if (InvPrintMgmt."SQU PO Number" <> SalesInvHdr."SQU PO Number") or
                       (InvPrintMgmt."CM Closed Date" <> SalesInvHdr."CM Closed Date")
                    then begin
                        InvPrintMgmt."SQU PO Number" := SalesInvHdr."SQU PO Number";
                        InvPrintMgmt."CM Closed Date" := SalesInvHdr."CM Closed Date";
                        InvPrintMgmt.Modify(true);
                    end;

                SalesInvUpdate.RecalcRevenueShare(InvPrintMgmt);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Group)
                {
                    field(UpdateConfirm; UpdateConfirm)
                    {
                        Caption = 'Confirm Update';
                        ApplicationArea = All;
                        ToolTip = 'Check this to confirm running the update.';
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if (CloseAction = Action::OK) and (not UpdateConfirm) then
                Error('You must confirm the update before proceeding.');
        end;
    }

    var
        UpdateConfirm: Boolean;

    trigger OnPostReport()
    begin
        Message('Invoice Printing Management records have been updated successfully.');
    end;
}