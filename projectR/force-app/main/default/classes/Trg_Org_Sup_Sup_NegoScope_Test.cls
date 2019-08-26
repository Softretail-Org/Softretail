/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for nego scope object
 * */
@isTest
private class Trg_Org_Sup_Sup_NegoScope_Test {
    
    private static User anotherUser;
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier1;
    private static Sup_Supplier__c supplier2;
    private static Sup_sup_NegoScope__c negoScope1;
    private static Sup_sup_NegoScope__c subNegoScope11;
    private static Sup_sup_NegoScope__c subNegoScope12;
    private static Orga_HE__c department;
    private static Orga_HE__c section1;
    private static Orga_HE__c section2;
    private static Sup_Brand__c brand1;
    private static Sup_Brand__c brand2;
    private static Supplier_PG_Mapping__c pg1;
    private static Supplier_PG_Mapping__c pg2;
    
    static void init() {
        try {
            // NOTE: Always should be first DML
            Profile profile = [SELECT Id FROM Profile WHERE PermissionsCustomizeApplication = true LIMIT 1];
            anotherUser = new User(FirstName='anotherUser', LastName = 'anotherUser', Alias = 'another', Email = 'another@user.com',
                                   Username = 'another@user.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
                                   EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = null);
            insert anotherUser;
            
            year = System.Today().year();
            // Root Element.
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;// NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Suppliers
            supplier1 = TestDataFactory.createSupplier(false, country, true);
            supplier2 = TestDataFactory.createSupplier(false, country, false);
            insert new List<Sup_Supplier__c> {supplier1, supplier2};
            // Create Department
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Elt Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Sections
            section1 = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1));
            section2 = new Orga_HE__c(Name = 'SEC2', Elt_Code__c = 'Elt Code 3', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1));
            insert new List<Orga_HE__c> {section1, section2};
            // Create brands
            brand1 = new Sup_Brand__c(Name = supplier1.Name + ' Brand 1', Brand_Owner__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
            brand2 = new Sup_Brand__c(Name = supplier2.Name + ' Brand 2', Brand_Owner__c = supplier2.Id, Status_BDate__c = date.newInstance(year, 1, 1));
            insert new List<Sup_Brand__c> {brand1, brand2};
            // Create PG.
            pg1 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' PG 1', Brand__c = brand1.Id, SNA_Code__c = '1', GIMA_Code__c = '1', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
            pg2 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' PG 2', Brand__c = brand1.Id, SNA_Code__c = '1', GIMA_Code__c = '2', Department__c = department.Id, Section__c = section1.Id, Supplier__c = supplier1.Id);
            insert new List<Supplier_PG_Mapping__c> {pg1, pg2};
            // Get the default negoscope created on supplier creation.
            negoScope1 = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier1.Id LIMIT 1];
            subNegoScope11 = new Sup_sup_NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS 1', Parent_Nego_Scope__c = negoScope1.Id,
                                                     Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            subNegoScope12 = new Sup_sup_NegoScope__c(Supplier__c = supplier1.id, Name ='Sub NS 2', Parent_Nego_Scope__c = negoScope1.Id,
                                                     Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert new List<Sup_sup_NegoScope__c> {subNegoScope11, subNegoScope12};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Test validation on negoscope name and supplier  before insert.
    @isTest static void case1_createNegoScopeForSameNameSupplier() {
        init(); 
        Sup_sup_NegoScope__c negoScope2 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - '+supplier1.Name, Supplier__c = supplier1.Id, Is_All_Brands__c = false, Is_All_HE__c = false, Is_All__c = false,
                                                                   Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        Test.startTest();        
        Database.SaveResult result = Database.insert(negoScope2, false); 
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique,
                                          new String[] {'Default NegoScope - '+supplier1.Name}), result.getErrors()[0].getMessage());
    }
    
    // Test validation on negoscope name and suppllier before  update.
    @isTest static void case2_updateNegoScopeDuplicateNameSupplier() {
        init();
        Sup_sup_NegoScope__c negoScope2 = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier1.Id, Is_All_Brands__c = false, Is_All_HE__c = false, Is_All__c = false,
                                                                   Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert negoScope2;
        negoScope2.Name = 'Default NegoScope - ' + supplier1.Name;
        Test.startTest();
        Database.SaveResult result = Database.update(negoScope2, false);
        Test.stopTest();        
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
    }
    
    // Test validation on adding 2 negoscope with same name.
    @isTest static void case3_createMultiNegoScope() {
        init();
        Sup_sup_NegoScope__c negoScope2 = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier1.Id, Is_All_Brands__c = false, Is_All_HE__c = false, Is_All__c = false,
                                                                   Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        Sup_sup_NegoScope__c negoScope3 = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier1.Id, Is_All_Brands__c = false, Is_All_HE__c = false, Is_All__c = false,
                                                                   Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        List<Sup_sup_NegoScope__c> lstNegoscope = new List<Sup_sup_NegoScope__c>();
        lstNegoscope.add(negoScope2);
        lstNegoscope.add(negoScope3);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstNegoscope, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            if(!result.isSuccess()) {
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(String.format(Label.MSG_The_Combination_NS_Name_Supplier_Keys_Must_Be_Unique,
                                                  new String[] {'Nego Scope 1'}), result.getErrors()[0].getMessage());
            }
        }
    }
    
    // Test validation on negoscope creation with all he , brand and pg check.
    @isTest static void case4_CreateNegoScopeWithAllChecked() {
        init();        
        Sup_sup_NegoScope__c NS = new Sup_sup_NegoScope__c(Name = 'New NS', Supplier__c = supplier1.Id, Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        // Start test.
        Test.startTest();
        insert NS;
        Test.stopTest();
        
        List<Sup_sup_NegoScope__c> listNegoScope = [Select Id FROM Sup_sup_NegoScope__c];
        
        System.assert(listNegoScope.size() > 0);
        System.assertEquals(4,listNegoScope.size());
    }
    
    // Test validation on multiple  negoscope creation with all he , brand and pg check.
    @isTest static void case5_CreateMultyNegoScopeWithAllChecked() {
        init();
        List<Sup_sup_NegoScope__c> listNegoScope = new List<Sup_sup_NegoScope__c>();        
        Sup_sup_NegoScope__c NS = new Sup_sup_NegoScope__c(Name = 'New NS', Supplier__c = supplier1.Id, Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        Sup_sup_NegoScope__c NS2 = new Sup_sup_NegoScope__c(Name = 'New NS 1', Supplier__c = supplier2.Id, Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        listNegoScope.add(NS);
        listNegoScope.add(NS2);
        // Start test.
        Test.startTest();
        insert listNegoScope;
        Test.stopTest();
        
        List<Sup_sup_NegoScope__c> getListNegoScope = [Select Id, Name FROM Sup_sup_NegoScope__c];
        
        System.assert(getListNegoScope.size() > 0);
        System.assertEquals(5,getListNegoScope.size());
    }
    
    // Assign supplier ISO code into the NS ISO Code.
    @isTest static void case6_assignmentISOCurrency() {
        // Create Region.
        Orga_BU__c region = new Orga_BU__c(Name = 'Region1', BU_Code__c = 'Region1', BU_ODate__c = date.newInstance(2017, 1, 1));
        region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
        insert region;
        // Create Country.
        Orga_BU__c country = new Orga_BU__c(Name = 'Country1', BU_Code__c = 'Country1', BU_ODate__c = date.newInstance(2017, 1, 1),
                                            Country_Zone_origin__c = region.Id, Status__c = 'Open');
        // Create supplier.
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'SupA',
                                                       Code__c = 'SupA',
                                                       CurrencyIsoCode = 'EUR',
                                                       Country_origin__c = country.Id,
                                                       Status__c = 'Active',
                                                       Is_Default_NegoScope__c = false);
        insert supplier;
        // Create NS.
        Sup_sup_NegoScope__c NS = new Sup_sup_NegoScope__c(Name = 'NS Name', Supplier__c = supplier.Id, CurrencyIsoCode = 'USD',
                                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        // Start test.
        Test.startTest();
        Database.insert(NS, false);
        Test.stopTest();
        // Assertion.
        Sup_sup_NegoScope__c selectedNS = [SELECT CurrencyIsoCode FROM Sup_sup_NegoScope__c];
        System.assertEquals('EUR', selectedNS.CurrencyIsoCode);
    }
    
    // Assign supplier ISO code into the NS ISO Code.
    @isTest static void case7_assignmentISOCurrency_Bulk() {
        // Create Region.
        Orga_BU__c region = new Orga_BU__c(Name = 'Region1', BU_Code__c = 'Region1', BU_ODate__c = date.newInstance(2017, 1, 1));
        region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
        insert region;
        // Create Country.
        Orga_BU__c country = new Orga_BU__c(Name = 'Country1', BU_Code__c = 'Country1', BU_ODate__c = date.newInstance(2017, 1, 1),
                                            Country_Zone_origin__c = region.Id, Status__c = 'Open');
        // Create supplier.
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'SupA',
                                                       Code__c = 'SupA',
                                                       CurrencyIsoCode = 'EUR',
                                                       Country_origin__c = country.Id,
                                                       Status__c = 'Active',
                                                       Is_Default_NegoScope__c = false);
        insert supplier;
        List<Sup_sup_NegoScope__c> NSs = new List<Sup_sup_NegoScope__c>();
        // Create NS.
        for (Integer i=1 ; i < 6 ; i ++) {
            Sup_sup_NegoScope__c NS = new Sup_sup_NegoScope__c(Name = 'NS Name' + i, Supplier__c = supplier.Id, CurrencyIsoCode = 'USD',
                                                               Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            NSs.add(NS);
        }
        // Start test.
        Test.startTest();
        Database.insert(NSs, false);
        Test.stopTest();
        // Assertion.
        List<Sup_sup_NegoScope__c> selectedNSs = [SELECT CurrencyIsoCode FROM Sup_sup_NegoScope__c];
        for (Sup_sup_NegoScope__c selectedNS : selectedNSs) {
            System.assertEquals('EUR', selectedNS.CurrencyIsoCode);
        }
    }
    
    // Update Sub NS owner when parent NS owner change.
    @isTest static void case8_updateSubNSOwner() {
        init();
        negoScope1.OwnerId = anotherUser.Id;
        
        Test.startTest();
        Database.SaveResult result = Database.update(negoScope1, false);
        Test.stopTest();
        
        // Assertion
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM Sup_sup_NegoScope__c WHERE Id = :negoScope1.Id].OwnerId);
        System.assertEquals(anotherUser.Id, [SELECT OwnerId FROM Sup_sup_NegoScope__c WHERE Id = :subNegoScope11.Id].OwnerId);
    }
    
    @isTest static void case9_setParentNsToRelatedWithContractNS() {
        init();
        
        Test.startTest();
        //Create NegoScopes
        Sup_sup_NegoScope__c nego1 = TestDataFactory.createNegoScope(true, supplier1, 'Nego Scope 1');
        Sup_sup_NegoScope__c nego2 = TestDataFactory.createNegoScope(true, supplier1, 'Nego Scope 2 NOT Updated');
        
        //Create Contract
        Contract__c contract = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier1.Id, Supplier_Nego_Scope__c = nego2.Id, Contract_Numbder__c = 'C123',
                                               Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                               Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month');
        
        insert contract;
        
        //Remove parent from Nego Scope
        nego1.Name = 'Nego Scope 1 updated Name';
        
        nego2.Parent_Nego_Scope__c = nego1.Id;
        nego2.Name = 'Nego Scope 2 update Name';
        
        List<Sup_sup_NegoScope__c> nsList = new List<Sup_sup_NegoScope__c>();
        nsList.add(nego1);
        nsList.add(nego2);
        List<Database.SaveResult> results = Database.update(nsList, false);
        Test.stopTest();
        
        //Calculate Number of successful result
        Integer failedCount = 0;
        String errorMsgs = '';
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results.get(i);
            if (!result.isSuccess()) {
                failedCount++;
                for (Database.Error err : result.getErrors()){
                    errorMsgs += err.getMessage();
                }
            }
        }
        
        System.assert(failedCount == 1);
        System.assertEquals('Nego Scope 1 updated Name', [SELECT Name FROM Sup_sup_NegoScope__c WHERE Id = :nego1.Id].Name);
        System.assertEquals('Nego Scope 2 NOT Updated', [SELECT Name FROM Sup_sup_NegoScope__c WHERE Id = :nego2.Id].Name);
        System.assertEquals(System.Label.Cannot_Set_Parent_NegoScope, errorMsgs);
    }
    
    // Assign stock owner to contract
    @isTest static void case10_assignStockOwner() {
        init();
        // Create Warehouse
        Orga_BU__c warehouse = TestDataFactory.createWarehouseBU(false, country.Id);
        warehouse.Ext_id__c = 'w1';
        insert warehouse;
        // Create Contract
        Contract__c contract1 = new Contract__c(Name ='Test Contract 0001', Supplier__c = supplier1.Id, Supplier_Nego_Scope__c = negoScope1.Id, Contract_Numbder__c = 'CM001',
                                                Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                                Duration__c = 14, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Duration_type__c='Month');
        insert contract1;
        Test.startTest();        
        negoScope1.Stock_Owner__c = warehouse.Id;
        update negoScope1;
        Test.stopTest();
        // Validation
        contract1 = [SELECT Stock_Owner__c FROM Contract__c WHERE Id = :contract1.Id];
        System.assertEquals(contract1.Stock_Owner__c, warehouse.Id);
    }
}