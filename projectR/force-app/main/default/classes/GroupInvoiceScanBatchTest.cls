/**
 * Unit Test class used to scan invoices group
 * INTEGRITY CONTROL: 
 * a- Check Mandatory fields
 * b- Check Warning fields
 * DATA MAPPING:
 * 1- Supplier Control : Check If Supplier not exists OR Supplier Code is not in Group Contract OR not linked to a BU Supplier
 * 2- Contract Control: Check if Contract not exists OR contract code is not in group contract OR not linked to a BU contract
 * 3- Conditions Control: Check if Condition not exists OR condition line is not in group contract detail or not linked to a BU contract line
 **/ 
@isTest
private class GroupInvoiceScanBatchTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c warehouse;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Group__c contractGroup;
    private static Contract_Group_Detail__c contractGroupDetail;  
    private static Batch__c batch;
    
    static void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
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
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            insert tariffCondition;
            // Create Group Contract
            contractGroup = TestDataFactory.createContractGroup(false, NS, System.Today().addMonths(-2), System.Today().addMonths(2), 'Group contract');
            contractGroup.Contract_Number__c = 'CG001';
            contractGroup.Origin_Supplier_Code__c = 'Sup001';
            contractGroup.Origin_Supplier__c = 'Sup001';
            contractGroup.Contract_linked__c = 'CL001';
            contractGroup.Status__c = 'Validated';
            contractGroup.Origin_Stock_owner__c = 'w1';
            insert contractGroup;
            // Create Group Contract Detail
            contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
            contractGroupDetail.Origin_Disc_Code__c = 'C1';
            contractGroupDetail.Origin_Disc_Code2__c = 'C1';
            contractGroupDetail.Condition_Linked__c = 'CL001';
            insert contractGroupDetail;
            // insert Batch__c
            batch = TestDataFactory.createBatch(true);
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    // Check Mandatory fields
    @isTest static void CaseEmptyMandatoryFields_Success() {
        init();
        // insert Invoice_Group__c With Mandatory Fields
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c= 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = NULL, Origin_Contract_Number__c = NULL,
                                                             Origin_Supplier_Code__c = NULL, Header_Integration_Status__c = NULL,
                                                             Amount_wo_Tax__c = NULL, Amount_w_Tax__c = NULL, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Origin_Stock_owner__c = null);
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Error_desc__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(String.IsNotBlank(invoiceGroup.Error_desc__c), True);
    }
    // Check Warning fields
    @isTest static void CaseWarningFields_Success() {
        init();
        // insert Invoice_Group__c With Warning Fields
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = -15, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Warning_Desc__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(String.IsNotBlank(invoiceGroup.Warning_Desc__c), True);
    }
    // Check Supplier Control
    @isTest static void SupplierControl_Success() {
        init();
        // insert Invoice_Group__c With Supplier Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Supplier__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Supplier__c, contractGroup.Supplier__c);
        System.assertEquals('Validated', invoiceGroup.Status__c);
    }
    // Check Contract Control
    @isTest static void ContractGroupControl_Success() {
        init();
        // insert Invoice_Group__c With Contract Group Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = supplier.Id, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Contract_reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Contract_reference__c, contractGroup.Id);
        System.assertEquals('Validated', invoiceGroup.Status__c);
    }
    // Check Conditions Control
    @isTest static void ConditionsControl_Success() {
        init();
        // insert Invoice_Group__c With Contract Group Detail Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Condition_Reference__c, contractGroupDetail.Id);
        System.assertEquals('Validated', invoiceGroup.Status__c);
    }
    // Check Rejected Invoice Group With Origin_Supplier_Code__c Not Exist
    @isTest static void InvoiceGroupWithOriginSupplierNotExist_Success() {
        init();
        // insert Invoice_Group__c With Supplier Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C111', Origin_Contract_Number__c = 'CG00111',
                                                             Origin_Supplier_Code__c = 'Sup00111', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Status__c, 'Rejected');
    }
    // Check Rejected Invoice Group With Supplier__c = NULL
    @isTest static void InvoiceGroupWithSupplierIsNULL_Success() {
        init();
        //contractGroup.Origin_Supplier__c = null;
        contractGroup.Supplier__c = null;
        contractGroup.Supplier_NegoScope__c = null;
        update contractGroup;
        // insert Invoice_Group__c With Supplier Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Status__c, 'Rejected');
    }
    // Check Invoice Group With Origin_Contract_Number__c Not Exist
    @isTest static void InvoiceGroupWithContractIsNULL_Success() {
        init();
        // insert Invoice_Group__c With Contract Group Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG00111',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Contract_reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Contract_reference__c, NULL);
    }
    // Check Invoice Group With Origin_Contract_Number__c exist and not linked
    @isTest static void InvoiceGroupWithContractNotLinked_Success() {
        init();
        contractGroup.Contract_Linked__c = null;
        update contractGroup;
        // insert Invoice_Group__c With Contract Group not linked
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Contract_reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Contract_reference__c, NULL);
    }
    // Check Contract Control Linked and Different Supplier
    @isTest static void InvoiceGroupWithContractDiffSupplier_Success() {
        init();
        // Create Supplier.
        Sup_Supplier__c supplier1 = TestDataFactory.createSupplier(false, country, true);
        insert supplier1;
        // insert Invoice_Group__c With Different Supplier
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = supplier1.Id, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Contract_reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Contract_reference__c, null);
    }
    // Check Invoice Group With Condition_reference__c = NULL AND Origin_Condition_Line__c Not Exist
    @isTest static void InvoiceGroupWithContractDetailIsNULL_Success() {
        init();
        // insert Invoice_Group__c With Contract Group Detail Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C111', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Condition_Reference__c, NULL);
    }
    // Check Invoice Group With Origin_Condition_Line__c exist and not linked
    @isTest static void InvoiceGroupWithConditionNotLinked_Success() {
        init();
        contractGroupDetail.Condition_Linked__c = null;
        update contractGroupDetail;
        // insert Invoice_Group__c With Contract Group Detail Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Condition_Reference__c, NULL);
    }
    // Check Conditions Control
    @isTest static void testInvoiceGroupWithStatusSynchroWithoutCondition_Success() {
        init();
        // insert Invoice_Group__c With Contract Group Detail Is NULL
        Invoice_Group__c invoiceGroup = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                             Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                             Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                             Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                             Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                             Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                             Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                             Invoice_Batch_Number__c = batch.Id, Status__c = 'Synchronized without Condition', Origin_Stock_owner__c = 'w1');
        insert invoiceGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup.Id}, System.today() - 1));
        Test.stopTest();
        // Validation Test
        invoiceGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Invoice_Group__c WHERE Id = :invoiceGroup.Id];
        System.assertEquals(invoiceGroup.Condition_Reference__c, contractGroupDetail.Id);
    }
    // test Store Warehouse
    @isTest static void testStoreWarehouse() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup1 = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                              Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                              Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                              Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                              Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                              Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                              Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                              Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w2');
        // Create warehouse with Ext_id__c = null
        Orga_BU__c warehouse2 = TestDataFactory.createWarehouseBU(true, country.Id);
        Invoice_Group__c invoiceGroup2 = new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                                              Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                                              Invoice_Number__c = 'inv-001', Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                              Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                                              Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                                              Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                                              Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                                              Invoice_Batch_Number__c = batch.Id, Origin_Stock_owner__c = null);
        insert new List<Invoice_Group__c>{invoiceGroup1,invoiceGroup2};
        Test.startTest();
        Database.executeBatch(new GroupInvoiceScanBatch('GroupInvoiceScanBatchTest', false, new List<Id>{invoiceGroup1.Id,invoiceGroup2.Id}, null));
        Test.stopTest();
        // Validation Test
        invoiceGroup1 = [SELECT Id, Name, Status__c, Supplier__c FROM Invoice_Group__c WHERE Id = :invoiceGroup1.Id];
        invoiceGroup2 = [SELECT Id, Name, Status__c, Supplier__c FROM Invoice_Group__c WHERE Id = :invoiceGroup2.Id];
        System.assertEquals(invoiceGroup1.Supplier__c, contractGroup.Supplier__c);
        System.assertEquals('Rejected', invoiceGroup1.Status__c);
        System.assertEquals('Validated', invoiceGroup2.Status__c);
    }    
}