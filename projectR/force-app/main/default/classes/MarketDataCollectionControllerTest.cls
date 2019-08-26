/**
 * @author ULiT
 * @description Test class for MarketDataCollectionController
 * */
@isTest
private class MarketDataCollectionControllerTest {
    
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
    private static NegoptimCustomSettings__c negoCustomSettings;
    private static Calendar_Canvas__c calendarConvas;
    
    static void init() {
        try {
            year = System.Today().year();
            month = System.Today().month();
            // Create negoCustomSettings
            negoCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
            negoCustomSettings.csv_Date_Format__c = 'dd/MM/yy';
            insert negoCustomSettings;
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
        } catch (Exception ex) { }
    }
    
    // scan Market Head and details
    @isTest static void caseScanMarketDataCollection_Success() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, department, client);
        marketHead.SEQ__c = 2;
        marketHead.Movement_Date__c = Date.newInstance(year, 2, 27);
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
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Market_Data_Collection_Head__c>());
        stdSetController.setSelected(new List<Market_Data_Collection_Head__c>{marketHead});
        MarketDataCollectionController ctrlr = new MarketDataCollectionController(stdSetController);
        Test.startTest();
        ctrlr.scanMarketDataCollection();
        Test.stopTest();
        markethead = [SELECT Id, Name, Orga_BU__c, Ext_Client_Name__c, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :markethead.Id];
        marketDetail = [SELECT Id, Name, Orga_BU__c, Status__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];
        System.assertEquals('Scan w/ success', markethead.Status__c);
        System.assertEquals('Scan w/ success', marketDetail.Status__c);
        System.assertEquals(buList.Id, marketHead.Orga_BU__c);
        System.assertEquals(buBanner1.Id, marketDetail.Orga_BU__c);
        System.assertEquals(4, [SELECT COUNT() FROM Market_Data_Collection_Detail__c]);
    }
    
    // synchro Market Head and details
    @isTest static void caseSynchroMarketDataCollection_Success() {
        init();
        // insert Market_Data_Collection_Head__c
        Market_Data_Collection_Head__c marketHead = TestDataFactory.createMarketDataCollectionHead(false, masterBU.Id, buList, department, client);
        marketHead.Status__c = 'Scan w/ success';
        insert markethead;
        // insert Market_Data_Collection_Detail__c
        Market_Data_Collection_Detail__c marketDetail = TestDataFactory.createMarketDataCollectionDetail(false, markethead.Id, buBanner1, category, product, brand);
        marketDetail.Status__c = 'Scan w/ success';
        insert marketDetail;
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<Market_Data_Collection_Head__c>());
        stdSetController.setSelected(new List<Market_Data_Collection_Head__c>{marketHead});
        MarketDataCollectionController ctrlr = new MarketDataCollectionController(stdSetController);
        Test.startTest();
        ctrlr.synchroMarketDataCollection();
        Test.stopTest();
        // Validation Test
        marketHead = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Head__c WHERE Id = :marketHead.Id];
        marketDetail = [SELECT Id, Name, Status__c FROM Market_Data_Collection_Detail__c WHERE Id = :marketDetail.Id];
        System.assertEquals('Synchro w/ success', marketHead.Status__c);
        System.assertEquals('Synchro w/ success', marketDetail.Status__c);
    }    
}