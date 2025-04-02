
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

    [ServiceEnabled]
    procedure CreatetCRJ(amount: Decimal; particulars: Text; accountno: Text; bankcode: Text; tranxtype: Text; stockcode: Text; batchname: Text; exdocno: Text; postingdate: Text; accttype: Text; documentno: Text; trans: Text) "50": Code[20]
    var
        xPostingDate: Date;
    begin
        JournalBatchName := BatchName;
        GenJnlTemplate.RESET;
        GenJnlTemplate.GET('CASH RECEI');

        GenJournalBatch.RESET;
        GenJournalBatch.SETFILTER(Name, JournalBatchName);
        GenJournalBatch.SETFILTER("Journal Template Name", 'CASH RECEI');
        GenJournalBatch.SETFILTER("Bal. Account Type", FORMAT(GenJnlTemplate."Bal. Account Type"::"G/L Account"));

        IF NOT GenJournalBatch.FINDLAST THEN BEGIN
            GenJournalBatch.INIT;
            GenJournalBatch.Name := JournalBatchName;
            GenJournalBatch."Journal Template Name" := 'CASH RECEI';
            GenJournalBatch."Bal. Account Type" := GenJnlTemplate."Bal. Account Type"; //GL Account

            GenJournalBatch."No. Series" := GenJnlTemplate."No. Series";
            GenJournalBatch."Posting No. Series" := 'GJNL-RCPT';// GenJnlTemplate."No. Series";

            GenJournalBatch.INSERT(TRUE);
        END;


        CLEAR(NoSeriesMgt);

        GenJournalLine.INIT;
        GenJournalLine."Journal Template Name" := 'CASH RECEI';
        GenJournalLine."Journal Batch Name" := JournalBatchName;
        EVALUATE(xPostingDate, PostingDate);
        GenJournalLine."Posting Date" := xPostingDate;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment; //payment or credit memo

        IF DocumentNo = '' THEN
#pragma warning disable AL0432
            GenJournalLine."Document No." := NoSeriesMgt.GetNextNo('GJNL-RCPT', WORKDATE, TRUE);
#pragma warning restore AL0432
        IF DocumentNo <> '' THEN
            GenJournalLine."Document No." := DocumentNo;

        GenJournalLine."External Document No." := ExDocNo;
        GenJournalLine.VALIDATE(GenJournalLine.Amount, Amount);

        IF Trans = 'CDC' THEN
            GenJournalLine."Bal. Account No." := '420004'

        ELSE IF Trans = 'CDI' THEN
            GenJournalLine."Bal. Account No." := '310001';

        IF AcctType = 'Bank Account' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Bank Account"
        ELSE IF AcctType = 'G/L Account' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account"
        ELSE IF AcctType = 'Vendor' THEN
            GenJournalLine."Account Type" := GenJournalLine."Account Type"::"Vendor";

        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";//balancing account

        IF AcctType = 'Vendor' then
            GenJournalLine."WHT Business Posting Group PHL" := 'V_CORP';

        IF accountno = '700008' then
            GenJournalLine."Gen. Prod. Posting Group" := 'GL';

        //GenJournalLine.Particulars:= Particulars;//description
        GenJournalLine.Description := Particulars;

        OldDimSetID := GenJournalLine."Dimension Set ID";


        //DIMENSION


        TempDimSetEntry.DELETEALL;
        TempDimSetEntry.INIT;
        IF Trans IN ['CDC', 'SC'] THEN
            TempDimSetEntry.VALIDATE("Dimension Code", 'BANK')//Dimension Code
        ELSE IF Trans IN ['CDI', 'SI'] THEN
            TempDimSetEntry.VALIDATE("Dimension Code", 'ACCOUNT NAME');
        TempDimSetEntry.VALIDATE("Dimension Value Code", BankCode);//Value 
        TempDimSetEntry.INSERT;

        TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'TRANX');//Dimension Code
        TempDimSetEntry.VALIDATE("Dimension Value Code", TranxType);//Value 
        TempDimSetEntry.INSERT;

        TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'INVESTEE');//Dimension Code
        TempDimSetEntry.VALIDATE("Dimension Value Code", StockCode);//Value 
        TempDimSetEntry.INSERT;

        TempDimSetEntry.INIT;
        TempDimSetEntry.Validate("Dimension Code", 'INV_TRANX');
        TempDimSetEntry.Validate("Dimension Value Code", '102');
        TempDimSetEntry.INSERT;

        TempDimSetEntry.RESET;
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry); //get new DimSetID, after existing PO dimensions are modified

        GenJournalLine."Dimension Set ID" := NewDimSetID;
        GenJournalLine."Line No." := GetLastLineNo('CASH RECEI', JournalBatchName) + 10000;
        GenJournalLine.INSERT(TRUE);

        EXIT(GenJournalLine."Document No.");
    end;

    local procedure GetLastLineNo(vJournalTemplateName: Code[20]; vBatchName: Code[30]) rvLineNo: Integer
    var
        vGenJournalLine: Record "Gen. Journal Line";
    begin
        vGenJournalLine.RESET;
        vGenJournalLine.SETFILTER("Journal Template Name", vJournalTemplateName);
        vGenJournalLine.SETFILTER("Journal Batch Name", vBatchName);
        IF vGenJournalLine.FINDLAST THEN
            EXIT(vGenJournalLine."Line No.");

        EXIT(0);
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

        if BankCode <> '' then
            TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'BANK');
        TempDimSetEntry.VALIDATE("Dimension Value Code", BankCode);//Value 
        TempDimSetEntry.INSERT;

        if TranxType <> '' then
            TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'TRANX');//Dimension Code
        TempDimSetEntry.VALIDATE("Dimension Value Code", TranxType);//Value 
        TempDimSetEntry.INSERT;

        if StockCode <> '' then
            TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'INVESTEE');//Dimension Code
        TempDimSetEntry.VALIDATE("Dimension Value Code", StockCode);//Value 
        TempDimSetEntry.INSERT;

        if InvTranx <> '' then
            TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'INV_TRANX');//Dimension Code
        TempDimSetEntry.VALIDATE("Dimension Value Code", InvTranx);//Value 
        TempDimSetEntry.INSERT;

        if APType <> '' then
            TempDimSetEntry.INIT;
        TempDimSetEntry.VALIDATE("Dimension Code", 'A/P TYPE');//Dimension Code
        TempDimSetEntry.VALIDATE("Dimension Value Code", APType);//Value 
        TempDimSetEntry.INSERT;

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

            GenJournalBatch."No. Series" := NoSeries;
            GenJournalBatch."Posting No. Series" := GenJnlTemplate."Posting No. Series";
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
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry); //get new DimSetID, after existing PO dimensions are modified

        GenJournalLine."Dimension Set ID" := NewDimSetID;
        GenJournalLine."Line No." := GetLastLineNo(SourceCode, JournalBatchName) + 10000;
        GenJournalLine.INSERT(TRUE);

        EXIT(GenJournalLine."Document No.");
    end;

}


