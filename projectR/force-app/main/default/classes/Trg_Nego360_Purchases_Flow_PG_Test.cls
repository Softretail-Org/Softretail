/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers for purchases flow product group 
 */
@isTest
private class Trg_Nego360_Purchases_Flow_PG_Test {
    
    private static Integer year;
    private static String currencyIsoCode;
    private static Id rootId;
    
    private static Orga_HE__c productStructure1;
    private static Sup_Supplier__c supplier;
    private static Sup_Supplier__c supplier2;
    private static Orga_HE__c department1;
    private static Orga_HE__c section1;
    private static Supplier_PG_Mapping__c pg1;
    private static Sup_NS_PG__c negoScopePG1;
    private static Sup_Brand__c brand1;
    private static Sup_Brand__c brand2;
    private static Sup_sup_NegoScope__c NS;
    private static Sup_NS_Brand__c negoScopeBrand;
    private static Supplier_NS_HE__c negoScopeHe;
    private static Contract__c contract1;
    //private static Contract__c contractTarget1;
    private static Orga_BU__c bu1;
    private static RecordType RT;
    private static Contract__c contractClosed;
    private static Supplier_PG_Mapping__c pgClosed;
    
    static void init() {
        try {
            year = System.Today().year();
            // root Element
            rootId = NegoptimHelper.getRootId();
            // Get the Corporate Currency
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Create supplier.
	        supplier = new Sup_Supplier__c(Name = 'SUPPLIER', Code__c = 'SUPPLIER', Status__c = 'Active',
	        						Is_Default_NegoScope__c = true, CurrencyIsoCode = currencyIsoCode,
	        						Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
	        insert supplier;
	        // Get the default negoscope created on supplier creation.
	        NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
	        // Create Department
            department1 = new Orga_HE__c(Name = 'DPT1', Elt_Code__c = 'Elt Code 1', Parent_Element__c = rootId, Level__c = 1, Status_BDate__c = date.newInstance(year, 1, 1), Dispatch_Inv_Hierarchy_Starting_Point__c = false, Purchases_DB_Upper_Starting_Point__c = true);
            insert department1;
            // Create Section        
            section1 = new Orga_HE__c(Name = 'SEC1', Elt_Code__c = 'Elt Code 2', Parent_Element__c = department1.Id, Level__c = 2, Status_BDate__c = date.newInstance(year, 1, 1),  Dispatch_Inv_Hierarchy_Starting_Point__c = true, Purchases_DB_Upper_Starting_Point__c = false);
            insert section1;
            // Create brand 
            brand1 = new Sup_Brand__c(Name = 'Brand 1', Brand_Owner__c = supplier.Id);
            insert brand1;
            // Create PG
            pg1 = new Supplier_PG_Mapping__c(Name = 'PG 1', SNA_Code__c = '123', GIMA_Code__c = '1', Brand__c=brand1.Id,Department__c = department1.Id, Section__c = section1.Id, Supplier__c = supplier.Id);
            insert pg1;
            // Create closed product group
            pgClosed = new Supplier_PG_Mapping__c(Name = 'PG Closed', SNA_Code__c = '234', GIMA_Code__c = '2', Brand__c=brand1.Id,Department__c = department1.Id, Section__c = section1.Id, Supplier__c = supplier.Id,Status__c='Close');
            insert pgClosed;
            // Create Supplier 2
            //supplier2 = new Sup_Supplier__c(Name = 'Supplier 002', Code__c = 'SUP002', Is_Default_NegoScope__c = false);
            //insert supplier2;
            // Create brand 
            //brand2 = new Sup_Brand__c(Name = 'Brand 2', Brand_Owner__c = supplier2.Id);
            //insert brand2;
            // Create BU
            bu1 = new Orga_BU__c(Name = 'Test BU2', BU_Code__c = 'TBU2', BU_ODate__c = date.newInstance(year+1, 1, 1));
            // create record type
            RT = [Select Id From RecordType WHERE Name = 'Country' limit 1];
            bu1.RecordTypeId = RT.Id;
            insert bu1;
            // create contract 
            contract1 = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                        Contract_BDate__c = date.newInstance(year, 1, 1), Contract_EDate__c = date.newInstance(year, 6, 1), Duration__c = 6, Contract_BU__c = bu1.Id,
                                        Contract_Type__c = 'Contract');		
            //insert contract1;
            /*// create contract target 
            contractTarget1 = new Contract__c(Name ='Test Contract Target 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'CT1234',
                                              Contract_BDate__c = date.newInstance(year-1, 1, 1), Contract_EDate__c = date.newInstance(year-1, 6, 1), Duration__c = 6, Contract_BU__c = bu1.Id,
                                              Contract_Type__c = 'Target');		
            insert contractTarget1;*/
            // create closed contract
            contractClosed = new Contract__c(Name ='Test contract closed', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C1122',
                                             Contract_BDate__c = date.newInstance(year+2, 1, 1), Contract_EDate__c = date.newInstance(year+3, 6, 1), Duration__c = 18, Contract_BU__c = bu1.Id,
                                             Contract_Type__c = 'Contract',Status__c='Closed');		
            //insert contractClosed;
            insert new List<Contract__c>{contract1, contractClosed};
            System.debug('contractClosed:: ' + contractClosed);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    /*
* Test validation on purchases flow to prevent adding closed Pg
*/
    @isTest static void test_createPurchasesFlowClosedPg() {
        init();         
        
        Purchases_Flow_PG__c newPfClosedPg = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = pgClosed.Id, Department__c = department1.Id, Section__c = section1.Id,
                                                                      Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract1.Id, Year__c = year, BU__c = bu1.Id,
                                                                      TO1__c = 200, TO2__c = 200, TO3__c = 200, TO4__c = 200, TO5__c = 200, TO6__c = 200,
                                                                      TO7__c = 200, TO8__c = 200, TO9__c = 200, TO10__c = 200, TO11__c = 200, TO12__c = 200);
        Test.startTest();
        Database.SaveResult result = Database.insert(newPfClosedPg, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Cannot_Add_Purchase_Linked_Pg, result.getErrors()[0].getMessage());
        
    }
    
    /*
* Test validation on purchases flow to prevent adding closed Contract
  */ 
    @isTest static void test_createPurchasesFlowClosedContract() {
        init();
        
        Purchases_Flow_PG__c newPfClosedContract = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = pg1.Id, Department__c = department1.Id, Section__c = section1.Id,
                                                                            Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contractClosed.Id, Year__c = 2016, BU__c = bu1.Id,
                                                                            TO1__c = 200, TO2__c = 200, TO3__c = 200, TO4__c = 200, TO5__c = 200, TO6__c = 200,
                                                                            TO7__c = 200, TO8__c = 200, TO9__c = 200, TO10__c = 200, TO11__c = 200, TO12__c = 200);
        Test.startTest();
        Database.SaveResult result = Database.insert(newPfClosedContract, false);
        Test.stopTest();
        System.assert(!result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.assertEquals(System.Label.MSG_Cannot_Add_Purchase_Linked_Contract, result.getErrors()[0].getMessage());
        
    }
  
    /*
* Test validation on List of purchases flow to prevent adding closed Pg
  */
    @isTest static void test_createListPurchasesFlowClosedPg() {
        init();
        
        List<Purchases_Flow_PG__c> lstPf = new List<Purchases_Flow_PG__c>();
        Purchases_Flow_PG__c newPfClosedPg = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = pgClosed.Id, Department__c = department1.Id, Section__c = section1.Id,
                                                                      Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract1.Id, Year__c = 2016, BU__c = bu1.Id,
                                                                      TO1__c = 200, TO2__c = 200, TO3__c = 200, TO4__c = 200, TO5__c = 200, TO6__c = 200,
                                                                      TO7__c = 200, TO8__c = 200, TO9__c = 200, TO10__c = 200, TO11__c = 200, TO12__c = 200);
        Purchases_Flow_PG__c newPfClosedPg2 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = pgClosed.Id, Department__c = department1.Id, Section__c = section1.Id,
                                                                       Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contract1.Id, Year__c = 2016, BU__c = bu1.Id,
                                                                       TO1__c = 200, TO2__c = 200, TO3__c = 200, TO4__c = 200, TO5__c = 200, TO6__c = 200,
                                                                       TO7__c = 200, TO8__c = 200, TO9__c = 200, TO10__c = 200, TO11__c = 200, TO12__c = 200);
        lstPf.add(newPfClosedPg);
        lstPf.add(newPfClosedPg2);
        Test.startTest();
        Database.SaveResult[] results = Database.insert(lstPf, false);
        Test.stopTest();
        for (Database.SaveResult result : results) {
            System.assert(!result.isSuccess());
            System.assert(result.getErrors().size() > 0);
            System.assertEquals(System.Label.MSG_Cannot_Add_Purchase_Linked_Pg, result.getErrors()[0].getMessage());
        }
        
    }
  
    /*
* Test validation on list of purchases flow to prevent adding closed Contract
*/
    @isTest static void test_createListPurchasesFlowClosedContract() {
        init();
        
        List<Purchases_Flow_PG__c> lstPf = new List<Purchases_Flow_PG__c>();
        Purchases_Flow_PG__c newPfClosedContract = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = pg1.Id, Department__c = department1.Id, Section__c = section1.Id,
                                                                            
                                                                            Supplier_Nego_Scope__c = NS.Id, 
                                                                            Contrat1__c = contractClosed.Id, Year__c = 2016, 
                                                                            BU__c = bu1.Id,
                                                                            TO1__c = 200, TO2__c = 200, TO3__c = 200, TO4__c = 200, TO5__c = 200, TO6__c = 200,
                                                                            TO7__c = 200, TO8__c = 200, TO9__c = 200, TO10__c = 200, TO11__c = 200, TO12__c = 200);
        Purchases_Flow_PG__c newPfClosedContract2 = new Purchases_Flow_PG__c(Supplier__c = supplier.Id, PG__c = pg1.Id, Department__c = department1.Id, Section__c = section1.Id,
                                                                             Supplier_Nego_Scope__c = NS.Id, Contrat1__c = contractClosed.Id, Year__c = 2016, BU__c = bu1.Id,
                                                                             TO1__c = 200, TO2__c = 200, TO3__c = 200, TO4__c = 200, TO5__c = 200, TO6__c = 200,
                                                                             TO7__c = 200, TO8__c = 200, TO9__c = 200, TO10__c = 200, TO11__c = 200, TO12__c = 200);
        lstPf.add(newPfClosedContract);
        lstPf.add(newPfClosedContract2);
        Test.startTest();        
        Database.SaveResult[] results = Database.insert(lstPf, false); 
        Test.stopTest();
        for (Database.SaveResult result : results) {
            System.assert(!result.isSuccess());
            System.assert(result.getErrors().size() > 0);
            System.assertEquals(System.Label.MSG_Cannot_Add_Purchase_Linked_Contract, result.getErrors()[0].getMessage());
        }
        
    } 
}