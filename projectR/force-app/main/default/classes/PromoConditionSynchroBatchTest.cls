@isTest
private class PromoConditionSynchroBatchTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store1;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Sup_sup_NegoScope__c negoScope;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Product2 product;
    private static Supplier_PG_Mapping__c pg;
    private static Contract__c contract;
    private static Commercial_Plan__c commercialPlan;
    private static Pol_Com_Condition__c tariffCondition;
    
    static void init() {
        try {
            year = System.Today().year();
            // Root Element Id
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'MEA');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Legal Form.
            legal = TestDataFactory.createBULegal(true, myCountry);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            country.Related_Client__c = supplier.Id;
            update country;
            // Get the default negoscope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Department
            department = TestDataFactory.createDepartment(true, rootId);
            // Create Section        
            section = TestDataFactory.createSection(true, department.Id);
            // Create brand owner
            Sup_Supplier__c brandOwner = TestDataFactory.createSupplier(true, country, true);
            // Create brand
            brand = TestDataFactory.createBrand(false, supplier.Id);
            brand.Brand_Owner__c = brandOwner.Id;
            insert brand;
            // insert brand distributor
            Sup_Bra_Distributor__c bd = new Sup_Bra_Distributor__c(Name = 'BD-Test', Brand__c = brand.Id, Supplier__c = supplier.Id, Status_BDate__c = system.today());
            insert bd;
            // insert product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.Brand__c = brand.Id;
            insert product;
            // Create PG
            pg = TestDataFactory.createPG(false, supplier.Id, department.Id, section.Id);
            pg.Product__c = product.Id;
            pg.Brand__c = brand.Id;
            insert pg;
            // create contract
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 6, 1));
            insert contract;
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Condition_Code__c = 'C1';
            insert tariffCondition;
            // insert commercialPlan
            commercialPlan = TestDataFactory.createCommercialPlan(false, date.newInstance(year, 2, 1), date.newInstance(year, 4, 1));
            commercialPlan.Status__c = 'In preparation';
            commercialPlan.Condition_Code__c = 'C1';
            commercialPlan.BU_Target__c = country.Id;
            commercialPlan.Supplier__c = supplier.Id;
            insert commercialPlan;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_GenerateConditions() {
        init();
        Test.startTest();
        // Create Store
        List<Orga_BU__c> stores = TestDataFactory.createBUStores(true, country, legal.Id, 1);
        store1 = stores[0];
        // insert purchase flow pg
        Purchases_Flow_PG__c purchase = TestDataFactory.createPurchase(true, pg, store1.Id);
        // insert product
        Product2 product2 = TestDataFactory.createProduct(false, section.Id, supplier.Id);
        product2.Brand__c = brand.Id;
        insert product2;
        // insert commercial plan detail
        Commercial_Plan_Detail__c cd = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        cd.Statut__c = 'In process of validation';
        cd.Supplier__c = supplier.Id;
        cd.Product__c = product.Id;
        Commercial_Plan_Detail__c cd2 = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        cd2.Statut__c = 'In process of validation';
        cd2.Supplier__c = supplier.Id;
        cd2.Product__c = product2.Id;
        insert new List<Commercial_Plan_Detail__c>{cd, cd2};
        // execute PromoConditionSynchroBatch
        commercialPlan.Status__c = 'Validated';
        update commercialPlan;
        Test.stopTest();
        system.assertEquals(1, [SELECT COUNT() FROM Contract_Discount__c]);
        system.assertEquals(2, [SELECT COUNT() FROM Inv_BUDispatch_Details__c]);
        List<Inv_BUDispatch_Details__c> dispatchDetails = [SELECT Id, Purchases_Flow_PG__c FROM Inv_BUDispatch_Details__c
                                                           WHERE PG__c = :pg.Id AND Inv_BUDispatch__c = :store1.Id];
        if(dispatchDetails != null && !dispatchDetails.isEmpty()) {
            system.assertEquals(purchase.Id, dispatchDetails.get(0).Purchases_Flow_PG__c);
        }
    }
    
    @isTest static void test_UpdateConditions() {
        init();
        Test.startTest();
        // Create Store
        List<Orga_BU__c> stores = TestDataFactory.createBUStores(true, country, legal.Id, 1);
        store1 = stores[0];
        // insert condition
        Contract_Discount__c condition = TestDataFactory.createCondition(false, tariffCondition, contract, commercialPlan.Start_Date__c, commercialPlan.End_Date__c);
        condition.Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c;
        condition.Value_amt__c = commercialPlan.Contribution_Validated__c;
        condition.Is_Prenego_Envelop__c = false;
        condition.Valid__c = true;
        insert condition;
        // insert commercial plan detail
        Commercial_Plan_Detail__c cd = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
        cd.Statut__c = 'In process of validation';
        cd.Supplier__c = supplier.Id;
        cd.Product__c = product.Id;
        cd.Prenego_envelop__c = condition.Id;
        insert cd;
        // insert dispatch head
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = Date.today().month(), Inv_Fiscal_Year__c = year,
                                                               Inv_BU__c = store1.Id, CurrencyIsoCode = condition.CurrencyIsoCode);
        insert dispatchHead;
        // insert dispatch detail
        Inv_BUDispatch_Details__c dd = new Inv_BUDispatch_Details__c(Inv_DispatchHead__c = dispatchHead.Id, Discount__c = condition.Id, Contract__c = contract.Id,
                                                                     Supplier__c = commercialPlan.Supplier__c, Inv_BUDispatch__c = store1.Id,
                                                                     Hierarchy_level_dispatch__c = pg.Section__c, PG__c = pg.Id,
                                                                     Status__c = 'New', Sequence__c = Date.today().month(), CurrencyIsoCode = condition.CurrencyIsoCode);
        insert dd;
        // execute PromoConditionSynchroBatch
        commercialPlan.Status__c = 'Validated';
        update commercialPlan;
        Test.stopTest();
        system.assertEquals(1, [SELECT COUNT() FROM Inv_BUDispatch_Details__c]);
    }
}