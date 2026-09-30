page 55001 "Job Dimension Values API"
{
    PageType = API;
    APIPublisher = 'Squire';
    APIGroup = 'CustomAPI';
    APIVersion = 'v1.0';
    EntityName = 'JobDimensionValue';
    EntitySetName = 'JobDimensionValues';
    SourceTable = "Dimension Value";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code";Rec.Code)
                {
                    Caption = 'Dimension Value Code';
                    ApplicationArea = All;
                }
               
                field("Name"; Rec."Name")
                {
                    Caption = 'Dimension Value Name';
                }
                field("DimensionCode"; Rec."Dimension Code")
                {
                    Caption = 'Dimension Code';
                    ApplicationArea = All;
                }
               
            }
        }
    }

}
