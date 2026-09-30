tableextension 55015 "PurchHeaderExt" extends "Purchase Header"
{
    fields
    {
       
         field(50001; "Exported To CM"; Boolean)
        {
            Description = 'Exported to CM';
            Caption = 'Exported to CM';
            DataClassification = CustomerContent;
        }// Add changes to table fields here
   
        
       
          field(55003; "CM Status"; text[10])
        {
            Caption = 'CM Status';
            DataClassification = SystemMetadata;
        }
  
    }
    
    keys
    {
        // Add changes to keys here
    }
    
    fieldgroups
    {
        // Add changes to field groups here
    }
    
    var
        myInt: Integer;
}