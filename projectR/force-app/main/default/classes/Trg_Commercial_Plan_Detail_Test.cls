/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for Commercial Plan Detail
*/
@isTest
private class Trg_Commercial_Plan_Detail_Test {
    
    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Commercial_Plan__c commercialPlan;
    private static Commercial_Plan_Detail__c commercialPlanDetail;
    
    static void init() {
        try {
            // Insert Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Insert Region.
            Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
            // Insert Country.
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Insert group BU.
            groupBU = TestDataFactory.createGroupBU(false, 'EMC');
            groupBU.Country_Zone_origin__c = region.Id;
            insert groupBU;
            // Insert Supplier.
            Sup_Supplier__c supplier = TestDataFactory.createSupplier(true, country, true);
	        // Get the default negoscope created on supplier creation.
	    	NS = TestDataFactory.getNSs(supplier.Id)[0];
		    // Insert contract.
	    	contract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-4), System.Today().addMonths(-2));
        	contract.Total_Marketing_Events_Justified__c = 0;
        	contract.Last_Active_Contract__c = TRUE;
            insert contract;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    // Test Creation of Commercial Plan Detail with Countrat is NULL
    // and Event_Start_Date__c Less Than Last Contract_BDate__c
    @isTest static void test_InsertCommercialPlanDetailWithContractIsNull() {
        init();
        // Insert CommercialPlan.
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today().addMonths(-5), System.Today().addMonths(-4));
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        Test.startTest();
        insert commercialPlanDetail;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail = [SELECT Id, Temp_Contract_Reference__c FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail.Id];
        contract = [SELECT Id, Name, Contract_Numbder__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(commercialPlanDetail.Temp_Contract_Reference__c, contract.Contract_Numbder__c +' - '+ contract.Name);
    }
    // Test Creation of Commercial Plan Detail with Countrat is NULL 
    // the fetch the most recent contract related to the Nego_Scope__c
    @isTest static void test_InsertCommercialPlanDetailWithLastActiveContractNS() {
        init();
        // Insert CommercialPlan.
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today().addMonths(-2), System.Today() + 1);
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        Test.startTest();
        insert commercialPlanDetail;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail = [SELECT Id, Contract__c FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(commercialPlanDetail.Contract__c, contract.Id);
    }
    @isTest static void test_UpdateDateExceptionCommercialPlanDetail() {
        init();
        // Insert CommercialPlan.
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today().addMonths(-3), System.Today() + 1);
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(true, commercialPlan.Id, NS);
        Test.startTest();
        commercialPlanDetail.Start_Date_exception__c = System.Today();
        commercialPlanDetail.End_Date_exception__c = System.Today() + 1;
        update commercialPlanDetail;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail = [SELECT Id, Contract__c FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(commercialPlanDetail.Contract__c, null);
    }
    // Case 2: Test Updating of Commercial Plan Detail with Countrat is changed and Management of fields changed.
    @isTest static void test_UpdateCommercialPlanDetailWithStatutNotDeleted() {
        init();
        // Insert CommercialPlan With Date < Today
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today() - 7, System.Today() - 1);
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail.Statut__c = 'Contract Edited';
        commercialPlanDetail.Temp_Contract_Reference__c = 'Contact Reference...';
        commercialPlanDetail.Line_Status__c = 'New';
        insert commercialPlanDetail;
        // Insert new contract with Group BU and Last_Active_Contract__c = TRUE
    	Contract__c newContract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addMonths(1));
        newContract.Contract_BU__c = groupBU.Id;
        newContract.Last_Active_Contract__c = TRUE;
        newContract.Total_Marketing_Events_Justified__c = 0;
        insert newContract;
        Test.startTest();
        commercialPlanDetail.Contract__c = newContract.Id;
        commercialPlanDetail.Extraction_Status__c = 'Extracted';
        update commercialPlanDetail;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail = [SELECT Id, Temp_Contract_Reference__c, Contract__c, Line_Status__c, Extraction_Status__c
                                FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(commercialPlanDetail.Temp_Contract_Reference__c, NULL);
        System.assertEquals(commercialPlanDetail.Extraction_Status__c, 'Extract');
        System.assertEquals(commercialPlanDetail.Line_Status__c, 'Updated');
    }
    // Case 2: Test Updating of Commercial Plan Detail with Countrat is changed and Management of fields changed.
    @isTest static void test_UpdateCommercialPlanDetailWithStatutDeleted() {
        init();
        // Insert CommercialPlan With Date < Today
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today() - 7, System.Today() - 1);
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail.Statut__c = 'Deleted';
        commercialPlanDetail.Temp_Contract_Reference__c = 'Contact Reference...';
        commercialPlanDetail.Line_Status__c = 'New';
        insert commercialPlanDetail;
        // Insert new contract with Group BU and Last_Active_Contract__c = TRUE
        Contract__c newContract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addMonths(1));
        newContract.Contract_BU__c = groupBU.Id;
        newContract.Last_Active_Contract__c = TRUE;
        newContract.Total_Marketing_Events_Justified__c = 0;
        insert newContract;
        Test.startTest();
        commercialPlanDetail.Contract__c = newContract.Id;
        commercialPlanDetail.Extraction_Status__c = 'Extracted';
        update commercialPlanDetail;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail = [SELECT Id, Temp_Contract_Reference__c, Contract__c, Line_Status__c, Extraction_Status__c
                                FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail.Id];
        System.assertEquals(commercialPlanDetail.Temp_Contract_Reference__c, NULL);
        System.assertEquals(commercialPlanDetail.Line_Status__c, 'Deleted');
    }
    // Case 3: Test Updating of Commercial Plan Detail with Countrat is changed and Management of fields changed.
    @isTest static void test_UpdateCommercialPlanDetailWithEndDateTomorrow() {
        init();
        // Insert commercialPlan With Date < Today
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today().addMonths(-7), System.Today() + 1);
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        // Insert CommercialPlan Detail.
        commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail.Statut__c = 'Contract Edited';
        commercialPlanDetail.Temp_Contract_Reference__c = 'Contact Reference...';
        commercialPlanDetail.Line_Status__c = 'New';
        insert commercialPlanDetail;
        // Insert new contract with Group BU and Last_Active_Contract__c = TRUE
        Contract__c newContract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addMonths(1));
        newContract.Contract_BU__c = groupBU.Id;
        newContract.Last_Active_Contract__c = TRUE;
        newContract.Total_Marketing_Events_Justified__c = 0;
        insert newContract;
        Test.startTest();
        commercialPlanDetail.Contract__c = newContract.Id;
        update commercialPlanDetail;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail = [SELECT Id, Temp_Contract_Reference__c, Contract__c, Line_Status__c, Extraction_Status__c
                                FROM Commercial_Plan_Detail__c WHERE Id =: commercialPlanDetail.Id];
        System.assertEquals(commercialPlanDetail.Extraction_Status__c, 'Extract');
    }
    // Update Total_Marketing_Events_Justified__c based on update Contribution_Total__c
    @isTest static void test_CaseUpdateTotalMarketingEventsJustifiedContract() {
        init();
        // Insert contracts.
        Contract__c contract1 = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addMonths(1));
        contract1.TO1__c = 1;
        contract1.TO2__c = 2;
        contract1.TO3__c = 3;
        contract1.TO1_Fact__c = 1;
        contract1.TO2_Fact__c = 2;
        contract1.TO3_Fact__c = 3;
        Contract__c contract2 = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addMonths(1));
        contract2.TO1__c = 1;
        contract2.TO2__c = 2;
        contract2.TO3__c = 3;
        contract2.TO4__c = 4;
        contract2.TO1_Fact__c = 1;
        contract2.TO2_Fact__c = 2;
        contract2.TO3_Fact__c = 3;
        contract2.TO4_Fact__c = 4;
        insert new List<Contract__c>{contract1, contract2};
        // Insert commercialPlan With Date < Today
        commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today() - 7, System.Today() + 1);
        commercialPlan.Name = 'Marketing Media001';
        commercialPlan.BU_Target__c = country.Id;
        insert commercialPlan;
        // Insert CommercialPlan Details.
        Commercial_Plan_Detail__c commercialPlanDetail1 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail1.Statut__c = 'Contract Edited';
        commercialPlanDetail1.Temp_Contract_Reference__c = 'Contact Reference...';
        commercialPlanDetail1.Line_Status__c = 'New';
        commercialPlanDetail1.Contribution_Unit_Amount__c = 5;
        commercialPlanDetail1.Contribution_Unit_Quantity__c = 10;
        
        Commercial_Plan_Detail__c commercialPlanDetail2 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail2.Statut__c = 'Contract Edited';
        commercialPlanDetail2.Temp_Contract_Reference__c = 'Contact Reference...';
        commercialPlanDetail2.Line_Status__c = 'New';
        commercialPlanDetail2.Contribution_Unit_Amount__c = 5;
        commercialPlanDetail2.Contribution_Unit_Quantity__c = 10;
        commercialPlanDetail2.Contract__c = contract1.Id;
        
        Commercial_Plan_Detail__c commercialPlanDetail3 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        commercialPlanDetail3.Statut__c = 'Contract Edited';
        commercialPlanDetail3.Temp_Contract_Reference__c = 'Contact Reference...';
        commercialPlanDetail3.Line_Status__c = 'New';
        commercialPlanDetail3.Contribution_Unit_Amount__c = 1;
        commercialPlanDetail3.Contribution_Unit_Quantity__c = 10;
        commercialPlanDetail3.Contract__c = contract1.Id;
        insert new List<Commercial_Plan_Detail__c>{commercialPlanDetail1, commercialPlanDetail2, commercialPlanDetail3};
        
        Test.startTest();
        commercialPlanDetail1.Contribution_Unit_Amount__c = 2;
        commercialPlanDetail1.Contract__c = contract1.Id;
        commercialPlanDetail2.Contribution_Unit_Amount__c = 3;
        commercialPlanDetail2.Contract__c = contract2.Id;
        update new List<Commercial_Plan_Detail__c>{commercialPlanDetail1, commercialPlanDetail2};
        delete commercialPlanDetail3;
        Test.stopTest();
        // Validation Test
        commercialPlanDetail1 = [SELECT Id, Contribution_Total__c FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail1.Id LIMIT 1];
        commercialPlanDetail2 = [SELECT Id, Contribution_Total__c FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail2.Id LIMIT 1];
        contract1 = [SELECT Id, Total_Marketing_Events_Justified__c, Status__c FROM Contract__c WHERE Id = :contract1.Id LIMIT 1];
        contract2 = [SELECT Id, Total_Marketing_Events_Justified__c, Status__c FROM Contract__c WHERE Id = :contract2.Id LIMIT 1];
        System.assertEquals(contract1.Total_Marketing_Events_Justified__c, commercialPlanDetail1.Contribution_Total__c);
        System.assertEquals(contract2.Total_Marketing_Events_Justified__c, commercialPlanDetail2.Contribution_Total__c);
    }
}