/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for Contract Group Detail
 * */
@isTest
private class Trg_Contract_Group_Detail_Test {    
    private static Integer year;
    private static Integer day;
    private static Integer month;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    private static Pol_Com_Condition__c tariffCondition;
    private static String plv;
    
    static void init() {
        try {
            year = System.Today().year();
            day = System.Today().day();
            month = System.Today().month();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Create Region
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country
            country = new Orga_BU__c(Name = 'Lebanon', BU_Code__c = 'LBN', CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = 'LBN', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
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
            plv = fieldResult.getPicklistValues().get(0).getValue();
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
    //Test validation on Group Contract Detail With Line_Integration_Status__c = updated or deleted
    public static testmethod void createContractGroupeDetail_Success() { 
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
                                                                                   Order_Number__c = 2, Line_Integration_Status__c = 'Updated', 
                                                                                   Last_Integration_date__c =  date.newInstance(year, 1, 1), 
                                                                                   Nego_Discount_Type__c = plv,
                                                                                   Condition_name__c = tariffCondition.Id);
        insert contractGroupDetail;
        Test.stopTest();
        contractGroupDetail = [SELECT Id, Status__c From Contract_Group_Detail__c WHERE Id =:contractGroupDetail.Id];
        System.assertEquals(contractGroupDetail.Status__c, 'Updated');
    }  
    //Test validation on Group Contract Detail With Line_Integration_Status__c = updated or deleted
    public static testmethod void updateContractGroupeDetail_Success() { 
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
                                                                                   Nego_Discount_Type__c = plv,
                                                                                   Condition_name__c = tariffCondition.Id);
        insert contractGroupDetail;
        contractGroupDetail.Line_Integration_Status__c = 'Updated';
        update contractGroupDetail;
        Test.stopTest();
        contractGroupDetail = [SELECT Id, Status__c From Contract_Group_Detail__c WHERE Id =:contractGroupDetail.Id];
        System.assertEquals(contractGroupDetail.Status__c, 'Updated');
    }
    //Test validation on Group Contract With status = Synchronized and condition status <> Synchronized
    public static testmethod void updateContractGroupSynchronizedStatus_Success() { 
        init();      
        Test.startTest();
        // Create Contract Group
        Contract_Group__c contractGroup = new Contract_Group__c(Name = 'Group Contract-01' + year ,Contract_Number__c = 'GC-01', 
                                                                Contract_Year__c = year, Origin_Supplier_Code__c = 'S01', 
                                                                Origin_Supplier__c = 'Supplier01', Supplier__c = supplier.Id,
                                                                Start_Date__c = date.newInstance(year, 1, 1), 
                                                                End_date__c = date.newInstance(year, 2, 1), 
                                                                Contract_type__c = 'Contract', Header_Integration_Status__c = 'New', 
                                                                Last_Integration_Date__c = date.newInstance(year, month, day),
                                                                Status__c = 'Synchronized');
        insert contractGroup; 
        // Create Condition       
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
        contractGroupDetail.Status__c = 'Updated';
        update contractGroupDetail;
        Test.stopTest();
        contractGroup = [SELECT Id, Status__c From Contract_Group__c WHERE Id =:contractGroup.Id];
        System.assertEquals(contractGroup.Status__c, 'Updated');
    }
}