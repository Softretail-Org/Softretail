@isTest
private class NegoTemplatePrintQueueTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    
    static void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
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
            // Create Supplier.
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode,
                                           Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Create NS.
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create contract
            contract = new Contract__c(Name ='Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                       Contract_BDate__c = System.Today().addMonths(-4), Contract_EDate__c = System.Today().addMonths(-2), Duration__c = 3, Contract_BU__c = country.Id,
                                       Contract_Type__c = 'Contract', Duration_type__c='Month', Last_Active_Contract__c = TRUE);            
            insert contract;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Related Type: Commercial_plan_detail__c
    static testmethod void test1() {
        init();
        String tName = 'Contrat d\'application';
        String tDescription = 'Contrat d\'application';
        String tType = 'Commercial_plan_detail__c';
        String tBody = 'CONTRAT D\'APPLICATION {{!contract_year__c}} {{!Contract__r.name}}';
        NegoTemplate__c nTemp = new NegoTemplate__c(Name = tName, Description__c = tDescription, ObjectType__c = tType, Body__c = tBody);
        insert nTemp;
        // Create commercialPlan.
        Commercial_Plan__c commercialPlan =
            new Commercial_Plan__c(Name = 'Marketing Media001', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-2), End_Date__c = System.Today() + 1,
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation',
                                   BU_Target__c = country.Id, Condition_Code__c = 'C06');
        commercialPlan.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Media_Catalog');
        insert commercialPlan;       
        // Create commercial plan detail.
        Commercial_Plan_Detail__c commercialPlanDetail =  
            new Commercial_Plan_Detail__c(Nego_Scope__c = NS.Id, Commercial_Event__c = commercialPlan.Id,
                                          CurrencyIsoCode = currencyIsoCode, Contribution_Unit_Quantity__c = 1, 
                                          Contribution_Unit_Amount__c = 1, Statut__c = 'In process of validation',
                                          Temp_Contract_Reference__c = 'Temp Ref Contract...', Supplier__c = supplier.Id);
        insert commercialPlanDetail;
        
        Test.startTest(); 
        System.enqueueJob(new NegoTemplatePrintQueue(new List<Id>{commercialPlanDetail.Id}, new List<Id>{nTemp.Id}));
        Test.stopTest();
        
        Integer attachementCount = [SELECT COUNT() FROM Attachment];
        System.assertEquals(1, attachementCount);
    }
    
    // Related Type: Contract__c
    static testmethod void test2() {
        init();
        String tName = 'Contrat d\'application';
        String tDescription = 'Contrat d\'application';
        String tType = 'Contract__c';
        String tBody = 'CONTRAT D\'APPLICATION {{!contract_year__c}} {{!Contract__r.name}}';
        NegoTemplate__c nTemp = new NegoTemplate__c(Name = tName, Description__c = tDescription, ObjectType__c = tType, Body__c = tBody);
        insert nTemp;
        // Create contract.
        Contract__c contract2 = new Contract__c(Name ='Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C124',
                                   Contract_BDate__c = System.Today().addMonths(-4), Contract_EDate__c = System.Today().addMonths(-2), Duration__c = 3, Contract_BU__c = country.Id,
                                   Contract_Type__c = 'Simulation', Duration_type__c='Month', Last_Active_Contract__c = TRUE);          
        insert contract2;
            
        Test.startTest(); 
        System.enqueueJob(new NegoTemplatePrintQueue(new List<Id>{contract.Id}, new List<Id>{nTemp.Id}));
        Test.stopTest();
        
        Integer attachementCount = [SELECT COUNT() FROM Attachment];
        System.assertEquals(1, attachementCount); 
    }
    
    // Mass.
    static testmethod void test3() {
        init();
        String tName = 'Contrat d\'application';
        String tDescription = 'Contrat d\'application';
        String tType = 'Commercial_plan_detail__c';
        String tBody = 'CONTRAT D\'APPLICATION {{!contract_year__c}} {{!Contract__r.name}}';
        NegoTemplate__c nTemp = new NegoTemplate__c(Name = tName, Description__c = tDescription, ObjectType__c = tType, Body__c = tBody);
        NegoTemplate__c nTemp2 = new NegoTemplate__c(Name = tName + '2', Description__c = tDescription + '2', ObjectType__c = tType, Body__c = tBody);
        insert new List<NegoTemplate__c>{nTemp, nTemp2};
        // Create commercialPlan With Date < Today
        Commercial_Plan__c commercialPlan =
            new Commercial_Plan__c(Name = 'Marketing Media001', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-2), End_Date__c = System.Today() + 1,
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation',
                                   BU_Target__c = country.Id, Condition_Code__c = 'C06');
        commercialPlan.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Media_Catalog');
        insert commercialPlan;       
        // Create list of commercial plan detail.
        Commercial_Plan_Detail__c commercialPlanDetail;
        List<Commercial_Plan_Detail__c> commercialPlanDetails = new List<Commercial_Plan_Detail__c>();
        for (Integer i=1 ; i<=100 ; i++) {
            commercialPlanDetail = new Commercial_Plan_Detail__c(Nego_Scope__c = NS.Id, Commercial_Event__c = commercialPlan.Id,
                                          CurrencyIsoCode = currencyIsoCode, Contribution_Unit_Quantity__c = 1, 
                                          Contribution_Unit_Amount__c = 1, Statut__c = 'In process of validation',
                                          Temp_Contract_Reference__c = 'Temp Ref Contract...', Supplier__c = supplier.Id);
            commercialPlanDetails.add(commercialPlanDetail);
        }
        insert commercialPlanDetails;
        List<Id> commercialPlanDetailIds = new List<Id>();
        for (Commercial_Plan_Detail__c c : commercialPlanDetails) {
            commercialPlanDetailIds.add(c.Id);
        }
        Test.startTest(); 
        System.enqueueJob(new NegoTemplatePrintQueue(commercialPlanDetailIds, new List<Id>{nTemp.Id, nTemp2.Id}));
        Test.stopTest();
        
        Integer attachementCount = [SELECT COUNT() FROM Attachment];
        System.assertEquals(2, attachementCount);
    }
    
    // Mass template.
    static testmethod void test4() {
        init();
        String tName = 'Contrat d\'application';
        String tDescription = 'Contrat d\'application';
        String tType = 'Commercial_plan_detail__c';
        String tBody = 'CONTRAT D\'APPLICATION {{!contract_year__c}} {{!Contract__r.name}}';
        List<NegoTemplate__c> templates = new List<NegoTemplate__c>();
            for (Integer i= 0 ; i < 100 ; i++) {
            	NegoTemplate__c nTemp = new NegoTemplate__c(Name = tName + i, Description__c = tDescription, ObjectType__c = tType, Body__c = tBody);
				templates.add(nTemp);                
            }   
            insert templates;
        List<Id> templateIds = new List<Id>();
        for (NegoTemplate__c temp : templates) {
            templateIds.add(temp.Id);
        } 
        
        // Create commercialPlan With Date < Today
        Commercial_Plan__c commercialPlan =
            new Commercial_Plan__c(Name = 'Marketing Media001', Event_Type__c = 'Collection', Event_Support__c = 'Front page',
                                   Start_Date__c = System.Today().addMonths(-2), End_Date__c = System.Today() + 1,
                                   CurrencyIsoCode = currencyIsoCode, Status__c = 'In Preparation',
                                   BU_Target__c = country.Id, Condition_Code__c = 'C06');
        commercialPlan.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Media_Catalog');
        insert commercialPlan;       
        // Create list of commercial plan detail.
        Commercial_Plan_Detail__c commercialPlanDetail;
        List<Commercial_Plan_Detail__c> commercialPlanDetails = new List<Commercial_Plan_Detail__c>();
        for (Integer i=1 ; i<=100 ; i++) {
            commercialPlanDetail = new Commercial_Plan_Detail__c(Nego_Scope__c = NS.Id, Commercial_Event__c = commercialPlan.Id,
                                          CurrencyIsoCode = currencyIsoCode, Contribution_Unit_Quantity__c = 1, 
                                          Contribution_Unit_Amount__c = 1, Statut__c = 'In process of validation',
                                          Temp_Contract_Reference__c = 'Temp Ref Contract...', Supplier__c = supplier.Id);
            commercialPlanDetails.add(commercialPlanDetail);
        }
        insert commercialPlanDetails;
        List<Id> commercialPlanDetailIds = new List<Id>();
        for (Commercial_Plan_Detail__c c : commercialPlanDetails) {
            commercialPlanDetailIds.add(c.Id);
        }
        Test.startTest(); 
        System.enqueueJob(new NegoTemplatePrintQueue(commercialPlanDetailIds, templateIds));
        Test.stopTest();        
        Integer attachementCount = [SELECT COUNT() FROM Attachment];
        System.assertEquals(100, attachementCount);
    }
}