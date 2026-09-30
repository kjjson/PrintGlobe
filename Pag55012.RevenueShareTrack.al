page 55014 "Revenue Share Tracking"
{
    PageType = List;
    SourceTable = "Revenue Share Tracking";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Customer No."; rec."Customer No.") { ApplicationArea = All; }
                field("Invoice No."; rec."Invoice No.") { ApplicationArea = All; }
                field("Revenue Credit Created"; rec."Revenue Credit Created") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RunRevenueShare)
            {
                Caption = 'Create Revenue Credits';
                ApplicationArea = All;
                Image = Process;

                trigger OnAction()
                var
                    RevProcessor: Codeunit "Revenue Share Processor";
                begin
                    RevProcessor.Run();
                    Message('Revenue Share credit memos created successfully.');
                end;
            }
        }
    }
}
