@isTest
private class Trg_Product_Assortment_Introduction_Test {
    
    private static Id rootId;
    private static Orga_BU__c country;
    private static Orga_BU__c buSource;
    private static Orga_BU__c buTarget;
    private static Sup_Supplier__c client;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product1;
    private static Product2 product2;
    private static Assortment_BU__c assortmentBU;
    
    static void init() {
        try{
            // Root element Id.
            rootId = NegoptimHelper.getRootId();
            // Create Department & Section
            department = TestDataFactory.createDepartment(true, rootId);
            section = TestDataFactory.createSection(true, department.Id);
            // Insert Country List.
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Insert Region.
            Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Supplier
            client = TestDataFactory.createSupplier(false, country, false);
            insert client;
            country.Related_Client__c = client.Id;
            update country;
            // Create Source BU (circuit)
            buSource = TestDataFactory.createBUBanner(false, country);
            buSource.Mission__c = 'Nielsen;Offer';
            buSource.Format_Origin__c = 'Hypermarket';
            buSource.Related_Client__c = client.Id;
            buSource.IsMasterBU__c = true;
            // Create BU Banner
            buTarget = TestDataFactory.createBUBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.Format_Origin__c = 'Hypermarket';
            buTarget.Related_Client__c = client.Id;
            buTarget.Category__c = department.Id;
            buTarget.IsMasterBU__c = false;
            insert new List<Orga_BU__c>{buSource, buTarget};
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section.Id, client.Id);
            product2 = TestDataFactory.createProduct(false, section.Id, client.Id);
            insert new List<Product2>{product1, product2};
            // insert assortment
            assortmentBU = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
            assortmentBU.Status__c = 'Validated';
            assortmentBU.Ass_BDate__c = System.today() + 1;
            assortmentBU.Ass_EDate__c = System.today().addmonths(1);
            insert assortmentBU;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Insert Product Assortment Intro History for Inno products with Any current & next assortment Load rule
    static testMethod void insertProductInnoCurrentNextAssortment() {
        init();
        // Create Product Assortment Introduct History
        Product_Assortment_Introduction_History__c productAssortment = new Product_Assortment_Introduction_History__c(
            BU_Target__c = buTarget.Id, Product__c = product1.Id, Load_Status__c = 'Yes',
            Load_Rules__c = 'Any current & next assortment', Client__c = client.Id);
        productAssortment.RecordTypeId = TestDataFactory.productAssortmentIntroRTIds.get('Inno');        
        Test.startTest();
        Database.SaveResult result = Database.insert(productAssortment,false);
        Test.stopTest();
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        List<Assortment_Detail__c> assortmentDetails = [SELECT Id from Assortment_Detail__c WHERE Assortment_BU__c = :assortmentBU.Id];
        System.assertEquals(1, assortmentDetails.size());
    }
    
    // Insert Product Assortment Intro History for Inno products with Only Nego assortment Load rule
    static testMethod void insertProductInnoOnlyNegoAssortment() {
        init();
        // Create Product Assortment Introduct History
        Product_Assortment_Introduction_History__c productAssortment = new Product_Assortment_Introduction_History__c(
            BU_Target__c = buTarget.Id, Product__c = product1.Id, Load_Status__c = 'Yes',
            Load_Rules__c = 'Only nego assortment', Client__c = client.Id);
        productAssortment.RecordTypeId = TestDataFactory.productAssortmentIntroRTIds.get('Inno');
        Test.startTest();
        Database.SaveResult result = Database.insert(productAssortment,false);
        Test.stopTest();
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        List<Assortment_Detail__c> assortmentDetails = [SELECT Id from Assortment_Detail__c WHERE Assortment_BU__c = :assortmentBU.Id];
        System.assertEquals(1, assortmentDetails.size());
    }
    
    // Insert Product Assortment Intro History for Inno products with Only Next assortment Load rule
    static testMethod void insertProductInnoOnlyNextAssortment() {
        init();
        // Create Product Assortment Introduct History
        Product_Assortment_Introduction_History__c productAssortment = new Product_Assortment_Introduction_History__c(
            BU_Target__c = buTarget.Id, Product__c = product1.Id, Load_Status__c = 'Yes',
            Load_Rules__c = 'Only next assortment', Client__c = client.Id);
        productAssortment.RecordTypeId = TestDataFactory.productAssortmentIntroRTIds.get('Inno');
        Test.startTest();
        Database.SaveResult result = Database.insert(productAssortment,false);
        Test.stopTest();
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        List<Assortment_Detail__c> assortmentDetails = [SELECT Id from Assortment_Detail__c WHERE Assortment_BU__c = :assortmentBU.Id];
        System.assertEquals(1, assortmentDetails.size());
    }
    // Insert Product Assortment Intro History for Stop products with Only Nego assortment Load rule
    static testMethod void insertProductStopOnlyNegoAssortment() {
        init();
        // Create Assortment Clusters
        Orga_BU__c assortmentClust1 = TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat0');
        // Create Assortment Detail
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                         Product__c = product1.Id,
                                                                         Category__c = product1.Category__c,
                                                                         Ass_BU_Cluster__c = assortmentClust1.Id,
                                                                         Client_Status__c = 'New');
        insert assortmentDetail;
        Product_Assortment_Introduction_History__c productAssortment = new Product_Assortment_Introduction_History__c(
            BU_Target__c = buTarget.Id, Product__c = product1.Id, Load_Status__c = 'Yes',
            Load_Rules__c = 'Only nego assortment', Client__c = client.Id);
        productAssortment.RecordTypeId = TestDataFactory.productAssortmentIntroRTIds.get('Stop');
        Test.startTest();
        Database.SaveResult result = Database.insert(productAssortment,false);
        Test.stopTest();
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        assortmentDetail = [SELECT Client_Status__c from Assortment_Detail__c WHERE Id = :assortmentDetail.Id]; 
        System.assertEquals('Delete', assortmentDetail.Client_Status__c);
    }
    // Insert Product Assortment Intro History for Stop products with Only Next assortment Load rule
    static testMethod void insertProductStopOnlyNextAssortment() {
        init();
        // Create Assortment Clusters
        Orga_BU__c assortmentClust1 = TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat0');
        // Create Assortment Detail
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                         Product__c = product1.Id,
                                                                         Category__c = product1.Category__c,
                                                                         Ass_BU_Cluster__c = assortmentClust1.Id,
                                                                         Client_Status__c = 'New');
        insert assortmentDetail;
        Product_Assortment_Introduction_History__c productAssortment = new Product_Assortment_Introduction_History__c(
            BU_Target__c = buTarget.Id, Product__c = product1.Id, Load_Status__c = 'Yes',
            Load_Rules__c = 'Only next assortment', Client__c = client.Id);
        productAssortment.RecordTypeId = TestDataFactory.productAssortmentIntroRTIds.get('Stop');
        Test.startTest();
        Database.SaveResult result = Database.insert(productAssortment,false);
        Test.stopTest();
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        assortmentDetail = [SELECT Client_Status__c from Assortment_Detail__c WHERE Id = :assortmentDetail.Id]; 
        System.assertEquals('Delete', assortmentDetail.Client_Status__c);
    }
}