/**
 * Unit Test class used to closing accounting trigger.
**/ 
@isTest
private class Trg_Accounting_Closing_Test {
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c storeBU;
    private static Orga_BU__c creditCompany;
    private static Orga_BU__c debitedCompany;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Pol_Com_Condition__c tariffCondition;
    private static String plv;
    private static Contract__c contract;
    private static Contract_Discount__c condition;
    static void init() {
        try {
            year = System.Today().year();
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEBFRANCE', 'FR');
            // Create Region.
            region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Create Country.
            country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Credit Company BU.
            creditCompany = TestDataFactory.createBULegal(true, myCountry);
            // Create Debited Company BU.
            debitedCompany = TestDataFactory.createBULegal(true, myCountry);
            // Create Store BU.            
            List<Orga_BU__c> stores = TestDataFactory.createBUStores(true, country, creditCompany.Id, 1);
            storeBU = stores[0];
            // Create Supplier.
            supplier = TestDataFactory.createSupplier(false, country, true);
            insert supplier;
            // Create NS.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(true, 1, 1);
            // Create contract.
            contract = TestDataFactory.createContract(true, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            // Create condition.
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    // Insert accounting closing
    @isTest static void insertAccountingClosing_Success() {
        init();
        Accounting_Closing__c accountingClosing = TestDataFactory.createAccountingClosing(false, storeBU.Id);
        accountingClosing.Closing_Date__c = System.today();
        accountingClosing.Invoices__c = true;
        accountingClosing.Status__c = 'Preview';
        
        Test.startTest();
        insert accountingClosing;
        Test.stopTest();
        // Validation Test
        List<Accounting_Closing__c> accountingClosingList = [SELECT Id, Name FROM Accounting_Closing__c];
        System.assertEquals(1, accountingClosingList.size());
    }
    
    // Update accounting closing
    @isTest static void updateAccountingClosing_Success() {
        init();
        Profile profile = [SELECT Id FROM Profile WHERE Name LIKE '%Standard%' LIMIT 1];
        User user;
        if(profile != null){
            user = new User(FirstName='user1', LastName = 'user1', Alias = 'USR', Email = 'user1@negoptim.com',
                             Username = 'user1@negoptim.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
                             EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id);
            insert user;
        }
        // Insert Accounting Scheme
        Accounting_Scheme__c accountingScheme = TestDataFactory.createAccountingScheme(false, storeBU.Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
        accountingScheme.Amount_Type__c = 'HT';
        accountingScheme.Included_Discount_Types__c = 'Penalties;Rebates';
        insert accountingScheme;
        
        // Insert Accounting Closing
        Accounting_Closing__c accountingClosing = TestDataFactory.createAccountingClosing(false, storeBU.Id);
        accountingClosing.Closing_Date__c = System.today();
        accountingClosing.Invoices__c = true;
        accountingClosing.Status__c = 'Preview';
        
        Test.startTest();
        insert accountingClosing;
        Test.stopTest();
        // Validation Test
        // Test update fields(Business_Unit__c, Closing_Date__c, Invoices__c, Payments__c,...)
        accountingClosing.Payments__c = true;
        Database.SaveResult result = Database.update(accountingClosing, false);
        System.assertEquals(Label.MSG_Delete_Accounting_Closing_Line, result.getErrors()[0].getMessage());
        // Insert Accounting Entry
        Accounting_Entry__c accountingEntry = new Accounting_Entry__c(Entry_Type__c = 'Invoice', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme.Id,
                                                                      Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'JV / Campagne ',
                                                                      Comment__c = 'HT', VAT_rate__c = 10, Amount__c = 50, Amount_signed__c = 50,
                                                                      Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'), Reference_year__c = year);
        insert accountingEntry;
        // Test update status to sent to SAP
        accountingClosing.Status__c = 'Sent_to_Accounting';
        update accountingClosing;
        accountingEntry = [SELECT Id, Status__c FROM Accounting_Entry__c LIMIT 1];
        System.assertEquals(accountingEntry.Status__c, 'Extract');
        // Test update status to preview
        if(user != null){
            System.runAs(user) {
                accountingClosing.Status__c = 'Preview';
                Database.SaveResult resultLocked = Database.update(accountingClosing, false);
                System.assertEquals(resultLocked.getErrors()[0].getStatusCode(), StatusCode.ENTITY_IS_LOCKED);
            }
        }
        // Test update status to preview by ADMIN USER
        accountingClosing.Status__c = 'Preview';
        update accountingClosing;
        System.assertEquals(accountingClosing.Status__c, 'Preview');
    }
    
    // Delete Accounting Closing
    @isTest static void deleteAccountingClosing_Success() {
        init();
        // Insert Accounting Scheme
        Accounting_Scheme__c accountingScheme = TestDataFactory.createAccountingScheme(false, storeBU.Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
        accountingScheme.Amount_Type__c = 'HT';
        accountingScheme.Included_Discount_Types__c = 'Penalties;Rebates';
        insert accountingScheme;
        // Insert Accounting Closing
        Accounting_Closing__c accountingClosing = TestDataFactory.createAccountingClosing(false, storeBU.Id);
        accountingClosing.Closing_Date__c = System.today();
        accountingClosing.Invoices__c = true;
        accountingClosing.Status__c = 'Preview';
        
        Test.startTest();
        insert accountingClosing; 
        // Insert Accounting Entry
        Accounting_Entry__c accountingEntry = new Accounting_Entry__c(Entry_Type__c = 'Invoice', Accounting_Closing__c = accountingClosing.Id, Accounting_Scheme_Line__c = accountingScheme.Id,
                                                                      Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id, Entry_Label__c = 'JV / Campagne ',
                                                                      Comment__c = 'HT', VAT_rate__c = 10, Amount__c = 50, Amount_signed__c = 50,
                                                                      Status__c = (accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'), Reference_year__c = year);
        insert accountingEntry;
        Test.stopTest();
        delete accountingClosing;
        // Validation Test
        List<Accounting_Entry__c> accountingEntries = [SELECT Id, Name, Accounting_Closing__c, Accounting_Scheme_Line__c, Credited_Company__c,
                                                       Entry_Label__c, Comment__c, VAT_rate__c, Amount__c, Status__c, Amount_Type__c
                                                       FROM Accounting_Entry__c];
        System.assertEquals(0, accountingEntries.size());
        List<Accounting_Closing__c> accountingClosingList = [SELECT Id, Name, Status__c FROM Accounting_Closing__c];
        System.assertEquals(0, accountingClosingList.size());
    }
}