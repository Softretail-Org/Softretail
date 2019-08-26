@isTest
private class CommercialPlanDetailBUControllerTest {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c legal;
    private static Orga_BU__c store1;
    private static Orga_BU__c store2;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Commercial_Plan_Detail__c cpd;
    private static Commercial_Plan__c commercialPlan;
    private static Map<Id, Orga_BU__c> buMap;
    public static PageReference pageRef;
    
    static void init() {
        try {
            year = System.Today().year();
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
            // Create Legal Form.
            legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
            legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
            insert legal;
            Id storeRecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
            // Create Store
            store1 = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store1.RecordTypeId = storeRecordTypeId;
            store2 = new Orga_BU__c(Name = 'Store 2', BU_Code__c = 'STR2', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
            store2.RecordTypeId = storeRecordTypeId;
            insert new List<Orga_BU__c>{store1, store2};
            // Create supplier.
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active',
                                           Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Get the default negoscope created on supplier creation.
            NS = [SELECT Id, NS_Code__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id LIMIT 1];
            Schema.DescribeFieldResult fieldResult = Commercial_Plan__c.Event_Support__c.getDescribe();
            String eventSupportValue = fieldResult.getPicklistValues().get(0).getValue();
            //Create Commercial Plan
            commercialPlan = new Commercial_Plan__c(Event_Support__c = eventSupportValue, Name = 'event', CurrencyIsoCode = currencyIsoCode,
                                                    Start_Date__c = date.newInstance(year, 1, 1) ,End_Date__c=date.newInstance(year, 1, 30),
                                                    Status__c = 'In Preparation', BU_Target__c = country.Id, Condition_Code__c = 'C06');
            insert commercialPlan;              
            //Create Commercial Plan Detail
            cpd = new Commercial_Plan_Detail__c(Commercial_Event__c = commercialPlan.Id, Contribution_Unit_Amount__c = 10,
                                                Contribution_Unit_Quantity__c = 10, CurrencyIsoCode = CurrencyIsoCode,
                                                BU_Target__c = country.Id, Nego_Scope__c = NS.Id,
                                                Supplier__c = supplier.Id);
            insert cpd;  
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void test_save(){
        init();    
        Commercial_Plan_Detail_BU__c cpdBu1 = new Commercial_Plan_Detail_BU__c(Commercial_Event_Line__c = cpd.id, Status__c = 'New',
                                                                               BU_Validated_Volume__c = 10, Orga_Business_Unit__c = store1.Id);
        insert cpdBu1;
        pageRef = new PageReference('/apex/Commercial_Plan_Detail_BU');
        pageRef.getParameters().put('Id', String.valueOf(cpd.Id));
        //Test
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cpd);
        Commercial_Plan_Detail_BU_Controller con = new Commercial_Plan_Detail_BU_Controller(stdController);
        String bucode = con.getCommercialPlanDetailBUList()[0].BUCode;
        con.getCommercialPlanDetailBUList()[0].cpdBU.BU_Validated_Volume__c = 50;
        con.save();
        Commercial_Plan_Detail_BU__c cpdBu = [SELECT BU_Validated_Volume__c
                                              FROM Commercial_Plan_Detail_BU__c
                                              WHERE Orga_Business_Unit__r.BU_Code__c = :bucode];
        
        //Assertion        
        System.assertEquals(50, cpdBu.BU_Validated_Volume__c);
    }
}