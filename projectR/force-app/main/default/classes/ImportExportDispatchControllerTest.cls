@isTest
private class ImportExportDispatchControllerTest {
	
	private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Supplier_PG_Mapping__c PG;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static Integer sequence;
    private static Integer fiscalYear;
    
	static void init() {
    	try {
    		year = System.Today().year();
    		Date dispatchDate = Date.today();
	        sequence = dispatchDate.month() == 1 ? 12 : dispatchDate.month() -1;
	        fiscalYear = dispatchDate.month() == 1 ? dispatchDate.year() -1 : dispatchDate.year();
			// Root Element Id.
			rootId = NegoptimHelper.getRootId();
			// Get the Corporate Currency.
			currencyIsoCode = NegoptimHelper.getCorporateCurrency();
			// Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
			ApexPages.currentPage().getParameters().put('action', 'Export');
			// Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
			// Create Legal Form.
	        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
            legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
	        insert legal;
			// Create Store
            store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
            insert store;
			// Create Department.
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1,
                                        Status_BDate__c = date.newInstance(year, 1, 1),
                                        Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Section.
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Code 1.0', Parent_Element__c = department.Id, Level__c = 2,
                                     Status_BDate__c = date.newInstance(year, 1, 1),
                                     Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
            insert section;
			// Create supplier.
	        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
	        						Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
	        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
	        insert supplier;
	        // Get the default negoscope created on supplier creation.
	        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create PG.
            PG = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG1', SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier.Id);
            insert PG;
            // Create contract.
            contract = new Contract__c(Name ='Test Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract');
	        insert contract;
	        // Create Policy - Tariff conditions.
	        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
	        String plv = fieldResult.getPicklistValues().get(0).getValue();
	        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                                        Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                                        Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        	insert tariffCondition;
        	// Create condition.
        	condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2.5, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Value_amt__c = 12);
        	insert condition;
    	} catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // BU: RecordType is Country.
    @isTest static void test_constructor1() {
    	init();
    	ApexPages.currentPage().getParameters().put('BU', country.Id);
        ApexPages.currentPage().getParameters().put('NS', NS.Id);
        ApexPages.currentPage().getParameters().put('ConditionId', condition.Id);
    	// Create New dispatch head.
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                               Inv_BU__c = country.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        // Create New dispatch Detail.
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id, Contract__c = contract.Id,
                                                                                      Supplier__c = supplier.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id, PG__c = PG.Id,
                                                                                      Status__c = 'New', Sequence__c = sequence, 
                                                                                      CurrencyIsoCode = currencyIsoCode, Inv_DispatchHead__c = dispatchHead.Id);
        insert dispatchDetailsLine;
        ImportExportDispatchController cntrl = new ImportExportDispatchController();
        system.assert(true);
    }
    
    // BU: RecordType is Store.
    @isTest static void test_constructor2() {
    	init();
    	ApexPages.currentPage().getParameters().put('BU', store.Id);
        ApexPages.currentPage().getParameters().put('NS', NS.Id);
        ApexPages.currentPage().getParameters().put('ConditionId', condition.Id);
    	// Create New dispatch head.
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                                   Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        // Create New dispatch Detail.
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id, Contract__c = contract.Id,
                                                                                      Supplier__c = supplier.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id, PG__c = PG.Id,
                                                                                      Status__c = 'New', Sequence__c = sequence, 
                                                                                      CurrencyIsoCode = currencyIsoCode, Inv_DispatchHead__c = dispatchHead.Id);
        insert dispatchDetailsLine;
        ImportExportDispatchController cntrl = new ImportExportDispatchController();
        system.assert(true);
    }
    
    // BU: RecordType is Country - Without Dispatch Detail.
    @isTest static void test_constructor3() {
    	init();
    	ApexPages.currentPage().getParameters().put('BU', country.Id);
        ApexPages.currentPage().getParameters().put('NS', NS.Id);
        ApexPages.currentPage().getParameters().put('ConditionId', condition.Id);
    	// Create New dispatch head.
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                                   Inv_BU__c = country.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        ImportExportDispatchController cntrl = new ImportExportDispatchController();
        system.assert(true);
    }
}