reportextension 55000 MyExtension extends "Standard Sales - Invoice"

{
    dataset
    {
        modify(Header)
        {
            trigger OnAfterAfterGetRecord()
            begin
                JobName := '';

                if Header."External Document No." <> '' then begin
                    if DimValue.Get('JOB', Header."External Document No.") then
                        JobName := DimValue.Name;
                end;

                InvoiceLinkURL := BaseURLTxt + Header."No.";

                // Pull the customer address from the live Customer master record
                // (Bill-to Customer No.) instead of the address snapshot stored on
                // the posted invoice, so the printed address reflects any changes
                // made to the customer's address since the invoice was posted.
                Clear(CustMasterAddr);
                if SQUCust.Get(Header."Bill-to Customer No.") then
                    SQUFormatAddress.Customer(CustMasterAddr, SQUCust);
            end;
        }

        add(Header)
        {
            column(JobName; JobName) { }
            column(SQUPONumber; Header."SQU PO Number") { }
            column(InvoiceLinkURL; InvoiceLinkURL) { }
            column(CustMasterAddress1; CustMasterAddr[1]) { }
            column(CustMasterAddress2; CustMasterAddr[2]) { }
            column(CustMasterAddress3; CustMasterAddr[3]) { }
            column(CustMasterAddress4; CustMasterAddr[4]) { }
            column(CustMasterAddress5; CustMasterAddr[5]) { }
            column(CustMasterAddress6; CustMasterAddr[6]) { }
            column(CustMasterAddress7; CustMasterAddr[7]) { }
            column(CustMasterAddress8; CustMasterAddr[8]) { }
        }

        modify(Line)
        {
            trigger OnBeforeAfterGetRecord()
            begin
                // Capture the G/L Account No. BEFORE the base trigger runs --
                // the base OnAfterGetRecord blanks Line."No." for G/L Account
                // lines ("if Type = Type::"G/L Account" then "No." := '';"),
                // so by OnAfterAfterGetRecord it's already too late to read it.
                SQUGLAccountNo := '';
                if Line.Type = Line.Type::"G/L Account" then
                    SQUGLAccountNo := Line."No.";
            end;

            trigger OnAfterAfterGetRecord()
            begin
                // GL 40020 and 20165 are fee lines with a fixed customer-facing
                // description regardless of the underlying G/L account's actual description.
                case SQUGLAccountNo of
                    '40020':
                        Line.Description := 'Shipping & Handling';
                    '20165':
                        Line.Description := 'Sales Tax Collected';
                end;
            end;
        }
    }

    var
        DimValue: Record "Dimension Value";
        SQUCust: Record Customer;
        SQUFormatAddress: Codeunit "Format Address";
        JobName: Text[100];
        BaseURLTxt: Label 'https://white-water-0543e061e.3.azurestaticapps.net/?tenantId=41a9b9ae-0cba-4b3a-9677-35259c6be3c4&environment=sandbox_May26&companyid=240fde62-6ace-ed11-a7c7-0022482870c6&invoice=', Locked = true;
        InvoiceLinkURL: Text;
        SQUGLAccountNo: Code[20];
        CustMasterAddr: array[8] of Text[100];
}