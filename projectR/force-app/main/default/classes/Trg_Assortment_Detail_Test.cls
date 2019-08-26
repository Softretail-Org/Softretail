@isTest
private class Trg_Assortment_Detail_Test {
    
    private static Id rootId;
    private static Sup_Supplier__c supplier;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Product2 product;
    private static Orga_BU__c buSource;
    private static Orga_BU__c buTarget;
    private static List<Orga_BU__c> clusters;
    private static Assortment_BU__c assortmentBU;
    private static Orga_BU__c country;
    
    static void init() {
        // Root element Id.
        rootId = NegoptimHelper.getRootId();
        // Insert Country List.
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        // Insert Region.
        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
        // Insert Country.
        country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
        country.IsMasterBU__c = true;
        insert country;
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true);
        insert supplier;
        // create HEs
        department = TestDataFactory.createDepartment(true, rootId);
        section = TestDataFactory.createSection(true, department.Id);
        // Create Product.
        product = TestDataFactory.createProduct(true, section.Id, null);
        // create Source BU Banner
        buSource = TestDataFactory.createBUBanner(false, country);
        buSource.Related_Client__c = supplier.Id;
        buSource.IsMasterBU__c = true;
        // create Target BU Banner
        buTarget = TestDataFactory.createBUBanner(false, country);
        buTarget.Related_Client__c = supplier.Id;
        buTarget.Category__c = department.Id;
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        for(Integer i = 1; i <= 12; i++) {
            buTarget.put('Weighted_Distribution_InnovRise_M' + i + '__c', i);
        }
        insert new List<Orga_BU__c>{buTarget, buSource};
        clusters = new List<Orga_BU__c>();
        for (Integer i = 5; i >= 0; i--) {
            Orga_BU__c cluster = TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat' + (5 - i));
            cluster.Weighted_Distribution_Manual__c = 3 * (i + 2); // 21, 18, 15, 12, 9, 6
            clusters.add(cluster);
        }
        insert clusters;
        // insert assortment_BU
        assortmentBU = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        assortmentBU.Status__c = 'Validated';
        //assortmentBU.Ass_BDate__c = Date.today();
        insert assortmentBU;
    }
    
    // case autoFillAssortmentCategory/update Client_Clust(i)__c/calculate WD
    static testmethod void case1_InsertAssortmentDetail_Success() {
        init();
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Category__c = null,
                                                                         Ass_BU_Cluster__c = clusters[1].Id, Client_Status__c = 'New');
        Test.startTest();
        insert assortmentDetail;
        Test.stopTest();
        // Assertion.
        assortmentDetail = [SELECT Category__c, Client_Clust1__c, Client_Clust2__c, Client_Clust3__c, Client_Clust4__c,
                            Client_Clust5__c, Client_Clust6__c, New_Client_WD_MarketBased__c, New_Client_WD_ClientBased__c
                            FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        
        System.assertEquals(product.Category__c, assortmentDetail.Category__c);
        System.assertEquals(false, assortmentDetail.Client_Clust1__c);
        System.assertEquals(true, assortmentDetail.Client_Clust2__c);
        System.assertEquals(true, assortmentDetail.Client_Clust3__c);
        System.assertEquals(true, assortmentDetail.Client_Clust4__c);
        System.assertEquals(true, assortmentDetail.Client_Clust5__c);
        System.assertEquals(true, assortmentDetail.Client_Clust6__c);
        System.assertEquals(60, assortmentDetail.New_Client_WD_MarketBased__c);
        System.assertEquals(60/81.0*100, assortmentDetail.New_Client_WD_ClientBased__c);
    }
    
    // case update Ass_BU_Cluster__c
    static testmethod void case2_UpdateAssortmentDetail_Success() {
        init();
        Test.startTest();
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Movement_Date__c = Date.today(),
                                                                         Ass_BU_Cluster__c = null, Client_Status__c = 'New', Status__c = 'Validated');
        insert assortmentDetail;
        ////assortmentDetail = [SELECT Client_Status__c, Client_Clust2__c, Record_Date__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        // case update Client_Clust__c
        assortmentDetail.Client_Status__c = 'Keep';
        assortmentDetail.Client_Clust2__c = true;
        assortmentDetail.Record_Date__c = System.today();
        update assortmentDetail;
        // Assertion.
        assortmentDetail = [SELECT Ass_BU_Cluster__c, Last_History__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        system.assertEquals(clusters[1].Id, assortmentDetail.Ass_BU_Cluster__c);
        /*System.assertEquals(1, [SELECT COUNT() FROM Assortment_Detail__c WHERE Assortment_BU__c =: assortmentBU.Id AND Product__c = :product.Id AND Status__c = 'In preparation']);
        System.assertEquals(2, [SELECT COUNT() FROM Assortment_Detail__c WHERE Assortment_BU__c =: assortmentBU.Id AND Product__c = :product.Id]);
        System.assertNotEquals(null, assortmentDetail.Last_History__c);
        // case Switch (client_status Deleted)
        Product2 referenceProduct = TestDataFactory.createProduct(true, section.Id, null);
        referenceProduct.Reference_Product__c = product.Id;
        update referenceProduct;
        //// assortmentDetail.Status__c = 'Validated';
        //// update assortmentDetail;
        assortmentDetail.Product__c = referenceProduct.Id;
        update assortmentDetail;
        assortmentDetail = [SELECT Client_Status__c, Product__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        System.assertEquals('New', assortmentDetail.Client_Status__c);
        System.assertEquals(referenceProduct.Id, assortmentDetail.Product__c);
        Test.stopTest();
        List<Assortment_Detail__c> historyLines = [SELECT Version__c FROM Assortment_Detail__c WHERE Assortment_BU__c =: assortmentBU.Id AND Product__c = :product.Id];
        System.assertEquals(2, historyLines.size());
        System.assertNotEquals(null, historyLines[0].Version__c);
        System.assertNotEquals(null, historyLines[1].Version__c);*/
    }
    
    static testmethod void case3_InsertPG_Success() {
        init();
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id,
                                                                         Category__c = product.Category__c, Ass_BU_Cluster__c = clusters[0].Id,
                                                                         Client_Status__c = 'New');
        insert assortmentDetail;
        System.assertEquals(0, [SELECT COUNT() FROM Supplier_PG_Mapping__c WHERE Product__c = :product.Id AND Supplier__c = :supplier.Id]);
        Test.startTest();
        // case insertPG
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        Test.stopTest();
        // Assertion.
        System.assertEquals(1, [SELECT COUNT() FROM Supplier_PG_Mapping__c WHERE Product__c = :product.Id AND Supplier__c = :supplier.Id]);
    }
    
    static testmethod void case4_ValidateAssortmentCategory_Failure() {
        init();
        // Create Departments & Sections.
        Orga_HE__c department1 = TestDataFactory.createDepartment(true, rootId);
        Orga_HE__c section1 = TestDataFactory.createSection(true, department1.Id);        
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Category__c = section1.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(assortmentDetail, false);
        Test.stopTest();
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, result.getErrors()[0]);
    }
        
    static testmethod void case5_InsertAssortmentDetailOneByOne_Failure() {
        init();
        Assortment_Detail__c assortmentDetail1 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Category__c = null,
                                                                          Ass_BU_Cluster__c = clusters[0].Id, Client_Status__c = 'New', Version__c = null);
        Assortment_Detail__c assortmentDetail2 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Category__c = null,
                                                                          Ass_BU_Cluster__c = clusters[0].Id, Client_Status__c = 'New', Version__c = null);
        Test.startTest();
        Database.SaveResult sr1 = Database.insert(assortmentDetail1, false);
        Database.SaveResult sr2 = Database.insert(assortmentDetail2, false);
        Test.stopTest();
        // Assertion.
        System.assertEquals(0, sr1.getErrors().size());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, sr2.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, sr2.getErrors()[0]);
    }
    
    static testmethod void case6_UpdateAssortmentDetail_Failure() {
        init();
        Test.startTest();
        Assortment_Detail__c assortmentDetail1 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Category__c = product.Category__c,
                                                                          Ass_BU_Cluster__c = null, Client_Status__c = 'New', Status__c = 'Validated', Version__c = null);
        insert assortmentDetail1;
        Product2 p1 = TestDataFactory.createProduct(false, section.Id, null);
        insert p1;
        Assortment_Detail__c assortmentDetail2 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = p1.Id, Category__c = product.Category__c,
                                                                          Ass_BU_Cluster__c = null, Client_Status__c = 'New', Status__c = 'Validated', Version__c = null);
        insert assortmentDetail2;
        assortmentDetail2.Product__c = product.Id;
        Database.SaveResult result = Database.update(assortmentDetail2,false);
        Test.stopTest();
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, result.getErrors()[0]);
    }
    
    static testmethod void case7_InsertAssortmentDetailList_Failure() {
        init();
        Assortment_Detail__c assortmentDetail1 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Category__c = null,
                                                                          Ass_BU_Cluster__c = clusters[0].Id, Client_Status__c = 'New', Version__c = null);
        Assortment_Detail__c assortmentDetail2 = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = product.Id, Category__c = null,
                                                                          Ass_BU_Cluster__c = clusters[0].Id, Client_Status__c = 'New', Version__c = null);
        Test.startTest();
        List<Database.SaveResult> lsr = Database.insert(new List<Assortment_Detail__c>{assortmentDetail1,assortmentDetail2}, false);
        Test.stopTest();
        // Assertion.
        System.assertEquals(0, lsr.get(0).getErrors().size());
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, lsr.get(1).getErrors()[0].getStatusCode());
        System.assertNotEquals(null, lsr.get(1).getErrors()[0]);
    }
    
    static testmethod void case8_GenerateAssortmentDetailSequencesAndMatrix_Success() {
        init();
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id,
                                                                         Product__c = product.Id,
                                                                         Ass_BU_Cluster__c = clusters[0].Id,
                                                                         Movement_Date__c = Date.today(),
                                                                         Record_date__c = Date.today(),
                                                                         Client_Status__c = 'Keep');
        insert assortmentDetail;
        Test.startTest();
        assortmentDetail.Status__c = 'Validated';
        update assortmentDetail;
        Test.stopTest();
        System.assertEquals(12, [SELECT COUNT() FROM Assortment_Detail_Sequence__c WHERE Assortment_Detail__c = :assortmentDetail.Id]);
    }
    
    static testmethod void case9_generateExternalId_Single_Failure() {
        init();
        Test.startTest();
        Product2 p1 = TestDataFactory.createProduct(true, section.Id, null);
        p1.Ext_id__c = null;
        update p1;
        Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = p1.Id, Category__c = p1.Category__c,
                                                                         Ass_BU_Cluster__c = null, Client_Status__c = 'New', Status__c = 'Validated', Version__c = null);
        Database.SaveResult result = Database.insert(assortmentDetail,false);
        Test.stopTest();
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, result.getErrors()[0]);
    }
    
    static testmethod void case10_generateExternalId_Mass_success() {
        init();
        Map<String, Id> recordTypes = NegoptimHelper.getObjectRecordTypeMapIds(Product2.sObjectType);
        Integer numberOfRecords = 50;
        Test.startTest();
        // Create Global Settings
        NegoptimCustomSettings__c negoSettings = TestDataFactory.createNegoptimCustomSettings(true);
        List<Product2> productList = new List<Product2>();
        List<Assortment_Detail__c> asdList = new List<Assortment_Detail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Product2 p = TestDataFactory.createProduct(false, section.Id, null);
            p.recordTypeId = recordTypes.get('Product');
            p.Ext_id__c = p.Product_EAN__c + '-' + p.ProductCode;
            productList.add(p);
        }
        insert productList;
        for (Integer i = 0; i < numberOfRecords; i++) {
            Assortment_Detail__c assortmentDetail = new Assortment_Detail__c(Assortment_BU__c = assortmentBU.Id, Product__c = productList.get(i).Id, Category__c = productList.get(i).Category__c,
                                                                             Ass_BU_Cluster__c = null, Client_Status__c = 'New', Status__c = 'Validated', Version__c = null);
            asdList.add(assortmentDetail);
        }
        List<Database.SaveResult> resultList = Database.insert(asdList,false);
        Test.stopTest();
        Set<Id> asdIdsSet = new Set<Id>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            asdIdsSet.add(asdList.get(i).Id);
        }
        asdList.clear();
        asdList = [SELECT Assortment_BU__r.Name, Version__c, Ext_Id__c FROM Assortment_Detail__c WHERE Id in :asdIdsSet];
        System.assertEquals(numberOfRecords, asdList.size());
        for (Integer i = 0; i < numberOfRecords; i++) {
            String version = asdList.get(i).Version__c != null ? String.valueOf(asdList.get(i).Version__c) : '';
            String externalID = asdList.get(i).Assortment_BU__r.Name + '-' + productList.get(i).Ext_Id__c + '-V' + version;
            System.assertEquals(externalID, asdList.get(i).Ext_Id__c);
        }
    }
    
    static testmethod void case11_linkToRefCorp_success() {
        init();
        Assortment_BU__c nego = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        nego.Status__c = 'Validated';
        Assortment_BU__c budget = TestDataFactory.createAssortmentBU(false, country, buSource, department);
        Map<String, Id> assortmentRTIds = TestDataFactory.assortmentRTIds;
        budget.RecordTypeId = assortmentRTIds.get('Budget');
        budget.Assortment_type__c = 'In';
        insert new List<Assortment_BU__c>{nego, budget};
        Integer numberOfRecords = 25;
        List<Product2> productList = new List<Product2>();
        List<Assortment_Detail__c> asdList = new List<Assortment_Detail__c>();
        List<Assortment_Detail__c> asdList2 = new List<Assortment_Detail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Product2 p = TestDataFactory.createProduct(false, section.Id, null);
            productList.add(p);
        }
        insert productList;
        for (Integer i = 0; i < numberOfRecords; i++) {
            Assortment_Detail__c assortmentDetail1 = TestDataFactory.createAssortmentDetail(false, nego.Id, productList.get(i), null);
            assortmentDetail1.Category__c = productList.get(i).Category__c;
            assortmentDetail1.Client_Status__c = 'New';
            assortmentDetail1.Status__c = 'Validated';
            assortmentDetail1.Version__c = null;
            asdList.add(assortmentDetail1);
            Assortment_Detail__c assortmentDetail2 = TestDataFactory.createAssortmentDetail(false, budget.Id, productList.get(i), null);
            assortmentDetail2.Category__c = productList.get(i).Category__c;
            assortmentDetail2.Client_Status__c = 'New';
            assortmentDetail2.Status__c = 'Validated';
            assortmentDetail2.Version__c = null;
            asdList2.add(assortmentDetail2);
        }
        List<Assortment_Detail__c> asdLists = new List<Assortment_Detail__c>(asdList);
        asdLists.addAll(asdList2);
        insert asdLists;
        Test.startTest();
        Assortment_BU__c target = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        target.Status__c = 'Validated';
        target.RecordTypeId = TestDataFactory.assortmentRTIds.get('Target');
        target.Assortment_parent__c = nego.Id;
        target.Assortment_Parent_Objective__c = budget.Id;
        insert target;
        Test.stopTest();
        List<Assortment_Detail__c> targetASDsList = new List<Assortment_Detail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, target.Id, productList.get(i), null);
            assortmentDetail.Category__c = productList.get(i).Category__c;
            assortmentDetail.Client_Status__c = 'New';
            assortmentDetail.Status__c = 'Validated';
            assortmentDetail.Version__c = null;
            targetASDsList.add(assortmentDetail);
        }
        insert targetASDsList;
        targetASDsList = [SELECT Id, Ref_Corp_Assortment__c, Ref_Client_Assortment__c FROM Assortment_Detail__c WHERE Assortment_BU__c = :target.Id];
        for (Integer i = 0; i < numberOfRecords; i++) {
            System.assertEquals(null, targetASDsList.get(i).Ref_Client_Assortment__c);
            System.assertEquals(asdList2.get(i).Id, targetASDsList.get(i).Ref_Corp_Assortment__c);
        }
    }
    
    static testmethod void case12_CreateAssortmentDetailsFromParentTarget_success() {
        init();
        Map<String, Id> assortmentRTIds = TestDataFactory.assortmentRTIds;
        Assortment_BU__c target = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        target.Status__c = 'Validated';
        insert target;
        Integer numberOfRecords = 25;
        List<Product2> productList = new List<Product2>();
        List<Assortment_Detail__c> asdList = new List<Assortment_Detail__c>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Product2 p = TestDataFactory.createProduct(false, section.Id, null);
            productList.add(p);
        }
        
        insert productList;
        for (Integer i = 0; i < numberOfRecords; i++) {
            Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, target.Id, productList.get(i), null);
            assortmentDetail.Category__c = productList.get(i).Category__c;
            assortmentDetail.Client_Status__c = 'New';
            assortmentDetail.Status__c = 'Validated';
            assortmentDetail.Version__c = null;
            asdList.add(assortmentDetail);
        }
        insert asdList;
        Test.startTest();
        Assortment_BU__c nego1 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        nego1.Status__c = 'Validated';
        nego1.Assortment_parent__c = target.Id;
        Assortment_BU__c nego2 = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department);
        nego2.Status__c = 'Validated';
        nego2.Assortment_parent__c = target.Id;
        insert new List<Assortment_BU__c> {nego1, nego2};
        Test.stopTest();
        List<Assortment_Detail__c> nego1ASDsList = [SELECT Id, Ref_Corp_Assortment__c, Ref_Client_Assortment__c FROM Assortment_Detail__c WHERE Assortment_BU__c = :nego1.Id];
        List<Assortment_Detail__c> nego2ASDsList = [SELECT Id, Ref_Corp_Assortment__c, Ref_Client_Assortment__c FROM Assortment_Detail__c WHERE Assortment_BU__c = :nego2.Id];
        
        for (Integer i = 0; i < numberOfRecords; i++) {
            System.assertEquals(asdList.get(i).Id,nego1ASDsList.get(i).Ref_Client_Assortment__c);
            System.assertEquals(null,nego1ASDsList.get(i).Ref_Corp_Assortment__c);
            System.assertEquals(asdList.get(i).Id,nego2ASDsList.get(i).Ref_Client_Assortment__c);
            System.assertEquals(null,nego2ASDsList.get(i).Ref_Corp_Assortment__c);
        }
    }
    
    static testmethod void case13_updateClientClusters_insert_single() {
        init();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        test.startTest();
        Assortment_Detail__c detail = TestDataFactory.createAssortmentDetail(true, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        test.stopTest();
        detail = [SELECT Client_Clust1__c, Client_Clust2__c, Client_Clust3__c, Client_Clust4__c, Client_Clust5__c, Client_Clust6__c
                  FROM Assortment_Detail__c WHERE Id = :detail.Id];
        System.assertEquals(true, detail.get('Client_Clust' + clusters.size() + '__c'));
        for (Integer i = clusters.size() - 1 ; i > 0; i--) {
            System.assertEquals(false, detail.get('Client_Clust' + i + '__c'));
        }
    }
    
    static testmethod void case14_updateClientClusters_insert_mass() {
        init();
        Integer nbProducts = 3;
        List<Product2> products = new List<Product2>();
        List<Assortment_Detail__c> details = new List<Assortment_Detail__c>();
        for (Integer i = 0; i < nbProducts; i++) {
            products.add(TestDataFactory.createProduct(false, section.Id, null));
        }
        insert products;
        for (Product2 product : products) {
            details.add(TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id));
        }
        test.startTest();
        insert details;
        test.stopTest();
        details = [SELECT Client_Clust1__c, Client_Clust2__c, Client_Clust3__c, Client_Clust4__c, Client_Clust5__c, Client_Clust6__c
                   FROM Assortment_Detail__c WHERE Id = :details];
        for (Assortment_Detail__c detail : details) {
            System.assertEquals(true, detail.get('Client_Clust' + clusters.size() + '__c'));
            for (Integer i = clusters.size() - 1 ; i > 0; i--) {
                System.assertEquals(false, detail.get('Client_Clust' + i + '__c'));
            }
        }
    }
    
    static testmethod void case15_updateClientClusters_update_single() {
        init();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        Assortment_Detail__c detail = TestDataFactory.createAssortmentDetail(true, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        test.startTest();
        detail.Ass_BU_Cluster__c = clusters[0].Id;
        update detail;
        test.stopTest();
        detail = [SELECT Client_Clust1__c, Client_Clust2__c, Client_Clust3__c, Client_Clust4__c, Client_Clust5__c, Client_Clust6__c
                  FROM Assortment_Detail__c WHERE Id = :detail.Id];
        for (Integer i = 1 ; i <= clusters.size(); i++) {
            System.assertEquals(true, detail.get('Client_Clust' + i + '__c'));
        }
    }
    
    static testmethod void case16_updateClientClusters_update_mass() {
        init();
        Integer nbProducts = 3;
        List<Product2> products = new List<Product2>();
        List<Assortment_Detail__c> details = new List<Assortment_Detail__c>();
        for (Integer i = 0; i < nbProducts; i++) {
            products.add(TestDataFactory.createProduct(false, section.Id, null));
        }
        insert products;
        for (Product2 product : products) {
            details.add(TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id));
        }
        insert details;
        test.startTest();
        for (Assortment_Detail__c detail : details) {
            detail.Ass_BU_Cluster__c = clusters[0].Id;
        }
        update details;
        test.stopTest();
        details = [SELECT Client_Clust1__c, Client_Clust2__c, Client_Clust3__c, Client_Clust4__c, Client_Clust5__c, Client_Clust6__c
                   FROM Assortment_Detail__c WHERE Id = :details];
        for (Assortment_Detail__c detail : details) {
            for (Integer i = 1 ; i <= clusters.size(); i++) {
                System.assertEquals(true, detail.get('Client_Clust' + i + '__c'));
            }
        }
    }
    
    static testmethod void case17_updateClientStatus_single_increase() {
        init();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        Assortment_Detail__c detail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        detail.Client_Status__c = 'Keep';
        detail.Status__c = 'Validated';
        insert detail;
        test.startTest();
        detail.Ass_BU_Cluster__c = clusters[0].Id;
        update detail;
        test.stopTest();
        detail = [SELECT Client_Status__c FROM Assortment_Detail__c WHERE Id = :detail.Id];
        System.assertEquals('Increase', detail.Client_Status__c);
    }
    
    static testmethod void case18_updateClientStatus_single_decrease() {
        init();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        Assortment_Detail__c detail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, clusters[0].Id);
        detail.Client_Status__c = 'Keep';
        detail.Status__c = 'Validated';
        insert detail;
        test.startTest();
        detail.Ass_BU_Cluster__c = clusters[1].Id;
        update detail;
        test.stopTest();
        detail = [SELECT Client_Status__c FROM Assortment_Detail__c WHERE Id = :detail.Id];
        System.assertEquals('Decrease', detail.Client_Status__c);
    }
    
    static testmethod void case19_updateClientStatus_single_delete() {
        init();
        Product2 product = TestDataFactory.createProduct(true, section.Id, null);
        Assortment_Detail__c detail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, clusters[clusters.size() - 1].Id);
        detail.Client_Status__c = 'Keep';
        detail.Status__c = 'Validated';
        insert detail;
        test.startTest();
        detail.Ass_BU_Cluster__c = null;
        update detail;
        test.stopTest();
        detail = [SELECT Client_Status__c FROM Assortment_Detail__c WHERE Id = :detail.Id];
        System.assertEquals('Delete', detail.Client_Status__c);
    }
    
    static testmethod void case20_updateClientStatus_mass() {
        init();
        Integer nbProducts = 3;
        List<Product2> products = new List<Product2>();
        Assortment_Detail__c detail1, detail2, detail3;
        List<Assortment_Detail__c> details = new List<Assortment_Detail__c>();
        for (Integer i = 0; i < nbProducts; i++) {
            products.add(TestDataFactory.createProduct(false, section.Id, null));
        }
        insert products;
        detail1 = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, products[0], clusters[clusters.size() - 1].Id);
        detail1.Client_Status__c = 'Keep';
        detail1.Status__c = 'Validated';
        details.add(detail1);
        detail2 = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, products[1], clusters[0].Id);
        detail2.Client_Status__c = 'Keep';
        detail2.Status__c = 'Validated';
        details.add(detail2);
        detail3 = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, products[2], clusters[0].Id);
        detail3.Client_Status__c = 'Keep';
        detail3.Status__c = 'Validated';
        details.add(detail3);        
        insert details;
        test.startTest();
        detail1.Ass_BU_Cluster__c = clusters[0].Id;
        detail2.Ass_BU_Cluster__c = clusters[1].Id;
        detail3.Ass_BU_Cluster__c = null;
        update details;
        test.stopTest();
        details = [SELECT Client_Status__c FROM Assortment_Detail__c WHERE Id = :details];
        for (Assortment_Detail__c detail : details) {
            if (detail.Id == detail1.Id) detail1 = detail;
            if (detail.Id == detail2.Id) detail2 = detail;
            if (detail.Id == detail3.Id) detail3 = detail;
        }
        System.assertEquals('Increase', detail1.Client_Status__c);
        System.assertEquals('Decrease', detail2.Client_Status__c);
        System.assertEquals('Delete', detail3.Client_Status__c);
    }
}