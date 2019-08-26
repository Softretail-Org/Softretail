public with sharing class MarketDataCollectionController extends NegoptimBaseController {
    
    public List<Market_Data_Collection_Head__c> records {get; set;}
    public List<Market_Data_Collection_Head__c> scanMarketHeadList {get; set;}
    public List<Market_Data_Collection_Head__c> synchroMarketHeadList {get; set;}
    public List<Id> scanMarketHeadIds {get; set;}
    public List<Id> synchroMarketHeadIds {get; set;}
    public Boolean isPollerActive {get; set;}
    public Boolean scanInProcess {get; set;}
    public Boolean synchroInProcess {get; set;}
    
    public MarketDataCollectionController(ApexPages.StandardSetController stdSetController) {
        if (!Test.isRunningTest()) {
            stdSetController.addFields(new String[]{'Id', 'Name','Master_BU__c', 'Ext_Client_Name__c', 'Ext_BU_Name__c',
                'Ext_Category_Name__c', 'Client__c', 'Orga_BU__c', 'Orga_HE__c', 'Year__c', 'SEQ__c', 'Status__c', 'Action_Todo__c'});
        }
        this.records = (List<Market_Data_Collection_Head__c>)stdSetController.getSelected();
        this.scanMarketHeadList = new List<Market_Data_Collection_Head__c>();
        this.synchroMarketHeadList = new List<Market_Data_Collection_Head__c>();
        this.scanMarketHeadIds = new List<Id>();
        this.synchroMarketHeadIds = new List<Id>();
        for(Market_Data_Collection_Head__c item : this.records) {
            if(item.Status__c == 'New' || item.Status__c == 'Updated') {
                this.scanMarketHeadList.add(item);
                this.scanMarketHeadIds.add(item.Id);
            }
            if(item.Status__c == 'Scan w/ success') {
                this.synchroMarketHeadList.add(item);
                this.synchroMarketHeadIds.add(item.Id);
            }
        }
        this.scanInProcess = false;
        this.synchroInProcess = false;
        this.isPollerActive = false;
    }
    
    // Scan Market Data Collection
    public PageReference scanMarketDataCollection() {
        this.scanInProcess = true;
        Set<Id> marketHeadIds = (new Map<Id, Market_Data_Collection_Head__c>(this.scanMarketHeadList)).keySet();
        Id batchInstanceId = Database.executeBatch(new MarketDataCollectionHeadScanBatch('MarketDataCollectionController', new List<Id>(marketHeadIds), null), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'MarketDataCollectionScanBatch', (String)batchInstanceId})));
        return refresh();
    }
    
    // Synchro Market Data Collection
    public PageReference synchroMarketDataCollection() {
        this.synchroInProcess = true;
        Set<Id> marketHeadIds = (new Map<Id, Market_Data_Collection_Head__c>(this.synchroMarketHeadList)).keySet();
        Id batchInstanceId = Database.executeBatch(new MarketDataCollectionSynchroBatch('MarketDataCollectionController', new List<Id>(marketHeadIds), null), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'MarketDataCollectionSynchroBatch', (String)batchInstanceId})));     
        return refresh();
    }
    
    // refresh Market Data Collection
    public PageReference refresh() {
        this.isPollerActive = false;
        this.scanMarketHeadList = [SELECT Id, Name, Master_BU__c, Ext_Client_Name__c, Ext_BU_Name__c, Ext_Category_Name__c,
                                   Client__c, Orga_BU__c, Orga_HE__c, Year__c, SEQ__c, Status__c, Action_Todo__c
                                   FROM Market_Data_Collection_Head__c WHERE Id IN :this.scanMarketHeadIds];
        this.synchroMarketHeadList = [SELECT Id, Name, Master_BU__c, Ext_Client_Name__c, Ext_BU_Name__c, Ext_Category_Name__c,
                                      Client__c, Orga_BU__c, Orga_HE__c, Year__c, SEQ__c, Status__c, Action_Todo__c
                                      FROM Market_Data_Collection_Head__c WHERE Id IN :this.synchroMarketHeadIds];        
        List<AsyncApexJob> batchJob = [SELECT Id, Status FROM AsyncApexJob
                                       WHERE ApexClass.Name IN ('MarketDataCollectionHeadScanBatch', 'MarketDataCollectionSynchroBatch')
                                       AND JobType != 'BatchApexWorker'
                                       ORDER BY CreatedDate DESC LIMIT 20];
        // Activate the poller if theare are a job holding or in process
        for(AsyncApexJob job : batchJob) {
            if(job.Status != 'Completed' && job.Status != 'Aborted' && job.Status != 'Failed') {
                this.isPollerActive = true;
                break;
            }
        }
        if(!this.isPollerActive) {
            this.scanInProcess = false;
            this.synchroInProcess = false;
        }
        return null;
    }
    
    public PageReference cancel() {
        String URL;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        for(Schema.DescribeTabSetResult tsr : tabSetDesc) {
            tabDesc.addAll(tsr.getTabs());
        }
        String sObjectName = Market_Data_Collection_Head__c.SObjectType.getDescribe().getName();
        for(Schema.DescribeTabResult tr : tabDesc) {
            if(sObjectName == tr.getSobjectName()) {
                URL = tr.getUrl();
            }
        }
        if(String.isNotBlank(URL)) return new PageReference(URL);
        return null;
    }
}