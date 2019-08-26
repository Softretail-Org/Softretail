@IsTest
private class RecentItemsBatchTest {
    
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
    
    static testMethod void test_ViewRecentItems()
    {
        init();
        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE '%admin%' LIMIT 1];
        User user1 = new User(FirstName='user1', LastName = 'user1', Alias = 'USR', Email = 'user1@negoptim.com',
                              Username = 'user1@negoptim.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
                              EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id);
        insert user1;       
        // Create Supplier.
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Supplier001', Code__c = 'Sup001', CurrencyIsoCode = currencyIsoCode,
                                                       Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true,
                                                       Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);                
        System.runAs(user1) {
            insert supplier;
        }
        Test.startTest();
        Id userId = UserInfo.getUserId();
        Database.executeBatch(new RecentItemsBatch('RecentItemsBatchTest', new List<String>{SObjectType.Sup_Supplier__c.Name}));
        Test.stopTest();        
        supplier = [SELECT LastViewedDate FROM Sup_Supplier__c WHERE Id = :supplier.Id];
        system.assertNotEquals(null, supplier.LastViewedDate);
    }
}