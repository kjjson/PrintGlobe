codeunit 55003 "Create CM From Neg Orders"

{

    Subtype = Normal;

    trigger OnRun()
    begin
        ProcessNegativeOrders();
    end;

    local procedure ProcessNegativeOrders()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeaderCredit: Record "Sales Header";
        SalesLineCredit: Record "Sales Line";
        TotalAmount: Decimal;
        NextLineNo: Integer;
    begin
        // Only Released Sales Orders
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        
    //    SalesHeader.SetRange(Status, SalesHeader.Status::Released);
    // Filter by CM Status = Billed or Canceled
        SalesHeader.SetFilter("CM Status", '%1|%2', 'Billed', 'Canceled');
        SalesHeader.SetRange("Your Reference", ''); // Only unprocessed orders

        if SalesHeader.FindSet() then
            repeat
                // Calculate total amount
                TotalAmount := 0;
                SalesLine.Reset();
                SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                SalesLine.SetRange("Document No.", SalesHeader."No.");
                if SalesLine.FindSet() then
                    repeat
                        TotalAmount += SalesLine."Line Amount";
                    until SalesLine.Next() = 0;

                if TotalAmount < 0 then begin
                    Message('Creating Credit Memo for %1 (Total %2)', SalesHeader."No.", TotalAmount);

                    // --- Create Credit Memo Header ---
                    Clear(SalesHeaderCredit);
                    SalesHeaderCredit.Init();
                    SalesHeaderCredit.Validate("Document Type", SalesHeaderCredit."Document Type"::"Credit Memo");
                    SalesHeaderCredit.Insert(true); // Assigns new No. from No. Series
                    SalesHeaderCredit.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
                    SalesHeaderCredit.Validate("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
                    SalesHeaderCredit.Validate("Posting Date", SalesHeader."Posting Date");
                    SalesHeaderCredit.Validate("Document Date", SalesHeader."Document Date");
                    SalesHeaderCredit.Validate("Currency Code", SalesHeader."Currency Code");
                    SalesHeaderCredit.Validate("CM Status", SalesHeader."CM Status");
                    SalesHeaderCredit.Validate("Salesperson Code", SalesHeader."Salesperson Code");
                    SalesHeaderCredit.Validate("Document Date", SalesHeader."Document Date");
                    SalesHeaderCredit.Validate("External Document No.", SalesHeader."External Document No."); // Link for traceability
                    SalesHeaderCredit.Modify(true);

                    // --- Copy Lines ---
                    SalesLine.Reset();
                    SalesLine.SetRange("Document Type", SalesHeader."Document Type");
                    SalesLine.SetRange("Document No.", SalesHeader."No.");

                    if SalesLine.FindSet() then begin
                        NextLineNo := 10000;
                        repeat
                            Clear(SalesLineCredit);
                            SalesLineCredit.Init();
                            SalesLineCredit.Validate("Document Type", SalesHeaderCredit."Document Type");
                            SalesLineCredit.Validate("Document No.", SalesHeaderCredit."No.");
                            SalesLineCredit."Line No." := NextLineNo;

                            SalesLineCredit.Validate(Type, SalesLine.Type);
                            if SalesLine.Type <> SalesLine.Type::" " then
                                SalesLineCredit.Validate("No.", SalesLine."No.");

                            SalesLineCredit.Validate(Description, SalesLine.Description);
                            SalesLineCredit.Validate(Quantity, SalesLine.Quantity);
                            SalesLineCredit.Validate("Unit Price", -1*SalesLine."Unit Price");
                            SalesLineCredit.Validate("Line Discount %", SalesLine."Line Discount %");
                            SalesLineCredit.Validate("Shortcut Dimension 2 Code", SalesLine."Shortcut Dimension 2 Code");
                            

                            SalesLineCredit.Insert(true);

                            NextLineNo += 10000;
                        until SalesLine.Next() = 0;
                    end;

                    // Mark original order as processed
                    SalesHeader."Your Reference" := 'Converted to Credit Memo';
                    SalesHeader.Modify(true);
                end;
            until SalesHeader.Next() = 0;
    end;
}
