codeunit 50103 "RDS Email Resending"
{
    trigger OnRun()
    var
        Approvalentry: Record "Approval Entry";
        Email: Codeunit Email;
        SentEmail: Record "Sent Email";
        EmailItem: record "Email Item";
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowExists: Boolean;

    begin

        Approvalentry.Reset();
        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Created, ApprovalEntry.Status::Open);
        ApprovalEntry.SetFilter(Approvalentry."Date-Time Sent for Approval", '<%1', CurrentDateTime);
        if ApprovalEntry.FindSet() then begin

            WorkflowExists := WorkflowManagement.WorkflowExists(ApprovalEntry, ApprovalEntry, WorkflowEventHandling.RunWorkflowOnSendOverdueNotificationsCode());


            OnSendOverdueNotifications();

        end;
    end;

    var
        NoWorkflowEnabledErr: Label 'There is no workflow enabled for sending overdue approval notifications.';

    [IntegrationEvent(false, false)]
    local procedure OnSendOverdueNotifications()
    begin
    end;

}
