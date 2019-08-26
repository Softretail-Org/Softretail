@isTest
private class GenerateInvoicesBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Orga_BU__c warehouse;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Supplier_PG_Mapping__c PG;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static List<Purchases_Flow_PG__c> purchases;
    private static List<Contract_Discount__c> conditions;
    private static NegoptimCustomSettings__c negoptimSettings;
    private static Invoice__c invoice;
    
    static public void init() {
        try {
            year = System.Today().year();
            // Root Element Id.
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;// NegoptimHelper.getCorporateCurrency();
            // Get all recortd type ids for Orga_BU__c SObject
            ////Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'EU');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Legal Form
            Orga_BU__c legal = TestDataFactory.createBULegal(true, myCountry);
            // Create Store
            store = TestDataFactory.createBUStores(false, country, legal.Id, 1)[0];
            // Create Warehouse
            warehouse = TestDataFactory.createBUWarehouses(false, country, 'DC', 1)[0];
            insert new List<Orga_BU__c>{store, warehouse};
            // Create Department
            department = TestDataFactory.createDepartment(false, rootId);
            insert department;
            // Create Section
            section = TestDataFactory.createSection(false, department.Id);
            insert section;
            // Create supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Get the default negoscope created on supplier creation
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            // Create Policy - Tariff Conditions
            tariffCondition = TestDataFactory.createTariffConditions(true, 2, 1)[0];
            // Create Contract
            contract = (Contract__c)TestDataFactory.createContractWithConditions(true, supplier, NS.Id, tariffCondition, 0)[0];
            // Create PG.
            PG = new Supplier_PG_Mapping__c(Name = supplier.Name + ' PG1', SNA_Code__c = '001', GIMA_Code__c = '001', Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier.Id);
            insert PG;
            conditions = new List<Contract_Discount__c>();
            // Create NegoptimCustomSettings__c
            negoptimSettings = new NegoptimCustomSettings__c(Name = 'NegoptimSettings', Invoice_Max_Closing_Day__c = Date.today().day() - 1);
            insert negoptimSettings;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage() + '-' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    static testmethod void GenerateSingleInvoice_Success() {
        init();
        Date conditionBeginDate = date.newInstance(year, 1, 1);
        conditions = new List<Contract_Discount__c>();
        // Create Conditions.
        for (Integer i = 0 ; i < 2 ; i++) {
            Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = conditionBeginDate,
                                                                      Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2 + i, Product_Scope__c = NS.Id,
                                                                      BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                      Invoice_base__c = 'Actual (YTD)', Valid__c = true, Invoice_period__c = 'Month',
                                                                      Invoice_sequence__c = 1, Payment_Condition__c = 'Net', Payment_Days__c = '10');
            conditions.add(condition);
        }
        insert conditions;
        
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Inv_Date__c, Inv_DueDate__c FROM Invoice__c WHERE Inv_Supplier__c = :supplier.Id];
        System.assertEquals(1, invoices.size());
        System.assertEquals(invoices.get(0).Inv_DueDate__c, invoices.get(0).Inv_Date__c + Integer.valueOf(conditions.get(0).Payment_Days__c));
    }
    
    static testmethod void GenerateInvoiceNumber_Success() {
        init();
        conditions = new List<Contract_Discount__c>();
        // Create Conditions.
        for (Integer i = 0 ; i < 2 ; i++) {
            Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                      Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2 + i, Product_Scope__c = NS.Id,
                                                                      BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                      Invoice_base__c = 'Actual (YTD)', first_invoice_date__c = date.newInstance(year, 1, 31), Invoice_period__c = 'Month',
                                                                      Invoice_sequence__c = 1, Valid__c = true);
            if(condition.first_invoice_date__c > Date.today()) {
                condition.first_invoice_date__c = Date.today() - 1;
            }
            conditions.add(condition);
        }
        insert conditions;
        
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        
        Invoice__c invoice = [SELECT Id, Invoice_Number_Prefix__c, Invoice_Number__c FROM Invoice__c WHERE Inv_Supplier__c = :supplier.Id];
        System.assertEquals(null, invoice.Invoice_Number__c);
        
        invoice.Inv_Status__c = 'Printed';
        update invoice;
        invoice = [SELECT Id, Invoice_Number_Prefix__c, Invoice_Number__c FROM Invoice__c WHERE Inv_Supplier__c = :supplier.Id];
        System.assertEquals(invoice.Invoice_Number_Prefix__c + '000001', invoice.Invoice_Number__c);
    }
    
    static testmethod void NoInvoiceToGenerate_Success() {
        init();
        conditions = new List<Contract_Discount__c>();
        // Create Condition and set already invoiced
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500, Already_Invoiced__c = 20,
                                                                  Invoice_base__c = 'Actual (YTD)', first_invoice_date__c = date.newInstance(year, 1, 31), Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1);
        // Update Policy - Tariff Conditions.
        tariffCondition.Index__c = 'Index1';
        update tariffCondition;
        // Create Condition and set Invoice_base__c to null
        Contract_Discount__c condition2 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                   Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                   BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                   Invoice_base__c = null, first_invoice_date__c = date.newInstance(year, 1, 31), Invoice_period__c = 'Month',
                                                                   Invoice_sequence__c = 1);
        conditions.add(condition);
        conditions.add(condition2);
        insert conditions;
        
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        
        Integer countInvoice = [SELECT COUNT() FROM Invoice__c WHERE Inv_Supplier__c = :supplier.Id];
        System.assertEquals(0, countInvoice);
    }
    
    static testmethod void GenerateMultipleDocTypeInvoice_Success() {
        init();
        // Create Policy - Tariff Conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv2 = fieldResult.getPicklistValues().get(1).getValue();
        Pol_Com_Condition__c tariffCondition2 = new Pol_Com_Condition__c(Name = plv2, Nego_Discount_Type__c = plv2, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C2',
                                                                         Abrev__c = 'Cond2', Gen_Name_com__c = 'Gen com 2', Name_Com__c = 'Com 2', Name_Fi__c = 'Fi 2',
                                                                         Name_Leg__c = 'Leg 2', Gen_Name_Fi__c = 'Gen Fi 2', Gen_Name_Leg__c = 'Gen Leg 2', VAT_Type__c = 'Rebate',
                                                                         Acc_Document_Type__c = 'Debit Note', Index__c = 'Index3');
        insert tariffCondition2;
        // Create Conditions.
        Date conditionBeginDate = date.newInstance(year, 1, 1);
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = conditionBeginDate,
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', Valid__c = true, Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1);
        Contract_Discount__c condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv2, Condition_Type__c = tariffCondition2.Id, Disc_BDate__c = conditionBeginDate,
                                                                   Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                                   BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                   Invoice_base__c = 'Actual (YTD)', Valid__c = true, Invoice_period__c = 'Month',
                                                                   Invoice_sequence__c = 1);
        insert new List<Contract_Discount__c>{condition, condition2};
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        Integer countInvoice = [SELECT COUNT() FROM Invoice__c WHERE Inv_Supplier__c = :supplier.Id];
        System.assertEquals(2, countInvoice);
    }
    
    static testmethod void DeleteInvoice_Success() {
        init();
        Test.startTest();
        conditions = new List<Contract_Discount__c>();
        Date endConditionsDate = date.newInstance(year, 12, 15);
        Date conditionBeginDate = date.newInstance(year, 1, 1);
        // Create Conditions.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = conditionBeginDate, Disc_EDate__c = endConditionsDate, Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000,
                                                                  Invoice_base__c = 'Actual (YTD)', Valid__c = true, Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1);
        Contract_Discount__c condition1 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                                   Disc_BDate__c = conditionBeginDate, Disc_EDate__c = endConditionsDate, Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                   BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Nego__c = 1000,
                                                                   Invoice_base__c = 'Negotiated', first_invoice_date__c = Date.today(), Invoice_period__c = 'Month',
                                                                   Invoice_sequence__c = 1, Valid__c = true);
        conditions.add(condition);
        conditions.add(condition1);
        insert conditions;
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        
        Integer countGeneratedInvoices = 12 - Date.today().month() + 1;
        Integer countInvoice = [SELECT COUNT() FROM Invoice__c WHERE Inv_Supplier__c = :supplier.Id];
        System.assertEquals(countGeneratedInvoices, countInvoice);
        
        Decimal totalAmountAlreadyInvoiced = 0;
        AggregateResult[] groupedConditions = [SELECT Id, SUM(Already_Invoiced__c) A1, SUM(Already_Invoiced_Edited__c) A2
                                               FROM Contract_Discount__c
                                               WHERE Id IN :conditions
                                               GROUP BY Id];
        for (AggregateResult ar : groupedConditions) {
            totalAmountAlreadyInvoiced += ar.get('A1') != null ? (Decimal)ar.get('A1') : 0;
            totalAmountAlreadyInvoiced += ar.get('A2') != null ? (Decimal)ar.get('A2') : 0;
        }
        System.assertEquals(40, totalAmountAlreadyInvoiced);
        
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c WHERE Inv_Supplier__c = :supplier.Id];
        delete invoices;
        
        AggregateResult[] groupedConditions2 = [SELECT Id, SUM(Already_Invoiced__c) A1, SUM(Already_Invoiced_Edited__c) A2
                                                FROM Contract_Discount__c
                                                WHERE Id IN :conditions
                                                GROUP BY Id];
        totalAmountAlreadyInvoiced = 0;
        for (AggregateResult ar : groupedConditions2) {
            totalAmountAlreadyInvoiced += ar.get('A1') != null ? (Decimal)ar.get('A1') : 0;
            totalAmountAlreadyInvoiced += ar.get('A2') != null ? (Decimal)ar.get('A2') : 0;
        }
        System.assertEquals(0, totalAmountAlreadyInvoiced);
    }
    
    static testmethod void GenerateMultipleInvoice_Success() {
        init();
        Date conditionBeginDate = date.newInstance(year, 1, 1);
        Test.startTest();
        // Create supplier.
        Sup_Supplier__c supplier2 = new Sup_Supplier__c(Name = 'Supplier 002', Code__c = 'SUP002', Status__c = 'Active', Country_origin__c = country.Id,
                                                        Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                                        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier2;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c negoScope2 = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier2.Id LIMIT 1];
        // Create second Contract.
        Contract__c contract2 = new Contract__c(Name ='Test Contract2', Supplier__c = supplier2.Id, Supplier_Nego_Scope__c = negoScope2.Id, Contract_Numbder__c = 'C112',
                                                Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                                Contract_Type__c = 'Contract', VAT_Rebate_Rate__c = 19.2, VAT_Service_Rate__c = 22.2);
        insert contract2;
        // Create Conditions.
        for (Integer i = 0 ; i < 2 ; i++) {
            Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c =  conditionBeginDate,
                                                                      Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2 + i, Product_Scope__c = NS.Id,
                                                                      BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                      Invoice_base__c = 'Actual (YTD)', Valid__c = true, Invoice_period__c = 'Month',
                                                                      Invoice_sequence__c = 1);
            conditions.add(condition);
        }
        Contract_Discount__c condition2 = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = conditionBeginDate,
                                                                   Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 3, Product_Scope__c = negoScope2.Id,
                                                                   BU_Scope__c = country.Id, Contract__c = contract2.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                   Invoice_base__c = 'Actual (YTD)', Valid__c = true, Invoice_period__c = 'Month',
                                                                   Invoice_sequence__c = 1);
        conditions.add(condition2);
        insert conditions;
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id, contract2.Id}, null, Date.today()));
        Test.stopTest();
        Integer countInvoice = [SELECT COUNT() FROM Invoice__c WHERE Inv_Supplier__c IN (:supplier.Id, :supplier2.Id)];
        System.assertEquals(2, countInvoice);
    }
    
    static testmethod void SetInvVATPercent_Success() {
        init();
        // Create Conditions.
        for (Integer i = 0 ; i < 2 ; i++) {
            Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                      Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2 + i, Product_Scope__c = NS.Id,
                                                                      BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                      Invoice_base__c = 'Actual (YTD)', first_invoice_date__c = date.newInstance(year, 1, 31), Invoice_period__c = 'Month',
                                                                      Invoice_sequence__c = 1);
            conditions.add(condition);
        }
        insert conditions;
        contract.VAT_Rebate_Rate__c = 8.2;
        contract.VAT_Service_Rate__c = 11.1;
        update contract;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invs = [SELECT Id, (SELECT Id, Inv_VAT_Percent__c FROM Invoice_Details__r WHERE Inv_Detail_BU__c = :country.Id)
                                 FROM Invoice__c
                                 WHERE Inv_Contract__c = :contract.Id
                                 AND Inv_Business_Unit__c = :country.Id];
        for (Invoice__c inv : invs) {
            for (Invoice_Detail__c invD : inv.Invoice_Details__r) {
                System.assertEquals(8.2, invD.Inv_VAT_Percent__c);
            }
        }
    }
    
    // VAT service and VAT rebate is null -> Invoice VAT percent should be equal to zero - VAT type is Rebate.
    static testmethod void VATNull_Rebate() {
        init();
        Date conditionBeginDate = date.newInstance(year, 1, 1);
        conditions = new List<Contract_Discount__c>();
        // Create Conditions.
        for (Integer i = 0 ; i < 2 ; i++) {
            Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = conditionBeginDate,
                                                                      Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2 + i, Product_Scope__c = NS.Id,
                                                                      BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                      Invoice_base__c = 'Actual (YTD)', Valid__c = true, Invoice_period__c = 'Month',
                                                                      Invoice_sequence__c = 1);
            conditions.add(condition);
        }
        insert conditions;
        
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invs = [SELECT Id, (SELECT Id, Inv_VAT_Percent__c FROM Invoice_Details__r WHERE Inv_Detail_BU__c = :country.Id)
                                 FROM Invoice__c
                                 WHERE Inv_Contract__c = :contract.Id
                                 AND Inv_Business_Unit__c = :country.Id];
        System.assertEquals(1, invs.size());
        System.assertEquals(2, invs.get(0).Invoice_Details__r.size());
        for (Invoice__c inv : invs) {
            for (Invoice_Detail__c invD : inv.Invoice_Details__r) {
                System.assertEquals(0, invD.Inv_VAT_Percent__c);
            }
        }
    }
    
    //inv_due_date doesn't change does not change
    static testmethod void setDueDate_Ins() { 
        init();
        Date invDueDate = date.newInstance(year, 1, 15);
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        negoSettings.allowUpdatingInvoiceDateOnPrint = false;
        GlobalSettingsManager.saveGlobalSettings(negoSettings);
        // Create Invoice
        invoice = new Invoice__c(Inv_Supplier__c = supplier.Id, Inv_Business_Unit__c = country.Id, Sequence_Number__c = 8,
                                 Inv_FiscalYear__c = year, Status_BDate__c = date.newInstance(year, 1, 5),
                                 Inv_Date__c = date.newInstance(year, 1, 5), Inv_DueDate__c = invDueDate,
                                 Inv_Status__c = 'Printed');
        insert invoice;
        System.assertEquals(invDueDate, [SELECT Inv_DueDate__c FROM Invoice__c WHERE Id = :invoice.Id LIMIT 1].Inv_DueDate__c);
    }
    
    static testmethod void setDueDate_Upd() {
        init();
        Date invDueDate = date.newInstance(year, 1, 15);
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        negoSettings.allowUpdatingInvoiceDateOnPrint = false;
        GlobalSettingsManager.saveGlobalSettings(negoSettings);
        // Create Invoice
        invoice = new Invoice__c(Inv_Supplier__c = supplier.Id, Inv_Business_Unit__c = country.Id, Sequence_Number__c = 8,
                                 Inv_FiscalYear__c = year, Status_BDate__c = date.newInstance(year, 1, 5),
                                 Inv_Date__c = date.newInstance(year, 1, 5), Inv_DueDate__c = invDueDate);
        insert invoice;
        invoice.Inv_Status__c = 'Printed';
        update invoice;
        System.assertEquals(invDueDate, [SELECT Inv_DueDate__c FROM Invoice__c WHERE Id = :invoice.Id LIMIT 1].Inv_DueDate__c);
    }
    
    // Set Invoice due Date after print.
    // New Inv Due Date = Today + (Old Inv Due Date - Old Inv Date).
    static testmethod void setDueDate_Ins_AllowDateUpdate() { 
        init();
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        negoSettings.allowUpdatingInvoiceDateOnPrint = true;
        GlobalSettingsManager.saveGlobalSettings(negoSettings);
        Date invDueDate = date.newInstance(year, 2, 15);
        Date invDate = date.newInstance(year, 1, 15);
        // Create Invoice
        invoice = new Invoice__c(Inv_Supplier__c = supplier.Id, Inv_Business_Unit__c = country.Id, Sequence_Number__c = 8,
                                 Inv_FiscalYear__c = year, Status_BDate__c = date.newInstance(year, 1, 5),
                                 Inv_DueDate__c = invDueDate, Inv_Date__c = invDate,
                                 Inv_Status__c = 'Printed');
        insert invoice;
        invoice = [SELECT Inv_DueDate__c FROM Invoice__c WHERE Id = :invoice.Id LIMIT 1];
        
        Integer diffOfDays = invDate.daysBetween(invDueDate);
        Date d = System.today().addDays(diffOfDays);
        System.assertEquals(d, invoice.Inv_DueDate__c);
    }
    
    // Set Invoice due Date after print.
    // New Inv Due Date = Today + (Old Inv Due Date - Old Inv Date).
    static testmethod void setDueDate_Upd_AllowDateUpdate() {
        init();
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        negoSettings.allowUpdatingInvoiceDateOnPrint = true;
        GlobalSettingsManager.saveGlobalSettings(negoSettings);
        Date invDueDate = date.newInstance(year, 2, 15);
        Date invDate = date.newInstance(year, 1, 15);
        // Create Invoice
        invoice = new Invoice__c(Inv_Supplier__c = supplier.Id, Inv_Business_Unit__c = country.Id, Sequence_Number__c = 8,
                                 Inv_FiscalYear__c = year, Status_BDate__c = date.newInstance(year, 1, 5),
                                 Inv_Date__c = invDate, Inv_DueDate__c = invDueDate);
        insert invoice;
        Integer diffOfDays = [SELECT Inv_Date__c FROM Invoice__c WHERE Id = :invoice.Id LIMIT 1].Inv_Date__c.daysBetween(invDueDate);
        invoice.Inv_Status__c = 'Printed';
        update invoice;
        Date d = System.today().addDays(diffOfDays);
        System.assertEquals(d, [SELECT Inv_DueDate__c FROM Invoice__c WHERE Id = :invoice.Id LIMIT 1].Inv_DueDate__c);
    }
    
    static testmethod void invoiceDates_case1() {
        init();
        Date invBeginDate = date.newInstance(year, 1, 1);
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = invBeginDate,
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        Integer month = Date.today().month() == 1 ? 12 : Date.today().month() - 1;
        year = Date.today().month() == 1 ? year - 1 : year;
        Date expectedDate = NegoptimHelper.getLastDayOfMonth(year, month);
        expectedDate = Date.today() > condition.Disc_EDate__c ? condition.Disc_EDate__c : expectedDate;
        
        /*if (!invoices.isEmpty() && invoices[0].inv_status__c == 'printed' && GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
            expectedDate = Date.today();
        }*/
        if (expectedDate > invBeginDate) {
            System.assertEquals(1, invoices.size());
            // since closingDay is yesterday (see init()) 
            System.assertEquals(Date.today() , invoices[0].inv_date__c);
        }
    }
    
    static testmethod void invoiceDates_case2() {
        init();
        Delete [SELECT Id FROM NegoptimCustomSettings__c]; // to come back to default value of Invoice_Max_Closing_Day__c = 31
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', first_invoice_date__c = Date.today() - 1, Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1);
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        Integer expected = Date.today() > condition.Disc_EDate__c ? 1 : 0;
        System.assertEquals(expected, [SELECT COUNT() FROM Invoice__c
                                       WHERE Inv_Contract__c = :contract.Id
                                       AND Inv_Business_Unit__c = :country.Id]);
        
    }
    
    static testmethod void invoiceDates_case3() {
        init();
        Delete [SELECT Id FROM NegoptimCustomSettings__c];
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', Invoice_period__c = 'Trimester',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c 
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        
        Integer currentMonth = Date.today().month();
        Integer month;
        if (Date.today() > condition.Disc_EDate__c) {
            month = condition.Disc_EDate__c.month();
        } else if(currentMonth >=1 && currentMonth <= 3) {
            System.assertEquals(0, invoices.size());
            return;
        } else if(currentMonth >= 4 && currentMonth <= 6) {
            month = 3;
        } else if(currentMonth >= 7 && currentMonth <= 9) {
            month = 6;
        } else {
            month = 9;
        }
        Date expectedDate = Date.today() > condition.Disc_EDate__c ? condition.Disc_EDate__c : NegoptimHelper.getLastDayOfMonth(year, month);
        if (invoices[0].inv_status__c == 'printed' && GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
            expectedDate = Date.today();
        }
        System.assertEquals(1, invoices.size());
        System.assertEquals(expectedDate, invoices[0].inv_date__c);
    }
    
    static testmethod void invoiceDates_case4() {
        init();
        Delete [SELECT Id FROM NegoptimCustomSettings__c];
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', Invoice_period__c = 'Semester',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        Integer currentMonth = Date.today().month();
        Integer month;
        if(Date.today() > condition.Disc_EDate__c) {
            month = condition.Disc_EDate__c.month();
        } else if (currentMonth >= 1 && currentMonth <= 6) {
            System.assertEquals(0, invoices.size());
            return;
        } else {
            month = 6;
        }
        
        Date expectedDate = Date.today() > condition.Disc_EDate__c ? condition.Disc_EDate__c : NegoptimHelper.getLastDayOfMonth(year, month);
        if (invoices[0].inv_status__c == 'printed' && GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
            expectedDate = Date.today();
        }
        System.assertEquals(1, invoices.size());
        System.assertEquals(expectedDate, invoices[0].inv_date__c);    
    }
    
    static testmethod void invoiceDates_case5() {
        init();
        Delete [SELECT Id FROM NegoptimCustomSettings__c];
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', Invoice_period__c = 'year',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c 
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        Integer currentMonth = Date.today().month();
        Integer month;
        if(Date.today() > condition.Disc_EDate__c) {
            
            month = condition.Disc_EDate__c.month();
            Date expectedDate = Date.today() > condition.Disc_EDate__c ? condition.Disc_EDate__c : NegoptimHelper.getLastDayOfMonth(year, month);
            if (invoices[0].inv_status__c == 'printed' && GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
                expectedDate = Date.today();
            }
            System.assertEquals(1, invoices.size());
            System.assertEquals(expectedDate, invoices[0].inv_date__c);
        } else {
            System.assertEquals(0, invoices.size());
            return;
        }
        
    }
    
    static testmethod void invoiceDates_case6() {
        init();
        Delete [SELECT Id FROM NegoptimCustomSettings__c];
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Forecasted', Invoice_period__c = 'month',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c 
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        Integer expectedCount = Date.today() > condition.Disc_EDate__c ? 1 : condition.Disc_EDate__c.month() - Date.today().month() + 2;
        System.assertEquals(expectedCount, invoices.size());
        Integer lastMonth = Date.today().month() == condition.Disc_BDate__c.month() ? Date.today().month() : Date.today().month() - 1;
        Date expectedDate = Date.today(); // NegoptimHelper.getLastDayOfMonth(year, month); 
        if (!invoices.isEmpty() && (invoices[0].inv_status__c != 'printed' || !GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint)) {
            expectedDate = NegoptimHelper.getLastDayOfMonth(year, lastMonth);
        }
        expectedDate = Date.today() > condition.Disc_EDate__c ? condition.Disc_EDate__c : expectedDate;
        for (Invoice__c inv : invoices) {
            System.assertEquals(expectedDate, inv.inv_date__c);
            if (invoices[0].inv_status__c != 'printed' || !GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
                lastMonth++;
                if (lastMonth != condition.Disc_EDate__c.month())
                    expectedDate = NegoptimHelper.getLastDayOfMonth(year, lastMonth);
                else
                    expectedDate = condition.Disc_EDate__c;
            }
        }
    }
    
    static testmethod void invoiceDates_case7() {
        init();
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Forecasted', Invoice_period__c = 'Trimester',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c 
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        Integer expectedCount;
        Integer expectedMonth;
        Integer currentMonth = Date.today().month();
        
        if (currentMonth >= 1 && currentMonth <= 5) {
            expectedCount = 4;
            expectedMonth = 3;
        } else if (currentMonth >= 6 && currentMonth <= 8) {
            expectedCount = 3;
            expectedMonth = 6;
        } else if (currentMonth >= 9 && currentMonth <= 11) {
            expectedCount = 2;
            expectedMonth = 9;
        } else if (currentMonth == 12) {
            expectedCount = 1;
        }
        expectedCount = Date.today() > condition.Disc_EDate__c ? expectedCount - 1 : expectedCount;
        System.assertEquals(expectedCount, invoices.size());
        Date expectedDate;
        for (Invoice__c inv : invoices) {
            if (invoices[0].inv_status__c == 'printed' && GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
                expectedDate = Date.today();
            } else {
                expectedDate = NegoptimHelper.getLastDayOfMonth(year, expectedMonth) > condition.Disc_EDate__c ? condition.Disc_EDate__c : NegoptimHelper.getLastDayOfMonth(year, expectedMonth);
                expectedMonth += 3;
            }
            expectedDate = expectedCount == 1 ? condition.Disc_EDate__c : expectedDate;
            System.assertEquals(expectedDate, inv.inv_date__c);
        }
    }
    
    static testmethod void invoiceDates_case8() {
        init();
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Forecasted', Invoice_period__c = 'Semester',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c 
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        Integer expectedCount;
        Integer expectedMonth; 
        Integer currentMonth = Date.today().month();
        if(currentMonth >= 1 && currentMonth <= 6) {
            expectedCount = 2;
            expectedMonth = 6;
        } else {
            expectedCount = 2;
            expectedMonth = 6;
        }
        expectedCount = Date.today() > condition.Disc_EDate__c ? expectedCount - 1 : expectedCount;
        System.assertEquals(expectedCount, invoices.size());
        Date expectedDate;
        for (Invoice__c inv : invoices) {
            if (invoices[0].inv_status__c == 'printed' && GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
                expectedDate = Date.today();
            } else {
                expectedDate = NegoptimHelper.getLastDayOfMonth(year, expectedMonth) > condition.Disc_EDate__c ? condition.Disc_EDate__c : NegoptimHelper.getLastDayOfMonth(year, expectedMonth);
                expectedMonth += 6;
            }
            expectedDate = expectedCount == 1 ? condition.Disc_EDate__c : expectedDate;
            System.assertEquals(expectedDate, inv.inv_date__c);
        }
    }
    
    static testmethod void invoiceDates_case9() {
        init();
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Forecasted', Invoice_period__c = 'Year',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c 
                                     FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        Date expectedDate = condition.Disc_EDate__c;
        if (invoices[0].inv_status__c == 'printed' && GlobalSettingsManager.loadGlobalSettings().allowUpdatingInvoiceDateOnPrint) {
            expectedDate = Date.today();
        }
        System.assertEquals(1, invoices.size());
        System.assertEquals(expectedDate, invoices[0].inv_date__c);
    }
    
    static testmethod void test_alreadyInvoicedAfterDelete() {
        init();
        test.startTest();
        Date conditionBeginDate = date.newInstance(year, 1, 1);
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = conditionBeginDate,
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        insert condition;
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        test.stopTest();
        if (Date.today().month() > conditionBeginDate.month()) {
            Decimal alreadyInvoiced = [SELECT Already_Invoiced__c FROM contract_Discount__c LIMIT 1].Already_Invoiced__c;
            delete [SELECT Id FROM Invoice__c];
            System.assert([SELECT Already_Invoiced__c FROM contract_Discount__c LIMIT 1].Already_Invoiced__c != alreadyInvoiced);
            System.assertEquals(0, [SELECT Already_Invoiced__c FROM contract_Discount__c LIMIT 1].Already_Invoiced__c);
        }
    }
    @istest(seeAllData = false)
    static void test_alreadyInvoicedAndEditedAfterDelete() {
        init();
        Date conditionBeginDate = date.newInstance(year, 1, 1);
        test.startTest();
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = conditionBeginDate,
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Actual (YTD)', Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1, Valid__c = true);
        insert condition;
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        test.stopTest();
        if (Date.today().month() > conditionBeginDate.month()) {
            Invoice__c inv = [SELECT Inv_Status__c FROM Invoice__c WHERE Inv_Contract__c = :contract.Id];
            inv.Inv_Status__c = 'Printed';
            update inv;
            Decimal alreadyInvoiced = [SELECT Already_Invoiced__c FROM contract_Discount__c WHERE Contract__c = :contract.Id].Already_Invoiced__c;
            delete [SELECT Id FROM Invoice__c];
            System.assertEquals(0, [SELECT Already_Invoiced_Edited__c FROM contract_Discount__c WHERE Contract__c = :contract.Id].Already_Invoiced_Edited__c);
        }
    }
    
    /**
     * @description condition.Valid__c = false => don't generate any invoice
	*/
    static testmethod void invalidCondition_case_normal() {
        init();
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                  Disc_EDate__c = date.newInstance(year, 11, 15), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Forecasted', Invoice_period__c = 'Month',
                                                                  Invoice_sequence__c = 1, Valid__c = false);
        insert condition;
        // Test
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        // Assertions
        System.assertEquals(0, [SELECT Count() FROM Invoice__c]);       
    }
    
    /**
     * @description startedFrom = ContractClosingBatch && condition.Valid__c = false => generate 1 invoice with value = -condition.Already_Invoiced__c
	*/
    static testmethod void invalidCondition_case_ContractClosingBatch() {
        init();
        Integer lastYear = year - 1;
        
        Contract__c contract1 = (Contract__c) TestDataFactory.createContractWithConditions(false, supplier, NS.Id, tariffCondition, 0)[0];
        contract1.Contract_BDate__c = Date.newInstance(lastYear, 1, 1);
        contract1.Contract_EDate__c = Date.newInstance(lastYear, 11, 15);
        insert contract1;
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract1, Date.newInstance(lastYear, 1, 1) , Date.newInstance(lastYear, 11, 15));
        condition.Valid__c = false;
        condition.Base_TO_Actual__c = 1200;
        condition.Value_per__c = 6; // YTD = 72
        condition.Invoice_base__c = 'Negotiated';
        condition.Invoice_period__c = 'Month';
        insert condition;
        condition.Already_Invoiced__c = 72;
        update condition;
        // Test
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('ContractBalancingBatch', country.Id, new List<Id>{contract1.Id}, null, Date.today()));
        Test.stopTest();
        // Get Data
        condition = [SELECT Already_Invoiced__c, Disc_EDate__c FROM Contract_Discount__c WHERE Id = :condition.Id];
        Invoice__c invoice = [SELECT Inv_value__c, Inv_Date__c FROM Invoice__c];
        // Assertions
        System.assertEquals(1, [SELECT Count() FROM Invoice__c]);
        System.assertEquals(-72, invoice.Inv_value__c);
        System.assertEquals(condition.Disc_EDate__c, invoice.Inv_Date__c);
        System.assertEquals(0, condition.Already_Invoiced__c);
        
        
    }
    
    static testmethod void invoiceDates_Trimester_case10() {
        init();
        // update Contract
        contract.Contract_BDate__c = date.newInstance(year, 3, 1);
        contract.Contract_EDate__c = date.newInstance(year, 12, 31);
        contract.Duration__c = 10;
        update contract;
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = contract.Contract_BDate__c, Disc_EDate__c = contract.Contract_EDate__c, Value_per__c = 2, Product_Scope__c = NS.Id,
                                                                  BU_Scope__c = country.Id, Contract__c = contract.Id, Base_TO_Actual__c = 1000, Value_amt__c = 1500,
                                                                  Invoice_base__c = 'Negotiated', Invoice_period__c = 'Trimester', Valid__c = true,
                                                                  Invoice_sequence__c = 1, first_Invoice_date__c = date.newInstance(year, 4, 30),
                                                                  Payment_Condition__c = 'End of Month', Payment_Days__c = '45');
        
        insert condition;
        Test.startTest();
        Database.executeBatch(new GenerateInvoicesBatch('GenerateInvoicesBatchTest', country.Id, new List<Id>{contract.Id}, null, Date.today()));
        Test.stopTest();
        List<Invoice__c> invoices = [SELECT Id, inv_date__c, inv_status__c  FROM Invoice__c
                                     WHERE Inv_Contract__c = :contract.Id AND Inv_Business_Unit__c = :country.Id];
        System.assertEquals(3, invoices.size());
    }
}