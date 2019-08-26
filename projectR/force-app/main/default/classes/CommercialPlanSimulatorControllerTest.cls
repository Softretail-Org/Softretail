@isTest
private class CommercialPlanSimulatorControllerTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Sup_sup_NegoScope__c negoScope;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand;
    private static Product2 product;
    private static Supplier_PG_Mapping__c pg;
    private static Contract__c contract;
    private static Sell_in_Flow__c sellIn;
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
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Create Country
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            country.Related_Client__c = supplier.Id;
            update country;
            // Get the default negoscope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // make NS Acc_Country__c = Contract_BU__r.Country__c
            NS.Acc_Country__c = country.Name;
            update NS;
            // Create Department
            department = TestDataFactory.createDepartment(false, rootId);
            insert department;
            // Create Section        
            section = TestDataFactory.createSection(false, department.Id);
            insert section;
            // Create brand
            brand = TestDataFactory.createBrand(false, supplier.Id);
            insert brand;
            // insert product
            product = TestDataFactory.createProduct(false, section.Id, supplier.Id);
            product.IsActive = true;
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
            insert tariffCondition;
            // Create sell in flow
            Sell_in_Flow__c sellIn = TestDataFactory.createSellinFlow(false, NS, section, product, Date.newInstance(year, 3, 1));
            sellIn.Master_BU__c = country.Id;
            sellIn.BU__c = country.Id;
            insert sellIn;
            // insert commercialPlan
            commercialPlan = new Commercial_Plan__c(Name = 'Marketing Media001', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                                    Start_Date__c = date.newInstance(year, 2, 1), End_Date__c = date.newInstance(year, 4, 1),
                                                    CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation', Supplier__c = supplier.Id,
                                                    BU_Target__c = country.Id, Condition_Code__c = 'C06', History_Reference__c = 'M-1_Y');
            commercialPlan.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Media_Catalog');
            insert commercialPlan;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_constructor() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(commercialPlan);
        CommercialPlanSimulatorController ctrlr = new CommercialPlanSimulatorController(stdController);
        ctrlr.getSellInOrOutOptions();
        ctrlr.getHistoryReferenceOptions();
        ctrlr.getproducts();
        system.assertEquals(1, ctrlr.StdSetControllerProduct.getResultSize());        
    }
    
    @isTest static void test_search() {
        init();
        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(commercialPlan);
        CommercialPlanSimulatorController ctrlr = new CommercialPlanSimulatorController(stdController);
        ctrlr.structureLevelLookup = new LookupValue(department.Name, department.Id, true);
        ctrlr.negoScopeLookup = new LookupValue(NS.Name, NS.Id, true);
        ctrlr.brandLookup = new LookupValue(brand.Name, brand.Id, true);
        ctrlr.SearchName = supplier.Name + ' PG1';
        ctrlr.SortToggle();
        ctrlr.searchProduct();
        Test.stopTest();
        system.assertEquals(0, ctrlr.StdSetControllerProduct.getResultSize());
        ctrlr.resetProduct();
        system.assertEquals(1, ctrlr.StdSetControllerProduct.getResultSize());
    }
    
    @isTest static void test_fillInitSimulator() {
        init();
        Test.startTest();
        // insert condition
        Contract_Discount__c condition = new Contract_Discount__c(Contract__c = contract.Id,  Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c,
                                                                  Condition_Type__c = tariffCondition.Id, Value_amt__c = commercialPlan.Contribution_Validated__c,
                                                                  BU_Scope__c = contract.Contract_BU__c, Status__c = 'Open',
                                                                  Disc_BDate__c = commercialPlan.Start_Date__c, Disc_EDate__c = commercialPlan.End_Date__c,
                                                                  Is_Prenego_Envelop__c = false, Valid__c = true, CurrencyIsoCode = contract.CurrencyIsoCode);
        insert condition;
        // insert commercial plan detail
        Commercial_Plan_Detail__c cpd = new Commercial_Plan_Detail__c(Nego_Scope__c = NS.Id, Commercial_Event__c = commercialPlan.Id,
                                                                      CurrencyIsoCode = currencyIsoCode, Contribution_Unit_Quantity__c = 1, 
                                                                      Contribution_Unit_Amount__c = 1, Statut__c = 'In process of validation',
                                                                      Supplier__c = supplier.Id, Product__c = product.Id,
                                                                      Contract__c = contract.Id, Prenego_envelop__c = condition.Id);
        insert cpd;
        ApexPages.StandardController stdController = new ApexPages.StandardController(commercialPlan);
        CommercialPlanSimulatorController ctrlr = new CommercialPlanSimulatorController(stdController);
        ctrlr.getHistoryReferenceOptions();        
        ctrlr.getSimulatorInitList();
        Test.stopTest();
        system.assertEquals(1, ctrlr.StdSetControllerSimulatorInit.getResultSize());
    }
    
    @isTest static void test_save() {
        init();
        Test.startTest();
        // insert commercial plan detail
        Commercial_Plan_Detail__c cpd = new Commercial_Plan_Detail__c(Nego_Scope__c = NS.Id, Commercial_Event__c = commercialPlan.Id,
                                                                      CurrencyIsoCode = currencyIsoCode, Contribution_Unit_Quantity__c = 1, 
                                                                      Contribution_Unit_Amount__c = 1, Statut__c = 'In process of validation',
                                                                      Supplier__c = supplier.Id, Product__c = product.Id);
        insert cpd;
        ApexPages.StandardController stdController = new ApexPages.StandardController(commercialPlan);
        CommercialPlanSimulatorController ctrlr = new CommercialPlanSimulatorController(stdController);
        ctrlr.getHistoryReferenceOptions();
        ctrlr.getproducts();
        ctrlr.dragProductSelected();
        ctrlr.getSimulatorList();
        ctrlr.SortToggleSimulator();
        ctrlr.save();
        Test.stopTest();
        system.assertEquals(1, ctrlr.StdSetControllerSimulator.getResultSize());
        ApexPages.currentPage().getParameters().put('productId', product.Id);
        ctrlr.deleteProductSimulator();
        system.assertEquals(0, ctrlr.StdSetControllerSimulator.getResultSize());
    }
    
    @isTest static void test_generateExcel() {
        init();
        Test.startTest();
        // insert commercial plan detail
        Commercial_Plan_Detail__c cpd = new Commercial_Plan_Detail__c(Nego_Scope__c = NS.Id, Commercial_Event__c = commercialPlan.Id,
                                                                      CurrencyIsoCode = currencyIsoCode, Contribution_Unit_Quantity__c = 1, 
                                                                      Contribution_Unit_Amount__c = 100, Statut__c = 'In process of validation',
                                                                      Supplier__c = supplier.Id, Product__c = product.Id);
        insert cpd;
        ApexPages.currentPage().getParameters().put('action', 'Export');
        ApexPages.StandardController stdController = new ApexPages.StandardController(commercialPlan);
        CommercialPlanSimulatorController ctrlr = new CommercialPlanSimulatorController(stdController);
        ctrlr.getHistoryReferenceOptions();
        ctrlr.getproducts();
        ctrlr.dragProductSelected();
        ctrlr.getSimulatorList();
        ctrlr.save();
        Test.stopTest();
        ctrlr.generateExcel();
        system.assertEquals(1, ctrlr.StdSetControllerSimulator.getResultSize());
    }
}