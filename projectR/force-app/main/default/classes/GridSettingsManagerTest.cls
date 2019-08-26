/**
 * @author ULiT
 * @description Test class for GridSettingsManager
 * */
@isTest
private class GridSettingsManagerTest {

    private static Integer year;
    private static Integer month;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c department;
    private static Orga_HE__c category;
    private static Product2 product;
    
    private static String OBJECT_NAME = Product_Assortment_Introduction_History__c.SObjectType.getDescribe().getName();
    private static NegoptimCustomSettings__c negoCustomSettings;    
    
    static void init() {
        try {
            year = System.Today().year();
            month = System.Today().month();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region.
            region = TestDataFactory.createBURegion(true, 'MEA');
            // Create Country.
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            /*country.Related_Client__c = supplier.Id;
            update country;*/
            Orga_BU__c banner = TestDataFactory.createBUBanner(false, country);
            banner.Related_Client__c = supplier.Id;
            insert banner;
            // Create NS.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Department
            department = TestDataFactory.createDepartment(false, rootId);
            insert department;
            // Create category        
            category = TestDataFactory.createSection(false, department.Id);
            category.Status__c = 'Active';
            insert category;
            // insert product
            product = TestDataFactory.createProduct(false, category.Id, supplier.Id);
            product.IsActive = true;
            insert product;
        } catch (Exception ex) { }
    }
    @isTest static void constructor_success() {
        init();
        // Create negoCustomSettings
        negoCustomSettings = TestDataFactory.createNegoptimCustomSettings(false);
        negoCustomSettings.Product_Inno_Grid_Layout__c = 'Product_Inno';
        insert negoCustomSettings;
        GridSettingsManager gridSettingsManager = new GridSettingsManager(OBJECT_NAME, null, negoCustomSettings.Product_Inno_Grid_Layout__c);
        String orderBy = 'Name';
        String query = gridSettingsManager.buildQuery(null, null, orderBy);
        List<Product_Assortment_Introduction_History__c> productList = Database.query(query);
        // Assertion.
        System.assertEquals(1, productList.size());
    }
}