namespace Squire.Sales;

using Microsoft.Sales.Document;

/// <summary>
/// Meant to be run from a recurring Job Queue Entry (Object Type to Run = Codeunit,
/// Object ID to Run = this codeunit's ID). Fully posts (ships + invoices) every Sales
/// Order where "CM Status" = 'Billed' and Amount >= 0, using that order's own
/// "CM Closed Date" as its Posting Date, Document Date, and Tax Date.
///
/// Because "CM Closed Date" can differ order to order, each qualifying order is posted
/// with its own call to the batch post report (report 296's InitializeRequest only
/// accepts one date per call, so a single shared-date batch run won't work here).
/// Orders are snapshotted into a temporary table first, then posted one at a time from
/// that snapshot — posting deletes the Sales Header row, so iterating the live,
/// filtered recordset directly while posting is unsafe.
///
/// A qualifying order with zero Sales Lines can't post (BC rejects posting an order
/// with no lines), so before posting, each order is checked and, if it has no lines,
/// given a single G/L Account 40010 line with Quantity = 1 purely so it will post.
///
/// NOTE: Renumber this codeunit into your own object range before compiling — 50200 is
/// a placeholder. Adjust the namespace to match how your other Squire objects are organized.
/// </summary>
codeunit 55008 "Squire Post Billed CM Orders"
{
    trigger OnRun()
    begin
        PostBilledCMOrders();
    end;

    local procedure PostBilledCMOrders()
    var
        SalesHeader: Record "Sales Header";
        OrdersToPost: Record "Sales Header" temporary;
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("CM Status", 'Billed');
        SalesHeader.SetFilter(Amount, '>=%1', 0);
        SalesHeader.SetFilter("CM Closed Date", '<>%1', 0D);
        // Orders matching CM Status/Amount but with a blank CM Closed Date are skipped
        // (there's no date to post them with) rather than defaulted to today — remove
        // the filter above if you'd rather fall back to WorkDate()/Today() for those.

        if SalesHeader.FindSet() then
            repeat
                OrdersToPost := SalesHeader;
                OrdersToPost.Insert();
            until SalesHeader.Next() = 0;

        if not OrdersToPost.FindSet() then
            exit;

        repeat
            EnsureOrderHasLine(OrdersToPost."Document Type", OrdersToPost."No.");
            PostSingleOrder(OrdersToPost."No.", OrdersToPost."CM Closed Date");
        until OrdersToPost.Next() = 0;
    end;

    /// <summary>
    /// If the order has no Sales Lines at all, adds a single G/L Account 40010 line
    /// with Quantity = 1 so the document has something to post. Leaves orders that
    /// already have at least one line untouched.
    /// </summary>
    local procedure EnsureOrderHasLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        if not SalesLine.IsEmpty() then
            exit;

        SalesLine.Init();
        SalesLine."Document Type" := DocumentType;
        SalesLine."Document No." := DocumentNo;
        SalesLine."Line No." := 10000;
        SalesLine.Insert(true);

        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", '40010');
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);
    end;

    local procedure PostSingleOrder(OrderNo: Code[20]; ClosedDate: Date)
    var
        SingleOrder: Record "Sales Header";
        BatchPostSalesOrders: Report "Batch Post Sales Orders";
    begin
        SingleOrder.SetRange("Document Type", SingleOrder."Document Type"::Order);
        SingleOrder.SetRange("No.", OrderNo);

        Clear(BatchPostSalesOrders);
        BatchPostSalesOrders.SetTableView(SingleOrder);
        BatchPostSalesOrders.InitializeRequest(
            true,           // Ship
            true,           // Invoice
            ClosedDate,     // Posting Date
            ClosedDate,     // Tax Date (VAT Date field, captioned "Tax Date" in US localization)
            true,           // Replace Posting Date
            true,           // Replace Document Date
            true,           // Replace Tax Date (Replace VAT Date)
            false);         // Calc. Inv. Discount
        BatchPostSalesOrders.UseRequestPage(false);
        BatchPostSalesOrders.RunModal();
    end;
}