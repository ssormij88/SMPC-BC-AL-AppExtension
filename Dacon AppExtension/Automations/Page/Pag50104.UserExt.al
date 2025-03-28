pageextension 50112 UserExt extends Users
{
    actions
    {
        addafter("Update users from Office")
        {
            action(AddUserfromMicrosoft365)
            {
                Caption = 'Add User from Microsoft 365';
                Image = Users;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    InputUserEmailDialog: Page "Input User Email Dialog";
                begin
                    InputUserEmailDialog.RunModal();
                    // if InputUserEmailDialog.RunModal() = Action::OK then
                    //   InputUserEmailDialog.SynchronizesAUser();
                end;
            }
            /*             action(DeleteUser)
                        {
                            Caption = 'Delete User*';
                            Image = Delete;
                            ApplicationArea = All;
                            Promoted = true;
                            PromotedCategory = Process;
                            PromotedIsBig = true;

                            trigger OnAction()
                            var
                                InputUserEmailDialog: Page "Input User Email Dialog";
                            begin
                                InputUserEmailDialog.RunModal();
                                //if InputUserEmailDialog.RunModal() = Action::OK then
                                //    InputUserEmailDialog.DeleteUser();
                            end;
                        } */
            action(UserPlan)
            {
                Caption = 'User Plans';
                Image = Users;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    UserPlan: Page UserPlans;
                begin
                    UserPlan.Run();
                end;
            }
        }
    }
}
