@isTest
private class LinkPurchasesToDispatchDetailsBatchTest {

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
    private static Contract_Discount__c condition;
    private static String plv;
    private static List<Supplier_PG_Mapping__c> PGs;
    private static List<Purchases_Flow_PG__c> purchases;
    private static List<Inv_BUDispatch_Details__c> dispatchDetails;
    private static Inv_BUDispatch__c dispatchHead;
    
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
            //
            dispatchDetails = new List<Inv_BUDispatch_Details__c>();
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
            // Create 5 PGs.
            for(Integer i = 1; i <= 5; i++) {
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
            condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id,
                                                                      Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31),
                                                                      Contract__c = contract.Id, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Value_amt__c = 12, Value_per__c = 2.5);
            insert condition;
            dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = 9, Inv_Fiscal_Year__c = year, Inv_BU__c = store.Id, CurrencyIsoCode = currencyIsoCode);
            insert dispatchHead;
        } catch (Exception ex) { } 
    }
    
    static testmethod void multiplePurchasesPerDispatch() {
        init();
        // Create purchases on store.
        Integer i;
        for (Integer j = 0 ; j < 10 ; j++) {
            i = j / 2;
            Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(i).Id, Supplier_Nego_Scope__c = NS.Id,
                                                                     Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id, BU__c = store.Id, Year__c = year,
                                                                     TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                     TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
            purchases.add(purchase);
        }
        insert purchases;
        // create dispatch details
        for (Integer j = 0 ; j < 5 ; j++) {
            Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Inv_BUDispatch__c = store.Id, PG__c= PGs.get(j).Id,
                                                                                     Discount__c = condition.Id, Contract__c = condition.Contract__c,
                                                                                     Supplier__c = supplier.Id,Status__c = 'New',
                                                                                     CurrencyIsoCode = currencyIsoCode, Inv_DispatchHead__c = dispatchHead.Id);
            dispatchDetails.add(dispatchDetail);
        }
        insert dispatchDetails;
        
        Test.startTest();
        Database.executeBatch(new LinkPurchasesToDispatchDetailsBatch('UNIT_TEST', null, null, year));
        Test.stopTest();
        
        System.assertEquals(0, [SELECT Count() FROM Inv_BUDispatch_Details__c WHERE Purchases_Flow_PG__c <> NULL]);
    }
    
    static testmethod void singlePurchasesPerDispatch() {
        init();
        // Create purchases on store.
        for (Integer i = 0 ; i < 5 ; i++) {
            Purchases_Flow_PG__c purchase = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = PGs.get(i).Id, Supplier_Nego_Scope__c = NS.Id,
                                                                     Department__c = department.Id, Section__c = section.Id, Contrat1__c = contract.Id, BU__c = store.Id, Year__c = year,
                                                                     TO1__c = 100, TO2__c = 100, TO3__c = 100, TO4__c = 100, TO5__c = 100, TO6__c = 100, TO7__c = 100, TO8__c = 100,
                                                                     TO9__c = 100, TO10__c = 100, TO11__c = 100, TO12__c = 100, CurrencyIsoCode = currencyIsoCode);
            purchases.add(purchase);
        }
        insert purchases;
        // create dispatch details
        for (Integer i = 0 ; i < 5 ; i++) {
            Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Inv_BUDispatch__c = store.Id, PG__c= PGs.get(i).Id,
                                                                                     Discount__c = condition.Id, Contract__c = condition.Contract__c,
                                                                                     Supplier__c = supplier.Id,Status__c = 'New',
                                                                                     CurrencyIsoCode = currencyIsoCode, Inv_DispatchHead__c = dispatchHead.Id);
            dispatchDetails.add(dispatchDetail);
        }
        insert dispatchDetails;
        
        Test.startTest();
        Database.executeBatch(new LinkPurchasesToDispatchDetailsBatch('UNIT_TEST', null, null, year));
        Test.stopTest();
        
        System.assertEquals(5, [SELECT Count() FROM Inv_BUDispatch_Details__c WHERE Purchases_Flow_PG__c <> NULL]);
    }
}