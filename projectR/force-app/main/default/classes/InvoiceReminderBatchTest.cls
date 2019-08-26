/*
 * Unit test methods to check invoice due date and insert invoice reminder.
 */
@isTest
public class InvoiceReminderBatchTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static String plv;
    private static Contract_Discount__c condition;
    
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
            // Create group BU.
            groupBU = new Orga_BU__c(Name = 'EMC', BU_Code__c = 'EMC', CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = 'LBN',
                                     BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            groupBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Group');
            insert groupBU;
            // Create Supplier.
            supplier = new Sup_Supplier__c(Name = 'Supplier001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode,
                                           Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Create NS.
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create Policy - Tariff Conditions.
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com', Name_Com__c = 'Com', Name_Fi__c = 'Fi',
                                                       Name_Leg__c = 'Leg', Gen_Name_Fi__c = 'Gen Fi', Gen_Name_Leg__c = 'Gen Leg', VAT_Type__c = 'Rebate', Condition_status__c = 'Open');
            insert tariffCondition;
            // Create contract.
            contract = new Contract__c(Name = 'Contract001' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                       Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
            insert contract;
            // Create condition.
            condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year, 12, 30), Value_per__c = 2.5, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = contract.Id);
            insert condition;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    // Check invoice Due Date is greater than (today+level value) and not totaly paid.
    static testmethod void insertInvoiceReminderLevel1_Success() {
    	init();
        // insert invoice
        Invoice__c  invoice = new Invoice__c(Inv_Business_Unit__c = groupBU.Id, ////Acc_Document_Type__c = 'Invoice',
                                             Inv_Contract__c = contract.Id, Inv_Date__c = System.Today(),
                                             Inv_DueDate__c = System.Today() - 5, Inv_FiscalYear__c = System.Today().year(),
                                             Invoice_Number__c = 'inv-001', Inv_Status__c = 'Printed',
                                             Inv_Supplier__c = supplier.Id, Sequence_Date__c = 'Month',
                                             Sequence_Number__c = System.Today().month(), origin__c = 'Group',                                        
                                             Status_BDate__c = System.Today());       
        insert invoice;
        // insert invoice detail
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = condition.Id, Invoice__c = invoice.Id,
                                                                Inv_Detail_Condition__c = tariffCondition.Id, 
                                                                Invoice_Value__c = 1000, Inv_VAT_Percent__c = 10);
        insert invoiceDetail;
        // Start test.
		Test.startTest();
        Database.executeBatch(new InvoiceReminderBatch('InvoiceReminderBatchTest', new List<Id>{invoice.Id}, new List<Id>{groupBU.Id}, 1, 1, 'email'));
        Test.stopTest();
        // Assertion. 
        AggregateResult[] c = [SELECT Count(Id) c FROM Invoice_Reminder__c WHERE Invoice__c = :invoice.Id];
        System.assertEquals(1, c[0].get('c'));        
    }
    // Check invoice Due Date is greater than (today+level value) and not totaly paid.
    static testmethod void insertInvoiceReminderLevel2_Success() {
    	init();
        // insert invoice
        Invoice__c  invoice = new Invoice__c(Inv_Business_Unit__c = groupBU.Id, ////Acc_Document_Type__c = 'Invoice',
                                             Inv_Contract__c = contract.Id, Inv_Date__c = System.Today(),
                                             Inv_DueDate__c = System.Today() - 5, Inv_FiscalYear__c = System.Today().year(),
                                             Invoice_Number__c = 'inv-001', Inv_Status__c = 'Printed',
                                             Inv_Supplier__c = supplier.Id, Sequence_Date__c = 'Month',
                                             Sequence_Number__c = System.Today().month(), origin__c = 'Group',
                                             Status_BDate__c = System.Today(), Reminded__c = '1');       
        insert invoice;
        // insert invoice detail
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = condition.Id, Invoice__c = invoice.Id,
                                                                Inv_Detail_Condition__c = tariffCondition.Id, 
                                                                Invoice_Value__c = 1000, Inv_VAT_Percent__c = 10);
        insert invoiceDetail;
        // Start test.
		Test.startTest();
        Database.executeBatch(new InvoiceReminderBatch('InvoiceReminderBatchTest', new List<Id>{invoice.Id}, new List<Id>{groupBU.Id}, 2, 2, 'email'));
        Test.stopTest();
        // Assertion. 
        AggregateResult[] c = [SELECT Count(Id) c FROM Invoice_Reminder__c WHERE Invoice__c = :invoice.Id];
        System.assertEquals(1, c[0].get('c'));        
    }
}