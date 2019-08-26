@isTest
private class Trg_Assortment_SF_Data_Collection_Test {
    
    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Orga_BU__c buTarget;
    private static Sup_Supplier__c supplier;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product;
    
    static void init() {
        year = System.Today().year();
        month = System.Today().month();
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
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        // Create Departments & Sections.
        department = TestDataFactory.createDepartment(true, rootId);
        section = TestDataFactory.createSection(true, department.Id);
        // Create Global Settings
        NegoptimCustomSettings__c negoSettings = TestDataFactory.createNegoptimCustomSettings(true);
        // Create Product.
        product = TestDataFactory.createProduct(false, section.Id, null);
        product.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Product2.getSObjectType(), 'Product');
        insert product;
        // Create BU Banner
        buTarget = TestDataFactory.createBUBanner(false, country);
        buTarget.Mission__c = 'Offer';
        buTarget.Format_Origin__c = 'Supermarket;Drive';
        buTarget.Related_Client__c = supplier.Id;
        buTarget.Category__c = department.Id;
        insert buTarget;
    }
    
    // Insert Assortment_Matrix_review__c
    @isTest static void caseInsertAssortmentMatrixReview_Success() {
        init();
        // insert Assortment_SF_Data_Collection__c
        Assortment_SF_Data_Collection__c assortmentSF = new Assortment_SF_Data_Collection__c(Orga_BU__c = buTarget.Id, Product__c = product.Id,
                                                                                             Movment_Date__c = System.today(), ND__c = 10);
        Test.startTest();
        insert assortmentSF;
        Test.stopTest();
        // Validation Test
        System.assertEquals(1, [SELECT COUNT() FROM Assortment_Matrix_review__c]);
    }
    
    // update Assortment_Matrix_review__c
    @isTest static void caseUpdateAssortmentMatrixReview_Success() {
        init();
        // insert Assortment_Matrix_review__c
        Assortment_Matrix_review__c assortmentMatrixReview = new Assortment_Matrix_review__c(BU_Source__c = null, BU_Target__c = buTarget.Id,
                                                                                             Produit__c = product.Id, Sequence__c = System.today().month(),
                                                                                             Year__c = System.today().year(), ND__c = 10, Name__c = 'Salesforce');
        insert assortmentMatrixReview;
        // insert Assortment_SF_Data_Collection__c
        Assortment_SF_Data_Collection__c assortmentSF = new Assortment_SF_Data_Collection__c(Orga_BU__c = buTarget.Id, Product__c = product.Id,
                                                                                             Movment_Date__c = System.today(), ND__c = 10);
        insert assortmentSF;
        assortmentSF.ND__c = 20;
        Test.startTest();
        update assortmentSF;
        Test.stopTest();
        // Validation Test
        assortmentMatrixReview = [SELECT ND__c FROM Assortment_Matrix_review__c WHERE Id = :assortmentMatrixReview.Id];
        System.assertEquals(20, assortmentMatrixReview.ND__c);
    }
}