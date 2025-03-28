query 50102 "Bank Account"
{
    APIGroup = 'SMPC';
    APIPublisher = 'SMPC';
    APIVersion = 'v2.0';
    EntityName = 'BankAccountEntity';
    EntitySetName = 'BankAccountEntitySet';
    QueryType = API;

    elements
    {
        dataitem(bankAccount; "Bank Account")
        {
            column(bankAccountNo; "Bank Account No.")
            {
            }
            column(name; Name)
            {
            }
            column(no; "No.")
            {
            }
            column(blocked; Blocked)
            {

            }
        }
    }

    trigger OnBeforeOpen()
    begin
        CurrQuery.SetRange(blocked, false);
    end;
}
