/**
 * Batchable class used to synchronize between Invoice payment group and Invoice_payment__c/Invoice_payment_detail__c.
 * Case Criteria: Status__c = 'Validated'
 * Create OR Update Invoice Payment / Invoice Payment Detail
 * Check Payment_Linked__c in Invoice Payment Group If Null then Insert Invoice Payment else Upsert Invoice_Payment__c = Payment_Linked__c
 * Update Invoice Payment Group
 **/
public with sharing class GroupInvoicePaymentSynchroBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public Id groupBUId;
    public final Boolean doRebateGroupScan;
    
    // Constructor.
    public GroupInvoicePaymentSynchroBatch(String startedFrom, Boolean doScan, List<Id> ids) {
        this.nb = new NegoptimBatch('Group Invoice Payment Sync', NegoptimBatch.BatchType.Stateful, startedFrom);
        doRebateGroupScan = doScan;
        
        String q = 'SELECT Id, Name, Payment_Date__c, Payment_Term__c, Payment_Value_Date__c, Invoice_Amount_Calc__c, ';
        q += 'Invoice_Reference__c, Invoice_Reference__r.Invoice_Linked__c, Invoice_Reference__r.Contract_Reference__r.Supplier__c, ';
        q += 'Last_synchro_date__c, Status__c, Payment_Linked__c, Payment_Label__c ';
        q += 'FROM Invoice_Payment_Group__c ';
        q += 'WHERE Status__c = \'Validated\' ';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        query = q;
        // push inputs to log
        nb.logParameter('doRebateGroupScan', this.doRebateGroupScan);
        nb.logParameter('paymentGroupIds', ids);
        nb.logParameter('query', this.query);
    }
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Invoice_Payment_Group__c> scope) {
        /* 1. Prepare Declaration. */
        // List of invoices payment group to Update.
        List<Invoice_Payment_Group__c> invoicePaymentGroupList = new List<Invoice_Payment_Group__c>();
        // List of invoices payment to Upsert.
        List<Invoice_Paiement__c> invoicePaymentList = new List<Invoice_Paiement__c>();
        // List of invoices payment lines to Upsert.
        List<Invoice_Paiement_Detail__c> invoicePaymentDetailsList = new List<Invoice_Paiement_Detail__c>();
        // Get List Invoice Payment Linked
        Set<Id> invoicePaymentLinkedSet = new Set<Id>();
        // List of wrapper payment group
        List<WrapperPaymentGroup> wPaymentGroupList = new List<WrapperPaymentGroup>();
        // List of Invoice Linked
        Set<Id> invoiceLinkedSet = new Set<Id>();
        // Map<Invoice Linked Id, Invoice_Detail__c>
        Map<Id, Invoice_Detail__c> invoiceDetailMap = new Map<Id, Invoice_Detail__c>();

        Savepoint sp = Database.setSavepoint();
        try {
            // Get Group BU Id
            groupBUId = NegoptimHelper.getGroupBUFromGlobalSetttings();
            
            // check security on read payment group fields
            String[] paymentGroupFields = new String[] { NegoptimHelper.normalizeAPIName('Payment_Date__c'), 
                NegoptimHelper.normalizeAPIName('Payment_Term__c'), NegoptimHelper.normalizeAPIName('Payment_Value_Date__c'), 
                NegoptimHelper.normalizeAPIName('Invoice_Amount_Calc__c'), NegoptimHelper.normalizeAPIName('Invoice_Reference__c'),
                NegoptimHelper.normalizeAPIName('Last_synchro_date__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Payment_Linked__c'), NegoptimHelper.normalizeAPIName('Payment_Label__c')};
                    
            String[] paymentGroupAccessFields = new String[]{ 'Id' };
            paymentGroupAccessFields.addAll(paymentGroupFields);
            
            /* 2. Prepare Load Data. */            
            for(Invoice_Payment_Group__c item : scope) {
                if(String.IsNotBlank(item.Payment_Linked__c)){
                    invoicePaymentLinkedSet.add(item.Payment_Linked__c);
                }
                if(String.IsNotBlank(item.Invoice_Reference__r.Invoice_Linked__c)){
                    invoiceLinkedSet.add(item.Invoice_Reference__r.Invoice_Linked__c);
                }
            }         
            
            // check security on read payment fields
            String[] paymentFields = new String[] { NegoptimHelper.normalizeAPIName('Amount__c'), 
                NegoptimHelper.normalizeAPIName('Payment_BU__c'), NegoptimHelper.normalizeAPIName('Comment__c'), 
                NegoptimHelper.normalizeAPIName('Due_Date__c'), NegoptimHelper.normalizeAPIName('Origin__c'), 
                NegoptimHelper.normalizeAPIName('Payment_Date__c'), NegoptimHelper.normalizeAPIName('Payment_Type__c'), 
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Value_Date__c'),
                NegoptimHelper.normalizeAPIName('Linked_Payment_Group__c')};
                    
            String[] paymentAccessFields = new String[]{ 'Id' };
            paymentAccessFields.addAll(paymentFields);
            
            // check security on read payment line fields
            String[] paymentDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Due_Date__c'), NegoptimHelper.normalizeAPIName('Matching_Amount__c')};
                String[] paymentDetailAccessFields = new String[]{ 'Id', NegoptimHelper.normalizeAPIName('Paiement__c'), NegoptimHelper.normalizeAPIName('Invoice_Line__c') };
                    paymentDetailAccessFields.addAll(paymentDetailFields);
           
            // Get all payments linked to payment group
            Map<Id, Invoice_Paiement__c> invoicePaymentLinkedMap = new Map<Id, Invoice_Paiement__c>();            
            if(NegoptimHelper.checkAccessibility(Invoice_Paiement__c.SObjectType, paymentAccessFields) && 
               NegoptimHelper.checkAccessibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailAccessFields))
            {
                // Map<Invoice Payment Linked Id, Invoice_Paiement__c>
                invoicePaymentLinkedMap = new Map<Id, Invoice_Paiement__c>([SELECT Id, Amount__c, Payment_BU__c, Comment__c, Due_Date__c,
                                                                            Origin__c, Payment_Date__c, Payment_Type__c, Supplier__c, 
                                                                            Value_Date__c, Linked_Payment_Group__c,
                                                                            (SELECT Id, Due_Date__c, Matching_Amount__c, Paiement__c, Invoice_Line__c
                                                                             FROM Invoice_Paiement_Details__r LIMIT 1)
                                                                            FROM Invoice_Paiement__c
                                                                            WHERE Id IN :invoicePaymentLinkedSet]);
            }
            // check security on read invoice line fields
            String[] invoiceDetailAccessFields = new String[] { 'Id', NegoptimHelper.normalizeAPIName('Invoice__c') };
            
            // Get list of invoice line based on invoice group linked to invoice
            if(NegoptimHelper.checkAccessibility(Invoice_Detail__c.SObjectType, invoiceDetailAccessFields)){
                for(Invoice_Detail__c item : [SELECT Id, Invoice__c FROM Invoice_Detail__c WHERE Invoice__c IN :invoiceLinkedSet]) {
                    if(!invoiceDetailMap.containsKey(item.Invoice__c)) {
                        invoiceDetailMap.put(item.Invoice__c, item);
                    }
                }
            }
            /* 3. Prepare Synchro Process. */
            if(NegoptimHelper.checkAccessibility(Invoice_Payment_Group__c.SObjectType, paymentGroupAccessFields) && 
               NegoptimHelper.checkAccessibility(Invoice_Detail__c.SObjectType, invoiceDetailAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Paiement__c.SObjectType, paymentAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailAccessFields))
            {
                for(Invoice_Payment_Group__c item : scope) {
                    Invoice_Paiement__c invoicePayment = null;
                    Invoice_Paiement_Detail__c invoicePaymentDetail = null;
                    // Check if invoice payment group linked to invoice payment
                    if(invoicePaymentLinkedMap.containsKey(item.Payment_Linked__c)){
                        // Update Invoice_Payment/Invoice_Paiement_Detail
                        invoicePayment = invoicePaymentLinkedMap.get(item.Payment_Linked__c);
                        List<Invoice_Paiement_Detail__c> invoicePaymentDetails = invoicePayment.Invoice_Paiement_Details__r;
                        if(invoicePaymentDetails != null && invoicePaymentDetails.size() > 0){
                            invoicePaymentDetail = invoicePaymentDetails.get(0);
                        }
                        else{
                            invoicePaymentDetail = new Invoice_Paiement_Detail__c();                    
                        }
                    }
                    else{
                        // Create new Invoice_Payment/Invoice_Paiement_Detail
                        invoicePayment = new Invoice_Paiement__c();
                        invoicePaymentDetail = new Invoice_Paiement_Detail__c();
                    }
                    // Get invoice line based on invoice group
                    Invoice_Detail__c invoiceLine = null;
                    if(String.IsNotBlank(item.Invoice_Reference__r.Invoice_Linked__c) &&
                       invoiceDetailMap.get(item.Invoice_Reference__r.Invoice_Linked__c) != null){
                           invoiceLine = invoiceDetailMap.get(item.Invoice_Reference__r.Invoice_Linked__c);
                       }
                    
                    // Fill invoice payment                
                    invoicePayment.Amount__c = item.Invoice_Amount_Calc__c;
                    invoicePayment.Payment_BU__c = groupBUId;
                    invoicePayment.Comment__c = item.Payment_Label__c;
                    invoicePayment.Due_Date__c = item.Payment_Value_Date__c;
                    invoicePayment.Origin__c = 'Group';
                    invoicePayment.Payment_Date__c = item.Payment_Value_Date__c;
                    invoicePayment.Payment_Type__c = item.Payment_Term__c;
                    invoicePayment.Supplier__c = item.Invoice_Reference__r.Contract_Reference__r.Supplier__c;
                    invoicePayment.Linked_Payment_Group__c = item.id;
                    invoicePayment.Value_Date__c = item.Payment_Value_Date__c;
                    // Fill invoice payment detail
                    invoicePaymentDetail.Due_Date__c = item.Payment_Value_Date__c;
                    invoicePaymentDetail.Matching_Amount__c = item.Invoice_Amount_Calc__c;
                    if(invoiceLine != null && invoicePaymentDetail.Invoice_Line__c == null){
                        invoicePaymentDetail.Invoice_Line__c = invoiceLine.Id;
                    }
                    // Update Invoice Payment Group Status/Last_synchro_date__c
                    item.Status__c = 'Synchronized';           
                    item.Last_synchro_date__c = System.now();
                    // Fill Wrapper
                    WrapperPaymentGroup wPaymentGroup = new WrapperPaymentGroup(item, invoicePayment, invoicePaymentDetail);
                    wPaymentGroupList.add(wPaymentGroup);
                }
            }
            // check security on update payment group fields
            String[] paymentGroupUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Payment_Linked__c'), NegoptimHelper.normalizeAPIName('Error_desc__c'),
                NegoptimHelper.normalizeAPIName('Last_synchro_date__c')};
            
            // check security on insert payment line fields
            String[] paymentDetailCreateFields = new String[]{ NegoptimHelper.normalizeAPIName('Paiement__c'), NegoptimHelper.normalizeAPIName('Invoice_Line__c') };
                paymentDetailCreateFields.addAll(paymentDetailFields);
            
            if(NegoptimHelper.checkUpdatibility(Invoice_Payment_Group__c.SObjectType, paymentGroupUpdateFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Detail__c.SObjectType, invoiceDetailAccessFields) &&
               NegoptimHelper.checkCreatibility(Invoice_Paiement__c.SObjectType, paymentFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Paiement__c.SObjectType, paymentFields) &&
               NegoptimHelper.checkCreatibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailCreateFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailFields))
            {
                // Map between payment line and wrapper payment
                Map<Integer, WrapperPaymentGroup> paymentLineMap = new Map<Integer, WrapperPaymentGroup>();
                integer indexPaymentLine = 0;
                // Upsert invoices Payment.
                for (WrapperPaymentGroup item : wPaymentGroupList) {
                    invoicePaymentList.add(item.invoicePayment);
                    invoicePaymentGroupList.add(item.invoicePaymentGroup);
                }
                if(invoicePaymentList != null && invoicePaymentList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(invoicePaymentList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperPaymentGroup wPayment = wPaymentGroupList.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? wPayment.invoicePayment.Name + '(' + result.Id + ') : ' : String.valueOf(wPayment.invoicePayment);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getFields() + ':' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            wPayment.invoicePaymentGroup.Error_desc__c += errorMessage;
                            wPayment.invoicePaymentGroup.Status__c = 'Synchronized_with_error';
                        }
                        else{
                            // Set corresponding invoice Payment Id.
                            if(wPayment.invoicePaymentLine.Paiement__c == null) wPayment.invoicePaymentLine.Paiement__c = wPayment.invoicePayment.Id;
                            if(wPayment.invoicePaymentGroup.Payment_Linked__c == null) wPayment.invoicePaymentGroup.Payment_Linked__c = wPayment.invoicePayment.Id;
                            // Fill list of valid payment line based of invoice line inserted
                            invoicePaymentDetailsList.add(wPayment.invoicePaymentLine);
                            paymentLineMap.put(indexPaymentLine, wPayment);
                            indexPaymentLine++;
                        }
                    }
                }
                // Upsert Invoice Payment Line
                if(invoicePaymentDetailsList != null && invoicePaymentDetailsList.size() > 0){
                    List<Database.UpsertResult> results = Database.upsert(invoicePaymentDetailsList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperPaymentGroup wPayment = paymentLineMap.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? wPayment.invoicePaymentLine.Name + '(' + result.Id + ') : ' : String.valueOf(wPayment.invoicePaymentLine);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            wPayment.invoicePaymentGroup.Error_desc__c += errorMessage;
                            wPayment.invoicePaymentGroup.Status__c = 'Synchronized_with_error';
                        }
                    }
                }
                // Update of Invoice Payment Group
                if(invoicePaymentGroupList != null && invoicePaymentGroupList.size() > 0){
                    List<Database.SaveResult> results = Database.update(invoicePaymentGroupList, false);
                    nb.logResults(results, invoicePaymentGroupList);
                }                
            } 
        } 
        catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        }
        catch (Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        if(doRebateGroupScan) {
            Database.executeBatch(new GroupRebatePaymentScanBatch('GroupInvoicePaymentSynchroBatch', doRebateGroupScan, null, null));           
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    /* Wrapper Class for Payment Group. */
    public class WrapperPaymentGroup {
        public Invoice_Payment_Group__c invoicePaymentGroup {get; set;}
        public Invoice_Paiement__c invoicePayment {get; set;}
        public Invoice_Paiement_Detail__c invoicePaymentLine {get; set;}
        public WrapperPaymentGroup(Invoice_Payment_Group__c paymentGroup, Invoice_Paiement__c invPayment, Invoice_Paiement_Detail__c invPaymentLine){
            invoicePaymentGroup = paymentGroup;
            invoicePaymentGroup.Error_desc__c = '';
            invoicePayment = invPayment;
            invoicePaymentLine = invPaymentLine;
        }
    }
}