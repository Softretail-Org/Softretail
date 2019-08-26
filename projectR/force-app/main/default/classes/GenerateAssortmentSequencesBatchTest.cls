@isTest
private class GenerateAssortmentSequencesBatchTest {
    
    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Orga_BU__c masterBU;
    private static Orga_BU__c buList;
    private static Orga_BU__c buTarget;
    private static Orga_BU__c cluster1;
    private static Orga_BU__c cluster2;
    private static Orga_BU__c refCluster;
    private static Sup_Supplier__c client;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product;
    private static Assortment_BU__c assortmentBU;
    
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
        client = TestDataFactory.createSupplier(false, country, true);
        insert client;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(client.Id)[0];
        // Create Departments & Sections.
        department = TestDataFactory.createDepartment(true, rootId);
        section = TestDataFactory.createSection(true, department.Id);
        // Create Product.
        product = TestDataFactory.createProduct(false, section.Id, null);
        insert product;
        // Create Master BU
        masterBU = TestDataFactory.createBUBanner(false, country);
        masterBU.Mission__c = 'Nielsen;Offer';
        masterBU.Format_Origin__c = 'Hypermarket;Supermarket;Drive';
        masterBU.Related_Client__c = client.Id;
        masterBU.IsMasterBU__c = true;
        masterBU.SiteOfSales_Number__c = 100;
        insert masterBU;
        // Create BU List
        buList = TestDataFactory.createBUList(false, country.Id);
        buList.Mission__c = 'Nielsen;Offer';
        buList.Format_Origin__c = 'Supermarket;Drive';
        buList.Related_Client__c = client.Id;
        insert buList;
        // Create BU Banner
        buTarget = TestDataFactory.createBUBanner(false, country);
        buTarget.Mission__c = 'Offer';
        buTarget.Format_Origin__c = 'Supermarket;Drive';
        buTarget.Related_Client__c = client.Id;
        buTarget.Category__c = department.Id;
        for(Integer i = 1; i <= 12; i++) {
            buTarget.put('Weighted_Distribution_InnovRise_M'+ i +'__c', i);
            buTarget.put('Weighted_Distribution_SwitchRise_M'+ i +'__c', i);
            buTarget.put('Weighted_Distribution_StopRise_M'+ i +'__c', i);
        }
        insert buTarget;
        // Create BU Cluster
        cluster1 = TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat0');
        cluster1.Category__c = department.Id;
        cluster1.Weighted_Distribution_Manual__c = 10;
        cluster1.SiteOfSales_Number__c = 1;
        cluster2 = TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat1');
        cluster2.Category__c = department.Id;
        cluster2.Weighted_Distribution_Manual__c = 10;
        cluster2.SiteOfSales_Number__c = 9;
        insert new List<Orga_BU__c>{cluster1,cluster2};
        // insert assortment_BU
        assortmentBU = TestDataFactory.createAssortmentBU(false, masterBU, buTarget, department);
        assortmentBU.Status__c = 'Validated';
        insert assortmentBU;
    }
   
    @isTest static void case1_AssortmentBudget_Success() {
        init();
        Test.startTest();
        // insert Assortment_BU__c
        Assortment_BU__c assortmentBUBudget = TestDataFactory.createAssortmentBU(false, masterBU, buTarget, department);
        assortmentBUBudget.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.getSObjectType(), 'Target');
        assortmentBUBudget.Status__c = 'Validated';
        insert assortmentBUBudget;
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, assortmentBUBudget.Id, product, null);
        assortmentDetail.Status__c = 'Validated';
        assortmentDetail.Client_Status__c = 'New';
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetail;
        Test.stopTest();
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();        
        Integer month = Date.today().month();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Budget_ND_MarketBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            Integer WDSequence = 1;
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                Decimal WDRise = Decimal.valueOf(String.valueOf(buTarget.get('Weighted_Distribution_InnovRise_M'+ WDSequence +'__c')));
                if(WDRise != null) WDRise = WDRise/100;
                if(sequence == month || sequence > month) WDSequence++;
                if(sequence < month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(null, item.Budget_ND_MarketBased__c);
                }
                if(sequence == month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays, item.Budget_ND_MarketBased__c);
                }
                if(sequence > month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * WDRise, item.Budget_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
        System.assertEquals(12, [SELECT COUNT() FROM Assortment_Matrix_review__c]);
    }
    
    @isTest static void case2_ProductInno_Success() {
        init();
        Test.startTest();
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, null);
        assortmentDetail.Status__c = 'Validated';
        assortmentDetail.Client_Status__c = 'New';
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetail;
        // insert assortment detail sequence
        Assortment_Detail_Sequence__c assortmentDetailSequence = TestDataFactory.createAssortmentDetailSequence(false, assortmentDetail.Id);
        assortmentDetailSequence.Sequence__c = month;
        insert assortmentDetailSequence;
        Test.stopTest();
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            Integer WDSequence = 1;
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                Decimal WDRise = Decimal.valueOf(String.valueOf(buTarget.get('Weighted_Distribution_InnovRise_M'+ WDSequence +'__c')));
                if(WDRise != null) WDRise = WDRise/100;
                if(sequence == month || sequence > month) WDSequence++;
                if(sequence < month) {
                    System.assertEquals(null, item.New_ND_MarketBased__c);
                    System.assertEquals(null, item.Fx_ND_MarketBased__c);
                }
                if(sequence == month) {
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c*(monthDays - day + 1)/monthDays, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays, item.Fx_ND_MarketBased__c);
                }
                if(sequence > month) {
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * WDRise, item.Fx_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
        System.assertEquals(36, [SELECT COUNT() FROM Assortment_Matrix_review__c]);
    }
    
    @isTest static void case3_ProductStop_Success() {
        init();
        Test.startTest();
        // insert history assortment details
        Assortment_Detail__c history = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, cluster1.Id);
        history.Status__c = 'Validated';
        history.Client_Status__c = 'New';
        history.Version__c = 1;
        history.New_Client_ND_MarketBased__c = 10;
        history.New_Client_WD_ClientBased__c = 40;
        insert history;
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, null);
        assortmentDetail.Status__c = 'Validated';
        assortmentDetail.Client_Status__c = 'Delete';
        assortmentDetail.Version__c = null;
        assortmentDetail.Last_History__c = history.Id;
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetail;
        // generate assortment sequences
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        Test.stopTest();
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            Integer WDSequence = 1;
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                Decimal WDRise = Decimal.valueOf(String.valueOf(buTarget.get('Weighted_Distribution_InnovRise_M'+ WDSequence +'__c')));
                if(WDRise != null) WDRise = WDRise/100;
                if(sequence == month || sequence > month) WDSequence++;
                if(sequence < month) {
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c, item.Fx_ND_MarketBased__c);
                }
                if(sequence == month) {
                    System.assertEquals(history.New_Client_ND_MarketBased__c*(day - 1)/monthDays, item.New_ND_MarketBased__c);
                    System.assertEquals(history.New_Client_ND_MarketBased__c * (day - 1 + (WDRise != null ? WDRise : 0) * (monthDays - day + 1))/monthDays, item.Fx_ND_MarketBased__c);
                }
                if(sequence > month) {
                    System.assertEquals(0, item.New_ND_MarketBased__c);
                    System.assertEquals(assortmentDetail.New_Client_ND_MarketBased__c * WDRise, item.Fx_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
    }
    
    @isTest static void case4_SameCluster_Success() {
        init();
        Test.startTest();
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, cluster2.Id);
        assortmentDetail.Status__c = 'In preparation';
        assortmentDetail.Client_Status__c = 'New';
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        assortmentDetail.Ref_BU_Cluster__c = cluster1.Id;
        assortmentDetail.Ass_BU_Cluster__c = null;
        insert assortmentDetail;
        // insert previous assortment details
        assortmentDetail.Ass_BU_Cluster__c = cluster1.Id;
        assortmentDetail.Client_Status__c = 'Increase';
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        // generate assortment details sequences
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        // insert assortment detail sequence
        Assortment_Detail_Sequence__c assortmentDetailSequence = TestDataFactory.createAssortmentDetailSequence(false, assortmentDetail.Id);
        assortmentDetailSequence.Sequence__c = month;
        insert assortmentDetailSequence;
        // insert assortment Matrix reviews
        Assortment_Matrix_review__c assortmentMatrixReview = TestDataFactory.createAssortmentMatrixReview(true, masterBU.Id, buTarget.Id, product.Id, 'Negotiated');
        assortmentMatrixReview.Sequence__c = month;
        Test.stopTest();
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                if(sequence > month) {
                    System.assertEquals(10, item.New_ND_MarketBased__c);
                    System.assertEquals(10, item.Fx_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
    }
    
    @isTest static void case5_ProductIncrease_Success() {
        init();
        Test.startTest();
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, cluster2.Id);
        assortmentDetail.Status__c = 'In preparation';
        assortmentDetail.Client_Status__c = 'New';
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetail;
        // insert previous assortment details
        assortmentDetail.Ass_BU_Cluster__c = cluster1.Id;
        assortmentDetail.Client_Status__c = 'Increase';
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        // generate assortment details sequences
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        Test.stopTest();
        assortmentDetail = [SELECT Id, Status__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        Integer monthDays = Date.daysInMonth(year, month);
        Integer day = Date.today().day();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = [SELECT Id, New_ND_MarketBased__c, Fx_ND_MarketBased__c,
                                                                         New_WD_ClientBased__c, Fx_WD_ClientBased__c, Sequence__c
                                                                         FROM Assortment_Detail_Sequence__c
                                                                         WHERE Assortment_Detail__c = :assortmentDetail.Id];
        if(!assortmentDetailSequences.isEmpty()) {
            for(Assortment_Detail_Sequence__c item : assortmentDetailSequences) {
                Integer sequence = Integer.valueOf(item.Sequence__c);
                if(sequence > month) {
                    System.assertEquals(10, item.New_ND_MarketBased__c);
                    System.assertEquals(10, item.Fx_ND_MarketBased__c);
                }
            }
        }
        System.assertEquals(12, assortmentDetailSequences.size());
    }
}