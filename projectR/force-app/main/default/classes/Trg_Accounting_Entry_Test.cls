/**
 * Unit Test class used to accounting entry trigger.
**/ 
@isTest
private class Trg_Accounting_Entry_Test {
	
	private static final Integer year = TestDataFactory.year;
    private static Country_List__c myCountry;
    private static Orga_BU__c storeBU;
    private static Orga_BU__c creditCompany;
    private static Orga_BU__c debitedCompany;
    
    static void init() {
        try {
            // Add Country
            myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
            // Create Region.
            Orga_BU__c region = TestDataFactory.createBURegion(false, 'EU');
            insert region;
            // Create Country.
            Orga_BU__c country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
            insert country;
            // Create Credit Company BU.
            creditCompany = TestDataFactory.createBULegal(false, myCountry);
            insert creditCompany;
            // Create Debited Company BU.
            debitedCompany = TestDataFactory.createBULegal(false, myCountry);
            insert debitedCompany;
            // Create Store BU.
            storeBU = TestDataFactory.createBUStores(false, country, creditCompany.Id, 1)[0];
            storeBU.Legal_Form__c = creditCompany.Id;
            insert storeBU;          
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    // Insert accounting entry
    @isTest static void InsertAccountingEntry_Success() {
        init();        
        // Insert Accounting Scheme
        Accounting_Scheme__c accountingScheme = TestDataFactory.createAccountingScheme(false, storeBU.Id, creditCompany.Id, debitedCompany.Id, 'Invoices');
        accountingScheme.Amount_Type__c = 'HT';
        accountingScheme.Included_Discount_Types__c = 'Penalties;Rebates';
        accountingScheme.Accounting_Type__c = 'Product';
        insert accountingScheme;        
        // Insert Accounting Closing
        Accounting_Closing__c accountingClosing = TestDataFactory.createAccountingClosing(false, storeBU.Id);
        accountingClosing.Closing_Date__c = System.today();
        accountingClosing.Invoices__c = true;
        accountingClosing.Status__c = 'Preview';
        insert accountingClosing;
        // Insert accounting entry
        Accounting_Entry__c accountingEntry = new Accounting_Entry__c(Entry_Type__c = 'Invoice', Accounting_Closing__c = accountingClosing.Id,
                                                                      Accounting_Scheme_Line__c = accountingScheme.Id, Credited_Company__c = creditCompany.Id, Debited_Company__c = debitedCompany.Id,
                                                                      Entry_Label__c = 'JV ' + ' / Campagne ' + year,
                                                                      Comment__c = '', VAT_rate__c = null, Amount__c = 120, Amount_signed__c = 120,
                                                                      Status__c = accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract'); 
        Test.startTest();
        insert accountingEntry;
        Test.stopTest();
        // Validation Test
        accountingEntry = [SELECT Id, Name, Ext_id__c FROM Accounting_Entry__c];
        System.assertEquals(accountingEntry.Name, accountingEntry.Ext_id__c);
    }
}