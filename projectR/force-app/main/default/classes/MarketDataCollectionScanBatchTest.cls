@isTest
private class MarketDataCollectionScanBatchTest {

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
            region = TestDataFactory.createBURegion(true, 'MEA');
            // Create Country.
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Supplier.
            client = TestDataFactory.createSupplier(true, country, true);
            // Create NS.
            NS = TestDataFactory.getNSs(client.Id)[0];
            // Create Department
            department = TestDataFactory.createDepartment(false, rootId);
            insert department;
            // Create category        
            category = TestDataFactory.createSection(false, department.Id);
            category.Status__c = 'Active';
            insert category;
            // Create brand
            brand = TestDataFactory.createBrand(false, client.Id);
            insert brand;
            // insert product
            product = TestDataFactory.createProduct(false, category.Id, client.Id);
            product.Product_EAN__c ='12345';
            product.IsActive = true;
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
            buList.Format_Origin__c = 'Supermarket;Drive';
            buList.Related_Client__c = client.Id;
            insert buList;
            // Create BU Banner
            buBanner1 = TestDataFactory.createBUBanner(false, country);
            buBanner1.Mission__c = 'Offer';
            buBanner1.Format_Origin__c = 'Supermarket;Drive';
            buBanner2 = TestDataFactory.createBUBanner(false, country);
            buBanner2.Mission__c = 'Offer';
            buBanner2.Format_Origin__c = 'Supermarket;Drive';
            insert new List<Orga_BU__c>{buBanner1,buBanner2};
            // Create Tax
            Map<String, Id> taxRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_Taxes__c.SObjectType);
            Orga_Taxes__c tax = new Orga_Taxes__c(Orga_BU_Source__c = masterBU.Id, Orga_HE__c = department.Id, Status__c = 'Open', Tax_percent__c = 5);
            tax.RecordTypeId = taxRTIds.get('VAT');
            insert tax;
            // Create Calendar_Canvas__c
            calendarConvas = new Calendar_Canvas__c(BU_Source__c = masterBU.Id, BU_Target__c = null, Year__c = year, Starting_day__c = null,
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
    
    // Check Mandatory fields
    @isTest static void caseMandatoryFields_Success() {
        init();
        Market_Data_Collection_Head__c markethead = new Market_Data_Collection_Head__c(Status__c = 'New', Ext_BU_Name__c = buList.Name);
        insert markethead;
        Market_Data_Collection_Detail__c marketDetail = new Market_Data_Collection_Detail__c(Market_Data_Collection_Head__c = marketHead.Id, Status__c = 'New', Ext_BU_Name__c = buList.Name);
        insert marketDetail;
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionHeadScanBatch('MarketDataCollectionScanBatchTest', new List<Id>{markethead.Id}, null));
        Database.executeBatch(new MarketDataCollectionDetailScanBatch('MarketDataCollectionScanBatchTest', new List<Id>{markethead.Id}, null));
        Test.stopTest();
        markethead = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :markethead.Id];
        marketDetail = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];
        System.assertEquals('Scan w/ error', markethead.Status__c);
        System.assertEquals('Scan w/ error', marketDetail.Status__c);
    }
    
    // Check scan Market Head with monthly details
    @isTest static void caseScanMonthlyMarketDataCollection_Success() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, category, client);
        marketHead.SEQ__c = 2;
        marketHead.Movement_Date__c = Date.newInstance(year, 1, 27);
        marketHead.Orga_BU__c = null;
        marketHead.Orga_HE__c = null;
        marketHead.Client__c = null;
        marketHead.Status__c = 'New';
        insert markethead;
        
        List<Orga_BU_List_Detail__c> buListDetails = [SELECT Id, Nielsen_Split__c FROM Orga_BU_List_Detail__c WHERE Entity_List__c = :buBanner1.Id];
        if(!buListDetails.isEmpty()) {
            for(Orga_BU_List_Detail__c item : buListDetails) {
                item.Nielsen_Split__c = 10;
            }
            update buListDetails;
        }
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetail = TestDataFactory.createMarketDataCollectionDetail(false, markethead.Id, buList, category, product, brand);
        marketDetail.SEQ__c = 2;
        marketDetail.Year__c = year;
        marketDetail.Orga_BU__c = null;
        marketDetail.Orga_HE__c = null;
        marketDetail.Product__c = null;
        marketDetail.SellOut_wTax_SEQ__c = 5;
        marketDetail.SellOut_Quantity_SEQ__c = 5;
        marketDetail.SellOut_Tone_SEQ__c = 5;
        marketDetail.SellOut_woTax_SEQ__c = 5;
        marketDetail.Status__c = 'New';
        insert marketDetail;
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionHeadScanBatch('MarketDataCollectionScanBatchTest', new List<Id>{markethead.Id}, null));
        Test.stopTest();
        markethead = [SELECT Id, Name, Master_BU__c, Orga_BU__c, Ext_Client_Name__c, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :markethead.Id];
        marketDetail = [SELECT Id, Name, Orga_BU__c, SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, Status__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];
        System.assertEquals('Scan w/ success', markethead.Status__c);
        System.assertEquals('Scan w/ success', marketDetail.Status__c);
        System.assertEquals(buList.Id, marketHead.Orga_BU__c);
        System.assertEquals(masterBU.Id, marketHead.Master_BU__c);
        System.assertEquals(marketDetail.Orga_BU__c, buBanner1.Id);
        System.assertEquals(5 * 0.1 * 27/28, marketDetail.SellOut_wTax_SEQ__c);
        System.assertEquals(4, [SELECT COUNT() FROM Market_Data_Collection_Detail__c]);
    }
    
    // Check scan Market Head with weekly details
    @isTest static void caseScanWeeklyMarketDataCollection_Success() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, category, client);
        marketHead.SEQ__c = 2;
        marketHead.Movement_Date__c = Date.newInstance(year, 2, 27);
        marketHead.Orga_BU__c = null;
        marketHead.Orga_HE__c = null;
        marketHead.Client__c = null;
        marketHead.SEQ__c = 2;
        marketHead.Status__c = 'New';
        insert markethead;
        List<Orga_BU_List_Detail__c> buListDetails = [SELECT Id, Nielsen_Split__c FROM Orga_BU_List_Detail__c WHERE Entity_List__c = :buBanner1.Id];
        if(!buListDetails.isEmpty()) {
            for(Orga_BU_List_Detail__c item : buListDetails) {
                item.Nielsen_Split__c = 10;
            }
            update buListDetails;
        }
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetailWeek = new Market_Data_Collection_Detail__c(Market_Data_Collection_Head__c = marketHead.Id, Ext_BU_Name__c = buList.Name,
                                                                                                 Ext_Category_Name__c = category.Name, Ext_Product_EAN__c = product.Product_EAN__c,
                                                                                                 Ext_Product_Name__c = product.Name, Ext_Brand_Name__c = brand.Name, Ext_Packaging__c = 'CONDITIONNEMENT',
                                                                                                 Date_SSEQ0__c = Date.valueOf(year + '-02-03'), Weight_SSEQ0__c = 3, SellOut_Quantity_SSEQ0__c = 80, SellOut_Tone_SSEQ0__c = 80,
                                                                                                 SellOut_wTax_SSEQ0__c = 80, ND_1_SSEQ0__c = 80, ND_2_SSEQ0__c = 80, WD_1_SSEQ0__c = 80, WD_2_SSEQ0__c = 80,
                                                                                                 
                                                                                                 Date_SSEQ1__c = Date.valueOf(year + '-02-10'), Weight_SSEQ1__c = 7, SellOut_Quantity_SSEQ1__c = 81, SellOut_Tone_SSEQ1__c = 81,
                                                                                                 SellOut_wTax_SSEQ1__c = 81, ND_1_SSEQ1__c = 81, ND_2_SSEQ1__c = 81, WD_1_SSEQ1__c = 81, WD_2_SSEQ1__c = 81,
                                                                                                 
                                                                                                 Date_SSEQ2__c = Date.valueOf(year + '-02-17'), Weight_SSEQ2__c = 7, SellOut_Quantity_SSEQ2__c = 82, SellOut_Tone_SSEQ2__c = 82,
                                                                                                 SellOut_wTax_SSEQ2__c = 82, ND_1_SSEQ2__c = 82, ND_2_SSEQ2__c = 82, WD_1_SSEQ2__c = 82, WD_2_SSEQ2__c = 82,
                                                                                                 
                                                                                                 Date_SSEQ3__c = Date.valueOf(year + '-02-24'), Weight_SSEQ3__c = 7, SellOut_Quantity_SSEQ3__c = 83, SellOut_Tone_SSEQ3__c = 83,
                                                                                                 SellOut_wTax_SSEQ3__c = 83, ND_1_SSEQ3__c = 83, ND_2_SSEQ3__c = 83, WD_1_SSEQ3__c = 83, WD_2_SSEQ3__c = 83,
                                                                                                 Status__c = 'New', Sequence_Type__c = 'Week', Sequence_Number__c = 8, SEQ__c = 2, Year__c = year);
        insert marketDetailWeek;
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionHeadScanBatch('MarketDataCollectionScanBatchTest', new List<Id>{markethead.Id}, null));
        Test.stopTest();
        marketDetailWeek = [SELECT Id, Orga_BU__c, SellOut_Quantity_SSEQ0__c, SellOut_Tone_SSEQ0__c, SellOut_wTax_SSEQ0__c,
                            SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, ND_1_SSEQ3__c, Status__c
                            FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetailWeek.Id];
        Market_Data_Collection_Detail__c marketDetailMonthly = [SELECT Id, Weight_SSEQ0__c, Weight_SSEQ1__c, SellOut_Quantity_SEQ__c, ND_1_SEQ__c, WD_1_SEQ__c, ND_2_SEQ__c, WD_2_SEQ__c,
                                                                Orga_BU__c, SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, Status__c
                                                                FROM Market_Data_Collection_Detail__c WHERE Sequence_Type__c = 'Month' AND SEQ__c = 2 AND Orga_BU__c = :buBanner1.Id];
        markethead = [SELECT Id, Name, Orga_BU__c, Ext_Client_Name__c, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :markethead.Id];
        
        System.assertEquals('Scan w/ success', markethead.Status__c);
        System.assertEquals('Scan w/ success', marketDetailWeek.Status__c);
        System.assertEquals('Scan w/ success', marketDetailMonthly.Status__c);
        System.assertEquals(buList.Id, marketHead.Orga_BU__c);
        System.assertEquals(buBanner1.Id, marketDetailMonthly.Orga_BU__c);
        Decimal calendarCanvasWeight2 = calendarConvas.Weight_SEQ5__c + calendarConvas.Weight_SEQ6__c + calendarConvas.Weight_SEQ7__c; // = 5
        System.assertEquals(80*10/100, marketDetailWeek.SellOut_Quantity_SSEQ0__c);
        System.assertEquals(80*10/100, marketDetailWeek.SellOut_Tone_SSEQ0__c);
        System.assertEquals(80*10/100, marketDetailWeek.SellOut_wTax_SSEQ0__c);
        System.assertEquals(7*calendarCanvasWeight2/100, marketDetailMonthly.Weight_SSEQ0__c);
        System.assertEquals((((((7*calendarCanvasWeight2/100)*(80*10/100))/7) + 8.1 + 8.2 + 8.3) * 27/28).setScale(2), marketDetailMonthly.SellOut_Quantity_SEQ__c.setScale(2));
        System.assertEquals(marketDetailWeek.ND_1_SSEQ3__c, marketDetailMonthly.ND_1_SEQ__c);
        System.assertEquals((81.97 * 27/28).setScale(2), marketDetailMonthly.ND_2_SEQ__c.setScale(2));
        System.assertEquals((81.97 * 27/28).setScale(2), marketDetailMonthly.WD_2_SEQ__c.setScale(2));
        System.assertEquals(((0.35*8/7+8.1+8.2+8.3) * 27/28).setScale(2), marketDetailMonthly.SellOut_wTax_SEQ__c.setScale(2));
        System.assertEquals((23.75 * 27/28).setScale(2), marketDetailMonthly.SellOut_woTax_SEQ__c.setScale(2));
        System.assertEquals(2, [SELECT COUNT() FROM Market_Data_Collection_Head__c]);
        System.assertEquals(4, [SELECT COUNT() FROM Market_Data_Collection_Detail__c WHERE Sequence_Type__c = 'Month']);
    }
    
    // Check scan Market Head with weekly details
    @isTest static void caseScanWeeklyMarketDataCollection_Error() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, category, client);
        marketHead.SEQ__c = 2;
        marketHead.Movement_Date__c = Date.newInstance(year, 1, 27);
        marketHead.Orga_BU__c = null;
        marketHead.Orga_HE__c = null;
        marketHead.Client__c = null;
        marketHead.Status__c = 'New';
        marketHead.SEQ__c = 2;
        insert markethead;
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetailWeek = new Market_Data_Collection_Detail__c(Market_Data_Collection_Head__c = marketHead.Id, Ext_BU_Name__c = buList.Name,
                                                                                                 Ext_Category_Name__c = category.Name, Ext_Product_EAN__c = '12210',
                                                                                                 Ext_Product_Name__c = product.Name, Ext_Brand_Name__c = brand.Name, Ext_Packaging__c = 'CONDITIONNEMENT',
                                                                                                 Date_SSEQ0__c = Date.valueOf(year + '-02-03'), Weight_SSEQ0__c = 3, SellOut_Quantity_SSEQ0__c = 80, SellOut_Tone_SSEQ0__c = 80,
                                                                                                 SellOut_wTax_SSEQ0__c = 80, ND_1_SSEQ0__c = 80, ND_2_SSEQ0__c = 80, WD_1_SSEQ0__c = 80, WD_2_SSEQ0__c = 80,
                                                                                                 
                                                                                                 Date_SSEQ1__c = Date.valueOf(year + '-02-10'), Weight_SSEQ1__c = 7, SellOut_Quantity_SSEQ1__c = 81, SellOut_Tone_SSEQ1__c = 81,
                                                                                                 SellOut_wTax_SSEQ1__c = 81, ND_1_SSEQ1__c = 81, ND_2_SSEQ1__c = 81, WD_1_SSEQ1__c = 81, WD_2_SSEQ1__c = 81,
                                                                                                 
                                                                                                 Date_SSEQ2__c = Date.valueOf(year + '-02-17'), Weight_SSEQ2__c = 7, SellOut_Quantity_SSEQ2__c = 82, SellOut_Tone_SSEQ2__c = 82,
                                                                                                 SellOut_wTax_SSEQ2__c = 82, ND_1_SSEQ2__c = 82, ND_2_SSEQ2__c = 82, WD_1_SSEQ2__c = 82, WD_2_SSEQ2__c = 82,
                                                                                                 
                                                                                                 Date_SSEQ3__c = Date.valueOf(year + '-02-24'), Weight_SSEQ3__c = 7, SellOut_Quantity_SSEQ3__c = 83, SellOut_Tone_SSEQ3__c = 83,
                                                                                                 SellOut_wTax_SSEQ3__c = 83, ND_1_SSEQ3__c = 83, ND_2_SSEQ3__c = 83, WD_1_SSEQ3__c = 83, WD_2_SSEQ3__c = 83,
                                                                                                 Status__c = 'New', Sequence_Type__c = 'Week', Sequence_Number__c = 8, SEQ__c = 2, Year__c = year);
        insert marketDetailWeek;
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionHeadScanBatch('MarketDataCollectionScanBatchTest', new List<Id>{markethead.Id}, null));
        Test.stopTest();
        marketDetailWeek = [SELECT Id, Orga_BU__c, SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, ND_1_SSEQ3__c, Status__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetailWeek.Id];
        markethead = [SELECT Id, Name, Orga_BU__c, Ext_Client_Name__c, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :markethead.Id];
        System.assertEquals('Scan w/ success', markethead.Status__c);
        System.assertEquals('Scan w/ error', marketDetailWeek.Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM Market_Data_Collection_Detail__c WHERE Market_Data_Collection_Head__c = :markethead.Id]);
    }
    
    // Check scan Market Head and details
    @isTest static void caseScanMarketDataCollection_Fails() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, category, client);
        marketHead.Ext_BU_Name__c = 'NA';
        marketHead.Orga_BU__c = null;
        marketHead.Status__c = 'New';
        insert markethead;        
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetail = TestDataFactory.createMarketDataCollectionDetail(false, markethead.Id, buList, category, product, brand);
        marketDetail.Orga_BU__c = null;
        marketDetail.Product__c = null;
        marketDetail.Status__c = 'New';
        marketDetail.Ext_BU_Name__c = 'NA';
        marketDetail.Ext_Product_EAN__c = 'NA';
        insert marketDetail;
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionHeadScanBatch('MarketDataCollectionScanBatchTest', new List<Id>{markethead.Id}, null));
        Database.executeBatch(new MarketDataCollectionDetailScanBatch('MarketDataCollectionScanBatchTest', new List<Id>{markethead.Id}, null));
        Test.stopTest();
        markethead = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :markethead.Id];
        marketDetail = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];
        System.assertEquals('Scan w/ error', markethead.Status__c);
        System.assertEquals('Scan w/ error', marketDetail.Status__c);
    }
}