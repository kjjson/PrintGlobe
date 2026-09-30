report 55008 "Archive Printed Inv Print Mgmt"
{
    Caption = 'Archive Printed Invoice Printing Management Records';
    ProcessingOnly = true;
    ApplicationArea = All;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(InvPrintMgmt; "Invoice Printing Management")
        {
            trigger OnPreDataItem()
            begin
                SetRange("Emailed", true);
            end;

            trigger OnAfterGetRecord()
            var
                Archive: Record "Invoice Print Mgmt Archive";
            begin
                // Copy to archive table
                Archive.Init();
                Archive."Document No." := "Document No.";
                Archive."Document Type" := "Document Type";
                Archive."Customer No." := "Customer No.";
                Archive."Summary Invoice" := "Summary Invoice";
                Archive."Summary Invoice No." := "Summary Invoice No.";
                Archive."Parent Customer No." := "Parent Customer No.";
                Archive."Printed Count" := "Printed Count";
                Archive."Revenue Share Amount" := "Revenue Share Amount";
                Archive."Revenue Share Base Amount" := "Revenue Share Base Amount";
                Archive."Revenue Share Percent" := "Revenue Share Percent";
                Archive."Profit Multiplier Amount" := "Profit Multiplier Amount";
                Archive."Profit Multiplier Base Amount" := "Profit Multiplier Base Amount";
                Archive."Profit Multiplier Percent" := "Profit Multiplier Percent";
                Archive."Emailed" := "Emailed";

                Archive."Emailed Date" := "Emailed Date";
                Archive."SQU PO Number" := "SQU PO Number";
                Archive."CM Closed Date" := "CM Closed Date";
                Archive."Archived Date" := CurrentDateTime();


                // Resolve FlowFields before archiving
                CalcFields("External Document No.", "Posting Date");
                Archive."External Document No." := "External Document No.";
                Archive."Posting Date" := "Posting Date";

                if Archive.Insert(true) then
                    ArchivedCount += 1;

                Mark(true);
            end;

            trigger OnPostDataItem()
            begin
                MarkedOnly(true);
                DeleteAll(true);
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
                    field(ConfirmArchive; ConfirmArchive)
                    {
                        Caption = 'Confirm Archive';
                        ApplicationArea = All;
                        ToolTip = 'Check this to confirm moving emailed records to the archive.';
                    }
                }
            }
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if (CloseAction = Action::OK) and (not ConfirmArchive) then
                Error('You must confirm the archive operation before proceeding.');
        end;
    }

    var
        ConfirmArchive: Boolean;
        ArchivedCount: Integer;

    trigger OnPostReport()
    begin
        Message('%1 record(s) archived and removed from Invoice Printing Management.', ArchivedCount);
    end;
}