/**
 * Batchable class used to merge duplicated and simulation contracts (conditions is included)
 * */
public with sharing class MergeContractBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id countryId;
    public final List<Id> supplierIds;
    public final List<Id> contractToMergeIds;
    public final List<Id> parentContractIds;
    public final Integer year;
    
    // Constructor.
    public MergeContractBatch(String staredFrom, Id countryId, List<Id> sIds, List<Id> cIds, List<Id> pIds, Integer y) {
        nb = new NegoptimBatch('Merge Contract', NegoptimBatch.BatchType.Stateful,staredFrom);
        this.countryId = countryId;
        this.supplierIds = sIds; // required if contractToMergeIds not empty or parentContractIds not empty
        this.contractToMergeIds = cIds;
        this.parentContractIds = pIds;
        this.year = y;
        String q = 'SELECT c.Id, c.Name, c.CurrencyIsoCode, c.Contract_BDate__c, c.Contract_BU__c, c.Contract_EDate__c,';
        q += ' c.Contract_Type__c,  c.D_N__c, c.Duration__c, c.Duration_type__c, c.Supplier__c, c.Contract_Numbder__c,';
        q += ' c.Parent_Contract__c, c.Supplier__r.Name, c.Supplier__r.Status__c, c.Supplier_Nego_Scope__r.Status__c,';
        q += ' c.TO1__c, c.TO2__c, c.TO3__c, c.TO4__c, c.TO5__c, c.TO6__c, c.TO7__c, c.TO8__c, c.TO9__c, c.TO10__c, c.TO11__c, c.TO12__c,';
        q += ' c.TO1_Fact__c, c.TO2_Fact__c, c.TO3_Fact__c, c.TO4_Fact__c, c.TO5_Fact__c, c.TO6_Fact__c,';
        q += ' c.TO7_Fact__c, c.TO8_Fact__c, c.TO9_Fact__c, c.TO10_Fact__c, c.TO11_Fact__c, c.TO12_Fact__c,';
        q += ' c.TO1_FX__c, c.TO2_FX__c, c.TO3_FX__c, c.TO4_FX__c, c.TO5_FX__c, c.TO6_FX__c,';
        q += ' c.TO7_FX__c, c.TO8_FX__c, c.TO9_FX__c, c.TO10_FX__c, c.TO11_FX__c, c.TO12_FX__c,';
        q += ' c.Qty1__c, c.Qty2__c, c.Qty3__c, c.Qty4__c, c.Qty5__c, c.Qty6__c, c.Qty7__c, c.Qty8__c, c.Qty9__c, c.Qty10__c, c.Qty11__c, c.Qty12__c,';
        q += ' c.Total_TO_Ref__c, Secure_Multiyear__c, Supplier_Nego_Scope__c,';
        q += ' (Select Id, Name, Base_TO_Nego__c, Base_TO_Actual__c, CurrencyIsoCode, Reference_condition__c, all_BU__c, all_items__c, Base_Calculation_Model__c,';
        q += ' BU_Scope__c, commercial_reference__c, Condition_Type__c, Contract__c, Contract_Group__c, Contract_Group_Reference__c,';
        q += ' Disc_BDate__c, Disc_EDate__c, financial_reference__c, first_invoice_date__c, Fist_Provision_Date__c,';
        q += ' Is_Conditional__c, is_duplicable__c, legal_reference__c, Minimum_Guarantee__c,';
        q += ' Payment_Condition__c, Payment_Days__c, Product_Scope__c, Provision_base__c, Provision_period__c, ';
        q += ' Invoice_base__c, Invoice_period__c, Invoice_sequence__c, Nego_Discount_Type__c, Provision_Sequence__c, Base_Quantity_Nego__c,';
        q += ' Rank__c, Reference_Contract__c, Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, slab_calc_method__c,';
        q += ' slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c,';
        q += ' slab_target__c, Slab_val_1__c, Slab_val_2__c, Slab_val_3__c, Slab_val_4__c, Slab_val_5__c, Slab_val_6__c,';
        q += ' Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c, Value_amt_disp_M6__c,';
        q += ' Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c, Value_amt_disp_M11__c, Value_amt_disp_M12__c,';
        q += ' Status__c, Status_BDate__c, unit_amount__c, Valid__c, Value_per__c, Value_amt__c, Is_Prenego_Envelop__c,';
        q += ' Value_per_Y1__c, Value_per_Y2__c, Value_amt_Y1__c, Value_amt_Y2__c';
        q += ' FROM Contract_Discounts__r WHERE Product_Scope__r.Status__c = \'Active\' AND BU_Scope__r.Status__c = \'Open\' AND Is_Prenego_Envelop__c = True)';
        q += ' FROM Contract__c c';
        q += ' WHERE c.Supplier__r.Status__c = \'Active\' AND c.Supplier_Nego_Scope__r.Status__c = \'Active\'';
        q += ' AND ((c.Contract_Type__c = \'Simulation\' AND c.Status__c = \'Published\'';
        if(contractToMergeIds != null && contractToMergeIds.size() > 0) {
            q += ' AND c.Id IN (\'' + String.join(contractToMergeIds, '\',\'') +'\')';
        }
        q += ' ) OR';
        q += ' (c.Contract_Type__c = \'Contract\' AND c.Status__c = \'Validated\' AND c.D_N__c = \'D\'';
        if(parentContractIds != null && parentContractIds.size() > 0) {
            q += ' AND c.Parent_Contract__c IN (\'' + String.join(parentContractIds, '\',\'') +'\')';
        }
        q += ' )) AND CALENDAR_YEAR(c.Contract_BDate__c) = ' + year + ' AND c.Contract_BU__c = \'' + countryId + '\'';
        if(supplierIds != null && supplierIds.size() > 0) {
            q += ' AND c.Supplier__c IN (\'' + String.join(supplierIds, '\',\'') +'\')';
        }
        q += ' ORDER BY Contract_Type__c';
        // Set the final variable.
        query = q;
        
        nb.logParameter('countryId', countryId);
        nb.logParameter('supplierIds', supplierIds);
        nb.logParameter('contractToMergeIds', contractToMergeIds);
        nb.logParameter('parentContractIds', parentContractIds);
        nb.logParameter('year', year);
        nb.logParameter('query', query);
    }
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method.
    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        Map<String, WrapperContract> wContractsMap = new Map<String, WrapperContract>();

        // Mapping: duplicated contract Id and conditions.
        Map<Id, List<Contract_Discount__c>> dupContIdWithConditionsMap = new Map<Id, List<Contract_Discount__c>>();
        // Mapping: simulation contract Id and conditions.
        Map<Id, List<Contract_Discount__c>> simContIdWithConditionsMap = new Map<Id, List<Contract_Discount__c>>();

        // Mapping: duplicated contract Id and simulation contract Id.
        Map<Id, Id> dupContIdWithSimContIdMap = new Map<Id, Id>();
        // Mapping: simulation contract Id and duplicated contract Id.
        Map<Id, Id> simContIdWithDupContIdMap = new Map<Id, Id>();


        // TODO: CHANGE THE LOGIC AND MOVE TO A WRAPPER CLASS KEY/SIMULATION/DUPLICATED
        for (Contract__c c : scope) {
            String key = c.Supplier__c + '' + c.Supplier_Nego_Scope__c;
            if(c.Parent_Contract__c != null)
                key += c.Parent_Contract__c;
            if(wContractsMap.containsKey(key)) {
                String s = wContractsMap.get(key).push(c);
                if(s != null) {
                    nb.logError(s + ' (' + key + ')');
                }
            }
            else {
                WrapperContract wContract = new WrapperContract(key);
                wContract.push(c);
                wContractsMap.put(key, wContract);
            }
        }
        // Wrapper class which contains list of conditions related to the duplicated contract, and
        // list of conditions related to the simulation contract.
        List<WrapperCondition> wCondsList = new List<WrapperCondition>();
        List<Contract__c> contractsToUpdate = new List<Contract__c>();
        Contract__c duplicatedContract; // TODO: REMOVE
        Boolean hasDuplicatedContract; // TODO: REMOVE
        for(String key : wContractsMap.keySet()) {
            WrapperContract wContract = wContractsMap.get(key);
            // TODO: MOVE MERGE CONDITIONS TO THE WRAPPER AND CALL IT FROM THE WRAPPER OF CONTRACT
            wContract.doMerge();
            hasDuplicatedContract = wContract.duplicatedContract != null && wContract.simulationContract != null; // TODO: REMOVE
            WrapperCondition wConds = new WrapperCondition();
            if(wContract.duplicatedContract != null) {
                dupContIdWithConditionsMap.put(wContract.duplicatedContract.Id, wContract.duplicatedContract.Contract_Discounts__r);
                wConds.conditionsD = wContract.duplicatedContract.Contract_Discounts__r;
                contractsToUpdate.add(wContract.duplicatedContract);
                // TODO: REMOVE
                duplicatedContract = wContract.duplicatedContract;
            }
            if(wContract.simulationContract != null) {
                simContIdWithConditionsMap.put(wContract.simulationContract.Id, wContract.simulationContract.Contract_Discounts__r);
                wConds.conditionsS = wContract.simulationContract.Contract_Discounts__r;
                contractsToUpdate.add(wContract.simulationContract);
            }
            if(wContract.duplicatedContract != null && wContract.simulationContract != null) {
                simContIdWithDupContIdMap.put(wContract.simulationContract.Id, wContract.duplicatedContract.Id);
            }
            wCondsList.add(wConds);
        }
        // Mapping: duplicated contract ref and duplicated contract.
        Map<Id, Contract_Discount__c> refCondDupWithCondDupMap = new Map<Id, Contract_Discount__c>();
        // Mapping: simulation contract ref and simulation contract.
        Map<Id, Contract_Discount__c> refCondSimWithCondSimMap = new Map<Id, Contract_Discount__c>();
        // Fill refCondDupWithCondDupMap, fill refCondSimWithCondSimMap, from wCondsList.
        Id refCondition;
        for (WrapperCondition wcItem: wCondsList) {
            for (Contract_Discount__c condD : wcItem.conditionsD) {
                // check if it's new condition => put id of the condition instead of
                refCondition = condD.Reference_condition__c != null ? condD.Reference_condition__c : condD.Id;
                refCondDupWithCondDupMap.put(refCondition, condD);
            }
            for (Contract_Discount__c condS : wcItem.conditionsS) {
                // check if it's new condition => put id of the condition instead of
                refCondition = condS.Reference_condition__c != null ? condS.Reference_condition__c : condS.Id;
                refCondSimWithCondSimMap.put(refCondition, condS);
            }
        } 
        List<Contract_Discount__c> conditionsToUpsert = new List<Contract_Discount__c>();
        List<Contract_Discount__c> conditionsToDelete = new List<Contract_Discount__c>();
        for (Id refCondS : refCondSimWithCondSimMap.keySet()) {
            Contract_Discount__c conditionInSimulation = refCondSimWithCondSimMap.get(refCondS);
            // If we have condition(s) which is/are inserted in the simulation contract.
            if (!refCondDupWithCondDupMap.containsKey(refCondS)) {
                Id dupContractId = simContIdWithDupContIdMap.get(conditionInSimulation.Contract__c);
                if(dupContractId != null) { // when duplicated contract exist
                    Contract_Discount__c conditionToCreate = conditionInSimulation.clone(false, true, true, false);
                    conditionToCreate.Contract__c = dupContractId;
                    conditionsToUpsert.add(conditionToCreate);
                }
            } else {
                Contract_Discount__c conditionInDuplicated = refCondDupWithCondDupMap.get(refCondS);
                Boolean isUpdated = False;
                if (conditionInSimulation.all_BU__c != conditionInDuplicated.all_BU__c) {
                    conditionInDuplicated.all_BU__c = conditionInSimulation.all_BU__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.all_items__c != conditionInDuplicated.all_items__c) {
                    conditionInDuplicated.all_items__c = conditionInSimulation.all_items__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Base_Calculation_Model__c != conditionInDuplicated.Base_Calculation_Model__c) {
                    conditionInDuplicated.Base_Calculation_Model__c = conditionInSimulation.Base_Calculation_Model__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.BU_Scope__c != conditionInDuplicated.BU_Scope__c) {
                    conditionInDuplicated.BU_Scope__c = conditionInSimulation.BU_Scope__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Condition_Type__c != conditionInDuplicated.Condition_Type__c) {
                    conditionInDuplicated.Condition_Type__c = conditionInSimulation.Condition_Type__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.CurrencyIsoCode != conditionInDuplicated.CurrencyIsoCode) {
                    conditionInDuplicated.CurrencyIsoCode = conditionInSimulation.CurrencyIsoCode;
                    isUpdated = True;
                }
                if (conditionInSimulation.Disc_BDate__c != conditionInDuplicated.Disc_BDate__c) {
                    conditionInDuplicated.Disc_BDate__c = conditionInSimulation.Disc_BDate__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Disc_EDate__c != conditionInDuplicated.Disc_EDate__c) {
                    conditionInDuplicated.Disc_EDate__c = conditionInSimulation.Disc_EDate__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Invoice_base__c != conditionInDuplicated.Invoice_base__c) {
                    conditionInDuplicated.Invoice_base__c = conditionInSimulation.Invoice_base__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Invoice_sequence__c != conditionInDuplicated.Invoice_sequence__c) {
                    conditionInDuplicated.Invoice_sequence__c = conditionInSimulation.Invoice_sequence__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.is_duplicable__c != conditionInDuplicated.is_duplicable__c) {
                    conditionInDuplicated.is_duplicable__c = conditionInSimulation.is_duplicable__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Minimum_Guarantee__c != conditionInDuplicated.Minimum_Guarantee__c) {
                    conditionInDuplicated.Minimum_Guarantee__c = conditionInSimulation.Minimum_Guarantee__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Payment_Condition__c != conditionInDuplicated.Payment_Condition__c) {
                    conditionInDuplicated.Payment_Condition__c = conditionInSimulation.Payment_Condition__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Payment_Days__c != conditionInDuplicated.Payment_Days__c) {
                    conditionInDuplicated.Payment_Days__c = conditionInSimulation.Payment_Days__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Product_Scope__c != conditionInDuplicated.Product_Scope__c) {
                    conditionInDuplicated.Product_Scope__c = conditionInSimulation.Product_Scope__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Provision_base__c != conditionInDuplicated.Provision_base__c) {
                    conditionInDuplicated.Provision_base__c = conditionInSimulation.Provision_base__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Provision_Sequence__c != conditionInDuplicated.Provision_Sequence__c) {
                    conditionInDuplicated.Provision_Sequence__c = conditionInSimulation.Provision_Sequence__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Rank__c != conditionInDuplicated.Rank__c) {
                    conditionInDuplicated.Rank__c = conditionInSimulation.Rank__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Valid__c != conditionInDuplicated.Valid__c) {
                    conditionInDuplicated.Valid__c = conditionInSimulation.Valid__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Value_per__c != conditionInDuplicated.Value_per__c) {
                    conditionInDuplicated.Value_per__c = conditionInSimulation.Value_per__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Base_Quantity_Nego__c != conditionInDuplicated.Base_Quantity_Nego__c) {
                    conditionInDuplicated.Base_Quantity_Nego__c = conditionInSimulation.Base_Quantity_Nego__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Value_amt__c != conditionInDuplicated.Value_amt__c) {
                    conditionInDuplicated.Value_amt__c = conditionInSimulation.Value_amt__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_per_1__c != conditionInDuplicated.slab_per_1__c) {
                    conditionInDuplicated.slab_per_1__c = conditionInSimulation.slab_per_1__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_per_2__c != conditionInDuplicated.slab_per_2__c) {
                    conditionInDuplicated.slab_per_2__c = conditionInSimulation.slab_per_2__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_per_3__c != conditionInDuplicated.slab_per_3__c) {
                    conditionInDuplicated.slab_per_3__c = conditionInSimulation.slab_per_3__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_per_4__c != conditionInDuplicated.slab_per_4__c) {
                    conditionInDuplicated.slab_per_4__c = conditionInSimulation.slab_per_4__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_per_5__c != conditionInDuplicated.slab_per_5__c) {
                    conditionInDuplicated.slab_per_5__c = conditionInSimulation.slab_per_5__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_per_6__c != conditionInDuplicated.slab_per_6__c) {
                    conditionInDuplicated.slab_per_6__c = conditionInSimulation.slab_per_6__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_1__c != conditionInDuplicated.Slab_1__c) {
                    conditionInDuplicated.Slab_1__c = conditionInSimulation.Slab_1__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_2__c != conditionInDuplicated.Slab_2__c) {
                    conditionInDuplicated.Slab_2__c = conditionInSimulation.Slab_2__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_3__c != conditionInDuplicated.Slab_3__c) {
                    conditionInDuplicated.Slab_3__c = conditionInSimulation.Slab_3__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_4__c != conditionInDuplicated.Slab_4__c) {
                    conditionInDuplicated.Slab_4__c = conditionInSimulation.Slab_4__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_5__c != conditionInDuplicated.Slab_5__c) {
                    conditionInDuplicated.Slab_5__c = conditionInSimulation.Slab_5__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_6__c != conditionInDuplicated.Slab_6__c) {
                    conditionInDuplicated.Slab_6__c = conditionInSimulation.Slab_6__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_val_1__c != conditionInDuplicated.Slab_val_1__c) {
                    conditionInDuplicated.Slab_val_1__c = conditionInSimulation.Slab_val_1__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_val_2__c != conditionInDuplicated.Slab_val_2__c) {
                    conditionInDuplicated.Slab_val_2__c = conditionInSimulation.Slab_val_2__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_val_3__c != conditionInDuplicated.Slab_val_3__c) {
                    conditionInDuplicated.Slab_val_3__c = conditionInSimulation.Slab_val_3__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_val_4__c != conditionInDuplicated.Slab_val_4__c) {
                    conditionInDuplicated.Slab_val_4__c = conditionInSimulation.Slab_val_4__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_val_5__c != conditionInDuplicated.Slab_val_5__c) {
                    conditionInDuplicated.Slab_val_5__c = conditionInSimulation.Slab_val_5__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Slab_val_6__c != conditionInDuplicated.Slab_val_6__c) {
                    conditionInDuplicated.Slab_val_6__c = conditionInSimulation.Slab_val_6__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_target__c != conditionInDuplicated.slab_target__c) {
                    conditionInDuplicated.slab_target__c = conditionInSimulation.slab_target__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.slab_calc_method__c != conditionInDuplicated.slab_calc_method__c) {
                    conditionInDuplicated.slab_calc_method__c = conditionInSimulation.slab_calc_method__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Commercial_reference__c != conditionInDuplicated.Commercial_reference__c) {
                    conditionInDuplicated.Commercial_reference__c = conditionInSimulation.Commercial_reference__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.financial_reference__c != conditionInDuplicated.financial_reference__c) {
                    conditionInDuplicated.financial_reference__c = conditionInSimulation.financial_reference__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.legal_reference__c != conditionInDuplicated.legal_reference__c) {
                    conditionInDuplicated.legal_reference__c = conditionInSimulation.legal_reference__c;
                    isUpdated = True;
                }
                if (conditionInSimulation.Base_TO_Nego__c != conditionInDuplicated.Base_TO_Nego__c) {
                    conditionInDuplicated.Base_TO_Nego__c = conditionInSimulation.Base_TO_Nego__c;
                    isUpdated = True;
                }
                if (isUpdated) {
                    conditionInDuplicated.Status__c = 'Updated';
                }
                conditionsToUpsert.add(conditionInDuplicated);
            }
        }
        
        List<Contract_Discount__c> removedConditionsList = new List<Contract_Discount__c>();
        for (Id refCondD : refCondDupWithCondDupMap.keySet()) {
            // If we have condition(s) which is removed from the simulation contract.
            if (!refCondSimWithCondSimMap.containsKey(refCondD)) {
                removedConditionsList.add(refCondDupWithCondDupMap.get(refCondD));
            }
        }
        // Set of conditions Id that cannot be deleted
        Set<Id> conditionsHavingDependenciesSet = new Set<Id>();
        // Invoice details
        for (AggregateResult ar : [SELECT Count(Id), Discount__c Discount__c
                                   FROM Invoice_Detail__c
                                   WHERE Discount__c IN :removedConditionsList
                                   GROUP BY Discount__c])
        {
            conditionsHavingDependenciesSet.add((Id)ar.get('Discount__c'));
        }
        // Dispatch Details
        for (AggregateResult ar : [SELECT count(Id), Discount__c Discount__c
                                   FROM Inv_BUDispatch_Details__c
                                   WHERE Discount__c IN :removedConditionsList
                                   GROUP BY Discount__c])
        {
            conditionsHavingDependenciesSet.add((Id)ar.get('Discount__c'));
        }
        // Set of conditions Id that cannot be deleted
        for (Contract_Discount__c cond : removedConditionsList) {
            // When the condition is not auto-generated by a Mass upload => Is_Prenego_Envelop__c is True.
            if (cond.Is_Prenego_Envelop__c != False) {
                if (cond.Value_amt__c != null) cond.Value_amt__c = 0;
                if (cond.Value_per__c != null) cond.Value_per__c = 0;
                if (cond.Base_Quantity_Nego__c != null) cond.Base_Quantity_Nego__c = 0;
                if (cond.Slab_1__c != Null) cond.Slab_1__c = 0;
                if (cond.Slab_2__c != Null) cond.Slab_2__c = 0;
                if (cond.Slab_3__c != Null) cond.Slab_3__c = 0;
                if (cond.Slab_4__c != Null) cond.Slab_4__c = 0;
                if (cond.Slab_5__c != Null) cond.Slab_5__c = 0;
                if (cond.Value_amt_disp_M1__c  != Null) cond.Value_amt_disp_M1__c  = 0;
                if (cond.Value_amt_disp_M2__c  != Null) cond.Value_amt_disp_M2__c  = 0;
                if (cond.Value_amt_disp_M3__c  != Null) cond.Value_amt_disp_M3__c  = 0;
                if (cond.Value_amt_disp_M4__c  != Null) cond.Value_amt_disp_M4__c  = 0;
                if (cond.Value_amt_disp_M5__c  != Null) cond.Value_amt_disp_M5__c  = 0;
                if (cond.Value_amt_disp_M6__c  != Null) cond.Value_amt_disp_M6__c  = 0;
                if (cond.Value_amt_disp_M7__c  != Null) cond.Value_amt_disp_M7__c  = 0;
                if (cond.Value_amt_disp_M8__c  != Null) cond.Value_amt_disp_M8__c  = 0;
                if (cond.Value_amt_disp_M9__c  != Null) cond.Value_amt_disp_M9__c  = 0;
                if (cond.Value_amt_disp_M10__c  != Null) cond.Value_amt_disp_M10__c  = 0;
                if (cond.Value_amt_disp_M11__c  != Null) cond.Value_amt_disp_M11__c  = 0;
                if (cond.Value_amt_disp_M12__c  != Null) cond.Value_amt_disp_M12__c  = 0;
                // There is/are linked Invoice(s).
                if(conditionsHavingDependenciesSet.contains(cond.Id)) {
                    cond.Status__c = 'Deleted';
                    cond.Value_per__c = 0;
                    conditionsToUpsert.add(cond);
                }
                else { // There is/are no linked Invoice(s).
                    conditionsToDelete.add(cond);
                }
            } else {
                // When the condition is auto-generated by a Mass upload => Is_Prenego_Envelop__c is False.
                // Nothing to do, neither update (set fields to 0) nor delete.
            }
        }
        
        // check security on upsert contract fields
        String[] contractFields = new String[] {'Name', NegoptimHelper.normalizeAPIName('Contract_Type__c'), NegoptimHelper.normalizeAPIName('Contract_Numbder__c'),
            NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('D_N__c'), NegoptimHelper.normalizeAPIName('Total_TO_Ref__c'),
            NegoptimHelper.normalizeAPIName('Secure_Multiyear__c'), NegoptimHelper.normalizeAPIName('Contract_BDate__c'), NegoptimHelper.normalizeAPIName('Contract_EDate__c')};
                
        // check security on upsert condition fields
        String[] conditionFields = new String[] {'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Value_amt__c'), NegoptimHelper.normalizeAPIName('Value_per__c'),
                    NegoptimHelper.normalizeAPIName('Base_Quantity_Nego__c'), NegoptimHelper.normalizeAPIName('Slab_1__c'), NegoptimHelper.normalizeAPIName('Slab_2__c'),
                    NegoptimHelper.normalizeAPIName('Slab_3__c'), NegoptimHelper.normalizeAPIName('Slab_4__c'), NegoptimHelper.normalizeAPIName('Slab_5__c'), NegoptimHelper.normalizeAPIName('Slab_6__c'),
                    NegoptimHelper.normalizeAPIName('Value_amt_disp_M1__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M2__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M3__c'),
                    NegoptimHelper.normalizeAPIName('Value_amt_disp_M4__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M5__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M6__c'),
                    NegoptimHelper.normalizeAPIName('Value_amt_disp_M7__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M8__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M9__c'),
                    NegoptimHelper.normalizeAPIName('Value_amt_disp_M10__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M11__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M12__c'),
                    NegoptimHelper.normalizeAPIName('all_BU__c'), NegoptimHelper.normalizeAPIName('all_items__c'), NegoptimHelper.normalizeAPIName('Base_Calculation_Model__c'),
                    NegoptimHelper.normalizeAPIName('BU_Scope__c'), NegoptimHelper.normalizeAPIName('Condition_Type__c'), NegoptimHelper.normalizeAPIName('Disc_BDate__c'),
                    NegoptimHelper.normalizeAPIName('Disc_EDate__c'), NegoptimHelper.normalizeAPIName('Invoice_base__c'), NegoptimHelper.normalizeAPIName('Invoice_sequence__c'),
                    NegoptimHelper.normalizeAPIName('is_duplicable__c'), NegoptimHelper.normalizeAPIName('Minimum_Guarantee__c'), NegoptimHelper.normalizeAPIName('Payment_Condition__c'),
                    NegoptimHelper.normalizeAPIName('Payment_Days__c'), NegoptimHelper.normalizeAPIName('Product_Scope__c'), NegoptimHelper.normalizeAPIName('Provision_base__c'),
                    NegoptimHelper.normalizeAPIName('Provision_Sequence__c'), NegoptimHelper.normalizeAPIName('Rank__c'), NegoptimHelper.normalizeAPIName('Valid__c'),
                    NegoptimHelper.normalizeAPIName('slab_per_1__c'), NegoptimHelper.normalizeAPIName('slab_per_2__c'), NegoptimHelper.normalizeAPIName('slab_per_3__c'),
                    NegoptimHelper.normalizeAPIName('slab_per_4__c'), NegoptimHelper.normalizeAPIName('slab_per_5__c'), NegoptimHelper.normalizeAPIName('slab_per_6__c'),
                    NegoptimHelper.normalizeAPIName('Slab_val_1__c'), NegoptimHelper.normalizeAPIName('Slab_val_2__c'), NegoptimHelper.normalizeAPIName('Slab_val_3__c'),
                    NegoptimHelper.normalizeAPIName('Slab_val_4__c'), NegoptimHelper.normalizeAPIName('Slab_val_5__c'), NegoptimHelper.normalizeAPIName('Slab_val_6__c'),
                    NegoptimHelper.normalizeAPIName('slab_target__c'), NegoptimHelper.normalizeAPIName('slab_calc_method__c'), NegoptimHelper.normalizeAPIName('Commercial_reference__c'),
                    NegoptimHelper.normalizeAPIName('financial_reference__c'), NegoptimHelper.normalizeAPIName('legal_reference__c'), NegoptimHelper.normalizeAPIName('Base_TO_Nego__c'),
                    NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Value_per_Y1__c'), NegoptimHelper.normalizeAPIName('Value_amt_Y1__c'),
                    NegoptimHelper.normalizeAPIName('Value_per_Y2__c'), NegoptimHelper.normalizeAPIName('Value_amt_Y2__c')};
                        
        String[] conditionInsertFields = new String[] {NegoptimHelper.normalizeAPIName('Contract__c')};
            conditionInsertFields.addAll(conditionFields);
        
        Savepoint sp = Database.setSavepoint();
        try {            
            // upsert conditions
            if(!conditionsToUpsert.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionInsertFields) &&
                   NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(conditionsToUpsert, false);
                    nb.logResults(results, conditionsToUpsert);
                }
            }
            // delete conditions
            if (NegoptimHelper.checkDeletibility(Contract_Discount__c.sObjectType)) {
                delete conditionsToDelete;
            }
            // upsert contracts
            if(!contractsToUpdate.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Contract__c.SObjectType, contractFields) && NegoptimHelper.checkUpdatibility(Contract__c.SObjectType, contractFields)) {
                    List<Database.UpsertResult> results = Database.upsert(contractsToUpdate, false);
                    nb.logResults(results, contractsToUpdate);
                }
            }
        } catch(DMLException e) {
            nb.logError(e);
        }
        // TODO: MOVE FOLLOWING TO WRAPPER
        // Secure multi year.
        List<Contract__c> contracts;
        Integer cCount = 0;
        if(duplicatedContract != null)
            cCount = duplicatedContract.Secure_Multiyear__c == '2 years' ? 1 : duplicatedContract.Secure_Multiyear__c == '3 years' ? 2 : 0;

        if (cCount != 0) {
            contracts = new List<Contract__c>();
            for (Integer i = 1 ; i <= cCount ; i++) {
                Contract__c c = duplicatedContract.clone(false, true, true, false);
                c.Contract_BDate__c = c.Contract_BDate__c.addYears(i);
                c.Contract_EDate__c = c.Contract_EDate__c.addYears(i);
                c.Name = c.Name.replace('' + (duplicatedContract.Contract_BDate__c.year()), '' +  (c.Contract_BDate__c.year()));
                c.Contract_Numbder__c = null;
                c.Secure_Multiyear__c = null;
                contracts.add(c);
            }
        }
        try {
            if (contracts != null && !contracts.isEmpty()) {
                // insert contracts
                if(!contracts.isEmpty()) {
                    if(NegoptimHelper.checkCreatibility(Contract__c.SObjectType, contractFields)) {
                        List<Database.SaveResult> results = Database.insert(contracts, false);
                        nb.logResults(results, contracts);
                    }
                }
                List<Contract_Discount__c> conditions = new List<Contract_Discount__c>();                
                for (Integer i = 0; i < contracts.size(); i++) {
                    Contract__c c = contracts.get(i);
                    if(!hasDuplicatedContract) {
                        for (Id id : simContIdWithConditionsMap.keySet()) {
                            if (simContIdWithConditionsMap.get(id) != Null) {
                                for (Contract_Discount__c condition : simContIdWithConditionsMap.get(id)) {
                                    Contract_Discount__c cond = condition.clone(false, true, true, false);
                                    cond.Contract__c = c.Id;
                                    cond.Disc_BDate__c = Date.newInstance(c.Contract_BDate__c.year(), condition.Disc_BDate__c.month(), condition.Disc_BDate__c.day());
                                    cond.Disc_EDate__c = Date.newInstance(c.Contract_EDate__c.year(), condition.Disc_EDate__c.month(), condition.Disc_EDate__c.day());
                                    conditions.add(cond);
                                }
                            }
                        }
                    }
                    else {
                        // Get list of conditions to attach it to the contract(s).
                        for (Contract_Discount__c condition : conditionsToUpsert) {
                            if (condition.Status__c != 'Deleted') {
                                Contract_Discount__c cond = condition.clone(false, true, true, false);
                                cond.Contract__c = c.Id;
                                cond.Disc_BDate__c = Date.newInstance(c.Contract_BDate__c.year(), condition.Disc_BDate__c.month(), condition.Disc_BDate__c.day());
                                cond.Disc_EDate__c = Date.newInstance(c.Contract_EDate__c.year(), condition.Disc_EDate__c.month(), condition.Disc_EDate__c.day());
                                conditions.add(cond);
                            }
                        }
                    }
                    for (Contract_Discount__c condition : conditions) {
                        if (i == 0) {
                            condition.Value_per__c = condition.Value_per_Y1__c != Null ? condition.Value_per_Y1__c : condition.Value_per__c;
                            condition.Value_amt__c = condition.Value_amt_Y1__c != Null ? condition.Value_amt_Y1__c : condition.Value_amt__c;
                            condition.Value_per_Y1__c = null;
                            condition.Value_amt_Y1__c = null;
                        }
                        if(i == 1) {
                            condition.Value_per__c = condition.Value_per_Y2__c != Null ? condition.Value_per_Y2__c : condition.Value_per__c;
                            condition.Value_amt__c = condition.Value_amt_Y2__c != Null ? condition.Value_amt_Y2__c : condition.Value_amt__c;
                            condition.Value_per_Y2__c = null;
                            condition.Value_amt_Y2__c = null;
                        }
                    }
                }
                if (!conditions.isEmpty()) {
                    if(NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionInsertFields)) {
                        List<Database.SaveResult> results = Database.insert(conditions, false);
                        nb.logResults(results, conditions);
                    }
                }
            }
        } catch(DMLException e) {
            nb.logError(e);
            Database.rollback(sp);
        }
        nb.incrementBatchIndex();
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        String countryName = 'N/A';
        try {
            if(countryId != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :countryId LIMIT 1].Name;
        } catch(DmlException e) {
            e.getDMLMessage(0);
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    /* Class WrapperContract */
    public class WrapperContract {
        
        public String key {get;set;}
        public Contract__c duplicatedContract {get; set;}
        public Contract__c simulationContract {get; set;}
        
        public WrapperContract(String s) {
            this.key = s;
        }
        // Set duplicated or simulation contracts
        // Return message if more than record found for the same type according to the key
        private String push(Contract__c contract) {
            String message;
            if(contract.Contract_Type__c == 'Contract') {
                if(this.duplicatedContract == null)
                    this.duplicatedContract = contract;
                else message = 'MULTIPLE DUPLICATE CONTRACTS FOUND';
            }
            if(contract.Contract_Type__c == 'Simulation') {
                if(this.simulationContract == null)
                    this.simulationContract = contract;
                else message = 'MULTIPLE SIMULATION CONTRACTS FOUND';
            }
            return message;
        }
        // Merge Contracts
        private void doMerge() {
            // Case 0: ERROR CASE
            if(this.duplicatedContract != null &&  this.simulationContract == null) {
                this.duplicatedContract = null;
            }
            // Case 1: normal case, duplicated and simulation found
            if(this.duplicatedContract != null && this.simulationContract != null) {
                /***
                // TOs assignment.
                this.duplicatedContract.TO1__c = this.simulationContract.TO1__c;
                this.duplicatedContract.TO2__c = this.simulationContract.TO2__c;
                this.duplicatedContract.TO3__c = this.simulationContract.TO3__c;
                this.duplicatedContract.TO4__c = this.simulationContract.TO4__c;
                this.duplicatedContract.TO5__c = this.simulationContract.TO5__c;
                this.duplicatedContract.TO6__c = this.simulationContract.TO6__c;
                this.duplicatedContract.TO7__c = this.simulationContract.TO7__c;
                this.duplicatedContract.TO8__c = this.simulationContract.TO8__c;
                this.duplicatedContract.TO9__c = this.simulationContract.TO9__c;
                this.duplicatedContract.TO10__c = this.simulationContract.TO10__c;
                this.duplicatedContract.TO11__c = this.simulationContract.TO11__c;
                this.duplicatedContract.TO12__c = this.simulationContract.TO12__c;
                // Qty assignment.
                this.duplicatedContract.Qty1__c = this.simulationContract.Qty1__c;
                this.duplicatedContract.Qty2__c = this.simulationContract.Qty2__c;
                this.duplicatedContract.Qty3__c = this.simulationContract.Qty3__c;
                this.duplicatedContract.Qty4__c = this.simulationContract.Qty4__c;
                this.duplicatedContract.Qty5__c = this.simulationContract.Qty5__c;
                this.duplicatedContract.Qty6__c = this.simulationContract.Qty6__c;
                this.duplicatedContract.Qty7__c = this.simulationContract.Qty7__c;
                this.duplicatedContract.Qty8__c = this.simulationContract.Qty8__c;
                this.duplicatedContract.Qty9__c = this.simulationContract.Qty9__c;
                this.duplicatedContract.Qty10__c = this.simulationContract.Qty10__c;
                this.duplicatedContract.Qty11__c = this.simulationContract.Qty11__c;
                this.duplicatedContract.Qty12__c = this.simulationContract.Qty12__c;
                ***/
                this.duplicatedContract.Total_TO_Ref__c = this.simulationContract.Total_TO_Ref__c;
                this.duplicatedContract.Secure_Multiyear__c = this.simulationContract.Secure_Multiyear__c;
                this.duplicatedContract.D_N__c = 'N';
                this.duplicatedContract.Status__c = 'Signed';
                
                // Change Status of simulation to Merged
                this.simulationContract.Status__c = 'Merged';
            }
            // Case 2: no duplication found
            if(this.duplicatedContract == null && this.simulationContract != null) {
                this.simulationContract.Name = 'Contract ' + simulationContract.Contract_BDate__c.year() + ' (Merged)';
                this.simulationContract.Contract_Type__c = 'Contract';
                this.simulationContract.D_N__c = 'N';
                this.simulationContract.Status__c = 'Signed';
                this.simulationContract.Contract_Numbder__c = null; // to generate new number
            }
        }
    }
    
    /* Wrapper class for duplicated conditions + simulation conditions. */
    public class WrapperCondition {
        
        public List<Contract_Discount__c> conditionsD {get;set;}
        public List<Contract_Discount__c> conditionsS {get;set;}
        
        public WrapperCondition() {
            conditionsD = new List<Contract_Discount__c>();
            conditionsS = new List<Contract_Discount__c>();
        }
    }
}