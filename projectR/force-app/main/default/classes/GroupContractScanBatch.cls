/**
* Batchable class used to scan group contracts
**/
global with sharing class GroupContractScanBatch implements Database.Batchable<SObject>, Database.Stateful {

    private NegoptimBatch nb;
    public String query;
    public String originBUCode;
    public static Map<String, string> contractGroupFieldNameLabels;
    public static Map<String, string> contractGroupDetailFieldNameLabels;
    public final Boolean doContractGroupSynchro;
    public final List<String> contractGroupIds;

    /* Constructor. */
    public GroupContractScanBatch(String startedFrom, Boolean doSynchro, List<String> ids, String groupBUCode) {
        this.nb = new NegoptimBatch('GroupContractScanBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.originBUCode = groupBUCode;
        this.doContractGroupSynchro = doSynchro;
        this.contractGroupIds = ids;
        String q = 'SELECT Id, Name, Contract_Number__c, Contract_Year__c, Origin_Supplier_Code__c, Origin_Supplier__c,';
        q += 'Origin_BU__c, Contract_Reference_Number__c, Start_Date__c, End_date__c, Contract_type__c, Negotiated_TO__c,';
        q += 'Header_Integration_Status__c, Last_Integration_Date__c, Action_ToDo__c, Action_done__c, Stock_owner__c, Origin_Stock_owner__c,';
        q += 'Supplier__c, Supplier_NegoScope__c, origin__c, Supplier__r.Id, Supplier__r.Name, Supplier__r.Status__c,';
        q += 'Supplier_NegoScope__r.Id, Supplier_NegoScope__r.Name, Supplier_NegoScope__r.Status__c, Status__c,Temp_Exclusion__c, ';
        q += '(SELECT Id, Name, Contract_List_Group__c, Origin_Disc_Code__c, Origin_Disc_name__c, Percent__c, Amount__c,';
        q += 'Disc_BDate__c, Disc_EDate__c, Last_Integration_date__c, Condition_name__r.Condition_Code__c, ';
        q += 'Condition_name__r.Condition_status__c, Order_Number__c, Origin_Disc_Code2__c, Line_Integration_Status__c, Status__c ';
        q += 'FROM Group_Contract_Details__r WHERE Status__c <> \'Synchronized\' AND Status__c <> \'Synchronized as deleted\' AND Status__c <> \'Deleted\') ';
        q += 'FROM Contract_Group__c ';
        q += 'WHERE (Temp_Exclusion__c = FALSE AND Status__c <> \'Synchronized\' AND Status__c <> \'Synchronized as deleted\' AND Status__c <> \'Deleted\') ';
        if(ids != null && ids.size() > 0) {
            if(String.isNotBlank(ids[0])) {
                q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\') ';
            }
        }
        if(String.isNotBlank(originBUCode)) {
            q += ' AND Origin_BU__c = \'' + originBUCode + '\'';
        }
        q += ' Order By Start_Date__c DESC';
        // Set the final variable.
        this.query = q;
        // push inputs to log
        nb.logParameter('doContractGroupSynchro', this.doContractGroupSynchro);
        nb.logParameter('originBUCode', this.originBUCode);
        nb.logParameter('contractGroupIds', this.contractGroupIds);
        nb.logParameter('query', this.query);
    }
    
    /* Start method implementation.*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        query +=  '' + (Test.isRunningTest()?' LIMIT 1000':'');
        return Database.getQueryLocator(query);
    }
    
    /* Execute method implementation.*/
    public void execute(Database.BatchableContext bc, List<Contract_Group__c> scope) {
        /* 1. Prepare Declaration. */
        // List Of Contract Group Id
        Set<Id> contractGroupIdSet = new Set<Id>();
        Set<Id> supplierIdSet = new Set<Id>();
        Set<Id> NSIdSet = new Set<Id>();
        Set<Decimal> contractYearSet = new Set<Decimal>();
        // List Of Contract reference number
        Set<String> setContractReferenceNumber = new Set<String>();
        // List Of tariff condition code
        Set<String> setOfTarifCode = new Set<String>();
        // List of Origin supplier code
        Set<String> originSupplierCodeSet = new Set<String>();
        // Map<Origin_Supplier_Code__c, Supplier__c DataBase>.
        Map<String, Contract_Group__c> mapOriginSupplierCode = new Map<String, Contract_Group__c>();
        // List of Origin supplier code
        Set<String> originStockOwnerSet = new Set<String>();
        // Map<Origin_Stock_owner__c, Orga_BU__c DataBase>.
        Map<String, Orga_BU__c> originStockOwnerMap = new Map<String, Orga_BU__c>();
        // Map<condition code, Tariff condition>.
        Map<String, Pol_Com_Condition__c> mapTarifCond = new Map<String, Pol_Com_Condition__c>();
        // Map<complex key, List<Contract_Group__c>>. The key is a concatenation of contract year,supplier Id and NegoScope Id.
        Map<String, List<Contract_Group__c>> managementDateMap = new Map<String, List<Contract_Group__c>>();
        List<Contract_Group__c> relatedContracts = new List<Contract_Group__c>();
        // Map<complex key, List<Contract_Group__c>>.
        Map<String, List<Contract_Group__c>> contractReferenceMap = new Map<String, List<Contract_Group__c>>();
        // <Contract_Number__c, Contract_Group__c>.
        Map<String, Contract_Group__c> contractReferenceNumberMap = new Map<String, Contract_Group__c>();
         // List of wrapper contract group        
        List<WrapperContractGroupLine> wContractGroupList = new List<WrapperContractGroupLine>();
        Map<Id, WrapperContractGroupLine> contractGroupMap = new Map<Id, WrapperContractGroupLine>();
         // List of wrapper condition group        
        List<WrapperConditionGroupLine> wConditionGroupList = new List<WrapperConditionGroupLine>();
        // List contract group to update
        List<Contract_Group__c> contractGroups = new List<Contract_Group__c>();
        // List condition group to update
        List<Contract_Group_Detail__c> contractGroupDetails = new List<Contract_Group_Detail__c>();
        // List contract group issues to insert
        List<Contract_Group_Issue__c> contractGroupIssues = new List<Contract_Group_Issue__c>();
        // Describe all fields for Contract_Group__c.
        contractGroupFieldNameLabels = NegoptimHelper.GetMandatoryFieldLabels(Contract_Group__c.SObjectType);
        // Describe all fields for Contract_Group_Detail__c.
        contractGroupDetailFieldNameLabels = NegoptimHelper.GetMandatoryFieldLabels(Contract_Group_Detail__c.SObjectType);
        /* 2. Prepare Load Data. */
        for(Contract_Group__c item : scope) {
            contractGroupIdSet.add(item.Id);
            // Fill all Contract Reference
            if(item.Contract_Reference_Number__c != null) {
                setContractReferenceNumber.add(item.Contract_Reference_Number__c);
            }
            // Fill all origin Supplier code
            if(item.Origin_Supplier_Code__c != null) {
                originSupplierCodeSet.add(item.Origin_Supplier_Code__c);
            }
            // Fill all stock owner code
            if(String.isNotBlank(item.Origin_Stock_owner__c)) {
                originStockOwnerSet.add(item.Origin_Stock_owner__c);
            } else {
                originStockOwnerSet.add(null);
            }
            // Get all Policy Tariff conditions.
            for(Contract_Group_Detail__c contractGroupDetail : item.Group_Contract_Details__r) {
                setOfTarifCode.add(contractGroupDetail.Origin_Disc_Code__c);
            }
        }
        // Get all Policy Tariff conditions.
        for(Pol_Com_Condition__c item : [SELECT Id, Name, Condition_Code__c, Condition_status__c, Nego_Discount_Type__c 
                                         FROM Pol_Com_Condition__c 
                                         WHERE Condition_Code__c IN :setOfTarifCode]) {
                                             mapTarifCond.put(item.Condition_Code__c, item);
                                         }
        // Get all Group Contract related to Contract reference number list       
        for(Contract_Group__c item : [SELECT Id, Contract_Number__c, Contract_Reference_Number__c, Origin_Supplier__c,
                                      Origin_Supplier_Code__c, Supplier__c, Supplier_NegoScope__c,
                                      Contract_type__c, Contract_Year__c, Start_Date__c, Status__c,
                                      Supplier__r.Id, Supplier__r.Name, Supplier__r.Status__c,
                                      Supplier_NegoScope__r.Id, Supplier_NegoScope__r.Name, Supplier_NegoScope__r.Status__c
                                      FROM Contract_Group__c
                                      WHERE (Contract_Number__c IN :setContractReferenceNumber
                                             OR (Origin_Supplier_Code__c IN :originSupplierCodeSet)
                                             OR (Contract_Reference_Number__c IN :setContractReferenceNumber AND Supplier__c != NULL AND Supplier_NegoScope__c != NULL))])
        {
            // Fill multi contract group with same year, Supplier, NS(Active) and linked to reference contract
            if((setContractReferenceNumber.contains(item.Contract_Number__c) || (setContractReferenceNumber.contains(item.Contract_Reference_Number__c) && item.Supplier__c != null && item.Supplier_NegoScope__c != null)) && 
               item.Supplier_NegoScope__r.Status__c == 'Active' &&
               item.Contract_type__c != null && (item.Contract_type__c == 'Prorogation' || item.Contract_type__c == 'Contract')){
                   if(item.Supplier__c != null && item.Supplier_NegoScope__c != null  && item.Contract_Year__c != null) {
                       String key = '';
                       if(setContractReferenceNumber.contains(item.Contract_Number__c)){
                           key = item.Contract_Number__c +''+ item.Supplier__c +''+ item.Supplier_NegoScope__c +''+ String.valueOf(item.Contract_Year__c);
                       }
                       else{
                           key = item.Contract_Reference_Number__c +''+ item.Supplier__c +''+ item.Supplier_NegoScope__c +''+ String.valueOf(item.Contract_Year__c);
                       }
                       if(contractReferenceMap.containsKey(key)){
                           contractReferenceMap.get(key).add(item);
                       }
                       else {
                           contractReferenceMap.put(key, new List<Contract_Group__c>{item});
                       }
                   }
               }
            // Fill Origin Supplier Code already linked to Supplier__c
            if(originSupplierCodeSet.contains(item.Origin_Supplier_Code__c)){
                if(item.Supplier__c != NULL && item.Supplier__r.Status__c == 'Active' &&
                   !mapOriginSupplierCode.containsKey(item.Origin_Supplier_Code__c)){
                       mapOriginSupplierCode.put(item.Origin_Supplier_Code__c, item);
                   }
            }
            if(setContractReferenceNumber.contains(item.Contract_Number__c)){
                // Fill all Contract Group Related to Contract Reference
                contractReferenceNumberMap.put(item.Contract_Number__c, item);
            }
        }
        
        // Get all stock owner
        if(!originStockOwnerSet.isEmpty()) {
            // Single Instance of BusinessUnitHelper
            BusinessUnitHelper buHelper = BusinessUnitHelper.getInstance(null, null);
            originStockOwnerMap = buHelper.getBUByExtIds(originStockOwnerSet, 'Warehouse');
        }
        
        /* 3. Prepare Scan Process. */
        /* Delete all error entries */
        // check security on delete contract group issue
        if(NegoptimHelper.checkDeletibility(Contract_Group_Issue__c.SObjectType)){
            List<Contract_Group_Issue__c> listGroupIssues = new List<Contract_Group_Issue__c>([SELECT Id FROM Contract_Group_Issue__c
                                                                                               WHERE Contract_group__c IN :contractGroupIdSet]);        
            if(listGroupIssues != null && listGroupIssues.size() > 0 ) {
                delete listGroupIssues;
            }
        }
        /* Loop into Contract Group */
        for (Contract_Group__c item : scope) {
            WrapperContractGroupLine wContractLine = new WrapperContractGroupLine(item);
            if(wContractLine.isValidLine){
                // INTEGRITY CONTROL: a- Check Mandatory fields
                wContractLine.CheckMandatoryFields();
                if(!wContractLine.scanIsValid) {
                    // Error
                }
                // get stock owner
                if(originStockOwnerMap.containsKey(item.Origin_Stock_owner__c)) {
                    wContractLine.refStockOwner = originStockOwnerMap.get(item.Origin_Stock_owner__c);
                }
                // Scan contract group
                wContractLine.scanContractGroup(mapOriginSupplierCode, contractReferenceNumberMap, contractReferenceMap); 
            }
            // Loop Into Group Contract Details
            for(Contract_Group_Detail__c condition : item.Group_Contract_Details__r) {
                WrapperConditionGroupLine wConditionLine = new WrapperConditionGroupLine(condition, wContractLine);
                // INTEGRITY CONTROL: a- Check Mandatory fields
                wConditionLine.CheckMandatoryFields();
                if(!wConditionLine.scanIsValid) {
                    // Error
                }
                // Scan condiion group
                wConditionLine.scanConditionGroup(mapTarifCond);
                // Fill Contract Group Detail Scan Results
                if(!wConditionLine.scanIsValid) {
                    wConditionLine.contractGroupDetail.Status__c = 'Rejected';
                }
                else{
                    wConditionLine.contractGroupDetail.Status__c = 'Validated';
                }
                wContractLine.actionToDoMessage += wConditionLine.actionToDoMessage;
                wContractLine.actionDoneMessage += wConditionLine.actionDoneMessage;
                wConditionLine.contractGroupDetail.Last_Scan_Date__c = System.now();
                wConditionGroupList.add(wConditionLine);
                wContractLine.wConditionLines.add(wConditionLine);
            }
            // Fill Contract Group Scan Results
            if(wContractLine.isValidLine){
                if(!wContractLine.scanIsValid) {
                    wContractLine.contractGroup.Status__c = 'Rejected';
                }
                else{
                    wContractLine.contractGroup.Status__c = 'Validated';
                }
                wContractLine.contractGroup.Last_Scan_Date__c = System.now();
            }
            wContractLine.contractGroup.Action_ToDo__c = wContractLine.actionToDoMessage;
            wContractLine.contractGroup.Action_done__c = wContractLine.actionDoneMessage;
            wContractGroupList.add(wContractLine);
            // Fill List Supplier
            if(wContractLine.contractGroup.Supplier__c != null && !supplierIdSet.contains(wContractLine.contractGroup.Supplier__c)){
                supplierIdSet.add(wContractLine.contractGroup.Supplier__c);
            }
            // Fill List NS
            if(wContractLine.contractGroup.Supplier_NegoScope__c != null && !NSIdSet.contains(wContractLine.contractGroup.Supplier_NegoScope__c)){
                NSIdSet.add(wContractLine.contractGroup.Supplier_NegoScope__c);
            }
            // Fill List Contract Year
            if(wContractLine.contractGroup.Contract_Year__c != null && !contractYearSet.contains(wContractLine.contractGroup.Contract_Year__c)){
                contractYearSet.add(wContractLine.contractGroup.Contract_Year__c);
            }
            // Fill Contract Group Map
            contractGroupMap.put(wContractLine.contractGroup.Id, wContractLine);
        }
        // Dates Management Process
        List<Contract_Group__c> contractList = [SELECT Id, Supplier__c, Supplier_NegoScope__c, Contract_type__c,
                                                Contract_Year__c, Start_Date__c, End_Date__c, Status__c, Action_done__c,
                                                (SELECT Id, Disc_EDate__c FROM Group_Contract_Details__r)
                                                FROM Contract_Group__c
                                                WHERE (Contract_type__c = 'Contract' OR Contract_type__c = 'Prorogation') AND
                                                ((Supplier__c IN :supplierIdSet AND Supplier_NegoScope__c IN :NSIdSet AND Contract_Year__c IN :contractYearSet
                                                  AND Temp_Exclusion__c = FALSE AND Status__c <> 'Synchronized as deleted' AND Status__c <> 'Deleted')
                                                 OR (Id IN :contractGroupMap.keySet()))
                                                Order By Start_Date__c DESC];
        for(Contract_Group__c item : contractList){
            String key = '';
            if(contractGroupMap.containsKey(item.Id)){
                WrapperContractGroupLine wContractLine = contractGroupMap.get(item.Id);
                if((wContractLine.contractGroup.Contract_type__c == 'Contract' || wContractLine.contractGroup.Contract_type__c == 'Prorogation') && 
                   wContractLine.contractGroup.Contract_Year__c != null && wContractLine.contractGroup.Supplier__c != null && wContractLine.contractGroup.Supplier_NegoScope__c != null) {
                       key = wContractLine.contractGroup.Contract_Year__c +''+ wContractLine.contractGroup.Supplier__c +''+ wContractLine.contractGroup.Supplier_NegoScope__c;
                   }
            }
            else if(item.Contract_Year__c != null && item.Supplier__c != null && item.Supplier_NegoScope__c != null) {
                key = item.Contract_Year__c +''+ item.Supplier__c +''+ item.Supplier_NegoScope__c;
            }
            if(String.isBlank(key)) continue;
            // Check if for the same year, supplier and NegoScope have one prorogation and multi negotiation contracts.
            if(managementDateMap.containsKey(key)) {
                List<Contract_Group__c> contracts = managementDateMap.get(key);
                Integer count = contracts.size();
                Contract_Group__c lastContractGroup = contracts[count-1];
                if(item.Contract_type__c == 'Contract' && lastContractGroup.Contract_type__c == 'Prorogation' && item.Start_Date__c == lastContractGroup.Start_Date__c){
                    contracts.add(count-1, item);
                }
                else{
                    contracts.add(item);
                }
                managementDateMap.put(key, contracts);
            }
            else{
                List<Contract_Group__c> contracts = new List<Contract_Group__c>{item};
                    managementDateMap.put(key, contracts);
            }
        }
        /* Dates management Process: */
        // If (end date) of the previous contract is different to (begin date -1) of the next contract =>
        // update (end date) of the previous contract to (begin date -1) of the next contract
        if(managementDateMap != null && managementDateMap.size() > 0) {
            for(String key : managementDateMap.keySet()) {
                List<Contract_Group__c> contracts = managementDateMap.get(key);
                if(contracts != null && contracts.size() > 1) {
                    for(Integer i = 0; i <= contracts.size() - 2; i++){
                        Contract_Group__c lastContract = contracts[i], contract = contracts[i+1];                        
                        if(lastContract.Start_date__c != null && contract.End_Date__c != lastContract.Start_date__c.addDays(-1)) {
                            if(contractGroupMap.containsKey(contract.Id)){
                                WrapperContractGroupLine wContractLine = contractGroupMap.get(contract.Id);
                                if(lastContract.Start_date__c.year() == lastContract.Start_date__c.addDays(-1).year()){
                                    wContractLine.contractGroup.End_Date__c = lastContract.Start_date__c.addDays(-1);
                                    // Compare dates 
                                    if(wContractLine.scanIsValid && wContractLine.contractGroup.Start_Date__c > wContractLine.contractGroup.End_date__c){                                   
                                        wContractLine.contractGroup.Status__c = 'Rejected';
                                    }
                                    // Update conditions End date
                                    for(WrapperConditionGroupLine wConditionLine :wContractLine.wConditionLines){
                                        wConditionLine.contractGroupDetail.Disc_EDate__c = wContractLine.contractGroup.End_Date__c;
                                    }
                                }
                                else{
                                    wContractLine.contractGroup.Status__c = 'Deleted';
                                }
                                wContractLine.contractGroup.Action_done__c += Label.MSG_MsgOverlapDates + '\n';
                            }
                            else{
                                if(lastContract.Start_date__c.year() == lastContract.Start_date__c.addDays(-1).year()){
                                    contract.End_Date__c = lastContract.Start_date__c.addDays(-1);
                                    // Compare dates 
                                    if(contract.Start_Date__c > contract.End_date__c){                                   
                                        contract.Status__c = 'Rejected';
                                    }
                                    // Update conditions End date
                                    for(Contract_Group_Detail__c condition : contract.Group_Contract_Details__r){
                                        condition.Disc_EDate__c = contract.End_Date__c;
                                    }
                                }
                                else{
                                    contract.Status__c = 'Deleted';
                                }
                                contract.Action_done__c = Label.MSG_MsgOverlapDates + '\n';
                                relatedContracts.add(contract);
                            }
                        }
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            String[] contractGroupUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Supplier_NegoScope__c'),
                NegoptimHelper.normalizeAPIName('Action_ToDo__c'), NegoptimHelper.normalizeAPIName('Action_done__c'),
                NegoptimHelper.normalizeAPIName('Last_Scan_Date__c'), NegoptimHelper.normalizeAPIName('End_Date__c'),
                NegoptimHelper.normalizeAPIName('Stock_Owner__c')};
            
            String[] conditionUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Condition_name__c'), NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'),
                NegoptimHelper.normalizeAPIName('Last_Scan_Date__c'), NegoptimHelper.normalizeAPIName('Disc_EDate__c')};
            
            String[] contractIssueCreateFields = new String[] { NegoptimHelper.normalizeAPIName('Contract_group__c'),
                NegoptimHelper.normalizeAPIName('Condition_line__c'), NegoptimHelper.normalizeAPIName('Issue_Type__c'),
                NegoptimHelper.normalizeAPIName('Reject_Cause__c'), NegoptimHelper.normalizeAPIName('Reject_Detail__c')};

            if(NegoptimHelper.checkUpdatibility(Contract_Group__c.SObjectType, contractGroupUpdateFields) &&
               NegoptimHelper.checkUpdatibility(Contract_Group_Detail__c.SObjectType, conditionUpdateFields) &&
               NegoptimHelper.checkCreatibility(Contract_Group_Issue__c.SObjectType, contractIssueCreateFields))
            {
                for (WrapperContractGroupLine item : wContractGroupList) {
                    contractGroups.add(item.contractGroup);
                    // Get Internal issues
                    if(item.contractGroupIssues.size() > 0)
                        contractGroupIssues.addAll(item.contractGroupIssues);
                }
                // update contract group
                if(contractGroups != NULL && contractGroups.size() > 0) {
                    List<Database.SaveResult> results = Database.update(contractGroups, false);
                }
                // update related contract group
                if(relatedContracts != NULL && relatedContracts.size() > 0) {
                    List<Database.SaveResult> results = Database.update(relatedContracts, false);
                }
                // update contract group detail            
                for (WrapperConditionGroupLine item : wConditionGroupList) {                
                    contractGroupDetails.add(item.contractGroupDetail);
                }
                if(contractGroupDetails != NULL && contractGroupDetails.size() > 0) {
                    List<Database.SaveResult> results = Database.update(contractGroupDetails, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        if (!result.isSuccess()){
                            String errorMessage = '';
                            Contract_Group_Detail__c contractGroupDetail = contractGroupDetails.get(i);                            
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors){
                                errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            Contract_Group_Issue__c cgIssue = new Contract_Group_Issue__c(Contract_group__c = contractGroupDetail.Contract_List_Group__c, 
                                                                                          Condition_line__c = contractGroupDetail.Id, Issue_Type__c = 'ERR', 
                                                                                          Reject_Cause__c = 'Other', Reject_Detail__c = errorMessage);
                            contractGroupIssues.add(cgIssue);
                        }
                    }
                }
                // insert error generated
                if(contractGroupIssues != null && contractGroupIssues.size() > 0) {
                    List<Database.SaveResult> results = Database.insert(contractGroupIssues, false);
                    nb.logResults(results, contractGroupIssues);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            // Roll everything back in case of error.
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        if(doContractGroupSynchro) {
            Database.executeBatch(new GroupContractSynchroBatch('GroupContractScanBatch', doContractGroupSynchro, contractGroupIds, originBUCode));            
        }
        // Get the Job.        
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper Class for contract Group Line */
    public class WrapperContractGroupLine {
        public Contract_Group__c contractGroup {get; set;}
        public List<Contract_Group_Issue__c> contractGroupIssues {get; set;}
        public List<WrapperConditionGroupLine> wConditionLines {get; set;}
        public Boolean scanIsValid {get; set;}
        public String errorDescMessage {get; set;}
        public String actionToDoMessage {get; set;}
        public String actionDoneMessage {get; set;}
        public Orga_BU__c refStockOwner {get; set;}
        
        public WrapperContractGroupLine(Contract_Group__c contract) {
            contractGroup = contract;
            contractGroupIssues = new List<Contract_Group_Issue__c>();
            wConditionLines = new List<WrapperConditionGroupLine>();
            scanIsValid = true;
            errorDescMessage = '';
            actionToDoMessage = '';
            actionDoneMessage = '';
        }
        public Boolean isValidLine {
            get {
                return contractGroup.Temp_Exclusion__c == false && contractGroup.Status__c != 'Synchronized' && 
                    contractGroup.Status__c != 'Synchronized as deleted' && contractGroup.Status__c != 'Deleted';
            }
            set;
        }
        // scan contract group
        public void scanContractGroup(Map<String, Contract_Group__c> mapOriginSupplierCode, Map<String, Contract_Group__c> contractReferenceNumberMap, Map<String, List<Contract_Group__c>> contractReferenceMap) {
            // Check Scan with current date
            if(contractGroup.Last_Integration_Date__c != null ) {
                if(contractGroup.Last_Integration_Date__c.date() != System.Now().date()) {
                    this.actionToDoMessage += Label.MSG_Contract_last_integration_date_control + '\n';
                    this.scanIsValid = false;
                }
            }
            // Compare dates
            if(contractGroup.End_date__c != null && contractGroup.Start_Date__c > contractGroup.End_date__c){
                Contract_Group_Issue__c cgIssue = new Contract_Group_Issue__c(Contract_group__c = contractGroup.Id, Issue_Type__c = 'ERR', Reject_Cause__c = 'Wrong format date', Reject_Detail__c = Label.MSG_MsgDateCompare);
                contractGroupIssues.add(cgIssue);
                this.scanIsValid = false;
            }
            if(contractGroup.Negotiated_TO__c == NULL) {
                String rejectedDetailTo = contractGroupFieldNameLabels.get('Negotiated_TO__c') +' is empty \n';
                Contract_Group_Issue__c cgIssue = new Contract_Group_Issue__c(Contract_group__c = contractGroup.Id, Issue_Type__c = 'WAr', Reject_Cause__c = 'Other', Reject_Detail__c = rejectedDetailTo);
                contractGroupIssues.add(cgIssue);
            }
            // Check if Origin_Supplier_Code__c was already linked.
            Contract_Group__c supContractLinked = NULL; Boolean isSupplierLinked = False;
            if(contractGroup.Origin_Supplier_Code__c != NULL && contractGroup.Supplier__c == NULL &&
               mapOriginSupplierCode.containsKey(contractGroup.Origin_Supplier_Code__c)){
                   supContractLinked = mapOriginSupplierCode.get(contractGroup.Origin_Supplier_Code__c);
               }
            // Check if Supplier or NegoScope is missing            
            if(contractGroup.Supplier__c == NULL || contractGroup.Supplier_NegoScope__c == NULL) {
                // Check if contract reference exist   
                if(!String.isBlank(contractGroup.Contract_Reference_Number__c)) {
                    if(!contractReferenceNumberMap.containsKey(contractGroup.Contract_Reference_Number__c)) {
                        this.actionToDoMessage += Label.MSG_MsgRefContNotExist + '\n';
                        if(supContractLinked != NULL){
                            contractGroup.Supplier__c = supContractLinked.Supplier__c;
                            this.actionDoneMessage += string.format(Label.MSG_SupplierLinked, new String[]{ supContractLinked.Supplier__r.Name }) + '\n';
                        }
                        if(contractGroup.Supplier__c == NULL) {
                            this.actionToDoMessage += Label.MSG_MsgSupplier + '\n';
                        }
                        if(contractGroup.Supplier_NegoScope__c == NULL) {
                            this.actionToDoMessage += Label.MSG_MsgNegoScope + '\n';
                        }
                    }
                    else{
                        Contract_Group__c contractGroupRef = contractReferenceNumberMap.get(contractGroup.Contract_Reference_Number__c);
                        if(contractGroupRef.Supplier__c == NULL || contractGroupRef.Supplier_NegoScope__c == NULL) {
                            this.actionToDoMessage += Label.MSG_Reference_Contract_Not_Linked + '\n';
                            if(contractGroup.Supplier__c == NULL && supContractLinked != NULL){
                                contractGroup.Supplier__c = supContractLinked.Supplier__c;
                                this.actionDoneMessage += string.format(Label.MSG_SupplierLinked, new String[]{ supContractLinked.Supplier__r.Name }) + '\n';
                                isSupplierLinked = True;
                            }
                            if(contractGroup.Supplier__c == NULL) {
                                this.actionToDoMessage += Label.MSG_MsgSupplier + '\n';
                            }
                            if(contractGroup.Supplier_NegoScope__c == NULL) {
                                this.actionToDoMessage += Label.MSG_MsgNegoScope + '\n';
                            }
                        }
                        if(contractGroup.Supplier__c == NULL){
                            if(contractGroup.Origin_Supplier_Code__c != NULL && contractGroupRef.Origin_Supplier_Code__c != NULL && contractGroup.Origin_Supplier_Code__c != contractGroupRef.Origin_Supplier_Code__c) {
                                this.actionToDoMessage += Label.MSG_MsgRefContDiffSupp + '\n';                                   
                                if(supContractLinked != NULL){
                                    contractGroup.Supplier__c = supContractLinked.Supplier__c;
                                    this.actionDoneMessage += string.format(Label.MSG_SupplierLinked, new String[]{ supContractLinked.Supplier__r.Name }) + '\n';
                                    isSupplierLinked = true;
                                }
                                else {
                                    this.scanIsValid = false;
                                }
                                if(contractGroup.Supplier__c == NULL) {
                                    this.actionToDoMessage += Label.MSG_MsgSupplier + '\n';
                                }
                            }
                            else{
                                if(contractGroupRef.Supplier__c != NULL && contractGroupRef.Supplier__r.Status__c == 'Active') {
                                    contractGroup.Supplier__c = contractGroupRef.Supplier__c;                                          
                                    // Fill Origin Supplier Code linked to new Supplier__c
                                    if(contractGroup.Origin_Supplier_Code__c != NULL &&
                                       !mapOriginSupplierCode.containsKey(contractGroup.Origin_Supplier_Code__c)){
                                           mapOriginSupplierCode.put(contractGroup.Origin_Supplier_Code__c, contractGroupRef);
                                       }
                                    this.actionDoneMessage += string.format(Label.MSG_SupplierLinked, new String[]{contractGroupRef.Supplier__r.Name}) + '\n';
                                }
                                else{
                                    this.scanIsValid = false;
                                    if(contractGroupRef.Supplier__c != NULL && contractGroupRef.Supplier__r.Status__c != 'Active') { 
                                        this.actionToDoMessage += Label.MSG_MsgRefContSuppInactive + '\n' + Label.MSG_MsgRefContSuppReactive;
                                    }
                                }
                            }
                        }
                        if(contractGroup.Supplier__c != null && !isSupplierLinked){
                            if(contractGroupRef.Supplier_NegoScope__c != null && contractGroup.Supplier_NegoScope__c == null &&
                               contractGroupRef.Supplier_NegoScope__r.Status__c == 'Active') {
                                   contractGroup.Supplier_NegoScope__c = contractGroupRef.Supplier_NegoScope__c;
                                   // Check multi contract group with same year, Supplier, NS and linked to reference contract
                                   String key = '';
                                   if(contractGroup.Contract_Year__c != null && contractGroup.Contract_type__c != null) {
                                       key = contractGroup.Contract_Reference_Number__c +''+ contractGroup.Supplier__c +''+ contractGroup.Supplier_NegoScope__c +''+ String.valueOf(contractGroup.Contract_Year__c);
                                       if(contractReferenceMap.containsKey(key)){
                                           List<Contract_Group__c> contractGroupRefList = contractReferenceMap.get(key);
                                           for(Contract_Group__c contractGRef :contractGroupRefList){
                                               if((contractGRef.Contract_type__c == 'Prorogation' && contractGroup.Contract_type__c == 'Prorogation') ||
                                                  (contractGRef.Contract_type__c == 'Contract' && contractGroup.Contract_type__c == 'Contract') ||
                                                  (contractGRef.Contract_type__c == 'Contract' && contractGroup.Contract_type__c == 'Prorogation')){
                                                      this.actionToDoMessage += string.format(Label.MSG_Contract_Already_Exist_For_NS, new String[]{contractGRef.Supplier_NegoScope__r.Name}) + '\n' + Label.MSG_MsgNegoScope + '\n';
                                                      contractGroup.Supplier_NegoScope__c = null;
                                                      this.scanIsValid = false;
                                                      break;
                                                  }
                                           }
                                       }
                                   }
                                   if(contractGroup.Supplier_NegoScope__c != null) {
                                       if(String.isNotBlank(key) && (contractGroup.Contract_type__c == 'Prorogation' || contractGroup.Contract_type__c == 'Contract')){
                                           if(contractReferenceMap.containsKey(key)){
                                               contractReferenceMap.get(key).add(contractGroup);
                                           }
                                           else{
                                               contractReferenceMap.put(key, new List<Contract_Group__c> {contractGroup});
                                           }
                                       }
                                       this.actionDoneMessage += string.format(Label.MSG_NegoLinked, new String[]{contractGroupRef.Supplier_NegoScope__r.Name}) + '\n';   
                                   }
                               }
                            else{
                                this.scanIsValid = false;
                                if(contractGroupRef.Supplier_NegoScope__c != null && contractGroup.Supplier_NegoScope__c == null &&  contractGroupRef.Supplier_NegoScope__r.Status__c != 'Active') {
                                    this.actionToDoMessage += Label.MSG_MsgRefContNsInactive + '\n' + Label.MSG_MsgRefContNsReactive + '\n';
                                }
                            }
                        }
                    }
                }
                else{
                    // If reference contract number is empty
                    if(supContractLinked != null){
                        contractGroup.Supplier__c = supContractLinked.Supplier__c;
                        this.actionDoneMessage += string.format(Label.MSG_SupplierLinked, new String[]{supContractLinked.Supplier__r.Name}) + '\n';
                    }
                    if(contractGroup.Supplier__c == null) {
                        this.actionToDoMessage += Label.MSG_MsgSupplier + '\n';
                    }
                    if(contractGroup.Supplier_NegoScope__c == null) {
                        this.actionToDoMessage += Label.MSG_MsgNegoScope + '\n';
                    }
                }
            }
            if(contractGroup.Supplier__c == null || contractGroup.Supplier_NegoScope__c == null) {
                this.scanIsValid = false;
            }
            // check stock owner
            if(this.contractGroup.Stock_owner__c == null) {
                if(this.refStockOwner == null) {
                    this.scanIsValid = false;
                    this.actionToDoMessage += Label.MSG_Stock_Owner_Not_Found + '\n';
                } else {
                    this.contractGroup.Stock_Owner__c = this.refStockOwner.Id;
                }
            }
        }
        // Check Mandatory Fields
        public void CheckMandatoryFields() {
            // Check missing fields
            if(contractGroup.Name == NULL || contractGroup.Contract_Number__c == NULL || contractGroup.Origin_Supplier_Code__c == NULL || 
               contractGroup.Origin_Supplier__c == NULL  || contractGroup.Contract_type__c == NULL ||  contractGroup.Start_Date__c == NULL ||
               contractGroup.Header_Integration_Status__c == NULL || contractGroup.Last_Integration_Date__c == NULL || contractGroup.Contract_Year__c == NULL
               || contractGroup.End_date__c == NULL) {
                   if(contractGroup.Name == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Name') + '\n';              
                   if(contractGroup.Contract_Number__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Contract_Number__c') + '\n';
                   if(contractGroup.Origin_Supplier_Code__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Origin_Supplier_Code__c') + '\n';
                   if(contractGroup.Origin_Supplier__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Origin_Supplier__c') + '\n';
                   if(contractGroup.Contract_type__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Contract_type__c') + '\n';
                   if(contractGroup.Start_Date__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Start_Date__c') + '\n';
                   if(contractGroup.Header_Integration_Status__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Header_Integration_Status__c') + '\n';
                   if(contractGroup.Last_Integration_Date__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Last_Integration_Date__c') + '\n';
                   if(contractGroup.Contract_Year__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('Contract_Year__c') + '\n';
                   if(contractGroup.End_date__c == NULL) errorDescMessage += contractGroupFieldNameLabels.get('End_date__c') + '\n';
                   Contract_Group_Issue__c cgIssue = new Contract_Group_Issue__c(Contract_group__c = contractGroup.Id, Issue_Type__c = 'ERR', Reject_Cause__c = 'Missing mandatory fields', Reject_Detail__c = Label.LBL_Missing_mandatory_fields + '\n' + errorDescMessage);
                   contractGroupIssues.add(cgIssue);
                   this.scanIsValid = false;
               }
        }
    }
    
    /* Wrapper Class for Condition Group Line */
    public class WrapperConditionGroupLine {
        public Contract_Group_Detail__c contractGroupDetail {get; set;}
        public WrapperContractGroupLine wContractLine {get; set;}
        public Boolean scanIsValid {get; set;}
        public String errorDescMessage {get; set;}
        public String actionToDoMessage {get; set;}
        public String actionDoneMessage {get; set;}
        public WrapperConditionGroupLine(Contract_Group_Detail__c condition, WrapperContractGroupLine wContract) {
            contractGroupDetail = condition;
            wContractLine = wContract;
            scanIsValid = true;
            errorDescMessage = '';
            actionToDoMessage = '';
            actionDoneMessage = '';
        }
        // scan condition group
        public void scanConditionGroup(Map<String, Pol_Com_Condition__c> mapTarifCond) 
        {
            // Update the contract condition (end date) of the contract accordingly
            if(wContractLine.contractGroup.End_Date__c != null){
                contractGroupDetail.Disc_EDate__c = wContractLine.contractGroup.End_Date__c;
            }
            // Check scan with current date
            if(contractGroupDetail.Last_Integration_Date__c != NULL) {
                if(contractGroupDetail.Last_Integration_Date__c.date() != System.Now().date()) {
                    this.actionToDoMessage += string.format(Label.MSG_MsgTestGroupContract, new List<String>{contractGroupDetail.Name}) + '\n';
                    this.scanIsValid = false;
                }
            }
            // Check if amount/percent are missing  
            if((contractGroupDetail.Percent__c == NULL || contractGroupDetail.Percent__c == 0) && (contractGroupDetail.Amount__c == NULL || contractGroupDetail.Amount__c == 0)) {
                Contract_Group_Issue__c cgIssue = new Contract_Group_Issue__c(Contract_group__c = wContractLine.contractGroup.Id, Condition_line__c = contractGroupDetail.Id, Issue_Type__c = 'WAr', Reject_Cause__c = 'Other', Reject_Detail__c = Label.MSG_MsgAmountEmpty);
                wContractLine.contractGroupIssues.add(cgIssue);
            }
            if(contractGroupDetail.Condition_name__c == NULL) {
                // If conditon is empty
                if(contractGroupDetail.Origin_Disc_Code__c != NULL) {
                    // conditon code  exist
                    if(mapTarifCond.get(contractGroupDetail.Origin_Disc_Code__c) != null) {
                        if(mapTarifCond.get(contractGroupDetail.Origin_Disc_Code__c).Condition_status__c != 'Open') { 
                            // condition closed
                            this.actionToDoMessage += Label.MSG_MsgRefConditionclosed +' '+ contractGroupDetail.Name + '\n' + Label.MSG_MsgRefConditionMap + '\n';
                            this.scanIsValid = false;
                        }
                        else{
                            // condition not closed
                            this.actionDoneMessage += Label.MSG_ConditionLinked + ' ' + contractGroupDetail.Name + '\n';
                            contractGroupDetail.Condition_name__c = mapTarifCond.get(contractGroupDetail.Origin_Disc_Code__c).Id;
                            contractGroupDetail.Nego_Discount_Type__c = mapTarifCond.get(contractGroupDetail.Origin_Disc_Code__c).Nego_Discount_Type__c;
                        }
                    }
                    else{
                        // code condition exist but no valid
                        this.actionToDoMessage += Label.MSG_MsgRefConditionNotExist +' '+ contractGroupDetail.Name + '\n' + Label.MSG_MsgRefConditionMap + '\n';
                        this.scanIsValid = false;
                    }
                }
                else{
                    // conditon code doesnt exist
                    this.actionToDoMessage += Label.MSG_MsgRefConditionNotExist +' '+ contractGroupDetail.Name + '\n' + Label.MSG_MsgRefConditionMap + '\n';
                    this.scanIsValid = false;
                }
            }
        }
        // Check Mandatory Fields
        public void CheckMandatoryFields() {
            // Check missing fields                
            if(contractGroupDetail.Contract_List_Group__c == NULL || contractGroupDetail.Origin_Disc_Code__c == NULL || contractGroupDetail.Origin_Disc_name__c == NULL || 
               contractGroupDetail.Disc_BDate__c == NULL  || contractGroupDetail.Order_Number__c == NULL ||  contractGroupDetail.Origin_Disc_Code2__c == NULL ||
               contractGroupDetail.Line_Integration_Status__c == NULL || contractGroupDetail.Last_Integration_date__c == NULL
               || contractGroupDetail.Disc_EDate__c == NULL) {
                   if(contractGroupDetail.Contract_List_Group__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Contract_List_Group__c') + '\n';
                   if(contractGroupDetail.Origin_Disc_Code__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Origin_Disc_Code__c') + '\n';
                   if(contractGroupDetail.Origin_Disc_name__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Origin_Disc_name__c') + '\n';
                   if(contractGroupDetail.Disc_BDate__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Disc_BDate__c') + '\n';
                   if(contractGroupDetail.Order_Number__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Order_Number__c') + '\n';
                   if(contractGroupDetail.Origin_Disc_Code2__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Origin_Disc_Code2__c') + '\n';
                   if(contractGroupDetail.Line_Integration_Status__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Line_Integration_Status__c') + '\n';
                   if(contractGroupDetail.Last_Integration_Date__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Last_Integration_Date__c') + '\n';
                   if(contractGroupDetail.Disc_EDate__c == NULL) errorDescMessage += contractGroupDetailFieldNameLabels.get('Disc_EDate__c') + '\n';
                   Contract_Group_Issue__c cgIssue = new Contract_Group_Issue__c(Contract_group__c = wContractLine.contractGroup.Id, Condition_line__c = contractGroupDetail.Id, Issue_Type__c = 'ERR', Reject_Cause__c = 'Missing mandatory fields', Reject_Detail__c = Label.LBL_Missing_mandatory_fields + '\n' + errorDescMessage);
                   wContractLine.contractGroupIssues.add(cgIssue);
                   this.scanIsValid = false;
               }
        }
    }
}