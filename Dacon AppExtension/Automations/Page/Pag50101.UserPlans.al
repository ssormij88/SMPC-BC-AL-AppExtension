page 50101 UserPlans
{
    ApplicationArea = All;
    Caption = 'User Plans';
    PageType = List;
    SourceTable = UserPlan;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("User Security ID"; Rec."User Security ID")
                {
                    Visible = false;
                    ToolTip = 'Specifies the value of the User Security ID field.', Comment = '%';
                }
                field("User Name"; Rec."User Name")
                {
                    ToolTip = 'Specifies the value of the User Name field.', Comment = '%';
                }
                field("User email"; Rec."User email")
                {

                }
                field("Plan ID"; Rec."Plan ID")
                {
                    Visible = false;
                    ToolTip = 'Specifies the value of the Plan ID field.', Comment = '%';
                }
                field("Plan Name"; Rec."Plan Name")
                {
                    ToolTip = 'Specifies the value of the Plan Name field.', Comment = '%';
                }
                field(State; Rec.State)
                {
                    ToolTip = 'Specifies the value of the User State field.', Comment = '%';
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        UsersInPlans: Query "Users in Plans";
        jLineNo: Integer;
    begin
        if UsersInPlans.Open() then begin
            while UsersInPlans.Read() do begin
                Rec.Init();
                jLineNo += 1;
                Rec."User Security ID" := UsersInPlans.User_Security_ID;
                Rec."User Name" := UsersInPlans.User_Name;
                Rec."Plan ID" := UsersInPlans.Plan_ID;
                Rec."Plan Name" := UsersInPlans.Plan_Name;
                Rec.State := UsersInPlans.User_State;
                Rec."Line No" := jLineNo;
                Rec.Insert();
            end;
            UsersInPlans.Close();
            Rec.FindFirst();
        end;
    end;
}
