report 55006 "Backfill Ext. Doc No. Inv Mgmt"
{
    Caption = 'Backfill External Document No. on Invoice Printing Management';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(InvPrintMgmt; "Invoice Printing Management")
        {
            trigger OnPreDataItem()
            begin
                SetRange("Document Type", "Document Type"::Invoice);
            end;

            trigger OnAfterGetRecord()
            var
                SalesInvHeader: Record "Sales Invoice Header";
            begin
                // Skip if already populated
                if InvPrintMgmt."External Document No." <> '' then begin
                    SkippedCount += 1;
                    exit;
                end;

                // Skip if the posted invoice no longer exists
                if not SalesInvHeader.Get(InvPrintMgmt."Document No.") then begin
                    MissingCount += 1;
                    exit;
                end;

                // Nothing to write — posted invoice has no external doc no.
                if SalesInvHeader."External Document No." = '' then begin
                    SkippedCount += 1;
                    exit;
                end;

                InvPrintMgmt."External Document No." := SalesInvHeader."External Document No.";
                InvPrintMgmt.Modify(true);
                UpdatedCount += 1;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(OverwriteExisting; OverwriteExisting)
                    {
                        Caption = 'Overwrite Existing Values';
                        ApplicationArea = All;
                        ToolTip = 'If enabled, existing External Document No. values will be overwritten with the value from the posted invoice.';
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if CloseAction = Action::OK then
                if not Confirm('This will update External Document No. on Invoice Printing Management records. Continue?') then
                    Error('');
        end;
    }

    var
        OverwriteExisting: Boolean;
        UpdatedCount: Integer;
        SkippedCount: Integer;
        MissingCount: Integer;

    trigger OnPostReport()
    begin
        Message(
            'Backfill complete.\n\nUpdated:  %1\nSkipped:  %2\nMissing:  %3',
            UpdatedCount,
            SkippedCount,
            MissingCount);
    end;
}