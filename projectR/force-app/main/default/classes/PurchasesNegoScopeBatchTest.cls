/**
 * @Description Test class methods that verify whether the particular piece of code on PurchasesNegoScopeBatch is working properly.
 **/
@isTest
private class PurchasesNegoScopeBatchTest {
    
    private static final Integer year = TestDataFactory.year;
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Sup_Supplier__c supplier;
    private static Supplier_PG_Mapping__c PG;
    
    static void init() {
        try {
	    	// Insert Country List.
	        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	    	// Insert Region.
	        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
	    	// Insert Country.
	        country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
	    	// Insert Legal.
	    	Orga_BU__c legal = TestDataFactory.createBULegal(true, myCountry);
	    	// Insert Store.
	    	store = TestDataFactory.createBUStores(true, country, legal.Id, 1).get(0);
			// Get Root Element Id.
			Id rootId = NegoptimHelper.getRootId();
			// Create Department.
			Orga_HE__c department = TestDataFactory.createDepartment(true, rootId);
			// Insert Section.
			Orga_HE__c section = TestDataFactory.createSection(true, department.Id);
	        // Insert supplier.
	    	supplier = TestDataFactory.createSupplier(true, country, true);
	        // Insert Brand.
	        Sup_Brand__c brand = TestDataFactory.createBrand(true, supplier.Id);
            // Insert PG.
	    	PG = TestDataFactory.createPGs(true, supplier.Id, department.Id, section.Id, 2)[0];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testMethod void test_simpleCase() {
        init();
        // Get the default negoscope created on supplier creation.
	    Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        // delete all NS-PG related
        /*List<Sup_NS_PG__c> nspgs = [SELECT Sup_PG__c, Sup_sup_NegoScope__c, Sup_sup_NegoScope__r.Parent_Nego_Scope__c
                                    FROM Sup_NS_PG__c WHERE Sup_PG__c = :pg.Id];
        delete nspgs;*/
        // Insert purchase.
        String fieldName;
        Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, store.Id);
        purchase.Supplier__c = supplier.Id;
        for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'TO' + i + '__c';
        	purchase.put(fieldName, 100);
        }
        insert purchase;
        // Create NS whish will contain the PG due to a trigger
        Sup_sup_NegoScope__c negoScopeMain = TestDataFactory.createNS(false, supplier.Id);
        negoScopeMain.Is_All_Brands__c = true;
        negoScopeMain.Is_All_HE__c = true;
        negoScopeMain.Is_All__c = true;
        Test.startTest();
        Database.executeBatch(new PurchasesNegoScopeBatch('PurchasesNegoScopeBatchTest', country.Id, year), 1000);
        Test.stopTest();
        // Assertion.
        Purchases_Flow_PG__c updatedPurchase = [SELECT Id, Name, PG__c, Supplier_Nego_Scope__c FROM Purchases_Flow_PG__c
                                                WHERE Supplier__c = :supplier.Id LIMIT 1];
        System.assertEquals(negoScopeMain.Id, updatedPurchase.Supplier_Nego_Scope__c);
    }
}