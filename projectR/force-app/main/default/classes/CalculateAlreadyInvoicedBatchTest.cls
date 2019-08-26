/**
* Unit Test class used to calculate already invoiced for conditions.
**/
@isTest
private class CalculateAlreadyInvoicedBatchTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    
    static public void init() {
        try {
            year = System.Today().year();
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
            // Create supplier
            supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create Policy - Tariff Conditions.
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ', VAT_Type__c = 'Rebate',
                                                       Acc_Document_Type__c = 'Credit Note Request', Index__c = 'Index2');
            insert tariffCondition;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // calculate already invoiced
    @isTest static void testCalculateAlreadyInvoiced_Success() {
        init();
        // Create init Contract + conditions
        Contract__c contract = new Contract__c(Name = 'Contract001' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
                                               Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                               Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Status__c = 'Signed', CurrencyIsoCode = currencyIsoCode,
                                               D_N__c = 'N', Tactite_reconduction__c = true, Ext_id__c = 'C1');
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Is_Prenego_Envelop__c = True);
        Contract__c contractReferenceC1 = new Contract__c(Ext_id__c='C1');
        condition.Contract__r = contractReferenceC1;
        List<SObject> contractWithConditionsList = new List<SObject>();
        contractWithConditionsList.add(contract);
        contractWithConditionsList.add(condition);
        Database.insert(contractWithConditionsList);
        // Insert Invoice with invoice details
        Invoice__c invoice = new Invoice__c(Inv_Business_Unit__c = country.Id, Acc_Document_Type__c = 'Invoice',
                                            Inv_Contract__c = contract.Id, Inv_Date__c = System.Today(),
                                            Inv_DueDate__c = System.Today().addMonths(2), Inv_FiscalYear__c = System.Today().year(),
                                            Invoice_Number__c = 'inv-001', Inv_Status__c = 'Printed',
                                            Inv_Supplier__c = supplier.Id, Sequence_Date__c = 'Month',
                                            Sequence_Number__c = System.Today().month(), origin__c = 'Group',
                                            Status_BDate__c = System.Today(), Inv_PrintedDate__c = System.Today().addDays(-1),
                                            Ext_id__c='12345');
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = condition.Id, Inv_Detail_BU__c = condition.BU_Scope__c,
                                                                Inv_Detail_Condition__c = condition.Condition_Type__c,
                                                                Invoice_Value__c = 10, Inv_VAT_Percent__c = 23, Inv_VAT_Code__c = 121,
                                                                CurrencyIsoCode = currencyIsoCode);
        Invoice_Detail__c invoiceDetail2 = new Invoice_Detail__c(Discount__c = condition.Id, Inv_Detail_BU__c = condition.BU_Scope__c,
                                                                Inv_Detail_Condition__c = condition.Condition_Type__c,
                                                                Invoice_Value__c = 15, Inv_VAT_Percent__c = 23, Inv_VAT_Code__c = 121,
                                                                CurrencyIsoCode = currencyIsoCode);
        Invoice_Detail__c invoiceDetail3 = new Invoice_Detail__c(Discount__c = condition.Id, Inv_Detail_BU__c = condition.BU_Scope__c,
                                                                Inv_Detail_Condition__c = condition.Condition_Type__c,
                                                                Invoice_Value__c = 20, Inv_VAT_Percent__c = 23, Inv_VAT_Code__c = 121,
                                                                CurrencyIsoCode = currencyIsoCode);
        
        Invoice__c invoiceReference = new Invoice__c(Ext_id__c='12345');
        invoiceDetail.Invoice__r = invoiceReference;
        invoiceDetail2.Invoice__r = invoiceReference;
        invoiceDetail3.Invoice__r = invoiceReference;
        List<SObject> invoiceWithDetailsList = new List<SObject>();
        invoiceWithDetailsList.add(invoice);
        invoiceWithDetailsList.add(invoiceDetail);
        invoiceWithDetailsList.add(invoiceDetail2);
        invoiceWithDetailsList.add(invoiceDetail3);
        Database.insert(invoiceWithDetailsList);  
        Test.startTest();
        Database.executeBatch(new CalculateAlreadyInvoicedBatch('CalculateAlreadyInvoicedBatchTest', null));
        Test.stopTest();
        condition = [SELECT Id, CurrencyIsoCode, Invoice_base__c, Already_Invoiced__c, Already_Invoiced_Edited__c
                     FROM Contract_Discount__c WHERE Id = :condition.Id];
        // Validation Test
        System.assertEquals(45, condition.Already_Invoiced__c);
        System.assertEquals(45, condition.Already_Invoiced_Edited__c);
    }
}