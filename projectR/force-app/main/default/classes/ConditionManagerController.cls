/**
 * @author ULiT
 * @description Controller for the page Contract Conditions Management
 **************************************************************************************************************/
global with sharing class ConditionManagerController extends NegoptimBaseController {
  
    private transient static String STARTED_FROM = 'Condition Manager Contoller';
    public Contract__c contract {get; set;}
    public ApexPages.StandardSetController setCtrlr {
        get {
            if(setCtrlr == null) {
                setCtrlr = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT Id, Name, Condition_type__c, Condition_type__r.Nego_Discount_Type__c, Condition_type__r.is_conditional__c, Condition_type__r.Condition_Mode__c, Condition_Type__r.Name, disc_bdate__c, value_amt__c, value_per__c,
                     Value_amt_approv_M1__c, Value_amt_approv_M2__c, Value_amt_approv_M3__c, Value_amt_approv_M4__c, Value_amt_approv_M5__c, Value_amt_approv_M6__c, Value_amt_approv_M7__c, 
                     Value_amt_approv_M8__c, Value_amt_approv_M9__c, Value_amt_approv_M10__c, Value_amt_approv_M11__c, Value_amt_approv_M12__c,
                     Value_amt_event_M1__c, Value_amt_event_M2__c, Value_amt_event_M3__c, Value_amt_event_M4__c, Value_amt_event_M5__c, Value_amt_event_M6__c, Value_amt_event_M7__c,
                     Value_amt_event_M8__c, Value_amt_event_M9__c, Value_amt_event_M10__c, Value_amt_event_M11__c, Value_amt_event_M12__c,
                     Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c, Value_amt_disp_M6__c, Value_amt_disp_M7__c,
                     Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c, Value_amt_disp_M11__c, Value_amt_disp_M12__c, Slab_Calc_Method_TO_Origin__c, Slab_calc_method__c,
                     slab_1__c, slab_per_1__c, slab_val_1__c, slab_2__c, slab_per_2__c, slab_val_2__c, slab_3__c, slab_per_3__c, slab_val_3__c, slab_target__c, Base_Redistribution_Model__c,
                     slab_4__c, slab_per_4__c, slab_val_4__c, slab_5__c, slab_per_5__c, slab_val_5__c, slab_6__c, slab_per_6__c, slab_val_6__c,
                     slab_7__c, slab_per_7__c, slab_val_7__c, slab_8__c, slab_per_8__c, slab_val_8__c, Y_Actu__c, Already_Invoiced__c,
                     Contract__c, disc_edate__c, rank__c, all_items__c, all_BU__c, commercial_reference__c, Minimum_Guarantee__c, Invoice_period__c, Invoicing_plan_generated__c, Is_Prenego_Envelop__c, legal_reference__c, financial_reference__c,
                     status__c, Nego_Discount_Type__c, valid__c, is_duplicable__c, comments__c, BU_Scope__c, Contract__r.Supplier_Nego_Scope__r.id, product_scope__c, product_scope__r.name
                     FROM Contract_Discount__c WHERE Contract__r.id = :contract.Id order by CreatedDate DESC]));
                setCtrlr.setPageSize(size); 
            }
            return setCtrlr;
        }
        set;
    }
    public Integer size {get; set;}
    public Integer noOfRecords {get; set;}
    public List<SelectOption> paginationSizeOptions {get; set;}
    
    public Integer selectedNegoYear {get; set;}
    public Id selectedSupplierId {get; set;}
    public Id selectedContractId {get; set;}
    // popups
    public Boolean popupNegoscope {get; set;}
    public Boolean popupSlabs {get; set;}
    public Boolean popupChildNegoscope {get; set;}
    public Boolean popupChildNegoscopeBrands {get; set;}
    public Boolean popupChildNegoscopeHEs {get; set;}
    public Boolean popupChildNegoscopePGs {get; set;}

    public List<WrapperContractNegoscope> wContractNegoscopeList {get; set;}
    
    public List<WrapperCondition> conditionList {get; set;}
    private Map<Id, Contract_Discount__c> conditionsMap = new Map<Id, Contract_Discount__c>();
    private List<Contract_Discount__c> conditionsToInsert = new List<Contract_Discount__c>();
    private List<Contract_Discount__c> conditionsToDelete = new List<Contract_Discount__c>();
    private set<Id> selectedConditions = new Set<Id>();
   // public Boolean selectAllConditions {get; set;}
    public Integer currentNegoscopeIndex {get; set;}
    public Integer currentConditionIndex {get; set;}
    public WrapperCondition wCurrentCondition {get; set;}
    public List<WrapperNegoscope> wChildNegoscopeList {get; set;}
    public List<Sup_NS_Brand__c> BrandList {get; set;}
    public List<Supplier_NS_HE__c> HEList {get; set;}
    public List<Sup_NS_PG__C> PGList {get; set;}
    public Id currentConditionId {get; set;}
    
    //Batch related - Action Poller
    private List<Id> batchIds;
    public Boolean batchInProgress {get;set;}
    //related to condition datePicker
    public boolean secondLoad {get; set;}
    // Slabs count
    public Integer[] slabs {get; set;}
    // Constructors
    public ConditionManagerController(ApexPages.StandardController stdController) {
        contract = (Contract__c)stdController.getRecord();
        selectedNegoYear = contract != null && contract.Contract_BDate__c != null ? contract.Contract_BDate__c.year() : Integer.valueOf(Date.today().year());
        selectedSupplierId = contract.Supplier__c;
        size = 10;
        noOfRecords = [SELECT COUNT() FROM Contract_Discount__c WHERE Contract__c = :contract.Id];
        // added by hawly
        conditionList = new List<WrapperCondition>();
       // refreshConditionList();
       // selectAllConditions = false;
        popupNegoscope = false;
        popupSlabs = false;
        popupChildNegoscope = false;
        popupChildNegoscopeBrands = false;
        popupChildNegoscopeHEs = false;
        popupChildNegoscopePGs = false;
        currentNegoscopeIndex = 0;
        currentConditionIndex = 0;
        wChildNegoscopeList = new List<WrapperNegoScope>();
        BrandList = new List<Sup_NS_Brand__c>();
        HEList = new List<Supplier_NS_HE__c>();
        PGList = new List<Sup_NS_PG__c>();
        batchInProgress = false;
        secondLoad = false;
        if (contract.Id != null) {
            refreshConditionList();
            secondLoad = true;
        }
        paginationSizeOptions = new List<SelectOption>();
        paginationSizeOptions.add(new SelectOption('5','5'));
        paginationSizeOptions.add(new SelectOption('10','10'));
        paginationSizeOptions.add(new SelectOption('20','20'));
        paginationSizeOptions.add(new SelectOption('50','50'));
        paginationSizeOptions.add(new SelectOption('100','100'));
    }
    
    /**
     * in case of use of custom components
	*/
    public ConditionManagerController() {
        //nothing
    }
    
    /**
     * @description Changes the size of pagination 
	************************************************************************************************************* */
    public PageReference refreshPageSize() {
        this.processSelection();
        updateConditionsMap();
        setCtrlr.setPageSize(size);
        refreshConditionList();
        restoreConditionList();
        return null;
    }
    
    /**
     * @description checks the status of ongoing batch jobs
     * used by the apex:actionPoller implemented on page
	************************************************************************************************************* */
    public PageReference checkBatchStatus() {
        if (batchIds != null) {
            List<String> messagesList = new List<String>();
            List<Id> jobIdsList = new List<Id>();
            Map<Id, Log__c> jobsIdLogMap = new Map<Id, Log__c>();
            List<AsyncApexJob> apexJobsList = [SELECT Id, Status, NumberOfErrors
                                               FROM AsyncApexJob
                                               WHERE Id IN :batchIds];
            
            for(Log__c item : [SELECT Id, Apex_Job_ID__c, Class_Name__c, status__c
                               FROM Log__c
                               WHERE Status__c IN :new List<String> {'Completed','Aborted','Failed'}
                               AND Apex_Job_ID__c IN :new Map<Id, AsyncApexJob>(apexJobsList).keySet()])
            {
                jobsIdLogMap.put(item.Apex_Job_ID__c, item);
            }
            
            if (jobsIdLogMap.size() == apexJobsList.size()) {
                for (AsyncApexJob item : apexJobsList) {
                    if(jobsIdLogMap.containsKey(item.Id)) {
                        messagesList.add('The Batch Apex Job '+ jobsIdLogMap.get(item.Id).Class_Name__c +' has ' + jobsIdLogMap.get(item.Id).status__c +'.   <a href="/' + jobsIdLogMap.get(item.Id).Id + '" target="_blank">View Log</a>');
                    }
                }
                batchIds = null;
                batchInProgress = false;
                for (String msg : messagesList) {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, msg);
                    ApexPages.addMessage(myMsg);
                }
            }
        }
        return null;
    }
        
    /**
     * @description calculates the YTD and update all conditions
	************************************************************************************************************* */
    public PageReference calculateYTD() {
        this.processSelection();
        List<Id> idContracts = new List<Id> {contract.Id};
            if(idContracts != null && idContracts.size() > 0) {
                Id batchInstanceId1 = Database.executeBatch(new CalculateTOContractBatch(STARTED_FROM , contract.Contract_BU__c, idContracts, selectedNegoYear));
                Id batchInstanceId2 = Database.executeBatch(new CalculateBaseTOBatch(STARTED_FROM , contract.Contract_BU__c, idContracts, new List<Id>(selectedConditions), selectedNegoYear));
                batchIds = new List<Id> {batchInstanceId1, batchInstanceId2};
                batchInProgress = true;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, String.format(Label.MSG_Job_In_Progress, new String[]{'Calculation Base TO', (String)batchInstanceId1 + ' & ' + (String)batchInstanceId2}));
                ApexPages.addMessage(myMsg);
            }
        return null;
    }
    
    /*
     * @description
     * Generate Invoice and invoice details
     * Triggered when pressing button 'Generate Invoice'
    ************************************************************************************************************* */
    public PageReference generateInvoice() {
        this.processSelection();
        Id batchInstanceId = Database.executeBatch(new GenerateInvoicesBatch(STARTED_FROM, contract.Contract_BU__c, new List<Id> {contract.Id}, new List<Id>(selectedConditions), contract.Contract_BDate__c));
        batchIds = new List<Id> {batchInstanceId};
        batchInProgress = true;
        ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.INFO, String.format(Label.MSG_Job_In_Progress, new String[]{'Generate Invoice', (String)batchInstanceId}));
        ApexPages.addMessage(pageMsg);
        return null;
    }
    
    /**
     * @description
	************************************************************************************************************* */ 
    public PageReference dispatch() {
        List<Id> selectedConditions = new List<Id>();
        if(conditionList !=null && !conditionList.isEmpty()) {
            for(WrapperCondition eachRecord : conditionList){
                if (eachRecord.condition.Condition_Type__c != NULL && eachRecord.selected) {
                    selectedConditions.add(eachRecord.condition.Id);                         
                }
            }
            List<Id> conditions = (selectedConditions != null && selectedConditions.size() > 0) ? selectedConditions : null;
            Id batchInstanceId = Database.executeBatch(new DispatchingBatch(STARTED_FROM , contract.Contract_BU__c, new List<Id> {contract.Id}, conditions, contract.Contract_BDate__c));
            batchIds = new List<Id> {batchInstanceId};
            batchInProgress = true;
            ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.INFO, String.format(Label.MSG_Job_In_Progress, new String[]{'Dispatching', (String)batchInstanceId}));
            ApexPages.addMessage(pageMsg);
        }
        return null;
    }

    /**
     * @description
	************************************************************************************************************* */
    public PageReference generateGRCRate() {
        Boolean lastActiveContract = [SELECT Last_Active_Contract__c FROM Contract__c WHERE Id = :contract.Id].Last_Active_Contract__c;
		Id batchInstanceId = Database.executeBatch(new GenerateGRCRatesBatch(STARTED_FROM, contract.Contract_BU__c, new List<Id> {contract.Id}, Date.today(), lastActiveContract));
        batchIds = new List<Id> {batchInstanceId};
        batchInProgress = true;
        ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.INFO, String.format(Label.MSG_Job_In_Progress, new String[]{'Generate GRC Rate', (String)batchInstanceId}));
        ApexPages.addMessage(pageMsg);
        return null;
    }
    
    /**
     * @description gets the first page of contract conditions
	************************************************************************************************************* */
    public void first() {
        this.processSelection();
        updateConditionsMap();
        setCtrlr.first();
        refreshConditionList();
        restoreConditionList();
    }
    
    
    /**
     * @description gets the next page of contract conditions
	************************************************************************************************************* */
    public void next() {
        this.processSelection();
        updateConditionsMap();
        setCtrlr.next();
        refreshConditionList();
        restoreConditionList();
    }
    
    /**
     * @description gets the previous page of contract conditions
	************************************************************************************************************* */
    public void previous() {
        this.processSelection();
        updateConditionsMap();
        setCtrlr.previous();
        refreshConditionList();
        restoreConditionList();
    }
    
    /**
     * @description gets the last page of contract conditions
	************************************************************************************************************* */
    public void last() {
        this.processSelection();
        updateConditionsMap();
        setCtrlr.last();
        refreshConditionList();
        restoreConditionList();
    }
    
    /**
     * @author hawly
     * @description
     * clears the list of conditions to be diplayed on the grid
     * and re-fills it from the standard controller
     * called in visualforce page after clicking first, next, previous, last in conditions table
     * called after inserting new conditions
	************************************************************************************************************* */
    public void refreshConditionList() {
        
        conditionList.clear();
        integer index = 0;
        for (Contract_Discount__c item : (List<Contract_Discount__c>) setCtrlr.getRecords()) {
            boolean selected = false;
            boolean isNew = false;
           /// try {
                WrapperCondition condition = new WrapperCondition(item.clone(true, true, false, false), item.name, selected, isNew, index++);
                conditionList.add(condition);
           /// } catch (Exception ex) {
           ///     ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'This contract contains invalid conditions that are not dispalyed in the conditions table'); 
           ///     ApexPages.addMessage(pageMsg);
           /// }
        }
        if (/*conditionsMap.isEmpty() &&*/ !conditionList.isEmpty()) {
            updateConditionsMap();
        }
        if (!setCtrlr.getHasPrevious() && conditionList.isEmpty()) {
            insertDiscountRow();
        }
    }
    
   	/**
   	 * description restore the state of edited conditions
	*/
    private void restoreConditionList() {
        
        for (WrapperCondition item : conditionList) {
            if (selectedConditions.contains(item.condition.Id)) {
                item.selected = true;
            }
            if (conditionsMap.keySet().contains(item.condition.id)) {
                item.condition = conditionsMap.get(item.condition.Id);
            }
        }
        
        if (!setCtrlr.getHasPrevious()) {
            for (integer i = conditionsToInsert.size() ; i > 0; i--) {
                boolean selected = false;
                boolean isNew = true;
                Integer index = 0;
                WrapperCondition wcondition = new WrapperCondition(conditionsToInsert[i-1], conditionsToInsert[i-1].Name, selected, isNew, index);
                if (conditionList.isEmpty()) {
                    conditionList.add(wcondition);
                } else {
                    for (WrapperCondition item : conditionList) {
                        item.index++;
                    }
                    conditionList.add(0, wcondition);
                }  
            }
        }
    }
    
    /**
     * 
	************************************************************************************************************* */
    private void updateConditionsMap() {
        for (WrapperCondition item : conditionList) {
            if (!item.isNew) conditionsMap.put(item.condition.id, item.condition);
        }
    }
    
    /**
     * @author hawly
     * @description  
     * inserts a new row with default values to the list of conditions to be dispayed on the grid and 
     * adds a new Contract_Discount__c sObject to the list of conditions to insert
	************************************************************************************************************* */
    public PageReference insertDiscountRow() {
        
        Contract_Discount__c condition = new Contract_Discount__c();
        condition.contract__c = contract.Id;
        condition.CurrencyIsoCode = contract.CurrencyIsoCode;
        condition.Product_Scope__c = contract.Supplier_Nego_Scope__c;
        condition.BU_Scope__c = contract.Contract_BU__c;
        condition.Disc_BDate__c =  contract.Contract_BDate__c;
        condition.Disc_EDate__c =  contract.Contract_EDate__c;
        Schema.DescribeFieldResult fieldNegoTypeResult = Contract_Discount__c.Nego_Discount_Type__c.getDescribe();
        Schema.DescribeFieldResult fieldPeriodResult = Contract_Discount__c.Invoice_period__c.getDescribe();
        Schema.DescribeFieldResult fieldIsPrenegoEnvResult = Contract_Discount__c.Is_Prenego_Envelop__c.getDescribe();
        Schema.DescribeFieldResult fieldSlabCalcMethodResult = Contract_Discount__c.Slab_Calc_Method__c.getDescribe();
        Schema.DescribeFieldResult fieldSlabCalcMethodToOriginResult = Contract_Discount__c.Slab_calc_Method_TO_Origin__c.getDescribe();
        condition.Nego_Discount_Type__c = NegoptimHelper.defaultPicklistValue(fieldNegoTypeResult);
        condition.Invoice_period__c = NegoptimHelper.defaultPicklistValue(fieldPeriodResult);
        condition.Is_Prenego_Envelop__c = (Boolean)fieldIsPrenegoEnvResult.getDefaultValue();
        condition.Slab_Calc_Method__c = NegoptimHelper.defaultPicklistValue(fieldSlabCalcMethodResult);
        condition.Slab_calc_Method_TO_Origin__c = NegoptimHelper.defaultPicklistValue(fieldSlabCalcMethodToOriginResult);
        boolean selected = false;
        boolean isNew = true;
        Integer index = 0;
        WrapperCondition wcondition = new WrapperCondition(condition, condition.Name, selected, isNew, index);
        if (conditionList.isEmpty()) {
            conditionList.add(wcondition);
        } else {
            for (WrapperCondition item : conditionList) {
                item.index++;
            }
            conditionList.add(0, wcondition);
        }
        if (conditionsToInsert.isEmpty()) {
            conditionsToInsert.add(condition);
        } else {
            conditionsToInsert.add(0, condition);
        }
        return null;
    }
    
    /**
     * @author hawly
     * @description 
     * checks if all requeried fields are filled, and if a field is missing 
     * on a specific row nothing is inserted and a error message is showed on the page
     * otherwise, all new conditions are inserted to the database and all existing conditions are updated
	************************************************************************************************************* */
    public PageReference saveConditions() {
        
        String[] conditionCreateFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Is_Prenego_Envelop__c'),
            NegoptimHelper.normalizeAPIName('Contract__c'), NegoptimHelper.normalizeAPIName('Product_Scope__c'),
            NegoptimHelper.normalizeAPIName('BU_Scope__c'), NegoptimHelper.normalizeAPIName('Disc_BDate__c'),
            NegoptimHelper.normalizeAPIName('Disc_EDate__c'), NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'),
            NegoptimHelper.normalizeAPIName('Invoice_period__c'), NegoptimHelper.normalizeAPIName('commercial_reference__c'),
            NegoptimHelper.normalizeAPIName('Minimum_Guarantee__c'), NegoptimHelper.normalizeAPIName('Value_amt__c'),
            NegoptimHelper.normalizeAPIName('Invoicing_plan_generated__c'), NegoptimHelper.normalizeAPIName('Valid__c'),
            NegoptimHelper.normalizeAPIName('Condition_Type__c'), NegoptimHelper.normalizeAPIName('Value_per__c')};
                
        String[] conditionUpdateFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Is_Prenego_Envelop__c'),
            NegoptimHelper.normalizeAPIName('Product_Scope__c'),NegoptimHelper.normalizeAPIName('BU_Scope__c'), 
            NegoptimHelper.normalizeAPIName('Disc_BDate__c'),NegoptimHelper.normalizeAPIName('Disc_EDate__c'),
            NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'), NegoptimHelper.normalizeAPIName('Invoice_period__c'),
            NegoptimHelper.normalizeAPIName('commercial_reference__c'), NegoptimHelper.normalizeAPIName('Minimum_Guarantee__c'),
            NegoptimHelper.normalizeAPIName('Value_amt__c'), NegoptimHelper.normalizeAPIName('Invoicing_plan_generated__c'),
            NegoptimHelper.normalizeAPIName('Valid__c'), NegoptimHelper.normalizeAPIName('Condition_Type__c'),
            NegoptimHelper.normalizeAPIName('Value_per__c')};
                
        if (!NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionCreateFields)) {
            return null;
        } 
        if (!NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionUpdateFields)) {
            return null;
        }
        boolean flag = false;
        for (WrapperCondition item : conditionList) {
            if (!(item.condition.Nego_Discount_Type__c != null && item.condition.Product_Scope__c != null && item.condition.Condition_Type__c != null 
                  && item.condition.BU_Scope__c != null && item.condition.Disc_BDate__c != null && item.condition.Disc_EDate__c != null)) { 
                ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Empty required fields in row: ' + (conditionList.indexOf(item) + 1)); 
                ApexPages.addMessage(pageMsg);
                flag = true;
            }
        }
        
        if(!flag) {
            List<Contract_Discount__c> conditionsToUpdate = new List<Contract_Discount__c>();
           /* for (WrapperCondition item : conditionList) {
                if (!item.isNew) {
                    conditionsToUpdate.add(item.condition);
                }
            }*/
            for (Id key : conditionsMap.keySet()) {
                conditionsToUpdate.add(conditionsMap.get(key));
            }
            try {
                if (conditionsToInsert.size() != 0) {
                    insert conditionsToInsert;
                    noOfRecords += conditionsToInsert.size();
                    ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, conditionsToInsert.size() + ' new conditions successfully inserted'); 
                    ApexPages.addMessage(pageMsg);
                }
                
                if (conditionstoUpdate.size() != 0) {
                    update conditionstoUpdate;
                }
                conditionsToInsert.clear();
                conditionsMap.clear();
                setCtrlr = null;
                refreshConditionList();
            } catch (DMLException e) {
                ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getDmlMessage(0));
                ApexPages.addMessage(pageMsg);
                return null;
            }
        }
        return null;
    }
    
     /**
     * @author hawly
     * @description
     * deletes selected conditions from the database
	************************************************************************************************************* */
    public PageReference deleteConditions() {
        this.processSelection();
        if (selectedConditions.isEmpty()) {
            ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'No conditions are selected to delete'); 
            ApexPages.addMessage(pageMsg);
            return null;
        }
        for (Id key : conditionsMap.keySet()) {
            if (selectedConditions.contains(key)) {
                conditionsToDelete.add(conditionsMap.get(key));
            }
        }
        
        try {
            if (checkDeletibility(Contract_Discount__c.SObjectType)) {
            delete conditionsToDelete;
            ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, conditionsToDelete.size() + ' rows successfully deleted'); 
            ApexPages.addMessage(pageMsg);
            noOfRecords -= conditionsToDelete.size();
            conditionsToDelete.clear();
            selectedConditions.clear();
            }
        } catch (DMLException ex ) {
            ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()); 
            ApexPages.addMessage(pageMsg);
        }
        
        setCtrlr = null;
		refreshConditionList(); 
        return null;
    }
    
    /**
     * @author hawly
     * description
     * resets the list of conditions to display
     * clears the list of conditions to insert
     * clears the list of conditions to delete
	************************************************************************************************************* */
  /*  public PageReference cancelConditions() {   
        setCtrlr = null;
		refreshConditionList(); 
        return null;
    }   */
    
    /**
     * @author hawly
     * @description sets all conditions to selected if the select all conditions checkbox is selected
     * and vise versa
	************************************************************************************************************* */
   /* public void selectAllConditions() {
        
        for (WrapperCondition item : conditionList) {
            item.selected = selectAllConditions;
            if (!item.isNew) {
                if (selectAllConditions) {
                    selectedConditions.add(item.condition.Id);
                } else {
                    selectedConditions.remove(item.condition.Id);
                }
            }
        }
    }*/
    
    
     /**
     * @author hawly
     * @description 
     * 
	************************************************************************************************************* */
    public void processSelection() {
       /* selectAllConditions = false;
        wCurrentCondition = conditionList[currentConditionIndex];
        if (!wCurrentCondition.isNew) {
            if (wCurrentCondition.selected) {
                selectedConditions.add(wCurrentCondition.condition.Id);
            } else {
                selectedConditions.remove(wCurrentCondition.condition.Id);
			}
            if (selectedConditions.contains(wCurrentCondition.condition.Id)) {
                selectedConditions.remove(wCurrentCondition.condition.Id);
            } else {
                selectedConditions.add(wCurrentCondition.condition.Id);
            }
        }*/
        for (WrapperCondition wc : conditionList) {
            if (wc.selected) {
                selectedConditions.add(wc.condition.Id);
            } else if (selectedConditions.contains(wc.condition.Id)) {
                selectedConditions.remove(wc.condition.Id);
            }
            
        }
    }
    
    /**
     * 
	*/
    public void adjustConditionMode() {
        wCurrentCondition = conditionList.get(currentConditionIndex);
        try {
            Pol_Com_Condition__c pcc = [SELECT Condition_Mode__c, Is_Conditional__c
                                        FROM Pol_Com_Condition__c
                                        WHERE Id = :wCurrentCondition.condition.Condition_type__c];
            wCurrentCondition.conditionMode = pcc.Condition_Mode__c;
            wCurrentCondition.isConditional = pcc.Is_Conditional__c;
        } catch (QueryException ex){
           // when the user enters a invalid value by hand
        }
            
    }
    
	/**
	 * @description
	************************************************************************************************************* */   
    public PageReference showPopup() {
        
        if(popupNegoscope) {
            loadContracts(selectedSupplierId, selectedNegoYear);
        }
        if (popupSlabs) {
            wCurrentCondition = ConditionList[currentConditionIndex];
            slabs = new Integer[SlabManager.slabsCount];
            for(Integer ndx = 1; ndx <= SlabManager.slabsCount; ndx++) {
                slabs.add(ndx);
            }
        }
        if(popupChildNegoscope) {
            wChildNegoscopeList.clear();
            Id sup_nego = contract.Supplier_Nego_Scope__c;
            boolean selected;
            wCurrentCondition = ConditionList[currentConditionIndex];
            Sup_Sup_negoscope__c temp = [SELECT Name, Is_All__c, Is_All_Brands__c, Is_All_HE__c
                                         FROM Sup_Sup_Negoscope__c
                                         WHERE Id = :contract.Supplier_Nego_Scope__c];
            selected = wCurrentCondition.condition.product_scope__c == temp.Id;
            wChildNegoscopeList.add(new WrapperNegoscope(temp, 0, selected));
            for (Sup_Sup_Negoscope__c item :[SELECT Name, Is_All__c, Is_All_Brands__c, Is_All_HE__c
                                             FROM Sup_Sup_Negoscope__c
                                             WHERE Parent_Nego_Scope__c = :contract.Supplier_Nego_Scope__c]) {
            	selected = wCurrentCondition.condition.product_scope__c == item.Id;
            	wChildNegoscopeList.add(new WrapperNegoscope(item, wChildNegoscopeList.size(), selected));
			}
        }
        if (popupChildNegoscopeBrands) {
            BrandList = [SELECT Name, Sup_Scope_Brand__r.Brand_Owner__r.Name
                        FROM Sup_NS_Brand__c
                        WHERE Sup_Sup_Negoscope__c = :wChildNegoscopeList[currentNegoscopeIndex].negoscope.id];
        }
        if (popupChildNegoscopeHEs) {
            HEList = [SELECT Structure_Element__r.Name, Choice__c
                     FROM Supplier_NS_HE__c
                     WHERE Sup_Sup_negoscope__c = :wChildNegoscopeList[currentNegoscopeIndex].negoscope.id];
        }
        if (popupChildNegoscopePGs) {
            PGList = [SELECT Name, sup_PG__r.Name, Section__c, Department__c, Status__c
                     FROM Sup_NS_PG__c
                     WHERE Sup_Sup_negoscope__c = :wChildNegoscopeList[currentNegoscopeIndex].negoscope.id];
        }
        
        return null;
    }
    
    /**
     * @description
	************************************************************************************************************* */
    public PageReference hidePopup() {
        
        if(popupNegoscope) {
            selectedContractId = processContractSelection();
            popupNegoscope = false;
            PageReference pageRef = Page.ConditionManager;
            pageRef.getParameters().put('id', selectedContractId);
            pageRef.setRedirect(true);
            return pageRef;
        }
        
        if (popupSlabs) {
            wCurrentCondition.sortSlabs('ASC'); // default is ascending
            popupSlabs = false;
        }
        
        if (popupChildNegoscope) {
            for (WrapperNegoscope item : wChildNegoscopeList) {
                if (item.selected) {
                    wCurrentCondition.condition.Product_Scope__c = item.negoscope.Id;
                    wCurrentCondition.productScopeName = item.negoscope.name;
                }
            }
            popupChildNegoscope = false;
        }
        
        return null;
    }
    
    /**
     * 
     * @description removes any popup on the screen without changes
	************************************************************************************************************* */
    public PageReference cancelPopup() {
        
        if (popupNegoscope) {
            popupNegoscope = false;
        } 
        if (popupSlabs) {
            popupSlabs = false;
        }
        if(popupChildNegoscope) {
            popupChildNegoscope = false;
        }
        if (popupChildNegoscopeBrands || popupChildNegoscopeHEs || popupChildNegoscopePGs) {
            popupChildNegoscopeBrands = false;
            popupChildNegoscopeHEs = false;
            popupChildNegoscopePGs = false;
            popupChildNegoscope = true;
        }
        
        return null;
    }
    
    /**
     * @description Get List of years to be displayed in Select list on page
    ************************************************************************************************************* */ 
    public List<SelectOption> getListYears() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer year = Date.today().year() - 2 ; year <= Date.today().year() + 3 ; year++) {
            options.add(new SelectOption(String.valueOf(year), String.valueOf(year)));
        }
        return options;
    }
    
    /**
     * @description used to find suppliers by autocomplete
	************************************************************************************************************* */
    @RemoteAction
    global static String findSupplier(String searchTerm) {
        String searchTermLike = '%' + searchTerm + '%';
        List<Sup_Supplier__c> listSuppliers = [SELECT Id, Name, Code__c FROM Sup_Supplier__c
                                               WHERE Name LIKE :searchTermLike
                                               OR Code__c LIKE :searchTermLike];
        return JSON.serialize(listSuppliers);
    }

    /**
     * @description loadContracts
    ************************************************************************************************************* */ 
    private void loadContracts(Id supplierId, Integer year) {
        wContractNegoscopeList = new List<WrapperContractNegoscope>();
        for(Sup_sup_NegoScope__c item : [SELECT Id, Name, NS_Code__c, Supplier__c, Supplier__r.CurrencyIsoCode, Supplier__r.Country_origin__c,
                                         (SELECT id, Name, Contract_Numbder__c, Status__c, Contract_BDate__c, Contract_EDate__c
                                          FROM Contracts1__r
                                          WHERE CALENDAR_YEAR(Contract_BDate__c) = :year
                                          ORDER BY Contract_BDate__c DESC)
                                         FROM Sup_sup_NegoScope__c
                                         WHERE supplier__c = :supplierId
                                         AND Parent_Nego_Scope__c = null
                                         ORDER BY Name ASC])
        {
            if(!item.Contracts1__r.isEmpty()) {
                for(Contract__c contract : item.Contracts1__r) {
                    WrapperContractNegoscope wContractNegoscope = new WrapperContractNegoscope(item, contract);
                    wContractNegoscopeList.add(wContractNegoscope);
                }
            }
            else {
                // case of no contract exist => to create default one
                WrapperContractNegoscope wContractNegoscope = new WrapperContractNegoscope(item);
                wContractNegoscopeList.add(wContractNegoscope);
            }
        }
        
        if (wContractNegoscopeList.size() > 0) {
            wContractNegoscopeList.get(0).selected = true;
        }
    }
    
    /**
     * @description
     * processContractSelection
	************************************************************************************************************* */ 
    private Id processContractSelection() {
        Id contractId;
        for(WrapperContractNegoscope item : wContractNegoscopeList) {
            if(item.selected) {
                if(item.contract.Id == null) {
                    // create new contract
                    item.contract.Name = 'Contract ' + selectedNegoYear + ' - ' + item.negoscope.Name; // not used, generated via trigger
                    item.contract.Contract_BDate__c = Date.newInstance(selectedNegoYear, 1, 1);
                    item.contract.Contract_EDate__c = Date.newInstance(selectedNegoYear, 12, 31);
                    try {
                        String[] contractFields = new String [] {'Name','CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Contract_Numbder__c'),
                            NegoptimHelper.normalizeAPIName('Supplier_Nego_Scope__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                            NegoptimHelper.normalizeAPIName('Contract_EDate__c'), NegoptimHelper.normalizeAPIName('Contract_BDate__c'),
                            NegoptimHelper.normalizeAPIName('Contract_BU__c')};
                                if(checkCreatibility(Contract__c.SObjectType, contractFields)) {
                                    insert item.contract;
                                }
                    } catch(DMLException e) {
                        ApexPages.Message pageMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getDmlMessage(0)); 
                        ApexPages.addMessage(pageMsg);
                        return null;
                    }
                }
                contractId = item.contract.Id;
                break;
            }
        }
        return contractId;
    }  

    /* class WrapperContractNegoscope */
    public class WrapperContractNegoscope {
        
        public Sup_sup_NegoScope__c negoscope {get;set;}
        public Contract__c contract {get;set;}
        public Boolean selected {get;set;}
        
        public WrapperContractNegoscope(Sup_sup_NegoScope__c ns) {
            
            this.negoscope = ns;
            this.contract = new Contract__c(Supplier__c = ns.Supplier__c, Supplier_Nego_Scope__c = ns.Id,
                                            CurrencyIsoCode = ns.Supplier__r.CurrencyIsoCode, Contract_BU__c = ns.Supplier__r.Country_origin__c,
                                            Contract_Type__c ='Contract');
        }
        public WrapperContractNegoscope(Sup_sup_NegoScope__c ns, Contract__c c) {
            
            this.negoscope = ns;
            this.contract = c;
        }
    }
    
    /**
     * @description
     * @author hawly
     ************************************************************************************************************* */ 
    public class WrapperCondition {
        
        public Contract_Discount__c condition {get;set;}
        public String name {get; set;}
        public Boolean selected {get;set;}
        public Boolean isNew {get; set;}
        public Integer index {get; set;}
        public boolean isConditional {get; set;}
        public boolean enableDistribute {
            get {
                return this.condition.Value_amt__c != 0 && this.condition.Value_amt__c != null && enableAmount;
            }
        }
        public boolean enableAmount{
            get {
                if (conditionMode != null) {
                return this.conditionMode.contains('U') || this.conditionMode.contains('F');
                } else {
                    return false;
                }
            }
        }
        public String productScopeName {get; set;}
        public String conditionMode {get; set;}
        
        public WrapperCondition(Contract_Discount__c condition, String name, Boolean selected, Boolean isNew, integer index) {
            
            this.condition = condition;
            this.name = name;
            this.selected = selected;
            this.isNew = isNew;
            this.index = index;
            this.productScopeName = condition.Product_Scope__r.name;
            if (productScopeName == '' || productScopeName == null) {
                List<Sup_Sup_Negoscope__c> nsList = [SELECT Name FROM Sup_Sup_Negoscope__c WHERE id = :condition.Product_Scope__c];
                if (nsList.isEmpty()) {
                    productScopeName = condition.contract__r.Supplier_Nego_Scope__c;
                } else {
                    productScopeName = [SELECT Name FROM Sup_Sup_Negoscope__c WHERE id = :condition.Product_Scope__c].name;               
                }
            }
            this.conditionMode = this.condition.Condition_type__r.Condition_Mode__c;
            isConditional = this.condition.Condition_type__r.Is_Conditional__c;
        }
        
        /** 
         * @description Rearrenge slabs in ASC or DESC order         
         * @param orderDirection: can be null or ASC or DESC 
        */
        public void sortSlabs(String orderDirection) {
            SlabManager.sortSlab(this.condition, orderDirection == 'ASC');
        }
    }
    
    /**
     * @author hawly
     * @description
	*/
    public class WrapperNegoscope{
        public Integer index {get;set;}
        public Sup_sup_NegoScope__c negoscope {get;set;}
        public String brandsLabel {
            get {
                if (negoscope.Is_All_Brands__c ) {
                    return 'All Brands';
                } else {
                    return 'Selected Brands';
                }
            }
        }
        public String HELabel {
            get {
                if (negoscope.Is_All_HE__c) {
                    return 'Root Included';
                } else {
                    return 'View HE scope';
                }
            }
        }
        public String pgLabel {
            get {
                if (negoscope.Is_All__c) {
                    return 'All Products';
                } else {
                    return 'View PGs';
                }
            }
        }
        public boolean selected {get; set;}
        
        public WrapperNegoscope(Sup_sup_NegoScope__c negoscope, Integer index, boolean selected) {
            this.negoscope = negoscope;
            this.index = index;
            this.selected = selected;
        }
    }   
}