codeunit 50100 CommonCodeExtension
{
    procedure CreateRDSHeader(reqNo: Code[20]): Code[20];
    begin

        ReqHeader.Reset();
        ReqHeader.SetRange("No.", reqNo);
        if not ReqHeader.FindFirst() then begin
            ReqHeader.Init();
            ReqHeader."Request Date" := WorkDate();
            ReqHeader."Document Date" := WorkDate();
            ReqHeader."Posting Date" := WorkDate();
            ReqHeader.Validate("Request Code", 'ASSET RELATED');

            ReqHeader.Insert(true);

            exit(ReqHeader."No.");
        end;
        exit(reqNo);
    end;

    procedure CreateRDSLine(reqNo: Code[20]; estateTax: Decimal; dimCode: Code[20];
     dimValue: Code[20]; lineNo: Integer; userAccount: Code[50]; vendorno: code[20]): Integer
    var
        ReqLine: Record PPHRDS_ReqLine;
        DefaultDimension: Record "Default Dimension";
        jLineNo: Integer;
        OldDimSetID: Integer;
        NewDimSetID: Integer;
    begin
        jLineNo := 10000;
        ReqHeader.Reset();
        ReqHeader.SetRange("No.", reqNo);
        if ReqHeader.FindFirst() then begin
            DefaultDimension.Reset();
            DefaultDimension.SetRange("Table ID", 5600);
            DefaultDimension.SetRange("Dimension Code", dimCode);
            DefaultDimension.SetRange("Dimension Value Code", dimValue);
            if DefaultDimension.FindFirst() then begin

                ReqLine.Reset();
                ReqLine.SetRange("Document No.", reqNo);
                if ReqLine.FindLast() then begin
                    jLineNo := ReqLine."Line No." + 10000;
                end;

                ReqLine.Reset();
                ReqLine.SetRange("Document No.", reqNo);
                ReqLine.SetRange("No.", DefaultDimension."No.");
                ReqLine.SetRange("Line No.", lineNo);
                if not ReqLine.FindFirst() then begin
                    ReqLine.Init();
                    ReqLine."Document No." := reqNo;
                    ReqLine."Line No." := jLineNo;
                    ReqLine.Type := ReqLine.Type::"Fixed Asset";
                    ReqLine.Validate("No.", DefaultDimension."No.");
                    ReqLine.Validate(Quantity, 1);
                    ReqLine.Validate("Direct Unit Cost", estateTax);
                    ReqLine.Validate("Vendor No.", vendorno);
                    ReqLine.Validate("Request Code", 'ASSET RELATED');
                    ReqLine.Insert();

                    ReqHeaderNo := ReqHeader."No.";
                    OldDimSetID := ReqHeader."Dimension Set ID";

                    //DIMENSION
                    TempDimSetEntry.DELETEALL;

                    DimSetEntry.RESET;
                    DimSetEntry.SETRANGE("Dimension Set ID", ReqHeader."Dimension Set ID");
                    IF DimSetEntry.FINDSET THEN BEGIN
                        REPEAT
                            TempDimSetEntry.RESET;
                            TempDimSetEntry.SETRANGE("Dimension Code", DimSetEntry."Dimension Code");
                            TempDimSetEntry.SETRANGE("Dimension Value Code", DimSetEntry."Dimension Value Code");
                            IF NOT TempDimSetEntry.FINDFIRST THEN BEGIN
                                TempDimSetEntry.INIT;
                                TempDimSetEntry.VALIDATE("Dimension Code", DimSetEntry."Dimension Code");
                                TempDimSetEntry.VALIDATE("Dimension Value Code", DimSetEntry."Dimension Value Code");
                                TempDimSetEntry.INSERT;
                            END;
                        UNTIL DimSetEntry.NEXT = 0;
                    END;


                    TempDimSetEntry.RESET;
                    TempDimSetEntry.SETRANGE("Dimension Code", dimCode);
                    TempDimSetEntry.SETRANGE("Dimension Value Code", dimValue);
                    IF NOT TempDimSetEntry.FINDFIRST THEN BEGIN
                        TempDimSetEntry.INIT;
                        TempDimSetEntry.VALIDATE("Dimension Code", dimCode);
                        TempDimSetEntry.VALIDATE("Dimension Value Code", dimValue);
                        TempDimSetEntry.INSERT;
                    END;
                    TempDimSetEntry.RESET;
                    NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry); //get new DimSetID, after existing PO dimensions are modified

                    IF OldDimSetID <> NewDimSetID THEN BEGIN
                        ReqHeader."Dimension Set ID" := NewDimSetID; //assign new DimSetID 
                        ReqHeader.Validate("Requestor ID", userAccount);
                        ReqHeader.MODIFY;
                    END;
                    exit(ReqLine."Line No.");
                end;
            end;
            exit(0);
        end;
        exit(0);
    end;

    procedure CreateRDSDimension(reqNo: Code[20]; dimCode: Code[20]; dimValue: Code[20]; jLineNo: Integer)
    var
        OldDimSetID: Integer;
        NewDimSetID: Integer;
        ReqLine: Record PPHRDS_ReqLine;
    begin

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", dimCode);
        DimensionValue.SetRange(Code, dimValue);
        if DimensionValue.FindFirst() then begin
            if DimensionValue.Blocked = false then begin
                ReqHeader.RESET;
                ReqHeader.SETRANGE("No.", reqNo);
                IF ReqHeader.FINDFIRST THEN begin

                    OldDimSetID := ReqHeader."Dimension Set ID";

                    //DIMENSION HEADER
                    TempDimSetEntry.DELETEALL;

                    DimSetEntry.RESET;
                    DimSetEntry.SETRANGE("Dimension Set ID", ReqHeader."Dimension Set ID");
                    IF DimSetEntry.FINDSET THEN BEGIN
                        REPEAT
                            TempDimSetEntry.RESET;
                            TempDimSetEntry.SETRANGE("Dimension Code", DimSetEntry."Dimension Code");
                            TempDimSetEntry.SETRANGE("Dimension Value Code", DimSetEntry."Dimension Value Code");
                            IF NOT TempDimSetEntry.FINDFIRST THEN BEGIN
                                TempDimSetEntry.INIT;
                                TempDimSetEntry.VALIDATE("Dimension Code", DimSetEntry."Dimension Code");
                                TempDimSetEntry.VALIDATE("Dimension Value Code", DimSetEntry."Dimension Value Code");
                                TempDimSetEntry.INSERT;
                            END;
                        UNTIL DimSetEntry.NEXT = 0;
                    END;

                    TempDimSetEntry.RESET;
                    TempDimSetEntry.SETRANGE("Dimension Code", dimCode);
                    TempDimSetEntry.SETRANGE("Dimension Value Code", dimValue);
                    IF NOT TempDimSetEntry.FINDFIRST THEN BEGIN
                        TempDimSetEntry.INIT;
                        TempDimSetEntry.VALIDATE("Dimension Code", dimCode);
                        TempDimSetEntry.VALIDATE("Dimension Value Code", dimValue);
                        TempDimSetEntry.INSERT;
                    END;
                    TempDimSetEntry.RESET;
                    NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry); //get new DimSetID, after existing PO dimensions are modified


                    IF OldDimSetID <> NewDimSetID THEN BEGIN
                        ReqHeader."Dimension Set ID" := NewDimSetID; //assign new DimSetID 

                        ReqHeader.MODIFY;
                    END;

                    //DIMENSION LINE
                    ReqLine.Reset();
                    ReqLine.SetRange("Document No.", reqNo);
                    ReqLine.SetRange("Line No.", jLineNo);
                    if ReqLine.FindFirst() then begin
                        OldDimSetID := ReqLine."Dimension Set ID";

                        TempDimSetEntry.DELETEALL;

                        DimSetEntry.RESET;
                        DimSetEntry.SETRANGE("Dimension Set ID", ReqLine."Dimension Set ID");
                        IF DimSetEntry.FINDSET THEN BEGIN
                            REPEAT
                                TempDimSetEntry.RESET;
                                TempDimSetEntry.SETRANGE("Dimension Code", DimSetEntry."Dimension Code");
                                TempDimSetEntry.SETRANGE("Dimension Value Code", DimSetEntry."Dimension Value Code");
                                IF NOT TempDimSetEntry.FINDFIRST THEN BEGIN
                                    TempDimSetEntry.INIT;
                                    TempDimSetEntry.VALIDATE("Dimension Code", DimSetEntry."Dimension Code");
                                    TempDimSetEntry.VALIDATE("Dimension Value Code", DimSetEntry."Dimension Value Code");
                                    TempDimSetEntry.INSERT;
                                END;
                            UNTIL DimSetEntry.NEXT = 0;
                        END;

                        TempDimSetEntry.RESET;
                        TempDimSetEntry.SETRANGE("Dimension Code", dimCode);
                        TempDimSetEntry.SETRANGE("Dimension Value Code", dimValue);
                        IF NOT TempDimSetEntry.FINDFIRST THEN BEGIN
                            TempDimSetEntry.INIT;
                            TempDimSetEntry.VALIDATE("Dimension Code", dimCode);
                            TempDimSetEntry.VALIDATE("Dimension Value Code", dimValue);
                            TempDimSetEntry.INSERT;
                        END;
                        TempDimSetEntry.RESET;
                        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry); //get new DimSetID, after existing PO dimensions are modified


                        IF OldDimSetID <> NewDimSetID THEN BEGIN
                            ReqLine."Dimension Set ID" := NewDimSetID; //assign new DimSetID 
                            ReqLine.MODIFY;
                        END;
                    end;
                end;
            end;
        end;
    end;

    procedure GetNextNoSeries(nSeries: Code[50]): Code[20]
    var
        NoSeriesMgt: Codeunit "No. Series";
    begin
        EXIT(NoSeriesMgt.GetNextNo(NSeries, WORKDATE, TRUE));
    end;

    procedure CreateJournalBatches(jTemplate: Code[30]; jBatchName: Code[30]; batchNoSeries: Code[30]): Integer
    var
        jLineNo: Integer;

    begin
        jLineNo := 10000;
        GenJournalBatch.RESET;
        GenJournalBatch.SETRANGE("Journal Template Name", jTemplate);
        GenJournalBatch.SETRANGE(Name, JBatchName);
        IF NOT GenJournalBatch.FINDFIRST THEN BEGIN
            JournalBatchName := JBatchName;// NoSeriesMgt.GetNextNo('ARS-RENTAL',WORKDATE,TRUE);
            GenJnlTemplate.RESET;
            GenJnlTemplate.GET(jTemplate);
            //JournalBatchName :=  NoSeriesMgt.GetNextNo('ARS-RENTAL',WORKDATE,TRUE);
            GenJournalBatch.INIT;
            GenJournalBatch.Name := JournalBatchName;
            GenJournalBatch."Journal Template Name" := jTemplate;
            GenJournalBatch."Bal. Account Type" := GenJnlTemplate."Bal. Account Type";
            GenJournalBatch."Bal. Account No." := GenJnlTemplate."Bal. Account No.";
            GenJournalBatch."No. Series" := BatchNoSeries; //'GJNL-RCPT';;
            GenJournalBatch."Posting No. Series" := GenJnlTemplate."Posting No. Series";
            GenJournalBatch."Reason Code" := GenJnlTemplate."Reason Code";
            GenJournalBatch."Copy VAT Setup to Jnl. Lines" := GenJnlTemplate."Copy VAT Setup to Jnl. Lines";
            GenJournalBatch."Allow VAT Difference" := GenJnlTemplate."Allow VAT Difference";
            GenJournalBatch.INSERT(TRUE);
        END;
    end;

    procedure CreateCRJ(jTemplate: Code[30]; jBatchName: Code[30]; postingDate: text[12]; documentType: text[50];
     documentNo: code[20]; amount: Decimal; accountType: text[50]; accountNo: Code[20];
     desciption: text[50]; externalDoc: Code[40]; dimCode: Code[20]; dimValue: Code[20];
     bal_Account_Type: text[50]; bal_Account_No: code[20]; sourceCode: code[10];
     contractDim: text[20]; contractDimName: text[50]): Integer
    var
        jLineNo: Integer;
        OldDimSetID: Integer;
        NewDimSetID: Integer;
        jPostingdate: Date;
    begin
        jLineNo := 10000;
        GenJournalLine.RESET;
        GenJournalLine.SETRANGE("Journal Template Name", jTemplate);
        GenJournalLine.SETRANGE("Journal Batch Name", JBatchName);
        IF GenJournalLine.FINDLAST THEN
            jLineNo := GenJournalLine."Line No." + 10000;


        Evaluate(jPostingdate, postingDate);
        GenJournalLine.Init();
        GenJournalLine."Journal Batch Name" := jBatchName;
        GenJournalLine."Journal Template Name" := jTemplate;
        GenJournalLine."Line No." := jLineNo;
        GenJournalLine."Source Code" := sourceCode;
        GenJournalLine."Document Date" := WorkDate();
        GenJournalLine."Posting Date" := jPostingdate;

        if documentType = 'Payment' then
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment
        else if accountType = '_blank_' then
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::" ";

        GenJournalLine."Document No." := documentNo;
        GenJournalLine.Amount := amount;

        if accountType = 'Bank_Account' then
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Bank Account"
        else if accountType = 'Vendor' then
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;


        GenJournalLine."Account No." := accountNo;
        GenJournalLine.Description := desciption;
        GenJournalLine."External Document No." := externalDoc;
        if bal_Account_Type <> '_blank_' then begin
            if bal_Account_Type = 'G_L_Account' then
                GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account"
            else if bal_Account_Type = 'Bank_Account' then
                GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";

            GenJournalLine."Bal. Account No." := bal_Account_No;
        end;

        GenJournalLine.Insert();

        OldDimSetID := GenJournalLine."Dimension Set ID";

        TempDimSetEntry.DeleteAll();

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", 'CONTRACT');
        DimensionValue.SetRange(Code, contractDim);
        if not DimensionValue.FindFirst() then begin
            DimensionValue.Init();
            DimensionValue.Validate("Dimension Code", 'CONTRACT');
            DimensionValue.Validate(Code, contractDim);
            DimensionValue.Name := contractDimName;
            DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
            DimensionValue.Insert();
        end;

        TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'CONTRACT');
        TempDimSetEntry.VALIDATE("Dimension Value Code", contractDim);
        TempDimSetEntry.INSERT;

        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", dimCode);
        DimensionValue.SetRange(Code, dimValue);
        if DimensionValue.FindFirst() then begin
            TempDimSetEntry.RESET;
            TempDimSetEntry.SETRANGE("Dimension Code", dimCode);
            TempDimSetEntry.SETRANGE("Dimension Value Code", dimValue);
            IF NOT TempDimSetEntry.FINDFIRST THEN BEGIN
                TempDimSetEntry.INIT;
                TempDimSetEntry.VALIDATE("Dimension Code", dimCode);
                TempDimSetEntry.VALIDATE("Dimension Value Code", dimValue);
                TempDimSetEntry.INSERT;
            END;
            TempDimSetEntry.RESET;
            NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry); //get new DimSetID, after existing PO dimensions are modified

            IF OldDimSetID <> NewDimSetID THEN BEGIN
                GenJournalLine.Reset();
                GenJournalLine.SetRange("Journal Template Name", jTemplate);
                GenJournalLine.SetRange("Journal Batch Name", jBatchName);
                GenJournalLine.SetRange("Line No.", jLineNo);
                if GenJournalLine.FindFirst() then begin
                    GenJournalLine."Dimension Set ID" := NewDimSetID; //assign new DimSetID 
                    GenJournalLine.MODIFY;
                end;
            END;
            exit(jLineNo);
        end;
    end;

    procedure CreateGenJournalLineDimension(jTemplate: Code[30]; jBatchName: Code[30]; jLineNo: Integer; dimCode: Code[30]; dimValue: Code[30])
    var
        OldDimSetID: Integer;
        NewDimSetID: Integer;
    begin
        GenJournalLine.RESET;
        GenJournalLine.SETRANGE("Journal Template Name", jTemplate);
        GenJournalLine.SETRANGE("Journal Batch Name", jBatchName);
        GenJournalLine.SETRANGE("Line No.", jLineNo);
        IF GenJournalLine.FINDFIRST THEN begin
            OldDimSetID := GenJournalLine."Dimension Set ID";

            DimensionValue.Reset();
            DimensionValue.SetRange("Dimension Code", dimCode);
            DimensionValue.SetRange(Code, dimValue);
            if DimensionValue.FindFirst() then begin

                //DIMENSION
                TempDimSetEntry.DELETEALL;

                DimSetEntry.RESET;
                DimSetEntry.SETRANGE("Dimension Set ID", GenJournalLine."Dimension Set ID");
                IF DimSetEntry.FINDSET THEN BEGIN
                    REPEAT
                        TempDimSetEntry.RESET;
                        TempDimSetEntry.SETRANGE("Dimension Code", DimSetEntry."Dimension Code");
                        IF TempDimSetEntry.FINDFIRST THEN BEGIN
                            TempDimSetEntry.VALIDATE("Dimension Value Code", DimValue);
                            TempDimSetEntry.MODIFY;
                        END ELSE BEGIN
                            TempDimSetEntry.INIT;
                            TempDimSetEntry.VALIDATE("Dimension Code", DimSetEntry."Dimension Code");
                            TempDimSetEntry.VALIDATE("Dimension Value Code", DimSetEntry."Dimension Value Code");
                            TempDimSetEntry.INSERT;
                        END;
                    UNTIL DimSetEntry.NEXT = 0;
                END;

                TempDimSetEntry.INIT;
                TempDimSetEntry.VALIDATE("Dimension Code", DimCode);
                TempDimSetEntry.VALIDATE("Dimension Value Code", DimValue);
                TempDimSetEntry.INSERT;

                TempDimSetEntry.RESET;
                NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry); //get new DimSetID, after existing PO dimensions are modified


                IF OldDimSetID <> NewDimSetID THEN BEGIN
                    GenJournalLine."Dimension Set ID" := NewDimSetID; //assign new DimSetID 
                    GenJournalLine.MODIFY;
                END;
            end;
        end;
    end;

    procedure GetCRJPostingDate(contractDim: code[20]): text
    var
        txt: Text[100];
        BankAccountentries: Record "Bank Account Ledger Entry";
    begin
        txt := '';

        DimSetEntry.RESET;
        DimSetEntry.SETRANGE("Dimension Code", 'CONTRACT');
        DimSetEntry.SETRANGE("Dimension Value Code", contractDim);
        if DimSetEntry.FindSet() then begin
            repeat
                BankAccountentries.RESET;
                BankAccountentries.SETRANGE("Dimension Set ID", DimSetEntry."Dimension Set ID");
                if BankAccountentries.FindFirst() then begin
                    txt := FORMAT(BankAccountentries."Posting Date") + '^' + BankAccountentries."External Document No.";
                    exit(txt);
                end;
            until DimSetEntry.Next() = 0;
        end;

        exit(txt);
    end;

    procedure GetJVEntry(contractDim: code[20]): Text
    var
        txt: Text[100];
        GLEntry: Record "G/L Entry";
    begin
        txt := '';

        DimSetEntry.RESET;
        DimSetEntry.SETRANGE("Dimension Code", 'CONTRACT');
        DimSetEntry.SETRANGE("Dimension Value Code", contractDim);
        if DimSetEntry.FindSet() then begin
            repeat
                GLEntry.RESET;
                GLEntry.SETRANGE("Dimension Set ID", DimSetEntry."Dimension Set ID");
                if GLEntry.FindFirst() then begin
                    txt := FORMAT(GLEntry."Posting Date") + '^' + GLEntry."External Document No.";
                    exit(txt);
                end;
            until DimSetEntry.Next() = 0;
        end;

        exit(txt);
    end;

    procedure CreateAssetDimension(dimValue: Code[30]; dimName: code[50];
     faSeries: code[20]; faName: text[50]; faVendor: code[20]; faSubClassName: text[50]): Text
    var
        DefaultDimension: Record "Default Dimension";
        FaNo: code[20];
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        DimensionValue.Reset();
        DimensionValue.SetRange("Dimension Code", 'ARSNO');
        DimensionValue.SetRange(Code, dimValue);
        if DimensionValue.FindFirst() then begin
            DimensionValue.Validate(Name, dimName);
            DimensionValue.Modify();

        end else begin
            DimensionValue.Init();
            DimensionValue.Validate("Dimension Code", 'ARSNO');
            DimensionValue.Validate(Code, dimValue);
            DimensionValue.Name := dimName;
            DimensionValue.Validate("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
            DimensionValue.Insert();

        end;

        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", 5600);
        DefaultDimension.SetRange("Dimension Code", 'ARSNO');
        DefaultDimension.SetRange("Dimension Value Code", dimValue);
        if DefaultDimension.FindFirst() then begin
            FixedAsset.Reset();
            FixedAsset.SetRange("No.", DefaultDimension."No.");
            if FixedAsset.FindFirst() then begin
                FixedAsset.Description := faName;

                if (faVendor = 'NULL') OR (faVendor = 'null') then
                    FixedAsset."Vendor No." := ''
                else
                    FixedAsset."Vendor No." := faVendor;

                FixedAsset."FA Class Code" := 'INVPROP';

                faSubClassName := '*' + faSubClassName + '*';
                FASubclass.Reset();
                FASubclass.SetFilter(Name, faSubClassName);
                if FASubclass.FindFirst() then
                    FixedAsset."FA Subclass Code" := FASubclass.Code;

                FixedAsset.Modify();
            end;
        end else begin
            FixedAsset.Init();
            FixedAsset."No." := NoSeriesMgt.GetNextNo(faSeries);
            FixedAsset.Description := faName;

            if (faVendor = 'NULL') OR (faVendor = 'null') then
                FixedAsset."Vendor No." := ''
            else
                FixedAsset."Vendor No." := faVendor;

            FixedAsset."FA Class Code" := 'INVPROP';

            faSubClassName := '*' + faSubClassName + '*';
            FASubclass.Reset();
            FASubclass.SetFilter(Name, faSubClassName);
            if FASubclass.FindFirst() then
                FixedAsset."FA Subclass Code" := FASubclass.Code;

            FixedAsset.Insert();

            DefaultDimension.Init();
            DefaultDimension.Validate("Table ID", 5600);
            DefaultDimension."No." := FixedAsset."No.";
            DefaultDimension."Dimension Code" := 'ARSNO';
            DefaultDimension.Validate("Dimension Value Code", dimValue);
            DefaultDimension.Insert();

            exit(FixedAsset."No.");
        end;
        exit('ok');
    end;

    var
        NoSeriesMgt: Codeunit "No. Series";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        DimMgt: Codeunit DimensionManagement;
        ReqHeaderNo: Code[20];
        ReqHeader: Record PPHRDS_ReqHeader;
        DimensionValue: Record "Dimension Value";
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalBatchName: Code[30];
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
}
