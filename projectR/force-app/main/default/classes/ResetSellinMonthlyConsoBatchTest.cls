@isTest
private class ResetSellinMonthlyConsoBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Product2 product;
    private static Supplier_PG_Mapping__c pg;
    private static Contract__c contract;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;// NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Department
            department = TestDataFactory.createDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createSection(true, department.Id);
            // Create supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default negoscope created on supplier creation.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // make NS Acc_Country__c = Contract_BU__r.Country__c
            NS.Acc_Country__c = country.Name;
            update NS;
            // Create Contract
            contract = (Contract__c)TestDataFactory.createContractWithConditions(true, supplier, NS.Id, null, 0)[0];
            // Create brand
            brand = TestDataFactory.createBrand(false, supplier.Id);
            insert brand;
            // insert product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product;
            // Create PG
            pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Product__c = product.Id;
            pg.Brand__c = brand.Id;
            insert pg;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_update() {
        init();
        Sell_in_Flow__c sellIn1 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 1, 1));
        sellIn1.BU__c = country.Id;
        sellIn1.Monthly_Conso__c = true;
        sellIn1.Master_BU__c = country.Id;
        sellIn1.Contract__c = contract.Id;
        Sell_in_Flow__c sellIn2 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 2, 1));
        sellIn2.Monthly_Conso__c = true;
        sellIn2.BU__c = country.Id;
        sellIn2.Master_BU__c = country.Id;
        sellIn2.Contract__c = contract.Id;        
        insert new List<Sell_in_Flow__c>{sellIn1, sellIn2};
        Test.startTest();
        Database.executeBatch(new ResetSellinMonthlyConsoBatch('Test', null , new List<Id>{country.Id}, new List<Id>{supplier.Id}, null, null, year, true, null));
        Test.stopTest();
        sellIn1 = [SELECT Id, Monthly_Conso__c FROM Sell_in_Flow__c WHERE Id = :sellIn1.Id];
        system.assertEquals(false, sellIn1.Monthly_Conso__c);
    }
    
    @isTest static void test_resetMonthlyPurchase() {
        init();
        Sell_in_Flow__c sellIn1 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 1, 1));
        sellIn1.BU__c = country.Id;
        sellIn1.Monthly_Conso__c = true;
        sellIn1.Master_BU__c = country.Id;
        sellIn1.Contract__c = contract.Id;
        Sell_in_Flow__c sellIn2 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 2, 1));
        sellIn2.Monthly_Conso__c = true;
        sellIn2.BU__c = country.Id;
        sellIn2.Master_BU__c = country.Id;
        sellIn2.Contract__c = contract.Id;        
        insert new List<Sell_in_Flow__c>{sellIn1, sellIn2};
        Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = pg.Id, Supplier_Nego_Scope__c = NS.Id,
                                                                 Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id, BU__c = country.Id, Year__c = year,
                                                                 TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                 TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        insert purchase;
        Test.startTest();
        Database.executeBatch(new ResetSellinMonthlyConsoBatch('Test', null , new List<Id>{country.Id}, new List<Id>{supplier.Id}, null, null, year, null, null));
        Test.stopTest();
        sellIn1 = [SELECT Id, Monthly_Conso__c FROM Sell_in_Flow__c WHERE Id = :sellIn1.Id];
        system.assertEquals(false, sellIn1.Monthly_Conso__c);
        ////system.assertEquals(null, [SELECT TO1__c FROM Purchases_Flow_PG__c WHERE Id = :purchase.Id].TO1__c);
    }
}