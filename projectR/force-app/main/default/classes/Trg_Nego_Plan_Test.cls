@isTest
private class Trg_Nego_Plan_Test {
    
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    
    static void init() {
        try {
            // Create supplier.
        	supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Is_Default_NegoScope__c = true,
	        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
	        insert supplier;
	        // Get the default negoscope created on supplier creation.
	        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
	@isTest static void negoFieldsAssignment_insertCase() {
		init();
 		Nego_Plan__c negoPlan = new Nego_Plan__c(Nego_Scope__c = NS.Id, Nego_Year__c = 2017,
 								NEGO_MOM_RDV1__c = 'aa', NEGO_MOM_RDV2__c = 'bb',
        						NEGO_MOM_RDV3__c = 'cc', NEGO_Keynote_Marketing_Plan__c = 'dd');
        insert negoPlan;
        // Assertions.
        Nego_Plan__c selectedNegoPlan = [SELECT NEGO_MOM_RDV1__c, NEGO_MOM_RDV2__c, NEGO_MOM_RDV3__c, NEGO_Keynote_Marketing_Plan__c
										FROM Nego_Plan__c WHERE Id = :negoPlan.Id];
        System.assertEquals(system.today().format() + '\n' + negoPlan.NEGO_MOM_RDV1__c, selectedNegoPlan.NEGO_MOM_RDV1__c);
        System.assertEquals(system.today().format() + '\n' + negoPlan.NEGO_MOM_RDV2__c, selectedNegoPlan.NEGO_MOM_RDV2__c);
        System.assertEquals(system.today().format() + '\n' + negoPlan.NEGO_MOM_RDV3__c, selectedNegoPlan.NEGO_MOM_RDV3__c);
        System.assertEquals(system.today().format() + '\n' + negoPlan.NEGO_Keynote_Marketing_Plan__c, selectedNegoPlan.NEGO_Keynote_Marketing_Plan__c);
 	}
 	
 	@isTest static void negoFieldsAssignment_updateCase() {
		init();
 		Nego_Plan__c negoPlan = new Nego_Plan__c(Nego_Scope__c = NS.Id, Nego_Year__c = 2017,
 								NEGO_MOM_RDV1__c = 'aa', NEGO_MOM_RDV2__c = 'bb',
        						NEGO_MOM_RDV3__c = 'cc', NEGO_Keynote_Marketing_Plan__c = 'dd');
        insert negoPlan;
        // Assertions.
    	negoPlan.NEGO_MOM_RDV1__c = 'ee';
    	negoPlan.NEGO_MOM_RDV2__c = 'ee';
    	negoPlan.NEGO_MOM_RDV3__c = 'ee';
    	negoPlan.NEGO_Keynote_Marketing_Plan__c = 'ee';
    	update negoPlan;
    	Nego_Plan__c selectedNegoPlan = [SELECT Name, NEGO_MOM_RDV1__c, NEGO_MOM_RDV2__c, NEGO_MOM_RDV3__c, NEGO_Keynote_Marketing_Plan__c
										FROM Nego_Plan__c];
    	// Assertions.
        System.assertEquals(system.today().format() + '\nee', selectedNegoPlan.NEGO_MOM_RDV1__c);
        System.assertEquals(system.today().format() + '\nee', selectedNegoPlan.NEGO_MOM_RDV2__c);
        System.assertEquals(system.today().format() + '\nee', selectedNegoPlan.NEGO_MOM_RDV3__c);
        System.assertEquals(system.today().format() + '\nee', selectedNegoPlan.NEGO_Keynote_Marketing_Plan__c);
 	}
}