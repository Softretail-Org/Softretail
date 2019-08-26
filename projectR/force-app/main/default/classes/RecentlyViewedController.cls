/**
 * Class that controls Recently Viewed Items.
 **/
public with sharing class RecentlyViewedController {
    public List<String> selectedObjects {get; set;}
    Public RecentlyViewedController(){
        selectedObjects = new List<String>();
    }
    // Fill list of custom objects
    public List<SelectOption> getObjectNames()
    {
        List<SelectOption> objNames = new List<SelectOption>();
        List<schema.sObjectType> allObjects = schema.getGlobalDescribe().Values();
        for(schema.SObjectType objTyp :allObjects){
            if(objTyp.getDescribe().isCustom()){
                objNames.add(new SelectOption(objTyp.getDescribe().getName(), objTyp.getDescribe().getLabel()));                
            }
        }
        return objNames;
    }
    // Recent Items Batch
    public PageReference submitRecentItemsBatch() {        
        if (selectedObjects != null) {
            Id batchInstanceId = Database.executeBatch(new RecentItemsBatch('RecentlyViewedController', selectedObjects), 150);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Recent Items', (String)batchInstanceId})));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Validation_Error));
        }
        return null;
    }
}