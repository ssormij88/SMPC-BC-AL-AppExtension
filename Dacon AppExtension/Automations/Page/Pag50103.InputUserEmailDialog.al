page 50103 "Input User Email Dialog"
{
    Caption = 'Add Specific User from Microsoft 365';
    PageType = List;
    SourceTable = UserPlan;
    ApplicationArea = All;
    SourceTableTemporary = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    layout
    {

        area(Content)
        {
            repeater(General)
            {

                field("User email"; Rec."User email")
                {
                    trigger OnValidate()
                    var
                        lineno: Integer;

                    begin
                        if xLineNo = 0 then begin
                            xLineNo := 1;
                            Rec."Line No" := 1
                        end else begin
                            xLineNo += 1;
                            Rec."Line No" := xLineNo;
                        end;

                    end;
                }
                field("Id"; Rec."Line No")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action("Add User Email")
            {
                Promoted = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    RecPlan: Record UserPlan;
                begin
                    Rec.SetFilter("User email", '<>%1', '');
                    if Rec.FindSet() then begin
                        repeat
                            ProgressWindow.Open(StrSubstNo(ProgressMsg, Rec."User email"));
                            SynchronizesAUser(Rec."User email");
                        until Rec.Next() = 0;
                        ProgressWindow.Close();
                        Message('User has been created');
                    end;
                end;
            }
        }
    }
    var
        UserEmail: Text;
        AADUserMgt: Codeunit "Azure AD User Management";
        xLineNo: Integer;
        ProgressWindow: Dialog;
        ProgressMsg: Label 'Creating new user  %1.';

    procedure SynchronizesAUser(UserADEmail: text[50])
    begin
        AADUserMgt.SynchronizeLicensedUserFromDirectory(UserADEmail);
    end;

    /*     procedure DeleteUser()
        var
            jUser: Record User;
        begin
            if UserEmail = '' then
                Error('Email is required.');
            jUser.Reset();
            jUser.SetFilter("Authentication Email", '*' + UserEmail + '*');
            IF jUser.FindSet() then begin
                repeat
                    jUser.Delete();

                until jUser.Next() = 0;
                Message(UserEmail + ' is deleted!');
            end;
        end; */
}
