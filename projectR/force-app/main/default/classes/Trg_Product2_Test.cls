@isTest
private with sharing class Trg_Product2_Test {
    
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c buSource;
    private static Orga_BU__c buTarget;
    private static Sup_Supplier__c supplier;
    private static Product2 product1;
    private static Product2 product2;
    private static Orga_HE__c department1;
    private static Orga_HE__c section1;
    private static Orga_HE__c department2;
    private static Orga_HE__c section2;
    private static Supplier_PG_Mapping__c PG1;
    private static Supplier_PG_Mapping__c PG2;
    private static Purchases_Flow_PG__c purchase1;
    private static Purchases_Flow_PG__c purchase2;
    private static Assortment_BU__c assortmentBU;
    private static Assortment_Detail__c detail1;
    private static Assortment_Detail__c detail2;
    
    static void init() {
        try {         
            // Get Root Element Id.
            Id rootId = NegoptimHelper.getRootId();
            // Insert Country.
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Insert Region.
            region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Insert Country.
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Insert supplier.
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];   
            // Create Departments & Sections.
            department1 = TestDataFactory.createDepartment(true, rootId);
            section1 = TestDataFactory.createSection(true, department1.Id);
            department2 = TestDataFactory.createDepartment(true, rootId);
            section2 = TestDataFactory.createSection(true, department2.Id);
            // Create Master BU
            buSource = TestDataFactory.createBUBanner(false, country);
            buSource.Mission__c = 'Nielsen;Offer';
            buSource.Format_Origin__c = 'Hypermarket;Supermarket;Drive';
            buSource.Related_Client__c = supplier.Id;
            buSource.IsMasterBU__c = true;
            buSource.SiteOfSales_Number__c = 100;
            // Create BU Target
            buTarget = TestDataFactory.createBUBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.Format_Origin__c = 'Hypermarket;Supermarket;';
            buTarget.Related_Client__c = supplier.Id;
            buTarget.Category__c = department2.Id;
            insert new List<Orga_BU__c>{buSource,buTarget};
            // Create Products.
            product1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
            product2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
            insert new List<Product2>{product1, product2};
	        // Create PGs.
            PG1 = TestDataFactory.createPG(false, supplier.Id, department1.Id, section1.Id);
            PG1.Product__c = product1.Id;
			PG2 = TestDataFactory.createPG(false, supplier.Id, department2.Id, section2.Id);
            PG2.Product__c = product2.Id;
            insert new List<Supplier_PG_Mapping__c>{PG1, PG2};
            // Create Purchases
            purchase1 = TestDataFactory.createPurchase(false, PG1, country.Id);
            purchase1.Department__c = PG1.Department__c;
            purchase1.Section__c = PG1.Section__c;
            purchase2 = TestDataFactory.createPurchase(false, PG2, country.Id);
            purchase2.Department__c = PG2.Department__c;
            purchase2.Section__c = PG2.Section__c;
            insert new List<Purchases_Flow_PG__c>{purchase1, purchase2};
            //Create Assortment BU.
            assortmentBU = TestDataFactory.createAssortmentBU(false, buSource, buTarget, department2);
            assortmentBU.Status__c = 'Validated';
            insert assortmentBU;
            //Create Assorment BU Details.
            detail1 = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product1, null);
            detail2 = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product2, null);
            insert new List<Assortment_Detail__c>{detail1,detail2};
        
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testMethod void before_update_single() {
        init();
        product1.Category__c = section2.Id;
        // Start test.
        Test.startTest();
        update product1;
        Test.stopTest();
        // Get Data
        Supplier_PG_Mapping__c PG1 = [SELECT Section__c, Department__c FROM Supplier_PG_Mapping__c WHERE Id = :PG1.Id];
        Purchases_Flow_PG__c purchase1 = [SELECT Section__c, Department__c FROM Purchases_Flow_PG__c WHERE Id = :purchase1.Id];
        // Assertions
        // the department and section of PGs related to the product have changed
        System.assertEquals(section2.Id, PG1.Section__c);
        System.assertEquals(department2.Id, PG1.Department__c);
        // the department and section of Purchases related to the PGs have changed
        System.assertEquals(section2.Id, purchase1.Section__c);
        System.assertEquals(department2.Id, purchase1.Department__c);
    }
    
    static testMethod void before_update_multiple() {
        init();
        product1.Category__c = section2.Id;
        product2.Category__c = section1.Id;
        // Start test.
        Test.startTest();
        update new List<Product2>{product1, product2};
        Test.stopTest();
        // Get Data
        Map<Id, Supplier_PG_Mapping__c> PGs = new Map<Id, Supplier_PG_Mapping__c>([SELECT Section__c, Department__c FROM Supplier_PG_Mapping__c]);
        Map<Id, Purchases_Flow_PG__c> purchases = new Map<Id, Purchases_Flow_PG__c>([SELECT Section__c, Department__c FROM Purchases_Flow_PG__c]);
        // Assertions
        // the department and section of PGs related to the product have changed       
        System.assertEquals(section2.Id, PGs.get(PG1.Id).Section__c);
        System.assertEquals(department2.Id, PGs.get(PG1.Id).Department__c);
        System.assertEquals(section1.Id, PGs.get(PG2.Id).Section__c);
        System.assertEquals(department1.Id, PGs.get(PG2.Id).Department__c);
        // the department and section of Purchases related to the PGs have changed
        System.assertEquals(section2.Id, purchases.get(purchase1.Id).Section__c);
        System.assertEquals(department2.Id, purchases.get(purchase1.Id).Department__c);
        System.assertEquals(section1.Id, purchases.get(purchase2.Id).Section__c);
        System.assertEquals(department1.Id, purchases.get(purchase2.Id).Department__c);
    }
    
    static testMethod void after_insert_single() {
        init();
        Product2 newProduct = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        newProduct.Reference_Product__c = product1.Id;
        // Start test.
        Test.startTest();
        insert newProduct;
        Test.stopTest();
        // Get Data
        Integer productHistoryCount = [SELECT COUNT() FROM Product_Assortment_Introduction_History__c];
        Product_Assortment_Introduction_History__c productHisto1 = [SELECT Product__c, BU_Target__c, Client__c
                                                                    FROM Product_Assortment_Introduction_History__c WHERE Product__c = :product1.Id];
        product1 = [SELECT Product_Reference_Type__c FROM Product2 WHERE Id = :product1.Id];
        // Assertions
        // Product_Assortment_Introduction_History__c created
        System.assertEquals(productHistoryCount, 3);
        System.assertEquals(productHisto1.BU_Target__c, buTarget.Id);
        System.assertEquals(productHisto1.Client__c, supplier.Id);
        System.assertEquals(product1.Product_Reference_Type__c, 'Switch');
        System.assertEquals(product1.Product_Reference_Type__c, 'Switch');
    }
    
    static testMethod void after_insert_multiple() {
        init();
        Product2 newProduct1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        Product2 newProduct2 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        newProduct1.Reference_Product__c = product1.Id;
        newProduct2.Reference_Product__c = product2.Id;
        // Start test.
        Test.startTest();
        insert new List<Product2> {newProduct1, newProduct2};
        Test.stopTest();
        // Get Data
        List<Product_Assortment_Introduction_History__c> productIntroHistoryList = [SELECT Product__c, BU_Target__c, Client__c
                                                                                    FROM Product_Assortment_Introduction_History__c];
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Product_Reference_Type__c FROM Product2]);
        // Assertions
        // Product_Assortment_Introduction_History__c created
        System.assertEquals(productIntroHistoryList.size(), 4);
        System.assertEquals(productIntroHistoryList[0].BU_Target__c, buTarget.Id);
        System.assertEquals(productIntroHistoryList[0].Client__c, supplier.Id);
        System.assertEquals(productIntroHistoryList[1].BU_Target__c, buTarget.Id);
        System.assertEquals(productIntroHistoryList[1].Client__c, supplier.Id);
        // reference product Product_Reference_Type__c field set to switch
        System.assertEquals('Switch', products.get(product1.Id).Product_Reference_Type__c);
        System.assertEquals('Switch', products.get(product2.Id).Product_Reference_Type__c);
    }
    
    /*
     * referencing a product
     **/
    static testMethod void after_update_single_case1() {
        init();
        product1.Reference_Product__c = product2.Id;
        test.startTest();
        update product1;
        test.stopTest();
        Product2 product2 = [SELECT Product_Reference_Type__c FROM Product2 WHERE Id = :product2.Id];
        System.assertEquals('Switch', product2.Product_Reference_Type__c);
    }
    
    /*
     * unreferencing a product
     **/
    static testMethod void after_update_single_case2() {
        init();
        product1.Reference_Product__c = product2.Id;
        update product1;
        product1.Reference_Product__c = null;
        test.startTest();
        update product1;
        test.stopTest();
        Product2 product2 = [SELECT Product_Reference_Type__c FROM Product2 WHERE Id = :product2.Id];
        System.assertEquals(null, product2.Product_Reference_Type__c);
    }
    
    /*
     * referencing a product
     **/
    static testMethod void after_update_multiple_case1() {
        init();
        Product2 newProduct1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        Product2 newProduct2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
        List<Product2> productList = new List<Product2> {newProduct1, newProduct2};
        insert productList;
        test.startTest();
        newProduct1.Reference_Product__c = product1.Id;
        newProduct2.Reference_Product__c = product2.Id;
        update productList;
        test.stopTest();
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Product_Reference_Type__c FROM Product2]);
        System.assertEquals('Switch', products.get(product1.Id).Product_Reference_Type__c);
        System.assertEquals('Switch', products.get(product2.Id).Product_Reference_Type__c);
    }
    
    /*
     * unreferencing a product
     **/
    static testMethod void after_update_multiple_case2() {
        init();
        Product2 newProduct1 = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        Product2 newProduct2 = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
        newProduct1.Reference_Product__c = product1.Id;
        newProduct2.Reference_Product__c = product2.Id;
        List<Product2> productList = new List<Product2> {newProduct1, newProduct2};
        insert productList;
        newProduct1.Reference_Product__c = null;
        newProduct2.Reference_Product__c = null;    
        test.startTest();
        update productList;
        test.stopTest();
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Product_Reference_Type__c FROM Product2]);
        System.assertEquals(null, products.get(product1.Id).Product_Reference_Type__c);
        System.assertEquals(null, products.get(product2.Id).Product_Reference_Type__c);
    }
    
    /**
     * referencing an already reference product
	*/
    static testMethod void after_update_case3 () {
        init();
        product2.Product_Reference_Type__c = 'Switch';
        update product2;
        product1.Reference_Product__c = product2.Id;
        Boolean assertion = false;
        Test.startTest();
        try {
            update product1;
        } catch (DMLException ex) {
            // TODO add condition on error message when message is finilized in trigger
            //// if (ex.getMessage().equals('Invalid Reference Product'))
            assertion = true;
        }
        Test.stopTest();
        System.assert(assertion);
    }
    
    static testMethod void test_after_delete() {
        init();
        // Create Countries with related clients
        Product2 product_a = TestDataFactory.createProduct(false, section1.Id, supplier.Id);
        Product2 product_b = TestDataFactory.createProduct(false, section2.Id, supplier.Id);
        List<Product2> productsList = new List<Product2>{product_a, product_b};
        insert productsList;
        // checking history count before delete
        Integer historyCount = [SELECT Count() FROM Product_Assortment_Introduction_History__c WHERE Product__c IN :productsList];
        System.assertEquals(2, historyCount);
        // Test
        Test.startTest();
        delete productsList;
        Test.stopTest();
        // Get data
        historyCount = [SELECT Count() FROM Product_Assortment_Introduction_History__c WHERE Product__c IN :productsList];
        System.assertEquals(0, historyCount);
    }
    @isTest
    static void delete_Product2_single_with_commercial_plan_detail() {
        init();
		Commercial_Plan__c cp=new Commercial_Plan__c();
		cp.Name='event '+Math.random()*999;
        cp.RecordTypeId=NegoptimHelper.getObjectRecordTypeMapIds(Commercial_Plan__c.sObjectType).get('Sales_Floor_Event');
        cp.Start_Date__c=Date.today();
        cp.End_Date__c=Date.today().addDays(30);
        cp.BU_Source__c=region.Id;
        cp.BU_Target__c=country.Id;
        insert cp;
        Commercial_Plan_Detail__c cpd=new Commercial_Plan_Detail__c();
		cpd.Commercial_Event__c=cp.Id;
        cpd.Edition_Date__c=Date.today();
        cpd.Contribution_Unit_Quantity__c=Math.random()*99;
        cpd.Contribution_Unit_Amount__c=Math.random()*99;
        cpd.Product__c=product1.Id;
        insert cpd;
        Test.startTest();
        Database.DeleteResult result = Database.delete(product1, false);
        Test.stopTest();
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, result.getErrors()[0]);
    }
    @isTest
    static void delete_Product2_multiple_with_commercial_plan_detail() {
        init();
        Commercial_Plan__c cp=new Commercial_Plan__c();
		cp.Name='event '+Math.random()*999;
        cp.RecordTypeId=NegoptimHelper.getObjectRecordTypeMapIds(Commercial_Plan__c.sObjectType).get('Sales_Floor_Event');
        cp.Start_Date__c=Date.today();
        cp.End_Date__c=Date.today().addDays(30);
        cp.BU_Source__c=region.Id;
        cp.BU_Target__c=country.Id;
        insert cp;
        Commercial_Plan_Detail__c cpd=new Commercial_Plan_Detail__c();
		cpd.Commercial_Event__c=cp.Id;
        cpd.Edition_Date__c=Date.today();
        cpd.Contribution_Unit_Quantity__c=Math.random()*99;
        cpd.Contribution_Unit_Amount__c=Math.random()*99;
        cpd.Product__c=product1.Id;
        insert cpd;
        cpd=new Commercial_Plan_Detail__c();
		cpd.Commercial_Event__c=cp.Id;
        cpd.Edition_Date__c=Date.today();
        cpd.Contribution_Unit_Quantity__c=Math.random()*99;
        cpd.Contribution_Unit_Amount__c=Math.random()*99;
        cpd.Product__c=product2.Id;
        insert cpd;
        
        Test.startTest();
        List<Database.DeleteResult> lsresult = Database.delete(new List<Product2>{product1,product2}, false);
        Test.stopTest();
        for (Database.DeleteResult result : lsresult) {
            System.assertNotEquals(null, result.getErrors()[0]);
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        }
    }
    
    @isTest
    static void delete_Product2_single_with_assortment_detail() {
        init();        
        Test.startTest();
        Database.DeleteResult result = Database.delete(product1, false);
        Test.stopTest();
        System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        System.assertNotEquals(null, result.getErrors()[0]);
    }
    @isTest
    static void delete_Product2_multiple_with_assortment_detail() {
        init();
        Test.startTest();
        List<Database.DeleteResult> lsresult = Database.delete(new List<Product2>{product1,product2}, false);
        Test.stopTest();
        for (Database.DeleteResult result : lsresult) {
            System.assertNotEquals(null, result.getErrors()[0]);
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, result.getErrors()[0].getStatusCode());
        }
    }
}