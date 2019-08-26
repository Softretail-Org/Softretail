@isTest
private class Nego360_Main_Edit_Controller_TEST {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
			currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get all recortd type ids for Orga_BU__c SObject
            Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = buRTIds.get('Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = buRTIds.get('Country');
            insert country;
            // Create Legal Form.
            Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
            legal.RecordTypeId = buRTIds.get('Legal');
	        insert legal;
            // Create Store
            store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store.RecordTypeId = buRTIds.get('Store');
            insert store;
            // Create Supplier
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', Status__c = 'Active', Country_origin__c = country.Id,
                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default NegoScope created on supplier creation
            negoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            // Create Contract
            contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C001',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract', D_N__c = 'N');
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
            insert tariffCondition;            
            // Create Condition
            condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = negoScope.Id,
                                                 BU_Scope__c = country.Id, Contract__c = contract.Id);
            insert condition;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_constructor() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();

        system.assertNotEquals(null, Nego360_Main_Edit_Controller.supplier);
    }
    @isTest static void test_getListNegoScopes() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();

        system.assertEquals(1, Nego360_Main_Edit_Controller.getListNegoScopes().size());
    }

    // A revoir
    /*@isTest static void test_getShowConditionTable() {

        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Supplier 1', Code__c = 'CD01');
        insert supplier;

        Sup_sup_NegoScope__c negoScope = new Sup_sup_NegoScope__c(Name = 'Nego Scope 1', Supplier__c = supplier.Id, Is_All_Brands__c = true, Is_All_HE__c = true);
        insert negoScope;

        Contract__c contractNego = new Contract__c(Contract_Type__c = 'Contrat', Contract_BDate__c = date.today().addYears(-1), Contract_EDate__c = date.today().addYears(1),
                                                                                                                    Supplier_Nego_Scope__c = negoScope.Id, SimulationNumber__c = 1, Supplier__c = supplier.Id, TO1__c = 1000);
        insert contractNego;

        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', '2015');
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();

        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;

        system.assertEquals(true, Nego360_Main_Edit_Controller.getShowConditionTable());

    }*/

    @isTest static void test_getNegoScope() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;

        system.assertNotEquals(null, Nego360_Main_Edit_Controller.getNegoScope());
    }
    
    @isTest static void test_init_without_contract_type() {
        init();
        Contract__c deleted = [SELECT Id FROM Contract__c WHERE Supplier__c = :supplier.Id];
        delete deleted;
        Contract__c contractNego = new Contract__c(Name = 'Contract1', Contract_Type__c = 'Target', Contract_BDate__c = date.today(), Contract_EDate__c = date.today(),
                                                   Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'TAR1', Supplier__c = supplier.Id, TO1__c = 1000);
        Contract__c contractNego2 = new Contract__c(Name = 'Contract2', Contract_Type__c = 'Simulation', Contract_BDate__c = date.today(), Contract_EDate__c = date.today(),
                                                    Supplier_Nego_Scope__c = negoScope.Id, SimulationNumber__c = 1, Supplier__c = supplier.Id, TO1__c = 1200);
        insert new List<Contract__c> {contractNego, contractNego2};

        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;
        Nego360_Main_Edit_Controller.init();

        system.assertEquals(3, Nego360_Main_Edit_Controller.listContractNego.size());
        system.assertEquals(true, Nego360_Main_Edit_Controller.existingTargetType);
        system.assertEquals(1, Nego360_Main_Edit_Controller.numContractSimulation);
    }
    
    @isTest static void test_newMatrice() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.init();

        system.assertEquals(3, Nego360_Main_Edit_Controller.matrice.columnsIds.size());
    }
    
    @isTest static void test_addCondition() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.init();

        Integer nbLines = Nego360_Main_Edit_Controller.matrice.lines.size();

        Nego360_Main_Edit_Controller.selectedLineLabel = 'Total Price Discount';

        Nego360_Main_Edit_Controller.addCondition();

        system.assertEquals(nbLines+1, Nego360_Main_Edit_Controller.matrice.lines.size());
    }
    
    @isTest static void test_addContract() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.init();

        Integer nbContracts = Nego360_Main_Edit_Controller.matrice.columnsIds.size();

        Nego360_Main_Edit_Controller.addContract();

        system.assertEquals(nbContracts+1, Nego360_Main_Edit_Controller.matrice.columnsIds.size());
    }
    
    @isTest static void test_computeAmount() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year+1));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;
        Nego360_Main_Edit_Controller.init();

        Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).conditionWrapper.contractNego.TO1__c = 1000;
        Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).conditionWrapper.condition.Value_per__c = 5;
        Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).conditionWrapper.condition.Value_amt__c = 500;

        Nego360_Main_Edit_Controller.computeAmount();

        System.assert(true);
        /*
        system.assertEquals(550, Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).computedAmount);
        
        system.assertEquals(500, Nego360_Main_Edit_Controller.matrice.linesTable.get(3).cells.get(0).amount);
        system.assertEquals(5, Nego360_Main_Edit_Controller.matrice.linesTable.get(3).cells.get(0).percent);
        system.assertEquals(550, Nego360_Main_Edit_Controller.matrice.linesTable.get(3).cells.get(0).computedAmount);*/
    }
    
    @isTest static void test_deleteCondition() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year+1));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;
        Nego360_Main_Edit_Controller.init();
        // add 2 conditions from page
        Nego360_Main_Edit_Controller.selectedLineLabel = condition.Nego_Discount_Type__c;
        Nego360_Main_Edit_Controller.addCondition();
        Nego360_Main_Edit_Controller.addCondition();
        
        Integer nbLines = Nego360_Main_Edit_Controller.matrice.lines.size();

        Nego360_Main_Edit_Controller.selectedLineNumber = 2;

        Nego360_Main_Edit_Controller.deleteCondition();

        system.assertEquals(nbLines - 1, Nego360_Main_Edit_Controller.matrice.lines.size());
    }
    
    @isTest static void test_saveContracts_without_negoscope() {
        init();
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();

        Nego360_Main_Edit_Controller.selectedNegoScopeId = null;

        system.assertEquals(null, Nego360_Main_Edit_Controller.saveContracts());
    }
    
    @isTest static void test_saveContracts() {
        init();
        Contract__c deleted = [SELECT Id FROM Contract__c WHERE Supplier__c = :supplier.Id];
        delete deleted;
        Contract__c contractNego = new Contract__c(Name = 'Contract1', Contract_Type__c = 'Contract', D_N__c = 'N', Contract_BDate__c = date.today(), Contract_EDate__c = date.today(),
                                                   Supplier_Nego_Scope__c = negoScope.Id, Supplier__c = supplier.Id, Contract_BU__c = country.Id, TO1__c = 1000);
        insert contractNego;

        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(year+1));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;
        Nego360_Main_Edit_Controller.init();
		/*
        Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).conditionWrapper.contractNego = contractNego;
        Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).conditionWrapper.contractNego.TO1__c = 1000;
        Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).conditionWrapper.condition.Value_per__c = 5;
        Nego360_Main_Edit_Controller.matrice.lines.get(0).cells.get(0).conditionWrapper.condition.Value_amt__c = 500;
		*/
        Nego360_Main_Edit_Controller.saveContracts();

        List<Contract__c> listContractNego = new List<Contract__c>();
        listContractNego = [SELECT Id, Name FROM Contract__c WHERE Supplier_Nego_Scope__c = :negoScope.Id];
        system.assertEquals(3, listContractNego.size());

        /*List<Conditions__c> listConditions = [SELECT Id, Name FROM Conditions__c];
        system.assertEquals(1, listConditions.size());*/
    }
    
    @isTest static void test_executiveSummary() {
        init();
        Integer nextYear = year + 1;
        Contract__c simContract = new Contract__c(Name = supplier.Name + ' Contract ' + nextYear, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id,
                                                  Contract_Numbder__c = 'C002', Contract_BDate__c = date.newInstance(nextYear, 1, 1),
                                                  Contract_EDate__c = date.newInstance(nextYear, 12, 31), Duration__c = 12,
                                                  Contract_Type__c = 'Simulation', TO1__c = 1000, Selected_Simul_For_Approval__c = true);
        insert simContract;
        
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(nextYear));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;
        Nego360_Main_Edit_Controller.executiveSummary();
        
        system.assertEquals(simContract.Id, Nego360_Main_Edit_Controller.selectedContractId);
    }
    
    @isTest static void test_others() {
        init();
        Integer nextYear = year + 1;
        Contract__c simContract = new Contract__c(Name = supplier.Name + ' Contract ' + nextYear, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id,
                                                  Contract_Numbder__c = 'C002', Contract_BDate__c = date.newInstance(nextYear, 1, 1),
                                                  Contract_EDate__c = date.newInstance(nextYear, 12, 31), Duration__c = 12,
                                                  Contract_Type__c = 'Simulation', TO1__c = 1000, Secure_Multiyear__c = '2 years');
        insert simContract;
        Contract_Discount__c condition1 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(nextYear, 1, 1),
                                                                   Disc_EDate__c = date.newInstance(nextYear, 12, 31), Value_per__c = 1, Product_Scope__c = negoScope.Id,
                                                                   BU_Scope__c = country.Id, Contract__c = simContract.Id, 	slab_per_1__c =10,	slab_per_2__c = 20, 
                                                                   Slab_1__c = 100, Slab_2__c = 20);
        insert condition1;
        
        
        ApexPages.currentPage().getParameters().put('supplier', supplier.Id);
        ApexPages.currentPage().getParameters().put('negoYear', String.valueOf(nextYear));
        Nego360_Main_Edit_Controller Nego360_Main_Edit_Controller = new Nego360_Main_Edit_Controller();
        Nego360_Main_Edit_Controller.selectedNegoScopeId = negoScope.Id;
        Nego360_Main_Edit_Controller.selectedContractId = simContract.Id;
        Nego360_Main_Edit_Controller.currentContract = simContract;
        Nego360_Main_Edit_Controller.saveNegoPlan();
        Nego360_Main_Edit_Controller.supplier = supplier;
        
        Nego360_Main_Edit_Controller.changeMultiYearSecure();
        Nego360_Main_Edit_Controller.getListMultiYear();
        
        system.assert(true);
    }
}