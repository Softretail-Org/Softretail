/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for Contract Group
 * */
@isTest
private class Trg_Contract_Group_Test {
    private static Integer year;
    private static Integer day;
    private static Integer month;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Contract_Group__c contractGroup;
    private static Pol_Com_Condition__c tariffCondition;
    
    static void init() {
        try {
            year = System.Today().year();
            day = System.Today().day();
            month = System.Today().month();
            // Get the Corporate Currency
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
            // Create Supplier
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, 
                                           Country_origin__c = country.Id, Is_Default_NegoScope__c = true, Status__c = 'Active',
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default NegoScope created on supplier creation.
            negoScope = [SELECT Id, OwnerId FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
            // Create Policy - Tariff Conditions.
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            String plv = fieldResult.getPicklistValues().get(0).getValue();
            tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                       Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                       Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ', VAT_Type__c = 'Rebate', Condition_status__c = 'Open');
            insert tariffCondition;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }    
    // Test validation on Group Contract Owner and NS owner befort insert 
    public static testmethod void createContractGroupeDuplicateNegoScopeOwner_Success() { 
        init();      
        Test.startTest();
        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE '%admin%' LIMIT 1];
        User user1 = new User(FirstName='user1', LastName = 'user1', Alias = 'USR', Email = 'user1@negoptim.com',
                              Username = 'user1@negoptim.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
                              EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id);
        System.runAs(user1) {
            // Create Contract Group
            contractGroup = new Contract_Group__c(Name = 'Group Contract-01' + year ,Contract_Number__c = 'GC-01', 
                                                  Contract_Year__c = year, Origin_Supplier_Code__c = 'S01', 
                                                  Origin_Supplier__c = 'Supplier01', Supplier__c = supplier.Id,
                                                  Start_Date__c = date.newInstance(year, 1, 1), 
                                                  End_date__c = date.newInstance(year, 2, 1), 
                                                  Contract_type__c = 'Contract', Header_Integration_Status__c = 'New', 
                                                  Last_Integration_Date__c = date.newInstance(year, month, day));
            insert contractGroup;
        }       
        Test.stopTest();
        System.assertEquals(user1.Id, [Select Id, OwnerId From Contract_Group__c Where Id = :contractGroup.Id].OwnerId);
        contractGroup.Supplier_NegoScope__c = negoScope.Id;
        update contractGroup;
        System.assertEquals(negoScope.OwnerId, [Select Id, OwnerId From Contract_Group__c Where Id = :contractGroup.Id].OwnerId);
    } 
    //Test validation on Group Contract With Header_Integration_Status__c = updated or deleted
    public static testmethod void createContractGroupWithHeaderStatusUpdated_Success() { 
        init();      
        Test.startTest();
        // Create Contract Group
        Contract_Group__c contractGroup = new Contract_Group__c(Name = 'Group Contract-01' + year ,Contract_Number__c = 'GC-01', 
                                                                Contract_Year__c = year, Origin_Supplier_Code__c = 'S01', 
                                                                Origin_Supplier__c = 'Supplier01', Supplier__c = supplier.Id,
                                                                Start_Date__c = date.newInstance(year, 1, 1), 
                                                                End_date__c = date.newInstance(year, 2, 1), 
                                                                Contract_type__c = 'Contract', Header_Integration_Status__c = 'Updated', 
                                                                Last_Integration_Date__c = date.newInstance(year, month, day));
        insert contractGroup;
        Test.stopTest();
        contractGroup = [SELECT Id, Status__c From Contract_Group__c WHERE Id =:contractGroup.Id];
        System.assertEquals(contractGroup.Status__c, 'Updated');
    }  
    //Test validation on Group Contract With Header_Integration_Status__c = updated or deleted
    public static testmethod void updateContractGroupWithHeaderStatusUpdated_Success() { 
        init();      
        Test.startTest();
        // Create Contract Group
        Contract_Group__c contractGroup = new Contract_Group__c(Name = 'Group Contract-01' + year ,Contract_Number__c = 'GC-01', 
                                                                Contract_Year__c = year, Origin_Supplier_Code__c = 'S01', 
                                                                Origin_Supplier__c = 'Supplier01', Supplier__c = supplier.Id,
                                                                Start_Date__c = date.newInstance(year, 1, 1), 
                                                                End_date__c = date.newInstance(year, 2, 1), 
                                                                Contract_type__c = 'Contract', Header_Integration_Status__c = 'New', 
                                                                Last_Integration_Date__c = date.newInstance(year, month, day));
        insert contractGroup;
        contractGroup.Header_Integration_Status__c = 'Updated';
        update contractGroup;
        Test.stopTest();
        contractGroup = [SELECT Id, Status__c From Contract_Group__c WHERE Id =:contractGroup.Id];
        System.assertEquals(contractGroup.Status__c, 'Updated');
    }
    // Test validation on update Group Contract
    public static testmethod void updateContractGroup_Success() { 
        init();      
        Test.startTest();
        // Create Contract Group
        Contract_Group__c contractGroup = new Contract_Group__c(Name = 'Group Contract-01' + year ,Contract_Number__c = 'GC-01', 
                                                                Contract_Year__c = year, Origin_Supplier_Code__c = 'S01', 
                                                                Origin_Supplier__c = 'Supplier01', Supplier__c = supplier.Id,
                                                                Start_Date__c = date.newInstance(year, 1, 1), 
                                                                End_date__c = date.newInstance(year, 2, 1), 
                                                                Contract_type__c = 'Contract', Header_Integration_Status__c = 'New', 
                                                                Last_Integration_Date__c = date.newInstance(year, month, day));
        insert contractGroup;
        Contract_Group_Detail__c contractGroupDetail= new Contract_Group_Detail__c(Contract_List_Group__c = contractGroup.Id,
                                                                                   Origin_Disc_Code__c = 'C1', Origin_Disc_Code2__c = 'C1', 
                                                                                   Origin_Disc_name__c = 'Rebate',
                                                                                   Disc_BDate__c =  date.newInstance(year, 1, 1),
                                                                                   Disc_EDate__c = date.newInstance(year, 1, 1), 
                                                                                   Order_Number__c = 2, Line_Integration_Status__c = 'New',
                                                                                   Last_Integration_date__c =  date.newInstance(year, 1, 1), 
                                                                                   Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c,
                                                                                   Condition_name__c = tariffCondition.Id);
        insert contractGroupDetail;
        contractGroup.Start_Date__c = date.newInstance(year, 2, 1);
        contractGroup.End_date__c = date.newInstance(year, 3, 1);
        update contractGroup;
        Test.stopTest();
        contractGroup = [SELECT Id, Start_Date__c, End_date__c, Status__c From Contract_Group__c WHERE Id =:contractGroup.Id];
        contractGroupDetail = [SELECT Id, Disc_BDate__c, Disc_EDate__c, Status__c From Contract_Group_Detail__c WHERE Id =:contractGroupDetail.Id];
        System.assertEquals(contractGroupDetail.Status__c, 'Updated');
        System.assertEquals(contractGroupDetail.Status__c, 'Updated');
        System.assertEquals(contractGroupDetail.Disc_BDate__c, contractGroup.Start_Date__c);
        System.assertEquals(contractGroupDetail.Disc_EDate__c, contractGroup.End_date__c);
    }
    // Test validation on delete Group Contract
    public static testmethod void deleteContractGroup_Success() { 
        init();      
        Test.startTest();
        // Create Contract Group
        Contract_Group__c contractGroup = new Contract_Group__c(Name = 'Group Contract-01' + year ,Contract_Number__c = 'GC-01', 
                                                                Contract_Year__c = year, Origin_Supplier_Code__c = 'S01', 
                                                                Origin_Supplier__c = 'Supplier01', Supplier__c = supplier.Id,
                                                                Start_Date__c = date.newInstance(year, 1, 1), 
                                                                End_date__c = date.newInstance(year, 2, 1), 
                                                                Contract_type__c = 'Contract', Header_Integration_Status__c = 'New', 
                                                                Last_Integration_Date__c = date.newInstance(year, month, day));
        insert contractGroup;
        Contract_Group_Detail__c contractGroupDetail= new Contract_Group_Detail__c(Contract_List_Group__c = contractGroup.Id,
                                                                                   Origin_Disc_Code__c = 'C1', Origin_Disc_Code2__c = 'C1', 
                                                                                   Origin_Disc_name__c = 'Rebate',
                                                                                   Disc_BDate__c =  date.newInstance(year, 1, 1),
                                                                                   Disc_EDate__c = date.newInstance(year, 1, 1), 
                                                                                   Order_Number__c = 2, Line_Integration_Status__c = 'New',
                                                                                   Last_Integration_date__c =  date.newInstance(year, 1, 1), 
                                                                                   Nego_Discount_Type__c = tariffCondition.Nego_Discount_Type__c,
                                                                                   Condition_name__c = tariffCondition.Id);
        insert contractGroupDetail;
        contractGroup.Status__c = 'Deleted';
        update contractGroup;
        Test.stopTest();
        contractGroupDetail = [SELECT Id, Status__c From Contract_Group_Detail__c WHERE Id =:contractGroupDetail.Id];
        System.assertEquals(contractGroupDetail.Status__c, 'Deleted');
    }
}