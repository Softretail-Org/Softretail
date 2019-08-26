/**
 * Unit Test class used to scan rebate payment group
 **/
@isTest
private class GroupRebatePaymentScanBatchTest {
    
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
        // insert Rebate_Payment_Group__c With Mandatory Fields
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = null, Payment_Line_Number__c = null, 
                                                                          Origin_Condition_Line__c = null, Origin_Contract_Number__c = null,
                                                                          Origin_Supplier_Code__c = null, Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 10,
                                                                          Supplier__c = null, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = null,
                                                                          Status__c = 'Validated', Payment_Batch_Number__c = batch.Id,
                                                                          Stock_owner__c = null);        
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Error_desc__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(String.IsNotBlank(rebateGroup.Error_desc__c), True);
    }
    // Check Warning fields
    @isTest static void CaseWarningFields_Success() {
        init();
        // insert Rebate_Payment_Group__c With Warning Fields
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today().addMonths(2),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = -15,
                                                                          Supplier__c = supplier.Id, Contract_Reference__c = contractGroup.Id, 
                                                                          Condition_Reference__c = contractGroupDetail.Id, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = null);      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Warning_Desc__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(String.IsNotBlank(rebateGroup.Warning_Desc__c), True);
    }
    // Check Validated Scan
    @isTest static void CaseScanRebatePaymentValidate_Success() {
        init();
        // insert Rebate_Payment_Group__c With Supplier Is NULL
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today().addMonths(2),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = null, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Supplier__c, Contract_reference__c, Condition_Reference__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Supplier__c, contractGroup.Supplier__c);
        System.assertEquals(rebateGroup.Contract_reference__c, contractGroup.Id);
        System.assertEquals(rebateGroup.Condition_Reference__c, contractGroupDetail.Id);
    }
    // Check Rejected Rebate Payment Group With Origin_Supplier_Code__c Not Exist
    @isTest static void RebateGroupWithOriginSupplierNotExist_Success() {
        init();
        // insert Rebate_Payment_Group__c With Supplier Is NULL
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1-1', Origin_Contract_Number__c = 'CG001-1',
                                                                          Origin_Supplier_Code__c = 'Sup001-1', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = null, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [Select Id, Name, Status__c, Condition_Reference__c
                       From Rebate_Payment_Group__c 
                       Where Id =: rebateGroup.Id];
        System.assertEquals(rebateGroup.Status__c, 'Rejected');
    }
    // Check Rejected Rebate Payment Group With Supplier__c = NULL
    @isTest static void RebateGroupWithSupplierIsNULL_Success() {
        init();
        contractGroup.Supplier__c = null;
        contractGroup.Supplier_NegoScope__c = null;
        update contractGroup;
        // insert Rebate_Payment_Group__c With Supplier Is NULL
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = null, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Status__c, 'Rejected');
    }
    // Check Rebate Group With Origin_Contract_Number__c Not Exist
    @isTest static void RebateGroupWithContractIsNULL_Success() {
        init();
        // insert Rebate_Payment_Group__c With Contract Group Is NULL
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001-1',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = null, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Contract_reference__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Contract_reference__c, NULL);
    }
    // Check Rebate Group With Origin_Contract_Number__c exist and not linked
    @isTest static void RebateGroupWithContractNotLinked_Success() {
        init();
        contractGroup.Contract_Linked__c = null;
        update contractGroup;
        // insert Rebate_Payment_Group__c With Contract Group not linked
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = null, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Contract_reference__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Contract_reference__c, NULL);
    }
    // Check Contract Control Linked and Different Supplier
    @isTest static void RebateGroupWithContractDiffSupplier_Success() {
        init();
        // Create Supplier.
        Sup_Supplier__c supplier1 = new Sup_Supplier__c(Name = 'Supplier0011', Code__c = 'Sup0011', CurrencyIsoCode = currencyIsoCode,
                                                        Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true,
                                                        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier1;
        // insert Rebate_Payment_Group__c With Different Supplier
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = supplier1.Id, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Contract_reference__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Contract_reference__c, null);
    }
    // Check Rebate Group With Condition_reference__c = NULL AND Origin_Condition_Line__c Not Exist
    @isTest static void RebateGroupWithContractDetailIsNULL_Success() {
        init();
        // insert Rebate_Payment_Group__c With Contract Group Detail Is NULL
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1-1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = NULL, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Condition_Reference__c, NULL);
    }
    // Check Rebate Group With Origin_Condition_Line__c exist and not linked
    @isTest static void RebateGroupWithConditionNotLinked_Success() {
        init();
        contractGroupDetail.Condition_Linked__c = null;
        update contractGroupDetail;
        // insert Rebate_Payment_Group__c With Contract Group Detail Is NULL
        Rebate_Payment_Group__c rebateGroup = new Rebate_Payment_Group__c(Fiscal_Year__c = System.Today().year(), Payment_Date__c = System.Today(),
                                                                          Payment_Number__c = 'p-001', Payment_Line_Number__c = 'pl-001', 
                                                                          Origin_Condition_Line__c = 'C1', Origin_Contract_Number__c = 'CG001',
                                                                          Origin_Supplier_Code__c = 'Sup001', Payment_Reconciliation_Date__c = System.Today(),
                                                                          Amount_wo_Tax__c = 5, Amount_w_Tax__c = 15,
                                                                          Supplier__c = NULL, Contract_Reference__c = null, 
                                                                          Condition_Reference__c = null, VAT_Amount__c = 100,
                                                                          Payment_Label__c = 'lbl-001', Payment_Transfer_Date__c = System.Today(),
                                                                          Payment_Batch_Number__c = batch.Id, Origin_Stock_owner__c = 'w1');      
        insert rebateGroup;
        Test.startTest();
        Database.executeBatch(new GroupRebatePaymentScanBatch('GroupRebatePaymentScanBatchTest', false, new List<Id>{rebateGroup.Id}, null));
        Test.stopTest();
        // Validation Test
        rebateGroup = [SELECT Id, Name, Status__c, Condition_Reference__c FROM Rebate_Payment_Group__c WHERE Id = :rebateGroup.Id];
        System.assertEquals(rebateGroup.Condition_Reference__c, NULL);
    }
}