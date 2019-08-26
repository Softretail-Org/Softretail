@isTest
private class GenerateAssortmentSFPlanningBatchTest {
    
    private static Id rootId;
    private static Orga_BU__c country;
    private static Orga_BU__c buSource;
    private static Orga_BU__c buTarget;
    private static List<Orga_BU__c> clusters;
    private static Sup_Supplier__c supplier;
    private static Sup_Supplier__c client;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product;
    private static Assortment_BU__c assortmentBU;
    
    static void init() {
        try {
            // Root element Id
            rootId = NegoptimHelper.getRootId();
            // Insert Country List
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Insert Region
            Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
            // Insert Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, false);
            client = TestDataFactory.createSupplier(false, country, false);
            insert new List<Sup_Supplier__c>{supplier,client};
            // Create Departments & Sections
            department = TestDataFactory.createDepartment(true, rootId);
            section = TestDataFactory.createSection(true, department.Id);
            // Create Product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            insert product;
            // Create Source BU (circuit)
            buSource = TestDataFactory.createBUBanner(false, country);
            buSource.Mission__c = 'Nielsen;Offer';
            buSource.Format_Origin__c = 'Hypermarket';
            buSource.Related_Client__c = supplier.Id;
            buSource.IsMasterBU__c = true;
            insert buSource;
            // Create BU Banner
            buTarget = TestDataFactory.createBUBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.Format_Origin__c = 'Hypermarket';
            buTarget.Related_Client__c = client.Id;
            insert buTarget;
            // Create Clusters
            clusters = new List<Orga_BU__c>();
            for (integer i = 0; i < 6; i++) {
                Orga_BU__c cluster = TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat' + i);
                cluster.Category__c = department.Id;
                clusters.add(cluster);
            }
            insert clusters;
            // insert assortment_BU
            assortmentBU = TestDataFactory.createAssortmentBU(true, buSource, buTarget, department);
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void case1_Generate_Success() {
        
        init();
        Test.startTest();
        
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                         Product__c = product.Id,
                                                                         Category__c = product.Category__c,
                                                                         Ass_BU_Cluster__c = clusters.get(2).Id,
                                                                         Movement_Date__c = Date.today().addDays(-20),
                                                                         Record_date__c = Date.today(),
                                                                         Client_Status__c = 'New',
                                                                         Status__c = 'Validated');
        insert assortmentDetail;
        
        Test.stopTest();
        System.assertEquals(4, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :assortmentDetail.Id]);
        /**
        // increase
        assortmentDetail.Ass_BU_Cluster__c = clusters.get(1).Id;
        assortmentDetail.Status__c = 'In preparation'; // also should be changed by trigger
        update assortmentDetail;
        assortmentDetail.Status__c = 'Validated'; // also should be changed by trigger
        update assortmentDetail;
        System.assertEquals(5, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :assortmentDetail.Id]);
        **/
    }
    
    @isTest static void case2_Generate_Success_Mass() {
        
        init();
        List<Product2> lsp = new List<Product2>();
        List<Assortment_Detail__c> lsasd = new List<Assortment_Detail__c>();
        for(Integer i = 0; i < 100; i++)
            lsp.add(TestDataFactory.createProduct(false, section.Id, supplier.Id));
        insert lsp;
        Test.startTest();
        for(Product2 item : lsp)
            lsasd.add(new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                               Product__c = item.Id,
                                               Category__c = item.Category__c,
                                               Ass_BU_Cluster__c = clusters.get(4).Id,
                                               Movement_Date__c = Date.today().addDays(-20),
                                               Record_date__c = Date.today(),
                                               Client_Status__c = 'New',
                                               Status__c = 'Validated')
                     );
        insert lsasd;
        Test.stopTest();
        AggregateResult[] groupedAgr = [SELECT count(Id) nbsfp,Assortment_BU_Detail__c asdId FROM Assortment_SF_Planning__c GROUP BY Assortment_BU_Detail__c];
        System.assertEquals(groupedAgr.size(), lsasd.size());
        Map<Id,INteger> mapAgr = new Map<Id,INteger>();
        for(AggregateResult agr : groupedAgr)
            mapAgr.put((Id)agr.get('asdId'),(Integer)agr.get('nbsfp'));
        for(Assortment_Detail__c item : lsasd)
            System.assertEquals(2, mapAgr.get(item.Id));
        
    }
    
    @isTest static void case3_Same_Cluster() {
        init();
        Test.startTest();
        
        Assortment_Detail__c history = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                Product__c = product.Id,
                                                                Category__c = product.Category__c,
                                                                Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                Movement_Date__c = Date.today().addDays(20),
                                                                Record_date__c = Date.today(),
                                                                Client_Status__c = 'New',
                                                                Status__c = 'Validated',
                                                                Version__c = 1);
        insert history;
        Assortment_Detail__c newRecord = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                  Product__c = product.Id,
                                                                  Category__c = product.Category__c,
                                                                  Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                  Movement_Date__c = Date.today().addDays(20),
                                                                  Record_date__c = Date.today(),
                                                                  Client_Status__c = 'New',
                                                                  Status__c = 'In preparation',
                                                                  Version__c = null,
                                                                  Last_History__c = history.Id);
        insert newRecord;
        List<Assortment_SF_Planning__c> lsasfp=new List<Assortment_SF_Planning__c>();
        for(Integer i=0 ; i<6 ; i++)
            lsasfp.add(createSFPlanningRecord(newRecord,clusters.get(i),false));
        insert lsasfp;
        newRecord.Status__c = 'Validated';
        update newRecord;
        
        Test.stopTest();
        System.assertEquals(6, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = true]);
        System.assertEquals(0, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = false]);
    }
    
    @isTest static void case4_No_Clusters() {
        init();
        Test.startTest();
        
        
        // delete all clusters and relations
        delete [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity_List__c IN :clusters];
        delete [SELECT Id FROM Orga_BU__c WHERE Id IN :clusters];
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                         Product__c = product.Id,
                                                                         Category__c = product.Category__c,
                                                                         Movement_Date__c = Date.today().addDays(20),
                                                                         Record_date__c = Date.today(),
                                                                         Client_Status__c = 'New',
                                                                         Status__c = 'In preparation');
        insert assortmentDetail;
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :assortmentDetail.Id]);
    }
    
    @isTest static void case5_Unset_Cluster() {
        init();
        Test.startTest();
        
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                         Product__c = product.Id,
                                                                         Category__c = product.Category__c,
                                                                         Ass_BU_Cluster__c = null,
                                                                         Movement_Date__c = Date.today().addDays(20),
                                                                         Record_date__c = Date.today(),
                                                                         Client_Status__c = 'New',
                                                                         Status__c = 'In preparation');
        insert assortmentDetail;
        assortmentDetail.Ass_BU_Cluster__c = null;
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :assortmentDetail.Id]);
    }
    
    @isTest static void case6_Increase() {
        init();
        Test.startTest();
        
        Assortment_Detail__c history = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                Product__c = product.Id,
                                                                Category__c = product.Category__c,
                                                                Ass_BU_Cluster__c = clusters.get(3).Id,
                                                                Movement_Date__c = Date.today().addDays(20),
                                                                Record_date__c = Date.today(),
                                                                Client_Status__c = 'New',
                                                                Status__c = 'Validated',
                                                                Version__c = 1);
        insert history;
        Assortment_Detail__c newRecord = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                  Product__c = product.Id,
                                                                  Category__c = product.Category__c,
                                                                  Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                  Movement_Date__c = Date.today().addDays(20),
                                                                  Record_date__c = Date.today(),
                                                                  Client_Status__c = 'New',
                                                                  Status__c = 'In preparation',
                                                                  Version__c = null,
                                                                  Last_History__c = history.Id);
        insert newRecord;
        List<Assortment_SF_Planning__c> lsasfp=new List<Assortment_SF_Planning__c>();
        for(Integer i = 3 ; i < 6 ; i++)
            lsasfp.add(createSFPlanningRecord(newRecord,clusters.get(i),false));
        insert lsasfp;
        newRecord.Status__c = 'Validated';
        update newRecord;
        
        Test.stopTest();
        System.assertEquals(6, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id]);
    }
    
    @isTest static void case7_Increase() {
        init();
        Test.startTest();
        
        Assortment_Detail__c history = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                Product__c = product.Id,
                                                                Category__c = product.Category__c,
                                                                Ass_BU_Cluster__c = clusters.get(3).Id,
                                                                Movement_Date__c = Date.today().addDays(-20),
                                                                Record_date__c = Date.today(),
                                                                Client_Status__c = 'New',
                                                                Status__c = 'Validated',
                                                                Version__c = 1);
        insert history;
        Assortment_Detail__c newRecord = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                  Product__c = product.Id,
                                                                  Category__c = product.Category__c,
                                                                  Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                  Movement_Date__c = Date.today().addDays(-20),
                                                                  Record_date__c = Date.today(),
                                                                  Client_Status__c = 'New',
                                                                  Status__c = 'In preparation',
                                                                  Version__c = null,
                                                                  Last_History__c = history.Id);
        insert newRecord;
        List<Assortment_SF_Planning__c> lsasfp=new List<Assortment_SF_Planning__c>();
        for(Integer i=3 ; i<6 ; i++)
            lsasfp.add(createSFPlanningRecord(newRecord,clusters.get(i),false));
        insert lsasfp;
        newRecord.Status__c = 'Validated';
        update newRecord;
        
        Test.stopTest();
        System.assertEquals(6, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id]);
    }
    
    @isTest static void case8_Increase() {
        init();
        Test.startTest();
        
        Assortment_Detail__c history = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                Product__c = product.Id,
                                                                Category__c = product.Category__c,
                                                                Ass_BU_Cluster__c = clusters.get(3).Id,
                                                                Movement_Date__c = Date.today().addDays(-80),
                                                                Record_date__c = Date.today(),
                                                                Client_Status__c = 'New',
                                                                Status__c = 'Validated',
                                                                Version__c = 1);
        insert history;
        Assortment_Detail__c newRecord = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                  Product__c = product.Id,
                                                                  Category__c = product.Category__c,
                                                                  Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                  Movement_Date__c = Date.today().addDays(-80),
                                                                  Record_date__c = Date.today(),
                                                                  Client_Status__c = 'New',
                                                                  Status__c = 'In preparation',
                                                                  Version__c = null,
                                                                  Last_History__c = history.Id);
        insert newRecord;
        List<Assortment_SF_Planning__c> lsasfp=new List<Assortment_SF_Planning__c>();
        for(Integer i=3 ; i<6 ; i++)
            lsasfp.add(createSFPlanningRecord(newRecord,clusters.get(i),false));
        insert lsasfp;
        newRecord.Status__c = 'Validated';
        update newRecord;
        
        Test.stopTest();
        System.assertEquals(6, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id]);
    }
    
    @isTest static void case9_Decrease() {
        init();
        Test.startTest();
        
        Assortment_Detail__c history = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                Product__c = product.Id,
                                                                Category__c = product.Category__c,
                                                                Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                Movement_Date__c = Date.today().addDays(20),
                                                                Record_date__c = Date.today(),
                                                                Client_Status__c = 'New',
                                                                Status__c = 'Validated',
                                                                Version__c = 1);
        insert history;
        Assortment_Detail__c newRecord = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                  Product__c = product.Id,
                                                                  Category__c = product.Category__c,
                                                                  Ass_BU_Cluster__c = clusters.get(3).Id,
                                                                  Movement_Date__c = Date.today().addDays(20),
                                                                  Record_date__c = Date.today(),
                                                                  Client_Status__c = 'New',
                                                                  Status__c = 'In preparation',
                                                                  Version__c = null,
                                                                  Last_History__c = history.Id);
        insert newRecord;
        List<Assortment_SF_Planning__c> lsasfp=new List<Assortment_SF_Planning__c>();
        for(Integer i=0 ; i<6 ; i++)
            lsasfp.add(createSFPlanningRecord(newRecord,clusters.get(i),false));
        insert lsasfp;
        newRecord.Status__c = 'Validated';
        update newRecord;
        
        Test.stopTest();
        System.assertEquals(6, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = true]);
        System.assertEquals(3, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = false]);
    }
    
    @isTest static void case10_Decrease() {
        init();
        Test.startTest();
        
        Assortment_Detail__c history = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                Product__c = product.Id,
                                                                Category__c = product.Category__c,
                                                                Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                Movement_Date__c = Date.today().addDays(-20),
                                                                Record_date__c = Date.today(),
                                                                Client_Status__c = 'New',
                                                                Status__c = 'Validated',
                                                                Version__c = 1);
        insert history;
        Assortment_Detail__c newRecord = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                  Product__c = product.Id,
                                                                  Category__c = product.Category__c,
                                                                  Ass_BU_Cluster__c = clusters.get(3).Id,
                                                                  Movement_Date__c = Date.today().addDays(-20),
                                                                  Record_date__c = Date.today(),
                                                                  Client_Status__c = 'New',
                                                                  Status__c = 'In preparation',
                                                                  Version__c = null,
                                                                  Last_History__c = history.Id);
        insert newRecord;
        List<Assortment_SF_Planning__c> lsasfp=new List<Assortment_SF_Planning__c>();
        for(Integer i=0 ; i<6 ; i++)
            lsasfp.add(createSFPlanningRecord(newRecord,clusters.get(i),false));
        insert lsasfp;
        newRecord.Status__c = 'Validated';
        update newRecord;
        
        Test.stopTest();
        System.assertEquals(6, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = true]);
        System.assertEquals(3, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = false]);
    }
    
    @isTest static void case11_Decrease() {
        init();
        Test.startTest();
        
        Assortment_Detail__c history = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                Product__c = product.Id,
                                                                Category__c = product.Category__c,
                                                                Ass_BU_Cluster__c = clusters.get(0).Id,
                                                                Movement_Date__c = Date.today().addDays(-80),
                                                                Record_date__c = Date.today(),
                                                                Client_Status__c = 'New',
                                                                Status__c = 'Validated',
                                                                Version__c = 1);
        insert history;
        Assortment_Detail__c newRecord = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                  Product__c = product.Id,
                                                                  Category__c = product.Category__c,
                                                                  Ass_BU_Cluster__c = clusters.get(3).Id,
                                                                  Movement_Date__c = Date.today().addDays(-80),
                                                                  Record_date__c = Date.today(),
                                                                  Client_Status__c = 'New',
                                                                  Status__c = 'In preparation',
                                                                  Version__c = null,
                                                                  Last_History__c = history.Id);
        insert newRecord;
        List<Assortment_SF_Planning__c> lsasfp=new List<Assortment_SF_Planning__c>();
        for(Integer i = 0 ; i < 6 ; i++)
            lsasfp.add(createSFPlanningRecord(newRecord,clusters.get(i),false));
        insert lsasfp;
        newRecord.Status__c = 'Validated';
        update newRecord;
        
        Test.stopTest();
        System.assertEquals(6, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = true]);
        System.assertEquals(3, [SELECT COUNT() FROM Assortment_SF_Planning__c WHERE Assortment_BU_Detail__c = :newRecord.Id AND IsLast__c = false]);
    }
    
    private static Assortment_SF_Planning__c createSFPlanningRecord(Assortment_Detail__c asd, Orga_BU__c cluster, Boolean isDecrease) {
        String externalId  = cluster.Country_Origin__r.BU_Code__c + '-' + cluster.BU_Code__c + '-' + asd.Product_Code__c + '-' + asd.Product_EAN__c + '-' + Date.today().format();
        String code;
        if (isDecrease) {
            if (Date.today() < asd.Movement_Date__c)
                code = 'D';
            else if (asd.Movement_Date__c!=null && Date.today() >= asd.Movement_Date__c && Date.today() < asd.Movement_Date__c.addDays(60))
                code = 'S';
            else if (asd.Movement_Date__c!=null && Date.today() >= asd.Movement_Date__c.addDays(60))
                code = null;
        } else {
            if (Date.today() < asd.Movement_Date__c)
                code = 'A';
            else if (asd.Movement_Date__c!=null && Date.today() >= asd.Movement_Date__c && Date.today() < asd.Movement_Date__c.addDays(60))
                code = 'N';
            else if (asd.Movement_Date__c!=null && Date.today() >= asd.Movement_Date__c.addDays(60))
                code = 'O';
        }
        System.assert(true);
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