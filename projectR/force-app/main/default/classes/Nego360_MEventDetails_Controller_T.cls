/**
 * This class contains unit tests for validating the behavior of Apex classes and triggers.
 **/
@isTest
private class Nego360_MEventDetails_Controller_T {
    
    private static Integer year;
    private static Integer previousYear;
    private static Commercial_Plan_Detail__c eventDetail;
    private static Commercial_Plan_Detail__c eventDetail1;
    private static Sup_Supplier__c supplier;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Attachment attach;
    private static Attachment attach2;
    private static String currencyIsoCode;
    
    static void init() {
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
        // Create Supplier
        supplier = TestDataFactory.createSupplier(false, country, true); 
        insert supplier;
        
        Schema.DescribeFieldResult fieldResult = Commercial_Plan__c.Event_Type__c.getDescribe();
        String plv0 = fieldResult.getPicklistValues().get(0).getValue();
        String plv1 = fieldResult.getPicklistValues().get(1).getValue();
        Commercial_Plan__c event1 = new Commercial_Plan__c(Event_Type__c = plv0, Name = plv0 + '-1-' + year, Start_Date__c = date.newInstance(year, 1, 1), End_Date__c = date.newInstance(year, 3, 1), CurrencyIsoCode = currencyIsoCode,
                                                           Event_Support__c = 'Front path', Status__c = 'In Preparation', BU_Target__c = country.Id, Condition_Code__c = 'C06');
        event1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Sales_Floor_Event');
        Commercial_Plan__c event2 = new Commercial_Plan__c(Event_Type__c = plv1, Name = plv1 + year,Start_Date__c = date.newInstance(year, 3, 2), End_Date__c = date.newInstance(year, 5, 1), CurrencyIsoCode = currencyIsoCode,
                                                           Event_Support__c = 'Front path', Status__c = 'In Preparation', BU_Target__c = country.Id, Condition_Code__c = 'C06');
        event2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Sales_Floor_Event');
        insert new List<Commercial_Plan__c> {event1, event2};
        
        eventDetail = new Commercial_Plan_Detail__c(Supplier__c = supplier.Id, Commercial_Event__c = Event1.Id,Contribution_Unit_Amount__c = 1500, Contribution_Unit_Quantity__c = 1, CurrencyIsoCode = currencyIsoCode);
        eventDetail1 = new Commercial_Plan_Detail__c(Supplier__c = supplier.Id, Commercial_Event__c = Event2.Id,Contribution_Unit_Amount__c = 1100, Contribution_Unit_Quantity__c = 2, CurrencyIsoCode = currencyIsoCode);
        insert new List<Commercial_Plan_Detail__c> {eventDetail, eventDetail1};
        //create attached pdf
        attach = new Attachment();
        attach.Name = 'Unit Test Attachment';
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        attach.body = bodyBlob;
        attach.ContentType = 'application/pdf';
        attach.parentId = eventDetail.Id;
        insert attach;
         //create attached image
        attach2 = new Attachment();
        attach2.Name = 'Unit Test Attachment 2';
        Blob bodyBlob2 = Blob.valueOf('Unit Test Attachment Body 2');
        attach2.body = bodyBlob2;
        attach2.ContentType = 'image/jpeg';
        attach2.parentId = eventDetail.Id;
        insert attach2;
    }
    /* test the construction , when we list events*/
    @isTest static void test_constructor() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEventDetails_Controller ctrlr = new Nego360_MarketingEventDetails_Controller(stdController);
        system.assertEquals(2, ctrlr.listEventsDetailWrapper.size());
    }
    
    @isTest static void test_filter_event_type() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEventDetails_Controller ctrlr = new Nego360_MarketingEventDetails_Controller(stdController);
        // special events
        String selectedChoice = ctrlr.eventsTypeOptions.get(1).getValue();
        ctrlr.valuesEventType.add(selectedChoice);
        ctrlr.getEventDetailsFilter();
        system.assertEquals(1, ctrlr.listEventsDetailWrapper.size());
    }
    
    @isTest static void test_filter_on_user() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEventDetails_Controller ctrlr = new Nego360_MarketingEventDetails_Controller(stdController);
        // special events
        String selectedChoice = ctrlr.usersOptions.get(0).getValue();
        ctrlr.valuesUsers.add(selectedChoice);
        ctrlr.getEventDetailsFilter();
        system.assertEquals(2, ctrlr.listEventsDetailWrapper.size());
    }
    
    @isTest static void test_filter_on_supplier() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEventDetails_Controller ctrlr = new Nego360_MarketingEventDetails_Controller(stdController);
        // special events
        String selectedChoice = ctrlr.suppliersOptions.get(0).getValue();
        ctrlr.valuesSuppliers.add(selectedChoice);
        ctrlr.getEventDetailsFilter();
        system.assertEquals(2, ctrlr.listEventsDetailWrapper.size());
    }
    
    @isTest static void test_filter_on_attachement() {
        init();
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Commercial_Plan__c());
        Nego360_MarketingEventDetails_Controller ctrlr = new Nego360_MarketingEventDetails_Controller(stdController);
        // special events
        String selectedChoice = ctrlr.attachTypeOptions.get(0).getValue();
        ctrlr.valuesAttachType.add(selectedChoice);
        ctrlr.getEventDetailsFilter();
        system.assertEquals(1, ctrlr.listEventsDetailWrapper.size());
    }
}