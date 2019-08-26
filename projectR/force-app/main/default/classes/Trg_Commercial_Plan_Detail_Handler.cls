/*(A) Update Contract reference/Temp Contract and Update Line_Status__c/Extraction_Status__c [on Before-Insert-Update trigger]
 * Case 1: Check when contract reference is null or start date exception updated or Nego scope updated, get the contract related to the Nego_Scope__c and check if the start date of commercial plan between start and end date of the contract
 * if contract not exist set Temp_Contract_Reference__c by last active contract name
 * Case 2: Management of fields - Update Line_Status__c/Extraction_Status__c
 * if Update on the fields [productx__c(s), contract__c, Contribution_Total__c, ContractBU = Group, ...] => Set Line_Status__c='Updated', Extraction_Status__c='Extract'	
 * if status__c=Deleted => Set Line_Status__c='Deleted' and Extraction_Status__c='Extract' 
 * Case 3: Scan Batch => Set Extraction_Status__c='Extract'
 * 
 *(B) Update Total_Marketing_Events_Justified__c based on update Contribution_Total__c [on AfterInsert-Update-Delete trigger]
 */

public class Trg_Commercial_Plan_Detail_Handler {
    
    static final String GROUP_RECORD_TYPE_NAME_CONST = 'Group';    
    // Action(s) on Before trigger.	
    public static void OnBeforeInsertOrUpdate(List<Commercial_Plan_Detail__c> newCommercialDetails, Map<ID, Commercial_Plan_Detail__c> oldCommercialDetailMap) {
        // (A) Update Contract reference/Temp Contract and Update Line_Status__c/Extraction_Status__c
        updateReferenceContractAndStatus(newCommercialDetails, oldCommercialDetailMap);
    }
    // Action(s) on After trigger.
    public static void OnAfterInsertOrUpdateOrDelete(List<Commercial_Plan_Detail__c> newCommercialDetails, Map<ID, Commercial_Plan_Detail__c> oldCommercialDetailMap) {
        // (B) Update Total_Marketing_Events_Justified__c based on update Contribution_Total__c
        updateTotalMarketingEventsJustified(newCommercialDetails, oldCommercialDetailMap);
    }
    // Update reference contract and status for commercial plan detail
    private static void updateReferenceContractAndStatus(List<Commercial_Plan_Detail__c> newCommercialDetails, Map<ID, Commercial_Plan_Detail__c> oldCommercialDetailMap){
        Set<Id> negoScopeSet = new Set<Id>();
        Set<Id> contractSet = new Set<Id>();
        // Map<Nego Scope Id, List Contract>
        Map<Id, List<Contract__c>> nsContractMap = new Map<Id, List<Contract__c>>();
        // Map<Contract Id, BU>
        Map<Id, Id> contractBUMap = new Map<Id, Id>();
        // Record type name and BU mapping.
        Map<Id, String> recordTypeMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Orga_BU__c.SObjectType);
        for(Commercial_Plan_Detail__c item : newCommercialDetails) {
            // check if commercial plan detail with contract reference null, start date exception or Nego scope updated
            if(item.Nego_Scope__c != null && (item.Contract__c == null || 
                                              (item.Id != null && item.Contract__c != null && item.Agreement_Start_Date__c != oldCommercialDetailMap.get(item.Id).Agreement_Start_Date__c) ||
                                              (item.Id != null && item.Nego_Scope__c != oldCommercialDetailMap.get(item.Id).Nego_Scope__c)))
            {
                negoScopeSet.add(item.Nego_Scope__c);
            }
            if(item.Contract__c != null){
                contractSet.add(item.Contract__c);
            }
        }
        // Get BU related to Contract for check the BU record type 'Group'
        if(contractSet.size() > 0){
            for(Contract__c item : [SELECT Id, Contract_BU__r.RecordTypeId FROM Contract__c WHERE Id IN :contractSet]){
                contractBUMap.put(item.Id, item.Contract_BU__r.RecordTypeId);                                       
            }
        }
        // Get all contract related to Nego Scope
        if(negoScopeSet.size() > 0){
            for(Sup_sup_NegoScope__c item : [SELECT Id, Name,(SELECT Id, Name, Contract_Numbder__c, Supplier_Nego_Scope__c, Contract_BDate__c,
                                                              Contract_EDate__c, Contract_BU__r.RecordTypeId, Last_Active_Contract__c 
                                                              FROM Contracts1__r WHERE Contract_Type__c = 'Contract' 
                                                              ORDER BY Contract_BDate__c DESC) 
                                             FROM Sup_sup_NegoScope__c WHERE Id IN :negoScopeSet]) 
            {
                if(!nsContractMap.containsKey(item.Id)) {
                    nsContractMap.put(item.Id, item.Contracts1__r);
                }
            }
        }
        for(Commercial_Plan_Detail__c item : newCommercialDetails) {
            // Case 1: when contract reference is null or Start Date exception updated or Nego scope updated
            if(item.Nego_Scope__c != null && (item.Contract__c == null || 
                                              (item.Id != null && item.Contract__c != null && item.Agreement_Start_Date__c != oldCommercialDetailMap.get(item.Id).Agreement_Start_Date__c) ||
                                              (item.Id != null && item.Nego_Scope__c != oldCommercialDetailMap.get(item.Id).Nego_Scope__c)))
            {
                if(nsContractMap.containsKey(item.Nego_Scope__c) &&  nsContractMap.get(item.Nego_Scope__c) != null) {
                    List<Contract__c> contracts = nsContractMap.get(item.Nego_Scope__c);
                    Contract__c refContract = null; Contract__c lastActiveContract = null;
                    for(Contract__c contract :contracts){
                        if(contract.Last_Active_Contract__c == true){
                            lastActiveContract = contract;
                        }
                        if(contract.Contract_BDate__c <= item.Agreement_Start_Date__c && contract.Contract_EDate__c >= item.Agreement_Start_Date__c) {
                            // check if linked contract reference not changed
                            refContract = contract;
                            if(item.Contract__c != null && item.Contract__c == refContract.Id){
                                break;
                            }
                            item.Contract__c = contract.Id;
                            item.Action_done__c = Label.MSG_Reference_Contract_Linked_Automatically + ' ' + Datetime.now().format('dd/MM/yyyy');
                            contractBUMap.put(contract.Id, contract.Contract_BU__r.RecordTypeId);
                            break;
                        }
                    }
                    if(item.Id != null && refContract == null && item.Contract__c != null) {
                        item.Contract__c = null;
                        item.Action_done__c = null;
                        item.Temp_Contract_Reference__c = null;
                    }
                    if(refContract == null && lastActiveContract != null) {
                        item.Temp_Contract_Reference__c = lastActiveContract.Contract_Numbder__c +' - '+ lastActiveContract.Name;
                    }
                }
            }
            // Case 2: Management of fields                
            if(String.isNotBlank(item.Temp_Contract_Reference__c) && item.Contract__c != null)
                item.Temp_Contract_Reference__c = null;
            if((item.Id != null && item.Pre_nego_line__c != null && oldCommercialDetailMap.get(item.Id).Pre_nego_line__c == null) && 
               item.Applicable_Rate_Manual__c != null &&
               (item.Statut__c == 'In process of validation' || item.Statut__c == 'Validated')){
                   item.Applicable_Rate_Manual__c = null;
               }
            // Case update line.
            if(item.Id != null && item.Contract__c != null){
                String recordTypeName = recordTypeMap.get(contractBUMap.get(item.Contract__c));
                if(((item.Product_1__c != oldCommercialDetailMap.get(item.Id).Product_1__c) ||
                    (item.Product_2__c != oldCommercialDetailMap.get(item.Id).Product_2__c) ||
                    (item.Product_3__c != oldCommercialDetailMap.get(item.Id).Product_3__c) ||
                    (item.Product_4__c != oldCommercialDetailMap.get(item.Id).Product_4__c) ||
                    (item.Product_5__c != oldCommercialDetailMap.get(item.Id).Product_5__c) ||
                    (item.Product_6__c != oldCommercialDetailMap.get(item.Id).Product_6__c) ||
                    (item.Product_7__c != oldCommercialDetailMap.get(item.Id).Product_7__c) ||
                    (item.Product_8__c != oldCommercialDetailMap.get(item.Id).Product_8__c) ||
                    (item.Product_9__c != oldCommercialDetailMap.get(item.Id).Product_9__c) ||
                    (item.Product_10__c != oldCommercialDetailMap.get(item.Id).Product_10__c) ||
                    (item.Product_11__c != oldCommercialDetailMap.get(item.Id).Product_11__c) ||
                    (item.Product_12__c != oldCommercialDetailMap.get(item.Id).Product_12__c) ||
                    (item.Product_13__c != oldCommercialDetailMap.get(item.Id).Product_13__c) ||
                    (item.Product_14__c != oldCommercialDetailMap.get(item.Id).Product_14__c) ||
                    (item.Product_15__c != oldCommercialDetailMap.get(item.Id).Product_15__c) ||
                    (item.Product_16__c != oldCommercialDetailMap.get(item.Id).Product_16__c) ||
                    (item.Product_17__c != oldCommercialDetailMap.get(item.Id).Product_17__c) ||
                    (item.Product_18__c != oldCommercialDetailMap.get(item.Id).Product_18__c) ||
                    (item.Product_19__c != oldCommercialDetailMap.get(item.Id).Product_19__c) ||
                    (item.Product_20__c != oldCommercialDetailMap.get(item.Id).Product_20__c) ||
                    (item.Product_21__c != oldCommercialDetailMap.get(item.Id).Product_21__c) ||
                    (item.Product_22__c != oldCommercialDetailMap.get(item.Id).Product_22__c) ||
                    (item.Product_23__c != oldCommercialDetailMap.get(item.Id).Product_23__c) ||
                    (item.Product_24__c != oldCommercialDetailMap.get(item.Id).Product_24__c) ||
                    (item.Product_25__c != oldCommercialDetailMap.get(item.Id).Product_25__c) ||
                    (item.Product_26__c != oldCommercialDetailMap.get(item.Id).Product_26__c) ||
                    (item.Product_27__c != oldCommercialDetailMap.get(item.Id).Product_27__c) ||
                    (item.Product_28__c != oldCommercialDetailMap.get(item.Id).Product_28__c) ||
                    (item.Product_29__c != oldCommercialDetailMap.get(item.Id).Product_29__c) ||
                    (item.Product_30__c != oldCommercialDetailMap.get(item.Id).Product_30__c) ||
                    (item.Contract__c != oldCommercialDetailMap.get(item.Id).Contract__c) ||
                    (item.Contribution_Total__c != oldCommercialDetailMap.get(item.Id).Contribution_Total__c)) &&              
                   (recordTypeName == GROUP_RECORD_TYPE_NAME_CONST) &&
                   (item.Line_Status__c == 'New' || item.Line_Status__c == 'Updated') &&
                   (item.Agreement_End_Date__c <= System.Today()) &&
                   (item.Extraction_Status__c == 'Extracted')){
                       if(item.Statut__c == 'Contract Edited' ||  item.Statut__c == 'Contract Sent' || item.Statut__c == 'Contract Signed'){
                           item.Extraction_Status__c = 'Extract';
                           item.Line_Status__c = 'Updated';
                       }
                   }
                // Case when Status is Deleted
                if((recordTypeName == GROUP_RECORD_TYPE_NAME_CONST) &&
                   (item.Line_Status__c == 'New' || item.Line_Status__c == 'Updated') &&
                   (item.Agreement_End_Date__c <= System.Today()) &&
                   (item.Extraction_Status__c == 'Extracted') &&
                   (item.Statut__c == 'Deleted')){
                       item.Extraction_Status__c = 'Extract';
                       item.Line_Status__c = 'Deleted';
                   }
                // Case 3: Scan Batch
                if((item.Agreement_End_Date__c <= System.Today() + 1) &&
                   (item.Extraction_Status__c != 'Extracted') &&
                   (item.Statut__c != 'Deleted') &&
                   (recordTypeName == GROUP_RECORD_TYPE_NAME_CONST)){
                       item.Extraction_Status__c = 'Extract';
                   }
            }
        }
    }
    // Update Total_Marketing_Events_Justified__c based on update Contribution_Total__c
    private static void updateTotalMarketingEventsJustified(List<Commercial_Plan_Detail__c> newCommercialDetails, Map<ID, Commercial_Plan_Detail__c> oldCommercialDetailMap){
        Set<Id> contractSet = new Set<Id>();
        if(newCommercialDetails != null && !newCommercialDetails.isEmpty()){
            for(Commercial_Plan_Detail__c item : newCommercialDetails) {
                if(item.Contract__c != null && ((oldCommercialDetailMap == null && item.Contribution_Total__c != null) || (oldCommercialDetailMap != null && item.Contribution_Total__c != oldCommercialDetailMap.get(item.Id).Contribution_Total__c))){
                    contractSet.add(item.Contract__c);
                }
                // Check if commercial plan detail is updated, update Total marketing events justified for old contract
                if(oldCommercialDetailMap != null && oldCommercialDetailMap.get(item.Id) != null &&
                   item.Contract__c != oldCommercialDetailMap.get(item.Id).Contract__c && oldCommercialDetailMap.get(item.Id).Contract__c != null){
                       contractSet.add(oldCommercialDetailMap.get(item.Id).Contract__c);
                   }
            }
        }
        else if(oldCommercialDetailMap != null && !oldCommercialDetailMap.isEmpty()){
            // Check if commercial plan detail is deleted, update Total marketing events justified for old contract
            for(Commercial_Plan_Detail__c item : oldCommercialDetailMap.values()) {
                if(item.Contract__c != null){
                    contractSet.add(item.Contract__c);
                }
            }
        }
        // Get Total marketing events justified to Contract
        Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
        if(contractSet.size() > 0){
            contractMap = new Map<Id, Contract__c>([SELECT Id, Total_Marketing_Events_Justified__c
                                                    FROM Contract__c
                                                    WHERE Id IN :contractSet]);
        }
        if(contractMap.size() > 0){
            // Case insert, update or delete commercial plan detail
            Contract__c refContract = null; Contract__c oldContract = null; Commercial_Plan_Detail__c oldItem = null;
            if(newCommercialDetails != null && !newCommercialDetails.isEmpty()){
                for(Commercial_Plan_Detail__c item : newCommercialDetails) {
                    refContract = null; oldContract = null; oldItem = null;
                    // Get old commercial plan detail
                    if(oldCommercialDetailMap != null && oldCommercialDetailMap.get(item.Id) != null){
                        oldItem = oldCommercialDetailMap.get(item.Id);
                    }
                    if(item.Contract__c != null && contractMap.containsKey(item.Contract__c)) {
                        refContract = contractMap.get(item.Contract__c);
                        if(refContract.Total_Marketing_Events_Justified__c == null) refContract.Total_Marketing_Events_Justified__c = 0;
                    }
                    // If insert new commercial plan detail
                    if(oldItem == null && refContract != null){
                        refContract.Total_Marketing_Events_Justified__c += item.Contribution_Total__c;
                    }
                    // If update commercial plan detail
                    if(oldItem != null){
                        if(refContract != null){
                            if(item.Contract__c != oldItem.Contract__c){                            
                                refContract.Total_Marketing_Events_Justified__c += item.Contribution_Total__c;
                            }
                            else if(item.Contribution_Total__c != oldItem.Contribution_Total__c){
                                refContract.Total_Marketing_Events_Justified__c += (item.Contribution_Total__c - oldItem.Contribution_Total__c);
                            }
                        }
                        // Update total justified for old contract
                        if(item.Contract__c != oldItem.Contract__c && oldItem.Contract__c != null){
                            if(contractMap.containsKey(oldItem.Contract__c)) {
                                oldContract = contractMap.get(oldItem.Contract__c);
	                        	if(oldContract.Total_Marketing_Events_Justified__c == null) oldContract.Total_Marketing_Events_Justified__c = 0;
                            	oldContract.Total_Marketing_Events_Justified__c -= oldItem.Contribution_Total__c;
                            }
                        }
                    }
                }
            }
            else if(oldCommercialDetailMap != null && !oldCommercialDetailMap.isEmpty()){
                // Case delete commercial plan detail
                for(Commercial_Plan_Detail__c item : oldCommercialDetailMap.values()) {
                    refContract = null;
                    if(item.Contract__c != null && contractMap.containsKey(item.Contract__c)) {
                        refContract = contractMap.get(item.Contract__c);
                    }
                    // If delete commercial plan detail
                    if(refContract != null){
                    	if(refContract.Total_Marketing_Events_Justified__c == null) refContract.Total_Marketing_Events_Justified__c = 0;
                        refContract.Total_Marketing_Events_Justified__c -= item.Contribution_Total__c;
                    }
                }
            }
            if(contractMap.size() > 0) update contractMap.values();
        }
    }

}