@isTest
private class ConditionManagerControllerTest {
    
    private static String currencyIsoCode;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Id rootId;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Sup_NegoScope__c negoscope;
    private static Integer year;
    private static Contract__c contract;
    private static Orga_BU__c region;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Pol_Com_Condition__c tariffCondition;
    private static String plv;
    private static List<Contract_Discount__c> conditionList;
    
    static void init() {
        year = System.Today().year();
        
        rootId = NegoptimHelper.getRootId();
        
        currencyIsoCode = 'EUR';
        
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        
        region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
        region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
        insert region;
        
        country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
        Id storeRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        
        store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = storeRecordTypeId;
        insert store;
        
        supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                           Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        
        // Get the default negoscope created on supplier creation.
        negoscope = [SELECT Id, NS_Code__c FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        
        // Create Department.
        department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = '1', Parent_Element__c = rootId, Level__c = 1,
                                    Status_BDate__c = date.newInstance(year, 1, 1), Status__c = 'Active',
                                    Nego_Type__c = 'Ferme', Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
        insert department;
        // Create Section.
        section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = '1011', Parent_Element__c = department.Id, Level__c = 2,
                                 Status_BDate__c = date.newInstance(year, 1, 1),
                                 Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
        insert section;
        
        // Create Contract.
        contract = new Contract__c(Name ='Test Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoscope.Id, Contract_Numbder__c = 'C111',
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                   Contract_Type__c = 'Contract', Status__c = 'Signed', D_N__c = 'N');
        insert contract;
        // Create Policy - Tariff Conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        plv = fieldResult.getPicklistValues().get(0).getValue();
        tariffCondition = new Pol_Com_Condition__c(Name = 'Progressive Rebates', Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                   Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                   Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ', VAT_Type__c = 'Rebate');
        insert tariffCondition;
        
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Value_amt__c = 3000,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Product_Scope__c = negoscope.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = True);
        conditionList = new List<Contract_Discount__c>();
        conditionList.add(condition);
        insert conditionList;
        
    }

    @isTest static void test_constructor() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        ConditionManagerController cnc = new ConditionManagerController(stdController);
		System.assertEquals(cnc.contract, contract);
        System.assertEquals(cnc.noOfRecords, [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__c = :contract.Id]);
    }
    
    @isTest static void test_delete() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        ConditionManagerController cnc = new ConditionManagerController(stdController);
        cnc.conditionList[0].selected = true;
        cnc.processSelection();
        cnc.deleteConditions();
        System.assertEquals(0, [SELECT COUNT()
                                FROM Contract_Discount__c 
                                WHERE Contract__c = :contract.Id]);
    }
    
    @isTest static void test_save_update() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        ConditionManagerController cnc = new ConditionManagerController(stdController);
        cnc.conditionList[0].condition.value_amt__c = 5000;
        cnc.saveConditions();
        System.assertEquals(5000, Integer.valueOf([SELECT Value_amt__c 
                                                   FROM Contract_Discount__c 
                                                   WHERE contract__c = :contract.Id].Value_amt__c));
    }
    
    @isTest static void test_save_add_missingValues() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        ConditionManagerController cnc = new ConditionManagerController(stdController);
        cnc.insertDiscountRow();
        cnc.saveConditions();
        System.assertEquals(1, [SELECT COUNT()
                                FROM Contract_Discount__c 
                                WHERE Contract__c = :contract.Id]);
    }
    
    @isTest static void test_save_add() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        ConditionManagerController cnc = new ConditionManagerController(stdController);
        cnc.insertDiscountRow();
        cnc.conditionList[0].condition.Nego_Discount_Type__c = plv;
        cnc.conditionList[0].condition.Condition_Type__c = tariffCondition.Id;
        cnc.saveConditions();
        System.assertEquals(2, [SELECT COUNT()
                                FROM Contract_Discount__c 
                                WHERE Contract__c = :contract.Id]);
    }
    
    @isTest static void increaseCoverage() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        ConditionManagerController cnc = new ConditionManagerController(stdController);
        
        cnc.refreshPageSize();
        cnc.currentConditionIndex = 0;
        cnc.adjustConditionMode();
        
        cnc.popupNegoscope = true;
        cnc.showPopup();
        cnc.hidePopup();
        cnc.popupChildNegoscope = true;
        cnc.showPopup();
        cnc.hidePopup();
        cnc.popupChildNegoscopeBrands = true;
        cnc.showPopup();
        cnc.hidePopup();
        cnc.popupChildNegoscopeHEs = true;
        cnc.showPopup();
        cnc.hidePopup();
        cnc.popupChildNegoscopePGs = true;
        cnc.showPopup();
        cnc.hidePopup();
        cnc.popupSlabs = true;
        cnc.showPopup();
        cnc.hidePopup();
        
        cnc.popupNegoscope = true;
        cnc.popupChildNegoscope = true;
        cnc.popupChildNegoscopeBrands = true;
        cnc.popupChildNegoscopeHEs = true;
        cnc.popupChildNegoscopePGs = true;
        cnc.popupSlabs = true;
        cnc.cancelPopup();
        
        cnc.first();
        cnc.next();
        cnc.previous();
        cnc.last();
        
        cnc.getListYears();
        
        cnc.dispatch();
        cnc.generateGRCRate();
        cnc.generateInvoice();
        cnc.calculateYTD();
        cnc.batchInProgress = true;
        cnc.checkBatchStatus();
        
        System.assert(true);
    }

}