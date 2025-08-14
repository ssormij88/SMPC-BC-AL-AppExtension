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
            action(DeleteUser)
            {
                Caption = 'Resend Email*';
                Image = Delete;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    RDSHeader: Record PPHRDS_ReqHeader;
                    Approvalentry: Record "Approval Entry";
                    Email: Codeunit Email;
                    SentEmail: Record "Sent Email";
                    EmailItem: record "Email Item";
                    WorkflowManagement: Codeunit "Workflow Management";
                    WorkflowEventHandling: Codeunit "Workflow Event Handling";
                    WorkflowExists: Boolean;
                begin
                    RDSHeader.Reset();
                    RDSHeader.SetRange("No.", 'REQ000124');
                    if RDSHeader.FindFirst() then begin
                        Approvalentry.SetRange("Document No.", RDSHeader."No.");
                        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
                        // ApprovalEntry.SetFilter("Due Date", '<%1', Today);
                        if ApprovalEntry.FindSet() then begin

                            WorkflowExists := WorkflowManagement.WorkflowExists(ApprovalEntry, ApprovalEntry, WorkflowEventHandling.RunWorkflowOnSendOverdueNotificationsCode());
                            Message(Format(WorkflowExists));

                            OnSendOverdueNotifications();
                            Message('sent');
                        end;

                    end;
                end;
            }
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
    var
        NoWorkflowEnabledErr: Label 'There is no workflow enabled for sending overdue approval notifications.';

    [IntegrationEvent(false, false)]
    local procedure OnSendOverdueNotifications()
    begin
    end;
}
