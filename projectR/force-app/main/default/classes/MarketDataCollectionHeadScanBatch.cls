/*
 * Scan market data collection.
 */ 
global with sharing class MarketDataCollectionHeadScanBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    private final Date selectedDate;
    public static Map<String, string> marketHeadFieldNameLabels;
    private final Set<Id> marketHeadIds;
    
    /* Constructor */
    public MarketDataCollectionHeadScanBatch(String startedFrom, List<Id> ids, Date d) {
        this.nb = new NegoptimBatch('MarketDataCollectionHeadScanBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.selectedDate = d;
        this.marketHeadIds = new Set<Id>();
        
        String q = 'SELECT Id, Name, Action_Done__c, Action_Todo__c, Orga_BU__c, Orga_HE__c, Client__c, Comment__c,';
        q += ' Client_Code__c, Ext_Client_Name__c, Ext_BU_Code__c, Ext_BU_Name__c, Ext_Category_Code__c, Ext_Category_Name__c,';
        q += ' Flow_Type__c, Master_BU__c, Movement_Date__c, Origin_Type__c, SEQ__c, Status__c, Year__c, Last_Scan_Date__c';
        q += ' FROM Market_Data_Collection_Head__c';
        q += ' WHERE (Status__c = \'New\' OR Status__c = \'Updated\')';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\')';
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
    public void execute(Database.BatchableContext bc, List<Market_Data_Collection_Head__c> scope) {
        // Declaration
        Set<String> buNameSet = new Set<String>();
        Set<String> buCodeSet = new Set<String>();
        Set<String> categoryNameSet = new Set<String>();
        Set<String> categoryCodeSet = new Set<String>();
        Set<String> formatOriginSet = new Set<String>();

        Map<String, Orga_BU__c> buNameMap = new Map<String, Orga_BU__c>();
        Map<String, Orga_BU__c> buCodeMap = new Map<String, Orga_BU__c>();
        Map<String, Orga_HE__c> categoryNameMap = new Map<String, Orga_HE__c>();
        Map<String, Orga_HE__c> categoryCodeMap = new Map<String, Orga_HE__c>();
        List<Market_Data_Collection_Head__c> marketHeadList = new List<Market_Data_Collection_Head__c>();
        List<MarketHeadWrapper> wMarketHeadList = new List<MarketHeadWrapper>();
        
        // Describe all fields for Market_Data_Collection_Head__c
        marketHeadFieldNameLabels = NegoptimHelper.GetMandatoryFieldLabels(Market_Data_Collection_Head__c.SObjectType);
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on read market head fields
            String[] marketHeadAccessFields = new String[] {'Id', 'Name', NegoptimHelper.normalizeAPIName('Action_Done__c'),
                NegoptimHelper.normalizeAPIName('Action_Todo__c'), NegoptimHelper.normalizeAPIName('Orga_BU__c'),
                NegoptimHelper.normalizeAPIName('Orga_HE__c'), NegoptimHelper.normalizeAPIName('Client__c'),
                NegoptimHelper.normalizeAPIName('Client_Code__c'), NegoptimHelper.normalizeAPIName('Ext_BU_Code__c'),
                NegoptimHelper.normalizeAPIName('Ext_BU_Name__c'), NegoptimHelper.normalizeAPIName('Ext_Category_Code__c'),
                NegoptimHelper.normalizeAPIName('Ext_Category_Name__c'), NegoptimHelper.normalizeAPIName('Ext_Client_Name__c'),
                NegoptimHelper.normalizeAPIName('Master_BU__c'), NegoptimHelper.normalizeAPIName('Status__c')};
          
            for(Market_Data_Collection_Head__c item : scope) {
                if(String.IsNotBlank(item.Ext_BU_Name__c) && !buNameSet.contains(item.Ext_BU_Name__c.toLowerCase())) {
                    buNameSet.add(item.Ext_BU_Name__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_BU_code__c) && !buCodeSet.contains(item.Ext_BU_Code__c.toLowerCase())) {
                    buCodeSet.add(item.Ext_BU_code__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_Category_Name__c) && !categoryNameSet.contains(item.Ext_Category_Name__c.toLowerCase())) {
                    categoryNameSet.add(item.Ext_Category_Name__c.toLowerCase());
                }
                if(String.IsNotBlank(item.Ext_Category_Code__c) && !categoryCodeSet.contains(item.Ext_Category_Code__c.toLowerCase())) {
                    categoryCodeSet.add(item.Ext_Category_Code__c.toLowerCase());
                }
            }
            
            Map<String, Orga_BU__c> masterBUsMap = new Map<String, Orga_BU__c>();
            // get BUs
            if(!buNameSet.isEmpty() || !buCodeSet.isEmpty()) {
                for(Orga_BU__c item : [SELECT Id, Name, BU_Code__c, IsMasterBU__c, Format_Origin__c, Panel_Name__c,
                                       Related_Client__c, Related_Client__r.Name, Related_Client__r.Code__c
                                       FROM Orga_BU__c
                                       WHERE Status__c = 'Open' AND (BU_Code__c IN :buCodeSet OR Name IN :buNameSet OR Panel_Name__c IN :buNameSet)
                                       AND Mission__c INCLUDES ('Nielsen')])
                {
                    if(buNameSet.contains(item.Name.toLowerCase()) && !buNameMap.containsKey(item.Name.toLowerCase())) {
                        buNameMap.put(item.Name.toLowerCase(), item);
                    }
                    if(item.Panel_Name__c != null && buNameSet.contains(item.Panel_Name__c.toLowerCase()) && !buNameMap.containsKey(item.Panel_Name__c.toLowerCase())) {
                        buNameMap.put(item.Panel_Name__c.toLowerCase(), item);
                    }
                    if(buCodeSet.contains(item.BU_Code__c.toLowerCase()) && !buCodeMap.containsKey(item.BU_Code__c.toLowerCase())) {
                        buCodeMap.put(item.BU_Code__c.toLowerCase(), item);
                    }
                    if(item.Format_Origin__c != null) {
                        formatOriginSet.addAll(item.Format_Origin__c.split(';'));
                    }
                }
                if(!formatOriginSet.isEmpty()) {
                    String query = 'SELECT Id, Format_Origin__c FROM Orga_BU__c WHERE IsMasterBU__c = TRUE AND Format_Origin__c INCLUDES (\'' + String.join(new List<String>(formatOriginSet), '\',\'') + '\')';
                    // fill map master BUs
                    for(Orga_BU__c item : Database.query(query)) {
                        // sorting format origin list
                        List<String> formatOriginList = item.Format_Origin__c.split(';');
                        formatOriginList.sort();
                        masterBUsMap.put(String.join(formatOriginList, ';'), item);
                    }
                }
            }
            // get Categories
            if(!categoryNameSet.isEmpty() || !categoryCodeSet.isEmpty()) {
                for(Orga_HE__c item : [SELECT Id, Name, Elt_Code__c FROM Orga_HE__c
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
            
            // Prepare Scan Process
            for(Market_Data_Collection_Head__c item : scope) {
                MarketHeadWrapper wMarketHead = new MarketHeadWrapper(item);
                // INTEGRITY CONTROL: a- Check Mandatory fields
                wMarketHead.CheckMandatoryFields();
                if(!wMarketHead.scanIsValid) {
                    // Error
                }
                // Data Mapping : b- Check BU, MasterBU, Client, Category
                if((String.IsNotBlank(item.Ext_BU_Name__c) && buNameMap.containsKey(item.Ext_BU_Name__c.toLowerCase())) || (String.IsNotBlank(item.Ext_BU_Code__c) && buCodeMap.containsKey(item.Ext_BU_Code__c.toLowerCase()))) {
                    if(String.IsNotBlank(item.Ext_BU_Name__c)) wMarketHead.refBU = buNameMap.get(item.Ext_BU_Name__c.toLowerCase());
                    if(wMarketHead.refBU == null && String.IsNotBlank(item.Ext_BU_Code__c)) wMarketHead.refBU = buCodeMap.get(item.Ext_BU_Code__c.toLowerCase());
                    if(wMarketHead.refBU != null) {
                        if(wMarketHead.refBU.Related_Client__c != null) wMarketHead.refClientId = wMarketHead.refBU.Related_Client__c;
                        // get master BU
                        if(wMarketHead.refBU.IsMasterBU__c != null && wMarketHead.refBU.IsMasterBU__c == true) wMarketHead.masterBUId = wMarketHead.refBU.Id;
                        else {
                            if(wMarketHead.refBU.Format_Origin__c != null) {
                                // sorting format origin list
                                List<String> buFormatOriginList = wMarketHead.refBU.Format_Origin__c.split(';');
                                buFormatOriginList.sort();
                                String buFormatOrigin = String.join(buFormatOriginList, ';');
                                if(masterBUsMap.ContainsKey(buFormatOrigin)) {
                                    wMarketHead.masterBUId = masterBUsMap.get(buFormatOrigin).Id;
                                } else {
                                    for(String masterBUFormatOrigin : masterBUsMap.keySet()) {
                                        Set<String> masterBUFormatOriginSet = new Set<String>(masterBUFormatOrigin.split(';'));
                                        Set<String> buFormatOriginSet = new Set<String>(buFormatOrigin.split(';'));
                                        if(masterBUFormatOriginSet.containsAll(buFormatOriginSet)) {
                                            wMarketHead.masterBUId = masterBUsMap.get(masterBUFormatOrigin).Id;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if((String.IsNotBlank(item.Ext_Category_Name__c) && categoryNameMap.containsKey(item.Ext_Category_Name__c.toLowerCase())) || (String.IsNotBlank(item.Ext_Category_Code__c) && categoryCodeMap.containsKey(item.Ext_Category_Code__c.toLowerCase()))) {
                    if(String.IsNotBlank(item.Ext_Category_Name__c)) wMarketHead.refCategory = categoryNameMap.get(item.Ext_Category_Name__c.toLowerCase());
                    if(wMarketHead.refCategory == null && String.IsNotBlank(item.Ext_Category_Code__c)) wMarketHead.refCategory = categoryCodeMap.get(item.Ext_Category_Code__c.toLowerCase());
                }
                // Scan Market Head
                wMarketHead.scanMarketHead();
                
                // Fill Scan Results
                if(!wMarketHead.scanIsValid) wMarketHead.marketHead.Status__c = 'Scan w/ error';
                else wMarketHead.marketHead.Status__c = 'Scan w/ success';
                wMarketHead.marketHead.Action_ToDo__c = wMarketHead.actionToDoMessage;
                wMarketHead.marketHead.Action_done__c = wMarketHead.actionDoneMessage;
                wMarketHead.marketHead.Last_Scan_Date__c = System.now();
                wMarketHeadList.add(wMarketHead);
            }
            for (MarketHeadWrapper item : wMarketHeadList) {
                marketHeadList.add(item.marketHead);
            }
            
            // check security on updated market head fields
            String[] marketHeadUpdatedFields = new String[] {NegoptimHelper.normalizeAPIName('Action_Done__c'), NegoptimHelper.normalizeAPIName('Action_Todo__c'),
                NegoptimHelper.normalizeAPIName('Orga_BU__c'), NegoptimHelper.normalizeAPIName('Orga_HE__c'), NegoptimHelper.normalizeAPIName('Client__c'),
                NegoptimHelper.normalizeAPIName('Master_BU__c'), NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Last_Scan_Date__c')};
            
            // Update market head
            if(!marketHeadList.isEmpty()) {
                if(NegoptimHelper.checkUpdatibility(Market_Data_Collection_Head__c.SObjectType, marketHeadUpdatedFields)) {
                    List<Database.SaveResult> results = Database.update(marketHeadList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Market_Data_Collection_Head__c marketHead = marketHeadList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = marketHead.Name + '(' + marketHead.Id + ') : ';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        } else {
                            if(marketHead.Status__c == 'Scan w/ success') this.marketHeadIds.add(marketHead.Id);
                        }
                    }
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
        if(!this.marketHeadIds.isEmpty()) {
            Database.executeBatch(new MarketDataCollectionDetailScanBatch('MarketDataCollectionHeadScanBatch', new List<Id>(this.marketHeadIds), this.selectedDate), 150);
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    // Market Head Wrapper
    public class MarketHeadWrapper {
        public Market_Data_Collection_Head__c marketHead {get; set;}
        public Id refClientId {get; set;}
        public Id masterBUId {get; set;}
        public Orga_BU__c refBU {get; set;}
        public Orga_HE__c refCategory {get; set;}
        
        public Boolean scanIsValid {get; set;}
        public String actionToDoMessage {get; set;}
        public String actionDoneMessage {get; set;}
        
        public MarketHeadWrapper(Market_Data_Collection_Head__c marketHead) {
            this.marketHead = marketHead;
            refClientId = null;
            masterBUId = null;
            refBU = null;
            refCategory = null;
            scanIsValid = true;
            actionToDoMessage = '';
            actionDoneMessage = '';
        }
        // scan Market Head
        public void scanMarketHead() {
            // get Master BU
            if(this.masterBUId == null) {
                this.actionToDoMessage += Label.MSG_MasterBU_Not_Exist + '\n';
                this.scanIsValid = false;
            } else {
                marketHead.Master_BU__c = this.masterBUId;
            }
            // get BU
            if(this.refBU == null) {
                this.actionToDoMessage += Label.MSG_BU_Not_Exist + '\n';
                this.scanIsValid = false;
            } else {
                marketHead.Orga_BU__c = this.refBU.Id;
            }
            // get client
            if(this.refClientId == null) {
                this.actionToDoMessage += Label.MSG_Client_Not_Exist + '\n';
                this.scanIsValid = false;
            } else {
                marketHead.Client__c = this.refClientId;
            }
            // get category
            if(this.refCategory == null) {
                this.actionToDoMessage += Label.MSG_Category_Not_Exist + '\n';
                this.scanIsValid = false;
            } else {
                marketHead.Orga_HE__c = this.refCategory.Id;
            }
        }
        // Check Mandatory Fields
        public void CheckMandatoryFields() {
            // Check missing fields
            if((marketHead.Ext_BU_Name__c == null && marketHead.Ext_BU_Code__c == null) ||
               (marketHead.Ext_Category_Name__c == null && marketHead.Ext_Category_Code__c == null) ||
               marketHead.Flow_Type__c == null || marketHead.Master_BU__c == null || marketHead.Movement_Date__c == null ||
               marketHead.Origin_Type__c == null || marketHead.Status__c == null || marketHead.SEQ__c == null || marketHead.Year__c == null)
            {
                if(marketHead.Ext_BU_Name__c == null && marketHead.Ext_BU_Code__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Ext_BU_Name__c') + ', ' + marketHeadFieldNameLabels.get('Ext_BU_Code__c')}) + '\n';
                if(marketHead.Ext_Category_Name__c == null && marketHead.Ext_Category_Code__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Ext_Category_Name__c') + ', ' + marketHeadFieldNameLabels.get('Ext_Category_Code__c')}) + '\n';
                if(marketHead.Flow_Type__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Flow_Type__c') }) + '\n';
                if(marketHead.Master_BU__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Master_BU__c') }) + '\n';
                if(marketHead.Movement_Date__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Movement_Date__c') }) + '\n';
                if(marketHead.Origin_Type__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Origin_Type__c') }) + '\n';
                if(marketHead.Status__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Status__c') }) + '\n';                
                if(marketHead.SEQ__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('SEQ__c') }) + '\n';
                if(marketHead.Year__c == null) this.actionToDoMessage += string.format(Label.MSG_MandatoryFields, new String[]{ marketHeadFieldNameLabels.get('Year__c') }) + '\n';
                this.scanIsValid = false;
            }
        }
    }
}