/**
 * copy sell in flow to purchases flow pg.
 **/
public with sharing class SellinToPurchaseBatch implements Database.Batchable<sObject>, Database.stateful {
	
	private NegoptimBatch nb;
	public final String query;
    private List<Id> buIds;
    private List<Id> supplierIds;
    private List<Id> productIds;
    private List<Integer> months;
    private Integer year;
    
    // list of contract list for re-Calculate TO
    private List<Id> contractIds;
    
    // Constructor.
    public SellinToPurchaseBatch(String startedFrom, List<Id> contractRecalculateIds, List<Id> buIds, List<Id> supplierIds, List<Id> productIds, List<Integer> months, Integer year, Boolean filterContract) {
        // Create instance of NegoptimBatch.
        nb = new NegoptimBatch('SellinToPurchaseBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.buIds = buIds;
        this.supplierIds = supplierIds;
        this.productIds = productIds;
        this.months = months;
        this.year = year;
        this.contractIds = new List<Id>();
        if(contractRecalculateIds != null && !contractRecalculateIds.isEmpty()) {
            this.contractIds.addAll(contractRecalculateIds);
        }
        
        String q = 'SELECT Id, Name, BU__c, Supplier__c, Structure_level__c, Structure_level__r.Parent_Element__c, Structure_level__r.Level__c,';
        q += ' Year__c, Month__c, Mvt_Purch_Product__c, Mvt_Purch_Product__r.Category__c, Mvt_Purch_Product__r.Category__r.Parent_Element__c,';
        q += ' Invoice_Net_Amount_woTax_calc__c, Invoice_Quantity__c, Net_Margin_Volume_Calc__c, Sales_Cost__c, Invoice_Date__c, Order_Date__c, CurrencyISOCode,';
        q += ' Contract__c, Has_Correct_Contract__c';
        q += ' FROM Sell_in_Flow__c';
        q += ' WHERE Monthly_Conso__c = FALSE';
        q += ' AND Invoice_Date__c <> NULL AND BU__c <> NULL AND Supplier__c <> NULL AND Mvt_Purch_Product__c <> NULL';
        
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
        if(this.year != null) {
            q += ' AND Year__c = ' + this.year + '';
        }
        // filterContract: used to force refresh of selected contract
        if(filterContract != null && filterContract && contractRecalculateIds != null && !contractRecalculateIds.isEmpty()) {
            q += ' AND Contract__c IN (\'' + String.join(contractRecalculateIds, '\',\'') +'\')';
        }
        q += ' Order By Mvt_Purch_Product__c, Month__c';
        this.query = q;
        
        // push inputs to log
        nb.logParameter('buIds', this.buIds);
        nb.logParameter('supplierIds', this.supplierIds);
        nb.logParameter('productIds', this.productIds);
        nb.logParameter('months', this.months);
        nb.logParameter('year', this.year);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('filterContract', filterContract);
        nb.logParameter('query', this.query);
    }
    // start
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    // execute
    public void execute(Database.BatchableContext BC, List<Sell_in_Flow__c> scope) {
        // List of sell in flow to update
        List<Sell_in_Flow__c> sellinFlowList = new List<Sell_in_Flow__c>();
        // List of purchase flow PG
        List<Purchases_Flow_PG__c> purchaseFlowPGList = new List<Purchases_Flow_PG__c>();
        List<SellInFlowWrapper> wSellInFlowList = new List<SellInFlowWrapper>();
        Map<String, SellInFlowWrapper> sellInFlowMap = new Map<String, SellInFlowWrapper>();
        Map<String, Purchases_Flow_PG__c> purchaseFlowPGMap = new Map<String, Purchases_Flow_PG__c>();
        Map<String, Supplier_PG_Mapping__c> supplierPGMap = new Map<String, Supplier_PG_Mapping__c>();
        Set<Id> buIdSet = new Set<Id>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        
        for(Sell_in_Flow__c item : scope) {
            String key = item.Year__c + '' + item.BU__c + '' + item.Mvt_Purch_Product__c + '' + item.Supplier__c;
            SellInFlowWrapper wSellInFlow;
            if(sellInFlowMap.containsKey(key)) {
                wSellInFlow = sellInFlowMap.get(key);
                wSellInFlow.month = Integer.valueOf(item.Month__c);
            } else {
                wSellInFlow = new SellInFlowWrapper();                
                wSellInFlow.year = Integer.valueOf(item.Year__c);
                wSellInFlow.month = Integer.valueOf(item.Month__c);
                wSellInFlow.buId = item.BU__c;
                wSellInFlow.sectionId = item.Mvt_Purch_Product__r.Category__c; // item.Structure_level__c
                wSellInFlow.departmentId = item.Mvt_Purch_Product__r.Category__r.Parent_Element__c; // item.Structure_level__r.Parent_Element__c
                wSellInFlow.productId = item.Mvt_Purch_Product__c;
                wSellInFlow.supplierId = item.Supplier__c;
                // Map to Purchase Flow PG
                wSellInFlow.mapToPurchaseFlowPG();
                wSellInFlow.purchaseFlowPG.CurrencyISOCode = item.CurrencyISOCode;
                sellInFlowMap.put(key, wSellInFlow);
            }
            wSellInFlow.calculate(item);
            if(!buIdSet.contains(item.BU__c)) {
                buIdSet.add(item.BU__c);
            }
            if(!productIdSet.contains(item.Mvt_Purch_Product__c)){
                productIdSet.add(item.Mvt_Purch_Product__c);
            }
            if(!supplierIdSet.contains(item.Supplier__c)){
                supplierIdSet.add(item.Supplier__c);
            }
            if(!yearSet.contains(Integer.valueOf(item.Year__c))){
                yearSet.add(Integer.valueOf(item.Year__c));
            }
            // update sell in flow conso
            item.Monthly_Conso__c = true;
            wSellInFlow.sellinFlows.add(item);
            // fill list of contracts to be calculated
            // TODO: filter only those related to success records
            if(item.Has_Correct_Contract__c && !contractIds.contains(item.Contract__c)){
                contractIds.add(item.Contract__c);
            }
        }
        // get old purchase flow PG
        for(Purchases_Flow_PG__c item : [SELECT Id, Name, Year__c, Sequence__c, BU__c, PG__c, PG__r.Product__c, Supplier__c, Department__c, Section__c,
                                         YTD_TO__c, TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c, TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c,
                                         Qty1__c, Qty2__c, Qty3__c, Qty4__c, Qty5__c, Qty6__c, Qty7__c, Qty8__c, Qty9__c, Qty10__c, Qty11__c, Qty12__c,
                                         Sales_Cost_M1__c, Sales_Cost_M2__c, Sales_Cost_M3__c, Sales_Cost_M4__c, Sales_Cost_M5__c, Sales_Cost_M6__c,
                                         Sales_Cost_M7__c, Sales_Cost_M8__c, Sales_Cost_M9__c, Sales_Cost_M10__c, Sales_Cost_M11__c, Sales_Cost_M12__c,
                                         Front_Margin_M1__c, Front_Margin_M2__c, Front_Margin_M3__c, Front_Margin_M4__c, Front_Margin_M5__c, Front_Margin_M6__c,
                                         Front_Margin_M7__c, Front_Margin_M8__c, Front_Margin_M9__c, Front_Margin_M10__c, Front_Margin_M11__c, Front_Margin_M12__c
                                         FROM Purchases_Flow_PG__c
                                         WHERE PG__r.Product__c IN :productIdSet
                                         AND Supplier__c IN :supplierIdSet
                                         AND BU__c IN :buIdSet
                                         AND Year__c IN :yearSet])
        {
            String key = item.Year__c + '' + item.BU__c + '' + item.PG__r.Product__c + '' + item.Supplier__c;
            purchaseFlowPGMap.put(key, item);
        }
        // get list of supplier pg
        for(Supplier_PG_Mapping__c item :[SELECT Id, Product__c, Supplier__c FROM Supplier_PG_Mapping__c 
                                          WHERE Product__c IN :productIdSet AND Supplier__c IN :supplierIdSet])
        {
            String key = item.Product__c + '' + item.Supplier__c;
            supplierPGMap.put(key, item);
        }
        // insert purchase flow PG
        for(SellInFlowWrapper item : sellInFlowMap.values()) {
            Supplier_PG_Mapping__c supplierPG = supplierPGMap.get(item.productId + '' + item.supplierId);
            if(supplierPG == null) continue;
            item.purchaseFlowPG.PG__c = supplierPG.Id;
            // update front margin
            // item.updateFrontMargin();
            // check existing purchase flow pg
            if(purchaseFlowPGMap.containsKey(item.key)) {
                Purchases_Flow_PG__c oldPurchaseFlowPG = purchaseFlowPGMap.get(item.key);
                item.updatePurchaseFlowPG(oldPurchaseFlowPG);
                item.purchaseFlowPG.Id = oldPurchaseFlowPG.Id;
            }
            wSellInFlowList.add(item);            
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            for(SellInFlowWrapper item :wSellInFlowList){
                purchaseFlowPGList.add(item.purchaseFlowPG);                
            }
            // Check purchase flow pg upsert field security
            String[] purchaseFlowPGFields = new String [] {NegoptimHelper.normalizeAPIName('Supplier__c'), 
                NegoptimHelper.normalizeAPIName('BU__c'), NegoptimHelper.normalizeAPIName('Department__c'), NegoptimHelper.normalizeAPIName('Section__c'), 
                NegoptimHelper.normalizeAPIName('Year__c'), NegoptimHelper.normalizeAPIName('PG__c'), NegoptimHelper.normalizeAPIName('Sequence__c'), 
                NegoptimHelper.normalizeAPIName('TO1__c'), NegoptimHelper.normalizeAPIName('TO2__c'), NegoptimHelper.normalizeAPIName('TO3__c'),
                NegoptimHelper.normalizeAPIName('TO4__c'), NegoptimHelper.normalizeAPIName('TO5__c'), NegoptimHelper.normalizeAPIName('TO6__c'),
                NegoptimHelper.normalizeAPIName('TO7__c'), NegoptimHelper.normalizeAPIName('TO8__c'), NegoptimHelper.normalizeAPIName('TO9__c'),
                NegoptimHelper.normalizeAPIName('TO10__c'), NegoptimHelper.normalizeAPIName('TO11__c'), NegoptimHelper.normalizeAPIName('TO12__c'),
                NegoptimHelper.normalizeAPIName('Qty1__c'), NegoptimHelper.normalizeAPIName('Qty2__c'), NegoptimHelper.normalizeAPIName('Qty3__c'),
                NegoptimHelper.normalizeAPIName('Qty4__c'), NegoptimHelper.normalizeAPIName('Qty5__c'), NegoptimHelper.normalizeAPIName('Qty6__c'),
                NegoptimHelper.normalizeAPIName('Qty7__c'), NegoptimHelper.normalizeAPIName('Qty8__c'), NegoptimHelper.normalizeAPIName('Qty9__c'),
                NegoptimHelper.normalizeAPIName('Qty10__c'), NegoptimHelper.normalizeAPIName('Qty11__c'), NegoptimHelper.normalizeAPIName('Qty12__c'),                
                NegoptimHelper.normalizeAPIName('Sales_Cost_M1__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M2__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M3__c'),
                NegoptimHelper.normalizeAPIName('Sales_Cost_M4__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M5__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M6__c'),
                NegoptimHelper.normalizeAPIName('Sales_Cost_M7__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M8__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M9__c'),
                NegoptimHelper.normalizeAPIName('Sales_Cost_M10__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M11__c'), NegoptimHelper.normalizeAPIName('Sales_Cost_M12__c'),                
                NegoptimHelper.normalizeAPIName('Front_Margin_M1__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M2__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M3__c'),
                NegoptimHelper.normalizeAPIName('Front_Margin_M4__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M5__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M6__c'),
                NegoptimHelper.normalizeAPIName('Front_Margin_M7__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M8__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M9__c'),
                NegoptimHelper.normalizeAPIName('Front_Margin_M10__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M11__c'), NegoptimHelper.normalizeAPIName('Front_Margin_M12__c')};
            
            // Check sell in field security
            String[] sellinFields = new String [] {NegoptimHelper.normalizeAPIName('Monthly_Conso__c')};           
            
            if(NegoptimHelper.checkCreatibility(Purchases_Flow_PG__c.SObjectType, purchaseFlowPGFields) && 
               NegoptimHelper.checkUpdatibility(Purchases_Flow_PG__c.SObjectType, purchaseFlowPGFields) &&
               purchaseFlowPGList.size() > 0) 
            {
                List<Database.UpsertResult> results = Database.upsert(purchaseFlowPGList, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results.get(i);
                    Purchases_Flow_PG__c purchaseFlowPG = purchaseFlowPGList.get(i);
                    SellInFlowWrapper sellinWrapper = wSellInFlowList.get(i);
                    if (!result.isSuccess()){                        
                        String errorMessage = (purchaseFlowPG.Name != null ? purchaseFlowPG.Name : '') + 
                            ' - PG Id (' + purchaseFlowPG.PG__c + ') - Supplier Id (' + purchaseFlowPG.Supplier__c +
                            ') - BU Id =(' + purchaseFlowPG.BU__c + ') : ';
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs){
                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        nb.logError(errorMessage);
                    }
                    else{
                        sellinFlowList.addAll(sellinWrapper.sellinFlows);
                    }
                }
            }
            // update sell in flow
            if(NegoptimHelper.checkUpdatibility(Sell_in_Flow__c.SObjectType, sellinFields) && sellinFlowList.size() > 0){
                List<Database.SaveResult> results = Database.update(sellinFlowList, false);
            }
        } catch(DmlException e) {
            nb.logError('DML Exception: ' + e.getDMLMessage(0) + ' - ' + e.getLineNumber());
            Database.rollback(sp);
        } catch(Exception e) {
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
        }
        nb.incrementBatchIndex();
    }
    // finish
    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ' - ';
        customSubject += this.year != null ? String.valueOf(this.year) : 'All Years';
        customSubject += '/';
        customSubject += this.months != null ? String.join(this.months, ',') : 'All Months';
        customSubject += ' : ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
        if (!this.contractIds.isEmpty() && (nb.getStartedFrom().equalsIgnoreCase('ResetSellinMonthlyConsoBatch') 
                                            || nb.getStartedFrom().equalsIgnoreCase('Schedule')
                                            || nb.getStartedFrom().equalsIgnoreCase('WebServiceExecuteBatches'))) {
            // Execute Calculate TO Contract Batch.
            Database.executeBatch(new CalculateTOContractBatch('SellinToPurchaseBatch', null, this.contractIds, this.year));
            // Execute Calculate Base TO Batch.
            Database.executeBatch(new CalculateBaseTOBatch('SellinToPurchaseBatch', null, this.contractIds, null, this.year));
        }
    }
                 
    /* Sell In Flow Wrapper Class */
    public class SellInFlowWrapper {
        List<Sell_in_Flow__c> sellinFlows {get; set;}
        Purchases_Flow_PG__c purchaseFlowPG {get; set;}
        public Integer year {get; set;}
        public Integer month {get; set;}
        public Id buId {get; set;}
        public Id departmentId {get; set;}
        public Id sectionId {get; set;}
        public Id productId {get; set;}
        public Id supplierId {get; set;}
        public Map<Integer, Decimal> frontMarginMap {get; set;}
        public String key {
            get {
                return year + '' + buId + '' + productId + '' + supplierId;
            }
            set;
        }
        
        public SellInFlowWrapper() {
            frontMarginMap = new Map<Integer, Decimal>();
            sellinFlows = new List<Sell_in_Flow__c>();
        }
        
        // Map to purchase flow PG
        public void mapToPurchaseFlowPG() {
            this.purchaseFlowPG = new Purchases_Flow_PG__c(Supplier__c = this.supplierId, Department__c = this.departmentId, 
                                                           Section__c = this.sectionId, Year__c = this.year,
                                                           Sequence__c = this.month, BU__c = this.buId);
        }
        
        /*public Boolean checkUpdate(Purchases_Flow_PG__c oldPurchaseFlowPG) {
            // check if updating TO, Qty, Front_Margin
            for(Integer i = 1; i <= 12; i++) {
                String fieldNameTO = 'TO' + i + '__c';
                String fieldQuantity = 'Qty' + i + '__c';
                String fieldNameFrontMargin = 'Front_Margin_M' + i + '__c';
                // check update TO
                if(oldPurchaseFlowPG.get(fieldNameTO) != null && this.purchaseFlowPG.get(fieldNameTO) != null &&
                   oldPurchaseFlowPG.get(fieldNameTO) != this.purchaseFlowPG.get(fieldNameTO)){
                       return true;
                   }
                // check update Qty
                if(oldPurchaseFlowPG.get(fieldQuantity) != null && this.purchaseFlowPG.get(fieldQuantity) != null &&
                   oldPurchaseFlowPG.get(fieldQuantity) != this.purchaseFlowPG.get(fieldQuantity)){
                       return true;
                   }
                // check update Front_Margin
                if(oldPurchaseFlowPG.get(fieldNameFrontMargin) != null && this.purchaseFlowPG.get(fieldNameFrontMargin) != null &&
                   oldPurchaseFlowPG.get(fieldNameFrontMargin) != this.purchaseFlowPG.get(fieldNameFrontMargin)){
                       return true;
                   }
            }
            return false;
        }*/
        
        public void updatePurchaseFlowPG(Purchases_Flow_PG__c oldPurchaseFlowPG) {
            // update TO, Qty, Front_Margin
            for(Integer i = 1; i <= 12; i++) {
                String fieldNameTO = 'TO' + i + '__c';
                String fieldQuantity = 'Qty' + i + '__c';
                String fieldSalesCost = 'Sales_Cost_M' + i + '__c';
                String fieldNameFrontMargin = 'Front_Margin_M' + i + '__c';
                
                Decimal to = 0, salesCost = 0, frontMargin = 0; Integer quantity = 0;
                // update TO                
                if(this.purchaseFlowPG.get(fieldNameTO) != null) {
                    to = Decimal.valueOf(String.valueOf(this.purchaseFlowPG.get(fieldNameTO)));
                }
                if(oldPurchaseFlowPG.get(fieldNameTO) != null){
                    to += Decimal.valueOf(String.valueOf(oldPurchaseFlowPG.get(fieldNameTO)));                    
                    this.purchaseFlowPG.put(fieldNameTO, to);
                }
                // update Quantity                
                if(this.purchaseFlowPG.get(fieldQuantity) != null) {
                    quantity = Integer.valueOf(this.purchaseFlowPG.get(fieldQuantity));                    
                }
                if(oldPurchaseFlowPG.get(fieldQuantity) != null){
                    quantity += Integer.valueOf(oldPurchaseFlowPG.get(fieldQuantity));
                    this.purchaseFlowPG.put(fieldQuantity, quantity);
                }
                // update Sales Cost
                if(this.purchaseFlowPG.get(fieldSalesCost) != null) {
                    salesCost = Decimal.valueOf(String.valueOf(purchaseFlowPG.get(fieldSalesCost)));
                }
                if(oldPurchaseFlowPG.get(fieldSalesCost) != null){
                    salesCost += Decimal.valueOf(String.valueOf(oldPurchaseFlowPG.get(fieldSalesCost)));                    
                    this.purchaseFlowPG.put(fieldSalesCost, salesCost);
                }
                // update Front_Margin                
                /*if(this.purchaseFlowPG.get(fieldNameFrontMargin) != null) {
                    frontMargin = Decimal.valueOf(String.valueOf(this.purchaseFlowPG.get(fieldNameFrontMargin)));
                }
                if(oldPurchaseFlowPG.get(fieldNameFrontMargin) != null){
                    frontMargin += Decimal.valueOf(String.valueOf(oldPurchaseFlowPG.get(fieldNameFrontMargin)));
                    this.purchaseFlowPG.put(fieldNameFrontMargin, frontMargin);
                }*/
            }
        }
        
        // calculate TO, Quatity and Front Magrin
        public void calculate(Sell_in_Flow__c sellIn) {
            String fieldNameTO = 'TO' + this.month + '__c';
            String fieldQuantity = 'Qty' + this.month + '__c';
            String fieldSalesCost = 'Sales_Cost_M' + this.month + '__c';
            
            Decimal totalInvoiceNetAmountwoTaxCalc = 0, totalNetMarginVolumeCalc = 0, totalSalesCost = 0;
            Integer totalInvoiceQuantity = 0;
            // calculate TO
            if(purchaseFlowPG.get(fieldNameTO) != null){
                totalInvoiceNetAmountwoTaxCalc = Decimal.valueOf(String.valueOf(purchaseFlowPG.get(fieldNameTO)));
            }
            if(sellIn.Invoice_Net_Amount_woTax_Calc__c != null) {
                totalInvoiceNetAmountwoTaxCalc += sellIn.Invoice_Net_Amount_woTax_Calc__c;
                this.purchaseFlowPG.put(fieldNameTO, totalInvoiceNetAmountwoTaxCalc);
            }
            // calculate quantity
            if(purchaseFlowPG.get(fieldQuantity) != null) {
                totalInvoiceQuantity = Integer.valueOf(purchaseFlowPG.get(fieldQuantity));
            }
            if(sellIn.Invoice_Quantity__c != null) {
                totalInvoiceQuantity += Integer.valueOf(sellIn.Invoice_Quantity__c);
                this.purchaseFlowPG.put(fieldQuantity, totalInvoiceQuantity);
            }
            // calculate Sales Cost
            if(this.purchaseFlowPG.get(fieldSalesCost) != null) {
                totalSalesCost = Decimal.valueOf(String.valueOf(purchaseFlowPG.get(fieldSalesCost)));
            }
            if(sellIn.Sales_Cost__c != null) {
                totalSalesCost += sellIn.Sales_Cost__c;
                this.purchaseFlowPG.put(fieldSalesCost, totalSalesCost);
            }
            // calculate front margin
            /*if(sellIn.Net_Margin_Volume_Calc__c != null) {
                if(frontMarginMap.containsKey(this.month)){
                    totalNetMarginVolumeCalc = frontMarginMap.get(this.month);
                    totalNetMarginVolumeCalc += sellIn.Net_Margin_Volume_Calc__c;
                    frontMarginMap.put(this.month, totalNetMarginVolumeCalc);
                }
                else{
                    frontMarginMap.put(this.month, sellIn.Net_Margin_Volume_Calc__c);
                }
            }*/
        }
        
        /*public void updateFrontMargin() {
            for(Integer i = 1; i <= 12; i++) {
                String fieldNameTO = 'TO' + i + '__c';
                String fieldNameFrontMargin = 'Front_Margin_M' + i + '__c';
                Decimal to = 0, totalNetMarginVolumeCalc = 0;
                if(this.purchaseFlowPG.get(fieldNameTO) != null){
                    to = Decimal.valueOf(String.valueOf(this.purchaseFlowPG.get(fieldNameTO)));                               
                }
                if(frontMarginMap.get(i) != null){
                    totalNetMarginVolumeCalc = Integer.valueOf(frontMarginMap.get(i));
                }
                if(totalNetMarginVolumeCalc != 0) {
                    this.purchaseFlowPG.put(fieldNameFrontMargin, (totalNetMarginVolumeCalc / (to + totalNetMarginVolumeCalc)));
                }
            }
        }*/
    }
}