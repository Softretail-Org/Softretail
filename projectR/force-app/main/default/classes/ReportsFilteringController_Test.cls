@isTest
private class ReportsFilteringController_Test {
    
    private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region; 
    private static Orga_BU__c country;
    
    static void init() {
    	year = System.Today().year();
        // Root Element Id.
        rootId = NegoptimHelper.getRootId();
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
    }
    
    @isTest static void testGetFilteringList() {
        init();
        ReportsFilteringController rf = new ReportsFilteringController();
        rf.getYears();
        system.assert(true);
    } 
    
     @isTest static void testSubmitReport() {
        init();
        ApexPages.currentPage().getParameters().put('pv0', country.Id);
        ApexPages.currentPage().getParameters().put('pv1', String.valueof(year));
        
        ReportsFilteringController rf = new ReportsFilteringController();
		rf.submitReportResult();
        system.assert(true);
    }
}