table 55024 "Invoice Email Setup"
{
    Caption = 'Invoice Email Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(2; "Email Logo"; Blob)
        {
            Caption = 'Email Logo';
            SubType = Bitmap;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Standard singleton-setup-table pattern: fetches the (only) record,
    /// creating it on first use so the page always has something to bind to.
    /// </summary>
    procedure GetRecordOnce()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;
}