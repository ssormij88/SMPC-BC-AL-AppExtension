query 50103 VendorList
{
    APIGroup = 'SMPC';
    APIPublisher = 'SMPC';
    APIVersion = 'v2.0';
    EntityName = 'VendorEntity';
    EntitySetName = 'VendorEntitySet';
    QueryType = API;

    elements
    {
        dataitem(vendor; Vendor)
        {
            column(no; "No.")
            {
            }
            column(name; Name)
            {
            }
            column(name2; "Name 2")
            {
            }
            column(address; Address)
            {
            }
            column(address2; "Address 2")
            {
            }
        }
    }

    trigger OnBeforeOpen()
    begin

    end;
}
