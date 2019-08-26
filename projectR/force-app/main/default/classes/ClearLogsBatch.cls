/**
* batch class to delete completed log before 1 month using NegoptimBatch class; 
**/
public class ClearLogsBatch implements Database.Batchable<SObject> {
    
    private final String query;
    private final Date theDate;
    private String startedFrom;
    
    public ClearLogsBatch(String startedFrom, List<String> statusList, Date d) {
        this.startedFrom = startedFrom;
        theDate = d == null ? System.today().addDays(-30) : d;
        List<String> statuses = statusList == null ? new List<String>{'Completed'} : statusList;
        String q = 'SELECT Id FROM Log__c';
        q += ' WHERE JobType__c = \'BatchApex\'';
        q += ' AND CompletedDate__c <= :theDate';
        q += ' AND Status__c IN (\'' + String.join(statuses, '\',\'') +'\')';
        this.query = q;
        System.debug(this.query);
    }
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method.
    public void execute(Database.BatchableContext bc,List<Log__c> logs){
        try {
            delete logs;
            if (startedFrom.equalsIgnoreCase('ClearLogsSchedule')) {   
                Database.emptyRecycleBin(logs);
            }
        } catch(Exception ex) {
            System.debug('Exception: ' + ex.getMessage() + ' - Line: ' + ex.getLineNumber());
        }
    }
    // Finish
    public void finish(Database.BatchableContext bc){
        System.debug('finish');
    }
}