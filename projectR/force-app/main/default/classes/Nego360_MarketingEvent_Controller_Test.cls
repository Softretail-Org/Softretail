/**
* This class contains unit tests for validating the behavior of Apex classes.
*/
@isTest
private class Nego360_MarketingEvent_Controller_Test {
    
    private static Integer year;
    private static String currencyIsoCode;    
    
    static public void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Get all recortd type ids for Orga_BU__c SObject
            Map<String, Id> buRTIds = NegoptimHelper.getObjectRecordTypeMapIds(Orga_BU__c.SObjectType);
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            Orga_BU__c region = TestDataFactory.createBURegion(true, 'MEA'); 
            // Create Country
            Orga_BU__c country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            
            Schema.DescribeFieldResult fieldResult = Commercial_Plan__c.Event_Type__c.getDescribe();
            String plv0 = fieldResult.getPicklistValues().get(0).getValue();
            String plv1 = fieldResult.getPicklistValues().get(1).getValue();
            
            Commercial_Plan__c event1 = new Commercial_Plan__c(Event_Type__c = plv0, Name = plv0 + '-1-' + year, Start_Date__c = date.newInstance(year, 1, 1), End_Date__c = date.newInstance(year, 3, 1), CurrencyIsoCode = currencyIsoCode,
                                                               Event_Support__c = 'Front page', Status__c = 'In Preparation', BU_Target__c = country.Id, Condition_Code__c = 'C06');
            event1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Marketing_campaign');
            Commercial_Plan__c event2 = new Commercial_Plan__c(Event_Type__c = plv1, Name = plv1 + year,Start_Date__c = date.newInstance(year, 3, 2), End_Date__c = date.newInstance(year, 5, 1), CurrencyIsoCode = currencyIsoCode,
                                                               Event_Support__c = 'Front page', Status__c = 'In Preparation', BU_Target__c = country.Id, Condition_Code__c = 'C06');
            event2.RecordTypeId = event1.RecordTypeId;
            Commercial_Plan__c event3 = new Commercial_Plan__c(Event_Type__c = plv0, Name = plv0 + '-2-' + year, Start_Date__c = date.newInstance(year, 6, 1), End_Date__c = date.newInstance(year, 12, 1), CurrencyIsoCode = currencyIsoCode,
                                                               Event_Support__c = 'Web flash', Status__c = 'In Preparation', BU_Target__c = country.Id, Condition_Code__c = 'C06');
            event3.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Web_marketing');
            insert new List<Commercial_Plan__c> {event1, event2, event3};
                
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // test constructor
    @isTest static void test_constructor() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEvent_Controller ctrlr = new Nego360_MarketingEvent_Controller(stdController);
        system.assertEquals(3, ctrlr.listEventsWrapper.size());
    }
    
    @isTest static void test_filter_event_type() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEvent_Controller ctrlr = new Nego360_MarketingEvent_Controller(stdController);
        // special events
        String selectedChoice = ctrlr.eventsTypeOptions.get(1).getValue();
        ctrlr.valuesEventType.add(selectedChoice);
        ctrlr.loadEvents();
        system.assertEquals(1, ctrlr.listEventsWrapper.size());
    }
    
    @isTest static void test_filter_record_type() {
        init();
        ////ApexPages.currentPage().getParameters().put('id', event1.Id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEvent_Controller ctrlr = new Nego360_MarketingEvent_Controller(stdController);
        // web marketing
        String selectedChoice = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Web_marketing');////ctrlr.recordTypeOptions.get(4).getValue();
        ctrlr.valuesRecordType.add(selectedChoice);
        ctrlr.loadEvents();
        system.assertEquals(1, ctrlr.listEventsWrapper.size());
    }
}