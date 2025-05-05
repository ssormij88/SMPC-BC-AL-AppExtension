pageextension 50107 VendorExtension extends "Vendor List"
{
    actions
    {
        addfirst(processing)
        {
            action(CopyMultipleVendor)
            {
                Caption = 'Copy Vendors to Multiple Companies';
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Image = Copy;
                AccessByPermission = TableData Company = RI;
                ToolTip = 'Copy an existing vendor to Multiple Companies.';
                trigger OnAction()
                var
                    CopyMultiCompaniesPage: Page "Copy to multiple companies";
                    jVendor: Record "Vendor";
                begin
                    jVendor.Reset();
                    CurrPage.SetSelectionFilter(jVendor);
                    CopyMultiCompaniesPage.SetVendor(jVendor);

                    if CopyMultiCompaniesPage.RunModal() = Action::OK then
                        CopyMultiCompaniesPage.CopyVendorsToMultipleCompanies();
                end;
            }
        }
    }
}
