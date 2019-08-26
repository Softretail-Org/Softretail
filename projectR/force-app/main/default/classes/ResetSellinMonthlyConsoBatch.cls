/**
 * update monthly conso sell in flow.
 **/
public with sharing class ResetSellinMonthlyConsoBatch implements Database.Batchable<sObject>, Database.stateful {
    
    private NegoptimBatch nb;
    public final String query;
    private List<Id> buIds;
    private List<Id> supplierIds;
    private List<Id> productIds;
    private List<Integer> months;
    private Integer year;

    // used in reparenting sell_in : list of old contract list for re-Calculate TO
    private List<Id> contractIds;
    private Boolean filterContract;
    
    // Constructor.
    public ResetSellinMonthlyConsoBatch(String startedFrom, List<Id> contractRecalculateIds, List<Id> buIds, List<Id> supplierIds, List<Id> productIds, List<Integer> months, Integer year, Boolean monthlyConso, Boolean filterContract) {
        nb = new NegoptimBatch('Reset Sell in flow Monthly conso', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.buIds = buIds;
        this.supplierIds = supplierIds;
        this.productIds = productIds;
        this.months = months;
        this.year = year;
        this.contractIds = new List<Id>();
        this.filterContract = filterContract;
        if(contractRecalculateIds != null && !contractRecalculateIds.isEmpty()) {
            this.contractIds.addAll(contractRecalculateIds);
        }
        
        String q = 'SELECT Id, Name, Monthly_Conso__c, Supplier__c, Mvt_Purch_Product__c, BU__c, Month__c, Year__c';
        q += ' FROM Sell_in_Flow__c';
        q += ' WHERE Invoice_Date__c <> NULL AND BU__c <> NULL AND Supplier__c <> NULL AND Mvt_Purch_Product__c <> NULL';
        q += ' AND Year__c = ' + year + '';
        
        if(monthlyConso != null) {
            q += ' AND Monthly_Conso__c = ' + monthlyConso;
        }
        if(this.buIds != null) {
            q += ' AND BU__c IN (\'' + String.join(buIds, '\',\'') +'\')';
        }
        if(this.supplierIds != null) {
            q += ' AND Supplier__c IN (\'' + String.join(supplierIds, '\',\'') +'\')';
        }
        if(this.productIds != null) {
            q += ' AND Mvt_Purch_Product__c IN (\'' + String.join(productIds, '\',\'') +'\')';
        }
        if(this.months != null) {
            q += ' AND Month__c IN (' + String.join(months, ',') +') ';
        }
        // filterContract: used to force refresh of selected contract
        if(filterContract != null && filterContract && contractRecalculateIds != null && !contractRecalculateIds.isEmpty()) {
            q += ' AND Contract__c IN (\'' + String.join(contractRecalculateIds, '\',\'') +'\')';
        }
        query = q;
        nb.logParameter('buIds', this.buIds);
        nb.logParameter('supplierIds', this.supplierIds);
        nb.logParameter('productIds', this.productIds);
        nb.logParameter('months', this.months);
        nb.logParameter('year', this.year);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('filterContract', this.filterContract);
        nb.logParameter('query', this.query);
    }
    
    // start
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // execute
    public void execute(Database.BatchableContext BC, List<Sell_in_Flow__c> scope) {
        Set<Id> buSet = new Set<Id>();
        Set<Id> supplierSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Set<Integer> monthSet = new Set<Integer>();
        
        for(Sell_in_Flow__c item : scope) {
            if(!buSet.contains(item.BU__c)){
                buSet.add(item.BU__c);
            }
            if(!supplierSet.contains(item.Supplier__c)){
                supplierSet.add(item.Supplier__c);
            }
            if(!productSet.contains(item.Mvt_Purch_Product__c)){
                productSet.add(item.Mvt_Purch_Product__c);
            }
            if(!monthSet.contains(Integer.valueOf(item.Month__c))){
                monthSet.add(Integer.valueOf(item.Month__c));
            }
            item.Monthly_Conso__c = false;
        }
        Savepoint sp = Database.setSavepoint();
        try {
            List<Database.SaveResult> results = Database.update(scope, false);
            nb.logResults(results, scope);
            
            // case delete purchases when delete PG
            if(negoptimHelper.checkDeletibility(Purchases_Flow_PG__c.SObjectType)){
                delete [SELECT Id FROM Purchases_Flow_PG__c WHERE PG__c = ''];
            }
            
            // Update/Delete purchases Monthly
            String purchasesQuery = 'SELECT Id FROM Purchases_Flow_PG__c WHERE PG__c <> null';
            if(!supplierSet.isEmpty()) {
                purchasesQuery += ' AND Supplier__c IN (\''+ String.join(new List<Id>(supplierSet), '\',\'') + '\')';
            }
            if(!productSet.isEmpty()) {
                purchasesQuery += ' AND PG__r.Product__c IN (\''+ String.join(new List<Id>(productSet), '\',\'') + '\')';
            }
            if(!buSet.isEmpty()) {
                purchasesQuery += ' AND BU__c IN (\''+ String.join(new List<Id>(buSet), '\',\'') + '\')';
            }
            if(this.year != null) {
                purchasesQuery += ' AND Year__c = ' + this.year + '';
            }
            List<Purchases_Flow_PG__c> purchases = Database.query(purchasesQuery);
            if(purchases != null && !purchases.isEmpty()) {
                for(Integer i : monthSet) {
                    String fieldNameTO = 'TO' + i + '__c';
                    String fieldQuantity = 'Qty' + i + '__c';
                    String fieldNameFrontMargin = 'Front_Margin_M' + i + '__c';
                    String fieldSalesCost = 'Sales_Cost_M' + i + '__c';
                    for(Purchases_Flow_PG__c item : purchases) {
                        item.put(fieldNameTO, null);
                        item.put(fieldQuantity, null);
                        item.put(fieldNameFrontMargin, null);
                        item.put(fieldSalesCost, null);
                    }
                }
                results = Database.update(purchases, false);
                nb.logResults(results, purchases);
            }
        } catch(DmlException e){
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e){
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // finish
    public void finish(Database.BatchableContext BC) {
        // update purchases monthly
        if(!Test.isRunningTest()) {
            Database.executeBatch(new SellinToPurchaseBatch('ResetSellinMonthlyConsoBatch', this.contractIds, this.buIds, this.supplierIds, this.productIds, this.months, this.year, this.filterContract));
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}