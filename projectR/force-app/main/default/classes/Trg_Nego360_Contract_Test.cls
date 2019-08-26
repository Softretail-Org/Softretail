/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers related to contracts
 */
@isTest
private class Trg_Nego360_Contract_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Sale_Condition__c saleCondition;
    private static Pol_Com_Condition__c tariffCondition;
    private static Folder folder;
    private static Document document;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id.
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get the folder settings.
            folder = NegoptimHelper.getFolderSettings();
            // Create Document
            if(folder != null) {
                String str = '{"tOGapTolerencePositive":0,"tOGapTolerenceNegative":0,"reminderValue3":0,"reminderValue2":0,"reminderValue1":0,"reminderLevel":0,"reminderDescription3":"","reminderDescription2":"","reminderDescription1":"","profile":null,"groupBU2":null,"groupBU1":null,"groupBU":null,"delimiter":",","datesOverlapControlBU":false,"coopGapTolerencePositive":0,"coopGapTolerenceNegative":0}';
                document = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, Body = Blob.valueof(str), FolderId = folder.Id );
                insert document;
            }
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.Country__c = country.Name;
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
            // Create supplier.
            supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            NS = [SELECT Id, Supplier__c, Supplier__r.Code__c FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // make NS Acc_Country__c = Contract_BU__r.Country__c
            NS.Acc_Country__c = country.Name;
            update NS;
            // Create Sales condition
            saleCondition = new Pol_Sale_Condition__c(Name = country.Name + ' ' + year, Status_BDate__c = date.newInstance(year, 1, 1),
                                                      Master_BU__c = country.Id, VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10,
                                                      Buying_Payment_Condition__c = 'Net', Buying_Payment_Days__c = '90', Status__c = 'Validated');
            insert saleCondition;
            // create contract
            contract = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                       Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month');			
            insert contract;
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
            insert tariffCondition;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Assign stock owner to contract
    @isTest static void test_assignStockOwner() {
        init();
        // Create Warehouse
        Orga_BU__c warehouse = TestDataFactory.createWarehouseBU(false, country.Id);
        warehouse.Ext_id__c = 'w1';
        insert warehouse;
        NS.Stock_Owner__c = warehouse.Id;
        update NS;
        // Create contract
        Contract__c contract1 = new Contract__c(Name ='Test Contract 0001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM001',
                                                Contract_BDate__c = date.newInstance((year + 3), 1, 1), Contract_EDate__c = date.newInstance((year + 3), 12, 1),
                                                Duration__c = 14, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Duration_type__c='Month');
        Test.startTest();
        Database.SaveResult result = Database.insert(contract1, false);
        Test.stopTest();
        // Validation
        contract1 = [SELECT Stock_Owner__c FROM Contract__c WHERE Id = :contract1.Id];
        System.assertEquals(contract1.Stock_Owner__c, warehouse.Id);
    }
    
    // Test validation prevent adding same contract type in the same period of another one (out range).
    @isTest static void test_createContractOutRange() {
        init();
        Contract__c c = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C12345',
                                               Contract_BDate__c = date.newInstance(year,1, 1), Contract_EDate__c = date.newInstance(year, 7, 1), Duration__c = 7, Contract_BU__c = country.Id,
                                               Contract_Type__c = 'Contract',Duration_type__c='Month');		
        Test.startTest();
        Database.SaveResult result = Database.insert(c, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - ('+contract.Id+')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding same contract target type in the same period of another one ( in range).
    @isTest static void test_createContractInRange() {
        init();
        Contract__c c = new Contract__c(Name ='Test Contract 002', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CT123456',
                                               Contract_BDate__c = date.newInstance(year, 4, 1), Contract_EDate__c = date.newInstance(year, 5, 1), Duration__c = 2, Contract_BU__c = country.Id,
                                               Contract_Type__c = 'Contract',Duration_type__c='Month');		
        Test.startTest();
        Database.SaveResult result = Database.insert(c, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - ('+contract.Id+')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding same contract target type in the same period of another one (on date begin).
    @isTest static void test_createContractOnDateBegin() {
        init();
        Contract__c c = new Contract__c(Name ='Test Contract 003', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CT123456',
                                               Contract_BDate__c = date.newInstance(year, 3, 1), Contract_EDate__c = date.newInstance((year+1), 5, 1), Duration__c = 15, Contract_BU__c = country.Id,
                                               Contract_Type__c = 'Contract',Duration_type__c='Month');
        Test.startTest();
        Database.SaveResult result = Database.insert(c, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - ('+contract.Id+')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding same contract target type in the same period of another one (on date end).
    @isTest static void test_createContractOnDateEnd() {
        init();
        Contract__c c = new Contract__c(Name ='Test Contract 004', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CT123456',
                                       Contract_BDate__c = date.newInstance((year-1), 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 8, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract', Duration_type__c='Month');		
        Test.startTest();
        Database.SaveResult result = Database.insert(c, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - ('+contract.Id+')', result.getErrors()[0].getMessage());
    }
    
    // Test validation prevent adding  contract if dates doesnt respect contract periodicity on month fail.
    @isTest static void test_createPeriodicMonthContractFail() {
        init();
        Contract__c contractByMonthType = new Contract__c(Name ='Test Contract 006', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM001',
                                                          Contract_BDate__c = date.newInstance((year+3), 1, 1), Contract_EDate__c = date.newInstance((year+3), 12, 1), Duration__c = 14, Contract_BU__c = country.Id,
                                                          Contract_Type__c = 'Contract',Duration_type__c='Month');
        Test.startTest();
        Database.SaveResult result = Database.insert(contractByMonthType, false);
        Test.stopTest();
        // VALIDATION REMOVED
        ////Boolean stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
        ////System.assertEquals(stringResult, true);
        Decimal duration = [SELECT Duration__c FROM Contract__c WHERE Id = :contractByMonthType.Id LIMIT 1].Duration__c;
        System.assertEquals(0, result.getErrors().size());
        System.assertEquals(12, duration);
    }
    
    // Test validation  prevent adding  contract if dates doesnt respect contract periodicity on month success.
    @isTest static void test_createPeriodicMonthContractSuccess() {
        init();
        Contract__c contractByMonthType = new Contract__c(Name ='Test Contract 002', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C1234567',
                                                          Contract_BDate__c = date.newInstance((year+3), 1, 1), Contract_EDate__c = date.newInstance((year+3), 12, 1), Duration__c = 12, Contract_BU__c = country.Id,
                                                          Contract_Type__c = 'Contract',Duration_type__c='Month');		
        insert contractByMonthType;
        System.assertEquals(12, contractByMonthType.Duration__c);
    }
    
    // Test validation  prevent adding  contract if dates doesnt respect contract periodicity on week fail.
    @isTest static void test_createPeriodicWeekContractFail() {
        init();
        Contract__c contractByWeekType = new Contract__c(Name ='Test Contract 003', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C1234',
                                                         Contract_BDate__c = date.newInstance((year+4), 1, 1), 
                                                         Contract_EDate__c = date.newInstance((year+4), 6, 10), Duration__c = 25, Contract_BU__c = country.Id,
                                                         Contract_Type__c = 'Contract',Duration_type__c = 'Week');		
        Test.startTest();
        Database.SaveResult result = Database.insert(contractByWeekType, false);
        Test.stopTest();
        // VALIDATION REMOVED
        ////Boolean stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
        ////System.assertEquals(stringResult, true);
        Decimal duration = [SELECT Duration__c FROM Contract__c WHERE Id = :contractByWeekType.Id LIMIT 1].Duration__c;
        System.assertEquals(23, duration);
    }
    
    // Test validation  prevent adding  contract if dates doesnt respect contract periodicity on week success.
    @isTest static void test_createPeriodicWeekContractSuccess() {
        init();
        Contract__c contractByWeekType2 = new Contract__c(Name ='Test Contract 004', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C1234',
                                                          Contract_BDate__c = date.newInstance((year+5), 1, 1), Contract_EDate__c = date.newInstance((year+5), 6, 10), Duration__c = 23, Contract_BU__c = country.Id,
                                                          Contract_Type__c = 'Contract',Duration_type__c='Week');		
        insert contractByWeekType2;
        System.assertEquals(23, contractByWeekType2.Duration__c);
    }
    
    // Test validation  prevent adding bulk contract if dates doesnt respect contract periodicity on week success.
    @isTest static void test_createPeriodicWeekListContractFail() {
        init();
        
        Boolean stringResult;
        List<Contract__c> lstContract = new List<Contract__c>();
        Contract__c contractByWeekType1 = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001',
                                                          Contract_BDate__c = date.newInstance((year+5), 1, 1), Contract_EDate__c = date.newInstance((year+5), 6, 10), Duration__c = 5, Contract_BU__c = country.Id,
                                                          Contract_Type__c = 'Contract',Duration_type__c='Week');		
        Contract__c contractByWeekType2 = new Contract__c(Name ='Test Contract 002', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C002',
                                                          Contract_BDate__c = date.newInstance((year+6), 1, 1), Contract_EDate__c = date.newInstance((year+6), 6, 10), Duration__c = 5, Contract_BU__c = country.Id,
                                                          Contract_Type__c = 'Contract',Duration_type__c='Week');		
        lstContract.add(contractByWeekType1);
        lstContract.add(contractByWeekType2);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstContract, false);
        Test.stopTest();
        // VALIDATION REMOVED
        /***for (Database.SaveResult result : insertResults) {
                stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
                System.assertEquals(stringResult, true);
           }***/
        Decimal duration1 = [SELECT Duration__c FROM Contract__c WHERE Id = :contractByWeekType1.Id LIMIT 1].Duration__c;
        System.assertEquals(23, duration1);
        Decimal duration2 = [SELECT Duration__c FROM Contract__c WHERE Id = :contractByWeekType2.Id LIMIT 1].Duration__c;
        System.assertEquals(23, duration2);
    }
    
    // Test validation  prevent adding  bulk contract if dates doesnt respect contract periodicity  on month fail
    @isTest static void test_createPeriodicMonthListContractFail() {
        init();
        Boolean stringResult;
        List<Contract__c> lstContract = new List<Contract__c>();
        Contract__c contractByMonthType = new Contract__c(Name ='Test Contract 006', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM001',
                                                          Contract_BDate__c = date.newInstance((year+3), 1, 1), Contract_EDate__c = date.newInstance((year+3), 12, 1), Duration__c = 14, Contract_BU__c = country.Id,
                                                          Contract_Type__c = 'Contract',Duration_type__c='Month');		
        Contract__c contractByMonthType2 = new Contract__c(Name ='Test Contract 007', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM002',
                                                           Contract_BDate__c = date.newInstance((year+4), 1, 1), Contract_EDate__c = date.newInstance((year+4), 12, 1), Duration__c =22, Contract_BU__c = country.Id,
                                                           Contract_Type__c = 'Contract',Duration_type__c='Month');		
        lstContract.add(contractByMonthType);
        lstContract.add(contractByMonthType2);
        Test.startTest();
        List<Database.Saveresult> insertResults = Database.insert(lstContract, false);
        Test.stopTest();
        // VALIDATION REMOVED
        /***for (Database.SaveResult result : insertResults) {
            stringResult = result.getErrors()[0].getMessage().contains(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity);
            System.assertEquals(stringResult, true);
        }***/
        Decimal duration1 = [SELECT Duration__c FROM Contract__c WHERE Id = :contractByMonthType.Id LIMIT 1].Duration__c;
        System.assertEquals(12, duration1);
        Decimal duration2 = [SELECT Duration__c FROM Contract__c WHERE Id = :contractByMonthType2.Id LIMIT 1].Duration__c;
        System.assertEquals(12, duration2);
    }
    
    // Test passing VAT values from sales condition to contract based on year and bu on create.
    @isTest static void test_createContractVATCondition() {
        init();
        contract = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(saleCondition.Id, Contract.Default_Sales_Conditions__c);
        System.assertEquals(saleCondition.VAT_Finance_Rate__c, contract.VAT_Finance_Rate__c);
        System.assertEquals(saleCondition.VAT_Rebate_Rate__c, contract.VAT_Rebate_Rate__c);
        System.assertEquals(saleCondition.VAT_Service_Rate__c, contract.VAT_Service_Rate__c);
    }
    
    @isTest static void test_updateContractVATCondition() {
        init();
        // Create Pol_Sale_Condition__c for year+1
        Pol_Sale_Condition__c saleCondition1 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance((year+1), 1, 1),
                                                                         Master_BU__c = country.Id, VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10,
                                                                         VAT_Service_Rate__c = 10, Buying_Payment_Condition__c = 'Net',
                                                                         Buying_Payment_Days__c = '5', Status__c = 'Validated');
        insert saleCondition1;
        // Create Contract__c for year+1
        Contract__c contract1 = new Contract__c(Name = 'Test Contract 006', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM001',
                                                Contract_BDate__c = date.newInstance((year+1), 1, 1), Contract_EDate__c = date.newInstance((year+1), 12, 1), Duration__c = 12,
                                                Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Duration_type__c = 'Month');		
        insert contract1;
        contract1 = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        System.assertEquals(saleCondition1.Id, contract1.Default_Sales_Conditions__c);
        System.assertEquals(saleCondition1.VAT_Finance_Rate__c, contract1.VAT_Finance_Rate__c);
        System.assertEquals(saleCondition1.VAT_Rebate_Rate__c, contract1.VAT_Rebate_Rate__c);
        System.assertEquals(saleCondition1.VAT_Service_Rate__c, contract1.VAT_Service_Rate__c);
        
        Id inExceptionRT = NegoptimHelper.getObjectRecordTypeId(Pol_Sale_Condition_Exception__c.SObjectType, 'In_Exception');
        // Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c saleConditionException = new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 11, VAT_Rebate_Rate__c = 12, 
                                                                                                     VAT_Service_Rate__c = 13, Contract__c = contract1.Id,
                                                                                                     Version__c = 1, RecordTypeId = inExceptionRT);
        insert saleConditionException;
        contract1 = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract1.Id];
        System.assertEquals(saleConditionException.VAT_Finance_Rate__c, contract1.VAT_Finance_Rate__c);
        System.assertEquals(saleConditionException.VAT_Rebate_Rate__c, contract1.VAT_Rebate_Rate__c);
        System.assertEquals(saleConditionException.VAT_Service_Rate__c, contract1.VAT_Service_Rate__c);
    }
    
    // Test passing VAT values from sales condition to contract based on year and bu on bulk create.
    @isTest static void test_listContractVATCondition() {
        init();
        // Create BU
        Orga_BU__c country = new Orga_BU__c(Name = 'Test BU3', BU_Code__c = 'TBU3', BU_ODate__c = date.newInstance((year+2), 1, 1));
        // create record type
        RecordType RT = [Select Id From RecordType WHERE Name = 'Country' limit 1];
        country.RecordTypeId = RT.Id;
        insert country;
        List<Contract__c> lstContract = new List<Contract__c>();
        Pol_Sale_Condition__c salesCond2 = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance((year+10), 1, 1), 
                                                                     Master_BU__c = country.Id,VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10);  
        insert salesCond2;
        Contract__c con1 = new Contract__c(Name ='Test Contract 006', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM001',
                                           Contract_BDate__c = date.newInstance((year+10), 1, 1), Contract_EDate__c = date.newInstance((year+10), 6, 1), Duration__c = 6, Contract_BU__c = country.Id,
                                           Contract_Type__c = 'Contract',Duration_type__c = 'Month');
        Contract__c con2 = new Contract__c(Name ='Test Contract 007', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM002',
                                           Contract_BDate__c = date.newInstance((year+10), 7, 1), Contract_EDate__c = date.newInstance((year+10), 12, 1), Duration__c = 6, Contract_BU__c = country.Id,
                                           Contract_Type__c = 'Contract',Duration_type__c = 'Month');
        lstContract.add(con1);
        lstContract.add(con2);
        insert lstContract;
        Contract__c Contract = [SELECT Id,Default_Sales_Conditions__c FROM Contract__c WHERE Id = :lstContract.get(0).Id];
        System.assertEquals(salesCond2.Id, Contract.Default_Sales_Conditions__c);
        
    }
    
    // Test validation  prevent updating contract  if date greater than its condition 
    @isTest static void test_updateContractDateFail() {
        init();
        // Create condition.
        Contract_Discount__c condition1 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 3, 1),
                                                                   Disc_EDate__c = date.newInstance(year, 5, 25), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                                   BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert condition1;
        contract.Contract_BDate__c = date.newInstance(year, 4, 25);
        contract.Duration__c = 3;
        Test.startTest();
        Database.SaveResult result = Database.update(contract, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        Boolean stringResult = result.getErrors()[0].getMessage().contains('Cannot update Contract date because its related condition');
        System.assertEquals(true, stringResult);
        
    }
    
    @isTest static void calculateBaseTO() {
        init();
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C2',
                                                                        Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                                        Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 2, 1), Disc_EDate__c = date.newInstance(year, 6, 1),
                                                                  Value_per__c = 2.5, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Base_TO_Nego__c = 0, Base_TO_Actual__c = 0, Base_TO_Forecast__c = 0);
        insert condition;
        
        Contract_Discount__c cond = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
                                     FROM Contract_Discount__c WHERE Id =: condition.Id];
        contract.TO1__c = 10;
        contract.TO2__c = 10;
        contract.TO3__c = 10;
        contract.TO4__c = 10;
        contract.TO1_Fact__c = 10;
        contract.TO2_Fact__c = 10;
        contract.TO3_Fact__c = 10;
        contract.TO4_Fact__c = 10;
        contract.TO1_FX__c = 10;
        contract.TO2_FX__c = 10;
        contract.TO3_FX__c = 10;
        contract.TO4_FX__c = 10;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(contract, false);
        Test.stopTest();
        Contract_Discount__c cond2 = [SELECT Id, Base_TO_Nego__c, Base_TO_Actual__c, Base_TO_Forecast__c, Respects_Contract_Scope__c
                                      FROM Contract_Discount__c WHERE Id =: condition.Id];
        // Assertion.
        System.assertEquals(40, cond2.Base_TO_Nego__c);
        System.assertEquals(40, cond2.Base_TO_Actual__c);
        System.assertEquals(40, cond2.Base_TO_Forecast__c);
    }
    
    // Test passing VAT values from sales condition exception to contract based on year and bu 
    @isTest static void test_ContractVATConditionException() {
        init();
        // Create Pol_Sale_Condition__c.
        Pol_Sale_Condition__c saleCondition = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance((year+10), 1, 1),
                                                                        Master_BU__c = country.Id,
                                                                        VAT_Finance_Rate__c = 10,
                                                                        VAT_Rebate_Rate__c = 10,
                                                                        VAT_Service_Rate__c = 10,
                                                                        Buying_Payment_Condition__c = 'Net',
                                                                        Buying_Payment_Days__c = '5',
                                                                        Status__c = 'Validated');  
        insert saleCondition;
        // Create contract.
        Contract__c contract = new Contract__c(Name = supplier.Name + ' - Contract ' + (year+10), Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001',
                                               Contract_BDate__c = date.newInstance((year+10), 1, 1), Contract_EDate__c = date.newInstance((year+10), 12, 31),
                                               Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c salesExCond = 
            new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 10, VAT_Rebate_Rate__c = 10, VAT_Service_Rate__c = 10, Contract__c = contract.Id,
                                                Policy_Sales_Conditions__c = saleCondition.Id);
        insert salesExCond;
        Contract__c c = [SELECT Id, VAT_Finance_Rate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(salesExCond.VAT_Finance_Rate__c, c.VAT_Finance_Rate__c);
    }
    
    // Assign supplier ISO code into the contract ISO Code.
    @isTest static void assignmentISOCurrency() {
        init();
        // Assertion.
        Contract__c selectedC = [SELECT CurrencyIsoCode FROM Contract__c];
        System.assertEquals(currencyIsoCode, selectedC.CurrencyIsoCode);
    }
    
    // Assign supplier ISO code into the contract ISO Code.
    @isTest static void assignmentISOCurrency_Bulk() {
        init();
        // Create contracts.
        List<Contract__c> cs = new List<Contract__c>();
        // Create contract.
        for (Integer i=1 ; i < 6 ; i ++) {
            Contract__c c = new Contract__c(Name = 'Contract Name' + i, Supplier__c = supplier.Id, CurrencyIsoCode = 'USD',
                                            Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123', Duration__c = 5,
                                            Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1),
                                            Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Duration_type__c = 'Month');
            cs.add(c);
        }
        // Start test.
        Test.startTest();
        Database.insert(cs, false);
        Test.stopTest();
        // Assertion.
        List<Contract__c> selectedCs = [SELECT CurrencyIsoCode FROM Contract__c];
        for (Contract__c selectedC : selectedCs) {
            System.assertEquals(currencyIsoCode, selectedC.CurrencyIsoCode);
        }
    }
    
    // Test is foreingn supplier trigger
    @isTest static void test_isForeignSupplierTrigger() {
        init();
        // make Contract__c.Is_Foreign_Supplier__c = false
        NS.Acc_Country__c = 'Other Country Name';
        update NS;
        delete contract;
        // Create Contract__c for year+1
        contract = new Contract__c(Name = 'Contract Is_Foreign_Supplier__c true', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CM001',
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 1), Duration__c = 12,
                                   Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Duration_type__c = 'Month');		
        insert contract;
        Integer count = [SELECT COUNT() FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract.Id];
        System.assertEquals(1, count);
        contract = [SELECT Id, Default_Sales_Conditions__c, VAT_Finance_Rate__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(0, contract.VAT_Finance_Rate__c);
        System.assertEquals(0, contract.VAT_Rebate_Rate__c);
        System.assertEquals(0, contract.VAT_Service_Rate__c);
    }
    
    // datesOverlapControlBU is True.
    @isTest static void datesOverlapControlBU() {
        init();
        delete [select Id from document];
        // Create Document
        if(folder != null) {
            String str = '{"tOGapTolerencePositive":0,"tOGapTolerenceNegative":0,"reminderValue3":0,"reminderValue2":0,"reminderValue1":0,"reminderLevel":0,"reminderDescription3":"","reminderDescription2":"","reminderDescription1":"","profile":null,"groupBU2":null,"groupBU1":null,"groupBU":null,"delimiter":",","datesOverlapControlBU":true,"coopGapTolerencePositive":0,"coopGapTolerenceNegative":0}';
            document = new Document(Name = NegoptimHelper.DOCUMENT_SETTINGS_NAME, Body = Blob.valueof(str), FolderId = folder.Id );
            insert document;
        }
        Contract__c c = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C12345',
                                               Contract_BDate__c = date.newInstance(year,4, 1), Contract_EDate__c = date.newInstance(year, 8, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                               Contract_Type__c = 'Contract',Duration_type__c='Month');		
        Test.startTest();
        Database.SaveResult result = Database.insert(c, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Contract_Exist_Same_Period + ' - ('+contract.Id+')', result.getErrors()[0].getMessage());
    }
    
    // Assign the Sales Condition Exception of the Parent Contract (if exist) to the current contract.
    @isTest static void assignSalesConditionException() {
    	init();
        NS.Acc_Country__c = 'CND';
        update NS;
    	Id inExceptionRT = NegoptimHelper.getObjectRecordTypeId(Pol_Sale_Condition_Exception__c.SObjectType, 'In_Exception');
    	// Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c saleConditionException1 = new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 11, VAT_Rebate_Rate__c = 12, 
                                                                                                     VAT_Service_Rate__c = 13, Contract__c = contract.Id,
                                                                                                     Version__c = 1, RecordTypeId = inExceptionRT);
        // Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c saleConditionException2 = new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 11, VAT_Rebate_Rate__c = 12, 
                                                                                                     VAT_Service_Rate__c = 13, Contract__c = contract.Id,
                                                                                                     Version__c = 1, RecordTypeId = inExceptionRT);
        insert new List<Pol_Sale_Condition_Exception__c>{saleConditionException1, saleConditionException2};
    	// Create contract.
        Contract__c contract2 = new Contract__c(Name ='Test Contract 002', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C124',
                                   Contract_BDate__c = date.newInstance(year, 7, 1), Contract_EDate__c = date.newInstance(year, 9, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                   Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month', Parent_Contract__c = contract.Id);			
        insert contract2;
        
        Integer count = [SELECT count() FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract2.Id];
        System.assertEquals(3, count);
    }
    
    @isTest static void assignSalesConditionException_mass() {
    	init();
    	country.Country__c = 'CND';
        update country;
    	Id inExceptionRT = NegoptimHelper.getObjectRecordTypeId(Pol_Sale_Condition_Exception__c.SObjectType, 'In_Exception');
    	// Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c saleConditionException1 = new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 11, VAT_Rebate_Rate__c = 12, 
                                                                                                     VAT_Service_Rate__c = 13, Contract__c = contract.Id,
                                                                                                     Version__c = 1, RecordTypeId = inExceptionRT);
        // Create Pol_Sale_Condition_Exception__c.
        Pol_Sale_Condition_Exception__c saleConditionException2 = new Pol_Sale_Condition_Exception__c(VAT_Finance_Rate__c = 11, VAT_Rebate_Rate__c = 12, 
                                                                                                     VAT_Service_Rate__c = 13, Contract__c = contract.Id,
                                                                                                     Version__c = 1, RecordTypeId = inExceptionRT);
        insert new List<Pol_Sale_Condition_Exception__c>{saleConditionException1, saleConditionException2};
    	// Create contracts.
        Contract__c contract2 = new Contract__c(Name ='Test Contract 002', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C124',
                                   Contract_BDate__c = date.newInstance(year, 7, 1), Contract_EDate__c = date.newInstance(year, 9, 25), Duration__c = 3, Contract_BU__c = country.Id,
                                   Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month', Parent_Contract__c = contract.Id);			
        Contract__c contract3 = new Contract__c(Name ='Test Contract 003', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C125',
                                   Contract_BDate__c = date.newInstance(year, 10, 1), Contract_EDate__c = date.newInstance(year, 11, 1), Duration__c = 2, Contract_BU__c = country.Id,
                                   Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month', Parent_Contract__c = contract.Id);			
        Contract__c contract4 = new Contract__c(Name ='Test Contract 004', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C126',
                                   Contract_BDate__c = date.newInstance(year, 11, 2), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 2, Contract_BU__c = country.Id,
                                   Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month', Parent_Contract__c = contract.Id);			
        insert new List<Contract__c>{contract2, contract3, contract4};
        Integer count2 = [SELECT count() FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract2.Id];
        Integer count3 = [SELECT count() FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract3.Id];
        Integer count4 = [SELECT count() FROM Pol_Sale_Condition_Exception__c WHERE Contract__c = :contract4.Id];
        System.assertEquals(3, count2);
        System.assertEquals(3, count3);
        System.assertEquals(3, count4);
    }
    // fill sell in line to be updated with contract value
    @isTest static void test_updateSellinFlowOnInsertContract() {
        init();        
        Sup_Supplier__c defaultSupplier = new Sup_Supplier__c(Name = 'Default Supplier', Code__c = 'DS', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                                              Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert defaultSupplier;
        Sup_sup_NegoScope__c defaultNegoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :defaultSupplier.Id LIMIT 1];
        // Create Country
        Orga_BU__c country1 = new Orga_BU__c(Name = 'Source LEB', BU_Code__c = 'LEB', CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = 'LBN', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
        country1.Country__c = country.Name;
        country1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country1;
        // Create Supplier
        Sup_Supplier__c  supplier1 = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                                        Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier1;
        // Get the default negoscope created on supplier creation
        Sup_sup_NegoScope__c NS1 = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier1.Id LIMIT 1];
        // Create Departments & Sections.
        Orga_HE__c department = TestDataFactory.createDepartment(true, rootId);
        Orga_HE__c section = TestDataFactory.createSection(true, department.Id);
        // Create brand
        Sup_Brand__c brand = new Sup_Brand__c(Name = supplier1.Name + ' Brand 1', Brand_Owner__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        insert brand;
        // Create product
        Product2 product = TestDataFactory.createProduct(false, section.Id, supplier1.Id);
        product.Ext_id__c = '1';
        insert product;
        // Create PG
        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' PG1', SNA_Code__c = '001', GIMA_Code__c = '001', 
                                                               Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier1.Id, 
                                                               Brand__c = brand.Id, Product__c = product.Id, CurrencyIsoCode = currencyIsoCode);
        insert pg;
        // Create sell in flow
        Sell_in_Flow__c sellIn = new Sell_in_Flow__c(BU__c = country.Id, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id, 
                                                     Supplier__c = supplier1.Id, Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 20,
                                                     Invoice_Quantity__c = 5, Unit_Cost__c = 2, Master_BU__c = country.Id,
                                                     Invoice_Date__c = Date.newInstance(year, 3, 1), Order_Date__c = Date.newInstance(year, 3, 10));
        insert sellIn;
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract.Id);
        // create official contract
        Contract__c officialSellinContract = new Contract__c(Name ='Official Contract', Supplier__c = supplier1.Id, Supplier_Nego_Scope__c = NS1.Id,
                                                             BU_Source__c = country.Id, Contract_BU__c = country.Id, Contract_Numbder__c = 'C' + math.random() * 5,
                                                             Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 5,
                                                             Contract_Type__c = 'Contract', D_N__c = 'N', Duration_type__c = 'Month');
        Test.startTest();
        insert officialSellinContract;
        Test.stopTest();
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(officialSellinContract.Id, sellIn.Contract__c);
    }
    
    // Delete contract is linked to sell in flow
    @isTest static void test_deleteContract() {
        init();
        // Create Supplier
        Sup_Supplier__c  supplier1 = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                                         Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier1;
        // Get the default negoscope created on supplier creation
        Sup_sup_NegoScope__c NS1 = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier1.Id LIMIT 1];
        // Create Department
        Orga_HE__c department = TestDataFactory.createDepartment(true, rootId);
        // Create Section        
        Orga_HE__c section = TestDataFactory.createSection(true, department.Id);
        // Create product
        Product2 product = new Product2(Name = 'P001', ProductCode = 'P001', Category__c = section.Id, Product_MasterSupplier__c = supplier.Id);
        insert product;
        // Create sell in flow
        Sell_in_Flow__c sellIn = new Sell_in_Flow__c(BU__c = country.Id, Structure_level__c = section.Id, Mvt_Purch_Product__c = product.Id, 
                                                     Supplier__c = supplier1.Id, Invoice_Net_Amount_woTax__c = 100, Footer_Order_Discount__c = 20,
                                                     Invoice_Quantity__c = 5, Unit_Cost__c = 2, Master_BU__c = country.Id,
                                                     Invoice_Date__c = Date.newInstance(year, 3, 1), Order_Date__c = Date.newInstance(year, 3, 10));
        insert sellIn;
        sellIn = [SELECT Id, Contract__c FROM Sell_in_Flow__c WHERE Id = :sellIn.Id];
        System.assertEquals(sellIn.Contract__c, contract.Id);
        // Start test.
        Database.DeleteResult result = Database.delete(contract, false);
        System.assertNotEquals(null, result.getErrors()[0].getMessage());
    }
    
    @isTest static void test_assignGRCIndex() {
    	init();
    	Sup_sup_NegoScope__c NS2 = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id);
    	insert NS2;
    	GRC__c GRC = new GRC__c(GRC_Master_BU__c = contract.Contract_BU__c, GRC_Category__c = NegoptimHelper.getRootId(),
                                GRC_BU__c = null, GRC_Period__c = 'Year', GRC_Period_Num__c = year);
        insert GRC;
    	GRC_Contract__c cGRC = new GRC_Contract__c(GRC__c = GRC.Id, NS__c = NS.Id, Contract__c = contract.Id, Supplier__c = supplier.Id,
    						Discount_N_1__c = 1, Discount_N__c = 2, Rebates_N_1__c = 1, Rebates_N__c = 2, Fees_N_1__c = 1, Fees_N__c = 2,
    						Others_N_1__c = 1, Others_N__c = 2, Net4_N_1__c = 1, Net4_N__c = 2, Promo_N_1__c = 1, Promo_N__c = 2,
    						Opening_N_1__c = 1, Opening_N__c = 2);
    	insert cGRC;
    	// Update Ns Contract.
    	contract.Supplier_Nego_Scope__c = NS2.Id;
    	// Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(contract, false);
        Test.stopTest();
        // Select GRC contract.
        GRC_Contract__c obj = [SELECT Id, Discount_N_1__c, Discount_N__c, Rebates_N_1__c, Rebates_N__c,
    					Fees_N_1__c, Fees_N__c, Others_N_1__c, Others_N__c, Net4_N_1__c, Net4_N__c,
            			Promo_N_1__c, Promo_N__c, Opening_N_1__c, Opening_N__c
                        FROM GRC_Contract__c WHERE Id =: cGRC.Id];
        // Assertions.
        System.assertEquals(2, obj.Discount_N_1__c);
        System.assertEquals(0, obj.Discount_N__c);
        System.assertEquals(2, obj.Rebates_N_1__c);
        System.assertEquals(0, obj.Rebates_N__c);
        System.assertEquals(2, obj.Fees_N_1__c);
        System.assertEquals(0, obj.Fees_N__c);
        System.assertEquals(2, obj.Others_N_1__c);
        System.assertEquals(0, obj.Others_N__c);
        System.assertEquals(2, obj.Net4_N_1__c);
        System.assertEquals(0, obj.Net4_N__c);
        System.assertEquals(2, obj.Promo_N_1__c);
        System.assertEquals(0, obj.Promo_N__c);
        System.assertEquals(2, obj.Opening_N_1__c);
        System.assertEquals(0, obj.Opening_N__c);
    }
    
    // Set NS conditions added manually
    static testmethod void updateNSConditions() {
        init();
        Sup_sup_NegoScope__c NS2 = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id);
        insert NS2;
        // Create conditions.
        Contract_Discount__c condition1 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 2, 1), date.newInstance(year, 3, 30));
        Contract_Discount__c condition2 = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 4, 1), date.newInstance(year, 4, 30));
        insert new List<Contract_Discount__c>{condition1, condition2};
        // Create Group Contract
        Contract_Group__c contractGroup = TestDataFactory.createContractGroup(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 2, 1), supplier.Name + ' - Contract1');
        contractGroup.contract_linked__c = contract.Id;
        contractGroup.Status__c = 'Validated';
        insert contractGroup;
        // Create Group Condition
        Contract_Group_Detail__c contractGroupDetail = TestDataFactory.createConditionGroup(false, contractGroup, tariffCondition);
        contractGroupDetail.condition_linked__c = condition1.Id;
        contractGroupDetail.Status__c = 'Validated';
        insert contractGroupDetail;
    	// Update Ns Contract.
    	contract.Supplier_Nego_Scope__c = NS2.Id;
        contract.Linked_contract_group__c = contractGroup.Id;
        Database.update(contract, false);
        Test.startTest();
        Database.executeBatch(new GroupContractSynchroBatch('GroupContractSynchroBatchTest', false, Null, Null));
        Test.stopTest();
        // Select condition2.
        condition2 = [SELECT Id, Product_Scope__c FROM Contract_Discount__c WHERE Id = :condition2.Id];
        // Assertions.
        System.assertEquals(NS2.Id, condition2.Product_Scope__c);
    }
}