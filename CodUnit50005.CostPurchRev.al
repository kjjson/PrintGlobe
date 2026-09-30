codeunit 55005 "Purch Job Reversal Handler"
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

        CreatePurchaseJobReversals(SalesHeader);
    end;


    local procedure CreatePurchaseJobReversals(SalesHeader: Record "Sales Header")
    var
        GLEntry: Record "G/L Entry";
        NextLineNo: Integer;
        OffsetAccount: Code[20];
    begin
        GLEntry.Reset();
        GLEntry.SetRange("Source Code", 'PURCHASES');
        GLEntry.SetRange("Global Dimension 2 Code", SalesHeader."External Document No.");

        // Only the 3 allowed accounts
        GLEntry.SetFilter(
            "G/L Account No.",
            '%1|%2|%3',
            '10171',
            '10172',
            '10173', '10175');

        if not GLEntry.FindSet() then
            exit;

        NextLineNo := GetNextLineNo('GENERAL', 'PURINVREV');

        repeat
            OffsetAccount := GetOffsetAccount(GLEntry."G/L Account No.");

            // --- REVERSAL LINE (original account) ---
            CreateJournalLine(
                NextLineNo,
                GLEntry."G/L Account No.",
                -GLEntry.Amount,
                GLEntry,
                SalesHeader,
                'Purch Job Reversal');

            // --- OFFSET LINE (mapped account) ---
            CreateJournalLine(
                NextLineNo,
                OffsetAccount,
                GLEntry.Amount,
                GLEntry,
                SalesHeader,
                'Purch Job Offset');

        until GLEntry.Next() = 0;
    end;


    // ======================================
    // Journal line creator (shared routine)
    // ======================================
    local procedure CreateJournalLine(
        var NextLineNo: Integer;
        AccountNo: Code[20];
        LineAmount: Decimal;
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        LabelText: Text[50])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Clear(GenJnlLine);
        GenJnlLine.Init();

        GenJnlLine."Journal Template Name" := 'GENERAL';
        GenJnlLine."Journal Batch Name" := 'PURINVREV';
        GenJnlLine."Line No." := NextLineNo;

        GenJnlLine."Posting Date" := SalesHeader."CM Closed Date";
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := GLEntry."Document No." + '-PJ';

        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := AccountNo;

        GenJnlLine.Amount := LineAmount;

        // Dimensions
        GenJnlLine."Shortcut Dimension 1 Code" :=
            GLEntry."Global Dimension 1 Code";

        GenJnlLine."Shortcut Dimension 2 Code" :=
            SalesHeader."External Document No.";

        GenJnlLine.Description :=
            CopyStr(
                StrSubstNo(
                    '%1 %2',
                    LabelText,
                    GLEntry."Document No."),
                1,
                100);

        GenJnlLine.Insert(true);

        NextLineNo += 10000;
    end;


    // ======================================
    // Mapping function for offset accounts
    // ======================================
    local procedure GetOffsetAccount(SourceAccount: Code[20]): Code[20]
    begin
        case SourceAccount of
            '10171':
                exit('50010');
            '10172':
                exit('50020');
            '10173':
                exit('50030');
            '10175':
                exit('50025');
        end;

        // Safety fallback (should never hit)
        Error('No offset account mapping for %1', SourceAccount);
    end;


    // ======================================
    // Get next line number
    // ======================================
    local procedure GetNextLineNo(
        TemplateName: Code[10];
        BatchName: Code[10]): Integer
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
