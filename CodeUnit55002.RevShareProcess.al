codeunit 55002 "Revenue Share Processor"
{
    trigger OnRun()
    var
        RevShare: Record "Revenue Share Tracking";
    begin
        RevShare.SetRange("Revenue Credit Created", false);
        if RevShare.FindSet() then
            repeat
                CreateRevenueCredit(RevShare);
            until RevShare.Next() = 0;
    end;

 local procedure CreateRevenueCredit(var RevShare: Record "Revenue Share Tracking")
var
    SalesInvHeader: Record "Sales Invoice Header";
    SalesCrMemoHeader: Record "Sales Header";
    SalesInvLine: Record "Sales Invoice Line";
    SalesLine: Record "Sales Line";
    Cust: Record Customer;
    LineNo: Integer;
    Total40010Amount: Decimal;
    CreditAmount: Decimal;
begin
    if not SalesInvHeader.Get(RevShare."Invoice No.") then
        exit;
    if not Cust.Get(RevShare."Customer No.") then
        exit;

    // ============================================================
// 1️⃣ SUM LINES FOR G/L 40010 + (optionally) 40020
// ============================================================
Total40010Amount := 0;

// ---- Include 40010 always ----
SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
SalesInvLine.SetRange("No.", '40010');

if SalesInvLine.FindSet() then
    repeat
        // Skip lines that contain "License Fee"
        if StrPos(UpperCase(SalesInvLine.Description), 'LICENSE FEE') = 0 then
            Total40010Amount += SalesInvLine."Line Amount";
    until SalesInvLine.Next() = 0;


// ---- Include 40020 only if customer setting allows ----
if Cust."Shipping in Rev Share" then begin
    SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
    SalesInvLine.SetRange(Type, SalesInvLine.Type::"G/L Account");
    SalesInvLine.SetRange("No.", '40020');

    if SalesInvLine.FindSet() then
        repeat
            // Skip lines that contain "License Fee"
            if StrPos(UpperCase(SalesInvLine.Description), 'LICENSE FEE') = 0 then
                Total40010Amount += SalesInvLine."Line Amount";
        until SalesInvLine.Next() = 0;
end;

// If no qualifying lines → exit
if Total40010Amount = 0 then
    exit;

// ============================================================
// 2️⃣ CALCULATE CREDIT MEMO AMOUNT
// ============================================================
CreditAmount := Total40010Amount * Cust."Revenue Share";


    // ============================================================
    // 3️⃣ CREATE CREDIT MEMO HEADER
    // ============================================================
    SalesCrMemoHeader.Init();
    SalesCrMemoHeader.Validate("Document Type", SalesCrMemoHeader."Document Type"::"Credit Memo");
    SalesCrMemoHeader.Validate("Sell-to Customer No.", Cust."No.");

    // Copy External Doc No. from original invoice
    SalesCrMemoHeader.Validate("External Document No.", SalesInvHeader."External Document No.");

    // Set Your Reference
    SalesCrMemoHeader.Validate("Your Reference",
        StrSubstNo('Revenue Share - %1', SalesInvHeader."No."));

    // Auto-apply to original invoice
    SalesCrMemoHeader.Validate("Applies-to Doc. Type", SalesCrMemoHeader."Applies-to Doc. Type"::Invoice);
    SalesCrMemoHeader.Validate("Applies-to Doc. No.", SalesInvHeader."No.");

    SalesCrMemoHeader.Insert(true);

    // ============================================================
    // 4️⃣ INSERT ONE SINGLE CREDIT MEMO LINE TO G/L ACCOUNT 40080
    // ============================================================
    LineNo := 10000;

    SalesLine.Init();
    SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
    SalesLine."Document No." := SalesCrMemoHeader."No.";
    SalesLine."Line No." := LineNo;

    SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
    SalesLine.Validate("No.", '40080');  // The credit G/L account

    SalesLine.Validate(Quantity, 1);     // One summary line
    SalesLine.Validate("Unit Price", CreditAmount); 

    SalesLine.Validate(Description,
        StrSubstNo('Revenue Share %1%% on Invoice %2',
            Cust."Revenue Share", SalesInvHeader."No."));

    SalesLine.Insert(true);

    // ============================================================
    // 5️⃣ MARK AS CREATED
    // ============================================================
    RevShare."Revenue Credit Created" := true;
    RevShare.Modify();
end;


}
