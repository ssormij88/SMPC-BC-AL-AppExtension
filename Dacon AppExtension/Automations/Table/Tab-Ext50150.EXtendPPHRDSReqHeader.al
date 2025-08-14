tableextension 50149 EXtendPPHRDS_ReqHeader extends PPHRDS_ReqHeader
{
    fields
    {
        field(3; "Notification Req. No."; Code[20])
        {
            Caption = 'Notification Req. No.';
            DataClassification = ToBeClassified;
        }
    }
}
