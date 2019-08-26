/**
 * @author ULiT
 * */
global class ReportsGridDataSource extends VisualEditor.DynamicPickList {
    
    global override VisualEditor.DataRow getDefaultValue() {
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('-- Select --', '');
        return defaultValue;
    }
    
    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows pickListValues = new VisualEditor.DynamicPickListRows();
        for(Folder item : [SELECT Id, Name, DeveloperName 
                           FROM Folder 
                           WHERE Type = 'Report'
                           AND (DeveloperName != null OR DeveloperName != '') 
                           ORDER By Name])
        {
            VisualEditor.DataRow pickListValue = new VisualEditor.DataRow(item.Name, String.valueOf(item.Id));
            pickListValues.addRow(pickListValue);
        }
        return pickListValues;
    }
}