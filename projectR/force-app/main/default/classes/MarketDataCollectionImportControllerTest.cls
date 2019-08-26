@isTest
private class MarketDataCollectionImportControllerTest {
    
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c masterBU;
    private static Id fileId;
    private static NegoptimCustomSettings__c negoCustomSettings;
    private static MarketDataCollectionImportController instance;
    
    static void init() {
        try {
            // Create negoCustomSettings
            negoCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
            negoCustomSettings.csv_Date_Format__c = 'dd/MM/yy';
            insert negoCustomSettings;
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region.
            region = TestDataFactory.createBURegion(true, 'MEA');
            // Create Country.
            masterBU = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            masterBU.IsMasterBU__c = true;
            insert masterBU;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void caseSaveFileAndImport_success() {
        init();
        String fileContents1 = ',,,,,,,,4 S 30/12/18,,,,,,,,,,,,CAD 18,,,,,,,,,,,,DERNIER CAM,,,,,,,,,, \n';
        fileContents1 += ',,SDESC,ITEM,MARQUES,CONDITIONNEMENT,STD/PROMO,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN,DV,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN,DV,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN,DV,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo \n';
        fileContents1 += 'CARREFOUR (INCL. DRIVE),,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, \n';
        fileContents1 += ',-0E50 POMME & FRAISE ITEM,CARREFOUR (INCL. DRIVE),1,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,0,0,CAD 18,0,0,0,0,0,0,0,0,0,0,0,DERNIER CAM,0,0,0,0,0,0,0,0,0,0,0\n';
        fileContents1 += ',* POM MAN PASS ITEM,CARREFOUR (INCL. DRIVE),2,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,0,0,CAD 18,21,5.5,16.9,0.43,1.43,0,0.43,0,0.43,0.6,0.8,DERNIER CAM,21,5.5,16.9,0.43,1.43,0,0.43,0,0.43,0.6,0.8\n';
        
        String fileDateBase64 = EncodingUtil.base64Encode(Blob.valueOf(fileContents1));
        // Test.
        Test.startTest();
        instance = new MarketDataCollectionImportController();
        MarketDataCollectionImportController.initClass();
        String filename = 'Nielsen_Compote_M112018_4S20132018.csv';
        fileId = MarketDataCollectionImportController.saveFile(filename, fileDateBase64, 1, '');
        
        // test append file
        String fileContents2 = ',* POMME ITEM,CARREFOUR (INCL. DRIVE),3,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,0,0,CAD 18,160,41.6,134.4,0.86,1.29,0.71,1,0.71,1,2.2,0.84,DERNIER CAM,160,41.6,134.4,0.86,1.29,0.71,1,0.71,1,2.2,0.84\n';
        fileDateBase64 = EncodingUtil.base64Encode(Blob.valueOf(fileContents2));
        MarketDataCollectionImportController.saveFile(filename, fileDateBase64, 2, fileId);
        
        // validate file name
        Map<String, Id> fileIdMap = new Map<String, Id>();
        fileIdMap.put('1', fileId);
        instance.isWeekly= false;
        instance.isMonthly = false;
        instance = MarketDataCollectionImportController.validateFileName(filename, instance);
        System.assertEquals('Compote', instance.categoryName);
        System.assertEquals(2018, instance.year);
        
        // test import
        instance = MarketDataCollectionImportController.import(filename, fileIdMap, instance);
        System.assertNotEquals(null, instance.processingMessage);
        
        List<ContentVersion> files = MarketDataCollectionImportController.getContentVersions(fileIdMap);
        String tabURL = MarketDataCollectionImportController.getMarketHeadTabURL();
        String objectType = MarketDataCollectionImportController.getObjectType();
        Test.stopTest();
        // Assertion.
        System.assertEquals(1, files.size());
    }
}