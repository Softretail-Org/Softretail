@isTest
private class MassProductsActionControllerTest {
    
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Orga_BU__c buList;
    private static Orga_BU__c buSource;
    private static Orga_BU__c buBanner1;
    private static Orga_BU__c buBanner2;
    private static Orga_BU__c assortmentClust1;
    private static Orga_BU__c assortmentClust2;
    private static Sup_Supplier__c supplier;
    private static Orga_HE__c department1;
    private static Orga_HE__c section1;
    private static Orga_HE__c department2;
    private static Orga_HE__c section2;
    private static Product2 product1;
    private static Product2 product2;
    private static Assortment_BU__c assortmentBU;
    private static NegoptimCustomSettings__c negoCustomSettings;
	
    static void init() {
        // Create negoCustomSettings
        negoCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
        negoCustomSettings.Product_Inno_Grid_Layout__c = 'Product_Inno';
        negoCustomSettings.Product_Stop_Grid_Layout__c = 'Product_Stop';
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
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        country.Related_Client__c = supplier.Id;
        update country;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        // Create Departments & Sections.
        department1 = TestDataFactory.createDepartment(true, rootId);
        section1 = TestDataFactory.createSection(true, department1.Id);
        department2 = TestDataFactory.createDepartment(true, rootId);
        section2 = TestDataFactory.createSection(true, department2.Id);
        // create banners
        buSource = TestDataFactory.createBUBanner(false, country);
        buSource.IsMasterBU__c = true;
        buBanner1 = TestDataFactory.createBUBanner(false, country);
        buBanner1.Related_Client__c = supplier.Id;
        buBanner1.Format_Origin__c = 'Hypermarket';
        buBanner1.Category__c = department1.Id;
        buBanner1.Mission__c = 'Offer';
        buBanner2 = TestDataFactory.createBUBanner(false, country);
        buBanner2.Related_Client__c = supplier.Id;
        buBanner2.Format_Origin__c = 'Hypermarket';
        buBanner2.Category__c = department2.Id;
        buBanner2.Mission__c = 'Offer';
        insert new List<Orga_BU__c>{buSource, buBanner1, buBanner2};
        // Create Assortment Clusters
        assortmentClust1 = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat0');
        assortmentClust2 = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat1');
        insert new List<Orga_BU__c>{assortmentClust1, assortmentClust2};
        Orga_BU_List_Detail__c buList1 = new Orga_BU_List_Detail__c(Entity__c = buBanner1.Id, Entity_List__c = assortmentClust1.Id);
        Orga_BU_List_Detail__c buList2 = new Orga_BU_List_Detail__c(Entity__c = buBanner2.Id, Entity_List__c = assortmentClust2.Id);
        insert new List<Orga_BU_List_Detail__c>{buList1, buList2};
        // Create Products.
        product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        product2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
        insert new List<Product2>{product1, product2};
        // insert assortment_BU
        assortmentBU = TestDataFactory.createAssortmentBU(true, buSource, buBanner1, department1);
    }
    
    static testMethod void test_constructor() {
        init();
        Test.startTest();
        MassProductsActionController ctrl = new MassProductsActionController();
        ctrl.introAction();
        ctrl.stopAction();
        ctrl.searchRecords();
        Test.stopTest();
        // Assertion.
        System.assertEquals(2, ctrl.assortmentBUsMap.size());
        System.assertEquals(4, [SELECT COUNT() FROM Product_Assortment_Introduction_History__c]);
    }
    
    static testMethod void test_productInnoAndStop() {
        init();
        Test.startTest();
        MassProductsActionController ctrl = new MassProductsActionController();
        // CASE PRODUCT INNO
        ctrl.introAction();
        List<Product_Assortment_Introduction_History__c> productAssortments = [SELECT Id FROM Product_Assortment_Introduction_History__c
                                                                               WHERE Product__c = :product1.Id
                                                                               AND RecordType.DeveloperName = 'Inno'];
        ctrl.selectedLoadRule = 'Any current & next assortment';
        Product_Assortment_Introduction_History__c productInno;
        if(productAssortments != null) {
            List<Product_Assortment_Introduction_History__c> productInnos;
            Product_Assortment_Introduction_History__c record = ctrl.initialProductIntroHistoryMap.get(product1.Id + '' + buBanner1.Id);
            if(record != null) {
                productInno = record.clone(true);
                productInno.Load_Status__c = 'Yes';
                productInno.BU_Assortment__c = assortmentClust1.Id;
                ctrl.updatedProductIntroHistoryMap.put(product1.Id + '' + buBanner1.Id, productInno);
                ctrl.save();
            }
        }
        // Assertion.
        System.assertNotEquals(null, productInno);
        System.assertEquals(1, [SELECT COUNT() FROM Assortment_Detail__c]);
        
        // CASE PRODUCT STOP
        product1.Market_End_of_Life_Date__c = System.today();
        update product1;
        ctrl.stopAction();
        productAssortments = [SELECT Id FROM Product_Assortment_Introduction_History__c
                              WHERE Product__c = :product1.Id
                              AND RecordType.DeveloperName = 'Stop'];
        Product_Assortment_Introduction_History__c productStop;
        if(productAssortments != null) {
            Product_Assortment_Introduction_History__c record = ctrl.initialProductIntroHistoryMap.get(product1.Id + '' + buBanner1.Id);
            if(record != null) {
                productStop = record.clone(true);
                productStop.Load_Status__c = 'Yes';
                ctrl.updatedProductIntroHistoryMap.put(product1.Id + '' + buBanner1.Id, productStop);
                ctrl.save();
            }
        }
        Test.stopTest();
        // Assertion.
        System.assertNotEquals(null, productStop);
        Assortment_Detail__c assortmentDetail = [SELECT Client_Status__c FROM Assortment_Detail__c WHERE Product__c = :product1.Id];
        System.assertEquals('Delete', assortmentDetail.Client_Status__c);
    }
}