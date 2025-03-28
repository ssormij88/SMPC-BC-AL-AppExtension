page 50105 "Copy to multiple companies"
{
    Caption = 'Copy to multiple companies';
    PageType = StandardDialog;
    SourceTable = UserPlan;
    ApplicationArea = All;
    SourceTableTemporary = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    Permissions = tabledata "Feature Data Update Status" = ri;
    layout
    {

        area(Content)
        {

            repeater(General)
            {

                field("Company"; Rec."User email")
                {
                    Caption = 'Company';
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

    var
        SourceName: text[50];
        xLineNo: Integer;
        NumberOfCopies: Integer;
        NewCompanyName: Text[30];
        company: Record Company;

    procedure SetSourceName(NewSourceName: Text[30])
    begin
        company.Reset();
        company.SetRange(Name, NewSourceName);
        SourceName := NewSourceName;
    end;

    procedure CopytoMultipleCompanies()
    var
        i: Integer;

        ProgressWindow: Dialog;
        ProgressMsg: Label 'Creating new company %1.';
        CopySuccessMsg: Label 'Company %1 has been copied successfully.';
        ReportLayoutSelection1: Record "Report Layout Selection";
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomReportLayout1: Record "Custom Report Layout";
        CustomReportLayout: Record "Custom Report Layout";
        FeatureDataUpdateStatus1: Record "Feature Data Update Status";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        ExperienceTierSetup1: Record "Experience Tier Setup";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        JobQueueManagement: Codeunit "Job Queue Management";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        OriginalCompany, CopiedCompany : Record Company;
    begin
        Rec.SetFilter("User email", '<>%1', '');
        if Rec.FindSet() then begin
            ExperienceTierSetup1.Reset();
            ExperienceTierSetup1.SetRange("Company Name", SourceName);

            ReportLayoutSelection1.Reset();
            ReportLayoutSelection1.SetRange("Company Name", SourceName);

            CustomReportLayout1.Reset();
            CustomReportLayout1.SetRange("Company Name", SourceName);

            FeatureDataUpdateStatus1.Reset();
            FeatureDataUpdateStatus1.SetRange("Company Name", SourceName);


            repeat
                if Rec."User email" <> '' then begin
                    NewCompanyName := Rec."User email";

                    ProgressWindow.Open(StrSubstNo(ProgressMsg, NewCompanyName));
                    CopyCompany(SourceName, NewCompanyName);

                    if ExperienceTierSetup1.FindSet() then begin
                        repeat
                            ExperienceTierSetup := ExperienceTierSetup1;
                            ExperienceTierSetup."Company Name" := NewCompanyName;
                            if ExperienceTierSetup.Insert() then;
                        //  ApplicationAreaMgmt.SetExperienceTierOtherCompany(ExperienceTierSetup, NewCompanyName);
                        until ExperienceTierSetup1.Next() = 0;
                    end;
                    if ReportLayoutSelection1.FindSet() then begin
                        repeat
                            ReportLayoutSelection := ReportLayoutSelection1;
                            ReportLayoutSelection."Report ID" := ReportLayoutSelection1."Report ID";
                            ReportLayoutSelection."Company Name" := NewCompanyName;
                            if ReportLayoutSelection.Insert() then;

                        until ReportLayoutSelection1.Next() = 0;
                    end;
                    if CustomReportLayout1.FindSet() then begin
                        repeat
                            CustomReportLayout := CustomReportLayout1;
                            CustomReportLayout.Code := '';
                            CustomReportLayout."Company Name" := NewCompanyName;
                            if CustomReportLayout.Insert(true) then;
                        until CustomReportLayout1.Next() = 0;
                    end;
                    if FeatureDataUpdateStatus1.FindSet() then begin
                        repeat
                            FeatureDataUpdateStatus := FeatureDataUpdateStatus1;
                            FeatureDataUpdateStatus."Company Name" := NewCompanyName;
                            if FeatureDataUpdateStatus.Insert() then;
                        until FeatureDataUpdateStatus1.Next() = 0;
                    end;

                    SetNewNameToNewCompanyInfo();
                    JobQueueManagement.SetRecurringJobsOnHold(NewCompanyName);
                    OnAfterCreatedNewCompanyByCopyCompany(NewCompanyName, company);
                    RegisterUpgradeTags(NewCompanyName);
                    if CopiedCompany.Get(NewCompanyName) then
                        AssistedCompanySetupStatus.CopySaaSCompanySetupStatus(SourceName, CopiedCompany.Name);

                    OnAfterCopyCompanyOnAction(NewCompanyName);
                end;
            until Rec.Next() = 0;
            ProgressWindow.Close();

            Message(CopySuccessMsg, SourceName);
        end;
    end;


    local procedure RegisterUpgradeTags(NewCompanyName: Code[30])
    var
        UpgradeTag: codeunit "Upgrade Tag";
    begin
        UpgradeTag.CopyUpgradeTags(CopyStr(CompanyName(), 1, MaxStrLen(NewCompanyName)), NewCompanyName);
    end;

    local procedure SetNewNameToNewCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        Company: Record Company;
    begin
        if Company.Get(NewCompanyName) then;
        Company."Display Name" := NewCompanyName;

        Company.Modify();

        if CompanyInformation.ChangeCompany(NewCompanyName) then
            if CompanyInformation.Get() then begin
                CompanyInformation.Name := NewCompanyName;
                CompanyInformation.Modify(true);
            end;

        OnAfterSetNewNameToNewCompanyInfo(NewCompanyName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewNameToNewCompanyInfo(NewCompanyName: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30]; Company: Record Company)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNewCompanyName(var NewCompanyName: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyCompanyOnAction(CompanyName: Text[30])
    begin
    end;
}
