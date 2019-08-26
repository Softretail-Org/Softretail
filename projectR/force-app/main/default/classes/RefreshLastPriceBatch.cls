/*
* Update last price for Product and PG
*/ 
public with sharing class RefreshLastPriceBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    private DateTime minSellinDate;
    private List<Supplier_PG_Mapping__c> pgUpdatedList;
    private Set<String> pgUpdatedSet;
    private Set<Id> productUpdatedSet;
    
    public RefreshLastPriceBatch(String startedFrom, List<Supplier_PG_Mapping__c> pgList) {
        
        this.nb = new NegoptimBatch('Refresh Last Price', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.pgUpdatedList = pgList;
        this.pgUpdatedSet = new Set<String>();
        this.productUpdatedSet = new Set<Id>();
        
        String q = 'SELECT Supplier__c, Mvt_Purch_Product__c, Gross_Price__c, List_price__c, Net_Price__c, Unit_Cost__c, Invoice_Date__c';
        q += ' FROM Sell_in_Flow__c';
        q += ' WHERE Mvt_Purch_Product__c <> NULL AND Supplier__c <> NULL';

        if(pgUpdatedList != null && !pgUpdatedList.isEmpty()) {
            List<Id> productIds = new List<Id>();
            List<Id> supplierIds = new List<Id>();
            for(Supplier_PG_Mapping__c item : pgUpdatedList){
                if(!productIds.contains(item.Product__c)){
                    productIds.add(item.Product__c);
                }
                if(!supplierIds.contains(item.Supplier__c)){
                    supplierIds.add(item.Supplier__c);
                }
            }
            q += ' AND Mvt_Purch_Product__c IN (\'' + String.join(productIds, '\',\'') +'\')';
            q += ' AND Supplier__c IN (\'' + String.join(supplierIds, '\',\'') +'\')';
        }
        q += ' ORDER BY Invoice_Date__c DESC';
        query = q;
        nb.logParameter('query' , query);
        nb.logParameter('pgList' , pgList);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    // Execute method
    public void execute(Database.BatchableContext BC, List<Sell_in_Flow__c> scope) {
        
        Set<Id> productIds = new Set<Id>();
        Set<Id> supplierIds = new Set<Id>();
        Map<String, Sell_in_Flow__c> lastSellinPGMap = new Map<String, Sell_in_Flow__c>();
        Map<Id, Sell_in_Flow__c> lastSellinProductMap = new Map<Id, Sell_in_Flow__c>();
        for(Sell_in_Flow__c item : scope) {
            if(!productIds.contains(item.Mvt_Purch_Product__c)) {
                productIds.add(item.Mvt_Purch_Product__c);
            }
            if(!supplierIds.contains(item.Supplier__c)) {
                supplierIds.add(item.Supplier__c);
            }
            // fill Map last sell in grouping by supplier and product
            String key = item.Supplier__c + '' + item.Mvt_Purch_Product__c;
            if(!this.pgUpdatedSet.contains(key)) {
                if(!lastSellinPGMap.containsKey(key)) {
                    lastSellinPGMap.put(key, item);
                }
                else {
                    Sell_in_Flow__c lastSellin = lastSellinPGMap.get(key);
                    if(lastSellin.Invoice_Date__c < item.Invoice_Date__c) {
                        lastSellinPGMap.put(key, item);
                    }
                }
            }
            // fill Map last sell in grouping by product
            if(!this.productUpdatedSet.contains(item.Mvt_Purch_Product__c)) {                
                if(!lastSellinProductMap.containsKey(item.Mvt_Purch_Product__c)) {
                    lastSellinProductMap.put(item.Mvt_Purch_Product__c, item);
                }
                else {
                    Sell_in_Flow__c lastSellin = lastSellinProductMap.get(item.Mvt_Purch_Product__c);
                    if(lastSellin.Invoice_Date__c < item.Invoice_Date__c) {
                        lastSellinProductMap.put(item.Mvt_Purch_Product__c, item);
                    }
                }
            }
        }
        List<Supplier_PG_Mapping__c> pgList = new List<Supplier_PG_Mapping__c>();
        Map<Id, Sell_in_Flow__c> productMap = new Map<Id, Sell_in_Flow__c>();        
        Map<String, Supplier_PG_Mapping__c> PGMap = new Map<String, Supplier_PG_Mapping__c>();
        if(lastSellinPGMap.size() > 0 || lastSellinProductMap.size() > 0) {
            if(this.pgUpdatedList == null) pgUpdatedList = [SELECT Id, Supplier__c, Product__c, Last_Gross_Price__c, Last_List_Price__c, Last_Net_Price__c
                                                            FROM Supplier_PG_Mapping__c 
                                                            WHERE Supplier__c IN :supplierIds AND Product__c IN :productIds];
            // Get PGs
            for(Supplier_PG_Mapping__c item : this.pgUpdatedList) {
                String key = item.Supplier__c + '' + item.Product__c;
                if(!PGMap.containsKey(key)) {
                    PGMap.put(key, item);
                }
            }
            
            // Get last sell in flow grouping by supplier and product
            for(String key : lastSellinPGMap.keySet()) {
                // get last sell in for PG
                Sell_in_Flow__c lastSellinPG = lastSellinPGMap.get(key);
                // get PG
                Supplier_PG_Mapping__c PG = PGMap.get(key);
                // update PG last price
                if(PG != null && !this.pgUpdatedSet.contains(key) && (lastSellinPG.Gross_Price__c != PG.Last_Gross_Price__c || lastSellinPG.List_price__c != PG.Last_List_Price__c || lastSellinPG.Net_Price__c != PG.Last_Net_Price__c)) {
                    PG.Last_Gross_Price__c = lastSellinPG.Gross_Price__c;
                    PG.Last_List_Price__c = lastSellinPG.List_price__c;
                    PG.Last_Net_Price__c = lastSellinPG.Net_Price__c;
                    pgList.add(PG);
                    this.pgUpdatedSet.add(key);
                }
            }
            for(String productId : lastSellinProductMap.keySet()) {
                // get last sell in for product
                Sell_in_Flow__c lastSellinProduct = lastSellinProductMap.get(productId);
                if(lastSellinProduct != null){
                    // get last unit price for product
                    if(!this.productUpdatedSet.contains(productId) && !productMap.containsKey(productId)) {
                        productMap.put(productId, lastSellinProduct);
                        this.productUpdatedSet.add(productId);
                    }
                }
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update PG fields
            String[] PGFields = new String[] {NegoptimHelper.normalizeAPIName('Last_Gross_Price__c'),
                NegoptimHelper.normalizeAPIName('Last_List_Price__c'), NegoptimHelper.normalizeAPIName('Last_Net_Price__c')};
            // update PG last price
            if(NegoptimHelper.checkUpdatibility(Supplier_PG_Mapping__c.SObjectType, PGFields) && pgList.size() > 0) {
                List<Database.SaveResult> results = Database.update(pgList, false);
                nb.logResults(results, pgList);
            }
            
            // check security on update product fields
            String[] productFields = new String[] {NegoptimHelper.normalizeAPIName('Last_Unit_Cost__c')};
            // update product last unit price
            if(NegoptimHelper.checkUpdatibility(Product2.SObjectType, productFields) && productMap.size() > 0) {
                List<Product2> products = new List<Product2>();
                for(Product2 item : [SELECT Id, Last_Unit_Cost__c FROM Product2 WHERE Id IN :productMap.keySet()]) {
                    Sell_in_Flow__c sellin = productMap.get(item.Id);
                    if(sellin.Unit_Cost__c != item.Last_Unit_Cost__c) {
                        item.Last_Unit_Cost__c = sellin.Unit_Cost__c;
                        products.add(item);
                    }
                }
                List<Database.SaveResult> results = Database.update(products, false);
                nb.logResults(results, products);
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
    
    // finish method
    public void finish(Database.BatchableContext bc){
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}