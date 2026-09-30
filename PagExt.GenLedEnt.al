pageextension 55000 "Gen Led Entry" extends "General Ledger Entries"
{
    layout
    {
       
        addafter("Source Code")
        {
           

            field(Description2;Rec.Description2)
            {
                Caption = 'Payable Description 2';
                ApplicationArea = All;
            }
            field(PayDescription2;Rec."Pay Desc 2")
            {
                Caption = 'Pay Description 2';
                ApplicationArea = All;
            }
              
      
    }
    
    }
   
}
