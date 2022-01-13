// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

pageextension 62026 "PTE DC Fixed Asset Factbox" extends "Fixed Asset Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part(CDCDocumentFiles; "CDC Document Files Factbox")
            {
                ApplicationArea = All;
                AccessByPermission = tabledata "CDC Record ID Tree" = R;
                ShowFilter = false;
                Visible = true;
                SubPageLink = "Find Documents Using" = const("Source Record PK"), "Source Table No. Filter" = const(5600), "Source No. Filter" = field("No.");
            }
        }
    }
}