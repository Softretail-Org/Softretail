@isTest
private class ZeroRebatesContractControllerTest {
	
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
    private static List<Supplier_PG_Mapping__c> PGs;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition1;
    private static Contract_Discount__c condition2;
    private static Contract_Discount__c condition3;
    private static Purchases_Flow_PG__c purchase1;
    private static Purchases_Flow_PG__c purchase2;
    private static List<Purchases_Flow_PG__c> purchases;
    private static String plv;
    
    static void init() {
		try {
			year = System.Today().year();
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
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
			// Create Legal Form.
            Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
            legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
	        insert legal;
			// Create Store
            store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
            insert store;
			// Create Department.
			department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1),
										Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
			insert department;
			// Create Section.
			section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Code 1.0', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1),
										Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c = false);
			insert section;
			// Create supplier.
        	supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
	        						Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
	        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
	        insert supplier;
	        // Get the default negoscope created on supplier creation.
	        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
	        // Create PGs.
	        Integer i;
	        PGs = new List<Supplier_PG_Mapping__c>();
	        for(i = 1; i <= 2; i++) {
	            Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG 00' + i, SNA_Code__c = '100' + i, GIMA_Code__c = '100' + i, Department__c = department.Id, Section__c = section.Id, Supplier__c = supplier.Id);
	            PGs.add(PG);
	        }
	        insert PGs;
			// Create contract.
	        contract = new Contract__c(Name ='Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
	                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
	                                   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract');
	        insert contract;
	        // Create Policy - Tariff conditions.
	        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
	        plv = fieldResult.getPicklistValues().get(0).getValue();
	        tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
	                                                   Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
	                                                   Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
	        insert tariffCondition;
	        // Create instances of lists.
	        purchases = new List<Purchases_Flow_PG__c>();
    	} catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    @isTest static void submitReport_WithoutAnyRebate() {
 		init();
 		// Create conditions.
        condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 800, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1000, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1200, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
        // Create Records in Purchases_Flow_PG__c
        purchase1 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(0).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        purchase2 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(1).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        insert new List<Purchases_Flow_PG__c>{purchase1, purchase2};
        ApexPages.currentPage().getParameters().put('selectedCountry', country.Id);
        ApexPages.currentPage().getParameters().put('selectedYear', String.valueof(year));        
        ZeroRebatesContractController zeroRebatesContract = new ZeroRebatesContractController();
        zeroRebatesContract.submitReport();
        system.assertEquals(2, zeroRebatesContract.purchases.size());
    }
    
    @isTest static void submitReport_WithOneOrMoreRebates() {
		init();
 		// Create conditions.
        condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 6, Value_amt__c = 800, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 6, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1200, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
        // Create Records in Purchases_Flow_PG__c
        purchase1 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(0).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        purchase2 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(1).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        insert new List<Purchases_Flow_PG__c>{purchase1, purchase2};
        ApexPages.currentPage().getParameters().put('selectedCountry', country.Id);
        ApexPages.currentPage().getParameters().put('selectedYear', String.valueof(year));        
        ZeroRebatesContractController zeroRebatesContract = new ZeroRebatesContractController();
        zeroRebatesContract.submitReport();
        system.assertEquals(0, zeroRebatesContract.purchases.size());
        ApexPages.Message[] messages = ApexPages.getMessages();        
        System.assert(messages[0].getSummary().contains('There are no contracts with no percentage condition'));
    }
    
    @isTest static void submitReport_WithoutOneOrMorePurchases() {
 		init();
 		// Create conditions.
        condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 800, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1000, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1200, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
        ApexPages.currentPage().getParameters().put('selectedCountry', country.Id);
        ApexPages.currentPage().getParameters().put('selectedYear', String.valueof(year));
        ZeroRebatesContractController zeroRebatesContract = new ZeroRebatesContractController();
        zeroRebatesContract.submitReport();
        system.assertEquals(0, zeroRebatesContract.purchases.size());
        ApexPages.Message[] messages = ApexPages.getMessages();
        System.assert(messages[0].getSummary().contains('There are no contracts with no percentage condition'));
    }
    
    @isTest static void submitReport_WithoutContract() {
    	init();
    	delete contract;
 		// Create Records in Purchases_Flow_PG__c
        purchase1 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(0).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        purchase2 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(1).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        insert new List<Purchases_Flow_PG__c>{purchase1, purchase2};
        ApexPages.currentPage().getParameters().put('selectedCountry', country.Id);
        ApexPages.currentPage().getParameters().put('selectedYear', String.valueof(year));
        ZeroRebatesContractController zeroRebatesContract = new ZeroRebatesContractController();
        zeroRebatesContract.submitReport();
        ApexPages.Message[] messages = ApexPages.getMessages();
        System.assert(messages[0].getSummary().contains('There are no contracts with no percentage condition'));
    }
    
    @isTest static void exportReport_Success() {
        init();
        // Create conditions.
        condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 800, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1000, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1200, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
        // Create Records in Purchases_Flow_PG__c
        purchase1 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(0).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        purchase2 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(1).Id, Department__c = department.Id, Section__c = section.Id,
                                                                  Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                                                  TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                                                  TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
        insert new List<Purchases_Flow_PG__c>{purchase1, purchase2};
        ApexPages.currentPage().getParameters().put('job', 'Export');
        ApexPages.currentPage().getParameters().put('selectedCountry', country.Id);
        ApexPages.currentPage().getParameters().put('selectedYear', String.valueof(year));        
        ZeroRebatesContractController zeroRebatesContract = new ZeroRebatesContractController();
        zeroRebatesContract.exportReport();
        system.assertEquals(true, zeroRebatesContract.isVisible);
    }
    
    @isTest static void exportReport_Failed() {
        init();
        // Create conditions.
        condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 6, Value_amt__c = 800, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 6, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
        condition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 1200, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert new List<Contract_Discount__c>{condition1, condition2, condition3};
        // Create Records in Purchases_Flow_PG__c
        purchase1 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(0).Id, Department__c = department.Id, Section__c = section.Id,
                                             Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                             TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                             TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100,
                                             CurrencyIsoCode = currencyIsoCode);
        purchase2 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(1).Id, Department__c = department.Id, Section__c = section.Id,
                                             Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract.Id, Year__c = year, BU__c = store.Id,
                                             TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100,
                                             TO7__c = 100, TO8__c = 100, TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100,
                                             CurrencyIsoCode = currencyIsoCode);
        insert new List<Purchases_Flow_PG__c>{purchase1, purchase2};
        ApexPages.currentPage().getParameters().put('job', 'Export');
        ApexPages.currentPage().getParameters().put('selectedCountry', country.Id);
        ApexPages.currentPage().getParameters().put('selectedYear', String.valueof(year));
        ZeroRebatesContractController zeroRebatesContract = new ZeroRebatesContractController();
        zeroRebatesContract.exportReport();
        ApexPages.Message[] messages = ApexPages.getMessages();
        System.assert(messages[0].getSummary().contains('There are no contracts with no percentage condition'));
    }
}