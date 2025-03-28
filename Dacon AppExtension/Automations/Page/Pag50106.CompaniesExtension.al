pageextension 50106 SMPCCompaniesExtension extends Companies
{
    actions
    {
        addfirst(processing)
        {
            action(CopyMultipleCompanies)
            {
                Caption = 'Copy to Multiple Companies';
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Image = Copy;
                AccessByPermission = TableData Company = RI;
                ToolTip = 'Copy an existing company to Multiple Companies.';
                trigger OnAction()
                var
                    CopyMultiCompaniesPage: Page "Copy to multiple companies";
                    UserPermissions: Codeunit "User Permissions";
                    OnlySuperCanCreateNewCompanyErr: Label 'Only users with the SUPER permission set can create a new company.';
                begin
                    if not UserPermissions.IsSuper(UserSecurityId()) then
                        Error(OnlySuperCanCreateNewCompanyErr);

                    CopyMultiCompaniesPage.SetSourceName(Rec.Name);
                    if CopyMultiCompaniesPage.RunModal() = Action::OK then
                        CopyMultiCompaniesPage.CopytoMultipleCompanies();
                end;
            }
        }
    }
}
