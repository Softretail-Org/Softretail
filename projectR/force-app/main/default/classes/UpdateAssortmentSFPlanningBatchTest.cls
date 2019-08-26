@isTest
private class UpdateAssortmentSFPlanningBatchTest {
	
    static List<Assortment_Detail__c> assortmentDetailsList;
    static List<Assortment_SF_Planning__c> sfPlanningList;
    
    static void init() {
        Country_List__c countryList = TestDataFactory.createCountry(true, 'LEBANON', 'LB');
        Orga_BU__c region = TestDataFactory.createBURegion(true, 'REGION');
        Orga_BU__c country = TestDataFactory.createBUCountry(true, countryList, region.Id);
        Sup_Supplier__c client = TestDataFactory.createSupplier(true, country, false);
        Orga_BU__c buSource = TestDataFactory.createBUBanner(false, country);
        buSource.IsMasterBU__c = true;
        Orga_BU__c buTarget = TestDataFactory.createBUBanner(false, country);
        buTarget.IsMasterBU__c = false;
        buTarget.Mission__c = 'Offer';
        buTarget.Related_Client__c = client.Id;
        insert new List<Orga_BU__c> {buSource, buTarget};
        List<Orga_HE__c> heBranch = TestDataFactory.createElementHierarchy(4, 1);
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 10; i++) {
            products.add(TestDataFactory.createProduct(false, heBranch[4].Id, null));
        }
        insert products;
        List<Orga_BU__c> clusters = new List<Orga_BU__c>();
        for (Integer i = 0; i < 6; i++) {
            Orga_BU__c cluster = TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat' + i);
            cluster.category__c = heBranch[1].Id;
            clusters.add(cluster);
        }
        insert clusters;
        Assortment_BU__c assortment = TestDataFactory.createAssortmentBU(true, buSource, buTarget, heBranch[1]);
        assortmentDetailsList = new List<Assortment_Detail__c>();
        for (Product2 product : products) {
            assortmentDetailsList.add(new Assortment_Detail__c (Product__c = product.Id,
                                                                Assortment_BU__c = assortment.Id,
                                                                Movement_Date__c = date.today().addDays(10),
                                                                Client_Clust6__c = true,
                                                                Client_Clust5__c = true,
                                                                Client_Status__c = 'Keep'));
        }
        insert assortmentDetailsList;
        sfPlanningList = new List<Assortment_SF_Planning__c>();
        for (Assortment_Detail__c detail : assortmentDetailsList) {
            sfPlanningList.add(createSFPlanningRecord(detail, clusters[5], false));
            sfPlanningList.add(createSFPlanningRecord(detail, clusters[4], true));
        }
        insert sfPlanningList;
    }
    
    /**
     * @description code doesn't change, only extraction status changes to extract
	*/
    static testmethod void CASE1() {
        init();
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = 'D' AND IsLast__c = TRUE]);
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = 'A' AND IsLast__c = TRUE]);
        for (Assortment_SF_Planning__c item : sfPlanningList)
            item.Extraction_status__c = 'Extracted';
        update sfPlanningList;
        Test.startTest();
        Database.executeBatch(new UpdateAssortmentSFPlanningBatch('UpdateAssortmentSFPlanningBatchTest', null));
        Test.stopTest();
        System.assertEquals(assortmentDetailsList.size() * 2, [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c IN ('D', 'A') AND IsLast__c = TRUE AND Extraction_status__c = 'Extract']);
        System.assertEquals(0, [SELECT count() FROM Assortment_SF_Planning__c WHERE IsLast__c = FALSE]);
    }
    
    /**
     * @description code changes from D to S OR from A to N
	*/
    static testmethod void CASE2() {
        init();
        for (Assortment_SF_Planning__c item : sfPlanningList) {
            item.Movement_Date__c = Date.today().addDays(-25);
            item.Extraction_status__c = 'Extracted';
        }
        update sfPlanningList;
        Test.startTest();
        Database.executeBatch(new UpdateAssortmentSFPlanningBatch('UpdateAssortmentSFPlanningBatchTest', null));
        Test.stopTest();
        System.assertEquals(0, [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c IN ('D', 'A') AND IsLast__c = TRUE]);
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = 'S' AND IsLast__c = TRUE AND Extraction_status__c = 'Extract']);
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = 'N' AND IsLast__c = TRUE AND Extraction_status__c = 'Extract']);
    }
    
    /**
     * @description code changes from D to NULL OR from A to O
	*/
    static testmethod void CASE3() {
        init();
        for (Assortment_SF_Planning__c item : sfPlanningList) {
            item.Movement_Date__c = Date.today().addDays(-60);
            item.Extraction_status__c = 'Extracted';
        }
        update sfPlanningList;
        Test.startTest();
        Database.executeBatch(new UpdateAssortmentSFPlanningBatch('UpdateAssortmentSFPlanningBatchTest', null));
        Test.stopTest();
        System.assertEquals(0, [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c IN ('D', 'A') AND IsLast__c = TRUE]);
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = NULL AND IsLast__c = TRUE AND Extraction_status__c = 'Extract']);
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = 'O' AND IsLast__c = TRUE AND Extraction_status__c = 'Extract']);
    }
    
    /**
     * description pass date as parameter in batch constructor
     * code changes from D to S OR from A to N
	*/
    static testmethod void CASE4() {
        init();
        Test.startTest();
        Database.executeBatch(new UpdateAssortmentSFPlanningBatch('UpdateAssortmentSFPlanningBatchTest', Date.today().addDays(60)));
        Test.stopTest();
        System.assertEquals(0, [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c IN ('D', 'A') AND IsLast__c = TRUE]);
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = 'S' AND IsLast__c = TRUE AND Extraction_status__c = 'Extract']);
        System.assertEquals(assortmentDetailsList.size(), [SELECT count() FROM Assortment_SF_Planning__c WHERE SF_Code__c = 'N' AND IsLast__c = TRUE AND Extraction_status__c = 'Extract']);
    }
    
    /**
     * @description create SF_Planning records
	*/
    static Assortment_SF_Planning__c createSFPlanningRecord(Assortment_Detail__c asd, Orga_BU__c cluster, Boolean isDecrease) {
        String externalId  = cluster.Country_Origin__r.BU_Code__c + '-' + cluster.BU_Code__c + '-' + asd.Product_Code__c + '-' + asd.Product_EAN__c + '-' + Date.today().format();
        String code;
        if (isDecrease) {
            if (Date.today() < asd.Movement_Date__c)
                code = 'D';
            else if (Date.today() >= asd.Movement_Date__c && Date.today() < asd.Movement_Date__c.addDays(60))
                code = 'S';
            else if (Date.today() >= asd.Movement_Date__c.addDays(60))
                code = null;
        } else {
            if (Date.today() < asd.Movement_Date__c)
                code = 'A';
            else if (Date.today() >= asd.Movement_Date__c && Date.today() < asd.Movement_Date__c.addDays(60))
                code = 'N';
            else if (Date.today() >= asd.Movement_Date__c.addDays(60))
                code = 'O';
        }
        return new Assortment_SF_Planning__c(Assortment_BU_Detail__c = asd.Id,
                                             Assortment_BU__c = asd.Assortment_BU__c,
                                             product__c = asd.Product__c,
                                             SF_Code__c = code,
                                             Movement_Date__c = asd.Movement_Date__c,
                                             Record_Date__c = asd.Record_date__c,
                                             Release_Date__c = asd.Release_Date__c,
                                             Generation_Date__c = Date.today(),
                                             Ext_Id__c = externalId,
                                             Business_Unit__c = cluster.Id,
                                             Planning_status__c = 'Demand sent',
                                             Extraction_status__c = 'Extract',
                                             Type__c = 'Regular',
                                             IsLast__c = true);
    }
    
}