page 50100 UserListPage
{
    APIGroup = 'SMPCGroup';
    APIPublisher = 'SMPC';
    APIVersion = 'v1.0';
    ApplicationArea = All;
    Caption = 'userList';
    DelayedInsert = true;
    EntityName = 'UserEntity';
    EntitySetName = 'UserEntitySet';
    PageType = API;
    SourceTable = User;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(userName; Rec."User Name")
                {
                    Caption = 'User Name';
                }
                field(fullName; Rec."Full Name")
                {
                    Caption = 'Full Name';
                }
                field(state; Rec.State)
                {
                    Caption = 'State';
                }
                field(contactEmail; Rec."Contact Email")
                {
                    Caption = 'Contact Email';
                }
                field(authenticationEmail; Rec."Authentication Email")
                {
                    Caption = 'Authentication Email';
                }
            }
        }
    }
}
