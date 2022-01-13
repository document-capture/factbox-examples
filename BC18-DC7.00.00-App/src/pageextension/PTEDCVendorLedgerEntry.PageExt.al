pageextension 62022 "PTE DC Vendor Ledger Entry" extends "Vendor Ledger Entries"
{
    // version DCW111.00.00.4.50
    layout
    {
        // Hide standard controls
        addfirst(FactBoxes)
        {
            part(CDCCaptureUI; "PTE DC Addin VendLedEnt")
            {
                Caption = 'Document';
                SubPageLink = "Entry No." = field("Entry No.");
                SubPageView = SORTING("Entry No.");
                ApplicationArea = Basic, Suite;
                AccessByPermission = tabledata "CDC Document Capture Setup" = R;
                Visible = CDCHasDCDocument;
            }
        }
    }
    var
        CDCHasAccess: Boolean;
        CDCHasDCDocument: Boolean;

    trigger OnOpenPage()
    begin
        CDCCheckIfHasAccess();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if CDCHasAccess then
            CDCEnableFields();
    end;

    local procedure CDCEnableFields();
    begin
        CDCHasDCDocument := HasDocumentsVendLedgEntry(Rec);
    end;

    local procedure HasDocumentsVendLedgEntry(VendorLedgerEntry: record "vendor ledger entry"): Boolean
    var
        Doc: Record "CDC Document";
        PurchCrMemoHeader: record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PreAssNo: Code[20];
        DocType: Integer;

    begin

        PreAssNo := '';
        CASE VendorLedgerEntry."Document Type" OF
            VendorLedgerEntry."Document Type"::Invoice:
                BEGIN
                    DocType := 2;
                    IF PurchInvHeader.GET(VendorLedgerEntry."Document No.") THEN
                        PreAssNo := PurchInvHeader."Pre-Assigned No.";
                END;
            VendorLedgerEntry."Document Type"::"Credit Memo":
                BEGIN
                    DocType := 3;
                    IF PurchCrMemoHeader.GET(VendorLedgerEntry."Document No.") THEN
                        PreAssNo := PurchCrMemoHeader."Pre-Assigned No.";
                END;
            ELSE
                EXIT(FALSE);
        END;

        Doc.SETCURRENTKEY("Created Doc. Table No.", "Created Doc. Subtype", "Created Doc. No.", "Created Doc. Ref. No.");
        Doc.SETRANGE("Created Doc. Table No.", DATABASE::"Purchase Header");
        Doc.SETRANGE("Created Doc. Subtype", DocType);
        Doc.SETRANGE("Created Doc. No.", PreAssNo);
        Doc.SETFILTER("File Type", '%1|%2', Doc."File Type"::OCR, Doc."File Type"::XML);
        EXIT(NOT Doc.ISEMPTY);

    end;

    local procedure CDCCheckIfHasAccess()
    var
        CDCLicenseMgt: Codeunit "CDC Continia License Mgt.";
    begin
        CDCHasAccess := CDCLicenseMgt.HasAccessToDC();
    end;

}
