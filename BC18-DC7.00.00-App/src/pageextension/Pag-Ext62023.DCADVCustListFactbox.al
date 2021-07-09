// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

pageextension 62023 "DCADV Cust. List Factbox" extends "Customer List"
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
                SubPageLink = "Find Documents Using" = const("Source Record PK"), "Source Table No. Filter" = const(18), "Source No. Filter" = field("No.");
            }
        }
    }
}