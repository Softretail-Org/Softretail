/**
 * @Description Test class that verify whether the particular piece of code on IndexManagementBatch is working properly.
 **/
@isTest
private class IndexManagementBatchTest {
    
    private static final Integer year = TestDataFactory.year;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition1, tariffCondition2, tariffCondition3;
    
    static void init() {
    	try {
			// Insert Country List.
	        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	        // Insert Region.
	        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
	        // Insert Country.
	        Orga_BU__c country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
	        // Insert supplier.
	        Sup_Supplier__c supplier = TestDataFactory.createSupplier(true, country, true);
	        // Get the default negoscope created on supplier creation.
	        NS = TestDataFactory.getNSs(supplier.Id)[0];
	    	// Insert Policy - Tariff conditions.
	    	tariffCondition1 = TestDataFactory.createTariffCondition(false, 0, 1);
	    	tariffCondition2 = TestDataFactory.createTariffCondition(false, 1, 2);
	    	tariffCondition3 = TestDataFactory.createTariffCondition(false, 2, 3);
	    	insert new List<Pol_Com_Condition__c> {tariffCondition1, tariffCondition2, tariffCondition3};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Single case.
    @isTest static void uTest1_singleContract() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Rise_Rate__c = 1;
    	contract.Depreciation_Rate__c = 0.5;
    	contract.Markdown_Rate_Break__c = 2;
    	contract.Markdown_Rate_Promo__c = 0.75;
    	contract.Markdown_Rate_Theft__c = 1;
    	contract.TO1_Fact__c  = 100000;
    	insert contract;
    	// Insert conditions.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition1.Value_per__c = 1;
    	condition1.Value_amt__c = 0;
    	Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition2.Value_per__c = 0;
    	condition2.Value_amt__c = 3000;
    	Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition2, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition3.Value_per__c = 8.5;
    	condition3.Value_amt__c = 0;
    	Contract_Discount__c condition4 = TestDataFactory.createCondition(false, tariffCondition3, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition4.Value_per__c = 2.5;
    	condition4.Value_amt__c = 0;
    	insert new List<Contract_Discount__c> {condition1, condition2, condition3, condition4};
        // Start test.
        Test.startTest();
        Database.executeBatch(new IndexManagementBatch(Null, Null, Null));
        Test.stopTest();
        Contract__c c = [SELECT index1__c, index2__c, index3__c, index4__c FROM Contract__c];
        // Assertions.
        System.assertEquals(100.25, c.index1__c);
        System.assertEquals(91.75, c.index2__c);
        System.assertEquals(89.25, c.index3__c);
        System.assertEquals(89.25, c.index4__c);
    }
    
    // Several case.
    @isTest static void uTest2_severalContracts() {
    	init();
    	// Insert contracts.
    	Contract__c contract1 = (Contract__c)TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract1.Rise_Rate__c = 1;
    	contract1.Depreciation_Rate__c = 0.5;
    	contract1.Markdown_Rate_Break__c = 2;
    	contract1.Markdown_Rate_Promo__c = 0.75;
    	contract1.Markdown_Rate_Theft__c = 1;
    	contract1.TO1_Fact__c  = 100000;
    	Contract__c contract2 = (Contract__c)TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract2.Rise_Rate__c = 1;
    	contract2.Depreciation_Rate__c = 0.5;
    	contract2.Markdown_Rate_Break__c = 2;
    	contract2.Markdown_Rate_Promo__c = 0.75;
    	contract2.Markdown_Rate_Theft__c = 1;
    	contract2.TO1_Fact__c  = 100000;
    	insert new List<Contract__c> {contract1, contract2};
    	// Insert conditions for the first contract.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition1, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition1.Value_per__c = 1;
    	condition1.Value_amt__c = 0;
    	Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition1, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition2.Value_per__c = 0;
    	condition2.Value_amt__c = 3000;
    	Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition2, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition3.Value_per__c = 8.5;
    	condition3.Value_amt__c = 0;
    	Contract_Discount__c condition4 = TestDataFactory.createCondition(false, tariffCondition3, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition4.Value_per__c = 2.5;
    	condition4.Value_amt__c = 0;
    	// Insert conditions for the second contract.
    	Contract_Discount__c condition5 = TestDataFactory.createCondition(false, tariffCondition1, contract2, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition5.Value_per__c = 1;
    	condition5.Value_amt__c = 0;
    	Contract_Discount__c condition6 = TestDataFactory.createCondition(false, tariffCondition1, contract2, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition6.Value_per__c = 0;
    	condition6.Value_amt__c = 3000;
    	Contract_Discount__c condition7 = TestDataFactory.createCondition(false, tariffCondition2, contract2, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition7.Value_per__c = 8.5;
    	condition7.Value_amt__c = 0;
    	Contract_Discount__c condition8 = TestDataFactory.createCondition(false, tariffCondition3, contract2, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	condition8.Value_per__c = 2.5;
    	condition8.Value_amt__c = 0;
    	insert new List<Contract_Discount__c> {condition1, condition2, condition3, condition4, condition5, condition6, condition7, condition8};
        // Start test.
        Test.startTest();
        Database.executeBatch(new IndexManagementBatch(Null, Null, Null));
        Test.stopTest();
        String cN1 = [SELECT Contract_Numbder__c FROM Contract__c WHERE Id = : contract1.Id].Contract_Numbder__c;
        String cN2 = [SELECT Contract_Numbder__c FROM Contract__c WHERE Id = : contract2.Id].Contract_Numbder__c;
        Contract__c c1 = [SELECT index1__c, index2__c, index3__c, index4__c FROM Contract__c WHERE Contract_Numbder__c = :cN1];
        Contract__c c2 = [SELECT index1__c, index2__c, index3__c, index4__c FROM Contract__c WHERE Contract_Numbder__c = :cN2];
        // Assertions.
        System.assertEquals(100.25, c1.index1__c);
        System.assertEquals(91.75, c1.index2__c);
        System.assertEquals(89.25, c1.index3__c);
        System.assertEquals(89.25, c1.index4__c);
        System.assertEquals(100.25, c2.index1__c);
        System.assertEquals(91.75, c2.index2__c);
        System.assertEquals(89.25, c2.index3__c);
        System.assertEquals(89.25, c2.index4__c);
    }
}