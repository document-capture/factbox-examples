page 62022 "PTE DC Addin VendLedEnt"
{
    // C/SIDE

    Caption = 'Document Capture Client Addin';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    Permissions = TableData 6085780 = rimd;
    SourceTable = "Vendor Ledger Entry";

    layout
    {
        area(content)
        {

            usercontrol(CaptureUIWeb; "CDC Capture UI AddIn")
            {
                Visible = SHOWCAPTUREWEBUI;
                ApplicationArea = All;

                trigger OnControlAddIn(index: Integer; data: Text)
                begin
                    OnControlAddInEvent(Index, Data);
                end;

                trigger AddInReady()
                begin
                    AddInReady := TRUE;
                    UpdatePage();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PurchCrMemoHeader: record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PreAssNo: Code[20];
        DocType: Integer;
    begin
        if GuiAllowed then begin

            PreAssNo := '';
            CASE Rec."Document Type" OF
                Rec."Document Type"::Invoice:
                    BEGIN
                        DocType := 2;
                        IF PurchInvHeader.GET(Rec."Document No.") THEN
                            PreAssNo := PurchInvHeader."Pre-Assigned No.";
                    END;
                Rec."Document Type"::"Credit Memo":
                    BEGIN
                        DocType := 3;
                        IF PurchCrMemoHeader.GET(Rec."Document No.") THEN
                            PreAssNo := PurchCrMemoHeader."Pre-Assigned No.";
                    END;
            END;
            IF ((Rec."Document Type" <> xRec."Document Type") OR (Rec."Document No." <> xRec."Document No.")) AND (DocType <> 0) THEN BEGIN
                Document.SETCURRENTKEY("Created Doc. Table No.", "Created Doc. Subtype", "Created Doc. No.", "Created Doc. Ref. No.");
                Document.SETRANGE("Created Doc. Table No.", DATABASE::"Purchase Header");
                Document.SETRANGE("Created Doc. Subtype", DocType);
                Document.SETRANGE("Created Doc. No.", PreAssNo);
                Document.SETFILTER("File Type", '%1|%2', Document."File Type"::OCR, Document."File Type"::XML);
                IF NOT Document.FINDFIRST() THEN
                    CLEAR(Document);
                UpdateImage();
                SendCommand(CaptureXmlDoc);
            END ELSE
                IF (SendAllPendingCommands AND (NOT CaptureXmlDoc.IsEmpty())) THEN BEGIN
                    SendAllPendingCommands := FALSE;
                    SendCommand(CaptureXmlDoc);
                END;

        end
    end;

    trigger OnOpenPage()
    begin
        IF ContiniaUserProp.GET(USERID) AND (ContiniaUserProp."Image Zoom" > 0) THEN
            CurrZoom := ContiniaUserProp."Image Zoom"
        ELSE
            CurrZoom := 50;

        ShowCaptureUI := NOT WebClientMgt.IsWebClient();
        ShowCaptureWebUI := WebClientMgt.IsWebClient();

        IF ContiniaUserProp.GET(USERID) AND (ContiniaUserProp."Add-In Min Width" > 0) THEN
            AddInWidth := ContiniaUserProp."Add-In Min Width"
        ELSE
            AddInWidth := 725;

        CaptureAddinLib.BuildSetAddInWidthCommand(AddInWidth, CaptureXmlDoc);
    end;

    var
        ContiniaUserProp: Record "CDC Continia User Property";
        Document: Record "cdc document";
        CaptureAddinLib: Codeunit "CDC Capture RTC Library";
        TIFFMgt: Codeunit "CDC TIFF Management";
        WebClientMgt: Codeunit "CDC Web Client Management";
        CaptureXmlDoc: Codeunit "CSC XML Document";
        AddInReady: Boolean;
        DisableCapture: Boolean;
        SendAllPendingCommands: Boolean;
        [InDataSet]
        ShowCaptureUI: Boolean;
        ShowCaptureWebUI: Boolean;
        Channel: Code[50];
        CurrZoom: Decimal;
        AddInWidth: Integer;
        CurrentPageNo: Integer;
        PageInTotalLbl: Label '(1 page in total)';
        PagesInTotalLbl: Label '(%1 pages in total)', Comment = '%1 show the number of pages';
        PageNoLbl: Label 'Page %1', Comment = '%1 Shows the page number';
        CaptureUISource: Text;
        CurrentZoomText: Text[30];
        HeaderFieldsFormName: Text[50];
        LineFieldsFormName: Text[50];
        CurrentPageText: Text[30];

    procedure UpdateImage()
    var
        "Page": Record "CDC Document Page";
        TempFile: Record "CDC Temp File" temporary;
        HasImage: Boolean;
        FileName: Text[1024];
    begin
        IF Document."No." = '' THEN
            IF NOT WebClientMgt.IsWebClient() THEN
                CaptureAddinLib.BuildSetImageCommand(FileName, TRUE, CaptureXmlDoc);

        IF Document."File Type" = Document."File Type"::XML THEN
            HasImage := Document.GetVisualFile(TempFile)
        ELSE
            IF WebClientMgt.IsWebClient() THEN BEGIN
                HasImage := Document.GetPngFile(TempFile, 1);
                IF NOT HasImage THEN
                    HasImage := Document.GetTiffFile(TempFile);
            END ELSE
                HasImage := Document.GetTiffFile(TempFile);

        IF (FileName = '') AND NOT HasImage THEN BEGIN
            CaptureAddinLib.BuildClearImageCommand(CaptureXmlDoc);
            UpdateCurrPageNo(0);
            EXIT;
        END ELSE
            IF (FileName = '') AND NOT WebClientMgt.IsWebClient() THEN BEGIN
                FileName := CopyStr(TempFile.GetClientFilePath(), 1, 1024);
                CaptureAddinLib.BuildSetImageCommand(FileName, TRUE, CaptureXmlDoc);
            END ELSE
                IF Document."File Type" = Document."File Type"::XML THEN
                    CaptureAddinLib.BuildSetImageDataCommand(TempFile.GetContentAsDataUrl(), TRUE, CaptureXmlDoc);

        UpdateCurrPageNo(1);

        CaptureAddinLib.BuildScrollTopCommand(CaptureXmlDoc);

        IF (ContiniaUserProp."Image Zoom" = 0) AND (Page.GET(Document."No.", 1)) AND (Page.Width > 0) THEN BEGIN
            IF NOT WebClientMgt.IsWebClient() THEN
                CurrZoom := ROUND(((AddInWidth - 50) / Page.Width) * 100, 1, '<')
            ELSE
                CurrZoom := ROUND(((AddInWidth - 80) / Page.Width) * 100, 1, '<');
        END ELSE
            CurrZoom := ContiniaUserProp."Image Zoom";

        Zoom(CurrZoom, FALSE);

        IF Document."No. of Pages" = 1 THEN
            CaptureAddinLib.BuildTotalNoOfPagesTextCommand(PageInTotalLbl, CaptureXmlDoc)
        ELSE
            CaptureAddinLib.BuildTotalNoOfPagesTextCommand(STRSUBSTNO(PagesInTotalLbl, Document."No. of Pages"), CaptureXmlDoc);
    end;

    procedure UpdateCurrPageNo(PageNo: Integer)
    var
        TempFile: Record "CDC Temp File" temporary;
        ImageManagement: Codeunit "CDC Image Management";
        ImageDataUrl: Text;
    begin
        Document.CALCFIELDS("No. of Pages");

        CurrentPageNo := PageNo;
        CurrentPageText := STRSUBSTNO(PageNoLbl, CurrentPageNo);

        IF (WebClientMgt.IsWebClient() AND (PageNo > 0)) THEN BEGIN
            IF Document.GetPngFile(TempFile, PageNo) THEN
                ImageDataUrl := ImageManagement.GetImageDataAsJpegDataUrl(TempFile, 100)
            ELSE
                IF Document.GetTiffFile(TempFile) THEN
                    ImageDataUrl := TIFFMgt.GetPageAsDataUrl(TempFile, PageNo);

            IF ImageDataUrl <> '' THEN
                CaptureAddinLib.BuildSetImageDataCommand(ImageDataUrl, TRUE, CaptureXmlDoc);
        END;

        CaptureAddinLib.BuildSetActivePageCommand(PageNo, CurrentPageText, CaptureXmlDoc);
    end;

    procedure ParsePageText(PageText: Text[30])
    var
        NewPageNo: Integer;
    begin
        IF STRPOS(PageText, ' ') = 0 THEN BEGIN
            IF EVALUATE(NewPageNo, PageText) THEN;
        END ELSE
            IF EVALUATE(NewPageNo, COPYSTR(PageText, STRPOS(PageText, ' '))) THEN;

        Document.CALCFIELDS("No. of Pages");
        IF (NewPageNo <= 0) OR (NewPageNo > Document."No. of Pages") THEN
            UpdateCurrPageNo(CurrentPageNo)
        ELSE
            UpdateCurrPageNo(NewPageNo);
    end;

    procedure Zoom(ZoomPct: Decimal; UpdateUserProp: Boolean)
    begin
        IF ZoomPct < 1 THEN
            ZoomPct := 1;
        CurrZoom := ZoomPct;
        CurrentZoomText := FORMAT(CurrZoom) + '%';

        IF UpdateUserProp THEN
            IF NOT ContiniaUserProp.GET(USERID) THEN BEGIN
                ContiniaUserProp."User ID" := USERID;
                ContiniaUserProp."Image Zoom" := CurrZoom;
                ContiniaUserProp.INSERT();
            END ELSE
                IF ContiniaUserProp."Image Zoom" <> CurrZoom THEN BEGIN
                    ContiniaUserProp."Image Zoom" := CurrZoom;
                    ContiniaUserProp.MODIFY();
                END;

        CaptureAddinLib.BuildZoomCommand(CurrZoom, CaptureXmlDoc);
        CaptureAddinLib.BuildZoomTextCommand(CurrentZoomText, CaptureXmlDoc);
    end;

    procedure SendCommand(var XmlDoc: Codeunit "CSC XML Document")
    var
        NewXmlDoc: Codeunit "CSC XML Document";
    begin
        IF NOT AddInReady AND WebClientMgt.IsWebClient() THEN
            EXIT;

        CaptureAddinLib.XmlToText(XmlDoc, CaptureUISource);
        CaptureAddinLib.TextToXml(NewXmlDoc, CaptureUISource);

        IF WebClientMgt.IsWebClient() THEN
            CurrPage.CaptureUIWeb.SourceValueChanged(CaptureUISource);

        CLEAR(CaptureXmlDoc);
    end;

    procedure SetConfig(NewHeaderFieldsFormName: Text[50]; NewLineFieldsFormName: Text[50]; NewChannel: Code[50])
    begin
        HeaderFieldsFormName := NewHeaderFieldsFormName;
        LineFieldsFormName := NewLineFieldsFormName;
        Channel := NewChannel;
    end;

    procedure HandleSimpleCommand(Command: Text[1024])
    begin
        CASE Command OF
            'ZoomIn':
                Zoom(ROUND(CurrZoom, 5, '<') + 5, TRUE);

            'ZoomOut':
                Zoom(ROUND(CurrZoom, 5, '>') - 5, TRUE);

            'FirstPage':
                BEGIN
                    Document.CALCFIELDS("No. of Pages");
                    IF Document."No. of Pages" > 0 THEN
                        UpdateCurrPageNo(1);
                END;

            'NextPage':
                BEGIN
                    Document.CALCFIELDS("No. of Pages");
                    IF CurrentPageNo < Document."No. of Pages" THEN
                        UpdateCurrPageNo(CurrentPageNo + 1);
                END;

            'PrevPage':
                IF CurrentPageNo > 1 THEN
                    UpdateCurrPageNo(CurrentPageNo - 1);

            'LastPage':
                BEGIN
                    Document.CALCFIELDS("No. of Pages");
                    UpdateCurrPageNo(Document."No. of Pages");
                END;
        END;

        SendCommand(CaptureXmlDoc);
    end;

    procedure HandleXmlCommand(Command: Text[1024]; var InXmlDoc: Codeunit "CSC XML Document")
    var
        XmlLib: Codeunit "CDC Xml Library";
        DocumentElement: Codeunit "CSC XML Node";
    begin
        InXmlDoc.GetDocumentElement(DocumentElement);
        CASE Command OF
            'ZoomTextChanged':
                BEGIN
                    CurrentZoomText := CopyStr(XmlLib.GetNodeText(DocumentElement, 'Text'), 1, 30);
                    IF EVALUATE(CurrZoom, DELCHR(CurrentZoomText, '=', '%')) THEN;
                    Zoom(CurrZoom, TRUE);
                END;

            'PageTextChanged':
                BEGIN
                    CurrentPageText := CopyStr(XmlLib.GetNodeText(DocumentElement, 'Text'), 1, 30);
                    ParsePageText(CurrentPageText);
                END;

            'ChangePage':
                UpdateCurrPageNo(XmlLib.Text2Int(XmlLib.GetNodeText(DocumentElement, 'NewPageNo')));

            'InfoPaneResized':
                AddInWidth := XmlLib.Text2Int(XmlLib.GetNodeText(DocumentElement, 'Width'));
        END;

        IF NOT CaptureXmlDoc.IsEmpty() THEN
            SendCommand(CaptureXmlDoc);
    end;

    procedure SetSendAllPendingCommands(NewSendAllPendingCommands: Boolean)
    begin
        SendAllPendingCommands := NewSendAllPendingCommands;
    end;

    procedure SetDisableCapture(NewDisableCapture: Boolean)
    begin
        DisableCapture := NewDisableCapture;
    end;

    procedure ClearImage()
    begin
        CaptureAddinLib.BuildClearImageCommand(CaptureXmlDoc);
        UpdateCurrPageNo(0);
        SendCommand(CaptureXmlDoc);
        CurrPage.UPDATE(FALSE);
    end;

    procedure UpdatePage()
    begin
        UpdateImage();
        CaptureAddinLib.BuildCaptureEnabledCommand(FALSE, CaptureXmlDoc);
        SendCommand(CaptureXmlDoc);
        CurrPage.UPDATE(FALSE);
    end;

    local procedure OnControlAddInEvent(Index: Integer; Data: Variant)
    var
        XmlLib: Codeunit "CDC Xml Library";
        InXmlDoc: Codeunit "CSC XML Document";
        DocumentElement: Codeunit "CSC XML Node";
    begin
        IF Index = 0 THEN
            HandleSimpleCommand(Data)
        ELSE BEGIN
            CaptureAddinLib.TextToXml(InXmlDoc, Data);
            InXmlDoc.GetDocumentElement(DocumentElement);
            IF WebClientMgt.IsWebClient() THEN
                HandleXmlCommand(CopyStr(XmlLib.GetNodeText(DocumentElement, 'Event'), 1, 1024), InXmlDoc)
            ELSE
                HandleXmlCommand(CopyStr(XmlLib.GetNodeText(DocumentElement, 'Command'), 1, 1024), InXmlDoc);
        END;
    end;
}