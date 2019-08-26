/**
 * @Description Test class that verify whether the particular piece of code on CloseSupplierBatch is working properly.
 **/
@isTest
private class CloseSupplierBatchTest {
    
    private static final Integer year = TestDataFactory.year;
    private static Orga_BU__c country;
    
    static void init() {
    	try {
	    	// Insert Country List.
	        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	    	// Insert Region.
	        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
	    	// Insert Country.
	        country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // When supplier status end date__c is smaller or equal the current date.
    static testmethod void uTest1_changingCase() {
    	init();
    	// Insert supplier.
		Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
		supplier.Status_BDate__c = date.newInstance(year, 1, 1);
		supplier.Status_EDate__c = date.today() - 1;
        insert supplier;
        // Start test.
		Test.startTest();
        Database.executeBatch(new CloseSupplierBatch('Test', country.Id));
        Test.stopTest();
        // Assertion.
        Sup_Supplier__c selectedSupplier = [SELECT Status__c FROM Sup_Supplier__c];
        System.assertEquals('Close', selectedSupplier.Status__c);
    }
    
    // When supplier status end date__c is greater than the current date.
    static testmethod void uTest2_unchangingCase() {
    	init();
    	// Insert supplier.
		Sup_Supplier__c supplier = TestDataFactory.createSupplier(false, country, true);
		supplier.Status_BDate__c = date.today() - 1;
		supplier.Status_EDate__c = date.today() + 1;
        insert supplier;
        // Start test.
		Test.startTest();
        Database.executeBatch(new CloseSupplierBatch('Test', country.Id));
        Test.stopTest();
        // Assertion.
        Sup_Supplier__c selectedSupplier = [SELECT Status__c FROM Sup_Supplier__c];
        System.assertEquals('Active', selectedSupplier.Status__c);
    }
}