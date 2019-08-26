@IsTest
private class ClearLogsBatchTest {
    private static Log__c log1;
    private static Log__c log2;
    private static Log__c log3;
    private static Log__c log4;
    private static Log__c log5;
    private static Log__c log6;
    private static Log__c log7;
    private static Log__c log8;
    
    static void init() {
        List<Log__c> logs = new List<Log__c>();
        
        log1 = new Log__c();
        log1.JobType__c = 'BatchApex';
        log1.Status__c = 'Completed';
        log1.CompletedDate__c = Date.today();
        logs.add(log1);
        
        log2 = new Log__c();
        log2.JobType__c = 'BatchApex';
        log2.Status__c = 'Failed';
        log2.CompletedDate__c = Date.today();
        logs.add(log2);
        
        log3 = new Log__c();
        log3.JobType__c = 'BatchApex';
        log3.Status__c = 'Aborted';
        log3.CompletedDate__c = Date.today();
        logs.add(log3);
        
        log4 = new Log__c();
        log4.JobType__c = 'BatchApex';
        log4.Status__c = 'Completed';
        log4.CompletedDate__c = Date.today() - 30;
        logs.add(log4);
        
        log5 = new Log__c();
        log5.JobType__c = 'BatchApex';
        log5.Status__c = 'Failed';
        log5.CompletedDate__c = Date.today() - 30;
        logs.add(log5);
        
        log6 = new Log__c();
        log6.JobType__c = 'BatchApex';
        log6.Status__c = 'Completed';
        log6.CompletedDate__c = date.today() - 40;
        logs.add(log6);
        
        log7 = new Log__c();
        log7.JobType__c = 'BatchApex';
        log7.Status__c = 'Completed';
        log7.CompletedDate__c = date.today() + 1;
        logs.add(log7);
        
        log8 = new Log__c();
        log8.JobType__c = 'BatchApex';
        log8.Status__c = 'Aborted';
        log8.CompletedDate__c = date.today() + 1;
        logs.add(log8);
        
        try {
            insert logs;
        } catch (DMLException ex) {
            System.debug('Exception: ' + ex.getMessage());
        }
    }
    
    @IsTest static void testDateAndStatusNotNull() {
        init();
        //start test
        Test.startTest();
        Database.executeBatch(new ClearLogsBatch('ClearLogsBatchTest', new List<String>{'Failed', 'Aborted'}, Date.today()));
        Test.stopTest();
        //get data
        Set<Id> remainingLogs = new Set<Id>();
        for (Log__c log : [SELECT Id FROM Log__c]) {
            remainingLogs.add(log.Id);
        }
        //assertions
        System.assertEquals(5, remainingLogs.size());
        System.assert(remainingLogs.contains(log1.Id));
        System.assert(remainingLogs.contains(log4.Id));
        System.assert(remainingLogs.contains(log6.Id));
        System.assert(remainingLogs.contains(log7.Id));
        System.assert(remainingLogs.contains(log8.Id));
        
    }
    
    @IsTest static void testDateNull() {
        init();
        //start test
        Test.startTest();
        Database.executeBatch(new ClearLogsBatch('ClearLogsBatchTest', new List<String>{'Failed', 'Aborted'}, null));
        Test.stopTest();
        //get data
        Set<Id> remainingLogs = new Set<Id>();
        for (Log__c log : [SELECT Id FROM Log__c]) {
            remainingLogs.add(log.Id);
        }
        //assertions
        System.assertEquals(7, remainingLogs.size());
        System.assert(remainingLogs.contains(log1.Id));
        System.assert(remainingLogs.contains(log2.Id));
        System.assert(remainingLogs.contains(log3.Id));
        System.assert(remainingLogs.contains(log4.Id));
        System.assert(remainingLogs.contains(log6.Id));
        System.assert(remainingLogs.contains(log7.Id));
        System.assert(remainingLogs.contains(log8.Id));
    }
    
    @IsTest static void testStatusNull() {
        init();
        //start test
        Test.startTest();
        Database.executeBatch(new ClearLogsBatch('ClearLogsBatchTest', null, Date.today()));
        Test.stopTest();
        //get data
        Set<Id> remainingLogs = new Set<Id>();
        for (Log__c log : [SELECT Id FROM Log__c]) {
            remainingLogs.add(log.Id);
        }
        //assertions
        System.assertEquals(5, remainingLogs.size());
        System.assert(remainingLogs.contains(log2.Id));
        System.assert(remainingLogs.contains(log3.Id));
        System.assert(remainingLogs.contains(log5.Id));
        System.assert(remainingLogs.contains(log7.Id));
        System.assert(remainingLogs.contains(log8.Id));
    }
    
    @IsTest static void testStatusAndDateNull() {
        init();       
        Test.startTest();
        Database.executeBatch( new ClearLogsBatch('ClearLogsSchedule', null, null));
        Test.stopTest();
        //get data
        Set<Id> remainingLogs = new Set<Id>();
        for (Log__c log : [SELECT Id FROM Log__c]) {
            remainingLogs.add(log.Id);
        }
        //assertions
        System.assertEquals(6, remainingLogs.size());
        System.assert(remainingLogs.contains(log1.Id));
        System.assert(remainingLogs.contains(log2.Id));
        System.assert(remainingLogs.contains(log3.Id));
        System.assert(remainingLogs.contains(log5.Id));
        System.assert(remainingLogs.contains(log7.Id));
        System.assert(remainingLogs.contains(log8.Id));
    }
    
  
}