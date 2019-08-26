/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers related to contracts  */
@isTest
private class Trg_Nego360_SaleConditionException_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract1;
    private static Contract__c contract2;
    private static Pol_Sale_Condition__c saleCond1;
    private static Pol_Sale_Condition__c saleCond2;
    
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
        	// Create supplier.
	        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active',
	        						Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
	        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
	        insert supplier;
	        // Get the default negoscope created on supplier creation.
	        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        	NS.Is_All_Brands__c = True;
        	NS.Is_All_HE__c = True;
        	update NS;
            // Create contract.
            contract1 = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C0A1',
                                        Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                        Contract_Type__c = 'Contract', Duration_type__c = 'Month');
            contract2 = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C0A2',
                                        Contract_BDate__c = date.newInstance(year, 7, 1), Contract_EDate__c = date.newInstance(year, 7, 30), Duration__c = 1, Contract_BU__c = country.Id,
                                        Contract_Type__c = 'Contract', Duration_type__c = 'Month');	
            insert new List<Contract__c> {contract1, contract2};
            saleCond1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance(year, 1, 1), Master_BU__c = country.Id,VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');  
            saleCond2 = new Pol_Sale_Condition__c(Name='Sales Condition 2', Status_BDate__c = date.newInstance(year, 1, 1), Master_BU__c = country.Id,VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');  
            insert new List<Pol_Sale_Condition__c> {saleCond1, saleCond2};
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
	// Test passing VAT values from sales condition to contract after creation of  sales cond execption
    @isTest static void test_createContractVATExCondition() {
        init();
        contract1.Contract_BDate__c = date.newInstance(year, 2, 1);
        contract1.Contract_EDate__c = date.newInstance(year, 6, 1);
        contract1.Duration__c = 5;
        update contract1;
        saleCond1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c=date.newInstance(year, 1, 1), Master_BU__c = country.Id,
	        									VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,  Status__c = 'Validated');  
        insert saleCond1;
        Pol_Sale_Condition_Exception__c salesCondEx = new Pol_Sale_Condition_Exception__c(Contract__c = contract1.Id,
    														Policy_Sales_Conditions__c = saleCond1.Id, Version__c  = 1);
        insert salesCondEx;
        Contract__c Contract = [SELECT Id, VAT_Rebate_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        // Assertion.
        System.assertEquals(saleCond1.VAT_Rebate_Rate__c, Contract.VAT_Rebate_Rate__c);
    }
    
	// Test passing VAT values from sales condition to contract after creation of  sales cond exception.
    @isTest static void test_createMultyContractVATExCondition() {
        init();
        Pol_Sale_Condition_Exception__c salesCondEx = new Pol_Sale_Condition_Exception__c(Contract__c = contract1.Id, Policy_Sales_Conditions__c = saleCond1.Id, Version__c  = 1);  
        Pol_Sale_Condition_Exception__c salesCondEx2 = new Pol_Sale_Condition_Exception__c(Contract__c = contract2.Id, Policy_Sales_Conditions__c = saleCond2.Id, Version__c  = 1);  
        insert new List<Pol_Sale_Condition_Exception__c> {salesCondEx, salesCondEx2};
        Contract__c con = [SELECT Id, VAT_Rebate_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        Contract__c con2 = [SELECT Id, VAT_Rebate_Rate__c FROM Contract__c WHERE Id = :contract2.Id];
        // Assertion.
        System.assertEquals(saleCond1.VAT_Rebate_Rate__c, con.VAT_Rebate_Rate__c);    
        System.assertEquals(saleCond1.VAT_Rebate_Rate__c, con2.VAT_Rebate_Rate__c);
    }
}