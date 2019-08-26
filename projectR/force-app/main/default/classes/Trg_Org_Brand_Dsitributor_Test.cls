/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers of brand distributor .
 */
@isTest
private class Trg_Org_Brand_Dsitributor_Test {
	
    private static Integer year;
    private static Id root;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier1;
    private static Sup_Supplier__c supplier2;
    private static Sup_Supplier__c supplier3;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Sup_Brand__c brand1;
    private static Sup_Brand__c brand2;
    private static Supplier_PG_Mapping__c pg1;
    private static Supplier_PG_Mapping__c pg2;
    
    static void init() {
    	try {
            year = System.Today().year();
            // root Element
            root = NegoptimHelper.getRootId();
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
            // Create Suppliers
            supplier1 = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', Country_origin__c = country.Id, Status__c = 'Active',
        						Is_Default_NegoScope__c = true, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            supplier2 = new Sup_Supplier__c(Name = 'Supplier 002', Code__c = 'SUP002', Country_origin__c = country.Id, Status__c = 'Active',
        						Is_Default_NegoScope__c = false, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            supplier3 = new Sup_Supplier__c(Name = 'Supplier 003', Code__c = 'SUP003', Country_origin__c = country.Id, Status__c = 'Active',
        						Is_Default_NegoScope__c = false, Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert new List<Sup_Supplier__c> {supplier1, supplier2, supplier3};
            // Get the default NegoScope created on supplier creation
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier1.Id LIMIT 1];
            // Create Department
            department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Elt Code 1', Parent_Element__c = root, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1));
            insert department;
            // Create Section        
            section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1));
            insert section;
            // Create Brand that automatically related to NS due to trigger
            brand1 = new Sup_Brand__c(Name = supplier1.Name + ' Brand 1', Brand_Owner__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
    		brand2 = new Sup_Brand__c(Name = supplier2.Name + ' Brand 2', Brand_Owner__c = supplier2.Id, Status_BDate__c = date.newInstance(year, 1, 1));
    		insert new List<Sup_Brand__c> {brand1, brand2};
            // Create PG that automatically related to NS due to trigger
            pg1 = new Supplier_PG_Mapping__c(Name = supplier1.Name + ' PG 1', Brand__c = brand1.Id, SNA_Code__c = '1', GIMA_Code__c = '1', Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier1.Id);
            pg2 = new Supplier_PG_Mapping__c(Name = supplier2.Name + ' PG 2', Brand__c = brand2.Id, SNA_Code__c = '2', GIMA_Code__c = '2', Department__c = department.Id, Section__c = section.Id,  Supplier__c = supplier2.Id);																				   
            insert new List<Supplier_PG_Mapping__c> {pg1, pg2};
    	  } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }

	/*
     * Test validation on deletion of brand distribution from brand page   
     */
    @isTest static void test_deleteBrandDistribution() {
    	init();
        Sup_Bra_Distributor__c selectBrandDistributor = [SELECT id FROM Sup_Bra_Distributor__c WHERE Brand__c = :brand1.Id];
        Test.startTest();
        Database.DeleteResult result = Database.delete(selectBrandDistributor, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Cant_Delete_Brand, result.getErrors()[0].getMessage());
    }
    
	/*
     * Test validation on deletion of multi brand distribution from brand page   
     */
    @isTest static void test_deleteMultiBrandDistribution() {
    	init();
        List<Sup_Bra_Distributor__c> brandDistList = new List<Sup_Bra_Distributor__c>();
        Sup_Bra_Distributor__c selectDistributor = [SELECT id FROM Sup_Bra_Distributor__c WHERE Brand__c = :brand1.Id];
        Sup_Bra_Distributor__c selectDistributor2 = [SELECT id FROM Sup_Bra_Distributor__c WHERE Brand__c = :brand2.Id];
        brandDistList.add(selectDistributor);
        brandDistList.add(selectDistributor2);
        Test.startTest();
        List<Database.DeleteResult> deleteResults = Database.delete(brandDistList, false);
        Test.stopTest();
        for (Database.DeleteResult result : deleteResults) {
            if(!result.isSuccess()){
                System.assert(result.getErrors().size() > 0);
                System.assertEquals(System.Label.MSG_Cant_Delete_Brand, result.getErrors()[0].getMessage());
            }
        }
    }
    
    /*
     * Test Validate if a distributor supplier is already linked to a brand
     */
    @isTest static void test_supplierAlreadyLinkedOnCreate() {
    	init();
        Sup_Bra_Distributor__c brandDist = new Sup_Bra_Distributor__c(Name = supplier1.Name + 'New Brand dist', Brand__c = brand1.Id,Supplier__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        Test.startTest();
        Database.SaveResult result = Database.insert(brandDist, false);
        Test.stopTest();
        Boolean expectedError = result.getErrors()[0].getMessage().contains('Please cancel or choose another Supplier !') ? true : false;
        System.assertEquals(true,expectedError);
    }
    
 	/*
     * Test Validate if a distributor supplier is already linked to a brand on update
     */
    @isTest static void test_supplierAlreadyLinkedOnUpdate() {
    	init();
        Sup_Bra_Distributor__c brandDist = new Sup_Bra_Distributor__c(Name = supplier1.Name + 'New Brand dist', Brand__c = brand1.Id,Supplier__c = supplier2.Id, Status_BDate__c = date.newInstance(year, 1, 1));
		insert brandDist;
        Sup_Bra_Distributor__c selectDistributor = [SELECT id FROM Sup_Bra_Distributor__c WHERE Brand__c = :brand1.Id AND Supplier__c = :supplier2.Id];
       	selectDistributor.Supplier__c = supplier1.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(selectDistributor, false);
        Test.stopTest();
        Boolean expectedError = result.getErrors()[0].getMessage().contains('Please cancel or choose another Supplier !') ? true : false;
        System.assertEquals(true,expectedError);
    }
  	
  	/*
     * Test Validate if a distributor supplier is already linked to a brand
     */
    @isTest static void test_supplierAlreadyLinkedOnMultiCreate() {
    	init();
        List<Sup_Bra_Distributor__c> lstBrandDist = new List<Sup_Bra_Distributor__c>();
        Sup_Bra_Distributor__c brandDist = new Sup_Bra_Distributor__c(Name = supplier1.Name + 'New Brand dist', Brand__c = brand1.Id,Supplier__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        Sup_Bra_Distributor__c brandDist2 = new Sup_Bra_Distributor__c(Name = supplier1.Name + 'New Brand dist 2', Brand__c = brand1.Id,Supplier__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        Sup_Bra_Distributor__c brandDist3 = new Sup_Bra_Distributor__c(Name = supplier1.Name + 'New Brand dist 3', Brand__c = brand2.Id,Supplier__c = supplier1.Id, Status_BDate__c = date.newInstance(year, 1, 1));
        lstBrandDist.add(brandDist);
        lstBrandDist.add(brandDist2);
        lstBrandDist.add(brandDist3);
        Test.startTest();
        List<Database.Saveresult>  insertResults = Database.insert(lstBrandDist, false);
        Test.stopTest();
        for (Database.SaveResult result : insertResults) {
        	if(!result.isSuccess()){
           		 Boolean expectedError = result.getErrors()[0].getMessage().contains('Please cancel or choose another Supplier !') ? true : false;
           		 System.assertEquals(true,expectedError);
			}
		}
    }
}