/*
 * Load csv files contains market data head and details
 */ 
public with sharing class MarketDataCollectionImportBatch implements Database.Batchable<String>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String fileName;
    private Map<String, Id> fileIdMap;
    private Integer fileNumber;
    private Id masterBUId;
    
    private String contents;
    private Integer columnsCount;
    private String flowType;
    private Date movementDate;
    private String categoryName;
    private Boolean isWeekly = false;
    private Boolean isMonthly = false;
    private Integer sequence;
    private Integer year;
    private String errorMessage = '';
    private Integer lineIndex;
    private RowHeaderWrapper rowHeader;
    
    private Set<Id> marketHeadIds;
    private Boolean isUpdatedImport = false;
    /* @params description :
     * fileIdMap: list of files uploaded with sequences
     * fileNumber: file number imported
     * masterBUId: marter BU (ex. HMSM)
     * flowType: ex. Nielsen
     * categoryName: category name (ex. Compote)
     * isWeekly: case market data collection weekly - file format Nielsen_Category_WWWYYYY_4SDDMMYYYY
     * isMonthly: case market data collection monthly - file format Nielsen_Category_MWWYYYY_4SDDMMYYYY
     */ 
    public MarketDataCollectionImportBatch(String startedFrom, Map<String, Id> fileIdMap, Integer fileNumber, Id masterBUId,
                                           String flowType, String categoryName, Boolean isWeekly, Boolean isMonthly, Integer year, Integer month,
                                           RowHeaderWrapper rowHeaderWrapper, Set<Id> marketHeadIds)
    {
        this.nb = new NegoptimBatch('MarketDataCollectionImportBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.fileIdMap = fileIdMap;
        this.fileNumber = fileNumber;
        this.masterBUId = masterBUId;
        this.marketHeadIds = marketHeadIds != null ? marketHeadIds : new Set<Id>();
        this.rowHeader = rowHeaderWrapper;
        
        try {
            // get file contents
            Id fileId = this.fileIdMap.get(String.valueOf(fileNumber));
            List<ContentVersion> contentVersions = [SELECT Id, title, versionData FROM ContentVersion WHERE Id = :fileId];
            if(contentVersions != null && !contentVersions.isEmpty()) {
                ContentVersion contentVersion = contentVersions[0];
                this.fileName = contentVersion.title;
                this.contents = NegoptimHelper.decodeBlob(contentVersion.versionData, 'UTF-8');                
            } else {
                this.contents = '';
                this.errorMessage = 'ERROR: file not found.';
            }
            this.flowType = flowType;
            this.categoryName = categoryName;
            this.isWeekly = isWeekly;
            this.isMonthly = isMonthly;
            this.year = year;
            this.sequence = month;
        } catch (Exception ex) {
            this.contents = '';
            this.errorMessage = 'ERROR: ' + ex.getMessage() + ' - ' + ex.getLineNumber();
            nb.logError(ex);
        }
    }
    
    public Iterable<String> start(Database.BatchableContext batchableContext) {
        return new CSVIterator(this.contents, CSVParser.LF);
    }
    
    public void execute(Database.BatchableContext batchableContext, List<String> scope) {
        // Parsing CSV file.
        List<List<String>> records = NegoptimHelper.parseCSV(scope, false, GlobalSettingsManager.loadGlobalSettings().delimiter);
        // Map<BU + year + month, market collection details>
        Map<String, List<RowDetailWrapper>> marketDataRowsMap = new Map<String, List<RowDetailWrapper>>();
        List<MarketDataCollectionWrapper> marketDataCollectionList = new List<MarketDataCollectionWrapper>();
        Set<Id> oldMarketHeadIds = new Set<Id>();
        Set<String> buNameSet = new Set<String>();
        Set<String> productEANSet = new Set<String>();
        Set<String> productNameSet = new Set<String>();
        
        // Fill the initial map.
        lineIndex = 0;
        Savepoint sp = Database.setSavepoint();
        try {
            for(List<String> record : records) {
                // get sequence date from the first row
                if(this.fileNumber == 1) {
                    // error found in constructor
                    if(String.isNotBlank(this.errorMessage)) break;
                    if(lineIndex == 0) {
                        this.rowHeader = new RowHeaderWrapper(lineIndex, record, this.isMonthly, this.isWeekly);
                        if(!this.rowHeader.validateRowHeader(this.categoryName, this.year, this.sequence)) {
                            this.errorMessage += this.rowHeader.errorMessage;
                        }
                        lineIndex++;
                        continue;
                    }
                    // check columns count
                    if(lineIndex == 1) {
                        if(record.size() == this.rowHeader.columnsCount) {
                            lineIndex++;
                        } else {
                            this.errorMessage += 'line ' + lineIndex + ':' + string.format(Label.MSG_Invalid_Columns_Count, new String[]{ String.valueOf(record.size()), String.valueOf(this.rowHeader.columnsCount) }) + ' \n';
                            lineIndex++;
                        }
                        continue;
                    }
                }
                if(String.isNotBlank(this.errorMessage)) {
                    break;
                }
                // if first columns contains BU name
                if(record[0] != '') {
                    lineIndex++;
                    continue;
                }
                // fill market details collection
                RowDetailWrapper rowDetailWrapper = new RowDetailWrapper(lineIndex, record);
                if(!rowDetailWrapper.validateRowDetail(this.rowHeader)) {
                    this.errorMessage += rowDetailWrapper.errorMessage;
                    lineIndex++;
                    continue;
                }
                // fill BUs and products
                if(!buNameSet.contains(rowDetailWrapper.buName.toLowerCase())) {
                    buNameSet.add(rowDetailWrapper.buName.toLowerCase());
                }
                if(String.isNotBlank(rowDetailWrapper.productEAN) && !productEANSet.contains(rowDetailWrapper.productEAN.toLowerCase())) {
                    productEANSet.add(rowDetailWrapper.productEAN.toLowerCase());
                }
                if(String.isNotBlank(rowDetailWrapper.productName) && !productNameSet.contains(rowDetailWrapper.productName.toLowerCase())) {
                    productNameSet.add(rowDetailWrapper.productName.toLowerCase());
                }
                // fill map grouped by bu
                if(!marketDataRowsMap.ContainsKey(rowDetailWrapper.buName)) {
                    marketDataRowsMap.put(rowDetailWrapper.buName, new List<RowDetailWrapper>{rowDetailWrapper});
                } else {
                    marketDataRowsMap.get(rowDetailWrapper.buName).add(rowDetailWrapper);
                }
                lineIndex++;
            }
            if(String.isBlank(this.errorMessage)) {
                // get old market head : Map<category+bu+seq+year, old marked head collection>
                Map<String, Market_Data_Collection_Head__c> oldMarketHeadMap = new Map<String, Market_Data_Collection_Head__c>();
                List<Market_Data_Collection_Head__c> oldMarketHeadList = [SELECT Id, Ext_Category_Name__c, Ext_BU_Name__c, Year__c, SEQ__c,
                                                                          Flow_Type__c, Master_BU__c, Movement_Date__c, Origin_Type__c, Status__c
                                                                          FROM Market_Data_Collection_Head__c
                                                                          WHERE Ext_Category_Name__c = :this.categoryName
                                                                          AND Ext_BU_Name__c IN :buNameSet
                                                                          AND Year__c = :this.year
                                                                          AND SEQ__c = :this.sequence];
                if(!oldMarketHeadList.isEmpty()) {
                    for(Market_Data_Collection_Head__c item : oldMarketHeadList) {
                        String key = item.Ext_Category_Name__c + '' + item.Ext_BU_Name__c + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.SEQ__c);
                        oldMarketHeadMap.put(key, item);
                        oldMarketHeadIds.add(item.Id);
                    }
                }
                // get old market details(Monthly and Weekly) : Map<category+bu+product+seq+year, old marked details collection>
                Map<String, Market_Data_Collection_Detail__c> oldMarketDetailsMap = new Map<String, Market_Data_Collection_Detail__c>();
                List<Market_Data_Collection_Detail__c> oldMarketDetailsList;
                if(this.rowHeader.isWeekly || (this.rowHeader.isMonthly && this.rowHeader.isCADCAM)) {
                    oldMarketDetailsList = [SELECT Id, Market_Data_Collection_Head__c, Ext_Category_Name__c,
                                            Ext_BU_Name__c, Ext_Product_Name__c, Ext_Product_EAN__c, Year__c, SEQ__c, Sequence_Number__c,
                                            // SEQ Weekly
                                            Date_SSEQ0__c, Date_SSEQ1__c, Date_SSEQ2__c, Date_SSEQ3__c, Date_SSEQ4__c, Date_SSEQ5__c, Weight_SSEQ0__c, Weight_SSEQ1__c, Weight_SSEQ2__c, Weight_SSEQ3__c, Weight_SSEQ4__c, Weight_SSEQ5__c,
                                            SellOut_Quantity_SSEQ0__c, SellOut_Quantity_SSEQ1__c, SellOut_Quantity_SSEQ2__c, SellOut_Quantity_SSEQ3__c, SellOut_Quantity_SSEQ4__c, SellOut_Quantity_SSEQ5__c,
                                            SellOut_Tone_SSEQ0__c, SellOut_Tone_SSEQ1__c, SellOut_Tone_SSEQ2__c, SellOut_Tone_SSEQ3__c, SellOut_Tone_SSEQ4__c, SellOut_Tone_SSEQ5__c,
                                            SellOut_wTax_SSEQ0__c, SellOut_wTax_SSEQ1__c, SellOut_wTax_SSEQ2__c, SellOut_wTax_SSEQ3__c, SellOut_wTax_SSEQ4__c, SellOut_wTax_SSEQ5__c,
                                            ND_1_SSEQ0__c, ND_1_SSEQ1__c, ND_1_SSEQ2__c, ND_1_SSEQ3__c, ND_1_SSEQ4__c, ND_1_SSEQ5__c,
                                            ND_2_SSEQ0__c, ND_2_SSEQ1__c, ND_2_SSEQ2__c, ND_2_SSEQ3__c, ND_2_SSEQ4__c, ND_2_SSEQ5__c,
                                            WD_1_SSEQ0__c, WD_1_SSEQ1__c, WD_1_SSEQ2__c, WD_1_SSEQ3__c, WD_1_SSEQ4__c, WD_1_SSEQ5__c,
                                            WD_2_SSEQ0__c, WD_2_SSEQ1__c, WD_2_SSEQ2__c, WD_2_SSEQ3__c, WD_2_SSEQ4__c, WD_2_SSEQ5__c,
                                            //YTD
                                            SellOut_Quantity_YTD__c, SellOut_Tone_YTD__c, SellOut_wTax_YTD__c, ND_1_YTD__c, WD_1_YTD__c, ND_2_YTD__c, WD_2_YTD__c, Average_Retail_Price_YTD__c,
                                            //12M
                                            SellOut_Quantity_12M__c, SellOut_Tone_12M__c, SellOut_wTax_12M__c, ND_1_12M__c, WD_1_12M__c, ND_2_12M__c, WD_2_12M__c, Average_Retail_Price_12M__c, Sequence_Type__c, Status__c
                                            FROM Market_Data_Collection_Detail__c
                                            WHERE Market_Data_Collection_Head__c IN :oldMarketHeadIds
                                            AND (Ext_Product_Name__c IN :productNameSet OR Ext_Product_EAN__c IN :productEANSet)
                                            AND Ext_BU_Name__c IN :buNameSet
                                            AND Year__c = :this.year AND SEQ__c = :this.sequence AND Sequence_Type__c = 'Week' AND Ext_BU_Name__c <> NULL
                                            ORDER BY Sequence_Number__c, Date_SSEQ0__c NULLS LAST, Date_SSEQ1__c NULLS LAST, Date_SSEQ2__c NULLS LAST,
                                            Date_SSEQ3__c NULLS LAST, Date_SSEQ4__c NULLS LAST, Date_SSEQ5__c NULLS LAST];
                } else if(this.rowHeader.isMonthly && !this.rowHeader.isCADCAM) {
                    oldMarketDetailsList = [SELECT Id, Market_Data_Collection_Head__c, Ext_Category_Name__c,
                                            Ext_BU_Name__c, Ext_Product_Name__c, Ext_Product_EAN__c, Year__c, SEQ__c, Sequence_Number__c,
                                            //SEQ Monthly
                                            SellOut_Quantity_SEQ__c, SellOut_Tone_SEQ__c, SellOut_wTax_SEQ__c, ND_1_SEQ__c, WD_1_SEQ__c, ND_2_SEQ__c, WD_2_SEQ__c, Average_Retail_Price_SEQ__c, Avg_Weekly_Sales_Ext_ClientBased__c,
                                            //YTD
                                            SellOut_Quantity_YTD__c, SellOut_Tone_YTD__c, SellOut_wTax_YTD__c, ND_1_YTD__c, WD_1_YTD__c, ND_2_YTD__c, WD_2_YTD__c, Average_Retail_Price_YTD__c,
                                            //12M
                                            SellOut_Quantity_12M__c, SellOut_Tone_12M__c, SellOut_wTax_12M__c, ND_1_12M__c, WD_1_12M__c, ND_2_12M__c, WD_2_12M__c, Average_Retail_Price_12M__c, Sequence_Type__c, Status__c
                                            FROM Market_Data_Collection_Detail__c
                                            WHERE Market_Data_Collection_Head__c IN :oldMarketHeadIds
                                            AND (Ext_Product_Name__c IN :productNameSet OR Ext_Product_EAN__c IN :productEANSet)
                                            AND Ext_BU_Name__c IN :buNameSet
                                            AND Year__c = :this.year AND SEQ__c = :this.sequence AND Sequence_Type__c = 'Month' AND Ext_BU_Name__c <> NULL];
                }
                if(oldMarketDetailsList != null && !oldMarketDetailsList.isEmpty()) {
                    for(Market_Data_Collection_Detail__c item : oldMarketDetailsList) {
                        String key = item.Ext_Product_Name__c + '' + (String.isNotBlank(item.Ext_Product_EAN__c) ? item.Ext_Product_EAN__c : '') + '' + item.Ext_Category_Name__c + '' +
                            item.Ext_BU_Name__c + '' + Integer.valueOf(item.Year__c) + '' + Integer.valueOf(item.SEQ__c) + '' + item.Sequence_Type__c;
                        if(!oldMarketDetailsMap.containsKey(key)) {
                            oldMarketDetailsMap.put(key, item);
                        }
                    }
                }
                
                List<Market_Data_Collection_Head__c> marketHeadList = new List<Market_Data_Collection_Head__c>();
                List<Market_Data_Collection_Detail__c> marketDetailsList = new List<Market_Data_Collection_Detail__c>();                
                for (String buName : marketDataRowsMap.keySet()) {
                    // get rows details by bu name
                    List<RowDetailWrapper> rowDetails = marketDataRowsMap.get(buName);
                    // fill market head
                    String keyHead = this.categoryName + '' + buName + '' + this.year + '' + this.sequence;
                    Market_Data_Collection_Head__c marketHead = null;
                    if(oldMarketHeadMap.containsKey(keyHead)) {
                        marketHead = oldMarketHeadMap.get(keyHead);
                        if(this.marketHeadIds.isEmpty() || !this.marketHeadIds.contains(marketHead.Id)) {
                            marketHead.Status__c = 'Updated';
                            this.isUpdatedImport = true;
                        }
                    } else {
                        marketHead = new Market_Data_Collection_Head__c(Ext_BU_Name__c = buName, Ext_Category_Name__c = this.categoryName,
                                                                        Flow_Type__c = this.flowType, Master_BU__c = this.masterBUId,
                                                                        Movement_Date__c = this.rowHeader.movementDate, Origin_Type__c = 'CSV', Status__c = 'New',
                                                                        SEQ__c = this.sequence, Year__c = this.year);
                        oldMarketHeadMap.put(keyHead, marketHead);
                    }
                    // fill wrapper data collection for current sequence
                    MarketDataCollectionWrapper marketDataCollectionWrapper = new MarketDataCollectionWrapper(this.rowHeader, marketHead, oldMarketDetailsMap);
                    // fill wrapper data collections
                    for (RowDetailWrapper item : rowDetails) {
                        String keyDetail = item.productName + '' + (String.isNotBlank(item.productEAN) ? item.productEAN : '') + '' + this.rowHeader.categoryName + '' + item.buName + '' + this.rowHeader.year + '' + this.rowHeader.sequence + '' + marketDataCollectionWrapper.sequenceType;
                        if(!marketDataCollectionWrapper.marketDetailsMap.containsKey(keyDetail)) {
                            marketDataCollectionWrapper.generateMarketDataCollectionDetail(item);
                        }
                    }
                    marketDataCollectionList.add(marketDataCollectionWrapper);
                }
                // check security on Market_Data_Collection_Head__c fields
                String[] marketDataCollectionHeadFields = new String[] {NegoptimHelper.normalizeAPIName('Ext_BU_Name__c'),
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
                    NegoptimHelper.normalizeAPIName('Average_Retail_Price_12M__c'), NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('SEQ__c'), NegoptimHelper.normalizeAPIName('Year__c'), NegoptimHelper.normalizeAPIName('Sequence_Type__c'),
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
                
                // insert market data collection
                if(!marketDataCollectionList.isEmpty()) {
                    if(NegoptimHelper.checkCreatibility(Market_Data_Collection_Head__c.SObjectType, marketDataCollectionHeadFields) &&
                       NegoptimHelper.checkUpdatibility(Market_Data_Collection_Head__c.SObjectType, marketDataCollectionHeadFields) &&
                       NegoptimHelper.checkCreatibility(Market_Data_Collection_Detail__c.SObjectType, marketDataCollectionDetailsInsertedFields) &&
                       NegoptimHelper.checkUpdatibility(Market_Data_Collection_Detail__c.SObjectType, marketDataCollectionDetailsFields))
                    {
                        for(MarketDataCollectionWrapper item : marketDataCollectionList) {
                            marketHeadList.add(item.marketHead);
                        }
                        // upsert market head
                        List<Database.UpsertResult> results = Database.upsert(marketHeadList, false);
                        for (Integer i = 0; i < results.size(); i++) {
                            Database.UpsertResult result = results.get(i);
                            Market_Data_Collection_Head__c marketHead = marketHeadList.get(i);
                            MarketDataCollectionWrapper wMarketDataCollection = marketDataCollectionList.get(i);
                            if (!result.isSuccess()) {
                                String errorMessage = String.valueOf(marketHead) + ' \n';
                                Database.Error[] errors = result.getErrors();
                                for (Database.Error err : errors) {
                                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                                }
                                this.errorMessage += errorMessage;
                            } else {
                                for(String key : wMarketDataCollection.marketDetailsMap.keySet()) {
                                    Market_Data_Collection_Detail__c marketDetail = wMarketDataCollection.marketDetailsMap.get(key);
                                    if(marketDetail.Market_Data_Collection_Head__c == null) marketDetail.Market_Data_Collection_Head__c = result.Id;
                                    marketDetailsList.add(marketDetail);
                                }
                                if(!this.marketHeadIds.contains(marketHead.Id)) {
                                    this.marketHeadIds.add(marketHead.Id);
                                }
                            }
                        }
                        // insert market details
                        if(!marketDetailsList.isEmpty()) {
                            List<Database.UpsertResult> resultsDetail = Database.upsert(marketDetailsList, false);
                            for (Integer i = 0; i < resultsDetail.size(); i++) {
                                Database.UpsertResult result = resultsDetail.get(i);
                                Market_Data_Collection_Detail__c marketDetail = marketDetailsList.get(i);
                                if (!result.isSuccess()) {
                                    String errorMessage = String.valueOf(marketDetail) + ' \n';
                                    Database.Error[] errors = result.getErrors();
                                    for (Database.Error err : errors) {
                                        errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + ' \n';
                                    }
                                    this.errorMessage += errorMessage;
                                }
                            }
                        }
                    }
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            this.errorMessage = 'ERROR: ' + e.getMessage() + ' - ' + e.getLineNumber();
            nb.logError('file name: ' + this.fileName + ' - ' + 'line ' + lineIndex);
            nb.logError(e);
        } catch (Exception ex) {
            Database.rollback(sp);
            this.errorMessage = 'ERROR: ' + ex.getMessage() + ' - ' + ex.getLineNumber();
            nb.logError('file name: ' + this.fileName + ' - ' + 'line ' + lineIndex);
            nb.logError(ex);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        if(String.isBlank(this.errorMessage)) {
            String nextFileNumber = String.valueOf(this.fileNumber + 1);
            // Re-Call MarketDataCollectionImportBatch
            if(this.fileIdMap.containsKey(nextFileNumber)) {
                Database.executeBatch(new MarketDataCollectionImportBatch('MarketDataCollectionImportBatch', this.fileIdMap, Integer.valueOf(nextFileNumber), this.masterBUId,
                                                                          this.flowType, this.categoryName, this.isWeekly, this.isMonthly, this.year, this.sequence,
                                                                          this.rowHeader, this.marketHeadIds), 1500);
            }
        } else {
            nb.logError('file name: ' + this.fileName + '\n' + this.errorMessage);
            if(!this.isUpdatedImport && !this.marketHeadIds.isEmpty()) {
                if(NegoptimHelper.checkDeletibility(Market_Data_Collection_Head__c.SObjectType)) {
                    DELETE [SELECT Id FROM Market_Data_Collection_Head__c WHERE Id IN :this.marketHeadIds];
                }
            }
            if(!fileIdMap.isEmpty()) {
                if(NegoptimHelper.checkDeletibility(ContentDocument.SObjectType)) {
                    DELETE [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :this.fileIdMap.values())];
                }
            }
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper header csv. */
    public class RowHeaderWrapper {
        private List<String> record;
        private Integer lineIndex;
        private Integer columnsCount;
        // File name Params
        private Boolean isWeekly;
        private Boolean isMonthly;
        private Boolean isCADCAM;
        // Map <SEQ/CAD/CAM, start column index>
        private Map<String, Integer> monthlyHeaderMap;
        private String categoryName;
        private Date movementDate;
        private Integer year;
        private Integer sequence;
        // Weekly Params
        private Integer weekNumber0;
        private Integer weekNumber1;
        private Integer weekNumber2;
        private Integer weekNumber3;
        
        private date dateSSEQ0;
        private date dateSSEQ1;
        private date dateSSEQ2;
        private date dateSSEQ3;
        
        // Validation params
        private String errorMessage;
        private Boolean isValidRow;
        
        public RowHeaderWrapper(Integer lineIndex, List<String> record, Boolean isMonthly, Boolean isWeekly) {
            this.record = record;
            this.lineIndex = lineIndex;
            this.isMonthly = isMonthly;
            this.isWeekly = isWeekly;
            this.isCADCAM = false;
            this.monthlyHeaderMap = new Map<String, Integer>();
            this.columnsCount = 0;
            this.errorMessage = '';
            this.isValidRow = true;
        }
        
        public Boolean validateRowHeader(String categoryName, Integer year, Integer sequence) {
            try {
                // get sequence date from the first row
                if(this.isMonthly) {
                    // case CAD/CAM
                    if(this.record[8] != '' && this.record[18] != '' && this.record.size() == 27) {
                        this.isCADCAM = true;
                    }
                    // get column index for SEQ/CAD/CAM
                    List<Integer> monthlyColumns = new List<Integer>{8, 18};
                    if(!this.isCADCAM) monthlyColumns.add(28);
                    for(Integer column : monthlyColumns) {
                        if(this.record[column] != '' && this.record[column].contains('CAD')) {
                            this.monthlyHeaderMap.put('CAD', column);
                        }
                        if(this.record[column] != '' && this.record[column].contains('CAM')) {
                            this.monthlyHeaderMap.put('CAM', column);
                        }
                    }
                    // case Monthly
                    if(!this.isCADCAM) {
                        for(Integer column : monthlyColumns) {
                            this.movementDate = validateDate(this.record[column], 3, 2);
                            if(this.movementDate != null) {
                                this.monthlyHeaderMap.put('SEQ', column);
                                break;
                            }
                        }
                        if(this.movementDate == null) {
                            this.errorMessage += 'line ' + this.lineIndex + ':' + string.format(Label.MSG_Invalid_Date, new String[]{'(Col 9: ' + this.record[8] + ', Col 19: ' + this.record[18] + ', Col 29: ' + this.record[28] + ')'}) + ' \n';
                            this.isValidRow = false;
                            return false;
                        }
                    }
                } else if(this.isWeekly) {
                    String invalidDateMsg = '';
                    this.dateSSEQ0 = validateDate(this.record[8], 2, 1);
                    this.dateSSEQ1 = validateDate(this.record[18], 2, 1);
                    this.dateSSEQ2 = validateDate(this.record[28], 2, 1);
                    this.dateSSEQ3 = validateDate(this.record[38], 2, 1);
                    if(this.dateSSEQ0 == null) invalidDateMsg = '(Col 9: ' + this.record[8];
                    if(this.dateSSEQ1 == null) invalidDateMsg += invalidDateMsg == '' ?  '(Col 19: ' + this.record[18] : ', Col 19: ' + this.record[18];
                    if(this.dateSSEQ2 == null) invalidDateMsg += invalidDateMsg == '' ?  '(Col 29: ' + this.record[28] : ', Col 29: ' + this.record[28];
                    if(this.dateSSEQ3 == null) invalidDateMsg += invalidDateMsg == '' ?  '(Col 39: ' + this.record[38] : ', Col 39: ' + this.record[38];
                    if(invalidDateMsg != '') {
                        invalidDateMsg += ')';
                        this.errorMessage += 'line ' + this.lineIndex + ':' + string.format(Label.MSG_Invalid_Date, new String[]{ invalidDateMsg }) + ' \n';
                        this.isValidRow = false;
                        return false;
                    }
                    if((this.dateSSEQ0 != null && this.dateSSEQ1 != null && dateSSEQ0.daysBetween(this.dateSSEQ1) != 7) ||
                       (this.dateSSEQ1 != null && this.dateSSEQ2 != null && dateSSEQ1.daysBetween(this.dateSSEQ2) != 7) ||
                       (this.dateSSEQ2 != null && this.dateSSEQ3 != null && dateSSEQ2.daysBetween(this.dateSSEQ3) != 7))
                    {
                        this.errorMessage += 'line ' + this.lineIndex + ':' + string.format(Label.MSG_Invalid_Date, new String[]{ '(Gap week dates in Cols(9,19,29,39))' }) + ' \n';
                        this.isValidRow = false;
                        return false;
                    }
                }
                
                // get columns count
                if(this.isWeekly) this.columnsCount = 47;
                else if(this.isMonthly && this.isCADCAM) this.columnsCount = 27;
                else if(this.isMonthly) this.columnsCount = 37;
                
                // check columns count
                if (this.record.size() != this.columnsCount) {
                    this.errorMessage += 'line ' + lineIndex + ':' + string.format(Label.MSG_Invalid_Columns_Count, new String[]{ String.valueOf(record.size()), String.valueOf(this.columnsCount) }) + ' \n';
                    this.isValidRow = false;
                    return false;
                }
                
                // fill sequences date and weight
                if(this.isWeekly) {
                    this.movementDate = this.dateSSEQ3;
                    // get sequences number
                    this.weekNumber0 = NegoptimHelper.getWeekNumberByDate(this.dateSSEQ0);
                    this.weekNumber1 = NegoptimHelper.getWeekNumberByDate(this.dateSSEQ1);
                    this.weekNumber2 = NegoptimHelper.getWeekNumberByDate(this.dateSSEQ2);
                    this.weekNumber3 = NegoptimHelper.getWeekNumberByDate(this.dateSSEQ3);
                }
                
                this.categoryName = categoryName;
                this.year = year;
                this.sequence = sequence;
            } catch (Exception e) {
                this.isValidRow = false;
            }
            return this.isValidRow;
        }
        
        private Date validateDate(String d, Integer splitNumber, Integer dateSequence) {
            if(d != '' && d.split(' ').size() == splitNumber) {
                String sequenceDate = d.split(' ')[dateSequence];
                try {
                    if(String.isNotBlank(sequenceDate)) {
                        NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
                        return NegoptimDate.parseDate(sequenceDate.trim(), settings.csvDateFormat);
                    }
                } catch (Exception e) { }
            }
            return null;
        }
    }
    
    /* Wrapper contains CSV columns. */
    public class RowDetailWrapper {
        private List<String> record;
        private Integer lineIndex;
            
        // Makert Head columns
        private String buName;
        
        // Makert Details columns
        private String productName;
        private String productEAN;
        private String brandName;
        private String packaging;
                        
        // SEQ
        private decimal sellOutQuantitySEQ;
        private decimal sellOutToneSEQ;
        private decimal sellOutwTaxSEQ;
        private decimal ND1SEQ;
        private decimal WD1SEQ;
        private decimal ND2SEQ;
        private decimal WD2SEQ;
        private decimal averageRetailPriceSEQ;
        private decimal avgWeeklySalesExtClientBasedSEQ;
        // YTD
        private decimal sellOutQuantityYTD;
        private decimal sellOutToneYTD;
        private decimal sellOutwTaxYTD;
        private decimal ND1YTD;
        private decimal WD1YTD;
        private decimal ND2YTD;
        private decimal WD2YTD;
        private decimal averageRetailPriceYTD;
        private decimal avgWeeklySalesExtClientBasedYTD;
        // 12M
        private decimal sellOutQuantity12M;
        private decimal sellOutTone12M;
        private decimal sellOutwTax12M;
        private decimal ND112M;
        private decimal WD112M;
        private decimal ND212M;
        private decimal WD212M;
        private decimal averageRetailPrice12M;
        private decimal avgWeeklySalesExtClientBased12M;
        
        // Weekly Params
        private date dateSSEQ0;
        private date dateSSEQ1;
        private date dateSSEQ2;
        private date dateSSEQ3;
        private decimal ND1SSEQ0; // DN Diffusion
        private decimal ND1SSEQ1;
        private decimal ND1SSEQ2;
        private decimal ND1SSEQ3;
        private decimal ND2SSEQ0; // DN
        private decimal ND2SSEQ1;
        private decimal ND2SSEQ2;
        private decimal ND2SSEQ3;
        private decimal sellOutQuantitySSEQ0; // Ventes UC
        private decimal sellOutQuantitySSEQ1;
        private decimal sellOutQuantitySSEQ2;
        private decimal sellOutQuantitySSEQ3;
        private decimal sellOutToneSSEQ0; // Ventes Volume
        private decimal sellOutToneSSEQ1;
        private decimal sellOutToneSSEQ2;
        private decimal sellOutToneSSEQ3;
        private decimal sellOutwoTaxSSEQ0; // Ventes Valeur
        private decimal sellOutwoTaxSSEQ1;
        private decimal sellOutwoTaxSSEQ2;
        private decimal sellOutwoTaxSSEQ3;
        private decimal sellOutwTaxSSEQ0;
        private decimal sellOutwTaxSSEQ1;
        private decimal sellOutwTaxSSEQ2;
        private decimal sellOutwTaxSSEQ3;
        private decimal WD1SSEQ0; // DV Diffusion
        private decimal WD1SSEQ1;
        private decimal WD1SSEQ2;
        private decimal WD1SSEQ3;
        private decimal WD2SSEQ0; // DV
        private decimal WD2SSEQ1;
        private decimal WD2SSEQ2;
        private decimal WD2SSEQ3;
        private decimal WeightSSEQ0;
        private decimal WeightSSEQ1;
        private decimal WeightSSEQ2;
        private decimal WeightSSEQ3;
        
        private String errorMessage;
        private Boolean isValidRow;
        
        public RowDetailWrapper(Integer lineIndex, List<String> record) {
            this.record = record;
            this.lineIndex = lineIndex;
            this.errorMessage = '';
            this.isValidRow = true;
        }
        
        public Boolean validateRowDetail(RowHeaderWrapper rowHeader) {
            // check columns count
            if (this.record.size() != rowHeader.columnsCount) {
                this.errorMessage += 'line ' + lineIndex + ':' + string.format(Label.MSG_Invalid_Columns_Count, new String[]{ String.valueOf(record.size()), String.valueOf(rowHeader.columnsCount) }) + ' \n';
                this.isValidRow = false;
                return false;
            }
            
            // check valid decimal
            if(((rowHeader.isMonthly || rowHeader.isCADCAM) &&
                (inValidDecimal(8) || inValidDecimal(9) || inValidDecimal(10) || inValidDecimal(11) || inValidDecimal(12) || inValidDecimal(13) || inValidDecimal(14) || inValidDecimal(15) || inValidDecimal(16) ||
                 inValidDecimal(18) || inValidDecimal(19) || inValidDecimal(20) || inValidDecimal(21) || inValidDecimal(22) || inValidDecimal(23) || inValidDecimal(24) || inValidDecimal(25) || inValidDecimal(26)))
               
               || (rowHeader.isMonthly && !rowHeader.isCADCAM &&
                   (inValidDecimal(28) || inValidDecimal(29) || inValidDecimal(30) || inValidDecimal(31) || inValidDecimal(32) || inValidDecimal(33) || inValidDecimal(34) || inValidDecimal(35) || inValidDecimal(36)))
               
               || (rowHeader.isWeekly &&
                   ((record[7] != '' && (inValidDecimal(8) || inValidDecimal(9) || inValidDecimal(10) || inValidDecimal(11) || inValidDecimal(12) || inValidDecimal(13) || inValidDecimal(14) || inValidDecimal(15) || inValidDecimal(16))) ||
                    (record[17] != '' && (inValidDecimal(18) || inValidDecimal(19) || inValidDecimal(20) || inValidDecimal(21) || inValidDecimal(22) || inValidDecimal(23) || inValidDecimal(24) || inValidDecimal(25) || inValidDecimal(26))) ||
                    (record[27] != '' && (inValidDecimal(28) || inValidDecimal(29) || inValidDecimal(30) || inValidDecimal(31) || inValidDecimal(32) || inValidDecimal(33) || inValidDecimal(34) || inValidDecimal(35) || inValidDecimal(36))) ||
                    (record[37] != '' && (inValidDecimal(38) || inValidDecimal(39) || inValidDecimal(40) || inValidDecimal(41) || inValidDecimal(42) || inValidDecimal(43) || inValidDecimal(44) || inValidDecimal(45) || inValidDecimal(46))))))
            {
                this.errorMessage += 'line ' + lineIndex + ':' + Label.MSG_Invalid_Decimal_Format + ' \n';
                this.isValidRow = false;
                return false;
            }
            
            // Makert Details columns
            this.productName = record[1];
            this.buName = record[2];
            this.productEAN = record[3]; // ITEM
            this.brandName = record[4]; // MARQUES
            this.packaging = record[5]; // CONDITIONNEMENT
            // 6- STD/PROMO, 7- SDESC 4 S 30/12/18
            if(rowHeader.isMonthly) {
                //SEQ
                if(rowHeader.monthlyHeaderMap.containsKey('SEQ')) {
                    Integer column = rowHeader.monthlyHeaderMap.get('SEQ');
                    fillSEQ(column);
                }
                //YTD
                if(rowHeader.monthlyHeaderMap.containsKey('CAD')) {
                    Integer column = rowHeader.monthlyHeaderMap.get('CAD');
                    fillCAD(column);
                }
                //12M
                if(rowHeader.monthlyHeaderMap.containsKey('CAM')) {
                    Integer column = rowHeader.monthlyHeaderMap.get('CAM');
                    fillCAM(column);
                }
            } else if(rowHeader.isWeekly) {
                // SEQ0
                this.sellOutQuantitySSEQ0 = NegoptimHelper.getDecimalValue(record[8].trim()); // Ventes UC
                this.sellOutToneSSEQ0 = NegoptimHelper.getDecimalValue(record[9].trim()); // Ventes Volume
                this.sellOutwTaxSSEQ0 = NegoptimHelper.getDecimalValue(record[10].trim()); // Ventes Valeur
                this.ND1SSEQ0 = NegoptimHelper.getDecimalValue(record[11].trim()); // DN Diffusion
                this.WD1SSEQ0 = NegoptimHelper.getDecimalValue(record[12].trim()); // DV Diffusion
                this.ND2SSEQ0 = NegoptimHelper.getDecimalValue(record[13].trim()); // DN
                this.WD2SSEQ0 = NegoptimHelper.getDecimalValue(record[14].trim()); // DV
                // SEQ1
                this.sellOutQuantitySSEQ1 = NegoptimHelper.getDecimalValue(record[18].trim()); // Ventes UC
                this.sellOutToneSSEQ1 = NegoptimHelper.getDecimalValue(record[19].trim()); // Ventes Volume
                this.sellOutwTaxSSEQ1 = NegoptimHelper.getDecimalValue(record[20].trim()); // Ventes Valeur
                this.ND1SSEQ1 = NegoptimHelper.getDecimalValue(record[21].trim()); // DN Diffusion
                this.WD1SSEQ1 = NegoptimHelper.getDecimalValue(record[22].trim()); // DV Diffusion
                this.ND2SSEQ1 = NegoptimHelper.getDecimalValue(record[23].trim()); // DN
                this.WD2SSEQ1 = NegoptimHelper.getDecimalValue(record[24].trim()); // DV
                // SEQ2
                this.sellOutQuantitySSEQ2 = NegoptimHelper.getDecimalValue(record[28].trim()); // Ventes UC
                this.sellOutToneSSEQ2 = NegoptimHelper.getDecimalValue(record[29].trim()); // Ventes Volume
                this.sellOutwTaxSSEQ2 = NegoptimHelper.getDecimalValue(record[30].trim()); // Ventes Valeur
                this.ND1SSEQ2 = NegoptimHelper.getDecimalValue(record[31].trim()); // DN Diffusion
                this.WD1SSEQ2 = NegoptimHelper.getDecimalValue(record[32].trim()); // DV Diffusion
                this.ND2SSEQ2 = NegoptimHelper.getDecimalValue(record[33].trim()); // DN
                this.WD2SSEQ2 = NegoptimHelper.getDecimalValue(record[34].trim()); // DV
                // SEQ3
                this.sellOutQuantitySSEQ3 = NegoptimHelper.getDecimalValue(record[38].trim()); // Ventes UC
                this.sellOutToneSSEQ3 = NegoptimHelper.getDecimalValue(record[39].trim()); // Ventes Volume
                this.sellOutwTaxSSEQ3 = NegoptimHelper.getDecimalValue(record[40].trim()); // Ventes Valeur
                this.ND1SSEQ3 = NegoptimHelper.getDecimalValue(record[41].trim()); // DN Diffusion
                this.WD1SSEQ3 = NegoptimHelper.getDecimalValue(record[42].trim()); // DV Diffusion
                this.ND2SSEQ3 = NegoptimHelper.getDecimalValue(record[43].trim()); // DN
                this.WD2SSEQ3 = NegoptimHelper.getDecimalValue(record[44].trim()); // DV
            }
            return true;
        }
        private Boolean inValidDecimal(Integer column) {
            return record[column] != '' && NegoptimHelper.getDecimalValue(record[column].trim()) == null;
        }
        private void fillSEQ(Integer column) {
            // SEQ
            this.sellOutQuantitySEQ = NegoptimHelper.getDecimalValue(record[column].trim()); // Ventes UC
            this.sellOutToneSEQ = NegoptimHelper.getDecimalValue(record[column + 1].trim()); // Ventes Volume
            this.sellOutwTaxSEQ = NegoptimHelper.getDecimalValue(record[column + 2].trim()); // Ventes Valeur
            this.ND1SEQ = NegoptimHelper.getDecimalValue(record[column + 3].trim()); // DN Diffusion
            this.WD1SEQ = NegoptimHelper.getDecimalValue(record[column + 4].trim()); // DV Diffusion
            this.ND2SEQ = NegoptimHelper.getDecimalValue(record[column + 5].trim()); // DN Hors Promo
            this.WD2SEQ = NegoptimHelper.getDecimalValue(record[column + 6].trim()); // DV Hors Promo
            this.avgWeeklySalesExtClientBasedSEQ = NegoptimHelper.getDecimalValue(record[column + 7].trim()); // VMH UC Hors Promo pond. par Réf
            this.averageRetailPriceSEQ = NegoptimHelper.getDecimalValue(record[column + 8].trim()); // Prix Moyen UC Hors Promo
        }
        private void fillCAD(Integer column) {
            //YTD
            this.sellOutQuantityYTD = NegoptimHelper.getDecimalValue(record[column].trim()); // Ventes UC
            this.sellOutToneYTD = NegoptimHelper.getDecimalValue(record[column + 1].trim()); // Ventes Volume
            this.sellOutwTaxYTD = NegoptimHelper.getDecimalValue(record[column + 2].trim()); // Ventes Valeur
            this.ND1YTD = NegoptimHelper.getDecimalValue(record[column + 3].trim()); // DN Diffusion
            this.WD1YTD = NegoptimHelper.getDecimalValue(record[column + 4].trim()); // DV Diffusion
            this.ND2YTD = NegoptimHelper.getDecimalValue(record[column + 5].trim()); // DN Hors Promo
            this.WD2YTD = NegoptimHelper.getDecimalValue(record[column + 6].trim()); // DV Hors Promo
            this.avgWeeklySalesExtClientBasedYTD = NegoptimHelper.getDecimalValue(record[column + 7].trim()); // VMH UC Hors Promo pond. par Réf
            this.averageRetailPriceYTD = NegoptimHelper.getDecimalValue(record[column + 8].trim()); // Prix Moyen UC Hors Promo
        }
        private void fillCAM(Integer column) {
            //12M
            this.sellOutQuantity12M = NegoptimHelper.getDecimalValue(record[column].trim()); // Ventes UC
            this.sellOutTone12M = NegoptimHelper.getDecimalValue(record[column + 1].trim()); // Ventes Volume
            this.sellOutwTax12M = NegoptimHelper.getDecimalValue(record[column + 2].trim()); // Ventes Valeur
            this.ND112M = NegoptimHelper.getDecimalValue(record[column + 3].trim()); // DN Diffusion
            this.WD112M = NegoptimHelper.getDecimalValue(record[column + 4].trim()); // DV Diffusion
            this.ND212M = NegoptimHelper.getDecimalValue(record[column + 5].trim()); // DN Hors Promo
            this.WD212M = NegoptimHelper.getDecimalValue(record[column + 6].trim()); // DV Hors Promo
            this.avgWeeklySalesExtClientBased12M = NegoptimHelper.getDecimalValue(record[column + 7].trim()); // VMH UC Hors Promo pond. par Réf
            this.averageRetailPrice12M = NegoptimHelper.getDecimalValue(record[column + 8].trim()); // Prix Moyen UC Hors Promo
        }
    }
    
    /* Wrapper MarketData */
    public class MarketDataCollectionWrapper {
        private RowHeaderWrapper rowHeader {get; set;}
        private Market_Data_Collection_Head__c marketHead {get; set;}
        private Map<String, Market_Data_Collection_Detail__c> marketDetailsMap {get; set;}
        private Map<String, Market_Data_Collection_Detail__c> oldMarketDetailsMap {get; set;}
        private String sequenceType {
            get {
                return this.rowHeader.isWeekly || this.rowHeader.isCADCAM ? 'Week' : 'Month';
            }
            set;
        }
        public MarketDataCollectionWrapper(RowHeaderWrapper rowHeader, Market_Data_Collection_Head__c marketHead, Map<String, Market_Data_Collection_Detail__c> oldMarketDetailsMap) {
            this.rowHeader = rowHeader;
            this.marketHead = marketHead;
            this.marketDetailsMap = new Map<String, Market_Data_Collection_Detail__c>();
            this.oldMarketDetailsMap = oldMarketDetailsMap;
        }
        
        public void generateMarketDataCollectionDetail(RowDetailWrapper rowDetail) {
            String keyDetail = rowDetail.productName + '' + (String.isNotBlank(rowDetail.productEAN) ? rowDetail.productEAN : '') + '' + this.rowHeader.categoryName + '' + rowDetail.buName + '' + this.rowHeader.year + '' + this.rowHeader.sequence + '' + this.sequenceType;
            Market_Data_Collection_Detail__c marketDetail = null;
            if(this.oldMarketDetailsMap.containsKey(keyDetail)) {
                marketDetail = this.oldMarketDetailsMap.get(keyDetail);
                marketDetail.Status__c = 'Updated';
            }
            if(marketDetail == null) {
                marketDetail = new Market_Data_Collection_Detail__c(Ext_BU_Name__c = rowDetail.buName, Ext_Category_Name__c = this.rowHeader.categoryName,
                                                                    Ext_Product_Name__c = rowDetail.productName, Ext_Product_EAN__c = rowDetail.productEAN,
                                                                    Ext_Brand_Name__c = rowDetail.brandName, Ext_Packaging__c = rowDetail.packaging,
                                                                    SEQ__c = this.rowHeader.sequence, Year__c = this.rowHeader.year, Status__c = 'New',
                                                                    Sequence_Type__c = this.sequenceType);
                oldMarketDetailsMap.put(keyDetail, marketDetail);
            }
            // case weekly sequence
            if(this.rowHeader.isWeekly) {
                marketDetail.Sequence_Number__c = this.rowHeader.weekNumber3;
                //SEQ0
                marketDetail.Date_SSEQ0__c = rowHeader.dateSSEQ0;
                marketDetail.SellOut_Quantity_SSEQ0__c = rowDetail.sellOutQuantitySSEQ0;
                marketDetail.SellOut_Tone_SSEQ0__c = rowDetail.sellOutToneSSEQ0;
                marketDetail.SellOut_wTax_SSEQ0__c = rowDetail.sellOutwTaxSSEQ0;
                marketDetail.ND_1_SSEQ0__c = rowDetail.ND1SSEQ0;
                marketDetail.ND_2_SSEQ0__c = rowDetail.ND2SSEQ0;
                marketDetail.WD_1_SSEQ0__c = rowDetail.WD1SSEQ0;
                marketDetail.WD_2_SSEQ0__c = rowDetail.WD2SSEQ0;
                //SEQ1
                marketDetail.Date_SSEQ1__c = rowHeader.dateSSEQ1;
                marketDetail.SellOut_Quantity_SSEQ1__c = rowDetail.sellOutQuantitySSEQ1;
                marketDetail.SellOut_Tone_SSEQ1__c = rowDetail.sellOutToneSSEQ1;
                marketDetail.SellOut_wTax_SSEQ1__c = rowDetail.sellOutwTaxSSEQ1;
                marketDetail.ND_1_SSEQ1__c = rowDetail.ND1SSEQ1;
                marketDetail.ND_2_SSEQ1__c = rowDetail.ND2SSEQ1;
                marketDetail.WD_1_SSEQ1__c = rowDetail.WD1SSEQ1;
                marketDetail.WD_2_SSEQ1__c = rowDetail.WD2SSEQ1;
                //SEQ2
                marketDetail.Date_SSEQ2__c = rowHeader.dateSSEQ2;
                marketDetail.SellOut_Quantity_SSEQ2__c = rowDetail.sellOutQuantitySSEQ2;
                marketDetail.SellOut_Tone_SSEQ2__c = rowDetail.sellOutToneSSEQ2;
                marketDetail.SellOut_wTax_SSEQ2__c = rowDetail.sellOutwTaxSSEQ2;
                marketDetail.ND_1_SSEQ2__c = rowDetail.ND1SSEQ2;
                marketDetail.ND_2_SSEQ2__c = rowDetail.ND2SSEQ2;
                marketDetail.WD_1_SSEQ2__c = rowDetail.WD1SSEQ2;
                marketDetail.WD_2_SSEQ2__c = rowDetail.WD2SSEQ2;
                //SEQ3
                marketDetail.Date_SSEQ3__c = rowHeader.dateSSEQ3;
                marketDetail.SellOut_Quantity_SSEQ3__c = rowDetail.sellOutQuantitySSEQ3;
                marketDetail.SellOut_Tone_SSEQ3__c = rowDetail.sellOutToneSSEQ3;
                marketDetail.SellOut_wTax_SSEQ3__c = rowDetail.sellOutwTaxSSEQ3;
                marketDetail.ND_1_SSEQ3__c = rowDetail.ND1SSEQ3;
                marketDetail.ND_2_SSEQ3__c = rowDetail.ND2SSEQ3;
                marketDetail.WD_1_SSEQ3__c = rowDetail.WD1SSEQ3;
                marketDetail.WD_2_SSEQ3__c = rowDetail.WD2SSEQ3;
            }
            // case monthly
            if(this.rowHeader.isMonthly && !this.rowHeader.isCADCAM) {
                //SEQ Monthly
                marketDetail.SellOut_Quantity_SEQ__c = rowDetail.sellOutQuantitySEQ;
                marketDetail.SellOut_Tone_SEQ__c = rowDetail.sellOutToneSEQ;
                marketDetail.SellOut_wTax_SEQ__c = rowDetail.sellOutwTaxSEQ;
                marketDetail.ND_1_SEQ__c = rowDetail.ND1SEQ;
                marketDetail.WD_1_SEQ__c = rowDetail.WD1SEQ;
                marketDetail.ND_2_SEQ__c = rowDetail.ND2SEQ;
                marketDetail.WD_2_SEQ__c = rowDetail.WD2SEQ;
                marketDetail.Average_Retail_Price_SEQ__c = rowDetail.averageRetailPriceSEQ;
                marketDetail.Avg_Weekly_Sales_Ext_ClientBased__c = rowDetail.avgWeeklySalesExtClientBasedSEQ;
            }
            // case Month/CAD/CAM
            if(this.rowHeader.isMonthly || this.rowHeader.isCADCAM) {
                //YTD
                marketDetail.SellOut_Quantity_YTD__c = rowDetail.sellOutQuantityYTD;
                marketDetail.SellOut_Tone_YTD__c = rowDetail.sellOutToneYTD;
                marketDetail.SellOut_wTax_YTD__c = rowDetail.sellOutwTaxYTD;
                marketDetail.ND_1_YTD__c = rowDetail.ND1YTD;
                marketDetail.WD_1_YTD__c = rowDetail.WD1YTD;
                marketDetail.ND_2_YTD__c = rowDetail.ND2YTD;
                marketDetail.WD_2_YTD__c = rowDetail.WD2YTD;
                marketDetail.Average_Retail_Price_YTD__c = rowDetail.averageRetailPriceYTD;
                //12M
                marketDetail.SellOut_Quantity_12M__c = rowDetail.sellOutQuantity12M;
                marketDetail.SellOut_Tone_12M__c = rowDetail.sellOutTone12M;
                marketDetail.SellOut_wTax_12M__c = rowDetail.sellOutwTax12M;
                marketDetail.ND_1_12M__c = rowDetail.ND112M;
                marketDetail.WD_1_12M__c = rowDetail.WD112M;
                marketDetail.ND_2_12M__c = rowDetail.ND212M;
                marketDetail.WD_2_12M__c = rowDetail.WD212M;
                marketDetail.Average_Retail_Price_12M__c = rowDetail.averageRetailPrice12M;
            }
            
            if(marketHead.Id != null && marketDetail.Market_Data_Collection_Head__c == null) {
                marketDetail.Market_Data_Collection_Head__c = marketHead.Id;
            }
            if(!this.marketDetailsMap.containsKey(keyDetail)) {
                this.marketDetailsMap.put(keyDetail, marketDetail);
            }
        }
    }
}