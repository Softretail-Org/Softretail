@IsTest
private class RecentlyViewedControllerTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;    
    static void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Create Region.
            region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
            region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
            insert region;
            // Create Country.
            country = new Orga_BU__c(Name = 'Lebanon', BU_Code__c = 'LBN', CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = 'LBN',
                                     BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
        } catch (Exception ex) {
            System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
        }
    }
    
    // Recent Items Batch.
    @isTest static void submitRecentItemsBatch_Success() {
    	init();
    	RecentlyViewedController instance = new RecentlyViewedController();
        instance.selectedObjects = new List<String> {'Sup_Supplier__c'};
    	Test.startTest();
    	instance.submitRecentItemsBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('Recent Items')) {
                   messageFound = true;
            }
		}
        System.assert(messageFound);
    }
}