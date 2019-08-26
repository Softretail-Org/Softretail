/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers for pg insertion inside NS1 page
*/
@isTest
private class Trg_Org_Supplier_NS_PG_Test {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Id rootId;
    private static Sup_Supplier__c supplier;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Supplier_PG_Mapping__c PG1;
    private static Supplier_PG_Mapping__c PG2;
    private static Sup_Brand__c brand;
    private static Sup_sup_NegoScope__c NS1;
    private static Sup_sup_NegoScope__c NS2;
    private static Sup_NS_PG__c NSPG1;
    private static Sup_NS_PG__c NSPG2;
    
    static void init() {
        try {
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Create Supplier
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001' , CurrencyIsoCode = currencyIsoCode, Is_Default_NegoScope__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
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
	        // Create Legal Form.
	        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
	        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
	        insert legal;
	        // Create Store
	        store = new Orga_BU__c(Name = 'Store', BU_Code__c = 'STR', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
	        store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
	        insert store;
            // Create Department
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Elt Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Section        
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c = false);
            insert section;
            // Create brand 
            brand = new Sup_Brand__c(Name = 'Brand 1', Brand_Owner__c = supplier.Id);
            insert brand;
            // Create PGs.
            PG1 = new Supplier_PG_Mapping__c(Name = 'PG 1', SNA_Code__c = '123', GIMA_Code__c = '1', Brand__c = brand.Id,Department__c = department.Id, Section__c = section.Id, Supplier__c = supplier.Id);
            PG2 = new Supplier_PG_Mapping__c(Name = 'PG 2', SNA_Code__c = '124', GIMA_Code__c = '2', Brand__c = brand.Id,Department__c = department.Id, Section__c = section.Id, Supplier__c = supplier.Id);
            insert new List<Supplier_PG_Mapping__c>{PG1, PG2};
            // Create NS1
            NS1 = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All__c = false, Is_All_Brands__c = false, Is_All_HE__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert NS1;
            NS2 = new Sup_sup_NegoScope__c(Name = 'Nego Scope 2', Supplier__c = supplier.Id, Is_All__c = false, Is_All_Brands__c = false, Is_All_HE__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert NS2;
            //Create negosope pg
            NSPG1 = new Sup_NS_PG__c(Sup_PG__c = PG1.Id, Supplier__c = supplier.Id, Sup_sup_NegoScope__c = NS1.Id);
            NSPG2 = new Sup_NS_PG__c(Sup_PG__c = PG2.Id, Supplier__c = supplier.Id, Sup_sup_NegoScope__c = NS2.Id);
            insert new List<Sup_NS_PG__c>{NSPG1, NSPG2};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Test validation  prevent adding prouct group on NS1 page 
    @isTest static void test_createPgNegoScope() {
        init();
        Sup_NS_PG__c NSPG2 = new Sup_NS_PG__c(Sup_PG__c =PG1.Id, Supplier__c = supplier.Id, Sup_sup_NegoScope__c = NS1.Id);
        Test.startTest();        
        Database.SaveResult result = Database.insert(NSPG2, false); 
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Product_Group_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
    }
    
    // Test validation  prevent updating product group on NS1 page 
    @isTest static void test_updatePgNegoScope() {
        init();
        Sup_NS_PG__c NSPG2 = new Sup_NS_PG__c(Sup_PG__c =PG2.Id, Supplier__c = supplier.Id, Sup_sup_NegoScope__c = NS1.Id);
        insert NSPG2;
        Sup_NS_PG__c selectedPgNegoScope= [SELECT id,Sup_PG__c FROM Sup_NS_PG__c WHERE id = :NSPG1.Id ];
        selectedPgNegoScope.Sup_PG__c = PG2.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(selectedPgNegoScope, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Product_Group_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
    }
    
    // Test validation  prevent addin same brand on NS1 page on mass mode 
    @isTest static void test_CreateMultiPGNegoScope() {
        init();
        List<Sup_NS_PG__c> lstPgNegoscope = new List<Sup_NS_PG__c>();
        Sup_NS_PG__c NSPG2 = new Sup_NS_PG__c(Sup_PG__c =PG1.Id, Supplier__c = supplier.Id, Sup_sup_NegoScope__c = NS1.Id);
        Sup_NS_PG__c negoScopePg3 = new Sup_NS_PG__c(Sup_PG__c =PG1.Id, Supplier__c = supplier.Id, Sup_sup_NegoScope__c = NS1.Id);
        lstPgNegoscope.add(NSPG2);
        lstPgNegoscope.add(negoScopePg3);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstPgNegoscope, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
            System.assert(!result.isSuccess());
            System.assert(result.getErrors().size() > 0);
            System.assertEquals(System.Label.MSG_Product_Group_Alaready_Exist_Negoscope, result.getErrors()[0].getMessage());
        }
    }
    
    // Control on NS_PG deleting regarding the corresponding dispatch details: prevent NSPG to Delete.
    @isTest static void preventNSPGToDelete() {
    	init();
    	// Create contract.
    	Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS1.Id, Contract_Numbder__c = 'C0A1',
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode,
                                   Status__c = 'Signed', D_N__c = 'N', Tactite_reconduction__c = True, Duration_type__c= 'Month');
		insert contract;
		// Create policy-tariff condition.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1),
        						Condition_Code__c = 'C1', Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ',
        						Name_Fi__c = 'Fi ', Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
    	// Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
        						Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 3, 31),
        						Contract__c = contract.Id, Product_Scope__c = NS1.Id, BU_Scope__c = country.Id);
    	insert condition;
        // Create Dispatch Head.
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = 1, Inv_Fiscal_Year__c = year, Inv_BU__c = country.Id);
        insert dispatchHead;
        // Create Dispatch Detail.
        Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Inv_DispatchHead__c = dispatchHead.Id, Supplier__c = supplier.Id, Contract__c = contract.Id,
                                                                                                 Discount__c = condition.Id, Inv_BUDispatch__c = store.Id, Hierarchy_level_dispatch__c = section.Id,
                                                                                                 Base_TO_Dispatch__c = 0, PG__c = PG1.Id, Status__c = 'New', Sequence__c = 1);
        insert dispatchDetail;
        DmlException expectedException;
        Test.startTest();
        try {
            delete NSPG1;
        } catch (DmlException dmx) {
            expectedException = dmx;
        }
        Test.stopTest();
        system.assertEquals(2, [SELECT count() FROM Sup_NS_PG__c]);
    	system.assertNotEquals(Null, expectedException);
    }
    
    // Control on NS_PG deleting regarding the corresponding dispatch details: allow NSPG to Delete.
    @isTest static void allowNSPGToDelete() {
    	init();
    	// Create contract.
    	Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS1.Id, Contract_Numbder__c = 'C0A1',
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode,
                                   Status__c = 'Signed', D_N__c = 'N', Tactite_reconduction__c = True, Duration_type__c= 'Month');
		insert contract;
		// Create policy-tariff condition.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1),
        						Condition_Code__c = 'C1', Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ',
        						Name_Fi__c = 'Fi ', Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
    	// Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
        						Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 3, 31),
        						Contract__c = contract.Id, Product_Scope__c = NS1.Id, BU_Scope__c = country.Id);
    	insert condition;
        // Create Dispatch Head.
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = 1, Inv_Fiscal_Year__c = year, Inv_BU__c = country.Id);
        insert dispatchHead;
        // Create Dispatch Detail.
        Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Inv_DispatchHead__c = dispatchHead.Id, Supplier__c = supplier.Id, Contract__c = contract.Id,
                                                                                                 Discount__c = condition.Id, Inv_BUDispatch__c = store.Id, Hierarchy_level_dispatch__c = section.Id,
                                                                                                 Base_TO_Dispatch__c = 0, PG__c = PG2.Id, Status__c = 'New', Sequence__c = 1);
        insert dispatchDetail;
        Test.startTest();
        delete NSPG1;
        Test.stopTest();
        system.assertEquals(1, [SELECT count() FROM Sup_NS_PG__c]);
    }
}