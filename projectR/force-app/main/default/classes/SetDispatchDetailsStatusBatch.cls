/**
* Batchable class used to set Status of Dispatch Details after account closing
**/
public with sharing class SetDispatchDetailsStatusBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    private final String query;
    private final List<Id> buIds;
    private final List<Integer> years;
    private final Integer month;
    
    // Constructor
    public SetDispatchDetailsStatusBatch(String startedFrom, List<Id> buIds, List<Integer> years, Integer month) {
        
        this.nb = new NegoptimBatch('Set Dispatch Details Status', NegoptimBatch.BatchType.Stateless, startedFrom);
        this.buIds = buIds;
        this.years = years;
        this.month = month == null ? System.today().month() : month;
        
        String q = 'SELECT Id';
        q += ' FROM Inv_BUDispatch_Details__c';
        q += ' WHERE Status__c = \'Sent to Accounting\'';
        if(this.buIds != null && this.buIds.size() > 0) {
            q += ' AND Contract__r.BU_Source__c IN (\'' + String.join(this.buIds, '\',\'') +'\') ';
        }
        if(this.years != null && this.years.size() > 0) {
            q += ' AND Inv_Fiscal_Year__c IN (' + String.join(this.years, ',') + ') ';
        }
        this.query = q;
        // push inputs to log
        nb.logParameter('buIds', this.buIds);
        nb.logParameter('this.years', this.years);
        nb.logParameter('query', this.query);
    }
    
    // Start
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    // Execute
    public void execute(Database.BatchableContext bc, List<Inv_BUDispatch_Details__c> scope) {        
        for (Inv_BUDispatch_Details__c item : scope) {
            item.Sequence__c = this.month;
            item.Status__c = 'Updated';
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update contract fields
            if(NegoptimHelper.checkUpdatibility(Inv_BUDispatch_Details__c.SObjectType, new String[] {NegoptimHelper.normalizeAPIName('Status__c')})) {
                List<Database.SaveResult> results = Database.update(scope, false);
                nb.logResults(results, scope);
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError(e);
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.saveLog(bc);
    }
    // Finish
    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}