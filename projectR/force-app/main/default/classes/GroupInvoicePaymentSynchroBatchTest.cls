/**
 * Unit Test class used to synchronize between Invoice payment group and Invoice_payment__c/Invoice_payment_detail__c.
**/ 
@isTest
private class GroupInvoicePaymentSynchroBatchTest {
    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static Contract_Group__c contractGroup;
    private static Contract_Group_Detail__c contractGroupDetail;
    private static NegoptimCustomSettings__c negoCustomSettings;
    
    static void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create negoCustomSettings
            negoCustomSettings = TestDataFactory.createNegoptimCustomSettings(true);
            // Create Region.
            region = TestDataFactory.createBURegion(false, 'MEA');
            insert region;
            // Create Country.
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Supplier.
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Create NS.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create group BU.
            groupBU = TestDataFactory.createGroupBU(false, 'AMC');
            groupBU.Name = 'AMC';
            groupBU.BU_Code__c = 'AMC';
            groupBU.Related_Client__c = supplier.Id;
            insert groupBU;
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            insert tariffCondition;
            // Create contract.
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            insert contract;
            // Create condition.
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            insert condition;
            // Create Group Contract
            contractGroup = TestDataFactory.createContractGroup(false, NS, System.Today().addMonths(-2), System.Today().addMonths(2), 'Group contract');
            contractGroup.Contract_Number__c = 'CG001';
            contractGroup.Origin_Supplier_Code__c = 'Sup001';
            contractGroup.Origin_Supplier__c = 'Sup001';
            contractGroup.Contract_linked__c = contract.Id;
            contractGroup.Origin_BU__c = groupBU.Id;
            insert contractGroup;
            // Create Group Contract Detail
            contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
            contractGroupDetail.Origin_Disc_Code__c = 'C1';
            contractGroupDetail.Origin_Disc_Code2__c = 'C1';
            contractGroupDetail.Condition_Linked__c = condition.Id;
            insert contractGroupDetail;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    // Insert Invoice Payment/ Invoice Payment Detail
    @isTest static void CaseInsertInvoicePayment_Error() {
        init();
        // insert invoice group payment
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = null, Origin_Supplier_Code__c = null,
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = null, Invoice_amount__c = null,
                                         Flow_Execution_Date__c = null, Payment_Mode_Code__c = '8',
                                         Detail_Integration_Status__c = null, Integration_Date_Last__c = null,
                                         Invoice_Reference__c = null, Status__c = 'Validated');
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Flow_Execution_Date__c = System.Today(), Payment_Mode_Code__c = '8',
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = null, Status__c = 'Validated');
        insert invoicePaymentGroup2;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentSynchroBatch('GroupInvoicePaymentSynchroBatchTest', false, new List<Id>{invoicePaymentGroup1.Id, invoicePaymentGroup2.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup1 = [SELECT Id, Name, Status__c, Payment_Linked__c
                                FROM Invoice_Payment_Group__c
                                WHERE Id = :invoicePaymentGroup1.Id];
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Payment_Linked__c
                                FROM Invoice_Payment_Group__c
                                WHERE Id = :invoicePaymentGroup2.Id];
        System.assertEquals(invoicePaymentGroup1.Status__c, 'Synchronized_with_error');
        System.assertEquals(invoicePaymentGroup2.Status__c, 'Synchronized_with_error');
    }
    // Insert Invoice Payment/ Invoice Payment Detail
    @isTest static void CaseInsertInvoicePayment_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                 Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Invoice_Number__c = 'inv-002', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                 Supplier__c = supplier.Id, Contract_reference__c = contractGroup.Id,
                                 Condition_Reference__c = contractGroupDetail.Id, VAT_Amount__c = 100,
                                 Status__c = 'Validated');
        insert invoiceGroup;
        // insert invoice/invoice_line
        Invoice__c  invoice = new Invoice__c(Inv_Business_Unit__c = groupBU.Id, ////Acc_Document_Type__c = 'Invoice',
                                             Inv_Contract__c = invoiceGroup.Contract_Reference__r.Contract_Linked__c,
                                             Inv_Date__c = invoiceGroup.Invoice_Date__c,
                                             Inv_DueDate__c = invoiceGroup.Invoice_Date__c, Inv_FiscalYear__c = invoiceGroup.Invoice_Year__c,
                                             Invoice_Number__c = invoiceGroup.Invoice_Number__c, Inv_Status__c = 'Printed',
                                             Inv_Supplier__c = invoiceGroup.Supplier__c, Sequence_Date__c = 'Month',
                                             Sequence_Number__c = invoiceGroup.Invoice_Date__c.month(), origin__c = 'Group',                                        
                                             Status_BDate__c = invoiceGroup.Invoice_Date__c);       
        insert invoice;
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = condition.Id,
                                                                Inv_Detail_Comment__c = invoiceGroup.Comment__c,
                                                                Inv_Detail_Condition__c = tariffCondition.Id,
                                                                Invoice__c = invoice.Id,
                                                                Invoice_Value__c = invoiceGroup.VAT_Amount__c,
                                                                Inv_VAT_Percent__c = 10);
        insert invoiceDetail;
        invoiceGroup.Invoice_Linked__c = invoice.Id;
        update invoiceGroup;
        // insert invoice group payment
        Invoice_Payment_Group__c invoicePaymentGroup =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Flow_Execution_Date__c = System.Today(), Payment_Mode_Code__c = '8',
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = invoiceGroup.Id, Status__c = 'Validated');
        insert invoicePaymentGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentSynchroBatch('GroupInvoicePaymentSynchroBatchTest', false, new List<Id>{invoicePaymentGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup = [SELECT Id, Name, Status__c, Payment_Linked__c
                               FROM Invoice_Payment_Group__c
                               WHERE Id =: invoicePaymentGroup.Id];
        AggregateResult[] c = [SELECT Count(Id) c FROM Invoice_Paiement__c Where Id = :invoicePaymentGroup.Payment_Linked__c];
        System.assertEquals(1, c[0].get('c'));
        System.assertEquals(invoicePaymentGroup.Status__c, 'Synchronized');
    }
    // Update Invoice Payment/ Invoice Payment Detail
    @isTest static void CaseUpdateInvoicePayment_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                 Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Invoice_Number__c = 'inv-002', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                 Supplier__c = supplier.Id, Contract_reference__c = contractGroup.Id, 
                                 Condition_Reference__c = contractGroupDetail.Id, VAT_Amount__c = 100,
                                 Status__c = 'Validated');
        insert invoiceGroup;
        // insert invoice/invoice_line
        Invoice__c  invoice = new Invoice__c(Inv_Business_Unit__c = groupBU.Id, ////Acc_Document_Type__c = 'Invoice',
                                             Inv_Contract__c = invoiceGroup.Contract_Reference__r.Contract_Linked__c,
                                             Inv_Date__c = invoiceGroup.Invoice_Date__c,
                                             Inv_DueDate__c = invoiceGroup.Invoice_Date__c, Inv_FiscalYear__c = invoiceGroup.Invoice_Year__c,
                                             Invoice_Number__c = invoiceGroup.Invoice_Number__c, Inv_Status__c = 'Printed',
                                             Inv_Supplier__c = invoiceGroup.Supplier__c, Sequence_Date__c = 'Month',
                                             Sequence_Number__c = invoiceGroup.Invoice_Date__c.month(), origin__c = 'Group',                                        
                                             Status_BDate__c = invoiceGroup.Invoice_Date__c);       
        insert invoice;
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = condition.Id,
                                                                Inv_Detail_Comment__c = invoiceGroup.Comment__c,
                                                                Inv_Detail_Condition__c = tariffCondition.Id,
                                                                Invoice__c = invoice.Id,
                                                                Invoice_Value__c = invoiceGroup.VAT_Amount__c,
                                                                Inv_VAT_Percent__c = 10);
        insert invoiceDetail;
        invoiceGroup.Invoice_Linked__c = invoice.Id;
        update invoiceGroup;
        // insert invoice group payment
        Invoice_Payment_Group__c invoicePaymentGroup =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Flow_Execution_Date__c = System.Today(), Payment_Mode_Code__c = '8',
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = invoiceGroup.Id, Status__c = 'Validated');
        insert invoicePaymentGroup;
        Invoice_Paiement__c invoicePayment = 
            new Invoice_Paiement__c(Amount__c = invoicePaymentGroup.Amount_wo_Tax__c, Payment_BU__c = groupBU.Id,
                                    Comment__c = invoicePaymentGroup.Payment_label__c, Due_Date__c = invoicePaymentGroup.Payment_Effect_Due_Date__c,
                                    Origin__c = 'Group', Payment_Date__c = invoicePaymentGroup.Payment_Date__c,
                                    Payment_type__c = NULL, Supplier__c = supplier.Id);
        insert invoicePayment;
        invoicePaymentGroup.Payment_Linked__c = invoicePayment.Id;
        update invoicePaymentGroup;
        Invoice_Paiement_Detail__c invoicePaymentDetail = 
            new Invoice_Paiement_Detail__c(Due_Date__c = invoicePaymentGroup.Payment_Effect_Due_Date__c,
                                           Matching_Amount__c = invoicePaymentGroup.Amount_wo_Tax__c,
                                           Invoice_Line__c = invoiceDetail.Id,
                                           Paiement__c = invoicePayment.Id);
        insert invoicePaymentDetail;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentSynchroBatch('GroupInvoicePaymentSynchroBatchTest', false, new List<Id>{invoicePaymentGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup = [SELECT Id, Name, Status__c, Payment_Linked__c
                               FROM Invoice_Payment_Group__c
                               WHERE Id = :invoicePaymentGroup.Id];
        System.assertEquals(invoicePaymentGroup.Status__c, 'Synchronized');
    }
}