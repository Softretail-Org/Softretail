/**
* Batchable class used to scan group Commercial Plan
**/
public with sharing class CommercialPlanScanBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    private final String query;
    private final Id country;
    private final Integer year;
    
    // Constructor.
    public CommercialPlanScanBatch(String startedFrom, List<Id> ids, Id countryId, String selectedDate, Boolean fillContract, Boolean updateStatus) {
        
        this.nb = new NegoptimBatch('Commercial Plan Scan', NegoptimBatch.BatchType.Stateless, startedFrom);
        country = countryId;
        String q = 'SELECT Id, Name, Event_Start_Date__c, Event_End_Date__c, Temp_Contract_Reference__c, ';
        q += 'Applicable_Rate_Formula__c, Applicable_Rate_Manual__c, Contract__c, Contract__r.Contract_BU__c, Nego_Scope__c, ';
        q += 'Action_done__c, Statut__c, Line_Status__c, Extraction_Status__c, Contribution_Total__c, ';
        q += 'Product_1__c, Product_2__c, Product_3__c, Product_4__c, Product_5__c,Product_6__c, Product_7__c, Product_8__c, ';
        q += 'Product_9__c, Product_10__c, Product_11__c, Product_12__c, Product_13__c, Product_14__c, Product_15__c, Product_16__c, ';
        q += 'Product_17__c, Product_18__c, Product_19__c, Product_20__c, Product_21__c, Product_22__c, Product_23__c, Product_24__c, ';
        q += 'Product_25__c, Product_26__c, Product_27__c, Product_28__c, Product_29__c, Product_30__c, Agreement_Start_Date__c, Agreement_End_Date__c ';
        q += 'FROM Commercial_Plan_Detail__c ';
        if(fillContract && updateStatus){
            q += 'Where (Contract__c = NULL OR (Contract__c <> NULL AND Agreement_End_Date__c <= TOMORROW AND Extraction_Status__c <> \'Extracted\' AND Statut__c <> \'Deleted\')) ';
        }
        else if(fillContract){
            q += 'Where (Contract__c = NULL) ';
        }
        else if(updateStatus){
            q += 'Where (Contract__c <> NULL AND Agreement_End_Date__c <= TOMORROW AND Extraction_Status__c <> \'Extracted\' AND Statut__c <> \'Deleted\') ';
        }
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        if(string.isNotBlank(countryId)) {
            q += ' AND Contract__r.Contract_BU__c = \'' + country + '\'';
        }
        if(string.isNotBlank(selectedDate)){
            year = Date.valueOf(selectedDate).year();
            q += ' AND CALENDAR_YEAR(Agreement_Start_Date__c) = ' + year + '';
        }
        query = q;
        // push inputs to log
        nb.logParameter('startedFrom', startedFrom);
        nb.logParameter('commercialPlanDetailIds', ids);
        nb.logParameter('countryId', countryId);
        nb.logParameter('selectedDate', selectedDate);
        nb.logParameter('fillContract', fillContract);
        nb.logParameter('updateStatus', updateStatus);
        nb.logParameter('query', this.query);
    }
    
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Start Execute
    public void execute(Database.BatchableContext bc, List<Commercial_Plan_Detail__c> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            if(scope != null && scope.size() > 0){
                List<Database.SaveResult> results = Database.update(scope, false);
                nb.logResults(results, scope);
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.saveLog(bc);
    }
    
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}