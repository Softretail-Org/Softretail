/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for brand insertion inside negoscope page 
*
*/
@isTest
private class Trg_Org_Supplier_Negoscope_Brand_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Sup_Supplier__c supplier1;
    private static Sup_Supplier__c supplier2;
    private static Orga_HE__c department1;
    private static Orga_HE__c section1;
    private static Sup_Brand__c brand1;
    private static Sup_Brand__c brand2;
    private static Sup_sup_NegoScope__c negoScope;
    private static Sup_NS_Brand__c negoScopeBrand;
    
    static void init() {
        try {
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();

            // Create Supplier
            supplier1 = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001',CurrencyIsoCode = currencyIsoCode, Is_Default_NegoScope__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier1;
            // Create Department
            department1 = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Elt Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Purchases_DB_Upper_Starting_Point__c = true);
            insert department1;
            // Create Section        
            section1 = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department1.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c = false);
            insert section1;
            // Create brand 
            brand1 = new Sup_Brand__c(Name = 'Brand 1', Brand_Owner__c = supplier1.Id);
            insert brand1;
            // Create Supplier 2
            supplier2 = new Sup_Supplier__c(Name = 'Supplier 002', Code__c = 'SUP002',CurrencyIsoCode = currencyIsoCode, Is_Default_NegoScope__c = false);
            insert supplier2;
            // Create brand 2
            brand2 = new Sup_Brand__c(Name = 'Brand 2', Brand_Owner__c = supplier2.Id);
            insert brand2;	
            // Create negoScope
            negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier1.Id,Is_All__c= false, Is_All_Brands__c = false, Is_All_HE__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert negoScope;
            // create brand for negoscope
            negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brand1.Id, Supplier__c = supplier1.Id, Sup_sup_NegoScope__c = negoScope.Id);
            insert negoScopeBrand;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /*	
* Test validation  prevent adding same brand on negoscope page 
*/
    @isTest static void test_createBrandNegoScope() {
        init();
        
        Sup_NS_Brand__c negoScopeBrand2 = new Sup_NS_Brand__c(Sup_Scope_Brand__c =brand1.Id, Supplier__c = supplier1.Id, Sup_sup_NegoScope__c = negoScope.Id);
        Test.startTest();        
        Database.SaveResult result = Database.insert(negoScopeBrand2, false); 
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Brand_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
        
    }
    
    /*
* Test validation  prevent updating same brand on negoscope page 
*/
    @isTest static void test_updateBrandNegoScope() {
        init();
        
        Sup_NS_Brand__c negoScopeBrand2 = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brand2.Id, Supplier__c = supplier1.Id, Sup_sup_NegoScope__c = negoScope.Id);
        insert negoScopeBrand2;
        Sup_NS_Brand__c selectedBrandNegoScope= [SELECT id,Sup_Scope_Brand__c FROM Sup_NS_Brand__c WHERE id = :negoScopeBrand.Id ];
        selectedBrandNegoScope.Sup_Scope_Brand__c = brand2.Id;
        Test.startTest();        
        Database.SaveResult result = Database.update(selectedBrandNegoScope, false); 
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Brand_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
        
    }
    
    /*
* Test validation  prevent addin same brand on negoscope page on mass mode 
*/
    @isTest static void test_CreateMultiBrandNegoScope() {
        init();
        
        List<Sup_NS_Brand__c> lstBrandNegoscope = new List<Sup_NS_Brand__c>();
        Sup_NS_Brand__c negoScopeBrand2 = new Sup_NS_Brand__c(Sup_Scope_Brand__c =brand1.Id, Supplier__c = supplier1.Id, Sup_sup_NegoScope__c = negoScope.Id);
        Sup_NS_Brand__c negoScopeBrand3 = new Sup_NS_Brand__c(Sup_Scope_Brand__c =brand1.Id, Supplier__c = supplier1.Id, Sup_sup_NegoScope__c = negoScope.Id);
        lstBrandNegoscope.add(negoScopeBrand2);
        lstBrandNegoscope.add(negoScopeBrand3);
        Test.startTest();        
        List<Database.Saveresult> insertResults = Database.insert(lstBrandNegoscope, false); 
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            System.assert(!result.isSuccess());
            System.assert(result.getErrors().size() > 0);
            System.assertEquals(System.Label.MSG_Brand_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
        }
        
    }
}