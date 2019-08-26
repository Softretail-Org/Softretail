/**
 * @Description Test class that verify whether the particular piece of code on CustomLookupController is working properly.
 **/
@isTest
private class CustomLookupControllerTest {

    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_BU__c country;
    
    static void init() {
    	try {
	    	// Insert Country List.
	        Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
	    	// Insert Region.
	        Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
	    	// Insert Country.
	        country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
	    	// Insert supplier.
		    supplier = TestDataFactory.createSupplier(false, country, true);
		    supplier.NS_Name_Autonum__c = 0;
		    insert supplier;
		    // Get the default negoscope created on supplier creation.
		    NS = TestDataFactory.getNSs(supplier.Id)[0];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    @isTest static void uTest1_testNSLoopup() {
        init();
        ApexPages.currentPage().getParameters().put('suppId', supplier.Id);
        ApexPages.currentPage().getParameters().put('case','productscope');
        ApexPages.currentPage().getParameters().put('negoId', NS.Id);
        
        CustomLookupController customLookup = new CustomLookupController();
        customLookup.search();
        System.assertEquals(1, customLookup.results.size());
    }
    
    @isTest static void uTest2_testNSLoopupWithSearch() {
        init();
        ApexPages.currentPage().getParameters().put('suppId', supplier.Id);
        ApexPages.currentPage().getParameters().put('case','productscope');
        
        CustomLookupController customLookup = new CustomLookupController();
        customLookup.searchString = 'Negoscope';
        customLookup.search();
        System.assertEquals(1, customLookup.results.size());
    }
    
    @isTest static void uTest3_testTariffCondLoopup() {
        init();
        // Insert contract;
	    Contract__c contract = TestDataFactory.createContract(false, NS, date.newInstance(2016, 2, 1), date.newInstance(2016, 6, 1));
	    contract.Duration_type__c = 'Month';
	    insert contract;
	    // Insert Policy - Tariff condition.
		Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
        insert tariffCondition;
        
        ApexPages.currentPage().getParameters().put('case','tarifflookup');
        ApexPages.currentPage().getParameters().put('buId', country.Id);
        //ApexPages.currentPage().getParameters().put('conditionType', plv);
        
        CustomLookupController customLookup = new CustomLookupController();
        customLookup.search();
        System.assertEquals(1, customLookup.resultsTariff.size());        
    }
    
    @isTest static void uTest4_testTariffCondLoopupWithSearch() {
        init();
        ApexPages.currentPage().getParameters().put('case','tarifflookup');
        ApexPages.currentPage().getParameters().put('buId', NS.Id);
        
        CustomLookupController customLookup = new CustomLookupController();
        customLookup.searchString = 'Condition';
        customLookup.search();
        System.assertEquals(0, customLookup.resultsTariff.size());
    }
    
    @isTest static void uTest5_testClearSearch() {
        init();
        ApexPages.currentPage().getParameters().put('suppId', supplier.Id);
        ApexPages.currentPage().getParameters().put('case','productscope');
        ApexPages.currentPage().getParameters().put('negoId', NS.Id);
        
        CustomLookupController customLookup = new CustomLookupController();
        customLookup.search();
        customLookup.clearSearch();
        System.assertEquals(1, customLookup.results.size());
    }
}