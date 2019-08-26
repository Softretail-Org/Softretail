/**
 * @Description Test class that verify whether the particular piece of code on CalculateTOContractBatch is working properly.
 **/
@isTest(SeeAllData=false)
private class CalculateTOContractBatchTest {
	
	private static final Integer SUPPLIER_NUMBER = 10;
    private static final Integer year = TestDataFactory.year;
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Sup_Supplier__c supplier;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Supplier_PG_Mapping__c PG;
    private static Contract__c contract;
    private static String fieldName;
    
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
			// Insert supplier.
		    supplier = TestDataFactory.createSupplier(true, country, true);
		    // Get the default negoscope created on supplier creation.
		    Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
			// Get Root Element Id.
			Id rootId = NegoptimHelper.getRootId();
			// Create Department.
			department = TestDataFactory.createDepartment(true, rootId);
			// Insert Section.
			section = TestDataFactory.createSection(true, department.Id);
		    // Insert PG.
			PG = TestDataFactory.createPG(true, supplier.Id, department.Id, section.Id);
			// Create contract.
			contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		} catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Single encapsulate Fact TO.
    static testmethod void uTest1_encapsulateFactTO() {
    	init();
	    // Insert Contract.
	    for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'TO' + i + '__c';
        	contract.put(fieldName, 0);
        }
	    insert contract;
	    // Insert purchases.
	    List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
	    for (Integer i = 1 ; i <= 2 ; i++) {
	    	Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, store.Id);
	        for (Integer j = 1 ; j <= 12 ; j++) {
	        	fieldName = 'TO' + j + '__c';
	        	purchase.put(fieldName, 100);
	        }
	        purchase.Contrat1__c = contract.Id;
	        purchases.add(purchase);
	    }
		insert purchases;
        // Start test.
		Test.startTest();
		Database.executeBatch(new CalculateTOContractBatch('itself', country.Id, null, year));
		Test.stopTest();
		// Assertions.
		Contract__c c = [SELECT TO1_Fact__c, TO2_Fact__c, TO3_Fact__c, TO4_Fact__c, TO5_Fact__c, TO6_Fact__c,
								TO7_Fact__c, TO8_Fact__c, TO9_Fact__c, TO10_Fact__c, TO11_Fact__c, TO12_Fact__c
								FROM Contract__c];
		for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'TO' + i + '_Fact__c';
        	System.assertEquals(200, c.put(fieldName, 0));
        }
    }
    
    // Single encapsulate Qty.
	static testmethod void uTest2_encapsulateQty() {
    	init();
	    // Insert Contract.
        for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'Qty' + i + '_Fact__c';
        	contract.put(fieldName, 0);
        }
	    insert contract;
	    // Insert purchases.
	    List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
	    for (Integer i = 1 ; i <= 2 ; i++) {
	    	Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, store.Id);
	    	for (Integer j = 1 ; j <= 12 ; j++) {
	        	fieldName = 'Qty' + j + '__c';
	        	purchase.put(fieldName, 10);
	        }
	        purchase.Contrat1__c = contract.Id;
	        purchases.add(purchase);
	    }
		insert purchases;
        // Start test.
		Test.startTest();
		Database.executeBatch(new CalculateTOContractBatch('itself', country.Id, null, year));
		Test.stopTest();
		// Assertions.
		Contract__c c = [SELECT Qty1_Fact__c, Qty2_Fact__c, Qty3_Fact__c, Qty4_Fact__c, Qty5_Fact__c, Qty6_Fact__c,
								Qty7_Fact__c, Qty8_Fact__c, Qty9_Fact__c, Qty10_Fact__c, Qty11_Fact__c, Qty12_Fact__c
								FROM Contract__c];
		for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'Qty' + i + '_Fact__c';
        	System.assertEquals(20, c.put(fieldName, 0));
        }
    }
    
    // Single encapsulate Sales.
    static testmethod void uTest3_encapsulateSales() {
    	init();
	    // Insert Contract.
	    for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'Sales_M' + i + '__c';
        	contract.put(fieldName, 0);
        }
	    insert contract;
	    // Insert purchases.
	    List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
	    for (Integer i = 1 ; i <= 2 ; i++) {
	    	Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, store.Id);
			for (Integer j = 1 ; j <= 12 ; j++) {
	        	fieldName = 'Sales_M' + j + '__c';
	        	purchase.put(fieldName, 10);
	        }
	        purchase.Contrat1__c = contract.Id;
	        purchases.add(purchase);
	    }
		insert purchases;
        // Start test.
		Test.startTest();
		Database.executeBatch(new CalculateTOContractBatch('itself', country.Id, null, year));
		Test.stopTest();
		// Assertions.
		Contract__c c = [SELECT Sales_M1__c, Sales_M2__c, Sales_M3__c, Sales_M4__c, Sales_M5__c, Sales_M6__c,
								Sales_M7__c, Sales_M8__c, Sales_M9__c, Sales_M10__c, Sales_M11__c, Sales_M12__c
								FROM Contract__c];
        for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'Sales_M' + i + '__c';
        	System.assertEquals(20, c.put(fieldName, 0));
        }
    }
    
    // Single encapsulate Front Margin.
    static testmethod void uTest4_encapsulateFrontMargin() {
    	init();
	    // Insert Contract.
        for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'Front_Margin_M' + i + '__c';
        	contract.put(fieldName, 0);
        }
	    insert contract;
	    // Insert purchases.
	    List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
	    for (Integer i = 1 ; i <= 2 ; i++) {
	    	Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PG, store.Id);
			for (Integer j = 1 ; j <= 12 ; j++) {
	        	fieldName = 'Front_Margin_M' + j + '__c';
	        	purchase.put(fieldName, 10);
	        }
	    	purchase.Contrat1__c = contract.Id;
	        purchases.add(purchase);
	    }
		insert purchases;
        // Start test.
		Test.startTest();
		Database.executeBatch(new CalculateTOContractBatch('itself', country.Id, null, year));
		Test.stopTest();
		// Assertions.
		Contract__c c = [SELECT Front_Margin_M1__c, Front_Margin_M2__c, Front_Margin_M3__c, Front_Margin_M4__c, Front_Margin_M5__c, Front_Margin_M6__c,
								Front_Margin_M7__c, Front_Margin_M8__c, Front_Margin_M9__c, Front_Margin_M10__c, Front_Margin_M11__c, Front_Margin_M12__c
								FROM Contract__c];
		for (Integer i = 1 ; i <= 12 ; i++) {
        	fieldName = 'Front_Margin_M' + i + '__c';
        	System.assertEquals(20, c.put(fieldName, 0));
        }
    }
    
    // Mass encapsulation.
    static testmethod void uTest5_massCase() {
    	init();
		// Create lists of purchases, PGs.
        List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
        List<Supplier_PG_Mapping__c> PGs = new List<Supplier_PG_Mapping__c>();
		// Insert suppliers.
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
        for (Integer i=1 ; i <= SUPPLIER_NUMBER ; i++) {
        	Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
        	suppliers.add(supplier);
        }
        insert suppliers;
        List<Id> supplierIds = new List<Id>();
        for (Sup_Supplier__c sup : suppliers) {
        	supplierIds.add(sup.Id);
        }
        // Get the default negoscope created on supplier creation.
        List<Sup_sup_NegoScope__c> NSs = [SELECT Id, Supplier__c, Supplier__r.Name, Supplier__r.Country_origin__c FROM Sup_sup_NegoScope__c WHERE Supplier__c IN : supplierIds];
        // Insert PGs.
        for(Integer i = 1; i <= SUPPLIER_NUMBER; i++) {
        	Supplier_PG_Mapping__c PG = TestDataFactory.createPG(false, suppliers.get(i-1).Id, department.Id, section.Id);
        	PGs.add(PG);
        }
        insert PGs;
        // Insert contract for each supplier.
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 1 ; i <= SUPPLIER_NUMBER ; i++) {
        	Contract__c contract = (Contract__c)TestDataFactory.createContract(false, NSs.get(i-1), date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        	for (Integer j = 1 ; j <= 12 ; j++) {
	        	fieldName = 'TO' + i + '__c';
	        	contract.put(fieldName, 0);
	        }
        	contracts.add(contract);
        }
        insert contracts;
		// Insert purchase for each contract.
		for (Integer k = 0 ; k < 2 ; k++) {
			for (Integer i = 1 ; i <= SUPPLIER_NUMBER ; i++) {
				Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(false, PGs.get(i-1), store.Id);
				for (Integer j = 1 ; j <= 12 ; j++) {
		        	fieldName = 'TO' + j + '__c';
		        	purchase.put(fieldName, 100);
		        }
		        purchase.Contrat1__c = contracts.get(i-1).Id;
				purchases.add(purchase);
			}
		}
        insert purchases;
        // Start test.
		Test.startTest();
		Database.executeBatch(new CalculateTOContractBatch('itself', country.Id, null, year));
		Test.stopTest();
		// Assertions.
        for (Contract__c c : [SELECT TO1_Fact__c, TO2_Fact__c, TO3_Fact__c, TO4_Fact__c, TO5_Fact__c, TO6_Fact__c,
									TO7_Fact__c, TO8_Fact__c, TO9_Fact__c, TO10_Fact__c, TO11_Fact__c, TO12_Fact__c
									FROM Contract__c]) {
        	for (Integer i = 1 ; i <= 12 ; i++) {
	        	fieldName = 'TO' + i + '_Fact__c';
	        	System.assertEquals(200, c.put(fieldName, 0));
	        }
        }
    }
}