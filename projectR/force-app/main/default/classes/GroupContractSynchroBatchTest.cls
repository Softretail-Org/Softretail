@isTest
private class GroupContractSynchroBatchTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c groupEMC;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c warehouse;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Group__c cGroup1;
    private static Contract_Group__c cGroup2;
    private static Contract_Group_Detail__c cGroupD1;
    private static Contract_Group_Detail__c cGroupD2;
    
    static public void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Group.
            groupEMC = TestDataFactory.createGroupBU(false, 'EMC');
            groupEMC.Name = 'EMC';
            groupEMC.BU_Code__c = 'EMC';
            insert groupEMC;
            // Create Region
            region = TestDataFactory.createBURegion(false, 'MEA');
            insert region;
            // Create Country
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Warehouse
            warehouse = TestDataFactory.createWarehouseBU(false, country.Id);
            warehouse.Ext_id__c = 'w1';
            insert warehouse;
            // Create supplier.
	        supplier = TestDataFactory.createSupplier(false, country, true);
	        insert supplier;
	        // Get the default negoscope created on supplier creation.
	        NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            insert tariffCondition;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // Contract group is not linked - Type: Contract.
    // Expectation: Add new contract.
    static testmethod void scenario1_1() {
    	init();
        cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Number__c = '16gty', Contract_Year__c = year,
                                        Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
                                        Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
                                        End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
                                        Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC', Origin_Stock_owner__c = 'w1',
                                        Stock_owner__c = warehouse.Id);
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c[0].get('cCount'));
        Contract__c contract = [SELECT Id, Stock_owner__c FROM Contract__c LIMIT 1];
        System.assertEquals(warehouse.Id, contract.Stock_owner__c);
    }
    
    // Contract group is not linked - Type: Contract.
    // Expectation: Update on contract group status from "Validated" to "Synchronized".
    static testmethod void scenario1_2() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
		
        Contract_Group__c cG = [SELECT status__c FROM Contract_Group__c WHERE Id = :cGroup1.Id];
        System.assertEquals('Synchronized', cG.Status__c);
    }
    
    // Contract group is not linked - Type: Contract.
    // Expectation: Update on contract group status from "Deleted" to "Synchronized as deleted".
    static testmethod void scenario1_3() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Deleted', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
		
        Contract_Group__c cG = [SELECT status__c FROM Contract_Group__c WHERE Id = :cGroup1.Id];
        System.assertEquals('Synchronized as deleted', cG.Status__c);
    }
    
    // Contract group is not linked - Type: Prorogation.
    // Expectation: Update on contract group status from "Validated" to "Synchronized".
    static testmethod void scenario1_4() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Prorogation', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c[0].get('cCount'));
    }
    
    // Contract group is not linked - Type: Prorogation.
    // Expectation: Update on contract group status from "Validated" to "Synchronized".
    static testmethod void scenario1_5() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Prorogation', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        Contract_Group__c cG = [SELECT status__c FROM Contract_Group__c WHERE Id = :cGroup1.Id];
        System.assertEquals('Synchronized', cG.Status__c);
    }
    
    // Contract group is not linked - Type: Prorogation.
    // Expectation: Update on contract group status from "Deleted" to "Synchronized as deleted".
    static testmethod void scenario1_6() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Deleted', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Prorogation', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        System.assertEquals('Synchronized as deleted', [SELECT status__c FROM Contract_Group__c WHERE Id = :cGroup1.Id].Status__c);
    }
    
    // Contract group is not linked - Type: Contract.
    // Expectation: Status of the inserted contract is "Signed".
    static testmethod void scenario1_7() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        System.assertEquals('Signed', [SELECT Status__c FROM Contract__c].Status__c);
    }
    
    // Contract group is linked - Contract linked field: invalid value.
    // Expectation: No new contract to add.
    static testmethod void scenario2_1() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), contract_linked__c = 'a090Y000005qNdxqqqq',
        									Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(0, c[0].get('cCount'));
    }
    
    // Contract group is linked - Contract linked field: invalid value.
    // Expectation: Update on contract group status from "Validated" to "Error during synchro".
    static testmethod void scenario2_2() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), contract_linked__c = 'a090Y000005qNdxqqqq',
        									Origin_BU__c = 'EMC');
        insert cGroup1;
        
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        System.assertEquals('Error during synchro', [SELECT status__c FROM Contract_Group__c WHERE Id = :cGroup1.Id].Status__c);
    }
    
    // Contract group is not linked - contract group detail is not linked - status is validated.
    // Expectation: Add new contract, Add new Contract discount.
    static testmethod void scenario3_1() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Validated', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id );
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c1 = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c1[0].get('cCount'));
        
        AggregateResult[] c2 = [SELECT Count(Id) cCount FROM Contract_Discount__c];
        System.assertEquals(1, c2[0].get('cCount'));
    }
    
    // Contract group is not linked - contract group detail is not linked - status is validated.
    // Expectation: Status of the inserted contract and contract discount is "Signed".
    static testmethod void scenario3_2() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Validated', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id );
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        System.assertEquals('Synchronized', [SELECT status__c FROM Contract_Group__c WHERE Id = :cGroup1.Id].Status__c);
        System.assertEquals('Synchronized', [SELECT status__c FROM Contract_Group_Detail__c WHERE Id = :cGroupD1.Id].Status__c);
        System.assertEquals('Signed', [SELECT Status__c FROM Contract__c].Status__c);
        System.assertEquals('Signed', [SELECT Status__c FROM Contract_Discount__c].Status__c);
    }
    
    // Contract group is not linked - contract group detail is not linked - status is Deleted.
    // Expectation: Status of the inserted contract and contract discount is "Deleted".
    static testmethod void scenario3_3() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Deleted', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Deleted', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id );
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        System.assertEquals('Synchronized as deleted', [SELECT status__c FROM Contract_Group__c WHERE Id = :cGroup1.Id].Status__c);
        System.assertEquals('Synchronized as deleted', [SELECT status__c FROM Contract_Group_Detail__c WHERE Id = :cGroupD1.Id].Status__c);
        System.assertEquals('Deleted', [SELECT Status__c FROM Contract__c].Status__c);
        System.assertEquals('Deleted', [SELECT Status__c FROM Contract_Discount__c].Status__c);
    }
    
    // Contract group is linked - Contract linked field: valid value.
    // Condition group detail is linked - condition linked field: valid value.
    static testmethod void scenario4() {
    	init();
    	// Create contract.
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2.5, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert condition;
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), contract_linked__c = contract.Id, Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Validated', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id, condition_linked__c = condition.Id);
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c1 = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c1[0].get('cCount'));
        
        AggregateResult[] c2 = [SELECT Count(Id) cCount FROM Contract_Discount__c];
        System.assertEquals(1, c2[0].get('cCount'));
    }
    
    // Contract group is linked - Contract linked field: valid value.
    // Condition group detail is not linked.
    static testmethod void scenario5() {
    	init();
    	// Create contract.
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 2, 28), Value_per__c = 2.5, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert condition;
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 12, 31), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), contract_linked__c = contract.Id, Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Validated', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 2, 28),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id);
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c1 = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c1[0].get('cCount'));
        
        AggregateResult[] c2 = [SELECT Count(Id) cCount FROM Contract_Discount__c];
        System.assertEquals(2, c2[0].get('cCount'));
    }
    
    // Contract group is linked - Contract linked field: invalid value.
    // Condition group detail is linked - Condition linked field: valid value.
    static testmethod void scenario6() {
    	init();
    	// Create contract.
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2.5, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert condition;
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), contract_linked__c = 'uuu', Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Validated', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id, condition_linked__c = condition.Id);
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c1 = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c1[0].get('cCount'));
        
        AggregateResult[] c2 = [SELECT Count(Id) cCount FROM Contract_Discount__c];
        System.assertEquals(1, c2[0].get('cCount'));
    }
    
    // Contract group is linked - Contract linked field: invalid value.
    // Condition group detail is linked - Condition linked field: invalid value.
    static testmethod void scenario7() {
    	init();
    	// Create contract.
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2.5, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert condition;
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), contract_linked__c = 'uuu', Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Validated', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id, condition_linked__c = 'ooo');
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c1 = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c1[0].get('cCount'));
        
        AggregateResult[] c2 = [SELECT Count(Id) cCount FROM Contract_Discount__c];
        System.assertEquals(1, c2[0].get('cCount'));
    }
    
    // Contract group is not linked.
    // Condition group detail is not linked - Status: Deleted.
    static testmethod void scenario8() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Deleted', Contract_Number__c = '16gty', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Deleted', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id );
        insert cGroupD1;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c1 = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c1[0].get('cCount'));
        
        AggregateResult[] c2 = [SELECT Count(Id) cCount FROM Contract_Discount__c];
        System.assertEquals(1, c2[0].get('cCount'));
    }
    
    // Contract group is linked - Contract linked field: valid value.
    // Condition group detail is linked - Contract linked field: valid value.
    // Delete condition before run the batch.
    static testmethod void scenario9() {
    	init();
    	// Create contract.
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                  Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 2, 28), Value_per__c = 2.5, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert condition;
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), contract_linked__c = contract.Id, Origin_BU__c = 'EMC');
        insert cGroup1;
        cGroupD1= new Contract_Group_Detail__c(Contract_List_Group__c = cGroup1.Id, Status__c = 'Validated', Origin_Disc_Code__c = 'C1',
        								Origin_Disc_Code2__c = 'C1', Origin_Disc_name__c = 'Rebate',
    									Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 1, 1),
    									Order_Number__c = 2, Line_Integration_Status__c = 'New', Last_Integration_date__c =  date.newInstance(year, 1, 1),
    									Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_name__c = tariffCondition.Id, condition_linked__c = condition.Id);
        insert cGroupD1;
        delete condition;
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        
        AggregateResult[] c1 = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c1[0].get('cCount'));
        
        AggregateResult[] c2 = [SELECT Count(Id) cCount FROM Contract_Discount__c];
        System.assertEquals(1, c2[0].get('cCount'));
    }
    
    // Contract group is not linked. Take only the selected rows.
    static testmethod void method1() {
    	init();
    	cGroup1 = new Contract_Group__c(Name = 'Goup contract' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup1;
        
        cGroup2 = new Contract_Group__c(Name = 'Goup contract2' + year, Status__c = 'Validated', Contract_Year__c = year,
        									Origin_Supplier_Code__c = '125', Origin_Supplier__c = 'Supplier', Supplier__c = supplier.Id,
        									Supplier_NegoScope__c = NS.Id, Start_Date__c = date.newInstance(year, 1, 1),
        									End_date__c = date.newInstance(year, 1, 1), Contract_type__c = 'Contract', Header_Integration_Status__c = 'New',
        									Last_Integration_Date__c = date.newInstance(year, 1, 1), Origin_BU__c = 'EMC');
        insert cGroup2;
        
        List<Id> ids = new List<Id>();
        ids.add(cGroup1.Id);
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, ids, Null));
        Test.stopTest();
        
        AggregateResult[] c = [SELECT Count(Id) cCount FROM Contract__c];
        System.assertEquals(1, c[0].get('cCount'));
    }
}