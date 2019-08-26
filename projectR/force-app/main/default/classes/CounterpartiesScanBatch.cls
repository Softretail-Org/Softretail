/**
 * @author ULiT
 * @description Batchable class used to scan Contract_discount_counterparty_detail__c
 * */
public with sharing class CounterpartiesScanBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    private Id country;
    private Integer year;
    // case updated Contract__c
    private Boolean updateContract;
    // case update Extraction_Status__c
    private Boolean updateStatus;
    
    // Constructor.
    public CounterpartiesScanBatch(String startedFrom, List<Id> ids, Id countryId, String selectedDate, Boolean updateContract, Boolean updateStatus) {
        this.nb = new NegoptimBatch('CounterpartiesScanBatch', NegoptimBatch.BatchType.Stateless, startedFrom);
        this.country = countryId;
        this.updateContract = updateContract == null ? false : updateContract;
        this.updateStatus = updateStatus == null ? false : updateStatus;
        
        String q = 'SELECT Id, Name, End_Date__c, Start_Date__c, Temp_Contract_Reference__c,';
        q += ' Applicable_Rate_Formula__c, Applicable_Rate_Manual__c, Contract__c, Contract__r.Contract_BU__c, Nego_Scope__c,';
        q += ' Proof_status__c, Line_Status__c, Extraction_Status__c';
        q += ' FROM Contract_discount_counterparty_detail__c';
        
        String contractFilter = '(Contract__c = NULL)';
        String statusFilter = '(Contract__c <> NULL AND Contract_discount__c <> NULL AND End_Date__c <= TOMORROW AND Extraction_Status__c = NULL';
        statusFilter += ' AND Proof_Status__c = \'Contract Edited\' AND Line_Status__c <> \'Deleted\' AND Contract__r.Contract_BU__r.RecordType.DeveloperName = \'Group\')';
        if(updateContract && updateStatus) {
            q += ' Where (' + contractFilter + ' OR ' + statusFilter + ')';
        }
        else if(updateContract) {
            q += ' Where ' + contractFilter;
        }
        else if(updateStatus) {
            q += ' Where ' + statusFilter;
        }
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\')';
        }
        if(string.isNotBlank(countryId)) {
            q += ' AND Contract__r.Contract_BU__c = \'' + country + '\'';
        }
        if(string.isNotBlank(selectedDate)) {
            year = Date.valueOf(selectedDate).year();
            q += ' AND CALENDAR_YEAR(Start_Date__c) = ' + year + '';
        }
        query = q;
        // push inputs to log
        nb.logParameter('startedFrom', startedFrom);
        nb.logParameter('ids', ids);
        nb.logParameter('countryId', countryId);
        nb.logParameter('selectedDate', selectedDate);
        nb.logParameter('updateContract', updateContract);
        nb.logParameter('updateStatus', updateStatus);
        nb.logParameter('query', this.query);
    }
    
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Start Execute
    public void execute(Database.BatchableContext bc, List<Contract_discount_counterparty_detail__c> scope) {
        Set<Id> negoScopeSet = new Set<Id>();
        List<Contract_discount_counterparty_detail__c> counterpartyList = new List<Contract_discount_counterparty_detail__c>();

        Savepoint sp = Database.setSavepoint();
        try {
            for(Contract_discount_counterparty_detail__c item : scope) {
                // case update Status
                if(this.updateStatus) {
                    item.Extraction_Status__c = 'Extract';
                    counterpartyList.add(item);
                }
                // case update contract
                if(this.updateContract) {
                    // check if contract discount counterparty with contract reference null
                    if(item.Nego_Scope__c != null) {
                        negoScopeSet.add(item.Nego_Scope__c);
                    }
                }
            }
            // Map<Nego Scope Id, List Contract>
            Map<Id, List<Contract__c>> nsContractMap = new Map<Id, List<Contract__c>>();
            // Get all contract related to Nego Scope
            if(!negoScopeSet.isEmpty()) {
                for(Sup_sup_NegoScope__c item : [SELECT Id, Name, (SELECT Id, Name, Contract_Numbder__c, Supplier_Nego_Scope__c, Contract_BDate__c,
                                                                   Contract_EDate__c, Contract_BU__r.RecordTypeId, Last_Active_Contract__c
                                                                   FROM Contracts1__r WHERE Contract_Type__c = 'Contract'
                                                                   ORDER BY Contract_BDate__c DESC)
                                                 FROM Sup_sup_NegoScope__c WHERE Id IN :negoScopeSet])
                {
                    if(!nsContractMap.containsKey(item.Id)) {
                        nsContractMap.put(item.Id, item.Contracts1__r);
                    }
                }
            }
            if(this.updateContract) {
                for(Contract_discount_counterparty_detail__c item : scope) {
                    if(nsContractMap.containsKey(item.Nego_Scope__c)) {
                        List<Contract__c> contracts = nsContractMap.get(item.Nego_Scope__c);
                        Contract__c lastActiveContract = null;
                        for(Contract__c contract :contracts) {
                            if(contract.Last_Active_Contract__c == true) {
                                lastActiveContract = contract;
                            }
                            if(contract.Contract_BDate__c <= item.Start_Date__c && contract.Contract_EDate__c >= item.Start_Date__c) {
                                item.Contract__c = contract.Id;
                                item.Temp_Contract_Reference__c = null;
                                counterpartyList.add(item);
                                break;
                            }
                        }
                        if(item.Contract__c == null && String.isBlank(item.Temp_Contract_Reference__c) && lastActiveContract != null) {
                            item.Temp_Contract_Reference__c = lastActiveContract.Contract_Numbder__c +' - '+ lastActiveContract.Name;
                            counterpartyList.add(item);
                        }
                    }
                }
            }
            
            // check security on updated counterpart fields
            String[] counterpartUpdatedFields = new String[] {NegoptimHelper.normalizeAPIName('Contract__c'),
                NegoptimHelper.normalizeAPIName('Temp_Contract_Reference__c'), NegoptimHelper.normalizeAPIName('Extraction_Status__c')};
           
            // update counterparty list
            if(!counterpartyList.isEmpty()) {
                if(NegoptimHelper.checkUpdatibility(Contract_discount_counterparty_detail__c.SObjectType, counterpartUpdatedFields)) {
                    List<Database.SaveResult> results = Database.update(counterpartyList, false);
                    nb.logResults(results, counterpartyList);
                }
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