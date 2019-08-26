public with sharing class Main_App_launcher_Controller {
    
    public List<AppMenuItem> appMenuItems {get; set;}

    public Main_App_launcher_Controller() {
        // fields to be checked
        String [] appMenuItemsFields = new String [] {'Id', 'Name', 'Label', 'ApplicationId', 'StartUrl', 'LogoUrl', 'IconUrl'};
        // Obtaining the field name/token map for the object
        Map<String,Schema.SObjectField> a = Schema.SObjectType.AppMenuItem.fields.getMap();
        for (String fieldToCheck : appMenuItemsFields) {
            // Check if the user has read access on each field
            if (!a.get(fieldToCheck).getDescribe().isAccessible()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to read AppMenuItem')); 
            }
        }
        this.appMenuItems = [SELECT Id, Name, Label, ApplicationId, StartUrl, LogoUrl, IconUrl
                             FROM AppMenuItem
                             WHERE Name IN ('myNego', 'myOrg', 'myStrategy', 'myRisk', 'myCash',
                                            'myOffer', 'myProof', 'myPromo', 'myConnect')
                             ORDER BY SortOrder];
    }
    @AuraEnabled
    public static String loadApps() {
        String json = JSON.serialize([SELECT Id, Name, Label, ApplicationId, StartUrl, LogoUrl, IconUrl
                                      FROM AppMenuItem
                                      WHERE Name IN ('myNego', 'myOrg', 'myStrategy', 'myRisk', 'myCash',
                                                     'myOffer', 'myProof', 'myPromo', 'myConnect')
                                      ORDER BY SortOrder]);
        return json;
    }
}