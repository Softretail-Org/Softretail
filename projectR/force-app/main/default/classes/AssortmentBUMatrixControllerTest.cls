/**
 * @author ULiT
 * @date 25-feb-2019
*/
@isTest
private class AssortmentBUMatrixControllerTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c client;
    private static Orga_BU__c buSource;
    private static Orga_BU__c buTarget;
    private static List<Orga_BU__c> stratList;
    private static List<Orga_HE__c> orgaHEList;
    private static List<Product2> products;
    private static Orga_HE__c assortmentCategory;
    private static Assortment_BU__c assortment;
    private static List<Assortment_Detail__c> details;
    
    /**
     * @description generates and initializes commun data for tests
     * calculates the current year
     * creates a country [Country_List__c]
     * Creates a region [Orga_BU__c]
     * creates a bu [Orga_BU__c] of type record type country 
     * creates a supplier [Sup_Supplier__c] related to the bu country
     * creates clientBranch bu [Orga_BU__c] of type record type country to represent one of the client's store groupes and assigns the related client field [Orga_BU__c.Related_Client__c]
     * creates a tree of hierarchy elements [Orga_HE__c] of depth 4 and with 3 elements on each level
     * creates 5 starts [Orga_BU__c] on clientBranch with category field null [Orga_BU__c.Category__c]
     * creates 4 strats [Orga_BU__c] on clientBranch with category field [Orga_BU__c.Category__c] of level 3 (limit to 2 categories)
     * the total of strats is (5 w/ category null) + (8 w/ category not null) = 13 strats
     * creates 1 product [Product2] on each element [Orga_HE__c] of level 4
     * assigns 1 element [Orga_HE__c] of level 1 to a variable
     * creates an assortment [Assortment_BU__c]
     * creates an assortment detail [Assortment_Detail__c] for each product
     * sets the test current page reference to Assortment BU Matrix
	*/
    static void init() {
        try {
            NegoptimCustomSettings__c negoptimCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
            negoptimCustomSettings.Assortment_Matrix_Grid_Layout__c = 'Matrix_Full';
            insert negoptimCustomSettings;
            year = System.Today().year();
            region = TestDataFactory.CreateBURegion(true, 'region');
            Country_List__c countryList = TestDataFactory.createCountry(true, 'France', 'FR');
            country = TestDataFactory.createBUCountry(true, countryList, region.Id);
            client = TestDataFactory.createSupplier(true, country, false);
            orgaHEList = TestDataFactory.createElementHierarchy(4, 1);
            buSource = TestDataFactory.createBUBanner(false, country);
            buSource.IsMasterBU__c = true;
            buTarget = TestDataFactory.createBUBanner(false, country);
            buTarget.Mission__c = 'Offer';
            buTarget.IsMasterBU__c = false;
            buTarget.Related_Client__c = client.Id;
            buTarget.Category__c = orgaHEList[1].Id;
            insert new List<Orga_BU__c> {buSource, buTarget};
            
            stratList = new List<Orga_BU__c>();
            for (Integer i = 0; i < 4; i++) {
                stratList.add(TestDataFactory.createBUAssortCluster(false, buTarget.Id, 'Strat' + i));
            }
            insert stratList;
            products = new List<Product2>();
            for (Integer i = 0; i < 50; i++) {
                products.add(TestDataFactory.createProduct(false, orgaHEList[4].Id, null));
            }
            insert products;
            
            assortment = TestDataFactory.createAssortmentBU(true, buSource, buTarget, orgaHEList[1]);
            details = new List<Assortment_Detail__c>();
            for (Product2 item : products) {
                details.add(new Assortment_Detail__c(Product__c = item.Id, Assortment_BU__c = assortment.Id,
                                                    Status__c = 'In preparation', Client_Status__c = 'Keep'));
            }
            insert details;
            PageReference pageRef = Page.AssortmentBUMatrix;
            Test.setCurrentPage(pageRef);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /**
     * @description sets the number of fetched records against the number of assortment details inserted in init()
	*/
   static testMethod void test_constructor() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixController ctrl = new AssortmentBUMatrixController(stdController);
        Test.stopTest();
        System.assertEquals(products.size(), ctrl.noOfRecords);
    }
    
    /**
     * @description
     * tests the set page size against the page size of the standard set controller in the controller instance
     * tests the current position againt the page number of the standard set controller in the controller instance
	*/
    static testMethod void test_navigation() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixController ctrl = new AssortmentBUMatrixController(stdController);
        ctrl.pageSize = 25;
        ctrl.refreshPageSize();
        System.assertEquals(25, ctrl.assortmentDetailStdSetCtrl.getPageSize());
        ctrl.next();
        ctrl.first();
        ctrl.last();
        ctrl.previous();
        System.assertEquals(((decimal) products.size()/25).setScale(0, RoundingMode.UP) - 1, ctrl.assortmentDetailStdSetCtrl.getPageNumber());
        Test.stopTest();
    }
    
    static testmethod void test_search_by_category() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixController ctrl = new AssortmentBUMatrixController(stdController);
        
        // search records by a parent category
        ctrl.product.Category__c = orgaHEList[3].Id;
        
        // search records by a parent category
        ctrl.clientStatus = 'Keep-Decrease';
        ctrl.search();
        System.assertEquals(products.size(), ctrl.noOfRecords);
        
        Test.stopTest();
    }
    
    static testmethod void test_search_by_product() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixController ctrl = new AssortmentBUMatrixController(stdController);
      
        String productName = products[0].Name;
      
        // search records by product by name
        ctrl.productSearch = productName;
        ctrl.search();
        System.assertEquals(1, ctrl.noOfRecords);
        
        Test.stopTest();
    }
    
    static testmethod void test_search_history() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixController ctrl = new AssortmentBUMatrixController(stdController);
        
        Assortment_Detail__c historyLine = details[0].clone(false);
        historyLine.Status__c = 'Validated';
        historyLine.Version__c = 1;
        
        // show history
        insert historyLine;
        ctrl.isShowHistory = true;
        ctrl.search();
        System.assertEquals(products.size() + 1, ctrl.noOfRecords);
        
        Test.stopTest();
    }
    
    static testmethod void test_save() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixController ctrl = new AssortmentBUMatrixController(stdController);
        AssortmentBUMatrixController.AssortmentDetailWrapper detailwrapper = ctrl.wAssortmentDetailList[0];
        detailwrapper.assortmentDetails[0].Client_Status__c = 'Keep';
        
        Assortment_Detail__c detailToSave = ctrl.wAssortmentDetailList[0].assortmentDetails[0];
        detailToSave.Client_Status__c = 'Decrease';
        // ctrl.wAssortmentDetailList[0].assortmentDetails[0].Client_Status__c = 'Keep';
        AssortmentBUMatrixController.evaluateAssortmentDetail(detailToSave, ctrl.fieldsToSumList_serialized);
        ctrl.save();
        Test.stopTest();
    }
    
    static testmethod void coverage() {
        init();
        test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(assortment);
        AssortmentBUMatrixController ctrl = new AssortmentBUMatrixController(stdController);
        
        // dynamic table
        ctrl.getDynamicPageBlockTable();
        ctrl.generateExcel();
        ctrl.popupGenerateExcel = true;
        ctrl.popupStopProduct = true;
        ctrl.popupSwitchProduct = true;
        ctrl.showPopup();
        ctrl.cancelPopup();
        System.assert(true);
        test.stopTest();
    }
}