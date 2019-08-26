/**
 * @Description Test class that verify whether the particular piece of code on CalculateBaseTOBatch is working properly.
 **/
@isTest
private class CalculateBaseTOBatchTest {
	
	private static final Integer CONTRACT_NUMBER = 100;
	private static final Integer year = TestDataFactory.year;
	private static final String currencyIsoCode = TestDataFactory.currencyIsoCode;
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Pol_Com_Condition__c tariffCondition;
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
			// Create Department.
			department = TestDataFactory.createDepartment(true, rootId);
			// Insert Section.
			section = TestDataFactory.createSection(true, department.Id);
			// Insert Policy - Tariff conditions.
	    	tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
			// Create list of PGs.
			PGs = new List<Supplier_PG_Mapping__c>();
	        // Create list of purchases.
	        purchases = new List<Purchases_Flow_PG__c>();
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Single calculate base TO for one contract.
    static testmethod void uTest1_calculateBaseTO() {
        init();
        // Insert supplier.
	    Sup_Supplier__c supplier = TestDataFactory.createSupplier(true, country, true);
	    // Get the default negoscope created on supplier creation.
	    Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
	    // Insert PGs.
	    PGs = TestDataFactory.createPGs(true, supplier.Id, department.Id, section.Id, 2);
	    // Insert contract.
    	Contract__c contract = (Contract__c)TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        // Insert condition.
    	Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 30));
    	condition.Value_per__c = 2.5;
    	condition.BU_Scope__c = country.Id;
    	insert condition;
        // Insert purchases.
        String fieldName;
        purchases = TestDataFactory.createPurchases(false, PGs, contract, store.Id, 2);
        for (Purchases_Flow_PG__c p : purchases) {
        	for (Integer i = 1 ; i <= 12 ; i++) {
	        	fieldName = 'TO' + i + '__c';
	        	p.put(fieldName, 100);
	        }
        }
        insert purchases;
        // Start test.
		Test.startTest();
        Database.executeBatch(new CalculateBaseTOBatch('itself', country.Id, new List<Id>{contract.Id}, null, year), 150);
        Test.stopTest();
        // Assertion.
        Contract_Discount__c c = [Select Base_TO_Actual__c FROM Contract_Discount__c WHERE Id = :condition.Id LIMIT 1];
        System.assertEquals(2400 * NegoptimHelper.getConversionRate(UserInfo.getDefaultCurrency()), c.Base_TO_Actual__c);
    }
    
    // Mass calculate base TO.
    static testmethod void uTest2_massCalculateBaseTO() {
    	init();
        // Insert suppliers.
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
        for (Integer i = 1; i < = CONTRACT_NUMBER; i++) {
	    	Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.Code__c += '-' + i;
        	suppliers.add(supplier);
        }
        insert suppliers;
        List<Id> supplierIds = new List<Id>();
        for (Sup_Supplier__c sup : suppliers) {
        	supplierIds.add(sup.Id);
        }
        // Get the default negoscope created on supplier creation.
        List<Sup_sup_NegoScope__c> NSs = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c IN : supplierIds];
        // Create PGs.
        for(Integer i = 1; i <= CONTRACT_NUMBER; i++) {
        	Supplier_PG_Mapping__c PG = TestDataFactory.createPG(false, suppliers.get(i-1).Id, department.Id, section.Id);
        	PGs.add(PG);
        }
        insert PGs;
        // Insert contract for each supplier.
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 1 ; i <= CONTRACT_NUMBER ; i++) {
        	Contract__c contract = new Contract__c(Name = suppliers.get(i-1).Name + ' - Contract ' + i + ' ' + year, Contract_Numbder__c = 'C00' + i, Supplier__c = suppliers.get(i-1).Id,
        							Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
    						   		Supplier_Nego_Scope__c = NSs.get(i-1).Id, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        	contracts.add(contract);
        }
        insert contracts;
        List<Id>contractIds = new List<Id>();
        for (Contract__c c : contracts) {
        	contractIds.add(c.Id);
        }
        // Insert condition for each contract.
        List<Contract_Discount__c> conditions = new List<Contract_Discount__c>();
        for (Integer i=1 ; i <= CONTRACT_NUMBER ; i++) {
        	Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
        							Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 30),
    						 		Contract__c = contracts.get(i-1).Id, Product_Scope__c = NSs.get(i-1).Id, BU_Scope__c = country.Id,
    						 		Value_per__c = 2.5);
         	conditions.add(condition);
        }
        insert conditions;
		// Insert purchase for each contract.
		for (Integer i=1 ; i <= CONTRACT_NUMBER ; i++) {
			Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = suppliers.get(i-1).Id, PG__c = PGs.get(i-1).Id, Supplier_Nego_Scope__c = NSs.get(i-1).Id,
        							Department__c = department.Id, Section__c = section.Id, Contrat1__c = contracts.get(i-1).Id, BU__c = store.Id, Year__c = year,
                                    TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                    TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
			purchases.add(purchase);
		}
        insert purchases;
        // Start test.
		Test.startTest();
        Database.executeBatch(new CalculateBaseTOBatch('itself', country.Id, contractIds, null, year), 150);
        Test.stopTest();
        // Assertion.
        List<Id> condIds = new List<Id>();
		for (Contract_Discount__c cond : conditions) {
			condIds.add(cond.Id);
		}
        Decimal d = NegoptimHelper.getConversionRate(UserInfo.getDefaultCurrency());
        for (Contract_Discount__c condition : [Select Base_TO_Actual__c FROM Contract_Discount__c WHERE Id = :condIds]) {
        	System.assertEquals(1200 * d, condition.Base_TO_Actual__c);
        }
    }
}