global with sharing class Nego360_Main_Selection_Controller_v2 extends NegoptimBaseController {

 
    public Sup_Supplier__c selectedSupplier {get; set;}
    public Id selectedSupplierId {get; set;}
    /***
    public String supplierCode {get; set;}
    public String supplierName {get; set;}
    ***/
    public String selectedNegoYear {get; set;}
    
    public Nego360_Main_Selection_Controller_v2() {
        // fields to be checked
        String [] suppliersFields = new String [] {'Id', 'Name', getFieldName('Code__c')};
        checkAccessibility(Sup_Supplier__c.SObjectType, suppliersFields);
        
        selectedSupplier = new Sup_Supplier__c();
        selectedNegoYear = String.valueOf(Date.today().year() + 1);
    }
    
    @RemoteAction
    global static String findSupplier(String searchTerm) {
        String searchTermLike = '%' + searchTerm + '%';
        // fields to be checked
        String [] suppliersFields = new String [] {'Id', 'Name', NegoptimHelper.normalizeAPIName('Code__c')};
        if(NegoptimHelper.checkAccessibility(Sup_Supplier__c.SObjectType, suppliersFields)) {
            List<Sup_Supplier__c> listSuppliers = [SELECT Id, Name, Code__c FROM Sup_Supplier__c WHERE Name LIKE :searchTermLike OR Code__c LIKE :searchTermLike];
            String JSONSuppliersList = JSON.serialize(listSuppliers);
            return JSONSuppliersList;
        }
        return null;
    }
    
    public List<SelectOption> getListYears() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer year = Date.today().year() - 2 ; year <= Date.today().year() + 3 ; year++) {
            options.add( new SelectOption(String.valueOf(year), String.valueOf(year)) );
        }
        return options;
    }
    
    public PageReference goToConditionScreen() {
        try {
            PageReference pageRef = new PageReference('/apex/Nego360_Main_Edit_v2');
            pageRef.getParameters().put('supplier', selectedSupplierId);
            pageRef.getParameters().put('negoyear', selectedNegoYear);
            return pageRef;
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
            return null;
        }
    }

}