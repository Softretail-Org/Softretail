/**
 * Controller for the page Merge Contract
 * */
public with sharing class Nego360_Merge_Contract_Controller extends NegoptimBaseController {
    
    // List used to push error messages if exists.
    public List<String> errors {get; set;}
    // Selected Contract.
    public Contract__c simulationContract {get; set;}
    // Simulated contract object.
    public Contract__c simContObj {get; set;}
    // Duplicated contract object.
    public Contract__c dupContObj {get; set;}
    public Boolean isMerged {get; set;}
    public List<WrapperCondition> simulationConditionsList {get; set;}
    public List<WrapperCondition> duplicatedConditionsList {get; set;}
    Boolean hasNoParent = false;
    
    public Nego360_Merge_Contract_Controller(ApexPages.StandardController stdController) {
        errors = new List<String>();
        // Get Ids from URL.
        String parentId = ApexPages.currentPage().getParameters().get('pId');
        String countryId = ApexPages.currentPage().getParameters().get('cId');
        String simContractId = ApexPages.currentPage().getParameters().get('Id');
        if(countryId == '' || simContractId == '') {
            errors.add(Label.MSG_Invalid_Parameters);
        } else if(countryId != '' && simContractId != '' && parentId == '') {
        	hasNoParent = true;
        }
        // check if contract exist.
        List<Contract__c> cList = [SELECT Contract_BDate__c, Contract_EDate__c, Contract_Type__c, Status__c, Contract_BU__c,
                                   Parent_Contract__c, Supplier_Nego_Scope__c, Supplier__r.Status__c, Supplier_Nego_Scope__r.Status__c
                                   FROM Contract__c
                                   WHERE Id = :simContractId
                                   AND Parent_Contract__c = :parentId
                                   AND Contract_BU__c = :countryId LIMIT 1];
        if (cList == null || cList.size() == 0) {
            errors.add(Label.MSG_Invalid_Parameters);
        } else {
            simulationContract = cList.get(0);
            if (simulationContract.Status__c == 'Merged') {
                errors.add(Label.Contract_is_Merged);
            } else if (simulationContract.Status__c != 'Published') {
                errors.add(Label.MSG_Status_not_Published);
            }
            if (simulationContract.Supplier__r.Status__c != 'Active') {
                errors.add(Label.MSG_Supplier_status_not_Active);
            }
            if (simulationContract.Supplier_Nego_Scope__r.Status__c != 'Active') {
                errors.add(Label.MSG_NegoScope_status_not_Active);
            }
            if (simulationContract.Contract_Type__c != 'Simulation') {
				errors.add(Label.MSG_Contract_type_not_Simulation_or_already_merged);
			}
        }
        // No Syntax or criteria errors
        if (errors.size() == 0) {
            // Declaration and creation of a map: <key: duplicated contract reference, value: related condition>.
            Map<Id, Contract_Discount__c> dupRefConditionMap = new Map<Id, Contract_Discount__c>();
            // Declaration and creation of a map: <key: simulated contract reference, value: related condition>.
            Map<Id, Contract_Discount__c> simRefConditionMap = new Map<Id,Contract_Discount__c>();            
            // Get corresponding duplicated and simulation contracts.
            List<Contract__c> contracts = loadContracts(simulationContract);
            if(contracts != null && contracts.size() > 0) {
                simulationConditionsList = new List<WrapperCondition>();
                duplicatedConditionsList = new List<WrapperCondition>();
                for (Contract__c c: contracts) {
                    // Specify the duplicated contract, specify the simulation contract.
                    if (c.Contract_Type__c == 'Simulation') {
                        simContObj = c;
                    } else if (c.Contract_Type__c == 'Contract' && c.Status__c == 'Validated' && c.D_N__c == 'D') {
                        dupContObj = c;
                    }
                    // Fill dupRefConditionMap and simRefConditionMap maps.
                    for(Contract_Discount__c condition : c.Contract_Discounts__r) {
                        // check if it's new condition => put id of the condition instead of
                        Id refCondition = condition.Reference_condition__c != null ? condition.Reference_condition__c : condition.Id;
                        if (c.Contract_Type__c == 'Contract') {
                            dupRefConditionMap.put(refCondition, condition);
                        }
                        if (c.Contract_Type__c == 'Simulation') {
                            simRefConditionMap.put(refCondition, condition);
                        }
                    }
                }
                // Check if there is no duplicated contract.
                if (dupContObj == Null) {
                	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_No_duplication_contract_exist));
                }
                for (Id key : simRefConditionMap.keySet()) {
                    WrapperCondition simulationCondition = new WrapperCondition(simRefConditionMap.get(key));	                    
                    if(dupRefConditionMap.containsKey(key)) {
                        // Update condition(s).
                        WrapperCondition duplicatedCondition = new WrapperCondition(dupRefConditionMap.get(key));
                        duplicatedConditionsList.add(duplicatedCondition);
                    } else {
                        // Add condition(s) related to the duplicated contract.
                        WrapperCondition duplicatedCondition = new WrapperCondition();
                        duplicatedConditionsList.add(duplicatedCondition);
                        simulationCondition.isToAdd = true;
                    }
                    simulationConditionsList.add(simulationCondition);
                }
                for (Id key : dupRefConditionMap.keySet()) {
                    // Remove condition(s) related to the duplicated contract.
                    if(!simRefConditionMap.containsKey(key)) {
                        WrapperCondition duplicatedCondition = new WrapperCondition(dupRefConditionMap.get(key));
                        duplicatedCondition.isToRemove = true;
                        duplicatedConditionsList.add(duplicatedCondition);
                    }
                }
            }
        } else {
            for(String error : errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, error));
            }
        }
    }
    // Query execution.
    private List<Contract__c> loadContracts(Contract__c simulationContract) {
        String q = 'SELECT c.Id, c.Name, c.Contract_BDate__c, c.Contract_EDate__c, c.Status__c , c.Contract_Type__c, c.D_N__c,';
        q += ' c.Parent_Contract__c, c.Supplier__c, c.Supplier__r.Name, c.Supplier__r.Status__c, c.Supplier_Nego_Scope__r.Status__c,';
        q += ' (Select Id, Name, Reference_condition__c, BU_Scope__c, Condition_Type__c, Condition_Type__r.Name,';
        q += ' Contract__c, Disc_EDate__c, Status__c, Value_per__c, Value_amt__c, Disc_BDate__c, BU_Scope__r.Name';
        q += ' FROM Contract_Discounts__r WHERE Product_Scope__r.Status__c = \'Active\' AND BU_Scope__r.Status__c = \'Open\')';
        q += ' FROM Contract__c c';
        q += ' WHERE c.Supplier__c = \'' + simulationContract.Supplier__c + '\' AND c.Supplier__r.Status__c = \'Active\' AND c.Supplier_Nego_Scope__r.Status__c = \'Active\'';
        q += ' AND ((c.Contract_Type__c = \'Simulation\' AND c.Status__c = \'Published\') OR';
        q += ' (c.Contract_Type__c = \'Contract\' AND c.Status__c = \'Validated\' AND c.D_N__c = \'D\') OR (c.Contract_Type__c = \'Contract\' AND c.Status__c = \'Signed\' AND c.D_N__c = \'N\'))';
        if (!hasNoParent && simulationContract.Parent_Contract__c != Null) {
        	q += ' AND c.Parent_Contract__c = \'' + simulationContract.Parent_Contract__c + '\'';
        }
        q += ' AND c.Contract_BU__c = \'' + simulationContract.Contract_BU__c + '\'';
        q += ' AND c.Supplier_Nego_Scope__c = \'' + simulationContract.Supplier_Nego_Scope__c + '\'';
        q += ' AND CALENDAR_YEAR(c.Contract_BDate__c) = ' + simulationContract.Contract_BDate__c.year() + '';
        return Database.query(q);
    }
    // Submit merge contracts.
    public PageReference submitMerge() {
        List<Id> parent = simulationContract.Parent_Contract__c != null ? new List<Id>{simulationContract.Parent_Contract__c} : null;
        // Invoking MergeContractBatch Class.
        Id batchInstanceId = Database.executeBatch(new MergeContractBatch('Nego360_Merge_Contract', simulationContract.Contract_BU__c,
                                                                          new List<Id>{simulationContract.Supplier__c},
                                                                          new List<Id>{simulationContract.Id},
                                                                          parent,
                                                                          simulationContract.Contract_BDate__c.year()));
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Contract Merge', (String)batchInstanceId})));
        isMerged = true;
        return null;
    }
    /**
    * Wrapper class for simulated condition to know
    * if it should be added to the duplicated contract or removed from it.
    * */
    public class WrapperCondition {
    	
        public Contract_Discount__c condition {get; set;}
        public boolean isToRemove {get; set;}
        public boolean isToAdd {get; set;}
        
        public WrapperCondition() {
            condition = new Contract_Discount__c();
            isToAdd = this.isToAdd;
        }
        public WrapperCondition(Contract_Discount__c c) {
            condition = c;
            isToRemove = this.isToRemove;
        }
    }
}