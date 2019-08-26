@isTest
private class MarketDataCollectionImportBatchTest {

    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static NegoptimCustomSettings__c negoCustomSettings;
    
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
            region = TestDataFactory.createBURegion(false, 'MEA');
            insert region;
            // Create Country.
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void case1_MonthlyImport_success() {
        init();
        String fileContents1 = ',,,,,,,,4 S 24/02/19,,,,,,,,,,CAD 18,,,,,,,,,,DERNIER CAM,,,,,,,, \n';
        fileContents1 += ',,SDESC,ITEM,MARQUES,CONDITIONNEMENT,STD/PROMO,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo \n';
        fileContents1 += 'CARREFOUR (INCL. DRIVE),,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, \n';
        fileContents1 += ',-0E50 POMME & FRAISE ITEM,CARREFOUR (INCL. DRIVE),3080920000000,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,CAD 18,0,0,0,0,0,0,0,0,0,DERNIER CAM,0,0,0,0,0,0,0,0,0 \n';
        fileContents1 += ',* POM MAN PASS ITEM,CARREFOUR (INCL. DRIVE),3080920000000,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,CAD 18,21,5.5,16.9,0.43,1.43,0,0.43,0.6,0.8,DERNIER CAM,21,5.5,16.9,0.43,1.43,0,0.43,0.6,0.8 \n';
        fileContents1 += ',* POMME ITEM,CARREFOUR (INCL. DRIVE),3080920000000,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,CAD 18,160,41.6,134.4,0.86,1.29,0.71,1,2.2,0.84,DERNIER CAM,160,41.6,134.4,0.86,1.29,0.71,1,2.2,0.84 \n';
        ContentVersion contentVersion1 = new ContentVersion(versionData = Blob.valueOf(fileContents1),
                                                           title = 'Nielsen_Compote_M112018_4S20132018_1.csv', pathOnClient = 'Nielsen_MCompote_P112018_4S20132018_1.csv', IsMajorVersion = false);
        
        String fileContents2 = ',* POM PECHE ITEM,CARREFOUR (INCL. DRIVE),3080920000000,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,1,1,2.5,0,0,0,0,2.1,2.5,CAD 18,5848,6081.8,14600.3,44.69,47.54,24.38,28.85,1.61,2.51,DERNIER CAM,5848,6081.8,14600.3,44.69,47.54,24.38,28.85,1.61,2.51 \n';
        fileContents2 += ',-0E50 POM MANGUE PASSION ITEM,CARREFOUR (INCL. DRIVE),3080920000000,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,2,2.1,5.2,1,1,0,0,1.55,2.7,CAD 18,6794,7065.3,16857.4,49.69,51.23,0.5,0.5,1.81,2.6,DERNIER CAM,6794,7065.3,16857.4,49.69,51.23,0.5,0.5,1.81,2.6 \n';
        fileContents2 += ',-0E50 POMME ITEM,CARREFOUR (INCL. DRIVE),3080920000000,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,4,4.2,9.8,0,6,0,7,0.1,2.45,CAD 18,5270,5481.1,12717.9,41.92,46,1,5,0.54,2.14,DERNIER CAM,5270,5481.1,12717.9,41.92,46,1,5,0.54,2.14 \n';
        ContentVersion contentVersion2 = new ContentVersion(versionData = Blob.valueOf(fileContents2),
                                                           title = 'Nielsen_Compote_M112018_4S20132018_2.csv', pathOnClient = 'Nielsen_MCompote_P112018_4S20132018_1.csv', IsMajorVersion = false);
        insert new List<ContentVersion>{contentVersion1, contentVersion2};
        Map<String, Id> fileIdMap = new Map<String, Id>();
        fileIdMap.put('1', contentVersion1.Id);
        fileIdMap.put('2', contentVersion2.Id);
        // Test.
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionImportBatch('MarketDataCollectionImportBatchTest', fileIdMap, 1, country.Id, 'Nielsen', 'Compote', false, true, 2018, 11, null, null), 1500);
        Test.stopTest();
        // Assertion.
        Integer marketHeadCount = [SELECT COUNT() FROM Market_Data_Collection_Head__c];
        Integer marketDetailsCount = [SELECT COUNT() FROM Market_Data_Collection_Detail__c];
        System.assertEquals(1, marketHeadCount);
        System.assertEquals(6, marketDetailsCount);
    }
    
    @isTest static void case2_WeeklyImport_success() {
        init();
        String fileContents1 = ',,,,,,,,S 03/02/19,,,,,,,,,,S 10/02/19,,,,,,,,,,S 17/02/19,,,,,,,,,,S 24/02/19,,,,,,,, \n';
        fileContents1 += ',,SDESC,ITEM,MARQUES,CONDITIONNEMENT,STD/PROMO,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo \n';
        fileContents1 += 'CARREFOUR (INCL. DRIVE),,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, \n';
        fileContents1 += ',AUTRE CONDITIONNEMENT ST MAMET AUTRES PRODUITS 4 STANDARD -0E50 POMME & FRAISE,CARREFOUR (INCL. DRIVE),3080920989064,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        fileContents1 += ',EP AUTRE CONDITIONNEMENT ST MAMET COMPOTE VELOUTEE 1 STANDARD * POM MAN PASS,CARREFOUR (INCL. DRIVE),3080920986193,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        ContentVersion contentVersion1 = new ContentVersion(versionData = Blob.valueOf(fileContents1),
                                                            title = 'Nielsen_COMPOTE_W022019_4S24022019_1.csv', pathOnClient = 'Nielsen_HCOMPOTE_P022019_4S24022019_1.csv', IsMajorVersion = false);
        
        String fileContents2 = ',EP AUTRE CONDITIONNEMENT ST MAMET COMPOTE VELOUTEE 1 STANDARD * POMME,CARREFOUR (INCL. DRIVE),3080920986391,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        fileContents2 += ',EP AUTRE CONDITIONNEMENT ST MAMET COMPOTE VELOUTEE 4 STANDARD * POM PECHE,CARREFOUR (INCL. DRIVE),3080920986469,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        ContentVersion contentVersion2 = new ContentVersion(versionData = Blob.valueOf(fileContents2),
                                                            title = 'Nielsen_COMPOTE_W022019_4S24022019_2.csv', pathOnClient = 'Nielsen_HCOMPOTE_P022019_4S24022019_2.csv', IsMajorVersion = false);
        insert new List<ContentVersion>{contentVersion1, contentVersion2};
        Map<String, Id> fileIdMap = new Map<String, Id>();
        fileIdMap.put('1', contentVersion1.Id);
        fileIdMap.put('2', contentVersion2.Id);
        // Test.
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionImportBatch('MarketDataCollectionImportBatchTest', fileIdMap, 1, country.Id, 'Nielsen', 'Compote', true, false, 2019, 2, null, null), 1500);
        Test.stopTest();
        // Assertion.
        Integer marketHeadCount = [SELECT COUNT() FROM Market_Data_Collection_Head__c];
        Integer marketDetailsCount = [SELECT COUNT() FROM Market_Data_Collection_Detail__c];
        System.assertEquals(1, marketHeadCount);
        System.assertEquals(4, marketDetailsCount);
    }
    
    @isTest static void case3_WeeklyImport_success() {
        init();
        String fileContents1 = ',,,,,,,,S 26/05/19,,,,,,,,,,S 02/06/19,,,,,,,,,,S 09/06/19,,,,,,,,,,S 16/06/19,,,,,,,, \n';
        fileContents1 += ',,SDESC,ITEM,MARQUES,CONDITIONNEMENT,STD/PROMO,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC Hors Promo,Ventes Volume Hors Promo  ,Ventes Valeur Hors Promo,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo \n';
        fileContents1 += 'CARREFOUR (INCL. DRIVE),,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, \n';
        fileContents1 += ',AUTRE CONDITIONNEMENT ST MAMET AUTRES PRODUITS 4 STANDARD -0E50 POMME & FRAISE,CARREFOUR (INCL. DRIVE),3080920989064,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        fileContents1 += ',EP AUTRE CONDITIONNEMENT ST MAMET COMPOTE VELOUTEE 1 STANDARD * POM MAN PASS,CARREFOUR (INCL. DRIVE),3080920986193,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        ContentVersion contentVersion1 = new ContentVersion(versionData = Blob.valueOf(fileContents1),
                                                            title = 'Nielsen_COMPOTE_W062019_4S24022019_1.csv', pathOnClient = 'Nielsen_HCOMPOTE_P022019_4S24022019_1.csv', IsMajorVersion = false);
        
        String fileContents2 = ',EP AUTRE CONDITIONNEMENT ST MAMET COMPOTE VELOUTEE 1 STANDARD * POMME,CARREFOUR (INCL. DRIVE),3080920986391,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        fileContents2 += ',EP AUTRE CONDITIONNEMENT ST MAMET COMPOTE VELOUTEE 4 STANDARD * POM PECHE,CARREFOUR (INCL. DRIVE),3080920986469,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,S 03/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 10/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 17/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00,S 24/02/19,0,0.000,0.000,0.00,0.00,0.00,0.00,0.00,0.00\n';
        ContentVersion contentVersion2 = new ContentVersion(versionData = Blob.valueOf(fileContents2),
                                                            title = 'Nielsen_COMPOTE_W062019_4S24022019_2.csv', pathOnClient = 'Nielsen_HCOMPOTE_P022019_4S24022019_2.csv', IsMajorVersion = false);
        insert new List<ContentVersion>{contentVersion1, contentVersion2};
        Map<String, Id> fileIdMap = new Map<String, Id>();
        fileIdMap.put('1', contentVersion1.Id);
        fileIdMap.put('2', contentVersion2.Id);
        // Test.
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionImportBatch('MarketDataCollectionImportBatchTest', fileIdMap, 1, country.Id, 'Nielsen', 'Compote', true, false, 2019, 6, null, null), 1500);
        Test.stopTest();
        // Assertion.
        Integer marketHeadCount = [SELECT COUNT() FROM Market_Data_Collection_Head__c];
        Integer marketDetailsCount = [SELECT COUNT() FROM Market_Data_Collection_Detail__c];
        System.assertEquals(1, marketHeadCount);
        System.assertEquals(4, marketDetailsCount);
    }
    
    @isTest static void case4_CADCAMImport_success() {
        init();
        String fileContents1 = ',,,,,,,,CAD 18,,,,,,,,,,DERNIER CAM,,,,,,,, \n';
        fileContents1 += ',,SDESC,ITEM,MARQUES,CONDITIONNEMENT,STD/PROMO,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo \n';
        fileContents1 += 'CARREFOUR (INCL. DRIVE),,,,,,,,,,,,,,,,,,,,,,,,,, \n';
        fileContents1 += ',-0E50 POMME & FRAISE ITEM,CARREFOUR (INCL. DRIVE),3080920000000,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,CAD 18,0,0,0,0,0,0,0,0,0,DERNIER CAM,0,0,0,0,0,0,0,0,0 \n';
        ContentVersion contentVersion1 = new ContentVersion(versionData = Blob.valueOf(fileContents1),
                                                            title = 'Nielsen_Compote_M112018_4S20132018_1.csv', pathOnClient = 'Nielsen_MCompote_P112018_4S20132018_1.csv', IsMajorVersion = false);
        insert contentVersion1;
        Map<String, Id> fileIdMap = new Map<String, Id>();
        fileIdMap.put('1', contentVersion1.Id);
        // Test.
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionImportBatch('MarketDataCollectionImportBatchTest', fileIdMap, 1, country.Id, 'Nielsen', 'Compote', false, true, 2018, 11, null, null), 1500);
        Test.stopTest();
        // Assertion.
        Integer marketHeadCount = [SELECT COUNT() FROM Market_Data_Collection_Head__c];
        Integer marketDetailsCount = [SELECT COUNT() FROM Market_Data_Collection_Detail__c];
        System.assertEquals(1, marketHeadCount);
        System.assertEquals(1, marketDetailsCount);
    }
    
    @isTest static void case5_Import_fails() {
        init();
        // invalid movement date
        String contentData = ',,,,,,,,30/12/18,,,,,,,,,,,,CAD 18,,,,,,,,,,,,DERNIER CAM,,,,,,,,,, \n';
        contentData += ',,SDESC,ITEM,MARQUES,CONDITIONNEMENT,STD/PROMO,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN,DV,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN,DV,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo,SDESC,Ventes UC,Ventes Volume  ,Ventes Valeur,DN Diffusion,DV Diffusion,DN,DV,DN Hors Promo,DV Hors Promo,VMH UC Hors Promo pond. par Réf,Prix Moyen UC Hors Promo \n';
        contentData += 'CARREFOUR (INCL. DRIVE),,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, \n';
        contentData += ',-0E50 POMME & FRAISE ITEM,CARREFOUR (INCL. DRIVE),3.08092E+12,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,0,0,CAD 18,0,0,0,0,0,0,0,0,0,0,0,DERNIER CAM,0,0,0,0,0,0,0,0,0,0,0\n';
        contentData += ',* POM MAN PASS ITEM,CARREFOUR (INCL. DRIVE),3.08092E+12,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,0,0,CAD 18,21,5.5,16.9,0.43,1.43,0,0.43,0,0.43,0.6,0.8,DERNIER CAM,21,5.5,16.9,0.43,1.43,0,0.43,0,0.43,0.6,0.8\n';
        contentData += ',* POMME ITEM,CARREFOUR (INCL. DRIVE),3.08092E+12,ST MAMET,AUTRE CONDITIONNEMENT,STANDARD,4 S 30/12/18,0,0,0,0,0,0,0,0,0,0,0,CAD 18,160,41.6,134.4,0.86,1.29,0.71,1,0.71,1,2.2,0.84,DERNIER CAM,160,41.6,134.4,0.86,1.29,0.71,1,0.71,1,2.2,0.84\n';
        ContentVersion contentVersion = new ContentVersion(versionData = Blob.valueOf(contentData),
                                                           title = '_enseignes_M132018_trame requêtes_1.csv', pathOnClient = 'Sell out Nielsen_enseignes_P132018_trame requêtes.csv', IsMajorVersion = false);
        insert contentVersion;
        Map<String, Id> fileIdMap = new Map<String, Id>();
        fileIdMap.put('1', contentVersion.Id);
        // Test.
        Test.startTest();
        Database.executeBatch(new MarketDataCollectionImportBatch('MarketDataCollectionImportBatchTest', fileIdMap, 1, country.Id, null, 'enseignes', false, false, 2018, 13, null, null), 1500);
        Test.stopTest();
        // Assertion.
        Integer marketHeadCount = [SELECT COUNT() FROM Market_Data_Collection_Head__c];
        System.assertEquals(0, marketHeadCount);
    }
}