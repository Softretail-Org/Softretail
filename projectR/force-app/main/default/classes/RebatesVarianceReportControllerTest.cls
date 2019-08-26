/**
* An apex class that test report of variance between condition list in this year and previous year
*/
@isTest
private class RebatesVarianceReportControllerTest {
    
    private static Integer year;
    private static Integer previousYear;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Orga_BU__c store;
    private static Contract__c contract;
    private static Contract__c previous_contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Pol_Com_Condition__c tariffCondition2;
    private static Contract_Discount__c condition1;
    private static Contract_Discount__c previous_condition;
    private static Contract_Discount__c condition2;
    private static Contract_Discount__c previous_condition2;
    
    static void init() {
            year = System.Today().year();
            previousYear = year - 1;
            // Root Element Id
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
            // Create Supplier
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true,
	        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default NegoScope created on supplier creation
            negoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            
            // Create Contract
            previous_contract = new Contract__c(Name = supplier.Name + ' - Contract ' + previousYear, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C001',
                                                Contract_BDate__c = date.newInstance(previousYear, 1, 1), Contract_EDate__c = date.newInstance(previousYear, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                                Contract_Type__c = 'Contract');
            insert previous_contract;
            // Create Contract
            contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_Numbder__c = 'C002',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract',Parent_Contract__c = previous_contract.Id);
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            String plv2 = fieldResult.getPicklistValues().get(1).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
            insert tariffCondition;
            tariffCondition2 = new Pol_Com_Condition__c(Name = plv2, Nego_Discount_Type__c = plv2, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C2',
                                                        Abrev__c = 'Cond.1', Gen_Name_com__c = 'Gen com 1', Name_Com__c = 'Com 1', Name_Fi__c = 'Fi 1',
                                                        Name_Leg__c = 'Leg 1', Gen_Name_Fi__c = 'Gen Fi 1', Gen_Name_Leg__c = 'Gen Leg 1');
            insert tariffCondition2;
            // Create Condition
            previous_condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(previousYear, 1, 1),
                                                          Disc_EDate__c = date.newInstance(previousYear, 12, 31), Value_per__c = null, Product_Scope__c = negoScope.Id,
                                                          BU_Scope__c = country.Id, Contract__c = previous_contract.Id);
            insert previous_condition;
            condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = negoScope.Id,
                                                  BU_Scope__c = country.Id, Contract__c = contract.Id ,Reference_condition__c = previous_condition.Id);
            insert condition1;
            // Create Condition
            previous_condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv2, Condition_Type__c = tariffCondition2.Id, Disc_BDate__c = date.newInstance(previousYear, 1, 1),
                                                           Disc_EDate__c = date.newInstance(previousYear, 12, 31), Value_per__c = 3, Product_Scope__c = negoScope.Id,
                                                           BU_Scope__c = country.Id, Contract__c = previous_contract.Id, Reference_condition__c = null);
            insert previous_condition2;
            condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv2, Condition_Type__c = tariffCondition2.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = negoScope.Id,
                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Reference_condition__c = null);
            insert condition2;
    }
    
    @isTest static void testVarianceValueSuccess() {
        init(); 
        ApexPages.currentPage().getParameters().put('country', country.Id);
        ApexPages.currentPage().getParameters().put('year', String.valueof(year));
        RebatesVarianceReportController RebatesVarianceReportController = new RebatesVarianceReportController();
        RebatesVarianceReportController.submitReport();
        system.assertEquals(-3, RebatesVarianceReportController.listWrapperRebatesCondition.get(0).lstVariance.get(0));
        system.assertEquals(1, RebatesVarianceReportController.listWrapperRebatesCondition.get(0).lstVariance.get(1));
    }
    
    @isTest static void testExport() {
        init(); 
        ApexPages.currentPage().getParameters().put('country', country.Id);
        ApexPages.currentPage().getParameters().put('year', String.valueof(year));
        ApexPages.currentPage().getParameters().put('action', 'Export');
        RebatesVarianceReportController RebatesVarianceReportController = new RebatesVarianceReportController();
        RebatesVarianceReportController.exportReport();
        system.assertEquals(true,RebatesVarianceReportController.isExport);
    }
}