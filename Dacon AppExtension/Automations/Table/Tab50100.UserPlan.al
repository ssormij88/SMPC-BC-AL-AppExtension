table 50100 UserPlan
{
    TableType = Temporary;
    Caption = 'UserPlan';
    DataClassification = CustomerContent;
    LookupPageId = UserPlans;
    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
        }
        field(2; "Plan ID"; Guid)
        {
            Caption = 'Plan ID';
        }
        field(3; "User Name"; Code[50])
        {
            Caption = 'User Name';
        }
        field(4; "Plan Name"; Text[50])
        {
            Caption = 'Plan Name';
        }
        field(5; State; Option)
        {
            Caption = 'User State';
            OptionCaption = 'Enabled,Disabled';
            OptionMembers = Enabled,Disabled;
            DataClassification = CustomerContent;
        }
        field(6; "User email"; Text[50])
        {
            Caption = 'User email';
        }
        field(7; "Line No"; Integer)
        {
            Caption = 'Id';
        }
    }
    keys
    {
        key(PK; "Line No")
        {
            Clustered = true;
        }
    }


}
