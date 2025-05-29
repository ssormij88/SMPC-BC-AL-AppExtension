
codeunit 50102 EquityWebServices
{

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
            GenJournalBatch."No. Series" := 'GJNL-RCPT';
            GenJournalBatch."Posting No. Series" := GenJnlTemplate."Posting No. Series";
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
            GenJournalLine."Document No." := NoSeriesMgt.GetNextNo('GJNL-RCPT', WORKDATE, TRUE);
#pragma warning restore AL0432
        IF documentno <> '' THEN
            GenJournalLine."Document No." := documentno;

        GenJournalLine."External Document No." := exdocno;
        GenJournalLine.VALIDATE(GenJournalLine.Amount, amount);

        IF trans = 'CDC' THEN
            GenJournalLine."Bal. Account No." := '420004'

        ELSE IF trans = 'CDI' THEN
            GenJournalLine."Bal. Account No." := '310001';

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
        IF (trans = 'CDC') or (trans = 'SC') or (trans = 'FC') or (trans = 'BC') THEN
            TempDimSetEntry.VALIDATE("Dimension Code", 'BANK')
        ELSE IF (trans = 'CDI') or (trans = 'SI') THEN
            TempDimSetEntry.VALIDATE("Dimension Code", 'ACCOUNT NAME');
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
            GenJournalBatch."No. Series" := 'JVNUMBER';
            GenJournalBatch."Posting No. Series" := GenJnlTemplate."Posting No. Series";
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

        Evaluate(dDocumentDate, documentdate);
        Evaluate(dPostingDate, postingdate);
        //RDSHeader."Requestor ID" := RequestId;
        RDSHeader."Request Code" := requestcode;
        RDSHeader."Request Description" := requestdesc;
        RDSHeader."Request Date" := Today();
        RDSHeader."Document Date" := dDocumentDate;
        RDSHeader."Posting Date" := dPostingDate;
        RDSHeader.Insert(true);

        if RDSHeader.Get(RDSHeader."No.") then begin
            RDSHeader."Requestor ID" := requestid;
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

    [ServiceEnabled]
    procedure GetDimension(BankCode: Text; TranxType: Text; StockCode: Text; InvTranx: Text; APType: Text): Integer
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

    [ServiceEnabled]
    procedure DACONNAVEntries(NoSeries: Text; SourceCode: Text; BatchName: Text; PostingDate: Text; DocumentType: Text; DocumentNo: Text; ExDocNo: Text;
        Amount: Decimal; AccountType: Text; AccountNo: Text; BalAccountType: Text; BalAccountNo: Text; Description: Text; Particulars: Text;
        TranxType: Text; IntIncome: Text; AssetClass: Text) "50": Code[20]
    var
        xPostingDate: Date;
    begin
        JournalBatchName := BatchName;
        GenJnlTemplate.RESET;
        GenJnlTemplate.GET(SourceCode);

        GenJournalBatch.RESET;
        GenJournalBatch.SETFILTER(Name, JournalBatchName);
        GenJournalBatch.SETFILTER("Journal Template Name", SourceCode);
        GenJournalBatch.SETFILTER("Bal. Account Type", FORMAT(GenJnlTemplate."Bal. Account Type"::"G/L Account"));

        IF NOT GenJournalBatch.FINDLAST THEN BEGIN
            GenJournalBatch.INIT;
            GenJournalBatch.Name := JournalBatchName;
            GenJournalBatch."Journal Template Name" := SourceCode;
            GenJournalBatch."Bal. Account Type" := GenJnlTemplate."Bal. Account Type";

            GenJournalBatch."No. Series" := GenJnlTemplate."No. Series";
            GenJournalBatch."Posting No. Series" := 'GJNL-RCPT';
            GenJournalBatch.INSERT(TRUE);
        END;

        CLEAR(NoSeriesMgt);

        GenJournalLine.INIT;
        GenJournalLine."Journal Template Name" := SourceCode;
        GenJournalLine."Journal Batch Name" := JournalBatchName;
        EVALUATE(xPostingDate, PostingDate);
        GenJournalLine."Posting Date" := xPostingDate;
        GenJournalLine."Account No." := AccountNo;

        IF AssetClass = 'PLACEMENT' THEN
            GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;

        IF DocumentNo = '' THEN
#pragma warning disable AL0432
            GenJournalLine."Document No." := NoSeriesMgt.GetNextNo(NoSeries, WORKDATE, TRUE);
#pragma warning restore AL0432
        IF DocumentNo <> '' THEN
            GenJournalLine."Document No." := DocumentNo;

        GenJournalLine."External Document No." := ExDocNo;
        GenJournalLine.VALIDATE(GenJournalLine.Amount, Amount);

        IF AccountType = 'Bank Account' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Bank Account"
        ELSE IF AccountType = 'G/L Account' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";

        IF BalAccountType = 'Bank Account' THEN
            GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account"
        ELSE IF BalAccountType = 'Bank Account' THEN
            GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";

        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account No." := BalAccountNo;
        GenJournalLine.Description := Description;
        //GenJournalLine.Particulars := Particulars;

        //DIMENSION


        TempDimSetEntry.DELETEALL;

        TempDimSetEntry.INIT;
        IF AssetClass = 'SWAP PTS' THEN
            TempDimSetEntry.VALIDATE("Dimension Code", 'SUSPENSE')//Dimension Code
        ELSE
            TempDimSetEntry.VALIDATE("Dimension Code", 'INTEREST INCOME');
        TempDimSetEntry.VALIDATE("Dimension Value Code", IntIncome);//Value 
        TempDimSetEntry.INSERT;

        TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'TRANX');//Dimension Code
        TempDimSetEntry.VALIDATE("Dimension Value Code", TranxType);//Value 
        TempDimSetEntry.INSERT;

        TempDimSetEntry.RESET;
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJournalLine."Dimension Set ID" := NewDimSetID;
        GenJournalLine."Line No." := GetLastLineNo(SourceCode, JournalBatchName) + 10000;
        GenJournalLine.INSERT(TRUE);

        EXIT(GenJournalLine."Document No.");
    end;
}


