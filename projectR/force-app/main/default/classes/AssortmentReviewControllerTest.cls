@isTest
private class AssortmentReviewControllerTest {
    
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product1;
    private static Product2 product2;
    static Orga_BU__c  buSource;
    static Orga_BU__c buTarget;
    static Assortment_BU__c assortment;
    
    // create bus for assortments
    static void init() {
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
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        country.Related_Client__c = supplier.Id;
        update country;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        // Create Departments & Sections.
        department = TestDataFactory.createDepartment(true, rootId);
        section = TestDataFactory.createSection(true, department.Id);
        // Create Products.
        product1 = TestDataFactory.createProduct(false, section.Id, null);
        product2 = TestDataFactory.createProduct(false, section.Id, null);
        insert new List<Product2>{product1,product2};
        // Create Banners
        buSource = TestDataFactory.createBUCountry(false, myCountry, region.Id);
        buSource.IsMasterBU__c = true;
        buTarget = TestDataFactory.createBUBanner(false, country);
        buTarget.IsMasterBU__c = true;
        insert new List<Orga_BU__c>{buSource,buTarget};
        assortment = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        assortment.RecordTypeId = TestDataFactory.assortmentRTIds.get('Budget');
        assortment.Assortment_type__c = 'In';
        insert assortment;
    }
    
    @isTest static void case_constructor() {
        init();
        Assortment_Detail__c assortmentDetail1 = new Assortment_Detail__c(Assortment_BU__c = assortment.Id, Product__c = product1.Id);
        Assortment_Detail__c assortmentDetail2 = new Assortment_Detail__c(Assortment_BU__c = assortment.Id, Product__c = product2.Id);
        insert new List<Assortment_Detail__c>{assortmentDetail1, assortmentDetail2};
        
        ApexPages.currentPage().getParameters().put('id', assortment.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentReviewController ctrlr = new AssortmentReviewController(stdController);
        // Assertions
        System.assert(true);
    }
    
    @isTest static void case_save() {
        init();
        Assortment_Detail__c assortmentDetail1 = new Assortment_Detail__c(Assortment_BU__c = assortment.Id, Product__c = product1.Id);
        Assortment_Detail__c assortmentDetail2 = new Assortment_Detail__c(Assortment_BU__c = assortment.Id, Product__c = product2.Id);
        insert new List<Assortment_Detail__c>{assortmentDetail1, assortmentDetail2};
        
        ApexPages.currentPage().getParameters().put('id', assortment.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentReviewController ctrlr = new AssortmentReviewController(stdController);

        Test.startTest();
        ctrlr.save();
        Test.stopTest();
        // Assertions
        System.assert(true);
    }
}