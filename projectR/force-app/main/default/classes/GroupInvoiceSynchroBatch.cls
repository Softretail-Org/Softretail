/**
 * Batchable class used to synchronize between invoices group and invoice/invoice detail.
 * Case Criteria: Status__c = 'Validated'
 * Create OR Update Invoice / Invoice Detail
 * Check Invoice_linked__c in Invoice Group If Null then insert Invoice else Upsert Invoice__c = Invoice_Linked__c
 * Update Invoice Group
 **/
public with sharing class GroupInvoiceSynchroBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public Id groupBUId;
    public final Boolean doPaymentGroupScan;
    
    // Constructor.
    public GroupInvoiceSynchroBatch(String startedFrom, Boolean doScan, List<Id> ids) {
        
        this.nb = new NegoptimBatch('GroupInvoiceSynchroBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        doPaymentGroupScan = doScan;
        
        String q = 'SELECT Id, Name, Invoice_Year__c, Invoice_Date__c, Invoice_Due_Date__c, Invoice_Number__c, ';
        q += 'Amount_wo_Tax__c, Amount_w_Tax__c, Supplier__c, ';
        q += 'Contract_reference__c, Contract_Reference__r.Origin_BU__c, Contract_Reference__r.Contract_Linked__c, ';
        q += 'Condition_Reference__c, Condition_Reference__r.Condition_Linked__c, Condition_Reference__r.Condition_name__c, ';
        q += 'Condition_Reference__r.Condition_name__r.Nego_Discount_Type__c, Error_desc__c, Status__c, ';
        q += 'Invoice_Linked__c, VAT_Amount__c, VAT_Perc__c, Comment__c, Option_Code__c, Last_synchro_date__c, Stock_Owner__c ';
        q += 'FROM Invoice_Group__c ';
        q += 'WHERE Status__c = \'Validated\' ';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        query = q;
        // push inputs to log
        nb.logParameter('doPaymentGroupScan', this.doPaymentGroupScan);
        nb.logParameter('invoiceGroupIds', ids);
        nb.logParameter('query', this.query);
    }
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Invoice_Group__c> scope) {
        /* 1. Prepare Declaration. */
        // List of invoices group to Update.
        List<Invoice_Group__c> invoiceGroupList = new List<Invoice_Group__c>();
        // List of invoices group to Upsert.
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        // List of invoices group to Upsert.
        List<Invoice_Detail__c> invoiceDetailsList = new List<Invoice_Detail__c>();
        // Get List Invoice Linked
        Set<Id> invoiceLinkedSet = new Set<Id>();
        // Get List contract reference
        Set<Id> contractSet = new Set<Id>();
        // Get List condition reference
        Set<Id> conditionSet = new Set<Id>();
        // List of wrapper invoice
        List<WrapperInvoice> wInvoiceList = new List<WrapperInvoice>();

        Savepoint sp = Database.setSavepoint();
        try {
            // Get Group BU Id
            groupBUId = NegoptimHelper.getGroupBUFromGlobalSetttings();
            
            // check security on read invoice group fields
            String[] invoiceGroupFields = new String[] {NegoptimHelper.normalizeAPIName('Invoice_Year__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Date__c'), NegoptimHelper.normalizeAPIName('Invoice_Due_Date__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Number__c'), NegoptimHelper.normalizeAPIName('Amount_wo_Tax__c'),
                NegoptimHelper.normalizeAPIName('Amount_w_Tax__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                NegoptimHelper.normalizeAPIName('Contract_reference__c'), NegoptimHelper.normalizeAPIName('Condition_Reference__c'),
                NegoptimHelper.normalizeAPIName('Error_desc__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Linked__c'), NegoptimHelper.normalizeAPIName('VAT_Amount__c'),
                NegoptimHelper.normalizeAPIName('VAT_Perc__c'), NegoptimHelper.normalizeAPIName('Comment__c'),
                NegoptimHelper.normalizeAPIName('Option_Code__c'), NegoptimHelper.normalizeAPIName('Last_synchro_date__c'),
                NegoptimHelper.normalizeAPIName('Stock_Owner__c')};
                    
            String[] invoiceGroupAccessFields = new String[]{ 'Id' };
            invoiceGroupAccessFields.addAll(invoiceGroupFields);
            
            // check security on read invoice fields
            String[] invoiceFields = new String[] { NegoptimHelper.normalizeAPIName('Inv_Business_Unit__c'), 
                NegoptimHelper.normalizeAPIName('Acc_Document_Type__c'), NegoptimHelper.normalizeAPIName('Inv_Contract__c'), 
                NegoptimHelper.normalizeAPIName('Inv_Date__c'), NegoptimHelper.normalizeAPIName('Inv_DueDate__c'),
                NegoptimHelper.normalizeAPIName('Inv_FiscalYear__c'), NegoptimHelper.normalizeAPIName('Inv_Status__c'),
                NegoptimHelper.normalizeAPIName('Inv_Supplier__c'), NegoptimHelper.normalizeAPIName('Sequence_Date__c'),
                NegoptimHelper.normalizeAPIName('Sequence_Number__c'), NegoptimHelper.normalizeAPIName('origin__c'),
                NegoptimHelper.normalizeAPIName('Inv_PrintedDate__c'), NegoptimHelper.normalizeAPIName('Origin_Invoice_Number__c'),
                NegoptimHelper.normalizeAPIName('Status_BDate__c'), NegoptimHelper.normalizeAPIName('Linked_Invoice_group__c'),
                NegoptimHelper.normalizeAPIName('Stock_Owner__c')};
            
            String[] invoiceAccessFields = new String[]{ 'Id' };
            invoiceAccessFields.addAll(invoiceFields);
            
            // check security on read invoice line fields
            String[] invoiceDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Discount__c'), NegoptimHelper.normalizeAPIName('Inv_Detail_Comment__c'), 
                NegoptimHelper.normalizeAPIName('Inv_Detail_Condition__c'), NegoptimHelper.normalizeAPIName('Invoice_Value__c'), 
                NegoptimHelper.normalizeAPIName('Inv_VAT_Value_Ext__c'), NegoptimHelper.normalizeAPIName('Inv_Detail_Value_w_VAT_Ext__c'),
                NegoptimHelper.normalizeAPIName('Inv_VAT_Percent__c'), NegoptimHelper.normalizeAPIName('Inv_Detail_BU__c'), 
                NegoptimHelper.normalizeAPIName('Invoice_detail_nego_disc_type__c')};
            
            String[] invoiceDetailAccessFields = new String[] { 'Id', NegoptimHelper.normalizeAPIName('Invoice__c') };
            invoiceDetailAccessFields.addAll(invoiceDetailFields);
            
            /* 2. Prepare Load Data. */
            for(Invoice_Group__c item : scope) {
                if(String.IsNotBlank(item.Invoice_Linked__c)){
                    invoiceLinkedSet.add(item.Invoice_Linked__c);
                }
                if(String.IsNotBlank(item.Contract_Reference__r.Contract_Linked__c) && !contractSet.Contains(item.Contract_Reference__r.Contract_Linked__c)){
                    contractSet.add(item.Contract_Reference__r.Contract_Linked__c);
                }
                if(String.IsNotBlank(item.Condition_Reference__r.Condition_Linked__c) && !conditionSet.Contains(item.Condition_Reference__r.Condition_Linked__c)){
                    conditionSet.add(item.Condition_Reference__r.Condition_Linked__c);
                }
            }
            
            if(contractSet.size() > 0){
                contractSet = (new Map<Id, Contract__c>([SELECT Id FROM Contract__c WHERE Id IN :contractSet])).keySet();
            }
            if(conditionSet.size() > 0){
                conditionSet = (new Map<Id, Contract_Discount__c>([SELECT Id FROM Contract_Discount__c WHERE Id IN :conditionSet])).keySet();
            }
            
            // Get all invoices linked to invoices group
            Map<Id, Invoice__c> invoiceLinkedMap = new Map<Id, Invoice__c>();
            if(NegoptimHelper.checkAccessibility(Invoice__c.SObjectType, invoiceAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Detail__c.SObjectType, invoiceDetailAccessFields))
            {
                invoiceLinkedMap = new Map<Id, Invoice__c>([SELECT Id, Inv_Business_Unit__c, Acc_Document_Type__c, Inv_Contract__c,
                                                            Inv_Date__c, Inv_DueDate__c, Inv_FiscalYear__c, Inv_Status__c, Inv_Supplier__c,
                                                            Sequence_Date__c, Sequence_Number__c, origin__c, Inv_PrintedDate__c,
                                                            Linked_Invoice_group__c, Origin_Invoice_Number__c, Status_BDate__c, Stock_Owner__c,
                                                            (SELECT Id, Invoice__c, Discount__c, Inv_Detail_Comment__c, Inv_Detail_Condition__c,
                                                             Invoice_Value__c, Inv_VAT_Value_Ext__c, Inv_Detail_Value_w_VAT_Ext__c, Inv_VAT_Percent__c, 
                                                             Invoice_detail_nego_disc_type__c, Inv_Detail_BU__c
                                                             FROM Invoice_Details__r LIMIT 1)
                                                            FROM Invoice__c
                                                            WHERE Id IN :invoiceLinkedSet]);
            }
            /* 3. Prepare Synchro Process. */
            if(NegoptimHelper.checkAccessibility(Invoice_Group__c.SObjectType, invoiceGroupAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice__c.SObjectType, invoiceAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Detail__c.SObjectType, invoiceDetailAccessFields))
            {
                for(Invoice_Group__c item : scope) {
                    Invoice__c invoice = null;
                    Invoice_Detail__c invoiceDetail = null;
                    // Check if invoice group linked to invoice
                    if(invoiceLinkedMap.containsKey(item.Invoice_Linked__c)){
                        // Update Invoice/List Invoice Detail
                        invoice = invoiceLinkedMap.get(item.Invoice_Linked__c);
                        List<Invoice_Detail__c> invoiceDetails = invoice.Invoice_Details__r;
                        if(invoiceDetails != null && invoiceDetails.size() > 0){
                            invoiceDetail = invoiceDetails.get(0);
                        }
                        else{
                            invoiceDetail = new Invoice_Detail__c();
                        }
                    }
                    else{
                        // Create new Invoice/Invoice_Detail
                        invoice = new Invoice__c();
                        invoiceDetail = new Invoice_Detail__c();
                    }
                    // Fill invoice
                    invoice.Inv_Business_Unit__c = groupBUId;
                    invoice.Acc_Document_Type__c = 'Down-payment Invoice';
                    if(contractSet.Contains(item.Contract_Reference__r.Contract_Linked__c)){
                        invoice.Inv_Contract__c = item.Contract_Reference__r.Contract_Linked__c;
                    } else {
                        invoice.Inv_Contract__c = null;
                    }
                    invoice.Inv_Date__c = item.Invoice_Date__c;
                    invoice.Inv_PrintedDate__c = item.Invoice_Date__c;
                    invoice.Inv_DueDate__c = item.Invoice_Due_Date__c;
                    invoice.Inv_FiscalYear__c = item.Invoice_Year__c;
                    invoice.Inv_Status__c = 'Printed';
                    invoice.Inv_Supplier__c = item.Supplier__c;
                    invoice.Sequence_Date__c = 'Month';
                    invoice.Sequence_Number__c = item.Invoice_Date__c.month();
                    invoice.origin__c = 'Group';
                    invoice.Linked_Invoice_group__c = item.Id;
                    invoice.Origin_Invoice_Number__c = item.Invoice_Number__c;
                    invoice.Status_BDate__c = item.Invoice_Date__c;
                    invoice.Stock_Owner__c = item.Stock_Owner__c;
                    // Fill invoice detail
                    if(conditionSet.Contains(item.Condition_Reference__r.Condition_Linked__c)){
                        invoiceDetail.Discount__c = item.Condition_Reference__r.Condition_Linked__c;
                    } else {
                        invoiceDetail.Discount__c = null;
                    }
                    invoiceDetail.Inv_Detail_Comment__c = item.Comment__c;
                    invoiceDetail.Inv_Detail_Condition__c = item.Condition_Reference__r.Condition_name__c;
                    invoiceDetail.Invoice_Value__c = item.Amount_wo_Tax__c;
                    invoiceDetail.Inv_VAT_Value_Ext__c = item.VAT_Amount__c;
                    invoiceDetail.Inv_Detail_Value_w_VAT_Ext__c = item.Amount_w_Tax__c;
                    invoiceDetail.Inv_VAT_Percent__c = item.VAT_Perc__c;
                    invoiceDetail.Inv_Detail_BU__c = groupBUId;
                    if(String.IsBlank(item.Condition_Reference__r.Condition_name__c)){
                        if(item.Option_Code__c == '70'){
                            invoiceDetail.Invoice_detail_nego_disc_type__c = 'Advertising Fees';
                        }
                        else{
                            invoiceDetail.Invoice_detail_nego_disc_type__c = 'Others';
                        }
                    }
                    else if(String.IsNotBlank(item.Condition_Reference__c)){
                        invoiceDetail.Invoice_detail_nego_disc_type__c = item.Condition_Reference__r.Condition_name__r.Nego_Discount_Type__c;
                    }
                    // Update Invoice Group Status/Last_synchro_date__c
                    if(String.IsBlank(item.Contract_reference__c) || !contractSet.Contains(item.Contract_Reference__r.Contract_Linked__c)) item.Status__c = 'Synchronized without Contract';
                    else if(String.IsBlank(item.Condition_reference__c) || !conditionSet.Contains(item.Condition_Reference__r.Condition_Linked__c)) item.Status__c = 'Synchronized without Condition';
                    else item.Status__c = 'Synchronized';
                    item.Last_synchro_date__c = System.now();
                    // Fill Wrapper
                    WrapperInvoice wInvoice = new WrapperInvoice(item, invoice, invoiceDetail);
                    wInvoiceList.add(wInvoice);
                }
            }
            // check security on update invoice group fields
            String[] invoiceGroupUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Linked__c'), NegoptimHelper.normalizeAPIName('Error_desc__c'),
                NegoptimHelper.normalizeAPIName('Last_synchro_date__c')};

            // check security on insert invoice line fields
            String[] invoiceDetailCreateFields = new String[]{ NegoptimHelper.normalizeAPIName('Invoice__c') };
                invoiceDetailCreateFields.addAll(invoiceDetailFields);
      
            if(NegoptimHelper.checkUpdatibility(Invoice_Group__c.SObjectType, invoiceGroupUpdateFields) && 
               NegoptimHelper.checkCreatibility(Invoice__c.SObjectType, invoiceFields) &&
               NegoptimHelper.checkUpdatibility(Invoice__c.SObjectType, invoiceFields) &&
               NegoptimHelper.checkCreatibility(Invoice_Detail__c.SObjectType, invoiceDetailCreateFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Detail__c.SObjectType, invoiceDetailFields)) {
                // Map between invoice line and Wrapper invoice
                Map<Integer, WrapperInvoice> invoiceLineMap = new Map<Integer, WrapperInvoice>();
                integer indexInv = 0;
                // Upsert invoices.
                for (WrapperInvoice item : wInvoiceList) {
                    invoiceList.add(item.invoice);                
                    invoiceGroupList.add(item.invoiceGroup);
                }
                if(invoiceList != null && invoiceList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(invoiceList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperInvoice wInvoice = wInvoiceList.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? wInvoice.invoice.Name + '(' + result.Id + ') : ' : String.valueOf(wInvoice.invoice);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage();
                            }
                            nb.logError(errorMessage);
                            wInvoice.invoiceGroup.Error_desc__c += errorMessage;
                            wInvoice.invoiceGroup.Status__c = 'Synchronized with error';
                        }
                        else{
                            // Set corresponding invoice Id.
                            if(wInvoice.invoiceLine.Invoice__c == null) wInvoice.invoiceLine.Invoice__c = wInvoice.invoice.Id;
                            if(wInvoice.invoiceGroup.Invoice_Linked__c == null) wInvoice.invoiceGroup.Invoice_Linked__c = wInvoice.invoice.Id;
                            // Fill list of valid invoice line
                            invoiceDetailsList.add(wInvoice.invoiceLine);
                            invoiceLineMap.put(indexInv, wInvoice);
                            indexInv++;
                        }
                    }
                }
                // Upsert Invoice Line
                if(invoiceDetailsList != null && invoiceDetailsList.size() > 0){
                    List<Database.UpsertResult> results = Database.upsert(invoiceDetailsList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperInvoice wInvoice = invoiceLineMap.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? wInvoice.invoiceLine.Name + '(' + result.Id + ') : ' : String.valueOf(wInvoice.invoiceLine);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            wInvoice.invoiceGroup.Error_desc__c += errorMessage;
                            wInvoice.invoiceGroup.Status__c = 'Synchronized with error';
                            wInvoice.isvalid = false;
                        }
                    }
                }
                // Update Invoice Group
                if(invoiceGroupList != null && invoiceGroupList.size() > 0){
                    List<Database.SaveResult> results = Database.update(invoiceGroupList, false);
                    nb.logResults(results, invoiceGroupList);
                    
                    //******* check invalid synchronized *******//
                    // List of invoices to delete.
                    List<Invoice__c> invoiceDeletedList = new List<Invoice__c>();                    
                    for (WrapperInvoice item : wInvoiceList) {
                        if(!item.isvalid) {
                            if(item.invoice != null && item.invoice.Id != null) invoiceDeletedList.add(item.invoice);
                        }
                    }
                    if(!invoiceDeletedList.isEmpty()) {
                        if (NegoptimHelper.checkDeletibility(Invoice__c.SObjectType)) {
                            Database.DeleteResult[] deleteResults = Database.Delete(invoiceDeletedList, false);
                        }
                    }
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        if(doPaymentGroupScan) {
            Database.executeBatch(new GroupInvoicePaymentScanBatch('GroupInvoiceSynchroBatch', doPaymentGroupScan, null));            
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    /* Wrapper Class for Invoice. */
    public class WrapperInvoice {
        public Invoice_Group__c invoiceGroup {get; set;}
        public Invoice__c invoice {get; set;}
        public Invoice_Detail__c invoiceLine {get; set;}
        public Boolean isValid {get; set;}
        public WrapperInvoice(Invoice_Group__c invGroup, Invoice__c inv, Invoice_Detail__c invLine) {
            invoiceGroup = invGroup;
            invoiceGroup.Error_desc__c = '';
            invoice = inv;
            invoiceLine = invLine;
            isValid = true;
        }
    }
}