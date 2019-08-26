public with sharing class MassBatchControllerForLightning {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getSettingsForSections() {
        List<String> sectionsSettings = new List<String>();
        NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
        sectionsSettings.add('MBF_Section_AssortmentSFPlanning=' +settings.MBF_Section_AssortmentSFPlanning);
        sectionsSettings.add('MBF_Section_Batches=' +settings.MBF_Section_Batches);
        sectionsSettings.add('MBF_Section_CallingWebServices=' +settings.MBF_Section_CallingWebServices);
        sectionsSettings.add('MBF_Section_ContractCounterpartyDetail=' +settings.MBF_Section_ContractCounterpartyDetail);
        sectionsSettings.add('MBF_Section_ContractDuplication=' +settings.MBF_Section_ContractDuplication);
        sectionsSettings.add('MBF_Section_ContractRates=' +settings.MBF_Section_ContractRates);
        sectionsSettings.add('MBF_Section_ContractTOProcedures=' +settings.MBF_Section_ContractTOProcedures);
        sectionsSettings.add('MBF_Section_GroupScanAndSynchro=' +settings.MBF_Section_GroupScanAndSynchro);
        sectionsSettings.add('MBF_Section_InvoiceReminder=' +settings.MBF_Section_InvoiceReminder);
        sectionsSettings.add('MBF_Section_LastActiveContractProcedure=' +settings.MBF_Section_LastActiveContractProcedure);
        sectionsSettings.add('MBF_Section_MarketDataCollection=' +settings.MBF_Section_MarketDataCollection);
        sectionsSettings.add('MBF_Section_MassDistribution=' +settings.MBF_Section_MassDistribution);
        sectionsSettings.add('MBF_Section_PenaltiesProcedure=' +settings.MBF_Section_PenaltiesProcedure);
        sectionsSettings.add('MBF_Section_PromoDetailProcedure=' +settings.MBF_Section_PromoDetailProcedure);
        sectionsSettings.add('MBF_Section_SellInProcedure=' +settings.MBF_Section_SellInProcedure);
        return sectionsSettings;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Orga_BU__c> getSelectOptionsCountries() {
        List<Orga_BU__c> countries = new List<Orga_BU__c>();
        for(Orga_BU__c item: [SELECT Id, Name, Business_Unit_Type__c
                              FROM Orga_BU__c
                              WHERE Business_Unit_Type__c = 'Country'
                              OR Business_Unit_Type__c = 'Group'
                              ORDER BY Business_Unit_Type__c DESC]) {
                                  countries.add(item);
                              }
        return countries;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Orga_BU__c> getSelectOptionsGroupBusinessUnits() {
        List<Orga_BU__c> groupBusinessUnits = new List<Orga_BU__c>();       
        for (Orga_BU__c item: [SELECT Id, BU_Code__c, Name, Business_Unit_Type__c
                               FROM Orga_BU__c
                               WHERE RecordType.DeveloperName = 'Group']) {
                                   groupBusinessUnits.add(item);
                               }
        return groupBusinessUnits;
    }
    
    @AuraEnabled(cacheable=true)
    public static String  generateInvoice(String c, String d) {
        System.debug('Country :'+c+'+Date :'+d);
        if(d != null){
            Id batchInstanceId = Database.executeBatch(new GenerateInvoicesBatch('MassBatchControllerForLightning', c, null, null, Date.valueOf(d)), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String callCalculateTo(String id, String d) {
        if(d != null){
            Date selectedDate = Date.valueOf(d);
            Id batchInstanceId1 = Database.executeBatch(new CalculateBaseTOBatch('MassBatchControllerForLightning', id, NULL, NULL, selectedDate.year()), 150);
            Id batchInstanceId2 = Database.executeBatch(new CalculateTOContractBatch('MassBatchControllerForLightning', id, NULL,selectedDate.year()), 150);
            return '1';
        } 
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String dispatchingBatch(String id, String d) {
        if(d != null){
            Id batchInstanceId = Database.executeBatch(new DispatchingBatch('MassBatchControllerForLightning', id, NULL , NULL, Date.valueOf(d)), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String baseRedistributionBatch(String d) {
        if (d != NULL) {
            Id batchInstanceId = Database.executeBatch(new BaseRedistributionModelBatch('MassBatchControllerForLightning', NULL, NULL, NULL, Date.valueOf(d), NULL), 100);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String duplicateContractBatch(String id, String d) {
        if (d != null) {
            Date selectedDate = Date.valueOf(d);
            Id batchInstanceId = Database.executeBatch(new DuplicateContractBatch('MassBatchControllerForLightning', id, NULL, selectedDate.year(), Null, Null, Null), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String generateGRCRatesBatch(String id, Boolean lastActiveContract, String d) {
        if(lastActiveContract) {
            submitLastActiveContractBatch(id);
            return '1';
        } else if (d != null) {
            Id batchInstanceId = Database.executeBatch(new GenerateGRCRatesBatch('MassBatchControllerForLightning', id, null, Date.valueOf(d), lastActiveContract), 150);
            return '1';  
        }
        else
            return '0';
    }
    
    @AuraEnabled(cacheable=true)
    public static String groupContractScanBatch(String bu) {
        Id batchInstanceId = Database.executeBatch(new GroupContractScanBatch('MassBatchControllerForLightning', false, null, bu), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String groupContractSynchroBatch(String bu) {
        Id batchInstanceId = Database.executeBatch(new GroupContractSynchroBatch('MassBatchControllerForLightning', false, null, bu), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String groupInvoiceScanBatch(String d) {
        if (d != null) {
            Id batchInstanceId = Database.executeBatch(new GroupInvoiceScanBatch('MassBatchControllerForLightning', false, null, Date.valueOf(d)), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String groupInvoiceSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupInvoiceSynchroBatch('MassBatchControllerForLightning', false, null), 150);
        return '1';
    }
    
    @AuraEnabled
    public static String groupInvoicePaymentScanBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupInvoicePaymentScanBatch('MassBatchControllerForLightning', false, null), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String groupInvoicePaymentSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupInvoicePaymentSynchroBatch('MassBatchControllerForLightning', false, null), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String penaltiesScanSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new PenaltiesScanSynchroBatch('MassBatchControllerForLightning', null), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitGroupRebatePaymentScanBatch(String d) {
        if (d != null) {
            Id batchInstanceId = Database.executeBatch(new GroupRebatePaymentScanBatch('MassBatchControllerForLightning', false, null, Date.valueOf(d)), 150);  
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitGroupRebatePaymentSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupRebatePaymentSynchroBatch('MassBatchControllerForLightning', null), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitCommercialPlanScanContractBatch(String id, String d) {
        if (d != null) {
            Id batchInstanceId = Database.executeBatch(new CommercialPlanScanBatch('MassBatchControllerForLightning', null, id, d, true, false), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitCommercialPlanScanStatusBatch(String id, String d) {
        if (d != null) {
            Id batchInstanceId = Database.executeBatch(new CommercialPlanScanBatch('MassBatchControllerForLightning', null, id, d, false, true), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitCloseSupplierBatch() {
        Id batchInstanceId = Database.executeBatch(new CloseSupplierBatch('MassBatchControllerForLightning', null), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitLastActiveContractBatch(String id) {
        Id batchInstanceId = Database.executeBatch(new LastActiveContractBatch('MassBatchControllerForLightning', id, null), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitSellinToPurchaseBatch(String id, String d) {
        Integer year;
        Integer month;
        if (d != null) {
            Date selectedDate = Date.valueOf(d);
            year = selectedDate.year();
            month = selectedDate.month();
        }
        List<Id> buIds = id != null ? new List<Id>{id} : null;
        List<Integer> months = month != null ? new List<Integer>{month} : null;
        Id batchInstanceId = Database.executeBatch(new SellinToPurchaseBatch('MassBatchControllerForLightning', null, buIds,  null, null, months, year, null), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitReparentingSellinBatch(String id, String d) {
        if (d != null) { 
            Id batchInstanceId = Database.executeBatch(new ReparentingSellinBatch('MassBatchControllerForLightning', null, null, null, null, null, null, null, null, true, id, Date.valueOf(d)), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitInvoiceReminderBatch(Integer selectedReminderLevel) {
        Integer reminderLevel = 0, reminderValue = 0;
        String reminderDescription;
        List<Id> reminderBUIds = new List<Id>();
        if(selectedReminderLevel != null){
            reminderLevel = selectedReminderLevel;
        }
        System.debug('>>>reminder :' +selectedReminderLevel);
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        if(negoSettings != null){
            if(reminderLevel > 0) {
                if(reminderLevel == 1 && negoSettings.reminderValue1 != null){
                    reminderValue = negoSettings.reminderValue1;
                    reminderDescription = negoSettings.reminderDescription1;
                }
                if(reminderLevel == 2 && negoSettings.reminderValue2 != null){
                    reminderValue = negoSettings.reminderValue2;
                    reminderDescription = negoSettings.reminderDescription2;
                }
                if(reminderLevel == 3 && negoSettings.reminderValue3 != null){
                    reminderValue = negoSettings.reminderValue3;
                    reminderDescription = negoSettings.reminderDescription3;
                }
            }
            reminderBUIds = negoSettings.reminderBUManagedList;
        }
        Id batchInstanceId = Database.executeBatch(new InvoiceReminderBatch('MassBatchControllerForLightning', null, reminderBUIds, reminderLevel, reminderValue, reminderDescription), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String  submitPurchasesNegoScopeBatch(String id, String d) {
        if (d != null) {
            Date selectedDate = Date.valueOf(d);
            Id batchInstanceId = Database.executeBatch(new PurchasesNegoScopeBatch('MassBatchControllerForLightning', id, selectedDate.year()), 150);
            return '1';
        }
        else{
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitCounterpartiesScanContractBatch(String id, String d) {
        Id batchInstanceId = Database.executeBatch(new CounterpartiesScanBatch('MassBatchControllerForLightning', null, id, d, true, false), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitCounterpartiesScanStatusBatch(String id, String d) {
        Id batchInstanceId = Database.executeBatch(new CounterpartiesScanBatch('MassBatchControllerForLightning', null, id, d, false, true), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitMarketDataCollectionScanBatch(String d) {
        Id batchInstanceId = Database.executeBatch(new MarketDataCollectionHeadScanBatch('MassBatchControllerForLightning', null, Date.valueOf(d)), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitMarketDataCollectionSynchroBatch(String d) {        
        Id batchInstanceId = Database.executeBatch(new MarketDataCollectionSynchroBatch('MassBatchControllerForLightning', null, Date.valueOf(d)), 150);
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitGenerateSFPlanning() {
        Id batchInstanceId = Database.executeBatch(new GenerateAssortmentSFPlanningBatch('MassBatchControllerForLightning', null));
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitUpdateSFPlanning(String d) {
        Id batchInstanceId = Database.executeBatch(new UpdateAssortmentSFPlanningBatch('MassBatchControllerForLightning', Date.valueOf(d)));
        return '1';
    }
    
    @AuraEnabled(cacheable=true)
    public static String submitConsolidateAssortmentBatch(String id, String d) {
        Set<Integer> years;
        Set<Id> countryIds;
        Date SelectedDate = Date.valueOf(d);
        if (SelectedDate != null) {
            years = new Set<Integer>{SelectedDate.year()};
        }
        if(id != null) {
            countryIds = new Set<Id>{id};
        }
        Id batchInstanceId = Database.executeBatch(new ConsolidateAssortmentBatch('MassBatchControllerForLightning', countryIds, years, null), 150);
        return '1';   
    }
    @AuraEnabled(cacheable=true)
    public static String uploadFile(String id, String fileuploaded, Boolean isYearlyDistribution, String nameFile, String d) {
        System.debug('Country :'+id+' file '+fileuploaded+' is yearly '+isYearlyDistribution);
        Document document = new Document();
        Blob blobFile = Blob.valueOf(fileuploaded);
        document.Body = blobFile;
        Date selectedDate = Date.valueOf(d);
        List<List<String>> records = new List<List<String>>();
        List<Contract__c> contracts = [SELECT Id
                                       FROM Contract__c
                                       WHERE Contract_BU__c = :id
                                       AND CALENDAR_YEAR(Contract_EDate__c) = :selectedDate.year()
                                       AND Contract_Type__c = 'Contract'
                                       AND((D_N__c = 'D' AND Status__c = 'Validated')
                                           OR (D_N__c = 'N' AND Status__c = 'Signed'))];
        
        if (contracts != Null && contracts.size() > 0) {
            if(document.name.endsWith('.csv')) {
                String contentData = fileuploaded;
                records = NegoptimHelper.parseCSV(contentData, true);
                if (records[0].size() == 21 || records[0].size() == 9) {
                    String folderName = 'Mass Distribution';
                    Folder myFolder;
                    try { 
                        myFolder = [Select Id From Folder Where Name = :folderName LIMIT 1];
                    } catch (Exception e) {
                        myFolder = Null;
                    }
                    if (myFolder != Null) {
                        Orga_BU__c country = [Select Name From Orga_BU__c Where Id = :id LIMIT 1];
                        document.Body = blobFile;
                        document.FolderId = myFolder.Id;
                        document.AuthorId = UserInfo.getUserId();
                        document.Name = System.Today().year() + '_' + country.Name + '_MASS_DISPATCHING__' + System.now().format('MM_dd_yyyy-hh_mm_ss') + '.csv';
                        String [] fields = new String [] {'Body', 'FolderId', 'AuthorId', 'Name'};
                            if (checkUpdatibility(Schema.Document.SObjectType, fields)
                                || checkCreatibility(Schema.Document.SObjectType, fields)) {
                                    try {
                                        upsert document;
                                    } catch(DMLException e) {
                                        System.debug(e.getDmlMessage(0));
                                    }
                                    Id batchInstanceId = Database.executeBatch(new MassDistributionBatch(id, String.valueOf(selectedDate.year()), blobFile, isYearlyDistribution), 1000);
                                    return '1';
                                } else {
                                    System.debug('Document not upserted.');
                                    return 'Document not upserted.';
                                }
                    } else {
                        System.debug('"' + folderName + '" folder name does not exist.');
                        return '"' + folderName + '" folder name does not exist.';
                    }
                } else {
                    System.debug('ERROR-001: I/O EXCEPTION. Invalid column number!');
                    return 'ERROR-001: I/O EXCEPTION. Invalid column number!';
                }
            } else {
                System.debug('ERROR-001: I/O EXCEPTION. File extension is not .csv');
                return 'ERROR-001: I/O EXCEPTION. File extension is not .csv';
            }
        } else {
            Orga_BU__C country = [SELECT Name FROM Orga_BU__c WHERE Id = :id ];
            System.debug('No signed contract found in ' + country.Name + 'for the year ' + selectedDate.year() + '.');
            return '0';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String uploadConditionPenaltiesExcelFile(String fileName, String file, String selectedSeperator) {
        if(fileName.endsWith('.csv')) {
            Blob blobFile = Blob.valueOf(file);
            Id batchInstanceId = Database.executeBatch(new MassConditionPenaltiesBatch('MassBatchControllerForLightning', blobFile, selectedSeperator), 1000);
            return '1';
        } else {
            System.debug('ERROR-001: I/O EXCEPTION. File\'s extension is not ".csv"!');
            return 'ERROR-001: I/O EXCEPTION. File\'s extension is not ".csv"!';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getSobjectsLabel() {
        Map<String, String> objectsLabelMap = new  Map<String, String>();
        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()) {
            String name = objTyp.getDescribe().getName();
            String label = objTyp.getDescribe().getLabel();
            if(name.contains('__c')){
                objectsLabelMap.put(name,label);
            }
        }
        return objectsLabelMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getFieldsLabel(String objectName) {
        Map<String,String> fieldLabelMap = new Map<String,String>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectName);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        for (String fieldName: fieldMap.keySet()) {
           fieldLabelMap.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
        }
        return fieldLabelMap;
    } 
    
    /**
     * Check Field Level Security for updating
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    private static Boolean checkUpdatibility(Schema.SObjectType objType, String[] fields) {
        // check access on update SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isUpdateable()){
            system.debug('Insufficient access to update ' + sObjectName);
            return false;
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has update access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isUpdateable()) {
                system.debug('Insufficient access to update "' + sObjectName + '.' + field + '"');
                return false;
            }
        }
        return true;
    }
    
    /**
     * Check SObject Level Security for Deleting
     * */
    private static Boolean checkDeletibility(Schema.SObjectType objType) {
        // check access on delete SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isDeletable()){
            system.debug('Insufficient access to delete ' + sObjectName);
            return false;
        }
        return true;
    }
    
    /**
      * Check Field Level Security for inserting
      * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
      * */
    private static Boolean checkCreatibility(Schema.SObjectType objType, String[] fields) {
        // check access on insert SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isCreateable()){
            system.debug('Insufficient access to insert ' + sObjectName);
            return false;
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has create access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isCreateable()) {
                system.debug('Insufficient access to insert "' + sObjectName + '.' + field + '"');
                return false;
            }
        }        
        return true;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<JobsWrapper> getJobs(){
        
        List<String> classNameList = new List<String>{
    								'CalculateBaseTOBatch', 'MergeContractBatch', 'DispatchingBatch',
    								'GenerateInvoicesBatch', 'DuplicateContractBatch', 'MassDistributionBatch',
									'PurchasesNegoScopeBatch', 'CalculateTOContractBatch', 'GroupContractScanBatch',
                                    'GroupContractSynchroBatch', 'GroupInvoiceScanBatch', 'GroupInvoiceSynchroBatch',
                                    'GroupInvoicePaymentScanBatch', 'GroupInvoicePaymentSynchroBatch', 'GroupRebatePaymentScanBatch',
                                    'GroupRebatePaymentSynchroBatch', 'PenaltiesScanSynchroBatch', 'GenerateGRCRatesBatch',
                                    'MassConditionPenaltiesBatch', 'CloseSupplierBatch', 'CommercialPlanScanBatch', 'LastActiveContractBatch',
                					'InvoiceReminderBatch', 'SellinToPurchaseBatch', 'ReparentingSellinBatch', 'BaseRedistributionModelBatch',
                                    'MarketDataCollectionScanBatch', 'CounterpartiesScanBatch', 'GenerateAssortmentSFPlanningBatch',
                                    'UpdateAssortmentSFPlanningBatch','ConsolidateAssortmentBatch'};
                    List<AsyncApexJob> batchJob = [SELECT Id, CreatedDate, Status, CompletedDate, TotalJobItems, JobItemsProcessed,
                                                   NumberOfErrors, CreatedBy.Name, CreatedBy.FirstName, JobType,MethodName, ApexClass.Name
                                                   FROM AsyncApexJob
                                                   WHERE ApexClass.Name IN :classNameList
                                                   AND JobType != 'BatchApexWorker'
                                                   ORDER BY CreatedDate DESC LIMIT 20];
        
        Map<Id, Id> jobsIdLogMap = new Map<Id, Id>();
        for(Log__c item : [SELECT Id, Apex_Job_ID__c
                           FROM Log__c
                           WHERE Status__c IN  :new List<String> {'Completed','Aborted','Failed'}
                           AND Apex_Job_ID__c IN :new Map<String, AsyncApexJob>(batchJob).keySet()])
        {
            jobsIdLogMap.put(item.Apex_Job_ID__c, item.Id);
        }
        JobsWrapper JobsWrapper;
        List<JobsWrapper> listJobsWrapper = new List<JobsWrapper>();
        for(AsyncApexJob jobObject : batchJob) {
            String completionDate = jobObject.CompletedDate != null ? jobObject.CompletedDate.format() : '';
            jobsWrapper = new JobsWrapper(jobObject.Id, jobObject.CreatedDate.format(), jobObject.Status, completionDate, jobObject.TotalJobItems, jobObject.JobItemsProcessed, jobObject.NumberOfErrors, jobObject.CreatedBy.Name, jobObject.JobType,jobObject.MethodName, jobObject.ApexClass.Name); 
            if(jobsIdLogMap.containsKey(jobObject.Id)) {
                jobsWrapper.logId = jobsIdLogMap.get(jobObject.Id);
                jobsWrapper.URL= '/'+jobsIdLogMap.get(jobObject.Id);
            }
            listJobsWrapper.add(jobsWrapper);
        }
        System.debug('>>> '+listJobsWrapper);
        return listJobsWrapper;
    }
    
    public class JobsWrapper{
        @AuraEnabled
        public String Id {get; set;}
        @AuraEnabled
        public String Status {get; set;}
        @AuraEnabled
        public String CreatedDate  {get; set;}
        @AuraEnabled
        public String CompletedDate  {get; set;}
        @AuraEnabled
        public Integer TotalJobItems {get; set;} 
        @AuraEnabled
        public Integer JobItemsProcessed {get; set;}
        @AuraEnabled
        public Integer NumberOfErrors {get; set;}
        @AuraEnabled
        public String submitterFullName {get; set;}
        @AuraEnabled
        public String JobType {get; set;}
        @AuraEnabled
        public String MethodName {get; set;}
        @AuraEnabled
        public String ApexClassName {get; set;}
        @AuraEnabled
        public Id logId {get; set;}
        @AuraEnabled
        public String URL {get; set;}
        public JobsWrapper(String Id, String CreatedDate, String Status, String CompletedDate,
                           Integer TotalJobItems, Integer JobItemsProcessed,Integer NumberOfErrors,
                           String submitterFullName, String JobType, String MethodName, String ApexClassName) {
                               this.Id = Id;
                               this.CreatedDate = CreatedDate;
                               this.Status = Status;
                               this.CompletedDate = CompletedDate;
                               this.JobItemsProcessed = JobItemsProcessed;
                               this.TotalJobItems = TotalJobItems;
                               this.NumberOfErrors = NumberOfErrors;
                               this.submitterFullName = submitterFullName;
                               this.JobType = JobType;
                               this.MethodName = MethodName;
                               this.ApexClassName = ApexClassName;
                               this.URL = '/'+Id;
                           }
        
    }
}