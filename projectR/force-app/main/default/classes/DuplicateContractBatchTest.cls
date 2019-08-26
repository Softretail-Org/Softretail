/**
 * @Description Test class that verify whether the particular piece of code on DuplicateContractBatch is working properly.
 **/
@isTest
private class DuplicateContractBatchTest {

    private static final Integer year = TestDataFactory.year;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    
	static void init() {
    	try {
			// Insert Country List.
	        myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	        // Insert Region.
	        region = TestDataFactory.createBURegion(true, 'EU');
	        // Insert Country.
	        country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
	        // Insert supplier.
	        supplier = TestDataFactory.createSupplier(true, country, true);
	        // Get the default negoscope created on supplier creation.
	        NS = TestDataFactory.getNSs(supplier.Id)[0];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
	
    // Duplicate a non duplicated contract.
    static testmethod void uTest1_nonDuplicatedContract_Success() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
        insert contract;
        // Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(2, c.size());
    }
	
	// Duplicate a duplicated contract.
    static testmethod void uTest2_duplicatedContract_Failed() {
    	init();
    	// Insert contracts.
    	Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract1.Tactite_reconduction__c = True;
        Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year + 1, 1, 1), date.newInstance(year + 1, 12, 31));
        contract2.Status__c = 'Validated';
        contract2.D_N__c = 'D';
        contract2.Tactite_reconduction__c = True;
        contract2.BU_Source__c = null;
        insert new List<Contract__c>{contract1, contract2};
        // Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract1.Id, contract2.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(2, c.size());
    }
    
    // Duplicate a non duplicated contract with related conditions.
    static testmethod void uTest3_nonDuplicatedContractWithConditions_Success() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		contract.Tactite_reconduction__c = True;
    	insert contract;
		// Insert Policy - Tariff conditions.
    	Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
    	// Insert conditions.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 2;
		condition1.is_duplicable__c = True;
    	Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 2;
		condition1.is_duplicable__c = True;
		Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition3.Value_per__c = 2;
		condition3.is_duplicable__c = True;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	List<Contract_Discount__c> cond = [SELECT Id FROM Contract_Discount__c];
       	System.assertEquals(8, c.size() + cond.size());
    }
    
    // Duplicate a duplicated contract with related conditions.
    static testmethod void uTest4_duplicatedContractWithConditions_Failed() {
        init();
        // Insert contracts.
    	Contract__c contract1 = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		contract1.Tactite_reconduction__c = True;
		contract1.BU_Source__c = null;
    	Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year+1, 1, 1), date.newInstance(year+1, 12, 31));
		contract2.Tactite_reconduction__c = True;
        contract2.Status__c = 'Validated';
        contract2.D_N__c = 'D';
        contract2.Tactite_reconduction__c = True;
        contract2.BU_Source__c = null;
        insert new List<Contract__c>{contract1, contract2};
        // Insert Policy - Tariff conditions.
    	Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
    	// Insert conditions.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 2;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract1, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition2.Value_per__c = 2;
        insert new List<Contract_Discount__c>{condition1, condition2};
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract1.Id}, year, null, null, null));
       	Test.stopTest();       	
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(2, c.size());
    }
    
    // Duplicate a non duplicated contract. / Supplier with status non "active".
    static testmethod void uTest5_nonDuplicatedContract_InactiveSupplier_Failed() {
    	init();
    	supplier.Status__c = 'Inactive';
    	update supplier;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
    	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(1, c.size());
    }
    
    // Duplicate a non duplicated contract. / Nego Scope is non "active".
    static testmethod void uTest6_nonDuplicatedContract_InactiveNegoScope_Failed() {
    	init();
    	NS.Status__c = 'Inactive';
    	update NS;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
    	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
    	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(1, c.size());
    }
    
    // Duplicate a non duplicated contract. / Tactite reconduction is unchecked.
    static testmethod void uTest7_nonDuplicatedContract_UncheckedTactite_Failed() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = False;
    	insert contract;
    	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
    	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(1, c.size());
    }
    
    // Duplicate a non duplicated contract with related conditions. / All NS "Active".
    static testmethod void uTest8_nonDuplicatedContractWithConditions_AllNSActive_Success() {
    	init();
        // Insert two NS.
        Sup_sup_NegoScope__c negoScope2 = TestDataFactory.createNS(false, supplier.Id);
        negoScope2.Is_All_Brands__c = true;
        negoScope2.Is_All_HE__c = true;
        Sup_sup_NegoScope__c negoScope3 = TestDataFactory.createNS(false, supplier.Id);
        negoScope3.Is_All_Brands__c = true;
        negoScope3.Is_All_HE__c = true;
        negoScope3.Status__c = 'Inactive';
        insert new List<Sup_sup_NegoScope__c>{negoScope2, negoScope3};
    	country.Country_Zone_origin__c = region.Id;
    	update country;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
    	// Insert Policy - Tariff conditions.
    	Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
    	// Insert conditions.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 2;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition2.Value_per__c = 3;
		condition2.Product_Scope__c = negoScope2.Id;
		Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition3.Value_per__c = 4;
		condition3.Product_Scope__c = negoScope3.Id;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	List<Contract_Discount__c> cond = [SELECT Id FROM Contract_Discount__c];
       	System.assertEquals(7, c.size() + cond.size());
    }
    
    // Duplicate a non duplicated contract with related conditions. / All BU "Active".
    static testmethod void uTest9_nonDuplicatedContractWithConditions_AllBUActive_Success() {
    	init();
    	country.Country_Zone_origin__c = region.Id;
    	update country;
    	Orga_BU__c listBU = TestDataFactory.createBUList(false, country.Id);
    	listBU.Status__c = 'Inactive';
    	insert listBU;
    	// Insert Country.
        Orga_BU__c country2 = TestDataFactory.createBUCountry(true, myCountry, region.Id);
		// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
    	// Insert Policy - Tariff conditions.
    	Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
    	// Insert conditions.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 2;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition2.Value_per__c = 3;
		condition2.BU_Scope__c = country2.Id;
		Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition3.Value_per__c = 4;
		condition3.BU_Scope__c = listBU.Id;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();       	
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	List<Contract_Discount__c> cond = [SELECT Id FROM Contract_Discount__c];
       	System.assertEquals(7, c.size() + cond.size());
    }
    
    // Duplicate a non duplicated contract. / The contract dates should remain the same, only the year should be updated to take into consideration N+1.
    static testmethod void uTest10_nonDuplicatedContract_ContractYearIncrement_Success() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id, Contract_BDate__c, Contract_EDate__c FROM Contract__c
   								WHERE CALENDAR_YEAR(Contract_BDate__c) =: year+1 AND CALENDAR_YEAR(Contract_EDate__c) =: year+1];
       	System.assertEquals(1, c.size());
    }
    
    // Duplicate a non duplicated contract with related conditions.
    // The conditions dates should remain the same, only the year should be updated to take into consideration N+1.
    static testmethod void uTest11_nonDuplicatedContractWithConditions_ConditionsYearIncrement_Success() {
    	init();
    	country.Country_Zone_origin__c = region.Id;
    	update country;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
    	// Insert Policy - Tariff conditions.
    	Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
    	// Insert conditions.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 2;
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition2.Value_per__c = 2;
		condition2.BU_Scope__c = country.Id;
		Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition3.Value_per__c = 2;
		condition3.BU_Scope__c = country.Id;
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract_Discount__c> cond = [SELECT Id, Disc_BDate__c, Disc_EDate__c FROM Contract_Discount__c
   											WHERE CALENDAR_YEAR(Disc_BDate__c) =: year AND CALENDAR_YEAR(Disc_EDate__c) =: year];
       	System.assertEquals(3, cond.size());
    }
    
    // Duplicate a non duplicated contract with related conditions. / The conditions status should be Validated.
    static testmethod void uTest12_nonDuplicatedContractWithConditions_ValidatedConditionsStatus_Success() {
    	init();
    	country.Country_Zone_origin__c = region.Id;
    	update country;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
    	// Insert Policy - Tariff conditions.
    	Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(true, 0, 1);
    	// Insert conditions.
    	Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition1.Value_per__c = 2;
		condition1.Status__c = 'Validated';
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition2.Value_per__c = 2;
		condition2.Status__c = 'Validated';
		Contract_Discount__c condition3 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
		condition3.Value_per__c = 2;
		condition3.Status__c = 'Validated';
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract_Discount__c> cond = [SELECT Id, Status__c FROM Contract_Discount__c
       										WHERE CALENDAR_YEAR(Disc_BDate__c) =: year AND CALENDAR_YEAR(Disc_EDate__c) =: year AND Status__c = 'Validated'];
       	System.assertEquals(3, cond.size());
    }
    
    // Duplicate a non duplicated contract. / contract type is not a contract.
    static testmethod void uTest13_nonDuplicatedContract_ContractTypeDiffContract_Failed() {
    	init();
    	country.Country_Zone_origin__c = region.Id;
    	update country;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	contract.Contract_Type__c = 'Target';
    	insert contract;
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();       	
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(1, c.size());
    }   
    
    // Duplicate a non duplicated contract. / Contract type is "Simulation" and contract status = "Validated".
    static testmethod void uTest14_nonDuplicatedContract_ContractTypeIsSimulatyion1_Failed() {
    	init();
    	country.Country_Zone_origin__c = region.Id;
    	update country;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	contract.Contract_Type__c = 'Simulation';
    	contract.Status__c = 'Validated';
    	insert contract;
       	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();       	
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(1, c.size());
    }
    
    // Duplicate a non duplicated contract. / Contract type is "Simulation" and contract status = "Request for approval".
    static testmethod void uTest15_nonDuplicatedContract_ContractTypeIsSimulatyion2_Failed() {
    	init();
    	country.Country_Zone_origin__c = region.Id;
    	update country;
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	contract.Contract_Type__c = 'Simulation';
    	contract.Status__c = 'Request for approval';
    	insert contract;
    	// Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, null));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(1, c.size());
    }
    
    // D/N is not Null.
    static testmethod void uTest16_successDuplication_DNNotNull_N() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	insert contract;
        // Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, contract.D_N__c));
       	Test.stopTest();
       	// Assertion.
       	Contract__c c = [SELECT D_N__c FROM Contract__c WHERE Id !=: contract.Id];
       	System.assertEquals('N', c.D_N__c);
    }
    
    // D/N is not Null.
    static testmethod void uTest17_successDuplication_DNNotNull_D() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	contract.D_N__c = 'D';
    	insert contract;
        // Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, contract.D_N__c));
       	Test.stopTest();
       	// Assertion.
       	Contract__c c = [SELECT D_N__c FROM Contract__c WHERE Id !=: contract.Id];
       	System.assertEquals('D', c.D_N__c);
    }
    
    // D/N is Null.
    static testmethod void uTest18_successDuplication_DNIsNull() {
    	init();
    	// Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
    	contract.Tactite_reconduction__c = True;
    	contract.D_N__c = Null;
    	insert contract;
        // Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, contract.D_N__c));
       	Test.stopTest();
       	// Assertion.
       	Contract__c c = [SELECT D_N__c FROM Contract__c WHERE Id !=: contract.Id];
       	System.assertEquals(Null, c.D_N__c);
    }
    
    // controlOnBULevel = True/False.
    static testmethod void uTest19_controlOnBULevel_False() {
    	init();
    	// Get the folder settings.
        Folder folder = NegoptimHelper.getFolderSettings();
        // Create Document
        if (folder != null) {
            String str = '{"tOGapTolerencePositive":0,"tOGapTolerenceNegative":0,"reminderValue3":0,"reminderValue2":0,"reminderValue1":0,"reminderLevel":0,"reminderDescription3":"","reminderDescription2":"","reminderDescription1":"","profile":null,"groupBU2":null,"groupBU1":null,"groupBU":null,"delimiter":",","datesOverlapControlBU":false,"coopGapTolerencePositive":0,"coopGapTolerenceNegative":0}';
            Document document = TestDataFactory.createDocument(true, folder.Id, str);
        }
        // Insert contract.
    	Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 3, 31));
    	contract.Tactite_reconduction__c = True;
    	contract.D_N__c = Null;
    	insert contract;
    	Contract__c contract2 = TestDataFactory.createContract(false, NS, date.newInstance(year, 4, 1), date.newInstance(year, 6, 28));
    	contract2.Tactite_reconduction__c = True;
    	contract2.D_N__c = Null;
    	contract2.Parent_Contract__c = contract.Id;
    	insert contract2;
        // Start test.
       	Test.startTest();
       	Database.executeBatch(new DuplicateContractBatch('DuplicateContractBatchTest', country.Id, new List<Id>{contract.Id}, year, null, null, contract.D_N__c));
       	Test.stopTest();
       	// Assertion.
       	List<Contract__c> c = [SELECT Id FROM Contract__c];
       	System.assertEquals(2, c.size());
    }
}