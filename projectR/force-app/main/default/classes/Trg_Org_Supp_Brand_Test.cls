/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for brands section 
*/
@isTest
private class Trg_Org_Supp_Brand_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier1;
    private static Sup_Supplier__c supplier2;
    private static Sup_sup_NegoScope__c negoScope;
    private static Sup_NS_PG__c negoScopePg;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Supplier_PG_Mapping__c pg;
    
    static void init() {
    	try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Create Country
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
			// Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            Orga_BU__c region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
            // Create Suppliers without default nego scope
            supplier1 = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Is_Default_NegoScope__c = false, Country_origin__c = country.Id, Status__c = 'Active',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            supplier2 = new Sup_Supplier__c(Name = 'Supplier 002', Code__c = 'SUP002', CurrencyIsoCode = currencyIsoCode, Is_Default_NegoScope__c = false, Country_origin__c = country.Id, Status__c = 'Active',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert new List<Sup_Supplier__c>{supplier1, supplier2};
			// Create Department
			department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Purchases_DB_Upper_Starting_Point__c = true);
	        insert department;
            // Create Section        
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c = false);
            insert section;
            // Create Brand
            brand = new Sup_Brand__c(Name = supplier1.Name + ' Brand 1', Brand_Owner__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
            insert brand;
            // Create PG
            pg = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' PG 1', Brand__c = brand.Id, SNA_Code__c = '1', GIMA_Code__c = '1', Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier1.Id);
            insert pg;
            // Create negoScope
            negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope Supplier 001', Supplier__c = supplier1.Id, Is_All_Brands__c = false, Is_All_HE__c = false, Incl_NewBrand__c = false, Incl_NewProduct__c = false, Is_All__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert negoScope;
            // add pg to negoscope 
            negoScopePg = new Sup_NS_PG__c(Sup_PG__c = pg.Id, Supplier__c = supplier1.Id, Sup_sup_NegoScope__c = negoScope.Id);
            insert negoScopePg;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    /*
     * Test validation on brand  creation with a same name  
     */
    @isTest static void test_createBrandDuplicateName() {
        init();
        // add a brand that  exist
        Sup_Brand__c brand2 = new Sup_Brand__c(Name = brand.Name, Brand_Owner__c = supplier1.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(brand2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Brand_Name_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    /*
     * Test validation on brand  when supplier is updated  
     */
    @isTest static void test_updateBrandSupplierDuplicateName() {
        init();
        Sup_Brand__c selectedBrand = [SELECT Brand_Owner__c FROM Sup_Brand__c WHERE id = :brand.Id];
        selectedBrand.Brand_Owner__c = supplier2.id;
        Test.startTest();
        Database.SaveResult result = Database.update(selectedBrand, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Cannot_Change_Current_Supplier, result.getErrors()[0].getMessage());
    }
    
    /*
     * Test validation success of brand update 
     */
    @isTest static void test_updateBrandSupplierSuccess() {
        init();
        

            Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Supplier 003', Code__c = 'SUP003',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Create brand 
            Sup_Brand__c brand3 = new Sup_Brand__c(Name = 'Brand 3', Brand_Owner__c = supplier2.Id);
            insert brand3;
            Sup_Brand__c selectedBrand = [SELECT Brand_Owner__c FROM Sup_Brand__c WHERE id = :brand3.Id ];
            selectedBrand.Brand_Owner__c = supplier.id;
            
            Test.startTest();        
            Database.SaveResult result = Database.update(selectedBrand, false); 
            Test.stopTest();
            System.assert(result.isSuccess());
            System.assert(result.getErrors().size()==0);
            System.assertEquals(0,result.getErrors().size());
             
    }
    /*
     * Test validation on multi brand delete  
     */
    @isTest static void test_deleteMultiBrandSupplier() {
        init();

            Sup_Brand__c selectedBrand = [SELECT Id FROM Sup_Brand__c WHERE Id = :brand.Id];
            Test.startTest();        
            Database.DeleteResult result = Database.delete(selectedBrand, false); 
            Test.stopTest();
            System.assert(!result.isSuccess());
            System.assert(result.getErrors().size() > 0);
            System.assertEquals(System.Label.MSG_Cannot_Change_Current_Supplier, result.getErrors()[0].getMessage());
     
    }
    
    /*
     * Test to validation if all brand in checked in negoscope page   
     */
    @isTest static void test_includeAllBrandInNegoScope() {
        init();

            // Create negoScope
            Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = 'New Nego Scope 2', Supplier__c = supplier1.Id, Is_All_Brands__c = true, Is_All_HE__c = false,Incl_NewBrand__c = false,Incl_NewProduct__c = false,Is_All__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert newNegoScope;
            // create new brand
            Sup_Brand__c newBrand = new Sup_Brand__c(Name = 'New Brand 1', Brand_Owner__c = supplier1.Id);
            insert newBrand;
            List<Sup_NS_Brand__c> allNegoScopeBrand = [Select Id FROM Sup_NS_Brand__c WHERE Supplier__c = :supplier1.Id];
            System.assertEquals(1, allNegoScopeBrand.size());
      
    }
    
    /*
    * Test to validation if new band added to negoscope when new brand is checked in negoscope page   
    */
    @isTest static void test_includeNewBrandInNegoScope() {
        init();
      
            // Create negoScope 
            Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = 'New Nego Scope 2', Supplier__c = supplier1.Id, Is_All_Brands__c = false, Is_All_HE__c = false,Incl_NewBrand__c = true,Incl_NewProduct__c = false,Is_All__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert newNegoScope;
            // create new brand
            Sup_Brand__c newBrand = new Sup_Brand__c(Name = 'New Brand 2', Brand_Owner__c = supplier1.Id);
            insert newBrand;
            List<Sup_NS_Brand__c> allNegoScopeBrand = [Select Id FROM Sup_NS_Brand__c WHERE Supplier__c = :supplier1.Id];
            System.assertEquals(1, allNegoScopeBrand.size());
      
    }
    
    /*
    * Test to validation if list of all new bands are added to negoscope when all brand is checked  negoscope page   
    */
    @isTest static void test_includeListNewBrandInNegoScope() {
        init();
      
            // Create negoScope
            Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = 'New Nego Scope 2', Supplier__c = supplier1.Id, Is_All_Brands__c = true, Is_All_HE__c = false,Incl_NewBrand__c = false,Incl_NewProduct__c = false,Is_All__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert newNegoScope;
            List<Sup_Brand__c> lstBrands = new List<Sup_Brand__c>();
            Sup_Brand__c brand3 = new Sup_Brand__c(Name = 'NewBrand 2', Brand_Owner__c = supplier1.Id);
            Sup_Brand__c brand4 = new Sup_Brand__c(Name = 'NewBrand 3', Brand_Owner__c = supplier1.Id);
            lstBrands.add(brand3);
            lstBrands.add(brand4);
            insert lstBrands;
            List<Sup_NS_Brand__c> allNegoScopeBrand = [Select Id FROM Sup_NS_Brand__c WHERE Supplier__c = :supplier1.Id];
            System.assertEquals(2, allNegoScopeBrand.size());
     
    }
    
    /*
     * Test to validation if list of all new bands are added to negoscope when new brand is checked in negoscope page   
     */
    @isTest static void test_includeListAllBrandInNegoScope() {
        init();
  
            // Create negoScope
            Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = 'New Nego Scope 2', Supplier__c = supplier1.Id, Is_All_Brands__c = false, Is_All_HE__c = false,Incl_NewBrand__c = true,Incl_NewProduct__c = false,Is_All__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert newNegoScope;
            List<Sup_Brand__c> lstBrands = new List<Sup_Brand__c>();
            Sup_Brand__c brand3 = new Sup_Brand__c(Name = 'NewBrand 2', Brand_Owner__c = supplier1.Id);
            Sup_Brand__c brand4 = new Sup_Brand__c(Name = 'NewBrand 3', Brand_Owner__c = supplier1.Id);
            lstBrands.add(brand3);
            lstBrands.add(brand4);
            insert lstBrands;
            List<Sup_NS_Brand__c> allNegoScopeBrand = [Select Id FROM Sup_NS_Brand__c WHERE Supplier__c = :supplier1.Id];
            system.debug(allNegoScopeBrand);
            System.assertEquals(2, allNegoScopeBrand.size());
        
    }
    
    /*
     * Test validation on brand multiple creation   
     */
    @isTest static void test_createMultiBrand() {
        init();
        List<Sup_Brand__c> lstBrands = new List<Sup_Brand__c>();
        Sup_Brand__c mainBrand = new Sup_Brand__c(Name = 'Main Brand', Brand_Owner__c = supplier1.Id); 
        insert mainBrand;
        Sup_sup_NegoScope__c negoScope3 = new Sup_sup_NegoScope__c(Name = 'Nego Scope 3', Supplier__c = supplier1.Id, Is_All_Brands__c = true, Is_All_HE__c = false, Incl_NewBrand__c = false, Incl_NewProduct__c = false, Is_All__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope3;
        Sup_sup_NegoScope__c negoScope4 = new Sup_sup_NegoScope__c(Name = 'Nego Scope 4', Supplier__c = supplier1.Id, Is_All_Brands__c = true, Is_All_HE__c = false, Incl_NewBrand__c = false, Incl_NewProduct__c = false, Is_All__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope4;
        Sup_Brand__c brand2 = new Sup_Brand__c(Name = 'Multi Brand 2', Brand_Owner__c = supplier1.Id); 
        Sup_Brand__c brand3 = new Sup_Brand__c(Name = 'Multi Brand 3', Brand_Owner__c = supplier1.Id); 
        Sup_Brand__c brand4 = new Sup_Brand__c(Name = 'Multi Brand 4', Brand_Owner__c = supplier1.Id); 
        lstBrands.add(brand2);
        lstBrands.add(brand3);
        lstBrands.add(brand4);
        insert lstBrands;
        List<Sup_Brand__c> allBrand = [Select Id FROM Sup_Brand__c WHERE Brand_Owner__c = :supplier1.Id];
        System.assertEquals(5, allBrand.size());
    }
    
    /*
     * Test validation on brand multiple creation same name 
     */
    @isTest static void test_createMultiSameBrand() {
        init();
        List<Sup_Brand__c> lstBrands = new List<Sup_Brand__c>();
        Sup_Brand__c brand2 = new Sup_Brand__c(Name = supplier1.Name + ' Brand 2', Brand_Owner__c = supplier1.Id); 
        Sup_Brand__c brand3 = new Sup_Brand__c(Name = supplier1.Name + ' Brand 2', Brand_Owner__c = supplier1.Id); 
        lstBrands.add(brand2);
        lstBrands.add(brand3);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstBrands, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Brand_Name_Already_Exist, result.getErrors()[0].getMessage());  
            }
        }
    }
}