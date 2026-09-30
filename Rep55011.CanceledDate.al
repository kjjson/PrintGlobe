namespace Squire.Sales;

using Microsoft.Sales.Document;

/// <summary>
/// Processing-only report. Defines a minimal, empty request page (no filter fields on
/// it) rather than omitting requestpage entirely — leaving requestpage out lets BC fall
/// back to an auto-generated default request page that echoes the DataItemTableView's
/// "CM Closed Date" = const(0D) filter back into a Date input box as blank text, and
/// re-parsing that blank text on OK is exactly what throws "The format of the Date ''''
/// does not match your device's date settings." when this is run interactively (e.g.
/// via Object Designer "Run"). The explicit empty request page below avoids that;
/// running from Job Queue with UseRequestPage(false) was never affected either way.
///
/// For every Sales Order where "CM Status" = 'Canceled' and "CM Closed Date" is still
/// blank, sets "CM Closed Date" to the date part of SystemModifiedAt (the date the
/// record was last modified). Records that already have a CM Closed Date are excluded
/// via the data item's own filter, so re-running this report is safe/idempotent — it
/// only ever touches records that are still blank.
///
/// NOTE: Renumber this report into your own object range before compiling — 50202 is
/// a placeholder. Adjust the namespace to match how your other Squire objects are organized.
/// </summary>
report 55011 "Squire Set CM Closed Date"
{
    Caption = 'Set CM Closed Date from Last Modified';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header"; "Sales Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order), "CM Status" = const('Canceled'), "CM Closed Date" = const(0D));

            trigger OnAfterGetRecord()
            begin
                "CM Closed Date" := DT2Date(SystemModifiedAt);
                Modify(true);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
            }
        }

        actions
        {
        }
    }
}