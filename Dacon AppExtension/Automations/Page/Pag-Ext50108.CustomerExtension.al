pageextension 50108 CustomerExtension extends "Customer List"
{
    actions
    {
        addbefore(PricesAndDiscounts)
        {
            action(CopyMultipleCustomer)
            {
                Caption = 'Copy Customers to Multiple Companies';
                ApplicationArea = All;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Image = Copy;
                AccessByPermission = TableData Company = RI;
                ToolTip = 'Copy an existing Customer to Multiple Companies.';
                trigger OnAction()
                var
                    CopyMultiCompaniesPage: Page "Copy to multiple companies";
                    jCustomer: Record Customer;
                begin
                    jCustomer.Reset();
                    CurrPage.SetSelectionFilter(jCustomer);
                    CopyMultiCompaniesPage.SetCustomers(jCustomer);

                    if CopyMultiCompaniesPage.RunModal() = Action::OK then
                        CopyMultiCompaniesPage.CopyCustomersToMultipleCompanies();
                end;
            }
        }
    }
}
