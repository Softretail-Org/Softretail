/**
 * Integrity Constraint to test duplication
 * in fields of 'Name' (supplier name) with 'Country_origin__c' (country)
 * and 'Code__c' with 'Country_origin__c'
 * */
@isTest 
private class Trg_Org_Supplier_Test {
	
	private static Integer year;
 	private static Orga_BU__c country1;
 	private static Orga_BU__c country2;
  	
 	static void init() {
 		try {
    		year = System.Today().year();
    		// Add Country
            Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
            insert myCountry;
		    // Create BU Country
		    String cRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
		    country1 = new Orga_BU__c(Name = 'France', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(2016, 1, 1));
		    country1.RecordTypeId =  cRTId;
		    // Create second BU Country
		    country2 = new Orga_BU__c(Name = 'Lebanon', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(2016, 1, 1));
		    country2.RecordTypeId =  cRTId;
		    insert new List<Orga_BU__c>{country1, country2};
	    } catch (Exception ex) {
	        System.debug('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
	        System.debug(ex.getMessage());
	        System.debug(ex.getStackTraceString());
	        System.debug('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<');
		}
    }
     /***
    @isTest static void TestInsertDuplicateSupplierNameAndSameCountry() {
        init();
        // Create BU Country
        Orga_BU__c bu = new Orga_BU__c(Name = 'France', BU_Code__c = 'BU', BU_ODate__c = date.newInstance(2016, 1, 1));
        String objType = new NegoptimBaseController().getFieldName('Orga_BU__c');
        bu.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert bu;
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier1', Country_origin__c = bu.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier1', Country_origin__c = bu.Id, Status_BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_SupplierName_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestInsertDuplicateSupplierNameAndDifferentCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier 001', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier 001', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }

    @isTest static void TestUpdatetDuplicateSupplierNameAndSameCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier 001', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier 002', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.Name = 'Supplier 001';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_SupplierName_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestUpdateDuplicateSupplierNameAndDifferentCountry() {
        init();     
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier 001', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier 002', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.Name = 'Supplier 001';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }***/
    
    @isTest static void TestInsertDuplicateCodeAndSameCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier 001', Country_origin__c = country2.Id,
        						Status_BDate__c = date.today(), Is_Default_NegoScope__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier 002', Country_origin__c = country2.Id,
        						Status_BDate__c = date.today(), Is_Default_NegoScope__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Code_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestUpdatetDuplicateCodeAndSameCountry() {
    	init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier 001', Country_origin__c = country1.Id,
        						Status_BDate__c = date.today(), Is_Default_NegoScope__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier 002', Country_origin__c = country1.Id,
        						Status_BDate__c = date.today(), Is_Default_NegoScope__c = false,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert new List<Sup_Supplier__c>{sup1, sup2};
        sup2.Code__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Code_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    /**
     * Integrity Constraint to test duplication
     * in fields of 'Intracommunity_VAT_Num__c' (supplier name) with 'Country_origin__c' (country)
     * and 'SIREN_Number__c' with 'Country_origin__c'
     * and 'SIRET_Number__c' with 'Country_origin__c'
     * */
     
     /**
     * Intracommunity_VAT_Num__c and Country_origin__c
     **//***
     @isTest static void TestInsertDuplicateIntracommAndSameCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', Intracommunity_VAT_Num__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', Intracommunity_VAT_Num__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Intracomm_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestInsertDuplicateIntracommAndDifferentCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', Intracommunity_VAT_Num__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', Intracommunity_VAT_Num__c = '1', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }

    @isTest static void TestUpdatetDuplicateIntracommAndSameCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', Intracommunity_VAT_Num__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', Intracommunity_VAT_Num__c = '2', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.Intracommunity_VAT_Num__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Intracomm_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestUpdateDuplicateIntracommAndDifferentCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', 
                                                   Name ='Supplier',
                                                   Intracommunity_VAT_Num__c = '1',
                                                   Country_origin__c = country1.Id,
                                                   Status_BDate__c = date.today());
        
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', Intracommunity_VAT_Num__c = '2', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.Intracommunity_VAT_Num__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }
    
    /**
     * SIREN_Number__c and Country_origin__c
     **//***
     @isTest static void TestInsertDuplicateSirenAndSameCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIREN_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIREN_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Siren_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestInsertDuplicateSirenAndDifferentCountry() {
        init();       
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIREN_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIREN_Number__c = '1', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }
	
    @isTest static void TestUpdatetDuplicateSirenAndSameCountry() {
        init();
 
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIREN_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIREN_Number__c = '2', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.SIREN_Number__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Siren_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestUpdateDuplicateSirenAndDifferentCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIREN_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIREN_Number__c = '2', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.SIREN_Number__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }
    
    /**
     * SIRET_Number__c and Country_origin__c
     **//***
     @isTest static void TestInsertDuplicateSiretAndSameCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIRET_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIRET_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Test.startTest();        
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Siret_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestInsertDuplicateSiretAndDifferentCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIRET_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIRET_Number__c = '1', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        Test.startTest();
        Database.SaveResult result = Database.insert(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }

    @isTest static void TestUpdatetDuplicateSiretAndSameCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIRET_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIRET_Number__c = '2', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.SIRET_Number__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Siret_With_CountryOrigin_Already_Exist, result.getErrors()[0].getMessage());
    }
    
    @isTest static void TestUpdateDuplicateSiretAndDifferentCountry() {
        init();
        Sup_Supplier__c sup1 = new Sup_Supplier__c(Code__c = '1', Name ='Supplier', SIRET_Number__c = '1', Country_origin__c = country1.Id, Status_BDate__c = date.today());
        
        Sup_Supplier__c sup2 = new Sup_Supplier__c(Code__c = '2', Name ='Supplier_', SIRET_Number__c = '2', Country_origin__c = country2.Id, Status_BDate__c = date.today());
        insert sup1;
        insert sup2;
        sup2.SIRET_Number__c = '1';
        Test.startTest();
        Database.SaveResult result = Database.update(sup2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assertEquals(0, result.getErrors().size());
    }***/
    
     @isTest static void Test_CreateDefaultNegoscope() {
        init();
        try {
        	Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'New supp 002', Code__c = 'NSUP002',
        								Is_Default_NegoScope__c=true,  Country_origin__c = country1.Id,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            List<Sup_sup_NegoScope__c> negoScope = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id];
            System.assertEquals(1, negoScope.size());
            List<Supplier_NS_HE__c> elementNegoscope = [SELECT Id FROM Supplier_NS_HE__c WHERE Sup_sup_NegoScope__c = :negoScope.get(0).Id];
            System.assertEquals(1, elementNegoscope.size());
        } catch(exception ex){
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
   }
   
    @isTest static void Test_CreateMultiSupplierSameNameDiffCountry() {
    	init();
        try {
        	Sup_Supplier__c supplier1 = new Sup_Supplier__c(Name = 'Nestle', Code__c = 'SN1',Is_Default_NegoScope__c=true, Country_origin__c = country1.Id,
        								Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            Sup_Supplier__c supplier2 = new Sup_Supplier__c(Name = 'Nestle', Code__c = 'SN2',Is_Default_NegoScope__c=true, Country_origin__c = country2.Id,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert new List<Sup_Supplier__c>{supplier1, supplier2};
            List<Sup_sup_NegoScope__c> negoScope = [SELECT Id FROM Sup_sup_NegoScope__c];
            System.assertEquals(2, negoScope.size());
	    } catch(exception ex){
	        System.debug('++++++++++++++++++++++++++++++'); 
	        System.debug(ex.getMessage() ); 
	        System.debug(ex.getStackTraceString() );
	        System.debug('++++++++++++++++++++++++++++++');
	    }
   }
    
    @isTest static void TestAdressManagement() {
        init();
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Nestle', Code__c = 'SN2', 
        						Is_Default_NegoScope__c = true,  Acc_Address1__c = 'UAE 1', Admin_Address1__c = 'UAE 2',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        Sup_sup_NegoScope__c negoScope = [SELECT Id,Acc_Address1__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id];
        negoScope.Admin_Address_External_Synchro__c = true;
        negoScope.Acc_Address_External_Synchro__c = true;
        update negoScope;
        supplier.Acc_Address1__c = 'UAE';
        update supplier;
        Sup_sup_NegoScope__c selectedNS = [SELECT Id,Acc_Address1__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id];
        System.assertEquals(supplier.Acc_Address1__c, selectedNS.Acc_Address1__c);
    }
    
      @isTest static void TestMultyAdressManagement() {
        init();
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Nestle', Code__c = 'SN2',Is_Default_NegoScope__c=true,
        						Country_origin__c = country2.Id, Acc_Address1__c = 'UAE 1', Admin_Address1__c = 'UAE 2',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        Sup_Supplier__c supplier2 = new Sup_Supplier__c(Name = 'Coca', Code__c = 'SN3',Is_Default_NegoScope__c=true,
								Country_origin__c = country2.Id, Acc_Address1__c = 'UAE 3', Admin_Address1__c = 'UAE 4',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert new List<Sup_Supplier__c> {supplier, supplier2};
        supplier.Name = 'Updated Nestle';
        supplier2.Name = 'Updated Coca';
        update new List<Sup_Supplier__c> {supplier, supplier2};
        Sup_sup_NegoScope__c negoScope = [SELECT Id,Acc_Address1__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id];
        Sup_sup_NegoScope__c negoScope2 = [SELECT Id,Acc_Address1__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier2.Id];
        negoScope.Admin_Address_External_Synchro__c = true;
        negoScope.Acc_Address_External_Synchro__c = true;
        negoScope2.Admin_Address_External_Synchro__c = true;
        negoScope2.Acc_Address_External_Synchro__c = true;
        update new List<Sup_sup_NegoScope__c> {negoScope, negoScope2};
        
        supplier.Acc_Address1__c = 'UAE 5';
        supplier2.Acc_Address1__c = 'UAE 6';
        update new List<Sup_Supplier__c> {supplier, supplier2};
        
        Sup_sup_NegoScope__c selectedNS = [SELECT Id,Acc_Address1__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier.Id];
        Sup_sup_NegoScope__c selectedNS2 = [SELECT Id,Acc_Address1__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplier2.Id];
        
        System.assertEquals(supplier.Acc_Address1__c,selectedNS.Acc_Address1__c);
        System.assertEquals(supplier2.Acc_Address1__c,selectedNS2.Acc_Address1__c);
    }
    
    @isTest static void processBuilder() {
    	Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'Nestle', Code__c = 'SN2', Is_Default_NegoScope__c = true,
    									Acc_Address_External_Synchro__c = true, Admin_Address_External_Synchro__c = true,
    									Ref_Address1__c = 'UAE', Acc_Address1__c = 'UAE', Admin_Address1__c = 'UAE');
        insert supplier;
        supplier.Ref_Address1__c = 'aa';
        update supplier;
        Sup_Supplier__c supp = [SELECT Acc_Address1__c, Admin_Address1__c FROM Sup_Supplier__c];
        System.assertEquals(supplier.Ref_Address1__c, supp.Acc_Address1__c);
        System.assertEquals(supplier.Ref_Address1__c, supp.Admin_Address1__c);
    }
    
    // When supplier status end date__c is greater than the current date, and status is close, then status = active;
    static testmethod void statusMod() {
    	init();
    	Date now = Date.newinstance(System.now().year(), System.now().month(), System.now().day()+1);
    	// Create active supplier.
        Sup_Supplier__c supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Close', Country_origin__c = country1.Id,
        						Status_EDate__c = date.newInstance(year, 3, 3),
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        supplier.Status_EDate__c = now;
        update supplier;
        // Assertion.
        Sup_Supplier__c selectedSupplier = [SELECT Status__c FROM Sup_Supplier__c];
        System.assertEquals('Active', selectedSupplier.Status__c);
    }
}