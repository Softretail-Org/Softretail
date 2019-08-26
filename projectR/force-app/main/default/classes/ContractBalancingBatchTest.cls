/**
 * @Description Test class that verify whether the particular piece of code on ContractBalancingBatch is working properly.
 **/
@isTest
private class ContractBalancingBatchTest {
    
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    
    static void init() {
    	try {
	        // Get the folder settings.
	        Folder folder = NegoptimHelper.getFolderSettings();
	        // Create Document
	        if (folder != null) {
	            String str = '{"delimiter": "," , "groupBU": "AMC"}';
	            Document document = TestDataFactory.createDocument(true, folder.Id, str);
	        }
	    	// Insert Country List.
	        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	    	// Insert Region.
	        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
	    	// Insert Country.
	        country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
	        // Insert group BU.
	        Orga_BU__c groupBU = TestDataFactory.createGroupBU(true, 'EMC');
	        // Insert supplier.
		    supplier = TestDataFactory.createSupplier(true, country, true);
	        // Get the default negoscope created on supplier creation.
		    NS = TestDataFactory.getNSs(supplier.Id)[0];
	        // Insert contract.
			Contract__c contract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-4), System.Today().addMonths(-2));
	        contract.Status__c = 'Signed';
	        contract.D_N__c = 'N';
	        contract.Tactite_reconduction__c = True;
	        contract.TO1__c = 10;
	        contract.TO2__c = 10;
	        contract.TO3__c = 10;
	        contract.TO4__c = 10;
	        contract.TO1_Fact__c = 10;
	        contract.TO2_Fact__c = 10;
	        contract.TO3_Fact__c = 10;
	        contract.TO4_Fact__c = 10;
	        contract.TO1_FX__c = 10;
	        contract.TO2_FX__c = 10;
	        contract.TO3_FX__c = 10;
	        contract.TO4_FX__c = 10;
	        insert contract;
	        // Insert Pol Sale Condition.
	        Pol_Sale_Condition__c saleCondition = TestDataFactory.createPolSaleCondition(false, country.Id);
	        saleCondition.VAT_Rebate_Rate__c = 10;
	        saleCondition.VAT_Service_Rate__c = 10;
	        saleCondition.Buying_Payment_Condition__c = 'Net';
	        saleCondition.Buying_Payment_Days__c = '10';
	        insert saleCondition;
	        // Insert Policy - Tariff conditions.
			tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
			tariffCondition.Name = 'Advertising fees';
			tariffCondition.Nego_Discount_Type__c = 'Advertising fees';
	        insert tariffCondition;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void uTest1_caseBalancingContract_Fail() {
        init();
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addMonths(1));
        contract1.Total_Marketing_Events_Justified__c = 250;
        contract1.TO1__c = 1;
        contract1.TO2__c = 2;
        contract1.TO3__c = 3;
        contract1.TO1_Fact__c = 1;
        contract1.TO2_Fact__c = 2;
        contract1.TO3_Fact__c = 0;
        insert contract1;
        // Insert condition.
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract1, System.Today(), System.Today().addDays(20));
        condition.Base_TO_Nego__c = 10;
        condition.Value_per__c = 5;
        condition.Value_amt__c = 500;
        insert condition;
        Test.startTest();
        Database.executeBatch(new ContractBalancingBatch('ContractBalancingBatchTest', new List<Id>{ contract1.Id }));
        Test.stopTest();
        // Assertion.
        contract1 = [SELECT Id, Status__c FROM Contract__c WHERE Id = :contract1.Id LIMIT 1];
        System.assertEquals(contract1.Status__c, 'Signed');
    }
    
    @isTest static void uTest2_caseBalancingContract_Success() {
        init();
        // Insert contract.
        Contract__c contract1 = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addDays(-1));
        contract1.Total_Marketing_Events_Justified__c = 505;
        contract1.Last_Active_Contract__c = true;
        contract1.TO1__c = 1;
        contract1.TO2__c = 2;
        contract1.TO3__c = 3;
        contract1.TO1_Fact__c = 1;
        contract1.TO2_Fact__c = 2;
        contract1.TO3_Fact__c = 3;
        contract1.Supplier__c = supplier.Id;
        contract1.Supplier_Nego_Scope__c = NS.Id;
        contract1.Contract_BU__c = country.Id;
        contract1.Duration_type__c = 'Month';
        insert contract1;
        // Insert condition.
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract1, System.Today().addDays(-20), System.Today().addDays(-2));
        condition.Base_TO_Nego__c = 10;
        condition.Value_per__c = 50;
        condition.Value_amt__c = 500;
        insert condition;
        // Start test.
        Test.startTest();
        Database.executeBatch(new ContractBalancingBatch('ContractBalancingBatchTest', new List<Id>{contract1.Id}));
        Test.stopTest();
        // Assertion.
        contract1 = [SELECT Id, Balancing_Action_ToDo__c, Status__c FROM Contract__c WHERE Id = :contract1.Id LIMIT 1];
        System.assertEquals(contract1.Status__c, 'Balanced');
    }
}