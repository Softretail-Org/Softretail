/**
* Batchable class used to scan last active contract for Nego Scope
**/
public with sharing class LastActiveContractBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    private final String query;
    private final Id country;
    
    // Constructor.
    public LastActiveContractBatch(String startedFrom, Id countryId, List<Id> ids) {
        
        this.nb = new NegoptimBatch('Last Active Contract', NegoptimBatch.BatchType.Stateless, startedFrom);
        country = countryId;
        // Re-query for the masters NS, including the last 2 contracts
        String q = 'SELECT ns.Id, ns.Name,';
        q += ' (SELECT Id, Name, Last_Active_Contract__c, Contract_BDate__c, Contract_EDate__c';
        q += ' FROM Contracts1__r WHERE Status__c <> \'Deleted\'';
        q += ' ORDER BY Contract_BDate__c DESC LIMIT 2)';
        q += ' FROM Sup_sup_NegoScope__c ns';
        q += ' WHERE Parent_Nego_Scope__c = NULL';
        if(ids != null && ids.size() > 0) {
            q += ' AND ns.Id IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        if(countryId != NULL) {
            q += ' AND ns.Supplier__r.Country_origin__c = \'' + country + '\'';
        }
        query = q;
        
        // push inputs to log
        nb.logParameter('countryId', countryId);
        nb.logParameter('negoScopeIds', ids);
        nb.logParameter('query', this.query);
    }
    
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method
    public void execute(Database.BatchableContext bc, List<Sup_sup_NegoScope__c> scope) {        
        List<Contract__c> updatedContracts = new List<Contract__c>();
        Contract__c lastContract, prvContract;
        for (Sup_sup_NegoScope__c item : scope) {
            if(item.Contracts1__r != null && item.Contracts1__r.size() > 0){
                if(item.Contracts1__r.size() == 1 && item.Contracts1__r[0].Last_Active_Contract__c == false){
                    lastContract = item.Contracts1__r[0];
                    lastContract.Last_Active_Contract__c = true;
                    updatedContracts.add(lastContract);
                }
                else if (item.Contracts1__r.size() == 2) {
                    lastContract = item.Contracts1__r[0];
                    prvContract = item.Contracts1__r[1];
                    if((lastContract.Contract_BDate__c <= Date.today() && lastContract.Contract_EDate__c >= Date.today())
                       || (lastContract.Contract_EDate__c < Date.today()))
                    {
                        if(lastContract.Last_Active_Contract__c == false){
                            lastContract.Last_Active_Contract__c = true;
                            updatedContracts.add(lastContract);
                        }
                        if(prvContract.Last_Active_Contract__c == true){
                            prvContract.Last_Active_Contract__c = false;
                            updatedContracts.add(prvContract);
                        }
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update contract fields
            String[] contractFields = new String[] {NegoptimHelper.normalizeAPIName('Last_Active_Contract__c')};
            if(NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractFields) &&
               updatedContracts != null && updatedContracts.size() > 0)
            {
                List<Database.SaveResult> results = Database.update(updatedContracts, false);
                nb.logResults(results, updatedContracts);
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
        if (nb.getStartedFrom().equalsIgnoreCase('LastActiveContractSchedule') || nb.getStartedFrom().equalsIgnoreCase('MassBatchForm')) {
        	// Execute GenerateGRCRatesBatch
        	Database.executeBatch(new GenerateGRCRatesBatch('LastActiveContractBatch', null, null, null, true));
        }
    }
}