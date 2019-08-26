@isTest
private class AssortmentMatrixComparatorControllerTest {
    
    static Integer year;
    static Orga_BU__c buCountry;
    static Sup_Supplier__c client;
    static Orga_BU__c buSource;
    static Orga_BU__c HMSM;
    static Orga_BU__c DRIVE;
    static List<Orga_HE__c> heList;
    static List<Product2> productList;
    static List<Assortment_BU__c> assortmentsList;
    static List<Assortment_Detail__c> detailsList;

    static void init() {
        Country_List__c countryList = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
        Orga_BU__c region = TestDataFactory.createBURegion(true, 'region');
        buCountry = TestDataFactory.createBUCountry(true, countryList, region.Id);
        client = TestDataFactory.createSupplier(true, buCountry, false);
        List<Orga_BU__c> buList = new List<Orga_BU__c>();
        buSource = TestDataFactory.createBUBanner(false, buCountry);
        buSource.IsMasterBU__c = true;
        buList.add(buSource);
        // create HMSM bu target
        HMSM = TestDataFactory.createBUBanner(false, buCountry);
        HMSM.Related_Client__c = client.Id;
        HMSM.Format_Origin__c = 'Hypermarket;Supermarket';
        HMSM.Mission__c = 'Offer';
        buList.add(HMSM);
        // create drive bu target
        DRIVE = TestDataFactory.createBUBanner(false, buCountry);
        DRIVE.Related_Client__c = client.Id;
        DRIVE.Format_Origin__c = 'Drive';
        DRIVE.Mission__c = 'Offer';
        buList.add(DRIVE);
        insert buList;
        // create clusters
        List<Orga_BU__c> clustersList = new List<Orga_BU__c>();
        Orga_BU__c clusterHMSM = TestDataFactory.createBUAssortCluster(false, HMSM.Id, 'Strat0');
        clustersList.add(clusterHMSM);
        Orga_BU__c clusterDRIVE = TestDataFactory.createBUAssortCluster(false, DRIVE.Id, 'Strat0');
        clustersList.add(clusterDRIVE);
        insert clustersList;
        heList = TestDataFactory.createElementHierarchy(4, 1);
        // Create Global Settings
        NegoptimCustomSettings__c negoSettings = TestDataFactory.createNegoptimCustomSettings(false);
        negoSettings.Assortment_Matrix_Comparator_Grid_Layout__c = 'Matrix_Full';
        insert negoSettings;
        // create Products
        List<Product2> productsList = new List<Product2>();
        Id productRecordType = NegoptimHelper.getObjectRecordTypeId(Product2.sObjectType, 'Product');
        for (integer index = 0; index < 100; index++) {
            Product2 product = TestDataFactory.createProduct(false, heList[4].Id, null);
            product.recordTypeId = productRecordType;
            productsList.add(product);
        }
        insert productsList;
        assortmentsList = new List<Assortment_BU__c>();
        Assortment_BU__c assortmentHMSM = TestDataFactory.createAssortmentBU(false, buSource, HMSM, heList[1]);
        assortmentsList.add(assortmentHMSM);
        Assortment_BU__c assortmentDRIVE = TestDataFactory.createAssortmentBU(false, buSource, DRIVE, heList[1]);
        assortmentsList.add(assortmentDRIVE);
        insert assortmentsList;
        // create Assortment Details
        detailsList = new List<Assortment_Detail__c>();
        for (Product2 product : productsList) {
            detailsList.add(TestDataFactory.createAssortmentDetail(false, assortmentHMSM.Id, product, clusterHMSM.Id));
            detailsList.add(TestDataFactory.createAssortmentDetail(false, assortmentDRIVE.Id, product, clusterDRIVE.Id));
        }
        insert detailsList;
        
    }
    
    private static testmethod void case1_constructor() {
        init();
        AssortmentMatrixComparatorController ctrl = new AssortmentMatrixComparatorController();
        ctrl.assortmentBU.Orga_HE__c = heList[1].Id;
        ctrl.orgaBU.Format_Origin__c = 'Hypermarket;Supermarket;Drive';
        ctrl.orgaBU.Country_Origin__c = buCountry.Id;
        Test.startTest();
        ctrl.changePageScope();
        ctrl.next();
        ctrl.previous();
        ctrl.last();
        ctrl.first();
        ctrl.pageSize = 50;
        ctrl.refreshPageSize();
        Test.stopTest();
        System.assertEquals(ctrl.assortmentsIdList.size(), 2);
    }
}