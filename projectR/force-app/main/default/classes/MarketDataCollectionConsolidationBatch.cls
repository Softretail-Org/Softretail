/*
 * Generate market collection details monthly
 * Recalculate market details using sequences day and weight
 */ 
public with sharing class MarketDataCollectionConsolidationBatch implements Database.Batchable<SObject> {

    private NegoptimBatch nb;
    private final String query;
    
    // Constructor.
    public MarketDataCollectionConsolidationBatch(String startedFrom, Set<Id> marketDetailIds) {
        this.nb = new NegoptimBatch('MarketDataCollectionConsolidationBatch', NegoptimBatch.BatchType.Stateful, startedFrom);

        String q = ' SELECT Id, Market_Data_Collection_Head__c, Market_Data_Collection_Head__r.Flow_Type__c, Market_Data_Collection_Head__r.Master_BU__c, Market_Data_Collection_Head__r.Movement_Date__c,';
        q += ' Market_Data_Collection_Head__r.Ext_Category_Name__c, Market_Data_Collection_Head__r.Ext_BU_Name__c,';
        q += ' Market_Data_Collection_Head__r.Orga_BU__c, Market_Data_Collection_Head__r.Orga_HE__c, Market_Data_Collection_Head__r.Client__c,';
        q += ' Orga_HE__c, Orga_BU__c, Product__c, Ext_Category_Name__c, Ext_BU_Name__c, Ext_Product_Name__c, Ext_Product_EAN__c, Ext_Brand_Name__c, Ext_Packaging__c, Year__c, SEQ__c,';
        q += ' Date_SSEQ0__c, Date_SSEQ1__c, Date_SSEQ2__c, Date_SSEQ3__c, Date_SSEQ4__c, Date_SSEQ5__c, Weight_SSEQ0__c, Weight_SSEQ1__c, Weight_SSEQ2__c, Weight_SSEQ3__c, Weight_SSEQ4__c, Weight_SSEQ5__c,';
        q += ' SellOut_Quantity_SSEQ0__c, SellOut_Quantity_SSEQ1__c, SellOut_Quantity_SSEQ2__c, SellOut_Quantity_SSEQ3__c, SellOut_Quantity_SSEQ4__c, SellOut_Quantity_SSEQ5__c,';
        q += ' SellOut_Tone_SSEQ0__c, SellOut_Tone_SSEQ1__c, SellOut_Tone_SSEQ2__c, SellOut_Tone_SSEQ3__c, SellOut_Tone_SSEQ4__c, SellOut_Tone_SSEQ5__c,';
        q += ' SellOut_wTax_SSEQ0__c, SellOut_wTax_SSEQ1__c, SellOut_wTax_SSEQ2__c, SellOut_wTax_SSEQ3__c, SellOut_wTax_SSEQ4__c, SellOut_wTax_SSEQ5__c,';
        q += ' SellOut_woTax_SSEQ0__c, SellOut_woTax_SSEQ1__c, SellOut_woTax_SSEQ2__c, SellOut_woTax_SSEQ3__c, SellOut_woTax_SSEQ4__c, SellOut_woTax_SSEQ5__c,';        
        q += ' ND_1_SSEQ0__c, ND_1_SSEQ1__c, ND_1_SSEQ2__c, ND_1_SSEQ3__c, ND_1_SSEQ4__c, ND_1_SSEQ5__c, ND_2_SSEQ0__c, ND_2_SSEQ1__c, ND_2_SSEQ2__c, ND_2_SSEQ3__c, ND_2_SSEQ4__c, ND_2_SSEQ5__c,';
        q += ' WD_1_SSEQ0__c, WD_1_SSEQ1__c, WD_1_SSEQ2__c, WD_1_SSEQ3__c, WD_1_SSEQ4__c, WD_1_SSEQ5__c, WD_2_SSEQ0__c, WD_2_SSEQ1__c, WD_2_SSEQ2__c, WD_2_SSEQ3__c, WD_2_SSEQ4__c, WD_2_SSEQ5__c,';
        q += ' SellOut_Quantity_SEQ__c, SellOut_Tone_SEQ__c, SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, ND_1_SEQ__c, WD_1_SEQ__c, ND_2_SEQ__c, WD_2_SEQ__c, Average_Retail_Price_SEQ__c, Avg_Weekly_Sales_Ext_ClientBased__c,';
        q += ' SellOut_Quantity_YTD__c, SellOut_Tone_YTD__c, SellOut_wTax_YTD__c, SellOut_woTax_YTD__c, ND_1_YTD__c, WD_1_YTD__c, ND_2_YTD__c, WD_2_YTD__c, Average_Retail_Price_YTD__c,';
        q += ' SellOut_Quantity_12M__c, SellOut_Tone_12M__c, SellOut_wTax_12M__c, SellOut_woTax_12M__c, ND_1_12M__c, WD_1_12M__c, ND_2_12M__c, WD_2_12M__c, Average_Retail_Price_12M__c, Sequence_Type__c, Sequence_Number__c, Status__c';
        q += ' FROM Market_Data_Collection_Detail__c WHERE Status__c = \'Scan w/ success\' ';
        if(marketDetailIds != null && marketDetailIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(new List<Id>(marketDetailIds), '\',\'') +'\') ';
        }
        q += ' ORDER BY Sequence_Number__c NULLS LAST, Date_SSEQ0__c NULLS LAST, Date_SSEQ1__c NULLS LAST, Date_SSEQ2__c NULLS LAST, Date_SSEQ3__c NULLS LAST, Date_SSEQ4__c NULLS LAST, Date_SSEQ5__c NULLS LAST';
        this.query = q;
        // push inputs to log
        nb.logParameter('marketDetailIds', marketDetailIds);
        nb.logParameter('query', this.query);
    }
    
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Start Execute
    public void execute(Database.BatchableContext bc, List<Market_Data_Collection_Detail__c> scope) {
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> monthSet = new Set<Integer>();
        Set<Id> masterBUSet = new Set<Id>();
        Set<Id> buHeadSet = new Set<Id>();
        Set<Id> buDetailSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Set<Id> categorySet = new Set<Id>();
        Set<Id> oldMarketHeadIds = new Set<Id>();
        
        List<MarketDataCollectionDetailWrapper> marketDetailsWrapperList = new List<MarketDataCollectionDetailWrapper>();
        Map<String, MarketDataCollectionMonthlyWrapper> monthlyMarketDetailsMap = new Map<String, MarketDataCollectionMonthlyWrapper>();
        Map<String, Market_Data_Collection_Head__c> marketHeadMap = new Map<String, Market_Data_Collection_Head__c>();
        List<Market_Data_Collection_Detail__c> monthlyMarketDetailsList = new List<Market_Data_Collection_Detail__c>();
        Savepoint sp = Database.setSavepoint();
        try {
            for(Market_Data_Collection_Detail__c item : scope) {
                MarketDataCollectionDetailWrapper marketDetailWrapper = new MarketDataCollectionDetailWrapper(item);
                // fill years and months
                marketDetailWrapper.generateWeight();
                yearSet.addAll(marketDetailWrapper.yearSet);
                monthSet.addAll(marketDetailWrapper.monthSet);
                // fill categories, BUs, products
                if(item.Market_Data_Collection_Head__r.Master_BU__c != null && !masterBUSet.contains(item.Market_Data_Collection_Head__r.Master_BU__c)) {
                    masterBUSet.add(item.Market_Data_Collection_Head__r.Master_BU__c);
                }
                if(item.Market_Data_Collection_Head__r.Orga_HE__c != null && !categorySet.contains(item.Market_Data_Collection_Head__r.Orga_HE__c)) {
                    categorySet.add(item.Market_Data_Collection_Head__r.Orga_HE__c);
                }
                if(item.Market_Data_Collection_Head__r.Orga_BU__c != null && !buHeadSet.contains(item.Market_Data_Collection_Head__r.Orga_BU__c)) {
                    buHeadSet.add(item.Market_Data_Collection_Head__r.Orga_BU__c);
                }
                if(item.Orga_BU__c != null && !buDetailSet.contains(item.Orga_BU__c)) {
                    buDetailSet.add(item.Orga_BU__c);
                }
                if(item.Product__c != null && !productSet.contains(item.Product__c)) {
                    productSet.add(item.Product__c);
                }
                marketDetailsWrapperList.add(marketDetailWrapper);
            }
            // get calendar canvas
            Map<String, Calendar_Canvas__c> calendarCanvasMap = new Map<String, Calendar_Canvas__c>();
            for(Calendar_Canvas__c item : [SELECT Id, BU_Source__c, BU_Target__c, Starting_day__c, Ending_day__c, Year__c, First_day_of_the_year__c, Last_day_of_the_year__c,
                                           Weight_SEQ1__c, Weight_SEQ2__c, Weight_SEQ3__c, Weight_SEQ4__c, Weight_SEQ5__c, Weight_SEQ6__c, Weight_SEQ7__c
                                           FROM Calendar_Canvas__c
                                           WHERE Status__c = 'Open' AND BU_Source__c IN :masterBUSet AND Year__c IN :yearSet AND Calendar_type__c = 'Regular'])
            {
                String key = item.BU_Source__c + '' + item.Year__c;
                if(!calendarCanvasMap.containsKey(key)) {
                    calendarCanvasMap.put(key, item);
                }
            }
            // get old market head : Map<category+bu+seq+year, old marked head collection>
            Map<String, Market_Data_Collection_Head__c> oldMarketHeadMap = new Map<String, Market_Data_Collection_Head__c>();
            List<Market_Data_Collection_Head__c> oldMarketHeadList = [SELECT Id, Ext_Category_Name__c, Ext_BU_Name__c, Year__c, SEQ__c,
                                                                      Orga_BU__c, Orga_HE__c, Client__c,
                                                                      Flow_Type__c, Master_BU__c, Movement_Date__c, Origin_Type__c, Status__c
                                                                      FROM Market_Data_Collection_Head__c
                                                                      WHERE Orga_HE__c IN :categorySet AND Orga_BU__c IN :buHeadSet
                                                                      AND Year__c IN :yearSet AND SEQ__c IN :monthSet];
            if(!oldMarketHeadList.isEmpty()) {
                for(Market_Data_Collection_Head__c item : oldMarketHeadList) {
                    String key = item.Orga_HE__c + '' + item.Orga_BU__c + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.SEQ__c);
                    oldMarketHeadMap.put(key, item);
                    oldMarketHeadIds.add(item.Id);
                }
            }
            // get old market details(Monthly) : Map<category+bu+product+seq+year, old marked details collection>
            Map<String, Market_Data_Collection_Detail__c> oldMarketDetailsMap = new Map<String, Market_Data_Collection_Detail__c>();
            List<Market_Data_Collection_Detail__c> oldMarketDetailsList = [SELECT Id, Market_Data_Collection_Head__c, Orga_HE__c, Orga_BU__c, Product__c,
                                                                           Ext_Category_Name__c,Ext_BU_Name__c, Ext_Product_Name__c, Ext_Product_EAN__c, Year__c, SEQ__c, Ext_Brand_Name__c, Ext_Packaging__c,
                                                                           // SEQ Weekly
                                                                           Date_SSEQ0__c, Date_SSEQ1__c, Date_SSEQ2__c, Date_SSEQ3__c, Date_SSEQ4__c, Date_SSEQ5__c,
                                                                           Weight_SSEQ0__c, Weight_SSEQ1__c, Weight_SSEQ2__c, Weight_SSEQ3__c, Weight_SSEQ4__c, Weight_SSEQ5__c,
                                                                           SellOut_Quantity_SSEQ0__c, SellOut_Quantity_SSEQ1__c, SellOut_Quantity_SSEQ2__c, SellOut_Quantity_SSEQ3__c, SellOut_Quantity_SSEQ4__c, SellOut_Quantity_SSEQ5__c,
                                                                           SellOut_Tone_SSEQ0__c, SellOut_Tone_SSEQ1__c, SellOut_Tone_SSEQ2__c, SellOut_Tone_SSEQ3__c, SellOut_Tone_SSEQ4__c, SellOut_Tone_SSEQ5__c,
                                                                           SellOut_wTax_SSEQ0__c, SellOut_wTax_SSEQ1__c, SellOut_wTax_SSEQ2__c, SellOut_wTax_SSEQ3__c, SellOut_wTax_SSEQ4__c, SellOut_wTax_SSEQ5__c,
                                                                           SellOut_woTax_SSEQ0__c, SellOut_woTax_SSEQ1__c, SellOut_woTax_SSEQ2__c, SellOut_woTax_SSEQ3__c, SellOut_woTax_SSEQ4__c, SellOut_woTax_SSEQ5__c,
                                                                           ND_1_SSEQ0__c, ND_1_SSEQ1__c, ND_1_SSEQ2__c, ND_1_SSEQ3__c, ND_1_SSEQ4__c, ND_1_SSEQ5__c,
                                                                           ND_2_SSEQ0__c, ND_2_SSEQ1__c, ND_2_SSEQ2__c, ND_2_SSEQ3__c, ND_2_SSEQ4__c, ND_2_SSEQ5__c,
                                                                           WD_1_SSEQ0__c, WD_1_SSEQ1__c, WD_1_SSEQ2__c, WD_1_SSEQ3__c, WD_1_SSEQ4__c, WD_1_SSEQ5__c,
                                                                           WD_2_SSEQ0__c, WD_2_SSEQ1__c, WD_2_SSEQ2__c, WD_2_SSEQ3__c, WD_2_SSEQ4__c, WD_2_SSEQ5__c,
                                                                           //SEQ Monthly
                                                                           SellOut_Quantity_SEQ__c, SellOut_Tone_SEQ__c, SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, ND_1_SEQ__c, WD_1_SEQ__c, ND_2_SEQ__c, WD_2_SEQ__c, Average_Retail_Price_SEQ__c, Avg_Weekly_Sales_Ext_ClientBased__c,
                                                                           //YTD
                                                                           SellOut_Quantity_YTD__c, SellOut_Tone_YTD__c, SellOut_wTax_YTD__c, SellOut_woTax_YTD__c, ND_1_YTD__c, WD_1_YTD__c, ND_2_YTD__c, WD_2_YTD__c, Average_Retail_Price_YTD__c,
                                                                           //12M
                                                                           SellOut_Quantity_12M__c, SellOut_Tone_12M__c, SellOut_wTax_12M__c, SellOut_woTax_12M__c, ND_1_12M__c, WD_1_12M__c, ND_2_12M__c, WD_2_12M__c, Average_Retail_Price_12M__c, Sequence_Type__c, Status__c
                                                                           FROM Market_Data_Collection_Detail__c
                                                                           WHERE Market_Data_Collection_Head__c IN :oldMarketHeadIds
                                                                           AND Product__c IN :productSet
                                                                           AND Orga_BU__c IN :buDetailSet
                                                                           AND Sequence_Type__c = 'Month' AND Id NOT IN :scope];
            if(!oldMarketDetailsList.isEmpty()) {
                for(Market_Data_Collection_Detail__c item : oldMarketDetailsList) {
                    String key = item.Product__c + '' + item.Orga_HE__c + '' + item.Orga_BU__c + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.SEQ__c);
                    oldMarketDetailsMap.put(key, item);
                }
            }
            for(MarketDataCollectionDetailWrapper item : marketDetailsWrapperList) {
                for(String key : item.sequenceSet) {
                    Integer month = Integer.valueOf(key.split('-')[0]);
                    Integer year = Integer.valueOf(key.split('-')[1]);
                    MarketDataCollectionMonthlyWrapper monthlyWrapper;
                    String keyDetail = item.marketDetail.Product__c + '' + item.marketDetail.Orga_HE__c + '' + item.marketDetail.Orga_BU__c + '' + year + '' + month;
                    if(!monthlyMarketDetailsMap.containsKey(keyDetail)) {
                        monthlyWrapper = new MarketDataCollectionMonthlyWrapper(item, year, month);
                        // case monthly
                        if(item.isMonthly) {
                            if(item.movementDate.day() == 28) continue;
                            else if(item.movementDate.day() < 28 && item.movementDate.month() == month && item.movementDate.year() == year) {
                                Market_Data_Collection_Detail__c initialMarketDetail = item.marketDetail.clone(true);
                                monthlyWrapper.calculateMarketDetailMonthly(initialMarketDetail);
                                monthlyMarketDetailsList.add(initialMarketDetail);
                                continue;
                            }
                        }
                        // insert new market head if not exist
                        monthlyWrapper.generateMarketHead(oldMarketHeadMap);
                        // generate monthly market details
                        monthlyWrapper.generateMonthlyMarketDetail(oldMarketDetailsMap, calendarCanvasMap);
                        monthlyMarketDetailsMap.put(keyDetail, monthlyWrapper);
                        if(!marketHeadMap.containsKey(monthlyWrapper.keyHead) /*&& monthlyWrapper.marketHead.Id == null*/) {
                            marketHeadMap.put(monthlyWrapper.keyHead, monthlyWrapper.marketHead);
                        }
                    }
                }
            }
            // check security on Market_Data_Collection_Head__c fields
            String[] marketDataCollectionHeadFields = new String[] { NegoptimHelper.normalizeAPIName('Ext_BU_Name__c'),
                NegoptimHelper.normalizeAPIName('Ext_Category_Name__c'), NegoptimHelper.normalizeAPIName('Flow_Type__c'),
                NegoptimHelper.normalizeAPIName('Origin_Type__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Year__c'), NegoptimHelper.normalizeAPIName('Master_BU__c'),
                NegoptimHelper.normalizeAPIName('Movement_Date__c'), NegoptimHelper.normalizeAPIName('SEQ__c')};
            
            // check security on Market_Data_Collection_Detail__c fields
            String[] marketDataCollectionDetailsFields = new String[] { NegoptimHelper.normalizeAPIName('Ext_BU_Name__c'), NegoptimHelper.normalizeAPIName('Ext_Category_Name__c'),
                NegoptimHelper.normalizeAPIName('Ext_Product_EAN__c'), NegoptimHelper.normalizeAPIName('Ext_Product_Name__c'), NegoptimHelper.normalizeAPIName('Ext_Brand_Name__c'), NegoptimHelper.normalizeAPIName('Ext_Packaging__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_SEQ__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SEQ__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SEQ__c'),
                NegoptimHelper.normalizeAPIName('ND_1_SEQ__c'), NegoptimHelper.normalizeAPIName('WD_1_SEQ__c'), NegoptimHelper.normalizeAPIName('ND_2_SEQ__c'), NegoptimHelper.normalizeAPIName('WD_2_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Average_Retail_Price_SEQ__c'), NegoptimHelper.normalizeAPIName('Avg_Weekly_Sales_Ext_ClientBased__c'),				
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_YTD__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_YTD__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_YTD__c'),
                NegoptimHelper.normalizeAPIName('ND_1_YTD__c'), NegoptimHelper.normalizeAPIName('WD_1_YTD__c'),
                NegoptimHelper.normalizeAPIName('ND_2_YTD__c'), NegoptimHelper.normalizeAPIName('WD_2_YTD__c'), NegoptimHelper.normalizeAPIName('Average_Retail_Price_YTD__c'),				
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_12M__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_12M__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_12M__c'),
                NegoptimHelper.normalizeAPIName('ND_1_12M__c'), NegoptimHelper.normalizeAPIName('WD_1_12M__c'), NegoptimHelper.normalizeAPIName('ND_2_12M__c'), NegoptimHelper.normalizeAPIName('WD_2_12M__c'),
                NegoptimHelper.normalizeAPIName('Average_Retail_Price_12M__c'), NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('SEQ__c'), NegoptimHelper.normalizeAPIName('Year__c'),
                NegoptimHelper.normalizeAPIName('Date_SSEQ0__c'), NegoptimHelper.normalizeAPIName('Date_SSEQ1__c'), NegoptimHelper.normalizeAPIName('Date_SSEQ2__c'), NegoptimHelper.normalizeAPIName('Date_SSEQ3__c'), NegoptimHelper.normalizeAPIName('Date_SSEQ4__c'), NegoptimHelper.normalizeAPIName('Date_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('Weight_SSEQ0__c'), NegoptimHelper.normalizeAPIName('Weight_SSEQ1__c'), NegoptimHelper.normalizeAPIName('Weight_SSEQ2__c'), NegoptimHelper.normalizeAPIName('Weight_SSEQ3__c'), NegoptimHelper.normalizeAPIName('Weight_SSEQ4__c'), NegoptimHelper.normalizeAPIName('Weight_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ0__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ1__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ2__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ3__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ4__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ0__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ1__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ2__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ3__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ4__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ0__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ1__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ2__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ3__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ4__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('ND_1_SSEQ0__c'), NegoptimHelper.normalizeAPIName('ND_1_SSEQ1__c'), NegoptimHelper.normalizeAPIName('ND_1_SSEQ2__c'), NegoptimHelper.normalizeAPIName('ND_1_SSEQ3__c'), NegoptimHelper.normalizeAPIName('ND_1_SSEQ4__c'), NegoptimHelper.normalizeAPIName('ND_1_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('ND_2_SSEQ0__c'), NegoptimHelper.normalizeAPIName('ND_2_SSEQ1__c'), NegoptimHelper.normalizeAPIName('ND_2_SSEQ2__c'), NegoptimHelper.normalizeAPIName('ND_2_SSEQ3__c'), NegoptimHelper.normalizeAPIName('ND_2_SSEQ4__c'), NegoptimHelper.normalizeAPIName('ND_2_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('WD_1_SSEQ0__c'), NegoptimHelper.normalizeAPIName('WD_1_SSEQ1__c'), NegoptimHelper.normalizeAPIName('WD_1_SSEQ2__c'), NegoptimHelper.normalizeAPIName('WD_1_SSEQ3__c'), NegoptimHelper.normalizeAPIName('WD_1_SSEQ4__c'), NegoptimHelper.normalizeAPIName('WD_1_SSEQ5__c'),
                NegoptimHelper.normalizeAPIName('WD_2_SSEQ0__c'), NegoptimHelper.normalizeAPIName('WD_2_SSEQ1__c'), NegoptimHelper.normalizeAPIName('WD_2_SSEQ2__c'), NegoptimHelper.normalizeAPIName('WD_2_SSEQ3__c'), NegoptimHelper.normalizeAPIName('WD_2_SSEQ4__c'), NegoptimHelper.normalizeAPIName('WD_2_SSEQ5__c')};
                    
            String[] marketDataCollectionDetailsInsertedFields = new String[]{NegoptimHelper.normalizeAPIName('Market_Data_Collection_Head__c')};
            marketDataCollectionDetailsInsertedFields.addAll(marketDataCollectionDetailsFields);
                
            if(!monthlyMarketDetailsMap.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Market_Data_Collection_Head__c.SObjectType, marketDataCollectionHeadFields) &&
                   NegoptimHelper.checkCreatibility(Market_Data_Collection_Detail__c.SObjectType, marketDataCollectionDetailsInsertedFields) &&
                   NegoptimHelper.checkUpdatibility(Market_Data_Collection_Detail__c.SObjectType, marketDataCollectionDetailsFields))
                {
                    // insert market head
                    if(!marketHeadMap.isEmpty()) {
                        List<Database.UpsertResult> results = Database.upsert(marketHeadMap.values(), false);
                        nb.logResults(results, marketHeadMap.values());
                    }
                    for(MarketDataCollectionMonthlyWrapper item : monthlyMarketDetailsMap.values()) {
                        if(item.marketHead.Id != null) {
                            if(item.marketDetailMonthly.Market_Data_Collection_Head__c == null) item.marketDetailMonthly.Market_Data_Collection_Head__c = item.marketHead.Id;
                            monthlyMarketDetailsList.add(item.marketDetailMonthly);
                        }
                    }
                    // upsert monthly market data collection details
                    if(!monthlyMarketDetailsList.isEmpty()) {
                        List<Database.UpsertResult> resultsDetail = Database.upsert(monthlyMarketDetailsList, false);
                        nb.logResults(resultsDetail, monthlyMarketDetailsList);
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
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper for weekly market details */
    public class MarketDataCollectionDetailWrapper {
        private Market_Data_Collection_Detail__c marketDetail {get; set;}
        private Set<Integer> monthSet;
        private Set<Integer> yearSet;
        private Set<String> sequenceSet;
        // case Monthly
        private date movementDate;
        private Integer previousMonth;
        private Integer previousYear;
        // case Weekly
        private date dateSSEQ0;
        private date dateSSEQ1;
        private date dateSSEQ2;
        private date dateSSEQ3;
        private decimal WeightSSEQ0;
        private decimal WeightSSEQ1;
        private decimal WeightSSEQ2;
        private decimal WeightSSEQ3;
        private Integer previousSEQ0;
        private Integer previousYear0;
        private Integer previousSEQWeight0;
        private Integer previousSEQ1;
        private Integer previousYear1;
        private Integer previousSEQWeight1;
        private Integer previousSEQ2;
        private Integer previousYear2;
        private Integer previousSEQWeight2;
        private Integer previousSEQ3;
        private Integer previousYear3;
        private Integer previousSEQWeight3;        
        public Boolean isWeekly {
            get {
                return this.marketDetail.Sequence_Type__c == 'Week';
            }
            set;
        }
        public Boolean isMonthly {
            get {
                return this.marketDetail.Sequence_Type__c == 'Month';
            }
            set;
        }
        
        public MarketDataCollectionDetailWrapper(Market_Data_Collection_Detail__c marketDetail) {
            this.marketDetail = marketDetail;
            this.monthSet = new Set<Integer>();
            this.yearSet = new Set<Integer>();
            this.sequenceSet = new Set<String>();
        }
        
        public void generateWeight() {
            this.movementDate = this.marketDetail.Market_Data_Collection_Head__r.Movement_Date__c;
            // case weekly
            if(this.isWeekly) {
                this.dateSSEQ0 = this.marketDetail.Date_SSEQ0__c;
                this.dateSSEQ1 = this.marketDetail.Date_SSEQ1__c;
                this.dateSSEQ2 = this.marketDetail.Date_SSEQ2__c;
                this.dateSSEQ3 = this.marketDetail.Date_SSEQ3__c;
                
                if(this.dateSSEQ0 != null) {
                    fillSequences(this.dateSSEQ0.month(), this.dateSSEQ0.year());
                    if(this.dateSSEQ0.month() != this.dateSSEQ0.toStartofWeek().month()) {
                        Date weekStartDate = this.dateSSEQ0.toStartofWeek();
                        this.previousSEQ0 = weekStartDate.month();
                        this.previousYear0 = weekStartDate.year();
                        this.previousSEQWeight0 = weekStartDate.daysBetween(this.dateSSEQ0) + 1 - this.dateSSEQ0.day();
                        this.WeightSSEQ0 = this.dateSSEQ0.day();
                        fillSequences(this.previousSEQ0, this.previousYear0);
                    } else if(this.dateSSEQ0 != null) {
                        this.WeightSSEQ0 = 7;
                    }
                }
                if(this.dateSSEQ1 != null) {
                    fillSequences(this.dateSSEQ1.month(), this.dateSSEQ1.year());
                    if(this.dateSSEQ1.month() != this.dateSSEQ1.toStartofWeek().month()) {
                        Date weekStartDate = this.dateSSEQ1.toStartofWeek();
                        this.previousSEQ1 = weekStartDate.month();
                        this.previousYear1 = weekStartDate.year();
                        this.previousSEQWeight1 = weekStartDate.daysBetween(this.dateSSEQ1) + 1 - this.dateSSEQ1.day();
                        this.WeightSSEQ1 = this.dateSSEQ1.day();
                        fillSequences(this.previousSEQ1, this.previousYear1);
                    } else if(this.dateSSEQ1 != null) {
                        this.WeightSSEQ1 = 7;
                    }
                }
                if(this.dateSSEQ2 != null) {
                    fillSequences(this.dateSSEQ2.month(), this.dateSSEQ2.year());
                    if(this.dateSSEQ2.month() != this.dateSSEQ2.toStartofWeek().month()) {
                        Date weekStartDate = this.dateSSEQ2.toStartofWeek();
                        this.previousSEQ2 = weekStartDate.month();
                        this.previousYear2 = weekStartDate.year();
                        this.previousSEQWeight2 = weekStartDate.daysBetween(this.dateSSEQ2) + 1 - this.dateSSEQ2.day();
                        this.WeightSSEQ2 = this.dateSSEQ2.day();
                        fillSequences(this.previousSEQ2, this.previousYear2);
                    } else if(this.dateSSEQ2 != null) {
                        this.WeightSSEQ2 = 7;
                    }
                }
                if(this.dateSSEQ3 != null) {
                    fillSequences(this.dateSSEQ3.month(), this.dateSSEQ3.year());
                    if(this.dateSSEQ3.month() != this.dateSSEQ3.toStartofWeek().month()) {
                        Date weekStartDate = this.dateSSEQ3.toStartofWeek();
                        this.previousSEQ3 = weekStartDate.month();
                        this.previousYear3 = weekStartDate.year();
                        this.previousSEQWeight3 = weekStartDate.daysBetween(this.dateSSEQ3) + 1 - this.dateSSEQ3.day();
                        this.WeightSSEQ3 = this.dateSSEQ3.day();
                        fillSequences(this.previousSEQ3, this.previousYear3);
                    } else if(this.dateSSEQ3 != null) {
                        this.WeightSSEQ3 = 7;
                    }
                }
            } else if(this.isMonthly) {
                // case monthly
                if(this.movementDate != null) {
                    fillSequences(this.movementDate.month(), this.movementDate.year());
                    if(this.movementDate.day() < 28) {
                        this.previousMonth = this.movementDate.month() == 1 ? 12 : this.movementDate.month() - 1;
                        this.previousYear = this.movementDate.month() == 1 ? this.movementDate.year() - 1 : this.movementDate.year();
                        fillSequences(this.previousMonth, this.previousYear);
                    }
                }
            }
            // fill years, months
            if(!monthSet.contains(Integer.valueOf(this.marketDetail.SEQ__c))) {
                monthSet.add(Integer.valueOf(this.marketDetail.SEQ__c));
            }
            if(!yearSet.contains(Integer.valueOf(this.marketDetail.Year__c))) {
                yearSet.add(Integer.valueOf(this.marketDetail.Year__c));
            }
        }
        
        private void fillSequences(Integer month, Integer year) {
            if(!this.sequenceSet.contains(month + '-' + year)) {
                this.sequenceSet.add(month + '-' + year);                    
            }
            if(!this.monthSet.contains(month)) {
                this.monthSet.add(month);
            }
            if(!this.yearSet.contains(year)) {
                this.yearSet.add(year);
            }
        }
    }
    
    /* Wrapper MarketDataCollectionMonthlyWrapper */
    public class MarketDataCollectionMonthlyWrapper {
        private Market_Data_Collection_Head__c marketHead {get; set;}
        private MarketDataCollectionDetailWrapper wMarketDetail {get; set;}
        private Market_Data_Collection_Detail__c marketDetailMonthly {get; set;}
        private Integer year {get; set;}
        private Integer month {get; set;}
        private String keyHead {
            get {
                return wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Orga_HE__c + '' +
                    wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Orga_BU__c + '' + year + '' + month;
            }
            set;
        }
        private String keyDetail {
            get {
                return wMarketDetail.marketDetail.Product__c + '' + wMarketDetail.marketDetail.Orga_HE__c + '' +
                    wMarketDetail.marketDetail.Orga_BU__c + '' + year + '' + month;
            }
            set;
        }

        public MarketDataCollectionMonthlyWrapper(MarketDataCollectionDetailWrapper marketDetail, Integer year, Integer month) {
            this.wMarketDetail = marketDetail;
            this.year = year;
            this.month = month;
        }
        
        private void generateMarketHead(Map<String, Market_Data_Collection_Head__c> oldMarketHeadMap) {
            // fill market head
            if(oldMarketHeadMap.containsKey(keyHead)) {
                this.marketHead = oldMarketHeadMap.get(keyHead);
            } else {
                this.marketHead = new Market_Data_Collection_Head__c(Ext_BU_Name__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Ext_BU_Name__c,
                                                                     Ext_Category_Name__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Ext_Category_Name__c,
                                                                     Flow_Type__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Flow_Type__c,
                                                                     Master_BU__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Master_BU__c,
                                                                     Movement_Date__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Movement_Date__c,
                                                                     Orga_BU__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Orga_BU__c,
                                                                     Orga_HE__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Orga_HE__c,
                                                                     Client__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Client__c,
                                                                     Origin_Type__c = 'CSV', SEQ__c = this.month, Year__c = this.year);
                oldMarketHeadMap.put(keyHead, this.marketHead);
            }
            this.marketHead.Status__c = 'Scan w/ success';
            this.marketHead.Last_Scan_Date__c = System.now();
        }
        
        private void generateMonthlyMarketDetail(Map<String, Market_Data_Collection_Detail__c> oldMarketDetailsMap, Map<String, Calendar_Canvas__c> calendarCanvasMap) {
            if(oldMarketDetailsMap.containsKey(keyDetail)) {
                this.marketDetailMonthly = oldMarketDetailsMap.get(keyDetail);
            } else {
                this.marketDetailMonthly = new Market_Data_Collection_Detail__c(////Ext_BU_Name__c = wMarketDetail.marketDetail.Ext_BU_Name__c, Ext_Category_Name__c = wMarketDetail.marketDetail.Ext_Category_Name__c,
                                                                                Ext_Product_Name__c = wMarketDetail.marketDetail.Ext_Product_Name__c, Ext_Product_EAN__c = wMarketDetail.marketDetail.Ext_Product_EAN__c,
                                                                                Ext_Brand_Name__c = wMarketDetail.marketDetail.Ext_Brand_Name__c, Ext_Packaging__c = wMarketDetail.marketDetail.Ext_Packaging__c,
                                                                                Orga_HE__c = wMarketDetail.marketDetail.Orga_HE__c, Orga_BU__c = wMarketDetail.marketDetail.Orga_BU__c,
                                                                                Product__c = wMarketDetail.marketDetail.Product__c, SEQ__c = month, Year__c = year, Sequence_Type__c = 'Month');
                oldMarketDetailsMap.put(keyDetail, this.marketDetailMonthly);
            }
            this.marketDetailMonthly.Status__c = 'Scan w/ success';
            this.marketDetailMonthly.Last_Scan_Date__c = System.now();
            
            if(this.marketHead.Id != null && this.marketDetailMonthly.Market_Data_Collection_Head__c == null) {
                this.marketDetailMonthly.Market_Data_Collection_Head__c = this.marketHead.Id;
            }
            // case weekly
            if(wMarketDetail.isWeekly) {
                calculateMarketDetailWeekly(calendarCanvasMap);
            } else if(wMarketDetail.isMonthly) {
                // case monthly
                calculateMarketDetailMonthly(this.marketDetailMonthly);
            }
        }
        
        // case weekly: update values
        private void calculateMarketDetailWeekly(Map<String, Calendar_Canvas__c> calendarCanvasMap) {            
            // SEQ0
            if(this.wMarketDetail.dateSSEQ0 != null && this.month == this.wMarketDetail.dateSSEQ0.month() && this.year == this.wMarketDetail.dateSSEQ0.year()) {
                updateMonthlySequences(wMarketDetail.dateSSEQ0, wMarketDetail.WeightSSEQ0, 0);
            }
            // previous SEQ0
            if(this.wMarketDetail.previousSEQ0 != null && this.month == this.wMarketDetail.previousSEQ0 && year == this.wMarketDetail.previousYear0) {
                updateMonthlySequences(wMarketDetail.dateSSEQ0, wMarketDetail.previousSEQWeight0, 0);
            }
            // SEQ1
            if(this.wMarketDetail.dateSSEQ1 != null && this.month == this.wMarketDetail.dateSSEQ1.month() && year == this.wMarketDetail.dateSSEQ1.year()) {
                updateMonthlySequences(wMarketDetail.dateSSEQ1, wMarketDetail.WeightSSEQ1, 1);
            }
            // previous SEQ1
            if(this.wMarketDetail.previousSEQ1 != null && this.month == this.wMarketDetail.previousSEQ1 && year == this.wMarketDetail.previousYear1) {
                updateMonthlySequences(wMarketDetail.dateSSEQ1, wMarketDetail.previousSEQWeight1, 1);
            }
            // SEQ2
            if(this.wMarketDetail.dateSSEQ2 != null && this.month == this.wMarketDetail.dateSSEQ2.month() && year == this.wMarketDetail.dateSSEQ2.year()) {
                updateMonthlySequences(wMarketDetail.dateSSEQ2, wMarketDetail.WeightSSEQ2, 2);
            }
            // previous SEQ2
            if(this.wMarketDetail.previousSEQ2 != null && this.month == this.wMarketDetail.previousSEQ2 && year == this.wMarketDetail.previousYear2) {
                updateMonthlySequences(wMarketDetail.dateSSEQ2, wMarketDetail.previousSEQWeight2, 2);
            }
            // SEQ3
            if(this.wMarketDetail.dateSSEQ3 != null && this.month == this.wMarketDetail.dateSSEQ3.month() && year == this.wMarketDetail.dateSSEQ3.year()) {
                updateMonthlySequences(wMarketDetail.dateSSEQ3, wMarketDetail.WeightSSEQ3, 3);
            }
            // previous SEQ3
            if(this.wMarketDetail.previousSEQ3 != null && this.month == this.wMarketDetail.previousSEQ3 && year == this.wMarketDetail.previousYear3) {
                updateMonthlySequences(wMarketDetail.dateSSEQ3, wMarketDetail.previousSEQWeight3, 3);
            }
            
            // calculate total
            Decimal sellOutQuantitySEQ = 0, sellOutToneSEQ = 0, sellOutwTaxSEQ = 0, sellOutwoTaxSEQ = 0, ND1SEQ = 0, WD1SEQ = 0, ND2SEQ = 0, WD2SEQ = 0;
            Decimal totalWeightSEQ = 0;
            for(Integer i = 0; i <= 5; i++) {
                if(marketDetailMonthly.get('Date_SSEQ'+ i +'__c') != null && marketDetailMonthly.get('Weight_SSEQ'+ i +'__c') != null) {
                    Decimal WeightSEQ = Decimal.valueOf(String.valueOf(marketDetailMonthly.get('Weight_SSEQ'+ i +'__c')));
                    Date dateSEQ = Date.valueOf(marketDetailMonthly.get('Date_SSEQ'+ i +'__c'));
                    Decimal sellOutQuantity = marketDetailMonthly.get('SellOut_Quantity_SSEQ'+ i +'__c') != null ? Decimal.valueOf(String.valueOf(marketDetailMonthly.get('SellOut_Quantity_SSEQ'+ i +'__c'))) : 0;
                    
                    // get calendar canvas
                    String calendarCanvasKey = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Master_BU__c + '' + dateSEQ.year();
                    Calendar_Canvas__c calendarCanvas;
                    if(calendarCanvasMap.containsKey(calendarCanvasKey)) {
                        calendarCanvas = calendarCanvasMap.get(calendarCanvasKey);
                    } else {
                        // create default calendar canvas if not found for BU source and year
                        Decimal weight = Decimal.valueOf(100)/7;
                        calendarCanvas = new Calendar_Canvas__c(BU_Source__c = wMarketDetail.marketDetail.Market_Data_Collection_Head__r.Master_BU__c, Year__c = this.year, Starting_day__c = null,
                                                                Weight_SEQ1__c = weight, Weight_SEQ2__c = weight, Weight_SEQ3__c = weight, Weight_SEQ4__c = weight, Weight_SEQ5__c = weight,
                                                                Weight_SEQ6__c = weight, Weight_SEQ7__c = weight, Status__c = 'Open');
                    }
                    Decimal calendarCanvasWeight = 7;
                    // calculate weight using calendar canvas
                    if(WeightSEQ != 7) {
                        // Weight = 7x(Weight_SEQ1__c + Weight_SEQ2__c + Weight_SEQ3__c + Weight_SEQ4__c)
                        calendarCanvasWeight = 7*getWeightByCalendarCanvas(dateSEQ, calendarCanvas)/100;
                        this.marketDetailMonthly.put('Weight_SSEQ'+ i +'__c', calendarCanvasWeight);
                    }
                    sellOutQuantitySEQ += calendarCanvasWeight * sellOutQuantity/7;
                    if(marketDetailMonthly.get('SellOut_Tone_SSEQ'+ i +'__c') != null) {
                        sellOutToneSEQ += calendarCanvasWeight * Decimal.valueOf(String.valueOf(marketDetailMonthly.get('SellOut_Tone_SSEQ'+ i +'__c')))/7;
                    }
                    if(marketDetailMonthly.get('SellOut_wTax_SSEQ'+ i +'__c') != null) {
                        sellOutwTaxSEQ += calendarCanvasWeight * Decimal.valueOf(String.valueOf(marketDetailMonthly.get('SellOut_wTax_SSEQ'+ i +'__c')))/7;
                    }
                    if(marketDetailMonthly.get('SellOut_woTax_SSEQ'+ i +'__c') != null) {
                        sellOutwoTaxSEQ += calendarCanvasWeight * Decimal.valueOf(String.valueOf(marketDetailMonthly.get('SellOut_woTax_SSEQ'+ i +'__c')))/7;
                    }
                    // DN/DV Diffusion = last value in last week
                    if(marketDetailMonthly.get('ND_1_SSEQ'+ i +'__c') != null) {
                        ND1SEQ = Decimal.valueOf(String.valueOf(marketDetailMonthly.get('ND_1_SSEQ'+ i +'__c')));
                    }
                    if(marketDetailMonthly.get('WD_1_SSEQ'+ i +'__c') != null) {
                        WD1SEQ = Decimal.valueOf(String.valueOf(marketDetailMonthly.get('WD_1_SSEQ'+ i +'__c')));
                    }
                    // DN/DV vendante = moyenne
                    if(sellOutQuantity > 0) {
                        if(marketDetailMonthly.get('ND_2_SSEQ'+ i +'__c') != null) {
                            ND2SEQ += calendarCanvasWeight * Decimal.valueOf(String.valueOf(marketDetailMonthly.get('ND_2_SSEQ'+ i +'__c')));
                        }
                        if(marketDetailMonthly.get('WD_2_SSEQ'+ i +'__c') != null) {
                            WD2SEQ += calendarCanvasWeight * Decimal.valueOf(String.valueOf(marketDetailMonthly.get('WD_2_SSEQ'+ i +'__c')));
                        }
                        totalWeightSEQ += calendarCanvasWeight;
                    }
                }
            }
            //SEQ
            marketDetailMonthly.SellOut_Quantity_SEQ__c = sellOutQuantitySEQ; // Ventes UC
            marketDetailMonthly.SellOut_Tone_SEQ__c = sellOutToneSEQ; // Ventes Volume
            marketDetailMonthly.SellOut_wTax_SEQ__c = sellOutwTaxSEQ; // Ventes Valeur
            marketDetailMonthly.SellOut_woTax_SEQ__c = sellOutwoTaxSEQ;
            marketDetailMonthly.ND_1_SEQ__c = ND1SEQ; // DN Diffusion
            marketDetailMonthly.WD_1_SEQ__c = WD1SEQ; // DV Diffusion
            marketDetailMonthly.ND_2_SEQ__c = totalWeightSEQ > 0 ? ND2SEQ/totalWeightSEQ : 0; // DN
            marketDetailMonthly.WD_2_SEQ__c = totalWeightSEQ > 0 ? WD2SEQ/totalWeightSEQ : 0; // DV
            // calculate weight monthly
            calculateMarketDetailMonthly(marketDetailMonthly);
        }
        
        // calculate weekly weight
        private Decimal getWeightByCalendarCanvas(Date dateSEQ, Calendar_Canvas__c calendarCanvas) {
            Map<String, Integer> dayNamesMap = new Map<String, Integer> {'Sunday'=>1, 'Monday'=>2, 'Tuesday'=>3, 'Wednesday'=>4, 'Thursday'=>5, 'Friday'=>6, 'Saturday'=>7};
                Map<Integer, String> daySequencesMap = new Map<Integer, String> {1=>'Sunday', 2=>'Monday', 3=>'Tuesday', 4=>'Wednesday', 5=>'Thursday', 6=>'Friday', 7=>'Saturday'};
                    Map<String, Integer> calendarCanvasDaysMap = new Map<String, Integer>();
            Decimal calendarCanvasWeight = 0; DateTime sequenceStartDate, sequenceEndDate;
            if(dateSEQ.month() == this.month) {
                sequenceStartDate = Date.newInstance(dateSEQ.year(), dateSEQ.month(), 1);
                sequenceEndDate = dateSEQ;
            } else if(dateSEQ.toStartofWeek().month() == this.month) {
                sequenceStartDate = dateSEQ.toStartofWeek();
                Integer numberOfDays = Date.daysInMonth(sequenceStartDate.year(), sequenceStartDate.month());
                sequenceEndDate = Date.newInstance(sequenceStartDate.year(), sequenceStartDate.month(), numberOfDays);
            }
            String startingDay;
            if(calendarCanvas.Starting_day__c != null) {
                startingDay = calendarCanvas.Starting_day__c;
            } else {
                DateTime startWeekDate = dateSEQ.toStartofWeek();
                startingDay = startWeekDate.format('EEEE');
            }
            // fill week days from startingDay
            if(startingDay != null) {
                calendarCanvasDaysMap.put(startingDay, 1);
                Integer daySequence = dayNamesMap.get(startingDay);
                for(Integer i = 2; i <= 7; i++) {
                    daySequence = daySequence + 1;
                    String nextDay = daySequencesMap.get(daySequence);
                    if(String.isBlank(nextDay)) {
                        daySequence = 1;
                        nextDay = daySequencesMap.get(daySequence);
                    }
                    calendarCanvasDaysMap.put(nextDay, i);
                }
            }
            if(sequenceStartDate != null && sequenceEndDate != null) {
                Integer sequence = 0;
                for(Integer i = sequenceStartDate.day(); i <= sequenceEndDate.day(); i++) {
                    // get Day name by sequence date
                    String sequenceStartDay = sequenceStartDate.addDays(sequence).format('EEEE');
                    if(calendarCanvasDaysMap.containsKey(sequenceStartDay)) {
                        Integer sequenceNumber = calendarCanvasDaysMap.get(sequenceStartDay);
                        if(calendarCanvas.get('Weight_SEQ'+ sequenceNumber +'__c') != null) {
                            calendarCanvasWeight += Decimal.valueOf(String.valueOf(calendarCanvas.get('Weight_SEQ'+ sequenceNumber +'__c')));
                        }
                    }
                    sequence++;
                }
            }
            return calendarCanvasWeight;
        }
        
        // case weekly: update monthly sequences values
        private void updateMonthlySequences(Date dateSSEQ, Decimal WeightSSEQ, Integer sequenceNumber) {
            Boolean sequenceExist = false;
            for(Integer i = 0; i <= 5; i++) {
                if(this.marketDetailMonthly.get('Date_SSEQ'+ i +'__c') != null && Date.valueOf(this.marketDetailMonthly.get('Date_SSEQ'+ i +'__c')) == dateSSEQ) {
                    this.marketDetailMonthly.put('Date_SSEQ'+ i +'__c', dateSSEQ);
                    this.marketDetailMonthly.put('Weight_SSEQ'+ i +'__c', WeightSSEQ);
                    this.marketDetailMonthly.put('SellOut_Quantity_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_Quantity_SSEQ'+ sequenceNumber +'__c'));
                    this.marketDetailMonthly.put('SellOut_Tone_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_Tone_SSEQ'+ sequenceNumber +'__c'));
                    this.marketDetailMonthly.put('SellOut_wTax_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_wTax_SSEQ'+ sequenceNumber +'__c'));
                    this.marketDetailMonthly.put('SellOut_woTax_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_woTax_SSEQ'+ sequenceNumber +'__c'));
                    this.marketDetailMonthly.put('ND_1_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('ND_1_SSEQ'+ sequenceNumber +'__c'));
                    this.marketDetailMonthly.put('ND_2_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('ND_2_SSEQ'+ sequenceNumber +'__c'));
                    this.marketDetailMonthly.put('WD_1_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('WD_1_SSEQ'+ sequenceNumber +'__c'));
                    this.marketDetailMonthly.put('WD_2_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('WD_2_SSEQ'+ sequenceNumber +'__c'));
                    sequenceExist = true;
                    break;
                }
            }
            if(!sequenceExist) {
                for(Integer i = 0; i <= 5; i++) {
                    if(this.marketDetailMonthly.get('Date_SSEQ'+ i +'__c') == null) {
                        this.marketDetailMonthly.put('Date_SSEQ'+ i +'__c', dateSSEQ);
                        this.marketDetailMonthly.put('Weight_SSEQ'+ i +'__c', WeightSSEQ);
                        this.marketDetailMonthly.put('SellOut_Quantity_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_Quantity_SSEQ'+ sequenceNumber +'__c'));
                        this.marketDetailMonthly.put('SellOut_Tone_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_Tone_SSEQ'+ sequenceNumber +'__c'));
                        this.marketDetailMonthly.put('SellOut_wTax_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_wTax_SSEQ'+ sequenceNumber +'__c'));
                        this.marketDetailMonthly.put('SellOut_woTax_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('SellOut_woTax_SSEQ'+ sequenceNumber +'__c'));
                        this.marketDetailMonthly.put('ND_1_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('ND_1_SSEQ'+ sequenceNumber +'__c'));
                        this.marketDetailMonthly.put('ND_2_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('ND_2_SSEQ'+ sequenceNumber +'__c'));
                        this.marketDetailMonthly.put('WD_1_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('WD_1_SSEQ'+ sequenceNumber +'__c'));
                        this.marketDetailMonthly.put('WD_2_SSEQ'+ i +'__c', wMarketDetail.marketDetail.get('WD_2_SSEQ'+ sequenceNumber +'__c'));
                        break;
                    }
                }
            }
        }
        
        // case monthly: update values
        public void calculateMarketDetailMonthly(Market_Data_Collection_Detail__c marketDetail) {
            Decimal WeightMonth = 0;
            if(wMarketDetail.movementDate.day() < 28) {
                if(wMarketDetail.movementDate.month() == month) WeightMonth = Decimal.valueOf(wMarketDetail.movementDate.day())/28;
                if(wMarketDetail.movementDate.month() != month) WeightMonth = Decimal.valueOf(28 - wMarketDetail.movementDate.day())/28;
            }
            if(wMarketDetail.isMonthly) {
                //SEQ
                marketDetail.SellOut_Quantity_SEQ__c = this.wMarketDetail.marketDetail.SellOut_Quantity_SEQ__c != null ? this.wMarketDetail.marketDetail.SellOut_Quantity_SEQ__c * WeightMonth : null; // Ventes UC
                marketDetail.SellOut_Tone_SEQ__c = this.wMarketDetail.marketDetail.SellOut_Tone_SEQ__c != null ? this.wMarketDetail.marketDetail.SellOut_Tone_SEQ__c * WeightMonth : null; // Ventes Volume
                marketDetail.SellOut_wTax_SEQ__c = this.wMarketDetail.marketDetail.SellOut_wTax_SEQ__c != null ? this.wMarketDetail.marketDetail.SellOut_wTax_SEQ__c * WeightMonth : null; // Ventes Valeur
                marketDetail.SellOut_woTax_SEQ__c = this.wMarketDetail.marketDetail.SellOut_woTax_SEQ__c != null ? this.wMarketDetail.marketDetail.SellOut_woTax_SEQ__c * WeightMonth : null;
                marketDetail.ND_1_SEQ__c = this.wMarketDetail.marketDetail.ND_1_SEQ__c; // DN Diffusion
                marketDetail.WD_1_SEQ__c = this.wMarketDetail.marketDetail.WD_1_SEQ__c; // DV Diffusion
                marketDetail.ND_2_SEQ__c = this.wMarketDetail.marketDetail.ND_2_SEQ__c != null ? this.wMarketDetail.marketDetail.ND_2_SEQ__c * WeightMonth : null; // DN
                marketDetail.WD_2_SEQ__c = this.wMarketDetail.marketDetail.WD_2_SEQ__c != null ? this.wMarketDetail.marketDetail.WD_2_SEQ__c * WeightMonth : null; // DV
            } else if(wMarketDetail.isWeekly) {
                //SEQ
                marketDetail.SellOut_Quantity_SEQ__c = marketDetail.SellOut_Quantity_SEQ__c * WeightMonth; // Ventes UC
                marketDetail.SellOut_Tone_SEQ__c = marketDetail.SellOut_Tone_SEQ__c * WeightMonth; // Ventes Volume
                marketDetail.SellOut_wTax_SEQ__c = marketDetail.SellOut_wTax_SEQ__c * WeightMonth; // Ventes Valeur
                marketDetail.SellOut_woTax_SEQ__c = marketDetail.SellOut_woTax_SEQ__c * WeightMonth;
                marketDetail.ND_2_SEQ__c = marketDetail.ND_2_SEQ__c * WeightMonth; // DN
                marketDetail.WD_2_SEQ__c = marketDetail.WD_2_SEQ__c * WeightMonth; // DV
            }
            //YTD
            marketDetail.SellOut_Quantity_YTD__c = this.wMarketDetail.marketDetail.SellOut_Quantity_YTD__c != null ? this.wMarketDetail.marketDetail.SellOut_Quantity_YTD__c * WeightMonth : null;
            marketDetail.SellOut_Tone_YTD__c = this.wMarketDetail.marketDetail.SellOut_Quantity_YTD__c != null ? this.wMarketDetail.marketDetail.SellOut_Quantity_YTD__c * WeightMonth : null;
            marketDetail.SellOut_wTax_YTD__c = this.wMarketDetail.marketDetail.SellOut_wTax_YTD__c != null ? this.wMarketDetail.marketDetail.SellOut_wTax_YTD__c * WeightMonth : null;
            marketDetail.SellOut_woTax_YTD__c = this.wMarketDetail.marketDetail.SellOut_woTax_YTD__c != null ? this.wMarketDetail.marketDetail.SellOut_woTax_YTD__c * WeightMonth : null;
            marketDetail.ND_1_YTD__c = this.wMarketDetail.marketDetail.ND_1_YTD__c;
            marketDetail.WD_1_YTD__c = this.wMarketDetail.marketDetail.WD_1_YTD__c;
            marketDetail.ND_2_YTD__c = this.wMarketDetail.marketDetail.ND_2_YTD__c != null ? this.wMarketDetail.marketDetail.ND_2_YTD__c * WeightMonth : null;
            marketDetail.WD_2_YTD__c = this.wMarketDetail.marketDetail.WD_2_YTD__c != null ? this.wMarketDetail.marketDetail.WD_2_YTD__c * WeightMonth : null;
            marketDetail.Average_Retail_Price_YTD__c = this.wMarketDetail.marketDetail.Average_Retail_Price_YTD__c != null ? this.wMarketDetail.marketDetail.Average_Retail_Price_YTD__c * WeightMonth : null;
            //12M
            marketDetail.SellOut_Quantity_12M__c = this.wMarketDetail.marketDetail.SellOut_Quantity_12M__c != null ? this.wMarketDetail.marketDetail.SellOut_Quantity_12M__c * WeightMonth : null;
            marketDetail.SellOut_Tone_12M__c = this.wMarketDetail.marketDetail.SellOut_Tone_12M__c != null ? this.wMarketDetail.marketDetail.SellOut_Tone_12M__c * WeightMonth : null;
            marketDetail.SellOut_wTax_12M__c = this.wMarketDetail.marketDetail.SellOut_wTax_12M__c != null ? this.wMarketDetail.marketDetail.SellOut_wTax_12M__c * WeightMonth : null;
            marketDetail.SellOut_woTax_12M__c = this.wMarketDetail.marketDetail.SellOut_woTax_12M__c != null ? this.wMarketDetail.marketDetail.SellOut_woTax_12M__c * WeightMonth : null;
            marketDetail.ND_1_12M__c = this.wMarketDetail.marketDetail.ND_1_12M__c;
            marketDetail.WD_1_12M__c = this.wMarketDetail.marketDetail.WD_1_12M__c;
            marketDetail.ND_2_12M__c = this.wMarketDetail.marketDetail.ND_2_12M__c != null ? this.wMarketDetail.marketDetail.ND_2_12M__c * WeightMonth : null;
            marketDetail.WD_2_12M__c = this.wMarketDetail.marketDetail.WD_2_12M__c != null ? this.wMarketDetail.marketDetail.WD_2_12M__c * WeightMonth : null;
            marketDetail.Average_Retail_Price_12M__c = this.wMarketDetail.marketDetail.Average_Retail_Price_12M__c != null ? this.wMarketDetail.marketDetail.Average_Retail_Price_12M__c * WeightMonth : null;
        }
    }
}