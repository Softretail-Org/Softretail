/**
 * BaseRedistributionModelBatchTest
 * */
@isTest(SeeAllData=false)
private class BaseRedistributionModelBatchTest {
    
    private static final Integer COUNTER = 10;
    private static final Integer STORE_NUMBER = 10;
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store1;
    private static Orga_BU__c store2;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static List<Supplier_PG_Mapping__c> PGs;
    
    private static Contract_Discount__c conditionPurchasesOfTheMonth;
    private static Contract_Discount__c conditionEqually;
    private static Contract_Discount__c conditionYTD;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = TestDataFactory.currencyIsoCode;
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Create Country
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Legal Form
            Orga_BU__c legal = TestDataFactory.createBULegal(false, myCountry);
            insert legal;
            // Create Stores
            store1 = TestDataFactory.createBUStores(false, country, legal.Id, 1)[0];
            store2 = TestDataFactory.createBUStores(false, country, legal.Id, 1)[0];
            insert new List<Orga_BU__c> {store1, store2};
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
            // Create list of PGs.
            PGs = new List<Supplier_PG_Mapping__c>();
            for(Integer i = 1; i <= 2; i++) {
                Supplier_PG_Mapping__c PG = new Supplier_PG_Mapping__c(Name = 'PG' + i, Supplier__c = supplier.Id, Department__c = department.Id, Section__c = section.Id,
                                                                       SNA_Code__c = '100' + i, GIMA_Code__c = '100' + i, CurrencyIsoCode = currencyIsoCode);
                PGs.add(PG);
            }
            insert PGs;
            // Create conditions.
            conditionPurchasesOfTheMonth = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                                    Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                    Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id,
                                                                    Value_amt__c = 60000, Value_per__c = 2.5, Base_Redistribution_Model__c = 'Purchases of the month',
                                                                    Value_amt_disp_M1__c = 5000, Value_amt_disp_M2__c = 5000, Value_amt_disp_M3__c = 5000,
                                                                    Value_amt_disp_M4__c = 5000, Value_amt_disp_M5__c = 5000, Value_amt_disp_M6__c = 5000,
                                                                    Value_amt_disp_M7__c = 5000, Value_amt_disp_M8__c = 5000, Value_amt_disp_M9__c = 5000,
                                                                    Value_amt_disp_M10__c = 5000, Value_amt_disp_M11__c = 5000, Value_amt_disp_M12__c = 5000);
            
            conditionYTD = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                    Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                    Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id,
                                                    Value_amt__c = 60000, Value_per__c = 2.5, Base_Redistribution_Model__c = 'YTD Purchases (current year)',
                                                    Value_amt_disp_M1__c = 5000, Value_amt_disp_M2__c = 5000, Value_amt_disp_M3__c = 5000,
                                                    Value_amt_disp_M4__c = 5000, Value_amt_disp_M5__c = 5000, Value_amt_disp_M6__c = 5000,
                                                    Value_amt_disp_M7__c = 5000, Value_amt_disp_M8__c = 5000, Value_amt_disp_M9__c = 5000,
                                                    Value_amt_disp_M10__c = 5000, Value_amt_disp_M11__c = 5000, Value_amt_disp_M12__c = 5000);
            
            ConditionEqually = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id,
                                                        Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                        Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id,
                                                        Value_amt__c = 60000, Value_per__c = 2.5, Base_Redistribution_Model__c = 'Equally',
                                                        Value_amt_disp_M1__c = 5000, Value_amt_disp_M2__c = 5000, Value_amt_disp_M3__c = 5000,
                                                        Value_amt_disp_M4__c = 5000, Value_amt_disp_M5__c = 5000, Value_amt_disp_M6__c = 5000,
                                                        Value_amt_disp_M7__c = 5000, Value_amt_disp_M8__c = 5000, Value_amt_disp_M9__c = 5000,
                                                        Value_amt_disp_M10__c = 5000, Value_amt_disp_M11__c = 5000, Value_amt_disp_M12__c = 5000);
            
            insert new List<Contract_Discount__c> {conditionPurchasesOfTheMonth, conditionEqually, conditionYTD};
                
            // Create purchases
            List<Purchases_Flow_PG__c> purchases = new List<Purchases_Flow_PG__c>();
            for (Integer i = 0 ; i < 10 ; i++) {
                Decimal amount = 10;
                // on store1
                Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(math.mod(i, 2)).Id, Supplier_Nego_Scope__c = NS.Id,
                                                                         Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id,
                                                                         BU__c = store1.Id, Year__c = year,
                                                                         TO1__c = amount, TO2__c = amount, TO3__c = amount, TO4__c = amount,
                                                                         TO5__c = amount, TO6__c = amount, TO7__c = amount, TO8__c = amount,
                                                                         TO9__c = amount, TO10__c = amount, TO11__c = amount, TO12__c = amount,
                                                                         CurrencyIsoCode = currencyIsoCode);
                // on store2
                Purchases_Flow_PG__c purchase2 = purchase.clone();
                purchase2.BU__c = store2.Id;
                purchases.add(purchase);
                purchases.add(purchase2);
                
            }
            insert purchases;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage() + '-' + ex.getLineNumber());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    static testmethod void test_purchasesOfTheMonth() {
        init();
        
        Date d = Date.newInstance(year, 3, 1);
        Integer sequence = d.month() == 1 ? 12 : d.month() - 1;
        
        Test.startTest();
        /*
        // Create dispatch head
        List<Inv_BUDispatch__c> dHeads = new List<Inv_BUDispatch__c>();
        Inv_BUDispatch__c dispatchHead1 = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                                Inv_BU__c = store1.Id, CurrencyIsoCode = currencyIsoCode);
        dHeads.add(dispatchHead1);
        Inv_BUDispatch__c dispatchHead2 = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                                Inv_BU__c = store2.Id, CurrencyIsoCode = currencyIsoCode);
        dHeads.add(dispatchHead2);
        insert dHeads;
        // Create dispatch detail
        List<Inv_BUDispatch_Details__c> dds = new List<Inv_BUDispatch_Details__c>();
        Inv_BUDispatch_Details__c dispatchDetailsLine11 = new Inv_BUDispatch_Details__c(Discount__c = conditionPurchasesOfTheMonth.Id,Inv_DispatchHead__c=dispatchHead1.Id,
                                                                                        Contract__c = contract.Id, Inv_BUDispatch__c = store1.Id,
                                                                                        Hierarchy_level_dispatch__c = section.Id,
                                                                                        Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                        PG__c = PGs[0].Id, Supplier__c = supplier.Id, Status__c = 'New');
        dds.add(dispatchDetailsLine11);
        Inv_BUDispatch_Details__c dispatchDetailsLine12 = new Inv_BUDispatch_Details__c(Discount__c = conditionPurchasesOfTheMonth.Id,Inv_DispatchHead__c=dispatchHead1.Id,
                                                                                        Contract__c = contract.Id, Inv_BUDispatch__c = store1.Id,
                                                                                        Hierarchy_level_dispatch__c = section.Id,
                                                                                        Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                        PG__c = PGs[1].Id, Supplier__c = supplier.Id, Status__c = 'New');
        dds.add(dispatchDetailsLine12);
        Inv_BUDispatch_Details__c dispatchDetailsLine21 = new Inv_BUDispatch_Details__c(Discount__c = conditionPurchasesOfTheMonth.Id,Inv_DispatchHead__c=dispatchHead2.Id,
                                                                                        Contract__c = contract.Id, Inv_BUDispatch__c = store2.Id,
                                                                                        Hierarchy_level_dispatch__c = section.Id,
                                                                                        Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                        PG__c = PGs[0].Id, Supplier__c = supplier.Id, Status__c = 'New');
        dds.add(dispatchDetailsLine21);
        Inv_BUDispatch_Details__c dispatchDetailsLine22 = new Inv_BUDispatch_Details__c(Discount__c = conditionPurchasesOfTheMonth.Id,Inv_DispatchHead__c=dispatchHead2.Id,
                                                                                        Contract__c = contract.Id, Inv_BUDispatch__c = store2.Id,
                                                                                        Hierarchy_level_dispatch__c = section.Id,
                                                                                        Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                        PG__c = PGs[1].Id, Supplier__c = supplier.Id, Status__c = 'New');
        dds.add(dispatchDetailsLine22);
        insert dds;*/
        Database.executeBatch(new BaseRedistributionModelBatch('UNIT TEST', country.Id, new List<Id>{contract.Id}, new List<Id>{conditionPurchasesOfTheMonth.Id}, Date.newInstance(year, 3, 1), 'Purchases of the month'));
        Test.stopTest();
        
        // Assertions
        System.assertEquals(2, [SELECT COUNT() FROM Inv_BUDispatch__c]); // One head for each store
        System.assertEquals(4, [SELECT COUNT() FROM Inv_BUDispatch_Details__c]); // One line per PG per Store
        String fixAmountField = 'Fix_Amount_Dispatch_M' + sequence + '__c';
        for (Inv_BUDispatch_Details__c item: [SELECT Fix_Amount_Dispatch_M1__c, Fix_Amount_Dispatch_M2__c, Fix_Amount_Dispatch_M3__c, Fix_Amount_Dispatch_M4__c,
                                              Fix_Amount_Dispatch_M5__c, Fix_Amount_Dispatch_M6__c, Fix_Amount_Dispatch_M7__c, Fix_Amount_Dispatch_M8__c,
                                              Fix_Amount_Dispatch_M9__c, Fix_Amount_Dispatch_M10__c, Fix_Amount_Dispatch_M11__c, Fix_Amount_Dispatch_M12__c
                                              FROM Inv_BUDispatch_Details__c])
        {
            System.assertEquals(1250.0, (Decimal) item.get(fixAmountField));
        }
        // Total dispatch details TO
        List<AggregateResult> ar = [SELECT SUM(YTD_Dispatch__c) Total FROM Inv_BUDispatch_Details__c];
        Decimal sumDispatchDetails = (Decimal) ar[0].get('Total');
        System.assertEquals(5000, sumDispatchDetails);
    }
    
    static testmethod void test_purchasesOfTheYear() {
        init();
        Test.startTest();
        Date d = Date.newInstance(year, 3, 1);
        Integer sequence = d.month() == 1 ? 12 : d.month() - 1;
        Database.executeBatch(new BaseRedistributionModelBatch('UNIT TEST', country.Id, new List<Id>{contract.Id}, null, Date.newInstance(year, 3, 1), 'YTD Purchases (current year)'));
        Test.stopTest();
        // Assertions
        System.assertEquals(2, [SELECT COUNT() FROM Inv_BUDispatch__c]);
        System.assertEquals(4, [SELECT COUNT() FROM Inv_BUDispatch_Details__c]);
        String fixAmountField = 'Fix_Amount_Dispatch_M' + sequence + '__c';
        for (Inv_BUDispatch_Details__c item: [SELECT Fix_Amount_Dispatch_M1__c, Fix_Amount_Dispatch_M2__c, Fix_Amount_Dispatch_M3__c, Fix_Amount_Dispatch_M4__c,
                                              Fix_Amount_Dispatch_M5__c, Fix_Amount_Dispatch_M6__c, Fix_Amount_Dispatch_M7__c, Fix_Amount_Dispatch_M8__c,
                                              Fix_Amount_Dispatch_M9__c, Fix_Amount_Dispatch_M10__c, Fix_Amount_Dispatch_M11__c, Fix_Amount_Dispatch_M12__c
                                              FROM Inv_BUDispatch_Details__c])
        {
            System.assertEquals(1250.0, (Decimal) item.get(fixAmountField));
        }
    }
    
    static testmethod void case_general() {
        init();

        Test.startTest();
        Database.executeBatch(new BaseRedistributionModelBatch('UNIT TEST', country.Id, new List<Id>{contract.Id}, null, Date.newInstance(year, 3, 1), null));
        Test.stopTest();
        
        // Get data
        Integer countDispatchLineEqually = [SELECT COUNT() FROM Inv_BUDispatch_Details__c WHERE Discount__c = :conditionEqually.Id];
        Integer countDispatchLineYTD = [SELECT COUNT() FROM Inv_BUDispatch_Details__c WHERE Discount__c = :conditionYTD.Id];
        Integer countDispatchLinePurchasesOfTheMonth = [SELECT COUNT() FROM Inv_BUDispatch_Details__c WHERE Discount__c = :conditionPurchasesOfTheMonth.Id];
        // Assertions
        System.assertEquals(2, [SELECT COUNT() FROM Inv_BUDispatch__c]);
        System.assertEquals(0, countDispatchLineEqually);
        System.assertEquals(4, countDispatchLineYTD);
        System.assertEquals(4, countDispatchLinePurchasesOfTheMonth);
    }
    
    static testmethod void test_ExtId() {
        init();
        Test.startTest();
        Date d = Date.newInstance(year, 3, 1);
        Integer sequence = d.month() == 1 ? 12 : d.month() - 1;
        // Create dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = year,
                                                                Inv_BU__c = store1.Id, CurrencyIsoCode = currencyIsoCode);
        insert dispatchHead;
        // Create dispatch detail
        Inv_BUDispatch_Details__c dispatchDetail1 = new Inv_BUDispatch_Details__c(Discount__c = conditionPurchasesOfTheMonth.Id, Inv_DispatchHead__c = dispatchHead.Id,
                                                                                  Contract__c = contract.Id, Inv_BUDispatch__c = store1.Id,
                                                                                  Hierarchy_level_dispatch__c = section.Id,
                                                                                  Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                  PG__c = PGs[0].Id, Supplier__c = supplier.Id, Status__c = 'New');
        Inv_BUDispatch_Details__c dispatchDetail2 = new Inv_BUDispatch_Details__c(Discount__c = conditionPurchasesOfTheMonth.Id, Inv_DispatchHead__c = dispatchHead.Id,
                                                                                  Contract__c = contract.Id, Inv_BUDispatch__c = store1.Id,
                                                                                  Hierarchy_level_dispatch__c = section.Id,
                                                                                  Sequence__c = sequence, CurrencyIsoCode = currencyIsoCode,
                                                                                  PG__c = PGs[0].Id, Supplier__c = supplier.Id, Status__c = 'New');
        insert new List<Inv_BUDispatch_Details__c>{dispatchDetail1,dispatchDetail2};
        Test.stopTest();
        Inv_BUDispatch_Details__c dispatchDetail1Inserted = [SELECT Id, Name, Ext_id__c FROM Inv_BUDispatch_Details__c WHERE Id = :dispatchDetail1.Id];
        System.assertEquals(dispatchDetail1Inserted.Name, dispatchDetail1Inserted.Ext_id__c);
        Inv_BUDispatch_Details__c dispatchDetail2Inserted = [SELECT Id, Name, Ext_id__c FROM Inv_BUDispatch_Details__c WHERE Id = :dispatchDetail2.Id];
        System.assertEquals(dispatchDetail2Inserted.Name, dispatchDetail2Inserted.Ext_id__c);
    }
}