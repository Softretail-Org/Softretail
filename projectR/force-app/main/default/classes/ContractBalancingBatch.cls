/*
 * - Scan the balancing process corresponds to the closing steps for the contract.
 * - When finish GenerateInvoicesBatch.
 * - When finish execute AccountingClosingBatch called from accounting closing trigger.
 * - Fill the fields Balancing_Events_List__c for contract and Balancing_Invoices_List__c for conditions
 */ 
public with sharing class ContractBalancingBatch implements Database.Batchable<sObject>, Database.stateful {
    
    private NegoptimBatch nb;
    public final String query;
    private Set<Id> contractIdSet;
    
    // Constructor.
    public ContractBalancingBatch(String startedFrom, List<Id> ids) {
        nb = new NegoptimBatch('Contract Balancing', NegoptimBatch.BatchType.stateful, startedFrom);
        contractIdSet = new Set<Id>();
        String q = 'SELECT Id, Name, Contract_BDate__c, Contract_EDate__c, Total_TO__c, Total_TO_Fact__c, Contract_BU__c,';
        q += ' Total_Marketing_Events_Justified__c, Total_Marketing_Events_to_Justify__c, Contract_Type__c, Status__c, Balancing_Action_ToDo__c,';
        q += ' (SELECT Event_Code__c, Event_Name__c, Event_Start_Date__c, Event_End_Date__c FROM Marketing_Event_Details__r)';
        q += ' FROM Contract__c';
        q += ' WHERE Status__c = \'Signed\' AND Contract_Type__c = \'Contract\'';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\')';
        }
        query = q;
        nb.logParameter('query', this.query);
        nb.logParameter('ids', ids);
    }
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Contract__c> scope) {
        /* 1. Prepare Declaration. */
        // List Contract + conditions to update
        List<SObject> contractWithConditionsList = new List<SObject>();
        // List of wrapper contract
        List<WrapperContract> wContractList = new List<WrapperContract>();
        /* 2. Prepare Process Balancing Contract. */
        try {
            // Get contract balancing settings
            NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
            for(Contract__c item : scope) {
                WrapperContract wContract = new WrapperContract(item);
                // Check balancing contract
                wContract.scanBalancingContract(negoSettings);
                // Fill balancing Results
                if(wContract.allowBalancing) {
                    wContract.contract.Status__c = 'Balanced';
                    wContract.contract.Balancing_Contract__c = true;
                    // Fill list of contracts for generate invoicing
                    if(!contractIdSet.contains(item.Id)){
                        contractIdSet.add(item.Id);
                    }
                }
                wContract.contract.Balancing_Action_ToDo__c = wContract.actionToDoMessage;
                wContract.contract.Balancing_Action_Executed__c = wContract.actionDoneMessage;
                wContractList.add(wContract);
            }
            Savepoint sp = Database.setSavepoint();
            try {
                for (WrapperContract item : wContractList) {                
                    contractWithConditionsList.add(item.contract);
                }
                // Fill the fields Balancing_Invoices_List__c for conditions related to scope
                String invoiceText;
                Set<String> invoiceNumberSet = new Set<String>();
                for(Contract_Discount__c item : [SELECT Id, (SELECT Invoice__r.Invoice_Number__c, Invoice__r.Inv_Date__c
                                                             FROM Invoice_Details__r
                                                             WHERE Invoice__r.Invoice_Number__c <> null)
                                                 FROM Contract_Discount__c
                                                 WHERE Contract__c IN :scope])
                {
                    invoiceText = '';
                    // fill by related invoices
                    for(Invoice_Detail__c invoiceDetail : item.Invoice_Details__r) {
                        if(!invoiceNumberSet.contains(invoiceDetail.Invoice__r.Invoice_Number__c)) {
                            invoiceNumberSet.add(invoiceDetail.Invoice__r.Invoice_Number__c);
                            invoiceText += invoiceDetail.Invoice__r.Invoice_Number__c + ' du ';
                            invoiceText += invoiceDetail.Invoice__r.Inv_Date__c != null ? invoiceDetail.Invoice__r.Inv_Date__c.format() : '[NO DATE]';
                            invoiceText += '\n';
                        }
                    }
                    item.Balancing_Invoices_List__c = invoiceText;
                    contractWithConditionsList.add(item);
                }
                // Update contract + conditions
                if(contractWithConditionsList != null && contractWithConditionsList.size() > 0) {
                    List<Database.SaveResult> results = Database.update(contractWithConditionsList, false);
                    /*for (Integer i = 0; i < scope.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        SObject obj = contractWithConditionsList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = String.valueOf(obj.getSObject('Name')) + ' (Id=' + String.valueOf(obj.getSObject('Id')) + ') : ';
                            Database.Error[] errs = result.getErrors();
                            for (Database.Error err : errs) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        }
                    }*/
                    nb.logResults(results, contractWithConditionsList);
                }
            } catch(dmlexception e) {
                Database.rollback(sp);
                nb.logError(e);
            }
        } catch (Exception ex) {
            nb.logError(ex);
        }
        nb.incrementBatchIndex();
    }
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(BC).Status;
        nb.sendEmail(bc, null, customSubject);
        // TODO: Execute Generate Invoices Batch.
        if (contractIdSet != null && contractIdSet.size() > 0) {
            Database.executeBatch(new GenerateInvoicesBatch('ContractBalancingBatch', null, new List<Id>(contractIdSet), null, Date.Today()));
        }
    }
    /* Wrapper Class for Contract */
    public class WrapperContract {
        Contract__c contract {get; set;}
        Boolean allowBalancing {get; set;}
        String actionToDoMessage {get; set;}
        String actionDoneMessage {get; set;}
        // constructor
        public WrapperContract(Contract__c c) {
            contract = c;
            // fill by related events
            String eventText = '';
            for (Commercial_Plan_Detail__c eventDetail : contract.Marketing_Event_Details__r) {
                eventText += eventDetail.Event_Code__c != null ? eventDetail.Event_Code__c  + ' - ' : '';
                eventText += eventDetail.Event_Name__c + ' du ';
                eventText += eventDetail.Event_Start_Date__c != null ? eventDetail.Event_Start_Date__c.format() : '[NO DATE]';
                eventText += ' au ';
                eventText += eventDetail.Event_End_Date__c != null ? eventDetail.Event_End_Date__c.format() : '[NO DATE]';
                eventText += '\n';
            }
            c.Balancing_Events_List__c = eventText;
            allowBalancing = True;
            actionToDoMessage = '';
            actionDoneMessage = '';
        }
        // scan balancing contract
        public void scanBalancingContract(NegoptimSettings negoSettings) {
            if(negoSettings.tOGapTolerenceNegative == null) negoSettings.tOGapTolerenceNegative = 0;
            if(negoSettings.tOGapTolerencePositive == null) negoSettings.tOGapTolerencePositive = 0;
            if(negoSettings.coopGapTolerenceNegative == null) negoSettings.coopGapTolerenceNegative = 0;
            if(negoSettings.coopGapTolerencePositive == null) negoSettings.coopGapTolerencePositive = 0;
            if(contract.Contract_EDate__c > system.today()){
                this.actionToDoMessage += Label.MSG_Contract_End_Date_Not_Allow_Balancing + '\n';
                this.allowBalancing = false;
            }
            Decimal totalTO, totalTOFact, totalMarketingEventsToJustify, totalMarketingEventsJustified;
            totalTO = contract.Total_TO__c != null ? contract.Total_TO__c : 0;
            totalTOFact = contract.Total_TO_Fact__c != null ? contract.Total_TO_Fact__c : 0;
            totalMarketingEventsToJustify = contract.Total_Marketing_Events_to_Justify__c != null ? contract.Total_Marketing_Events_to_Justify__c : 0; 
            totalMarketingEventsJustified = contract.Total_Marketing_Events_Justified__c != null ? contract.Total_Marketing_Events_Justified__c :0;
            Boolean checkTotalTO = (((totalTO * (1 - negoSettings.tOGapTolerenceNegative)) <= totalTOFact) &&
                                    ((totalTO * (1 + negoSettings.tOGapTolerencePositive)) >= totalTOFact));
            if(!checkTotalTO) {
                this.actionToDoMessage += Label.MSG_Negotiated_TO_Not_Equal_Actual_TO + '\n';
                this.allowBalancing = false;
            }
            Boolean checkMarketingEvents = ((totalMarketingEventsToJustify * (1 - negoSettings.coopGapTolerenceNegative)) <= totalMarketingEventsJustified) &&
                							((totalMarketingEventsToJustify * (1 + negoSettings.coopGapTolerencePositive)) >= totalMarketingEventsJustified);
            // Check Marketing events marge only when the total to justify is positif
            if(totalMarketingEventsToJustify > 0 && !checkMarketingEvents) {
                this.actionToDoMessage += Label.MSG_Total_Coop_Not_Fully_Justified + '\n';
                this.allowBalancing = false;
            }
            if(this.allowBalancing) this.actionDoneMessage = Label.MSG_Contract_Successfully_Balanced;
        }
    }
}