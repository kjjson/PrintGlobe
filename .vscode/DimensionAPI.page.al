page 55003 "Dimension Value API"
{
    PageType = API;
    APIPublisher = 'Squire';
    APIGroup = 'squire';
    APIVersion = 'v2.0';
    EntityName = 'dimensionValue';
    EntitySetName = 'dimensionValues';
    SourceTable = "Dimension Value";
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = true;
    ModifyAllowed = true;


    DelayedInsert = true;
    Permissions = tabledata "Dimension Value" = RM;

    layout
    {
        area(content)
        {
            group(Group)
            {
                field(Code; Rec."Code") { }
                field(Name; Rec."Name") { }
                field("DimensionCode"; Rec."Dimension Code") { }
                field(Blocked; Rec.Blocked) { }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Validate that the Dimension Code exists, etc.
        Rec.Validate("Dimension Code");
        Rec.Validate(Code);
    end;
}
