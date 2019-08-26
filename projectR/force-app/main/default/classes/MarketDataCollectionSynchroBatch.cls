/*
 * Synchro market data collection.
 */ 
global with sharing class MarketDataCollectionSynchroBatch implements Database.Batchable<SObject>, Database.Stateful {
    private NegoptimBatch nb;
    private String query;
    private final Date selectedDate;
    private Set<Id> marketHeadSynchroIds;
    
    /* Constructor */
    public MarketDataCollectionSynchroBatch(String startedFrom, List<Id> ids, Date d) {
        this.nb = new NegoptimBatch('MarketDataCollectionSynchroBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.selectedDate = d;
        this.marketHeadSynchroIds = new Set<Id>();
        
        String q = ' SELECT Id, Name, Market_Data_Collection_Head__c, Action_Done__c, Action_Todo__c, Status__c, SEQ__c, Year__c,';
        q += ' Orga_HE__c, Product__c, Orga_BU__c, Orga_BU__r.IsMasterBU__c, Ext_Product_Code__c, Ext_Product_Name__c, Sequence_Number__c, Sequence_Type__c,';
        q += ' Market_Data_Collection_Head__r.Client__c, Market_Data_Collection_Head__r.Master_BU__c,';
        q += ' Market_Data_Collection_Head__r.Orga_BU__c, Market_Data_Collection_Head__r.Orga_HE__c,';
        q += ' Market_Data_Collection_Head__r.Orga_BU__r.Format_Origin__c, Avg_Weekly_Sales_Ext_ClientBased__c, Avg_Weekly_Sales_Ext_MarketBased__c,';
        q += ' ND_1_12M__c, ND_1_SEQ__c, ND_1_YTD__c, ND_2_12M__c, ND_2_SEQ__c, ND_2_YTD__c,';
        q += ' WD_1_12M__c, WD_1_SEQ__c, WD_1_YTD__c, WD_2_12M__c, WD_2_SEQ__c, WD_2_YTD__c,';
        q += ' SellOut_Quantity_SEQ__c, SellOut_Tone_SEQ__c, SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, SellOut_Quantity_YTD__c, SellOut_Tone_YTD__c,';		
        q += ' SellOut_wTax_YTD__c, SellOut_woTax_YTD__c, SellOut_Quantity_12M__c, SellOut_Tone_12M__c, SellOut_wTax_12M__c, SellOut_woTax_12M__c,';	
        q += ' Average_Retail_Price_SEQ__c, Average_Retail_Price_YTD__c, Average_Retail_Price_12M__c, Last_Synchro_Date__c';
        q += ' FROM Market_Data_Collection_Detail__c WHERE Sequence_Type__c = \'Month\' AND Status__c = \'Scan w/ success\'';
        
        if(ids != null && ids.size() > 0) {
            q += ' AND Market_Data_Collection_Head__c IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        this.query = q;
        // push inputs to log
        nb.logParameter('Ids', ids);
        nb.logParameter('selectedDate', this.selectedDate);
        nb.logParameter('query', this.query);
    }
    
    /* Start method implementation.*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    /* Execute method implementation.*/
    public void execute(Database.BatchableContext bc, List<Market_Data_Collection_Detail__c> scope) {
        Set<Id> marketReviewIds = new Set<Id>();
        Set<Id> clientSet = new Set<Id>();
        Set<Id> categorySet = new Set<Id>();
        Set<Id> buSet = new Set<Id>();
        Set<Id> masterBUSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> sequenceSet = new Set<Integer>();
        Map<Id, List<Market_Data_Collection_Detail__c>> marketDataCollectionsMap = new Map<Id, List<Market_Data_Collection_Detail__c>>();
        // List of Market Review to Upsert.
        List<Market_review__c> marketReviewList = new List<Market_review__c>();
        // List of Market Review Detail BU to Upsert.
        List<Market_Review_Detail_BU__c> marketReviewDetailsBUList = new List<Market_Review_Detail_BU__c>();
        // market collection head updated list
        Map<Id, Market_Data_Collection_Head__c> marketHeadUpdatedMap = new Map<Id, Market_Data_Collection_Head__c>();
        // market collection details updated list
        List<Market_Data_Collection_Detail__c> marketDetailsList = new List<Market_Data_Collection_Detail__c>();
        Map<Id, MarketDataCollectionWrapper> wMarketDataCollectionMap = new Map<Id, MarketDataCollectionWrapper>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            for(Market_Data_Collection_Detail__c item : scope) {
                if(!clientSet.contains(item.Market_Data_Collection_Head__r.Client__c)) {
                    clientSet.add(item.Market_Data_Collection_Head__r.Client__c);
                }
                if(!categorySet.contains(item.Orga_HE__c)) {
                    categorySet.add(item.Orga_HE__c);
                }
                if (item.Orga_BU__c != null && !buSet.contains(item.Orga_BU__c)) {
                    buSet.add(item.Orga_BU__c);
                }
                if(!masterBUSet.contains(item.Market_Data_Collection_Head__r.Master_BU__c)) {
                    masterBUSet.add(item.Market_Data_Collection_Head__r.Master_BU__c);
                }
                if(!productSet.contains(item.Product__c)) {
                    productSet.add(item.Product__c);
                }
                if(!yearSet.contains(Integer.valueOf(item.Year__c))) {
                    yearSet.add(Integer.valueOf(item.Year__c));
                }
                if (item.SEQ__c != null && !sequenceSet.contains(Integer.valueOf(item.SEQ__c))) {
                    sequenceSet.add(Integer.valueOf(item.SEQ__c));
                }
                if(!marketDataCollectionsMap.containsKey(item.Market_Data_Collection_Head__c)) {
                    marketDataCollectionsMap.put(item.Market_Data_Collection_Head__c, new List<Market_Data_Collection_Detail__c>{item});
                } else {
                    marketDataCollectionsMap.get(item.Market_Data_Collection_Head__c).add(item);
                }
            }
            // get market heads
            Map<Id, Market_Data_Collection_Head__c> marketHeadMap = new Map<Id, Market_Data_Collection_Head__c>([SELECT Id, Action_Todo__c, Orga_BU__c, Orga_BU__r.Format_Origin__c, Orga_HE__c, Client__c, SEQ__c, Year__c, Status__c,
                                                                                                                 Flow_Type__c, Master_BU__c, Movement_Date__c, Origin_Type__c, Ext_Category_Code__c, Ext_Category_Name__c, Last_Synchro_Date__c
                                                                                                                 FROM Market_Data_Collection_Head__c
                                                                                                                 WHERE Id IN :marketDataCollectionsMap.keySet()]);
            // get market reviews
            Map<String, Market_review__c> marketReviewLinkedMap = new Map<String, Market_review__c>();
            for(Market_review__c item : [SELECT Id, Orga_HE__c, Market__c, Channel__c, Year__c
                                         FROM Market_review__c
                                         WHERE Orga_HE__c IN :categorySet
                                         AND Market__c IN :masterBUSet
                                         AND Year__c IN :yearSet])
            {
                String key = item.Market__c + '' + item.Channel__c + '' + item.Orga_HE__c + '' + Integer.valueOf(item.Year__c);
                marketReviewLinkedMap.put(key, item);
                marketReviewIds.add(item.Id);
            }
            // get market review BU details
            Map<String, Market_Review_Detail_BU__c> marketReviewDetailBULinkedMap = new Map<String, Market_Review_Detail_BU__c>();
            // get market review details
            Map<String, Market_Review_Detail__c> marketReviewDetailLinkedMap = new Map<String, Market_Review_Detail__c>();
            if(!marketReviewIds.isEmpty()) {
                for(Market_Review_Detail_BU__c item : [SELECT Id, Product__c, Orga_BU__c, Market_review__c, Market_Review_Product__c, Sequence__c
                                                       FROM Market_Review_Detail_BU__c
                                                       WHERE Market_review__c IN :marketReviewIds AND Product__c IN :productSet])
                {
                    String key = item.Market_review__c + '' + item.Orga_BU__c + '' + item.Product__c + '' + Integer.valueOf(item.Sequence__c);
                    marketReviewDetailBULinkedMap.put(key, item);
                }
            }
            
            // get existing assortment details/ assortment detail sequences
            Map<String, Assortment_Detail__c> assortmentDetailMap = new Map<String, Assortment_Detail__c>();
            Map<String, List<Decimal>> calculateWDNDMap = new Map<String, List<Decimal>>();
            List<Assortment_Detail__c> matchedAssortmentDetails = [SELECT Id, Product__c, Year__c, Category__c, Category__r.Path__c,
                                                                   Assortment_BU__c, Assortment_BU__r.Ass_BDate__c, Assortment_BU__r.BU_Source__c, Assortment_BU__r.BU_Target__c,
                                                                   Assortment_BU__r.Orga_HE__c, Assortment_BU__r.Orga_HE__r.Path__c, Ass_BU_Cluster__c,
                                                                   Avg_Weekly_Sales_Ext_ClientBased__c, Avg_Weekly_Sales_Ext_MarketBased__c, Fact_ND_ClientBased__c,
                                                                   Fact_ND_MarketBased__c, Fact_WD_ClientBased__c, Fact_WD_MarketBased__c, Fact_SellOut_Quantity_SEQ__c,	
                                                                   Fact_SellOut_Tone_SEQ__c, Fact_SellOut_SEQ__c, Fact_SellOut_Quantity_YTD__c, Fact_SellOut_Tone_YTD__c,
                                                                   Fact_SellOut_YTD__c, Fact_SellOut_Quantity_12M__c, Fact_SellOut_Tone_12M__c, Fact_SellOut_12M__c,
                                                                   Fact_client_retail_price__c, Fact_SellOut_Quantity_SEQLast__c, Fact_SellOut_Tone_SEQLast__c, Fact_SellOut_SEQLast__c,
                                                                   (SELECT Id, Sequence__c, Avg_Weekly_Sales_Ext_ClientBased__c, Avg_Weekly_Sales_Ext_MarketBased__c,
                                                                    Fact_ND_ClientBased__c, Fact_ND_MarketBased__c, Fact_WD__c, Fact_WD_MarketBased__c, Fact_Client_Retail_Price__c
                                                                    FROM Assortment_Detail_Sequences__r WHERE Sequence__c IN :sequenceSet)
                                                                   FROM Assortment_Detail__c  WHERE Year__c IN :yearSet
                                                                   AND Assortment_BU__r.BU_Source__c IN :masterBUSet AND Assortment_BU__r.BU_Target__c IN :buSet
                                                                   AND Assortment_BU__r.Assortment_type__c = 'Out' AND Assortment_BU__r.Status__c = 'Validated'
                                                                   AND Product__c IN :productSet AND Version__c = NULL AND Status__c = 'Validated'];
            Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> assortmentBUClustersMap = AssortmentUtility.getAssortmentBUClustersMap(matchedAssortmentDetails);
            for(Assortment_Detail__c item : matchedAssortmentDetails) {
                Decimal WD = 0, ND = 0;
                Id buId = item.Assortment_BU__r.BU_Target__c;
                // Get Clusters WD cumul
                if (assortmentBUClustersMap.containsKey(buId) && assortmentBUClustersMap.get(buId).containsKey(item.Category__c)) {
                    WD = AssortmentUtility.getWDMarketBased(item, assortmentBUClustersMap.get(buId).get(item.Category__c).values());
                    ////ND = AssortmentUtility.getNDMarketBased(item, assortmentBUClustersMap.get(buId).get(item.Category__c).values());
                }
                
                String key = item.Assortment_BU__r.BU_Source__c + '' + item.Assortment_BU__r.BU_Target__c + '' + item.Product__c + '' + Integer.valueOf(item.Year__c);
                assortmentDetailMap.put(key, item);
                calculateWDNDMap.put(key, new List<Decimal>{WD/100, ND/100});
            }
            // get assortment Matrix reviews
            Map<String, Assortment_Matrix_review__c> assortmentMatrixReviewMap = new Map<String, Assortment_Matrix_review__c>();
            for(Assortment_Matrix_review__c item : [SELECT Id, BU_Source__c, BU_Target__c, Category__c, Produit__c, Sequence__c, Year__c,
                                                    Name__c, ND__c, WD__c, SellOut_Quantity__c, SellOut_Tone__c, SellOut__c
                                                    FROM Assortment_Matrix_review__c
                                                    WHERE BU_Source__c IN :masterBUSet AND BU_Target__c IN :buSet
                                                    AND Produit__c IN :productSet AND Year__c IN :yearSet AND Sequence__c IN :sequenceSet])
            {
                String key = item.BU_Source__c + '' + item.BU_Target__c + '' + item.Produit__c + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.Sequence__c) + '' + item.Name__c;
                assortmentMatrixReviewMap.put(key, item);
            }
            // Process Synchro market heads and details
            for(Id marketHeadId : marketDataCollectionsMap.keySet()) {
                Market_Data_Collection_Head__c marketHead = marketHeadMap.get(marketHeadId);
                MarketDataCollectionWrapper wMarketDataCollection = new MarketDataCollectionWrapper(marketHead);
                // upsert market review
                String keyHead = marketHead.Master_BU__c + '' + marketHead.Orga_BU__r.Format_Origin__c + '' + marketHead.Orga_HE__c + '' + Integer.valueOf(marketHead.Year__c);
                Market_review__c marketReview;
                // check if market review already exist
                if(marketReviewLinkedMap.containsKey(keyHead)) {
                    marketReview = marketReviewLinkedMap.get(keyHead);
                    // fill updated fields
                } else {
                    marketReview = new Market_review__c(Year__c = marketHead.Year__c,
                                                        Orga_HE__c = marketHead.Orga_HE__c,
                                                        Channel__c = marketHead.Orga_BU__r.Format_Origin__c,
                                                        Market__c = marketHead.Master_BU__c,
                                                        Std_Category_Code__c = marketHead.Ext_Category_Code__c,
                                                        Std_Category_Name__c = marketHead.Ext_Category_Name__c);
                    marketReviewList.add(marketReview);
                    marketReviewLinkedMap.put(keyHead, marketReview);
                }
                wMarketDataCollection.marketReview = marketReview;
                // check if market head already synchronized
                if(!this.marketHeadSynchroIds.contains(marketHead.Id)) {
                    marketHead.Status__c = 'Synchro w/ success';
                }
                
                // upsert market review detail
                List<Market_Data_Collection_Detail__c> marketDataCollectionDetails = marketDataCollectionsMap.get(marketHeadId);
                for(Market_Data_Collection_Detail__c marketDetail : marketDataCollectionDetails) {
                    Market_Review_Detail_BU__c marketReviewDetailBU;
                    // check if market review detail already exist
                    String keyDetail = marketReview.Id + '' + marketDetail.Orga_BU__c + '' + marketDetail.Product__c + '' + Integer.valueOf(marketDetail.SEQ__c);
                    if(marketReview.Id != null && marketReviewDetailBULinkedMap.containsKey(keyDetail)) {
                        marketReviewDetailBU = marketReviewDetailBULinkedMap.get(keyDetail);
                    } else {
                        marketReviewDetailBU = new Market_Review_Detail_BU__c(Market_review__c = marketReview.Id,
                                                                              Orga_BU__c = marketDetail.Orga_BU__c,
                                                                              Product__c = marketDetail.Product__c,
                                                                              Sequence__c = marketDetail.SEQ__c);
                    }
                    // get WD for product
                    Decimal WD = 0, ND = 0;
                    String keyAssortmentDetail = marketHead.Master_BU__c + '' + marketDetail.Orga_BU__c + '' + marketDetail.Product__c + '' + Integer.valueOf(marketHead.Year__c);
                    if(calculateWDNDMap.containsKey(keyAssortmentDetail)) {
                        List<Decimal> WDND = calculateWDNDMap.get(keyAssortmentDetail);
                        WD = WDND[0];
                        ND = WDND[1];
                    }
                    // Calcul de la DV circuit
                    // DV circuit = DV enseigne * DV de orga_bu(Ass_BU_Cluster)
                    ////marketReviewDetailBU.Sequence_Type__c = marketDetail.Sequence_Type__c; TODO: check field type
                    marketReviewDetailBU.Avg_Weekly_Sales_Ext_ClientBased__c = marketDetail.Avg_Weekly_Sales_Ext_ClientBased__c;
                    marketReviewDetailBU.Avg_Weekly_Sales_Ext_MarketBased__c = marketDetail.Avg_Weekly_Sales_Ext_MarketBased__c; // TODO: ?
                    marketReviewDetailBU.Fact_ND1_ClientBased_12M__c = marketDetail.ND_1_12M__c;
                    marketReviewDetailBU.Fact_ND1_ClientBased_SEQ__c = marketDetail.ND_1_SEQ__c;
                    marketReviewDetailBU.Fact_ND1_ClientBased_YTD__c = marketDetail.ND_1_YTD__c;
                    marketReviewDetailBU.Fact_ND1_MarketBased_12M__c = marketDetail.ND_1_12M__c /*!= null ? marketDetail.ND_1_12M__c * ND : null*/;
                    marketReviewDetailBU.Fact_ND1_MarketBased_SEQ__c = marketDetail.ND_1_SEQ__c /*!= null ? marketDetail.ND_1_SEQ__c * ND : null*/;
                    marketReviewDetailBU.Fact_ND1_MarketBased_YTD__c = marketDetail.ND_1_YTD__c /*!= null ? marketDetail.ND_1_YTD__c * ND : null*/;
                    marketReviewDetailBU.Fact_ND2_ClientBased_12M__c = marketDetail.ND_2_12M__c;
                    marketReviewDetailBU.Fact_ND2_ClientBased_SEQ__c = marketDetail.ND_2_SEQ__c;
                    marketReviewDetailBU.Fact_ND2_ClientBased_YTD__c = marketDetail.ND_2_YTD__c;
                    marketReviewDetailBU.Fact_ND2_MarketBased_12M__c = marketDetail.ND_2_12M__c /*!= null ? marketDetail.ND_2_12M__c * ND : null*/;
                    marketReviewDetailBU.Fact_ND2_MarketBased_SEQ__c = marketDetail.ND_2_SEQ__c /*!= null ? marketDetail.ND_2_SEQ__c * ND : null*/;
                    marketReviewDetailBU.Fact_ND2_MarketBased_YTD__c = marketDetail.ND_2_YTD__c /*!= null ? marketDetail.ND_2_YTD__c * ND : null*/;
                    marketReviewDetailBU.Fact_WD1_ClientBased_12M__c = marketDetail.WD_1_12M__c;
                    marketReviewDetailBU.Fact_WD1_ClientBased_SEQ__c = marketDetail.WD_1_SEQ__c;
                    marketReviewDetailBU.Fact_WD1_ClientBased_YTD__c = marketDetail.WD_1_YTD__c;
                    marketReviewDetailBU.Fact_WD1_MarketBased_12M__c = marketDetail.WD_1_12M__c != null ? marketDetail.WD_1_12M__c * WD : null;
                    marketReviewDetailBU.Fact_WD1_MarketBased_SEQ__c = marketDetail.WD_1_SEQ__c != null ? marketDetail.WD_1_SEQ__c * WD : null;
                    marketReviewDetailBU.Fact_WD1_MarketBased_YTD__c = marketDetail.WD_1_YTD__c != null ? marketDetail.WD_1_YTD__c * WD : null;
                    marketReviewDetailBU.Fact_WD2_ClientBased_12M__c = marketDetail.WD_2_12M__c;
                    marketReviewDetailBU.Fact_WD2_ClientBased_SEQ__c = marketDetail.WD_2_SEQ__c;
                    marketReviewDetailBU.Fact_WD2_ClientBased_YTD__c = marketDetail.WD_2_YTD__c;
                    marketReviewDetailBU.Fact_WD2_MarketBased_12M__c = marketDetail.WD_2_12M__c != null ? marketDetail.WD_2_12M__c * WD : null;
                    marketReviewDetailBU.Fact_WD2_MarketBased_SEQ__c = marketDetail.WD_2_SEQ__c != null ? marketDetail.WD_2_SEQ__c * WD : null;
                    marketReviewDetailBU.Fact_WD2_MarketBased_YTD__c = marketDetail.WD_2_YTD__c != null ? marketDetail.WD_2_YTD__c * WD : null;
                    marketReviewDetailBU.Fact_SellOut_Quantity_SEQ_Ext1__c = marketDetail.SellOut_Quantity_SEQ__c;
                    marketReviewDetailBU.Fact_SellOut_Tone_SEQ_Ext1__c = marketDetail.SellOut_Tone_SEQ__c;
                    marketReviewDetailBU.Fact_SellOut_wTax_SEQ_Ext1__c = marketDetail.SellOut_wTax_SEQ__c;
                    marketReviewDetailBU.Fact_SellOut_woTax_SEQ_Ext1__c = marketDetail.SellOut_woTax_SEQ__c;
                    marketReviewDetailBU.Fact_SellOut_Quantity_YTD_Ext1__c = marketDetail.SellOut_Quantity_YTD__c;
                    marketReviewDetailBU.Fact_SellOut_Tone_YTD_Ext1__c = marketDetail.SellOut_Tone_YTD__c;
                    marketReviewDetailBU.Fact_SellOut_wTax_YTD_Ext1__c = marketDetail.SellOut_wTax_YTD__c;
                    marketReviewDetailBU.Fact_SellOut_woTax_YTD_Ext1__c = marketDetail.SellOut_woTax_YTD__c;
                    marketReviewDetailBU.Fact_SellOut_Quantity_12M_Ext1__c = marketDetail.SellOut_Quantity_12M__c;
                    marketReviewDetailBU.Fact_SellOut_Tone_12M_Ext1__c = marketDetail.SellOut_Tone_12M__c;
                    marketReviewDetailBU.Fact_SellOut_wTax_12M_Ext1__c = marketDetail.SellOut_wTax_12M__c;
                    marketReviewDetailBU.Fact_SellOut_woTax_12M_Ext1__c = marketDetail.SellOut_woTax_12M__c;
                    marketReviewDetailBU.Avg_Retail_Price_SEQ_Ext1__c = marketDetail.Average_Retail_Price_SEQ__c;
                    marketReviewDetailBU.Avg_Retail_Price_YTD_Ext1__c = marketDetail.Average_Retail_Price_YTD__c;
                    marketReviewDetailBU.Avg_Retail_Price_12M_Ext1__c = marketDetail.Average_Retail_Price_12M__c;
                    // fill maps
                    wMarketDataCollection.marketReviewDetailsBUMap.put(marketDetail.Orga_BU__c + '' + marketDetail.Product__c + '' + Integer.valueOf(marketDetail.SEQ__c), marketReviewDetailBU);
                    wMarketDataCollection.marketDetailsMap.put(marketDetail.Orga_BU__c + '' + marketDetail.Product__c + '' + Integer.valueOf(marketDetail.SEQ__c), marketDetail);
                    marketDetail.Status__c = 'Synchro w/ success';
                    marketDetail.Last_Synchro_Date__c = System.now();
                }
                wMarketDataCollectionMap.put(marketHeadId, wMarketDataCollection);
            }
            
            // check security on updated market Review fields
            String[] marketReviewFields = new String[] {NegoptimHelper.normalizeAPIName('Year__c'), NegoptimHelper.normalizeAPIName('Orga_HE__c'), NegoptimHelper.normalizeAPIName('Channel__c'),
                NegoptimHelper.normalizeAPIName('Market__c'), NegoptimHelper.normalizeAPIName('Std_Category_Code__c'), NegoptimHelper.normalizeAPIName('Std_Category_Name__c')};
            
            // upsert market review
            if(!marketReviewList.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Market_review__c.SObjectType, marketReviewFields) &&
                   NegoptimHelper.checkUpdatibility(Market_review__c.SObjectType, marketReviewFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(marketReviewList, false);
                    nb.logResults(results, marketReviewList);
                }
            }
            
            Map<String, Market_Data_Collection_Detail__c> marketDetailsMap = new Map<String, Market_Data_Collection_Detail__c>();
            for(MarketDataCollectionWrapper item : wMarketDataCollectionMap.values()) {
                if(item.marketReview.Id != null) {
                    for(Market_Review_Detail_BU__c reviewDetail : item.marketReviewDetailsBUMap.values()) {
                        reviewDetail.Market_review__c = item.marketReview.Id;
                        Market_Data_Collection_Detail__c marketDetail = item.marketDetailsMap.get(reviewDetail.Orga_BU__c + '' + reviewDetail.Product__c + '' + Integer.valueOf(reviewDetail.Sequence__c));
                        String key = item.marketReview.Id + '' + reviewDetail.Orga_BU__c + '' + reviewDetail.Product__c + '' + Integer.valueOf(reviewDetail.Sequence__c);
                        marketDetailsMap.put(key, marketDetail);
                    }
                    marketReviewDetailsBUList.addAll(item.marketReviewDetailsBUMap.values());
                    marketDetailsList.addAll(item.marketDetailsMap.values());
                } else {
                    item.marketHead.Status__c = 'Synchro w/ error';
                    item.marketHead.Action_Todo__c = (item.marketHead.Action_Todo__c != null ? item.marketHead.Action_Todo__c : '') + String.valueOf(item.marketReview);
                    for(Market_Data_Collection_Detail__c marketDetail : item.marketDetailsMap.values()) {
                        marketDetail.Status__c = 'Synchro w/ error';
                        marketDetail.Action_Todo__c = (marketDetail.Action_Todo__c != null ? marketDetail.Action_Todo__c : '') + String.valueOf(item.marketReview);
                        marketDetailsList.add(marketDetail);
                    }
                }
                // check if market head already synchro or error synchro
                if(!this.marketHeadSynchroIds.contains(item.marketHead.Id) || item.marketHead.Status__c == 'Synchro w/ error') {
                    marketHeadUpdatedMap.put(item.marketHead.Id, item.marketHead);
                    this.marketHeadSynchroIds.add(item.marketHead.Id);
                }
            }
            
            // check security on updated market Review fields
            String[] marketReviewDetailsBUFields = new String[] {NegoptimHelper.normalizeAPIName('Orga_BU__c'), NegoptimHelper.normalizeAPIName('Product__c'),
                NegoptimHelper.normalizeAPIName('Sequence__c'), NegoptimHelper.normalizeAPIName('Avg_Weekly_Sales_Ext_ClientBased__c'), NegoptimHelper.normalizeAPIName('Avg_Weekly_Sales_Ext_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('Fact_ND1_ClientBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_ND1_ClientBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_ND1_ClientBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_ND1_MarketBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_ND1_MarketBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_ND1_MarketBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_ND2_ClientBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_ND2_ClientBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_ND2_ClientBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_ND2_MarketBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_ND2_MarketBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_ND2_MarketBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_WD1_ClientBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_WD1_ClientBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_WD1_ClientBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_WD1_MarketBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_WD1_MarketBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_WD1_MarketBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_WD2_ClientBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_WD2_ClientBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_WD2_ClientBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_WD2_MarketBased_12M__c'), NegoptimHelper.normalizeAPIName('Fact_WD2_MarketBased_SEQ__c'),
                NegoptimHelper.normalizeAPIName('Fact_WD2_MarketBased_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity_SEQ_Ext1__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Tone_SEQ_Ext1__c'),
                NegoptimHelper.normalizeAPIName('Fact_SellOut_wTax_SEQ_Ext1__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_woTax_SEQ_Ext1__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity_YTD_Ext1__c'),
                NegoptimHelper.normalizeAPIName('Fact_SellOut_Tone_YTD_Ext1__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_wTax_YTD_Ext1__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_woTax_YTD_Ext1__c'),
                NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity_12M_Ext1__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Tone_12M_Ext1__c'),
                NegoptimHelper.normalizeAPIName('Fact_SellOut_woTax_12M_Ext1__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_wTax_12M_Ext1__c'),                
                NegoptimHelper.normalizeAPIName('Avg_Retail_Price_SEQ_Ext1__c'), NegoptimHelper.normalizeAPIName('Avg_Retail_Price_YTD_Ext1__c'), NegoptimHelper.normalizeAPIName('Avg_Retail_Price_12M_Ext1__c'),
                NegoptimHelper.normalizeAPIName('Sequence_Type__c')};
            
            String[] marketReviewDetailsBUCreateFields = new String[]{NegoptimHelper.normalizeAPIName('Market_review__c')};
            marketReviewDetailsBUCreateFields.addAll(marketReviewDetailsBUFields);
            
            Map<String, Market_Review_Detail_BU__c> marketReviewDetailBUInsertedMap = new Map<String, Market_Review_Detail_BU__c>();
            // upsert market review details BU
            if(!marketReviewDetailsBUList.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Market_Review_Detail_BU__c.SObjectType, marketReviewDetailsBUCreateFields) &&
                   NegoptimHelper.checkUpdatibility(Market_Review_Detail_BU__c.SObjectType, marketReviewDetailsBUFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(marketReviewDetailsBUList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Market_Review_Detail_BU__c marketReviewDetailBU = marketReviewDetailsBUList.get(i);
                        String key = marketReviewDetailBU.Market_review__c + '' + marketReviewDetailBU.Orga_BU__c + '' + marketReviewDetailBU.Product__c + '' + Integer.valueOf(marketReviewDetailBU.Sequence__c);
                        Market_Data_Collection_Detail__c marketDetail = marketDetailsMap.get(key);
                        if (!result.isSuccess()) {
                            String errorMessage = result.Id != null ? marketReviewDetailBU.Name + '(' + result.Id + ') : ' : String.valueOf(marketReviewDetailBU);
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            // update market detail status/message
                            marketDetail.Status__c = 'Synchro w/ error';
                            marketDetail.Action_Todo__c = (marketDetail.Action_Todo__c != null ? marketDetail.Action_Todo__c : '') + errorMessage;
                            // update market head status/message
                            Market_Data_Collection_Head__c marketHead;
                            if(marketHeadUpdatedMap.containsKey(marketDetail.Market_Data_Collection_Head__c)) {
                                marketHead = marketHeadUpdatedMap.get(marketDetail.Market_Data_Collection_Head__c);
                            } else {
                                marketHead = marketHeadMap.get(marketDetail.Market_Data_Collection_Head__c);
                            }
                            marketHead.Status__c = 'Synchro w/ error';
                            marketHead.Action_Todo__c = (marketHead.Action_Todo__c != null ? marketHead.Action_Todo__c : '') + errorMessage;
                            if(String.isNotBlank(marketHead.Action_Todo__c) && marketHead.Action_Todo__c.length() > 31000) {
                                marketHead.Action_Todo__c = marketHead.Action_Todo__c.substring(0, 31000) + '... (message truncated)';
                            }
                            marketHead.Last_Synchro_Date__c = System.now();
                            marketHeadUpdatedMap.put(marketHead.Id, marketHead);
                        } else {
                            marketReviewDetailBUInsertedMap.put(key, marketReviewDetailBU);
                        }
                    }
                }
            }
            
            // update existing assortment details/ assortment detail sequences
            if(!marketReviewDetailBUInsertedMap.isEmpty()) {
                List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();
                List<Assortment_Detail_Sequence__c> assortmentDetailSequences = new List<Assortment_Detail_Sequence__c>();
                List<Assortment_Matrix_review__c> assortmentMatrixReviews = new List<Assortment_Matrix_review__c>();
                Map<String, Market_Review_Detail_BU__c> lastMarketReviewDetailBUMap = new Map<String, Market_Review_Detail_BU__c>();
                Map<String, Market_Review_Detail_BU__c> marketReviewDetailBUSequencesMap = new Map<String, Market_Review_Detail_BU__c>();
                Map<String, Integer> sequencesMap = new Map<String, Integer>();
                for(String key : marketReviewDetailBUInsertedMap.keySet()) {
                    Market_Review_Detail_BU__c marketReviewDetailBU = marketReviewDetailBUInsertedMap.get(key);
                    Market_Data_Collection_Detail__c marketDetail = marketDetailsMap.get(key);
                    String keyDetail = marketDetail.Market_Data_Collection_Head__r.Master_BU__c + '' + marketReviewDetailBU.Orga_BU__c + '' + marketReviewDetailBU.Product__c + '' + Integer.valueOf(marketDetail.Year__c);
                    marketReviewDetailBUSequencesMap.put(keyDetail + '' + Integer.valueOf(marketReviewDetailBU.Sequence__c), marketReviewDetailBU);
                    // check last sequence
                    if(sequencesMap.containsKey(keyDetail)) {
                        Integer lastSequence = Integer.valueOf(sequencesMap.get(keyDetail));
                        if(Integer.valueOf(marketReviewDetailBU.Sequence__c) > lastSequence) {
                            sequencesMap.put(keyDetail, Integer.valueOf(marketReviewDetailBU.Sequence__c));
                        } else  continue;
                    } else {
                        sequencesMap.put(keyDetail, Integer.valueOf(marketReviewDetailBU.Sequence__c));
                    }
                    lastMarketReviewDetailBUMap.put(keyDetail, marketReviewDetailBU);
                }
                Set<String> assortmentDetailSet = new Set<String>();
                for(String key : marketReviewDetailBUInsertedMap.keySet()) {
                    Market_Review_Detail_BU__c marketReviewDetailBU = marketReviewDetailBUInsertedMap.get(key);
                    Market_Data_Collection_Detail__c marketDetail = marketDetailsMap.get(key);
                    // update assortment detail
                    String keyDetail = marketDetail.Market_Data_Collection_Head__r.Master_BU__c + '' + marketReviewDetailBU.Orga_BU__c + '' + marketReviewDetailBU.Product__c + '' + Integer.valueOf(marketDetail.Year__c);
                    // Check if target BU is Circuit (IsMasterBU__=TRUE AND SOURCE_BU=MATERNE)
                    Boolean isCircuit = marketDetail.Orga_BU__r.IsMasterBU__c != null && marketDetail.Orga_BU__r.IsMasterBU__c == true;
                    if(!isCircuit && assortmentDetailMap.containsKey(keyDetail) && !assortmentDetailSet.contains(keyDetail)) {
                        Assortment_Detail__c assortmentDetail = assortmentDetailMap.get(keyDetail);
                        Market_Review_Detail_BU__c lastMarketReviewDetailBU = lastMarketReviewDetailBUMap.get(keyDetail);
                        
                        // update assortment detail sequences
                        for(Assortment_Detail_Sequence__c assortmentDetailSequence : assortmentDetail.Assortment_Detail_Sequences__r) {
                            Market_Review_Detail_BU__c marketReviewDetailBUSequence = marketReviewDetailBUSequencesMap.get(keyDetail + '' + Integer.valueOf(assortmentDetailSequence.Sequence__c));
                            if(marketReviewDetailBUSequence != null) {
                                assortmentDetailSequence.Avg_Weekly_Sales_Ext_ClientBased__c = marketReviewDetailBUSequence.Avg_Weekly_Sales_Ext_ClientBased__c;
                                assortmentDetailSequence.Avg_Weekly_Sales_Ext_MarketBased__c = marketReviewDetailBUSequence.Avg_Weekly_Sales_Ext_MarketBased__c;
                                assortmentDetailSequence.Fact_ND_ClientBased__c = marketReviewDetailBUSequence.Fact_ND1_ClientBased_SEQ__c;
                                assortmentDetailSequence.Fact_ND_MarketBased__c = marketReviewDetailBUSequence.Fact_ND1_MarketBased_SEQ__c;
                                assortmentDetailSequence.Fact_WD_ClientBased__c = marketReviewDetailBUSequence.Fact_WD1_ClientBased_SEQ__c;
                                assortmentDetailSequence.Fact_WD_MarketBased__c = marketReviewDetailBUSequence.Fact_WD1_MarketBased_SEQ__c;
                                assortmentDetailSequence.Fact_Client_Retail_Price__c = marketReviewDetailBUSequence.Avg_Retail_Price_SEQ_Ext1__c;
                                assortmentDetailSequences.add(assortmentDetailSequence);
                            }
                        }
                        assortmentDetail.Avg_Weekly_Sales_Ext_ClientBased__c = lastMarketReviewDetailBU.Avg_Weekly_Sales_Ext_ClientBased__c;
                        assortmentDetail.Avg_Weekly_Sales_Ext_MarketBased__c = lastMarketReviewDetailBU.Avg_Weekly_Sales_Ext_MarketBased__c;
                        assortmentDetail.Fact_ND_ClientBased__c = lastMarketReviewDetailBU.Fact_ND1_ClientBased_SEQ__c;
                        assortmentDetail.Fact_ND_MarketBased__c = lastMarketReviewDetailBU.Fact_ND1_MarketBased_SEQ__c;
                        assortmentDetail.Fact_WD_ClientBased__c = lastMarketReviewDetailBU.Fact_WD1_ClientBased_SEQ__c;
                        assortmentDetail.Fact_WD_MarketBased__c = lastMarketReviewDetailBU.Fact_WD1_MarketBased_SEQ__c;
                        assortmentDetail.Fact_SellOut_Quantity_SEQLast__c = assortmentDetail.Fact_SellOut_Quantity_SEQ__c;
                        assortmentDetail.Fact_SellOut_Quantity_SEQ__c = lastMarketReviewDetailBU.Fact_SellOut_Quantity_SEQ_Ext1__c;
                        assortmentDetail.Fact_SellOut_SEQLast__c = assortmentDetail.Fact_SellOut_SEQ__c;
                        assortmentDetail.Fact_SellOut_SEQ__c = lastMarketReviewDetailBU.Fact_SellOut_woTax_SEQ_Ext1__c;
                        assortmentDetail.Fact_SellOut_Quantity_YTD__c = lastMarketReviewDetailBU.Fact_SellOut_Quantity_YTD_Ext1__c;
                        assortmentDetail.Fact_SellOut_YTD__c = lastMarketReviewDetailBU.Fact_SellOut_woTax_YTD_Ext1__c;
                        assortmentDetail.Fact_SellOut_Quantity_12M__c = lastMarketReviewDetailBU.Fact_SellOut_Quantity_12M_Ext1__c;
                        assortmentDetail.Fact_SellOut_12M__c = lastMarketReviewDetailBU.Fact_SellOut_woTax_12M_Ext1__c;
                        assortmentDetail.Fact_client_retail_price__c = lastMarketReviewDetailBU.Avg_Retail_Price_SEQ_Ext1__c;
                        assortmentDetails.add(assortmentDetail);
                        assortmentDetailSet.add(keyDetail);
                    }
                    // upsert assortment matrix review
                    Set<String> nameSet = new Set<String>{'Fact1', 'Fact2'};
                    for(String name : nameSet) {
                        String keyAssortmentMatrix = keyDetail + '' + Integer.valueOf(marketReviewDetailBU.Sequence__c) + '' + name;
                        Assortment_Matrix_review__c assortmentMatrixReview = assortmentMatrixReviewMap.get(keyAssortmentMatrix);
                        if(assortmentMatrixReview == null) {
                            // insert assortment Matrix review
                            assortmentMatrixReview = new Assortment_Matrix_review__c(BU_Source__c = marketDetail.Market_Data_Collection_Head__r.Master_BU__c,
                                                                                     BU_Target__c = marketReviewDetailBU.Orga_BU__c,
                                                                                     Produit__c = marketReviewDetailBU.Product__c,
                                                                                     Sequence__c = marketReviewDetailBU.Sequence__c,
                                                                                     Year__c = Integer.valueOf(marketDetail.Year__c),
                                                                                     Name__c = name);
                        }
                        if(name == 'Fact1') {
                            assortmentMatrixReview.ND__c = marketReviewDetailBU.Fact_ND1_ClientBased_SEQ__c;
                            assortmentMatrixReview.WD__c = marketReviewDetailBU.Fact_WD1_ClientBased_SEQ__c;
                            assortmentMatrixReview.SellOut_Quantity__c = marketReviewDetailBU.Fact_SellOut_Quantity_SEQ_Ext1__c;
                            assortmentMatrixReview.SellOut_Tone__c = marketReviewDetailBU.Fact_SellOut_Tone_SEQ_Ext1__c;
                            // Calcul de la DV circuit
                            // DV circuit = DV enseigne * DV de orga_bu(Ass_BU_Cluster)
                            assortmentMatrixReview.ND_Marketbase__c = marketReviewDetailBU.Fact_ND1_MarketBased_SEQ__c;
                            assortmentMatrixReview.WD_Marketbase__c = marketReviewDetailBU.Fact_WD1_MarketBased_SEQ__c;
                        }
                        if(name == 'Fact2') {
                            assortmentMatrixReview.ND__c = marketReviewDetailBU.Fact_ND2_ClientBased_SEQ__c;
                            assortmentMatrixReview.WD__c = marketReviewDetailBU.Fact_WD2_ClientBased_SEQ__c;
                            assortmentMatrixReview.ND_Marketbase__c = marketReviewDetailBU.Fact_ND2_MarketBased_SEQ__c;
                            assortmentMatrixReview.WD_Marketbase__c = marketReviewDetailBU.Fact_WD2_MarketBased_SEQ__c;
                        }
                        assortmentMatrixReview.SellOut__c = marketReviewDetailBU.Fact_SellOut_woTax_SEQ_Ext1__c;                        
                        assortmentMatrixReviews.add(assortmentMatrixReview);
                    }
                }
             
                // check security on Assortment_Detail__c fields
                String[] assortmentDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Avg_Weekly_Sales_Ext_ClientBased__c'),
                    NegoptimHelper.normalizeAPIName('Avg_Weekly_Sales_Ext_MarketBased__c'), NegoptimHelper.normalizeAPIName('Fact_ND_ClientBased__c'),
                    NegoptimHelper.normalizeAPIName('Fact_ND_MarketBased__c'), NegoptimHelper.normalizeAPIName('Fact_WD_ClientBased__c'),
                    NegoptimHelper.normalizeAPIName('Fact_WD_MarketBased__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity_SEQLast__c'),
                    NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity_SEQ__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_SEQLast__c'),
                    NegoptimHelper.normalizeAPIName('Fact_SellOut_SEQ__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity_YTD__c'),
                    NegoptimHelper.normalizeAPIName('Fact_SellOut_YTD__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity_12M__c'),
                    NegoptimHelper.normalizeAPIName('Fact_SellOut_12M__c'), NegoptimHelper.normalizeAPIName('Fact_client_retail_price__c')};
                 
                // check security on Assortment_Detail_Sequence__c fields
                String[] assortmentDetailSequenceFields = new String[] {NegoptimHelper.normalizeAPIName('Avg_Weekly_Sales_Ext_ClientBased__c'),
                    NegoptimHelper.normalizeAPIName('Avg_Weekly_Sales_Ext_MarketBased__c'), NegoptimHelper.normalizeAPIName('Fact_ND_ClientBased__c'),
                    NegoptimHelper.normalizeAPIName('Fact_ND_MarketBased__c'), NegoptimHelper.normalizeAPIName('Fact_WD_ClientBased__c'),
                    NegoptimHelper.normalizeAPIName('Fact_WD_MarketBased__c'), NegoptimHelper.normalizeAPIName('Fact_Client_Retail_Price__c')};
                 
                // check security on Assortment_Matrix_review__c fields
                String[] assortmentMatrixReviewFields = new String[] {NegoptimHelper.normalizeAPIName('ND__c'), NegoptimHelper.normalizeAPIName('WD__c'),
                    NegoptimHelper.normalizeAPIName('ND_Marketbase__c'), NegoptimHelper.normalizeAPIName('WD_Marketbase__c')};
                        
                String[] assortmentMatrixReviewInsertedFields = new String[]{NegoptimHelper.normalizeAPIName('BU_Source__c'),
                    NegoptimHelper.normalizeAPIName('BU_Target__c'), NegoptimHelper.normalizeAPIName('Produit__c'), NegoptimHelper.normalizeAPIName('Sequence__c'),
                    NegoptimHelper.normalizeAPIName('Year__c'), NegoptimHelper.normalizeAPIName('Name__c')};
                assortmentMatrixReviewInsertedFields.addAll(assortmentMatrixReviewFields);
                
                if(NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields) &&
                   NegoptimHelper.checkUpdatibility(Assortment_Detail_Sequence__c.SObjectType, assortmentDetailSequenceFields) &&
                   NegoptimHelper.checkCreatibility(Assortment_Matrix_review__c.SObjectType, assortmentMatrixReviewInsertedFields) &&
                   NegoptimHelper.checkUpdatibility(Assortment_Matrix_review__c.SObjectType, assortmentMatrixReviewFields))
                {
                    // update assortment details
                    if(!assortmentDetails.isEmpty()) {
                        List<Database.SaveResult> results = Database.update(assortmentDetails, false);
                        nb.logResults(results, assortmentDetails);
                    }
                    // update assortment details sequences
                    if(!assortmentDetailSequences.isEmpty()) {
                        List<Database.SaveResult> results = Database.update(assortmentDetailSequences, false);
                        nb.logResults(results, assortmentDetailSequences);
                    }
                    // upsert assortment Matrix reviews
                    if(!assortmentMatrixReviews.isEmpty()) {
                        List<Database.UpsertResult> results = Database.upsert(assortmentMatrixReviews, false);
                        nb.logResults(results, assortmentMatrixReviews);
                    }
                }
            }
            
            // check security on updated market head fields
            String[] marketHeadUpdatedFields = new String[] {NegoptimHelper.normalizeAPIName('Action_Todo__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Last_Synchro_Date__c')};
          
            // check security on updated market details fields
            String[] marketDetailsUpdatedFields = new String[] {NegoptimHelper.normalizeAPIName('Action_Todo__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Last_Synchro_Date__c')};
            
            // update market details
            if(!marketDetailsList.isEmpty()) {
                if(NegoptimHelper.checkUpdatibility(Market_Data_Collection_Detail__c.SObjectType, marketDetailsUpdatedFields)) {
                    List<Database.SaveResult> results = Database.update(marketDetailsList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Market_Data_Collection_Detail__c marketDetail = marketDetailsList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = marketDetail.Name + '(' + marketDetail.Id + ') : ';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            // update market head status/message
                            Market_Data_Collection_Head__c marketHead;
                            if(marketHeadUpdatedMap.containsKey(marketDetail.Market_Data_Collection_Head__c)) {
                                marketHead = marketHeadUpdatedMap.get(marketDetail.Market_Data_Collection_Head__c);
                            } else {
                                marketHead = marketHeadMap.get(marketDetail.Market_Data_Collection_Head__c);
                            }
                            marketHead.Status__c = 'Synchro w/ error';
                            marketHead.Action_Todo__c = (marketHead.Action_Todo__c != null ? marketHead.Action_Todo__c : '') + errorMessage;
                            if(String.isNotBlank(marketHead.Action_Todo__c) && marketHead.Action_Todo__c.length() > 31000) {
                                marketHead.Action_Todo__c = marketHead.Action_Todo__c.substring(0, 31000) + '... (message truncated)';
                            }
                            marketHead.Last_Synchro_Date__c = System.now();
                            marketHeadUpdatedMap.put(marketHead.Id, marketHead);
                        }
                    }
                }
            }
            // update market head
            if(!marketHeadUpdatedMap.isEmpty()) {
                if(NegoptimHelper.checkUpdatibility(Market_Data_Collection_Head__c.SObjectType, marketHeadUpdatedFields)) {
                    List<Database.SaveResult> results = Database.update(marketHeadUpdatedMap.values(), false);
                    nb.logResults(results, marketHeadUpdatedMap.values());
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
    
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper Class for MarketDataCollection. */
    public class MarketDataCollectionWrapper {
        public Market_Data_Collection_Head__c marketHead {get; set;}
        // Map<BU + Product Id, Market Detail>
        public Map<String, Market_Data_Collection_Detail__c> marketDetailsMap {get; set;}
        
        public Market_review__c marketReview {get; set;}
        // Map<BU + Product Id, Market Review Detail BU>
        public Map<String, Market_Review_Detail_BU__c> marketReviewDetailsBUMap {get; set;}
        
        public MarketDataCollectionWrapper(Market_Data_Collection_Head__c marketHead) {
            this.marketHead = marketHead;
            this.marketDetailsMap = new Map<String, Market_Data_Collection_Detail__c>();
            this.marketReview = null;
            this.marketReviewDetailsBUMap = new Map<String, Market_Review_Detail_BU__c>();
        }
    }
}