/**
* Batchable class used to reset related dispatch details of the PGs after changes of their sections
**/
public with sharing class CancelDispatchingBatch implements Database.Batchable<SObject>, Database.stateful {
    
    private NegoptimBatch nb;
    private final String query;
    private Set<Id> conditionIdSet;
    // Global Settings for last closing day
    public Integer closingDay = GlobalSettingsManager.loadGlobalSettings().invoiceMaxClosingDay;
    
    // Constructor
    public CancelDispatchingBatch(String startedFrom, List<Id> pgIds) {
        
        this.nb = new NegoptimBatch('CancelDispatchingBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.conditionIdSet = new Set<Id>();
        Integer year = Date.today().year();
        // Set default value if null or 0
        closingDay = closingDay == null || closingDay == 0 ? 31 : closingDay;
        
        String q = 'SELECT Id, PG__c, PG__r.Section__c, Hierarchy_level_dispatch__c, Base_TO_Dispatch__c, Discount__c';
        q += ' FROM Inv_BUDispatch_Details__c';
        q += ' WHERE Inv_Fiscal_Year__c = ' + year + '';
        q += ' AND Discount__r.Disc_EDate__c >= TODAY';
        if (pgIds != null && pgIds.size() > 0) {
            q += ' AND PG__c IN (\'' + String.join(pgIds, '\',\'') +'\') ';
        }
        this.query = q;
        // push inputs to log
        nb.logParameter('pgIds', pgIds);
        nb.logParameter('query', this.query);
        nb.logParameter('closingDay', closingDay);
    }
    
    // Start
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    // Execute
    public void execute(Database.BatchableContext bc, List<Inv_BUDispatch_Details__c> scope) {
        List<Inv_BUDispatch_Details__c> dispatchDetailsToUpdateList = new List<Inv_BUDispatch_Details__c>();
        Integer sequence;
        if (Date.today().day() <= closingDay) {
            sequence = Date.today().month() == 1 ? 12 : Date.today().month() - 1;
        } else {
            sequence = Date.today().month();
        }
        // check promo if already synchronized
        for (Inv_BUDispatch_Details__c item : scope) {
            if (!conditionIdSet.contains(item.Discount__c)) {
                conditionIdSet.add(item.Discount__c);
            }
        }        
        if (!conditionIdSet.isEmpty()) {
            for (Commercial_Plan_Detail__c item : [SELECT Id, Prenego_envelop__c FROM Commercial_Plan_Detail__c 
                                                   WHERE Prenego_envelop__c IN :conditionIdSet
                                                   AND (Commercial_Event__r.Status__c = 'Validated'
                                                        OR Commercial_Event__r.Status__c = 'Validate with fact data')])
            {
                if (conditionIdSet.contains(item.Prenego_envelop__c))
                    conditionIdSet.remove(item.Prenego_envelop__c);
            }
        }
        for (Inv_BUDispatch_Details__c item : scope) {
            if (!conditionIdSet.contains(item.Discount__c)) continue; // ignore conditions coming from promo
            if (item.Hierarchy_level_dispatch__c != item.PG__r.Section__c) {
                item.Base_TO_Dispatch__c = 0;
                item.Sequence__c = sequence;
                item.Status__c = 'Updated';
                dispatchDetailsToUpdateList.add(item);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update Inv_BUDispatch_Details__c
            String[] dispatchDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Base_TO_Dispatch__c'),
                NegoptimHelper.normalizeAPIName('Sequence__c'), NegoptimHelper.normalizeAPIName('Status__c')};
            
            if (!dispatchDetailsToUpdateList.isEmpty()) {
                if (NegoptimHelper.checkUpdatibility(Inv_BUDispatch_Details__c.SObjectType, dispatchDetailFields)) {
                    List<Database.SaveResult> results = Database.update(dispatchDetailsToUpdateList, false);
                    nb.logResults(results, dispatchDetailsToUpdateList);
                }
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
        // Call Dispatching Batch.
        if (!conditionIdSet.isEmpty()) {
            Database.executeBatch(new DispatchingBatch('CancelDispatchingBatch', null, null, new List<Id>(conditionIdSet), Date.today()), 25);
        }
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}