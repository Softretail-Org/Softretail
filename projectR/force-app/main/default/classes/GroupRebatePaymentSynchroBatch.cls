/**
* Batchable class used to synchronize between rebate payment group and invoice/invoice detail/payment/payment detail.
* Case Criteria: Status__c = 'Validated'
* Create OR Update Invoice / Invoice Detail / Payment / Payment Detail
* Update Rebate Payment Group
**/
global with sharing class GroupRebatePaymentSynchroBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public Id groupBUId;
    
    // Constructor.
    public GroupRebatePaymentSynchroBatch(String startedFrom, List<Id> ids) {
        this.nb = new NegoptimBatch('GroupRebatePaymentSynchroBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        
        String q = 'SELECT Id, Name, Payment_Date__c, Payment_Term__c, Supplier__c, Fiscal_Year__c, ';
        q += 'Contract_Reference__c, Contract_Reference__r.Origin_BU__c, Contract_Reference__r.Contract_Linked__c, ';
        q += 'Condition_Reference__c, Condition_Reference__r.Condition_Linked__c, Condition_Reference__r.Condition_name__c, ';
        q += 'Condition_Reference__r.Condition_name__r.Nego_Discount_Type__c, ';
        q += 'Status__c, Invoice_Linked__c, Payment_Linked__c, Error_desc__c, Amount_wo_Tax__c, Amount_w_Tax__c, ';
        q += 'Last_synchro_date__c, Payment_Value_Date__c, VAT_Amount__c, Payment_Label__c, Stock_Owner__c ';
        q += 'FROM Rebate_Payment_Group__c ';
        q += 'WHERE Status__c = \'Validated\' ';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        query = q;
        // push inputs to log
        nb.logParameter('rebateGroupIds', ids);
        nb.logParameter('query', this.query);
    }
    
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Rebate_Payment_Group__c> scope) {
        /* 1. Prepare Declaration. */
        // List of rebates Payment group to Update.
        List<Rebate_Payment_Group__c> rebatePaymentGroupList = new List<Rebate_Payment_Group__c>();
        // List of invoices to Upsert.
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        // List of invoices detail to Upsert.
        List<Invoice_Detail__c> invoiceDetailsList = new List<Invoice_Detail__c>();
        // List of invoices payment to Upsert.
        List<Invoice_Paiement__c> invoicePaymentList = new List<Invoice_Paiement__c>();
        // List of invoices payment lines to Upsert.
        List<Invoice_Paiement_Detail__c> invoicePaymentDetailsList = new List<Invoice_Paiement_Detail__c>();
        // Get List Invoice Payment Linked
        Set<Id> invoicePaymentLinkedSet = new Set<Id>();
        // Get List Invoice Linked
        Set<Id> invoiceLinkedSet = new Set<Id>();
        // Get List contract reference
        Set<Id> contractSet = new Set<Id>();
        // Get List condition reference
        Set<Id> conditionSet = new Set<Id>();
        // List of wrapper rebate payment
        List<WrapperRebatePayment> wRebatePaymentList = new List<WrapperRebatePayment>();        
        
        Savepoint sp = Database.setSavepoint();
        try {
            // Get Group BU Id
            groupBUId = NegoptimHelper.getGroupBUFromGlobalSetttings();
            
            // check security on read rebate group fields
            String[] rebateGroupFields = new String[] { NegoptimHelper.normalizeAPIName('Payment_Date__c'), 
                NegoptimHelper.normalizeAPIName('Payment_Term__c'), NegoptimHelper.normalizeAPIName('Supplier__c'), 
                NegoptimHelper.normalizeAPIName('Fiscal_Year__c'), NegoptimHelper.normalizeAPIName('Contract_Reference__c'),
                NegoptimHelper.normalizeAPIName('Condition_Reference__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Linked__c'), NegoptimHelper.normalizeAPIName('Payment_Linked__c'),
                NegoptimHelper.normalizeAPIName('Error_desc__c'), NegoptimHelper.normalizeAPIName('Amount_wo_Tax__c'),
                NegoptimHelper.normalizeAPIName('Amount_w_Tax__c'), NegoptimHelper.normalizeAPIName('Last_synchro_date__c'),
                NegoptimHelper.normalizeAPIName('Payment_Value_Date__c'), NegoptimHelper.normalizeAPIName('VAT_Amount__c'),
                NegoptimHelper.normalizeAPIName('Payment_Label__c'), NegoptimHelper.normalizeAPIName('Stock_Owner__c')};
            String[] rebateGroupAccessFields = new String[]{ 'Id' };
            rebateGroupAccessFields.addAll(rebateGroupFields);
                        
            /* 2. Prepare Load Data. */
            for(Rebate_Payment_Group__c item : scope) {
                if(String.IsNotBlank(item.Invoice_Linked__c)){
                    invoiceLinkedSet.add(item.Invoice_Linked__c);
                }
                if(String.IsNotBlank(item.Payment_Linked__c)){
                    invoicePaymentLinkedSet.add(item.Payment_Linked__c);
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
            
            // check security on read invoice fields
            String[] invoiceFields = new String[] { NegoptimHelper.normalizeAPIName('Inv_Business_Unit__c'), 
                NegoptimHelper.normalizeAPIName('Acc_Document_Type__c'), NegoptimHelper.normalizeAPIName('Inv_Contract__c'), 
                NegoptimHelper.normalizeAPIName('Inv_Date__c'), NegoptimHelper.normalizeAPIName('Inv_DueDate__c'),
                NegoptimHelper.normalizeAPIName('Inv_FiscalYear__c'), NegoptimHelper.normalizeAPIName('Inv_Status__c'),
                NegoptimHelper.normalizeAPIName('Inv_Supplier__c'), NegoptimHelper.normalizeAPIName('Sequence_Date__c'),
                NegoptimHelper.normalizeAPIName('Sequence_Number__c'), NegoptimHelper.normalizeAPIName('origin__c'),
                NegoptimHelper.normalizeAPIName('Inv_PrintedDate__c'), NegoptimHelper.normalizeAPIName('Origin_Invoice_Number__c'),
                NegoptimHelper.normalizeAPIName('Status_BDate__c'), NegoptimHelper.normalizeAPIName('Linked_Rebate_Payment_Group__c'),
                NegoptimHelper.normalizeAPIName('Linked_Invoice_group__c'), NegoptimHelper.normalizeAPIName('Stock_Owner__c')};
                    
            String[] invoiceAccessFields = new String[]{ 'Id' };
            invoiceAccessFields.addAll(invoiceFields);
                       
            // check security on read invoice line fields
            String[] invoiceDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Discount__c'), NegoptimHelper.normalizeAPIName('Inv_Detail_Comment__c'), 
                NegoptimHelper.normalizeAPIName('Inv_Detail_Condition__c'), NegoptimHelper.normalizeAPIName('Invoice_Value__c'), 
                NegoptimHelper.normalizeAPIName('Inv_VAT_Value_Ext__c'), NegoptimHelper.normalizeAPIName('Inv_Detail_Value_w_VAT_Ext__c'), 
                NegoptimHelper.normalizeAPIName('Inv_Detail_BU__c'), NegoptimHelper.normalizeAPIName('Invoice_detail_nego_disc_type__c')};
                    
            String[] invoiceDetailAccessFields = new String[] { 'Id', NegoptimHelper.normalizeAPIName('Invoice__c') };                        
            invoiceDetailAccessFields.addAll(invoiceDetailFields);
            
            // Get all invoices linked to rebates group
            Map<Id, Invoice__c> invoiceLinkedMap = new Map<Id, Invoice__c>();
            if(NegoptimHelper.checkAccessibility(Invoice__c.SObjectType, invoiceAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Detail__c.SObjectType, invoiceDetailAccessFields))
            {
                invoiceLinkedMap = new Map<Id, Invoice__c>([SELECT Id, Inv_Business_Unit__c, Acc_Document_Type__c, Inv_Contract__c,
                                                            Inv_Date__c, Inv_DueDate__c, Inv_FiscalYear__c, Inv_Status__c, Inv_Supplier__c, 
                                                            Sequence_Date__c, Sequence_Number__c, origin__c, Inv_PrintedDate__c, 
                                                            Origin_Invoice_Number__c, Status_BDate__c, Linked_Rebate_Payment_Group__c,
                                                            Linked_Invoice_group__c, Stock_Owner__c, 
                                                            (SELECT Id, Invoice__c, Discount__c, Inv_Detail_Comment__c, Inv_Detail_Condition__c,
                                                             Invoice_Value__c, Inv_VAT_Value_Ext__c, Inv_Detail_Value_w_VAT_Ext__c, Inv_Detail_BU__c,
                                                             Invoice_detail_nego_disc_type__c
                                                             FROM Invoice_Details__r LIMIT 1)
                                                            FROM Invoice__c
                                                            WHERE Id IN :invoiceLinkedSet]);
            }
            // check security on read payment fields
            String[] paymentFields = new String[] { NegoptimHelper.normalizeAPIName('Amount__c'), 
                NegoptimHelper.normalizeAPIName('Payment_BU__c'), NegoptimHelper.normalizeAPIName('Comment__c'), 
                NegoptimHelper.normalizeAPIName('Due_Date__c'), NegoptimHelper.normalizeAPIName('Origin__c'), 
                NegoptimHelper.normalizeAPIName('Payment_Date__c'), NegoptimHelper.normalizeAPIName('Payment_Type__c'), 
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Value_Date__c'),
                NegoptimHelper.normalizeAPIName('Linked_Payment_Group__c'), NegoptimHelper.normalizeAPIName('Linked_Rebate_Payment_group__c')};
            
            String[] paymentAccessFields = new String[]{ 'Id' };
            paymentAccessFields.addAll(paymentFields);
            
            // check security on read payment line fields
            String[] paymentDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Due_Date__c'), NegoptimHelper.normalizeAPIName('Matching_Amount__c')};
            String[] paymentDetailAccessFields = new String[]{ 'Id', NegoptimHelper.normalizeAPIName('Paiement__c'), NegoptimHelper.normalizeAPIName('Invoice_Line__c') };
            paymentDetailAccessFields.addAll(paymentDetailFields);
            
            // Get all payments linked to rebates group
            Map<Id, Invoice_Paiement__c> invoicePaymentLinkedMap = new Map<Id, Invoice_Paiement__c>();
            if(NegoptimHelper.checkAccessibility(Invoice_Paiement__c.SObjectType, paymentAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailAccessFields))
            {
                invoicePaymentLinkedMap = new Map<Id, Invoice_Paiement__c>([SELECT Id, Amount__c, Payment_BU__c, Comment__c, Due_Date__c,
                                                                            Origin__c, Payment_Date__c, Payment_Type__c, Supplier__c,
                                                                            Value_Date__c, Linked_Payment_Group__c, Linked_Rebate_Payment_group__c,
                                                                            (SELECT Id, Due_Date__c, Matching_Amount__c, Paiement__c,
                                                                             Invoice_Line__c FROM Invoice_Paiement_Details__r LIMIT 1)
                                                                            FROM Invoice_Paiement__c
                                                                            WHERE Id IN :invoicePaymentLinkedSet]);
            }
            
            /* 3. Prepare Synchro Process. */
            if(NegoptimHelper.checkAccessibility(Rebate_Payment_Group__c.SObjectType, rebateGroupAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice__c.SObjectType, invoiceAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Detail__c.SObjectType, invoiceDetailAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Paiement__c.SObjectType, paymentAccessFields) &&
               NegoptimHelper.checkAccessibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailAccessFields))
            {
                for(Rebate_Payment_Group__c item : scope) {
                    Invoice__c invoice = null;
                    Invoice_Detail__c invoiceDetail = null;
                    Invoice_Paiement__c invoicePayment = null;
                    Invoice_Paiement_Detail__c invoicePaymentDetail = null;
                    // Check if rebate payment group linked to invoice
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
                    // Check if rebate group linked to invoice payment
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
                    
                    // Fill invoice
                    invoice.Inv_Business_Unit__c = groupBUId;
                    invoice.Acc_Document_Type__c = 'Credit Note Request';
                    if(contractSet.Contains(item.Contract_Reference__r.Contract_Linked__c)){
                        invoice.Inv_Contract__c = item.Contract_Reference__r.Contract_Linked__c;
                    } else {
                        invoice.Inv_Contract__c = null;
                    }
                    invoice.Inv_Date__c = system.today();
                    invoice.Inv_PrintedDate__c = system.today();
                    invoice.Inv_DueDate__c = system.today();
                    invoice.Inv_FiscalYear__c = item.Fiscal_Year__c;
                    invoice.Inv_Status__c = 'Printed';
                    invoice.Inv_Supplier__c = item.Supplier__c;
                    invoice.Sequence_Date__c = 'Month';
                    invoice.Sequence_Number__c = system.today().month();
                    invoice.origin__c = 'Group';
                    invoice.Linked_Invoice_group__c = null;
                    invoice.Linked_Rebate_Payment_Group__c = item.Id;
                    invoice.Origin_Invoice_Number__c = null;
                    invoice.Status_BDate__c = system.today();
                    invoice.Stock_Owner__c = item.Stock_Owner__c;
                    // Fill invoice detail
                    if(conditionSet.Contains(item.Condition_Reference__r.Condition_Linked__c)){
                        invoiceDetail.Discount__c = item.Condition_Reference__r.Condition_Linked__c;
                    } else {
                        invoiceDetail.Discount__c = null;
                    }
                    invoiceDetail.Inv_Detail_Comment__c = null;
                    invoiceDetail.Inv_Detail_Condition__c = item.Condition_Reference__r.Condition_name__c;
                    invoiceDetail.Invoice_Value__c = item.Amount_wo_Tax__c;
                    invoiceDetail.Inv_Detail_Value_w_VAT_Ext__c = item.Amount_wo_Tax__c;
                    invoiceDetail.Inv_VAT_Value_Ext__c = item.VAT_Amount__c;
                    invoiceDetail.Inv_Detail_BU__c = groupBUId;
                    if(String.IsBlank(item.Condition_Reference__r.Condition_name__c)){
                        invoiceDetail.Invoice_detail_nego_disc_type__c = 'Rebates';
                    }
                    else if(String.IsNotBlank(item.Condition_Reference__c)){
                        invoiceDetail.Invoice_detail_nego_disc_type__c = item.Condition_Reference__r.Condition_name__r.Nego_Discount_Type__c;
                    }
                    // Fill invoice payment
                    invoicePayment.Amount__c = item.Amount_w_Tax__c;
                    invoicePayment.Payment_BU__c = groupBUId;
                    invoicePayment.Comment__c = item.Payment_Label__c;
                    invoicePayment.Due_Date__c = item.Payment_Value_Date__c;
                    invoicePayment.Origin__c = 'Group';
                    invoicePayment.Payment_Date__c = item.Payment_Date__c;
                    invoicePayment.Payment_Type__c = item.Payment_Term__c;
                    invoicePayment.Supplier__c = item.Supplier__c;
                    invoicePayment.Linked_Payment_Group__c = null;
                    invoicePayment.Linked_Rebate_Payment_group__c = item.Id;
                    invoicePayment.Value_Date__c = item.Payment_Date__c;
                    // Fill invoice payment detail
                    invoicePaymentDetail.Due_Date__c = item.Payment_Value_Date__c;
                    invoicePaymentDetail.Matching_Amount__c = item.Amount_w_Tax__c;
                    // Update Rebate Payment Group Status/Last_synchro_date__c
                    if(String.IsBlank(item.Contract_Reference__c) || !contractSet.Contains(item.Contract_Reference__r.Contract_Linked__c)) item.Status__c = 'Synchronized without Contract';
                    else if(String.IsBlank(item.Condition_Reference__c) || !conditionSet.Contains(item.Condition_Reference__r.Condition_Linked__c)) item.Status__c = 'Synchronized without Condition';
                    else item.Status__c = 'Synchronized';
                    item.Last_synchro_date__c = System.now();
                    // Fill Wrapper
                    WrapperRebatePayment wRebatePayment = new WrapperRebatePayment(item, invoice, invoiceDetail, invoicePayment, invoicePaymentDetail);
                    wRebatePaymentList.add(wRebatePayment);
                }
            }
            
            // check security on update rebate group fields
            String[] rebateGroupUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Linked__c'), NegoptimHelper.normalizeAPIName('Payment_Linked__c'),
                NegoptimHelper.normalizeAPIName('Error_desc__c'), NegoptimHelper.normalizeAPIName('Last_synchro_date__c')};

            // check security on insert invoice line fields
            String[] invoiceDetailCreateFields = new String[]{ NegoptimHelper.normalizeAPIName('Invoice__c') };
            invoiceDetailCreateFields.addAll(invoiceDetailFields);
            
            // check security on insert payment line fields
            String[] paymentDetailCreateFields = new String[]{ NegoptimHelper.normalizeAPIName('Paiement__c'), NegoptimHelper.normalizeAPIName('Invoice_Line__c') };
            paymentDetailCreateFields.addAll(paymentDetailFields);
                        
            if(NegoptimHelper.checkUpdatibility(Rebate_Payment_Group__c.SObjectType, rebateGroupUpdateFields) &&
               NegoptimHelper.checkCreatibility(Invoice__c.SObjectType, invoiceFields) &&
               NegoptimHelper.checkUpdatibility(Invoice__c.SObjectType, invoiceFields) &&
               NegoptimHelper.checkCreatibility(Invoice_Detail__c.SObjectType, invoiceDetailCreateFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Detail__c.SObjectType, invoiceDetailFields) &&
               NegoptimHelper.checkCreatibility(Invoice_Paiement__c.SObjectType, paymentFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Paiement__c.SObjectType, paymentFields) &&
               NegoptimHelper.checkCreatibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailCreateFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailFields))
            {
                // Map between invoice line and Wrapper rebate
                Map<Integer, WrapperRebatePayment> invoiceLineMap = new Map<Integer, WrapperRebatePayment>();
                // Map between payment and Wrapper rebate
                Map<Integer, WrapperRebatePayment> paymentMap = new Map<Integer, WrapperRebatePayment>();
                // Map between payment line and Wrapper rebate
                Map<Integer, WrapperRebatePayment> paymentLineMap = new Map<Integer, WrapperRebatePayment>();
                integer indexInv = 0, indexInvLine = 0, indexPayment = 0;                
                for (WrapperRebatePayment item : wRebatePaymentList) {
                    rebatePaymentGroupList.add(item.rebateGroup);
                    invoiceList.add(item.invoice);
                }
                // Upsert invoices
                if(invoiceList != null && invoiceList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(invoiceList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperRebatePayment wRebatePayment = wRebatePaymentList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = result.Id != null ? wRebatePayment.invoice.Name + '(' + result.Id + ') : ' : String.valueOf(wRebatePayment.invoice);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            wRebatePayment.rebateGroup.Error_desc__c += errorMessage;
                            wRebatePayment.rebateGroup.Status__c = 'Synchronized with error';
                            wRebatePayment.isvalid = false;
                        }
                        else {
                            // Set corresponding invoice Id.
                            if(wRebatePayment.invoiceLine.Invoice__c == null) wRebatePayment.invoiceLine.Invoice__c = wRebatePayment.invoice.Id;
                            if(wRebatePayment.rebateGroup.Invoice_Linked__c == null) wRebatePayment.rebateGroup.Invoice_Linked__c = wRebatePayment.invoice.Id;
                            // Fill list of valid invoice line
                            invoiceDetailsList.add(wRebatePayment.invoiceLine);
                            invoiceLineMap.put(indexInv, wRebatePayment);
                            indexInv++;
                        }
                    }
                }
                // Upsert Invoice Line
                if(invoiceDetailsList != null && invoiceDetailsList.size() > 0){
                    List<Database.UpsertResult> results = Database.upsert(invoiceDetailsList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperRebatePayment wRebatePayment = invoiceLineMap.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? wRebatePayment.invoiceLine.Name + '(' + result.Id + ') : ' : String.valueOf(wRebatePayment.invoiceLine);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            wRebatePayment.rebateGroup.Error_desc__c += errorMessage;
                            wRebatePayment.rebateGroup.Status__c = 'Synchronized with error';
                            wRebatePayment.invoicePaymentLine = null;
                            wRebatePayment.isvalid = false;
                        }
                        else {
                            if(wRebatePayment.invoicePaymentLine.Invoice_Line__c == null) wRebatePayment.invoicePaymentLine.Invoice_Line__c = wRebatePayment.invoiceLine.Id;
                            invoicePaymentList.add(wRebatePayment.invoicePayment);
                            paymentMap.put(indexInvLine, wRebatePayment);
                            indexInvLine++;
                        }
                    }
                }
                // Upsert Invoice Payment
                if(invoicePaymentList != null && invoicePaymentList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(invoicePaymentList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperRebatePayment wRebatePayment = paymentMap.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? wRebatePayment.invoicePayment.Name + '(' + result.Id + ') : ' : String.valueOf(wRebatePayment.invoicePayment);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            wRebatePayment.rebateGroup.Error_desc__c += errorMessage;
                            wRebatePayment.rebateGroup.Status__c = 'Synchronized with error';
                            wRebatePayment.isvalid = false;
                        }
                        else {
                            // Set corresponding invoice Payment Id.                        
                            if(wRebatePayment.rebateGroup.Payment_Linked__c == null) wRebatePayment.rebateGroup.Payment_Linked__c = wRebatePayment.invoicePayment.Id;
                            if(wRebatePayment.invoicePaymentLine != null){
                                if(wRebatePayment.invoicePaymentLine.Paiement__c == null) wRebatePayment.invoicePaymentLine.Paiement__c = wRebatePayment.invoicePayment.Id;
                                // Fill list of valid payment line based of invoice line inserted
                                invoicePaymentDetailsList.add(wRebatePayment.invoicePaymentLine);
                                paymentLineMap.put(indexPayment, wRebatePayment);
                                indexPayment++;
                            }
                        }
                    }
                }
                // Upsert Invoice Payment Line
                if(invoicePaymentDetailsList != null && invoicePaymentDetailsList.size() > 0){
                    List<Database.UpsertResult> results = Database.upsert(invoicePaymentDetailsList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        WrapperRebatePayment wRebatePayment = paymentLineMap.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = result.Id != null ? wRebatePayment.invoicePaymentLine.Name + '(' + result.Id + ') : ' : String.valueOf(wRebatePayment.invoicePaymentLine);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            wRebatePayment.rebateGroup.Error_desc__c += errorMessage;
                            wRebatePayment.rebateGroup.Status__c = 'Synchronized with error';
                            wRebatePayment.isvalid = false;
                        }
                    }
                }
                // Update rebate payment Group
                if(rebatePaymentGroupList != null && rebatePaymentGroupList.size() > 0){
                    List<Database.SaveResult> results = Database.update(rebatePaymentGroupList, false);
                    nb.logResults(results, rebatePaymentGroupList);
                    
                    //******* check invalid synchronized *******//
                    // List of invoices to delete.
                    List<Invoice__c> invoiceDeletedList = new List<Invoice__c>();
                    // List of invoices detail to delete.
                    List<Invoice_Detail__c> invoiceDetailsDeletedList = new List<Invoice_Detail__c>();
                    // List of invoices payment to delete.
                    List<Invoice_Paiement__c> paymentDeletedList = new List<Invoice_Paiement__c>();
                    // List of invoices payment lines to delete.
                    List<Invoice_Paiement_Detail__c> paymentDetailsDeletedList = new List<Invoice_Paiement_Detail__c>();
                    for (WrapperRebatePayment item : wRebatePaymentList) {
                        if(!item.isvalid) {
                            if(item.invoice != null && item.invoice.Id != null) invoiceDeletedList.add(item.invoice);
                            if(item.invoiceLine != null && item.invoiceLine.Id != null) invoiceDetailsDeletedList.add(item.invoiceLine);
                            if(item.invoicePayment != null && item.invoicePayment.Id != null) paymentDeletedList.add(item.invoicePayment);
                            if(item.invoicePaymentLine != null && item.invoicePaymentLine.Id != null) paymentDetailsDeletedList.add(item.invoicePaymentLine);
                        }
                    }
                    if(!invoiceDeletedList.isEmpty()) {
                        if (NegoptimHelper.checkDeletibility(Invoice__c.SObjectType)) {
                            Database.DeleteResult[] deleteResults = Database.Delete(invoiceDeletedList, false);
                        }
                    }
                    if(!invoiceDetailsDeletedList.isEmpty()) {
                        if (NegoptimHelper.checkDeletibility(Invoice_Detail__c.SObjectType)) {
                            Database.DeleteResult[] deleteResults = Database.Delete(invoiceDetailsDeletedList, false);
                        }
                    }
                    if(!paymentDeletedList.isEmpty()) {
                        if (NegoptimHelper.checkDeletibility(Invoice_Paiement__c.SObjectType)) {
                            Database.DeleteResult[] deleteResults = Database.Delete(paymentDeletedList, false);
                        }
                    }
                    if(!paymentDetailsDeletedList.isEmpty()) {
                        if (NegoptimHelper.checkDeletibility(Invoice_Paiement_Detail__c.SObjectType)) {
                            Database.DeleteResult[] deleteResults = Database.Delete(paymentDetailsDeletedList, false);
                        }
                    }
                }
            }
        }
        catch(DmlException e) {  
            Database.rollback(sp);        
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        }
        catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    /* Wrapper Class for Rebate Payment. */
    public class WrapperRebatePayment {
        public Rebate_Payment_Group__c rebateGroup {get; set;}
        public Invoice__c invoice {get; set;}
        public Invoice_Detail__c invoiceLine {get; set;}
        public Invoice_Paiement__c invoicePayment {get; set;}
        public Invoice_Paiement_Detail__c invoicePaymentLine {get; set;}
        public Boolean isValid {get; set;}
        public WrapperRebatePayment(Rebate_Payment_Group__c rebate, Invoice__c inv, Invoice_Detail__c invLine, Invoice_Paiement__c invPayment, Invoice_Paiement_Detail__c invPaymentLine) {
            rebateGroup = rebate;
            rebateGroup.Error_desc__c = '';
            invoice = inv;
            invoiceLine = invLine;
            invoicePayment = invPayment;
            invoicePaymentLine = invPaymentLine;
            isValid = true;
        }
    }
}