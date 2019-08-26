@isTest
private class RefreshLastPriceBatchTest {
    
    private static Integer year;
    private static Id rootId;
    static Country_List__c myCountry;
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
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Create Country
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default negoscope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // make NS Acc_Country__c = Contract_BU__r.Country__c
            NS.Acc_Country__c = country.Name;
            update NS;
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
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void updateAllLastPrice() {
        init();
        // Create PG
        pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand.Id;
        insert pg;
        // create contract
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
        insert contract;
        // Create sell in flow
        Sell_in_Flow__c sellin1 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 3, 1));
        sellin1.Invoice_Net_Amount_woTax__c = 100; sellin1.Footer_Order_Discount__c = 20; sellin1.Invoice_Quantity__c = 5; sellin1.Unit_Cost__c = 2;
        sellin1.Gross_Price__c = 200; sellin1.List_price__c = 100; sellin1.Net_Price__c = 50;
        
        Sell_in_Flow__c sellin2 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 2, 1));
        sellin2.Invoice_Net_Amount_woTax__c = 100; sellin2.Footer_Order_Discount__c = 20; sellin2.Invoice_Quantity__c = 5; sellin2.Unit_Cost__c = 2;
        sellin2.Gross_Price__c = 200; sellin2.List_price__c = 100; sellin2.Net_Price__c = 50;
        
        Sell_in_Flow__c sellin3 = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 2, 1));
        sellin3.Invoice_Net_Amount_woTax__c = 100; sellin3.Footer_Order_Discount__c = 20; sellin3.Invoice_Quantity__c = 5; sellin3.Unit_Cost__c = 2;
        sellin3.Gross_Price__c = 200; sellin3.List_price__c = 100; sellin3.Net_Price__c = 50; 
        insert new List<Sell_in_Flow__c> {sellIn1, sellIn2, sellIn3};
        
        Test.startTest();
        Database.executeBatch(new RefreshLastPriceBatch('RefreshLastPriceBatch', null));
        Test.stopTest();
        // Validation Test
        sellIn1 = [SELECT Id, Contract__c, Gross_Price__c, List_price__c, Net_Price__c , Unit_Cost__c FROM Sell_in_Flow__c WHERE Id = :sellIn1.Id];
        pg = [SELECT Id, Last_Gross_Price__c, Last_List_Price__c, Last_Net_Price__c FROM Supplier_PG_Mapping__c WHERE Id = :pg.Id];
        product = [SELECT Id, Last_Unit_Cost__c FROM Product2 WHERE Id = :product.Id];
        System.assertEquals(contract.Id, sellIn1.Contract__c);
        System.assertEquals(pg.Last_Gross_Price__c, sellIn1.Gross_Price__c);
        System.assertEquals(pg.Last_List_Price__c, sellIn1.List_price__c);
        System.assertEquals(pg.Last_Net_Price__c, sellIn1.Net_Price__c);
        System.assertEquals(product.Last_Unit_Cost__c, sellIn1.Unit_Cost__c);
    }
    
    @isTest static void updatePGLastPrice() {
        init();
        // create contract
        Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));
        insert contract;
        // Create sell in flow
        Sell_in_Flow__c sellin = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 3, 1));
        sellin.Invoice_Net_Amount_woTax__c = 100; sellin.Footer_Order_Discount__c = 20; sellin.Invoice_Quantity__c = 5; sellin.Unit_Cost__c = 2;
        sellin.Gross_Price__c = 200; sellin.List_price__c = 100; sellin.Net_Price__c = 50;        
        insert sellIn;
        // Create PG
        pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
        pg.Product__c = product.Id;
        pg.Brand__c = brand.Id;
        insert pg;
        Test.startTest();
        Database.executeBatch(new RefreshLastPriceBatch('RefreshLastPriceBatch', new List<Supplier_PG_Mapping__c>{pg}));
        Test.stopTest();
        // Validation Test
        sellIn = [SELECT Id, Contract__c, Gross_Price__c, List_price__c, Net_Price__c , Unit_Cost__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        pg = [SELECT Id, Last_Gross_Price__c, Last_List_Price__c, Last_Net_Price__c FROM Supplier_PG_Mapping__c WHERE Id = :pg.Id];
        product = [SELECT Id, Last_Unit_Cost__c FROM Product2 WHERE Id = :product.Id];
        System.assertEquals(contract.Id, sellIn.Contract__c);
        System.assertEquals(pg.Last_Gross_Price__c, sellIn.Gross_Price__c);
        System.assertEquals(pg.Last_List_Price__c, sellIn.List_price__c);
        System.assertEquals(pg.Last_Net_Price__c, sellIn.Net_Price__c);
        System.assertEquals(product.Last_Unit_Cost__c, sellIn.Unit_Cost__c);
    }
}