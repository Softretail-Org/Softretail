/**
 * @author ULiT
 * @description Test class for CounterpartiesScanBatch
 * */
@isTest
private class CounterpartiesScanBatchTest {
    
    private static Integer year = TestDataFactory.year;
    private static String currencyIsoCode;
    private static Orga_BU__c region;
    private static Orga_BU__c country;
    private static Orga_BU__c groupBU;
    private static Sup_Supplier__c supplier;
    private static Sup_sup_NegoScope__c NS;
    private static Contract__c contract;
    private static Pol_Com_Condition__c tariffCondition;
    private static Contract_Discount__c condition;
    private static String eventSupportValue;
    
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
            contract = TestDataFactory.createContract(false, NS, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            contract.Last_Active_Contract__c = true;
            contract.Contract_BU__c = groupBU.Id;
            insert contract;
            // Create Policy - Tariff Conditions.
            tariffCondition = TestDataFactory.createTariffCondition(false, 0, 1);
            tariffCondition.Proof_counterparty_requested__c = true;
            insert tariffCondition;
            // Create condition.
            condition = TestDataFactory.createCondition(false, tariffCondition, contract, date.newInstance(year, 1, 1), date.newInstance(year, 12, 31));
            insert condition;
            Schema.DescribeFieldResult fieldResult = Contract_discount_counterparty_detail__c.Event_Support__c.getDescribe();
            eventSupportValue = fieldResult.getPicklistValues().get(0).getValue();
        } catch (Exception ex) {
            System.debug('++++++++++++++++++++++++++++++'); 
            System.debug(ex.getMessage() ); 
            System.debug(ex.getStackTraceString() );
            System.debug('++++++++++++++++++++++++++++++');
        }
    }
    
    // Case update contract
    @isTest static void caseUpdateCounterpartyContract_success() {
        init();
        Schema.DescribeFieldResult fieldResult = Contract_discount_counterparty_detail__c.Event_Support__c.getDescribe();
        // insert counterparty
        Contract_discount_counterparty_detail__c counterparty = new Contract_discount_counterparty_detail__c(Nego_Scope__c = NS.Id, Start_Date__c = contract.Contract_BDate__c, End_Date__c = System.today() + 1,
                                                                                                             Supplier__c = supplier.Id, Extraction_Status__c = null, Contribution_Unit_Amount__c = 1000,
                                                                                                             Proof_Status__c = null, Event_Support__c = eventSupportValue);
        insert counterparty;
        Test.startTest();
        Database.executeBatch(new CounterpartiesScanBatch('CounterpartiesScanBatch', new List<Id>{counterparty.Id}, null, null, true, false));
        Test.stopTest();
        // Validation Test
        counterparty = [SELECT Id, Contract__c, Line_Status__c, Extraction_Status__c FROM Contract_discount_counterparty_detail__c WHERE Id = :counterparty.Id];
        System.assertEquals(contract.Id, counterparty.Contract__c);
    }
    
    // Case update status
    @isTest static void caseUpdateCounterpartyStatus_success() {
        init();
        // insert counterparty
        Contract_discount_counterparty_detail__c counterparty = new Contract_discount_counterparty_detail__c(Nego_Scope__c = NS.Id, Start_Date__c = contract.Contract_BDate__c, End_Date__c = System.today() + 1,
                                                                                                             Supplier__c = supplier.Id, Extraction_Status__c = null, Contribution_Unit_Amount__c = 1000,
                                                                                                             Proof_Status__c = 'Contract Edited', Contract__c = contract.Id, Contract_discount__c = condition.Id,
                                                                                                             Event_Support__c = eventSupportValue);
        system.debug('counterparty>>>'+counterparty);
        insert counterparty;
        Test.startTest();
        Database.executeBatch(new CounterpartiesScanBatch('CounterpartiesScanBatch', new List<Id>{counterparty.Id}, groupBU.Id, String.valueOf(counterparty.Start_Date__c), false, true));
        Test.stopTest();
        // Validation Test
        counterparty = [SELECT Id, Contract__c, Line_Status__c, Extraction_Status__c FROM Contract_discount_counterparty_detail__c WHERE Id = :counterparty.Id];
        System.assertEquals('Extract', counterparty.Extraction_Status__c);
    }
}