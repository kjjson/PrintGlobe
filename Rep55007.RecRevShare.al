report 55007 "Recalc Revenue Share Amounts"
{
    Caption = 'Recalculate Revenue Share Amounts';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(InvPrintMgmt; "Invoice Printing Management")
        {
            trigger OnPreDataItem()
            begin
                // Only process records that have a revenue share percentage set
                SetFilter("Revenue Share Percent", '>0');
            end;

            trigger OnAfterGetRecord()
            var
                CorrectAmount: Decimal;
            begin
                CorrectAmount := Round(
                    "Revenue Share Base Amount" * ("Revenue Share Percent" / 100), 0.01);

                if "Revenue Share Amount" <> CorrectAmount then begin
                    "Revenue Share Amount" := CorrectAmount;
                    Modify(true);
                    UpdatedCount += 1;
                end else
                    SkippedCount += 1;
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

                    field(UpdateConfirm; UpdateConfirm)
                    {
                        Caption = 'Confirm Update';
                        ApplicationArea = All;
                        ToolTip = 'Check this to confirm running the recalculation.';
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
        UpdatedCount: Integer;
        SkippedCount: Integer;

    trigger OnPostReport()
    begin
        Message(
            'Recalculation complete.\n\nUpdated:  %1\nSkipped (already correct):  %2',
            UpdatedCount,
            SkippedCount);
    end;
}