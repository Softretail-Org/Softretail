/*  Code fragment 1
 * Test code related to fragment 1 of the Trg_Org_OrgaBusinessUnitListDetail trigger, concerning:
 * 1) Contract__c (dependencies)
 * 2) Contract_Discount__c (dependencies)
 * 3) Invoice__c (dependencies)
 * 4) Inv_BUDispatch_Detail__c (dependencies)
 * Code fragment 2
 * Test code related to fragment 2 of the Trg_Org_OrgaBusinessUnitListDetail trigger, concerning:
 * 5) Orga_BU_List_Detail__c (duplication)
 */
@isTest
public with sharing class Trg_Org_Orga_BU_List_Detail_Test {
	
	private static Integer year;
    private static Id rootId;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country1;
    private static Orga_BU__c country2;
    private static Orga_BU__c legal;
    private static Orga_BU__c store;
    private static Orga_BU__c store2;
    private static Orga_BU__c store3;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c negoScope;
    
    // Init (Code fragment 1)
    static void init() {
    	year = System.Today().year();
		// Root Element Id.
		rootId = NegoptimHelper.getRootId();
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
        String cRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        country1 = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
        country1.RecordTypeId = cRTId;
        country2 = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
        country2.RecordTypeId = cRTId;
        insert new List<Orga_BU__c>{country1, country2};
        // Create Legal Form.
        legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
        // Create Store
        store = new Orga_BU__c(BU_Code__c = 'BU11', Status__c = 'Open', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert store;
        // Create Supplier
        supplier = new Sup_Supplier__c(Code__c = 'CD01', Country_origin__c = country1.Id);
        insert supplier;        
        // Create NegoScope
        negoScope = new Sup_sup_NegoScope__c(Supplier__c = supplier.Id);
        insert negoScope;
    }

    /*
     * 1) Related to Contract__c (Dependencies)
     */
    @isTest static void contractRelatedToEntity_EntityListDeleteFailed() {         
        init();        
        // Create Contract
        Contract__c contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_BU__c = country1.Id);
        insert contract;
        // Create Orga BU List Detail
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country1.Id, Entity_List__c = store.Id);
        insert linkedEntity;
        Database.DeleteResult result = Database.delete(linkedEntity, false);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Parent_Related_To_Contract);
    }
    
    @isTest static void contractRelatedToEntity_EntityListDeleteSucceed() {
        init();
        // Create Contract
        Contract__c contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_BU__c = country1.Id);
        insert contract;
        // Create Orga BU List Detail
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country2.Id, Entity_List__c = store.Id);
        insert linkedEntity;
		Database.DeleteResult result = Database.delete(linkedEntity, false);
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
    
    /*
     * 2) Related to Contract_Discount__c (Dependencies)
     */
    @isTest static void ContractDiscountRelatedToEntity_EntityListDeleteFailed() {
        init();
        // Create Contract
        Contract__c contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31));
        insert contract;        
        // Create Pol_Com_Condition__c
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = 'Sample Rebates', Nego_Discount_Type__c = 'Rebates', Status_BDate__c = date.newInstance(2016, 1, 1), Condition_Code__c = 'RB',
                                                                  Abrev__c = 'Y_RB', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ',
                                                                  Name_Fi__c = 'Fi ', Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create Condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = 'Rebates', Condition_Type__c = tariffCondition.Id,
                                    Disc_BDate__c = date.newInstance(year, 5, 5), Disc_EDate__c = date.newInstance(year, 6, 6), Value_per__c = 2, Product_Scope__c = negoScope.Id,
                                    BU_Scope__c = country1.Id, Contract__c = contract.Id);
        insert condition;        
        // Create Orga BU List Detail
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country1.Id, Entity_List__c = store.Id);
        insert linkedEntity;        
        Database.DeleteResult result = Database.delete(linkedEntity, false);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Parent_Related_To_ContractDiscount);
    }
    
    @isTest static void ContractDiscountRelatedToEntity_EntityListDeleteSucceed() {
        init();
        // Create Contract
        Contract__c contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id);
        insert contract;                
        // Create Condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = 'Head Office Fees (MAF)', Condition_Type__c = 'a1624000002EW8FAAW',
                                    Disc_BDate__c = date.newInstance(year, 1, 1), Disc_EDate__c = date.newInstance(year, 12, 31), Value_per__c = 2, Product_Scope__c = negoScope.Id,
                                    BU_Scope__c = country1.Id, Contract__c = contract.Id);
        // Create Orga BU List Detail
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country2.Id, Entity_List__c = store.Id);
        insert linkedEntity;        
        Database.DeleteResult result = Database.delete(linkedEntity, false);        
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
    
    /*
     * 3) Related to Invoice__c (Dependencies)
     */
    @isTest static void InvoiceRelatedToEntity_EntityListDeleteFailed() {       
        init();
        // Create Contract
        Contract__c contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_BU__c = country1.Id);
        // Create Invoice
        Invoice__c invoice = new Invoice__c(Inv_Date__c = date.newInstance(year, 8, 31), Inv_Supplier__c = supplier.Id,
                                        Inv_Business_Unit__c = contract.Contract_BU__c, Sequence_Number__c = 8, Inv_FiscalYear__c = year, Status_BDate__c = date.newInstance(year, 8, 31));
        insert invoice;
        // Create Orga BU List Detail
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country1.Id, Entity_List__c = store.Id);
        insert linkedEntity;
        Database.DeleteResult result = Database.delete(linkedEntity, false);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Parent_Related_To_Invoice);
    }
    
    @isTest static void InvoiceRelatedToEntity_EntityListDeleteSucceed() {
        init();
        // Create Contract
        Contract__c contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_BU__c = country1.Id);
        // Create Invoice
        Invoice__c invoice = new Invoice__c(Inv_Date__c = date.newInstance(year, 8, 31), Inv_Supplier__c = supplier.Id,
                                        Inv_Business_Unit__c = contract.Contract_BU__c, Sequence_Number__c = 8, Inv_FiscalYear__c = year, Status_BDate__c = date.newInstance(year, 8, 31));
        insert invoice;
        // Create Orga BU List Detail
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country2.Id, Entity_List__c = store.Id);
        insert linkedEntity;
        Database.DeleteResult result = Database.delete(linkedEntity, false);
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
    
    /*
     * 4) Related to Inv_BUDispatch_Details__c (Dependencies)
     */
     @isTest static void InvoiceBUDispatchRelatedToEntity_EntityListDeleteFailed() {
        init();
        // Create Contract
        Contract__c contract = new Contract__c(Supplier__c = supplier.Id, Supplier_Nego_Scope__c = negoScope.Id, Contract_BU__c = country2.Id, Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 12, 31));
        insert contract;
        // Create Pol_Com_Condition__c
        Pol_Com_Condition__c tariffCondition = new Pol_Com_Condition__c(Name = 'Sample Rebates', Nego_Discount_Type__c = 'Rebates', Status_BDate__c = date.newInstance(2016, 1, 1), Condition_Code__c = 'RB',
                                                                  Abrev__c = 'Y_RB', Gen_Name_com__c = 'Gen com ', Name_Com__c = 'Com ',
                                                                  Name_Fi__c = 'Fi ', Name_Leg__c = 'Leg ', Gen_Name_Fi__c = 'Gen Fi ', Gen_Name_Leg__c = 'Gen Leg ');
        insert tariffCondition;
        // Create Condition
        Contract_Discount__c condition = new Contract_Discount__c(Nego_Discount_Type__c = 'Rebates', Condition_Type__c = tariffCondition.Id,
                                    Disc_BDate__c = date.newInstance(year, 8, 8), Disc_EDate__c = date.newInstance(year, 9, 9), Value_per__c = 2, Product_Scope__c = negoScope.Id,
                                    BU_Scope__c = country2.Id, Contract__c = contract.Id);
        insert condition;
        // Create Inv_BUDispatch__c
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = 1, Inv_Fiscal_Year__c = 2016, Inv_BU__c = country1.Id);
        insert dispatchHead;
        // Create Inv_BUDispatch_Details__c
        Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Inv_DispatchHead__c = dispatchHead.Id, Discount__c = condition.Id, Inv_BUDispatch__c = store.Id,
                                                                       Base_TO_Dispatch__c = 10000, Status__c = 'New', Sequence__c = 1);
        insert dispatchDetail;
        // Create Orga BU List Detail
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country1.Id, Entity_List__c = store.Id);
        insert linkedEntity;
        Database.DeleteResult result = Database.delete(linkedEntity, false);
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_BU_Parent_Related_To_BUDispatchDetail);
    }
    
    @isTest static void InvoiceBUDispatchRelatedToEntity_EntityListDeleteSucceed() {
    	init();                
        // Create Orga BU List Detail 
        Orga_BU_List_Detail__c linkedEntity = new Orga_BU_List_Detail__c(Entity__c = country1.Id, Entity_List__c = store.Id);
        insert linkedEntity;        
        Database.DeleteResult result = Database.delete(linkedEntity, false);        
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
    
    // Code fragment 2
    /*
     * 4) Related to Inv_BUDispatch_Details__c (Duplication)
     */
    @isTest static void DuplicateEntityList_EntityListInsertFailed() {
    	year = System.Today().year();
    	// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create Orga_BU__c Country
        Orga_BU__c country1 = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country1;
		// Create Legal Form.
        Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
        // Create store BU.
        Orga_BU__c lStoreBU = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country1.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        lStoreBU.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert lStoreBU;
        // Create Orga BU List Detail 
        Orga_BU_List_Detail__c lBUList2 = new Orga_BU_List_Detail__c(Entity__c = country1.Id, Entity_List__c = lStoreBU.Id);        
        Test.startTest();        
        Database.SaveResult result = Database.insert(lBUList2, false); 
        Test.stopTest();        
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_Code_LinkedEntity_Already_Exist);
    }
    
    @isTest static void DuplicateEntityList_EntityListInsertSucceed() {
    	year = System.Today().year();
    	// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create Orga_BU__c Country
        Orga_BU__c country1 = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country1;
		// Create Legal Form.
        Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
        // Create store BU.
        Orga_BU__c lStoreBU1 = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country1.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        lStoreBU1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert lStoreBU1;
        // Create store BU.
        Orga_BU__c lStoreBU2 = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country1.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        lStoreBU2.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        insert lStoreBU2;
        
        List<Orga_BU_List_Detail__c> listDetails =  [select Id from Orga_BU_List_Detail__c];
        System.assertEquals(2, listDetails.size());
    }
    
    @isTest static void DuplicateEntityList_EntityListUpdateFailed() {
    	year = System.Today().year();
    	// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create Orga_BU__c Country
        Orga_BU__c country1 = new Orga_BU__c(Name = 'LEBANON', BU_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1));
        country1.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        insert country1;
		// Create Legal Form.
        Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
        // Create Orga_BU__c Store
        String sRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        // Create store BU.
        Orga_BU__c lStoreBU1 = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country1.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        lStoreBU1.RecordTypeId = sRTId;
        // Create store BU.
        Orga_BU__c lStoreBU2 = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country1.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        lStoreBU2.RecordTypeId = sRTId;
        insert new List<Orga_BU__c>{lStoreBU1, lStoreBU2};
        Orga_BU_List_Detail__c lBUList1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c = :country1.Id AND Entity_List__c = :lStoreBU1.Id];
        Orga_BU_List_Detail__c lBUList2 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c = :country1.Id AND Entity_List__c = :lStoreBU2.Id];
        lBUList2.Entity_List__c = lStoreBU1.Id;        
        Test.startTest();        
        Database.SaveResult result = Database.update(lBUList2, false); 
        Test.stopTest();        
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(result.getErrors()[0].getMessage(), System.Label.MSG_Code_LinkedEntity_Already_Exist);
    }
    
    @isTest static void DuplicateEntityList_EntityListUpdateSucceed() {
    	year = System.Today().year();
    	// Add Country
        Country_List__c myCountry = new Country_List__c(Name = 'FRANCE', Country_Code__c = 'FR');
        insert myCountry;
        // Create Orga_BU__c Country
        String cRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
        Orga_BU__c country1 = new Orga_BU__c(BU_Code__c = 'LEBANON', Country__c = myCountry.Name);
        country1.RecordTypeId = cRTId;
        Orga_BU__c country2 = new Orga_BU__c(BU_Code__c = 'LEBANON', Country__c = myCountry.Name);
        country2.RecordTypeId = cRTId;
        insert new List<Orga_BU__c>{country1, country2};
		// Create Legal Form.
        Orga_BU__c legal = new Orga_BU__c(Name = 'Legal', BU_Code__c = 'Legal', BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country__c = myCountry.Name);
        legal.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Legal');
        insert legal;
        // Create Orga_BU__c Store
        String sRTId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Store');
        // Create store BU.
        Orga_BU__c store = new Orga_BU__c(Name = 'Store 1', BU_Code__c = 'STR1', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country1.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store.RecordTypeId = sRTId;
        Orga_BU__c store2 = new Orga_BU__c(Name = 'Store 2', BU_Code__c = 'STR2', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country1.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store2.RecordTypeId = sRTId;
        Orga_BU__c store3 = new Orga_BU__c(Name = 'Store 3', BU_Code__c = 'STR3', BU_ODate__c = date.newInstance(year, 1, 1),
                            	Country_origin__c = country2.Id, Format_Origin__c = 'Supermarket', Legal_Form__c = legal.Id, Country__c = myCountry.Name);
        store3.RecordTypeId = sRTId;
        insert new List<Orga_BU__c>{store, store2, store3};
        Orga_BU_List_Detail__c linkedEntity1 = [SELECT Id FROM Orga_BU_List_Detail__c WHERE Entity__c = :country1.Id AND Entity_List__c = :store.Id];
        Orga_BU_List_Detail__c linkedEntity2 = [SELECT Id, Entity_List__c FROM Orga_BU_List_Detail__c WHERE Entity__c = :country1.Id AND Entity_List__c = :store2.Id];
        linkedEntity2.Entity_List__c = store3.Id;
        Test.startTest();
        Database.SaveResult result = Database.update(linkedEntity2, false);
        Test.stopTest();
        System.assert(result.isSuccess());
        System.assert(result.getErrors().size() == 0);
    }
}