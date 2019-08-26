/**
 * Controller for the page Duplicate Contract
 * */
public with sharing class Nego360_Duplicate_Contract_Controller extends NegoptimBaseController {
    
    public String contractId;
    public Contract__c contractObj { get; set; }
    public Contract__c duplicatedContract { get; set; }
    public List<Contract_Discount__c> duplicatedConditions { get; set; }
    public Boolean isDuplicate { get; set; }
    public Boolean invalidId { get; set; }
    public Boolean controlOnBULevel { get; set; }
    public List<String> errors {get; set;}
    
    // Constructor
    public Nego360_Duplicate_Contract_Controller(ApexPages.StandardController stdController) {
        invalidId = false;
        isDuplicate = false;
        controlOnBULevel = false;
        errors = new List<String>();
         // contract to duplicate
        contractId = ApexPages.currentPage().getParameters().get('id');
        // Ensure contract exist.
        List<Contract__c> contractList = [SELECT Id, Name, Contract_BDate__c,Contract_EDate__c, Contract_BU__c, Tactite_reconduction__c, Status__c,
                                          D_N__c, Supplier__r.Name, Supplier__r.Status__c, Supplier__r.Code__c, Contract_Numbder__c, Supplier_Nego_Scope__c, 
                                          Supplier_Nego_Scope__r.NS_Code__c, Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__r.Status__c,
                                          Contract_BU__r.Status__c, Contract_Type__c, Linked_Contract_Group__c,
                                          (SELECT Name, Disc_BDate__c, Disc_EDate__c, Contract__c, Nego_Discount_Type__c,
                                           Value_per__c, Value_amt__c, Product_Scope__r.Name, BU_Scope__r.Name,
                                           BU_Scope__r.Status__c, Product_Scope__r.Status__c, Condition_Type__r.Name, 
                                           is_duplicable__c
                                           FROM Contract_Discounts__r)
                                          FROM Contract__c
                                          WHERE Id = :contractId];
       
        if(contractList == null || contractList.size() == 0) {
            invalidId = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSG_Invalid_Contract_Id));
        }
        else {
            contractObj = contractList.get(0);
            if(contractObj.Contract_Type__c != 'Contract') {
                errors.add(Label.MSG_Should_Be_Contract_Type);
            }
            if(contractObj.Supplier__r.Status__c != 'Active') {
                errors.add(Label.MSG_Inactive_supplier);
            }
            if(contractObj.Supplier_Nego_Scope__r.Status__c != 'Active') {
                errors.add(Label.MSG_Inactive_NegoScope);
            }
            if(contractObj.Contract_BU__r.Status__c != 'Open') {
                errors.add(Label.MSG_BU_Not_Open);
            }
            if(contractObj.Status__c != 'Signed' && contractObj.Status__c != 'Balanced') {
                errors.add(Label.MSG_Contract_Not_Signed);
            }
            /**if(contractObj.D_N__c != 'N') {
                errors.add(Label.MSG_Contract_Not_A_Negotiation);
            }**/
            if(contractObj.Tactite_reconduction__c == false) {
                errors.add(Label.MSG_Unchecked_Tacite_Reconduction);
            }
            /*if(contractObj.Linked_Contract_Group__c != Null) {
                errors.add(Label.MSG_Contract_origin_equal_to_AMC_cannot_be_duplicated);
            }*/
            if (errors.size() == 0) {
            	// Load Settings
            	try {
            		NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
            		controlOnBULevel = settings.datesOverlapControlBU;
            	} catch (Exception e) {
            		errors.add(e.getMessage());
            	}
                // Duplicated Contract
                duplicatedContract = contractObj.clone(true, true, false, false);
                if (duplicatedContract.D_N__c == 'N') {
		        	duplicatedContract.D_N__c = 'D';
		        } else if (duplicatedContract.D_N__c == 'D') {
		        	duplicatedContract.D_N__c = 'N';
		        } else {
		        	duplicatedContract.D_N__c =  Null;
		        }
                duplicatedContract.Contract_BDate__c = duplicatedContract.Contract_EDate__c.addDays(1);
                duplicatedContract.Contract_EDate__c = NegoptimHelper.getLastDayOfMonth(duplicatedContract.Contract_BDate__c.Year(), 12);
                checkContract();
            }
            else {
                for(String error : errors) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, error));
                }
            }
        }
    }
    // Check if contract is already duplicated for specified dates or return possibility to duplicate
    public PageReference checkContract() {
        isDuplicate = false;
        Boolean contractExistOnSamePeriod = false;
        // Check if another contracts exist for the selected dates
        for(Contract__c item :  [SELECT Id, Name, Parent_Contract__c, Contract_BU__c
                                 FROM Contract__c
                                 WHERE /*Parent_Contract__c = :contractId AND*/ Contract_Type__c = 'Contract'
                                 AND Supplier__c = :duplicatedContract.Supplier__c
                                 AND Supplier_Nego_Scope__c = :duplicatedContract.Supplier_Nego_Scope__c
                                 AND ((Contract_BDate__c <= :duplicatedContract.Contract_BDate__c AND Contract_EDate__c >= :duplicatedContract.Contract_BDate__c)
                                      OR (Contract_BDate__c <= :duplicatedContract.Contract_EDate__c AND Contract_EDate__c >= :duplicatedContract.Contract_EDate__c)
                                      OR (Contract_BDate__c >= :duplicatedContract.Contract_BDate__c AND Contract_EDate__c <= :duplicatedContract.Contract_EDate__c))])
        {
            if(item.Parent_Contract__c == contractId) {
                // Another Duplicated Contract exist
                isDuplicate = true && (!controlOnBULevel || controlOnBULevel && item.Contract_BU__c == duplicatedContract.Contract_BU__c);
                break;
            }
            else {
                contractExistOnSamePeriod = true && (!controlOnBULevel || controlOnBULevel && item.Contract_BU__c == duplicatedContract.Contract_BU__c);
                if(contractExistOnSamePeriod) break;
            }
        }
        if(isDuplicate) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_Already_Duplicated));
        }
        else if(contractExistOnSamePeriod) {
            isDuplicate = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_Contract_Exist_Same_Period));
        }
        else {
            isDuplicate = false;
            getDuplicatedConditions(duplicatedContract.Contract_BDate__c, duplicatedContract.Contract_EDate__c);
        }
		return null;
	}
    // Get list of conditions with specified dates
    public PageReference getDuplicatedConditions(Date bDate, Date eDate) {
        duplicatedConditions = new List<Contract_Discount__c>();
        for (Contract_Discount__c condition : contractObj.Contract_Discounts__r) {
            Contract_Discount__c duplicatedCondition;
            if(condition.is_duplicable__c) {
                duplicatedCondition = condition.clone(false, true, true, false);
                duplicatedCondition.Disc_BDate__c = bDate;
                duplicatedCondition.Disc_EDate__c = eDate;
            }
            else {
                duplicatedCondition = new Contract_Discount__c(is_duplicable__c = false, Disc_BDate__c = null, Disc_EDate__c = null);
            }
            /***if(condition.Value_per__c == 0 || condition.Product_Scope__r.Status__c != 'Active' || condition.BU_Scope__r.Status__c != 'Open') {
                ConditionsWrapper.fcond = new Contract_Discount__c();
                ConditionsWrapper.isDuplicate = false;
            } 
            if(condition.Value_per__c == null) {
                // define new object of future condition to show empty rows in output table
                ConditionsWrapper.fcond = new Contract_Discount__c();
                condition.Value_per__c = 0; 
                ConditionsWrapper.isDuplicate = false;
            }***/
            duplicatedConditions.add(duplicatedCondition);
        }
        return null;
    }
    // Button Duplicate Action
    public PageReference submitDuplicate() {
        if(!invalidId) {
            List<Id> contractIdList = new List<Id> {contractId};
            // Invoking DuplicateContractBatch Class
            Id batchInstanceId = Database.executeBatch(new DuplicateContractBatch('Nego360_Duplicate_Contract', contractObj.Contract_BU__c, contractIdList, contractObj.Contract_BDate__c.year(),
                                                                                  duplicatedContract.Contract_BDate__c, duplicatedContract.Contract_EDate__c,
                                                                                  duplicatedContract.D_N__c));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, string.format(Label.MSG_Job_In_Progress, new String[]{'Duplicate Contracts procedure', (String)batchInstanceId})));
            isDuplicate = true;
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,Label.MSG_Invalid_Contract_Id));
        }
        return null;
    }
}