/**
 * Test class for SetDispatchDetailsStatusBatch
 * */
@isTest
private class SetDispatchDetailsStatusBatchTest {
	
    private static Orga_BU__c country;
    private static Orga_BU__c store;
    private static Sup_Supplier__c supplier;
    private static Orga_HE__c department;
    private static Orga_HE__c section;
    private static Supplier_PG_Mapping__c PG;
    private static Contract__c contract;
    private static Contract_discount__c condition;
    
    static void init() {
        try {
            Country_List__c myCountry = TestDataFactory.createCountry(true, 'FRANCE', 'FR');
            Orga_BU__c region = TestDataFactory.createBURegion(true, 'EU');
            country = TestDataFactory.createBUCountry(true, myCountry, region.Id);
            Orga_BU__c legal = TestDataFactory.createBULegal(true, myCountry);
            store = TestDataFactory.createBUStores(true, country, legal.Id, 1).get(0);
            supplier = TestDataFactory.createSupplier(true, country, true);
            Sup_sup_NegoScope__c NS = TestDataFactory.getNSs(supplier.Id)[0];
            department = TestDataFactory.createDepartment(true, NegoptimHelper.getRootId());
            section = TestDataFactory.createSection(true, department.Id);
            PG = TestDataFactory.createPG(true, supplier.Id, department.Id, section.Id);
            contract = TestDataFactory.createContract(true, NS, date.newInstance(TestDataFactory.year, 1, 1), date.newInstance(TestDataFactory.year, 12, 31));
            Pol_Com_Condition__c tariffCondition = TestDataFactory.createTariffConditions(true, 2, 1)[0];
            condition = TestDataFactory.createCondition(true, tariffCondition, contract, contract.Contract_BDate__c, contract.Contract_EDate__c);
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++');
            System.debug(ex.getMessage());
            System.debug(ex.getStackTraceString());
            System.debug(ex.getLineNumber());
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    static testmethod void test() {
        init();
        Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = 1, Inv_Fiscal_Year__c = TestDataFactory.year,
                                                               Inv_BU__c = store.Id, CurrencyIsoCode = TestDataFactory.currencyIsoCode);
        insert dispatchHead;
        Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Discount__c = condition.Id,Inv_DispatchHead__c = dispatchHead.Id,
                                                                                 Contract__c = contract.Id, Inv_BUDispatch__c = store.Id,
                                                                                 Hierarchy_level_dispatch__c = section.Id,
                                                                                 Sequence__c = 1, CurrencyIsoCode = TestDataFactory.currencyIsoCode,
                                                                                 PG__c = pg.Id, Supplier__c = supplier.Id, Status__c = 'Sent to Accounting');
        insert dispatchDetail;
        Test.startTest();
        Id batchInstanceId = Database.executeBatch(new SetDispatchDetailsStatusBatch('SetDispatchDetailsStatusBatchTest', new List<Id>{contract.BU_Source__c},
                                                                                     new List<Integer>{TestDataFactory.year}, null));
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE Apex_Job_ID__c = :batchInstanceId]);
        System.assertEquals('Updated', [SELECT Status__c FROM Inv_BUDispatch_Details__c WHERE Id = :dispatchDetail.Id].Status__c);
        System.assertEquals(System.today().month(), [SELECT Sequence__c FROM Inv_BUDispatch_Details__c WHERE Id = :dispatchDetail.Id].Sequence__c);
    }
}