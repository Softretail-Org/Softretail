/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for product group 
*/
@isTest
private class Trg_Org_SupplierPg_Test {
	
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier1;
    private static Sup_Supplier__c supplier2;
    private static Sup_sup_NegoScope__c negoScope;
    private static Orga_HE__c department;
    private static Orga_HE__c section1;
    private static Orga_HE__c section2;
    private static Sup_Brand__c brand1;
    private static Sup_Brand__c brand2;
    private static Supplier_PG_Mapping__c pg1;
        
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Department
            department = TestDataFactory.createDepartment(true, rootId);
            // Create Sections
            section1 = TestDataFactory.createSection(false, department.Id);
            section2 = TestDataFactory.createSection(false, department.Id);
            insert new List<Orga_HE__c> {section1, section2};
            // Create Suppliers
            supplier1 = TestDataFactory.createSupplier(false, country, false);
            supplier2 = TestDataFactory.createSupplier(false, country, false);
            insert new List<Sup_Supplier__c> {supplier1, supplier2};
            // Create brands
            brand1 = new Sup_Brand__c(Name = supplier1.Name + ' Brand 1', Brand_Owner__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
    		brand2 = new Sup_Brand__c(Name = supplier2.Name + ' Brand 2', Brand_Owner__c = supplier2.Id, Status_BDate__c = date.newInstance(year, 1, 1));
    		insert new List<Sup_Brand__c> {brand1, brand2};
            // Create PG
            pg1 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' PG 1', Brand__c = brand1.Id, SNA_Code__c = '1', GIMA_Code__c = '1', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
            insert pg1;            
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /*
    * Test validation on product group name and supplier  befort insert 
    */
    /****
    @isTest static void test_createProductGroup() {
        init();        
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = pg1.Name, Brand__c = brand1.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(pg, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_The_Combination_Name_Supplier_Keys_Must_Be_Unique, result.getErrors()[0].getMessage());
    }
    ****/
    /*
    * Test validation on product group code and supplier  and section  befort insert 
    */
    @isTest static void test_createProductGroupDuplicateSupplierCode() {
        init();
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' New PG', Brand__c = brand1.Id, SNA_Code__c = '10', GIMA_Code__c = pg1.GIMA_Code__c, Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(pg, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_The_Combination_Code_Supplier_Section_Keys_Must_Be_Unique, result.getErrors()[0].getMessage());
    }
    
    /*
    * Test to validation if all new product added to negoscope when all new product  is checked in negoscope page   
    */
    @isTest static void test_includeAllPGInNegoScope() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c = true,
                                                                     Is_All_Brands__c = true, Is_All_HE__c = false, Incl_NewProduct__c = false,
                                                                     Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        insert new Supplier_NS_HE__c(Sup_sup_NegoScope__c = newNegoScope.Id, Structure_Element__c = department.Id, Choice__c = 'Include');
        
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG', Brand__c = brand1.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert pg;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(1, allNegoScopePg.size());
    }
    
    /*
    * Test to validation if new product added to negoscope when new product  is checked in negoscope page   
    */
    @isTest static void test_includePGInNegoScope() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c=false,Is_All_Brands__c = false, Is_All_HE__c = false,Incl_NewProduct__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;        
        Supplier_NS_HE__c negoScopeHe = new Supplier_NS_HE__c(Structure_Element__c =department.Id, Sup_sup_NegoScope__c = newNegoScope.Id,Choice__c = 'Include');
        insert negoScopeHe;        
        Sup_NS_Brand__c negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brand2.Id, Supplier__c = supplier2.Id, Sup_sup_NegoScope__c = newNegoScope.Id);
        insert negoScopeBrand;
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG', Brand__c = brand2.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert pg;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(1, allNegoScopePg.size());
    }
    
    /*
    * Test to validation if new product added to negoscope when new product  is checked in negoscope page  and have a section as he with brand false  
    */
    @isTest static void test_includePGInNegoScopeWithHeSectionButNotAllBrand() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c=false,Is_All_Brands__c = false, Is_All_HE__c = false,Incl_NewProduct__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        Supplier_NS_HE__c negoScopeHe = new Supplier_NS_HE__c(Structure_Element__c =section1.Id, Sup_sup_NegoScope__c = newNegoScope.Id, Choice__c = 'Include');
        insert negoScopeHe;
        Sup_NS_Brand__c negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c =brand2.Id, Supplier__c = supplier2.Id, Sup_sup_NegoScope__c = newNegoScope.Id);
        insert negoScopeBrand;
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG', Brand__c = brand2.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert pg;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(1, allNegoScopePg.size());
    }
    
    /*
    * Test to validation if new product added to negoscope when new product  is checked in negoscope page  and have a section as he with brand false  
    */
    @isTest static void test_includePGInNegoScopeWithHeSectionButAllBrand() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c=false,Is_All_Brands__c = true, Is_All_HE__c = false,Incl_NewProduct__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        Supplier_NS_HE__c negoScopeHe = new Supplier_NS_HE__c(Structure_Element__c =section1.Id, Sup_sup_NegoScope__c = newNegoScope.Id, Choice__c = 'Include');
        insert negoScopeHe;
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG', Brand__c = brand2.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert pg;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(1, allNegoScopePg.size());
    }
    
    /*
    * Test to validation if list of new product are added to negoscope when all new product  is checked in negoscope page   
    */
    @isTest static void test_includeListPGInNegoScope() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c=true,
                                                                     Is_All_Brands__c = false, Is_All_HE__c = false, Incl_NewProduct__c = false,
                                                                     Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        insert new Supplier_NS_HE__c(Sup_sup_NegoScope__c = newNegoScope.Id, Structure_Element__c = section1.Id, Choice__c = 'Include');
        insert new Sup_NS_Brand__c(Sup_sup_NegoScope__c = newNegoScope.Id, Sup_Scope_Brand__c = brand2.Id);
        
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG 2', Brand__c = brand2.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg3 = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG 3', Brand__c = brand2.Id, SNA_Code__c = '11', GIMA_Code__c = '11', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert new List<Supplier_PG_Mapping__c> {pg2, pg3};
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(2, allNegoScopePg.size());
    }
    
    /*
    * Test to validation if list of new product are added to negoscope when all product is checked in negoscope page   
    */
    @isTest static void test_includeListAllPGInNegoScope() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c = true,
                                                                     Is_All_Brands__c = false, Is_All_HE__c = false, Incl_NewProduct__c = false,
                                                                     Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        insert new Supplier_NS_HE__c(Sup_sup_NegoScope__c = newNegoScope.Id, Structure_Element__c = department.Id, Choice__c = 'Include');
        insert new Sup_NS_Brand__c(Sup_sup_NegoScope__c = newNegoScope.Id, Sup_Scope_Brand__c = brand1.Id);
        
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG 2', Brand__c = brand1.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg3 = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' New PG 3', Brand__c = brand1.Id, SNA_Code__c = '11', GIMA_Code__c = '11', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert new List<Supplier_PG_Mapping__c> {pg2, pg3};
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(2, allNegoScopePg.size());
    }
    
    /*
    * Test bulk insert for product group 
    */
    @isTest static void test_createMultiProductGroup() {
        init();
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = 'New pg 2', SNA_Code__c = '123', GIMA_Code__c = '2', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg3 = new Supplier_PG_Mapping__c(Name = 'New pg 3', SNA_Code__c = '123', GIMA_Code__c = '3', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg4 = new Supplier_PG_Mapping__c(Name = 'New pg 4', SNA_Code__c = '123', GIMA_Code__c = '1', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg5 = new Supplier_PG_Mapping__c(Name = 'New pg 5', SNA_Code__c = '123', GIMA_Code__c = '2', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg6 = new Supplier_PG_Mapping__c(Name = 'New pg 6', SNA_Code__c = '123', GIMA_Code__c = '3', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg7 = new Supplier_PG_Mapping__c(Name = 'New pg 7', SNA_Code__c = '123', GIMA_Code__c = '1', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg8 = new Supplier_PG_Mapping__c(Name = 'New pg 8', SNA_Code__c = '123', GIMA_Code__c = '2', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg9 = new Supplier_PG_Mapping__c(Name = 'New pg 9', SNA_Code__c = '123', GIMA_Code__c = '3', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg10 = new Supplier_PG_Mapping__c(Name = 'New pg 10', SNA_Code__c = '123', GIMA_Code__c = '1', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg11 = new Supplier_PG_Mapping__c(Name = 'New pg 11', SNA_Code__c = '123', GIMA_Code__c = '2', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg12 = new Supplier_PG_Mapping__c(Name = 'New pg 12', SNA_Code__c = '123', GIMA_Code__c = '3', Brand__c = brand1.Id, Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier2.Id);
        insert new List<Supplier_PG_Mapping__c> {pg2, pg3, pg4, pg5, pg6, pg7, pg8, pg9, pg10, pg11, pg12}; 
		Integer countPGSupplier1 = [Select COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier1.Id];
        Integer countPGSupplier2 = [Select COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier2.Id];            
        System.assertEquals(6, countPGSupplier1);
        System.assertEquals(6, countPGSupplier2);
    }
    
    /*
    * Test validation on multi  product group code and supplier  and section  befort insert 
    */
    @isTest static void test_createMultiProductGroupDuplicateSuplierCode() {
        init();
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' New PG 2', Brand__c = brand1.Id, SNA_Code__c = '10', GIMA_Code__c = '1', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg3 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' New PG 3', Brand__c = brand1.Id, SNA_Code__c = '11', GIMA_Code__c = '1', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(new List<Supplier_PG_Mapping__c> {pg2, pg3}, false); 
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if(!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_The_Combination_Code_Supplier_Section_Keys_Must_Be_Unique, result.getErrors()[0].getMessage());  
            }
        }
    }
    
    /*
    * Test validation on multi product group same name but different suppliers
    */
    @isTest static void test_createMultiProductGroup_Success() {
        init();
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = 'New PG 1', Brand__c = brand1.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg3 = new Supplier_PG_Mapping__c(Name = 'New PG 1', Brand__c = brand1.Id, SNA_Code__c = '11', GIMA_Code__c = '11', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg4 = new Supplier_PG_Mapping__c(Name = 'New PG 2', Brand__c = brand1.Id, SNA_Code__c = '12', GIMA_Code__c = '12', Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg5 = new Supplier_PG_Mapping__c(Name = 'New PG 2', Brand__c = brand1.Id, SNA_Code__c = '13', GIMA_Code__c = '13', Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier2.Id);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(new List<Supplier_PG_Mapping__c> {pg2, pg3, pg4, pg5}); 
        Test.stopTest();
        Integer countPGSupplier2 = [Select COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(2, countPGSupplier2);
    }
    
    /*
    * Test validation on multi product group supplier name
    */
    @isTest static void test_createMultiProductGroupDuplicateSuplierName_Failure() {
        init();
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' New PG 1', Brand__c = brand1.Id, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
        Supplier_PG_Mapping__c pg3 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' New PG 1', Brand__c = brand1.Id, SNA_Code__c = '11', GIMA_Code__c = '11', Department__c = department.Id, Section__c = section2.Id, Supplier__c = supplier1.Id);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(new List<Supplier_PG_Mapping__c> {pg2, pg3}, false); 
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if(!result.isSuccess()){
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_The_Combination_Name_Supplier_Keys_Must_Be_Unique, result.getErrors()[0].getMessage());  
            }
        }
    }
    
    /*
    * Test to validation if new product added to negoscope when new product and all brand of nego is checked 
    */
    @isTest static void test_includePGInNegoScopeBrandChecked() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'New Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c=false,Is_All_Brands__c = true, Is_All_HE__c = false,Incl_NewProduct__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        Supplier_NS_HE__c negoScopeHe = new Supplier_NS_HE__c(Structure_Element__c = department.Id, Sup_sup_NegoScope__c = newNegoScope.Id, Choice__c = 'Include');
        insert negoScopeHe;
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier2.Name + 'PG 3', SNA_Code__c = '111', GIMA_Code__c = '12', Brand__c=brand2.Id,Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert pg;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(1, allNegoScopePg.size());  
    }
    
    /*
    * Test to validation if new product added to negoscope when new product and all he of nego is checked 
    */
    @isTest static void test_includePGInNegoScopeHeChecked() {
        init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = supplier2.Name + 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c = false,
                                                                     Is_All_Brands__c = false, Is_All_HE__c = true, Incl_NewProduct__c = true,
                                                                     Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        Sup_NS_Brand__c negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brand2.Id, Supplier__c = supplier2.Id, Sup_sup_NegoScope__c = newNegoScope.Id);
        insert negoScopeBrand;
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier2.Name + 'PG 2', SNA_Code__c = '111', GIMA_Code__c = '12', Brand__c = brand2.Id, 
                                                               Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert pg;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Supplier__c = :supplier2.Id];
        System.assertEquals(1, allNegoScopePg.size());
    }
    
    /*
    * delete pg will remove relation with nesgoscope
    */
	@isTest static void test_deletePg() {
		init();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c=false,Is_All_Brands__c = false, Is_All_HE__c = true,Incl_NewProduct__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = 'New Product group 2', SNA_Code__c = '111', GIMA_Code__c = '12', Brand__c=brand2.Id,Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        insert pg;
        delete pg;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :newNegoScope.Id];
        System.assertEquals(0, allNegoScopePg.size());
    }
    
	/*
     * delete pg will remove relation with nesgoscope
     */
	@isTest static void test_bulkDeletePg() {
    	init();
        List<Supplier_PG_Mapping__c> lstPgs = new List<Supplier_PG_Mapping__c>();
        // Create negoScope
        Sup_sup_NegoScope__c newNegoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier2.Id, Is_All__c=false,Is_All_Brands__c = false, Is_All_HE__c = true,Incl_NewProduct__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert newNegoScope;
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = 'New Product group 2', SNA_Code__c = '111', GIMA_Code__c = '12', Brand__c=brand2.Id,Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = 'New Product group 3', SNA_Code__c = '112', GIMA_Code__c = '13', Brand__c=brand2.Id,Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier2.Id);
		lstPgs.add(pg);
        lstPgs.add(pg2);
        insert lstPgs;
        delete lstPgs;
        List<Sup_NS_PG__c> allNegoScopePg = [Select Id FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :newNegoScope.Id];
        System.assertEquals(0, allNegoScopePg.size());
    }
    
    // Restriction of the duplication of Supplier + product.
    @isTest static void test_restrictionSupplierProduct() {
    	init();
    	Product2 product = new Product2(Name = 'PRODUCT1');
    	insert product;
        Supplier_PG_Mapping__c pg1 = new Supplier_PG_Mapping__c(Name = supplier1.Name, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id, Product__c = product.Id);
        insert pg1;
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = supplier1.Name, SNA_Code__c = '11', GIMA_Code__c = '11', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id, Product__c = product.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(pg2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
		System.assertEquals(System.Label.MSG_The_combination_of_Supplier_and_Product_must_be_unique, result.getErrors()[0].getMessage());
    }
    
    @isTest static void test_bulkRestrictionSupplierProduct() {
    	init();
    	Product2 product = new Product2(Name = 'PRODUCT1');
    	insert product;
        Supplier_PG_Mapping__c pg1 = new Supplier_PG_Mapping__c(Name = supplier1.Name, SNA_Code__c = '10', GIMA_Code__c = '10', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id, Product__c = product.Id);
        insert pg1;
        Supplier_PG_Mapping__c pg2 = new Supplier_PG_Mapping__c(Name = supplier1.Name, SNA_Code__c = '11', GIMA_Code__c = '11', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id, Product__c = product.Id);
        Supplier_PG_Mapping__c pg3 = new Supplier_PG_Mapping__c(Name = supplier1.Name, SNA_Code__c = '11', GIMA_Code__c = '11', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id, Product__c = product.Id);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(new List<Supplier_PG_Mapping__c> {pg2, pg3}, false); 
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_The_combination_of_Supplier_and_Product_must_be_unique, result.getErrors()[0].getMessage());
            }
        }
    }
}