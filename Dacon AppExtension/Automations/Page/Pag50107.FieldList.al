page 50107 "Field List"
{
    ApplicationArea = All;
    Caption = 'Field List';
    PageType = List;
    SourceTable = "Field";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(TableNo; Rec.TableNo)
                {
                    ToolTip = 'Specifies the table number.';
                }
                field(TableName; Rec.TableName)
                {
                    ToolTip = 'Specifies the name of the table.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the ID number of the field in the table.';
                }
                field(FieldName; Rec.FieldName)
                {
                    ToolTip = 'Specifies the name of the field in the table.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ToolTip = 'Specifies the caption of the field, that is, the name that will be shown in the user interface.';
                }
                field("Type"; Rec."Type")
                {
                    ToolTip = 'Specifies the type of the field in the table, which indicates the type of data it contains.';
                }
                field(IsPartOfPrimaryKey; Rec.IsPartOfPrimaryKey)
                {
                    ToolTip = 'Specifies the value of the IsPartOfPrimaryKey field.', Comment = '%';
                }
                field(Len; Rec.Len)
                {
                    ToolTip = 'Specifies the value of the Len field.', Comment = '%';
                }

                field(ObsoleteReason; Rec.ObsoleteReason)
                {
                    ToolTip = 'Specifies the value of the ObsoleteReason field.', Comment = '%';
                }
                field(ObsoleteState; Rec.ObsoleteState)
                {
                    ToolTip = 'Specifies the value of the ObsoleteState field.', Comment = '%';
                }
                field(OptimizeForTextSearch; Rec.OptimizeForTextSearch)
                {
                    ToolTip = 'Specifies the value of the OptimizeForTextSearch field.', Comment = '%';
                }
                field(OptionString; Rec.OptionString)
                {
                    ToolTip = 'Specifies the option string.';
                }
                field(RelationFieldNo; Rec.RelationFieldNo)
                {
                    ToolTip = 'Specifies the value of the RelationFieldNo field.', Comment = '%';
                }
                field(RelationTableNo; Rec.RelationTableNo)
                {
                    ToolTip = 'Specifies the ID number of a table from which the field on the current table gets data. For example, the field can provide a lookup into another table.';
                }
                field(SQLDataType; Rec.SQLDataType)
                {
                    ToolTip = 'Specifies the value of the SQLDataType field.', Comment = '%';
                }


            }
        }
    }
}
