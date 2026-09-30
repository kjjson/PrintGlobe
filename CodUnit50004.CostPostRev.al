codeunit 55004 "CMJOB Reversal Handler"
{
    Subtype = Normal;

    [EventSubscriber(
        ObjectType::Codeunit,
        Codeunit::"Sales-Post",
        'OnAfterPostSalesDoc',
        '',
        false,
        false)]
    local procedure OnAfterPostSalesDoc(
        SalesHeader: Record "Sales Header";
        CommitIsSuppressed: Boolean)
    begin
        // Only Sales Orders
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
            exit;

        if SalesHeader."External Document No." = '' then
            exit;

        CreateReversalJournalLines(SalesHeader);
    end;

    local procedure CreateReversalJournalLines(SalesHeader: Record "Sales Header")
    var
        GLEntry: Record "G/L Entry";
        GenJnlLine: Record "Gen. Journal Line";
        NextLineNo: Integer;
    begin
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", SalesHeader."External Document No.");
        GLEntry.SetRange("Journal Batch Name", 'CMJOB');

        if not GLEntry.FindSet() then
            exit;

        NextLineNo := GetNextLineNo('GENERAL', 'CMJOBREV');

        repeat
            Clear(GenJnlLine);
            GenJnlLine.Init();

            GenJnlLine."Journal Template Name" := 'GENERAL';
            GenJnlLine."Journal Batch Name" := 'CMJOBREV';
            GenJnlLine."Line No." := NextLineNo;

            GenJnlLine."Posting Date" := SalesHeader."CM Closed Date";
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
            GenJnlLine."Document No." := GLEntry."Document No." + '-R';

            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine."Account No." := GLEntry."G/L Account No.";

            // Reverse amount
            GenJnlLine.Amount := -GLEntry.Amount;

            // Dimensions
            GenJnlLine."Shortcut Dimension 1 Code" := GLEntry."Global Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := SalesHeader."External Document No.";

            GenJnlLine.Description :=
                CopyStr(
                    StrSubstNo(
                        'Reversal of CMJOB %1',
                        GLEntry."Document No."),
                    1,
                    100);

            GenJnlLine.Insert(true);

            NextLineNo += 10000;
        until GLEntry.Next() = 0;
    end;

    local procedure GetNextLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", TemplateName);
        GenJnlLine.SetRange("Journal Batch Name", BatchName);

        if GenJnlLine.FindLast() then
            exit(GenJnlLine."Line No." + 10000)
        else
            exit(10000);
    end;
}


