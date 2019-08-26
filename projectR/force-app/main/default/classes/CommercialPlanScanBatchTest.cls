/*
 * Unit test for scan commercial plan detail batch
 **/ 
@isTest
private class CommercialPlanScanBatchTest {
    private static Integer year = TestDataFactory.year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    
    static void init() {
        try {
            // Get the Corporate Currency.
            currencyIsoCode = NegoptimHelper.getCorporateCurrency();
            // Add Country
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            // Create Region
            region = TestDataFactory.createBURegion(true, 'MEA');
            // Create Country
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            // Create group BU.
            groupBU = TestDataFactory.createGroupBU(false, 'EMC');
            groupBU.Country_Zone_origin__c = region.Id;
            insert groupBU;
            // Create Supplier.
            supplier = TestDataFactory.createSupplier(true, country, true);
            // Create NS.
            NS = TestDataFactory.getNSs(supplier.Id)[0];
            // create contract
            contract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-4), System.Today().addMonths(-2));
            contract.Last_Active_Contract__c = true;
            insert contract;
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    // Test Updating of Commercial Plan Detail with Countrat is changed and Management of fields changed.
    @isTest static void test_UpdateCommercialPlanDetailWithContractIsNULL() {
        init();
        try {
            // insert commercialPlan With Date < Today
            Commercial_Plan__c commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today().addMonths(-2), System.Today() + 1);
            insert commercialPlan;
            // insert commercial plan detail
            Commercial_Plan_Detail__c commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
            commercialPlanDetail.Temp_Contract_Reference__c = 'Ref Contract';
            commercialPlanDetail.Supplier__c = supplier.Id;
            insert commercialPlanDetail;
            Test.startTest();
            Database.executeBatch(new CommercialPlanScanBatch('CommercialPlanScanBatchTest', new List<Id>{commercialPlanDetail.Id}, country.Id, String.valueOf(commercialPlan.Start_Date__c), true, false));
            Test.stopTest();
            // Validation Test
            commercialPlanDetail = [SELECT Id, Temp_Contract_Reference__c, Contract__c, Line_Status__c, Extraction_Status__c FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail.Id];
            System.assertEquals(contract.Id, commercialPlanDetail.Contract__c);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    // Test Updating of Commercial Plan Detail with Countrat is changed and Management of fields changed.
    @isTest static void test_UpdateCommercialPlanDetailWithEndDateTomorrow() {
        init();
        try {
            // insert new contract with Group BU and Last_Active_Contract__c = TRUE
            Contract__c newContract = TestDataFactory.createContract(false, NS, System.Today().addMonths(-1), System.Today().addMonths(1));
            newContract.Contract_BU__c = groupBU.Id;
            newContract.Last_Active_Contract__c = true;
            insert newContract;
            // insert commercialPlan With Date < Today
            Commercial_Plan__c commercialPlan = TestDataFactory.createCommercialPlan(false, System.Today() - 7, System.Today() + 1);
            insert commercialPlan;
            // insert commercial plan detail
            Commercial_Plan_Detail__c commercialPlanDetail = TestDataFactory.createCommercialPlanDetail(false, commercialPlan.Id, NS);
            commercialPlanDetail.Temp_Contract_Reference__c = 'Contact Reference';
            commercialPlanDetail.Supplier__c = supplier.Id;
            commercialPlanDetail.Contract__c = newContract.Id;
            commercialPlanDetail.Statut__c = 'Contract Edited';
            insert commercialPlanDetail;
            Test.startTest();
            Database.executeBatch(new CommercialPlanScanBatch('CommercialPlanScanBatchTest', new List<Id>{commercialPlanDetail.Id}, NULL, String.valueOf(commercialPlan.Start_Date__c), false, true));
            Test.stopTest();
            // Validation Test
            commercialPlanDetail = [SELECT Id, Temp_Contract_Reference__c, Contract__c, Line_Status__c, Extraction_Status__c FROM Commercial_Plan_Detail__c WHERE Id = :commercialPlanDetail.Id];
            System.assertEquals('Extract', commercialPlanDetail.Extraction_Status__c);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
}