
codeunit 50102 EquityWebServices
{
    #region Global Variable
    var
        JournalBatchName: Code[30];
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        OldDimSetID: Integer;
        NewDimSetID: Integer;
#pragma warning disable AL0432
        NoSeriesMgt: Codeunit "NoSeriesManagement";
#pragma warning restore AL0432
        DimMgt: Codeunit "DimensionManagement";
        xPostingDate: Date;
    #endregion
    #region Executive Handshake


    [ServiceEnabled]
    procedure CreatetCRJ(amount: Decimal; particulars: Text; accountno: Text; bankcode: Text; tranxtype: Text; stockcode: Text; batchname: Text; exdocno: Text; postingdate: Text; accttype: Text; documentno: Text; trans: Text; balacctno: Text) "50": Code[20]
    var
        vLineNo: Integer;
    begin
        JournalBatchName := BatchName;
        GenJnlTemplate.RESET;
        GenJnlTemplate.GET('CASHRCPT');

        GenJournalBatch.RESET;
        GenJournalBatch.SETFILTER(Name, JournalBatchName);
        GenJournalBatch.SETFILTER("Journal Template Name", 'CASHRCPT');
        GenJournalBatch.SETFILTER("Bal. Account Type", FORMAT(GenJnlTemplate."Bal. Account Type"::"G/L Account"));

        IF NOT GenJournalBatch.FINDLAST THEN BEGIN
            GenJournalBatch.INIT;
            GenJournalBatch.Name := JournalBatchName;
            GenJournalBatch."Journal Template Name" := 'CASHRCPT';
            GenJournalBatch."Bal. Account Type" := GenJnlTemplate."Bal. Account Type";
            GenJournalBatch."No. Series" := 'GJNL-RCPT2';
            GenJournalBatch."Posting No. Series" := 'GJNL-RCPT';
            GenJournalBatch.INSERT(TRUE);
        END;


        CLEAR(NoSeriesMgt);
        GenJournalLine.INIT;
        GenJournalLine."Journal Template Name" := 'CASHRCPT';
        GenJournalLine."Journal Batch Name" := JournalBatchName;
        EVALUATE(xPostingDate, postingdate);
        GenJournalLine."Posting Date" := xPostingDate;
        GenJournalLine."Account No." := accountno;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;

        IF documentno = '' THEN
#pragma warning disable AL0432
            GenJournalLine."Document No." := NoSeriesMgt.GetNextNo('GJNL-RCPT2', WORKDATE, TRUE);
#pragma warning restore AL0432
        IF documentno <> '' THEN
            GenJournalLine."Document No." := documentno;

        GenJournalLine."External Document No." := exdocno;
        GenJournalLine.VALIDATE(GenJournalLine.Amount, amount);

        IF trans = 'CDC' THEN
            GenJournalLine."Bal. Account No." := '420004'

        ELSE IF trans = 'CDI' THEN
            GenJournalLine."Bal. Account No." := '310005';

        IF accttype = 'Bank Account' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Bank Account"
        ELSE IF accttype = 'G/L Account' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account"
        ELSE IF accttype = 'Vendor' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Vendor"
        ELSE IF accttype = 'Customer' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Customer";

        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";

        if balacctno <> '' then
            GenJournalLine."Bal. Account No." := balacctno;

        IF accttype = 'Vendor' then
            GenJournalLine."WHT Business Posting Group PHL" := 'V_CORP';
        IF accountno = '700008' then
            GenJournalLine."Gen. Prod. Posting Group" := 'GL';
        GenJournalLine.Description := particulars;

        OldDimSetID := GenJournalLine."Dimension Set ID";

        vLineNo := GetLastLineNo('CASHRCPT', JournalBatchName) + 10000;
        GenJournalLine."Line No." := vLineNo;
        GenJournalLine.INSERT(TRUE);

        TempDimSetEntry.DELETEALL;

        TempDimSetEntry.INIT;

        TempDimSetEntry.VALIDATE("Dimension Code", 'BANK');
        TempDimSetEntry.VALIDATE("Dimension Value Code", bankcode);
        TempDimSetEntry.INSERT;

        TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'TRANX');
        TempDimSetEntry.VALIDATE("Dimension Value Code", tranxtype);
        TempDimSetEntry.INSERT;

        TempDimSetEntry.INIT;
        case Trans of
            'FC', 'FI':
                TempDimSetEntry.VALIDATE("Dimension Code", 'SHORT-TERM INVESTMEN');
            'BC', 'BI':
                TempDimSetEntry.VALIDATE("Dimension Code", 'BONDS');
            //Add Dimension for BOND
            else
                TempDimSetEntry.VALIDATE("Dimension Code", 'INVESTEE');
        end;
        TempDimSetEntry.VALIDATE("Dimension Value Code", stockcode);
        TempDimSetEntry.INSERT;

        IF (accttype = 'Vendor') and (trans = 'SC') then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.Validate("Dimension Code", 'A/P TYPE');
            TempDimSetEntry.Validate("Dimension Value Code", 'A/P - TRADE');
            TempDimSetEntry.INSERT;
        end;

        if trans in ['SI', 'SC'] then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.Validate("Dimension Code", 'INV_TRANX');
            TempDimSetEntry.Validate("Dimension Value Code", '102');
            TempDimSetEntry.INSERT;
        end;

        TempDimSetEntry.RESET;
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.SetRange("Journal Template Name", 'CASHRCPT');
        GenJournalLine.SetRange("Line No.", vLineNo);
        if GenJournalLine.FindFirst() then begin
            GenJournalLine."Dimension Set ID" := NewDimSetID;
            GenJournalLine.Modify();
        end;

        EXIT(GenJournalLine."Document No.");
    end;

    procedure CreatePayJournal(batchname: Text; postingdate: Text; vatdate: Text; documenttype: Text; documentno: Text; externaldocno: Text; accttype: Text; acctno: Text; description: Text; amount: Decimal; balaccttype: Text; bankcode: Text; tranxcode: Text; shortterminv: Text; trans: Text) docno: Code[20]
    var
        vLineNo: Integer;
    begin
        // 1. Validate and initialize the batch
        GenJnlTemplate.GET('GENERAL');

        // Ensure batch name is not empty
        if batchname = '' then
            Error('Batch name cannot be empty');

        // Check/create the batch
        if not GenJournalBatch.Get('GENERAL', batchname) then begin
            GenJournalBatch.Init();
            GenJournalBatch."Journal Template Name" := 'GENERAL';
            GenJournalBatch.Name := batchname;
            GenJournalBatch.Description := 'Auto-created batch';
            GenJournalBatch."No. Series" := 'JVNUMBR';
            GenJournalBatch."Posting No. Series" := 'GJNL-GEN';
            GenJournalBatch."Bal. Account Type" := GenJnlTemplate."Bal. Account Type";
            GenJournalBatch.Insert(true);
        end;

        // 2. Create journal line
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := 'GENERAL';
        GenJournalLine."Journal Batch Name" := batchname;
        Evaluate(xPostingDate, postingdate);
        GenJournalLine."Posting Date" := xPostingDate;
        if externaldocno <> '' then
            GenJournalLine."VAT Reporting Date" := xPostingDate;

        GenJournalLine."External Document No." := externaldocno;

        case accttype of
            'Customer':
                GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
            'Bank Account':
                GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Bank Account";
            'G/L Account':
                GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
            else
                GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        end;

        case balaccttype of
            'G/L Account':
                GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
        end;

        GenJournalLine."Account No." := acctno;
        GenJournalLine.Description := description;
        GenJournalLine.Amount := amount;
        GenJournalLine."Amount (LCY)" := amount;

        // 3. Handle document number generation
        if documentno = '' then
#pragma warning disable AL0432    
        GenJournalLine."Document No." := NoSeriesMgt.GetNextNo('JVNUMBR', WORKDATE, TRUE)
#pragma warning restore AL0432
        else
            GenJournalLine."Document No." := documentno;

        // Store document number for return before inserting
        docno := GenJournalLine."Document No.";

        // Get line number and insert
        vLineNo := GetLastLineNo('GENERAL', batchname) + 10000;
        GenJournalLine."Line No." := vLineNo;
        GenJournalLine.INSERT(TRUE);

        // Handle dimensions (your existing code)
        TempDimSetEntry.DELETEALL;
        if bankcode <> '' then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", 'BANK');
            TempDimSetEntry.VALIDATE("Dimension Value Code", BankCode);
            TempDimSetEntry.INSERT;
        end;

        TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'TRANX');
        TempDimSetEntry.VALIDATE("Dimension Value Code", tranxcode);
        TempDimSetEntry.INSERT;

        if shortterminv <> '' then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", 'SHORT-TERM INVESTMEN');
            TempDimSetEntry.VALIDATE("Dimension Value Code", shortterminv);
            TempDimSetEntry.INSERT;
        end;

        // Update dimensions
        TempDimSetEntry.RESET;
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Batch Name", batchname);
        GenJournalLine.SetRange("Journal Template Name", 'GENERAL');
        GenJournalLine.SetRange("Line No.", vLineNo);
        if GenJournalLine.FindFirst() then begin
            GenJournalLine."Dimension Set ID" := NewDimSetID;
            GenJournalLine.Modify();
        end;

        // 4. Explicitly return the document number
        exit(docno);
    end;

    [ServiceEnabled]
    procedure CreateHeaderRDS(requestid: Code[50]; requestcode: Code[20]; requestdesc: Text; documentdate: Text; postingdate: Text; bankcode: Text; tranxcode: Text) rdsno: Code[20]
    var
        RDSHeader: Record PPHRDS_ReqHeader;
        dDocumentDate: Date;
        dPostingDate: Date;
    begin

        if not Evaluate(dDocumentDate, documentdate) then begin
            Error('The provided Document Date "%1" is not in a valid format.', documentdate);
        end;

        if not Evaluate(dPostingDate, postingdate) then begin
            Error('The provided Posting Date "%1" is not in a valid format.', postingdate);
        end;

        RDSHeader."Request Code" := requestcode;
        RDSHeader."Request Description" := requestdesc;
        RDSHeader."Request Date" := Today();
        RDSHeader."Shortcut Dimension 1 Code" := bankcode;
        RDSHeader."Shortcut Dimension 2 Code" := tranxcode;
        RDSHeader.Insert(true);

        if RDSHeader.Get(RDSHeader."No.") then begin
            RDSHeader."Requestor ID" := requestid;
            RDSHeader."Requestor Name" := GetFullNameFromUserName(requestid);
            RDSHeader."Document Date" := dDocumentDate;
            RDSHeader."Posting Date" := dPostingDate;
            RDSHeader.Modify();
        end;

        exit(RDSHeader."No.");

    end;

    procedure CreateLineRDS(docno: Code[20]; lineno: Integer; no: Code[20]; description: Text; quantity: Integer; directcost: Decimal; expectedrecdate: Text; requestcode: Code[20]; bankcode: Text; tranxcode: Text; aptype: Text; invtranx: Text; investee: Text) rvpurchline: Integer
    var
        RDSLine: Record PPHRDS_ReqLine;
        dExpectedRecDate: Date;
    begin
        Evaluate(dExpectedRecDate, expectedrecdate);
        RDSLine.RESET;
        RDSLine.SETFILTER("Document No.", docno);

        IF RDSLine.FINDLAST THEN
            RDSLine."Line No." := RDSLine."Line No." + 10000
        ELSE
            RDSLine."Line No." := lineno;

        RDSLine."Document No." := docno;
        RDSLine.Type := RDSLine.Type::"G/L Account";
        RDSLine."No." := no;
        RDSLine.Description := description;
        RDSLine.Quantity := quantity;
        RDSLine."Direct Unit Cost" := directcost;
        RDSLine."Line Amount" := directcost;
        RDSLine."Expected Receipt Date" := dExpectedRecDate;
        RDSLine."Request Code" := requestcode;
        RDSLine."Dimension Set ID" := GetDimension(bankcode, tranxcode, investee, invtranx, aptype);
        RDSLine.Insert(true);
        exit(RDSLine."Line No.");
    end;

    [ServiceEnabled]
    procedure CreatePurchInvHeader(VendorNo: Code[20]; BankCode: Text; TranxType: Text; StockCode: Text; InvoiceNo: Text; PostingDate: Text; Particulars: Text) PurchNo: Code[20]
    var
        PurchHeader: Record "Purchase Header";
        xPostingDate: Date;
    begin
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice; //options
        PurchHeader."Buy-from Vendor No." := VendorNo;
        EVALUATE(xPostingDate, PostingDate);
        PurchHeader."Posting Date" := xPostingDate;
        PurchHeader."Document Date" := xPostingDate;
        PurchHeader."Vendor Invoice No." := InvoiceNo;
        PurchHeader."Posting Description" := Particulars;
        PurchHeader.VALIDATE("Buy-from Vendor No.");
        PurchHeader.INSERT(TRUE);
        EXIT(PurchHeader."No.");
    end;

    [ServiceEnabled]
    procedure CreatePurchInvLine(DocNo: Code[20]; LineNo: Integer; AcctType: Text; AccountNo: Text; Description: Text; Quantity: Integer; Amount: Decimal; UnitMeasureCode: Text; VatProdPostingGrp: Text; GenProdPostingGrp: Text; WHTBusinessPostingGrp: Text; BankCode: Text; TranxType: Text; StockCode: Text) rvPurchLine: Integer
    var
        PurchLine: Record "Purchase Line";
    begin
        //PurchLine."Line No." := LineNo;
        PurchLine."Document Type" := PurchLine."Document Type"::Invoice;
        PurchLine.RESET;
        PurchLine.SETFILTER("Document No.", DocNo);
        IF PurchLine.FINDLAST THEN
            PurchLine."Line No." := PurchLine."Line No." + 10000
        ELSE
            PurchLine."Line No." := LineNo;

        PurchLine."Document No." := DocNo;
        PurchLine.Type := PurchLine.Type::"G/L Account";
        PurchLine."No." := AccountNo;
        PurchLine.Description := Description;
        PurchLine.VALIDATE(PurchLine.Quantity, Quantity);
        PurchLine.VALIDATE(PurchLine.Amount, Amount);
        PurchLine.VALIDATE(PurchLine."Direct Unit Cost", Amount);
        PurchLine."Unit of Measure Code" := UnitMeasureCode;
        PurchLine."VAT Prod. Posting Group" := VatProdPostingGrp;
        PurchLine."Gen. Prod. Posting Group" := GenProdPostingGrp;
        PurchLine."WHT Product Posting Group PHL" := WHTBusinessPostingGrp;
        PurchLine."Dimension Set ID" := GetDimension(BankCode, TranxType, StockCode, '', '');
        PurchLine.INSERT(TRUE);
        //EXIT(PurchLine."Dimension Set ID");
        EXIT(PurchLine."Line No.")
    end;

    #endregion

    #region Local Procedure

    procedure GetFullNameFromUserName(UserName: Code[50]): Text[100]
    var
        UserRec: Record User;
    begin
        UserRec.SetRange("User Name", UserName);
        if UserRec.FindFirst() then
            exit(UserRec."Full Name");

        exit('');
    end;

    local procedure GetLastLineNo(vjournaltemplatename: Code[20]; vbatchname: Code[30]) rvLineNo: Integer
    var
        vGenJournalLine: Record "Gen. Journal Line";
    begin
        vGenJournalLine.RESET;
        vGenJournalLine.SETFILTER("Journal Template Name", vjournaltemplatename);
        vGenJournalLine.SETFILTER("Journal Batch Name", vbatchname);
        IF vGenJournalLine.FINDLAST THEN
            EXIT(vGenJournalLine."Line No.");
        EXIT(0);
    end;

    [ServiceEnabled]
    local procedure GetDimension(BankCode: Text; TranxType: Text; StockCode: Text; InvTranx: Text; APType: Text): Integer
    begin
        TempDimSetEntry.DELETEALL;

        if BankCode <> '' then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", 'BANK');
            TempDimSetEntry.VALIDATE("Dimension Value Code", BankCode);//Value 
            TempDimSetEntry.INSERT;
        end;

        if TranxType <> '' then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", 'TRANX');//Dimension Code
            TempDimSetEntry.VALIDATE("Dimension Value Code", TranxType);//Value 
            TempDimSetEntry.INSERT;
        end;

        if StockCode <> '' then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", 'INVESTEE');//Dimension Code
            TempDimSetEntry.VALIDATE("Dimension Value Code", StockCode);//Value 
            TempDimSetEntry.INSERT;
        end;

        if InvTranx <> '' then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", 'INV_TRANX');//Dimension Code
            TempDimSetEntry.VALIDATE("Dimension Value Code", InvTranx);//Value 
            TempDimSetEntry.INSERT;
        end;

        if APType <> '' then begin
            TempDimSetEntry.INIT;
            TempDimSetEntry.VALIDATE("Dimension Code", 'A/P TYPE');//Dimension Code
            TempDimSetEntry.VALIDATE("Dimension Value Code", APType);//Value 
            TempDimSetEntry.INSERT;
        end;

        TempDimSetEntry.RESET;
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);

        EXIT(NewDimSetID);
    end;

    local procedure GetAccountTypeEnum(accountTypeText: Text): Enum "Gen. Journal Account Type"
    begin
        case accountTypeText of
            'Customer':
                exit("Gen. Journal Account Type"::Customer);
            'Vendor':
                exit("Gen. Journal Account Type"::Vendor);
            'Bank Account':
                exit("Gen. Journal Account Type"::"Bank Account");
            'G/L Account':
                exit("Gen. Journal Account Type"::"G/L Account");
            else
                Error('Invalid account type: %1', accountTypeText);
        end;
    end;

    local procedure AddDimension(var TempDimSetEntry: Record "Dimension Set Entry" temporary; dimCode: Code[20]; valueCode: Code[20])
    begin
        if valueCode = '' then
            exit;

        TempDimSetEntry.Init();
        TempDimSetEntry.Validate("Dimension Code", dimCode);
        TempDimSetEntry.Validate("Dimension Value Code", valueCode);
        if TempDimSetEntry.Insert() then;
    end;

    local procedure CheckGenJournalBatchExists(
        TemplateName: Code[10];
        BatchName: Code[20];
        NoSeries: Code[20];
        PostingNoSeries: Code[20];
        Description: Text)
    begin
        // Check if the General Journal Batch already exists
        if not GenJournalBatch.Get(TemplateName, BatchName) then begin
            // Initialize new General Journal Batch
            GenJournalBatch.Init();
            GenJournalBatch."Journal Template Name" := TemplateName;
            GenJournalBatch.Name := BatchName;
            GenJournalBatch.Description := Description;

            // Assign No. Series based on the Template Name
            GenJournalBatch."No. Series" := NoSeries;
            GenJournalBatch."Posting No. Series" := PostingNoSeries;

            // Assign Balancing Account Type
            GenJournalBatch."Bal. Account Type" := GenJnlTemplate."Bal. Account Type";

            // Insert the newly created General Journal Batch
            GenJournalBatch.Insert(true);
        end;
    end;
    #endregion

    #region DACON Handshake
    procedure DACONCashDiv(
        batchname: Text;
        postingdate: Text;
        documentno: Text;
        externaldocno: Text;
        accounttype: Text;
        accountno: Text;
        description: Text;
        qty: Decimal;
        amount: Decimal;
        amountlcy: Decimal;
        balaccttype: Text;
        balacctno: Text;
        investeecode: Text;
        cashtranx: Text
    ) docno: Code[20]
    var
        NewDimSetID: Integer;
        vLineNo: Integer;
        NextDocNo: Code[20];
        DIM_INVESTEE: Label 'INVESTEE';
        DIM_CASH_TRANX: Label 'CASH_TRANX';
    begin

        // Ensure batch exists or create
        if not GenJournalBatch.Get('GENERAL', batchname) then begin
            GenJournalBatch.Init();
            GenJournalBatch."Journal Template Name" := 'GENERAL';
            GenJournalBatch.Name := batchname;
            GenJournalBatch.Description := 'Auto-created batch';
            GenJournalBatch."No. Series" := 'GJNL-GEN';
            GenJournalBatch."Posting No. Series" := GenJnlTemplate."Posting No. Series";
            GenJournalBatch."Bal. Account Type" := GenJnlTemplate."Bal. Account Type";
            GenJournalBatch.Insert(true);
        end;

        // Get next line number
        vLineNo := GetLastLineNo('GENERAL', batchname) + 10000;

        // Document No. assignment - use No. Series codeunit
        EVALUATE(xPostingDate, postingdate);
        if documentno = '' then begin
#pragma warning disable AL0432
            NextDocNo := NoSeriesMgt.GetNextNo(GenJournalBatch."No. Series", xPostingDate, true);
#pragma warning restore AL0432
            if NextDocNo = '' then
                Error('Could not generate a document number from No. Series %1.', GenJournalBatch."No. Series");
            documentno := NextDocNo;
        end;

        // Create journal line
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := 'GENERAL';
        GenJournalLine."Journal Batch Name" := batchname;
        GenJournalLine."Line No." := vLineNo;
        GenJournalLine."Posting Date" := xPostingDate;
        GenJournalLine."Document No." := documentno;
        docno := documentno;

        if externaldocno <> '' then
            GenJournalLine."External Document No." := externaldocno;

        // Assign enum Account Type
        GenJournalLine."Account Type" := GetAccountTypeEnum(accounttype);
        GenJournalLine."Account No." := accountno;

        // Assign enum Bal. Account Type and Bal. Account No.
        GenJournalLine."Bal. Account Type" := GetAccountTypeEnum(balaccttype);
        GenJournalLine."Bal. Account No." := balacctno;

        GenJournalLine.Description := description;
        GenJournalLine.Amount := amount;
        GenJournalLine."Amount (LCY)" := amountlcy;

        // Add dimensions before inserting
        AddDimension(TempDimSetEntry, DIM_INVESTEE, investeecode);
        AddDimension(TempDimSetEntry, DIM_CASH_TRANX, cashtranx);
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJournalLine."Dimension Set ID" := NewDimSetID;

        GenJournalLine.Insert(true);

        exit(docno);
    end;

    procedure DACONTimeDeposit(
         batchname: Text;
         postingdate: Text;
         documentno: Text;
         externaldocno: Text;
         accttype: Text;
         acctno: Text;
         description: Text;
         amount: Decimal;
         amountlcy: Decimal;
         balaccttype: Text;
         assetclass: Text;
         bank: Text;
         cashtranx: Text;
         template: Text;
         balacctno: Text;
         noseries: Code[20];
         postingnoseries: Code[20];
         descript: Text

    ) docno: Code[20]
    var
        NewDimSetID: Integer;
        vLineNo: Integer;
        NextDocNo: Code[20];

    begin
        if GenJnlTemplate.GET(template) then begin
            CheckGenJournalBatchExists(template, batchname, noseries, postingnoseries, descript);
        end;
        EVALUATE(xPostingDate, postingdate);
        // Get next line number
        vLineNo := GetLastLineNo(template, batchname) + 10000;
        if documentno = '' then begin
#pragma warning disable AL0432
            NextDocNo := NoSeriesMgt.GetNextNo(noseries, xPostingDate, true);
#pragma warning restore AL0432
            if NextDocNo = '' then
                Error('Could not generate a document number from No. Series %1.', GenJournalBatch."No. Series");
            documentno := NextDocNo;
        end;
        // Create journal line
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := template;
        GenJournalLine."Journal Batch Name" := batchname;
        GenJournalLine."Line No." := vLineNo;
        GenJournalLine."Posting Date" := xPostingDate;
        GenJournalLine."Document No." := documentno;
        docno := documentno;

        if externaldocno <> '' then
            GenJournalLine."External Document No." := externaldocno;

        GenJournalLine."Bal. Account No." := balacctno;

        // Assign enum Account Type
        GenJournalLine."Account Type" := GetAccountTypeEnum(accttype);
        GenJournalLine."Account No." := acctno;

        // Assign enum Bal. Account Type and Bal. Account No.
        GenJournalLine."Bal. Account Type" := GetAccountTypeEnum(balaccttype);

        GenJournalLine.Description := description;
        GenJournalLine.Amount := amount;
        GenJournalLine."Amount (LCY)" := amountlcy;

        if amount <> amountlcy then
            GenJournalLine."Currency Code" := 'USD';

        // Add dimensions before inserting
        AddDimension(TempDimSetEntry, 'ASSET CLASS', assetclass);
        AddDimension(TempDimSetEntry, 'BANK', bank);
        AddDimension(TempDimSetEntry, 'CASH_TRANX', cashtranx);
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJournalLine."Dimension Set ID" := NewDimSetID;

        GenJournalLine.Insert(true);

        exit(docno);
    end;

    procedure DACONBuy(
        batchname: Text;
        postingdate: Text;
        docno: Text;
        externaldocno: Text;
        accttype: Text;
        acctno: Text;
        description: Text;
        qty: Integer;
        amount: Decimal;
        amountlcy: Decimal;
        aptype: Text;
        cashtranx: Text;
        invtranx: Text;
        investee: Text;
        template: Text;
        noseries: Code[20];
        postingnoseries: Code[20];
        descript: Text
    ) docuno: Code[20]

    var
        NewDimSetID: Integer;
        vLineNo: Integer;
        NextDocNo: Code[20];
    begin
        if GenJnlTemplate.GET(template) then begin
            CheckGenJournalBatchExists(template, batchname, noseries, postingnoseries, descript);
        end;
        EVALUATE(xPostingDate, postingdate);
        // Get next line number
        vLineNo := GetLastLineNo(template, batchname) + 10000;
        if docno = '' then begin
#pragma warning disable AL0432
            NextDocNo := NoSeriesMgt.GetNextNo(noseries, xPostingDate, true);
#pragma warning restore AL0432
            if NextDocNo = '' then
                Error('Could not generate a document number from No. Series %1.', GenJournalBatch."No. Series");
            docno := NextDocNo;
        end;
        // Create journal line
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := template;
        GenJournalLine."Journal Batch Name" := batchname;
        GenJournalLine."Line No." := vLineNo;
        GenJournalLine."Posting Date" := xPostingDate;
        GenJournalLine."Document No." := docno;
        docno := docno;

        if externaldocno <> '' then
            GenJournalLine."External Document No." := externaldocno;

        // Assign enum Account Type
        GenJournalLine."Account Type" := GetAccountTypeEnum(accttype);
        GenJournalLine."Account No." := acctno;

        GenJournalLine.Description := description;
        GenJournalLine.Quantity := qty;
        GenJournalLine.Amount := amount;
        GenJournalLine."Amount (LCY)" := amountlcy;

        // Add dimensions before inserting
        if (accttype = 'Vendor') then begin
            AddDimension(TempDimSetEntry, 'A/P TYPE', aptype);
        end;
        AddDimension(TempDimSetEntry, 'CASH_TRANX', cashtranx);
        AddDimension(TempDimSetEntry, 'INV_TRANX', invtranx);
        AddDimension(TempDimSetEntry, 'INVESTEE', investee);
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJournalLine."Dimension Set ID" := NewDimSetID;

        GenJournalLine.Insert(true);

        exit(docno);
    end;

    procedure DACONSell(
        batchname: Text;
        postingdate: Text;
        documentno: Text;
        externaldocno: Text;
        accttype: Text;
        acctno: Text;
        description: Text;
        qty: Integer;
        amount: Decimal;
        amountlcy: Decimal;
        aptype: Text;
        cashtranx: Text;
        gainsale: Text;
        invtranx: Text;
        investee: Text;
        template: Text;
        noseries: Code[20];
        postingnoseries: Code[20];
        descript: Text
    ) docno: Code[20]

    var
        NewDimSetID: Integer;
        vLineNo: Integer;
        NextDocNo: Code[20];
    begin
        if GenJnlTemplate.GET(template) then begin
            CheckGenJournalBatchExists(template, batchname, noseries, postingnoseries, descript);
        end;
        EVALUATE(xPostingDate, postingdate);
        // Get next line number
        vLineNo := GetLastLineNo(template, batchname) + 10000;
        if documentno = '' then begin
#pragma warning disable AL0432
            NextDocNo := NoSeriesMgt.GetNextNo(noseries, xPostingDate, true);
#pragma warning restore AL0432
            if NextDocNo = '' then
                Error('Could not generate a document number from No. Series %1.', GenJournalBatch."No. Series");
            documentno := NextDocNo;
        end;
        // Create journal line
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := template;
        GenJournalLine."Journal Batch Name" := batchname;
        GenJournalLine."Line No." := vLineNo;
        GenJournalLine."Posting Date" := xPostingDate;
        GenJournalLine."Document No." := documentno;
        docno := documentno;

        if externaldocno <> '' then
            GenJournalLine."External Document No." := externaldocno;

        // Assign enum Account Type
        GenJournalLine."Account Type" := GetAccountTypeEnum(accttype);
        GenJournalLine."Account No." := acctno;

        GenJournalLine.Description := description;
        GenJournalLine.Quantity := qty;
        GenJournalLine.Amount := amount;
        GenJournalLine."Amount (LCY)" := amountlcy;

        // Add dimensions before inserting
        AddDimension(TempDimSetEntry, 'A/P TYPE', aptype);
        AddDimension(TempDimSetEntry, 'CASH_TRANX', cashtranx);
        if (acctno = '700008') then begin
            AddDimension(TempDimSetEntry, 'GAIN ON SALE', gainsale);
        end;
        AddDimension(TempDimSetEntry, 'INV_TRANX', invtranx);
        AddDimension(TempDimSetEntry, 'INVESTEE', investee);
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJournalLine."Dimension Set ID" := NewDimSetID;

        GenJournalLine.Insert(true);

        exit(docno);
    end;
    #endregion

}


