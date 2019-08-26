@isTest
private class Nego360_Merge_Contract_Controller_Test {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c initContract;
    private static Contract__c dupContract;
    private static Contract__c simContract;
    private static String plv;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c initCondition1;
    private static Contract_Discount__c initCondition2;
    private static Contract_Discount__c initCondition3;
    private static Contract_Discount__c dupCondition1;
    private static Contract_Discount__c dupCondition2;
    private static Contract_Discount__c dupCondition3;
    private static Contract_Discount__c simCondition1;
    private static Contract_Discount__c simCondition2;
    private static Contract_Discount__c simCondition3;
    private static Contract_Discount__c simCondition4;
    
    static void init() {
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
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
                                       Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                       Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create init Contract
        initContract = new Contract__c(Name ='Nestle Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C111',
                                       Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 12,
                                       CurrencyIsoCode = currencyIsoCode, Contract_BU__c = country.Id, Status__c = 'Signed', D_N__c = 'N', Tactite_reconduction__c = true);
        insert initContract;
        // Create duplicated Contract
        dupContract = new Contract__c(Name ='Nestle Contract 2018', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C112',
                                      Contract_BDate__c = date.newInstance(year+1, 1, 1), Contract_EDate__c = date.newInstance(year+1, 12, 31), Duration__c = 12,
                                      Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Status__c = 'Validated', CurrencyIsoCode = currencyIsoCode,
                                      D_N__c = 'D', Tactite_reconduction__c = true, Parent_Contract__c = initContract.Id);
        // Create simulation Contract
        simContract = new Contract__c(Name ='Simulation 1 2018', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C113',
                                      Contract_BDate__c = date.newInstance(year+1, 1, 1), Contract_EDate__c = date.newInstance(year+1, 12, 31), Duration__c = 12,
                                      Contract_BU__c = country.Id, Contract_Type__c = 'Simulation', Status__c = 'Published', CurrencyIsoCode = currencyIsoCode,
                                      Parent_Contract__c = initContract.Id);
        insert new List<Contract__c>{dupContract, simContract};
            // Create Policy - Tariff Conditions
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        plv = fieldResult.getPicklistValues().get(0).getValue();
        tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                   Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                   Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create Conditions related to the initial contract.
        initCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                  BU_Scope__c = country.Id, Contract__c = initContract.Id);
        initCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                  BU_Scope__c = country.Id, Contract__c = initContract.Id);
        initCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                                  Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                  BU_Scope__c = country.Id, Contract__c = initContract.Id);
        insert new List<Contract_Discount__c>{initCondition1, initCondition2, initCondition3};
            // Create Conditions related to the duplicated contract.
            dupCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                     Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                     BU_Scope__c = country.Id, Contract__c = dupContract.Id, Reference_condition__c = initCondition1.Id);
        dupCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = dupContract.Id, Reference_condition__c = initCondition2.Id);
        dupCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = dupContract.Id, Reference_condition__c = initCondition3.Id);
        // Create Conditions related to the simulation contract.
        simCondition1 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 1, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition1.Id);
        simCondition2 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 2, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition2.Id);
        simCondition3 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 3, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id, Reference_condition__c = initCondition3.Id);
        simCondition4 = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year+1, 1, 1),
                                                 Disc_EDate__c = date.newInstance(year+1, 12, 31), Value_per__c = 4, Product_Scope__c = NS.Id,
                                                 BU_Scope__c = country.Id, Contract__c = simContract.Id);
        insert new List<Contract_Discount__c>{dupCondition1, dupCondition2, dupCondition3, simCondition1, simCondition2, simCondition3, simCondition4};
            }
    
    // List of contract is not null.
    @isTest static void const1() {
        init();
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);   
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        system.assertNotEquals(null, nego360MergeContractController.simContObj);
        system.assertNotEquals(null, nego360MergeContractController.dupContObj);
    }
    
    // The contract type does not "Simulation".
    @isTest static void const2() {
        init(); 
        // Update type of the simulation contract.
        simContract.Contract_Type__c = 'Target';
        update simcontract;        
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('Contract type is not a Simulation')){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    // The contract status does not "Published".
    @isTest static void const3() {
        init(); 
        // Update status of the simulation contract.
        simContract.Status__c = 'In preparation';
        update simcontract;
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('Contract status is not Published.')){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    // The status of the supplier does not "Active".
    @isTest static void const4() {
        init();
        supplier.Status__c = 'In preperation';
        update supplier;
        
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('Supplier status is not Active.')){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    // The status of the NS does not "Active".
    @isTest static void const5() {
        init();
        NS.Status__c = 'Inactive';
        update NS;
        
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains('Nego Scope status is not Active.')) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    // Merge with duplicated contracts. Three cases: Insert condition, update and delete.
    @isTest static void submitMerge_Success() {
        init();
        delete simCondition2;
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        nego360MergeContractController.submitMerge();
        system.assertEquals(true, nego360MergeContractController.isMerged);
    }
    
    // Merge without duplicated contracts.
    @isTest static void submitMerge_Success_WithoutDup() {
        init();
        delete dupContract;
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        nego360MergeContractController.submitMerge();
        system.assertEquals(true, nego360MergeContractController.isMerged);
    }
    
    // The status of the simulation contract does not "Simulation" or the contract is already merged.
    @isTest static void const6() {
        init(); 
        // Update type of the simulation contract.
        simContract.Status__c = 'Merged';
        update simcontract;
        ApexPages.currentPage().getParameters().put('cId', simContract.Contract_BU__c);
        ApexPages.currentPage().getParameters().put('pId', simContract.Parent_Contract__c);
        ApexPages.currentPage().getParameters().put('Id', simContract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(simContract);
        Nego360_Merge_Contract_Controller nego360MergeContractController = new Nego360_Merge_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('Contract type is not a Simulation or already merged.')){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
}