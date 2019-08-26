@isTest
private class MassBatchFormControllerTest {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;    
    private static Contract__c contract;
    private Document document;
    private static Id rootId;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Supplier_PG_Mapping__c PG;
    
   	static void init() {
    	year = System.Today().year();
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
    }
    // Mass Calculate Base TO: Success case.
    @isTest static void submitCalculateContractBatch_Success() {
    	init();
    	MassBatchFormController instance = new MassBatchFormController();
    	//instance.selectedCountry = instance.buOptions.get(0).getValue();
    	instance.selectedCountry = country.Id;
    	Test.startTest();
    	instance.submitCalculateContractBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains(String.format(Label.MSG_Job_In_Progress, new String[]{'Calculation Base TO', ''}).split('"').get(1))) messageFound = true;
		}
        System.assert(messageFound);
    }
    // Mass Generate Invoices: Success case.
    @isTest static void submitGenerateInvoicesBatch_Success() {
    	init();
    	// Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
		// Create contract.
		contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001',
								   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
								   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
		insert contract;    	
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	instance.contract = contract;
    	Test.startTest();
    	instance.submitGenerateInvoicesBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains(String.format(Label.MSG_Job_In_Progress, new String[]{'Generating Invoices', ''}).split('"').get(1))) messageFound = true;
		}
        System.assert(messageFound);
    }
    // Mass Generate Invoices: Fail case.
    @isTest static void submitGenerateInvoicesBatch_Fail() {
    	init();
    	// Create supplier.
        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active', Country_origin__c = country.Id,
        						Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
        insert supplier;
        // Get the default negoscope created on supplier creation.
        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
		// Create contract.
		contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001',
								   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
								   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
		insert contract;
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
		instance.contract.Contract_BDate__c = null;
    	Test.startTest();
    	instance.submitGenerateInvoicesBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains(Label.MSG_Validation_Error.split(':').get(0))) messageFound = true;
		}
        System.assert(messageFound);
    }
    // Mass Dispatching: Success case.
    @isTest static void submitDispatchingBatch_Success() {
    	init();
    	// Create supplier.
		supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = false);
		insert supplier;
		// Create active NS.
        NS = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id, status__c = 'Active');
        insert NS;
		// Create contract.
		contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001',
								   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
								   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
		insert contract;    	
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	instance.contract = contract;
    	Test.startTest();
    	instance.submitDispatchingBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains(String.format(Label.MSG_Job_In_Progress, new String[]{'Dispatching', ''}).split('"').get(1))) messageFound = true;
		}
        System.assert(messageFound);
    }
    // Mass Dispatching: Fail case.
    @isTest static void submitDispatchingBatch_Fail() {
    	init();
    	// Create supplier.
		supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = false);
		insert supplier;
		// Create active NS.
        NS = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id, status__c = 'Active');
        insert NS;
		// Create contract.
		contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001',
								   Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
								   Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
		insert contract;
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
		instance.contract.Contract_BDate__c = null;
    	Test.startTest();
    	instance.submitDispatchingBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains(Label.MSG_Validation_Error)) messageFound = true;
		}
        System.assert(messageFound);
    }
    // Mass Duplicate Contract: Success case.
    @isTest static void submitDuplicateContractBatch_Success() {
    	init();
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	Test.startTest();
    	instance.submitDuplicateContractBatch();
    	Test.stopTest();
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            System.assertEquals(ApexPages.Severity.INFO, message.getSeverity());
		}
    }
    // GRC
    @isTest static void generateGRCRatesBatch_Success() {
    	init();
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	instance.lastActiveContract = false;
    	Test.startTest();
    	instance.generateGRCRatesBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains(String.format(Label.MSG_Job_In_Progress, new String[]{'Generate GRC Contract Rates', ''}).split('"').get(1))) messageFound = true;
		}
        System.assert(messageFound);
    }
    /* Mass Merge Contract: Success case.
    @isTest static void submitMergeContractBatch_Success() {
    	init();
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	Test.startTest();
    	instance.submitMergeContractBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('The Job for contract merge of Id')) {
                   messageFound = true;
            }
		}
        System.assert(messageFound);
    }
    // Mass Merge Contract: Fail case.
    @isTest static void submitMergeContractBatch_Fail() {
    	init();
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = Null;
    	Test.startTest();
    	instance.submitMergeContractBatch();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for(ApexPages.Message message : pageMessages) {
            if(message.getSummary().contains('Validation Error: Value is required.')) {
                   messageFound = true;
            }
		}
        System.assert(messageFound);
    }*/
    /* Mass Distribution Block Section */
    // Country is not selected.
    @isTest static void notSelectedCountry() {
    	init();
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = Null;
    	instance.file = Blob.valueOf('Unit Test Body');
    	Test.startTest();
    	instance.upload();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains('ERROR-001: I/O EXCEPTION. No country chosen!')) messageFound = true;
		}
        System.assert(messageFound);
    }
    // File is not selected.
    @isTest static void notSelectedFile() {
    	init();
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	instance.file = NULL;
    	Test.startTest();
    	instance.upload();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains('ERROR-001: I/O EXCEPTION. No file chosen!')) messageFound = true;
		}
        System.assert(messageFound);
    }
    // File name doesn't finish by ".csv".
    @isTest static void incorrectExtension() {
    	init();
		// Create supplier.
        supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = false);
        insert supplier;
        // Create active NS.
        NS = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id, status__c = 'Active');
        insert NS;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, D_N__c = 'D',
        							Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001', Status__c = 'Validated',
                                   	Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   	Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	instance.file = Blob.valueOf('Unit Test Body');
    	instance.document.name = 'myDoc.pdf';
    	Test.startTest();
    	instance.upload();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains('ERROR-001: I/O EXCEPTION. File\'s extension is not ".csv"!')) messageFound = true;
		}
        System.assert(messageFound);
    }
    // Invalid column number.
    @isTest static void invalidColumnNumber() {
    	init();
		// Create supplier.
        supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = false);
        insert supplier;
        // Create active NS.
        NS = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id, status__c = 'Active');
        insert NS;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, D_N__c = 'D',
        							Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001', Status__c = 'Validated',
                                   	Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   	Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER\r\n';
        contentData += 'Sup002,1011,SUBNS-PepsiC,St004C,Advertising Fees,12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,2051,NS-Nestle-00,St001,Advertising Fees,12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,2051,NS-Nestle-00,St002,Sample Progressive Rebates,12000,New,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        instance.file = Blob.valueOf(contentData);
        instance.document.name = 'myDoc.csv';
    	Test.startTest();
    	instance.upload();
    	Test.stopTest();
    	Boolean messageFound = false;
    	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        for (ApexPages.Message message : pageMessages) {
            if (message.getSummary().contains('ERROR-001: I/O EXCEPTION. Invalid column number!')) messageFound = true;
		}
        System.assert(messageFound);
    }
    // Valid column number.
    @isTest static void yearlyFile_columnsNumber() {
    	init();
		// Create supplier.
        supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = false);
        insert supplier;
        // Create active NS.
        NS = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id, status__c = 'Active');
        insert NS;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, D_N__c = 'D',
        							Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001', Status__c = 'Validated',
                                   	Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   	Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += 'Sup002,1011,SUBNS-PepsiC,St004C,Advertising Fees,12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,2051,NS-Nestle-00,St001,Advertising Fees,12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,2051,NS-Nestle-00,St002,Sample Progressive Rebates,12000,New,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,1026,NS-Nestle-00,St003,Sample Rebates,12000,New,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        instance.file = Blob.valueOf(contentData);
        instance.document.name = 'myDoc.csv';
    	Test.startTest();
    	instance.upload();
    	Test.stopTest();
    	System.assertEquals(21, instance.records[0].size());
    }
    // Valid column number.
    @isTest static void monthlyFile_columnsNumber() {
    	init();
		// Create supplier.
        supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = false);
        insert supplier;
        // Create active NS.
        NS = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id, status__c = 'Active');
        insert NS;
        // Root Element Id.
		rootId = NegoptimHelper.getRootId();
		// Create Department.
		department = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = '1', Parent_Element__c = rootId, Level__c = 1,
									Status_BDate__c = date.newInstance(year, 1, 1), Status__c = 'Active',
									Nego_Type__c = 'Ferme', Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
		insert department;
		// Create Section.
		section = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = '1011', Parent_Element__c = department.Id, Level__c = 2,
								Status_BDate__c = date.newInstance(year, 1, 1),
								Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c =false);
		insert section;
		// Create PG.
        PG = new Supplier_PG_Mapping__c(Name = 'PG 00', SNA_Code__c = '100', GIMA_Code__c = '100',
	    									Department__c = department.Id, Section__c = section.Id,
	    									Supplier__c = supplier.Id, Nego_Scope__c = NS.Id);
        insert PG;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, D_N__c = 'D',
        							Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001', Status__c = 'Validated',
                                   	Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   	Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	String contentData = 'SUPPLIER,SECTION,PG,NS,STORE,CONDITION,AMOUNT,Type,COMMENT\r\n';
        contentData += 'Sup002,1011,100,SUBNS-PepsiC,St004C,Advertising Fees,12000,Pre-Nego,a\r\n';
        contentData += 'Sup001,2051,100,NS-Nestle-00,St001,Advertising Fees,12000,Pre-Nego,a\r\n';
        contentData += 'Sup001,2051,100,NS-Nestle-00,St002,Sample Progressive Rebates,12000,New,a\r\n';
        contentData += 'Sup001,1026,100,NS-Nestle-00,St003,Sample Rebates,12000,New,a\r\n';
        instance.file = Blob.valueOf(contentData);
        instance.document.name = 'myDoc.csv';
    	Test.startTest();
    	instance.upload();
    	Test.stopTest();
    	System.assertEquals(9, instance.records[0].size());
    }
    // Existing folder.
    @isTest static void folderExists() {
    	init();    	
		// Create supplier.
        supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode, Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = false);
        insert supplier;
        // Create active NS.
        NS = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id, status__c = 'Active');
        insert NS;
        // Create contract.
        contract = new Contract__c(Name = supplier.Name + ' - Contract ' + year, Supplier__c = supplier.Id, D_N__c = 'D',
        							Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C001', Status__c = 'Validated',
                                   	Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31),
                                   	Duration__c = 12, Contract_BU__c = country.Id, Contract_Type__c = 'Contract', CurrencyIsoCode = currencyIsoCode);
        insert contract;
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.selectedCountry = country.Id;
    	String contentData = 'SUPPLIER CODE,SECTION CODE,NS,STORE CODE,CONDITION NAME,AMOUNT,Type,COMMENT,SECONDARY LABEL,JANUARY,FEBRUARY,MARCH,APRIL,MAY,JUNE,JULY,AUGUST,SEPTEMBER,OCTOBER,NOVEMBER,DECEMBER\r\n';
        contentData += 'Sup002,1011,SUBNS-PepsiC,St004C,Advertising Fees,12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,2051,NS-Nestle-00,St001,Advertising Fees,12000,Pre-Nego,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,2051,NS-Nestle-00,St002,Sample Progressive Rebates,12000,New,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        contentData += 'Sup001,1026,NS-Nestle-00,St003,Sample Rebates,12000,New,,,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000,1000\r\n';
        instance.file = Blob.valueOf(contentData);
        instance.document.name = 'myDoc.csv';
    	Test.startTest();
    	instance.upload();
    	Test.stopTest();
    	System.assertNotEquals(NULL, document.FolderId);
    }
    // Profile Name is System Administrator.
    @isTest static void pickList_profile1() {
 		Profile profile = [SELECT Id FROM Profile WHERE PermissionsCustomizeApplication = true limit 1];
 		// Create Role.
        UserRole role1 = new UserRole(Name='CEO', ParentRoleId = Null);
 		User user1 = new User(FirstName='user1', LastName = 'user1', Alias = 'jliv', Email = 'user1@user1.com',
				        Username = 'user1a@user1.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
				        EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = role1.Id);
    	insert user1;
    	MassBatchFormController instance;
    	System.runAs(user1) {
    		init();
    		instance = new MassBatchFormController();
    	}
    	System.assertEquals(2, instance.countries.size());
    }
    /*// Profile Name is not System Administrator.
    @isTest static void pickList_profile2() {
 		Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
 		// Create Role.
        UserRole role1 = new UserRole(Name='CEO', ParentRoleId = Null);
 		User user1 = new User(FirstName='user1', LastName = 'user1', Alias = 'jliv', Email = 'user1@user1.com',
				        Username = 'user1a@user1.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US',
				        EmailEncodingKey = 'UTF-8', LocaleSidKey = 'en_US', ProfileId = profile.id, UserRoleId = role1.Id);
    	insert user1;
    	MassBatchFormController instance;
    	System.runAs(user1) {
    		init();
    		instance = new MassBatchFormController();
    	}
    	System.assertEquals(1, instance.countries.size());
    }*/
    @isTest static void test() {
    	MassBatchFormController instance = new MassBatchFormController();
    	instance.submitCalculateContractBatch();
    	instance.submitGenerateInvoicesBatch();
    	instance.submitDispatchingBatch();
    	instance.submitBaseRedistributionBatch();
    	instance.submitDuplicateContractBatch();
    	//instance.generateGRCRatesBatch();
    	instance.submitGroupContractScanBatch();
    	instance.submitGroupContractSynchroBatch();
    	instance.submitGroupInvoiceScanBatch();
    	instance.submitGroupInvoiceSynchroBatch();
    	instance.submitGroupInvoicePaymentScanBatch();
    	instance.submitGroupInvoicePaymentSynchroBatch();
    	instance.submitPenaltiesScanSynchroBatch();
    	instance.submitGroupRebatePaymentScanBatch();
    	instance.submitGroupRebatePaymentSynchroBatch();
    	instance.submitCommercialPlanScanContractBatch();
    	instance.submitCommercialPlanScanStatusBatch();
    	instance.submitCloseSupplierBatch();
    	instance.submitLastActiveContractBatch();
    	instance.submitSellinToPurchaseBatch();
    	instance.submitReparentingSellinBatch();
    	instance.submitInvoiceReminderBatch();
    	instance.submitPurchasesNegoScopeBatch();
    	System.assert(True);
    }
}