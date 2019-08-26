@isTest
private class Nego360_ExecutiveSummary_Controller_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Contract__c contract;
    private static Contract__c simulationContract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition1;
    
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
            // Create Department
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Section
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1));
            insert section;
            // Create Contract
            contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C001',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract', D_N__c = 'N');
            insert contract;
            // Create Simulation Contract
            Integer nextYear = year + 1;
            simulationContract = new Contract__c(Name = supplier.Name + ' - Round ' + nextYear, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id,
                                                 Contract_BDate__c = date.newInstance(nextYear, 1, 1), Contract_EDate__c = date.newInstance(nextYear, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                                 Contract_Type__c = 'Simulation', D_N__c = 'N', Parent_Contract__c = contract.Id);
            insert simulationContract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
            insert tariffCondition;            
            // Create Condition
            condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = negoScope.Id,
                                                  BU_Scope__c = country.Id, Contract__c = contract.Id);
            insert condition1;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    // Success test
    @isTest static void test_constructor1() {
        init();
        ApexPages.currentPage().getParameters().put('id', simulationContract.Id);
        Nego360_ExecutiveSummary_Controller ctrlr = new Nego360_ExecutiveSummary_Controller();
        Contract__c c = [SELECT Id, Name, Reference_Year__c, Contract_BU__c, Status__c, CreatedBy.Name,
                         Supplier_Nego_Scope__c, Supplier__c, Parent_Contract__c, Contract_Type__c
                         FROM Contract__c
                         WHERE Id = :simulationContract.Id];
        system.assertEquals(c, ctrlr.simulationContract);
    }
    // Invalid Id
    @isTest static void test_constructor2() {
        init();
        ApexPages.currentPage().getParameters().put('id', 'ABCDEF');
        Nego360_ExecutiveSummary_Controller ctrlr = new Nego360_ExecutiveSummary_Controller();
        system.assert(ctrlr.errors.size() > 0);
    }
    //
    @isTest static void test_submitApproval() {
        init();
        Integer nextYear = year + 1;
        // Create Condition
        Contract_Discount__c condition2 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(nextYear, 1, 1),
                                                                   Disc_EDate__c = date.newInstance(nextYear, 12, 31), Value_per__c = 1, Product_Scope__c = negoScope.Id,
                                                                   BU_Scope__c = country.Id, Contract__c = simulationContract.Id);
        insert condition2;
        ApexPages.currentPage().getParameters().put('id', simulationContract.Id);
        Nego360_ExecutiveSummary_Controller ctrlr = new Nego360_ExecutiveSummary_Controller();
        system.assertEquals(1, ctrlr.executiveSummaryMap.size());
        ctrlr.submitApproval();
        String status = [SELECT Status__c FROM Contract__c WHERE Id = :simulationContract.Id].Status__c;
        system.assertEquals(status, ctrlr.simulationContract.Status__c);
    }
    // test Nego360_ES_Pdf_Controller
    @isTest static void test_Nego360_ES_Pdf_Controller() {
        init();
        ApexPages.currentPage().getParameters().put('id', simulationContract.Id);
        Nego360_ES_Pdf_Controller ctrlr = new Nego360_ES_Pdf_Controller();
        
        system.assertEquals(ctrlr.imgLeft, ctrlr.imgLeft);
        system.assertEquals(ctrlr.imgRight, ctrlr.imgRight);
        system.assertEquals(ctrlr.imgUp, ctrlr.imgUp);
        system.assertEquals(ctrlr.imgDown, ctrlr.imgDown);
    }
}