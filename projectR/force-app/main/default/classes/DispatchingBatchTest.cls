/*
 * This class contains unit test methods to validate the Dispatching procedure.
 */
@isTest(SeeAllData=false)
private class DispatchingBatchTest {
    
    private static final Integer COUNTER = 100;
    private static final Integer STORE_NUMBER = 100;
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Supplier_PG_Mapping__c PG;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static String plv;
    private static List<Supplier_PG_Mapping__c> PGs;
    private static List<Purchases_Flow_PG__c> purchases;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root element Id.
            rootId = NegoptimHelper.getRootId();
            // Get the corporate currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
            // Create Legal Form.
            legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
            legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
            insert legal;
            // Create department.
            department = new Orga_HE__c(Name = 'DEPARTMENT', Elt_Code__c = 'DEPARTMENT', Parent_Element__c = rootId, Level__c = 1,
                                        Status_BDate__c = date.newInstance(year, 1, 1), Purchases_DB_Upper_Starting_Point__c = true,
                                        Dispatch_Inv_Hierarchy_Starting_Point__c = false);
            insert department;
            // Create section.
            section = new Orga_HE__c(Name = 'SECTION', Elt_Code__c = 'SECTION', Parent_Element__c = department.Id, Level__c = 2,
                                     Status_BDate__c = date.newInstance(year, 1, 1), Purchases_DB_Upper_Starting_Point__c = false,
                                     Dispatch_Inv_Hierarchy_Starting_Point__c = true);
            insert section;
            // Create policy-tariff condition.
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1),
                                                       Condition_Code__c = 'C1', Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ',
                                                       Name_Fi__c = 'Fi ', Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
            insert tariffCondition;
            // Create list of PGs.
            PGs = new List<Supplier_PG_Mapping__c>();
            // Create list of purchases.
            purchases = new List<Purchases_Flow_PG__c>();
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // Single dispatching.
    static testmethod void dispatch() {
        init();
        // Create Store
        store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert store;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                       Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                       Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create PGs.
        for(Integer i = 1; i <= 2; i++) {
            Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG' + i, Supplier__c = supplier.Id, Department__c = department.Id, Section__c = section.Id,
                                                                   SNA_Code__c = '100' + i, GIMA_Code__c = '100' + i, CurrencyIsoCode = currencyIsoCode);
            PGs.add(PG);
        }
        insert PGs;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Contract_Numbder__c = 'C001', Supplier__c = supplier.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                   Supplier_Nego_Scope__c = NS.Id, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Value_amt__c = 12, Value_per__c = 2.5);
        insert condition;
        // Create purchases on store.
        for (Integer i = 0 ; i < 2 ; i++) {
            Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(i).Id, Supplier_Nego_Scope__c = NS.Id,
                                                                     Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id, BU__c = store.Id, Year__c = year,
                                                                     TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                     TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
            purchases.add(purchase);
        }
        insert purchases;
        // Start test.
        Test.startTest();
        Database.executeBatch(new DispatchingBatch('UNIT TEST', country.Id, new List<Id>{contract.Id}, new List<Id>{condition.Id}, Date.newInstance(year, 1, 25)));
        Test.stopTest();
        // Assertions.
        // Get count of the dispatch head.
        Integer countDispatchHead = [SELECT COUNT() FROM Inv_BUDispatch__c];
        List<AggregateResult> ar = [SELECT SUM(Base_TO_Dispatch__c) Total FROM Inv_BUDispatch_Details__c];
        Decimal sumDispatchDetails = (Decimal) ar[0].get('Total');
        // One head for each store.
        System.assertEquals(1, countDispatchHead);
        // Total dispatch details TO.
        System.assertEquals(2400.0, sumDispatchDetails);
    }
    
    // Mass dispatching.
    static testmethod void massDispatch() {
        init();
        // Start test.
        Test.startTest();
        // Create suppliers.
        List<Sup_Supplier__c> suppliers = new List<Sup_Supplier__c>();
        for (Integer i=1 ; i <= COUNTER ; i++) {
            Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'SUPPLIER' + i, Code__c = 'SUPPLIER' + i, Status__c = 'Active', Country_origin__c = country.Id,
                                                           Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            suppliers.add(supplier);
        }
        insert suppliers;
        List<Id> supplierIds = new List<Id>();
        for (Sup_Supplier__c sup : suppliers) {
            supplierIds.add(sup.Id);
        }
        // Get the default negoscope created on supplier creation.
        List<Sup_sup_NegoScope__c> NSs = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c IN : supplierIds];
        // Create PGs.
        for(Integer i = 1; i <= STORE_NUMBER; i++) {
            Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG' + i, Supplier__c = suppliers.get(i-1).Id, Department__c = department.Id, Section__c = section.Id,
                                                                   SNA_Code__c = '100' + i, GIMA_Code__c = '100' + i, CurrencyIsoCode = currencyIsoCode);
            PGs.add(PG);
        }
        insert PGs;
        // Create store BUs.
        List<Orga_BU__c> stores = new List<Orga_BU__c>();
        String rtId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        for (Integer i = 1 ; i <= STORE_NUMBER ; i++) {
            store = new Orga_BU__c(Name = 'STORE' + i, BU_Code__c = 'STORE' + i, CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id,
                                   BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store.RecordTypeId = rtId;
            stores.add(store);
        }
        insert stores;
        // Create contract for each supplier.
        List<Contract__c> contracts = new List<Contract__c>();
        for (Integer i = 1 ; i <= COUNTER ; i++) {
            Contract__c contract = new Contract__c(Name = suppliers.get(i-1).Name + ' - Contract ' + i + ' ' + year, Contract_Numbder__c = 'C00' + i, Supplier__c = suppliers.get(i-1).Id,
                                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                                   Supplier_Nego_Scope__c = NSs.get(i-1).Id, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
            contracts.add(contract);
        }
        insert contracts;
        List<Id> contractIds = new List<Id>();
        for (Contract__c c : contracts) {
            contractIds.add(c.Id);
        }
        // Create condition for each contract.
        List<Contract_Discount__c> conditions = new List<Contract_Discount__c>();
        for (Integer i = 1 ; i <= COUNTER ; i++) {
            Contract_Discount__c condition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                       Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                       Contract__c = contracts.get(i-1).Id, Product_Scope__c = NSs.get(i-1).Id, BU_Scope__c = country.Id,
                                                                       Value_per__c = 2.5, Value_amt__c = 12 + i * 0.1);
            Contract_Discount__c condition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                                       Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2.5, Product_Scope__c = NSs.get(i-1).Id,
                                                                       BU_Scope__c = country.Id, Contract__c = contracts.get(i-1).Id, Value_amt__c = 12 + i * 0.1);
            conditions.add(condition1);
            //conditions.add(condition2);
        }
        insert conditions;
        List<Id> condIds = new List<Id>();
        for (Contract_Discount__c cond : conditions) {
            condIds.add(cond.Id);
        }
        // Create purchase for each contract.
        for (Integer i = 1 ; i <= STORE_NUMBER ; i++) {
            Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = suppliers.get(i-1).Id, PG__c = PGs.get(i-1).Id, Supplier_Nego_Scope__c = NSs.get(i-1).Id,
                                                                     Department__c = department.Id, Section__c = section.Id, Contrat1__c = contracts.get(i-1).Id, BU__c = stores.get(i-1).Id, Year__c = year,
                                                                     TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                     TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
            purchases.add(purchase);
        }
        insert purchases;
        Database.executeBatch(new DispatchingBatch('UNIT TEST', country.Id, contractIds, condIds, Date.newInstance(year, 1, 25)), 150);
        Test.stopTest();
        // Assertion.
        // Get count of the dispatch head.
        Integer countDispatchHead = [SELECT COUNT() FROM Inv_BUDispatch__c];
        List<AggregateResult> ar = [SELECT SUM(Base_TO_Dispatch__c) Total FROM Inv_BUDispatch_Details__c];
        Decimal sumDispatchDetails = (Decimal) ar[0].get('Total');
        // One head for each store.
        System.assertEquals(STORE_NUMBER, countDispatchHead);
        // Total dispatch details TO.
        System.assertEquals(STORE_NUMBER * 1200.0, sumDispatchDetails);
        // Number of dispatch detail.
        Integer countDispatchDetail = [SELECT COUNT() FROM Inv_BUDispatch_Details__c];
        System.assertEquals(STORE_NUMBER, countDispatchDetail);
    }
    
    // Single update dispatch detail.
    static testmethod void updateDispatchDetail() {
        init();
        // Create Store
        store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert store;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                       Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                       Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create PGs.
        for(Integer i = 1; i <= 2; i++) {
            Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG' + i, Supplier__c = supplier.Id, Department__c = department.Id, Section__c = section.Id,
                                                                   SNA_Code__c = '100' + i, GIMA_Code__c = '100' + i, CurrencyIsoCode = currencyIsoCode);
            PGs.add(PG);
        }
        insert PGs;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Contract_Numbder__c = 'C001', Supplier__c = supplier.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                   Supplier_Nego_Scope__c = NS.Id, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Value_amt__c = 12, Value_per__c = 2.5);
        insert condition;
        // Create purchases on store.
        for (Integer i = 0 ; i < 2 ; i++) {
            Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(i).Id, Supplier_Nego_Scope__c = NS.Id,
                                                                     Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id, BU__c = store.Id, Year__c = year,
                                                                     TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                     TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
            purchases.add(purchase);
        }
        insert purchases;
        // Start test.
        Test.startTest();
        Database.executeBatch(new DispatchingBatch('UNIT TEST', country.Id, new List<Id>{contract.Id}, new List<Id>{condition.Id}, Date.newInstance(year, 1, 25)));
        Test.stopTest();
        // Assertion.
        Inv_BUDispatch_Details__c detail = [SELECT Id FROM Inv_BUDispatch_Details__c LIMIT 1];
        detail.Status__c = 'Sent to Accounting';
        update detail;
        Date dispatchDate = Date.today();
        Integer sequence = dispatchDate.month() == 1 ? 12 : dispatchDate.month() - 1;
        String fieldName = 'Value_Dispatch_M' + sequence + '__c';
        Decimal d = (Decimal)detail.get(fieldName);
        System.assertEquals(d , detail.New_Dispatch_Value__c);
    }
    
    static testmethod void fixMonthlyDispatch_test() {
        init();
        // Create Store
        store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert store;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                       Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                       Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create PGs.
        for(Integer i = 1; i <= 2; i++) {
            Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG' + i, Supplier__c = supplier.Id, Department__c = department.Id, Section__c = section.Id,
                                                                   SNA_Code__c = '100' + i, GIMA_Code__c = '100' + i, CurrencyIsoCode = currencyIsoCode);
            PGs.add(PG);
        }
        insert PGs;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Contract_Numbder__c = 'C001', Supplier__c = supplier.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                   Supplier_Nego_Scope__c = NS.Id, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Value_amt__c = 12, Value_per__c = 2.5);
        insert condition;
        // Create purchases on store.
        for (Integer i = 0 ; i < 2 ; i++) {
            Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(i).Id, Supplier_Nego_Scope__c = NS.Id,
                                                                     Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id, BU__c = store.Id, Year__c = year,
                                                                     TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                     TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
            purchases.add(purchase);
        }
        insert purchases;
        
        Date dispatchDate = Date.today();
        Integer sequence = dispatchDate.month() == 1 ? 12 : dispatchDate.month() - 1;
        Invoice__c invoice = new Invoice__c(Inv_Business_Unit__c = store.Id, Acc_Document_Type__c = 'Invoice',
                                            Inv_Contract__c = contract.Id, Inv_Date__c = System.Today(),
                                            Inv_DueDate__c = System.Today().addMonths(2), Inv_FiscalYear__c = System.Today().year(),
                                            Invoice_Number__c = 'inv-001', Inv_Status__c = 'Printed',
                                            Inv_Supplier__c = supplier.Id, Sequence_Date__c = 'Month',
                                            Sequence_Number__c = sequence, origin__c = 'Group',
                                            Status_BDate__c = System.Today(), Inv_PrintedDate__c = System.Today().addDays(-1));
        insert invoice;
        Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Invoice__c = invoice.Id, Discount__c = condition.Id, Inv_Detail_Comment__c = 'comment--1',
                                                                 Inv_Detail_Condition__c = tariffCondition.Id);
        insert invoiceDetail;
        // Start test.
        Test.startTest();
        Database.executeBatch(new DispatchingBatch('UNIT TEST', country.Id, new List<Id>{contract.Id}, new List<Id>{condition.Id}, dispatchDate));
        Test.stopTest();
        // Assertion.
        Inv_BUDispatch_Details__c detail = [SELECT Id, Sequence__c FROM Inv_BUDispatch_Details__c LIMIT 1];
        detail.Status__c = 'Validated';
        detail.Sequence__c = detail.Sequence__c + 1;
        update detail;
        String fieldName = 'Value_Dispatch_M' + sequence + '__c';
        Decimal d = (Decimal)detail.get(fieldName);
        System.assertEquals(d , detail.New_Dispatch_Value__c);
        String fieldName2 = 'Invoice_Ref_M' + sequence + '__c';
        detail = [SELECT Invoice_Ref_M1__c, Invoice_Ref_M2__c, Invoice_Ref_M3__c, Invoice_Ref_M4__c, Invoice_Ref_M5__c, Invoice_Ref_M6__c,
                  Invoice_Ref_M7__c, Invoice_Ref_M8__c, Invoice_Ref_M9__c, Invoice_Ref_M10__c, Invoice_Ref_M11__c, Invoice_Ref_M12__c
                  FROM Inv_BUDispatch_Details__c LIMIT 1];
        Id detailId = (Id)detail.get(fieldName2);
        System.assertEquals(invoiceDetail.Id , detailId);
    }
    
    static testmethod void case_dispatchAggregateMode() {
        init();
        // Create Store
        store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert store;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                       Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                       Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create PG
        Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG1', Supplier__c = supplier.Id, Department__c = department.Id, Section__c = section.Id,
                                                               SNA_Code__c = '1001', GIMA_Code__c = '1001', CurrencyIsoCode = currencyIsoCode);
        insert PG;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Contract_Numbder__c = 'C001', Supplier__c = supplier.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                   Supplier_Nego_Scope__c = NS.Id, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
        // Create condition.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Value_amt__c = 12, Value_per__c = 2.5);
        insert condition;
        // Create purchases on store.
        for (Integer i = 0 ; i < 2 ; i++) {
            Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PG.Id, Supplier_Nego_Scope__c = NS.Id,
                                                                     Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id, BU__c = store.Id, Year__c = year,
                                                                     TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                     TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
            purchases.add(purchase);
        }
        insert purchases;
        // Start test.
        Test.startTest();
        Database.executeBatch(new DispatchingBatch('UNIT TEST', country.Id, new List<Id>{contract.Id}, new List<Id>{condition.Id}, Date.newInstance(year, 1, 25)));
        Test.stopTest();
        // Get count of the dispatch head
        Integer countDispatchHead = [SELECT COUNT() FROM Inv_BUDispatch__c];
        // Get count of the dispatch details
        List<Inv_BUDispatch_Details__c> dispatchDetails = [SELECT Purchases_Flow_PG__c FROM Inv_BUDispatch_Details__c];
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        // Assertions.
        // One head for each store
            System.assertEquals(1, countDispatchHead);
        if (negoSettings.dispatchAggregateMode) {
            // 1 dispatch detail per purchase
            System.assertEquals(1, dispatchDetails.size());
            // 
            System.assert(dispatchDetails[0].Purchases_Flow_PG__c == null);
        } else {
            // 1 dispatch detail per purchase
            System.assertEquals(2, dispatchDetails.size());
            System.assert(dispatchDetails[0].Purchases_Flow_PG__c != null
                          && dispatchDetails[1].Purchases_Flow_PG__c != null
                          && dispatchDetails[0].Purchases_Flow_PG__c != dispatchDetails[1].Purchases_Flow_PG__c);
        }
    }
}