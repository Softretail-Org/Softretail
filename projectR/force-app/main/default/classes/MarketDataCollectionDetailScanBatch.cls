/*
 * Scan market data collection.
 */ 
global with sharing class MarketDataCollectionDetailScanBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    public final Date selectedDate;
    public static Map<String, string> marketDetailFieldNameLabels;
    private final Set<Id> marketDetailIds;
    
    /* Constructor */
    public MarketDataCollectionDetailScanBatch(String startedFrom, List<Id> ids, Date d) {
        this.nb = new NegoptimBatch('MarketDataCollectionDetailScanBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.selectedDate = d;
        this.marketDetailIds = new Set<Id>();
        
        String q = 'SELECT Id, Name, Market_Data_Collection_Head__c, Market_Data_Collection_Head__r.Master_BU__c, Market_Data_Collection_Head__r.Movement_Date__c,';
        q += ' Action_Done__c, Action_Todo__c, Status__c, SEQ__c, Year__c, Sequence_Type__c, Sequence_Number__c,';
        q += ' Orga_HE__c, Ext_Brand_Code__c, Ext_Brand_Name__c, Ext_Category_Code__c, Ext_Category_Name__c, Ext_BU_Code__c,';
        q += ' Ext_BU_Name__c, Orga_BU__c, Ext_Packaging__c, Ext_Product_Code__c, Ext_Product_EAN__c, Ext_Product_Name__c, Product__c, Last_Scan_Date__c,';
        q += ' Date_SSEQ0__c, Date_SSEQ1__c, Date_SSEQ2__c, Date_SSEQ3__c, Date_SSEQ4__c, Date_SSEQ5__c,';
        q += ' Weight_SSEQ0__c, Weight_SSEQ1__c, Weight_SSEQ2__c, Weight_SSEQ3__c, Weight_SSEQ4__c, Weight_SSEQ5__c,';
        q += ' SellOut_Quantity_SSEQ0__c, SellOut_Quantity_SSEQ1__c, SellOut_Quantity_SSEQ2__c, SellOut_Quantity_SSEQ3__c, SellOut_Quantity_SSEQ4__c, SellOut_Quantity_SSEQ5__c,';
        q += ' SellOut_Tone_SSEQ0__c, SellOut_Tone_SSEQ1__c, SellOut_Tone_SSEQ2__c, SellOut_Tone_SSEQ3__c, SellOut_Tone_SSEQ4__c, SellOut_Tone_SSEQ5__c,';
        q += ' SellOut_wTax_SSEQ0__c, SellOut_wTax_SSEQ1__c, SellOut_wTax_SSEQ2__c, SellOut_wTax_SSEQ3__c, SellOut_wTax_SSEQ4__c, SellOut_wTax_SSEQ5__c,';
        q += ' ND_1_SSEQ0__c, ND_1_SSEQ1__c, ND_1_SSEQ2__c, ND_1_SSEQ3__c, ND_1_SSEQ4__c, ND_1_SSEQ5__c,';
        q += ' ND_2_SSEQ0__c, ND_2_SSEQ1__c, ND_2_SSEQ2__c, ND_2_SSEQ3__c, ND_2_SSEQ4__c, ND_2_SSEQ5__c,';
        q += ' WD_1_SSEQ0__c, WD_1_SSEQ1__c, WD_1_SSEQ2__c, WD_1_SSEQ3__c, WD_1_SSEQ4__c, WD_1_SSEQ5__c,';
        q += ' WD_2_SSEQ0__c, WD_2_SSEQ1__c, WD_2_SSEQ2__c, WD_2_SSEQ3__c, WD_2_SSEQ4__c, WD_2_SSEQ5__c,';
        q += ' Avg_Weekly_Sales_Ext_ClientBased__c, Avg_Weekly_Sales_Ext_MarketBased__c, ND_1_12M__c, ND_1_SEQ__c, ND_1_YTD__c,';
        q += ' ND_2_12M__c, ND_2_SEQ__c, ND_2_YTD__c, WD_1_12M__c, WD_1_SEQ__c, WD_1_YTD__c, WD_2_12M__c, WD_2_SEQ__c, WD_2_YTD__c,';
        q += ' SellOut_Quantity_SEQ__c, SellOut_Tone_SEQ__c, SellOut_wTax_SEQ__c, SellOut_woTax_SEQ__c, SellOut_Quantity_YTD__c, SellOut_Tone_YTD__c,';
        q += ' SellOut_wTax_YTD__c, SellOut_woTax_YTD__c, SellOut_Quantity_12M__c, SellOut_Tone_12M__c, SellOut_wTax_12M__c, SellOut_woTax_12M__c,';
        q += ' Average_Retail_Price_SEQ__c, Average_Retail_Price_YTD__c, Average_Retail_Price_12M__c,';
        q += ' SellOut_woTax_SSEQ0__c, SellOut_woTax_SSEQ1__c, SellOut_woTax_SSEQ2__c, SellOut_woTax_SSEQ3__c, SellOut_woTax_SSEQ4__c, SellOut_woTax_SSEQ5__c';
        q += ' FROM Market_Data_Collection_Detail__c WHERE Ext_BU_Name__c <> NULL AND (Status__c = \'New\' OR Status__c = \'Updated\')';
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
        // Declaration
        Set<Id> masterBUSet = new Set<Id>();
        Set<Id> marketHeadIdSet = new Set<Id>();
        Set<String> buNameSet = new Set<String>();
        Set<String> buCodeSet = new Set<String>();
        Set<String> categoryNameSet = new Set<String>();
        Set<String> categoryCodeSet = new Set<String>();
        Set<String> productEANSet = new Set<String>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Integer> monthSet = new Set<Integer>();

        Map<String, Orga_BU__c> buNameMap = new Map<String, Orga_BU__c>();
        Map<String, Orga_BU__c> buCodeMap = new Map<String, Orga_BU__c>();
        Map<String, Orga_HE__c> categoryNameMap = new Map<String, Orga_HE__c>();
        Map<String, Orga_HE__c> categoryCodeMap = new Map<String, Orga_HE__c>();
        Map<String, Product2> productMap = new Map<String, Product2>();
        List<Market_Data_Collection_Detail__c> marketDetailsList = new List<Market_Data_Collection_Detail__c>();
        Map<Id, MarketDetailWrapper> wMarketDetailMap = new Map<Id, MarketDetailWrapper>();
        Map<Id, MarketHeadWrapper> wMarketHeadMap = new Map<Id, MarketHeadWrapper>();
        
        // Describe all fields for Market_Data_Collection_Detail__c
        marketDetailFieldNameLabels = NegoptimHelper.GetMandatoryFieldLabels(Market_Data_Collection_Detail__c.SObjectType);
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on read market details fields
            String[] marketDetailsAccessFields = new String[] {'Id', 'Name', NegoptimHelper.normalizeAPIName('Market_Data_Collection_Head__c'),
                NegoptimHelper.normalizeAPIName('Action_Done__c'), NegoptimHelper.normalizeAPIName('Action_Todo__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Ext_Product_Code__c'),
                NegoptimHelper.normalizeAPIName('Ext_Product_EAN__c'), NegoptimHelper.normalizeAPIName('Product__c'),
                NegoptimHelper.normalizeAPIName('Ext_Category_Code__c'), NegoptimHelper.normalizeAPIName('Ext_Category_Name__c'),
                NegoptimHelper.normalizeAPIName('Orga_HE__c')};
            
            for(Market_Data_Collection_Detail__c item : scope) {
                if(!marketHeadIdSet.contains(item.Market_Data_Collection_Head__c)) {
                    marketHeadIdSet.add(item.Market_Data_Collection_Head__c);
                }
                if(item.Market_Data_Collection_Head__r.Master_BU__c != null && !masterBUSet.Contains(item.Market_Data_Collection_Head__r.Master_BU__c)) {
                    masterBUSet.add(item.Market_Data_Collection_Head__r.Master_BU__c);
                }
                if(String.IsNotBlank(item.Ext_BU_Name__c) && !buNameSet.contains(item.Ext_BU_Name__c.toLowerCase())) {
                    buNameSet.add(item.Ext_BU_Name__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_BU_Code__c) && !buCodeSet.contains(item.Ext_BU_Code__c.toLowerCase())) {
                    buCodeSet.add(item.Ext_BU_Code__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_Category_Name__c) && !categoryNameSet.contains(item.Ext_Category_Name__c.toLowerCase())) {
                    categoryNameSet.add(item.Ext_Category_Name__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_Category_Code__c) && !categoryCodeSet.contains(item.Ext_Category_Code__c.toLowerCase())) {
                    categoryCodeSet.add(item.Ext_Category_Code__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_Product_EAN__c) && !productEANSet.contains(item.Ext_Product_EAN__c.toLowerCase())) {
                    productEANSet.add(item.Ext_Product_EAN__c.toLowerCase());
                }
                if (item.Year__c != null && !yearSet.contains(Integer.valueOf(item.Year__c))) {
                    yearSet.add(Integer.valueOf(item.Year__c));
                }
                if (item.SEQ__c != null && !monthSet.contains(Integer.valueOf(item.SEQ__c))) {
                    monthSet.add(Integer.valueOf(item.SEQ__c));
                }
            }
            // get Taxes for calculate Sellout w/o Tax
            Map<String, Orga_Taxes__c> taxesMap = new Map<String, Orga_Taxes__c>();
            for(Orga_Taxes__c item : [SELECT Id, Name, Orga_BU_Source__c, Orga_HE__c, Orga_HE__r.Path__c, Status__c, Tax_percent__c, Tax_amount__c
                                      FROM Orga_Taxes__c WHERE Orga_BU_Source__c IN :masterBUSet AND Orga_HE__c <> NULL
                                      AND Status__c = 'Open' AND RecordType.DeveloperName = 'VAT'])
            {
                String key = item.Orga_BU_Source__c + '' + item.Orga_HE__r.Path__c;
                if(!taxesMap.containsKey(key)) {
                    taxesMap.put(key, item);
                }
            }
            Map<Id, Set<Id>> buListMap = new Map<Id, Set<Id>>();
            Set<Id> buBannerSet = new Set<Id>();
            // get BUs
            if(!buNameSet.isEmpty() || !buCodeSet.isEmpty()) {
                for(Orga_BU__c item : [SELECT Id, Name, BU_Code__c, Panel_Name__c, RecordType.DeveloperName,
                                       (SELECT Id, Name, Entity_List__c, Entity_List__r.RecordType.DeveloperName, Nielsen_Split__c
                                        FROM List_detail1__r
                                        WHERE Entity_List__r.Status__c = 'Open' AND Entity_List__r.RecordType.DeveloperName = 'Banner'
                                        AND Entity_List__r.Mission__c INCLUDES ('Offer'))
                                       FROM Orga_BU__c
                                       WHERE Status__c = 'Open' AND (BU_Code__c IN :buCodeSet OR Name IN :buNameSet OR Panel_Name__c IN :buNameSet)
                                       AND Mission__c INCLUDES ('Nielsen')])
                {
                    // fill bus banner already related to market details
                    if(item.RecordType.DeveloperName == 'List' && !item.List_detail1__r.isEmpty()) {
                        for(Orga_BU_List_Detail__c buListDetail : item.List_detail1__r) {
                            if(!buListMap.containsKey(item.Id)) {
                                buListMap.put(item.Id, new Set<Id>{buListDetail.Entity_List__c});
                            } else {
                                buListMap.get(item.Id).add(buListDetail.Entity_List__c);
                            }
                            buBannerSet.add(buListDetail.Entity_List__c);
                        }
                    }
                    if(buNameSet.contains(item.Name.toLowerCase()) && !buNameMap.containsKey(item.Name.toLowerCase())) {
                        buNameMap.put(item.Name.toLowerCase(), item);
                    }
                    if(item.Panel_Name__c != null && buNameSet.contains(item.Panel_Name__c.toLowerCase()) && !buNameMap.containsKey(item.Panel_Name__c.toLowerCase())) {
                        buNameMap.put(item.Panel_Name__c.toLowerCase(), item);
                    }
                    if(buCodeSet.contains(item.BU_Code__c.toLowerCase()) && !buCodeMap.containsKey(item.BU_Code__c.toLowerCase())) {
                        buCodeMap.put(item.BU_Code__c.toLowerCase(), item);
                    }
                }
            }
            // get Categories
            if(!categoryNameSet.isEmpty() || !categoryCodeSet.isEmpty()) {
                for(Orga_HE__c item : [SELECT Id, Name, Elt_Code__c, Path__c FROM Orga_HE__c
                                       WHERE Status__c = 'Active' AND (Elt_Code__c IN :categoryCodeSet OR Name IN :categoryNameSet)]) 
                {
                    if(categoryNameSet.contains(item.Name.toLowerCase()) && !categoryNameMap.containsKey(item.Name.toLowerCase())) {
                        categoryNameMap.put(item.Name.toLowerCase(), item);
                    }
                    if(categoryCodeSet.contains(item.Elt_Code__c.toLowerCase()) && !categoryCodeMap.containsKey(item.Elt_Code__c.toLowerCase())) {
                        categoryCodeMap.put(item.Elt_Code__c.toLowerCase(), item);
                    }
                }
            }
            // get Products
            if(!productEANSet.isEmpty()) {
                for(Product2 item : [SELECT Id, Name, Product_EAN__c FROM Product2
                                     WHERE IsActive = TRUE AND Product_EAN__c IN :productEANSet])
                {
                    if(!productMap.containsKey(item.Product_EAN__c.toLowerCase())) {
                        productMap.put(item.Product_EAN__c.toLowerCase(), item);
                    }
                }
            }
            // get old market details linked to banners BU and Status__c='Scan w/ success'
            Map<String, Market_Data_Collection_Detail__c> oldRelatedMarketDetailsMap = new Map<String, Market_Data_Collection_Detail__c>();
            if(!buListMap.isEmpty()) {
                // case re-scan market details(BU type List and related to Banners)
                for(Market_Data_Collection_Detail__c item : [SELECT Id, Name, Market_Data_Collection_Head__c, Orga_BU__c, Product__c, Year__c, SEQ__c, Sequence_Type__c
                                                             FROM Market_Data_Collection_Detail__c
                                                             WHERE Market_Data_Collection_Head__c IN :marketHeadIdSet AND Orga_BU__c IN :buBannerSet AND Year__c IN :yearSet AND SEQ__c IN :monthSet
                                                             AND Orga_BU__c <> NULL AND Product__c <> NULL AND Orga_HE__c <> NULL])
                {
                    String key = item.Market_Data_Collection_Head__c + '' + item.Orga_BU__c + '' + item.Product__c + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.SEQ__c) + '' + item.Sequence_Type__c;
                    oldRelatedMarketDetailsMap.put(key, item);
                }
            }
            // Prepare Scan Process
            Map<Id, List<MarketDetailWrapper>> relatedMarketDetailsMap = new Map<Id, List<MarketDetailWrapper>>();
            for(Market_Data_Collection_Detail__c item : scope) {
                Market_Data_Collection_Detail__c initialMarketDetail = item.clone(true);
                MarketDetailWrapper wMarketDetail = new MarketDetailWrapper(initialMarketDetail);
                // INTEGRITY CONTROL: a- Check Mandatory fields
                wMarketDetail.CheckMandatoryFields();
                if(!wMarketDetail.scanIsValid) {
                    // Error
                }
                // Data Mapping : b- Check BU, Category and Product
                if((String.IsNotBlank(item.Ext_Category_Name__c) && categoryNameMap.containsKey(item.Ext_Category_Name__c.toLowerCase())) || (String.IsNotBlank(item.Ext_Category_Code__c) && categoryCodeMap.containsKey(item.Ext_Category_Code__c.toLowerCase()))) {
                    if(String.IsNotBlank(item.Ext_Category_Name__c)) wMarketDetail.refCategory = categoryNameMap.get(item.Ext_Category_Name__c.toLowerCase());
                    if(wMarketDetail.refCategory == null && String.IsNotBlank(item.Ext_Category_Code__c)) wMarketDetail.refCategory = categoryCodeMap.get(item.Ext_Category_Code__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_Product_EAN__c)) {
                    if(productMap.containsKey(item.Ext_Product_EAN__c.toLowerCase())) {
                        wMarketDetail.refProduct = productMap.get(item.Ext_Product_EAN__c.toLowerCase());
                    }
                }
                if((String.IsNotBlank(item.Ext_BU_Name__c) && buNameMap.containsKey(item.Ext_BU_Name__c.toLowerCase())) || (String.IsNotBlank(item.Ext_BU_Code__c) && buCodeMap.containsKey(item.Ext_BU_Code__c.toLowerCase()))) {
                    Orga_BU__c bu;
                    if(String.IsNotBlank(item.Ext_BU_Name__c)) bu = buNameMap.get(item.Ext_BU_Name__c.toLowerCase());
                    if(bu == null && String.IsNotBlank(item.Ext_BU_Code__c)) bu = buCodeMap.get(item.Ext_BU_Code__c.toLowerCase());
                    if(bu != null) {
                        // check if Header BU type = 'List'
                        if(bu.RecordType.DeveloperName == 'List' && !bu.List_detail1__r.isEmpty()) {
                            String key = '';
                            if(item.Orga_BU__c != null && wMarketDetail.refProduct != null) {
                                // check if initial market detail with BU='Banner' already exist
                                key = item.Market_Data_Collection_Head__c + '' + item.Orga_BU__c + '' + wMarketDetail.refProduct.Id + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.SEQ__c) + '' + item.Sequence_Type__c;
                                if(oldRelatedMarketDetailsMap.containsKey(key)) {
                                    wMarketDetail.refBUId = item.Orga_BU__c;
                                } else {
                                    // case Banner not exist in List
                                    wMarketDetail.marketDetail.Orga_BU__c = null;
                                }
                            }
                            // get BUs child type = 'Banner'
                            for(Orga_BU_List_Detail__c buListDetail : bu.List_detail1__r) {
                                if(wMarketDetail.refBUId == null) {
                                    // linked first banner to initial record
                                    wMarketDetail.refBUId = buListDetail.Entity_List__c;
                                    wMarketDetail.setValues(buListDetail);
                                } else {
                                    // case linked first banner to initial record
                                    if(wMarketDetail.refBUId != null && wMarketDetail.refBUId == buListDetail.Entity_List__c) {
                                        // calculate nielsen split value
                                        wMarketDetail.setValues(buListDetail);
                                        continue;
                                    }
                                    Market_Data_Collection_Detail__c relatedMarketDetail = item.clone(false);
                                    relatedMarketDetail.Ext_BU_Name__c = null;
                                    // check if related market detail with BU Banner already exist
                                    if(wMarketDetail.refProduct != null) {
                                        key = item.Market_Data_Collection_Head__c + '' + buListDetail.Entity_List__c + '' + wMarketDetail.refProduct.Id + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.SEQ__c) + '' + item.Sequence_Type__c;
                                        if(oldRelatedMarketDetailsMap.containsKey(key)) {
                                            if(item.Id == oldRelatedMarketDetailsMap.get(key).Id) continue;
                                            relatedMarketDetail.Id = oldRelatedMarketDetailsMap.get(key).Id;
                                        }
                                    }
                                    relatedMarketDetail.Orga_BU__c = buListDetail.Entity_List__c;
                                    MarketDetailWrapper relatedMarketDetailWrapper = new MarketDetailWrapper(relatedMarketDetail);
                                    relatedMarketDetailWrapper.setValues(buListDetail);
                                    if(!relatedMarketDetailsMap.containsKey(item.Id)) {
                                        relatedMarketDetailsMap.put(item.Id, new List<MarketDetailWrapper>{relatedMarketDetailWrapper});
                                    } else {
                                        relatedMarketDetailsMap.get(item.Id).add(relatedMarketDetailWrapper);
                                    }
                                }
                            }
                        } else {
                            wMarketDetail.refBUId = bu.Id;
                        }
                    }
                }
                // Scan Market Details
                wMarketDetail.scanMarketDetails();
                // Fill Scan Results
                if(!wMarketDetail.scanIsValid) {
                    if(relatedMarketDetailsMap.containsKey(wMarketDetail.marketDetail.Id)) {
                        // remove related banners to List
                        relatedMarketDetailsMap.remove(wMarketDetail.marketDetail.Id);
                    }
                    wMarketDetail.marketDetail.Status__c = 'Scan w/ error';
                    // update market head status
                    MarketHeadWrapper wMarketHead;
                    if(!wMarketHeadMap.containsKey(item.Market_Data_Collection_Head__c)) {
                        wMarketHead = new MarketHeadWrapper(item.Market_Data_Collection_Head__c);
                    } else {
                        wMarketHead = wMarketHeadMap.get(item.Market_Data_Collection_Head__c);
                    }
                    wMarketHead.actionToDoMessage += item.Name + ' (' + item.Id + ') : ' + wMarketDetail.actionToDoMessage + '\n';
                    wMarketHeadMap.put(item.Market_Data_Collection_Head__c, wMarketHead);
                } else {
                    wMarketDetail.marketDetail.Status__c = 'Scan w/ success';
                    // update taxes
                    wMarketDetail.setTax(taxesMap);
                }
                wMarketDetail.marketDetail.Action_ToDo__c = wMarketDetail.actionToDoMessage;
                wMarketDetail.marketDetail.Action_done__c = wMarketDetail.actionDoneMessage;
                wMarketDetail.marketDetail.Last_Scan_Date__c = System.now();
                wMarketDetailMap.put(item.Id, wMarketDetail);
            }
            // processing scan market details linked to BU Banner
            if(!relatedMarketDetailsMap.isEmpty()) {
                for(Id marketDetailId : relatedMarketDetailsMap.keySet()) {
                    MarketDetailWrapper wMarketDetail = wMarketDetailMap.get(marketDetailId);
                    List<MarketDetailWrapper> relatedMarketDetailsList = relatedMarketDetailsMap.get(marketDetailId);
                    for(MarketDetailWrapper item : relatedMarketDetailsList) {
                        item.marketDetail.Status__c = wMarketDetail.marketDetail.Status__c;
                        item.marketDetail.Orga_HE__c = wMarketDetail.marketDetail.Orga_HE__c;
                        item.marketDetail.Product__c = wMarketDetail.marketDetail.Product__c;
                        item.marketDetail.Action_ToDo__c = wMarketDetail.marketDetail.Action_ToDo__c;
                        item.marketDetail.Action_done__c = wMarketDetail.marketDetail.Action_done__c;
                        item.marketDetail.Last_Scan_Date__c = wMarketDetail.marketDetail.Last_Scan_Date__c;
                        // update taxes
                        item.setTax(taxesMap);
                        marketDetailsList.add(item.marketDetail);
                    }
                }
            }
            // fill market details list
            for (MarketDetailWrapper item : wMarketDetailMap.values()) {
                marketDetailsList.add(item.marketDetail);
            }
            
            // check security on updated market head fields
            String[] marketHeadUpdatedFields = new String[] {NegoptimHelper.normalizeAPIName('Action_Todo__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Last_Scan_Date__c')};
          
            // check security on updated market details fields
            String[] marketDetailsUpdatedFields = new String[] {NegoptimHelper.normalizeAPIName('Action_Done__c'), NegoptimHelper.normalizeAPIName('Action_Todo__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Orga_HE__c'), NegoptimHelper.normalizeAPIName('Product__c'),
                NegoptimHelper.normalizeAPIName('Orga_BU__c'), NegoptimHelper.normalizeAPIName('Last_Scan_Date__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_SEQ__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SEQ__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SEQ__c'), NegoptimHelper.normalizeAPIName('SellOut_woTax_SEQ__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_YTD__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_YTD__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_YTD__c'), NegoptimHelper.normalizeAPIName('SellOut_woTax_YTD__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_12M__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_12M__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_12M__c'), NegoptimHelper.normalizeAPIName('SellOut_woTax_12M__c'),
                NegoptimHelper.normalizeAPIName('SellOut_woTax_SSEQ0__c'), NegoptimHelper.normalizeAPIName('SellOut_woTax_SSEQ1__c'), NegoptimHelper.normalizeAPIName('SellOut_woTax_SSEQ2__c'), NegoptimHelper.normalizeAPIName('SellOut_woTax_SSEQ3__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ0__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ1__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ2__c'), NegoptimHelper.normalizeAPIName('SellOut_Quantity_SSEQ3__c'),
                NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ0__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ1__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ2__c'), NegoptimHelper.normalizeAPIName('SellOut_Tone_SSEQ3__c'),
                NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ0__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ1__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ2__c'), NegoptimHelper.normalizeAPIName('SellOut_wTax_SSEQ3__c')};
            
            String[] marketDataCollectionDetailsInsertedFields = new String[]{NegoptimHelper.normalizeAPIName('Market_Data_Collection_Head__c')};
            marketDataCollectionDetailsInsertedFields.addAll(marketDetailsUpdatedFields);
            
            // Upsert market details
            if(!marketDetailsList.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Market_Data_Collection_Detail__c.SObjectType, marketDataCollectionDetailsInsertedFields) &&
                   NegoptimHelper.checkUpdatibility(Market_Data_Collection_Detail__c.SObjectType, marketDetailsUpdatedFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(marketDetailsList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results.get(i);
                        Market_Data_Collection_Detail__c marketDetail = marketDetailsList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = marketDetail.Name + ' (' + marketDetail.Id + ') : ';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                            // update market head status
                            MarketHeadWrapper wMarketHead;
                            if(!wMarketHeadMap.containsKey(marketDetail.Market_Data_Collection_Head__c)) {
                                wMarketHead = new MarketHeadWrapper(marketDetail.Market_Data_Collection_Head__c);
                            } else {
                                wMarketHead = wMarketHeadMap.get(marketDetail.Market_Data_Collection_Head__c);
                            }
                            wMarketHead.actionToDoMessage += errorMessage;
                            wMarketHeadMap.put(marketDetail.Market_Data_Collection_Head__c, wMarketHead);
                        } else {
                            // fill weekly data collection list for MarketDataCollectionConsolidationBatch
                            if(marketDetail.Status__c == 'Scan w/ success' /*&& marketDetail.Sequence_Type__c == 'Week'*/) {
                                this.marketDetailIds.add(marketDetail.Id);
                            }
                        }
                    }
                }
            }
            // Update market head with detail errors
            if(!wMarketHeadMap.isEmpty()) {
                if(NegoptimHelper.checkUpdatibility(Market_Data_Collection_Head__c.SObjectType, marketHeadUpdatedFields)) {
                    List<Market_Data_Collection_Head__c> marketHeadList = new List<Market_Data_Collection_Head__c>();
                    for(Market_Data_Collection_Head__c marketHead : [SELECT Id, Name, Action_Todo__c, Status__c, Last_Scan_Date__c
                                                                     FROM Market_Data_Collection_Head__c
                                                                     WHERE Id IN :wMarketHeadMap.keySet()])
                    {
                        MarketHeadWrapper wMarketHead = wMarketHeadMap.get(marketHead.Id);
                        String actionTODOMessage = marketHead.Action_Todo__c != null ? marketHead.Action_Todo__c : '';                    
                        marketHead.Action_Todo__c = actionTODOMessage + wMarketHead.actionToDoMessage;
                        if(String.isNotBlank(marketHead.Action_Todo__c) && marketHead.Action_Todo__c.length() > 31000) {
                            marketHead.Action_Todo__c = marketHead.Action_Todo__c.substring(0, 31000) + '... (message truncated)';
                        }
                        ////marketHead.Status__c = 'Scan w/ error';
                        marketHead.Last_Scan_Date__c = System.now();
                        marketHeadList.add(marketHead);
                    }
                    List<Database.SaveResult> results = Database.update(marketHeadList, false);
                    nb.logResults(results, marketHeadList);
                }
            }
        }
        catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        }
        catch (Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        // Call MarketDataCollectionConsolidationBatch
        if(!this.marketDetailIds.isEmpty()) {
            Database.executeBatch(new MarketDataCollectionConsolidationBatch('MarketDataCollectionDetailScanBatch', this.marketDetailIds), 150);
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    // Market Details Wrapper
    public class MarketDetailWrapper {
        public Market_Data_Collection_Detail__c marketDetail {get; set;}
        public Id refBUId {get; set;}
        public Orga_HE__c refCategory {get; set;}
        public Product2 refProduct {get; set;}
        public Boolean scanIsValid {get; set;}
        public String actionToDoMessage {get; set;}
        public String actionDoneMessage {get; set;}
        public Boolean isWeekly {
            get {
                return this.marketDetail.Sequence_Type__c == 'Week';
            }
            set;
        }
        public MarketDetailWrapper(Market_Data_Collection_Detail__c marketDetail) {
            this.marketDetail = marketDetail;
            this.refBUId = null;
            this.refCategory = null;
            this.refProduct = null;
            this.scanIsValid = true;
            this.actionToDoMessage = '';
            this.actionDoneMessage = '';
        }
        
        // scan market details
        public void scanMarketDetails() {
            if(this.refBUId == null) {
                this.actionToDoMessage += Label.MSG_BU_Not_Exist + '\n';
                this.scanIsValid = false;
            } else {
                marketDetail.Orga_BU__c = this.refBUId;
            }
            if(this.refCategory == null) {
                this.actionToDoMessage += Label.MSG_Category_Not_Exist + '\n';
                this.scanIsValid = false;
            } else {
                marketDetail.Orga_HE__c = this.refCategory.Id;
            }
            if(this.refProduct == null) {
                this.actionToDoMessage += Label.MSG_Product_Not_Exist + '\n';
                this.scanIsValid = false;
            } else {
                marketDetail.Product__c = this.refProduct.Id;
            }
            if(!this.isWeekly) {
                if(marketDetail.Average_Retail_Price_SEQ__c == null) {
                    this.actionToDoMessage += Label.MSG_Average_Retail_Price_Empty + '\n';
                }
                if(marketDetail.ND_1_12M__c == null && marketDetail.ND_1_SEQ__c == null && marketDetail.ND_1_YTD__c == null &&
                   marketDetail.ND_2_12M__c == null && marketDetail.ND_2_SEQ__c == null && marketDetail.ND_2_YTD__c == null)
                {
                    this.actionToDoMessage += Label.MSG_ND_Empty + '\n';
                }
                if(marketDetail.WD_1_12M__c == null && marketDetail.WD_1_SEQ__c == null && marketDetail.WD_1_YTD__c == null &&
                   marketDetail.WD_2_12M__c == null && marketDetail.WD_2_SEQ__c == null && marketDetail.WD_2_YTD__c == null)
                {
                    this.actionToDoMessage += Label.MSG_WD_Empty + '\n';
                }
            }
        }
        // Check Mandatory Fields
        public void CheckMandatoryFields() {
            // Check missing fields
            if((marketDetail.Ext_BU_Name__c == null && marketDetail.Ext_BU_Code__c == null) || (marketDetail.Ext_Category_Code__c == null && marketDetail.Ext_Category_Name__c == null) ||
               marketDetail.Ext_Product_EAN__c == null || (marketDetail.Ext_Brand_Name__c == null && marketDetail.Ext_Brand_Code__c == null) || marketDetail.Ext_Packaging__c == null)
            {
                if(marketDetail.Ext_BU_Name__c == null && marketDetail.Ext_BU_Code__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketDetailFieldNameLabels.get('Ext_BU_Name__c') + ', ' + marketDetailFieldNameLabels.get('Ext_BU_Code__c')}) + '\n';
                if(marketDetail.Ext_Category_Name__c == null && marketDetail.Ext_Category_Code__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketDetailFieldNameLabels.get('Ext_Category_Name__c') + ', ' + marketDetailFieldNameLabels.get('Ext_Category_Code__c') }) + '\n';
                if(marketDetail.Ext_Product_EAN__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketDetailFieldNameLabels.get('Ext_Product_EAN__c') }) + '\n';
                if(marketDetail.Ext_Brand_Name__c == null && marketDetail.Ext_Brand_Code__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketDetailFieldNameLabels.get('Ext_Brand_Name__c') + ', ' + marketDetailFieldNameLabels.get('Ext_Brand_Code__c')}) + '\n';
                if(marketDetail.Ext_Packaging__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketDetailFieldNameLabels.get('Ext_Packaging__c') }) + '\n';
                this.scanIsValid = false;
            }
        }
        
        public void setValues(Orga_BU_List_Detail__c buListDetail) {
            Decimal nielsenSplitValue = buListDetail.Nielsen_Split__c != null ? buListDetail.Nielsen_Split__c/100 : 0;
            if(this.marketDetail.SellOut_Quantity_SEQ__c != null) this.marketDetail.SellOut_Quantity_SEQ__c = this.marketDetail.SellOut_Quantity_SEQ__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_Tone_SEQ__c != null) this.marketDetail.SellOut_Tone_SEQ__c = this.marketDetail.SellOut_Tone_SEQ__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_wTax_SEQ__c != null) this.marketDetail.SellOut_wTax_SEQ__c = this.marketDetail.SellOut_wTax_SEQ__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_woTax_SEQ__c != null) this.marketDetail.SellOut_woTax_SEQ__c = this.marketDetail.SellOut_woTax_SEQ__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_Quantity_YTD__c != null) this.marketDetail.SellOut_Quantity_YTD__c = this.marketDetail.SellOut_Quantity_YTD__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_Tone_YTD__c != null) this.marketDetail.SellOut_Tone_YTD__c = this.marketDetail.SellOut_Tone_YTD__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_wTax_YTD__c != null) this.marketDetail.SellOut_wTax_YTD__c = this.marketDetail.SellOut_wTax_YTD__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_woTax_YTD__c != null) this.marketDetail.SellOut_woTax_YTD__c = this.marketDetail.SellOut_woTax_YTD__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_Quantity_12M__c != null) this.marketDetail.SellOut_Quantity_12M__c = this.marketDetail.SellOut_Quantity_12M__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_Tone_12M__c != null) this.marketDetail.SellOut_Tone_12M__c = this.marketDetail.SellOut_Tone_12M__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_wTax_12M__c != null) this.marketDetail.SellOut_wTax_12M__c = this.marketDetail.SellOut_wTax_12M__c * nielsenSplitValue;
            if(this.marketDetail.SellOut_woTax_12M__c != null) this.marketDetail.SellOut_woTax_12M__c = this.marketDetail.SellOut_woTax_12M__c * nielsenSplitValue;
            if(this.isWeekly) {
                if(this.marketDetail.SellOut_Quantity_SSEQ0__c != null) this.marketDetail.SellOut_Quantity_SSEQ0__c = this.marketDetail.SellOut_Quantity_SSEQ0__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_Quantity_SSEQ1__c != null) this.marketDetail.SellOut_Quantity_SSEQ1__c = this.marketDetail.SellOut_Quantity_SSEQ1__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_Quantity_SSEQ2__c != null) this.marketDetail.SellOut_Quantity_SSEQ2__c = this.marketDetail.SellOut_Quantity_SSEQ2__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_Quantity_SSEQ3__c != null) this.marketDetail.SellOut_Quantity_SSEQ3__c = this.marketDetail.SellOut_Quantity_SSEQ3__c * nielsenSplitValue;
                
                if(this.marketDetail.SellOut_Tone_SSEQ0__c != null) this.marketDetail.SellOut_Tone_SSEQ0__c = this.marketDetail.SellOut_Tone_SSEQ0__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_Tone_SSEQ1__c != null) this.marketDetail.SellOut_Tone_SSEQ1__c = this.marketDetail.SellOut_Tone_SSEQ1__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_Tone_SSEQ2__c != null) this.marketDetail.SellOut_Tone_SSEQ2__c = this.marketDetail.SellOut_Tone_SSEQ2__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_Tone_SSEQ3__c != null) this.marketDetail.SellOut_Tone_SSEQ3__c = this.marketDetail.SellOut_Tone_SSEQ3__c * nielsenSplitValue;
                
                if(this.marketDetail.SellOut_wTax_SSEQ0__c != null) this.marketDetail.SellOut_wTax_SSEQ0__c = this.marketDetail.SellOut_wTax_SSEQ0__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_wTax_SSEQ1__c != null) this.marketDetail.SellOut_wTax_SSEQ1__c = this.marketDetail.SellOut_wTax_SSEQ1__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_wTax_SSEQ2__c != null) this.marketDetail.SellOut_wTax_SSEQ2__c = this.marketDetail.SellOut_wTax_SSEQ2__c * nielsenSplitValue;
                if(this.marketDetail.SellOut_wTax_SSEQ3__c != null) this.marketDetail.SellOut_wTax_SSEQ3__c = this.marketDetail.SellOut_wTax_SSEQ3__c * nielsenSplitValue;
            }
        }
        
        public void setTax(Map<String, Orga_Taxes__c> taxesMap) {
            String key = this.marketDetail.Market_Data_Collection_Head__r.Master_BU__c + '' + this.refCategory.Path__c;
            for(String taxKey : taxesMap.keySet()) {
                if(key.contains(taxKey)) {
                    Orga_Taxes__c tax = taxesMap.get(taxKey);
                    Decimal taxPercent = tax != null && tax.Tax_percent__c != null ? tax.Tax_percent__c/100 : 0;
                    this.marketDetail.SellOut_woTax_SEQ__c = this.marketDetail.SellOut_wTax_SEQ__c != null ? (this.marketDetail.SellOut_wTax_SEQ__c - this.marketDetail.SellOut_wTax_SEQ__c * taxPercent) : 0;
                    this.marketDetail.SellOut_woTax_YTD__c = this.marketDetail.SellOut_wTax_YTD__c != null ? (this.marketDetail.SellOut_wTax_YTD__c - this.marketDetail.SellOut_wTax_YTD__c * taxPercent) : 0;
                    this.marketDetail.SellOut_woTax_12M__c = this.marketDetail.SellOut_wTax_12M__c != null ? (this.marketDetail.SellOut_wTax_12M__c - this.marketDetail.SellOut_wTax_12M__c * taxPercent) : 0;
                    if(this.isWeekly) {
                        this.marketDetail.SellOut_woTax_SSEQ0__c = this.marketDetail.SellOut_wTax_SSEQ0__c != null ? (this.marketDetail.SellOut_wTax_SSEQ0__c - this.marketDetail.SellOut_wTax_SSEQ0__c * taxPercent) : 0;
                        this.marketDetail.SellOut_woTax_SSEQ1__c = this.marketDetail.SellOut_wTax_SSEQ1__c != null ? (this.marketDetail.SellOut_wTax_SSEQ1__c - this.marketDetail.SellOut_wTax_SSEQ1__c * taxPercent) : 0;
                        this.marketDetail.SellOut_woTax_SSEQ2__c = this.marketDetail.SellOut_wTax_SSEQ2__c != null ? (this.marketDetail.SellOut_wTax_SSEQ2__c - this.marketDetail.SellOut_wTax_SSEQ2__c * taxPercent) : 0;
                        this.marketDetail.SellOut_woTax_SSEQ3__c = this.marketDetail.SellOut_wTax_SSEQ3__c != null ? (this.marketDetail.SellOut_wTax_SSEQ3__c - this.marketDetail.SellOut_wTax_SSEQ3__c * taxPercent) : 0;
                    }
                    break;
                }
            }
        }
    }
    
    // Market Head Wrapper
    public class MarketHeadWrapper {
        public Id marketHeadId {get; set;}
        public String actionToDoMessage {get; set;}
        public MarketHeadWrapper(Id marketHeadId) {
            this.marketHeadId = marketHeadId;
            this.actionToDoMessage = '';
        }        
    }
}