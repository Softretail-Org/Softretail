@isTest
private class AssortmentBUProductSelectionControllerT {

    static List<Sup_Brand__c> brands;
    static List<Orga_HE__c> categories;
    static List<Product2> products;
    static Assortment_BU__c assortmentBU;
    static List<Assortment_Detail__c> assortmentDetails;
    // Level 1
    static Orga_HE__c chocolate ;
    static Orga_HE__c poudre ;
    static Orga_HE__c bonbon;
    // Level 2
    static Orga_HE__c poulin;
    static Orga_HE__c suchard;
    static Orga_HE__c kaba;
    static Orga_HE__c benco;
    static Orga_HE__c carambar;
    static Orga_HE__c malabar;
    // Apex Page
    static ApexPages.StandardController stdController;
    static AssortmentBUProductSelectionController controller;
    
    static void init() {
        // Supplier initialization
        Sup_Supplier__c supplier = new Sup_Supplier__c (name = 'TestSupplier', code__c = 'testSupplier123');
        insert supplier;
        // Brands initialization
        brands = new List<Sup_Brand__c>();
        brands.add(new Sup_Brand__c(name = 'testBrand1', Brand_code__c = 'testBrand1', Brand_Owner__c = supplier.Id));
        brands.add(new Sup_Brand__c(name = 'testBrand2', Brand_code__c = 'testBrand2', Brand_Owner__c = supplier.Id));
        insert brands;
        // Orga_HE__c initialization
        Id rootId = NegoptimHelper.getRootId();
        // Level 1
        chocolate = new Orga_HE__c(name = 'testChocolate', Elt_Code__c = '11', Level__c = 1, Parent_Element__c = rootId, path__c = '0|11');
        poudre = new Orga_HE__c(name = 'testPoudre', Elt_Code__c = '12', Level__c = 1, Parent_Element__c = rootId, path__c = '0|12');
        bonbon = new Orga_HE__c(name = 'testBonbon', Elt_Code__c = '13', Level__c = 1, Parent_Element__c = rootId, path__c = '0|13');
        insert new List<Orga_HE__c> {chocolate, poudre, bonbon};
        // Level 2
        poulin = TestDataFactory.createSection(false, chocolate.Id);
        poulin.Name = 'testPoulin';
        poulin.Elt_Code__c = '111';
        suchard = TestDataFactory.createSection(false, chocolate.Id);
        suchard.Name = 'testSuchard';
        suchard.Elt_Code__c = '112';
        kaba = TestDataFactory.createSection(false, chocolate.Id);
        kaba.Name = 'testKaba';
        kaba.Elt_Code__c = '121';
        benco = TestDataFactory.createSection(false, chocolate.Id);
        benco.Name = 'testBenco';
        benco.Elt_Code__c = '122';
        carambar = TestDataFactory.createSection(false, poudre.Id);
        carambar.Name = 'testCarambar';
        carambar.Elt_Code__c = '131';
        malabar = TestDataFactory.createSection(false, bonbon.Id);
        malabar.Name = 'testMalabar';
        malabar.Elt_Code__c = '132';
        insert new List<Orga_HE__c> {poulin, suchard, kaba, benco, carambar, malabar};
        // Product initialization
        products = new List<Product2>();
        for(Orga_HE__c category : new List<Orga_HE__c> {poulin, suchard, kaba, benco, carambar, malabar}){
            for(Integer i = 0; i < 5; i++) {
                Product2 product1 = TestDataFactory.createProduct(false, category.Id, null);
                product1.Brand__c = brands.get(0).Id;
                Product2 product2 = TestDataFactory.createProduct(false, category.Id, null);
                product2.Name = product2.Name + 'b2';
                product2.Brand__c = brands.get(1).Id;
                products.add(product1);
                products.add(product2);
            }
        }
        insert products;
        // create Orga_BUs
        Country_List__c countryList = TestDataFactory.createCountry(true, 'Lebanon', 'LBN');
        Orga_BU__c region = TestDataFactory.createBURegion(true, 'Region');
        Orga_BU__c country = TestDataFactory.createBUCountry(true, countryList, region.Id);
        Orga_BU__c buSource = TestDataFactory.createBUBanner(false, country);
        buSource.IsMasterBU__c = true;
        orga_BU__c buTarget = TestDataFactory.createBUBanner(false, country);
        buTarget.Mission__c = 'Offer';
        buTarget.IsMasterBU__c = false;
        buTarget.Related_Client__c = supplier.Id;
        insert new List<Orga_BU__c>{buSource, buTarget};
        assortmentBU = TestDataFactory.createAssortmentBU(true, buSource, buTarget, chocolate);
        assortmentBU = [SELECT id, Orga_HE__c, Orga_HE__r.Elt_code__c, Orga_HE__r.Level__c, Orga_HE__r.Path__c
                        FROM Assortment_BU__c
                        WHERE Id = :assortmentBU.Id];
        ApexPages.currentPage().getParameters().put('id', assortmentBU.Id);
        stdController = new ApexPages.StandardController(assortmentBU);
        controller = new AssortmentBUProductSelectionController(stdController);
    }
    @isTest 
    static void case1_Constructor() {
        init();
        System.assertEquals(assortmentBU.Id, stdController.getRecord().Id);
    }
    @isTest 
    static void case2_getProductRecords() {
        init();
        controller.pageSize = 100;
        controller.productStdSetCtrl.setpageSize(100);
        List<AssortmentBUProductSelectionController.ProductWrapper> wrapperList = controller.getProductRecords();
        System.assertEquals(40, wrapperList.size());
        controller.pageSize = 10;
        controller.productStdSetCtrl.setpageSize(10);
        wrapperList = controller.getProductRecords();
        System.assertEquals(10, wrapperList.size());
    }
    @isTest 
    static void case3_searchString() {
        init();
        controller.pageSize = 100;
        controller.productStdSetCtrl.setpageSize(100);
        controller.searchString = 'b2';
        controller.searchProducts();
        List<AssortmentBUProductSelectionController.ProductWrapper> wrapperList = controller.getProductRecords();
        System.assertEquals(20, wrapperList.size());
    }
    @isTest 
    static void case4_SearchBrandLookup() {
        init();
        controller.pageSize = 100;
        controller.productStdSetCtrl.setpageSize(100);
        controller.brandLookup.label = 'testBrand1';
        controller.searchProducts();
        List<AssortmentBUProductSelectionController.ProductWrapper> wrapperList = controller.getProductRecords();
        System.assertEquals(20, wrapperList.size());
        controller.brandLookup.label = 'testBrand2';
        controller.searchProducts();
        wrapperList = controller.getProductRecords();
        System.assertEquals(20, wrapperList.size());
        controller.brandLookup.label = 'testBrand';
        controller.searchProducts();
        wrapperList = controller.getProductRecords();
        System.assertEquals(40, wrapperList.size());
        controller.brandLookup.label = '123';
        controller.searchProducts();
        wrapperList = controller.getProductRecords();
        System.assertEquals(0, wrapperList.size());
        
        controller.brandLookup.value = brands.get(0).Id;
        controller.searchProducts();
        wrapperList = controller.getProductRecords();
        System.assertEquals(20, wrapperList.size());
        controller.brandLookup.value = brands.get(1).Id;
        controller.searchProducts();
        wrapperList = controller.getProductRecords();
        System.assertEquals(20, wrapperList.size());
    } 
    @isTest 
    static void case5_SearchCategoryLookup() {
        init();
        controller.pageSize = 100;
        controller.productStdSetCtrl.setpageSize(100);
        controller.categoryLookup.label = 'testChocolate';
        controller.searchProducts();
        List<AssortmentBUProductSelectionController.ProductWrapper> wrapperList = controller.getProductRecords();
        System.assertEquals(40, wrapperList.size());
        
        controller.categoryLookup.value = chocolate.Id;
        controller.searchProducts();
        wrapperList = controller.getProductRecords();
        System.assertEquals(40, wrapperList.size());
        controller.categoryLookup.value = poulin.Id;
        controller.searchProducts();
        wrapperList = controller.getProductRecords();
        System.assertEquals(10, wrapperList.size());
    } 
    @isTest 
    static void case6_Importall() {
        init();
        controller.importAll(); 
        List<Product2> chocolateProductsList = [SELECT id, Name
                                                FROM Product2
                                                Where category__r.Path__c LIKE '%|11|%'];
        List<String> importedList = new List<String>();
        for (Assortment_Detail__c assortmentDetail : [SELECT Product__r.name
                                                      FROM Assortment_Detail__c
                                                      WHERE Assortment_BU__c = :assortmentBU.Id])
            importedList.add(assortmentDetail.Product__r.name);
        System.assertEquals(40, importedList.size());
        for(Product2 prod : chocolateProductsList)
            System.assert(importedList.contains(prod.name));
    }
    @isTest 
    static void case7_ImportSelected() {
        init();
        controller.pageSize = 100;
        controller.productStdSetCtrl.setpageSize(100);
        List<AssortmentBUProductSelectionController.ProductWrapper> wrapperList = controller.getProductRecords();
        List<String> selectedProductsNames = new List<String>();
        for(Integer i = 10; i< 35; i++){
            wrapperList.get(i).isSelected = true;
            selectedProductsNames.add(wrapperList.get(i).product.Name);
        }
        controller.importSelected(); 
        List<String> importedList = new List<String>();
        for (Assortment_Detail__c assortmentDetail : [SELECT Product__r.name
                                                      FROM Assortment_Detail__c
                                                      WHERE Assortment_BU__c = : assortmentBU.Id])
            importedList.add(assortmentDetail.Product__r.name);
        System.assertEquals(selectedProductsNames.size(), importedList.size());
        for(String productName : selectedProductsNames)
            System.assert(importedList.contains(productName));
    }
}