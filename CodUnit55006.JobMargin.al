codeunit 55006 "Job Margin Mgt."
{
    procedure LoadJobMargins(var TempJobMarginBuffer: Record "Job Margin Buffer" temporary)
    var
        JobMarginSource: Query "Job Margin Source";
        JobCode: Code[20];
        GLAccountNo: Code[20];
        TotalAmount: Decimal;
    begin
        TempJobMarginBuffer.Reset();
        TempJobMarginBuffer.DeleteAll();

        JobMarginSource.Open();

        while JobMarginSource.Read() do begin
            JobCode := JobMarginSource.JobCode;
            GLAccountNo := JobMarginSource.GLAccountNo;
            TotalAmount := JobMarginSource.TotalAmount;

            if JobCode <> '' then begin
                if not TempJobMarginBuffer.Get(JobCode) then begin
                    TempJobMarginBuffer.Init();
                    TempJobMarginBuffer."Job Code" := JobCode;
                    TempJobMarginBuffer.Costs := 0;
                    TempJobMarginBuffer.Revenue := 0;
                    TempJobMarginBuffer.WIP := 0;
                    TempJobMarginBuffer.Margin := 0;
                    TempJobMarginBuffer.Insert();
                end;

                if CopyStr(GLAccountNo, 1, 1) = '5' then
                    TempJobMarginBuffer.Costs += TotalAmount;

                if CopyStr(GLAccountNo, 1, 1) = '4' then
                    TempJobMarginBuffer.Revenue += -TotalAmount;

                if CopyStr(GLAccountNo, 1, 4) = '1017' then
                    TempJobMarginBuffer.WIP += TotalAmount;

                TempJobMarginBuffer.Margin := TempJobMarginBuffer.Revenue - TempJobMarginBuffer.Costs;
                TempJobMarginBuffer.Modify();
            end;
        end;

        JobMarginSource.Close();
    end;
}