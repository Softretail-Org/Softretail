/**
 * @author ULiT
 * @description Apex Controller Class to run and manage the Batches
 **/
public with sharing class MassBatchFormController extends NegoptimBaseController {
    
    public NegoptimSettings settings {get; set;}
    public Id selectedCountry {get; set;}
    public List<SelectOption> countries {get; set;}
    public String selectedGroupBU {get; set;}
    public String selectedSeperator {get; set;}
    public List<SelectOption> groupBusinessUnits {get; set;}
    public List<SelectOption> seperatorOptions {get; set;}
    public Contract__c contract {get; set;}
    public List<jobsWrapper> listJobsWrapper {get; set;}
	public Blob file {get; set;}
	public Document document {get;set;}
	public Id folderId {get;set;}
	public List<List<String>> records;
	public String option = null;
    public String fileName {get;set;}
    public Integer selectedReminderLevel {get; set;}
    private String delimiter;
    public Boolean lastActiveContract {get; set;}
    // Monitor if the actionPoller in the page is active
    public Boolean isPollerActive {get; set;}
    // parameters for RecalculateAssortmentDetailBatch
    public List<Id> buSourceIdList {get; set;}
    public List<Id> buTargetIdList {get; set;}
    public Boolean L4LOnly {get; set;}
    public Boolean inPreparationOnly {get; set;}
    public Integer assortmentyear {get; set;}
    
    public MassBatchFormController() {
    	// Load Settings
    	settings = GlobalSettingsManager.loadGlobalSettings();
        delimiter = settings.delimiter;
    	contract = new Contract__c(Contract_BDate__c = date.newInstance(System.Today().year(), 1, 1));
		countries = NegoptimHelper.getSelectOptionsCountries(true);
        groupBusinessUnits = getSelectOptionsGroupBusinessUnits(true);
        seperatorOptions = getSelectOptionsSeperators(true);
		listJobsWrapper = new List<jobsWrapper>();
		getLatestActiveJobs();
		document = new Document();
		option = 'Monthly';
        // parameters for RecalculateAssortmentDetailBatch
        this.buSourceIdList = new List<Id>();
        this.buTargetIdList = new List<Id>();
        this.L4LOnly = false;
        this.inPreparationOnly = false;
        this.assortmentyear = Date.today().year();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'This page use Global Settings.<a href="/apex/GlobalSettings" target="_blank">View</a>'));
        isPollerActive = false;
    }
    // Latest Active Jobs.
    public PageReference getLatestActiveJobs() {
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
        isPollerActive = false;
        // Activate the poller if theare are a job holding or in process
        for(AsyncApexJob job : batchJob) {
            if(job.Status != 'Completed' && job.Status != 'Aborted' && job.Status != 'Failed') {
                isPollerActive = true;
                break;
            }
        }
        Map<Id, Id> jobsIdLogMap = new Map<Id, Id>();
        for(Log__c item : [SELECT Id, Apex_Job_ID__c
                           FROM Log__c
                           WHERE Status__c IN  :new List<String> {'Completed','Aborted','Failed'}
                           AND Apex_Job_ID__c IN :new Map<String, AsyncApexJob>(batchJob).keySet()])
        {
            jobsIdLogMap.put(item.Apex_Job_ID__c, item.Id);
        }
        JobsWrapper JobsWrapper;
        listJobsWrapper = new List<JobsWrapper>();
        for(AsyncApexJob jobObject : batchJob) {
            String completionDate = jobObject.CompletedDate != null ? jobObject.CompletedDate.format() : '';
            jobsWrapper = new JobsWrapper(jobObject.Id, jobObject.CreatedDate.format(), jobObject.Status, completionDate, jobObject.TotalJobItems, jobObject.JobItemsProcessed, jobObject.NumberOfErrors, jobObject.CreatedBy.Name, jobObject.JobType,jobObject.MethodName, jobObject.ApexClass.Name); 
            if(jobsIdLogMap.containsKey(jobObject.Id)) {
                jobsWrapper.logId = jobsIdLogMap.get(jobObject.Id);
            }
            listJobsWrapper.add(jobsWrapper);
        }
        return null;
    }
    // Calculate Base TO, calculate TO Contract.
    public PageReference submitCalculateContractBatch() {
        if (contract.Contract_BDate__c != null) {
            Id batchInstanceId1 = Database.executeBatch(new CalculateTOContractBatch('MassBatchForm', selectedCountry, NULL, contract.Contract_BDate__c.year()), 150);
            Id batchInstanceId2 = Database.executeBatch(new CalculateBaseTOBatch('MassBatchForm', selectedCountry, NULL, NULL, contract.Contract_BDate__c.year()), 150);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Calculation Base TO', (String)batchInstanceId1 + ' & ' + (String)batchInstanceId2})));
            getLatestActiveJobs();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Validation_Error));
        }
        return null;
    }
    // Generate Invoices.
    public PageReference submitGenerateInvoicesBatch() {
        if (contract.Contract_BDate__c != NULL) {
            Id batchInstanceId = Database.executeBatch(new GenerateInvoicesBatch('MassBatchForm', selectedCountry, null, null, contract.Contract_BDate__c), 150);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Generating Invoices', (String)batchInstanceId})));
			getLatestActiveJobs();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Validation_Error));
        }
        return null;
    }
    // Generate Assortment SF Planning.
    public PageReference submitGenerateSFPlanning() {
        Id batchInstanceId = Database.executeBatch(new GenerateAssortmentSFPlanningBatch('MassBatchForm', null));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Generating SF Planning', (String)batchInstanceId})));
        getLatestActiveJobs();
        return null;
    }
    // Update Assortment SF Planning.
    public PageReference submitUpdateSFPlanning() {
        Id batchInstanceId = Database.executeBatch(new UpdateAssortmentSFPlanningBatch('MassBatchForm', contract.Contract_BDate__c));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Update SF Planning', (String)batchInstanceId})));
        getLatestActiveJobs();
        return null;
    }
    // Dispatching.
    public PageReference submitDispatchingBatch() {
        if (contract.Contract_BDate__c != NULL) {
            Id batchInstanceId = Database.executeBatch(new DispatchingBatch('MassBatchForm', selectedCountry, NULL , NULL, contract.Contract_BDate__c), 150);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Dispatching', (String)batchInstanceId})));
            getLatestActiveJobs();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Validation_Error));
        }
        return null;
    }
    // Base Redistribution.
    public PageReference submitBaseRedistributionBatch() {
        if (contract.Contract_BDate__c != NULL) {
            Id batchInstanceId = Database.executeBatch(new BaseRedistributionModelBatch('MassBatchForm', NULL, NULL, NULL, contract.Contract_BDate__c, NULL), 100);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Base Redistribution', (String)batchInstanceId})));
            getLatestActiveJobs();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Validation_Error));
        }
        return null;
    }
    // Duplicate Contract.
    public PageReference submitDuplicateContractBatch() {
        if (contract.Contract_BDate__c != null) {
            Id batchInstanceId = Database.executeBatch(new DuplicateContractBatch('MassBatchForm', selectedCountry, NULL, contract.Contract_BDate__c.year(), Null, Null, Null),150);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Duplicate Contracts procedure', (String)batchInstanceId})));     
            getLatestActiveJobs();       
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Validation_Error));
        }
        return null;
    }
    // GRC Contract Rates
    public PageReference generateGRCRatesBatch() {
        if(lastActiveContract) {
        	return submitLastActiveContractBatch();
        } else {
        	Id batchInstanceId = Database.executeBatch(new GenerateGRCRatesBatch('MassBatchForm', selectedCountry, null, contract.Contract_BDate__c, lastActiveContract), 150);
           	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Generate GRC Contract Rates', (String)batchInstanceId})));     
            getLatestActiveJobs();
        }
        return null;
    }
    // Scan Group Contract.
    public PageReference submitGroupContractScanBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupContractScanBatch('MassBatchForm', false, null, selectedGroupBU), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Scan Group Contract', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Synchro Group Contract.
    public PageReference submitGroupContractSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupContractSynchroBatch('MassBatchForm', false, null, selectedGroupBU), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Synchro Group Contract', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Scan Group Invoice.
    public PageReference submitGroupInvoiceScanBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupInvoiceScanBatch('MassBatchForm', false, null, contract.Contract_BDate__c),150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Scan Group Invoice', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Synchro Group Invoice.
    public PageReference submitGroupInvoiceSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupInvoiceSynchroBatch('MassBatchForm', false, null),150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Synchro Group Invoice', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Scan Group Invoice Payment.
    public PageReference submitGroupInvoicePaymentScanBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupInvoicePaymentScanBatch('MassBatchForm', false, null),150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Scan Group Invoice Payment', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Synchro Group Invoice Payment.
    public PageReference submitGroupInvoicePaymentSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupInvoicePaymentSynchroBatch('MassBatchForm', false, null),150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Synchro Group Invoice', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Scan/Synchro Penalties.
    public PageReference submitPenaltiesScanSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new PenaltiesScanSynchroBatch('MassBatchForm', null), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Scan/Synchro Penalties', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Scan Group Rebate Payment.
    public PageReference submitGroupRebatePaymentScanBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupRebatePaymentScanBatch('MassBatchForm', false, null, contract.Contract_BDate__c),150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Scan Group Rebate Payment', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Synchro Group Rebate Payment.
    public PageReference submitGroupRebatePaymentSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new GroupRebatePaymentSynchroBatch('MassBatchForm', null),150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Synchro Group Rebate Payment', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Scan Contracts Commercial Plan Detail
    public PageReference submitCommercialPlanScanContractBatch() {
        Id batchInstanceId = Database.executeBatch(new CommercialPlanScanBatch('MassBatchForm', null, selectedCountry, String.valueOf(contract.Contract_BDate__c), true, false), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Commercial Plan Scan Contract', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Scan Status Commercial Plan Detail
    public PageReference submitCommercialPlanScanStatusBatch() {
        Id batchInstanceId = Database.executeBatch(new CommercialPlanScanBatch('MassBatchForm', null, selectedCountry, String.valueOf(contract.Contract_BDate__c), false, true), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Commercial Plan Scan Status', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // Close Supplier
    public PageReference submitCloseSupplierBatch() {
        Id batchInstanceId = Database.executeBatch(new CloseSupplierBatch('MassBatchForm', null), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Close Supplier', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Scan Last Active Contract
    public PageReference submitLastActiveContractBatch() {
        Id batchInstanceId = Database.executeBatch(new LastActiveContractBatch('MassBatchForm', selectedCountry, null), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Last Active Contract', (String)batchInstanceId})));     
		getLatestActiveJobs();
        return null;
    }
    // copy sell in flow to purchase flow pg
    public PageReference submitSellinToPurchaseBatch() {
        Integer year;
        Integer month;
        if (contract.Contract_BDate__c != null) {
            year = contract.Contract_BDate__c.year();
            month = contract.Contract_BDate__c.month();
        }
        List<Id> buIds = selectedCountry != null ? new List<Id>{selectedCountry} : null;
        List<Integer> months = month != null ? new List<Integer>{month} : null;
        Id batchInstanceId = Database.executeBatch(new SellinToPurchaseBatch('MassBatchForm', null, buIds,  null, null, months, year, null), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Sell in flow to Purchase flow PG', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Re-Scan Sell_in
    public PageReference submitReparentingSellinBatch() {
        Id batchInstanceId = Database.executeBatch(new ReparentingSellinBatch('MassBatchForm', null, null, null, null, null, null, null, null, true, selectedCountry, contract.Contract_BDate__c), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Reparenting Sell in Batch', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Scan Market Data Collection
    public PageReference submitMarketDataCollectionScanBatch() {
        Id batchInstanceId = Database.executeBatch(new MarketDataCollectionHeadScanBatch('MassBatchForm', null, contract.Contract_BDate__c), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'MarketDataCollectionScanBatch', (String)batchInstanceId})));
        getLatestActiveJobs();
        return null;
    }
    // Synchro Market Data Collection
    public PageReference submitMarketDataCollectionSynchroBatch() {
        Id batchInstanceId = Database.executeBatch(new MarketDataCollectionSynchroBatch('MassBatchForm', null, contract.Contract_BDate__c), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'MarketDataCollectionSynchroBatch', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Scan Counterparties Contracts
    public PageReference submitCounterpartiesScanContractBatch() {
        Id batchInstanceId = Database.executeBatch(new CounterpartiesScanBatch('MassBatchForm', null, selectedCountry, String.valueOf(contract.Contract_BDate__c), true, false), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Counterparties Scan Contract', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Scan Counterparties Status
    public PageReference submitCounterpartiesScanStatusBatch() {
        Id batchInstanceId = Database.executeBatch(new CounterpartiesScanBatch('MassBatchForm', null, selectedCountry, String.valueOf(contract.Contract_BDate__c), false, true), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Counterparties Scan Status', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Consolidate Assortment
    public PageReference submitConsolidateAssortmentBatch() {
        Set<Integer> years;
        Set<Id> countryIds;
        if (contract.Contract_BDate__c != null) {
            years = new Set<Integer>{contract.Contract_BDate__c.year()};
        }
        if(selectedCountry != null) {
            countryIds = new Set<Id>{selectedCountry};
        }
        Id batchInstanceId = Database.executeBatch(new ConsolidateAssortmentBatch('MassBatchForm', countryIds, years, null), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Consolidate Assortment', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Invoice Reminder
    public PageReference submitInvoiceReminderBatch() {
        Integer reminderLevel = 0, reminderValue = 0;
        String reminderDescription;
        List<Id> reminderBUIds = new List<Id>();
        if(selectedReminderLevel != null){
            reminderLevel = selectedReminderLevel == 1 ? 1 : selectedReminderLevel == 2 ? 2 : selectedReminderLevel == 3 ? 3 : 0;
        }
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
        Id batchInstanceId = Database.executeBatch(new InvoiceReminderBatch('Mass Batch', null, reminderBUIds, reminderLevel, reminderValue, reminderDescription), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Invoice Reminder', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
    // Get Reminder Level
    public List<SelectOption> getReminderLevels() {
        List<SelectOption> options = new List<SelectOption>();
        String[] levels = new String[]{'0', '1', '2', '3'};
        for(String l : levels) {
            options.add(new SelectOption(l, l));
        }
        return options;
    }
    // Return select option list for all Group Business Unit
    public List<SelectOption> getSelectOptionsGroupBusinessUnits(Boolean defaultOption) {
        List<SelectOption> groupBusinessUnits = new List<SelectOption>();       
        if (defaultOption) {
            groupBusinessUnits.add(new SelectOption('', '--'));
        }
        for (Orga_BU__c item: [SELECT Id, Name, BU_Code__c
                               FROM Orga_BU__c
                               WHERE RecordType.DeveloperName = 'Group'])
        {
            groupBusinessUnits.add(new SelectOption(item.BU_Code__c, item.Name));
        }
        return groupBusinessUnits;
    }
    
    public List<SelectOption> getSelectOptionsSeperators(Boolean defaultOption) {
    	List<SelectOption> seperators = new List<SelectOption>();
    	if (defaultOption) seperators.add(new SelectOption(delimiter, delimiter));
		Set<String> delimeters = new Set<String>{',', ';', '|', ':'};
		for (String str : delimeters) if (str != delimiter) seperators.add(new SelectOption(str, str));
    	return seperators;
    }
    // Merge Contract.
    /*public PageReference submitMergeContractBatch() {
    	if (contract.Contract_BDate__c != NULL) {
            year = contract.Contract_BDate__c.year();
        }
        if(year != 0 && selectedCountry!= NULL) { //&& contract.Contract_Type__c == 'Simulation'
        	Id batchInstanceId = Database.executeBatch(new MergeContractBatch(selectedCountry, null, null, parentContractIds, contract.Contract_BDate__c.year()));
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Contract Merge', (String)batchInstanceId})));     
			getLatestActiveJobs();
        } else {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Invalid Choice'));
        }
        return null;
    }*/
    // Mass Distribution.
    public PageReference upload() {
    	if(selectedCountry == Null) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-001: I/O EXCEPTION. No country chosen!');
            ApexPages.addMessage(msg);
            sendErrorMessage();
            return Null;
        }
    	if(file == Null) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-001: I/O EXCEPTION. No file chosen!');
            ApexPages.addMessage(msg);
            sendErrorMessage();
        } else {
            List<Contract__c> contracts = [SELECT Id
                                           FROM Contract__c
                                           WHERE Contract_BU__c = :selectedCountry
                                           AND CALENDAR_YEAR(Contract_EDate__c) = :contract.Contract_BDate__c.year()
                                           AND Contract_Type__c = 'Contract'
                                           AND((D_N__c = 'D' AND Status__c = 'Validated')
                                               OR (D_N__c = 'N' AND Status__c = 'Signed'))];
        
        	if (contracts != Null && contracts.size() > 0) {
        		if(document.name.endsWith('.csv')) {
	                String contentData = file.toString();
	            	records = NegoptimHelper.parseCSV(contentData, true);
	                if (records[0].size() == 21 || records[0].size() == 9) {
	                    Boolean isYearlyDistribution;
	                    /*if (records[0].size() == 21) {
	                        isYearlyDistribution = true;
	                    } else {
	                        isYearlyDistribution = false;
	                    }*/
	                    String folderName = 'Mass Distribution';
	                    Folder myFolder;
	                    try { 
	                    	myFolder = [Select Id From Folder Where Name = :folderName LIMIT 1];
	                    } catch (Exception e) {
	                    	myFolder = Null;
	                    }
	                    if (myFolder != Null) {
	                    	Orga_BU__c country = [Select Name From Orga_BU__c Where Id = :selectedCountry LIMIT 1];
	                    	document.Body = file;
		                    document.FolderId = myFolder.Id;
		                    document.AuthorId = UserInfo.getUserId();
		                    document.Name = System.Today().year() + '_' + country.Name + '_MASS_DISPATCHING__' + System.now().format('MM_dd_yyyy-hh_mm_ss') + '.csv';
		                    String [] fields = new String [] {'Body', 'FolderId', 'AuthorId', 'Name'};
		                    if (checkUpdatibility(Schema.Document.SObjectType, fields)
				            	|| checkCreatibility(Schema.Document.SObjectType, fields)) {
			            		try {
			            			upsert document;
			            		} catch(DMLException e) {
						        }
						        if (option == 'Yearly') {
						        	isYearlyDistribution = True;
						        } else {
						        	isYearlyDistribution = False;
						        }
				            	Id batchInstanceId = Database.executeBatch(new MassDistributionBatch(this.selectedCountry, String.valueOf(contract.Contract_BDate__c.year()), this.file, isYearlyDistribution), 1000);
			    				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Mass Distribution', (String)batchInstanceId})));     
			                    getLatestActiveJobs();
				            } else {
				            	ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Document not upserted.');
		                    	ApexPages.addMessage(msg);
				            }
	                    } else {
	                    	ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, '"' + folderName + '" folder name does not exist.');
		                    ApexPages.addMessage(msg);
	                    }
	                } else {
	                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-001: I/O EXCEPTION. Invalid column number!');
	                    ApexPages.addMessage(msg);
	                    sendErrorMessage();
	                }
			    } else {
			    	ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-001: I/O EXCEPTION. File\'s extension is not ".csv"!');
		            ApexPages.addMessage(msg);
		            sendErrorMessage();
			    }
        	} else {
        		Orga_BU__C country = [SELECT Name FROM Orga_BU__c WHERE Id = :selectedCountry ];
        		ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'No signed contract found in "' + country.Name + '" for the year "' + contract.Contract_BDate__c.year() + '".');
            	ApexPages.addMessage(msg);
        	}
        }
        return Null;
    }
    // Purchases-NegoScope.
    public PageReference submitPurchasesNegoScopeBatch() {
    	if (contract.Contract_BDate__c != NULL && selectedCountry != NULL) {
            Id batchInstanceId = Database.executeBatch(new PurchasesNegoScopeBatch('MassBatchForm', selectedCountry, contract.Contract_BDate__c.year()), 150);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Purchases-NegoScope', (String)batchInstanceId})));
            getLatestActiveJobs();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Validation_Error));
        }
        return null;
    }
    // Upload condition penalties files
    public PageReference uploadConditionPenaltiesExcelFile() {
    	if(file == Null) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-001: I/O EXCEPTION. No file chosen!');
            ApexPages.addMessage(msg);
            sendErrorMessage();
        } else {
        	if(fileName.endsWith('.csv')) {
                try {
                    this.file.toString();
                } catch(Exception ex) {
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage());
                    ApexPages.addMessage(msg);
                    return null;
                }
        		Id batchInstanceId = Database.executeBatch(new MassConditionPenaltiesBatch('MassBatchForm', this.file, selectedSeperator), 1000);
        	    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Upload Condition Penalties', (String)batchInstanceId})));
				getLatestActiveJobs();
        	} else {
		    	ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-001: I/O EXCEPTION. File\'s extension is not ".csv"!');
	            ApexPages.addMessage(msg);
	            sendErrorMessage();
		    }
        }
        return Null;
    }
    // Recalculate Assortment Details KPIs
    public PageReference submitRecalculateAssortmentDetailBatch() {
        Id batchInstanceId = Database.executeBatch(new RecalculateAssortmentDetailBatch('MassBatchForm', this.buSourceIdList, this.buTargetIdList, this.assortmentyear, this.L4LOnly, this.inPreparationOnly));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Recalculate Assortment Detail ', (String)batchInstanceId})));     
        getLatestActiveJobs();
        return null;
    }
	// get Banners (BU Target)
    public List<SelectOption> getAssortmentBUTargetList() {
        List<SelectOption> selectOptionList = new List<SelectOption>();
        for (Orga_BU__c item : [SELECT Id, name, BU_Code__c FROM Orga_BU__c WHERE RecordType.DeveloperName = 'Banner' AND Mission__c INCLUDES ('Offer')]) {
            selectOptionList.add(new SelectOption(item.Id, item.Name + '('+ item.BU_Code__c + ')'));
        }
        return selectOptionList;
    }
	// get Banners (BU Source)
    public List<SelectOption> getAssortmentBUSourceList() {
        List<SelectOption> selectOptionList = new List<SelectOption>();
        for (Orga_BU__c item : [SELECT Id, name, BU_Code__c FROM Orga_BU__c WHERE RecordType.DeveloperName = 'Banner' AND isMasterBU__c = TRUE]) {
            selectOptionList.add(new SelectOption(item.Id, item.Name + '('+ item.BU_Code__c + ')'));
        }
        return selectOptionList;
    }
    // Send Message
    private void sendErrorMessage() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String userName = UserInfo.getUserName();
		User activeUser = [Select Email From User where Username = : userName limit 1];
        String[] toAddresses = new String[] {activeUser.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Fix Amount - Mass distribution: ');
        mail.setHTMLBody('ERROR-001: I/O EXCEPTION.');
        Integer used = Limits.getEmailInvocations();
		Integer emailLimit = Limits.getLimitEmailInvocations();
		if(used >= emailLimit) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING, 'ERROR-0--: Caught Email Exception.');
            ApexPages.addMessage(msg);
        } else {
        	try {
			  	Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
		    } catch(System.EmailException ex){
		      	// This message should be added to the page, as an exception is caught.
	      		Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Caught Email Exception: ' + ex));
		    }
        }
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Monthly','Monthly')); 
        options.add(new SelectOption('Yearly','Yearly'));
        return options; 
    }
    //
    public String getOption() {
        return option;
    }
    //
    public void setOption(String option) { this.option = option; }

    /* Wrapper class to handle Jobs */
    public class JobsWrapper {

        public String Id {get; set;}
        public String Status {get; set;}
        public String CreatedDate  {get; set;}
        public String CompletedDate  {get; set;}
        public Integer TotalJobItems {get; set;} 
        public Integer JobItemsProcessed {get; set;}
        public Integer NumberOfErrors {get; set;}
        public String submitterFullName {get; set;}
        public String JobType {get; set;}
        public String MethodName {get; set;}
        public String ApexClassName {get; set;}
        public Id logId {get; set;}
        
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
        }
    }
}