@isTest
private class AssortmentBudgetSimulationControllerTest {

    static Integer year;
    static Orga_BU__c buCountry;
    static List <Sup_Supplier__c> clientList;
    static Orga_BU__c mainBU;
    static Orga_BU__c channel;
    static List <Orga_BU__c> banners;
    static List <Orga_HE__c> heList;
    static List <Product2> productList;
    static List <Assortment_BU__c> histoAssortmentList;
    static List <Assortment_Detail__c> histoDetailList;
    static Assortment_BU__c assortmentBudget;
    static Map <String, Id> Product2recordTypes;
    
    static void init() {
        Product2recordTypes = NegoptimHelper.getObjectRecordTypeMapIds(Product2.sObjectType);
        // Create Global Settings
        NegoptimCustomSettings__c negoSettings = TestDataFactory.createNegoptimCustomSettings(true);
        //
        year = Date.today().year();
        Country_List__c country = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        Orga_BU__c region = TestDataFactory.createBURegion(true, 'region');
        buCountry = TestDataFactory.createBUCountry(true, country, region.Id);
        // create 4 clients
        clientList = new List <Sup_Supplier__c> ();
        for (Integer i = 0; i < 4; i++) {
            clientList.add(TestDataFactory.createSupplier(false, buCountry, false));
        }
        insert clientList;
        List <Orga_BU__c> buList = new List <Orga_BU__c> ();
        // create mainBU
        mainBU = TestDataFactory.createBUCountry(false, country, region.Id);
        mainBU.BU_Code__c = 'MAIN';
        mainBU.IsMasterBU__c = true;
        buList.add(mainBU);
        // create channel BU
        channel = TestDataFactory.createBUBanner(false, mainBU);
        channel.IsMasterBU__c = true;
        buList.add(channel);
        // create clients banners
        banners = new List <Orga_BU__c> ();
        for (Sup_Supplier__c supplier: clientList) {
            Orga_BU__c banner = TestDataFactory.createBUBanner(false, buCountry);
            banner.Name += supplier.Name;
            banner.Related_Client__c = supplier.Id;
            banner.Mission__c = 'Offer';
            banner.Layer_Budget_Display__c = true;
            banners.add(banner);
        }
        buList.addAll(banners);
        insert buList;
        heList = TestDataFactory.createElementHierarchy(4, 1);
        // create 26 products on level 4 he
        productList = new List <Product2> ();
        for (Orga_HE__c he: heList) {
            if (he.Level__c == 4) {
                for (Integer i = 0; i < 5; i++) {
                    Product2 product = TestDataFactory.createProduct(false, he.Id, null);
                    product.RecordTypeId = Product2recordTypes.get('Product');
                    product.IsActive = true;
                    productList.add(product);
                }
            }
        }
        insert productList;
        // histo assortments
        Integer i = 1;
        histoAssortmentList = new List <Assortment_BU__c> ();
        for (Orga_BU__c banner: banners) {
            Assortment_BU__c assortmentNego = TestDataFactory.createAssortmentBU(false, channel, banner, heList[1]);
            assortmentNego.Name = banner.Name + i;
            assortmentNego.Assortment_Type__c = 'Out';
            assortmentNego.Assortment__c = 'Deal';
            assortmentNego.Status__c = 'Validated';
            assortmentNego.RecordTypeId = TestDataFactory.assortmentRTIds.get('Nego');
            histoAssortmentList.add(assortmentNego);
            i++;
        }
        insert histoAssortmentList;
        // create histoAssortmentDetails
        histoDetailList = new List <Assortment_Detail__c> ();
        for (Assortment_BU__c assortment: histoAssortmentList) {
            for (Product2 product: productList) {
                Assortment_Detail__c ad = TestDataFactory.createAssortmentDetail(false, assortment.Id, product, null);
                ad.Status__c = 'Validated';
                histoDetailList.add(ad);
            }
        }
        insert histoDetailList;
        // create budget Assortment
        assortmentBudget = TestDataFactory.createAssortmentBU(false, mainBU, channel, heList[1]);
        assortmentBudget.Name = 'BUDGET-' + (year + 1);
        assortmentBudget.Assortment_Type__c = 'In';
        assortmentBudget.Assortment__c = 'Simul';
        assortmentBudget.Ass_BDate__c = Date.newInstance(year + 1, 1, 1);
        assortmentBudget.Ass_EDate__C = Date.newInstance(year + 1, 12, 31);
        assortmentBudget.Year__c = year + 1;
        assortmentBudget.RecordTypeId = TestDataFactory.assortmentRTIds.get('Budget');
        insert assortmentBudget;
        // fetch fields for assortmentBudget
        assortmentBudget = [SELECT Assortment_type__c, BU_source__c, BU_source__r.BU_Code__c, BU_Target__c, Orga_HE__c, Long_Name__c,
            BU_Target__r.Format_Origin__c, Orga_HE__r.Path__c, Orga_HE__r.Name, Year__c, Ass_BDate__c, Ass_EDate__c, Status__c
            FROM Assortment_BU__c WHERE Id =: assortmentBudget.Id
        ];

        PageReference pageRef = Page.AssortmentBudgetSimulation;
        Test.setCurrentPage(pageRef);
    }

    static testmethod void case1_constructorAndSearch() {
        init();
        Product2 introProduct = TestDataFactory.createProduct(false, heList[4].Id, null);
        introProduct.Market_Introduction_Date__c = Date.newInstance((year + 1), 2, 3);
        introProduct.IsActive = true;
        insert introProduct;
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortmentBudget);
        AssortmentBudgetSimulationController ctrl = new AssortmentBudgetSimulationController(stdController);
        ctrl.searchTerm = productList.get(0).Name;
        ctrl.search();
        System.assertEquals(1, ctrl.noOfRecords);
        ctrl.searchTerm = 'searchterm';
        ctrl.search();
        System.assertEquals(0, ctrl.noOfRecords);
        ctrl.validate();
        ctrl.save();
        Test.stopTest();
    }

    static testmethod void case2_pagination() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortmentBudget);
        AssortmentBudgetSimulationController ctrl = new AssortmentBudgetSimulationController(stdController);
        ctrl.pageSize = 2;
        ctrl.refreshPageSize();
        ctrl.last();
        ctrl.first();
        ctrl.last();
        ctrl.next();
        ctrl.previous();
        Test.stopTest();
        System.assert(true);

    }

    static testmethod void case3_requestForApproval() {
        init();
        histoDetailList = [SELECT Product__c, Assortment_BU__r.BU_Target__c FROM Assortment_Detail__c WHERE Id IN :histoDetailList];
        List <Assortment_Detail__c> budgetAssortmentDetailList = new List <Assortment_Detail__c> ();
        for (Product2 item: productList) {
            Assortment_Detail__c asd = new Assortment_Detail__c();
            asd.Assortment_BU__c = assortmentBudget.Id;
            asd.Product__c = item.Id;
            budgetAssortmentDetailList.add(asd);
        }
        insert budgetAssortmentDetailList;
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortmentBudget);
        AssortmentBudgetSimulationController ctrl = new AssortmentBudgetSimulationController(stdController);
        ctrl.requestForApproval();
        Test.stopTest();
        List <Assortment_BU__c> targetAssortmentBUList = [SELECT Id, BU_Target__c, Assortment_Parent_Objective__c, Assortment_parent__c
                                                          FROM Assortment_BU__c 
                                                          WHERE RecordType.DeveloperName = 'Target'];
        List<Assortment_Detail__c> targetDetailList = [SELECT Id, Product__c, Assortment_BU__r.BU_Target__c, Ref_Client_Assortment__c, Ref_Corp_Assortment__c
                                                       FROM Assortment_Detail__c
                                                       WHERE Assortment_BU__c IN :targetAssortmentBUList];
        
        Map<Id, Assortment_BU__c> histoAssortmentByBUMap = new Map<Id, Assortment_BU__c>();
        Map<Id, Assortment_BU__c> targetAssortmentByBUMap = new Map<Id, Assortment_BU__c>();
        Map<String, Assortment_Detail__c> histoDetailsbyBU_ProductMap = new Map<String, Assortment_Detail__c>();
        Map<String, Assortment_Detail__c> targetDetailsbyBU_ProductMap = new Map<String, Assortment_Detail__c>();
        Map<Id, Assortment_Detail__c> budgetDetailsbyProductMap = new Map<Id, Assortment_Detail__c>();
        
        for (Assortment_BU__c item : histoAssortmentList) {
            histoAssortmentByBUMap.put(item.BU_Target__c, item);
        }
        for (Assortment_BU__c item : targetAssortmentBUList) {
            targetAssortmentByBUMap.put(item.BU_Target__c, item);
        }
        for (Assortment_Detail__c item : histoDetailList) {
            histoDetailsbyBU_ProductMap.put(item.Assortment_BU__r.BU_Target__c + '' + item.Product__c, item);
        }
        for (Assortment_Detail__c item : targetDetailList) {
            targetDetailsbyBU_ProductMap.put(item.Assortment_BU__r.BU_Target__c + '' + item.Product__c, item);
        }
        for (Assortment_Detail__c item : budgetAssortmentDetailList) {
            budgetDetailsbyProductMap.put(item.Product__c, item);
        }
        System.assertEquals(histoAssortmentList.size(), targetAssortmentBUList.size());
        for (Id key : targetAssortmentByBUMap.keySet()) {
            System.assertEquals(histoAssortmentByBUMap.get(key).Id, targetAssortmentByBUMap.get(key).Assortment_parent__c);
            System.assertEquals(assortmentBudget.Id, targetAssortmentByBUMap.get(key).Assortment_Parent_Objective__c);
        }
        for (String key : targetDetailsbyBU_ProductMap.keySet()) {
            System.assertEquals(histoDetailsbyBU_ProductMap.get(key).Id, targetDetailsbyBU_ProductMap.get(key).Ref_Client_Assortment__c);
            Id productId = targetDetailsbyBU_ProductMap.get(key).Product__c;
            System.assertEquals(budgetDetailsbyProductMap.get(productId).Id, targetDetailsbyBU_ProductMap.get(key).Ref_Corp_Assortment__c);
        }
    }
}