query 50100 "Dimension List"
{
    APIGroup = 'SMPC';
    APIPublisher = 'SMPC';
    APIVersion = 'v2.0';
    EntityName = 'DimensionEntity';
    EntitySetName = 'DimensionEntitySet';
    QueryType = API;

    elements
    {
        dataitem(dimension; Dimension)
        {
            column("code"; "Code")
            {
            }
            column(description; Description)
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
