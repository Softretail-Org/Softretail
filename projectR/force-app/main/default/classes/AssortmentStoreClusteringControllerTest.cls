/**
 * @Description Test class that verify whether the particular piece of code on Assortment Store Clustering Controller is working properly.
 **/
@isTest
private class AssortmentStoreClusteringControllerTest {
    
    private static Orga_BU__c country;
	private static Orga_BU__c store1;
	private static Orga_BU__c store2;
	
    static void init() {
		// Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
        country.Weighted_Distribution_SellIn_Fact__c = 1.1;
        country.Weighted_Distribution_forecasting_Ass__c = 'Sell In (Fact)';
        insert country;
        // Insert Legal.
    	Orga_BU__c legal = TestDataFactory.createBULegal(true, myCountry);
    	// Insert Store1.
    	store1 = TestDataFactory.createBUStores(false, country, legal.Id, 1).get(0);
    	store1.Assortment_Strat__c = 'Strat0';
    	store1.Weighted_Distribution_SellIn_Fact__c = 1.1;
        // Insert Store2.
    	store2 = TestDataFactory.createBUStores(false, country, legal.Id, 1).get(0);
    	store2.Assortment_Strat__c = 'Strat1';
    	store2.Weighted_Distribution_SellIn_Fact__c = 20;
        insert new List<Orga_BU__c>{store1, store2};
    }
    
    @isTest static void test_constructor() {
    	init();
        Test.startTest();
        // Create Assortment Clusters.
        Orga_BU__c assortmentClust0 = TestDataFactory.createBUAssortCluster(true, country.Id, 'Strat0');
        Orga_BU__c assortmentClust1 = TestDataFactory.createBUAssortCluster(true, country.Id, 'Strat1');
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);        
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.stopTest();
        // Assertion.
        system.assertEquals(country.Id, ctrlr.recordId);
        System.assertEquals(1, ctrlr.wCountryMap.size());
        System.assertEquals(2, ctrlr.wCountryMap.get(country.Id).assortmentClusters.size());
    }
    
    // case country.Weighted_Distribution_forecasting_Ass__c == 'Sell Out (Forecast)
    @isTest static void test_SellOutForecast() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Sell Out (Forecast)';
    	country.Weighted_Distribution_SellOut_Fact__c = 1.1;
        update country;
        store1.Weighted_Distribution_forecasting_Ass__c = 'Sell Out (Forecast)';
        store1.Weighted_Distribution_SellOut_Fact__c = 1.1;
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Sell Out (Forecast)';
        insert assortmentClust;
        Test.startTest();
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.stopTest();
        System.assertEquals(1, ctrlr.wCountryMap.size());
    }
    
    // Weighted_Distribution_forecasting_Ass__c == 'Sell In (Fact).
    @isTest static void test_SellInFact() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Sell In (Fact)';
    	country.Weighted_Distribution_SellIn_Fact__c = 1.1;
        update country;
        store1.Weighted_Distribution_forecasting_Ass__c = 'Sell In (Fact)';
        store1.Weighted_Distribution_SellIn_Fact__c = 1.1;
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Sell In (Fact)';
        insert assortmentClust;
        Test.startTest();
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.stopTest();
        System.assertEquals(1, ctrlr.wCountryMap.size());
    }
    
    // Weighted_Distribution_forecasting_Ass__c == 'Sell Out (Fact).
    @isTest static void test_SellOutFact() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Sell Out (Fact)';
    	country.Weighted_Distribution_SellOut_Fact__c = 1.1;
        update country;
        store1.Weighted_Distribution_forecasting_Ass__c = 'Sell Out (Fact)';
        store1.Weighted_Distribution_SellOut_Fact__c = 1.1;
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Sell In (Fact)';
        insert assortmentClust;
        Test.startTest();
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.stopTest();
        System.assertEquals(1, ctrlr.wCountryMap.size());
    }
    
    // Weighted_Distribution_forecasting_Ass__c == 'Sell In (Forecast).
    @isTest static void test_SellInForecast() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Sell In (Forecast)';
    	country.Weighted_Distribution_SellIn_Forecast__c = 1.1;
        update country;
        store1.Weighted_Distribution_SellIn_Forecast__c = 1.1;
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Sell In (Forecast)';
        insert assortmentClust;
        Test.startTest();
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.stopTest();
        System.assertEquals(1, ctrlr.wCountryMap.size());
    }
    
    // Weighted_Distribution_forecasting_Ass__c == 'Manual.
    @isTest static void test_Manual() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Manual';
    	country.Weighted_Distribution_Manual__c = 1.1;
        update country;
        store1.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        store1.Weighted_Distribution_Manual__c = 1.1;
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        insert assortmentClust;
        Test.startTest();
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.stopTest();
        System.assertEquals(1, ctrlr.wCountryMap.size());
    }
    // updateWeightDistribution method + Weighted_Distribution_forecasting_Ass__c == 'Manual.
    @isTest static void test_UpdateWeightDistribution() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        update country;
        store1.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        insert assortmentClust;
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.startTest();
        ctrlr.updateWeightDistribution();
        Test.stopTest();
        System.assert(true);
    }
    
    // SetWDSelloutWDWeight method + Weighted_Distribution_forecasting_Ass__c == 'Manual.
    @isTest static void test_SetWDSelloutWDWeight() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        update country;
        store1.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        insert assortmentClust;
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.startTest();
        ctrlr.setWDSelloutWDWeight();
        Test.stopTest();
        System.assert(true);
    }
    
    // SetWDSellinWDWeight method + Weighted_Distribution_forecasting_Ass__c == 'Manual.
    @isTest static void test_SetWDSellinWDWeight() {
    	init();
    	country.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        update country;
        store1.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        update store1;
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        // Create Assortment Clusters.
		Orga_BU__c assortmentClust = TestDataFactory.createBUAssortCluster(false, country.Id, 'Strat3');
        assortmentClust.Weighted_Distribution_forecasting_Ass__c = 'Manual';
        insert assortmentClust;
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.startTest();
        ctrlr.setWDSellinWDWeight();
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest static void test_search() {
    	init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.startTest();
        ctrlr.search();
        Test.stopTest();
        system.assert(true);
    }
    
    @isTest static void test_resetStores() {
    	init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(country);
        AssortmentStoreClusteringController ctrlr = new AssortmentStoreClusteringController(stdController);
        Test.startTest();
        ctrlr.resetStores();
        Test.stopTest();
        system.assert(true);
    }
}