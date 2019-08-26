@isTest
public class LastActiveContractBatchTest {
    private static Integer year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    
    static void init() {
        try {
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
			ApexPages.currentPage().getParameters().put('action', 'Export');
			// Create Country
            country = new Orga_BU__c(Name = myCountry.Name, BU_Code__c = myCountry.Country_Code__c, CurrencyIsoCode = currencyIsoCode, ISO_Country_Code__c = myCountry.Country_Code__c, BU_ODate__c = date.newInstance(year, 1, 1), Status__c = 'Open', Country_Zone_origin__c = region.Id);
            country.RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
            insert country;
            // Create Supplier.
            supplier = new Sup_Supplier__c(Name = 'Supplier 001', Code__c = 'SUP001', CurrencyIsoCode = currencyIsoCode,
                                           Country_origin__c = country.Id, Status__c = 'Active', Is_Default_NegoScope__c = true,
                                           Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false);
            insert supplier;
            // Create NS.
            NS = [SELECT Id FROM Sup_sup_NegoScope__c WHERE Supplier__c =: supplier.Id LIMIT 1];
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    @isTest static void test_NSWithOneContrat() {
        init();
        try{
            // create contract
            Contract__c lastContract = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                                                Contract_BDate__c = System.Today().addMonths(-6),
                                                                Contract_EDate__c = System.Today().addMonths(-5), Duration__c = 2,
                                                                Contract_BU__c = country.Id, Contract_Type__c = 'Contract',Duration_type__c='Month');
            insert lastContract;
            Test.startTest();        
            Database.executeBatch(new LastActiveContractBatch('LastActiveContractBatchTest', country.Id, new List<Id>{NS.Id}));
            Test.stopTest();
            // Validation Test
            lastContract = [Select Id, Last_Active_Contract__c
                        From Contract__c
                        Where Id =: lastContract.Id];
            System.assertEquals(lastContract.Last_Active_Contract__c, true);
        }catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    @isTest static void test_NSWithContratEndDateLessThanToday() {
        init();
        try{
            // create contract
            Contract__c prvContract = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, 
                                                      Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                                      Contract_BDate__c = System.Today().addMonths(-6), 
                                                      Contract_EDate__c = System.Today().addMonths(-5), Duration__c = 2, 
                                                      Contract_BU__c = country.Id, Contract_Type__c = 'Contract',Duration_type__c='Month');
            
            insert prvContract;
            Contract__c lastContract = new Contract__c(Name ='New Test Contract 01', Supplier__c = supplier.Id, 
                                                       Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C01',
                                                       Contract_BDate__c = System.Today().addMonths(-2), 
                                                       Contract_EDate__c = System.Today().addMonths(-1),
                                                       Duration__c = 2,  Contract_BU__c = country.Id,
                                                       Contract_Type__c = 'Contract', Duration_type__c='Month');
            insert lastContract;
            Test.startTest();            
            Database.executeBatch(new LastActiveContractBatch('LastActiveContractBatchTest', null, new List<Id>{NS.Id}));
            Test.stopTest();
            // Validation Test
            lastContract = [Select Id, Last_Active_Contract__c
                           From Contract__c
                           Where Id =: lastContract.Id];
            System.assertEquals(lastContract.Last_Active_Contract__c, true);
        }catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }    
    @isTest static void test_NSWithContratEndDateGreaterThanToday() {
        init();
        try{
            Contract__c prvContract = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, 
                                                      Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                                      Contract_BDate__c = System.Today().addMonths(-6), 
                                                      Contract_EDate__c = System.Today().addMonths(-5), Duration__c = 2, 
                                                      Contract_BU__c = country.Id, Contract_Type__c = 'Contract',Duration_type__c='Month');
            
            insert prvContract;            
            Contract__c lastContract = new Contract__c(Name ='New Test Contract 01', Supplier__c = supplier.Id, 
                                                       Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C01',
                                                       Contract_BDate__c = System.Today().addMonths(-1), 
                                                       Contract_EDate__c = System.Today().addMonths(1), Duration__c = 3,  
                                                       Contract_BU__c = country.Id, Contract_Type__c = 'Contract', Duration_type__c='Month');
            insert lastContract;
            Test.startTest();            
            Database.executeBatch(new LastActiveContractBatch('LastActiveContractBatchTest', null, new List<Id>{NS.Id}));
            Test.stopTest();
            // Validation Test
            lastContract = [Select Id, Last_Active_Contract__c
                           From Contract__c
                           Where Id =: lastContract.Id];
            System.assertEquals(lastContract.Last_Active_Contract__c, true);
        }catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }  
    @isTest static void test_NSWithPreviousLastActiveContratTrue() {
        init();
        try{
            Contract__c prvContract = new Contract__c(Name ='Test Contract 001', Supplier__c = supplier.Id, 
                                                      Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C123',
                                                      Contract_BDate__c = System.Today().addMonths(-6), 
                                                      Contract_EDate__c = System.Today().addMonths(-5), Duration__c = 2, 
                                                      Contract_BU__c = country.Id, Contract_Type__c = 'Contract',Duration_type__c='Month',
                                                      Last_Active_Contract__c = True);
            
            insert prvContract;
            Contract__c lastContract = new Contract__c(Name ='New Test Contract 01', Supplier__c = supplier.Id, 
                                                      Supplier_Nego_Scope__c = NS.Id, Contract_Numbder__c = 'C01',
                                                      Contract_BDate__c = System.Today().addMonths(-1), 
                                                      Contract_EDate__c = System.Today().addMonths(1),
                                                      Duration__c = 3,  
                                                      Contract_BU__c = country.Id,
                                                      Contract_Type__c = 'Contract', Duration_type__c='Month');
            insert lastContract;
            Test.startTest();            
            Database.executeBatch(new LastActiveContractBatch('LastActiveContractBatchTest', null, new List<Id>{NS.Id}));
            Test.stopTest();
            // Validation Test
            prvContract = [Select Id, Last_Active_Contract__c
                           From Contract__c
                           Where Id =: prvContract.Id];
            System.assertEquals(prvContract.Last_Active_Contract__c, false);
        }catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage() );
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
}