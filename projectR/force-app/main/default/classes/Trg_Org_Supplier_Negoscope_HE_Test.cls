/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for He 
 **/
 
@isTest
private class Trg_Org_Supplier_Negoscope_HE_Test {
    
    private static Id rootId;
    private static String currencyIsoCode;
    private static Sup_Supplier__c supplier1;
    private static Sup_sup_NegoScope__c negoScope1;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Supplier__c supplier2;
    private static Sup_sup_NegoScope__c negoScope2;
    private static Supplier_NS_HE__c NSHE;
    private static Supplier_NS_HE__c NSHE2;
    private static Integer year;
    
    static void init() {
    	try{
    		year = System.Today().year();
	        // Create HE root.
			rootId = NegoptimHelper.getRootId();
			// Get the Corporate Currency.
			currencyIsoCode = NegoptimHelper.getCorporateCurrency();
	        // Create department.
	        department = new Orga_HE__c(Name = 'Consumer Goods', Elt_Code__c = 'Elt Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1));
	        insert department;
	        // Create section.
	        section = new Orga_HE__c(Name = 'Beverages', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1));
	        insert section;
	        // Create supplier.
	        supplier1 = new Sup_Supplier__c(Name = 'Nestle', Code__c = 'Nestle', Is_Default_NegoScope__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
	        insert supplier1;
	        // Get the default negoscope created on supplier creation.
	        negoScope1 = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier1.Id LIMIT 1];
    	} catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Single insertion: success case.
    @isTest static void insertNSHE_success() {
    	init();
    	// Create NS HE.
        NSHE = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope1.Id, Structure_Element__c = section.Id);
        Test.startTest();
        Database.SaveResult result = Database.insert(NSHE, false);
        Test.stopTest();
        Integer countNSHE = [SELECT Count() FROM Supplier_NS_HE__c];
        System.assert(result.isSuccess());
        System.assertEquals(2, countNSHE);
    }
    
    // Single insertion: fail case.
    @isTest static void insertNSHE_failed() {
    	init();
    	// Create NS HE.
        NSHE = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope1.Id, Structure_Element__c = section.Id);
        insert NSHE;
        NSHE2 = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope1.Id, Structure_Element__c = section.Id);        
        Test.startTest();
        Database.SaveResult result = Database.insert(NSHE2, false);
        Test.stopTest();
        Integer countNSHE = [SELECT Count() FROM Supplier_NS_HE__c];
        System.assert(!result.isSuccess());
        System.assertEquals(2, countNSHE);
    }
    
    // Bulk insertion: success case.
    @isTest static void insertNSHE_sucessBulk() {
    	init();
        // Create second supplier.
        supplier2 = new Sup_Supplier__c(Name = 'Nestle2', Code__c = 'Nestle2', Is_Default_NegoScope__c = true,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier2;
        // Get the default negoscope created on supplier creation.
        negoScope2 = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier2.Id LIMIT 1];
    	// Create sections.
    	List<Orga_HE__c> sections = new List<Orga_HE__c>();
    	for (Integer i = 1 ; i <= 80 ; i++) {
	        section = new Orga_HE__c(Name = 'Beverages' + i, Elt_Code__c = 'Elt Code' + i, Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1));
    		sections.add(section);
    	}
        insert sections;
        List<Supplier_NS_HE__c> NSHEs = new List<Supplier_NS_HE__c>();
        for (Orga_HE__c sec1 : sections) {
        	// Create NS HE.
        	NSHE = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope1.Id, Structure_Element__c = sec1.Id);
        	NSHEs.add(NSHE);
        }
        for (Orga_HE__c sec2 : sections) {
        	// Create NS HE.
        	NSHE = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope2.Id, Structure_Element__c = sec2.Id);
        	NSHEs.add(NSHE);
        }
        Test.startTest();        
        List<Database.SaveResult> results = Database.insert(NSHEs, false); 
        Test.stopTest();
        for (Database.SaveResult result : results) {
        	System.assert(result.isSuccess());
        }
        Integer countNSHE = [SELECT Count() FROM Supplier_NS_HE__c];
        System.assertEquals(2 + 160, countNSHE);
    }
    
    // Bulk insertion: fail case.
    @isTest static void insertNSHE_failedBulk() {
    	init();
        NSHE = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope1.Id, Structure_Element__c = department.Id);
		NSHE2 = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope1.Id, Structure_Element__c = section.Id);
        Supplier_NS_HE__c NSHE3 = new Supplier_NS_HE__c(Sup_sup_NegoScope__c = negoScope1.Id, Structure_Element__c = section.Id);
        List<Supplier_NS_HE__c> NSHEs = new List<Supplier_NS_HE__c>();
        NSHEs.add(NSHE);
        NSHEs.add(NSHE2);
        NSHEs.add(NSHE3);
        Test.startTest();
        List<Database.Saveresult> results = Database.insert(NSHEs, false);
        Test.stopTest();
		for (Database.SaveResult result : results) {
            if(!result.isSuccess()) {
            	System.assert(result.getErrors().size() > 0);
            }
		}
        Integer countNSHE = [SELECT Count() FROM Supplier_NS_HE__c];
        System.assertEquals(3, countNSHE);
    }
}