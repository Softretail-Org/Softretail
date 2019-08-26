/**
* Calculate already invoiced for conditions.
**/
public with sharing class CalculateAlreadyInvoicedBatch implements Database.Batchable<sObject>, Database.stateful  {
    
    private NegoptimBatch nb;
    public final String query;
    
    // Constructor.
    public CalculateAlreadyInvoicedBatch(String startedFrom, List<Id> ids) {
        this.nb = new NegoptimBatch('CalculateAlreadyInvoicedBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        String q = 'SELECT Id, Name, CurrencyIsoCode, Invoice_base__c, Already_Invoiced__c, Already_Invoiced_Edited__c';
        q += ' FROM Contract_Discount__c';
        if(ids != null && ids.size() > 0) {
            q += ' WHERE Id IN (\'' + String.join(ids, '\',\'') +'\')';
        }
        query = q;
        // push inputs to log
        nb.logParameter('conditionIds', ids);
        nb.logParameter('query', this.query);
    }
    
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Contract_Discount__c> scope) {
        List<Id> conditionIds = new List<Id>(new Map<Id, Contract_Discount__c>(scope).keySet());
        Map<Id, List<AggregateResult>> invoiceDetailsMap = new Map<Id, List<AggregateResult>>();
        for(AggregateResult item :  [SELECT Discount__c Id, SUM(Invoice_Value__c) Total_Invoice_Value, Invoice__r.Inv_Status__c inv_status
                                     FROM Invoice_Detail__c
                                     WHERE Discount__c IN :conditionIds
                                     GROUP BY Discount__c, Invoice__r.Inv_Status__c])
        {
            Id conditionId = (Id)item.get('Id');
            if(invoiceDetailsMap.containsKey(conditionId)) {
                invoiceDetailsMap.get(conditionId).add(item);
            } else {
                invoiceDetailsMap.put(conditionId, new List<AggregateResult>{item});
            }
        }
        // Load map of currencies with exchange rate
        Map<String, Double> currencies = NegoptimHelper.getCurrencyMap();
        Decimal alreadyInvoiced, alreadyInvoicedAndEdited;
        List<Contract_Discount__c> conditionsToUpdate = new List<Contract_Discount__c>();
        // Get corresponding total invoice line value for each condition to substract from the original value.
        for(Contract_Discount__c item : scope) {
            if(invoiceDetailsMap.containsKey(item.Id)) {
                alreadyInvoiced = 0;
                alreadyInvoicedAndEdited = 0;
                Decimal conversionRate = currencies.get(item.CurrencyIsoCode);
                for(AggregateResult ar : invoiceDetailsMap.get(item.Id)) {
                    if(ar != null && ar.get('Total_Invoice_Value') != null) {
                        alreadyInvoiced += Decimal.valueOf(String.valueOf(ar.get('Total_Invoice_Value')));
                        if (ar.get('inv_status') == 'Printed') {
                            alreadyInvoicedAndEdited += Decimal.valueOf(String.valueOf(ar.get('Total_Invoice_Value')));
                        }
                    }
                }
                alreadyInvoiced = (alreadyInvoiced * conversionRate).setScale(2);
                alreadyInvoicedAndEdited = (alreadyInvoicedAndEdited * conversionRate).setScale(2);
                if(item.Already_Invoiced__c != alreadyInvoiced || item.Already_Invoiced_Edited__c != alreadyInvoicedAndEdited) {
                    item.Already_Invoiced__c = alreadyInvoiced;
                    item.Already_Invoiced_Edited__c = alreadyInvoicedAndEdited;
                    conditionsToUpdate.add(item);
                    nb.logMessage(item.Name + ' - ' + item.Id);
                }
            } else {
                if(item.Already_Invoiced__c != null || item.Already_Invoiced_Edited__c != null) {
                    item.Already_Invoiced__c = null;
                    item.Already_Invoiced_Edited__c = null;
                    conditionsToUpdate.add(item);
                    nb.logMessage(item.Name + ' - ' + item.Id);
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update Contract_Discount__c
            String[] conditionFields = new String[] { NegoptimHelper.normalizeAPIName('Already_Invoiced__c'), NegoptimHelper.normalizeAPIName('Already_Invoiced_Edited__c')};
            if(!conditionsToUpdate.isEmpty()) {
                if (NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionFields)) {
                    List<Database.SaveResult> results = Database.update(conditionsToUpdate, false);
                    nb.logResults(results, conditionsToUpdate);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError(e);
        } catch (Exception e) {
            // Roll everything back in case of error.
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
    
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
        if(nb.getNumberOfMessages() > 0) {
            nb.sendMessages(bc);
        }
    }
}