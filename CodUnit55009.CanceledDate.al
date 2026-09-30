namespace Squire.Sales;

/// <summary>
/// Thin wrapper so the Job Queue Entry points at a Codeunit instead of the Report
/// directly. When a Job Queue Entry's "Object Type to Run" is Report, BC captures and
/// stores that report's request page parameters (filters/options) as XML the first
/// time you set the entry up, and replays that stored XML on every future run — it does
/// not recapture fresh values just because the report's source was republished. If a
/// blank/invalid Date value ever got baked into that stored XML (e.g. from an earlier
/// version of the report's request page), every subsequent run keeps failing with the
/// same "date format" error even after the report itself is fixed, because the Job
/// Queue Entry is replaying its old stored parameters, not re-reading the report.
///
/// Routing through this codeunit sidesteps that mechanism entirely: Object Type to Run
/// = Codeunit never stores/replays report request page parameters, and
/// UseRequestPage(false) here means the report's request page (empty or not) is never
/// touched at run time.
///
/// Point your Job Queue Entry's Object Type to Run = Codeunit, Object ID to Run = this
/// codeunit's ID, and delete/recreate the old entry that pointed directly at report
/// "Squire Set CM Closed Date" so it isn't replaying stale stored parameters.
///
/// NOTE: Renumber this codeunit into your own object range before compiling — 50203 is
/// a placeholder.
/// </summary>
codeunit 55009 "Squire Set CM Closed Date JQ"
{
    trigger OnRun()
    var
        SetCMClosedDate: Report "Squire Set CM Closed Date";
    begin
        SetCMClosedDate.UseRequestPage(false);
        SetCMClosedDate.RunModal();
    end;
}