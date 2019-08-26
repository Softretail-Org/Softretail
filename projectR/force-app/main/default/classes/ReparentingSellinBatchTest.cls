@isTest
private class ReparentingSellinBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c defaultSupplier;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Sup_sup_NegoScope__c defaultNegoScope;
    private static Contract__c contract;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Product2 product;
    private static Supplier_PG_Mapping__c pg;
        
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Create Country
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Supplier
            defaultSupplier = TestDataFactory.createSupplier(false, country, true);
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert new List<Sup_Supplier__c>{defaultSupplier, supplier};
            // Get the default negoscope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            defaultNegoScope = TestDataFactory.getNSs(defaultSupplier.Id)[0];
            // make NS Acc_Country__c = Contract_BU__r.Country__c
            NS.Acc_Country__c = country.Name;
            update NS;
            // create contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 6, 1));
            insert contract;
            // Create Department
            department = TestDataFactory.createDepartment(false, rootId);
            insert department;
            // Create Section        
            section = TestDataFactory.createSection(false, department.Id);
            insert section;
            // Create brand
            brand = TestDataFactory.createBrand(false, supplier.Id);
            insert brand;
            // insert product
            product = TestDataFactory.createProduct(false, section.Id, defaultSupplier.Id);
            insert product;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage()); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    @isTest static void test_ReparentingSellin_OnDeleteContract(){
        init();
        // create temp contract		
        Contract__c defaultSellinContract = TestDataFactory.createContract(false, defaultNegoScope, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        insert defaultSellinContract;
        // Create Legal Form
        Orga_BU__c legal = TestDataFactory.createBULegal(false, myCountry);
        insert legal;
        // Create Store
        ////Orga_BU__c store = TestDataFactory.createBUStores(false, country, legal.Id, 'STR', 1)[0];
        // Create sell in flow
        Sell_in_Flow__c sellIn = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 3, 1));
        insert sellIn;
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(contract.Id, sellIn.Contract__c);
        Test.startTest();
        Database.executeBatch(new ReparentingSellinBatch('Test', null, null, new List<Id>{contract.Id}, null, null, null, null, null, false, null, null));
        Test.stopTest();
        // Validation Test
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(defaultSellinContract.Id, sellIn.Contract__c);
        System.assertEquals(1, [SELECT COUNT() FROM Contract__c]);
    }
    
    @isTest static void test_ReparentingSellin_OnInsertContract(){
        init();
        // Create Supplier
        Sup_Supplier__c supplier1 = TestDataFactory.createSupplier(false, country, true);
        insert supplier1;
        // Get the default negoscope created on supplier creation
        Sup_sup_NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Create PG
        Supplier_PG_Mapping__c pg = TestDataFactory.createPG(false, supplier1.Id, department.Id, section.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand.Id;
        insert pg;
        // Create sell in flow
        Sell_in_Flow__c sellIn = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 4, 1));
        insert sellIn;
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract.Id);
        // create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 1));
        // Start test.
        Test.startTest();
        insert contract1;
        Test.stopTest();
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract1.Id);
    }
    
    @isTest static void test_ReparentingSellin_OnInsertNSPG(){
        init();
        // Create Supplier
        Sup_Supplier__c supplier1 = TestDataFactory.createSupplier(false, country, true);
        insert supplier1;
        // Get the default negoscope created on supplier creation
        Sup_sup_NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Create sell in flow
        Sell_in_Flow__c sellIn = TestDataFactory.createSellinFlow(false, NS1, section, product, Date.newInstance(year, 4, 1));
        insert sellIn;
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract.Id);        
        // create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 1));
        insert contract1;
        // Create PG
        Supplier_PG_Mapping__c pg = TestDataFactory.createPG(false, supplier1.Id, department.Id, section.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand.Id;
        // Start test.
        Test.startTest();
        insert pg;
        Test.stopTest();
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract1.Id);
    }
    
    @isTest static void test_ReparentingSellin_OnDeleteNSPG(){
        init();
        // Create Supplier
        Sup_Supplier__c supplier1 = TestDataFactory.createSupplier(false, country, true);
        insert supplier1;
        // Get the default negoscope created on supplier creation
        Sup_sup_NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Create PG
        Supplier_PG_Mapping__c pg = TestDataFactory.createPG(false, supplier1.Id, department.Id, section.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand.Id;
        insert pg;
        // create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 1));
        insert contract1;
        // Create sell in flow
        Sell_in_Flow__c sellIn = TestDataFactory.createSellinFlow(false, NS1, section, product, Date.newInstance(year, 4, 1));
        insert sellIn;
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract1.Id);
        Sup_NS_PG__c nspg = [SELECT Id FROM Sup_NS_PG__c WHERE Sup_PG__c = :pg.Id LIMIT 1];
        // Start test.
        Test.startTest();
        delete pg;
        Test.stopTest();
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract.Id);
    }
    
    @isTest static void test_ReparentingSellin_OnDeleteBUList(){
        init();
        // Create Supplier
        Sup_Supplier__c supplier1 = TestDataFactory.createSupplier(false, country, true);
        insert supplier1;
        // Get the default negoscope created on supplier creation
        Sup_sup_NegoScope__c NS1 = TestDataFactory.getNSs(supplier1.Id)[0];
        // Create Banner.
        Orga_BU__c banner = TestDataFactory.createBUBanner(false, country);
        insert banner;
        // create contract
        Contract__c contract1 = TestDataFactory.createContract(false, NS1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 1));
        contract1.Contract_BU__c = banner.Id;
        insert contract1;
        // Create PG
        Supplier_PG_Mapping__c pg = TestDataFactory.createPG(false, supplier1.Id, department.Id, section.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand.Id;
        insert pg;
        // Create sell in flow
        Sell_in_Flow__c sellIn = TestDataFactory.createSellinFlow(false, NS1, section, product, Date.newInstance(year, 4, 1));
        sellIn.BU__c = banner.Id;
        insert sellIn;
        ////sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        ////System.assertEquals(sellIn.Contract__c, contract1.Id);
        Orga_BU_List_Detail__c buList = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity_List__c = :banner.Id];
        // Start test.
        ////Test.startTest();
        ////delete buList;
        ////Test.stopTest();
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract1.Id);
    }
}