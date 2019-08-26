@isTest
private class MarketDataCollectionSynchroBatchTest {
    
    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c masterBU;
    private static Orga_BU__c buList;
    private static Orga_BU__c buBanner1;
    private static Orga_BU__c buBanner2;
    private static Orga_BU__c cluster1;
    private static Orga_BU__c cluster2;
    private static Orga_BU__c cluster3;
    private static Sup_Supplier__c client;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c department;
    private static Orga_HE__c category;
    private static Sup_Brand__c brand;
    private static Product2 product;
    
    static void init() {
        try {
            year = System.Today().year();
            month = System.Today().month();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region.
            region = TestDataFactory.createBURegion(false, 'MEA');
            insert region;
            // Create Country.
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Supplier.
            client = TestDataFactory.createSupplier(false, country, true);
            insert client;
            // Create NS.
            NS = TestDataFactory.getNSs(client.Id)[0];
            // Create Department
            department = TestDataFactory.createDepartment(true, rootId);
            // Create category        
            category = TestDataFactory.createSection(true, department.Id);
            // Create brand
            brand = TestDataFactory.createBrand(false, client.Id);
            insert brand;
            // insert product
            product = TestDataFactory.createProduct(false, category.Id, client.Id);
            product.Product_EAN__c ='12345';
            insert product;
            // Create Master BU
            masterBU = TestDataFactory.createBUBanner(false, country);
            masterBU.Mission__c = 'Nielsen;Offer';
            masterBU.Format_Origin__c = 'Hypermarket;Supermarket;Drive';
            masterBU.Related_Client__c = client.Id;
            masterBU.IsMasterBU__c = true;
            masterBU.SiteOfSales_Number__c = 100;
            // Create BU List
            buList = TestDataFactory.createBUList(false, country.Id);
            buList.Mission__c = 'Nielsen;Offer';
            buList.Format_Origin__c = 'Supermarket;Drive';
            buList.Related_Client__c = client.Id;
            insert buList;
            // Create BU Banner
            buBanner1 = TestDataFactory.createBUBanner(false, country);
            buBanner1.Mission__c = 'Offer';
            buBanner1.Format_Origin__c = 'Supermarket;Drive';
            buBanner1.Related_Client__c = client.Id;
            buBanner1.Category__c = department.Id;
            buBanner2 = TestDataFactory.createBUBanner(false, country);
            buBanner2.Mission__c = 'Offer';
            buBanner2.Format_Origin__c = 'Supermarket;Drive';
            buBanner2.Related_Client__c = client.Id;
            buBanner2.Category__c = department.Id;
            insert new List<Orga_BU__c>{masterBU,buBanner1,buBanner2};
            // Create BU Cluster
            cluster1 = TestDataFactory.createBUAssortCluster(false, buBanner1.Id, 'Strat0');
            cluster1.Category__c = department.Id;
            cluster1.Weighted_Distribution_Manual__c = 10;
            cluster1.SiteOfSales_Number__c = 20;
            cluster1.BU_ODate__c = Date.today().addDays(-1);
            cluster2 = TestDataFactory.createBUAssortCluster(false, buBanner1.Id, 'Strat1');
            cluster2.Category__c = department.Id;
            cluster2.Weighted_Distribution_Manual__c = 20;
            cluster2.SiteOfSales_Number__c = 30;
            cluster2.BU_ODate__c = Date.today().addDays(-1);
            insert new List<Orga_BU__c>{cluster1,cluster2};
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // Insert Market Review/Market Review Detail
    @isTest static void caseInsertMarketReview_Success() {
        init();
        Test.startTest();
        // insert assortment BU
        Assortment_BU__c assortmentBU = TestDataFactory.createAssortmentBU(false, masterBU, buBanner1, department);
        assortmentBU.Status__c = 'Validated';
        insert assortmentBU;
        // insert assortment detail
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, cluster1.Id);
        assortmentDetail.Client_Status__c = 'Keep';
        assortmentDetail.Status__c = 'Validated';
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetail;
        // insert assortment detail sequence
        Assortment_Detail_Sequence__c assortmentDetailSequence = TestDataFactory.createAssortmentDetailSequence(true, assortmentDetail.Id);
        // insert assortment Matrix reviews
        Assortment_Matrix_review__c assortmentMatrixReview = TestDataFactory.createAssortmentMatrixReview(false, masterBU.Id, buBanner1.Id, product.Id, 'Fact1');
        insert assortmentMatrixReview;
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, department, client);
        marketHead.Status__c = 'Scan w/ success';
        insert markethead;
        Market_Data_Collection_Detail__c marketDetail = TestDataFactory.createMarketDataCollectionDetail(false, markethead.Id, buBanner1, department, product, brand);
        marketDetail.Status__c = 'Scan w/ success';
        insert marketDetail;
        Database.executeBatch(new MarketDataCollectionSynchroBatch('MarketDataCollectionSynchroBatch', new List<Id>{marketHead.Id}, null));
        Test.stopTest();
        // Validation Test
        marketHead = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :marketHead.Id];
        marketDetail = [SELECT Id, Name, Status__c, WD_1_SEQ__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];
        System.assertEquals(marketHead.Status__c, 'Synchro w/ success');
        System.assertEquals(marketDetail.Status__c, 'Synchro w/ success');
        Market_Review_Detail_BU__c marketReviewDetailBU = [SELECT Fact_ND1_ClientBased_SEQ__c, Fact_WD1_ClientBased_SEQ__c, Fact_WD1_MarketBased_SEQ__c
                                                           FROM Market_Review_Detail_BU__c WHERE Orga_BU__c = :buBanner1.Id AND Product__c = :product.Id];
        assortmentDetail = [SELECT Fact_ND_ClientBased__c, Fact_WD_MarketBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        assortmentDetailSequence = [SELECT Fact_WD_ClientBased__c FROM Assortment_Detail_Sequence__c WHERE Id = :assortmentDetailSequence.Id];
        assortmentMatrixReview = [SELECT Id, WD_Marketbase__c FROM Assortment_Matrix_review__c WHERE Id = :assortmentMatrixReview.Id];
        System.assertEquals(0/*marketReviewDetailBU.Fact_ND1_ClientBased_SEQ__c*/, assortmentDetail.Fact_ND_ClientBased__c);
        System.assertEquals(marketDetail.WD_1_SEQ__c * 30/100, marketReviewDetailBU.Fact_WD1_MarketBased_SEQ__c);
        System.assertEquals(marketReviewDetailBU.Fact_WD1_ClientBased_SEQ__c, assortmentDetailSequence.Fact_WD_ClientBased__c);
        System.assertEquals(marketReviewDetailBU.Fact_WD1_MarketBased_SEQ__c, assortmentMatrixReview.WD_Marketbase__c);
    }
    
    // Insert Market Review/Market Review Detail
    @isTest static void caseInsertMarketReview_Fails() {
        init();
        Test.startTest();
        // Create category with level > 2
        Orga_HE__c category1 = TestDataFactory.createSection(false, category.Id);
        insert category1;
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, category1, client);
        marketHead.Status__c = 'Scan w/ success';
        insert markethead;
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetail = TestDataFactory.createMarketDataCollectionDetail(false, markethead.Id, buBanner1, category1, product, brand);
        marketDetail.Status__c = 'Scan w/ success';
        insert marketDetail;
        Database.executeBatch(new MarketDataCollectionSynchroBatch('MarketDataCollectionSynchroBatch', new List<Id>{marketHead.Id}, null));
        Test.stopTest();
        // Validation Test
        marketHead = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :marketHead.Id];
        System.assertEquals(marketHead.Status__c, 'Synchro w/ error');
    }
    
    // Update Market Review/Market Review Detail
    @isTest static void caseUpdateMarketReview_Success() {
        init();
        Test.startTest();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, department, client);
        marketHead.Status__c = 'Scan w/ success';
        insert markethead;
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetail = TestDataFactory.createMarketDataCollectionDetail(false, markethead.Id, buBanner1, category, product, brand);
        marketDetail.Status__c = 'Scan w/ success';
        insert marketDetail;
        // insert Market_review__c
        Market_review__c marketReview = TestDataFactory.createMarketReview(true, marketHead.Master_BU__c, buList.Format_Origin__c, marketHead.Orga_HE__c);
        // insert Market_Review_Detail_BU__c
        Market_Review_Detail_BU__c marketReviewDetailBU = TestDataFactory.createMarketReviewDetailBU(true, marketReview.Id, buList.Id, marketDetail.Product__c);
        Database.executeBatch(new MarketDataCollectionSynchroBatch('MarketDataCollectionSynchroBatch', new List<Id>{marketHead.Id}, null));
        Test.stopTest();
        // Validation Test
        marketHead = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :marketHead.Id];
        marketDetail = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];
        System.assertEquals(marketHead.Status__c, 'Synchro w/ success');
        System.assertEquals(marketDetail.Status__c, 'Synchro w/ success');
    }
}