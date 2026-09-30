query 55003 "Job Margin Source"
{
    Caption = 'Job Margin Source';
    QueryType = Normal;

    elements
    {
        dataitem(GLEntry; "G/L Entry")
        {
            filter(JobCodeFilter; "Global Dimension 2 Code")
            {
            }

            filter(GLAccountFilter; "G/L Account No.")
            {
            }

            column(JobCode; "Global Dimension 2 Code")
            {
            }

            column(GLAccountNo; "G/L Account No.")
            {
            }

            column(TotalAmount; Amount)
            {
                Method = Sum;
            }
        }
    }
}