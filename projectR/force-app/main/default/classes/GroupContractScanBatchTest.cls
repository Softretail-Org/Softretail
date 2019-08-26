/*
 * Unit Test for scan contract group.
 **/
@isTest
private class GroupContractScanBatchTest {    
    private static final Integer CONTRACT_NUMBER = 500;
    private static Integer year;
    private static Integer day;
    private static Integer month;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c warehouse;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    private static Pol_Com_Condition__c tariffConditionClosed;
    
    static public void init() {
        try {
            year = System.Today().year();
            day = System.Today().day();
            month = System.Today().month();
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
            // Create supplier.
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Condition_Code__c = 'C1';
            tariffCondition.Condition_status__c = 'Open';
            tariffConditionClosed = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffConditionClosed.Condition_Code__c = 'C2';
            tariffConditionClosed.Condition_status__c = 'Closed';
            insert new List<Pol_Com_Condition__c> {tariffCondition, tariffConditionClosed};
        } catch (Exception ex) { }
    }
    static testmethod void scanContractLinkedToContractReferenceNumber_Success() {
        init();
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        contractGroup.Contract_type__c = 'Prorogation';
        contractGroup.Temp_Exclusion__c = false;
        contractGroup.Origin_Stock_owner__c = 'w1';
        Contract_Group__c contractGroupRef = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract Ref');
        contractGroupRef.Contract_Reference_Number__c = '16gty';
        contractGroupRef.Contract_Number__c = '17tyu546';
        contractGroupRef.Origin_Supplier_Code__c = '125';
        contractGroupRef.Supplier__c = null;
        contractGroupRef.Supplier_NegoScope__c = null;
        contractGroupRef.Temp_Exclusion__c = false;
        contractGroupRef.Origin_Stock_owner__c = 'w1';
        insert new List<Contract_Group__c>{contractGroup, contractGroupRef};
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupRef = [SELECT Status__c, Action_ToDo__c FROM Contract_Group__c WHERE Id =:contractGroupRef.Id];
        System.assertEquals(contractGroupRef.Status__c, 'Validated');
    }
    static testmethod void scanContractLinkedToContractReferenceNumber_Fails() {
        init();
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Goup contract');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        Contract_Group__c contractGroupRef = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Goup contract Ref');
        contractGroupRef.Contract_Reference_Number__c = '16gty001';
        contractGroupRef.Contract_Number__c = '17tyu546';
        contractGroupRef.Origin_Supplier_Code__c = '1256';
        contractGroupRef.Supplier__c = null;
        contractGroupRef.Supplier_NegoScope__c = null;
        contractGroup.Origin_Stock_owner__c = 'w1';
        insert new List<Contract_Group__c>{contractGroup, contractGroupRef};
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupRef = [SELECT Status__c, Action_ToDo__c FROM Contract_Group__c WHERE Id =:contractGroupRef.Id];
        System.assertEquals(contractGroupRef.Status__c, 'Rejected');
    }
    static testmethod void scanContractLinkedToContractReferenceNumberWithSupplierIsNULL_Fails() {
        init();
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Goup contract');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        contractGroup.Supplier__c = null;
        contractGroup.Supplier_NegoScope__c = null;
        contractGroup.Origin_Stock_owner__c = 'w1';
        Contract_Group__c contractGroupRef = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Goup contract Ref');
        contractGroupRef.Contract_Reference_Number__c = '16gty';
        contractGroupRef.Contract_Number__c = '17tyu546';
        contractGroupRef.Origin_Supplier_Code__c = '1256';
        contractGroupRef.Supplier__c = null;
        contractGroupRef.Supplier_NegoScope__c = null;
        contractGroupRef.Origin_Stock_owner__c = 'w1';
        insert new List<Contract_Group__c>{contractGroup, contractGroupRef};
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupRef = [SELECT Status__c, Action_ToDo__c FROM Contract_Group__c WHERE Id =:contractGroupRef.Id];
        System.assertEquals(contractGroupRef.Status__c, 'Rejected');
    }
    static testmethod void scanContractLinkedToContractReferenceNumberWithOrigineSuppCodeDiff_Fails() {
        init();
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Goup contract');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        contractGroup.Origin_Stock_owner__c = 'w1';
        Contract_Group__c contractGroupRef = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Goup contract Ref');
        contractGroupRef.Contract_Reference_Number__c = '16gty';
        contractGroupRef.Contract_Number__c = '17tyu546';
        contractGroupRef.Origin_Supplier_Code__c = '1234';
        contractGroupRef.Supplier__c = null;
        contractGroupRef.Supplier_NegoScope__c = null;
        contractGroupRef.Origin_Stock_owner__c = 'w1';
        insert new List<Contract_Group__c>{contractGroup, contractGroupRef};
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        Contract_Group__c contractRefResult = [SELECT Status__c, Action_ToDo__c FROM Contract_Group__c WHERE Id =:contractGroupRef.Id];
        System.assertEquals(contractRefResult.Status__c, 'Rejected');
    }
    static testmethod void scanContractWithErrorDates_Success() {
        init();
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 3, 1), date.newInstance(year, 2, 1), 'Goup contract');
        insert contractGroup;
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        Contract_Group__c contractRefResult = [SELECT Status__c, Action_ToDo__c FROM Contract_Group__c WHERE Id =:contractGroup.Id];
        System.assertEquals(contractRefResult.Status__c, 'Rejected');
    }
    static testmethod void scanContractInactiveSuppNego_Fail() {
        init();
        Sup_Supplier__c supplier2 = TestDataFactory.createSupplier(false, country, true);
        supplier2.Name = 'Supplier 002';
        supplier2.Code__c = 'SUP002';
        insert supplier2;
        // Get the default NS created on supplier creation.
        Sup_sup_NegoScope__c negoScope2 = TestDataFactory.getNSs(supplier2.Id)[0];
        negoScope2.Status__c = 'Inactive';
        update negoScope2;
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, negoScope2, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract');
        contractGroup.Contract_Number__c = '17gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        // Create Group Contract Reference
        Contract_Group__c contractGroupRef = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract Ref');
        contractGroupRef.Contract_Reference_Number__c = '17gty';
        contractGroupRef.Contract_Number__c = '18tyu546';
        contractGroupRef.Origin_Supplier_Code__c = '125';
        contractGroupRef.Supplier__c = null;
        contractGroupRef.Supplier_NegoScope__c = null;
        insert new List<Contract_Group__c>{contractGroup, contractGroupRef};
        Test.startTest();
        // scan first time to check and correct error
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupRef = [SELECT Status__c FROM Contract_Group__c WHERE Id = :contractGroupRef.Id];
        System.assertEquals(contractGroupRef.Status__c, 'Rejected');
    }
    static testmethod void scanContractInactiveSupplier_Fail() {
        init();
        Sup_Supplier__c supplier2 = TestDataFactory.createSupplier(false, country, true);
        supplier2.Name = 'Supplier 002';
        supplier2.Code__c = 'SUP002';
        supplier2.Status__c = 'Close';
        insert supplier2;
        // Get the default NS created on supplier creation.
        Sup_sup_NegoScope__c negoScope2 = TestDataFactory.getNSs(supplier2.Id)[0];
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, negoScope2, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract');
        contractGroup.Contract_Number__c = '17gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        // Create Group Contract Reference
        Contract_Group__c contractGroupRef = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract Ref');
        contractGroupRef.Contract_Reference_Number__c = '17gty';
        contractGroupRef.Contract_Number__c = '18tyu546';
        contractGroupRef.Origin_Supplier_Code__c = '125';
        contractGroupRef.Supplier__c = null;
        contractGroupRef.Supplier_NegoScope__c = null;
        insert new List<Contract_Group__c>{contractGroup, contractGroupRef};
        Test.startTest();
        // scan first time to check and correct error
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupRef = [SELECT Status__c FROM Contract_Group__c WHERE Id = :contractGroupRef.Id];
        System.assertEquals(contractGroupRef.Status__c, 'Rejected');
    }
    static testmethod void scanGroupContractDetailClosed_Fail() {
        init();
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';  
        contractGroup.Origin_Stock_owner__c = 'w1';      
        insert contractGroup;
        // Create Group Condition
        Contract_Group_Detail__c contractGroupDetailClosed = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
        contractGroupDetailClosed.Origin_Disc_Code__c = 'C2';
        contractGroupDetailClosed.Origin_Disc_Code2__c = 'C2';
        contractGroupDetailClosed.Condition_name__c = tariffConditionClosed.Id;
        insert contractGroupDetailClosed;
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        List<Contract_Group_Detail__c> contractRefResult = [Select Id, Contract_List_Group__r.Status__c FROM Contract_Group_Detail__c WHERE Contract_List_Group__r.Id = :contractGroup.Id];
        System.assertEquals(contractRefResult.get(0).Contract_List_Group__r.Status__c, 'Validated');
    }
    static testmethod void scanGroupContractDetailInvalidCondition() {
        init();
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        contractGroup.Origin_Stock_owner__c = 'w1';
        insert contractGroup;
        // Create Group Condition
        Contract_Group_Detail__c contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
        contractGroupDetail.Origin_Disc_Code__c = 'C2';
        contractGroupDetail.Origin_Disc_Code2__c = 'C2';
        contractGroupDetail.Condition_name__c = null;
        insert contractGroupDetail;
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        List<Contract_Group_Detail__c> contractRefResult = [Select Id, Contract_List_Group__r.Status__c FROM Contract_Group_Detail__c WHERE Contract_List_Group__r.Id = :contractGroup.Id];
        System.assertEquals(contractRefResult.get(0).Contract_List_Group__r.Status__c, 'Validated');
    }
    static testmethod void massScanMulti_Contract_Condition_Success() {
        init();
        // Create suppliers.
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
        for (Integer i = 1; i <= CONTRACT_NUMBER; i++) {
            Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.Name = 'SUPPLIER' + i;
            supplier.Code__c = 'SUPPLIER' + i;
            suppliers.add(supplier);
        }
        insert suppliers;
        List<Id> supplierIds = new List<Id>(new Map<Id, Sup_Supplier__c>(suppliers).keySet());
        // Get the default NS created on supplier creation.
        List<Sup_sup_NegoScope__c> negoScopes = [SELECT Id, Supplier__c, Supplier__r.Name, Supplier__r.Code__c, Supplier__r.Country_origin__c 
                                                 FROM Sup_sup_NegoScope__c WHERE Supplier__c IN :supplierIds ORDER BY Name ASC];        
        Map<Id, Sup_sup_NegoScope__c> mapNegoSupp = new Map<Id, Sup_sup_NegoScope__c>();
        for (Sup_sup_NegoScope__c nego :negoScopes) {
            mapNegoSupp.put(nego.Supplier__c, nego);
        }
        // Create contract for each supplier.
        List<Contract_Group__c> contractGroups = new List<Contract_Group__c>();
        for (Integer i = 1; i <= CONTRACT_NUMBER; i++) {            
            Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, mapNegoSupp.get(suppliers.get(i-1).Id),
                                                                                  date.newInstance(year, 1, 1), date.newInstance(year, 12, 31),
                                                                                  suppliers.get(i-1).Name + ' - Contract' + i + ' ' + year);
            contractGroup.Contract_Number__c = 'C00' + i;
            contractGroup.Origin_Supplier_Code__c = suppliers.get(i-1).Code__c;
            contractGroup.Origin_Stock_owner__c = 'w1';
            contractGroups.add(contractGroup);
        }
        insert contractGroups;
        // Create condition for each contract.
        List<Contract_Group_Detail__c> contractGroupDetails = new List<Contract_Group_Detail__c>();
        for (Integer i = 1 ; i < = CONTRACT_NUMBER ; i++) {
            Contract_Group_Detail__c contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroups.get(i-1), tariffCondition);
            contractGroupDetail.Origin_Disc_Code__c = 'C1';
            contractGroupDetail.Origin_Disc_Code2__c = 'C1';
            contractGroupDetail.Origin_Disc_name__c = 'Price Discount';
            contractGroupDetails.add(contractGroupDetail);
        }
        insert contractGroupDetails;
        // Start test.
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        // Stop test.
        contractGroups = [Select Id FROM Contract_Group__c WHERE Status__c = 'Validated'];
        contractGroupDetails = [Select Id FROM Contract_Group_Detail__c WHERE Status__c = 'Validated'];
        System.assertEquals(CONTRACT_NUMBER, contractGroups.size());
        System.assertEquals(CONTRACT_NUMBER, contractGroupDetails.size());    
    }
    static testmethod void massScanMulti_Contract_Condition_Fail() {
        init();
        // Create suppliers.
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();        
        for (Integer i=1 ; i < = CONTRACT_NUMBER ; i++) {
            Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
            supplier.Name = 'SUPPLIER' + i;
            supplier.Code__c = 'SUPPLIER' + i;
            suppliers.add(supplier);
        }
        insert suppliers;
        List<Id> supplierIds = new List<Id>(new Map<Id, Sup_Supplier__c>(suppliers).keySet());
        // Get the default NS created on supplier creation.
        List<Sup_sup_NegoScope__c> negoScopes = [SELECT Id, Supplier__c, Supplier__r.Name, Supplier__r.Code__c, Supplier__r.Country_origin__c 
                                                 FROM Sup_sup_NegoScope__c WHERE Supplier__c IN :supplierIds ORDER BY Name ASC];        
        Map<Id, Sup_sup_NegoScope__c> mapNegoSupp = new Map<Id, Sup_sup_NegoScope__c>();
        for (Sup_sup_NegoScope__c nego :negoScopes) {
            mapNegoSupp.put(nego.Supplier__c, nego);
        }
        // Create contract for each supplier.
        List<Contract_Group__c> contractGroups = new List<Contract_Group__c>();
        for (Integer i = 1 ; i < = CONTRACT_NUMBER ; i++) {
            Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, mapNegoSupp.get(suppliers.get(i-1).Id),
                                                                                  date.newInstance(year, 1, 1), date.newInstance(year, 12, 31),
                                                                                  suppliers.get(i-1).Name + ' - Contract' + i + ' ' + year);
            contractGroup.Contract_Number__c = 'C00' + i;
            contractGroup.Origin_Supplier_Code__c = suppliers.get(i-1).Code__c;
            contractGroup.Header_Integration_Status__c = null;
            contractGroup.Origin_Stock_owner__c = 'w1';
            contractGroups.add(contractGroup);            
        }
        insert contractGroups;
        // Create condition for each contract.
        List<Contract_Group_Detail__c> contractGroupDetails = new List<Contract_Group_Detail__c>();
        for (Integer i = 1 ; i < = CONTRACT_NUMBER ; i++) {
            Contract_Group_Detail__c contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroups.get(i-1), tariffCondition);
            contractGroupDetail.Origin_Disc_Code__c = 'C1-1';
            contractGroupDetail.Origin_Disc_Code2__c = 'C1-1';
            contractGroupDetail.Origin_Disc_name__c = 'Rebate';
            contractGroupDetail.Line_Integration_Status__c = null;
            contractGroupDetails.add(contractGroupDetail);
        }
        insert contractGroupDetails;
        // Start test.
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        // Stop test.
        contractGroups = [Select Id FROM Contract_Group__c WHERE Status__c = 'Rejected'];
        contractGroupDetails = [Select Id FROM Contract_Group_Detail__c WHERE Status__c = 'Rejected'];
        System.assertEquals(CONTRACT_NUMBER, contractGroupDetails.size());
        System.assertEquals(CONTRACT_NUMBER, contractGroups.size());
    }
    static testmethod void massScanContractDateManagement_Success() {
        init();
        // Create Group Contract
        Contract_Group__c contractGroup1 = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 3, 31), 'D-'+ supplier.Name + ' - Contract1');
        contractGroup1.Contract_Number__c = 'C001';
        contractGroup1.Contract_type__c = 'Prorogation';
        contractGroup1.Origin_Stock_owner__c = 'w1';
        
        Contract_Group__c contractGroup2 = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31), 'N-'+ supplier.Name + ' - Contract2');
        contractGroup2.Contract_Number__c = 'C002';
        contractGroup2.Origin_Stock_owner__c = 'w1';
        
        Contract_Group__c contractGroup3 = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 11, 30), 'N-'+ supplier.Name + ' - Contract3');
        contractGroup3.Contract_Number__c = 'C003';
        contractGroup3.Origin_Stock_owner__c = 'w1';
        insert new List<Contract_Group__c>{contractGroup1, contractGroup2, contractGroup3};
        // Start test.
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, new List<String>{contractGroup1.Id, contractGroup2.Id, contractGroup3.Id}, null), CONTRACT_NUMBER);
        Test.stopTest();
        // Stop test.        
        List<Contract_Group__c> contractGroups = [Select Id, Name, Status__c FROM Contract_Group__c WHERE Status__c = 'Validated'];
        contractGroup1 = [Select Id, Name, Status__c FROM Contract_Group__c WHERE Id =:contractGroup1.Id LIMIT 1];
        System.assertEquals(contractGroup1.Status__c, 'Deleted');
        System.assertEquals(1, contractGroups.size());
    }
    static testmethod void massScanMandatoryFields_Fails() {
        init();
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, system.today().addMonths(4), null, supplier.Name + ' - Contract1');
        contractGroup.Contract_Number__c = null;
        insert contractGroup;
        // Create Group Condition
        Contract_Group_Detail__c contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
        contractGroupDetail.Origin_Disc_Code__c = null;
        contractGroupDetail.Origin_Disc_Code2__c = null;
        contractGroupDetail.Condition_name__c = null;
        insert contractGroupDetail;
        // Start test.
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, new List<String>{contractGroup.Id}, null), CONTRACT_NUMBER);
        Test.stopTest();
        // Stop test.        
        contractGroup = [Select Id, Status__c FROM Contract_Group__c WHERE Id =: contractGroup.Id];
        System.assertEquals(contractGroup.Status__c, 'Rejected');
    }
    static testmethod void scanContractGroupWithConditionFilterValidationFails_Error() {
        init();
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, system.today().addMonths(4), null, supplier.Name + ' - Contract1');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        insert contractGroup;
        // Create Group Condition
        Contract_Group_Detail__c contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
        contractGroupDetail.Origin_Disc_Code__c = 'C1';
        contractGroupDetail.Origin_Disc_Code2__c = 'C1';
        contractGroupDetail.Origin_Disc_name__c = 'Price Discount';
        contractGroupDetail.Disc_EDate__c = date.newInstance(year, 1, 1);
        insert contractGroupDetail;
        // update tarrif condition
        tariffCondition.Nego_Discount_Type__c = 'Rebates';
        update tariffCondition;
        // create contract group detail
        Contract_Group_Detail__c contractGroupDetail1 = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
        contractGroupDetail1.Origin_Disc_Code__c = 'C1';
        contractGroupDetail1.Origin_Disc_Code2__c = 'CC1';
        contractGroupDetail1.Origin_Disc_name__c = 'Rebates';
        contractGroupDetail1.Disc_EDate__c = date.newInstance(year, 1, 1);
        insert contractGroupDetail1;
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupDetail = [SELECT Id, Status__c FROM Contract_Group_Detail__c WHERE Id =:contractGroupDetail.Id];
        contractGroupDetail1 = [SELECT Id, Status__c FROM Contract_Group_Detail__c WHERE Id =:contractGroupDetail1.Id];
        System.assertEquals(contractGroupDetail.Status__c, 'New');   
        System.assertEquals(contractGroupDetail1.Status__c, 'Validated');
    }
    static testmethod void scanMultiContractWithSameYearSupplierNS_Success() {
        init();
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), supplier.Name + ' - Contract1');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        contractGroup.Status__c = 'Synchronized';        
        Contract_Group__c contractGroupRef = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), 'Group contract Ref');
        contractGroupRef.Contract_Reference_Number__c = '16gty';
        contractGroupRef.Contract_Number__c = '17tyu546';
        contractGroupRef.Origin_Supplier_Code__c = '125';
        contractGroupRef.Supplier__c = null;
        contractGroupRef.Supplier_NegoScope__c = null;
        insert new List<Contract_Group__c>{contractGroup, contractGroupRef};
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupRef = [SELECT Status__c, Action_ToDo__c FROM Contract_Group__c WHERE Id =:contractGroupRef.Id];
        System.assertEquals(contractGroupRef.Status__c, 'Rejected');
    }
    static testmethod void scanGroupContractSynchronized_Success() {
        init();
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), supplier.Name + ' - Contract1');
        contractGroup.Contract_Number__c = '16gty';
        contractGroup.Origin_Supplier_Code__c = '125';
        contractGroup.Status__c = 'Synchronized';
        contractGroup.Origin_Stock_owner__c = 'w1';
        insert contractGroup;
        
        // Create Group Condition
        Contract_Group_Detail__c contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
        contractGroupDetail.Origin_Disc_Code__c = 'C1';
        contractGroupDetail.Origin_Disc_Code2__c = 'C1';
        insert contractGroupDetail;
        contractGroupDetail.Status__c = 'Updated';
        update contractGroupDetail;
        Test.startTest();
        Database.executeBatch(new GroupContractScanBatch('GroupContractScanBatchTest', false, null, null), CONTRACT_NUMBER);
        Test.stopTest();
        contractGroupDetail = [Select Id, Status__c FROM Contract_Group_Detail__c WHERE Id = :contractGroupDetail.Id];
        System.assertEquals(contractGroupDetail.Status__c, 'Validated');
    }
}