codeunit 55011 "SQU Pro Forma Mgt."
{
    Permissions = TableData "Sales Header" = rm;
    // ============================================================
    // Route every call to the standard Pro Forma report (1302) to
    // the Squire version. This covers the built-in "Pro Forma
    // Invoice" action on Sales Order / Sales Invoice pages and
    // Report Selections, so users don't need a new button.
    // (Alternative without code: Report Selection - Sales,
    //  Usage = "Pro Forma S. Invoice" -> report 55021.)
    // ============================================================
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure SubstituteProFormaReport(
        ReportId: Integer;
        RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal;
        RequestPageXml: Text;
        RecordRef: RecordRef;
        var NewReportId: Integer)
    begin
        if ReportId = Report::"Standard Sales - Pro Forma Inv" then
            NewReportId := Report::"SQU Sales - Pro Forma Inv";
    end;

    // ============================================================
    // Parent customer resolution - same rule as posting in
    // codeunit 55001: use Customer."Parent Company" when it is set
    // and the parent exists. Returns false when there is no parent,
    // in which case the report keeps the standard bill-to address.
    // ============================================================
    procedure GetParentCustomer(SellToCust: Record Customer; var ParentCust: Record Customer): Boolean
    begin
        Clear(ParentCust);
        if SellToCust."Parent Company" = '' then
            exit(false);
        if SellToCust."Parent Company" = SellToCust."No." then
            exit(false);
        exit(ParentCust.Get(SellToCust."Parent Company"));
    end;

    // ============================================================
    // Revenue Share base-line rule - mirrors
    // "Sales Invoice Update".CalcRevenueShareAmounts, but evaluated
    // against an unposted Sales Line:
    //   * G/L 40010, description not containing 'FEE'
    //   * G/L 40020 (only when Customer."Shipping in Rev Share"),
    //     description not containing 'FEE'
    // ============================================================
    procedure IsRevShareBaseLine(SalesLine: Record "Sales Line"; Cust: Record Customer): Boolean
    begin
        if Cust."Revenue Share" <= 0 then
            exit(false);
        if SalesLine.Type <> SalesLine.Type::"G/L Account" then
            exit(false);
        if StrPos(UpperCase(SalesLine.Description), 'FEE') <> 0 then
            exit(false);

        case SalesLine."No." of
            '40010':
                exit(true);
            '40020':
                exit(Cust."Shipping in Rev Share");
        end;
        exit(false);
    end;

    procedure CalcRevShareFromBase(
        Cust: Record Customer;
        RevShareBase: Decimal;
        var RevSharePercent: Decimal;
        var RevShareAmount: Decimal): Boolean
    begin
        RevSharePercent := 0;
        RevShareAmount := 0;

        if (Cust."Revenue Share" <= 0) or (RevShareBase = 0) then
            exit(false);

        RevSharePercent := Cust."Revenue Share";
        RevShareAmount := Round(RevShareBase * (Cust."Revenue Share" / 100), 0.01);
        exit(true);
    end;

    // ============================================================
    // Flag the document. Uses its own record variable so the report's
    // Header record isn't touched, and Modify(false) so Sales Header
    // OnModify logic (status checks, etc.) doesn't fire on a released
    // order just because a report printed.
    // ============================================================
    procedure MarkProFormaPrinted(SalesHeader: Record "Sales Header")
    var
        SalesHeaderToUpdate: Record "Sales Header";
    begin
        if not SalesHeaderToUpdate.Get(SalesHeader."Document Type", SalesHeader."No.") then
            exit;
        if SalesHeaderToUpdate."Printed Pro Forma" then
            exit;

        SalesHeaderToUpdate."Printed Pro Forma" := true;
        SalesHeaderToUpdate.Modify(false);
    end;
}