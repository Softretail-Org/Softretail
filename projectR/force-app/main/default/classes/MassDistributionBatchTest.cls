@isTest
private class MassDistributionBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Orga_BU__c store2;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Orga_HE__c section2;
    private static Orga_HE__c section3;
    private static Contract__c contract;
    private static Contract__c contract2;
    private static Pol_Com_Condition__c tariffCondition;
    private static String plv;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Sup_sup_NegoScope__c NS2;
    private static List<Supplier_PG_Mapping__c> PGs;
    private static Supplier_PG_Mapping__c PG;
    private static Supplier_PG_Mapping__c PG2;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id.
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency.
            //currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            currencyIsoCode = 'EUR';
            // Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
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
            Id storeRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
            // Create Store
            store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store.RecordTypeId = storeRecordTypeId;
            store2 = new Orga_BU__c(Name = 'Store 2', BU_Code__c = 'STR2', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store2.RecordTypeId = storeRecordTypeId;
            insert new List<Orga_BU__c>{store, store2};
                // Create supplier.
                supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                               Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            NS = [SELECT Id, NS_Code__c FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            NS2 = new Sup_sup_NegoScope__c(Name = 'Default NegoScope - Nestle 2', Supplier__c = supplier.Id,
                                           Is_All_Brands__c = True, Incl_NewBrand__c = True, Is_All__c = True,
                                           Is_All_HE__c = True, Is_All_BU__c = True, Incl_NewBU__c = True);
            insert NS2;
            NS2 = [SELECT Id, NS_Code__c FROM Sup_sup_NegoScope__c WHERE Id = :NS2.Id LIMIT 1];
            // Create Department.
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = '1', Parent_Element__c = rootId, Level__c = 1,
                                        Status_BDate__c = date.newInstance(year, 1, 1), Status__c = 'Active',
                                        Nego_Type__c = 'Ferme', Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            insert department;
            // Create Section.
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = '1011', Parent_Element__c = department.Id, Level__c = 2,
                                     Status_BDate__c = date.newInstance(year, 1, 1),
                                     Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
            insert section;
            // Create PG.
            PG = new Supplier_PG_Mapping__c(Name = 'PG 00', SNA_Code__c = '100', GIMA_Code__c = '100',
                                            Department__c = department.Id, Section__c = section.Id,
                                            Supplier__c = supplier.Id, Nego_Scope__c = NS.Id);
            
            PG2 = new Supplier_PG_Mapping__c(Name = 'PG 02', SNA_Code__c = '200', GIMA_Code__c = '200',
                                             Department__c = department.Id, Section__c = section.Id,
                                             Supplier__c = supplier.Id, Nego_Scope__c = NS.Id);
            insert new List<Supplier_PG_Mapping__c> {PG, PG2};
                
                // Create Contract.
                contract = new Contract__c(Name ='Test Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
                                           Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                           Contract_Type__c = 'Contract', Status__c = 'Signed', D_N__c = 'N');
            // Create Contract.
            contract2 = new Contract__c(Name ='Test Contract2', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS2.Id, Contract_Numbder__c = 'C112',
                                        Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12, Contract_BU__c = country.Id,
                                        Contract_Type__c = 'Contract', Status__c = 'Signed', D_N__c = 'N');
            List<Contract__c> contracts = new List<Contract__c>();
            contracts.add(contract);
            contracts.add(contract2);
            insert contracts;
            // Create Policy - Tariff Conditions.
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = 'Progressive Rebates', Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ', VAT_Type__c = 'Rebate');
            insert tariffCondition;
        } catch (Exception ex) { }
    }
    /* Yearly */
    // If line as a type new & condition doen't exist for scope (type non prenego)
    // => Create a new non prenego condition, upload line in the distribute part of this new condition
    // Succes
    @isTest static void case6_happyScenario() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    // Failed: Amount value is different of sum of month's values.
    @isTest static void case6_happyScenario_amount() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',14000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(0, dispatchHeadCount);
        System.assertEquals(0, dispatchDetailsCount);
        System.assertEquals(0, conditionCount);
    }
    // Success: Check Fix Amounts, PG, section and comment on inserted dispatch details.
    @isTest static void case6_happyScenario_DD() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',78000,New,case6,1000,2000,3000,4000,5000,6000,7000,8000,9000,10000,11000,12000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get Data.
        Inv_BUDispatch_Details__c dd = [SELECT Fix_Amount_Dispatch_M1__c, Fix_Amount_Dispatch_M2__c, Fix_Amount_Dispatch_M3__c,
                                        Fix_Amount_Dispatch_M4__c, Fix_Amount_Dispatch_M5__c, Fix_Amount_Dispatch_M6__c,
                                        Fix_Amount_Dispatch_M7__c, Fix_Amount_Dispatch_M8__c, Fix_Amount_Dispatch_M9__c,
                                        Fix_Amount_Dispatch_M10__c, Fix_Amount_Dispatch_M11__c, Fix_Amount_Dispatch_M12__c,
                                        PG__c, Hierarchy_level_dispatch__c, Discount__c, Comment__c
                                        FROM Inv_BUDispatch_Details__c];
        // Assertion.
        System.assertEquals(1000, dd.Fix_Amount_Dispatch_M1__c);
        System.assertEquals(2000, dd.Fix_Amount_Dispatch_M2__c);
        System.assertEquals(3000, dd.Fix_Amount_Dispatch_M3__c);
        System.assertEquals(4000, dd.Fix_Amount_Dispatch_M4__c);
        System.assertEquals(5000, dd.Fix_Amount_Dispatch_M5__c);
        System.assertEquals(6000, dd.Fix_Amount_Dispatch_M6__c);
        System.assertEquals(7000, dd.Fix_Amount_Dispatch_M7__c);
        System.assertEquals(8000, dd.Fix_Amount_Dispatch_M8__c);
        System.assertEquals(9000, dd.Fix_Amount_Dispatch_M9__c);
        System.assertEquals(10000, dd.Fix_Amount_Dispatch_M10__c);
        System.assertEquals(11000, dd.Fix_Amount_Dispatch_M11__c);
        System.assertEquals(12000, dd.Fix_Amount_Dispatch_M12__c);
        System.assertEquals(PG.Id, dd.PG__c);
        System.assertEquals(section.Id, dd.Hierarchy_level_dispatch__c);
        System.assertEquals('case6', dd.Comment__c);
    }
    // Success: Check Amount, Reference condition and condition type on inserted condition.
    @isTest static void case6_happyScenario_Condition() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Contract_Discount__c condition = [SELECT Value_amt__c, Reference_condition__c, Condition_Type__c FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(12000, condition.Value_amt__c);
        System.assertEquals(Null, condition.Reference_condition__c);
        System.assertEquals(tariffCondition.Id, condition.Condition_Type__c);
    }
    // Success: Check Invoice Business Unit on inserted dispatch head.
    @isTest static void case6_happyScenario_DH() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Inv_BUDispatch__c dh = [SELECT Inv_BU__c FROM Inv_BUDispatch__c];
        // Assertion.
        System.assertEquals(store.Id, dh.Inv_BU__c);
    }
    // Case 6 - Two lines - different stores.
    @isTest static void case6_store() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store2.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(2, dispatchHeadCount);
        System.assertEquals(2, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    // Case 6 - Two lines - different NS.
    @isTest static void case6_NS() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS2.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer c1 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract.Id];
        Integer c2 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract2.Id];
        // Assertion.
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(2, dispatchDetailsCount);
        System.assertEquals(1, c1);
        System.assertEquals(1, c2);
    }
    // Case 6 - Two lines - different NS, store.
    @isTest static void case6_NS_Store() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS2.NS_Code__c + ',' + store2.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        List<Inv_BUDispatch__c> DHs = [SELECT Id FROM Inv_BUDispatch__c];
        Integer d1 = [SELECT count() FROM Inv_BUDispatch_Details__c WHERE Inv_DispatchHead__c = :DHs.get(0).Id];
        Integer d2 = [SELECT count() FROM Inv_BUDispatch_Details__c WHERE Inv_DispatchHead__c = :DHs.get(1).Id];
        Integer c1 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract.Id];
        Integer c2 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract2.Id];
        // Assertion.
        System.assertEquals(2, DHs.size());
        System.assertEquals(1, d1);
        System.assertEquals(1, d2);
        System.assertEquals(1, c1);
        System.assertEquals(1, c2);
    }
    // If line has a type prenego & condition doesn't exist for scope (type prenego)
    // => Reject the line.
    // Case 2 - .
    @isTest static void case2() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,Prenego,case2,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(0, dispatchHeadCount);
        System.assertEquals(0, dispatchDetailsCount);
        System.assertEquals(0, conditionCount);
    }
    
    @isTest static void case5() {
        init();
        // Create conditions.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case5,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    
    // If line as a type prenego & condition exist for scope (type non prenego)
    // => Create new condition in which Is_Prenego_Envelop__c is True.
    @isTest static void case4() {
        init();
        // Create conditions.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);        
        insert condition;
        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,Prenego,case4,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(0, dispatchHeadCount);
        System.assertEquals(0, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    // Case 4 - check Is_Prenego_Envelop__c on created condition.
    /*@isTest static void case4_isPrenego() {
        init();
        // Create conditions.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);        
        insert condition;
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,Prenego,case4,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Contract_Discount__c newCondition = [SELECT Is_Prenego_Envelop__c FROM Contract_Discount__c WHERE Id != :condition.Id];
        // Assertion.
        System.assertEquals(True, newCondition.Is_Prenego_Envelop__c);
    }*/
    
    /* Monthly */
    @isTest static void case6_happyScenario_monthly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    // Success: Check Invoice Business Unit on inserted dispatch head.
    @isTest static void case6_happyScenario_DH_monthly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Inv_BUDispatch__c dh = [SELECT Inv_BU__c FROM Inv_BUDispatch__c];
        // Assertion.
        System.assertEquals(store.Id, dh.Inv_BU__c);
    }
    // Case 6 - Two lines - different stores.
    @isTest static void case6_store_monthly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store2.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(2, dispatchHeadCount);
        System.assertEquals(2, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    // Case 6 - Two lines - different NS.
    @isTest static void case6_NS_monthly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS2.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer c1 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract.Id];
        Integer c2 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract2.Id];
        // Assertion.
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(2, dispatchDetailsCount);
        System.assertEquals(1, c1);
        System.assertEquals(1, c2);
    }
    // Case 6 - Two lines - different NS, store.
    @isTest static void case6_NS_Store_monthly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS2.NS_Code__c + ',' + store2.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case6\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        List<Inv_BUDispatch__c> DHs = [SELECT Id FROM Inv_BUDispatch__c];
        Integer d1 = [SELECT count() FROM Inv_BUDispatch_Details__c WHERE Inv_DispatchHead__c = :DHs.get(0).Id];
        Integer d2 = [SELECT count() FROM Inv_BUDispatch_Details__c WHERE Inv_DispatchHead__c = :DHs.get(1).Id];
        Integer c1 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract.Id];
        Integer c2 = [SELECT count() FROM Contract_Discount__c WHERE Contract__c = :contract2.Id];
        // Assertion.
        System.assertEquals(2, DHs.size());
        System.assertEquals(1, d1);
        System.assertEquals(1, d2);
        System.assertEquals(1, c1);
        System.assertEquals(1, c2);
    }
    // If line has a type prenego & condition doesn't exist for scope (type prenego)
    // => Reject the line.
    // Case 2 - .
    @isTest static void case2_monthly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,Prenego,case2\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(0, dispatchHeadCount);
        System.assertEquals(0, dispatchDetailsCount);
        System.assertEquals(0, conditionCount);
    }
    
    
    @isTest static void case5_monthly() {
        init();
        // Create conditions.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,New,case5\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    
    // If line as a type prenego & condition exist for scope (type non prenego)
    // => Create new condition in which Is_Prenego_Envelop__c is True.
    @isTest static void case4_monthly() {
        init();
        // Create conditions.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);        
        insert condition;
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,Prenego,case4\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(0, dispatchHeadCount);
        System.assertEquals(0, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    // Case 4 - check Is_Prenego_Envelop__c on created condition.
    /*@isTest static void case4_isPrenego_monthly() {
        init();
        // Create conditions.
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);        
        insert condition;
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,Prenego,case4\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Contract_Discount__c newCondition = [SELECT Is_Prenego_Envelop__c FROM Contract_Discount__c WHERE Id != :condition.Id];
        // Assertion.
        System.assertEquals(True, newCondition.Is_Prenego_Envelop__c);
    }*/
            
    //case 7: if column number in csv file is 9 and isYearlyDistribution --> add 12 columns for each month of the year
    @isTest static void case7_yearly_new_9columns(){
        init();
        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',0,new,case7\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvBlob,true));
        Test.stopTest();
        
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        //Assertion
        System.assertEquals(1, conditionCount);
    }
    
    //case 8: if 2 rows in the csv file refer to the same condition and isYearlyDistribution --> sum months
    @isTest static void case8() {
        init();
        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,new,case8a,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,new,case8b,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvBlob,true));
        Test.stopTest();
        //Get data
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        
        Contract_Discount__c cd = [SELECT Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c,
                                   Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c,
                                   Value_amt_disp_M11__c, Value_amt_disp_M12__c
                                   FROM Contract_Discount__c
                                   LIMIT 1];
        
        decimal[] months = new decimal[]{0,0,0,0,0,0,0,0,0,0,0,0};
            months[0] = cd.Value_amt_disp_M1__c;
        months[1] = cd.Value_amt_disp_M2__c;
        months[2] = cd.Value_amt_disp_M3__c;
        months[3] = cd.Value_amt_disp_M4__c;
        
        months[4] = cd.Value_amt_disp_M5__c;
        months[5] = cd.Value_amt_disp_M6__c;
        months[6] = cd.Value_amt_disp_M7__c;
        months[7] = cd.Value_amt_disp_M8__c;
        
        months[8] = cd.Value_amt_disp_M9__c;
        months[9] = cd.Value_amt_disp_M10__c;
        months[10] = cd.Value_amt_disp_M11__c;
        months[11] = cd.Value_amt_disp_M12__c;
        
        //Assertion
        System.assertEquals(1, conditionCount);
        for(integer index =0; index<12;index++){
            System.assertEquals(2000, months[index]);
        }
    }
    
    //adding a monthly distribution to and existing contidion with current month value equal to 0
    @isTest static void case9_currentMonth_0(){
        
        init();
        
        Integer fiscalYear = System.today().year();
        Integer sequence = System.today().month();
        
        // Create prenego condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = True);
        insert condition;
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = fiscalYear,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        // Create dispatch
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c=dispatchHead.Id,
                                                                                      Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id,
                                                                                      Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                      PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'New');
        insert dispatchDetailsLine; 
        
        String monthlyContentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        monthlyContentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',1000,prenego,case9\r\n';
        Blob csvMonthlyBlob = Blob.valueOf(monthlyContentData);        
        
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvMonthlyBlob,false));
        Test.stopTest();
        
        //Get data
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        
        String field = 'Fix_Amount_Dispatch_M' + sequence + '__c';
        Inv_BUDispatch_Details__c dd = Database.query ('SELECT '+field +' FROM Inv_BUDispatch_Details__c LIMIT 1');
        
        decimal month = (decimal) dd.get(field);
        //Assertion
        System.assertEquals(1, conditionCount);
        System.assertEquals(1,dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        System.assertEquals(1000, month);
        
    }
    
    //adding a monthly distribution to and existing contidion with current month value not equal to 0 and not null
    @isTest static void case9_currentMonth_not0(){
        
        init();
        
        Integer fiscalYear = System.today().year();
        Integer sequence = System.today().month();
        
        String field = 'Value_amt_disp_M' + sequence + '__c';
        
        // Create prenego condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = True);
        insert condition;
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = fiscalYear,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        // Create dispatch
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c=dispatchHead.Id,
                                                                                      Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id,
                                                                                      Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                      PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'New');
        
        insert dispatchDetailsLine;
        String monthlyContentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        monthlyContentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',1000,prenego,case9\r\n';
        Blob csvMonthlyBlob = Blob.valueOf(monthlyContentData);        
        
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvMonthlyBlob,false));
        Test.stopTest();
        
        //Get data
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        
        
        //Assertion
        System.assertEquals(1, conditionCount);
        System.assertEquals(1,dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        
        
    }
    
    //case 10: merge if same scope
    //import monthly distribution type 'new' on scope 'new'
    @isTest static void case10_monthly_new() {
        init();
        Integer sequence = System.today().month();
        
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        // Create prenego condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = false);
        insert condition;
        // Create dispatch detail
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c=dispatchHead.Id,
                                                                                      Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id,
                                                                                      Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                      PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'New');
        Integer month = sequence == 12 ? 11 : sequence + 1;
        dispatchDetailsLine.put('Fix_Amount_Dispatch_M' + month + '__c', 800);
        insert dispatchDetailsLine;
        
        String monthlyContentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        monthlyContentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',1000,new,case9\r\n';
        Blob csvMonthlyBlob = Blob.valueOf(monthlyContentData);
        
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvMonthlyBlob,false));
        Test.stopTest();
        //Get data
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion		
        System.assertEquals(1800, [SELECT Value_amt__c FROM Contract_Discount__c WHERE Id = :condition.Id].Value_amt__c);
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    //import monthly distribution type 'prenego' on scope 'prenego'
    @isTest static void case10_monthly_prenego() {
        init();
        Integer sequence = System.today().month();
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        
        // Create prenego condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = True);
        insert condition;
        
        // Create dispatch detail
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c=dispatchHead.Id,
                                                                                      Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id,
                                                                                      Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                      PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'New');
        Integer month = sequence == 12 ? 11 : sequence + 1;
        dispatchDetailsLine.put('Fix_Amount_Dispatch_M' + month + '__c', 800);
        insert dispatchDetailsLine;
        
        String monthlyContentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        monthlyContentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',1000,prenego,case9\r\n';
        Blob csvMonthlyBlob = Blob.valueOf(monthlyContentData);
        
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvMonthlyBlob,false));
        Test.stopTest();
        //Get data
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion
        System.assertEquals(1800, [SELECT Value_amt__c FROM Contract_Discount__c WHERE Id = :condition.Id].Value_amt__c);
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(1, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
    }
    //import yearly distribution of type 'prenego' on existing scope of type 'new' --> reject new line
    @isTest static void case10_yearly_new_on_prenego() {
        init();
        
        // Integer fiscalYear = System.today().year();
        Integer sequence = System.today().month();
        
        String field = 'Fix_Amount_Dispatch_M' + sequence + '__c';
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        
        // Create prenego condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = True);
        condition.Value_amt_disp_M1__c = 1000;
        condition.Value_amt_disp_M2__c = 1000;
        condition.Value_amt_disp_M3__c = 1000;
        condition.Value_amt_disp_M4__c = 1000;
        condition.Value_amt_disp_M5__c = 1000;
        condition.Value_amt_disp_M6__c = 1000;
        condition.Value_amt_disp_M7__c = 1000;
        condition.Value_amt_disp_M8__c = 1000;
        condition.Value_amt_disp_M9__c = 1000;
        condition.Value_amt_disp_M10__c = 1000;
        condition.Value_amt_disp_M11__c = 1000;
        condition.Value_amt_disp_M12__c = 1000;
        
        insert condition;
        
        // Create dispatch detail
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c=dispatchHead.Id,
                                                                                      Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id,
                                                                                      Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                      PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'New',
                                                                                      Fix_Amount_Dispatch_M1__c=800);
        
        insert dispatchDetailsLine;
        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',12000,new,case8a,2000,2000,2000,2000,2000,2000,2000,2000,2000,2000,2000,2000\r\n';
        
        Blob csvBlob = Blob.valueOf(contentData);
        
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvBlob,true));
        Test.stopTest();
        
        Contract_Discount__c cd = [SELECT Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c,
                                   Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c,
                                   Value_amt_disp_M11__c, Value_amt_disp_M12__c
                                   FROM Contract_Discount__c
                                   LIMIT 1];
        
        decimal[] months = new decimal[]{0,0,0,0,0,0,0,0,0,0,0,0};
            months[0] = cd.Value_amt_disp_M1__c;
        months[1] = cd.Value_amt_disp_M2__c;
        months[2] = cd.Value_amt_disp_M3__c;
        months[3] = cd.Value_amt_disp_M4__c;
        
        months[4] = cd.Value_amt_disp_M5__c;
        months[5] = cd.Value_amt_disp_M6__c;
        months[6] = cd.Value_amt_disp_M7__c;
        months[7] = cd.Value_amt_disp_M8__c;
        
        months[8] = cd.Value_amt_disp_M9__c;
        months[9] = cd.Value_amt_disp_M10__c;
        months[10] = cd.Value_amt_disp_M11__c;
        months[11] = cd.Value_amt_disp_M12__c;
        
        
        //Assertion
        System.assertEquals(800,[SELECT Value_amt__c FROM Contract_Discount__c WHERE Id = :condition.Id].Value_amt__c);
        for(integer index =0; index<12;index++){
            System.assertEquals(1000, months[index]);
        }	
    }
    
    @isTest static void case10_yearly_prenego() {
        init();
        
        // Integer fiscalYear = System.today().year();
        Integer sequence = System.today().month();
      
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        
        // Create prenego condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = True);
        condition.Value_amt_disp_M1__c = 1000;
        condition.Value_amt_disp_M2__c = 1000;
        condition.Value_amt_disp_M3__c = 1000;
        condition.Value_amt_disp_M4__c = 1000;
        condition.Value_amt_disp_M5__c = 1000;
        condition.Value_amt_disp_M6__c = 1000;
        condition.Value_amt_disp_M7__c = 0;
        condition.Value_amt_disp_M8__c = 0;
        condition.Value_amt_disp_M9__c = 0;
        condition.Value_amt_disp_M10__c = 0;
        condition.Value_amt_disp_M11__c = 0;
        condition.Value_amt_disp_M12__c = 0;
        
        insert condition;
        
        // Create dispatch detail
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c=dispatchHead.Id,
                                                                                      Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id,
                                                                                      Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                      PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'New');
        
        insert dispatchDetailsLine;
        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',6000,prenego,case8a,0,0,0,0,0,0,1000,1000,1000,1000,1000,1000\r\n';
        
        Blob csvBlob = Blob.valueOf(contentData);
        
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvBlob,true));
        Test.stopTest();
        
        Contract_Discount__c cd = [SELECT Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c,
                                   Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c,
                                   Value_amt_disp_M11__c, Value_amt_disp_M12__c
                                   FROM Contract_Discount__c
                                   LIMIT 1];
        
        decimal[] months = new decimal[]{0,0,0,0,0,0,0,0,0,0,0,0};
        months[0] = cd.Value_amt_disp_M1__c;
        months[1] = cd.Value_amt_disp_M2__c;
        months[2] = cd.Value_amt_disp_M3__c;
        months[3] = cd.Value_amt_disp_M4__c;
        
        months[4] = cd.Value_amt_disp_M5__c;
        months[5] = cd.Value_amt_disp_M6__c;
        months[6] = cd.Value_amt_disp_M7__c;
        months[7] = cd.Value_amt_disp_M8__c;
        
        months[8] = cd.Value_amt_disp_M9__c;
        months[9] = cd.Value_amt_disp_M10__c;
        months[10] = cd.Value_amt_disp_M11__c;
        months[11] = cd.Value_amt_disp_M12__c;
        
        
        //Assertion
        System.assertEquals(1, [SELECT count() FROM Contract_Discount__c]);
        System.assertEquals(1, [SELECT count() FROM Inv_BUDispatch__c]);
        System.assertEquals(1, [SELECT count() FROM Inv_BUDispatch_Details__c]);
        
//        System.assertEquals(12800,[SELECT Value_amt__c FROM Contract_Discount__c WHERE Id = :condition.Id].Value_amt__c);
        System.assertEquals(1000,months[0]);
        System.assertEquals(1000, months[11]);
        for(integer index =0; index<12;index++){
            System.assertEquals(1000, months[index]);
            
        }
    }
    
    @isTest static void case10_yearly_new(){
        init();
        
        // Integer fiscalYear = System.today().year();
        Integer sequence = System.today().month();
        
        String field = 'Fix_Amount_Dispatch_M' + sequence + '__c';
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
      //  insert dispatchHead;
        
        // Create prenego condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Value_amt__c = 800, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);
        condition.Value_amt_disp_M1__c = 1000;
        condition.Value_amt_disp_M2__c = 1000;
        condition.Value_amt_disp_M3__c = 1000;
        condition.Value_amt_disp_M4__c = 1000;
        condition.Value_amt_disp_M5__c = 1000;
        condition.Value_amt_disp_M6__c = 1000;
        condition.Value_amt_disp_M7__c = 0;
        condition.Value_amt_disp_M8__c = 0;
        condition.Value_amt_disp_M9__c = 0;
        condition.Value_amt_disp_M10__c = 0;
        condition.Value_amt_disp_M11__c = 0;
        condition.Value_amt_disp_M12__c = 0;
        
        insert condition;
        
        // Create dispatch detail
        Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c=dispatchHead.Id,
                                                                                      Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                      Hierarchy_level_dispatch__c = section.Id,
                                                                                      Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                      PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'New',
                                                                                      Fix_Amount_Dispatch_M1__c=800);
        
     //   insert dispatchDetailsLine;
        
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',6000,new,case8a,0,0,0,0,0,0,1000,1000,1000,1000,1000,1000\r\n';
        
        Blob csvBlob = Blob.valueOf(contentData);
        
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvBlob,true));
        Test.stopTest();
        
        Contract_Discount__c cd = [SELECT Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c,
                                   Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c,
                                   Value_amt_disp_M11__c, Value_amt_disp_M12__c
                                   FROM Contract_Discount__c
                                   LIMIT 1];
        
        decimal[] months = new decimal[]{0,0,0,0,0,0,0,0,0,0,0,0};
        months[0] = cd.Value_amt_disp_M1__c;
        months[1] = cd.Value_amt_disp_M2__c;
        months[2] = cd.Value_amt_disp_M3__c;
        months[3] = cd.Value_amt_disp_M4__c;
        
        months[4] = cd.Value_amt_disp_M5__c;
        months[5] = cd.Value_amt_disp_M6__c;
        months[6] = cd.Value_amt_disp_M7__c;
        months[7] = cd.Value_amt_disp_M8__c;
        
        months[8] = cd.Value_amt_disp_M9__c;
        months[9] = cd.Value_amt_disp_M10__c;
        months[10] = cd.Value_amt_disp_M11__c;
        months[11] = cd.Value_amt_disp_M12__c;
        
        
        //Assertion
      //  System.assertEquals(12800,[SELECT Value_amt__c FROM Contract_Discount__c WHERE Id = :condition.Id].Value_amt__c);
        System.assertEquals(1, [SELECT count() FROM Contract_Discount__c]);
        System.assertEquals(1, [SELECT count() FROM Inv_BUDispatch__c]);
        System.assertEquals(1, [SELECT count() FROM Inv_BUDispatch_Details__c]);
       
        for(integer index =0; index<12;index++){
            System.assertEquals(1000, months[index]);
            
        }	
    }
        @isTest static void case10_yearly_new_PG(){
        init();
        //Create condition type new
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                  Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                  Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id,
                                                                  Is_Prenego_Envelop__c = False);
        insert condition;
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',3000,New,case10,1000,1000,1000,0,0,0,0,0,0,0,0,0\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG2.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',3000,New,case10,1000,1000,1000,0,0,0,0,0,0,0,0,0\r\n';
            contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG2.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',3000,New,case10,0,0,0,0,0,0,0,0,0,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        //Test
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id,String.valueOf(year), csvBlob,true));
        Test.stopTest();
        //Get data
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        Contract_Discount__c cd = [SELECT Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt__c 
                              FROM Contract_Discount__c
                              LIMIT 1];
        Decimal conditionM1 = cd.Value_amt_disp_M1__c;
        Decimal conditionM2 = cd.Value_amt_disp_M2__c;
        Decimal conditionM3 = cd.Value_amt_disp_M3__c;
        Decimal amt = cd.Value_amt__c;
        // Assertion
        System.assertEquals(1, dispatchHeadCount);
        System.assertEquals(2, dispatchDetailsCount);
        System.assertEquals(1, conditionCount);
        System.assertEquals(2000, conditionM1);
        System.assertEquals(2000, conditionM2);
        System.assertEquals(2000, conditionM3);
        System.assertEquals(9000, amt);
        
    }

    /*
    
    @isTest static void testBatch() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += supplier.Code__c + ',' +section.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
    	contentData += supplier.Code__c + ',' +section2.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store2.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += supplier.Code__c + ',' +section3.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store2.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,2051,NS-Nestle-00,St001,Sample Advertising fees,21000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Start test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(2, dispatchHeadCount);
		System.assertEquals(3, dispatchDetailsCount);
		System.assertEquals(3, conditionCount);
    }
    // Valid record.
    @isTest static void validRecord() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += supplier.Code__c + ',' +section.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Start test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHead = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetails = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer condition = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(1, dispatchHead);
		System.assertEquals(1, dispatchDetails);
		System.assertEquals(1, condition);
    }
    // Invalid record: invalid supplier code.
    @isTest static void invalidSupplier() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += 'X' + supplier.Code__c + ',' +section.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Start test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHead = [SELECT count() FROM Inv_BUDispatch__c];        
        Integer dispatchDetails = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer condition = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(0, dispatchHead);
		System.assertEquals(0, dispatchDetails);
		System.assertEquals(0, condition);
    }
    // Invalid record: invalid section code.
    @isTest static void invalidSection() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += supplier.Code__c + ',X' +section.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Start test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHead = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetails = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer condition = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(0, dispatchHead);
		System.assertEquals(0, dispatchDetails);
		System.assertEquals(0, condition);
    }
    // Invalid record: invalid NS code.
    @isTest static void invalidNS() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += supplier.Code__c + ',' +section.Elt_Code__c+ ',X' +negoScope.NS_Code__c+ ',' +store.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
		// Start test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHead = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetails = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer condition = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(0, dispatchHead);
		System.assertEquals(0, dispatchDetails);
		System.assertEquals(0, condition);
	}
    // Invalid record: invalid store code.
    @isTest static void invalidStore() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += supplier.Code__c + ',' +section.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',X' +store.BU_Code__c+ ',' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHead = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetails = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer condition = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(0, dispatchHead);
		System.assertEquals(0, dispatchDetails);
		System.assertEquals(0, condition);
    }
    // Invalid record: invalid condition name (case sensitive)
    @isTest static void invalidTarrifCondition() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += supplier.Code__c + ',' +section.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store.BU_Code__c+ ',X' +tariffCondition.Name+ ',12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Start test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHead = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetails = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer condition = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(0, dispatchHead);
		System.assertEquals(0, dispatchDetails);
		System.assertEquals(0, condition);
    }
    // Invalid record: invalid amount.
    @isTest static void invalidAmount() {
    	init();
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
    	contentData += supplier.Code__c + ',' +section.Elt_Code__c+ ',' +negoScope.NS_Code__c+ ',' +store.BU_Code__c+ ',' +tariffCondition.Name+ ',18000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
		// Start test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        Integer dispatchHead = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetails = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer condition = [SELECT count() FROM Contract_Discount__c];
		// Assertion.
		System.assertEquals(0, dispatchHead);
		System.assertEquals(0, dispatchDetails);
		System.assertEquals(0, condition);
    }*/
    @isTest static void invalidAmount_monthly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',ag,new,test_monthly\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, false));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(0, dispatchHeadCount);
        System.assertEquals(0, dispatchDetailsCount);
        System.assertEquals(0, conditionCount);
    }
    
    @isTest static void invalidAmount_yearly() {
        init();
        String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += supplier.Code__c + ',' + section.Elt_Code__c + ',' + PG.SNA_Code__c + ','
            + NS.NS_Code__c + ',' + store.BU_Code__c + ',' + tariffCondition.Name + ',1000,new,test_yearly,1000,o,0,0,0,0,0,0,0,0,0,0\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        // Test.
        Test.startTest();
        Database.executeBatch(new MassDistributionBatch(country.Id, String.valueOf(year), csvBlob, true));
        Test.stopTest();
        // Get data.
        Integer dispatchHeadCount = [SELECT count() FROM Inv_BUDispatch__c];
        Integer dispatchDetailsCount = [SELECT count() FROM Inv_BUDispatch_Details__c];
        Integer conditionCount = [SELECT count() FROM Contract_Discount__c];
        // Assertion.
        System.assertEquals(0, dispatchHeadCount);
        System.assertEquals(0, dispatchDetailsCount);
        System.assertEquals(0, conditionCount);
    }
}