@isTest
private class MarketDataCollectionConsolidationTest {

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
    private static Sup_Supplier__c client;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c department;
    private static Orga_HE__c category;
    private static Sup_Brand__c brand;
    private static Product2 product;
    private static Calendar_Canvas__c calendarConvas;
    
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
            department = TestDataFactory.createDepartment(false, rootId);
            insert department;
            // Create category        
            category = TestDataFactory.createSection(false, department.Id);
            insert category;
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
            insert masterBU;
            // Create BU List
            buList = TestDataFactory.createBUList(false, country.Id);
            buList.Mission__c = 'Nielsen;Offer';
            buList.Format_Origin__c = 'Hypermarket';
            buList.Related_Client__c = client.Id;
            insert buList;
            // Create BU Banner
            buBanner1 = TestDataFactory.createBUBanner(false, country);
            buBanner1.Mission__c = 'Offer';
            buBanner1.Format_Origin__c = 'Hypermarket';
            buBanner2 = TestDataFactory.createBUBanner(false, country);
            buBanner2.Mission__c = 'Offer';
            buBanner2.Format_Origin__c = 'Hypermarket';
            insert new List<Orga_BU__c>{buBanner1,buBanner2};
            // Create Calendar_Canvas__c
            calendarConvas = new Calendar_Canvas__c(BU_Source__c = masterBU.Id, BU_Target__c = buList.Id, Year__c = year, Starting_day__c = null,
                                                    First_day_of_the_year__c = Date.newInstance(year, 1, 1), Last_day_of_the_year__c = Date.newInstance(year, 12, 31),
                                                    Weight_SEQ1__c = 90, Weight_SEQ2__c = 5, Weight_SEQ3__c = 0, Weight_SEQ4__c = 0, Weight_SEQ5__c = 0,
                                                    Weight_SEQ6__c = 0, Weight_SEQ7__c = 5, Status__c = 'Open', Calendar_type__c = 'Regular');
            insert calendarConvas;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // Generate Market Data Collection Detail
    @isTest static void case1_GenerateMonthlyByWeeklySuccess() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, category, client);
        marketHead.Movement_Date__c = Date.newInstance(year, 2, 27);
        marketHead.Status__c = 'Scan w/ success';
        marketHead.SEQ__c = 2;
        insert markethead;
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetailWeek = new Market_Data_Collection_Detail__c(Market_Data_Collection_Head__c = marketHead.Id, Ext_BU_Name__c = buBanner1.Name, Orga_BU__c = buBanner1.Id,
                                                                                                 Ext_Category_Name__c = category.Name, Orga_HE__c = category.Id,
                                                                                                 Ext_Product_EAN__c = product.Product_EAN__c, Product__c = product.Id,
                                                                                                 Ext_Brand_Name__c = brand.Name, Ext_Packaging__c = 'CONDITIONNEMENT',
                                                                                                 Date_SSEQ0__c = Date.valueOf(year + '-02-03'), Weight_SSEQ0__c = 3, SellOut_Quantity_SSEQ0__c = 80, SellOut_Tone_SSEQ0__c = 80,
                                                                                                 SellOut_wTax_SSEQ0__c = 80, ND_1_SSEQ0__c = 80, ND_2_SSEQ0__c = 80, WD_1_SSEQ0__c = 80, WD_2_SSEQ0__c = 80,
                                                                                                 
                                                                                                 Date_SSEQ1__c = Date.valueOf(year + '-02-10'), Weight_SSEQ1__c = 7, SellOut_Quantity_SSEQ1__c = 81, SellOut_Tone_SSEQ1__c = 81,
                                                                                                 SellOut_wTax_SSEQ1__c = 81, ND_1_SSEQ1__c = 81, ND_2_SSEQ1__c = 81, WD_1_SSEQ1__c = 81, WD_2_SSEQ1__c = 81,
                                                                                                 
                                                                                                 Date_SSEQ2__c = Date.valueOf(year + '-02-17'), Weight_SSEQ2__c = 7, SellOut_Quantity_SSEQ2__c = 82, SellOut_Tone_SSEQ2__c = 82,
                                                                                                 SellOut_wTax_SSEQ2__c = 82, ND_1_SSEQ2__c = 82, ND_2_SSEQ2__c = 82, WD_1_SSEQ2__c = 82, WD_2_SSEQ2__c = 82,
                                                                                                 
                                                                                                 Date_SSEQ3__c = Date.valueOf(year + '-02-24'), Weight_SSEQ3__c = 7, SellOut_Quantity_SSEQ3__c = 83, SellOut_Tone_SSEQ3__c = 83,
                                                                                                 SellOut_wTax_SSEQ3__c = 83, ND_1_SSEQ3__c = 83, ND_2_SSEQ3__c = 83, WD_1_SSEQ3__c = 83, WD_2_SSEQ3__c = 83,
                                                                                                 Status__c = 'Scan w/ success', Sequence_Type__c = 'Week', Sequence_Number__c = 8, SEQ__c = 2, Year__c = year);
        insert marketDetailWeek;
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionConsolidationBatch('MarketDataCollectionConsolidationBatch', new Set<Id>{marketDetailWeek.Id}));
        Test.stopTest();
        // Validation Test
        Market_Data_Collection_Detail__c marketDetailMonthly = [SELECT Id, Weight_SSEQ0__c, Weight_SSEQ1__c, SellOut_Quantity_SEQ__c, ND_1_SEQ__c, WD_1_SEQ__c, ND_2_SEQ__c, WD_2_SEQ__c
                                                                FROM Market_Data_Collection_Detail__c WHERE Sequence_Type__c = 'Month' AND SEQ__c = 2];
        Decimal calendarCanvasWeight2 = calendarConvas.Weight_SEQ5__c + calendarConvas.Weight_SEQ6__c + calendarConvas.Weight_SEQ7__c;
        System.assertEquals(0.35, marketDetailMonthly.Weight_SSEQ0__c);
        System.assertEquals(((calendarCanvasWeight2/100*80+81+82+83)* 27/28).setScale(2), marketDetailMonthly.SellOut_Quantity_SEQ__c.setScale(2));
        System.assertEquals(marketDetailWeek.ND_1_SSEQ3__c, marketDetailMonthly.ND_1_SEQ__c);
        System.assertEquals((81.97 * 27/28).setScale(2), marketDetailMonthly.ND_2_SEQ__c.setScale(2));
        System.assertEquals((81.97* 27/28).setScale(2), marketDetailMonthly.WD_2_SEQ__c.setScale(2));
        System.assertEquals(2, [SELECT COUNT() FROM Market_Data_Collection_Head__c]);
        System.assertEquals(2, [SELECT COUNT() FROM Market_Data_Collection_Detail__c WHERE Sequence_Type__c = 'Month']);
    }
    
    // Generate Market Data Collection Detail
    @isTest static void case1_GenerateMonthlyByMonthlySuccess() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, category, client);
        marketHead.Movement_Date__c = Date.newInstance(year, 2, 27);
        marketHead.Status__c = 'Scan w/ success';
        marketHead.SEQ__c = 2;
        insert markethead;
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetail = new Market_Data_Collection_Detail__c(Market_Data_Collection_Head__c = marketHead.Id, Ext_BU_Name__c = buBanner1.Name, Orga_BU__c = buBanner1.Id,
                                                                                                 Ext_Category_Name__c = category.Name, Orga_HE__c = category.Id,
                                                                                                 Ext_Product_EAN__c = product.Product_EAN__c, Product__c = product.Id,
                                                                                                 Ext_Brand_Name__c = brand.Name, Ext_Packaging__c = 'CONDITIONNEMENT',
                                                                                                 //SEQ
                                                                                                 SellOut_Quantity_SEQ__c = 100, SellOut_wTax_SEQ__c = 50, ND_1_SEQ__c = 0, WD_1_SEQ__c = 0, ND_2_SEQ__c = 0, WD_2_SEQ__c = 0,
                                                                                                 Average_Retail_Price_SEQ__c = 0, Avg_Weekly_Sales_Ext_ClientBased__c = 0,
                                                                                                 //YTD
                                                                                                 SellOut_wTax_YTD__c = 0, ND_1_YTD__c = 0, WD_1_YTD__c = 0, ND_2_YTD__c = 0, WD_2_YTD__c = 0, Average_Retail_Price_YTD__c = 0,
                                                                                                 //12M
                                                                                                 SellOut_wTax_12M__c = 0, ND_1_12M__c = 0, WD_1_12M__c = 0, ND_2_12M__c = 0, WD_2_12M__c = 0, Average_Retail_Price_12M__c = 0,
                                                                                                 Status__c = 'Scan w/ success', Sequence_Type__c = 'Month', Sequence_Number__c = 8, SEQ__c = 2, Year__c = year);
        insert marketDetail;
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionConsolidationBatch('MarketDataCollectionConsolidationBatch', new Set<Id>{marketDetail.Id}));
        Test.stopTest();
        // Validation Test
        marketDetail = [SELECT Id, SellOut_Quantity_SEQ__c, SellOut_wTax_SEQ__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];        
        Market_Data_Collection_Detail__c marketDetail1 = [SELECT Id, SellOut_Quantity_SEQ__c, SellOut_wTax_SEQ__c FROM Market_Data_Collection_Detail__c WHERE Sequence_Type__c = 'Month' AND SEQ__c = 1];
        System.assertEquals(Decimal.valueOf(100 * 27)/28, marketDetail.SellOut_Quantity_SEQ__c);
        System.assertEquals(Decimal.valueOf(100 * 1)/28, marketDetail1.SellOut_Quantity_SEQ__c);
        System.assertEquals(2, [SELECT COUNT() FROM Market_Data_Collection_Head__c]);
        System.assertEquals(2, [SELECT COUNT() FROM Market_Data_Collection_Detail__c WHERE Sequence_Type__c = 'Month']);
    }
}