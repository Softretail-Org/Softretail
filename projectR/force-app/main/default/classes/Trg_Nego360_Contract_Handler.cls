public class Trg_Nego360_Contract_Handler {
    
    public static void OnAfterInsert(List<Contract__c> nContracts) {
        checkForeignSupplier(nContracts);
        // Assign the Sales Condition Exception of the Parent Contract (if exist) to the current contract.
        assignSalesConditionException(nContracts);
    }
    
    public static void OnAfterUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        assignBaseTOs(nContracts, oContractMap);
        // Reset GRC rates to 0 when NS of contracts is changed
        resetGRCIndexRates(nContracts, oContractMap);
        // update NS conditions added manually
        updateNSConditions(nContracts, oContractMap);
    }
    
    public static void OnAfterInsertOrUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // update sell in flow on insert/update contract
        updateSellinFlow(nContracts, oContractMap);
    }
    
    public static void OnBeforeInsert(List<Contract__c> nContracts) {
        setContractNameAndNumber(nContracts);
        assignSupCurrencyISOCode(nContracts);
        assignStockOwner(nContracts);
    }
    
    public static void OnBeforeUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        validateDates(nContracts, oContractMap);
    }
    
    public static void OnBeforeInsertOrUpdate(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        validatePeriods(nContracts, oContractMap);
        assignFromConditionSale(nContracts, oContractMap);
    }
    
    public static void OnBeforeDelete(Map<Id, Contract__c> oContractMap) {
        reparentingSellin(oContractMap);
    }
    /**
     * Generate Contract Name and Number (if empty)
     * @param nContracts:  new contracts list
     * On Before Insert
     **/
    private static void setContractNameAndNumber(List<Contract__c> nContracts) {
        // Loop over new contracts to find the number prefixes
        Integer count = 0, max;
        Map<String, Integer> contractsNumberPrefixMap = new Map<String, Integer>();
        // Push distinct prefixes in a map
        for (Contract__c item : nContracts) {
            String key = item.Contract_Number_Prefix__c;
            if (String.isNotBlank(key) && !contractsNumberPrefixMap.containsKey(key)) {
                contractsNumberPrefixMap.put(key, 1);
            }
        }
        // Loop over prefixes to find the correponding max counter.
        for(String s : contractsNumberPrefixMap.keySet()) {
            String query = 'SELECT Contract_Numbder__c, Autonum__c FROM Contract__c WHERE Contract_Number_Prefix__c = \'' + String.escapeSingleQuotes(s) + '\' AND Autonum__c <> null ORDER BY Autonum__c DESC LIMIT 1';
            List<Contract__c> contracts = Database.query(query);
            if(!contracts.isEmpty() && contracts.get(0).Contract_Numbder__c != null) {
                max = Integer.valueOf(String.valueOf(contracts.get(0).Autonum__c));
                contractsNumberPrefixMap.put(s, max + 1);
            }
        }
        for(Contract__c item : nContracts) {
            // Set an auto contract number based on the max for each prefix
            if(item.Contract_Numbder__c == null) {
                count = contractsNumberPrefixMap.get(item.Contract_Number_Prefix__c);
                if(item.Linked_Contract_Group__c == null) {
                    item.Name = item.Contract_Name_Prefix__c + '-' + count;
                }
                item.Contract_Numbder__c = item.Contract_Number_Prefix__c + count;
                item.Autonum__c = count;
                // Increment the counter and update related value in the map.
                count++;
                contractsNumberPrefixMap.put(item.Contract_Number_Prefix__c, count);
            }
        }
        // Loop over prefixes to find the correponding max counter
        /*for (String s : contractsNumberPrefixMap.keySet()) {
            String query = 'SELECT Contract_Numbder__c FROM Contract__c WHERE Contract_Numbder__c LIKE \'' + String.escapeSingleQuotes(s) + '%\' ORDER BY CreatedDate DESC LIMIT 1';
            List<Contract__c> contracts = Database.query(query);
            if(contracts != null && contracts.size() > 0 && contracts.get(0).Contract_Numbder__c != null) {
                String[] parts = String.valueOf(contracts.get(0).Contract_Numbder__c).split('-');
                if(parts != null && parts.size() > 1){
                    max = Integer.valueOf(parts[2]);
                    contractsNumberPrefixMap.put(s, max + 1);
                }
            }
        }
        for (Contract__c item : nContracts) {
            // Set an auto contract number based on the max for each prefix
            ////if (item.Contract_Type__c == 'Contract') {
            count = contractsNumberPrefixMap.get(item.Contract_Number_Prefix__c);
            // Override the name only on the creation from standard page
            // and not from the import because the field is required
            if(item.Linked_Contract_Group__c == null) {
                item.Name = item.Contract_Name_Prefix__c + '-' + count;
            }
            if(item.Contract_Numbder__c == null) {
                ////item.Contract_Numbder__c = item.Contract_Number_Prefix__c + '-' + string.valueof(count).leftPad(4, '0');
                item.Contract_Numbder__c = item.Contract_Number_Prefix__c + '-' + count;
                // Increment the counter and update related value in the map
                count++;
                contractsNumberPrefixMap.put(item.Contract_Number_Prefix__c, count);
            }
            ////}
        }*/
    }
    /**
     * Push only contracts with modified TO to the Map to fetch their conditions.
     * @param List<Contract__c>, Map<Id, Contract__c>
     * On After Update.
     **/
    private static void assignBaseTOs(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // Creation of a map <Contract Id, Contract>.
        Map<Id, Contract__c> contractsWithModifiedTO = new Map<Id, Contract__c>();
        for (Contract__c item : nContracts) {
            if (item.Total_TO__c != oContractMap.get(item.Id).Total_TO__c
	                || item.Total_TO_Fact__c != oContractMap.get(item.Id).Total_TO_Fact__c
	                || item.Total_TO_FX__c != oContractMap.get(item.Id).Total_TO_FX__c
	                || item.Total_Qty__c != oContractMap.get(item.Id).Total_Qty__c
	                || item.Total_Qty_Fact__c != oContractMap.get(item.Id).Total_Qty_Fact__c) {
                contractsWithModifiedTO.put(item.Id, item);
            }
        }
        if (contractsWithModifiedTO.size() > 0) {
            try {
                // check security on update payment group fields
                String[] conditionUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Base_TO_Nego__c'),
                    NegoptimHelper.normalizeAPIName('Base_TO_Actual__c'), NegoptimHelper.normalizeAPIName('Base_TO_Forecast__c'),
                    NegoptimHelper.normalizeAPIName('Base_TO_Actual_1__c'), NegoptimHelper.normalizeAPIName('Base_TO_Nego_1__c'),
                    NegoptimHelper.normalizeAPIName('Base_Quantity_Nego__c'), NegoptimHelper.normalizeAPIName('Base_Quantity_Actual__c')};
                
                if(NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionUpdateFields)) {
                    // Get all conditions related to the current contract and have Respects_Contract_Scope__c equal True.
                    List<Contract_Discount__c> conditionsToUpdate = new List<Contract_Discount__c>();
                    for (Contract_Discount__c condition : [SELECT Id, Contract__c
                                                           FROM Contract_Discount__c
                                                           WHERE Contract__c IN :contractsWithModifiedTO.keySet()
                                                           AND Respects_Contract_Scope__c = True])
                    {
                        condition.Base_TO_Nego__c = contractsWithModifiedTO.get(condition.Contract__c).Total_TO__c;
                        condition.Base_TO_Actual__c = contractsWithModifiedTO.get(condition.Contract__c).Total_TO_Fact__c;
                        condition.Base_TO_Forecast__c = contractsWithModifiedTO.get(condition.Contract__c).Total_TO_FX__c;
                        condition.Base_TO_Actual_1__c = contractsWithModifiedTO.get(condition.Contract__c).Total_TO_Fact_1__c;
                        condition.Base_TO_Nego_1__c = contractsWithModifiedTO.get(condition.Contract__c).Total_TO_Nego_1__c;
                        condition.Base_Quantity_Nego__c = contractsWithModifiedTO.get(condition.Contract__c).Total_Qty__c;
                        condition.Base_Quantity_Actual__c = contractsWithModifiedTO.get(condition.Contract__c).Total_Qty_Fact__c;
                        conditionsToUpdate.add(condition);
                    }
                    if(!conditionsToUpdate.isEmpty()) {
                        update conditionsToUpdate;
                    }
                }
            } catch(DmlException e) {
                for (Contract__c item : nContracts) {
                    item.addError(e.getDmlMessage(0));
                }            
            } catch(Exception e) {
                for (Contract__c item : nContracts) {
                    item.addError(e.getMessage());
                }
            }
        }
    }
    /**
     * Reset GRC rates to 0 when NS of contracts is changed
     * On After Update
     **/
    private static void resetGRCIndexRates(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
    	// Set of contract Ids with modified NS
        Set<Id> contractsWithModifiedNS = new Set<Id>();
        // Set of contract Ids with status deleted to be used in calculate GRC procedure
        Set<Id> deletedContractsIds = new Set<Id>();
        for (Contract__c item : nContracts) {
            if (item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c) {
            	contractsWithModifiedNS.add(item.Id);
            }
            // collect Ids of contracts to Run Calculate GRC if Status__c = Deleted
            if (item.Status__c != oContractMap.get(item.Id).Status__c && item.Status__c == 'Deleted') {
                deletedContractsIds.add(item.Id);
            }
        }
        // Reset GRC rates
        if (contractsWithModifiedNS.size() > 0) {
        	List<GRC_Contract__c> GRCToUpdate = new List<GRC_Contract__c>();
            for (GRC_Contract__c item : [SELECT Discount_N_1__c, Discount_N__c, Rebates_N_1__c, Rebates_N__c,
                                         Fees_N_1__c, Fees_N__c, Others_N_1__c, Others_N__c, Net4_N_1__c, Net4_N__c,
                                         Promo_N_1__c, Promo_N__c, Opening_N_1__c, Opening_N__c
                                         FROM GRC_Contract__c
                                         WHERE Contract__c IN :contractsWithModifiedNS])
            {
                item.Discount_N_1__c = item.Discount_N__c;
                item.Discount_N__c = 0;
                item.Rebates_N_1__c = item.Rebates_N__c;
                item.Rebates_N__c = 0;
                item.Fees_N_1__c = item.Fees_N__c;
                item.Fees_N__c = 0;
                item.Others_N_1__c = item.Others_N__c;
                item.Others_N__c = 0;
                item.Net4_N_1__c = item.Net4_N__c;
                item.Net4_N__c = 0;
                item.Promo_N_1__c = item.Promo_N__c;
                item.Promo_N__c = 0;
                item.Opening_N_1__c = item.Opening_N__c;
                item.Opening_N__c = 0;
                GRCToUpdate.add(item);
            }
            try {
                String[] grcContractFields = new String[] {NegoptimHelper.normalizeAPIName('Discount_N_1__c'),
                    NegoptimHelper.normalizeAPIName('Discount_N__c'), NegoptimHelper.normalizeAPIName('Rebates_N_1__c'),
                    NegoptimHelper.normalizeAPIName('Rebates_N__c'), NegoptimHelper.normalizeAPIName('Fees_N_1__c'),
                    NegoptimHelper.normalizeAPIName('Fees_N__c'), NegoptimHelper.normalizeAPIName('Others_N_1__c'),
                    NegoptimHelper.normalizeAPIName('Others_N__c'), NegoptimHelper.normalizeAPIName('Net4_N_1__c'),
                    NegoptimHelper.normalizeAPIName('Net4_N__c'), NegoptimHelper.normalizeAPIName('Promo_N_1__c'),
                    NegoptimHelper.normalizeAPIName('Promo_N__c'), NegoptimHelper.normalizeAPIName('Opening_N_1__c'),
                    NegoptimHelper.normalizeAPIName('Opening_N__c')};
                
                if(!GRCToUpdate.isEmpty()) {
                    if (NegoptimHelper.checkUpdatibility(GRC_Contract__c.SObjectType, grcContractFields)) {
                        update GRCToUpdate;
                    }
                }
            } catch(DmlException e) {
    	   		for (Contract__c item : nContracts) {
    	   			item.addError(e.getDmlMessage(0));
    	   		}
            }
        }
        // Recalculate GRC rates
        if (!deletedContractsIds.isEmpty() && !System.isBatch()) {
            Database.executeBatch(new GenerateGRCRatesBatch('Trg_Nego360_Contract_Handler', null, new List<Id>(deletedContractsIds), null, null));
        }
    }
    /**
     * update NS of conditions not added by integration of contract group when NS of contracts is changed
     * @param List<Contract__c>, Map<Id, Contract__c> oContractMap
     * On After Update.
     **/
    private static void updateNSConditions(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // Set of contract Ids with modified NS
        Set<Id> contractsWithModifiedNS = new Set<Id>();
        for (Contract__c item : nContracts) {
            // get list of contract linked to contract group
            if (item.Linked_contract_group__c != null && item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c) {
                contractsWithModifiedNS.add(item.Id);
            }
        }
        if (!contractsWithModifiedNS.isEmpty()) {
            Map<Id, List<Contract_Discount__c>>  contractConditionsMap = new Map<Id, List<Contract_Discount__c>>();
            // Get related conditions added manualy
            List<Contract_Discount__c> conditionsList = [SELECT Disc_BDate__c, Disc_EDate__c, Contract__c
                                                         FROM Contract_Discount__c
                                                         WHERE Contract__c IN :contractsWithModifiedNS
                                                         AND Linked_Condition_Group__c = NULL];
            for (Contract_Discount__c item : conditionsList) {
                if (contractConditionsMap.containsKey(item.Contract__c)) {
                    contractConditionsMap.get(item.Contract__c).add(item);
                } else {
                    contractConditionsMap.put(item.Contract__c, new List<Contract_Discount__c> {item});
                }
            }
            if(contractConditionsMap.size() > 0) {
                for (Contract__c item : nContracts) {
                    if (contractConditionsMap.containsKey(item.Id)) {
                        List<Contract_Discount__c> contractConditions = contractConditionsMap.get(item.Id);
                        for (Contract_Discount__c condition : contractConditions) {
                            condition.Product_Scope__c = item.Supplier_Nego_Scope__c;
                        }
                    }
                }
                try {
                    
                // check security on update payment group fields
                String[] conditionUpdateFields = new String[] {NegoptimHelper.normalizeAPIName('Product_Scope__c')};
                    
                if(!conditionsList.isEmpty()) {
                    if(NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionUpdateFields)) {
                        update conditionsList;
                    }
                }
                } catch(DmlException e) {
                    for (Contract__c item : nContracts) {
                        item.addError(e.getDmlMessage(0));
                    }
                }
            }
        }
    }
    /**
     * Assign the supplier currency ISO code into the contract currency ISO code. Single/Bulk
     * @param List<Contract__c>
     * On Before Insert.
     **/
    private static void assignSupCurrencyISOCode(List<Contract__c> nContracts) {
    	Map<Id, String> supplierCurrencyMap = new Map<Id, String>();
    	Set<Id> supplierIds = new Set<Id>();
    	for (Contract__c c : nContracts) {
        	supplierIds.add(c.Supplier__c);
        }
    	for (Sup_Supplier__c sup : [SELECT Id, CurrencyIsoCode
        							FROM Sup_Supplier__c
        							WHERE Id IN :supplierIds]) {
        	supplierCurrencyMap.put(sup.Id, sup.CurrencyIsoCode);
        }
        // Assignment.
    	for (Contract__c c : nContracts) {
			c.CurrencyIsoCode = supplierCurrencyMap.get(c.Supplier__c);
    	}
    }
    
    /**
     * Validate contract date range with its conditions date range on modification.
     * @param List<Contract__c>, Map<Id, Contract__c> oContractMap
     * On Before Update.
     **/
    private static void validateDates(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
    	Set<Id> contractIdSet = new Set<Id>();
        for (Contract__c item : nContracts) {
            if (item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c || item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c) {
                contractIdSet.add(item.Id);
            }
        }
        if (contractIdSet.size() > 0) {
            Map<Id, List<Contract_Discount__c>>  contractConditionsMap = new Map<Id, List<Contract_Discount__c>>();
            // Get related conditions for only contracts with modified dates
            List<Contract_Discount__c> conditionsList = [SELECT Disc_BDate__c, Disc_EDate__c, Contract__c
                                                         FROM Contract_Discount__c
                                                         WHERE Contract__c IN :contractIdSet];
            for (Contract_Discount__c item : conditionsList) {
                if (contractConditionsMap.containsKey(item.Contract__c)) {
                    contractConditionsMap.get(item.Contract__c).add(item);
                } else {
                    contractConditionsMap.put(item.Contract__c, new List<Contract_Discount__c> {item});
                }
            }
            // Check if date conditions conflict with contract dates
            for (Contract__c item : nContracts) {
                if (contractConditionsMap.containsKey(item.Id)) {
                    List<Contract_Discount__c> contractConditions = contractConditionsMap.get(item.Id);
                    for (Contract_Discount__c condition : contractConditions) {
                        if (item.Contract_BDate__c > condition.Disc_BDate__c || item.Contract_EDate__c < condition.Disc_EDate__c) {
                            item.addError(string.format(Label.MSG_Wrong_Date_Range,new String[]{condition.Id}));
                            break; // Leave the loop on first conflict
                        }
                    }
                }
            }
        }
    }
    
	/**
	 * Validate Only one Target per NS for the period.
	 * Validate Only one Contract per NS for the period.
	 * Validte of contract dates that should respect contract periodicity.
     * @param List<Contract__c>, Map<Id, Contract__c> oContractMap.
     * On Before Insert Or Update.
     **/
    private static void validatePeriods(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
    	// Local variable declaration.
        Set<Id> NSIdSet = new Set<Id>();
        Set<String> conTypeSet = new Set<String>();
        // List of contract based on negoscope id, contract types and different from current contracts ids
        List<Contract__c> existingContractsList = new List<Contract__c>();
        for (Contract__c item : nContracts) {
            if(item.Id == null || (item.Id != null &&
                                   (item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c ||
                                    item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c ||
                                    item.Contract_Type__c != oContractMap.get(item.Id).Contract_Type__c ||
                                    item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c ||
                                    item.Contract_BU__c != oContractMap.get(item.Id).Contract_BU__c)))
            {
                NSIdSet.add(item.Supplier_Nego_Scope__c);
                conTypeSet.add(item.Contract_Type__c);
            }
            // Set SimulationNumber__c to null if type is Contract
            if (item.Contract_Type__c == 'Contract') {
                item.SimulationNumber__c = null;
            }
            // Set Last_Active_Contract__c to false if Status__c = Deleted
            if (item.Status__c == 'Deleted') {
                item.Last_Active_Contract__c = false;
            }
        }
        // There are a contracts to be checked in creation mode or update with change of date fields
        if(NSIdSet.size() > 0) {
            existingContractsList = [SELECT Id, Contract_BDate__c, Contract_EDate__c, Contract_Numbder__c, Contract_Type__c,
                                     Supplier__c, Supplier_Nego_Scope__c, Contract_BU__c
                                     FROM Contract__c
                                     WHERE Supplier_Nego_Scope__c IN :NSIdSet
                                     AND Contract_Type__c IN :conTypeSet
                                     AND Status__c <> 'Deleted'
                                     AND Id NOT IN :nContracts]; // used in case of update to not fetch itself
            Date bDate, eDate;
            Boolean isExist;
            Integer duration;
            Boolean isPeriodic = true;
            Boolean validateOveralpOnBULevel = false;
            try {
               NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
               validateOveralpOnBULevel = settings.datesOverlapControlBU;
            } catch (Exception e) {
                
            }
             
            for (Contract__c Con : nContracts) {
                bDate = Con.Contract_BDate__c;
                eDate = Con.Contract_EDate__c;
                duration = Con.Duration__c.intValue();
                isExist = false;
                if (bDate < eDate) {
                    // We do validation only on 2 types of contract : target and contract
                    if (Con.Contract_Type__c != 'Simulation') {
                    	Id existingContractId;
                        for (Contract__c contractObject : existingContractsList) {
                			if (((contractObject.Contract_BDate__c <= bDate && contractObject.Contract_EDate__c >= bDate)
                         		|| (contractObject.Contract_BDate__c <= eDate && contractObject.Contract_EDate__c >= eDate)
                             	|| (contractObject.Contract_BDate__c >= bDate && contractObject.Contract_EDate__c <= eDate))
                        		&& contractObject.Contract_Type__c == Con.Contract_Type__c && contractObject.Supplier__c == Con.Supplier__c
                            	&& contractObject.Supplier_Nego_Scope__c == Con.Supplier_Nego_Scope__c)
                            {
                                if (validateOveralpOnBULevel) {
                                    if (contractObject.Contract_BU__c == Con.Contract_BU__c) {
                                        isExist = true;
                                        existingContractId = contractObject.Id;
                                        break;
                                    }
                                } else {
                                    isExist = true;
                                    existingContractId = contractObject.Id;
                                    break;
                                }
                            }
                        }
                        if (isExist == true) Con.addError(System.Label.MSG_Contract_Exist_Same_Period + ' - ('+existingContractId+')');
                    }
                    // Contract dates should respect contract periodicity
                    Double daysDiff = bDate.daysBetween(eDate);
                    Integer monthDiff = bDate.monthsBetween(eDate) + 1;
                    Integer WeekDiff = Math.ceil(daysDiff/7).intValue();
                    Integer currentDuration;
                    if (Con.Duration_type__c == 'Month' && duration != monthDiff) {
                        isPeriodic = false;
                        currentDuration = monthDiff;
                    }
                    if (Con.Duration_type__c == 'Week' && duration != WeekDiff) {
                        isPeriodic = false;
                        currentDuration = WeekDiff;
                    }
                    if (isPeriodic == false) {
                        // force set of duration field
                    	Con.Duration__c = currentDuration;
                    	////Con.addError(System.Label.MSG_Contract_Dates_should_Respect_Contract_Periodicity + ' ( ' + currentDuration + ' ' + Con.Duration_type__c + '(s) )' + ' - Contract Name: ' + Con.Name);
                    }
                }
            }
        }
    }
    
    /**
     * Assign from condition sale.
     * @param List<Contract__c>.
     * On Before Insert Or Update.
     **/
    private static void assignFromConditionSale(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        // TODO: NOT NECESSARY ON UPDATE
    	Set<Integer> years = new Set<Integer>();
        Set<Id> BUList = new Set<Id>();
        List<Id> contractIdsToUpdate = new List<Id>();
        // Collect bu and year of contract in list 
        for (Contract__c item : nContracts) {
            if (item.Id == null || (item.Id != null && (item.Reference_Year__c != oContractMap.get(item.Id).Reference_Year__c
                                                        || item.Contract_BU__c != oContractMap.get(item.Id).Contract_BU__c
                                                        || item.BU_Source__c != oContractMap.get(item.Id).BU_Source__c)))
                {
                    years.add(Integer.valueOf(item.Reference_Year__c));
                    if(item.Contract_BU__c != null)
                    	BUList.add(item.Contract_BU__c);
                    if(item.BU_Source__c != null)
                    	BUList.add(item.BU_Source__c);
                    if(item.Id != null)
                        contractIdsToUpdate.add(item.Id);
                }
        }
        // Get conditions sales exeption for all contract
        Map<Id, Pol_Sale_Condition_Exception__c> mapContractCondEx = new Map<Id, Pol_Sale_Condition_Exception__c>();
        if(contractIdsToUpdate.size() > 0) {
            for (Pol_Sale_Condition_Exception__c item : [SELECT Id, Contract__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                                         Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c
                                                         FROM Pol_Sale_Condition_Exception__c
                                                         WHERE Contract__c IN :contractIdsToUpdate]) {
                // push in map by contract id as key
                mapContractCondEx.put(item.Contract__c, item);                                         
            }
        }
        // Get Pol_Sale_Condition__c for all contract
        Map<String, Pol_Sale_Condition__c> salesConditionsMap = new Map<String, Pol_Sale_Condition__c>();
        for(Pol_Sale_Condition__c item : [SELECT Id, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                          Status_BDate__c, Master_BU__c, Buying_Payment_Term_Abbrev__c, Services_Payment_Term_Abbrev__c
                                          FROM Pol_Sale_Condition__c
                                          WHERE CALENDAR_YEAR(Status_BDate__c) IN :years
                                          AND Master_BU__c IN :BUList]) {
            salesConditionsMap.put(item.Status_BDate__c.Year() + '' + item.Master_BU__c, item);
        }
        if (salesConditionsMap.size() > 0) {
            for (Contract__c Con : nContracts) {
                // Check if year and bu of contract and condition sales are matching to pass the value
                String key1 = Integer.valueOf(Con.Reference_Year__c ) + '' + Con.Contract_BU__c;
                String key2 = Integer.valueOf(Con.Reference_Year__c ) + '' + Con.BU_Source__c;
                String key = salesConditionsMap.containsKey(key1) ? key1 : salesConditionsMap.containsKey(key2) ? key2 : null;
                if (key != null && !mapContractCondEx.containsKey(Con.Id)) { //check if it has an execptionel sales condition
                    Pol_Sale_Condition__c condSales = salesConditionsMap.get(key);
                    Con.VAT_Rebate_Rate__c = condSales.VAT_Rebate_Rate__c;
                    Con.VAT_Service_Rate__c = condSales.VAT_Service_Rate__c;
                    Con.VAT_Finance_Rate__c = condSales.VAT_Finance_Rate__c;
                    Con.Buying_Payment_Term_Abbrev__c = condSales.Buying_Payment_Term_Abbrev__c;
                    Con.Services_Payment_Term_Abbrev__c = condSales.Services_Payment_Term_Abbrev__c;
                    Con.Default_Sales_Conditions__c = condSales.Id;
                } else if (mapContractCondEx.containsKey(Con.Id)) {
                    // update if there are Pol_Sale_Condition_Exception__c
                    Pol_Sale_Condition_Exception__c salesConditionException = mapContractCondEx.get(Con.Id);
                    Con.VAT_Rebate_Rate__c = salesConditionException.VAT_Rebate_Rate__c;
                    Con.VAT_Service_Rate__c = salesConditionException.VAT_Service_Rate__c;
                    Con.VAT_Finance_Rate__c = salesConditionException.VAT_Finance_Rate__c;
                    Con.Buying_Payment_Term_Abbrev__c = salesConditionException.Buying_Payment_Term_Abbrev__c;
                    Con.Services_Payment_Term_Abbrev__c = salesConditionException.Services_Payment_Term_Abbrev__c;
                }
            }
        }
    }
    
    /**
     * Create sales condition exception when is Foreign Supplier
     * @param List<Contract__c>.
     * On After Insert
     **/
    private static void checkForeignSupplier(List<Contract__c> nContracts) {
        Map<Id, Id> contractSalesConditionMap = new Map<Id, Id>();
        // Collect bu and year of contract in list 
        for (Contract__c item : nContracts) {
            if (item.Is_Foreign_Supplier__c) {
                contractSalesConditionMap.put(item.Id, item.Default_Sales_Conditions__c);
            }
        }
        if (contractSalesConditionMap.size() > 0) {
            Map<Id, Pol_Sale_Condition__c> salesConditionsMap = new Map<Id, Pol_Sale_Condition__c>([SELECT Id, Master_BU__c, Buying_Payment_Days__c, Buying_Payment_Condition__c,
                                                                                                    VAT_Service_Rate__c, VAT_Rebate_Rate__c, VAT_Finance_Rate__c, 
                                                                                                    Services_Payment_Type__c, Services_Payment_Days__c,
                                                                                                    Services_Payment_Condition__c, Return_Authorization1__c, Return_Agreement__c,
                                                                                                    Return_Agreement_Trans__c, Merchandiser_Authorization__c, Merchandiser_Agreement__c,
                                                                                                    Merchandiser_Agreement_Trans__c, Incoterms_definition__c, Delivery_Chain2_planning__c,
                                                                                                    Delivery_Chain2__c, Delivery_Chain2_MinOrder__c, Delivery_Chain2_MinOrder_Trans__c,
                                                                                                    Delivery_Chain2_Incoterm__c, Delivery_Chain2_Context__c, Delivery_Chain2_Context_Trans__c,
                                                                                                    Delivery_Chain1_planning__c, Delivery_Chain1__c, Delivery_Chain1_MinOrder__c,
                                                                                                    Delivery_Chain1_MinOrder_Trans__c, Delivery_Chain1_Incoterm__c, Delivery_Chain1_Context__c,
                                                                                                    Delivery_Chain1_Context_Trans__c
                                                                                                    FROM Pol_Sale_Condition__c
                                                                                                    WHERE Id IN : contractSalesConditionMap.values()
                                                                                                    AND Status__c = 'Validated']);
            // Get Record Type ID
            Id inExceptionRT = NegoptimHelper.getObjectRecordTypeId(Pol_Sale_Condition_Exception__c.SObjectType, 'In_Exception');
            // conditions sales exeption list to create
            List<Pol_Sale_Condition_Exception__c> salesConditionsExceptionList = new  List<Pol_Sale_Condition_Exception__c>();
            
            try {
                // check security on insert Pol_Sale_Condition_Exception__c fields
                String[] saleConditionExceptionFields = new String[] { 'RecordTypeId', NegoptimHelper.normalizeAPIName('Contract__c'),
                    NegoptimHelper.normalizeAPIName('VAT_Service_Rate__c'), NegoptimHelper.normalizeAPIName('VAT_Rebate_Rate__c'),
                    NegoptimHelper.normalizeAPIName('VAT_Finance_Rate__c'), NegoptimHelper.normalizeAPIName('Version__c'),
                    NegoptimHelper.normalizeAPIName('Policy_Sales_Conditions__c'), NegoptimHelper.normalizeAPIName('Buying_Payment_Days__c'),
                    NegoptimHelper.normalizeAPIName('Buying_Payment_Condition__c'), NegoptimHelper.normalizeAPIName('Services_Payment_Type__c'),
                    NegoptimHelper.normalizeAPIName('Services_Payment_Days__c'), NegoptimHelper.normalizeAPIName('Services_Payment_Condition__c'),
                    NegoptimHelper.normalizeAPIName('Return_Authorization1__c'), NegoptimHelper.normalizeAPIName('Return_Agreement__c'),
                    NegoptimHelper.normalizeAPIName('Return_Agreement_Trans__c'), NegoptimHelper.normalizeAPIName('Merchandiser_Authorization__c'),
                    NegoptimHelper.normalizeAPIName('Merchandiser_Agreement__c'), NegoptimHelper.normalizeAPIName('Merchandiser_Agreement_Trans__c'),
                    NegoptimHelper.normalizeAPIName('Incoterms_definition__c'), NegoptimHelper.normalizeAPIName('Delivery_Chain2_planning__c'),
                    NegoptimHelper.normalizeAPIName('Delivery_Chain2__c'), NegoptimHelper.normalizeAPIName('Delivery_Chain2_MinOrder__c'),
                    NegoptimHelper.normalizeAPIName('Delivery_Chain2_MinOrder_Trans__c'), NegoptimHelper.normalizeAPIName('Delivery_Chain2_Incoterm__c'),
                    NegoptimHelper.normalizeAPIName('Delivery_Chain2_Context__c'), NegoptimHelper.normalizeAPIName('Delivery_Chain2_Context_Trans__c'),
                    NegoptimHelper.normalizeAPIName('Delivery_Chain1_planning__c'), NegoptimHelper.normalizeAPIName('Delivery_Chain1__c'),
                    NegoptimHelper.normalizeAPIName('Delivery_Chain1_MinOrder__c'), NegoptimHelper.normalizeAPIName('Delivery_Chain1_Incoterm__c'), 
                    NegoptimHelper.normalizeAPIName('Delivery_Chain1_MinOrder_Trans__c'), NegoptimHelper.normalizeAPIName('Delivery_Chain1_Context_Trans__c'), 
                    NegoptimHelper.normalizeAPIName('Delivery_Chain1_Context__c')};

                if(NegoptimHelper.checkCreatibility(Pol_Sale_Condition_Exception__c.SObjectType, saleConditionExceptionFields)) {
                    for (Id item : contractSalesConditionMap.keySet()) {
                        Pol_Sale_Condition__c originSalesCondition = salesConditionsMap.get(contractSalesConditionMap.get(item));
                        Pol_Sale_Condition_Exception__c salesConditionException = new Pol_Sale_Condition_Exception__c(Contract__c = item, VAT_Service_Rate__c = 0, VAT_Rebate_Rate__c = 0,
                                                                                                                      VAT_Finance_Rate__c = 0, Version__c = 1, RecordTypeId = inExceptionRT);
                        
                        if(originSalesCondition != null) {
                            salesConditionException.Policy_Sales_Conditions__c = originSalesCondition.Id;
                            salesConditionException.Buying_Payment_Days__c = originSalesCondition.Buying_Payment_Days__c;
                            salesConditionException.Buying_Payment_Condition__c = originSalesCondition.Buying_Payment_Condition__c;
                            salesConditionException.Services_Payment_Type__c = originSalesCondition.Services_Payment_Type__c;
                            salesConditionException.Services_Payment_Days__c = originSalesCondition.Services_Payment_Days__c;
                            salesConditionException.Services_Payment_Condition__c = originSalesCondition.Services_Payment_Condition__c;
                            salesConditionException.Return_Authorization1__c = originSalesCondition.Return_Authorization1__c;
                            salesConditionException.Return_Agreement__c = originSalesCondition.Return_Agreement__c;
                            salesConditionException.Return_Agreement_Trans__c = originSalesCondition.Return_Agreement_Trans__c;
                            salesConditionException.Merchandiser_Authorization__c = originSalesCondition.Merchandiser_Authorization__c;
                            salesConditionException.Merchandiser_Agreement__c = originSalesCondition.Merchandiser_Agreement__c;
                            salesConditionException.Merchandiser_Agreement_Trans__c = originSalesCondition.Merchandiser_Agreement_Trans__c;
                            salesConditionException.Incoterms_definition__c = originSalesCondition.Incoterms_definition__c;
                            salesConditionException.Delivery_Chain2_planning__c = originSalesCondition.Delivery_Chain2_planning__c;
                            salesConditionException.Delivery_Chain2__c = originSalesCondition.Delivery_Chain2__c;
                            salesConditionException.Delivery_Chain2_MinOrder__c = originSalesCondition.Delivery_Chain2_MinOrder__c;
                            salesConditionException.Delivery_Chain2_MinOrder_Trans__c = originSalesCondition.Delivery_Chain2_MinOrder_Trans__c;
                            salesConditionException.Delivery_Chain2_Incoterm__c = originSalesCondition.Delivery_Chain2_Incoterm__c;
                            salesConditionException.Delivery_Chain2_Context__c = originSalesCondition.Delivery_Chain2_Context__c;
                            salesConditionException.Delivery_Chain2_Context_Trans__c = originSalesCondition.Delivery_Chain2_Context_Trans__c;
                            salesConditionException.Delivery_Chain1_planning__c = originSalesCondition.Delivery_Chain1_planning__c;
                            salesConditionException.Delivery_Chain1__c = originSalesCondition.Delivery_Chain1__c;
                            salesConditionException.Delivery_Chain1_MinOrder__c = originSalesCondition.Delivery_Chain1_MinOrder__c;
                            salesConditionException.Delivery_Chain1_MinOrder_Trans__c = originSalesCondition.Delivery_Chain1_MinOrder_Trans__c;
                            salesConditionException.Delivery_Chain1_Incoterm__c = originSalesCondition.Delivery_Chain1_Incoterm__c;
                            salesConditionException.Delivery_Chain1_Context__c = originSalesCondition.Delivery_Chain1_Context__c;
                            salesConditionException.Delivery_Chain1_Context_Trans__c = originSalesCondition.Delivery_Chain1_Context_Trans__c;
                        }
                        salesConditionsExceptionList.add(salesConditionException);
                    }
                    // insert list
                    if(!salesConditionsExceptionList.isEmpty()){
                        insert salesConditionsExceptionList;
                    }
                }
            }  catch(DmlException e) {
                for (Contract__c item : nContracts) {
                    item.addError(e.getDmlMessage(0));
                }            
            } catch(Exception e) {
                for (Contract__c item : nContracts) {
                    item.addError(e.getMessage());
                }
            }
        }
    }
    
    /**
     * Assign the Sales Condition Exception of the Parent Contract (if exist) to the current contract.
     * @param List<Contract__c>.
     * On After Insert.
     **/
    private static void assignSalesConditionException(List<Contract__c> nContracts) {
    	// Map <Contract Parent Id, Contract Id>
    	Map<Id, List<Id>> cMap = new Map<Id, List<Id>>();
    	// Map <Contract Parent Id, Sale Condition Exception>
    	Map<Id, Pol_Sale_Condition_Exception__c> cParentMap = new Map<Id, Pol_Sale_Condition_Exception__c>();
    	// Collect the contracts having a parent and fill the list of parent Ids.
        for (Contract__c c : nContracts) {
        	if (c.Is_Foreign_Supplier__c && c.Parent_Contract__c != Null) {
    			if (!cMap.containsKey(c.Parent_Contract__c)) {
        			cMap.put(c.Parent_Contract__c, new List<Id>{c.Id});
        		} else {
        			cMap.get(c.Parent_Contract__c).add(c.Id);
        		}
        	}
        }
        if (cMap.size() > 0) {
        	// Iterate over the list of Sale Condition Exception related to the corresponding parent Contracts, and fill the map.
	        for (Pol_Sale_Condition_Exception__c item : [SELECT Id, Contract__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
						Buying_Payment_Days__c, Buying_Payment_Condition__c, Services_Payment_Days__c, Services_Payment_Condition__c,
						Payment_term_exc1_section__c, Payment_term_exc2_section__c, Buying_Payment_Term_Abbrev_Exc1__c,
						Buying_Payment_Condition_exc1__c, Buying_Payment_Term_Abbrev_Exc2__c, Buying_Payment_Condition_exc2__c
						FROM Pol_Sale_Condition_Exception__c
						WHERE Contract__c = :cMap.keySet()]) {
				cParentMap.put(item.Id, item);
			}
	        Pol_Sale_Condition_Exception__c clonedSCE;
	        List<Pol_Sale_Condition_Exception__c> toInsert = new List<Pol_Sale_Condition_Exception__c>();
	        // Allocation + Fill the list of Sale Condition Exception to insert.
	        for (Id cParent : cParentMap.keySet()) {
	        	for (Id cId : cMap.get(cParentMap.get(cParent).Contract__c)) {
	        		clonedSCE = cParentMap.get(cParent).clone(false, true, true, false);
	        		clonedSCE.Contract__c = cId;
	        		toInsert.add(clonedSCE);
	        	}
	        }
            
            String[] salesConditionExceptionFields = new String []{ NegoptimHelper.normalizeAPIName('Contract__c') };
            if (!toInsert.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(Pol_Sale_Condition_Exception__c.SObjectType, salesConditionExceptionFields)) {
                    insert toInsert;
                }
            }
        }
    }
    
    /**
     * fill sell in line to be updated with contract value
     * On After Insert/Update
     **/
    private static void updateSellinFlow(List<Contract__c> nContracts, Map<Id, Contract__c> oContractMap) {
        List<Contract__c> newContracts = new List<Contract__c>();
        List<Contract__c> updatedContracts = new List<Contract__c>();
        Set<Id> businessUnitsSet = new Set<Id>();
        for (Contract__c item : nContracts) {
            if(item.Reference_Year__c != null && item.Supplier__c != null && item.BU_Source__c != null && item.Contract_BU__c != null &&
               item.Supplier_Nego_Scope__c != null && item.Contract_BDate__c != null && item.Contract_EDate__c != null)
            {
                // case update contract
                if(oContractMap != null && (item.Supplier_Nego_Scope__c != oContractMap.get(item.Id).Supplier_Nego_Scope__c ||
                                            item.Contract_BU__c != oContractMap.get(item.Id).Contract_BU__c ||
                                            item.BU_Source__c != oContractMap.get(item.Id).BU_Source__c ||
                                            item.Contract_BDate__c != oContractMap.get(item.Id).Contract_BDate__c ||
                                            item.Contract_EDate__c != oContractMap.get(item.Id).Contract_EDate__c))
                {
                    updatedContracts.add(item);
                }
                // case insert contract
                if(oContractMap == null){
                    newContracts.add(item);
                }
                
                if(!businessUnitsSet.contains(item.Contract_BU__c)) {
                    businessUnitsSet.add(item.Contract_BU__c);
                }
            }
        }
        if((newContracts.size() > 0 || updatedContracts.size() > 0) && !System.isBatch()) {
            // Load Map of BUs
            Map<Id, Set<Id>> businessUnitsMap = NegoptimHelper.getBUChildrenMap(businessUnitsSet);
            Database.executeBatch(new ReparentingSellinBatch('After Insert/Update Contract', newContracts, updatedContracts, null, 
                                                             businessUnitsMap, null, null, null, null, false, null, null));
        }
    }
    /**
     * Check if the contracts deleted is linked to sell_in_flow
     * @param List<Contract__c>.
     * On Before Delete
     **/
    private static void reparentingSellin(Map<Id, Contract__c> oContractMap) {
        // Map contract and sell in count
        Map<Id, AggregateResult> contractWithSellinCount = new Map<Id, AggregateResult>([SELECT Contract__c Id, COUNT(Id) c
                                                                                         FROM Sell_in_Flow__c
                                                                                         WHERE Contract__c IN :oContractMap.KeySet()
                                                                                         GROUP BY Contract__c]);
        for (Contract__c item : oContractMap.values()) {
            AggregateResult result = contractWithSellinCount.get(item.Id);
            if(result != null){
                Integer sellinCount = Integer.valueOf(result.get('c'));
                if(sellinCount > 0) {
                    item.Name.addError('This contract have linked to Sell in Flow.');
                }
            }
        }
    }
    /**
     * Assign stock owner BU to contracts 
     * @param List<Contract__c>.
     * On Before Insert
     **/
    private static void assignStockOwner(List<Contract__c> nContracts) {
        Set<Id> NSIdSet = new Set<Id>();
        for (Contract__c item : nContracts) {
            if(item.Stock_Owner__c == null) {
                NSIdSet.add(item.Supplier_Nego_Scope__c);
            }
        }
        if(!NSIdSet.isEmpty()) {
            Map<Id, Sup_sup_NegoScope__c> negoScopesMap =  new Map<Id, Sup_sup_NegoScope__c>([SELECT Id, Stock_Owner__c 
                                                                                              FROM Sup_sup_NegoScope__c
                                                                                              WHERE Id IN :NSIdSet]);
            for (Contract__c item : nContracts) {
                if(item.Stock_Owner__c == null) {
                    item.Stock_Owner__c = negoScopesMap.get(item.Supplier_Nego_Scope__c).Stock_Owner__c;
                }
            }
        }
    }
}