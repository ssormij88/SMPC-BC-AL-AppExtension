query 50104 "Bank Ledger Entry"
{
    APIGroup = 'SMPC';
    APIPublisher = 'SMPC';
    APIVersion = 'v1.0';
    EntityName = 'BankAccountLedgerEntity';
    EntitySetName = 'BankAccountLedgerEntitySet';
    QueryType = API;

    elements
    {
        dataitem(Bank_Account_Ledger_Entry; "Bank Account Ledger Entry")
        {
            filter(Posting_Date_Filter; "Posting Date") { }
            column(Entry_No; "Entry No.") { }
            column(Bank_Account_No; "Bank Account No.") { }
            column(Posting_Date; "Posting Date") { }
            column(Amount; Amount) { }
            column(Remaining_Amount; "Remaining Amount") { }
            column(Amount_LCY; "Amount (LCY)") { }
            column(Description; "Description") { }
            dataitem(Department_Dimension; "Dimension Set Entry")
            {
                DataItemLink = "Dimension Set ID" = Bank_Account_Ledger_Entry."Dimension Set ID";
                SqlJoinType = InnerJoin;

                filter(CashTranx_Code; "Dimension Code") { }

                column(CashTranx_Value; "Dimension Value Code")
                {
                    Caption = 'ValueCode';
                }

                column(CashTranx_Value_name; "Dimension Value Name")
                {
                    Caption = 'ValueName';
                }
            }
        }
    }

    trigger OnBeforeOpen()
    var
        StartDate: Date;
        EndDate: Date;
    begin
        EndDate := CalcDate('<CM>', Today());
        StartDate := CalcDate('<-8M>', EndDate);
        SetRange(Posting_Date_Filter, StartDate, EndDate);
        SetRange(CashTranx_Code, 'CASH_TRANX');
    end;
}