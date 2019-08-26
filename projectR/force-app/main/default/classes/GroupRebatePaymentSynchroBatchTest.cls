/**
 * Unit Test class used to synchronize between rebate payment group and invoice/invoice detail/payment/payment detail.
**/ 
@isTest
private class GroupRebatePaymentSynchroBatchTest {
    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c warehouse;
    private static Orga_BU__c groupBU;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    private static Contract_Group__c contractGroup;
    private static Contract_Group_Detail__c contractGroupDetail;  
    private static Batch__c batch;
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
            // Create Warehouse
            warehouse = TestDataFactory.createWarehouseBU(false, country.Id);
            warehouse.Ext_id__c = 'w1';
            insert warehouse;
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
            // insert Batch__c
            batch = TestDataFactory.createBatch(true);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Insert Invoice/Invoice Detail/Payment/Payment Detail
    @isTest static void CaseInsertInvoiceAndPayment_Success() {
        init();
        // insert Rebate_Payment_Group__c
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today().addMonths(2),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                                                          Supplier__c = supplier.Id, Contract_Reference__c = contractGroup.Id, 
                                                                          Condition_Reference__c = contractGroupDetail.Id,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Status__c = 'Validated', Payment_Batch_Number__c = batch.Id, Stock_owner__c = warehouse.Id);      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentSynchroBatch('GroupRebatePaymentSynchroBatchTest', new List<Id>{ rebateGroup.Id }));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Invoice_Linked__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(1, [SELECT Count() FROM Invoice__c WHERE Id = :rebateGroup.Invoice_Linked__c]);
        System.assertEquals(rebateGroup.Status__c, 'Synchronized');
    }
    
    // Insert Invoice/Invoice Detail/Payment/Payment Detail
    @isTest static void CaseInsertInvoiceAndPayment_Error() {
        init();
        // insert Rebate_Payment_Group__c
        Rebate_Payment_Group__c rebateGroup1 = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                           Payment_Number__c = null, Payment_Line_Number__c = null, 
                                                                           Origin_Condition_Line__c = null, Origin_Contract_Number__c = null,
                                                                           Origin_Supplier_Code__c = null, Payment_Reconciliation_Date__c = System.Today(),
                                                                           Amount_wo_Tax__c = null, Amount_w_Tax__c = null,
                                                                           Supplier__c = null, Contract_Reference__c = null, 
                                                                           Condition_Reference__c = null, VAT_Amount__c = null,
                                                                           Payment_Label__c = null, Payment_Transfer_Date__c = System.Today(),
                                                                           Status__c = 'Validated', Payment_Batch_Number__c = batch.Id, Stock_owner__c = warehouse.Id);        
        Rebate_Payment_Group__c rebateGroup2 = new Rebate_Payment_Group__c(Fiscal_Year__c = null, Payment_Date__c = null,
                                                                           Payment_Number__c = null, Payment_Line_Number__c = null, 
                                                                           Origin_Condition_Line__c = null, Origin_Contract_Number__c = null,
                                                                           Origin_Supplier_Code__c = null, Payment_Reconciliation_Date__c = null,
                                                                           Amount_wo_Tax__c = null, Amount_w_Tax__c = null,
                                                                           Supplier__c = supplier.Id, Contract_Reference__c = null, 
                                                                           Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                           Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = null,
                                                                           Status__c = 'Validated', Payment_Batch_Number__c = batch.Id, Stock_owner__c = warehouse.Id);        
        insert new List<Rebate_Payment_Group__c>{rebateGroup1,rebateGroup2};
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentSynchroBatch('GroupRebatePaymentSynchroBatchTest', new List<Id>{rebateGroup1.Id, rebateGroup2.Id}));
        Test.stopTest();
        // Validation Test
        rebateGroup1 = [SELECT Id, Name, Status__c, Invoice_Linked__c, Payment_Linked__c, Error_desc__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup1.Id];
        rebateGroup2 = [SELECT Id, Name, Status__c, Invoice_Linked__c, Payment_Linked__c, Error_desc__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup2.Id];
        System.assertEquals(rebateGroup1.Status__c, 'Synchronized with error');
        System.assertEquals(rebateGroup2.Status__c, 'Synchronized with error');      
    }
    
    // Update Invoice Invoice/Invoice Detail/Payment/Invoice Payment Detail
    @isTest static void CaseUpdateInvoiceAndPayment_Success() {
        init();
        // insert Rebate_Payment_Group__c
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today().addMonths(2),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                                                          Supplier__c = supplier.Id, Contract_Reference__c = contractGroup.Id, 
                                                                          Condition_Reference__c = contractGroupDetail.Id, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Status__c = 'Validated', Payment_Batch_Number__c = batch.Id, Stock_owner__c = warehouse.Id);      
        insert rebateGroup;
        // insert invoice/invoice_line
        Invoice__c  invoice = new Invoice__c(Inv_Business_Unit__c = groupBU.Id, ////Acc_Document_Type__c = 'Invoice',
                                             Inv_Contract__c = rebateGroup.Contract_Reference__r.Contract_Linked__c,
                                             Inv_Date__c = system.today(),
                                             Inv_DueDate__c = system.today(), Inv_FiscalYear__c = system.today().year(),
                                             Invoice_Number__c = null, Inv_Status__c = 'Printed',
                                             Inv_Supplier__c = rebateGroup.Supplier__c, Sequence_Date__c = 'Month',
                                             Sequence_Number__c = system.today().month(), origin__c = 'Group',                                        
                                             Status_BDate__c = system.today());       
        insert invoice;
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = condition.Id,
                                                                Inv_Detail_Comment__c = null,
                                                                Inv_Detail_Condition__c = tariffCondition.Id,
                                                                Invoice__c = invoice.Id,
                                                                Invoice_Value__c = rebateGroup.Amount_wo_Tax__c,
                                                                Inv_VAT_Percent__c = 10);
        insert invoiceDetail;
        // insert payment/payment_line
        Invoice_Paiement__c invoicePayment =  new Invoice_Paiement__c(Amount__c = rebateGroup.Amount_wo_Tax__c, Payment_BU__c = groupBU.Id,
                                                                      Comment__c = rebateGroup.Payment_label__c, Due_Date__c = rebateGroup.Payment_Transfer_Date__c,
                                                                      Payment_Date__c = system.today(), Supplier__c = rebateGroup.Supplier__c,
                                                                      Origin__c = 'Group');
        insert invoicePayment;
        Invoice_Paiement_Detail__c invoicePaymentDetail =  new Invoice_Paiement_Detail__c(Due_Date__c = rebateGroup.Payment_Transfer_Date__c,
                                                                                          Matching_Amount__c = rebateGroup.Amount_wo_Tax__c,
                                                                                          Invoice_Line__c = invoiceDetail.Id,
                                                                                          Paiement__c = invoicePayment.Id);
        insert invoicePaymentDetail;
        rebateGroup.Payment_Linked__c = invoicePayment.Id;
        rebateGroup.Invoice_Linked__c = invoice.Id;
        update rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentSynchroBatch('GroupRebatePaymentSynchroBatchTest', new List<Id>{rebateGroup.Id}));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Invoice_Linked__c, Payment_Linked__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Status__c, 'Synchronized');
    }
    
    // invalid synchro
    @isTest static void CaseInvalidSynchro_Success() {
        init();
        // insert Rebate_Payment_Group__c
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today().addMonths(2),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                                                          Supplier__c = supplier.Id, Contract_Reference__c = contractGroup.Id, 
                                                                          Condition_Reference__c = contractGroupDetail.Id,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Status__c = 'Validated', Payment_Batch_Number__c = batch.Id, Stock_owner__c = warehouse.Id);
        insert rebateGroup;
        Test.startTest();
        rebateGroup.Payment_Date__c = null;
        update rebateGroup;
        Database.executeBatch(new GroupRebatePaymentSynchroBatch('GroupRebatePaymentSynchroBatchTest', new List<Id>{rebateGroup.Id}));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Invoice_Linked__c, Payment_Linked__c, Error_desc__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Status__c, 'Synchronized with error');
    }
}