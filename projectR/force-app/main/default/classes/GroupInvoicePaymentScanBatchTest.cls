/**
 * Batchable class used to scan invoices payment group
 * Case Criteria: Status = New or Invoice_Reference__c = NULL
 * INTEGRITY CONTROL: 
 * a- Check Mandatory fields
 * b- Check Warning fields
 * DATA MAPPING:
 * - Invoice Control : Check If Invoice Group not exists
 **/ 
@isTest
private class GroupInvoicePaymentScanBatchTest {
    private static Integer year;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
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
            // Create group BU.
            groupBU = TestDataFactory.createGroupBU(false, 'AMC');
            insert groupBU;
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
            contractGroup.Origin_BU__c = groupBU.Id;
            insert contractGroup;
            // Create Group Contract Detail
            contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
            contractGroupDetail.Origin_Disc_Code__c = 'C1';
            contractGroupDetail.Origin_Disc_Code2__c = 'C1';
            contractGroupDetail.Condition_Linked__c = 'CL001';
            insert contractGroupDetail;
            // insert Batch__c
            batch = new Batch__c(Name = 'Batch 001', Batch_Counter__c = 1, Entity_Code__c = 'X001', Movement_Type__c = 'FA', Ext_id__c = 'X001',
                                 Processing_date__c = '05-11-2017', Processing_hour__c = '20:15', Records_Count__c = 10001);
            insert batch;
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
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Document_type__c = 'A', Invoice_Year__c = System.Today().year(),
                                 Invoice_Date__c = System.Today(), Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Invoice_Number__c = null, Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Origin_Supplier_Code__c = 'Sup001', Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL);
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup =
            new Invoice_Payment_Group__c(Invoice_Date__c = System.Today(), Invoice_Number__c = null,
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100, 
                                         Payment_mode__c = NULL, Payment_type__c = NULL, Origin_Supplier_Code__c = null,
                                         Flow_Execution_Date__c = NULL, Detail_Integration_Status__c = NULL, Integration_Date_Last__c = NULL,
                                         Invoice_Reference__c = NULL, Status__c = NULL);
        insert invoicePaymentGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup = [SELECT Id, Name, Status__c FROM Invoice_Payment_Group__c WHERE Id = :invoicePaymentGroup.Id];
        System.assertEquals(invoicePaymentGroup.Status__c, 'Rejected');
    }
    // Check Warning fields
    @isTest static void CaseWarningFields_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '9', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = NULL);
        insert invoicePaymentGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup = [SELECT Id, Name, Status__c, Warning_Desc__c FROM Invoice_Payment_Group__c WHERE Id = :invoicePaymentGroup.Id];
        System.assertEquals(String.IsNotBlank(invoicePaymentGroup.Warning_Desc__c), True);
    }
    // Insert payment related to invoice group not validated
    @isTest static void InsertPaymentNotLinkedToInvoiceGroup_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Linked__c = null);
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup = [SELECT Id, Name, Status__c, Invoice_Reference__c FROM Invoice_Payment_Group__c WHERE Id = :invoicePaymentGroup.Id];
        System.assertEquals(invoicePaymentGroup.Status__c, 'Rejected');
    }  
    // Insert payment related to invoice group not validated
    @isTest static void InsertPaymentWithDiffInvoiceNumber_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Linked__c = null);
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-002', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup = [SELECT Id, Name, Status__c, Invoice_Reference__c FROM Invoice_Payment_Group__c WHERE Id = :invoicePaymentGroup.Id];                      
        System.assertEquals(invoicePaymentGroup.Status__c, 'Rejected');
    }  
    // Check Invoice With Payment_mode_code=(8)
    @isTest static void InvoiceControl_Case1_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup = [SELECT Id, Name, Status__c, Invoice_Reference__c FROM Invoice_Payment_Group__c WHERE Id = :invoicePaymentGroup.Id];
        System.assertEquals(invoicePaymentGroup.Status__c, 'Validated');
    }
    // Check Same Invoice With Payment_mode_code=(9,8,3) Validated
    @isTest static void InvoiceControl_Case2_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '9', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '3', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup2;
        Invoice_Payment_Group__c invoicePaymentGroup3 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup3;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup1.Id,invoicePaymentGroup2.Id,invoicePaymentGroup3.Id}));
        Test.stopTest();
        // Validation Test        
        invoicePaymentGroup1 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup1.Id];
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup2.Id];
        invoicePaymentGroup3 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup3.Id];
        System.assertEquals(invoicePaymentGroup1.Status__c, 'Validated');
        System.assertEquals(invoicePaymentGroup2.Status__c, 'Validated');
        System.assertEquals(invoicePaymentGroup3.Status__c, 'Validated');
    }
    // Check Same Invoice With Payment_mode_code=(7,9,8) and 8=Rejected => (7,9)=Rejected
    @isTest static void InvoiceControl_Case3_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '7', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '9', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup2;
        Invoice_Payment_Group__c invoicePaymentGroup3 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = NULL);
        insert invoicePaymentGroup3;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup1.Id,invoicePaymentGroup2.Id,invoicePaymentGroup3.Id}));
        Test.stopTest();
        // Validation Test        
        invoicePaymentGroup1 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup1.Id];
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup2.Id];
        invoicePaymentGroup3 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup3.Id];
        System.assertEquals(invoicePaymentGroup1.Status__c, 'Rejected');
        System.assertEquals(invoicePaymentGroup2.Status__c, 'Rejected');
        System.assertEquals(invoicePaymentGroup3.Status__c, 'Rejected');
    }
    // Check Same Invoice With Payment_mode_code=(7,9,8) and 7=Synchro => (8,9)=Rejected
    @isTest static void InvoiceControl_Case4_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = 'Synchronized',
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '7', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '9', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup2;
        Invoice_Payment_Group__c invoicePaymentGroup3 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = NULL);
        insert invoicePaymentGroup3;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup2.Id,invoicePaymentGroup3.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup2.Id];
        invoicePaymentGroup3 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup3.Id];
        System.assertEquals(invoicePaymentGroup2.Status__c, 'Rejected');
        System.assertEquals(invoicePaymentGroup3.Status__c, 'Rejected');
    }
    // Check Same Invoice With Payment_mode_code=(7,8) and 7=Rejected => 8=Validated => 7=Validated
    @isTest static void InvoiceControl_Case5_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = 'Rejected',
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '7', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup2;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup2.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup1 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup1.Id];
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup2.Id];
        System.assertEquals(invoicePaymentGroup1.Status__c, 'Validated');
        System.assertEquals(invoicePaymentGroup2.Status__c, 'Validated');
    }
    // Check Same Invoice With Payment_mode_code=(7,9) and 7=Rejected => 9=Temporary blocked
    @isTest static void InvoiceControl_Case6_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = 'Rejected',
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '7', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '9', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup2;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup2.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup1 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup1.Id];
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup2.Id];
        System.assertEquals(invoicePaymentGroup2.Status__c, 'Temporary Blocked');
    }
    // Check Same Invoice With Payment_mode_code=(7,9) and 7=Rejected => 9=Temporary blocked
    @isTest static void InvoiceControl_Case7_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = null,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '7', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '9', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup2;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup1.Id,invoicePaymentGroup2.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup1 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup1.Id];
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup2.Id];
        System.assertEquals(invoicePaymentGroup1.Status__c, 'Temporary Blocked');
    }
    // Check Same Invoice With Payment_mode_code=(9,8,7) Validated
    @isTest static void InvoiceControl_Case8_Success() {
        init();
        // insert Invoice_Group__c
        Invoice_Group__c invoiceGroup =
            new Invoice_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                 Invoice_Year__c = System.Today().year(), Invoice_Date__c = System.Today(),
                                 Document_type__c = 'A', Invoice_Due_Date__c = System.Today().addMonths(2),
                                 Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                 Header_Integration_Status__c = 'New',
                                 Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10, Warning_Desc__c = NULL,
                                 Supplier__c = NULL, Contract_reference__c = NULL, Condition_Reference__c = NULL,
                                 Action_ToDo__c = NULL, Action_done__c = NULL, Error_desc__c = NULL,
                                 Invoice_Editor_Site_code__c = 'inv01', Invoice_Linked__c = 'invLink001');
        insert invoiceGroup;
        Invoice_Payment_Group__c invoicePaymentGroup1 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '9', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup1;
        Invoice_Payment_Group__c invoicePaymentGroup2 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '7', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup2;
        Invoice_Payment_Group__c invoicePaymentGroup3 =
            new Invoice_Payment_Group__c(Invoice_Number__c = 'inv-001', Origin_Supplier_Code__c = 'Sup001',
                                         Invoice_Date__c = System.Today(),
                                         Payment_date__c = System.Today(), Invoice_amount__c = 100,
                                         Payment_Mode__c = 'Créance mobilisée',
                                         Payment_type__c = 'R-(règlement)', Flow_Execution_Date__c = System.Today(),
                                         Detail_Integration_Status__c = 'New', Integration_Date_Last__c = System.Today(),
                                         Invoice_Reference__c = NULL, Status__c = NULL,
                                         Invoice_Editor_Site_code__c = 'inv01', Payment_Editor_Site_code__c ='p001',
                                         Payment_Mode_Code__c = '8', Payment_Nature_Code__c = 'p1',
                                         Payment_Number__c = 'p001', Payment_Batch_Number__c = batch.Id);
        insert invoicePaymentGroup3;
        Test.startTest();
        Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoicePaymentScanBatchTest', false, new List<Id>{invoicePaymentGroup1.Id,invoicePaymentGroup2.Id,invoicePaymentGroup3.Id}));
        Test.stopTest();
        // Validation Test
        invoicePaymentGroup1 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup1.Id];
        invoicePaymentGroup2 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup2.Id];
        invoicePaymentGroup3 = [SELECT Id, Name, Status__c, Invoice_Reference__c
                                FROM Invoice_Payment_Group__c 
                                WHERE Id = :invoicePaymentGroup3.Id];
        System.assertEquals(invoicePaymentGroup1.Status__c, 'Validated');
        System.assertEquals(invoicePaymentGroup2.Status__c, 'Validated');
        System.assertEquals(invoicePaymentGroup3.Status__c, 'Validated');
    }
}