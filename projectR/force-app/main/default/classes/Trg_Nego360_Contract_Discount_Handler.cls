public class Trg_Nego360_Contract_Discount_Handler {
    
    public static void OnBeforeInsertOrUpdate(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        assignBaseTOs(nConditions);
        reachProgressiveSlab(nConditions);
        setFields(nConditions, oConditionMap);
    }
    
    public static void OnBeforeUpdate(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        assignmentAndNSControl(nConditions, oConditionMap);
    }
    
    public static void OnBeforeInsert(List<Contract_Discount__c> nConditions) {
        assignContractFieldsToCondition(nConditions);
    }
    
    public static void OnAfterUpdate(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        // Delete non-printed invoices if Valid__c become unchecked
        cleanUpInvoices(nConditions, oConditionMap);
    }
    /*
	 * Assign Base To on contract level when the scope respects the current update.
     * @param List<Contract_Discount__c>, Map<Id, Contract_Discount__c> oContractMap.
     * On Before Insert Or Before Update.
     **/
    private static void assignBaseTOs(List<Contract_Discount__c> nConditions) {
    	Map<Id, List<Contract_Discount__c>> conditionsWithModifiedScope;
    	// Push only conditions with modified Scope to the Map to fetch their contracts.
        conditionsWithModifiedScope = new Map<Id, List<Contract_Discount__c>>();
        for (Contract_Discount__c item : nConditions) {
        	// If the scope respects the current update.
            if (item.Respects_Contract_Scope__c
                /*&& item.Respects_Contract_Scope__c != Trigger.OldMap.get(item.Id).Respects_Contract_Scope__c*/) {
                    if (conditionsWithModifiedScope.containsKey(item.Contract__c)) {
                        conditionsWithModifiedScope.get(item.Contract__c).add(item);
                    } else {
                        conditionsWithModifiedScope.put(item.Contract__c, new List<Contract_Discount__c>{item});
                    }
                }
        }
        // Get all conditions related to the current contract and have Respects_Contract_Scope__c equal True.
        Contract_Discount__c condition = new Contract_Discount__c();
        for (Contract__c contract : [SELECT Id, Total_TO__c, Total_TO_Fact__c, Total_TO_FX__c, Total_TO_Fact_1__c, Total_TO_Nego_1__c,
                                     Total_Qty__c, Total_Qty_Fact__c
                                     FROM Contract__c
                                     WHERE Id IN :conditionsWithModifiedScope.keySet()])
        {
            for (Contract_Discount__c item : conditionsWithModifiedScope.get(contract.Id)) {
                item.Base_TO_Nego__c = contract.Total_TO__c;
                item.Base_TO_Actual__c = contract.Total_TO_Fact__c;
                item.Base_TO_Forecast__c = contract.Total_TO_FX__c;
                item.Base_TO_Actual_1__c = contract.Total_TO_Fact_1__c;
                item.Base_TO_Nego_1__c = contract.Total_TO_Nego_1__c;
                item.Base_Quantity_Nego__c = contract.Total_Qty__c;
                item.Base_Quantity_Actual__c = contract.Total_Qty_Fact__c;
            }
        }
    }
    
    /**
     * Assignment before update the status to "Deleted".
     * + control on NS when already invoiced is not Null.
     * @param List<Contract_Discount__c>, Map<Id, Contract_Discount__c>.
     * On Before Update.
     **/
    private static void assignmentAndNSControl(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
    	Map<Id, Contract_Discount__c> conditionsWithModifiedStatus = new Map<Id, Contract_Discount__c>();
        for (Contract_Discount__c item : nConditions) {
            if (item.Status__c != oConditionMap.get(item.Id).Status__c && item.Status__c == 'Deleted') {
                conditionsWithModifiedStatus.put(item.Id, item);
            }
            // Control on NS when already invoiced is not Null.
            if (item.Product_Scope__c != oConditionMap.get(item.Id).Product_Scope__c && item.Already_Invoiced__c != null)
        	    item.addError(string.format(Label.MSG_Cannot_change_NS_for_Condition, new String[]{(String)item.Name}));
        }
        List<Contract_Discount__c> conditionsToUpdate = new List<Contract_Discount__c>();
        for (Contract_Discount__c condition : conditionsWithModifiedStatus.values()) {
        	condition.Value_per__c = 0;
           	condition.Value_amt__c = 0;
           	condition.Deletion_Action_Executed__c = 'Cond value to 0 put to 0. Balance invoice generated';
           	conditionsToUpdate.add(condition);
        }
    }
    
    /**
     * Assign the contract currency ISO code, payment days and payment condition to the condition map fields
     * @param List<Contract_Discount__c>
     * On Before Insert.
     **/
    private static void assignContractFieldsToCondition(List<Contract_Discount__c> nConditions) {
        Set<Id> contractIds = new Set<Id>();
        for (Contract_Discount__c cond : nConditions) {
            contractIds.add(cond.Contract__c);
        }
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>([SELECT Id, CurrencyIsoCode, Default_Sales_Conditions__r.Buying_Payment_Days__c,
                                                                      Default_Sales_Conditions__r.Buying_Payment_Condition__c
                                                                      FROM Contract__c
                                                                      WHERE Id IN :contractIds]);
        // TODO: Handle case of contract having sales condition Exception
        // 
        // Assignment.
        for (Contract_Discount__c cond : nConditions) {
            // Set Already_Invoiced__c and Already_Invoiced_Edited__c to null in case of clone
            cond.Already_Invoiced__c = null;
            cond.Already_Invoiced_Edited__c = null;
            Contract__c contract = contractsMap.get(cond.Contract__c);
            cond.CurrencyIsoCode = contract.CurrencyIsoCode;
            if(contract.Default_Sales_Conditions__r != null) {
                cond.Payment_Days__c = cond.Payment_Days__c == null ? contract.Default_Sales_Conditions__r.Buying_Payment_Days__c : cond.Payment_Days__c;
                cond.Payment_Condition__c = cond.Payment_Condition__c == null ? contract.Default_Sales_Conditions__r.Buying_Payment_Condition__c : cond.Payment_Condition__c;
            }
        }
    }
    
    /**
     * Reach progressive slab Single/Bulk.
     * @param List<Contract_Discount__c> nConditions
     * On Before Insert or Update.
     **/
	private static void reachProgressiveSlab(List<Contract_Discount__c> nConditions) {
		for (Contract_Discount__c item : nConditions) {
	        if (item.Is_Conditional__c) {
	        	Decimal slab;
                if (item.Slab_Calc_Method_TO_Origin__c == 'Actual') {
                    
                    if (item.slab_calc_method__c == 'TO' || item.slab_calc_method__c == 'Prog TO')
                        slab = item.slab_reach_actual__c;
                    
                    else if (item.slab_calc_method__c == 'Qty' || item.slab_calc_method__c == 'Prog Qty')
                        slab = item.Slab_Reach_Actual_Qty__c;

                    else if (item.slab_calc_method__c == 'Sell Out' || item.slab_calc_method__c == 'Prog Sell Out')
                        slab = item.Slab_Reach_Actual_SellOut__c;
                    
                    else if (item.slab_calc_method__c == 'Inc Qty' || item.slab_calc_method__c == 'Inc Prog Qty')
                        slab = item.Slab_Reach_Actual_QtyInc__c;

                    else if (item.slab_calc_method__c == 'Inc Sell Out' || item.slab_calc_method__c == 'Inc Prog Sell out')
                        slab = item.Slab_Reach_Actual_SellOutInc__c;

                    else if (item.slab_calc_method__c == 'Inc TO' || item.slab_calc_method__c == 'Inc Prog TO')
                        slab = item.Slab_Reach_Actual_T0Inc__c;
                    
                } else if (item.Slab_Calc_Method_TO_Origin__c == 'Nego') {
                    
                    if (item.slab_calc_method__c == 'TO' || item.slab_calc_method__c == 'Prog TO')
                        slab = item.Slab_reach_nego__c;
                    
                    else if (item.slab_calc_method__c == 'Qty' || item.slab_calc_method__c == 'Prog Qty')
                        slab = item.Slab_Reach_Nego_Qty__c;
                    
                    else if (item.slab_calc_method__c == 'Sell Out' || item.slab_calc_method__c == 'Prog Sell Out')
                        slab = item.Slab_Reach_Nego_SellOut__c;
                    
                    else if (item.slab_calc_method__c == 'Inc Qty' || item.slab_calc_method__c == 'Inc Prog Qty')
                        slab = item.Slab_Reach_Nego_QtyInc__c;

                    else if (item.slab_calc_method__c == 'Inc Sell Out' || item.slab_calc_method__c == 'Inc Prog Sell out')
                        slab = item.Slab_Reach_Nego_SellOutInc__c;

                    else if (item.slab_calc_method__c == 'Inc TO' || item.slab_calc_method__c == 'Inc Prog TO')
                        slab = item.Slab_Reach_Nego_TOInc__c;
                    
                } else if (item.slab_target__c != null && item.Slab_Calc_Method_TO_Origin__c == 'Target') { //TODO: Check For This Case
                    slab = item.slab_target__c;
                }
                if(slab != null) {
					String slabPercentFieldName = 'slab_per_' + slab + '__c';
                    String slabAmountFieldName = 'Slab_val_' + slab + '__c';
	                item.Value_per__c = (Decimal)item.get(slabPercentFieldName);
	                item.Value_amt__c = (Decimal)item.get(slabAmountFieldName);
                } else {
                    item.Value_per__c = null;
                    item.Value_amt__c = null;
                }
	            /***try {
	                Decimal baseTOActuel = item.Base_TO_Actual__c;
	                Decimal slabThreshold, diff = 1, percent = 0, reachSlab = 0;
	                Integer slabCount = 6, i = 1; // slabCount is the number of field for the slab
	                String slabThresholdFieldName, slabPercentFieldName;
	                slabThresholdFieldName = 'slab_' + i + '__c';
	                slabThreshold = (Decimal)item.get(slabThresholdFieldName);
	                if(slabThreshold != NULL) {
	                    diff = baseTOActuel - slabThreshold;
	                }
	                while(diff > 0 && i <= slabCount) { // number of slab fields = 5, update the number when changing
	                    slabPercentFieldName = 'slab_per_' + i + '__c'; //Save percent of the slab
	                    percent = (Decimal)item.get(slabPercentFieldName);
	                    reachSlab = i;
	                    
	                    i++; // check next slab step
	                    slabThresholdFieldName = (i <= slabCount) ? 'slab_' + i + '__c' : 'slab_' + (i - 1) + '__c';
	                    slabThreshold = (Decimal)item.get(slabThresholdFieldName);
	                    if(slabThreshold != NULL) {
	                        diff = baseTOActuel - slabThreshold;
	                    }
	                    else {
	                        slabPercentFieldName = 'slab_per_' + (i - 1) + '__c';
	                        percent = (Decimal)item.get(slabPercentFieldName);
	                        diff = -1;
	                    }
	                }
	                // check if percent was changed => update percentage value to slab
	                item.Value_per__c = percent;
	                item.slab_target__c = reachSlab; 
	            } catch (Exception e) {
	            }***/
	        }
	    }
	}
    /**
     * Set Invoice Base to null when the index is equal to "Index1". Single/Bulk.
     * Set Is Duplicable field to true when the Is Duplicable field in condition type is not empty
     * Set Total_Counteparts_to_Justify__c when Proof_counterparty_requested__c in tarrif Condition is checked
     * @param List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap
     * On Before Upsert
     **/
    private static void setFields(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        Set<Id> tarrifConditionSet = new Set<Id>();
        Set<Id> parentConditionSet = new Set<Id>();
        List<Contract_Discount__c> allConditionsList = new List<Contract_Discount__c>();
        for (Contract_Discount__c item : nConditions) {
            if (item.Index__c == 'Index1' && (item.Invoice_base__c != null || (item.Id != null && item.Invoice_base__c != oConditionMap.get(item.Id).Invoice_base__c))) {
                item.Invoice_base__c = null;
            }
            // set is_duplicable__c and Total_Counterparts_to_Justify__c fields
            if (item.Condition_Type__c != null) {
                if (item.Id == null && item.Reference_condition__c != null) {
                    parentConditionSet.add(item.Reference_condition__c);
                }
                tarrifConditionSet.add(item.Condition_Type__c);
                allConditionsList.add(item);
            }
            ////if (item.Nego_Discount_Type__c == 'Penalties') item.is_duplicable__c = False;
        }
        // Set is_duplicable__c field for new records and Total_Counteparts_to_Justify__c on insert or update
        if (!allConditionsList.isEmpty() && !tarrifConditionSet.isEmpty()) {
            Map<Id, Pol_Com_Condition__c> tarrifConditionMap = new Map<Id, Pol_Com_Condition__c>([SELECT Id, Condition_Duplication__c, Proof_counterparty_requested__c
                                                                                                  FROM Pol_Com_Condition__c
                                                                                                  WHERE Id IN :tarrifConditionSet]);
            Map<Id, Contract_Discount__c> parentConditionMap;
            if (!parentConditionSet.isEmpty())
                parentConditionMap = new Map<Id, Contract_Discount__c>([SELECT Id, is_duplicable__c
                                                                        FROM Contract_Discount__c
                                                                        WHERE Id IN :parentConditionSet]);
            for (Contract_Discount__c item : allConditionsList) {
                if (item.Condition_Type__c != null) {
                    Pol_Com_Condition__c tarrifCondition = tarrifConditionMap.get(item.Condition_Type__c); 
                    // set is_duplicable__c
                    if(item.Id == null) {
                        if (item.Reference_condition__c != null && parentConditionMap != null && parentConditionMap.containsKey(item.Reference_condition__c)) {
                            item.is_duplicable__c = parentConditionMap.get(item.Reference_condition__c).is_duplicable__c;
                            if (tarrifCondition.Condition_Duplication__c != null) {
                                List<String> duplicationList = tarrifCondition.Condition_Duplication__c.split(';');
                                if (!duplicationList.contains('%')) {
                                    item.Value_per__c = null;
                                }
                                if (!duplicationList.contains('F')) {
                                    item.Value_amt__c = null;
                                }
                                if (!duplicationList.contains('U')) {
                                    item.unit_amount__c = null;
                                }
                            }
                        } else {
                            if (tarrifCondition.Condition_Duplication__c != null) {
                                List<String> duplicationList = tarrifCondition.Condition_Duplication__c.split(';');
                                if ((duplicationList.contains('%') && item.Value_per__c != null)
                                    || (duplicationList.contains('F') && item.Value_amt__c != null)
                                    || (duplicationList.contains('U') && item.unit_amount__c != null))
                                {
                                    item.is_duplicable__c = true;
                                }
                            } else {
                                item.is_duplicable__c = false;
                            }
                        }
                    }
                    // set Total_Counteparts_to_Justify__c
                    if(tarrifCondition.Proof_counterparty_requested__c == true) {
                        item.Total_Counterparts_to_Justify__c = item.YTD_Nego__c;
                    }
                }
            }
        }
    }
    /**
     * Delete Invoice details line and Invoices head (if are empty)
     * when condition pass to Valid__c = false.
     * On After Update
     * */
    private static void cleanUpInvoices(List<Contract_Discount__c> nConditions, Map<Id, Contract_Discount__c> oConditionMap) {
        // List of impacted conditions
        Set<Id> conditions = new Set<Id>();
        for (Contract_Discount__c item : nConditions) {
            if (item.Valid__c == false && item.Valid__c != oConditionMap.get(item.Id).Valid__c) {
                conditions.add(item.Id);
            }
        }
        if (!conditions.isEmpty()) {
            List<Invoice_Detail__c> invoicesDetailsToDelete = new List<Invoice_Detail__c>();
            Set<Id> invoicesToDelete = new Set<Id>();
            for (Invoice_Detail__c item : [SELECT Id, Invoice__c FROM Invoice_Detail__c
                                           WHERE Discount__c IN :conditions
                                           AND Invoice__r.Inv_Status__c <> 'Printed'])
            {
                invoicesDetailsToDelete.add(item);
                invoicesToDelete.add(item.Invoice__c);
            }
            if (!invoicesDetailsToDelete.isEmpty()) {
                if(NegoptimHelper.checkDeletibility(Invoice__c.SObjectType) && NegoptimHelper.checkDeletibility(Invoice_Detail__c.SObjectType)) {
                    delete invoicesDetailsToDelete;
                    delete [SELECT Id FROM Invoice__c WHERE Id IN :invoicesToDelete AND Inv_value__c = 0];
                }
            }
        }
    }
}