public with sharing class Org_BrandDistrib_Edit_Controller extends NegoptimBaseController {
    
    public Org_BrandDistrib_Edit_Controller(ApexPages.StandardController stdController) {     
        if(stdController.getId() == null) {
            Sup_Bra_Distributor__c instance = (Sup_Bra_Distributor__c) stdController.getRecord();
            // fields to be checked
            if(checkAccessibility(Sup_Brand__c.SObjectType, new String[] { 'Name' })) {
                List<Sup_Brand__c> brands = [SELECT Name FROM Sup_Brand__c WHERE Id = :instance.Brand__c LIMIT 1];
                if(!brands.isEmpty())
                    instance.Name = brands[0].Name;
            }
        }
    }
}