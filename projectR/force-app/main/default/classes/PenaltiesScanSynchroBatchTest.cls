/**
* Unit Test class used to insert penalties conditions.
**/
@isTest
private class PenaltiesScanSynchroBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    
    static void init() {
        try {
            year = TestDataFactory.year;
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Department
            department = TestDataFactory.createDepartment(true, rootId);
            // Create Section
            section = TestDataFactory.createSection(true, department.Id);
            // Create supplier
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Get the default negoscope created on supplier creation
            NS = [SELECT Id, NS_Code__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            // Create Policy - Tariff Conditions
            tariffCondition = TestDataFactory.createTariffConditions(false, 2, 1)[0];
            tariffCondition.Name = 'Penalty1';
            insert tariffCondition;
            // Create Contract
            contract = TestDataFactory.createContract(true, country, supplier, NS);
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage() + '-' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    // Test Mandatory Fields
    @isTest static void case1_EmptyMandatoryFields_Success() {
        init();
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2, 
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = 'SecY', 
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null, 
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c, 
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Error_desc__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        System.assertEquals(true, String.IsNotBlank(penalty.Error_desc__c));
    }
    // Case section code not exist
    @isTest static void case2_SectionCodeNotExist_Success() {
        init();
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2,
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = 'Sec001000',
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null,
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = 'SUP001000',
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        System.assertEquals('Rejected', penalty.Status__c);
    }
    // Case NS and one contract based on the section code and the suppliers
    @isTest static void case3_SectionWithNegoScopeAndContract_Success() {
        init();
        Sup_sup_NegoScope__c NS1 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 1', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true, NS_Section_main__c = section.Name,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS1;            
        // Create Contract
        Contract__c contract1 = TestDataFactory.createContract(true, country, supplier, NS1);
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2, 
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c, 
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null, 
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c, 
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        List<Contract_Discount__c> conditions = [SELECT Id, Name FROM Contract_Discount__c WHERE Contract__c = :contract1.Id];
        System.assertEquals(1, conditions.size());
        System.assertEquals('Synchronized', penalty.Status__c);
    }
    // Case NS and multi contract based on the section code and the suppliers.
    @isTest static void case4_SectionWithNegoScopeAndMultiContract_Success() {
        init();
        Sup_sup_NegoScope__c NS1 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 1', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true, NS_Section_main__c = section.Name,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS1;
        // Create Contracts
        Contract__c contract1 = TestDataFactory.createContract(false, country, supplier, NS1);
        contract1.Contract_BDate__c = Date.newInstance(year, 1, 1);
        contract1.Contract_EDate__c = Date.newInstance(year, 6, 30);
        contract1.Duration__c = 6;
        insert contract1;
        Contract__c contract2 = TestDataFactory.createContract(false, country, supplier, NS1);
        contract2.Contract_BDate__c = Date.newInstance(year, 7, 1);
        contract2.Contract_EDate__c = Date.newInstance(year, 12, 31);
        contract2.Duration__c = 6;
        insert contract2;
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2, 
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c, 
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null, 
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c, 
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        List<Contract_Discount__c> conditions = [SELECT Id, Name FROM Contract_Discount__c WHERE Contract__c = :contract1.Id];
        System.assertEquals(1, conditions.size());
        System.assertEquals('Synchronized', penalty.Status__c);
    }
    // Case multi NS and multi contract based on the section code and the suppliers.
    @isTest static void case5_SectionWithMultiNegoScopeAndMultiContract_Success() {
        init();
        // Create NS
        Sup_sup_NegoScope__c NS1 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 1', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true, NS_Section_main__c = section.Name,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS1;
        Sup_sup_NegoScope__c NS2 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 2', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true, NS_Section_main__c = section.Name,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS2;
        // Create Contracts
        Contract__c contract1 = TestDataFactory.createContract(true, country, supplier, NS1);
        Contract__c contract2 = TestDataFactory.createContract(true, country, supplier, NS2);
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2,
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c,
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null,
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c,
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        List<Contract_Discount__c> conditions = [SELECT Id, Name FROM Contract_Discount__c WHERE Contract__c = :contract2.Id];
        System.assertEquals(1, conditions.size());
        System.assertEquals('Synchronized', penalty.Status__c);
    }
    // Case NS HE and multi contract based on the section code and the suppliers.
    @isTest static void case6_SectionHEWithMultiNegoScopeAndMultiContract_Success() {
        init();
        // Create NS
        Sup_sup_NegoScope__c NS1 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 1', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS1;
        Sup_sup_NegoScope__c NS2 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 2', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS2;
        Supplier_NS_HE__c NsHE = new Supplier_NS_HE__c(Structure_Element__c = section.Id, Sup_sup_NegoScope__c = NS2.Id);
        insert NsHE;
        // Create Contracts
        Contract__c contract1 = TestDataFactory.createContract(true, country, supplier, NS1);
        Contract__c contract2 = TestDataFactory.createContract(true, country, supplier, NS2);
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2, 
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c, 
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null, 
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c, 
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        List<Contract_Discount__c> conditions = [SELECT Id, Name FROM Contract_Discount__c WHERE Contract__c = :contract2.Id];
        System.assertEquals(1, conditions.size());
        System.assertEquals('Synchronized', penalty.Status__c);
    }
    // No Contract or NS found + generate invoice
    @isTest static void case7_GenerateInvoiceWithoutContract() {
        init();
        // Create Section
        Orga_HE__c section = new Orga_HE__c(Name = 'Beverages', Elt_Code__c = '1011', Parent_Element__c = department.Id, Level__c = 2,
                                            Status_BDate__c = date.newInstance(year, 1, 1),
                                            Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c = false);
        insert section;	
        // Create Sales Condition
        // Create Pol_Sale_Condition__c.
        Pol_Sale_Condition__c saleCondition = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance(year, 12, 31),
                                                                        Master_BU__c = country.Id,
                                                                        VAT_Finance_Rate__c = 10,
                                                                        VAT_Rebate_Rate__c = 11,
                                                                        VAT_Service_Rate__c = 12,
                                                                        Buying_Payment_Condition__c = 'Net',
                                                                        Buying_Payment_Days__c = '5 days',
                                                                        Status__c = 'Validated');  
        insert saleCondition;
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Penalty', Condition_Name__c = 'Penalty1', Month__c = 2,
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c, 
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null,
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c,
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        List<Invoice__c> invoices = [SELECT Id, Inv_Date__c, Inv_DueDate__c,
                                     (SELECT Id, Inv_VAT_Percent__c, Invoice_detail_nego_disc_type__c FROM Invoice_Details__r WHERE Inv_Detail_BU__c = :country.Id)
                                     FROM Invoice__c
                                     WHERE Inv_Business_Unit__c = :country.Id];
        Date invoiceDate = Date.today() > NegoptimHelper.getLastDayOfMonth(year, 2) ? NegoptimHelper.getLastDayOfMonth(year, 2) : Date.today();
        for(Invoice__c invoice : invoices) {
            System.assertEquals(invoiceDate.addDays(30), invoice.Inv_DueDate__c);
            for(Invoice_Detail__c item : invoice.Invoice_Details__r) {
                System.assertEquals(11, item.Inv_VAT_Percent__c);
                System.assertEquals(tariffCondition.Nego_Discount_Type__c, item.Invoice_detail_nego_disc_type__c);
            }
        }
        System.assertEquals(1, invoices.size());
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        List<Contract_Discount__c> conditions = [SELECT Id, Name FROM Contract_Discount__c WHERE Contract__c = :contract.Id];            
        System.assertEquals(0, conditions.size());
        System.assertEquals('Synchronized without Contract', penalty.Status__c);
    }
    // No Contract or NS found + generate invoice
    @isTest static void case8_GenerateInvoiceWithoutContractWithForeignSupplier() {
        init();
        supplier.Acc_Country__c = 'OTHER COUNTRY'; // Make it foreign
        update supplier;
        // Create Section
        Orga_HE__c section = TestDataFactory.createSection(true, department.Id);
        // Create Sales Condition
        // Create Pol_Sale_Condition__c.
        Pol_Sale_Condition__c saleCondition = new Pol_Sale_Condition__c(Name='Sales Condition 1', Status_BDate__c = date.newInstance(year, 12, 31),
                                                                        Master_BU__c = country.Id,
                                                                        VAT_Finance_Rate__c = 10,
                                                                        VAT_Rebate_Rate__c = 11,
                                                                        VAT_Service_Rate__c = 12,
                                                                        Buying_Payment_Condition__c = 'Net',
                                                                        Buying_Payment_Days__c = '5 days',
                                                                        Status__c = 'Validated');  
        insert saleCondition;
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Penalty', Condition_Name__c = 'Penalty1', Month__c = 2,
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c,
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null,
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c,
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        List<Invoice__c> invoices = [SELECT Id, Inv_Date__c, Inv_DueDate__c,
                                     (SELECT Id, Inv_VAT_Percent__c, Invoice_detail_nego_disc_type__c FROM Invoice_Details__r WHERE Inv_Detail_BU__c = :country.Id)
                                     FROM Invoice__c
                                     WHERE Inv_Business_Unit__c = :country.Id];
        Date invoiceDate = Date.today() > NegoptimHelper.getLastDayOfMonth(year, 2) ? NegoptimHelper.getLastDayOfMonth(year, 2) : Date.today();
        for(Invoice__c invoice : invoices) {
            System.assertEquals(invoiceDate.addDays(30), invoice.Inv_DueDate__c);
            for(Invoice_Detail__c item : invoice.Invoice_Details__r) {
                System.assertEquals(0, item.Inv_VAT_Percent__c);
                System.assertEquals(tariffCondition.Nego_Discount_Type__c, item.Invoice_detail_nego_disc_type__c);
            }
        }
        System.assertEquals(invoices.size(), 1);
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        List<Contract_Discount__c> conditions = [SELECT Id, Name FROM Contract_Discount__c WHERE Contract__c = :contract.Id];            
        System.assertEquals(0, conditions.size());
        System.assertEquals('Synchronized without Contract', penalty.Status__c);
    }
    // Case penalty with nego scope code not exist.
    @isTest static void case9_PenaltyWithNSCodeNotExist_Fails() {
        init();
        Sup_sup_NegoScope__c NS1 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 1', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true, NS_Section_main__c = section.Name,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS1;
        NS1 = [SELECT Id, NS_Code__c FROM Sup_sup_NegoScope__c WHERE Id = :NS1.Id];
        // Create Contract
        Contract__c contract1 = TestDataFactory.createContract(true, country, supplier, NS1);
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2, 
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c, 
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null, 
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c, 
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year,
                                                          NS_Code__c = '00123');
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        System.assertEquals('Rejected', penalty.Status__c);
    }    
    // Case penalty with nego scope code exist.
    @isTest static void case10_PenaltyWithNSCodeExist_Success() {
        init();
        Sup_sup_NegoScope__c NS1 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 1', Supplier__c = supplier.Id,
                                                            NS_Code_Prefix__c = 'NAT', Is_All_Brands__c = true, Incl_NewBrand__c = true, Is_All__c = true,
                                                            Is_All_HE__c = true, Is_All_BU__c = true, Incl_NewBU__c = true, NS_Section_main__c = section.Name,
                                                            Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert NS1;
        NS1 = [SELECT Id, NS_Code__c FROM Sup_sup_NegoScope__c WHERE Id = :NS1.Id];
        // Create Contract.
        Contract__c contract1 = TestDataFactory.createContract(true, country, supplier, NS1);
        // insert Supply_Penalty__c With Mandatory Fields
        Supply_Penalty__c penalty = new Supply_Penalty__c(Comment__c = 'Pen', Condition_Name__c = 'Penalty1', Month__c = 2,
                                                          NS_Code_Prefix__c = 'NAT', Penalty_Date__c = System.today(),
                                                          Penalty_Value__c = 100, Section__c = null, Section_Code__c = section.Elt_Code__c,
                                                          Service_Rate_Fact__c = null, Service_Rate_Target__c = null,
                                                          Status__c = 'New', Supplier__c = null, Supplier_code__c = supplier.Code__c,
                                                          Supplier_Email__c = null, Supplier_Name__c = null, Year__c = year,
                                                          NS_Code__c = NS1.NS_Code__c);
        insert penalty;
        
        Test.startTest();
        Database.executeBatch(new PenaltiesScanSynchroBatch('PenaltiesScanSynchroBatchTest', new List<Id>{penalty.Id}));
        Test.stopTest();
        
        penalty = [SELECT Id, Status__c FROM Supply_Penalty__c WHERE Id = :penalty.Id];
        List<Contract_Discount__c> conditions = [SELECT Id, Name FROM Contract_Discount__c WHERE Contract__c = :contract1.Id];            
        System.assertEquals(1, conditions.size());
        System.assertEquals('Synchronized', penalty.Status__c);
    }
}