/**
 * unit test for commercial plan.
 */
@isTest
private class Trg_Commercial_Plan_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Map<String, Id> buRTIds;
    private static Country_List__c myCountry;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
    private static Orga_BU__c legal;
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
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get all recortd type ids for Orga_BU__c SObject
            buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'MEA'); 
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create Supplier
            supplier = TestDataFactory.createSupplier(false, country, true); 
            insert supplier;        
            country.Related_Client__c = supplier.Id;
            update country;
            // Get the default negoscope created on supplier creation
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create group BU.
            groupBU = TestDataFactory.createGroupBU(true,'EMC');
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_InsertCommercialPlan() {
        init();
        //insert task
        Commercial_Plan_Task__c task = new Commercial_Plan_Task__c(BU__c = groupBU.Id, Event_Type__c = 'Web',
                                                                  Level__c = 'Regular', Status__c = 'In process of building');
        insert task;
        Commercial_Plan_Task_List__c todo1 = new Commercial_Plan_Task_List__c(Critical_to_continue__c = true, Duration_nb_day__c = 1,
                                                                              Step__c = 'S1', Commercial_Plan_Task__c = task.Id,
                                                                              Is_Supplier_RFP_step__c = true);
        Commercial_Plan_Task_List__c todo2 = new Commercial_Plan_Task_List__c(Critical_to_continue__c = true, Duration_nb_day__c = 2, 
                                                                              Step__c = 'S2', Commercial_Plan_Task__c = task.Id);
        Commercial_Plan_Task_List__c todo3 = new Commercial_Plan_Task_List__c(Critical_to_continue__c = true, Duration_nb_day__c = 3, 
                                                                              Step__c = 'S3', Commercial_Plan_Task__c = task.Id);
        insert new List<Commercial_Plan_Task_List__c>{todo1, todo2, todo3};
        // insert commercialPlan
        Commercial_Plan__c event = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                                          Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                                          CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation', Task_List_Reference__c = task.Id,
                                                          Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        event.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Marketing_campaign');
        Test.startTest();
        insert event;
        Test.stopTest();
        // Validation Test
        List<Commercial_Plan__c> events = [SELECT Id, Name, Start_Date__c FROM Commercial_Plan__c WHERE Task_List_Reference__c = NULL];
        system.debug(events);
        System.assertEquals(events.size(), 3);
    }
    
    @isTest static void test_DeleteCommercialPlan() {
         init();
        //insert task
        Commercial_Plan_Task__c task = new Commercial_Plan_Task__c(BU__c = groupBU.Id, Event_Type__c = 'Web',
                                                                  Level__c = 'Regular', Status__c = 'In process of building');
        insert task;
        // insert commercialPlan
        Commercial_Plan__c event = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                                          Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                                          CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation', Task_List_Reference__c = task.Id,
                                                          Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        event.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Marketing_campaign');
        insert event;
        
        Commercial_Plan__c todo1 = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation',
                                   Commercial_Animation_Plan_Parent__c =event.Id,
                                   Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        todo1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'TODO_inRFP');
        
        Commercial_Plan__c todo2 = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation', Commercial_Animation_Plan_Parent__c =event.Id,
                                   Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        todo2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'TODO_inRFP');
        
        Commercial_Plan__c todo3 = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation',
                                   Commercial_Animation_Plan_Parent__c =event.Id,
                                   Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        todo3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'TODO_inRFP');
        
        insert new List<Commercial_Plan__c>{todo1, todo2, todo3};
        test.startTest();
        event.Task_List_Reference__c = null;
        update event;
        test.stopTest();
      
        // Validation Test
        List<Commercial_Plan__c> events = [SELECT Id, Name, Start_Date__c FROM Commercial_Plan__c WHERE Task_List_Reference__c = NULL];
        system.debug(events);
        System.assertEquals(events.size(), 1);
    }
    
    @isTest static void test_updateCommercialPlan() {
         init();
        //insert task
        Commercial_Plan_Task__c task = new Commercial_Plan_Task__c(BU__c = groupBU.Id, Event_Type__c = 'Web',
                                                                  Level__c = 'Regular', Status__c = 'In process of building');
        insert task;
        
        // insert commercialPlan
        Commercial_Plan__c event = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation', Task_List_Reference__c = task.Id,
                                   Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        event.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Marketing_campaign');
        insert event;
        
        Commercial_Plan__c event2 = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation',
                                   Commercial_Animation_Plan_Parent__c =event.Id,
                                   Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        event2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'TODO_inRFP');
        
        Commercial_Plan__c event3 = new Commercial_Plan__c(Name = 'event1', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-4), End_Date__c = System.Today(),
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation',
                                   Commercial_Animation_Plan_Parent__c =event.Id,
                                   Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06');
        event3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Todo');
        insert new List<Commercial_Plan__c> {event2, event3};
        Date event2Date = event2.Start_Date__c;
        test.startTest();
        event.Start_Date__c = event.Start_Date__c.addDays(2);
        update event;
        test.stopTest();
      
        // Validation Test
        Commercial_Plan__c childEvent = [SELECT Id, Name, Start_Date__c FROM Commercial_Plan__c WHERE Id = :event2.Id];
        system.debug(childEvent);
        System.assertEquals(childEvent.Start_Date__c, event2Date.addDays(2));
    }
    
    @isTest static void test_GenerateConditions() {
        init();
        Test.startTest();
        // Create Legal Form.
        legal = TestDataFactory.createBULegal(false, myCountry);
        insert legal;
        // Create Department
        department = TestDataFactory.createDepartment(false, rootId);
        insert department;
        // Create Section        
        section = TestDataFactory.createSection(false, department.Id);
        insert section;
        // Create brand owner
        Sup_Supplier__c brandOwner = new Sup_Supplier__c(Name = 'brandOwner 001', Code__c = 'brandOwner001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                                         Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert brandOwner;
        // Create brand
        brand = TestDataFactory.createBrand(false, brandOwner.Id);
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
        tariffCondition.Condition_Code__c = 'C06';
        insert tariffCondition;
        // insert commercialPlan
        commercialPlan = new Commercial_Plan__c(Name = 'Marketing Media001', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                                Start_Date__c = date.newInstance(year, 2, 1), End_Date__c = date.newInstance(year, 4, 1),
                                                CurrencyIsoCode = currencyIsoCode, Supplier__c = supplier.Id, BU_Target__c = country.Id, Condition_Code__c = 'C06', Status__c = 'In Preparation');
        commercialPlan.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Media_Catalog');
        insert commercialPlan;
        commercialPlan = [SELECT Id, Status__c FROM Commercial_Plan__c WHERE Id = :commercialPlan.Id];
        System.assertEquals('In preparation', commercialPlan.Status__c);
        // insert commercial plan detail
        Commercial_Plan_Detail__c cd = new Commercial_Plan_Detail__c(Nego_Scope__c = NS.Id, Commercial_Event__c = commercialPlan.Id,
                                                                     CurrencyIsoCode = currencyIsoCode, Contribution_Unit_Quantity__c = 1, 
                                                                     Contribution_Unit_Amount__c = 1, Statut__c = 'In process of validation',
                                                                     Supplier__c = supplier.Id, Product__c = product.Id, Contract__c = contract.Id);
        insert cd;
        // update commercial plan
        commercialPlan.Status__c = 'Validated';
        update commercialPlan;
        Test.stopTest();
        cd = [SELECT Id, Prenego_envelop__c FROM Commercial_Plan_Detail__c WHERE Id = :cd.Id];
        system.assertEquals(1, [SELECT COUNT() FROM Contract_Discount__c]);
    }
}