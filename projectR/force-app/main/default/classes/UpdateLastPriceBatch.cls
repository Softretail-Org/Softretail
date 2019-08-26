/*
 * Update last price for Product and PG
 */ 
public with sharing class UpdateLastPriceBatch implements Database.Batchable<AggregateResult>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    private List<Id> productIds;
    private List<Id> supplierIds;
    private DateTime minSellinDate;
    private Map<String, Sell_in_Flow__c> lastSellinPGMap;
    private Map<Id, Sell_in_Flow__c> lastSellinProductMap;
    
    public UpdateLastPriceBatch(String startedFrom, List<Sell_in_Flow__c> sellinList){
        
        this.nb = new NegoptimBatch('Update Last Price', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.productIds = new List<Id>();
        this.supplierIds = new List<Id>();
        this.lastSellinPGMap = new Map<String, Sell_in_Flow__c>();
        this.lastSellinProductMap = new Map<Id, Sell_in_Flow__c>();
        
        if(sellinList != null && !sellinList.isEmpty()) {
            for(Sell_in_Flow__c item : sellinList){
                if(!this.productIds.contains(item.Mvt_Purch_Product__c)){
                    this.productIds.add(item.Mvt_Purch_Product__c);
                }
                if(!this.supplierIds.contains(item.Supplier__c)){
                    this.supplierIds.add(item.Supplier__c);
                }
                // fill Map last sell in grouping by supplier and product
                String key = item.Supplier__c + '' + item.Mvt_Purch_Product__c;
                if(!this.lastSellinPGMap.containsKey(key)){
                    this.lastSellinPGMap.put(key, item);
                }
                else {
                    Sell_in_Flow__c lastSellin = lastSellinPGMap.get(key);
                    if(lastSellin.Invoice_Date__c < item.Invoice_Date__c){
                        this.lastSellinPGMap.put(key, item);
                    }
                }
                // fill Map last sell in grouping by product
                if(!this.lastSellinProductMap.containsKey(item.Mvt_Purch_Product__c)){
                    this.lastSellinProductMap.put(item.Mvt_Purch_Product__c, item);
                }
                else {
                    Sell_in_Flow__c lastSellin = lastSellinProductMap.get(item.Mvt_Purch_Product__c);
                    if(lastSellin.Invoice_Date__c < item.Invoice_Date__c){
                        this.lastSellinProductMap.put(item.Mvt_Purch_Product__c, item);
                    }
                }
                // get min sell in date
                if(item.Invoice_Date__c != null){
                    if(minSellinDate == null){
                        minSellinDate = item.Invoice_Date__c;
                    }
                    else if(item.Invoice_Date__c < minSellinDate){
                        minSellinDate = item.Invoice_Date__c;
                    }
                }
            }
        }
        String minSellinDateFormat = minSellinDate != null ? minSellinDate.format('yyyy-MM-dd') : DateTime.now().format('yyyy-MM-dd');
        String q = 'SELECT Supplier__c Supplier__c, Mvt_Purch_Product__c Mvt_Purch_Product__c, MAX(Invoice_Date__c) maxDate';
        q += ' FROM Sell_in_Flow__c';
        q += ' WHERE Mvt_Purch_Product__c <> NULL AND Supplier__c <> NULL';
        q += ' AND Mvt_Purch_Product__c IN (\'' + String.join(productIds, '\',\'') +'\')';
        q += ' AND Invoice_Date__c >= '+ minSellinDateFormat +'';
        q += ' GROUP BY Supplier__c, Mvt_Purch_Product__c';
        q += ' ORDER BY MAX(Invoice_Date__c) DESC';        
        query = q;
        nb.logParameter('query' , query);
    }
    
    public Iterable<AggregateResult> start(Database.BatchableContext bc){
        return new AggregateResultIterable(query);
    }
    
    // Execute method
    public void execute(Database.BatchableContext BC, List<Sobject> scope){
        List<Supplier_PG_Mapping__c> pgList = new List<Supplier_PG_Mapping__c>();
        Map<Id, Sell_in_Flow__c> productMap = new Map<Id, Sell_in_Flow__c>();        
        Map<String, Supplier_PG_Mapping__c> PGMap = new Map<String, Supplier_PG_Mapping__c>();
        if(supplierIds.size() > 0 && productIds.size() > 0){
            // Get PGs
            for(Supplier_PG_Mapping__c item : [SELECT Id, Supplier__c, Product__c, Last_Gross_Price__c, Last_List_Price__c, Last_Net_Price__c
                                               FROM Supplier_PG_Mapping__c 
                                               WHERE Supplier__c IN :supplierIds AND Product__c IN :productIds])
            {
                String key = item.Supplier__c + '' + item.Product__c;
                if(!PGMap.containsKey(key)){
                    PGMap.put(key, item);
                }
            }
            
            // Get last sell in flow grouping by supplier and product
            for(Sobject obj : scope) {
                AggregateResult aggr = (AggregateResult) obj;
                Date maxInvoiceDate = Date.valueOf(aggr.get('maxDate'));
                Id supplierId = (Id)aggr.get('Supplier__c');
                Id productId = (Id)aggr.get('Mvt_Purch_Product__c');
                string key = supplierId + '' + productId;
                // get last sell in for PG
                Sell_in_Flow__c lastSellinPG = lastSellinPGMap.get(key);
                if(lastSellinPG != null){
                    if(lastSellinPG.Invoice_Date__c >= maxInvoiceDate){
                        // get PG
                        Supplier_PG_Mapping__c PG = PGMap.get(key);
                        // update PG last price
                        if(PG != null && (lastSellinPG.Gross_Price__c != PG.Last_Gross_Price__c || lastSellinPG.List_price__c != PG.Last_List_Price__c || lastSellinPG.Net_Price__c != PG.Last_Net_Price__c)){
                            PG.Last_Gross_Price__c = lastSellinPG.Gross_Price__c;
                            PG.Last_List_Price__c = lastSellinPG.List_price__c;
                            PG.Last_Net_Price__c = lastSellinPG.Net_Price__c;
                            pgList.add(PG);
                        }
                    }
                    lastSellinPGMap.remove(key);
                }
                
                // get last sell in for product
                Sell_in_Flow__c lastSellinProduct = lastSellinProductMap.get(productId);
                if(lastSellinProduct != null){
                    if(lastSellinProduct.Invoice_Date__c >= maxInvoiceDate){
                        // get last unit price for product
                        if(!productMap.containsKey(productId)){
                            productMap.put(productId, lastSellinProduct);
                        }
                    }
                    lastSellinProductMap.remove(productId);
                }
            }            
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update PG fields
            String[] PGFields = new String[] {NegoptimHelper.normalizeAPIName('Last_Gross_Price__c'),
                NegoptimHelper.normalizeAPIName('Last_List_Price__c'), NegoptimHelper.normalizeAPIName('Last_Net_Price__c')};
            // update PG last price
            if(NegoptimHelper.checkUpdatibility(Supplier_PG_Mapping__c.SObjectType, PGFields) && pgList.size() > 0){
                List<Database.SaveResult> results = Database.update(pgList, false);
                nb.logResults(results, pgList);
            }
            
            // check security on update product fields
            String[] productFields = new String[] {NegoptimHelper.normalizeAPIName('Last_Unit_Cost__c')};
            // update product last unit price
            if(NegoptimHelper.checkUpdatibility(Product2.SObjectType, productFields) && productMap.size() > 0){
                List<Product2> products = new List<Product2>();
                for(Product2 item : [SELECT Id, Last_Unit_Cost__c FROM Product2 WHERE Id IN :productMap.keySet()]){
                    Sell_in_Flow__c sellin = productMap.get(item.Id);
                    if(sellin.Unit_Cost__c != item.Last_Unit_Cost__c){
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