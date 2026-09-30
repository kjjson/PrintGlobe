// ============================================================================
// Wires PJ Cash Receipt Import (codeunit 50200 - renumber to match) onto the
// standard Cash Receipt Journal page as a "Import PayJunction CSV" action.
// Object ID 50200 is a PLACEHOLDER - renumber into your own range, and update
// the codeunit reference below if you renumber the codeunit itself.
// ============================================================================

pageextension 55013 "PJ Cash Receipt Journal Ext" extends "Cash Receipt Journal"
{
    actions
    {
        addlast(Processing)
        {
            action(ImportPayJunctionCsv)
            {
                ApplicationArea = All;
                Caption = 'Import PayJunction CSV';
                ToolTip = 'Imports a PayJunction Cash Receipts export into this journal batch, matching each row to a customer by looking up its invoice number against posted Sales Invoice External Document No.';
                Image = ImportDatabase;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    PJCashReceiptImport: Codeunit "PJ Cash Receipt Import";
                    GenJournalBatch: Record "Gen. Journal Batch";
                    ApplyToInvoice: Boolean;
                begin
                    if not GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                        Error('Could not find the current journal batch.');

                    ApplyToInvoice := Confirm('Also apply each payment to its matched invoice (Applies-to Doc. No.)?', true);
                    PJCashReceiptImport.ImportFile(GenJournalBatch, ApplyToInvoice);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}