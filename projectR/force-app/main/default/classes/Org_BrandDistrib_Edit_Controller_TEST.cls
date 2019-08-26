@isTest
private class Org_BrandDistrib_Edit_Controller_TEST {
    
    @isTest static void existing_brand_distrib() {
        Sup_Supplier__c owner = new Sup_Supplier__c(Name = 'Owner', Code__c = 'CD01', Is_Default_NegoScope__c = false);
        insert owner;
        
        Sup_Supplier__c distrib = new Sup_Supplier__c(Name = 'Distrib', Code__c = 'CD02', Is_Default_NegoScope__c = false);
        insert distrib;
        
        Sup_Brand__c brand = new Sup_Brand__c(Name = 'Brand', Brand_owner__c = owner.id);
        insert brand;
        
        Sup_Bra_Distributor__c bra_distr1 = new Sup_Bra_Distributor__c(Brand__c = brand.id, Supplier__c = distrib.id, Status_BDate__c = date.today());
        insert bra_distr1;
        
        Sup_Bra_Distributor__c bra_distr2 = new Sup_Bra_Distributor__c(Brand__c = brand.id, Supplier__c = distrib.id, Status_BDate__c = date.today());    
        ApexPages.currentPage().getParameters().put('retURL', '/');
        ApexPages.StandardController stdController = new ApexPages.StandardController(bra_distr2);
        Org_BrandDistrib_Edit_Controller Org_BrandDistrib_Edit_Controller = new Org_BrandDistrib_Edit_Controller(stdController);
        
        List<Sup_Bra_Distributor__c> lst_bra_distr = [select Name, Brand__c, Supplier__c from Sup_Bra_Distributor__c where Supplier__c = :distrib.Id LIMIT:1];
        
        system.assertEquals(1, lst_bra_distr.size());
        system.assertEquals(brand.id, lst_bra_distr.get(0).Brand__c); 
    }
}