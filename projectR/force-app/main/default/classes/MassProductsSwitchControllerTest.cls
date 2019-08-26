@isTest
private class MassProductsSwitchControllerTest {
    
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Orga_BU__c assortmentClust1;
    private static Orga_BU__c assortmentClust2;
    private static Orga_BU__c buSource;
    private static Orga_BU__c buTarget;
    private static Sup_Supplier__c supplier;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product1;
    private static Product2 referenceProduct1;
    private static Product2 product2;
    private static Product2 referenceProduct2;
    private static Assortment_BU__c assortmentBU;
    private static NegoptimCustomSettings__c negoCustomSettings;
    
    static void init() {
        // Create negoCustomSettings
        negoCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
        negoCustomSettings.Product_Switch_Grid_Layout__c = 'Product_Switch';
        insert negoCustomSettings;
        // Root element Id.
        rootId = NegoptimHelper.getRootId();
        // Get the Corporate Currency.
        currencyIsoCode = NegoptimHelper.getCorporateCurrency();
        // Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
        /*// Create Assortment Clusters
        assortmentClust1 = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat0');
        assortmentClust2 = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat1');
        insert new List<Orga_BU__c>{assortmentClust1, assortmentClust2};*/
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        country.Related_Client__c = supplier.Id;
        update country;
        /*// Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];*/
        // Create Departments & Sections.
        department = TestDataFactory.createDepartment(true, rootId);
        section = TestDataFactory.createSection(true, department.Id);
        // Create Products.
        referenceProduct1 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
        referenceProduct1.Product_Reference_Type__c = null;
        referenceProduct2 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
        referenceProduct2.Product_Reference_Type__c = null;
        insert new List<Product2> {referenceProduct1, referenceProduct2};
        product1 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
        product1.Market_Introduction_Date__c = Date.today();
        product1.isSwitch__c = true;
        product1.Reference_Product__c = referenceProduct1.Id;
        product1.isActive = true;
        product2 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
        product2.Market_Introduction_Date__c = Date.today();
        product2.isSwitch__c = true;
        product2.isActive = true;
        insert new List<Product2> {product1, product2};
        // create Source BU Banner
        buSource = TestDataFactory.createBUBanner(false, country);
        buSource.Related_Client__c = supplier.Id;
        buSource.IsMasterBU__c = true;
        // create Target BU Banner
        buTarget = TestDataFactory.createBUBanner(false, country);
        buTarget.Related_Client__c = supplier.Id;
        buTarget.Category__c = department.Id;
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        insert new List<Orga_BU__c> {buSource, buTarget};
        // insert assortment_BU
        assortmentBU = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        assortmentBU.Ass_BDate__c = System.today()-1;
        assortmentBU.Ass_EDate__c = System.today().addmonths(1);
        assortmentBU.Assortment_Type__c = 'Out';
        assortmentBU.Assortment__c = 'Deal';
        assortmentBU.Status__c = 'Validated';
        assortmentBU.RecordTypeId = TestDataFactory.assortmentRTIds.get('Nego');
        insert assortmentBU;
        Assortment_Detail__c assortmentDetail1 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = referenceProduct1.Id, Client_Status__c = 'New');
        Assortment_Detail__c assortmentDetail2 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = referenceProduct2.Id, Client_Status__c = 'New');
        insert new List<Assortment_Detail__c>{assortmentDetail1, assortmentDetail2};
    }
    
    static testMethod void test_constructor() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Product2());
        Test.startTest();
        MassProductsSwitchController ctrl = new MassProductsSwitchController(stdController);
        Test.stopTest();
        // Assertion.
        System.assert(ctrl.gridSettingsManager.ERRORS.isEmpty());
    }
    
    static testMethod void test_switchAndSave() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Product2());
        Test.startTest();
        MassProductsSwitchController ctrl = new MassProductsSwitchController(stdController);
        // update product reference
        /*product.Reference_Product__c = referenceProduct.Id;
        update product;
        referenceProduct = [SELECT IsReferenceProduct__c FROM Product2 WHERE Id = :referenceProduct.Id];
        System.assertEquals(true, referenceProduct.IsReferenceProduct__c);*/
        // search results
        ctrl.onlySwitchProduct = false;
        ctrl.searchProducts();
        /*referenceProduct.IsReferenceProduct__c = false;
        update referenceProduct;*/
        product2.Reference_Product__c = referenceProduct2.Id;
        ctrl.introducedProductId = product2.Id;
        // call switch
        ctrl.switchProduct();
        // save results
        ctrl.save();
        Test.stopTest();
        // Assertion.
        /// System.assertEquals(1, ctrl.orgaBUList.size());
    }    
    
    static testMethod void test_pagination() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Product2());
        Test.startTest();
        MassProductsSwitchController ctrl = new MassProductsSwitchController(stdController);
        ctrl.onlySwitchProduct = true;
        ctrl.selectedMonths = '1,2,3,4,5,6,7,8,9,11,12';
        ctrl.searchProducts();
        ctrl.pageSize = 1;
        ctrl.refreshPageSize();
        ctrl.next();
        ctrl.last();
        ctrl.previous();
        ctrl.first();
        Test.stopTest();
        System.assertEquals(2, ctrl.noOfRecords);
    }
}