/* (1) MAF1.6 Update Format list detail when store creation
 * (2) MAF1.5 Update Country list detail when store / Web / DC creation
 * (3) MAF21.2 List can't be close if active contract
 * (4) MAF17.1 Country can change his allocation country zone if no contract as been defined to its country zone
 * (5) MAF15.5 Update Country detail list when  status begin open
 * (6) MAF16.2 Close Country will close all linked Stores / DC / Web / List
 */
 
@isTest
public with sharing class Trg_Org_Orga_BU_Test {
	
	private static Orga_BU__c country;
	private static Orga_BU__c countryBU2;
	private static Orga_BU__c listBU;
	private static Orga_BU__c listBU2;
    private static Orga_BU__c supermarketListBU;
    private static Orga_BU__c hyperSuperListBU;
	private static Orga_BU__c legal;
	private static Orga_BU__c storeBU;
    private static Orga_BU__c supermarketStoreBU;
    private static Orga_BU__c hyperSuperstoreBU;
	//private static Integer year = 2017;
	private static Orga_BU__c webBU;
	private static Orga_BU__c warehouseBU;
	private static Sup_Supplier__c supplier;
	private static Contract__c contract;
	private static Pol_Com_Condition__c tariffCondition;
	private static Contract_Discount__c condition;
	private static Invoice__c invoice;
	private static Orga_BU__c regionBU;
	
	private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c region1;
    private static Orga_BU__c region2;
    private static Orga_BU__c store;
    private static Integer year = System.Today().year();
    private static Integer month = System.Today().month();
    private static Id rootId;
    private static Orga_BU__c masterBU;
    private static Orga_BU__c buList;
    private static Orga_BU__c buBanner1;
    private static Orga_BU__c buBanner2;
    private static Orga_BU__c cluster1;
    private static Orga_BU__c cluster2;
    private static Orga_BU__c cluster3;
    private static Sup_Supplier__c client;
    private static Sup_sup_NegoScope__c NS;
    private static Orga_HE__c department;
    private static Orga_HE__c category;
    private static Sup_Brand__c brand;
    private static Product2 product;

    // Hyp: Country BU.
    // Eq: Creation of a Store BU related to the Country BU => Add a BU List Detail related to the Country BU.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void createStoreBU1() {
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
        // Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
		// Create Store
        storeBU = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        storeBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails.size());
    }
    
    // Hyp: Country BU - List BU is related to the Country BU and having format origin.
	// Eq: Creation of a Store BU related to a Country BU and having the same format origin
	//		=> (Add a BU List Detail related to the Country BU) AND (Add a BU List Detail related to the List BU)
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void createStoreBU2() {
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
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1), Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
		// Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
		// Create Store
        storeBU = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        storeBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
    }
    
    // Hyp: Country BU - List BU is related to the Country BU and having format origin.
	// Eq: Creation of a Store BU related to a Country BU and having different format origin 
	//		=> Add a BU List Detail related to the Country BU
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void createStoreBU3() {
    	// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Hypermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
        // Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
		// Create store BU.
        storeBU = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1), Country_origin__c = country.Id, Format_Origin__c = 'Supermarket', Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        storeBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: storeBU.Id];
        // List of BU List Details which is related to the List BU.
        List<Orga_BU_List_Detail__c> BUListDetails2 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: listBU.Id AND Entity_List__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
    }
    
    // Hyp: Country BU.
    // Eq: Creation of a Web BU related to the Country BU => Add a BU List Detail related to the Country BU.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void createWebBU1() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
		// Create web BU.
        webBU = new Orga_BU__c(Name = 'Bu Khalil', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1),
								Country_origin__c = country.Id);
        webBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Web');
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(webBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: webBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails.size());
    }
    
    // Hyp: Country BU - List BU is related to the Country BU and having format origin.
	// Eq: Creation of a Web BU related to a Country BU (format origin is insubstantial)
	//		=> Add a BU List Detail related to the Country BU only.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void createWebBU2() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
		// Create web BU.
        webBU = new Orga_BU__c(Name = 'Bu Khalil', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country.Id, Format_Origin__c = 'Supermarket');
        webBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Web');
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(webBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: webBU.Id];
        // List of BU List Details which is related to the List BU.
        List<Orga_BU_List_Detail__c> BUListDetails2 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: listBU.Id AND Entity_List__c =: webBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
    }
    
    // Hyp: Country BU - List BU is related to the Country BU.
    // Eq: Creation of a Warehouse BU related to the Country BU => Add a BU List Detail related to the Country BU only.
    // NB: This piece of code covers addBUListDetail method on after insert.
    @isTest static void createWarehouseBU() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
		// Create warehouse BU.
        warehouseBU = new Orga_BU__c(Name = 'Bu Khalil', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1),
								Country_origin__c = country.Id);
        warehouseBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Warehouse');
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.insert(warehouseBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: warehouseBU.Id];
        // List of BU List Details which is related to the List BU.
        List<Orga_BU_List_Detail__c> BUListDetails2 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: listBU.Id AND Entity_List__c =: warehouseBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
    }
    
    // Hyp:
    // 		- Country BU: country , Country BU: countryBU2
    // 		- List BU related to the Country BU and having format origin
    // 		- Store BU related to the Country BU
	// 		- BU List Detail related to the Country BU (as child)
	// 		- BU List Detail related to the List BU (as child)
	// 		- Two BU List Details related to the Store BU (as parents)
	// Eq: Modify the Store BU in which it will be related to another Country BU
	//		=> (Remove BU List Detail which is related to the initial Country BU)
	//			AND (Remove BU List Detail which is related to the List BU)
	//			AND (Add a BU List Detail related to the new Country BU)
	// 			AND (Add a BU List Detail (parent) related to the Store BU)
    // NB: This piece of code covers modifyBUListDetail method on after insert.
    @isTest static void updateStoreBU1() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        String cRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = cRTId;
        // Create second country BU.
        countryBU2 = new Orga_BU__c(Name = 'CANADA', BU_Code__c = 'codeBU 004', BU_ODate__c = date.newInstance(year, 1, 1));
        countryBU2.RecordTypeId = cRTId;
        insert new List <Orga_BU__c>{country, countryBU2};
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
        // Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
		// Create store BU.
        storeBU = new Orga_BU__c(Name = 'Bu Khalil', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        storeBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert storeBU;
        storeBU.Country_origin__c = countryBU2.Id;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: storeBU.Id];
        // List of BU List Details which is related to the List BU.
        List<Orga_BU_List_Detail__c> BUListDetails2 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: listBU.Id AND Entity_List__c =: storeBU.Id];
        // List of BU List Details which is related to the second Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails3 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: countryBU2.Id AND Entity_List__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(0, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
        System.assertEquals(1, BUListDetails3.size());
    }
    
    // Hyp:
    // 		- Country BU: country , Country BU: countryBU2
    // 		- List BU related to country and having a format origin , second List BU related to countryBU2 and having a format origin
    // 		- Store BU related to country and had the same format origin of the second List BU
	// 		- BU List Detail related to the Country BU (as child)
	// 		- BU List Detail related to the List BU (as child)
	// 		- Two BU List Details related to the Store BU (as parents)
	// Eq: Modify the Store BU in which it will be related to another Country BU
	//		=> (Remove BU List Detail which is related to the initial Country BU)
	//			AND (Remove BU List Detail which is related to the List BU)
	//			AND (Add a BU List Detail related to the new Country BU)
	// 			AND (Add a BU List Detail (parent) related to the Store BU)
    // NB: This piece of code covers modifyBUListDetail method on after insert.
    @isTest static void updateStoreBU2() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        String cRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = cRTId;
        // Create second country BU.
        countryBU2 = new Orga_BU__c(Name = 'CANADA', BU_Code__c = 'codeBU 004', BU_ODate__c = date.newInstance(year, 1, 1));
        countryBU2.RecordTypeId = cRTId;
        insert new List <Orga_BU__c>{country, countryBU2};
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
        // Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
		// Create store BU.
        storeBU = new Orga_BU__c(Name = 'Bu Khalil', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country.Id, Format_Origin__c = 'Supermarket', Country__c = myCountry.Name,
                            	Legal_Form__c = legal.Id);
        storeBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert storeBU;
        // Create second list BU.
        listBU2 = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 005', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = countryBU2.Id);
        listBU2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU2;
        storeBU.Country_origin__c = countryBU2.Id;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(storeBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: storeBU.Id];
        // List of BU List Details which is related to the List BU.
        List<Orga_BU_List_Detail__c> BUListDetails2 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: listBU.Id AND Entity_List__c =: storeBU.Id];
        // List of BU List Details which is related to the second Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails3 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: countryBU2.Id AND Entity_List__c =: storeBU.Id];
        // List of BU List Details which is related to the second List BU.
        List<Orga_BU_List_Detail__c> BUListDetails4 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: listBU2.Id AND Entity_List__c =: storeBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(0, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
        System.assertEquals(1, BUListDetails3.size());
        System.assertEquals(1, BUListDetails4.size());
    }
    
    // Web - Country_origin__c
    @isTest static void updateWebBU() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        String cRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = cRTId;
        // Create second country BU.
        countryBU2 = new Orga_BU__c(Name = 'CANADA', BU_Code__c = 'codeBU 004', BU_ODate__c = date.newInstance(year, 1, 1));
        countryBU2.RecordTypeId = cRTId;
        insert new List<Orga_BU__c>{country, countryBU2};
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
		// Create store BU.
        webBU = new Orga_BU__c(Name = 'Web', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country.Id, Format_Origin__c = 'Supermarket');
        webBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Web');
        insert webBU;
        webBU.Country_origin__c = countryBU2.Id;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(webBU, false);
        Test.stopTest();
        // List of BU List Details which is related to the Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: country.Id AND Entity_List__c =: webBU.Id];
        // List of BU List Details which is related to the List BU.
        List<Orga_BU_List_Detail__c> BUListDetails2 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: listBU.Id AND Entity_List__c =: webBU.Id];
        // List of BU List Details which is related to the second Country BU.
        List<Orga_BU_List_Detail__c> BUListDetails3 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c =: countryBU2.Id AND Entity_List__c =: webBU.Id];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(0, BUListDetails1.size());
        System.assertEquals(0, BUListDetails2.size());
        System.assertEquals(1, BUListDetails3.size());
    }
    
    // (3) Closed constraint related to  Contract__c, Contract_Discount__c, Invoice__c on Country BU
    // Hyp:
    // 		- Country BU: country
    // 		- Supplier which is related to the Country BU
    // 		- Contract which is related to the Country BU
	// Eq: Contract is related to a Country BU => Country BU cannot be closed.
    // NB: This piece of code covers closedBUEvent method on after insert.
    @isTest static void closeCountryBUInRelationWithContract() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create contract.
        contract = new Contract__c(Name ='Nestle Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Contract_BU__c = country.Id);
        insert contract;
        country.Status__c = 'Closed';
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();
        // Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractRelation);
    }
    
    // Hyp:
    // 		- Country BU: country
    // 		- Supplier which is related to the Country BU
    // 		- Contract
    //		- Condition which is related to the Country BU
	// Eq: Condition is related to a Country BU => Country BU cannot be closed.
    // NB: This piece of code covers closedBUEvent method on after insert.
    @isTest static void closeCountryBUInRelationWithCondition() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create contract.
        contract = new Contract__c(Name ='Nestle Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31));
        insert contract;
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                   Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                   Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 800, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
		insert condition;
        country.Status__c = 'Closed';
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();
        // Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractDetailsRelation);
    }
    
    // Hyp:
    // 		- Country BU: country
    // 		- Supplier which is related to the Country BU
    // 		- Contract
    //		- Invoice which is related to the Country BU
	// Eq: Invoice is related to a Country BU => Country BU cannot be closed.
    // NB: This piece of code covers closedBUEvent method on after insert.
    @isTest static void closeCountryBUInRelationWithInvoice() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create contract.
        contract = new Contract__c(Name ='Nestle Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31));
        insert contract;
        // Create Invoice
        invoice = new Invoice__c(Inv_Date__c = date.newInstance(2017, 8, 31), Inv_Supplier__c = supplier.Id, Inv_Business_Unit__c = country.Id,
        							Sequence_Number__c = 8, Inv_FiscalYear__c = 2017, Status_BDate__c = date.newInstance(2017, 8, 31));
        insert invoice;
        country.Status__c = 'Closed';
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();
        // Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Cannot_Choose_CloseStatus_InvoiceRelation);
    }
    
    // Hyp:
    // 		- Country BU: country
    //		- List BU: listBU
    // 		- Supplier which is related to the Country BU
    // 		- Contract which is related to the Country BU
	// Eq: Contract is related to a List BU => List BU cannot be closed.
    // NB: This piece of code covers closedBUEvent method on after insert.
    @isTest static void closeListBUInRelationWithContract() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create contract.
        contract = new Contract__c(Name ='Nestle Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Contract_BU__c = country.Id);
        insert contract;
        listBU.Status__c = 'Closed';
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(listBU, false);
        Test.stopTest();
        // Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractRelation);
    }
    
    // Hyp:
    // 		- Country BU: country
    //		- List BU: listBU    
    // 		- Supplier which is related to the Country BU
    // 		- Contract
    //		- Condition which is related to the Country BU
	// Eq: Condition is related to a Country BU => List BU cannot be closed.
    // NB: This piece of code covers closedBUEvent method on after insert.
    @isTest static void closeListBUInRelationWithCondition() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create contract.
        contract = new Contract__c(Name ='Nestle Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Contract_BU__c = country.Id);
        insert contract;
        // Create Policy - Tariff conditions.
        Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
        String plv = fieldResult.getPicklistValues().get(0).getValue();
        tariffCondition = new Pol_Com_Condition__c(Name = plv, Nego_Discount_Type__c = plv, Status_BDate__c = date.newInstance(year, 1, 1), Condition_Code__c = 'C1',
                                                   Abrev__c = 'Cond.', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ', Name_Fi__c = 'Fi ',
                                                   Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create conditions.
        condition = new Contract_Discount__c(Nego_Discount_Type__c = plv, Condition_Type__c = tariffCondition.Id, Disc_BDate__c = date.newInstance(year, 1, 1),
                                             Disc_EDate__c = date.newInstance(year, 12, 31), Value_amt__c = 800, Product_Scope__c = NS.Id,
                                             BU_Scope__c = country.Id, Contract__c = contract.Id);        
		insert condition;
        listBU.Status__c = 'Closed';
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(listBU, false);
        Test.stopTest();
        // Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Cannot_Choose_CloseStatus_ContractDetailsRelation);
    }
    
    // Hyp:
    // 		- Country BU: country
    // 		- Supplier which is related to the Country BU
    // 		- Contract
    //		- Invoice which is related to the Country BU
	// Eq: Invoice is related to a Country BU => List BU cannot be closed.
    // NB: This piece of code covers closedBUEvent method on after insert.
    @isTest static void closeListBUInRelationWithInvoice() {
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create contract.
        contract = new Contract__c(Name ='Nestle Contract', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id,
                                   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   Contract_BU__c = country.Id);
        insert contract;
        // Create Invoice.
        invoice = new Invoice__c(Inv_Date__c = date.newInstance(2017, 8, 31), Inv_Supplier__c = supplier.Id, Inv_Business_Unit__c = country.Id,
        							Sequence_Number__c = 8, Inv_FiscalYear__c = 2017, Status_BDate__c = date.newInstance(2017, 8, 31));
        insert invoice;
        listBU.Status__c = 'Closed';
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(listBU, false);
        Test.stopTest();
        // Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Cannot_Choose_CloseStatus_InvoiceRelation);
    }
        
    // Cannot detach a country zone origin (Region) in which a contract is related to it.
    @isTest static void countryZoneOriginInRelationWithContract() {
        // Create region BU.
        regionBU = new Orga_BU__c(Name = 'West Asia', BU_Code__c = 'AS', BU_ODate__c = date.newInstance(year, 1, 1));
        regionBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
        insert regionBU;
        // Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        country.Country_Zone_origin__c = regionBU.Id;
        insert country;
        // Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = 'EUR',
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        Sup_sup_NegoScope__c NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        // Create Contract.
        contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_BU__c = regionBU.Id);
        insert contract;
        Orga_BU__c regionBU2 = new Orga_BU__c(Name = 'West Asia', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1));
        regionBU2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
        insert regionBU2;
        country.Country_Zone_origin__c = regionBU2.Id;
        // Start test.
        Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();
		// Assertion.
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_Cannot_Detach_Country_Zone_Origin);
    }
    
    // Close all BU related to the country BU.
    @isTest static void closeAllRelatedBU() {
    	// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create list BU.
        listBU = new Orga_BU__c(Name = 'BU ', BU_Code__c = 'codeBU 002', BU_ODate__c = date.newInstance(year, 1, 1),
    							Format_Origin__c = 'Supermarket', Country_origin__c = country.Id);
        listBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'List');
        insert listBU;
		// Create web BU.
        webBU = new Orga_BU__c(Name = 'WebA', BU_Code__c = 'codeBU 003', BU_ODate__c = date.newInstance(year, 1, 1),
								Country_origin__c = country.Id);
        webBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Web');
        // Create warehouse BU.
        warehouseBU = new Orga_BU__c(Name = 'WarehouseA', BU_Code__c = 'codeBU 004', BU_ODate__c = date.newInstance(year, 1, 1),
								Country_origin__c = country.Id);
        warehouseBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Warehouse');
    	country.Status__c = 'Closed';
    	// Create store BU.
        storeBU = new Orga_BU__c(Name = 'Bu Khalil', BU_Code__c = 'codeBU 005', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country.Id, Format_Origin__c = 'Supermarket');
        storeBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
    	// Start test.
    	Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();        
        List<Orga_BU__c> BUs = [Select Status__c FROM Orga_BU__c WHERE Id =: listBU.Id AND Id =: webBU.Id
								AND Id =: warehouseBU.Id AND Id =: storeBU.Id];        
    	// Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        for (Orga_BU__c BU : BUs) {
        	System.assertEquals('Closed', BU.Status__c);
        }
    }
    // 
    @isTest static void bulkInsert() {
    	// Create Region.
		region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
		region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
		insert region;
		// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create country BU.
        country = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Country_Zone_origin__c = region.Id);
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
		// Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
		// Create Stores.
		List<Orga_BU__c> stores = new List<Orga_BU__c>();
		Id storeRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
		for (Integer i = 0 ; i < 10 ; i++) {
			store = new Orga_BU__c(Name = 'Store CND ' + i, BU_Code__c = 'Store CND ' + i, Country_origin__c = country.Id,
									BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open',
									CurrencyIsoCode = currencyIsoCode, Country__c = myCountry.Name, Legal_Form__c = legal.Id);
			store.RecordTypeId = storeRTId;
			stores.add(store);
		}
		Test.startTest();
		Database.insert(stores, false);
        Test.stopTest();
		
		Integer count = database.countQuery('SELECT count() From Orga_BU_List_Detail__c');
        System.assertEquals(10, count);
    }
    
    // Add BU List Detail record in the current country BU when the country BU status is equal to "Open" (If the BU List Detail does not exist).
    @isTest static void addBUListDetailWhenStatusEqualOpen_testMethod() {
		// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
    	// Create country BU.
        country = new Orga_BU__c(Name = 'Country', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), status__c = 'Close');
        country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country;
        // Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
		// Create store BU.
        storeBU = new Orga_BU__c(Name = 'Store', BU_Code__c = 'Store', BU_ODate__c = date.newInstance(year, 1, 1), Country_origin__c = country.Id, Country__c = myCountry.Name, Legal_Form__c = legal.Id);
        storeBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert storeBU;
        Orga_BU_List_Detail__c detail = [SELECT Entity__c, Entity_List__c FROM Orga_BU_List_Detail__c];
        delete detail;
        country.status__c = 'Open';
        Test.startTest();
        Database.SaveResult result = Database.update(country, false);
        Test.stopTest();
        
        List<Orga_BU_List_Detail__c> details = [SELECT Entity__c, Entity_List__c FROM Orga_BU_List_Detail__c];
        // Assertion.
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
        System.assertEquals(1, details.size());
    }
    
    @isTest static void updateReferenceCountryStoreBU() {
    	// Add Country
		Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
		insert myCountry;
		// Create Region
		Orga_BU__c region = new Orga_BU__c(Name = 'MEA', BU_Code__c = 'MEA', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open');
		region.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Region');
		insert region;
		// Create Country
		country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
		country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
		insert country;
		// Create Legal Form.
		Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
		legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
		insert legal;
		// Create Store
		store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = 'FR');
		store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');

		Database.SaveResult result = Database.insert(store, false);
	
		System.assert(result.isSuccess());
		System.assert(result.getErrors().size() == 0);
		storeBU = [Select Id, Country__c From Orga_BU__c Where Id =: store.Id];
		System.assertEquals(storeBU.Country__c, myCountry.Name);
    }
    @isTest static void recalculateAssortmentDetails() {
        year = System.Today().year();
        month = System.Today().month();
        // Root Element Id
        rootId = NegoptimHelper.getRootId();
        // Get the Corporate Currency.
        currencyIsoCode = NegoptimHelper.getCorporateCurrency();
        // Add Country
        Country_List__c myCountry = TestDataFactory.createCountry(true, 'SEB', 'FR');
        // Create Region.
        region = TestDataFactory.createBURegion(false, 'MEA');
        insert region;
        // Create Country.
        country = TestDataFactory.createBUCountry(false, myCountry, region.Id);
        insert country;
        // Create Supplier.
        client = TestDataFactory.createSupplier(false, country, true);
        insert client;
        // Create NS.
        NS = TestDataFactory.getNSs(client.Id)[0];
        // Create Department
        department = TestDataFactory.createDepartment(true, rootId);
        // Create category        
        category = TestDataFactory.createSection(true, department.Id);
        // Create brand
        brand = TestDataFactory.createBrand(false, client.Id);
        insert brand;
        // insert product
        product = TestDataFactory.createProduct(false, category.Id, client.Id);
        product.Product_EAN__c ='12345';
        insert product;
        // Create Master BU
        masterBU = TestDataFactory.createBUBanner(false, country);
        masterBU.Mission__c = 'Nielsen;Offer';
        masterBU.Format_Origin__c = 'Hypermarket;Supermarket;Drive';
        masterBU.Related_Client__c = client.Id;
        masterBU.IsMasterBU__c = true;
        masterBU.SiteOfSales_Number__c = 100;
        // Create BU List
        buList = TestDataFactory.createBUList(false, country.Id);
        buList.Mission__c = 'Nielsen;Offer';
        buList.Format_Origin__c = 'Supermarket;Drive';
        buList.Related_Client__c = client.Id;
        insert buList;
        // Create BU Banner
        buBanner1 = TestDataFactory.createBUBanner(false, country);
        buBanner1.Mission__c = 'Offer';
        buBanner1.Format_Origin__c = 'Supermarket;Drive';
        buBanner1.Related_Client__c = client.Id;
        buBanner1.Category__c = department.Id;
        buBanner2 = TestDataFactory.createBUBanner(false, country);
        buBanner2.Mission__c = 'Offer';
        buBanner2.Format_Origin__c = 'Supermarket;Drive';
        buBanner2.Related_Client__c = client.Id;
        buBanner2.Category__c = department.Id;
        insert new List<Orga_BU__c>{masterBU,buBanner1,buBanner2};
        // Create BU Cluster
        cluster1 = TestDataFactory.createBUAssortCluster(false, buBanner1.Id, 'Strat0');
        cluster1.Category__c = department.Id;
        cluster1.Weighted_Distribution_Manual__c = 10;
        cluster1.Weighted_Distribution_Manual_N1__c = 10;
        cluster1.SiteOfSales_Number__c = 20;
        cluster1.Mission__c = 'Offer';
        cluster1.BU_ODate__c = Date.today().addDays(-1);
        cluster1.Country_origin__c = buBanner1.Id;
        cluster2 = TestDataFactory.createBUAssortCluster(false, buBanner1.Id, 'Strat1');
        cluster2.Category__c = department.Id;
        cluster2.Weighted_Distribution_Manual__c = 20;
        cluster2.Weighted_Distribution_Manual_N1__c = 20;
        cluster2.SiteOfSales_Number__c = 30;
        cluster2.BU_ODate__c = Date.today().addDays(-1);
        cluster2.Mission__c = 'Offer';
        cluster2.Country_origin__c = buBanner1.Id;
        insert new List<Orga_BU__c>{cluster1,cluster2};
        // insert assortment BU
        Assortment_BU__c assortmentBU = TestDataFactory.createAssortmentBU(false, masterBU, buBanner1, department);
        assortmentBU.Status__c = 'Validated';
        insert assortmentBU;
        // insert assortment detail
        Assortment_Detail__c assortmentDetail = TestDataFactory.createAssortmentDetail(false, assortmentBU.Id, product, cluster1.Id);
        assortmentDetail.Status__c = 'Validated';
        assortmentDetail.New_Client_ND_MarketBased__c = 10;
        assortmentDetail.New_Client_WD_ClientBased__c = 40;
        insert assortmentDetail;
        // update cluster1
        cluster1.Weighted_Distribution_Manual_N1__c = 21;
        Test.startTest();
        update cluster1;
        Test.stopTest();
        assortmentDetail = [SELECT L4L_Client_WD_MarketBased__c FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];
        System.assertEquals(41, assortmentDetail.L4L_Client_WD_MarketBased__c);
    }
}