page 55022 "Job Margin Results"
{
    PageType = List;
    SourceTable = "Job Margin Buffer";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Job Margin Results';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Job Code"; Rec."Job Code")
                {
                    ApplicationArea = All;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        GLEntry.SetRange("Global Dimension 2 Code", Rec."Job Code");
                        GLEntry.SetFilter("G/L Account No.", '4*|5*|1017*');

                        Page.Run(Page::"General Ledger Entries", GLEntry);
                    end;
                }
                field(Revenue; Rec.Revenue)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                }
                field(Costs; Rec.Costs)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                }
                field(Margin; Rec.Margin)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                }
                field(WIP; Rec.WIP)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RefreshData)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;

                trigger OnAction()
                begin
                    LoadData();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadData();
    end;

    local procedure LoadData()
    var
        JobMarginMgt: Codeunit "Job Margin Mgt.";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        JobMarginMgt.LoadJobMargins(Rec);
        CurrPage.Update(false);
    end;
}