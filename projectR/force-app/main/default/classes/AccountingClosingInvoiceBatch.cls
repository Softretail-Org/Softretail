/*
 * Prepare accounting balance that will be called during monthly during closure.				
 * Based on the accouting schema, it will generate the accouting journal, keep the relation with invoices, payment & redistrib data and organize the synchro to accounting system.				
 */ 
public with sharing class AccountingClosingInvoiceBatch implements Database.Batchable<sObject>, Database.stateful {

    private NegoptimBatch nb;
    public String query;
    public final Accounting_Closing__c accountingClosing;
    public final List<Accounting_Scheme__c> accountingSchemes;
    
    // Constructor.
    public AccountingClosingInvoiceBatch(String startedFrom, Accounting_Closing__c accountingClosing, List<Accounting_Scheme__c> accountingSchemes) {
        this.nb = new NegoptimBatch('Accounting Closing Invoice', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.accountingClosing = accountingClosing;
        this.accountingSchemes = accountingSchemes;
        
        Set<Id> creditedCompanySet = new Set<Id>();
        List<String> negoDiscTypeForInvoiceList = new List<String>();
        Set<String> accountingTypeSet = new Set<String>();
        if(accountingSchemes != null && !accountingSchemes.isEmpty()) {
            for(Accounting_Scheme__c item : accountingSchemes){
                // Manage Invoices accounting
                if(item.RecordType.DeveloperName == 'Invoices' && item.Credited_Company__c != null && item.Debited_Company__c != null && 
                   (item.Included_Discount_Types__c != null || item.Included_Discount_Type__c != null) && item.Include_Free_Invoices__c != null && item.Accounting_Type__c != null && item.Amount_Type__c != null)
                {
                    // Get credit company list
                    if(item.Credited_Company__c != null){
                        creditedCompanySet.add(item.Credited_Company__c);
                    }
                    // Get all nego discount type
                    if(item.Included_Discount_Type__c != null){
                        negoDiscTypeForInvoiceList.add(item.Included_Discount_Type__c);
                    }
                    if(item.Included_Discount_Types__c != null){
                        negoDiscTypeForInvoiceList.addAll(item.Included_Discount_Types__c.split(';'));
                    }
                    // Fill accounting type list
                    if(item.Accounting_Type__c != null){
                        accountingTypeSet.add(item.Accounting_Type__c);
                    }
                }
            }
        }
        String q = 'SELECT Invoice__r.Inv_Business_Unit__r.Legal_Form__c, Invoice_detail_nego_disc_type__c,';
        q += ' Invoice__r.Inv_Nego_year__c, Inv_VAT_Percent__c, Invoice_Value__c,';
        q += ' Inv_VAT_Value__c, Invoice_Detail_Value_w_VAT__c, Invoice__r.Inv_PrintedDate__c,';
        q += ' Inv_Detail_Condition__r.Accounting_Account_Type__c,';
        q += ' Accounting_entry_woVAT__c, Accounting_entry_VAT__c, Accounting_entry_wVAT__c';
        q += ' FROM Invoice_Detail__c';
        q += ' WHERE Invoice__r.Inv_Business_Unit__r.Legal_Form__c IN (\'' + String.join(new List<Id>(creditedCompanySet), '\',\'') +'\')';
        q += ' AND (Invoice_detail_nego_disc_type__c IN (\'' + String.join(negoDiscTypeForInvoiceList, '\',\'') +'\') OR Invoice_detail_nego_disc_type__c = NULL)';
        q += ' AND (Inv_Detail_Condition__r.Accounting_Account_Type__c IN (\'' + String.join(new List<String>(accountingTypeSet), '\',\'') +'\') OR Inv_Detail_Condition__c = NULL)';
        q += ' AND Invoice__r.Inv_PrintedDate__c <> NULL AND Invoice__r.Inv_Nego_year__c <> NULL AND Inv_VAT_Percent__c <> NULL';
        q += ' AND Accounting_entry_woVAT__c = NULL AND Accounting_entry_VAT__c = NULL AND Accounting_entry_wVAT__c = NULL';
        
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
    public void execute(Database.BatchableContext BC, List<Invoice_Detail__c> scope) {
        // Fill list of accounting scheme for invoices
        Map<String, List<Accounting_Scheme__c>> accountingSchemeForInvoiceMap = new Map<String, List<Accounting_Scheme__c>>();
        Map<Id, List<Accounting_Scheme__c>> creditedCompanyForInvoiceMap = new Map<Id, List<Accounting_Scheme__c>>();
        Map<String, Accounting_Scheme__c> amountTypeForInvoiceMap = new Map<String, Accounting_Scheme__c>();
        Set<String> invoiceDetailAssignToAccountingEntrySet = new Set<String>();
        
        Map<String, WrapperAccounting> accountingInvoiceMap = new Map<String, WrapperAccounting>();
        List<Accounting_Entry__c> accountingEntryList = new List<Accounting_Entry__c>();        
        Map<Id, Invoice_Detail__c> invoiceDetailMap = new Map<Id, Invoice_Detail__c>();
        
        Map<Id, Accounting_Scheme__c> accountingSchemeMap = new Map<Id, Accounting_Scheme__c>(accountingSchemes);
        
        for(Accounting_Scheme__c item : accountingSchemes){
            // Manage Invoices accounting
            if(item.RecordType.DeveloperName == 'Invoices' && item.Credited_Company__c != null && item.Debited_Company__c != null && 
               (item.Included_Discount_Types__c != null || item.Included_Discount_Type__c != null) && item.Include_Free_Invoices__c != null && item.Accounting_Type__c != null && item.Amount_Type__c != null)
            {
                String key = item.Credited_Company__c + '' + item.Debited_Company__c + '' +
                    (item.Included_Discount_Types__c != null ? item.Included_Discount_Types__c : '' ) + '' +
                    (item.Included_Discount_Type__c != null ? '-' + item.Included_Discount_Type__c : '' ) + '' +
                    item.Include_Free_Invoices__c + '' + item.Accounting_Type__c;
                
                String keyAmount = key + item.Amount_Type__c;
                // Map distinct credit company, debited company, (discount types or discount type), include free invoices
                if(!accountingSchemeForInvoiceMap.containsKey(key)){
                    if(creditedCompanyForInvoiceMap.containsKey(item.Credited_Company__c)){
                        creditedCompanyForInvoiceMap.get(item.Credited_Company__c).add(item);
                    }
                    else {
                        creditedCompanyForInvoiceMap.put(item.Credited_Company__c, new List<Accounting_Scheme__c>{item});
                    }
                }
                // Fill Map amount type
                if(!amountTypeForInvoiceMap.containsKey(keyAmount)){
                    amountTypeForInvoiceMap.put(keyAmount, item);                    
                    // Fill Map accounting scheme for invoices
                    if(accountingSchemeForInvoiceMap.containsKey(key)){
                        accountingSchemeForInvoiceMap.get(key).add(item);
                    }
                    else {
                        accountingSchemeForInvoiceMap.put(key, new List<Accounting_Scheme__c>{item});
                    }
                }
            }
        }
        
        // Get accounting entry list already created for same closing
        List<Accounting_Entry__c> oldAccountingEntryList = [SELECT Id, Name, Accounting_Closing__c, Accounting_Scheme_Line__c, Credited_Company__c, Debited_Company__c,
                                                            Entry_Label__c, Comment__c, VAT_rate__c, Amount__c, Amount_signed__c, Status__c, Reference_year__c, Amount_Type__c
                                                            FROM Accounting_Entry__c
                                                            WHERE Accounting_Closing__c = :this.accountingClosing.Id AND Accounting_Scheme_Line__c IN :this.accountingSchemes
                                                            AND Accounting_Scheme_Line__r.RecordType.DeveloperName = 'Invoices'];
        if(oldAccountingEntryList != null && oldAccountingEntryList.size() > 0) {
            for(Accounting_Entry__c item : oldAccountingEntryList) {
                Accounting_Scheme__c accountingScheme = accountingSchemeMap.get(item.Accounting_Scheme_Line__c);                
                String key = item.Credited_Company__c + '' + item.Debited_Company__c + '' +
                    (accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : '' ) + '' +
                    (accountingScheme.Included_Discount_Type__c != null ? '-' + accountingScheme.Included_Discount_Type__c : '' ) + '' +                           
                    accountingScheme.Include_Free_Invoices__c + '' + accountingScheme.Accounting_Type__c + '' + Integer.valueOf(item.Reference_year__c) + '' + String.valueOf(item.VAT_rate__c).rightPad(18, '0');
                WrapperAccounting wAccounting;
                if(accountingInvoiceMap.containsKey(key)){
                    wAccounting = accountingInvoiceMap.get(key);
                }
                else {
                    wAccounting = new WrapperAccounting();
                    wAccounting.accountingScheme = accountingScheme;
                    wAccounting.accountingClosing = accountingClosing;
                    wAccounting.creditedCompanyId = item.Credited_Company__c;
                    wAccounting.debitedCompanyId = item.Debited_Company__c;
                    wAccounting.NegoDiscountTypes = accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : null;
                    wAccounting.NegoDiscountType = accountingScheme.Included_Discount_Type__c != null ? accountingScheme.Included_Discount_Type__c : null;
                    wAccounting.invNegoYear = item.Reference_year__c;
                    wAccounting.includeFreeInvoices = accountingScheme.Include_Free_Invoices__c;
                    wAccounting.accountingType = accountingScheme.Accounting_Type__c;
                    wAccounting.invVATPercent = item.VAT_rate__c;
                    wAccounting.businessUnitId = accountingScheme.Business_Unit__c;
                    wAccounting.businessUnitName = accountingScheme.Business_Unit__r.Name;
                    wAccounting.creditedCompanyName = accountingScheme.Credited_Company__r.Name;
                    wAccounting.debitedCompanyName = accountingScheme.Debited_Company__r.Name;                    
                    accountingInvoiceMap.put(key, wAccounting);
                }
                if(item.Amount_Type__c == 'HT'){
                    wAccounting.isLinkedToHT = true;
                    wAccounting.existHT = true;
                    wAccounting.invAmountWoVAT = item.Amount_signed__c;
                }
                if(item.Amount_Type__c == 'TVA'){
                    wAccounting.isLinkedToTVA = true;
                    wAccounting.existTVA = true;
                    wAccounting.invAmountVAT = item.Amount_signed__c;
                }
                if(item.Amount_Type__c == 'TTC'){
                    wAccounting.isLinkedToTTC = true;
                    wAccounting.existTTC = true;
                    wAccounting.invAmountWVAT = item.Amount_signed__c;
                }
                wAccounting.invoiceAccountingEntryMap.put(key + '' + item.Amount_Type__c, item);
                wAccounting.invoiceAccountingEntries.add(item);
            }
        }
                
        /* Prepare Accounting for Invoices */
        for (Invoice_Detail__c item : scope) {
            Id creditedCompanyId = item.Invoice__r.Inv_Business_Unit__r.Legal_Form__c;
            if(item.Invoice__r.Inv_PrintedDate__c > accountingClosing.Closing_Date__c) {
                continue;
            }
            String negoDiscountType = item.Invoice_detail_nego_disc_type__c;
            String accountingAccountType = item.Inv_Detail_Condition__r.Accounting_Account_Type__c != null ? item.Inv_Detail_Condition__r.Accounting_Account_Type__c : 'Product';
            Decimal invNegoYear = item.Invoice__r.Inv_Nego_year__c;
            Decimal invVATPercent = item.Inv_VAT_Percent__c != null ? item.Inv_VAT_Percent__c : 0;
            Decimal invAmountWoVAT = item.Invoice_Value__c != null ? item.Invoice_Value__c : 0;
            Decimal invAmountVAT = item.Inv_VAT_Value__c != null ? item.Inv_VAT_Value__c : 0;
            Decimal invAmountWVAT = item.Invoice_Detail_Value_w_VAT__c != null ? item.Invoice_Detail_Value_w_VAT__c : 0;
            List<Accounting_Scheme__c> accountingSchemeList = creditedCompanyForInvoiceMap.get(creditedCompanyId);
            if(accountingSchemeList != null && !accountingSchemeList.isEmpty()) {
                for(Accounting_Scheme__c accountingScheme : accountingSchemeList) {
                    Boolean existHT = false, existTVA = false, existTTC = false, invoiceDetailLinkedToHT = false, invoiceDetailLinkedToTVA = false, invoiceDetailLinkedToTTC = false;
                    Id debitedCompanyId = accountingScheme.Debited_Company__c;
                    // Check free invoices
                    Boolean includeFreeInvoices = accountingScheme.Include_Free_Invoices__c;
                    String key;
                    if((negoDiscountType != null && ((accountingScheme.Included_Discount_Types__c != null && accountingScheme.Included_Discount_Types__c.Contains(negoDiscountType)) || accountingScheme.Included_Discount_Type__c == negoDiscountType)) ||
                       (includeFreeInvoices == true && negoDiscountType == null)){
                           key = creditedCompanyId + '' + debitedCompanyId + '' +
                               (accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : '' ) + '' +
                               (accountingScheme.Included_Discount_Type__c != null ? '-' + accountingScheme.Included_Discount_Type__c : '' ) + '' +                           
                               includeFreeInvoices + '' + accountingAccountType + '' + Integer.valueOf(invNegoYear) + '' + String.valueOf(invVATPercent).rightPad(18, '0');
                       }
                    if(String.isNotBlank(key)) {
                        // check if invoice line assign to accounting HT, TVA or TTC
                        String invoicekey = creditedCompanyId + '' + debitedCompanyId + '' + 
                            (accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : '' ) + '' +
                            (accountingScheme.Included_Discount_Type__c != null ? '-' + accountingScheme.Included_Discount_Type__c : '' ) + '' +
                            includeFreeInvoices + '' + accountingAccountType;
                        if(accountingSchemeForInvoiceMap.containsKey(invoicekey)){
                            List<Accounting_Scheme__c> accountingSchemesForInvoice = accountingSchemeForInvoiceMap.get(invoicekey);
                            for(Accounting_Scheme__c scheme : accountingSchemesForInvoice){
                                if(scheme.Amount_Type__c == 'HT'){
                                    existHT = true;
                                    if(invoiceDetailAssignToAccountingEntrySet.contains(item.Id + '' + scheme.Amount_Type__c)){
                                        invoiceDetailLinkedToHT = true;
                                    }
                                    else{
                                        invoiceDetailAssignToAccountingEntrySet.add(item.Id + '' + scheme.Amount_Type__c);
                                    }
                                }
                                if(scheme.Amount_Type__c == 'TVA'){
                                    existTVA = true;
                                    if(invoiceDetailAssignToAccountingEntrySet.contains(item.Id + '' + scheme.Amount_Type__c)){
                                        invoiceDetailLinkedToTVA = true;
                                    }
                                    else{
                                        invoiceDetailAssignToAccountingEntrySet.add(item.Id + '' + scheme.Amount_Type__c);
                                    }
                                }
                                if(scheme.Amount_Type__c == 'TTC'){
                                    existTTC = true;
                                    if(invoiceDetailAssignToAccountingEntrySet.contains(item.Id + '' + scheme.Amount_Type__c)){
                                        invoiceDetailLinkedToTTC = true;
                                    }
                                    else{
                                        invoiceDetailAssignToAccountingEntrySet.add(item.Id + '' + scheme.Amount_Type__c);
                                    }
                                }
                            }
                        }
                        if((existHT && !invoiceDetailLinkedToHT) || (existTVA && !invoiceDetailLinkedToTVA) || (existTTC && !invoiceDetailLinkedToTTC)){
                            WrapperAccounting wAccounting;
                            if(accountingInvoiceMap.containsKey(key)){
                                wAccounting = accountingInvoiceMap.get(key);
                                wAccounting.invoiceDetails.add(item);
                            } else {
                                wAccounting = new WrapperAccounting();
                                wAccounting.accountingScheme = accountingScheme;
                                wAccounting.accountingClosing = accountingClosing;
                                wAccounting.creditedCompanyId = creditedCompanyId;
                                wAccounting.debitedCompanyId = debitedCompanyId;
                                wAccounting.NegoDiscountTypes = accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : null;
                                wAccounting.NegoDiscountType = accountingScheme.Included_Discount_Type__c != null ? accountingScheme.Included_Discount_Type__c : null;
                                wAccounting.invNegoYear = invNegoYear;
                                wAccounting.includeFreeInvoices = includeFreeInvoices;
                                wAccounting.accountingType = accountingAccountType;
                                wAccounting.invVATPercent = invVATPercent;                            
                                wAccounting.businessUnitId = accountingScheme.Business_Unit__c;
                                wAccounting.businessUnitName = accountingScheme.Business_Unit__r.Name;
                                wAccounting.creditedCompanyName = accountingScheme.Credited_Company__r.Name;
                                wAccounting.debitedCompanyName = accountingScheme.Debited_Company__r.Name;                            
                                wAccounting.invoiceDetails.add(item);
                                accountingInvoiceMap.put(key, wAccounting);
                            }
                            // calculate amount
                            if(existHT && !invoiceDetailLinkedToHT){
                                wAccounting.invAmountWoVAT += invAmountWoVAT;
                            }
                            if(existTVA && !invoiceDetailLinkedToTVA){
                                wAccounting.invAmountVAT += invAmountVAT;                              
                            }
                            if(existTTC && !invoiceDetailLinkedToTTC){
                                wAccounting.invAmountWVAT += invAmountWVAT;                             
                            }
                            if(!wAccounting.isLinkedToHT){
                                wAccounting.isLinkedToHT = existHT && !invoiceDetailLinkedToHT;
                            }
                            if(!wAccounting.isLinkedToTVA){
                                wAccounting.isLinkedToTVA = existTVA && !invoiceDetailLinkedToTVA;
                            }
                            if(!wAccounting.isLinkedToTTC){
                                wAccounting.isLinkedToTTC = existTTC && !invoiceDetailLinkedToTTC;
                            }
                            // Assign invoice detail to HT, TVA, TTC
                            if(existHT && !invoiceDetailLinkedToHT){
                                if(wAccounting.ammountTypeForInvoiceMap.containsKey(item.Id)){
                                    wAccounting.ammountTypeForInvoiceMap.get(item.Id).add('HT');
                                }
                                else{
                                    wAccounting.ammountTypeForInvoiceMap.put(item.Id, new Set<String>{'HT'});
                                }
                            }
                            if(existTVA && !invoiceDetailLinkedToTVA){
                                if(wAccounting.ammountTypeForInvoiceMap.containsKey(item.Id)){
                                    wAccounting.ammountTypeForInvoiceMap.get(item.Id).add('TVA');
                                }
                                else{
                                    wAccounting.ammountTypeForInvoiceMap.put(item.Id, new Set<String>{'TVA'});
                                }
                            }
                            if(existTTC && !invoiceDetailLinkedToTTC){
                                if(wAccounting.ammountTypeForInvoiceMap.containsKey(item.Id)){
                                    wAccounting.ammountTypeForInvoiceMap.get(item.Id).add('TTC');
                                }
                                else{
                                    wAccounting.ammountTypeForInvoiceMap.put(item.Id, new Set<String>{'TTC'});
                                }
                            }
                        }
                    }
                }
            }
        }
        if(accountingInvoiceMap != null && !accountingInvoiceMap.isEmpty()) {
            for (WrapperAccounting item : accountingInvoiceMap.values()) {
                if(item.isLinkedToHT){
                    if(!item.existHT) {
                        item.insertAccountingEntryForInvoice('HT', item.invAmountWoVAT, amountTypeForInvoiceMap);
                    }
                    else {
                        item.updateAccountingEntryForInvoice('HT', item.invAmountWoVAT);
                    }
                }
                if(item.isLinkedToTVA){
                    if(!item.existTVA) {
                        item.insertAccountingEntryForInvoice('TVA', item.invAmountVAT, amountTypeForInvoiceMap);
                    }
                    else {
                        item.updateAccountingEntryForInvoice('TVA', item.invAmountVAT);
                    }
                }
                if(item.isLinkedToTTC){
                    if(!item.existTTC) {
                        item.insertAccountingEntryForInvoice('TTC', item.invAmountWVAT, amountTypeForInvoiceMap);
                    }
                    else {
                        item.updateAccountingEntryForInvoice('TTC', item.invAmountWVAT);
                    }
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on insert accounting entry fields
            String[] accountingEntryInsertFields = new String[] { NegoptimHelper.normalizeAPIName('Entry_Type__c'),
                NegoptimHelper.normalizeAPIName('Accounting_Closing__c'), NegoptimHelper.normalizeAPIName('Accounting_Scheme_Line__c'),
                NegoptimHelper.normalizeAPIName('Credited_Company__c'), NegoptimHelper.normalizeAPIName('Debited_Company__c'),
                NegoptimHelper.normalizeAPIName('Entry_Label__c'), NegoptimHelper.normalizeAPIName('Comment__c'),
                NegoptimHelper.normalizeAPIName('VAT_rate__c'), NegoptimHelper.normalizeAPIName('Amount__c'),
                NegoptimHelper.normalizeAPIName('Amount_signed__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Reference_year__c')};
            
            // check security on update accounting entry fields
            String[] accountingEntryUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Amount__c'), NegoptimHelper.normalizeAPIName('Amount_signed__c')};
                
            // check security on update invoice line fields
            String[] invoiceDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Accounting_entry_woVAT__c'),
                NegoptimHelper.normalizeAPIName('Accounting_entry_VAT__c'), NegoptimHelper.normalizeAPIName('Accounting_entry_wVAT__c')};
           
            if(accountingInvoiceMap != null && !accountingInvoiceMap.isEmpty()) {
                for (WrapperAccounting item : accountingInvoiceMap.values()) {
                    accountingEntryList.addAll(item.invoiceAccountingEntries);
                    if(String.isNotBlank(item.errorMessage)) {
                        nb.logError(item.errorMessage);
                    }
                }
            }
            
            if(NegoptimHelper.checkCreatibility(Accounting_Entry__c.SObjectType, accountingEntryInsertFields) &&
               NegoptimHelper.checkUpdatibility(Accounting_Entry__c.SObjectType, accountingEntryUpdateFields) &&
               NegoptimHelper.checkUpdatibility(Invoice_Detail__c.SObjectType, invoiceDetailFields))
            {
                // Insert Accounting Entry.
                if(accountingEntryList != null && accountingEntryList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(accountingEntryList, false);
                    nb.logResults(results, accountingEntryList);
                    
                    Map<Id, Accounting_Entry__c> accountingEntryMap = new Map<Id, Accounting_Entry__c>([SELECT Id, Name, Ext_id__c, Amount_Type__c, Flag_D_or_C__c, Accounting_Entry_for__c 
                                                                                                        FROM Accounting_Entry__c WHERE Id IN :accountingEntryList]);
                    // Update Invoice Details.
                    if(accountingEntryMap != null && accountingEntryMap.size() > 0){
                        for (WrapperAccounting item : accountingInvoiceMap.values()) {
                            for(Invoice_Detail__c invoiceDetail : item.invoiceDetails){
                                if(invoiceDetailMap.containsKey(invoiceDetail.Id)){
                                    invoiceDetail = invoiceDetailMap.get(invoiceDetail.Id);
                                }else{
                                    invoiceDetailMap.put(invoiceDetail.Id, invoiceDetail);
                                }
                                // check invoice detail linked to HT,TVA,TTC
                                Set<String> amountTypeSet;
                                if(item.ammountTypeForInvoiceMap.containsKey(invoiceDetail.Id)){
                                    amountTypeSet = item.ammountTypeForInvoiceMap.get(invoiceDetail.Id);
                                }
                                if(amountTypeSet == null) continue;
                                for(Accounting_Entry__c accountingEntry : item.invoiceAccountingEntries){
                                    if(accountingEntry.Id != null && accountingEntryMap.get(accountingEntry.Id) != null){
                                        accountingEntry = accountingEntryMap.get(accountingEntry.Id);
                                        if(accountingEntry.Amount_Type__c == 'HT' && amountTypeSet.contains(accountingEntry.Amount_Type__c) && invoiceDetail.Accounting_entry_woVAT__c == null){
                                            invoiceDetail.Accounting_entry_woVAT__c = accountingEntry.Id;
                                        }
                                        if(accountingEntry.Amount_Type__c == 'TVA' && amountTypeSet.contains(accountingEntry.Amount_Type__c) && invoiceDetail.Accounting_entry_VAT__c == null){
                                            invoiceDetail.Accounting_entry_VAT__c = accountingEntry.Id;
                                        }
                                        if(accountingEntry.Amount_Type__c ==  'TTC' && amountTypeSet.contains(accountingEntry.Amount_Type__c) && invoiceDetail.Accounting_entry_wVAT__c == null){
                                            invoiceDetail.Accounting_entry_wVAT__c = accountingEntry.Id;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if(invoiceDetailMap != null && invoiceDetailMap.size() > 0) {
                    List<Database.SaveResult> results = Database.update(invoiceDetailMap.values(), false);
                    nb.logResults(results, invoiceDetailMap.values());
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
        
        Map<String, Accounting_Entry__c> invoiceAccountingEntryMap {get; set;}
        List<Accounting_Entry__c> invoiceAccountingEntries {get; set;}
        List<Invoice_Detail__c> invoiceDetails {get; set;}
        Map<Id, Set<String>> ammountTypeForInvoiceMap {get; set;}
                
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
        // Accounting invoices parameters
        Decimal invVATPercent {get; set;}
        Decimal invAmountWoVAT {get; set;}
        Decimal invAmountVAT {get; set;}
        Decimal invAmountWVAT {get; set;}
        Boolean isLinkedToHT {get; set;}
        Boolean isLinkedToTVA {get; set;}
        Boolean isLinkedToTTC {get; set;}
        Boolean existHT {get; set;}
        Boolean existTVA {get; set;}
        Boolean existTTC {get; set;}
        
        // constructor
        public WrapperAccounting() {
            invoiceAccountingEntryMap = new Map<String, Accounting_Entry__c>();
            invoiceAccountingEntries = new List<Accounting_Entry__c>();
            invoiceDetails = new List<Invoice_Detail__c>();
            ammountTypeForInvoiceMap = new Map<Id, Set<String>>();
            isLinkedToHT = false;
            isLinkedToTVA = false;
            isLinkedToTTC = false;
            existHT = false;
            existTVA = false;
            existTTC = false;
            
            invAmountWoVAT = 0;
            invAmountVAT = 0;
            invAmountWVAT = 0;
            errorMessage ='';
        }
        
        // create accounting entry for invoices
        public void insertAccountingEntryForInvoice(String amountType, Decimal amount, Map<String, Accounting_Scheme__c> amountTypeMap){
            String key = this.creditedCompanyId + '' + this.debitedCompanyId + '' +
                (this.NegoDiscountTypes != null ? this.NegoDiscountTypes : '') + '' +
                (this.NegoDiscountType != null ? '-' + this.NegoDiscountType : '') + '' +
                this.includeFreeInvoices + '' + this.accountingType + '' + amountType;
            Accounting_Scheme__c accountingSchemeForInvoice;
            if(amountTypeMap.containsKey(key)){
                accountingSchemeForInvoice = amountTypeMap.get(key);
            }
            if(accountingSchemeForInvoice == null){
                this.errorMessage += string.format('Accounting scheme based on the business unit {0}, credited company {1}, debited company {2}, NegoDiscountTypes {3}, accounting type {4} and amount type {5} not exist.', 
                                                   new String[]{ this.businessUnitName, this.creditedCompanyName, this.debitedCompanyName, 
                                                       (this.NegoDiscountTypes != null ? this.NegoDiscountTypes : '') + (this.NegoDiscountType != null ?  ' - ' + this.NegoDiscountType : ''),
                                                       this.accountingType, amountType }) + '\n';
                return;
            }
            Accounting_Entry__c accountingEntry = new Accounting_Entry__c(Entry_Type__c = 'Invoice',
                                                                          Accounting_Closing__c = accountingClosing.Id,
                                                                          Accounting_Scheme_Line__c = accountingSchemeForInvoice != null ? accountingSchemeForInvoice.Id : null,
                                                                          Credited_Company__c = this.creditedCompanyId,
                                                                          Debited_Company__c = this.debitedCompanyId,
                                                                          Entry_Label__c = 'JV ' + formatDate(accountingClosing.Closing_Date__c, 'MM/yy') + ' / Campagne ' + Integer.valueOf(this.invNegoYear),
                                                                          Comment__c = Integer.valueOf(this.invNegoYear) + amountType,
                                                                          VAT_rate__c = this.invVATPercent,
                                                                          Amount__c = amount.abs(),
                                                                          Amount_signed__c = amount,
                                                                          Status__c = accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract',
                                                                          Reference_year__c = Integer.valueOf(this.invNegoYear));
            invoiceAccountingEntries.add(accountingEntry);
        }
        
        // update existing accounting entry
        public void updateAccountingEntryForInvoice(String amountType, Decimal amount){
            String key = this.creditedCompanyId + '' + this.debitedCompanyId + '' +
                (this.NegoDiscountTypes != null ? this.NegoDiscountTypes : '') + '' +
                (this.NegoDiscountType != null ? '-' + this.NegoDiscountType : '') + '' +
                this.includeFreeInvoices + '' + this.accountingType + '' + Integer.valueOf(this.invNegoYear) + '' + String.valueOf(this.invVATPercent).rightPad(18, '0');
            Accounting_Entry__c accountingEntry = invoiceAccountingEntryMap.get(key + '' + amountType);
            accountingEntry.Amount__c = amount.abs();
            accountingEntry.Amount_signed__c = amount;
        }
        
        String formatDate(Date input, String format){
            return DateTime.newInstance( input.year(), input.month(), input.day()).format(format);
        }
    }
}