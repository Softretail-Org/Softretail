@isTest
private class Product_Selection_Controller_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Contract__c contract;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Supplier_PG_Mapping__c pg;
    private static Product2 product;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
            // Create Supplier
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                           Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation
            Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            // Create Contract
            contract = new Contract__c(Name = 'Test Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract');
            insert contract;
            // Create Department
            department = TestDataFactory.createDepartment(true, rootId);
            // Create Section        
            section = TestDataFactory.createSection(true, department.Id);
            // Create brand owner
            Sup_Supplier__c brandOwner = new Sup_Supplier__c(Name = 'brandOwner 001', Code__c = 'brandOwner001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                                             Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert brandOwner;
            // Create brand
            brand = new Sup_Brand__c(Name = supplier.Name + ' Brand 1', Brand_Owner__c = brandOwner.Id, Status_BDate__c = date.newInstance(year, 1, 1));
            insert brand;
            // insert brand distributor
            Sup_Bra_Distributor__c bd = new Sup_Bra_Distributor__c(Name = 'BD-Test', Brand__c = brand.Id, Supplier__c = supplier.Id, Status_BDate__c = system.today());
            insert bd;
            // insert product
            product = new Product2(Name = 'P-Test', ProductCode = 'P-Test', Category__c = section.Id, Brand__c = brand.Id, IsActive = true);
            insert product;
            // Create PG
            pg = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG1', Product__c = product.Id, SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department.Id, Section__c = section.Id, Supplier__c = supplier.Id, Brand__c = brand.Id);
            insert pg;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_constructor() {
        init();
        ApexPages.currentPage().getParameters().put('id', supplier.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(supplier);
        Product_Selection_Controller ctrlr = new Product_Selection_Controller(stdController);
        
        system.assertEquals(supplier.Id, ctrlr.clientAssortment.Supplier__c);
        
        Integer productListingOptionsSize = ctrlr.getProductListingOptions().size();
        system.assertEquals(4, productListingOptionsSize);
        
        Product2 p = new Product2(Name = 'P001', ProductCode = 'P001', Category__c = section.Id, Brand__c = brand.Id, IsActive = true);
        insert p;
        
        ctrlr.selectedProductsIds.add(p.Id);
        Integer productsSize = ctrlr.getProducts().size();
        system.assertEquals(2, productsSize);
        
        system.assertEquals(1, [SELECT COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id]);
        ctrlr.savePGs();
    }
    @isTest static void test_ProductsSellInChartController() {
        init();
        ApexPages.currentPage().getParameters().put('id', supplier.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(supplier);
        // Test for Chart Controller
        ProductsSellInChartController ctrlr2 = new ProductsSellInChartController(stdController);
        ctrlr2.getChartData();
        system.assertEquals(0, ctrlr2.countPositiveSellInWithoutAssortment);
    }
    @isTest static void test_fastAction1() {
        init();
        Product2 p = new Product2(Name = 'P001', ProductCode = 'P001', Category__c = section.Id, Brand__c = brand.Id);
        insert p;
        // Create purchase flow
        Sell_in_Flow__c sf = new Sell_in_Flow__c(Mvt_Purch_Product__c = p.Id, Order_Amt_withouttax__c = 100, Supplier__c = supplier.Id,
                                                 Contract__c = contract.Id, Order_Tax__c = 110, Order_Date__c = date.newInstance(year, 1, 1),
                                                 Order_Quantity__c = 1, Master_BU__c = country.Id, Invoice_Date__c = date.newInstance(year, 1, 1),
                                                 Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 10);
        insert sf;
        ApexPages.currentPage().getParameters().put('id', supplier.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(supplier);
        Product_Selection_Controller ctrlr = new Product_Selection_Controller(stdController);
        system.assertEquals(1, [SELECT COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id]);
        ctrlr.fastAction1();
        system.assertEquals(2, [SELECT COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id]);
    }
    @isTest static void test_fastAction2() {
        init();
        Product2 p = new Product2(Name = 'P001', ProductCode = 'P001', Category__c = section.Id, Brand__c = brand.Id);
        insert p;
        pg.Product__c = p.Id;
        update pg;
        ApexPages.currentPage().getParameters().put('id', supplier.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(supplier);
        Product_Selection_Controller ctrlr = new Product_Selection_Controller(stdController);
        system.assertEquals(1, [SELECT COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id]);
        ctrlr.fastAction2();
        system.assertEquals(0, [SELECT COUNT() FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id]);
    }
}