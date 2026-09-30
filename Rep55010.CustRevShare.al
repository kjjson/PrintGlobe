report 55010 "Update Cust. Revenue Share"
{
    Caption = 'Update Customer Revenue Share from Parent';
    ProcessingOnly = true;
    UsageCategory = Administration;
    ApplicationArea = All;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.", "Parent Company";
            DataItemTableView = sorting("No.") where("Parent Company" = filter(<> ''));

            trigger OnPreDataItem()
            begin
                UpdatedCount := 0;
                SkippedCount := 0;
                ErrorCount := 0;
            end;

            trigger OnAfterGetRecord()
            var
                ParentCustomer: Record Customer;
            begin
                // A customer should never be its own parent - guard against bad data
                if "Parent Company" = "No." then begin
                    ErrorCount += 1;
                    ErrorLog += StrSubstNo('%1: set as its own Parent Company - skipped.\', "No.");
                    CurrReport.Skip();
                    exit;
                end;

                if not ParentCustomer.Get("Parent Company") then begin
                    ErrorCount += 1;
                    ErrorLog += StrSubstNo('%1: Parent Company %2 not found - skipped.\', "No.", "Parent Company");
                    CurrReport.Skip();
                    exit;
                end;

                if "Revenue Share" = ParentCustomer."Revenue Share" then begin
                    SkippedCount += 1;
                    exit;
                end;

                "Revenue Share" := ParentCustomer."Revenue Share";
                Modify(true);
                UpdatedCount += 1;
            end;

            trigger OnPostDataItem()
            var
                ResultMsg: Text;
            begin
                ResultMsg := StrSubstNo('Revenue Share update complete.\Updated: %1\Already current: %2\Errors: %3', UpdatedCount, SkippedCount, ErrorCount);
                if ErrorCount > 0 then
                    ResultMsg += '\\Details:\' + ErrorLog;
                Message(ResultMsg);
            end;
        }
    }

    trigger OnPreReport()
    begin
        if not Confirm('This will update Revenue Share % on every customer that has a Parent Company assigned, copying the value from the parent record. Continue?', true) then
            CurrReport.Quit();
    end;

    var
        UpdatedCount: Integer;
        SkippedCount: Integer;
        ErrorCount: Integer;
        ErrorLog: Text;
}
