/*
 * Prepare accounting balance that will be called during monthly during closure.				
 * Based on the accouting schema, it will generate the accouting journal, keep the relation with invoices, payment & redistrib data and organize the synchro to accounting system.				
 */ 
public with sharing class AccountingClosingRedistributionBatch implements Database.Batchable<sObject>, Database.stateful {

    private NegoptimBatch nb;
    public String query;
    public final Accounting_Closing__c accountingClosing;
    public final List<Accounting_Scheme__c> accountingSchemes;
    
    // Constructor.
    public AccountingClosingRedistributionBatch(String startedFrom, Accounting_Closing__c accountingClosing, List<Accounting_Scheme__c> accountingSchemes) {
        this.nb = new NegoptimBatch('Accounting Closing Redistribution', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.accountingClosing = accountingClosing;
        this.accountingSchemes = accountingSchemes;
        
        Set<Id> debitedCompanySet = new Set<Id>();
        List<String> negoDiscTypeForRedistributionSet = new List<String>();
        Set<String> storeTypeSet = new Set<String>();
        Set<Boolean> managedBUSet = new Set<Boolean>();
        
        if(accountingSchemes != null && !accountingSchemes.isEmpty()) {
            for(Accounting_Scheme__c item : accountingSchemes){
                // Manage Redistribution accounting
                if(item.RecordType.DeveloperName == 'Redistribution' && item.Debited_Company__c != null && item.Included_Discount_Types__c != null &&
                   item.Accounting_Entry_for__c != null && item.Store_Type__c != null && item.Managed_BU__c != null && item.Accounting_Type__c != null && item.Amount_Type__c != null && item.Flag_D_or_C__c != null)
                {
                    // Get debited company list
                    if(item.Debited_Company__c != null){
                        debitedCompanySet.add(item.Debited_Company__c);
                    }
                    // Get all nego discount type
                    if(item.Included_Discount_Types__c != null){
                        negoDiscTypeForRedistributionSet.add(item.Included_Discount_Types__c);
                    }
                    // Fill store type list
                    if(item.Store_Type__c != null){
                        storeTypeSet.add(item.Store_Type__c);
                    }
                    // Fill managed BU list
                    if(item.Managed_BU__c != null){
                        managedBUSet.add(item.Managed_BU__c);
                    }
                }
            }
        }
        String q = 'SELECT Store__r.Legal_Form__c, Redistrib_head__r.Master_BU__r.Legal_Form__c,';
        q += ' Redistrib_head__r.Nego_Discount_Type__c, Redistrib_head__r.Year__c,';
        q += ' Redistrib_amnt_HT__c, Redistributed_amount_TTC__c, Store__r.Management_Type__c, Store__r.Managed_BU__c,';
        q += ' Accounting_entry_credit_woVAT__c, Accounting_entry_credit_VAT__c, Accounting_entry_credit_wVAT__c, Accounting_entry_credit_woVAT_D__c,';
        q += ' Accounting_entry_debit_woVAT__c, Accounting_entry_debit_VAT__c, Accounting_entry_debit_wVAT__c, Accounting_entry_debit_woVAT_D__c,';
        q += ' Accounting_entry_woVAT__c, Accounting_entry_VAT__c, Accounting_entry_wVAT__c, Accounting_entry_woVAT_D__c';
        q += ' FROM Redistrib_detail__c';
        q += ' WHERE Redistrib_head__r.Master_BU__r.Legal_Form__c IN (\'' + String.join(new List<Id>(debitedCompanySet), '\',\'') +'\')';
        q += ' AND Redistrib_head__r.Nego_Discount_Type__c IN (\'' + String.join(negoDiscTypeForRedistributionSet, '\',\'') +'\')';
        q += ' AND Store__r.Management_Type__c IN (\'' + String.join(new List<String>(storeTypeSet), '\',\'') +'\')';        
        if(!managedBUSet.isEmpty()) {
            q += ' AND Store__r.Managed_BU__c IN (' + String.join(new List<Boolean>(managedBUSet), ',') +')';
        }
        q += ' AND Redistrib_head__r.Year__c <> NULL AND Store__r.Legal_Form__c <> NULL';
        q += ' AND Accounting_entry_credit_woVAT__c = NULL AND Accounting_entry_credit_VAT__c = NULL';
        q += ' AND Accounting_entry_credit_wVAT__c = NULL AND Accounting_entry_credit_woVAT_D__c = NULL';
        q += ' AND Accounting_entry_debit_woVAT__c = NULL AND Accounting_entry_debit_VAT__c = NULL';
        q += ' AND Accounting_entry_debit_wVAT__c = NULL AND Accounting_entry_debit_woVAT_D__c = NULL';
        q += ' AND Accounting_entry_woVAT__c = NULL AND Accounting_entry_VAT__c = NULL';
        q += ' AND Accounting_entry_wVAT__c = NULL AND Accounting_entry_woVAT_D__c = NULL';
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
    public void execute(Database.BatchableContext BC, List<Redistrib_detail__c> scope) {
        // Fill list of accounting scheme for redistributions
        Map<String, List<Accounting_Scheme__c>> accountingSchemeForRedistributionMap = new Map<String, List<Accounting_Scheme__c>>();
        Map<Id, List<Accounting_Scheme__c>> debitedCompanyForRedistributionMap = new Map<Id, List<Accounting_Scheme__c>>();
        Map<String, Accounting_Scheme__c> amountTypeForRedistributionMap = new Map<String, Accounting_Scheme__c>();
        Set<String> redistributionDetailAssignToAccountingEntrySet = new Set<String>();
        Set<String> storeTypeSet = new Set<String>();
        Set<Boolean> managedBUSet = new Set<Boolean>();
        Set<Integer> redistributionYearSet = new Set<Integer>();
        
        Map<String, WrapperAccounting> accountingRedistributionMap = new Map<String, WrapperAccounting>();
        List<Accounting_Entry__c> accountingEntryList = new List<Accounting_Entry__c>();        
        Map<Id, Redistrib_detail__c> redistributionDetailMap = new Map<Id, Redistrib_detail__c>();
        
        Map<Id, Accounting_Scheme__c> accountingSchemeMap = new Map<Id, Accounting_Scheme__c>(accountingSchemes);
        
        for(Accounting_Scheme__c item : accountingSchemes) {
            // Manage Redistribution accounting
            if(item.RecordType.DeveloperName == 'Redistribution' && item.Debited_Company__c != null && item.Included_Discount_Types__c != null &&
               item.Accounting_Entry_for__c != null && item.Store_Type__c != null && item.Managed_BU__c != null && item.Accounting_Type__c != null && item.Amount_Type__c != null && item.Flag_D_or_C__c != null)
            {
                String key = item.Debited_Company__c + '' + item.Included_Discount_Types__c + '' + item.Accounting_Entry_for__c + '' +
                    item.Store_Type__c + '' + item.Managed_BU__c + '' + item.Accounting_Type__c + '' + item.Flag_D_or_C__c;
                String keyAmount = key + item.Amount_Type__c;
                // Map distinct debited company, discount types, accounting entry for, store type, managed bu, accounting type, Flag_D_C
                if(!accountingSchemeForRedistributionMap.containsKey(key)){
                    if(debitedCompanyForRedistributionMap.containsKey(item.Debited_Company__c)){
                        debitedCompanyForRedistributionMap.get(item.Debited_Company__c).add(item);
                    }
                    else{
                        debitedCompanyForRedistributionMap.put(item.Debited_Company__c, new List<Accounting_Scheme__c>{item});
                    }
                }
                // Fill Map amount type
                if(!amountTypeForRedistributionMap.containsKey(keyAmount)){
                    amountTypeForRedistributionMap.put(keyAmount, item);
                    // Fill Map accounting scheme for Redistributions
                    if(accountingSchemeForRedistributionMap.containsKey(key)){
                        accountingSchemeForRedistributionMap.get(key).add(item);
                    }
                    else{
                        accountingSchemeForRedistributionMap.put(key, new List<Accounting_Scheme__c>{item});
                    }
                }
            }
        }
        
        // Get accounting entry list already created for same closing
        List<Accounting_Entry__c> oldAccountingEntryList = [SELECT Id, Name, Accounting_Closing__c, Accounting_Scheme_Line__c, Credited_Company__c, Debited_Company__c,
                                                            Entry_Label__c, Comment__c, VAT_rate__c, Amount__c, Amount_signed__c, Status__c, Reference_year__c,
                                                            Amount_Type__c, Flag_D_or_C__c
                                                            FROM Accounting_Entry__c
                                                            WHERE Accounting_Closing__c = :this.accountingClosing.Id AND Accounting_Scheme_Line__c IN :this.accountingSchemes
                                                            AND Accounting_Scheme_Line__r.RecordType.DeveloperName = 'Redistribution'];
        if(oldAccountingEntryList != null && oldAccountingEntryList.size() > 0) {
            for (Redistrib_detail__c item : scope) {
                // Fill store type list
                if(item.Store__r.Management_Type__c != null){
                    storeTypeSet.add(item.Store__r.Management_Type__c);
                }
                // Fill managed BU list
                if(item.Store__r.Managed_BU__c != null){
                    managedBUSet.add(item.Store__r.Managed_BU__c);
                }
                // Fill year list
                if(item.Redistrib_head__r.Year__c != null){
                    redistributionYearSet.add(Integer.valueOf(item.Redistrib_head__r.Year__c));
                }
            }
            List<Redistrib_detail__c> oldRedistributionDetails = [SELECT Store__r.Legal_Form__c, Redistrib_head__r.Master_BU__r.Legal_Form__c,
                                                                  Redistrib_head__r.Nego_Discount_Type__c, Redistrib_head__r.Year__c,
                                                                  Redistrib_amnt_HT__c, Redistributed_amount_TTC__c, Store__r.Management_Type__c, Store__r.Managed_BU__c,
                                                                  Accounting_entry_credit_woVAT__c, Accounting_entry_credit_VAT__c, Accounting_entry_credit_wVAT__c, Accounting_entry_credit_woVAT_D__c,
                                                                  Accounting_entry_debit_woVAT__c, Accounting_entry_debit_VAT__c, Accounting_entry_debit_wVAT__c, Accounting_entry_debit_woVAT_D__c,
                                                                  Accounting_entry_woVAT__c, Accounting_entry_VAT__c, Accounting_entry_wVAT__c, Accounting_entry_woVAT_D__c
                                                                  FROM Redistrib_detail__c
                                                                  WHERE Store__r.Management_Type__c IN :storeTypeSet
                                                                  AND Store__r.Managed_BU__c IN :managedBUSet
                                                                  AND Redistrib_head__r.Year__c IN :redistributionYearSet
                                                                  AND (Accounting_entry_credit_woVAT__c IN :oldAccountingEntryList OR Accounting_entry_credit_VAT__c IN :oldAccountingEntryList
                                                                       OR Accounting_entry_credit_wVAT__c IN :oldAccountingEntryList OR Accounting_entry_credit_woVAT_D__c IN :oldAccountingEntryList
                                                                       OR Accounting_entry_debit_woVAT__c IN :oldAccountingEntryList OR Accounting_entry_debit_VAT__c IN :oldAccountingEntryList
                                                                       OR Accounting_entry_debit_wVAT__c IN :oldAccountingEntryList OR Accounting_entry_debit_woVAT_D__c IN :oldAccountingEntryList
                                                                       OR Accounting_entry_woVAT__c IN :oldAccountingEntryList OR Accounting_entry_VAT__c IN :oldAccountingEntryList
                                                                       OR Accounting_entry_wVAT__c IN :oldAccountingEntryList OR Accounting_entry_woVAT_D__c IN :oldAccountingEntryList)];
            Map<Id, Redistrib_detail__c> oldAccountingEntryMap = new Map<Id, Redistrib_detail__c>();
            if(!oldRedistributionDetails.isEmpty()) {
                for (Redistrib_detail__c item : oldRedistributionDetails) {
                    if(item.Accounting_entry_credit_woVAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_credit_woVAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_credit_woVAT__c, item);
                    }
                    if(item.Accounting_entry_credit_VAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_credit_VAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_credit_VAT__c, item);
                    }
                    if(item.Accounting_entry_credit_wVAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_credit_wVAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_credit_wVAT__c, item);
                    }
                    if(item.Accounting_entry_credit_woVAT_D__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_credit_woVAT_D__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_credit_woVAT_D__c, item);
                    }
                    if(item.Accounting_entry_debit_woVAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_debit_woVAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_debit_woVAT__c, item);
                    }
                    if(item.Accounting_entry_debit_VAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_debit_VAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_debit_VAT__c, item);
                    }
                    if(item.Accounting_entry_debit_wVAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_debit_wVAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_debit_wVAT__c, item);
                    }
                    if(item.Accounting_entry_debit_woVAT_D__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_debit_woVAT_D__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_debit_woVAT_D__c, item);
                    }
                    if(item.Accounting_entry_woVAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_woVAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_woVAT__c, item);
                    }
                    if(item.Accounting_entry_VAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_VAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_VAT__c, item);
                    }
                    if(item.Accounting_entry_wVAT__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_wVAT__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_wVAT__c, item);
                    }
                    if(item.Accounting_entry_woVAT_D__c != null && !oldAccountingEntryMap.containsKey(item.Accounting_entry_woVAT_D__c)) {
                        oldAccountingEntryMap.put(item.Accounting_entry_woVAT_D__c, item);
                    }
                }
                for(Accounting_Entry__c item : oldAccountingEntryList) {
                    Redistrib_detail__c redistributionDetail = oldAccountingEntryMap.get(item.Id);
                    if(redistributionDetail == null) continue;
                    Decimal redistributionYear = redistributionDetail.Redistrib_head__r.Year__c;
                    
                    Accounting_Scheme__c accountingScheme = accountingSchemeMap.get(item.Accounting_Scheme_Line__c);
                    String accountingEntryFor = accountingScheme.Accounting_Entry_for__c;
                    String accountingType = accountingScheme.Accounting_Type__c;
                    String flagDC = accountingScheme.Flag_D_or_C__c;
                    String storeType = accountingScheme.Store_Type__c;
                    Boolean managedBU = accountingScheme.Managed_BU__c;
                    
                    String key = item.Debited_Company__c + '' +
                        (accountingScheme.Included_Discount_Types__c != null ? accountingScheme.Included_Discount_Types__c : '' ) + '' +
                        accountingEntryFor + '' + storeType + '' + managedBU + '' + accountingType + '' +
                        flagDC + '' + item.Credited_Company__c + '' + Integer.valueOf(redistributionYear);
                    
                    WrapperAccounting wAccounting;
                    if(accountingRedistributionMap.containsKey(key)) {
                        wAccounting = accountingRedistributionMap.get(key);
                    }
                    else {
                        wAccounting = new WrapperAccounting();
                        wAccounting.accountingScheme = accountingScheme;
                        wAccounting.accountingClosing = accountingClosing;
                        wAccounting.creditedCompanyId = item.Credited_Company__c;
                        wAccounting.debitedCompanyId = item.Debited_Company__c;
                        wAccounting.NegoDiscountTypes = accountingScheme.Included_Discount_Types__c;
                        wAccounting.redistributionYear = redistributionYear;      
                        wAccounting.storeType = storeType;
                        wAccounting.managedBU = managedBU;
                        wAccounting.accountingType = accountingScheme.Accounting_Type__c;
                        wAccounting.accountingEntryFor = accountingScheme.Accounting_Entry_for__c;
                        wAccounting.flagDC = accountingScheme.Flag_D_or_C__c;
                        wAccounting.businessUnitId = accountingScheme.Business_Unit__c;
                        wAccounting.businessUnitName = accountingScheme.Business_Unit__r.Name;
                        wAccounting.creditedCompanyName = accountingScheme.Credited_Company__r.Name;
                        wAccounting.debitedCompanyName = accountingScheme.Debited_Company__r.Name;
                        accountingRedistributionMap.put(key, wAccounting);
                    }
                    if(item.Amount_Type__c == 'HT') {
                        wAccounting.amountHT = item.Amount_signed__c;
                        if(accountingEntryFor == 'Credited' && flagDC == 'Credit'){
                            wAccounting.existHTCreditedFlagC = true;
                            wAccounting.isLinkedToHTCreditedFlagC = true;
                        }
                        if(accountingEntryFor == 'Credited' && flagDC == 'Debit'){
                            wAccounting.existHTCreditedFlagD = true;
                            wAccounting.isLinkedToHTCreditedFlagD = true;
                        }
                        if(accountingEntryFor == 'Debited' && flagDC == 'Credit'){
                            wAccounting.existHTDebitedFlagC = true;
                            wAccounting.isLinkedToHTDebitedFlagC = true;
                        }
                        if(accountingEntryFor == 'Debited' && flagDC == 'Debit'){
                            wAccounting.existHTDebitedFlagD = true;
                            wAccounting.isLinkedToHTDebitedFlagD = true;
                        }
                        if(accountingEntryFor == 'Debited=Credited' && flagDC == 'Credit'){
                            wAccounting.existHTDCFlagC = true;
                            wAccounting.isLinkedToHTDCFlagC = true;
                        }
                        if(accountingEntryFor == 'Debited=Credited' && flagDC == 'Debit'){
                            wAccounting.existHTDCFlagD = true;
                            wAccounting.isLinkedToHTDCFlagD = true;
                        }
                    }
                    if(item.Amount_Type__c == 'TVA') {
                        wAccounting.amountTVA = item.Amount_signed__c;
                        if(accountingEntryFor == 'Credited'){
                            wAccounting.existTVACredited = true;
                            wAccounting.isLinkedToTVACredited = true;
                        }
                        if(accountingEntryFor == 'Debited'){
                            wAccounting.existTVADebited = true;
                            wAccounting.isLinkedToTVADebited = true;
                        }
                        if(accountingEntryFor == 'Debited=Credited'){
                            wAccounting.existTVADC = true;
                            wAccounting.isLinkedToTVADC = true;
                        }
                    }
                    if(item.Amount_Type__c == 'TTC') {
                        wAccounting.amountTTC = item.Amount_signed__c;
                        if(accountingEntryFor == 'Credited'){
                            wAccounting.existTTCCredited = true;
                            wAccounting.isLinkedToTTCCredited = true;
                        }
                        if(accountingEntryFor == 'Debited'){
                            wAccounting.existTTCDebited = true;
                            wAccounting.isLinkedToTTCDebited = true;
                        }
                        if(accountingEntryFor == 'Debited=Credited'){
                            wAccounting.existTTCDC = true;
                            wAccounting.isLinkedToTTCDC = true;
                        }
                    }
                    wAccounting.redistributionAccountingEntryMap.put(key + '' +item.Amount_Type__c, item);
                    wAccounting.redistributionAccountingEntries.add(item);
                }
            }
        }
        
        /* Prepare Accounting for Redistributions */        
        for (Redistrib_detail__c item : scope) {
            Id creditedCompanyId = item.Store__r.Legal_Form__c;
            Id debitedCompanyId = item.Redistrib_head__r.Master_BU__r.Legal_Form__c;
            String negoDiscountTypes = item.Redistrib_head__r.Nego_Discount_Type__c;
            String storeType = item.Store__r.Management_Type__c;
            Boolean managedBU = item.Store__r.Managed_BU__c;
            Decimal redistributionYear = item.Redistrib_head__r.Year__c;
            Decimal amountHT = item.Redistrib_amnt_HT__c != null ? item.Redistrib_amnt_HT__c : 0;
            Decimal amountTTC = item.Redistributed_amount_TTC__c != null ? item.Redistributed_amount_TTC__c : 0;
            List<Accounting_Scheme__c> accountingSchemeList = debitedCompanyForRedistributionMap.get(debitedCompanyId);
            if(accountingSchemeList != null && !accountingSchemeList.isEmpty()) {
                for(Accounting_Scheme__c accountingScheme : accountingSchemeList){
                    Boolean existHTCreditedFlagC = false, existHTCreditedFlagD = false, existHTDebitedFlagC = false, existHTDebitedFlagD = false, existHTDCFlagC = false, existHTDCFlagD = false,
                        existTTCCredited = false, existTTCDebited = false, existTTCDC = false,
                        existTVACredited = false, existTVADebited = false, existTVADC = false,
                        redistribDetailLinkedToHTCreditedFlagC = false, redistribDetailLinkedToHTCreditedFlagD = false, 
                        redistribDetailLinkedToHTDebitedFlagC = false, redistribDetailLinkedToHTDebitedFlagD = false, 
                        redistribDetailLinkedToHTDCFlagC = false, redistribDetailLinkedToHTDCFlagD = false,
                        redistribDetailLinkedToTVACredited = false, redistribDetailLinkedToTVADebited = false, redistribDetailLinkedToTVADC = false,
                        redistribDetailLinkedToTTCCredited = false, redistribDetailLinkedToTTCDebited = false, redistribDetailLinkedToTTCDC = false;
                    String accountingEntryFor = accountingScheme.Accounting_Entry_for__c;
                    String accountingType = accountingScheme.Accounting_Type__c;
                    String flagDC = accountingScheme.Flag_D_or_C__c;
                    // Delete accounting entries
                    if(accountingType == 'Ristourne' &&
                       ((creditedCompanyId == debitedCompanyId && (accountingEntryFor == 'Credited' || accountingEntryFor == 'Debited')) ||
                        (creditedCompanyId != debitedCompanyId && accountingEntryFor == 'Debited=Credited'))){
                            continue;
                        }
                    String key;
                    if(negoDiscountTypes != null && accountingScheme.Included_Discount_Types__c == negoDiscountTypes){
                        key = debitedCompanyId + '' + accountingScheme.Included_Discount_Types__c + '' + accountingEntryFor + '' +
                            storeType + '' + managedBU + '' + accountingType + '' + flagDC + '' + creditedCompanyId + '' + Integer.valueOf(redistributionYear);
                    }
                    if(String.isNotBlank(key)){
                        // check if redistribution line assign to accounting HT,TTC,TVA
                        String redistributionkey = debitedCompanyId + '' + accountingScheme.Included_Discount_Types__c + '' + accountingEntryFor + '' + storeType + '' + managedBU + '' + accountingType + '' + flagDC;
                        if(accountingSchemeForRedistributionMap.containsKey(redistributionkey)){
                            List<Accounting_Scheme__c> accountingSchemesForRedistribution = accountingSchemeForRedistributionMap.get(redistributionkey);
                            for(Accounting_Scheme__c scheme : accountingSchemesForRedistribution){
                                String keyAmount = item.Id + '' + scheme.Amount_Type__c + '' + accountingEntryFor;
                                if(scheme.Amount_Type__c == 'HT'){
                                    if(accountingEntryFor == 'Credited' && flagDC == 'Credit'){
                                        existHTCreditedFlagC = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount + '' + flagDC)){
                                            redistribDetailLinkedToHTCreditedFlagC = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Credited' && flagDC == 'Debit'){
                                        existHTCreditedFlagD = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount + '' + flagDC)){
                                            redistribDetailLinkedToHTCreditedFlagD = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited' && flagDC == 'Credit'){
                                        existHTDebitedFlagC = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount + '' + flagDC)){
                                            redistribDetailLinkedToHTDebitedFlagC = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited' && flagDC == 'Debit'){
                                        existHTDebitedFlagD = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount + '' + flagDC)){
                                            redistribDetailLinkedToHTDebitedFlagD = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited=Credited' && flagDC == 'Credit'){
                                        existHTDCFlagC = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount + '' + flagDC)){
                                            redistribDetailLinkedToHTDCFlagC = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited=Credited' && flagDC == 'Debit'){
                                        existHTDCFlagD = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount + '' + flagDC)){
                                            redistribDetailLinkedToHTDCFlagD = true;
                                        }
                                    }
                                    if(!redistributionDetailAssignToAccountingEntrySet.contains(keyAmount + '' + flagDC)){
                                        redistributionDetailAssignToAccountingEntrySet.add(keyAmount + '' + flagDC);
                                    }
                                }
                                if(scheme.Amount_Type__c == 'TVA'){
                                    if(accountingEntryFor == 'Credited'){
                                        existTVACredited = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                            redistribDetailLinkedToTVACredited = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited'){
                                        existTVADebited = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                            redistribDetailLinkedToTVADebited = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited=Credited'){
                                        existTVADC = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                            redistribDetailLinkedToTVADC = true;
                                        }
                                    }
                                    if(!redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                        redistributionDetailAssignToAccountingEntrySet.add(keyAmount);
                                    }
                                }
                                if(scheme.Amount_Type__c == 'TTC'){
                                    if(accountingEntryFor == 'Credited'){
                                        existTTCCredited = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                            redistribDetailLinkedToTTCCredited = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited'){
                                        existTTCDebited = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                            redistribDetailLinkedToTTCDebited = true;
                                        }
                                    }
                                    if(accountingEntryFor == 'Debited=Credited'){
                                        existTTCDC = true;
                                        if(redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                            redistribDetailLinkedToTTCDC = true;
                                        }
                                    }
                                    if(!redistributionDetailAssignToAccountingEntrySet.contains(keyAmount)){
                                        redistributionDetailAssignToAccountingEntrySet.add(keyAmount);
                                    }
                                }
                            }
                        }
                        if((existHTCreditedFlagC && !redistribDetailLinkedToHTCreditedFlagC) || (existHTCreditedFlagD && !redistribDetailLinkedToHTCreditedFlagD) ||
                           (existHTDebitedFlagC && !redistribDetailLinkedToHTDebitedFlagC) || (existHTDebitedFlagD && !redistribDetailLinkedToHTDebitedFlagD) ||
                           (existHTDCFlagC && !redistribDetailLinkedToHTDCFlagC) || (existHTDCFlagD && !redistribDetailLinkedToHTDCFlagD) ||                       
                           (existTVACredited && !redistribDetailLinkedToTVACredited) || (existTVADebited && !redistribDetailLinkedToTVADebited) || (existTVADC && !redistribDetailLinkedToTVADC) ||
                           (existTTCCredited && !redistribDetailLinkedToTTCCredited) || (existTTCDebited && !redistribDetailLinkedToTTCDebited) || (existTTCDC && !redistribDetailLinkedToTTCDC)){
                               WrapperAccounting wAccounting;
                               if(accountingRedistributionMap.containsKey(key)){
                                   wAccounting = accountingRedistributionMap.get(key);                               
                                   wAccounting.redistributionDetails.add(item);
                               }
                               else{
                                   wAccounting = new WrapperAccounting();
                                   wAccounting.accountingScheme = accountingScheme;
                                   wAccounting.accountingClosing = accountingClosing;
                                   wAccounting.creditedCompanyId = creditedCompanyId;
                                   wAccounting.debitedCompanyId = debitedCompanyId;
                                   wAccounting.NegoDiscountTypes = accountingScheme.Included_Discount_Types__c;
                                   wAccounting.redistributionYear = redistributionYear;      
                                   wAccounting.storeType = storeType;
                                   wAccounting.managedBU = managedBU;
                                   wAccounting.accountingType = accountingType;
                                   wAccounting.accountingEntryFor = accountingEntryFor;
                                   wAccounting.flagDC = flagDC;
                                   wAccounting.businessUnitId = accountingScheme.Business_Unit__c;
                                   wAccounting.businessUnitName = accountingScheme.Business_Unit__r.Name;
                                   wAccounting.creditedCompanyName = accountingScheme.Credited_Company__r.Name;
                                   wAccounting.debitedCompanyName = accountingScheme.Debited_Company__r.Name;
                                   wAccounting.redistributionDetails.add(item);
                                   accountingRedistributionMap.put(key, wAccounting);
                               }
                               // calculate amount
                               if((existHTCreditedFlagC && !redistribDetailLinkedToHTCreditedFlagC) || (existHTCreditedFlagD && !redistribDetailLinkedToHTCreditedFlagD) ||
                                  (existHTDebitedFlagC && !redistribDetailLinkedToHTDebitedFlagC) || (existHTDebitedFlagD && !redistribDetailLinkedToHTDebitedFlagD) ||
                                  (existHTDCFlagC && !redistribDetailLinkedToHTDCFlagC) || (existHTDCFlagD && !redistribDetailLinkedToHTDCFlagD)){
                                      wAccounting.amountHT += amountHT;
                                  }
                               if((existTTCCredited && !redistribDetailLinkedToTTCCredited) || (existTTCDebited && !redistribDetailLinkedToTTCDebited) || (existTTCDC && !redistribDetailLinkedToTTCDC)){
                                   wAccounting.amountTTC += amountTTC;
                               }
                               if((existTVACredited && !redistribDetailLinkedToTVACredited) || (existTVADebited && !redistribDetailLinkedToTVADebited) || (existTVADC && !redistribDetailLinkedToTVADC)){
                                   wAccounting.amountTVA += (amountTTC - amountHT);
                               }
                               if(!wAccounting.isLinkedToHTCreditedFlagC){
                                   wAccounting.isLinkedToHTCreditedFlagC = existHTCreditedFlagC && !redistribDetailLinkedToHTCreditedFlagC;
                               }
                               if(!wAccounting.isLinkedToHTCreditedFlagD){
                                   wAccounting.isLinkedToHTCreditedFlagD = existHTCreditedFlagD && !redistribDetailLinkedToHTCreditedFlagD;
                               }
                               if(!wAccounting.isLinkedToHTDebitedFlagC){
                                   wAccounting.isLinkedToHTDebitedFlagC = existHTDebitedFlagC && !redistribDetailLinkedToHTDebitedFlagC;
                               }
                               if(!wAccounting.isLinkedToHTDebitedFlagD){
                                   wAccounting.isLinkedToHTDebitedFlagD = existHTDebitedFlagD && !redistribDetailLinkedToHTDebitedFlagD;
                               }
                               if(!wAccounting.isLinkedToHTDCFlagC){
                                   wAccounting.isLinkedToHTDCFlagC = existHTDCFlagC && !redistribDetailLinkedToHTDCFlagC;
                               }
                               if(!wAccounting.isLinkedToHTDCFlagD){
                                   wAccounting.isLinkedToHTDCFlagD = existHTDCFlagD && !redistribDetailLinkedToHTDCFlagD;
                               }
                               if(!wAccounting.isLinkedToTVACredited){
                                   wAccounting.isLinkedToTVACredited = existTVACredited && !redistribDetailLinkedToTVACredited;
                               }
                               if(!wAccounting.isLinkedToTVADebited){
                                   wAccounting.isLinkedToTVADebited = existTVADebited && !redistribDetailLinkedToTVADebited;
                               }
                               if(!wAccounting.isLinkedToTVADC){
                                   wAccounting.isLinkedToTVADC = existTVADC && !redistribDetailLinkedToTVADC;
                               }
                               if(!wAccounting.isLinkedToTTCCredited){
                                   wAccounting.isLinkedToTTCCredited = existTTCCredited && !redistribDetailLinkedToTTCCredited;
                               }
                               if(!wAccounting.isLinkedToTTCDebited){
                                   wAccounting.isLinkedToTTCDebited = existTTCDebited && !redistribDetailLinkedToTTCDebited;
                               }
                               if(!wAccounting.isLinkedToTTCDC){
                                   wAccounting.isLinkedToTTCDC = existTTCDC && !redistribDetailLinkedToTTCDC;
                               }
                               // Assign redistribution detail to HT,TTC,TVA
                               if(existHTCreditedFlagC && !redistribDetailLinkedToHTCreditedFlagC){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('HT' + 'Credited' + 'Credit');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'HT' + 'Credited' + 'Credit'});
                                   }
                               }
                               if(existHTCreditedFlagD && !redistribDetailLinkedToHTCreditedFlagD){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('HT' + 'Credited' + 'Debit');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'HT' + 'Credited' + 'Debit'});
                                   }
                               }
                               if(existHTDebitedFlagC && !redistribDetailLinkedToHTDebitedFlagC){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('HT' + 'Debited' + 'Credit');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'HT' + 'Debited' + 'Credit'});
                                   }
                               }
                               if(existHTDebitedFlagD && !redistribDetailLinkedToHTDebitedFlagD){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('HT' + 'Debited' + 'Debit');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'HT' + 'Debited' + 'Debit'});
                                   }
                               }
                               if(existHTDCFlagC && !redistribDetailLinkedToHTDCFlagC){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('HT' + 'Debited=Credited' + 'Credit');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'HT' + 'Debited=Credited' + 'Credit'});
                                   }
                               }
                               if(existHTDCFlagD && !redistribDetailLinkedToHTDCFlagD){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('HT' + 'Debited=Credited' + 'Debit');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'HT' + 'Debited=Credited' + 'Debit'});
                                   }
                               }
                               if(existTVACredited && !redistribDetailLinkedToTVACredited){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('TVA' + 'Credited');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'TVA' + 'Credited'});
                                   }
                               }
                               if(existTVADebited && !redistribDetailLinkedToTVADebited){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('TVA' + 'Debited');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'TVA' + 'Debited'});
                                   }
                               }
                               if(existTVADC && !redistribDetailLinkedToTVADC){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('TVA' + 'Debited=Credited');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'TVA' + 'Debited=Credited'});
                                   }
                               }
                               if(existTTCCredited && !redistribDetailLinkedToTTCCredited){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('TTC' + 'Credited');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'TTC' + 'Credited'});
                                   }
                               }
                               if(existTTCDebited && !redistribDetailLinkedToTTCDebited){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('TTC' + 'Debited');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'TTC' + 'Debited'});
                                   }
                               }
                               if(existTTCDC && !redistribDetailLinkedToTTCDC){
                                   if(wAccounting.ammountTypeForRedistributionMap.containsKey(item.Id)){
                                       wAccounting.ammountTypeForRedistributionMap.get(item.Id).add('TTC' + 'Debited=Credited');
                                   }
                                   else{
                                       wAccounting.ammountTypeForRedistributionMap.put(item.Id, new Set<String>{'TTC' + 'Debited=Credited'});
                                   }
                               }
                           }
                    }
                }
            }
        }
        if(accountingRedistributionMap != null && !accountingRedistributionMap.isEmpty()) {
            for (WrapperAccounting item : accountingRedistributionMap.values()) {
                if(item.isLinkedToHTCreditedFlagC || item.isLinkedToHTCreditedFlagD || 
                   item.isLinkedToHTDebitedFlagC || item.isLinkedToHTDebitedFlagD || 
                   item.isLinkedToHTDCFlagC || item.isLinkedToHTDCFlagD)
                {
                    if(item.existHTCreditedFlagC || item.existHTCreditedFlagD ||
                       item.existHTDebitedFlagC || item.existHTDebitedFlagD || 
                       item.existHTDCFlagC || item.existHTDCFlagD) 
                    {
                        item.updateAccountingEntryForRedistribution('HT', item.amountHT);
                    }
                    else {
                        item.insertAccountingEntryForRedistribution('HT', item.amountHT, amountTypeForRedistributionMap);                    
                    }
                }
                if(item.isLinkedToTTCCredited || item.isLinkedToTTCDebited || item.isLinkedToTTCDC){
                    if(item.existTTCCredited || item.existTTCDebited || item.existTTCDC) {
                        item.updateAccountingEntryForRedistribution('TTC', item.amountTTC);
                    }
                    else {
                        item.insertAccountingEntryForRedistribution('TTC', item.amountTTC, amountTypeForRedistributionMap);
                    }
                }
                if(item.isLinkedToTVACredited || item.isLinkedToTVADebited || item.isLinkedToTVADC){
                    if(item.existTVACredited || item.existTVADebited || item.existTVADC) {
                        item.updateAccountingEntryForRedistribution('TVA', item.amountTVA);
                    }
                    else {
                        item.insertAccountingEntryForRedistribution('TVA', item.amountTVA, amountTypeForRedistributionMap);
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
                NegoptimHelper.normalizeAPIName('Amount__c'), NegoptimHelper.normalizeAPIName('Amount_signed__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Reference_year__c')};
            
            // check security on update accounting entry fields
            String[] accountingEntryUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Amount__c'), NegoptimHelper.normalizeAPIName('Amount_signed__c')};
                        
            // check security on update redistribution detail fields
            String[] redistributionDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Accounting_entry_credit_woVAT__c'),
                NegoptimHelper.normalizeAPIName('Accounting_entry_credit_woVAT_D__c'), NegoptimHelper.normalizeAPIName('Accounting_entry_debit_woVAT__c'),
                NegoptimHelper.normalizeAPIName('Accounting_entry_debit_woVAT_D__c'), NegoptimHelper.normalizeAPIName('Accounting_entry_woVAT__c'),
                NegoptimHelper.normalizeAPIName('Accounting_entry_woVAT_D__c'), NegoptimHelper.normalizeAPIName('Accounting_entry_credit_wVAT__c'),
                NegoptimHelper.normalizeAPIName('Accounting_entry_debit_wVAT__c'), NegoptimHelper.normalizeAPIName('Accounting_entry_wVAT__c'),
                NegoptimHelper.normalizeAPIName('Accounting_entry_credit_VAT__c'), NegoptimHelper.normalizeAPIName('Accounting_entry_debit_VAT__c'),
                NegoptimHelper.normalizeAPIName('Accounting_entry_VAT__c')};
       
            if(accountingRedistributionMap != null && !accountingRedistributionMap.isEmpty()) {
                for (WrapperAccounting item : accountingRedistributionMap.values()) {
                    accountingEntryList.addAll(item.redistributionAccountingEntries);
                    if(String.isNotBlank(item.errorMessage)) {
                        nb.logError(item.errorMessage);
                    }
                }
            }
            if(NegoptimHelper.checkCreatibility(Accounting_Entry__c.SObjectType, accountingEntryInsertFields) &&
               NegoptimHelper.checkUpdatibility(Accounting_Entry__c.SObjectType, accountingEntryUpdateFields) &&
               NegoptimHelper.checkUpdatibility(Redistrib_detail__c.SObjectType, redistributionDetailFields))
            {
                // Insert Accounting Entry.
                if(accountingEntryList != null && accountingEntryList.size() > 0) {
                    List<Database.UpsertResult> results = Database.upsert(accountingEntryList, false);
                    nb.logResults(results, accountingEntryList);
                    
                    Map<Id, Accounting_Entry__c> accountingEntryMap = new Map<Id, Accounting_Entry__c>([SELECT Id, Name, Ext_id__c, Amount_Type__c, Flag_D_or_C__c, Accounting_Entry_for__c FROM Accounting_Entry__c WHERE Id IN :accountingEntryList]);
                    // Update Redistribution Details.
                    if(accountingEntryMap != null && accountingEntryMap.size() > 0) {
                        for (WrapperAccounting item : accountingRedistributionMap.values()) {
                            for(Redistrib_detail__c redistributionDetail : item.redistributionDetails){
                                if(redistributionDetailMap.containsKey(redistributionDetail.Id)){
                                    redistributionDetail = redistributionDetailMap.get(redistributionDetail.Id);
                                }else{
                                    redistributionDetailMap.put(redistributionDetail.Id, redistributionDetail);
                                }
                                // check redistribution detail linked to HT,TTC,TVA
                                Set<String> amountTypeSet;
                                if(item.ammountTypeForRedistributionMap.containsKey(redistributionDetail.Id)){
                                    amountTypeSet = item.ammountTypeForRedistributionMap.get(redistributionDetail.Id);
                                }
                                if(amountTypeSet == null) continue;
                                for(Accounting_Entry__c accountingEntry : item.redistributionAccountingEntries){
                                    if(accountingEntry.Id != null && accountingEntryMap.get(accountingEntry.Id) != null){
                                        accountingEntry = accountingEntryMap.get(accountingEntry.Id);
                                        String key = accountingEntry.Amount_Type__c + accountingEntry.Accounting_Entry_for__c;
                                        if(accountingEntry.Amount_Type__c == 'HT'){
                                            key += accountingEntry.Flag_D_or_C__c;
                                            if(accountingEntry.Accounting_Entry_for__c == 'Credited' && accountingEntry.Flag_D_or_C__c == 'Credit' && redistributionDetail.Accounting_entry_credit_woVAT__c == null){
                                                redistributionDetail.Accounting_entry_credit_woVAT__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Credited' && accountingEntry.Flag_D_or_C__c == 'Debit' && redistributionDetail.Accounting_entry_credit_woVAT_D__c == null){
                                                redistributionDetail.Accounting_entry_credit_woVAT_D__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited' && accountingEntry.Flag_D_or_C__c == 'Credit' && redistributionDetail.Accounting_entry_debit_woVAT__c == null){
                                                redistributionDetail.Accounting_entry_debit_woVAT__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited' && accountingEntry.Flag_D_or_C__c == 'Debit' && redistributionDetail.Accounting_entry_debit_woVAT_D__c == null){
                                                redistributionDetail.Accounting_entry_debit_woVAT_D__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited=Credited' && accountingEntry.Flag_D_or_C__c == 'Credit' && redistributionDetail.Accounting_entry_woVAT__c == null){
                                                redistributionDetail.Accounting_entry_woVAT__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited=Credited' && accountingEntry.Flag_D_or_C__c == 'Debit' && redistributionDetail.Accounting_entry_woVAT_D__c == null){
                                                redistributionDetail.Accounting_entry_woVAT_D__c = accountingEntry.Id;
                                            }
                                        }
                                        if(accountingEntry.Amount_Type__c == 'TTC'){
                                            if(accountingEntry.Accounting_Entry_for__c == 'Credited' && amountTypeSet.contains(key) && redistributionDetail.Accounting_entry_credit_wVAT__c == null){
                                                redistributionDetail.Accounting_entry_credit_wVAT__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited' && amountTypeSet.contains(key) && redistributionDetail.Accounting_entry_debit_wVAT__c == null){
                                                redistributionDetail.Accounting_entry_debit_wVAT__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited=Credited' && amountTypeSet.contains(key) && redistributionDetail.Accounting_entry_wVAT__c == null){
                                                redistributionDetail.Accounting_entry_wVAT__c = accountingEntry.Id;
                                            }
                                        }
                                        if(accountingEntry.Amount_Type__c == 'TVA'){
                                            if(accountingEntry.Accounting_Entry_for__c == 'Credited' && amountTypeSet.contains(key) && redistributionDetail.Accounting_entry_credit_VAT__c == null){
                                                redistributionDetail.Accounting_entry_credit_VAT__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited' && amountTypeSet.contains(key) && redistributionDetail.Accounting_entry_debit_VAT__c == null){
                                                redistributionDetail.Accounting_entry_debit_VAT__c = accountingEntry.Id;
                                            }
                                            if(accountingEntry.Accounting_Entry_for__c == 'Debited=Credited' && amountTypeSet.contains(key) && redistributionDetail.Accounting_entry_VAT__c == null){
                                                redistributionDetail.Accounting_entry_VAT__c = accountingEntry.Id;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if(redistributionDetailMap != null && redistributionDetailMap.size() > 0) {
                    List<Database.SaveResult> results = Database.update(redistributionDetailMap.values(), false);
                    nb.logResults(results, redistributionDetailMap.values());
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
        
        Map<String, Accounting_Entry__c> redistributionAccountingEntryMap {get; set;}
        List<Accounting_Entry__c> redistributionAccountingEntries {get; set;}
        List<Redistrib_detail__c> redistributionDetails {get; set;}
        Map<Id, Set<String>> ammountTypeForRedistributionMap {get; set;}
                
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
        // Accounting redistributions parameters
        String accountingEntryfor {get; set;}
        String storeType {get; set;}
        Boolean managedBU {get; set;}
        String flagDC {get; set;}
        Decimal redistributionYear {get; set;}
        Decimal amountHT {get; set;}
        Decimal amountTTC {get; set;}
        Decimal amountTVA {get; set;}
        Boolean isLinkedToHTCreditedFlagC {get; set;}
        Boolean isLinkedToHTCreditedFlagD {get; set;}
        Boolean isLinkedToHTDebitedFlagC {get; set;}
        Boolean isLinkedToHTDebitedFlagD {get; set;}
        Boolean isLinkedToHTDCFlagC {get; set;}
        Boolean isLinkedToHTDCFlagD {get; set;}
        Boolean isLinkedToTVACredited {get; set;}
        Boolean isLinkedToTVADebited {get; set;}
        Boolean isLinkedToTVADC {get; set;}
        Boolean isLinkedToTTCCredited {get; set;}
        Boolean isLinkedToTTCDebited {get; set;}
        Boolean isLinkedToTTCDC {get; set;}
        Boolean existHTCreditedFlagC {get; set;}
        Boolean existHTCreditedFlagD {get; set;}
        Boolean existHTDebitedFlagC {get; set;}
        Boolean existHTDebitedFlagD {get; set;}
        Boolean existHTDCFlagC {get; set;}
        Boolean existHTDCFlagD {get; set;}
        Boolean existTTCCredited {get; set;}
        Boolean existTTCDebited {get; set;}
        Boolean existTTCDC {get; set;}
        Boolean existTVACredited {get; set;}
        Boolean existTVADebited {get; set;}
        Boolean existTVADC {get; set;}
        
        // constructor
        public WrapperAccounting() {
            redistributionAccountingEntryMap = new Map<String, Accounting_Entry__c>();
                        
            redistributionAccountingEntries = new List<Accounting_Entry__c>();
            redistributionDetails = new List<Redistrib_detail__c>();
            ammountTypeForRedistributionMap = new Map<Id, Set<String>>();
            
            isLinkedToHTCreditedFlagC = false;
            isLinkedToHTCreditedFlagD = false;
            isLinkedToHTDebitedFlagC = false;
            isLinkedToHTDebitedFlagD = false;
            isLinkedToHTDCFlagC = false;
            isLinkedToHTDCFlagD = false;
            isLinkedToTVACredited = false;
            isLinkedToTVADebited = false;
            isLinkedToTVADC = false;
            isLinkedToTTCCredited = false;
            isLinkedToTTCDebited = false;
            isLinkedToTTCDC = false;
            
            existHTCreditedFlagC = false;
            existHTCreditedFlagD = false;
            existHTDebitedFlagC = false;
            existHTDebitedFlagD = false;
            existHTDCFlagC = false;
            existHTDCFlagD = false;
            existTTCCredited = false;
            existTTCDebited = false;
            existTTCDC = false;
            existTVACredited = false;
            existTVADebited = false;
            existTVADC = false;
            
            amountHT = 0;
            amountTTC = 0;
            amountTVA = 0;
            errorMessage ='';
        }
        
        // create accounting entry for redistributions
        public void insertAccountingEntryForRedistribution(String amountType, Decimal amount, Map<String, Accounting_Scheme__c> amountTypeMap){
            String key = this.debitedCompanyId + '' + this.NegoDiscountTypes + '' + this.accountingEntryFor + '' + this.storeType + '' + this.managedBU + '' + this.accountingType + '' + this.flagDC + '' + amountType;
            Accounting_Scheme__c accountingSchemeForRedistribution;
            if(amountTypeMap.containsKey(key)){
                accountingSchemeForRedistribution = amountTypeMap.get(key);
            }
            if(accountingSchemeForRedistribution == null){
                this.errorMessage += string.format('Accounting scheme based on the business unit {0}, debited company {1}, NegoDiscountTypes {2}, accountingEntryfor {3}, storeType {4}, managedBU {5}, accountingType {6} and amountType {7} not exist.', 
                                                   new String[]{ this.businessUnitName, this.debitedCompanyName, this.NegoDiscountTypes, this.accountingEntryfor, this.storeType, string.valueOf(this.managedBU), this.accountingType, amountType }) + '\n';
                return;
            }
            Accounting_Entry__c accountingEntry = new Accounting_Entry__c(Entry_Type__c = 'Redistribution',
                                                                          Accounting_Closing__c = accountingClosing.Id,
                                                                          Accounting_Scheme_Line__c = accountingSchemeForRedistribution != null ? accountingSchemeForRedistribution.Id : null,
                                                                          Credited_Company__c = this.creditedCompanyId,
                                                                          Debited_Company__c = this.debitedCompanyId,
                                                                          Entry_Label__c = 'DISTRIBUTION AUX AYANTS_DROITS',
                                                                          Comment__c = Integer.valueOf(this.redistributionYear) + (this.storeType == 'Affiliated' ? 'A' : 'P') + (this.storeType == 'Affiliated' && this.managedBU == true ? 'G' : ' ') + amountType,
                                                                          Amount__c = amount.abs(),
                                                                          Amount_signed__c = amount,
                                                                          Status__c = accountingClosing.Status__c == 'Preview' ? 'Preview' : 'Extract',
                                                                          Reference_year__c = Integer.valueOf(this.redistributionYear));
            redistributionAccountingEntries.add(accountingEntry);
        }
        
        // update existing accounting entry for Redistribution
        public void updateAccountingEntryForRedistribution(String amountType, Decimal amount){           
            String key = this.debitedCompanyId + '' + this.NegoDiscountTypes + '' + this.accountingEntryFor + '' + this.storeType + '' + 
                this.managedBU + '' + this.accountingType + '' + this.flagDC + '' + this.creditedCompanyId + '' + Integer.valueOf(this.redistributionYear);
            Accounting_Entry__c accountingEntry = redistributionAccountingEntryMap.get(key + '' + amountType);
            accountingEntry.Amount__c = amount.abs();
            accountingEntry.Amount_signed__c = amount;
        }
        
        String formatDate(Date input, String format){
            return DateTime.newInstance( input.year(), input.month(), input.day()).format(format);
        }
    }
}