@isTest
private class NegoTemplateCreateControllerTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static NegoTemplate__c negoTemplate;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Commercial_Plan__c event;
    private static Commercial_Plan_Detail__c eventDetail;
    
    static void init() {
        year = System.Today().year();
        currencyIsoCode = NegoptimHelper.getCorporateCurrency();
        // Create Template.
    	negoTemplate = new NegoTemplate__c(Name = 'nTemp', Description__c = 'MPX', IsActive__c = True, ObjectType__c = SObjectType.Commercial_Plan_Detail__c.Name,
                                           //Body__c = '<div style="text-align: center;"><p style="font-family: arial,helvetica,sans-serif; font-size: 10px;"><strong>CONTRAT D&#39;APPLICATION</strong><br>{{!contract_year__c}}<br>{{!Contract__r.name}}</p></div><!--<lineitems><class>table255</class><listname>invoice_details__r</listname><column newrow="true" >name</column>-->'); 
                                           Body__c = '<!--{{!<div style="text-align: center;"><p style="font-family: arial,helvetica,sans-serif; font-size: 10px;"><strong>CONTRAT D&#39;APPLICATION</strong><br>{{!contract_year__c}}<br>{{!Contract__r.name}}</p></div>}}-->');     	
    	
    	insert negoTemplate;
        // Add Country.
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create Region.
        region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
        region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
        insert region;
        // Create Country.
        country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create Supplier.
        supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', Country_origin__c = country.Id, Status__c = 'Active');
        insert supplier;
        Schema.DescribeFieldResult fieldResult = Commercial_Plan__c.Event_Type__c.getDescribe();
        String plv0 = fieldResult.getPicklistValues().get(0).getValue();
        event = new Commercial_Plan__c(Event_Type__c = plv0, Name = plv0 + '-1-' + year, BU_Target__c = country.Id, Condition_Code__c = 'C06',
                                       Start_Date__c = date.newInstance(year, 1, 1), End_Date__c = date.newInstance(year, 3, 1), CurrencyIsoCode = currencyIsoCode);
        event.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Commercial_Plan__c.SObjectType, 'Sales_Floor_Event');
        insert event;
        eventDetail = new Commercial_Plan_Detail__c(Supplier__c = supplier.Id, Commercial_Event__c = event.Id,Contribution_Unit_Amount__c = 1500, Contribution_Unit_Quantity__c = 1, CurrencyIsoCode = currencyIsoCode);
        insert eventDetail;
    }
    
    static testmethod void constructor() {
        init();
        ApexPages.currentPage().getParameters().put('id', eventDetail.Id);
        NegoTemplateCreateController inst = new NegoTemplateCreateController();
        System.assertEquals(1, inst.availableTemplatesMap.size());
    }
    
    static testmethod void preview() {
        init();
        ApexPages.currentPage().getParameters().put('id', eventDetail.Id);
        ApexPages.currentPage().getParameters().put('tid', negoTemplate.Id);
        NegoTemplateCreateController inst = new NegoTemplateCreateController();
        Test.startTest();
        inst.preview();
        Test.stopTest();
        System.assert(true);
    }
    
    static testmethod void save() {
    	init();
        ApexPages.currentPage().getParameters().put('id', eventDetail.Id);
        ApexPages.currentPage().getParameters().put('tid', negoTemplate.Id);
    	NegoTemplateCreateController inst = new NegoTemplateCreateController();
    	inst.selectedTemplates = new List<Id>{negoTemplate.Id};
        Test.startTest();
        inst.save();
        Test.stopTest();
        // Validation Test
        List<Attachment> attachments = [SELECT Id FROM Attachment];
        System.assertEquals(1, attachments.size());
    }
}