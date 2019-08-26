/*
 * Prepare accounting balance that will be called during monthly during closure.				
 * Based on the accouting schema, it will generate the accouting journal, keep the relation with invoices, payment & redistrib data and organize the synchro to accounting system.				
 */ 
public with sharing class AccountingClosingPaymentBatch implements Database.Batchable<sObject>, Database.stateful {

    private NegoptimBatch nb;
    public String query;
    public final Accounting_Closing__c accountingClosing;
    public final List<Accounting_Scheme__c> accountingSchemes;
    
    // Constructor.
    public AccountingClosingPaymentBatch(String startedFrom, Accounting_Closing__c accountingClosing, List<Accounting_Scheme__c> accountingSchemes) {
        this.nb = new NegoptimBatch('Accounting Closing Payment', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.accountingClosing = accountingClosing;
        this.accountingSchemes = accountingSchemes;
        
        Set<Id> creditedCompanySet = new Set<Id>();
        List<String> negoDiscTypeForPaymentList = new List<String>();
        Set<String> paymentTypeSet = new Set<String>();
        if(accountingSchemes != null && !accountingSchemes.isEmpty()) {
            for(Accounting_Scheme__c item : accountingSchemes){            
                // Manage Payments accounting
                if(item.RecordType.DeveloperName == 'Payments' && item.Credited_Company__c != null && item.Debited_Company__c != null && item.Included_Discount_Types__c != null &&
                   item.Include_Free_Invoices__c != null && item.Payment_Type__c != null && item.Closing_Accounting_Type__c != null && item.Flag_D_or_C__c != null)
                {
                    // Get credit company list
                    if(item.Credited_Company__c != null){
                        creditedCompanySet.add(item.Credited_Company__c);
                    }
                    // Get all nego discount type
                    if(item.Included_Discount_Types__c != null){
                        negoDiscTypeForPaymentList.addAll(item.Included_Discount_Types__c.split(';'));
                    }
                    // Fill payment type list
                    if(item.Payment_Type__c != null){
                        paymentTypeSet.add(item.Payment_Type__c);
                    }
                }            
            }
        }
        
        String q = 'SELECT Invoice_Line__r.Invoice__r.Inv_Business_Unit__r.Legal_Form__c,';
        q += ' Invoice_Line__r.Invoice_detail_nego_disc_type__c, Invoice_Line__r.Invoice__r.Inv_Nego_year__c,';
        q += ' Paiement__r.Closing_Calc_date__c, Paiement__r.Closing_Payment_Name__c,';
        q += ' Paiement__r.Closing_Payment_code__c, Paiement__r.Closing_Payment_code_Group__c,';
        q += ' Paiement__r.Payment_Type__c, Matching_Amount__c, Accounting_Entry_credit__c, Accounting_Entry_debit__c';
        q += ' FROM Invoice_Paiement_Detail__c';
        q += ' WHERE Invoice_Line__r.Invoice__r.Inv_Business_Unit__r.Legal_Form__c IN (\'' + String.join(new List<Id>(creditedCompanySet), '\',\'') +'\')';
        q += ' AND (Invoice_Line__r.Invoice_detail_nego_disc_type__c IN (\'' + String.join(negoDiscTypeForPaymentList, '\',\'') +'\') OR Invoice_Line__r.Invoice_detail_nego_disc_type__c = NULL)';
        q += ' AND Paiement__r.Payment_Type__c IN (\'' + String.join(new List<String>(paymentTypeSet), '\',\'') +'\')';
        q += ' AND Invoice_Line__r.Invoice__r.Inv_Nego_year__c <> NULL AND Paiement__r.Closing_Calc_date__c <> NULL';
        q += ' AND Paiement__r.Closing_Payment_Name__c <> NULL AND Paiement__r.Closing_Payment_code__c <> NULL';
        q += ' AND Paiement__r.Closing_Payment_code_Group__c <> NULL';
        q += ' AND Accounting_Entry_credit__c = NULL AND Accounting_Entry_debit__c = NULL';
        
        query = q;
        // push inputs to log
        nb.logParameter('query', this.query);
        nb.logParameter('accountingClosing', this.accountingClosing);
        nb.logParameter('accountingSchemes', this.accountingSchemes);
    }
    // Start method implementation.
    public Database.QueryLocator start(Database.BatchableContext BC) {
         query += '' + (Test.isRunningTest() ? ' LIMIT 1000' : '');
        return Database.getQueryLocator(query);
    }
    // Execute method implementation.
    public void execute(Database.BatchableContext BC, List<Invoice_Paiement_Detail__c> scope) {        
        // Fill list of accounting scheme for payments
        Map<String, List<Accounting_Scheme__c>> accountingSchemeForPaymentMap = new Map<String, List<Accounting_Scheme__c>>();
        Map<Id, List<Accounting_Scheme__c>> creditedCompanyForPaymentMap = new Map<Id, List<Accounting_Scheme__c>>();
        Map<String, Accounting_Scheme__c> payDCTypeMap = new Map<String, Accounting_Scheme__c>();
        Set<String> paymentDetailAssignToAccountingEntrySet = new Set<String>();
        Set<Integer> invNegoYearSet = new Set<Integer>();
        Set<Date> closingCalcDateSet = new Set<Date>();
        Set<String> closingPaymentNameSet = new Set<String>();
        Set<String> closingPaymentCodeSet = new Set<String>();
        Set<String> closingPaymentCodeGroupSet = new Set<String>();
        
        Map<String, WrapperAccounting> accountingPaymentMap = new Map<String, WrapperAccounting>();
        List<Accounting_Entry__c> accountingEntryList = new List<Accounting_Entry__c>();        
        Map<Id, Invoice_Paiement_Detail__c> invoicePaymentDetailMap = new Map<Id, Invoice_Paiement_Detail__c>();
        
        Map<Id, Accounting_Scheme__c> accountingSchemeMap = new Map<Id, Accounting_Scheme__c>(accountingSchemes);
        
        for(Accounting_Scheme__c item : accountingSchemes) {
            // Manage Payments accounting
            if(item.RecordType.DeveloperName == 'Payments' && item.Credited_Company__c != null && item.Debited_Company__c != null && item.Included_Discount_Types__c != null &&
               item.Include_Free_Invoices__c != null && item.Payment_Type__c != null && item.Closing_Accounting_Type__c != null && item.Flag_D_or_C__c != null)
            {
                String key = item.Credited_Company__c + '' + item.Debited_Company__c + '' + item.Included_Discount_Types__c + '' +
                    item.Include_Free_Invoices__c + '' + item.Payment_Type__c + '' + item.Closing_Accounting_Type__c;
                
                String keyPayment = key + item.Flag_D_or_C__c;                   
                // Map distinct credit company, debited company, discount types, payment type, closing accounting type
                if(!accountingSchemeForPaymentMap.containsKey(key)){
                    if(creditedCompanyForPaymentMap.containsKey(item.Credited_Company__c)) {
                        creditedCompanyForPaymentMap.get(item.Credited_Company__c).add(item);
                    }
                    else{
                        creditedCompanyForPaymentMap.put(item.Credited_Company__c, new List<Accounting_Scheme__c>{item});
                    }
                }
                // Fill Map payment type
                if(!payDCTypeMap.containsKey(keyPayment)) {
                    payDCTypeMap.put(keyPayment, item);
                    // Fill Map accounting scheme for Payments
                    if(accountingSchemeForPaymentMap.containsKey(key)) {
                        accountingSchemeForPaymentMap.get(key).add(item);
                    }
                    else{
                        accountingSchemeForPaymentMap.put(key, new List<Accounting_Scheme__c>{item});
                    }
                }
            }
        }
        
        // Get accounting entry list already created for same closing
        List<Accounting_Entry__c> oldAccountingEntryList = [SELECT Id, Name, Accounting_Closing__c, Accounting_Scheme_Line__c, Credited_Company__c, Debited_Company__c,
                                                            Entry_Label__c, Comment__c, VAT_rate__c, Amount__c, Amount_signed__c, Status__c, Reference_year__c, Flag_D_or_C__c
                                                            FROM Accounting_Entry__c
                                                            WHERE Accounting_Closing__c = :this.accountingClosing.Id AND Accounting_Scheme_Line__c IN :this.accountingSchemes
                                                            AND Accounting_Scheme_Line__r.RecordType.DeveloperName = 'Payments'];
        if(oldAccountingEntryList != null && oldAccountingEntryList.size() > 0) {
            for (Invoice_Paiement_Detail__c item : scope) {
                if(item.Invoice_Line__r.Invoice__r.Inv_Nego_year__c != null) {
                    invNegoYearSet.add(Integer.valueOf(item.Invoice_Line__r.Invoice__r.Inv_Nego_year__c));
                }
                if(item.Paiement__r.Closing_Calc_date__c != null) {
                    closingCalcDateSet.add(item.Paiement__r.Closing_Calc_date__c);
                }
                if(item.Paiement__r.Closing_Payment_Name__c != null) {
                    closingPaymentNameSet.add(item.Paiement__r.Closing_Payment_Name__c);
                }
                if(item.Paiement__r.Closing_Payment_code__c != null) {
                    closingPaymentCodeSet.add(item.Paiement__r.Closing_Payment_code__c);
                }
                if(item.Paiement__r.Closing_Payment_code_Group__c != null) {
                    closingPaymentCodeGroupSet.add(item.Paiement__r.Closing_Payment_code_Group__c);
                }
            }
            List<Invoice_Paiement_Detail__c> paymentDetails = [SELECT Invoice_Line__r.Invoice__r.Inv_Business_Unit__r.Legal_Form__c,
                                                               Invoice_Line__r.Invoice_detail_nego_disc_type__c, Invoice_Line__r.Invoice__r.Inv_Nego_year__c,
                                                               Paiement__r.Closing_Calc_date__c, Paiement__r.Closing_Payment_Name__c,
                                                               Paiement__r.Closing_Payment_code__c, Paiement__r.Closing_Payment_code_Group__c,
                                                               Paiement__r.Payment_Type__c, Matching_Amount__c, Accounting_Entry_credit__c, Accounting_Entry_debit__c
                                                               FROM Invoice_Paiement_Detail__c
                                                               WHERE Invoice_Line__r.Invoice__r.Inv_Nego_year__c IN :invNegoYearSet 
                                                               AND Paiement__r.Closing_Calc_date__c IN :closingCalcDateSet
                                                               AND Paiement__r.Closing_Payment_Name__c IN :closingPaymentNameSet
                                                               AND Paiement__r.Closing_Payment_code__c IN :closingPaymentCodeSet
                                                               AND Paiement__r.Closing_Payment_code_Group__c IN :closingPaymentCodeGroupSet
                                                               AND (Accounting_Entry_credit__c IN :oldAccountingEntryList OR Accounting_Entry_debit__c IN :oldAccountingEntryList)];
            Map<Id, Invoice_Paiement_Detail__c> oldAccountingEntryMap = new Map<Id, Invoice_Paiement_Detail__c>();
            if(!paymentDetails.isEmpty()) {
                for (Invoice_Paiement_Detail__c item : paymentDetails) {
                    if(item.Accounting_Entry_credit__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_Entry_credit__c)) {
                        oldAccountingEntryMap.put(item.Accounting_Entry_credit__c, item);
                    }
                    if(item.Accounting_Entry_debit__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_Entry_debit__c)) {
                        oldAccountingEntryMap.put(item.Accounting_Entry_debit__c, item);
                    }
                }
                for(Accounting_Entry__c item : oldAccountingEntryList) {
                    Invoice_Paiement_Detail__c paymentDetail = oldAccountingEntryMap.get(item.Id);
                    if(paymentDetail == null) continue;
                    Decimal invNegoYear = paymentDetail.Invoice_Line__r.Invoice__r.Inv_Nego_year__c;
                    Date closingCalcDate = paymentDetail.Paiement__r.Closing_Calc_date__c;
                    String closingPaymentName = paymentDetail.Paiement__r.Closing_Payment_Name__c;
                    String closingPaymentCode = paymentDetail.Paiement__r.Closing_Payment_code__c;
                    String closingPaymentCodeGroup = paymentDetail.Paiement__r.Closing_Payment_code_Group__c;
                    
                    Accounting_Scheme__c accountingScheme = accountingSchemeMap.get(item.Accounting_Scheme_Line__c);
                    
                    String key = item.Credited_Company__c + '' + item.Debited_Company__c + '' +
                        (accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : '' ) + '' +
                        accountingScheme.Include_Free_Invoices__c + '' + accountingScheme.Payment_Type__c + '' +
                        accountingScheme.Closing_Accounting_Type__c + '' + Integer.valueOf(invNegoYear) + '' + closingCalcDate + '' + closingPaymentName + '' + 
                        closingPaymentCode + '' + closingPaymentCodeGroup;
                    
                    WrapperAccounting wAccounting;
                    if(accountingPaymentMap.containsKey(key)) {
                        wAccounting = accountingPaymentMap.get(key);
                    }
                    else {
                        wAccounting = new WrapperAccounting();
                        wAccounting.accountingScheme = accountingScheme;
                        wAccounting.accountingClosing = accountingClosing;
                        wAccounting.creditedCompanyId = item.Credited_Company__c;
                        wAccounting.debitedCompanyId = item.Debited_Company__c;
                        wAccounting.NegoDiscountTypes = accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : null;
                        wAccounting.invNegoYear = invNegoYear;
                        wAccounting.includeFreeInvoices = accountingScheme.Include_Free_Invoices__c;
                        wAccounting.accountingType = accountingScheme.Accounting_Type__c;
                        wAccounting.closingAccountingType = accountingScheme.Closing_Accounting_Type__c;
                        wAccounting.paymentType = accountingScheme.Payment_Type__c;
                        wAccounting.closingCalcDate = closingCalcDate;
                        wAccounting.closingPaymentName = closingPaymentName;
                        wAccounting.closingPaymentCode = closingPaymentCode;
                        wAccounting.closingPaymentCodeGroup = closingPaymentCodeGroup;
                        wAccounting.businessUnitId = accountingScheme.Business_Unit__c;
                        wAccounting.businessUnitName = accountingScheme.Business_Unit__r.Name;
                        wAccounting.creditedCompanyName = accountingScheme.Credited_Company__r.Name;
                        wAccounting.debitedCompanyName = accountingScheme.Debited_Company__r.Name;
                        accountingPaymentMap.put(key, wAccounting);
                    }
                    if(item.Flag_D_or_C__c == 'Credit'){
                        wAccounting.isLinkedToCredit = true;
                        wAccounting.existCredit = true;
                        wAccounting.payAmountcredit = item.Amount_signed__c;
                    }
                    if(item.Flag_D_or_C__c == 'Debit'){
                        wAccounting.isLinkedToDebit = true;
                        wAccounting.existDebit = true;
                        wAccounting.payAmountdebit = item.Amount_signed__c;
                    }
                    wAccounting.paymentAccountingEntryMap.put(key + '' + item.Flag_D_or_C__c, item);
                    wAccounting.paymentAccountingEntries.add(item);
                }
            }
        }
        
        /* Prepare Accounting for Payments */        
        for (Invoice_Paiement_Detail__c item : scope) {
            Id creditedCompanyId = item.Invoice_Line__r.Invoice__r.Inv_Business_Unit__r.Legal_Form__c;
            Date closingCalcDate = item.Paiement__r.Closing_Calc_date__c;
            if(closingCalcDate > accountingClosing.Closing_Date__c){
                continue;
            }
            String negoDiscountType = item.Invoice_Line__r.Invoice_detail_nego_disc_type__c;
            String paymentType = item.Paiement__r.Payment_Type__c;
            Decimal invNegoYear = item.Invoice_Line__r.Invoice__r.Inv_Nego_year__c;
            String closingPaymentName = item.Paiement__r.Closing_Payment_Name__c;
            String closingPaymentCode = item.Paiement__r.Closing_Payment_code__c;
            String closingPaymentCodeGroup = item.Paiement__r.Closing_Payment_code_Group__c;
            Decimal payAmount = item.Matching_Amount__c != null ? item.Matching_Amount__c : 0;
            List<Accounting_Scheme__c> accountingSchemeList = creditedCompanyForPaymentMap.get(creditedCompanyId);
            if(accountingSchemeList != null && !accountingSchemeList.isEmpty()) {
                for(Accounting_Scheme__c accountingScheme : accountingSchemeList){
                    Boolean existCredit = false, existDebit = false, paymentDetailLinkedToCredit = false, paymentDetailLinkedToDebit = false;
                    Id debitedCompanyId = accountingScheme.Debited_Company__c;
                    String accountingType = accountingScheme.Accounting_Type__c;
                    String closingAccountingType = accountingScheme.Closing_Accounting_Type__c;
                    // Check free invoices
                    Boolean includeFreeInvoices = accountingScheme.Include_Free_Invoices__c;
                    String key;
                    if((negoDiscountType != null && accountingScheme.Included_Discount_Types__c.Contains(negoDiscountType))
                       || (includeFreeInvoices == true && negoDiscountType == null)) {
                           key = creditedCompanyId + '' + debitedCompanyId + '' + accountingScheme.Included_Discount_Types__c + '' + includeFreeInvoices + '' +
                               paymentType + '' + closingAccountingType + '' + Integer.valueOf(invNegoYear) + '' + closingCalcDate + '' + closingPaymentName + '' + closingPaymentCode + '' + closingPaymentCodeGroup;
                       }
                    if(String.isNotBlank(key)){
                        // check if payment line assign to accounting credit or debit
                        String paymentkey = creditedCompanyId + '' + debitedCompanyId + '' + accountingScheme.Included_Discount_Types__c + '' + includeFreeInvoices + '' + paymentType + '' + closingAccountingType;
                        if(accountingSchemeForPaymentMap.containsKey(paymentkey)){
                            List<Accounting_Scheme__c> accountingSchemesForPayment = accountingSchemeForPaymentMap.get(paymentkey);
                            for(Accounting_Scheme__c scheme : accountingSchemesForPayment){
                                if(scheme.Flag_D_or_C__c == 'Credit'){
                                    existCredit = true;
                                    if(paymentDetailAssignToAccountingEntrySet.contains(item.Id + '' + scheme.Flag_D_or_C__c)){
                                        paymentDetailLinkedToCredit = true;
                                    }
                                    else{
                                        paymentDetailAssignToAccountingEntrySet.add(item.Id + '' + scheme.Flag_D_or_C__c);
                                    }
                                }
                                if(scheme.Flag_D_or_C__c == 'Debit'){
                                    existDebit = true;
                                    if(paymentDetailAssignToAccountingEntrySet.contains(item.Id + '' + scheme.Flag_D_or_C__c)){
                                        paymentDetailLinkedToDebit = true;
                                    }
                                    else{
                                        paymentDetailAssignToAccountingEntrySet.add(item.Id + '' + scheme.Flag_D_or_C__c);
                                    }
                                }
                            }
                        }
                        if((existCredit && !paymentDetailLinkedToCredit) || (existDebit && !paymentDetailLinkedToDebit)){
                            WrapperAccounting wAccounting;
                            if(accountingPaymentMap.containsKey(key)){
                                wAccounting = accountingPaymentMap.get(key);                            
                                wAccounting.invoicePaymentDetails.add(item);
                            }
                            else{
                                wAccounting = new WrapperAccounting();
                                wAccounting.accountingScheme = accountingScheme;
                                wAccounting.accountingClosing = accountingClosing;
                                wAccounting.creditedCompanyId = creditedCompanyId;
                                wAccounting.debitedCompanyId = debitedCompanyId;
                                wAccounting.NegoDiscountTypes = accountingScheme.Included_Discount_Types__c;
                                wAccounting.invNegoYear = invNegoYear;
                                wAccounting.includeFreeInvoices = includeFreeInvoices;
                                wAccounting.accountingType = accountingType;
                                wAccounting.closingAccountingType = closingAccountingType;
                                wAccounting.paymentType = paymentType;
                                wAccounting.closingCalcDate = closingCalcDate;
                                wAccounting.closingPaymentName = closingPaymentName;
                                wAccounting.closingPaymentCode = closingPaymentCode;
                                wAccounting.closingPaymentCodeGroup = closingPaymentCodeGroup;                            
                                wAccounting.businessUnitId = accountingScheme.Business_Unit__c;
                                wAccounting.businessUnitName = accountingScheme.Business_Unit__r.Name;
                                wAccounting.creditedCompanyName = accountingScheme.Credited_Company__r.Name;
                                wAccounting.debitedCompanyName = accountingScheme.Debited_Company__r.Name;                            
                                wAccounting.invoicePaymentDetails.add(item);
                                accountingPaymentMap.put(key, wAccounting);
                            }
                            // calculate amount
                            if(existCredit && !paymentDetailLinkedToCredit){
                                wAccounting.payAmountcredit += payAmount;
                            }
                            if(existDebit && !paymentDetailLinkedToDebit){
                                wAccounting.payAmountdebit += payAmount;                                
                            }
                            if(!wAccounting.isLinkedToCredit){
                                wAccounting.isLinkedToCredit = existCredit && !paymentDetailLinkedToCredit;
                            }
                            if(!wAccounting.isLinkedToDebit){
                                wAccounting.isLinkedToDebit = existDebit && !paymentDetailLinkedToDebit;
                            }
                            // Assign payment detail to credit or debit
                            if(existCredit && !paymentDetailLinkedToCredit){
                                if(wAccounting.payTypeForPaymentMap.containsKey(item.Id)){
                                    wAccounting.payTypeForPaymentMap.get(item.Id).add('Credit');
                                }
                                else{
                                    wAccounting.payTypeForPaymentMap.put(item.Id, new Set<String>{'Credit'});
                                }
                            }
                            if(existDebit && !paymentDetailLinkedToDebit){
                                if(wAccounting.payTypeForPaymentMap.containsKey(item.Id)){
                                    wAccounting.payTypeForPaymentMap.get(item.Id).add('Debit');
                                }
                                else{
                                    wAccounting.payTypeForPaymentMap.put(item.Id, new Set<String>{'Debit'});
                                }
                            }
                        }
                    }
                }
            }
        }
        if(accountingPaymentMap != null && !accountingPaymentMap.isEmpty()) {
            for (WrapperAccounting item : accountingPaymentMap.values()) {
                if(item.isLinkedToCredit){
                    if(!item.existCredit) {
                        item.insertAccountingEntryForPayment('Credit', item.payAmountcredit, payDCTypeMap);
                    }
                    else {
                        item.updateAccountingEntryForPayment('Credit', item.payAmountcredit);
                    }
                }
                if(item.isLinkedToDebit){
                    if(!item.existDebit) {
                        item.insertAccountingEntryForPayment('Debit', item.payAmountdebit, payDCTypeMap);
                    }
                    else {
                        item.updateAccountingEntryForPayment('Debit', item.payAmountdebit);
                    }
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try{
            // check security on insert accounting entry fields
            String[] accountingEntryInsertFields = new String[] { NegoptimHelper.normalizeAPIName('Entry_Type__c'),
                NegoptimHelper.normalizeAPIName('Accounting_Closing__c'), NegoptimHelper.normalizeAPIName('Accounting_Scheme_Line__c'),
                NegoptimHelper.normalizeAPIName('Credited_Company__c'), NegoptimHelper.normalizeAPIName('Debited_Company__c'),
                NegoptimHelper.normalizeAPIName('Entry_Label__c'), NegoptimHelper.normalizeAPIName('Comment__c'),
                NegoptimHelper.normalizeAPIName('Amount__c'), NegoptimHelper.normalizeAPIName('Amount_signed__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Reference_year__c')};
            
            // check security on update accounting entry fields
            String[] accountingEntryUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Amount__c'), NegoptimHelper.normalizeAPIName('Amount_signed__c')};
                        
            // check security on update payment line fields
            String[] paymentDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Accounting_Entry_credit__c'), NegoptimHelper.normalizeAPIName('Accounting_Entry_debit__c')};
            if(accountingPaymentMap != null && !accountingPaymentMap.isEmpty()) {
                for (WrapperAccounting item : accountingPaymentMap.values()) {
                    accountingEntryList.addAll(item.paymentAccountingEntries);
                    if(String.isNotBlank(item.errorMessage)) {
                        nb.logError(item.errorMessage);
                    }
                }
            }
            if(NegoptimHelper.checkCreatibility(Accounting_Entry__c.SObjectType, accountingEntryInsertFields) &&
               NegoptimHelper.checkUpdatibility(Accounting_Entry__c.SObjectType, accountingEntryUpdateFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailFields))
            {
                // Insert Accounting Entry.
                if(accountingEntryList != null && accountingEntryList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(accountingEntryList, false);
                    nb.logResults(results, accountingEntryList);
                                        
                    Map<Id, Accounting_Entry__c> accountingEntryMap = new Map<Id, Accounting_Entry__c>([SELECT Id, Name, Ext_id__c, Amount_Type__c, Flag_D_or_C__c, Accounting_Entry_for__c 
                                                                                                        FROM Accounting_Entry__c WHERE Id IN :accountingEntryList]);
                    // Update Invoice Payment Details.
                    if(accountingEntryMap != null && accountingEntryMap.size() > 0){
                        for (WrapperAccounting item : accountingPaymentMap.values()) {
                            for(Invoice_Paiement_Detail__c invoicePaymentDetail : item.invoicePaymentDetails){
                                if(invoicePaymentDetailMap.containsKey(invoicePaymentDetail.Id)){
                                    invoicePaymentDetail = invoicePaymentDetailMap.get(invoicePaymentDetail.Id);
                                }else{
                                    invoicePaymentDetailMap.put(invoicePaymentDetail.Id, invoicePaymentDetail);
                                }
                                // check payment detail linked to credit or debit
                                Set<String> payTypeSet;
                                if(item.payTypeForPaymentMap.containsKey(invoicePaymentDetail.Id)){
                                    payTypeSet = item.payTypeForPaymentMap.get(invoicePaymentDetail.Id);
                                }
                                if(payTypeSet == null) continue;
                                for(Accounting_Entry__c accountingEntry : item.paymentAccountingEntries){
                                    if(accountingEntry.Id != null && accountingEntryMap.get(accountingEntry.Id) != null){
                                        accountingEntry = accountingEntryMap.get(accountingEntry.Id);
                                        if(accountingEntry.Flag_D_or_C__c == 'Credit' && payTypeSet.contains(accountingEntry.Flag_D_or_C__c) && invoicePaymentDetail.Accounting_Entry_credit__c == null){
                                            invoicePaymentDetail.Accounting_Entry_credit__c = accountingEntry.Id;
                                        }
                                        if(accountingEntry.Flag_D_or_C__c == 'Debit' && payTypeSet.contains(accountingEntry.Flag_D_or_C__c)  && invoicePaymentDetail.Accounting_Entry_debit__c == null){
                                            invoicePaymentDetail.Accounting_Entry_debit__c = accountingEntry.Id;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if(invoicePaymentDetailMap != null && invoicePaymentDetailMap.size() > 0) {
                    List<Database.SaveResult> results = Database.update(invoicePaymentDetailMap.values(), false);
                    nb.logResults(results, invoicePaymentDetailMap.values());
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            // Roll everything back in case of error.
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
    
    /* Wrapper Class for Accounting */
    public class WrapperAccounting {
        Accounting_Closing__c accountingClosing {get; set;}
        Accounting_Scheme__c accountingScheme {get; set;}
        
        Map<String, Accounting_Entry__c> paymentAccountingEntryMap {get; set;}
        List<Accounting_Entry__c> paymentAccountingEntries {get; set;}
        List<Invoice_Paiement_Detail__c> invoicePaymentDetails {get; set;}
        Map<Id, Set<String>> payTypeForPaymentMap {get; set;}
                
        String errorMessage {get; set;}
        Id businessUnitId {get; set;}
        Id creditedCompanyId {get; set;}
        Id debitedCompanyId {get; set;}
        String businessUnitName {get; set;}
        String creditedCompanyName {get; set;}
        String debitedCompanyName {get; set;}
        String NegoDiscountType {get; set;}
        String NegoDiscountTypes {get; set;}
        Decimal invNegoYear {get; set;}
        Boolean includeFreeInvoices {get; set;}
        String accountingType {get; set;}
        // Accounting payments parameters
        String paymentType {get; set;}
        String closingAccountingType {get; set;}
        Date closingCalcDate {get; set;}
        String closingPaymentName {get; set;}
        String closingPaymentCode {get; set;}
        String closingPaymentCodeGroup {get; set;}
        Decimal payAmountcredit {get; set;}
        Decimal payAmountdebit {get; set;}
        Boolean isLinkedToCredit {get; set;}
        Boolean isLinkedToDebit {get; set;}
        Boolean existCredit {get; set;}
        Boolean existDebit {get; set;}
                
        // constructor
        public WrapperAccounting() {
            paymentAccountingEntryMap = new Map<String, Accounting_Entry__c>();
            
            paymentAccountingEntries = new List<Accounting_Entry__c>();
            invoicePaymentDetails = new List<Invoice_Paiement_Detail__c>();
            payTypeForPaymentMap = new Map<Id, Set<String>>();
            
            isLinkedToCredit = false;
            isLinkedToDebit = false;
            existCredit = false;
            existDebit = false;
            
            payAmountcredit = 0;
            payAmountdebit = 0;
            errorMessage ='';
        }
        
        // create accounting entry for payments
        public void insertAccountingEntryForPayment(String payType, Decimal amount, Map<String, Accounting_Scheme__c> payDCTypeMap) {
            String key = this.creditedCompanyId + '' + this.debitedCompanyId + '' + this.NegoDiscountTypes + '' + 
                this.includeFreeInvoices + '' + this.paymentType + '' + this.closingAccountingType + '' + payType;
            Accounting_Scheme__c accountingSchemeForPayment;
            if(payDCTypeMap.containsKey(key)) {
                accountingSchemeForPayment = payDCTypeMap.get(key);
            }
            if(accountingSchemeForPayment == null) {
                this.errorMessage += string.format('Accounting scheme based on the business unit {0}, credited company {1}, debited company {2}, NegoDiscountTypes {3}, payment type {4}, closing accounting type {5} and Flag D or C {6} not exist.', 
                                                   new String[]{ this.businessUnitName, this.creditedCompanyName, this.debitedCompanyName, this.NegoDiscountTypes, this.paymentType, this.closingAccountingType, payType }) + '\n';
                return;
            }
            Accounting_Entry__c accountingEntry = new Accounting_Entry__c(Entry_Type__c = 'Payment',
                                                                          Accounting_Closing__c = accountingClosing.Id,
                                                                          Accounting_Scheme_Line__c = accountingSchemeForPayment != null ? accountingSchemeForPayment.Id : null,
                                                                          Credited_Company__c = this.creditedCompanyId,
                                                                          Debited_Company__c = this.debitedCompanyId,
                                                                          Entry_Label__c = this.closingPaymentName + ' ' + formatDate(this.closingCalcDate, 'dd/MM/yy'),
                                                                          Comment__c = Integer.valueOf(this.invNegoYear) + this.closingPaymentCode + this.closingPaymentCodeGroup + this.closingAccountingType,
                                                                          Amount__c = amount.abs(),
                                                                          Amount_signed__c = amount,
                                                                          Status__c = accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract',
                                                                          Reference_year__c = Integer.valueOf(this.invNegoYear));
            paymentAccountingEntries.add(accountingEntry);
        }
        
        // update existing accounting entry for payments
        public void updateAccountingEntryForPayment(String payType, Decimal amount) {
            String key = this.creditedCompanyId + '' + this.debitedCompanyId + '' + this.NegoDiscountTypes + '' + 
                this.includeFreeInvoices + '' + this.paymentType + '' + this.closingAccountingType + '' +
                Integer.valueOf(this.invNegoYear) + '' + this.closingCalcDate + '' + this.closingPaymentName + '' + 
                this.closingPaymentCode + '' + this.closingPaymentCodeGroup;
            Accounting_Entry__c accountingEntry = paymentAccountingEntryMap.get(key + '' + payType);
            accountingEntry.Amount__c = amount.abs();
            accountingEntry.Amount_signed__c = amount;
        }
        
        String formatDate(Date input, String format) {
            return DateTime.newInstance( input.year(), input.month(), input.day()).format(format);
        }
    }
}