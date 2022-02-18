pageextension 62027 "PTE DC PostPurchInv Factbox" extends "Posted Purchase Invoices"
{

    layout
    {
        addfirst(factboxes)
        {
            part(CDCCaptureUI; "CDC Client Addin - Post Purch.")
            {
                Caption = 'Document';
                SubPageLink = "Created Doc. No." = field("Pre-Assigned No.");
                SubPageView = SORTING("Created Doc. Table No.", "Created Doc. Subtype", "Created Doc. No.", "Created Doc. Ref. No.")
                              WHERE("Created Doc. Table No." = CONST(38), "Created Doc. Subtype" = CONST(2), "Created Doc. Ref. No." = CONST(0)); // Invoice
                ApplicationArea = Basic, Suite;
                AccessByPermission = tabledata "CDC Document Capture Setup" = R;
                Visible = CDCHasDCDocument;
            }
        }
    }
    trigger OnOpenPage()
    begin
        CDCCheckIfHasAccess();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if CDCHasAccess then
            CDCHasDCDocument := PurchDocMgt.HasDocumentsPostedInv(Rec);

    end;

    local procedure CDCCheckIfHasAccess()
    var
        CDCLicenseMgt: Codeunit "CDC Continia License Mgt.";
    begin
        CDCHasAccess := CDCLicenseMgt.HasAccessToDC();
    end;

    var
        PurchDocMgt: Codeunit "CDC Purch. Doc. - Management";
        CDCHasAccess: Boolean;
        CDCHasDCDocument: Boolean;

}
