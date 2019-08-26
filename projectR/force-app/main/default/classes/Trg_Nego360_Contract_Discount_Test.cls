/*
 * This class contains unit tests for validating the behavior of Apex classes and triggers related to conditions.
 **/
@isTest
private class Trg_Nego360_Contract_Discount_Test {
	
	private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static Pol_Com_Condition__c tariffCondition;
    
	static void init() {
    	try {
    		year = System.Today().year();
			// Get the Corporate Currency.
			currencyIsoCode = NegoptimHelper.getCorporateCurrency();
			// Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
			// Create supplier.
	        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
	        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
	        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
	        insert supplier;
	        // Get the default negoscope created on supplier creation.
	        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create sale condition.
            Pol_Sale_Condition__c saleCondition = new Pol_Sale_Condition__c(Name = country.Name + ' ' + year, Status_BDate__c = date.newInstance(year, 1, 1),
                                                                            Master_BU__c = country.Id, VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,
                                                                            Buying_Payment_Condition__c = 'Net', Buying_Payment_Days__c = '90', Status__c = 'Validated');
            insert saleCondition;
	        // Create contract.
	        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C0A1',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                       Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode,
                                       Status__c = 'Signed', D_N__c = 'N', Tactite_reconduction__c = True, Duration_type__c= 'Month',
                                       TO1__c = 10, TO2__c = 10, TO3__c = 10, TO4__c = 10,
                                       TO1_Fact__c = 10, TO2_Fact__c = 10, TO3_Fact__c = 10, TO4_Fact__c = 10,
                                       TO1_FX__c = 10, TO2_FX__c = 10, TO3_FX__c = 10, TO4_FX__c = 10,
                                       Qty1__c = 20, Qty2__c = 20, Qty3__c = 20, Qty4__c = 20, Qty5__c = 20, Qty6__c = 20,
                                       Qty7__c = 20, Qty8__c = 20, Qty9__c = 20, Qty10__c = 20,  Qty11__c = 20,  Qty12__c = 20,
                                       Qty1_Fact__c = 20, Qty2_Fact__c = 20, Qty3_Fact__c = 20, Qty4_Fact__c = 20, Qty5_Fact__c = 20, Qty6_Fact__c = 20,
                                       Qty7_Fact__c = 20, Qty8_Fact__c = 20, Qty9_Fact__c = 20, Qty10_Fact__c = 20, Qty11_Fact__c = 20, Qty12_Fact__c = 20);
            insert contract;
	        // Create Policy - Tariff conditions.
	        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
	        String plv = fieldResult.getPicklistValues().get(2).getValue();
	        tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
	                                                   Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
	                                                   Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ',
	                                                   Index__c = 'Index1', Is_Conditional__c = false);
	        insert tariffCondition;
    	} catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }

    /*
	 * Assign Base To on contract level when the scope respects the current update. / Scope: False to True.
	 * @methodName assignBaseTOs
     * @param List<Contract_Discount__c>, Map<Id, Contract_Discount__c> oContractMap.
     * On Before Insert Or Before Update.
     **/
    @isTest static void case1_assignBaseTO() {
    	init();
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        insert condition;
    	condition.Disc_EDate__c = date.newInstance(year, 12, 31);
    	// Start test.
    	Test.startTest();
        Database.SaveResult result = Database.update(condition, false);
        Test.stopTest();
        // Assertion.
    	Contract_Discount__c cond = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
									FROM Contract_Discount__c
									WHERE Id = :condition.Id];
        System.assertEquals(40, cond.Base_TO_Nego__c);
        System.assertEquals(40, cond.Base_TO_Actual__c);
        System.assertEquals(40, cond.Base_TO_Forecast__c);
    }
    
    /*
	 * Assign Base To on contract level when the scope respects the current update. / Scope: True to False.
	 * @methodName assignBaseTOs
     * @param List<Contract_Discount__c>, Map<Id, Contract_Discount__c> oContractMap.
     * On Before Insert Or Before Update.
     **/
    @isTest static void case2_assignBaseTOs() {
    	init();
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        insert condition;
    	condition.Disc_EDate__c = date.newInstance(year, 12, 30);
    	condition.Base_TO_Nego__c = 0;
    	condition.Base_TO_Actual__c = 0;
    	condition.Base_TO_Forecast__c = 0;
    	// Start test.
    	Test.startTest();
        Database.SaveResult result = Database.update(condition, false);
        Test.stopTest();
        // Assertion.
    	Contract_Discount__c cond = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
									FROM Contract_Discount__c
									WHERE Id = :condition.Id];
        System.assertEquals(0, cond.Base_TO_Nego__c);
        System.assertEquals(0, cond.Base_TO_Actual__c);
        System.assertEquals(0, cond.Base_TO_Forecast__c);
    }
    
    // assignmentAndNSControl method.
    @isTest static void case3_assignBeforeStatusDeleted() {
    	init();
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Value_amt__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Deletion_Action_Executed__c = '');        
        insert condition;
    	condition.Status__c = 'Deleted';
    	// Start test.
    	Test.startTest();
        update condition;
        Test.stopTest();
        // Assertion.
    	Contract_Discount__c cond = [SELECT Id, Value_per__c, Value_amt__c, Deletion_Action_Executed__c
									FROM Contract_Discount__c
									WHERE Id = :condition.Id];
        System.assertEquals(0, cond.Value_per__c);
        System.assertEquals(0, cond.Value_amt__c);
        System.assertEquals('Cond value to 0 put to 0. Balance invoice generated', cond.Deletion_Action_Executed__c);
    }
    
    // Assign contract ISO code into the condition ISO Code.
    // Assign contract payment condition into the condition payment condition.
    // Assign contract payment days into the condition payment days.
    @isTest static void case4_assignContractFieldsToCondition() {
    	init();
    	// Create condition.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        insert condition;
		// Start test.
		Test.startTest();
        Database.insert(condition, false);
        Test.stopTest();
        // Assertion.
        String paymentDays = NegoptimHelper.defaultPicklistValue(Contract_Discount__c.Payment_Days__c.getDescribe());
        String paymentCondition = NegoptimHelper.defaultPicklistValue(Contract_Discount__c.Payment_Condition__c.getDescribe());
		condition = [SELECT CurrencyIsoCode, Payment_Condition__c, Payment_Days__c FROM Contract_Discount__c];
		System.assertEquals('EUR', condition.CurrencyIsoCode);
		System.assertEquals(paymentDays, condition.Payment_Days__c); // '90'
        System.assertEquals(paymentCondition, condition.Payment_Condition__c); // 'Net'
    }
    
    // Assign contract ISO code into the condition ISO Code.
    @isTest static void case5_assignmentISOCurrency_Bulk() {
    	init();
    	// Create conditions.
    	List<Contract_Discount__c> conds = new List<Contract_Discount__c>();
    	for (Integer i=1 ; i < 6 ; i ++) {
			condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, CurrencyIsoCode = currencyIsoCode);
			conds.add(condition);
		}
		// Start test.
		Test.startTest();
        Database.insert(conds, false);
        Test.stopTest();
        // Assertion.
		List<Contract_Discount__c> selectedConds = [SELECT CurrencyIsoCode FROM Contract_Discount__c];
		for (Contract_Discount__c selectedCond : selectedConds) {
			System.assertEquals('EUR', selectedCond.CurrencyIsoCode);
		}
    }
    
    /**
     * Set Invoice Base to null when the index is equal to "Index1". Single/Bulk. (Success)
     * @param List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap
     * On Before Insert.
     **/
    @isTest static void case6_setInvoiceBaseToNull() {
    	init();
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted');        
        insert condition;
        // Assertion.
        Contract_Discount__c selectedCond = [select index__c, Invoice_base__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals('Index1', selectedCond.index__c);
        System.assertEquals(Null, selectedCond.Invoice_base__c);
    }
    
    /**
     * Set Invoice Base to null when the index is equal to "Index1". Single/Bulk. (Failed)
     * @param List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap
     * On Before Insert.
     **/
    @isTest static void case7_setInvoiceBaseToNull() {
    	init();
    	tariffCondition.index__c = 'Index2';
    	update tariffCondition;
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted');        
        insert condition;
        // Assertion.
        Contract_Discount__c selectedCond = [select index__c, Invoice_base__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals('Index2', selectedCond.index__c);
        System.assertEquals('Forecasted', selectedCond.Invoice_base__c);
    }
    
    // Slab_Calc_Method_TO_Origin__c is Actual, slab_calc_method__c = TO
    @isTest static void case8_reachProgressiveSlab() {
        init();
        tariffCondition.Is_Conditional__c = true;
        update tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 7, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 20.2,
                                             slab_per_1__c = 3, slab_calc_method__c  = 'TO', Slab_Calc_Method_TO_Origin__c = 'Actual');        
        insert condition;
        // Assertion.
        Contract_Discount__c selectedCond = [select Value_per__c, slab_reach_actual__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals(1, selectedCond.slab_reach_actual__c);
        System.assertEquals(3, selectedCond.Value_per__c);
    }
    
    // Slab_Calc_Method_TO_Origin__c is Nego, slab_calc_method__c = TO
    @isTest static void case9_reachProgressiveSlab() {
        init();
        tariffCondition.Is_Conditional__c = true;
        update tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 7, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Nego__c = 20.2,
                                             slab_per_1__c = 3, slab_calc_method__c = 'TO', Slab_Calc_Method_TO_Origin__c = 'Nego');        
        insert condition;
        // Assertion.
        Contract_Discount__c selectedCond = [select Value_per__c, slab_reach_nego__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals(1, selectedCond.slab_reach_nego__c);
        System.assertEquals(3, selectedCond.Value_per__c);
    }
    
    // Insert case.
    @isTest static void case10_setIsDuplicable() {
    	init();
    	tariffCondition.Nego_Discount_Type__c = 'Penalties';
        tariffCondition.Condition_Duplication__c = 'F';
    	update tariffCondition;
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted', is_duplicable__c = false, Value_amt__c = 100);
        Test.startTest();
        insert condition;
        Test.stopTest();
        // Assertion.
        Contract_Discount__c selectedCond = [select is_duplicable__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals(true, selectedCond.is_duplicable__c);
    }
    
    // assignmentAndNSControl method: NS Control. Already_Invoiced__c Not Null.
    @isTest static void case11_NSControl() {
    	init();
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Value_amt__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Deletion_Action_Executed__c = '', Already_Invoiced__c = 2000);
        insert condition;
		Sup_sup_NegoScope__c NS2 = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id);    	
		insert NS2;
		condition.Product_Scope__c = NS2.Id;
    	// Start test.
    	Test.startTest();
        Database.SaveResult result = Database.update(condition, false);
        //update condition;
        Test.stopTest();
        // Assertion.
    	System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        Contract_Discount__c selectedCond = [SELECT Name FROM Contract_Discount__c WHERE Id = :condition.Id];
        System.assertEquals('You cannot change the negoscope for the condition "' + selectedCond.Name + '" because it has related invoices.', result.getErrors()[0].getMessage());
    }
    
    @isTest static void case12_cleanInvoicesWhenValidUnchecked() {
    	init();
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                             Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 30),
                                             Value_per__c = 2, Value_amt__c = 2, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                             Deletion_Action_Executed__c = '', Already_Invoiced__c = 0, Valid__c = true);
        insert condition;
        // Invoice 1
        Invoice__c invoice1 = new Invoice__c(Inv_Contract__c = contract.Id, Inv_Business_Unit__c = country.Id, Inv_Date__c = Date.newInstance(year, 4, 1),
                                             Inv_Supplier__c = supplier.Id, Inv_FiscalYear__c = year, Inv_Status__c = 'Generated',
                                             Acc_Document_Type__c = tariffCondition.Acc_Document_Type__c, origin__c = 'BU', Ext_id__c = '12345');
        // Invoice 2
        Invoice__c invoice2 = invoice1.clone(false, false, false, false);
        invoice2.Inv_Status__c = 'Printed';
        invoice2.Ext_id__c = '67890';
        // Invoice Detail 1
        Invoice_Detail__c invoiceDetail1 = new Invoice_Detail__c(Discount__c = condition.Id, Inv_Detail_BU__c = condition.BU_Scope__c,
                                                                 Inv_Detail_Condition__c = condition.Condition_Type__c,
                                                                 Invoice_detail_nego_disc_type__c = condition.Nego_Discount_Type__c,
                                                                 Invoice_Value__c = 100);
        // Invoice Detail 2
        Invoice_Detail__c invoiceDetail2 = invoiceDetail1.clone(false, false, false, false);
        invoiceDetail2.Invoice_Value__c = 200;
        Invoice__c invoiceReference1 = new Invoice__c(Ext_id__c = invoice1.Ext_id__c);
        Invoice__c invoiceReference2 = new Invoice__c(Ext_id__c = invoice2.Ext_id__c);
        invoiceDetail1.Invoice__r = invoiceReference1;
        invoiceDetail2.Invoice__r = invoiceReference2;
        Database.insert(new List<SObject>{invoice1, invoice2, invoiceDetail1, invoiceDetail2});
        
        System.assertEquals(2, [SELECT COUNT() FROM Invoice__c]);
        
    	// Start test
    	Test.startTest();
        condition.Valid__c = false;
        Database.SaveResult result = Database.update(condition, false);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Invoice__c]);
    }
    // case update Total_Counterparts_to_Justify__c on before Insert/Update.
    @isTest static void case13_setTotalCounterpartJustify() {
    	init();
    	tariffCondition.Proof_counterparty_requested__c = true;
    	update tariffCondition;
    	// Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id, Invoice_base__c = 'Forecasted', is_duplicable__c = false,
                                             Value_amt__c = 100, Base_Quantity_Nego__c  = 5, unit_amount__c = 5);
        Test.startTest();
        insert condition;
        Test.stopTest();
        // Assertion.
        condition = [select Total_Counterparts_to_Justify__c, YTD_Nego__c from Contract_Discount__c where Id = :condition.Id];
        System.assertEquals(condition.YTD_Nego__c, condition.Total_Counterparts_to_Justify__c);
    }
}