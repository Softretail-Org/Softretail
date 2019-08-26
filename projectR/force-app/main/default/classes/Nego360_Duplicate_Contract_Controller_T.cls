@isTest
private class Nego360_Duplicate_Contract_Controller_T {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    
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
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active',
                                        Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
                                        Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
        // Insert Contract
        contract = new Contract__c(Name = 'Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                   Contract_BDate__c = date.newInstance(year, 2, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 5, Contract_BU__c = country.Id,
                                   Status__c = 'Signed', D_N__c = 'N', Tactite_reconduction__c = true, Contract_Type__c = 'Contract', Duration_type__c= 'Month');		
        insert contract;
        // Create Policy - Tariff Conditions
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(2016, 1, 1), Condition_Code__c = 'C1',
                                                                        Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                                        Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create Condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = contract.Contract_BDate__c,
                                                                  Disc_EDate__c = contract.Contract_EDate__c, Value_per__c = 2, Product_Scope__c = NS.Id, BU_Scope__c = country.Id, Contract__c = contract.Id);
        insert condition;
    }
    
    @isTest static void constructor_ContractListNotNull() {
        init();
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        system.assertNotEquals(null, ctrlr.contractObj);
    }
    
    @isTest static void constructor_ContractListNotNull_Tactite() {
        init();
        contract.Tactite_reconduction__c = false;
        update contract;
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains(Label.MSG_Unchecked_Tacite_Reconduction)){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest static void constructor_ContractList_AlreadyDuplicate() {
        init();
        // Create contract
        Contract__c contract2 = new Contract__c(Name = 'Contract ' + (year + 1), Parent_Contract__c = contract.Id, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C12345',
                                                Contract_BDate__c = contract.Contract_EDate__c.addDays(1), Contract_EDate__c = date.newInstance(year, 12, 31), Duration__c = 7, Contract_BU__c = country.Id,
                                                Status__c = 'Signed', D_N__c = 'D', Tactite_reconduction__c = false, Contract_Type__c = 'Contract', Duration_type__c= 'Month');		
        insert contract2;
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains(Label.MSG_Already_Duplicated)){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest static void constructor_ContractListNotNull_Status() {
        init();
        contract.Status__c = 'Closed';
        update contract;
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains(Label.MSG_Contract_Not_Signed)){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest static void constructor_ContractListNotNull_NegoScopeStatus() {
        init();
        NS.Status__c = 'Inactive';
        upsert NS;
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains(Label.MSG_Inactive_NegoScope)){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest static void constructor_ContractListNotNull_SuppStatus() {
        init();
        supplier.Status__c = 'Close';
        update supplier;
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains(Label.MSG_Inactive_supplier)){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest static void constructor_ContractListInvalidId() {
        init();
        ApexPages.currentPage().getParameters().put('id', supplier.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        system.assertEquals(null, ctrlr.contractObj);
        
        ctrlr.submitDuplicate();
        Boolean messageFound = false;
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains(Label.MSG_Invalid_Contract_Id)){
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
    
    @isTest static void submitDuplicate_Success() {
        init();
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        ctrlr.submitDuplicate();
        system.assertEquals(true, ctrlr.isDuplicate);
    }
    
    // D/N switching. N -> D.
    @isTest static void constructor_NToD() {
        init();
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        system.assertEquals('D', ctrlr.duplicatedContract.D_N__c);
    }
    
    // D/N switching. D -> N.
    @isTest static void constructor_DToN() {
        init();
        contract.D_N__c = 'D';
        update contract;
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        system.assertEquals('N', ctrlr.duplicatedContract.D_N__c);
    }
    
    // D/N is Null.
    @isTest static void constructor_DNIsNull() {
        init();
        contract.D_N__c = Null;
        update contract;
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(contract);
        Nego360_Duplicate_Contract_Controller ctrlr = new Nego360_Duplicate_Contract_Controller(stdController);
        system.assertEquals(Null, ctrlr.duplicatedContract.D_N__c);
    }
}