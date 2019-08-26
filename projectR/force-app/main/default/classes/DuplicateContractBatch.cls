/**
 * Batchable class used to duplicate contracts.
 * Works for single or multiple contract duplication procedure.
 **/
public with sharing class DuplicateContractBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final List<Id> contractIds;
    public final Integer year;
    // variables to use internally
	public Date targetBDate;
	public Date targetEDate;
	public String targetDN;
	public Boolean controlOnBULevel;
	
    // Constructor.
    public DuplicateContractBatch(String startedFrom, Id countryId, List<Id> cIds, Integer y, Date bDate, Date eDate, String dn) {
        nb = new NegoptimBatch('DuplicateContractBatch', NegoptimBatch.BatchType.stateful, startedFrom);
        country = countryId;
        contractIds = cIds;
        year = y;
        targetBDate = bDate;
        targetEDate = eDate;
        targetDN = dn;
        String q = 'SELECT c.Contract_BDate__c, c.Contract_BU__c, c.BU_Source__c, c.Contract_EDate__c, c.Contract_Numbder__c, c.Name, c.Id,';
        q += ' c.Contract_Type__c, c.CurrencyIsoCode, c.D_N__c, c.Duration__c, c.Duration_type__c, c.Parent_Contract__c, c.Status__c,';
        q += ' c.Supplier__c, c.Supplier_Nego_Scope__c, c.Tactite_reconduction__c, c.Total_TO_Ref__c, Supplier_Nego_Scope__r.Name, c.RecordTypeId,';
        q += ' c.TO1__c, c.TO2__c, c.TO3__c, c.TO4__c, c.TO5__c, c.TO6__c,';
        q += ' c.TO7__c, c.TO8__c, c.TO9__c, c.TO10__c, c.TO11__c, c.TO12__c,';
        q += ' c.Qty1__c, c.Qty2__c, c.Qty3__c, c.Qty4__c, c.Qty5__c, c.Qty6__c,';
        q += ' c.Qty7__c, c.Qty8__c, c.Qty9__c, c.Qty10__c, c.Qty11__c, c.Qty12__c, c.Reference_Year__c, c.Linked_Contract_Group__c,';
        q += ' (SELECT Id, all_BU__c, all_items__c, Base_Calculation_Model__c, CurrencyIsoCode,';
        q += ' comments__c, Y_Actu__c, YTD_Nego__c, Value_per_fact__c, Slab_Calc_Method_TO_Origin__c, Base_Redistribution_Model__c,';
        q += ' RecordTypeId, Prog_TO_Nego__c, Prog_TO_Actu__c, Maximum_Guarantee__c, Is_Prenego_Envelop__c, Invoicing_plan_generated__c,';
        q += ' BU_Scope__c, commercial_reference__c, Condition_Type__c, Contract__c, Contract_Group__c, Contract_Group_Reference__c,';
        q += ' Disc_BDate__c, Disc_EDate__c, financial_reference__c, first_invoice_date__c, Fist_Provision_Date__c, Invoice_base__c, Invoice_period__c,';
        q += ' Is_Conditional__c, is_duplicable__c, legal_reference__c, Minimum_Guarantee__c, Name, Nego_Discount_Type__c,';
        q += ' Payment_Condition__c, Payment_Days__c, Product_Scope__c, Provision_base__c, Provision_period__c, Provision_Sequence__c, Base_Quantity_Nego__c,';
        q += ' Value_amt_disp_M12__c, Value_amt_disp_M11__c, Value_amt_disp_M10__c, Value_amt_disp_M9__c, Value_amt_disp_M8__c, Value_amt_disp_M7__c,';
        q += ' Value_amt_disp_M6__c, Value_amt_disp_M5__c, Value_amt_disp_M4__c, Value_amt_disp_M3__c, Value_amt_disp_M2__c, Value_amt_disp_M1__c,';
        q += ' Rank__c, Reference_Contract__c, Slab_1__c, Slab_2__c, Slab_3__c, Slab_4__c, Slab_5__c, Slab_6__c, slab_calc_method__c,';
        q += ' slab_per_1__c, slab_per_2__c, slab_per_3__c, slab_per_4__c, slab_per_5__c, slab_per_6__c,';
        q += ' slab_target__c, Slab_Val_1__c, Slab_Val_2__c, Slab_Val_3__c, Slab_Val_4__c, Slab_Val_5__c, Slab_Val_6__c,';
        q += ' Status__c, Status_BDate__c, unit_amount__c, Valid__c, Value_per__c, Value_amt__c, Base_TO_Nego__c, Invoice_sequence__c';
        q += ' FROM Contract_Discounts__r WHERE is_duplicable__c = true';
        q += ' AND Product_Scope__r.Status__c = \'Active\' AND BU_Scope__r.Status__c = \'Open\')';
        q += ' FROM Contract__c c ';
        q += ' WHERE c.Status__c IN (\'Signed\', \'Balanced\') AND c.Supplier__r.Status__c = \'Active\' AND c.Supplier_Nego_Scope__r.Status__c = \'Active\' ';
        q += ' AND c.Contract_Type__c = \'Contract\' AND c.Tactite_reconduction__c = true ';
        /*q += ' AND c.Linked_Contract_Group__c = Null ';*/
        q += ' AND c.Contract_BU__r.Status__c = \'Open\'';
        if(country != null) {
            q += ' AND c.Contract_BU__c = \'' + country + '\'';
        }
        if(contractIds != null && contractIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(contractIds, '\',\'') +'\')';
        }
        if(year != null) {
            q += ' AND CALENDAR_YEAR(c.Contract_BDate__c) = ' + year + '';
        }
        // Set the final variable.
        query = q;
        
        nb.logParameter('country', country);
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('year', year);
        nb.logParameter('targetBDate', targetBDate);
        nb.logParameter('targetEDate', targetEDate);
        nb.logParameter('targetDN', targetDN);
        nb.logParameter('query', query);
        // load settings
        try {
    		NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
    		controlOnBULevel = settings.datesOverlapControlBU;
    	} catch (Exception e) {
    		nb.logError(e);
    	}
    }
	// Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method.
    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        Map<Id, Contract__c> contractsMap = new Map<Id, Contract__c>();
        // Map parent contract Id to their exsisting contracts
        Map<Id, List<Contract__c>> duplicatedContractMap = new Map<Id, List<Contract__c>>();
        Set<Integer> years = new Set<Integer>();
        Set<Id> suppliersIdSet = new Set<Id>();
        Set<Id> NSsIdSet = new Set<Id>();
        for (Contract__c contract : scope) {
            contractsMap.put(contract.Id, contract);
            suppliersIdSet.add(contract.Supplier__c);
            NSsIdSet.add(contract.Supplier_Nego_Scope__c);
            Date cBD = targetBDate == null ? contract.Contract_EDate__c.addDays(1) : targetBDate;
            years.add(cBD.year());
        }
        // Get all contract already duplicated.
        for(Contract__c item : [SELECT Parent_Contract__c, Contract_BDate__c, Contract_EDate__c, Contract_BU__c
                                FROM Contract__c
                                WHERE ((Parent_Contract__c IN :contractsMap.keySet() AND Contract_Type__c = 'Contract')
                                       OR (Contract_Type__c = 'Simulation' AND Status__c = 'Validated')
                                       OR (Contract_Type__c = 'Simulation' AND Status__c = 'Request for approval'))
                                AND Reference_Year__c IN :years
                                AND Supplier__c IN :suppliersIdSet
                                AND Supplier_Nego_Scope__c IN :NSsIdSet])
        {
            if(duplicatedContractMap.containsKey(item.Parent_Contract__c)) {
                duplicatedContractMap.get(item.Parent_Contract__c).add(item);
            }
            else {
                duplicatedContractMap.put(item.Parent_Contract__c, new List<Contract__c>{item});
            }
        }
        // Get count contracts per supplier
        /***
        Map<Id, Integer> totalContractBySupplierMap = new Map<Id, Integer>();
        AggregateResult[] groupedResults = [SELECT COUNT(Id) total, Supplier__c
                                            FROM Contract__c
                                            WHERE Supplier__c IN :suppliersIdSet
                                            AND Contract_Type__c = 'Contract'
                                            GROUP BY Supplier__c];
        for(AggregateResult ar : groupedResults) {
            if (ar.get('total') != null) {
                totalContractBySupplierMap.put((Id)ar.get('Supplier__c'), (Integer)ar.get('total'));
            }
        }
        ***/
        // List for duplicated to be insert.
        List<Contract__c> duplicatedContractList = new List<Contract__c>();
        // Map to put the conditions with the corresponding contract index to get Id after insertion.
        Map<Integer, List<Contract_Discount__c>> conditionsMap = new Map<Integer, List<Contract_Discount__c>>();
        Integer counter = 0;
        ////Integer countContract = [SELECT COUNT() FROM Contract__c WHERE Contract_Type__c = 'Contract'];
        Boolean isDuplicated;
        for(Contract__c item : scope) {
            Contract__c duplicatedContract = item.clone(false, true, true, false);
            duplicatedContract.Contract_BDate__c = targetBDate == null ? duplicatedContract.Contract_EDate__c.addDays(1) : targetBDate;
            duplicatedContract.Contract_EDate__c = targetEDate == null ? NegoptimHelper.getLastDayOfMonth(duplicatedContract.Contract_BDate__c.Year(), 12) : targetEDate;
            isDuplicated = false;
            // Check if contract have duplication for choosing dates
            if(duplicatedContractMap.containsKey(item.Id)) {
                for(Contract__c contract : duplicatedContractMap.get(item.Id)) {
                    if(((duplicatedContract.Contract_BDate__c <= contract.Contract_BDate__c && duplicatedContract.Contract_EDate__c >= contract.Contract_BDate__c)
                        || (duplicatedContract.Contract_BDate__c <= contract.Contract_EDate__c && duplicatedContract.Contract_EDate__c >= contract.Contract_EDate__c)
                        || (duplicatedContract.Contract_BDate__c >= contract.Contract_BDate__c && duplicatedContract.Contract_EDate__c <= contract.Contract_EDate__c)))
                    {
                        isDuplicated = true && (!controlOnBULevel || controlOnBULevel && duplicatedContract.Contract_BU__c == contract.Contract_BU__c);
                        // duplicate contract found => leave the loop
                        break;
                    }
                }
                if(isDuplicated == true) {
                    nb.logError('The Contract "' + item.Contract_Numbder__c + '" is already duplicated for the dates: ' + duplicatedContract.Contract_BDate__c + ' to ' + duplicatedContract.Contract_EDate__c);
                    // continue to next iteration
                    continue;
                }
            }
            duplicatedContract.Duration__c = duplicatedContract.Contract_EDate__c.month() - duplicatedContract.Contract_BDate__c.month() + 1;
            /***
            if(totalContractBySupplierMap.containsKey(item.Supplier__c)) {
                countContract = totalContractBySupplierMap.get(item.Supplier__c) + 1;
            }
            totalContractBySupplierMap.put(item.Supplier__c, countContract);
            ***/
            duplicatedContract.Name = null;// duplicatedContract.Supplier_Nego_Scope__r.Name + '-' + duplicatedContract.Contract_BDate__c.year() + '-' + + string.valueof(countContract).leftPad(4, '0');
            duplicatedContract.Contract_Numbder__c = null;// duplicatedContract.Contract_BDate__c.year() + '-CS-' + string.valueof(countContract).leftPad(4, '0');
            duplicatedContract.Status__c = 'Signed';
            duplicatedContract.Parent_Contract__c = item.Id;
            
            if (targetDN != Null) {
            	duplicatedContract.D_N__c = targetDN;
            } else {
            	if (duplicatedContract.D_N__c == 'N') {
            		duplicatedContract.D_N__c = 'D';
            	} else if (duplicatedContract.D_N__c == 'D') {
            		duplicatedContract.D_N__c = 'N';
            	} else {
            		// Default Value: N.
            		duplicatedContract.D_N__c = Null;
            	}
            }
            duplicatedContractList.add(duplicatedContract);
            // Get the conditions and Map modified fields.
            for(Contract_Discount__c condition : item.Contract_Discounts__r) {
                Contract_Discount__c newCondition = condition.clone(false, true, true, false);
                newCondition.Reference_condition__c = condition.Id;
                // Increment start and end dates.
                newCondition.Disc_BDate__c = targetBDate == null ? condition.Disc_EDate__c.addDays(1) : targetBDate;
                newCondition.Disc_EDate__c = targetEDate == null ? NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), 12) : targetEDate;
                if (newCondition.first_invoice_date__c != null) {
                    newCondition.first_invoice_date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
                }
                if (newCondition.Fist_Provision_Date__c != null) {
                    newCondition.Fist_Provision_Date__c = NegoptimHelper.getLastDayOfMonth(newCondition.Disc_BDate__c.Year(), newCondition.Disc_BDate__c.month());
                }
                newCondition.Status__c = 'Validated';
                // Push condition to the index of corresponding contract.
                if(!conditionsMap.containsKey(counter)) {
                    List<Contract_Discount__c> newconditionList = new List <Contract_Discount__c>();
                    newconditionList.add(newCondition);
                    conditionsMap.put(counter, newconditionList);
                }
                else {
                    conditionsMap.get(counter).add(newCondition);
                }
            }
            counter++;
        }
        Savepoint sp = Database.setSavepoint();
        try {
        	List<Database.SaveResult> results;
            String[] contractFields = new String[] {'Name', NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('D_N__c'), NegoptimHelper.normalizeAPIName('Parent_Contract__c'),
                NegoptimHelper.normalizeAPIName('Contract_Numbder__c'), NegoptimHelper.normalizeAPIName('Contract_BDate__c'),
                NegoptimHelper.normalizeAPIName('Contract_EDate__c')
                };
            if (NegoptimHelper.checkCreatibility(Contract__c.SObjectType, contractFields)) {
                results = Database.insert(duplicatedContractList, false);
                nb.logResults(results, duplicatedContractList);
                List<Contract_Discount__c> duplicatedConditionsList = new List<Contract_Discount__c>();
                for(Integer i : conditionsMap.keySet()) {
                    // The corresponding contract on index i.
                    Contract__c correspondingContract = duplicatedContractList.get(i);
                    for(Contract_Discount__c item : conditionsMap.get(i)) {
                        if(correspondingContract.Id != null) {
                            item.Contract__c = correspondingContract.Id;
                            duplicatedConditionsList.add(item);
                        }
                    }
                }
                String[] conFields = new String[] {NegoptimHelper.normalizeAPIName('Contract__c'), NegoptimHelper.normalizeAPIName('Disc_BDate__c'), NegoptimHelper.normalizeAPIName('first_invoice_date__c'), NegoptimHelper.normalizeAPIName('Fist_Provision_Date__c') };
                if(NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conFields)){
                    results = Database.insert(duplicatedConditionsList, false);
	                nb.logResults(results, duplicatedConditionsList);
                }
            }
        } catch(DMLException e) {
            Database.rollback(sp);
            nb.logError(e);
        }
        nb.incrementBatchIndex();
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        String countryName = 'N/A';
        try {
            if(country != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
            nb.logError(e);
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ this.year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}