@isTest
private class UnitNeedProductMergeControllerTest {
    static List<Orga_HE__c> categories;
    static List<Product2> products;
    static Map<Id, String> productsCodeMap;
    static Id productRecordtype;
    static Id unitNeedRecordtype;
    static Orga_HE__c department;
    static Orga_HE__c chocolate ;
    static Orga_HE__c bonbon;
    static Orga_HE__c poudre;
    //Apex Page
    static ApexPages.StandardSetController stdController;
    static UnitNeedProductMergeController controller;
    //Test Data Initialization
    //Creation of orga hierarchy elements, products, and unit needs
    static void init() {
        // Orga_HE__c  initialization
        productsCodeMap =  new Map<Id, String>();
        Id rootId = NegoptimHelper.getRootId();
        productRecordtype = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Product');
        unitNeedRecordtype = NegoptimHelper.getObjectRecordTypeId(Product2.SObjectType, 'Unit_Need');
        department = TestDataFactory.createDepartment(true, rootId);
        chocolate = TestDataFactory.createSection(false, department.Id);
        bonbon = TestDataFactory.createSection(false, department.Id);
        poudre = TestDataFactory.createSection(false, department.Id);
        insert new List<Orga_HE__c>{chocolate, bonbon, poudre};
        // Create Global Settings
        NegoptimCustomSettings__c negoSettings = TestDataFactory.createNegoptimCustomSettings(true);
        //Product initialization 
        products = new List<Product2>();
        for(Orga_HE__c category : new List<Orga_HE__c> {chocolate, bonbon}){
            for(Integer i = 0; i < 18; i++){
                //create products
                for(Integer j = 0; j < 3; j++){
                    Product2 product = TestDataFactory.createProduct(false, category.Id, null);
                    product.recordTypeId = productRecordtype;
                    product.ProductCode = '12' + j + category.Elt_Code__c + i;
                    products.add(product);
                }
                //create unit needs
                Product2 product = TestDataFactory.createProduct(false, category.Id, null);
                product.recordTypeId = unitNeedRecordtype;
                products.add(product);
            }
        }
        //insert product to Pouder orga hierarchy element
        for(Integer i = 0; i < 15; i++){
            Product2 product = TestDataFactory.createProduct(false, poudre.Id, null);
            product.recordTypeId = productRecordtype;
            product.ProductCode = '789' + i;
            products.add(product);
        }
        insert products;
        stdController = new ApexPages.StandardSetController(products);
        controller = new UnitNeedProductMergeController(stdController);
    }
    // test Controller
    @isTest 
    static void test_UnselectMode(){
        init();
        system.assert(!controller.isSelectedRecords);
        system.assertEquals(10, getSearchSize(controller.unitNeedsMap));
        for(integer i=0; i<3 ; i++){
            system.assert(controller.unitNeedStdcontroller.getHasNext());
            system.assertEquals(10, getSearchSize(controller.unitNeedsMap));
            controller.unitNeedNext();
        }
        system.assert(!controller.unitNeedStdcontroller.getHasNext());
        system.assertEquals(6, getSearchSize(controller.unitNeedsMap));
        
        for(integer i=0; i<10 ; i++){
            system.assert(controller.productsStdSetCtrl.getHasNext());
            system.assertEquals(10, getSearchSize(controller.productsMap));
            controller.next();
        }
        system.assert(!controller.productsStdSetCtrl.getHasNext());
        system.assertEquals(8, getSearchSize(controller.productsMap));
    }
    @isTest
    static void test_Search(){
        init();
        controller.pageSize = 200;
        controller.refreshPageSize();
        system.assertEquals(controller.unitNeedStdcontroller.getPageSize(), 200);
        system.assertEquals(controller.productsStdSetCtrl.getPageSize(), 200);  
        controller.productSearchString = bonbon.Elt_Code__c;
        controller.searchProducts();
        system.assertEquals(54, getSearchSize(controller.productsMap)); 
        controller.productSearchString = '122'+bonbon.Elt_Code__c;
        controller.searchProducts();
        system.assertEquals(18, getSearchSize(controller.productsMap));
        controller.unitNeedSearchString = chocolate.Name;
        controller.searchUnitNeed();
        system.assertEquals(18, getSearchSize(controller.unitNeedsMap));
        controller.resetUnitNeed();
        system.assertEquals('', controller.unitNeedSearchString);
        system.assertEquals(36, getSearchSize(controller.unitNeedsMap));
        controller.resetProduct();
        system.assertEquals('', controller.productSearchString);
        system.assertEquals(108, getSearchSize(controller.productsMap));
    }
    //Test the save method
    @isTest
    static void test_save(){
        init();
        prepareDataForSaving();
        Test.startTest();
        controller.save();
        Test.stopTest();
        //Successed
        system.assertEquals(10, controller.reportMap.get(Label.MSG_Success).size());  
        //Failed
        system.assertEquals(20, controller.reportMap.get(Label.MSG_Failed).size());
        Integer productCodeNotFound = 0;
        Integer duplicatedProductCode = 0;
        Integer diffClassification = 0;
        //Error categories count
        for(UnitNeedProductMergeController.MergeReportWrapper wrapper : controller.reportMap.get(Label.MSG_Failed).values()){
            if(wrapper.note.equals(Label.MSG_Product_Not_Found))
                productCodeNotFound++;
            else if(wrapper.note.equals(Label.MSG_Code_Product_On_Wrong_Product_Classification))
                diffClassification++;
        }
        //Error categories Assertion
        System.assertEquals(10, productCodeNotFound);
        System.assertEquals(10, diffClassification);
        System.assertEquals(10,getSearchSize(controller.unitNeedsMap));
        //Assert the remaning available product after saving
        for(integer i=0; i<9 ; i++){
            system.assert(controller.productsStdSetCtrl.getHasNext());
            system.assertEquals(getSearchSize(controller.productsMap), 10);
            controller.next();
        } 
        system.assert(!controller.productsStdSetCtrl.getHasNext());
        system.assertEquals(getSearchSize(controller.productsMap), 8);
    }
    static void prepareDataForSaving(){
        List<Product2> mapValues = controller.selectedUnitNeedList;
        // fill products with correct codes
        for(integer i = 0; i < 10; i ++){
            Product2 unitNeedItem = mapValues.get(i);
            controller.unProductsMap.put(unitNeedItem.Id, '120' + unitNeedItem.Category__r.Elt_Code__c + i);
        }
        //code not found 
        for(integer i = 10; i < 20; i ++)
            controller.unProductsMap.put(mapValues.get(i).Id, '126' + i);
        //link to a product with different category
        for(integer i = 20; i < 30; i ++){
            Product2 unitNeedItem = mapValues.get(i);
            String code = unitNeedItem.Category__c == chocolate.Id ? bonbon.Elt_Code__c : chocolate.Elt_Code__c;
            controller.unProductsMap.put(unitNeedItem.Id, '122' + code + (i-20));
        }
    }
    //Test for auto complete
    @isTest
    static void test_findPoduct(){
        init();
        String s = UnitNeedProductMergeController.findProduct('122');
        List<Product2> productsMap = (List<Product2>) JSON.deserializeStrict(s, List<Product2>.class);
        system.assertEquals(36, productsMap.size());
    }
    private static Integer getSearchSize(Map<Id, List<Product2>> productsMap){
        Integer size =0;
        for(List<Product2> productsList : productsMap.values()){
            size += productsList.size();
        }
        return size;
    } 
    private static List<Product2> getProductsAsList(Map<Id, List<Product2>> productsMap){
        List<Product2> productsList = new List<Product2>();
          for(List<Product2> prodList : productsMap.values())
              productsList.addAll(prodList);
        return productsList;
    } 
}