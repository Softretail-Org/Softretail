@isTest
private class MassConditionPenaltiesBatchTest {
    
    @isTest static void test_success() {
        String contentData = 'Year,Month,Supplier code,Section code,Condition name,Penalties number,Penalties value,Service rate fact,Service rate target,Penalty date,Appro name,Appro email,Supplier name,Supplier email,Comment,NS Code\r\n';
        contentData += '2017,1,100,1011,Penalties01,1,15,82,92,5/5/2017,appro name1,app1@emai.com,Davidoff,sup1@email.com,com1,00001,NAT\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        
        Test.startTest();
        Database.executeBatch(new MassConditionPenaltiesBatch('Test', csvBlob, ','));
        Test.stopTest();
        
        // Assertion.
        System.assertEquals(1, [SELECT COUNT() FROM Supply_Penalty__c]);
    }
    
    @isTest static void test_fail() {
        String contentData = 'Year,Month,Supplier code,Section code,Condition name,Penalties number,Penalties value,Service rate fact,Service rate target,Penalty date,Appro name,Appro email,Supplier name,Supplier email,Comment,NS Code\r\n';
        contentData += '2017,1,100,1011,Penalties01,1,15,82,92,NOT_VALID_DATE,appro name1,app1@emai.com,Davidoff,sup1@email.com,com1,00001,MPX\r\n';
        Blob csvBlob = Blob.valueOf(contentData);
        
        Test.startTest();
        Database.executeBatch(new MassConditionPenaltiesBatch('Test', csvBlob, ','));
        Test.stopTest();
        
        // Assertion.
        System.assertEquals(0, [SELECT COUNT() FROM Supply_Penalty__c]);
    }
}