/**
 * Unit Test class used to synchronize invoices group with invoice And invoice Line.
**/ 
@isTest
private class GroupInvoiceSynchroBatchTest {
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
            // Create group BU.
            groupBU = TestDataFactory.createGroupBU(false, 'AMC');
            groupBU.Name = 'AMC';
            groupBU.BU_Code__c = 'AMC';
            insert groupBU;
            // Create Supplier.
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Create NS.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
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
    
    // Insert Invoice/Invoice Detail
    @isTest static void CaseInsertInvoice_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                                             Supplier__c = supplier.Id, Contract_reference__c = contractGroup.Id, 
                                                             Condition_Reference__c = contractGroupDetail.Id, VAT_Amount__c = 100,
                                                             Status__c = 'Validated', Stock_owner__c = warehouse.Id);
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceSynchroBatch('GroupInvoiceSynchroBatchTest', false, new List<Id>{invoiceGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Invoice_Linked__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(1, [SELECT Count() FROM Invoice__c Where Id =:invoiceGroup.Invoice_Linked__c]);
        System.assertEquals(invoiceGroup.Status__c, 'Synchronized');
    }
    
    // Insert Invoice/Invoice Detail
    @isTest static void CaseInsertInvoice_Error() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup1 = new Invoice_Group__c(Document_type__c = null, Invoice_Year__c = null,
                                                              Invoice_Date__c = system.today(), Invoice_Due_Date__c = System.Today(),
                                                              Invoice_Number__c = null, Origin_Condition_Line__c = null, Origin_Contract_Number__c = null,
                                                              Origin_Supplier_Code__c = null, Header_Integration_Status__c = null,
                                                              Amount_wo_Tax__c = 5, Amount_w_Tax__c = null,
                                                              Supplier__c = supplier.Id, Contract_reference__c = null, 
                                                              Condition_Reference__c = null, VAT_Amount__c = null,
                                                              Status__c = 'Validated', Stock_owner__c = warehouse.Id);
        Invoice_Group__c invoiceGroup2 = new Invoice_Group__c(Document_type__c = null, Invoice_Year__c = year,
                                                              Invoice_Date__c = system.today(), Invoice_Due_Date__c = System.Today(),
                                                              Invoice_Number__c = null, Origin_Condition_Line__c = null, Origin_Contract_Number__c = null,
                                                              Origin_Supplier_Code__c = null, Header_Integration_Status__c = null,
                                                              Amount_wo_Tax__c = null, Amount_w_Tax__c = null,
                                                              Supplier__c = supplier.Id, Contract_reference__c = null, 
                                                              Condition_Reference__c = null, VAT_Amount__c = null,
                                                              Status__c = 'Validated', Stock_owner__c = warehouse.Id);
        insert new List<Invoice_Group__c> {invoiceGroup1,invoiceGroup2};
        Test.startTest();
        Database.executeBatch(new GroupInvoiceSynchroBatch('GroupInvoiceSynchroBatchTest', false, new List<Id>{invoiceGroup1.Id, invoiceGroup2.Id}));
        Test.stopTest();
        // Validation Test
        invoiceGroup1 = [SELECT Id, Name, Status__c, Error_desc__c, Invoice_Linked__c FROM Invoice_Group__c WHERE Id = :invoiceGroup1.Id];
        invoiceGroup2 = [SELECT Id, Name, Status__c, Error_desc__c, Invoice_Linked__c FROM Invoice_Group__c WHERE Id = :invoiceGroup2.Id];
        System.assertEquals(invoiceGroup1.Status__c, 'Synchronized with error');
        System.assertEquals(invoiceGroup2.Status__c, 'Synchronized with error');
    }
    
    // Update Invoice/Invoice Detail
    @isTest static void CaseUpdateInvoiceWithLinkedInvoiceGroup_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =  new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                              Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                              Invoice_Number__c = 'inv-002', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                              Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                              Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                                              Supplier__c = supplier.Id, Contract_reference__c = contractGroup.Id, 
                                                              Condition_Reference__c = contractGroupDetail.Id, VAT_Amount__c = 100,
                                                              Status__c = 'Validated', Stock_owner__c = warehouse.Id);
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
        Test.startTest();
        Database.executeBatch(new GroupInvoiceSynchroBatch('GroupInvoiceSynchroBatchTest', false, new List<Id>{invoiceGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Invoice_Linked__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Status__c, 'Synchronized');
    }
    
    // Update Invoice/Invoice Detail
    @isTest static void CaseUpdateInvoiceWithoutContract_Success() {
        init();
        delete contract;
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-002', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                                             Supplier__c = supplier.Id, Contract_reference__c = contractGroup.Id, 
                                                             Condition_Reference__c = contractGroupDetail.Id, VAT_Amount__c = 100,
                                                             Status__c = 'Validated', Stock_owner__c = warehouse.Id);
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
        invoiceGroup.Invoice_Linked__c = invoice.Id;
        update invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceSynchroBatch('GroupInvoiceSynchroBatchTest', false, new List<Id>{invoiceGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Invoice_Linked__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Status__c, 'Synchronized without Contract');
    }
}