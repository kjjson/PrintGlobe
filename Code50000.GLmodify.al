codeunit 55000 "GL Description"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePurchInvLineInsert', '', true, true)]
    local procedure OnBeforePurchInvLineInsert(var PurchInvLine: Record "Purch. Inv. Line"; PurchaseLine: Record "Purchase Line")
    begin
        PurchInvLine."Description 2" := PurchaseLine."Description 2";

    end;


    // [EventSubscriber(ObjectType::Table, Database::"Invoice Post. Buffer", OnAfterInvPostBufferPreparePurchase, '', false, false)]
    // local procedure OnAfterInvPostBufferPreparePurchase(var PurchaseLine: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    // begin
    //     InvoicePostBuffer.Description2 := PurchaseLine."Description 2";
    // end;




    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post",OnBeforePostInvPostBuffer , '', false, false)]
    // local procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var PurchHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var GenJnlLineDocNo: code[20]);
    // begin

    //     GenJnlLine.Description2 := InvoicePostBuffer.Description2;
    // end;

    [EventSubscriber(
        ObjectType::Table,
        Database::"Purch. Inv. Line",
        'OnAfterInsertEvent',
        '',
        false,
        false)]
    local procedure PurchInvLineOnAfterInsert(
        var Rec: Record "Purch. Inv. Line";
        RunTrigger: Boolean)
    var
        PurchLine: Record "Purchase Line";
    begin
        // Only lines created from a Purchase Order
        if (Rec."Order No." = '') or (Rec."Order Line No." = 0) then
            exit;

        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("Document No.", Rec."Order No.");
        PurchLine.SetRange("Line No.", Rec."Order Line No.");

        if PurchLine.FindFirst() then begin
            if PurchLine."Description 2" <> '' then begin
                Rec."Description 2" := PurchLine."Description 2";
                Rec.Modify();
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeInsertGlobalGLEntry, '', false, false)]
    local procedure OnBeforeInsertGlobalGLEntry(var GlobalGLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; GLRegister: Record "G/L Register");
    begin

        GlobalGLEntry.Description2 := GenJournalLine.Description2;
    end;



    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", OnPostLinesOnBeforeGenJnlLinePost, '', false, false)]

    // local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean);
    // begin
    //   //  TempInvoicePostingBuffer.Description2 := PurchHeader."Description 2";
    //   message('Did this run'+PurchHeader."Buy-from Vendor Name");
    //     GenJnlLine.Description2 := PurchHeader."Posting Description";
    // end;

    // [EventSubscriber(ObjectType::Table, Database::"Invoice Posting Buffer", OnAfterPreparePurchase, '', false, false)]
    // local procedure OnAfterPreparePurchase(var InvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var PurchaseLine: Record "Purchase Line")
    // begin

    //      InvoicePostingBuffer.Description2:= PurchaseLine."Description 2";
    // message('Buffer' +InvoicePostingBuffer.Description2);
    // end;






}
