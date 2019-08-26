/**
 * @Description Test class that verify whether the particular piece of code on PurchasesContractBatch is working properly.
 **/
@isTest(SeeAllData=false)
private class PurchasesContractBatchTest {
    
    private static final Integer SUPPLIER_NUMBER = 10;
    private static final Integer year = TestDataFactory.year;
	private static final String currencyIsoCode = TestDataFactory.currencyIsoCode;
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static List<Supplier_PG_Mapping__c> PGs;
    private static List<Purchases_Flow_PG__c> purchases;
	
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
			// Insert Department.
			department = TestDataFactory.createDepartment(true, rootId);
			// Insert Section.
			section = TestDataFactory.createSection(true, department.Id);
			// Create list of PGs.
			PGs = new List<Supplier_PG_Mapping__c>();
	        // Create list of Purchases.
	        purchases = new List<Purchases_Flow_PG__c>();
    	} catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testmethod void uTest1_singleCase() {
    	init();
    	// Insert supplier.
	    Sup_Supplier__c supplier = TestDataFactory.createSupplier(true, country, true);
        // Get the default negoscope created on supplier creation.
	    Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
        // Insert PG.
	    Supplier_PG_Mapping__c PG = TestDataFactory.createPGs(true, supplier.Id, department.Id, section.Id, 2)[0];
        // Insert contract.
    	Contract__c contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        // Insert purchase.
        String fieldName;
        Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, store.Id);
        for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'TO' + i + '__c';
        	purchase.put(fieldName, 100);
        }
        purchase.Contrat1__c = contract.Id;
        insert purchase;
        // Start test.
		Test.startTest();
		//Database.SaveResult result = Database.update(purchase, false);
		Database.executeBatch(new PurchasesContractBatch('PurchasesContractBatchTest', country.Id, year));
		Test.stopTest();
		// Assertion.
		Purchases_Flow_PG__c p = [SELECT Contrat1__c FROM Purchases_Flow_PG__c];
        System.assertEquals(contract.Id, p.Contrat1__c);
    }
    
    static testmethod void uTest2_massCase() {
    	init();
    	List<Sup_Supplier__c> suppliers = TestDataFactory.createSuppliers(true, country, true, SUPPLIER_NUMBER);
        List<Id> supplierIds = new List<Id>();
        for (Sup_Supplier__c sup : suppliers) {
        	supplierIds.add(sup.Id);
        }
        // Get the default negoscope created on supplier creation.
        List<Sup_sup_NegoScope__c> NSs = [SELECT Id, Supplier__c, Supplier__r.Name, Supplier__r.Code__c, Supplier__r.Country_origin__c FROM Sup_sup_NegoScope__c WHERE Supplier__c IN : supplierIds];      
        // Create PGs.
        for(Integer i = 1; i <= SUPPLIER_NUMBER; i++) {
        	Supplier_PG_Mapping__c PG = TestDataFactory.createPG(false, suppliers.get(i-1).Id, department.Id, section.Id);
        	PGs.add(PG);
        }
        insert PGs;
        // Create contract for each supplier.
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 1 ; i < = SUPPLIER_NUMBER ; i++) {
    		Contract__c contract = (Contract__c)TestDataFactory.createContract(false, NSs.get(i-1), date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        	contracts.add(contract);
        }
        insert contracts;
        List<Id>contractIds = new List<Id>();
        for (Contract__c c : contracts) {
        	contractIds.add(c.Id);
        }
		// Create purchase for each contract.
		for (Integer k = 0 ; k < 2 ; k++) {
			for (Integer i = 1 ; i < = SUPPLIER_NUMBER ; i++) {
				Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = suppliers.get(i-1).Id, PG__c = PGs.get(i-1).Id, Department__c = department.Id, Section__c = section.Id,
                                              Supplier_Nego_Scope__c = NSs.get(i-1).Id, Year__c = year, BU__c = store.Id,
                                              TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                              TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
				purchases.add(purchase);
			}
		}
        insert purchases;
        // Start test.
		Test.startTest();
		Database.executeBatch(new PurchasesContractBatch('PurchasesContractBatchTest', country.Id, year));
		Test.stopTest();
		// Assertions.
		List<Purchases_Flow_PG__c> ps = [SELECT Contrat1__c FROM Purchases_Flow_PG__c];
		System.assertEquals(ps.get(0).Contrat1__c, contractIds.get(0));
		System.assertEquals(ps.get(1).Contrat1__c, contractIds.get(1));
		System.assertEquals(ps.get(2).Contrat1__c, contractIds.get(2));
    }
}