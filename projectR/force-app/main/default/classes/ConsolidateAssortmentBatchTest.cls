@isTest
private class ConsolidateAssortmentBatchTest {

    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Orga_BU__c buConsoHMSM;
    private static Orga_BU__c buConsoDrive;
    private static Orga_BU__c masterBU;
    private static Orga_BU__c buList;
    private static Orga_BU__c buBannerHM;
    private static Orga_BU__c buBannerSM;
    private static Orga_BU__c buBannerDrive;
    private static Sup_Supplier__c client;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product1;
    private static Product2 product2;
    private static Orga_BU__c cluster1;
    private static Orga_BU__c cluster2;
    private static Orga_BU__c cluster3;
    
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
        product1 = TestDataFactory.createProduct(false, section.Id, null);
        product1.Ext_id__c = '1';
        product2 = TestDataFactory.createProduct(false, section.Id, null);
        product2.Ext_id__c = '2';
        insert new List<Product2>{product1,product2};
        // Create Conso BO
        buConsoHMSM = TestDataFactory.createBUBanner(false, country);
        buConsoHMSM.Mission__c = 'Nielsen;Offer';
        buConsoHMSM.Format_Origin__c = 'Hypermarket;Supermarket';
        buConsoHMSM.Related_Client__c = client.Id;
        buConsoHMSM.Layer_Nego_Conso__c = true;
        buConsoHMSM.Category__c = department.Id;
        buConsoDrive = TestDataFactory.createBUBanner(false, country);
        buConsoDrive.Mission__c = 'Nielsen;Offer';
        buConsoDrive.Format_Origin__c = 'Drive';
        buConsoDrive.Related_Client__c = client.Id;
        buConsoDrive.Layer_Nego_Conso__c = true;
        buConsoDrive.Category__c = department.Id;
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
        buBannerHM = TestDataFactory.createBUBanner(false, country);
        buBannerHM.Mission__c = 'Offer';
        buBannerHM.Format_Origin__c = 'Hypermarket;Supermarket;';
        buBannerHM.Related_Client__c = client.Id;
        buBannerHM.Category__c = department.Id;
        buBannerSM = TestDataFactory.createBUBanner(false, country);
        buBannerSM.Mission__c = 'Offer';
        buBannerSM.Format_Origin__c = 'Hypermarket;Supermarket;';
        buBannerSM.Related_Client__c = client.Id;
        buBannerSM.Category__c = department.Id;
        buBannerDrive = TestDataFactory.createBUBanner(false, country);
        buBannerDrive.Mission__c = 'Offer';
        buBannerDrive.Format_Origin__c = 'Drive;';
        buBannerDrive.Related_Client__c = client.Id;
        buBannerDrive.Category__c = department.Id;
        insert new List<Orga_BU__c>{buConsoHMSM,buConsoDrive,masterBU,buBannerHM,buBannerSM,buBannerDrive};
        // Create BU Cluster
        cluster1 = TestDataFactory.createBUAssortCluster(false, buBannerHM.Id, 'Strat0');
        cluster1.Category__c = department.Id;
        cluster1.Weighted_Distribution_Manual__c = 10;
        cluster1.Weighted_Distribution_Manual_N1__c = 10;
        cluster1.SiteOfSales_Number__c = 20;
        cluster1.Mission__c = 'Offer';
        cluster1.BU_ODate__c = Date.today().addDays(-1);
        cluster1.Country_origin__c = buBannerHM.Id;
        cluster2 = TestDataFactory.createBUAssortCluster(false, buBannerSM.Id, 'Strat0');
        cluster2.Category__c = department.Id;
        cluster2.Weighted_Distribution_Manual__c = 20;
        cluster2.Weighted_Distribution_Manual_N1__c = 20;
        cluster2.SiteOfSales_Number__c = 30;
        cluster2.BU_ODate__c = Date.today().addDays(-1);
        cluster2.Mission__c = 'Offer';
        cluster2.Country_origin__c = buBannerSM.Id;
        cluster3 = TestDataFactory.createBUAssortCluster(false, buBannerDrive.Id, 'Strat0');
        cluster3.Category__c = department.Id;
        cluster3.Weighted_Distribution_Manual__c = 20;
        cluster3.Weighted_Distribution_Manual_N1__c = 20;
        cluster3.SiteOfSales_Number__c = 30;
        cluster3.BU_ODate__c = Date.today().addDays(-1);
        cluster3.Mission__c = 'Offer';
        cluster3.Country_origin__c = buBannerDrive.Id;
        insert new List<Orga_BU__c>{cluster1,cluster2,cluster3};
    }
    
    @isTest static void consolidateAssortmentDetails() {
        init();
        Test.startTest();
        // insert assortment_BU
        Assortment_BU__c assortmentBU1 = TestDataFactory.createAssortmentBU(false, masterBU, buBannerHM, department);
        assortmentBU1.Status__c = 'Validated';
        Assortment_BU__c assortmentBU2 = TestDataFactory.createAssortmentBU(false, masterBU, buBannerSM, department);
        assortmentBU2.Status__c = 'Validated';
        Assortment_BU__c assortmentBU3 = TestDataFactory.createAssortmentBU(false, masterBU, buBannerDrive, department);
        assortmentBU3.Status__c = 'Validated';
        insert new List<Assortment_BU__c>{assortmentBU1,assortmentBU2,assortmentBU3};
        // insert Assortment_Detail__c
        Assortment_Detail__c assortmentDetail1 = TestDataFactory.createAssortmentDetail(false, assortmentBU1.Id, product1, null);
        assortmentDetail1.Status__c = 'Validated';
        assortmentDetail1.Client_Status__c = 'New';
        assortmentDetail1.New_Client_WD_ClientBased__c = 11;
        assortmentDetail1.WD_Conso__c = false;
        Assortment_Detail__c assortmentDetail2 = TestDataFactory.createAssortmentDetail(false, assortmentBU1.Id, product2, null);
        assortmentDetail2.Status__c = 'Validated';
        assortmentDetail2.Client_Status__c = 'New';
        assortmentDetail2.New_Client_WD_ClientBased__c = 22;
        assortmentDetail2.WD_Conso__c = false;
        
        Assortment_Detail__c assortmentDetail3 = TestDataFactory.createAssortmentDetail(false, assortmentBU2.Id, product1, null);
        assortmentDetail3.Status__c = 'Validated';
        assortmentDetail3.Client_Status__c = 'New';
        assortmentDetail3.New_Client_WD_ClientBased__c = 33;
        assortmentDetail3.WD_Conso__c = false;
        Assortment_Detail__c assortmentDetail4 = TestDataFactory.createAssortmentDetail(false, assortmentBU2.Id, product2, null);
        assortmentDetail4.Status__c = 'Validated';
        assortmentDetail4.Client_Status__c = 'New';
        assortmentDetail4.New_Client_WD_ClientBased__c = 88;
        assortmentDetail4.WD_Conso__c = false;
        
        Assortment_Detail__c assortmentDetail5 = TestDataFactory.createAssortmentDetail(false, assortmentBU3.Id, product1, null);
        assortmentDetail5.Status__c = 'Validated';
        assortmentDetail5.Client_Status__c = 'New';
        assortmentDetail5.New_Client_WD_ClientBased__c = 6;
        assortmentDetail5.WD_Conso__c = false;
        Assortment_Detail__c assortmentDetail6 = TestDataFactory.createAssortmentDetail(false, assortmentBU3.Id, product2, null);
        assortmentDetail6.Status__c = 'Validated';
        assortmentDetail6.Client_Status__c = 'New';
        assortmentDetail6.New_Client_WD_ClientBased__c = 7;
        assortmentDetail6.WD_Conso__c = false;
        insert new List<Assortment_Detail__c>{assortmentDetail1,assortmentDetail2,assortmentDetail3,assortmentDetail4,assortmentDetail5,assortmentDetail6};
            
        Database.executeBatch(new ConsolidateAssortmentBatch('ConsolidateAssortmentBatchTest', null, new Set<Integer>{year}, null));
        Test.stopTest();
        Assortment_Detail__c assortmentDetailConso1 = [SELECT New_Client_WD_ClientBased__c FROM Assortment_Detail__c 
                                                       WHERE Product__c = :product1.Id AND Assortment_BU__r.BU_Target__c = :buConsoHMSM.Id
                                                       AND Assortment_BU__r.RecordType.DeveloperName = 'Conso'];
        Assortment_Detail__c assortmentDetailConso2 = [SELECT New_Client_WD_ClientBased__c FROM Assortment_Detail__c 
                                                       WHERE Product__c = :product2.Id AND Assortment_BU__r.BU_Target__c = :buConsoHMSM.Id
                                                       AND Assortment_BU__r.RecordType.DeveloperName = 'Conso'];
        assortmentDetail5 = [SELECT Id, WD_Conso__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail5.Id];
        System.assertEquals(true, assortmentDetail5.WD_Conso__c);
        Assortment_Detail__c assortmentDetailConso3 = [SELECT New_Client_WD_ClientBased__c FROM Assortment_Detail__c 
                                                       WHERE Product__c = :product1.Id AND Assortment_BU__r.BU_Target__c = :buConsoDrive.Id
                                                       AND Assortment_BU__r.RecordType.DeveloperName = 'Conso'];
        System.assertEquals(2, [SELECT COUNT() FROM Assortment_BU__c WHERE RecordType.DeveloperName = 'Conso']);
        System.assertEquals(44, assortmentDetailConso1.New_Client_WD_ClientBased__c);
        System.assertEquals(110, assortmentDetailConso2.New_Client_WD_ClientBased__c);
        System.assertEquals(6, assortmentDetailConso3.New_Client_WD_ClientBased__c);
    }
    
    @isTest static void resetAssortmentDetails() {
        init();
        Test.startTest();
        // insert assortment_BU
        Assortment_BU__c assortmentBU1 = TestDataFactory.createAssortmentBU(false, masterBU, buBannerHM, department);
        assortmentBU1.Status__c = 'Validated';
        Assortment_BU__c assortmentBU2 = TestDataFactory.createAssortmentBU(false, masterBU, buBannerSM, department);
        assortmentBU2.Status__c = 'Validated';
        Assortment_BU__c assortmentBU3 = TestDataFactory.createAssortmentBU(false, masterBU, buBannerDrive, department);
        assortmentBU3.Status__c = 'Validated';
        // insert assortment_BU Conso
        Assortment_BU__c assortmentBUConso1 = TestDataFactory.createAssortmentBU(false, masterBU, buConsoHMSM, department);
        assortmentBUConso1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.SObjectType, 'Conso');
        assortmentBUConso1.Status__c = 'Validated';
        Assortment_BU__c assortmentBUConso2 = TestDataFactory.createAssortmentBU(false, masterBU, buConsoDrive, department);
        assortmentBUConso2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.SObjectType, 'Conso');
        assortmentBUConso2.Status__c = 'Validated';
        insert new List<Assortment_BU__c>{assortmentBU1,assortmentBU2,assortmentBU3,assortmentBUConso1,assortmentBUConso2};
       
        // insert Assortment_Detail__c Linked to HMSM
        Assortment_Detail__c assortmentDetail1 = TestDataFactory.createAssortmentDetail(false, assortmentBU1.Id, product1, null);
        assortmentDetail1.Status__c = 'Validated';
        assortmentDetail1.Client_Status__c = 'New';
        assortmentDetail1.New_Client_WD_ClientBased__c = 11;
        assortmentDetail1.WD_Conso__c = true;
        // insert Assortment_Detail__c Linked to HMSM
        Assortment_Detail__c assortmentDetail2 = TestDataFactory.createAssortmentDetail(false, assortmentBU2.Id, product1, null);
        assortmentDetail2.Status__c = 'Validated';
        assortmentDetail2.Client_Status__c = 'New';
        assortmentDetail2.New_Client_WD_ClientBased__c = 33;
        assortmentDetail2.WD_Conso__c = true;
        // insert Assortment_Detail__c Linked to Drive
        Assortment_Detail__c assortmentDetail3 = TestDataFactory.createAssortmentDetail(false, assortmentBU3.Id, product1, null);
        assortmentDetail3.Status__c = 'Validated';
        assortmentDetail3.Client_Status__c = 'New';
        assortmentDetail3.New_Client_WD_ClientBased__c = 6;
        assortmentDetail3.WD_Conso__c = true;
        
        // insert Assortment_Detail__c Conso Linked to HMSM
        Assortment_Detail__c assortmentDetailConsoHMSM = TestDataFactory.createAssortmentDetail(false, assortmentBUConso1.Id, product1, null);
        assortmentDetailConsoHMSM.Status__c = 'Validated';
        assortmentDetailConsoHMSM.Client_Status__c = 'New';
        assortmentDetailConsoHMSM.New_Client_WD_ClientBased__c = 44;
        // insert Assortment_Detail__c Conso inked to Drive
        Assortment_Detail__c assortmentDetailConsoDrive = TestDataFactory.createAssortmentDetail(false, assortmentBUConso2.Id, product1, null);
        assortmentDetailConsoDrive.Status__c = 'Validated';
        assortmentDetailConsoDrive.Client_Status__c = 'New';
        assortmentDetailConsoDrive.New_Client_WD_ClientBased__c = 6;
        insert new List<Assortment_Detail__c>{assortmentDetail1,assortmentDetail2,assortmentDetail3,assortmentDetailConsoHMSM,assortmentDetailConsoDrive};
        // update Assortment_Detail__c Linked to HMSM
        assortmentDetail2.New_Client_WD_ClientBased__c = 12;
        assortmentDetail3.New_Client_WD_ClientBased__c = 7;
        update new List<Assortment_Detail__c>{assortmentDetail2,assortmentDetail3};
        Test.stopTest();
        assortmentDetailConsoHMSM = [SELECT New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetailConsoHMSM.Id];
        assortmentDetailConsoDrive = [SELECT New_Client_WD_ClientBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetailConsoDrive.Id];
        System.assertEquals(23, assortmentDetailConsoHMSM.New_Client_WD_ClientBased__c);
        System.assertEquals(7, assortmentDetailConsoDrive.New_Client_WD_ClientBased__c);
    }
}