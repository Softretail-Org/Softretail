@isTest
private class ProductToPGBatchTest {
    
    static Integer year;
    static String currencyIsoCode;
    static Id rootId;
    static Country_List__c myCountry;
    static Orga_BU__c country;
    static Orga_BU__c region;
    static Orga_HE__c department;
    static Orga_HE__c section;
    static Sup_Brand__c brand;
    static Sup_sup_NegoScope__c NS;
    static Contract__c contract;
    static List<Product2> products;
    static Sup_Supplier__c masterSupplier;
    static List<Sup_Supplier__c> suppliers;
    static List<Sell_In_Flow__c> sellInFlows;
    
    static void init() {
        year = System.Today().year();        
        // Root Element Id
        rootId = NegoptimHelper.getRootId();
        // Get the Corporate Currency
        currencyIsoCode = TestDataFactory.currencyIsoCode;
        // Add Country LIST
        myCountry = TestDataFactory.createCountry(true, 'SEB FRANCE', 'FR');
        // Create Region
        region = TestDataFactory.createBURegion(false, 'EU');
        insert region;
        // Create Country
        country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
        insert country;
        // Create Suppliers
        suppliers = new List<Sup_Supplier__c> ();
        for (integer i = 0; i < 10; i++) {
            Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.Name = 'Supplier 000' + i;
            supplier.Code__c = 'SUP000' + i;
            suppliers.add(supplier);
        }
        insert suppliers;
        // Create master Supplier
        masterSupplier = TestDataFactory.createSupplier(false, country, true);
        masterSupplier.Name = 'Supplier 001';
        masterSupplier.Code__c = 'SUP001';
        insert masterSupplier;
        // Get the default negoscope created on supplier creation
        NS = TestDataFactory.getNSs(masterSupplier.Id)[0];
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
        brand = TestDataFactory.createBrand(false, masterSupplier.Id);
        insert brand;
        // Create Products
        products = new List<Product2>();
        for (Integer i = 0; i < 10; i++) {
            Product2 product = TestDataFactory.createProduct(false, section.Id, masterSupplier.Id);
            product.Name = 'P000' + i;
            product.ProductCode = 'P000' + i;
            product.Brand__c = brand.Id;
            products.add(product);
        }
        insert products;
        // Create Contract
        contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 2, 1), date.newInstance(year, 6, 1));    
        insert contract;
        // Create sell in flows
        sellInFlows = new List<Sell_in_Flow__c>();
        for (Sup_Supplier__c supplier : suppliers) {
            for (Product2 product : products) {
                Sell_in_Flow__c sellin = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 2, 1));
                sellin.BU__c = country.Id;
                sellin.Supplier__c = supplier.Id;
                sellin.Invoice_Net_Amount_woTax__c = 100;
                sellInFlows.add(sellin);
            }
        }
        insert sellInFlows;            
    }
    
    static testmethod void insertPGs() {
        init();
        
        System.debug([SELECT COUNT() FROM Supplier_PG_Mapping__c]);
        List<ID> supplierIds = new List<Id>();
        for (Sup_Supplier__c sup : suppliers) {
            supplierIds.add(sup.Id);
        }
        Test.startTest();
        Database.executeBatch(new ProductToPGBatch('Test', year, supplierIds));
        Test.stopTest();
        System.assertEquals(100, [SELECT COUNT() FROM Supplier_PG_Mapping__c]);
    }
    
}