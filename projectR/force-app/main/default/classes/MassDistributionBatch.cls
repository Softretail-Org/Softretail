public with sharing class MassDistributionBatch implements Database.batchable<String>, Database.Stateful {
    
    private NegoptimBatch nb;
    private Id selectedCountry;
    private String selectedYear;
    private String contentData;
    private Integer year;
    private Boolean isYearlyDistribution;
    
    public MassDistributionBatch(Id selectedCountry, String selectedYear, Blob contentData, Boolean isYearlyDistribution) {
        this(selectedCountry, selectedYear, contentData, isYearlyDistribution, 'itself');
    }
    
    public MassDistributionBatch(Id selectedCountry, String selectedYear, Blob contentData, Boolean isYearlyDistribution, String startedFrom) {
        this.selectedCountry = selectedCountry;
        this.contentData = contentData.toString(); //this.contentData = EncodingUtil.base64Encode(contentData);
        nb = new NegoptimBatch('Mass Distribution', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.year = Integer.valueof(selectedYear);
        this.isYearlyDistribution = isYearlyDistribution;
        nb.logParameter('selectedCountry', selectedCountry);
        nb.logParameter('year', selectedYear);
        nb.logParameter('isYearlyDistribuation', isYearlyDistribution);
    }
    
    public Iterable<String> start(Database.batchableContext batchableContext) {
        return new CSVIterator(this.contentData, CSVParser.crlf);
    }
    
    public void execute(Database.BatchableContext batchableContext, List<String> scope) {
        /* Phase 0: Parsing CSV file. */
        // TODO: pass CSV separator
        List<List<String>> records = NegoptimHelper.parseCSV(scope, true, null);
        
        // Get dispatch date, sequence and fiscal year.
        Date dispatchDate = Date.today();
        Integer sequence = dispatchDate.month();
        Integer fiscalYear = dispatchDate.year();
        
        nb.logParameter('dispatchDate', dispatchDate);
        nb.logParameter('sequence', sequence);
        nb.logParameter('fiscalYear', fiscalYear);
        
        /* Phase 1: Prepare Data. */
        // Declaration of a map of suppliers code with CSV row.
        Map<String, List<WrapperRow>> rowsMap = new Map<String, List<WrapperRow>>();
        Set<String> sectionCodeSet = new Set<String>();
        Set<String> NSCodeSet = new Set<String>();
        Set<String> storeCodeSet = new Set<String>();
        Set<String> conditionNameSet = new Set<String>();
        Set<String> PGSNASet = new Set<String>();
        // Fill the initial map.
        Integer lineInd = 1;
        for(List<String> row : records) {
            lineInd++;
            WrapperRow wRow = new WrapperRow();
            wRow.lineIndex = lineInd;
            wRow.supplierCode = row[0];
            wRow.sectionCode = row[1];
            wRow.pgCode = row[2];
            wRow.nsCode = row[3];
            wRow.storeCode = row[4];
            wRow.conditionName = row[5];
            wRow.sAmount = row[6];
            wRow.amount = NegoptimHelper.getDecimalValue(row[6]) != null ? NegoptimHelper.getDecimalValue(row[6]) : 0;
            wRow.prenego = row[7];
            wRow.comment = row[8];
            
            if (isYearlyDistribution) {
                
                // Handling when a row finishes by empty fields.
                for (Integer i = 9 ; i <= 20 ; i++) {
                    if (row.size() == i) {
                        for (Integer j = 1 ; j <= 21 - i ; j++) {
                            row.add('');
                        }
                    }
                    wRow.sMonths[i - 9] = row[i];
                }
                // Handling when a row contains one or more empty fields.
                wRow.month1 = NegoptimHelper.getDecimalValue(row[9]) != null ? NegoptimHelper.getDecimalValue(row[9]) : 0;
                wRow.month2 = NegoptimHelper.getDecimalValue(row[10]) != null ? NegoptimHelper.getDecimalValue(row[10]) : 0;
                wRow.month3 = NegoptimHelper.getDecimalValue(row[11]) != null ? NegoptimHelper.getDecimalValue(row[11]) : 0;
                wRow.month4 = NegoptimHelper.getDecimalValue(row[12]) != null ? NegoptimHelper.getDecimalValue(row[12]) : 0;
                wRow.month5 = NegoptimHelper.getDecimalValue(row[13]) != null ? NegoptimHelper.getDecimalValue(row[13]) : 0;
                wRow.month6 = NegoptimHelper.getDecimalValue(row[14]) != null ? NegoptimHelper.getDecimalValue(row[14]) : 0;
                wRow.month7 = NegoptimHelper.getDecimalValue(row[15]) != null ? NegoptimHelper.getDecimalValue(row[15]) : 0;
                wRow.month8 = NegoptimHelper.getDecimalValue(row[16]) != null ? NegoptimHelper.getDecimalValue(row[16]) : 0;
                wRow.month9 = NegoptimHelper.getDecimalValue(row[17]) != null ? NegoptimHelper.getDecimalValue(row[17]) : 0;
                wRow.month10 = NegoptimHelper.getDecimalValue(row[18]) != null ? NegoptimHelper.getDecimalValue(row[18]) : 0;
                wRow.month11 = NegoptimHelper.getDecimalValue(row[19]) != null ? NegoptimHelper.getDecimalValue(row[19]) : 0;
                wRow.month12 = NegoptimHelper.getDecimalValue(row[20]) != null ? NegoptimHelper.getDecimalValue(row[20]) : 0;
            }
            // Test on supplier code existence in the map. A supplier can have many contracts (rows).
            if(!rowsMap.containsKey(wRow.supplierCode)) {
                rowsMap.put(wRow.supplierCode, new List<WrapperRow>{wRow});
            } else {
                //rowsMap.get(wRow.supplierCode).add(wRow);
                List<WrapperRow> l = rowsMap.get(wRow.supplierCode);
                Boolean found = false;
                for (WrapperRow item : l) {
                    if (item.supplierCode == wRow.supplierCode && item.storeCode == wRow.storeCode &&
                        item.pgCode == wRow.pgCode && item.nsCode == wRow.nsCode && item.conditionName == wRow.conditionName) {
                            item.amount += wRow.amount;
                            if(isYearlyDistribution) {
                                item.month1 += wRow.month1;
                                item.month2 += wRow.month2;
                                item.month3 += wRow.month3;
                                item.month4 += wRow.month4;
                                item.month5 += wRow.month5;
                                item.month6 += wRow.month6;
                                item.month7 += wRow.month7;
                                item.month8 += wRow.month8;
                                item.month9 += wRow.month9;
                                item.month10 += wRow.month10;
                                item.month11 += wRow.month11;
                                item.month12 += wRow.month12;
                            }
                            found = true;
                            break;
                        }
                }
                if(!found) {
                    rowsMap.get(wRow.supplierCode).add(wRow);
                }
            }
            // Fill section code set.
            if(!sectionCodeSet.contains(wRow.sectionCode)) {
                sectionCodeSet.add(wRow.sectionCode);
            }
            // Fill NS code set.
            if(!NSCodeSet.contains(wRow.nsCode)) {
                NSCodeSet.add(wRow.nsCode);
            }
            // Fill BUs (store or web) code set.
            if(!storeCodeSet.contains(wRow.storeCode)) {
                storeCodeSet.add(wRow.storeCode);
            }
            // Fill condition name set.
            if(!conditionNameSet.contains(wRow.conditionName)) {
                conditionNameSet.add(wRow.conditionName);
            }
            // Fill PG name set.
            if(!PGSNASet.contains(wRow.pgCode)) {
                PGSNASet.add(wRow.pgCode);
            }
        }
        
        /* Phase 2: Load Data. */
        // Map<supplier code, supplier (database)> creation.
        Map<String, Sup_Supplier__c> suppliersMap = new Map<String, Sup_Supplier__c>();
        // Map<section code, section (database)> creation.
        Map<String, Orga_HE__c> sectionsMap = new Map<String, Orga_HE__c>();
        // Map<NS name, NS (database)> creation.
        Map<String, Sup_sup_NegoScope__c> NSsMap = new Map<String, Sup_sup_NegoScope__c>();
        // Map<BU code, BU (database)> creation.
        Map<String, Orga_BU__c> BUMap = new Map<String, Orga_BU__c>();
        // Map<condition name, Tarrif condition (database)> creation.
        Map<String, Pol_Com_Condition__c> tarrifConditionsMap = new Map<String, Pol_Com_Condition__c>();
        // Map<complex key, Contract__c> creation. The key is a concatenation of supplier Id, NegoScope Id and selected country.
        Map<String, Contract__c> cMap = new Map<String, Contract__c>();
        // 14/06/17
        Map<String, Supplier_PG_Mapping__c> PGsMap = new Map<String, Supplier_PG_Mapping__c>();
        // Group rows with same condition
        // key = Contract_Discount__c Id
        Map<Id, List<WrapperRow>> groupConditionRowMap = new Map<Id, List<WrapperRow>>();
        // Group rows with same scope to create one condition for identicals
        // key = Condition_Type__c + Product_Scope__c
        Map<String, List<WrapperRow>> groupRowMap = new Map<String, List<WrapperRow>>();
        // Map for new conditions to insert
        // key = Condition_Type__c + Product_Scope__c
        Map<String, Contract_Discount__c> newConditionsMap = new Map<String, Contract_Discount__c>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            // Get suppliers based on the input file and the selected country.
            List<Sup_Supplier__c> suppliers = [SELECT Id, Code__c, Name, CurrencyIsoCode
                                               FROM Sup_Supplier__c
                                               WHERE Country_origin__c = :selectedCountry
                                               AND Status__c = 'Active'
                                               AND Code__c IN :rowsMap.keySet()];
            for(Sup_Supplier__c item : suppliers) {
                suppliersMap.put(item.Code__c, item);
            }
            // Get sections based on the input file and the status.
            List<Orga_HE__c> sections = [SELECT Id, Elt_Code__c, Name
                                         FROM Orga_HE__c
                                         WHERE Status__c = 'Active'
                                         AND Elt_Code__c IN :sectionCodeSet
                                         AND Level__c = 2];
            for (Orga_HE__c item : sections) {
                sectionsMap.put(item.Elt_Code__c, item);
            }
            // Get NS based on the input file and the suppliers.
            List<Sup_sup_NegoScope__c> NSs = [SELECT Id, Name, NS_Code__c, Parent_Nego_Scope__c, CurrencyIsoCode,
                                              (SELECT Sup_sup_NegoScope__r.NS_Code__c, Sup_PG__r.SNA_Code__c FROM Supplier_Nego_Scope_PG__r)
                                              FROM Sup_sup_NegoScope__c
                                              WHERE Supplier__c IN :suppliers
                                              AND NS_Code__c IN :NSCodeSet];
            for (Sup_sup_NegoScope__c item : NSs) {
                NSsMap.put(item.NS_Code__c, item);
            }
            // Creation of a list of NS Ids.
            Set<Id> NSIds = new Set<Id>();
            for (Sup_sup_NegoScope__c item : NSs) {
                if (item.Parent_Nego_Scope__c == null) {
                    NSIds.add(item.Id);
                } else {
                    NSIds.add(item.Parent_Nego_Scope__c);
                }
            }
            // Get Store and web with parents
            List<Orga_BU__c> BUs = [SELECT Id, Name, BU_Code__c, CurrencyIsoCode, Business_Unit_Type__c,
                                    (SELECT Entity__r.Id, Entity__r.Name, Entity__r.BU_Code__c, Entity__r.CurrencyIsoCode
                                     FROM List_parent__r WHERE Entity__r.Status__c = 'Open')
                                    FROM Orga_BU__c WHERE Business_Unit_Type__c IN ('Store', 'Web', 'Warehouse')
                                    AND Status__c = 'Open' AND BU_Code__c IN :storeCodeSet];
            // Map each store / web to their parent list
            Map<String, Set<String>> businessUnitsMap = new  Map<String, Set<String>>();
            // Map each BU Id to the corresponding currency.
            Map<Id, String> buCurrenciesMap = new Map<Id, String>();
            // All Bu parents + children
            Set<Id> buIdSet = new Set<Id>();
            for(Orga_BU__c buItem: BUs) {
                Set<String> businessUnitsList = new Set<String>();
                for(Orga_BU_List_Detail__c item: buItem.List_parent__r) {
                    businessUnitsList.add(item.Entity__r.BU_Code__c);
                    buIdSet.add(item.Entity__c);
                    BUMap.put(item.Entity__r.BU_Code__c, item.Entity__r);
                    buCurrenciesMap.put(item.Entity__c, item.Entity__r.CurrencyIsoCode);
                }
                buIdSet.add(buItem.Id);
                BUMap.put(buItem.BU_Code__c, buItem);
                buCurrenciesMap.put(buItem.Id, buItem.CurrencyIsoCode);
                businessUnitsMap.put(buItem.BU_Code__c, businessUnitsList);
            }
            // Get all Policy Tariff conditions.
            List<Pol_Com_Condition__c> tarrifConditions = [SELECT Id, Name, Nego_Discount_Type__c
                                                           FROM Pol_Com_Condition__c
                                                           WHERE Name IN :conditionNameSet];
            for (Pol_Com_Condition__c item : tarrifConditions) {
                tarrifConditionsMap.put(item.Name, item);
            }
            // Get contracts based on suppliers, NS, country and year.
            List<Contract__c> contracts = [SELECT Id, Name, Contract_Numbder__c, Supplier__c, Supplier_Nego_Scope__c
                                           FROM Contract__c
                                           WHERE Supplier__c IN :suppliers
                                           AND Supplier_Nego_Scope__c IN :NSIds
                                           AND Contract_BU__c = :selectedCountry
                                           AND CALENDAR_YEAR(Contract_BDate__c) = :year
                                           AND Contract_Type__c = 'Contract'
                                           AND((D_N__c = 'D' AND Status__c = 'Validated')
                                               OR (D_N__c = 'N' AND Status__c = 'Signed'))];
            for (Contract__c item : contracts) {
                String key = item.Supplier__c + '' + item.Supplier_Nego_Scope__c;
                cMap.put(key, item);
            }
            // Load PGs
            List<Supplier_PG_Mapping__c> PGs = [SELECT id, SNA_Code__c, Supplier__c, Name, Section__c, Department__c FROM Supplier_PG_Mapping__c
                                                WHERE Supplier__c IN :suppliers
                                                AND SNA_Code__c = :PGSNASet
                                                AND Section__c IN :sections];
            for (Supplier_PG_Mapping__c item : PGs) {
                PGsMap.put(item.SNA_Code__c, item);
            }
            List<Contract_Discount__c> conditionList = [SELECT id, Name, Is_Prenego_Envelop__c, BU_Scope__c, BU_Scope__r.BU_Code__c, Product_Scope__c, Condition_Type__c,
                                                        Condition_Type__r.Name, Nego_Discount_Type__c, CurrencyIsoCode, Value_amt__c, Contract__c,
                                                        Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c,
                                                        Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c,
                                                        Value_amt_disp_M11__c, Value_amt_disp_M12__c, Disc_BDate__c, Disc_EDate__c
                                                        FROM Contract_Discount__c
                                                        WHERE Contract__c IN :contracts
                                                        AND BU_Scope__c IN :buIdSet
                                                        AND Product_Scope__c = :NSs
                                                        AND Condition_Type__c = :tarrifConditions];// AND Is_Prenego_Envelop__c = true
            // TODO: Push into map
            // Set IDs
            for(String key : rowsMap.keySet()) {
                Sup_Supplier__c supplier = suppliersMap.get(key);
                if(supplier != null) {
                    List<WrapperRow> wRows = rowsMap.get(key);
                    if(wRows != null && wRows.size() > 0) {
                        for(WrapperRow wRow : wRows) {
                            // Supplier
                            wRow.supplierID = supplier.Id;
                            wRow.supplierCurrency = supplier.CurrencyIsoCode;
                            // Section
                            Orga_HE__c section = sectionsMap.get(wRow.sectionCode);
                            if(section != null) {
                                wRow.sectionID = section.Id;
                            }
                            // PG
                            Supplier_PG_Mapping__c PG = PGsMap.get(wRow.pgCode);
                            if(PG != null) {
                                wRow.pgID = PG.Id;
                            }
                            // NS
                            Sup_sup_NegoScope__c NS = NSsMap.get(wRow.nsCode);
                            if(NS != null) {
                            	Boolean linkNSPGFound = false;
                                for (Sup_NS_PG__c NSPG : NS.Supplier_Nego_Scope_PG__r) {
                                    if (wRow.nspgCode == NSPG.Sup_sup_NegoScope__r.NS_Code__c + '-' + NSPG.Sup_PG__r.SNA_Code__c) {
                                        wRow.nsID = NS.Id;
                                		wRow.parentNSID = NS.Parent_Nego_Scope__c;
                                		linkNSPGFound = true;
                                		break;
                                    }
                                }
                                if(!linkNSPGFound) {
                                    nb.logError('PG (code: ' + wRow.pgCode + ') not linked to NS (code: ' + wRow.nsCode + '). (ROW ' +  wRow.lineIndex + ')');
                                }
                            }
                            // BU
                            Orga_BU__c BU = BUMap.get(wRow.storeCode);
                            if(BU != null) {
                                wRow.storeID = BU.Id;
                            }
                            // Tarrif Condition
                            Pol_Com_Condition__c tarrifCondition = tarrifConditionsMap.get(wRow.conditionName);
                            if(tarrifCondition != null) {
                                wRow.tarrifConditionID = tarrifCondition.Id;
                                wRow.negoDiscountType = tarrifCondition.Nego_Discount_Type__c;
                            }
                            // Contract
                            if (wRow.isValidRow) {
                                // !! CASE: multiple contract on same NS !!
                                Contract__c contract = cMap.get(wRow.contractKey);
                                if(contract != null) {
                                    wRow.contractID = contract.Id;
                                }
                                else {
                                    nb.logError(wRow.getLogs(isYearlyDistribution));
                                }
                                // Condition
                                for (Contract_Discount__c cond : conditionList) {
                                    if (cond.Condition_Type__c == wRow.tarrifConditionID
                                        && (cond.BU_Scope__c == wRow.storeID || businessUnitsMap.get(wRow.storeCode).contains(cond.BU_Scope__r.BU_Code__c))
                                        && cond.Product_Scope__c == wRow.nsID
                                        && cond.Is_Prenego_Envelop__c == wRow.isPrenego
                                        && (dispatchDate.month() >= cond.Disc_BDate__c.month()
                                            && dispatchDate.month() <= cond.Disc_EDate__c.month())) {
                                                wRow.condition = cond;
                                                wRow.conditionID = cond.Id;
                                            }
                                }
                                // New conditions to insert
                                if((!wRow.isPrenego && wRow.condition == null) ||
                                   (!wRow.isPrenego && wRow.condition != null && wRow.condition.Is_Prenego_Envelop__c == true) || 
                                   (wRow.isPrenego && wRow.condition != null && wRow.condition.Is_Prenego_Envelop__c == False)) {
                                       String rowChar = wRow.isPrenego ? 'P' : 'N';
                                       String conditionKey = wRow.tarrifConditionID + '' + wRow.nsID + rowChar;
                                       if(!groupRowMap.containsKey(conditionKey)) {
                                           List<WrapperRow> wrapperRowList = new List<WrapperRow>();
                                           wrapperRowList.add(wRow);
                                           groupRowMap.put(conditionKey, wrapperRowList);
                                       }
                                       else {
                                           groupRowMap.get(conditionKey).add(wRow);
                                       }
                                   }
                            }
                            else {
                                nb.logError(wRow.getLogs(isYearlyDistribution));
                            }
                        }
                    }
                }
            }
            
            // check security on insert condition fields
            String[] conditionCreateFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Is_Prenego_Envelop__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M1__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M2__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M3__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M4__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M5__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M6__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M7__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M8__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M9__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M10__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M11__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M12__c'),
                NegoptimHelper.normalizeAPIName('Contract__c'), NegoptimHelper.normalizeAPIName('Condition_Type__c'),
                NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'), NegoptimHelper.normalizeAPIName('Product_Scope__c'),
                NegoptimHelper.normalizeAPIName('BU_Scope__c'), NegoptimHelper.normalizeAPIName('Value_amt__c')};
                    Boolean isConditionAccess = NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionCreateFields);  
            
            if(isConditionAccess){
                // Loop over groupRowMap to create the new conditions and put into newConditionsMap
                for(String key : groupRowMap.keySet()) {
                    List<WrapperRow> wRows = groupRowMap.get(key);
                    Decimal sumAmount = 0;
                    Boolean commonFieldAssigned = false; // flag to check if common field was set from a row
                    Id refContractId;
                    String refTarrifCondition;
                    String refNegoDiscountType;
                    String refCurrency;
                    String refNS;
                    String refBU;
                    Contract_Discount__c newCondition = new Contract_Discount__c(Is_Prenego_Envelop__c = wRows.get(0).isPrenego, Value_amt_disp_M1__c = 0, Value_amt_disp_M2__c = 0,
                                                                                 Value_amt_disp_M3__c = 0, Value_amt_disp_M4__c = 0,Value_amt_disp_M5__c = 0, Value_amt_disp_M6__c = 0,
                                                                                 Value_amt_disp_M7__c = 0, Value_amt_disp_M8__c = 0,Value_amt_disp_M9__c = 0, Value_amt_disp_M10__c = 0,
                                                                                 Value_amt_disp_M11__c = 0, Value_amt_disp_M12__c = 0);
                    for(WrapperRow wr : wRows) {
                        sumAmount += wr.amount;
                        if(!commonFieldAssigned) {
                            refContractId = wr.contractID;
                            refTarrifCondition = wr.tarrifConditionID;
                            refNegoDiscountType = wr.negoDiscountType;
                            refCurrency = wr.supplierCurrency;
                            refNS = wr.nsID;
                            commonFieldAssigned = true && refContractId != null;
                        }
                        if(isYearlyDistribution) {
                            newCondition.Value_amt_disp_M1__c += wr.month1;
                            newCondition.Value_amt_disp_M2__c += wr.month2;
                            newCondition.Value_amt_disp_M3__c += wr.month3;
                            newCondition.Value_amt_disp_M4__c += wr.month4;
                            newCondition.Value_amt_disp_M5__c += wr.month5;
                            newCondition.Value_amt_disp_M6__c += wr.month6;
                            newCondition.Value_amt_disp_M7__c += wr.month7;
                            newCondition.Value_amt_disp_M8__c += wr.month8;
                            newCondition.Value_amt_disp_M9__c += wr.month9;
                            newCondition.Value_amt_disp_M10__c += wr.month10;
                            newCondition.Value_amt_disp_M11__c += wr.month11;
                            newCondition.Value_amt_disp_M12__c += wr.month12;
                        }
                    }
                    newCondition.Contract__c = refContractId;
                    newCondition.Condition_Type__c = refTarrifCondition;
                    newCondition.Nego_Discount_Type__c = refNegoDiscountType;
                    newCondition.CurrencyIsoCode = refCurrency;
                    newCondition.Product_Scope__c = refNS;
                    newCondition.BU_Scope__c = selectedCountry;
                    newCondition.Value_amt__c = sumAmount;
                    if(!isYearlyDistribution) {
                        String fieldName = 'Value_amt_disp_M' + dispatchDate.month() + '__c';
                        newCondition.put(fieldName, sumAmount);
                    }
                    // add to the Map
                    if(commonFieldAssigned)
                        newConditionsMap.put(key, newCondition);
                }
                // insert new conditions
                if(newConditionsMap.values() != null && newConditionsMap.values().size() > 0){
                    insert newConditionsMap.values();
                }
            }
            List<WrapperRow> passedWrapperRowList = new List<WrapperRow>();
            // check business rules and initialise the dispatch lines
            for(List<WrapperRow> l : rowsMap.values()) {
                for(WrapperRow item : l) {
                    if(item.getLogs(isYearlyDistribution) == null) {
                        passedWrapperRowList.add(item);
                    } else {
                        nb.logError(item.getLogs(isYearlyDistribution));
                    }
                }    
            }
            
            /* Phase 4: Dispatching process. */
            
            // List of dispatch details to be upserted
            List<Inv_BUDispatch_Details__c> dispatchDetailsList = new List<Inv_BUDispatch_Details__c>();
            // Get Dispatch heads for existing BU.
            List<Inv_BUDispatch__c> dispatchHeadList = [SELECT Id, Inv_BU__c
                                                        FROM Inv_BUDispatch__c
                                                        WHERE Inv_BU__c IN :BUs
                                                        AND Inv_Fiscal_Year__c = :fiscalYear];
            // Set of inv bu dispatch creation.
            Set<Id> buSet = new Set<Id>();
            // Fill the set of inv bu diapstch.
            for (Inv_BUDispatch__c DH : dispatchHeadList) {
                buSet.add(DH.Inv_BU__c);
            }
            // Get Dispatch Details for existing BU and section and PG.
            List<Inv_BUDispatch_Details__c> dispatchDetails = [SELECT Id, Discount__c, Inv_BUDispatch__c, Hierarchy_level_dispatch__c,
                                                               PG__c, Order_to_DC__c, Sequence__c,
                                                               Fix_Amount_Dispatch_M1__c, Fix_Amount_Dispatch_M2__c, Fix_Amount_Dispatch_M3__c,
                                                               Fix_Amount_Dispatch_M4__c, Fix_Amount_Dispatch_M5__c, Fix_Amount_Dispatch_M6__c,
                                                               Fix_Amount_Dispatch_M7__c, Fix_Amount_Dispatch_M8__c, Fix_Amount_Dispatch_M9__c,
                                                               Fix_Amount_Dispatch_M10__c, Fix_Amount_Dispatch_M11__c, Fix_Amount_Dispatch_M12__c
                                                               FROM Inv_BUDispatch_Details__c
                                                               WHERE Discount__c IN :conditionList
                                                               AND Inv_BUDispatch__c IN :BUs
                                                               AND Hierarchy_level_dispatch__c IN :sections
                                                               AND PG__c IN :PGs
                                                               AND Order_to_DC__c = null];
            // Map for existing dispatch details
            Map<String, Inv_BUDispatch_Details__c> dispatchDetailsMap = new Map<String, Inv_BUDispatch_Details__c>();
            for(Inv_BUDispatch_Details__c item : dispatchDetails) {
                String key = item.Discount__c + '' + item.Hierarchy_level_dispatch__c + '' + item.Inv_BUDispatch__c + '' + item.PG__c;
                dispatchDetailsMap.put(key, item);
            }
            Integer index = 0;
            Map<Integer, List<Inv_BUDispatch_Details__c>> mapOfNewDD = new Map<Integer, List<Inv_BUDispatch_Details__c>>();
            // Starting dispatching process. Loop over the Dispatch detail wrapper.
            Inv_BUDispatch__c dispatchHead;
            for (WrapperRow wDD : passedWrapperRowList) {
                if (!buSet.contains(wDD.storeId)) {
                    dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = fiscalYear,
                                                         Inv_BU__c = wDD.storeID, CurrencyIsoCode = buCurrenciesMap.get(wDD.storeID));
                    dispatchHeadList.add(dispatchHead);
                    index = dispatchHeadList.size() - 1;
                    buSet.add(wDD.storeID);
                } else {
                    for(Integer i = 0; i < dispatchHeadList.size(); i++) {
                        if(wDD.storeID == dispatchHeadList.get(i).Inv_BU__c) {
                            index = i;
                            continue;
                        }
                    }
                }
                Inv_BUDispatch_Details__c dispatchDetailsLine;
                // The Cases
                if((wDD.isPrenego && wDD.condition.Is_Prenego_Envelop__c) || (!wDD.isPrenego && wDD.condition != null && !wDD.condition.Is_Prenego_Envelop__c)) {
                    String ddKey = wDD.condition.Id + '' + wDD.sectionID + '' + wDD.storeID + '' + wDD.pgID;
                    // check if a previous dispatch detail exist
                    if (!dispatchDetailsMap.containsKey(ddKey)) {
                        dispatchDetailsLine = wDD.mapToDispatchDetail(isYearlyDistribution, sequence);
                        if(!mapOfNewDD.containsKey(index)) {
                            List<Inv_BUDispatch_Details__c> newListDD = new List <Inv_BUDispatch_Details__c>();
                            newListDD.add(dispatchDetailsLine);
                            mapOfNewDD.put(index, newListDD);
                        }
                        else {
                            mapOfNewDD.get(index).add(dispatchDetailsLine);
                        }
                        dispatchDetailsMap.put(ddKey, dispatchDetailsLine);
                        
                    }
                    else {
                        if(!isYearlyDistribution) {
                            // check if already dispatched to current month
                            String fieldNameFixAmount = 'Fix_Amount_Dispatch_M' + sequence + '__c';
                            String fieldNameComment = 'Comment_M' + sequence + '__c';
                            Decimal existingValue = (Decimal) dispatchDetailsMap.get(ddKey).get(fieldNameFixAmount);
                            if(existingValue != null && existingValue != 0) {
                                nb.logError('ERROR-0011: VALUE ALREADY EXIST IN MONTH "' + sequence + '". (ROW ' +  wDD.lineIndex + ')');
                            }
                            else {
                                // Set value in target month + update sequence
                                Inv_BUDispatch_Details__c dd = dispatchDetailsMap.get(ddKey);
                                dd.put(fieldNameComment, wDD.comment);
                                dd.put(fieldNameFixAmount, wDD.amount);
                                dd.Sequence__c = sequence;
                                dd.Status__c = 'Updated';
                                dispatchDetailsList.add(dd);
                            }
                        } else {
                            dispatchDetailsLine = wDD.mapToDispatchDetail(isYearlyDistribution, sequence);
                            Inv_BUDispatch_Details__c dd = dispatchDetailsMap.get(ddKey);
                            String fieldMonthFixAmount = '';
                            Decimal existingMonthValue = 0;
                            Decimal newMonthValue = 0;
                            for (integer i = 1; i <= 12; i++){
                                fieldMonthFixAmount = 'Fix_Amount_Dispatch_M'+ i +'__c';
                                existingMonthValue = (Decimal) dd.get(fieldMonthFixAmount);
                                newMonthValue = (Decimal) dispatchDetailsLine.get(fieldMonthFixAmount);
                                if(existingMonthValue != null && existingMonthValue != 0 && newMonthValue != 0){
                                    nb.logError('ERROR-0012: VALUE ALREADY EXIST IN MONTH "' + i + '". (ROW ' +  wDD.lineIndex + ')');
                                    break;
                                } else {
                                    fieldMonthFixAmount = 'Fix_Amount_Dispatch_M'+ i +'__c';
                                    existingMonthValue = (Decimal) dd.get(fieldMonthFixAmount) != null ? (Decimal) dd.get(fieldMonthFixAmount) : 0;
                                    newMonthValue = (Decimal) dispatchDetailsLine.get(fieldMonthFixAmount) != null ? (Decimal) dispatchDetailsLine.get(fieldMonthFixAmount) : 0;
                                    dd.put(fieldMonthFixAmount, existingMonthValue + newMonthValue);
                                }
                            }
                            dd.Sequence__c = sequence;
                            dd.Status__c = 'Updated';
                            dispatchDetailsList.add(dd);
                            //TODO: Allow successful records to upsert
                        }
                    }
                    
                    // push rows with same condition to the map to calculate the sum of amounts
                    if(!groupConditionRowMap.containsKey(wDD.condition.Id)) {
                        List<WrapperRow> wrapperRowList = new List<WrapperRow>();
                        wrapperRowList.add(wDD);
                        groupConditionRowMap.put(wDD.condition.Id, wrapperRowList);
                    }
                    else {
                        groupConditionRowMap.get(wDD.condition.Id).add(wDD);
                    }
                }
                if((!wDD.isPrenego && wDD.condition == null) || 
                   (!wDD.isPrenego && wDD.condition != null && wDD.condition.Is_Prenego_Envelop__c == true) || 
                   (wDD.isPrenego && wDD.condition != null && wDD.condition.Is_Prenego_Envelop__c == False)) {
                       String rowChar = wDD.isPrenego ? 'P' : 'N';
                       String conditionKey = wDD.tarrifConditionID + '' + wDD.nsID + rowChar;
                       wDD.condition = newConditionsMap.get(conditionKey);
                       dispatchDetailsLine = wDD.mapToDispatchDetail(isYearlyDistribution, sequence);
                       if(!mapOfNewDD.containsKey(index)) {
                           List<Inv_BUDispatch_Details__c> newListDD = new List<Inv_BUDispatch_Details__c>();
                           newListDD.add(dispatchDetailsLine);
                           mapOfNewDD.put(index, newListDD);
                       }
                       else {
                           mapOfNewDD.get(index).add(dispatchDetailsLine);
                       }
                   }
            }
            // Calculate the total amount for existing conditions
            List<Contract_Discount__c> toUpdateConditionList = new List<Contract_Discount__c>();
            
            // check security on update condition fields
            String[] conditionUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Value_amt__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M1__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M2__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M3__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M4__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M5__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M6__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M7__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M8__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M9__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M10__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M11__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M12__c')};
                    isConditionAccess = NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionUpdateFields);  
            
            // check security on upsert dispatch fields
            String[] dispatchFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Sequence_Number__c'),
                NegoptimHelper.normalizeAPIName('Inv_Fiscal_Year__c'), NegoptimHelper.normalizeAPIName('Inv_BU__c')};
                    Boolean isDispatchAccess = NegoptimHelper.checkUpdatibility(Inv_BUDispatch__c.SObjectType, dispatchFields);  
            
            // check security on upsert dispatch detail fields
            String[] dispatchDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Sequence__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), /*NegoptimHelper.normalizeAPIName('Discount__c'),*/
                NegoptimHelper.normalizeAPIName('Inv_BUDispatch__c'), NegoptimHelper.normalizeAPIName('Hierarchy_level_dispatch__c'),
                NegoptimHelper.normalizeAPIName('PG__c'), NegoptimHelper.normalizeAPIName('Order_to_DC__c'),
                NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M1__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M2__c'),
                NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M3__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M4__c'),
                NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M5__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M6__c'),
                NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M7__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M8__c'),
                NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M9__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M10__c'),
                NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M11__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M12__c')};
                    Boolean isDispatchDetailAccess = NegoptimHelper.checkCreatibility(Inv_BUDispatch_Details__c.SObjectType, dispatchDetailFields) && NegoptimHelper.checkUpdatibility(Inv_BUDispatch_Details__c.SObjectType, dispatchDetailFields);  
            
            if(isConditionAccess && isDispatchAccess && isDispatchDetailAccess){
                for(String key : groupConditionRowMap.keySet()) {
                    List<WrapperRow> wRows = groupConditionRowMap.get(key);
                    Contract_Discount__c condition = wRows.get(0).condition;
                    Decimal sumAmount = 0;
                    decimal[] sumMonth = new decimal[]{0,0,0,0,0,0,0,0,0,0,0,0};
                        for(WrapperRow wr : wRows) {
                            ////if(!wr.isPrenego) {
                            sumAmount += wr.amount;
                            ////}
                            if(isYearlyDistribution) {
                                sumMonth[0] += wr.month1;
                                sumMonth[1] += wr.month2;
                                sumMonth[2] += wr.month3;
                                sumMonth[3] += wr.month4;
                                sumMonth[4] += wr.month5;
                                sumMonth[5] += wr.month6;
                                sumMonth[6] += wr.month7;
                                sumMonth[7] += wr.month8;
                                sumMonth[8] += wr.month9;
                                sumMonth[9] += wr.month10;
                                sumMonth[10] += wr.month11;
                                sumMonth[11] += wr.month12;
                            }
                        }
                    if(sumAmount != 0) {
                        if(condition.Value_amt__c == null) {
                            condition.Value_amt__c = 0;
                        }
                        condition.Value_amt__c += sumAmount;
                    }
                    if(!isYearlyDistribution) {
                        String fieldName = 'Value_amt_disp_M' + dispatchDate.month() + '__c';
                        Decimal existingValue = (Decimal) condition.get(fieldName);
                        if(existingValue != null) {
                            sumAmount += existingValue;
                        }
                        condition.put(fieldName, sumAmount);
                    }
                    else {
                        String field = '';
                        for(integer i = 1; i <= 12; i++){
                            field='Value_amt_disp_M'+ i+'__c';
                            Decimal currentValue = condition.get(field) != null ? (Decimal)condition.get(field) : 0;
                            condition.put(field, currentValue + sumMonth[i-1]);
                        }
                    }
                    // add to the List
                    toUpdateConditionList.add(condition);
                }
                if(toUpdateConditionList != null && toUpdateConditionList.size() > 0){                
                    // update existing conditions
                    update toUpdateConditionList;
                }
                if(dispatchHeadList != null && dispatchHeadList.size() > 0){                
                    // update dispatch head
                    upsert dispatchHeadList;
                }
                for(Integer i : mapOfNewDD.keySet()) {
                    for(Inv_BUDispatch_Details__c item : mapOfNewDD.get(i)) {
                        item.Inv_DispatchHead__c = dispatchHeadList.get(i).Id;
                        dispatchDetailsList.add(item);
                    }
                }
                
                String [] fields = new String [] { NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Sequence__c')};
                    if (NegoptimHelper.checkUpdatibility(Inv_BUDispatch_Details__c.SObjectType, fields)
                        || NegoptimHelper.checkCreatibility(Inv_BUDispatch_Details__c.SObjectType, fields))
                {
                    upsert dispatchDetailsList;
                }
            }
            if(nb.getErrorNumberByBatchIndex() > 0) {
                Database.rollback(sp);
            }
        } catch(DMLException e) {
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            Database.rollback(sp);
        } catch (Exception e) {
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            // Roll everything back in case of error.
            Database.rollback(sp);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        String countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :selectedCountry LIMIT 1].Name;
        String str;
        if (isYearlyDistribution) {
            str = 'Yearly';
        } else {
            str = 'Monthly';
        }
        String customSubject = 'Mass Distribution Fix Amount - '  + str + ' - ' + countryName + '/'+ year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
        ////nb.sendEmail(bc, nb.BATCH_SUMMARY);
    }
    
    /* Wrapper contains all CSV columns. */
    private class WrapperRow {
        
        private Integer lineIndex;
        
        private String supplierCode;
        private String sectionCode;
        private String nsCode;
        private String storeCode;
        private String conditionName;
        private Decimal amount;
        private String sAmount;
        private String pgCode;
        private String comment;
        private String prenego;
        private String secondaryLabel;
        private String[] sMonths = new String[] {'','','','','','','','','','','',''};
        private Decimal month1;
        private Decimal month2;
        private Decimal month3;
        private Decimal month4;
        private Decimal month5;
        private Decimal month6;
        private Decimal month7;
        private Decimal month8;
        private Decimal month9;
        private Decimal month10;
        private Decimal month11;
        private Decimal month12;
        private String nspgCode {
            get {
                return nsCode + '-' + pgCode;
            }
            set;
        }
        
        // Added fields
        public Id supplierID;
        public String supplierCurrency;
        public Id sectionID;
        public Id pgID;
        public Id nsID;
        public Id parentNSID;
        public Id storeID;
        public Id tarrifConditionID;
        public String negoDiscountType;
        public Id contractID;
        public Id conditionID;
        public Contract_Discount__c condition;
        
        public Boolean isPrenego {
            get {
                if(this.prenego.toLowerCase() == 'prenego') {
                    return True;
                } else if (this.prenego.toLowerCase() == 'new') {
                    return False;
                } else {
                    return False;
                }               
            }
            set;
        }
        public Boolean isValidRow {
            get {
                return this.supplierID != null && this.sectionID != null
                    && this.pgID != null && this.nsID != null
                    && this.storeID != null && this.tarrifConditionID != null;
            }
            set;
        }
        public String contractKey {
            get {
                String key = this.supplierID;
                if (this.parentNSID == null) {
                    key += '' + this.nsID;
                } else {
                    key += '' + this.parentNSID;
                }
                return key;
            }
            set;
        }
        private Decimal checkedAmount {
            get {
                return month1 + month2 + month3 + month4 + month5 + month6 +
                    month7 + month8 + month9 + month10 + month11 + month12;
            }
        }
        
        // Methods
        public String getLogs(Boolean mode) {
            if(this.supplierID == null) {
                return 'ERROR-002: SUPPLIER "' + this.supplierCode + '" NOT FOUND OR NOT ACTIVE. (ROW ' +  this.lineIndex + ')';
            }
            if (this.sectionID == null) {
                return 'ERROR-004: SECTION "' + this.sectionCode + '" NOT FOUND. (ROW ' +  this.lineIndex + ')';
            }
            if (this.pgID == null) {
                return 'ERROR-005: PG NAME "' + this.pgCode + '" NOT FOUND. (ROW ' +  this.lineIndex + ')';
            }
            if (this.nsID == null) {
                return 'ERROR-006: NS "' + this.nsCode + '" NOT FOUND OR NOT ACTIVE. (ROW ' +  this.lineIndex + ')';
            }
            if (this.storeID == null) {
                return 'ERROR-007: STORE/WAREHOUSE "' + this.storeCode + '" NOT FOUND OR IS NOT OPEN. (ROW ' +  this.lineIndex + ')';
            }
            if (this.tarrifConditionID == null) {
                return 'ERROR-008: CONDITION NAME "' + this.conditionName + '" NOT FOUND. (ROW ' +  this.lineIndex + ')';
            }
            if(this.contractID == null) {
                return 'ERROR-003: NO SIGNED CONTRACT FOR THE SUPPLIER: "' + this.supplierCode + '" WITH NEGOSCOPE: "' + this.nsCode + '". (ROW ' +  this.lineIndex + ')';
            }
            if (this.isPrenego && this.condition == null) {
                return 'ERROR-009: NO Prenego CONDITION FOUND. (ROW ' +  this.lineIndex + ')';
            }
            if(NegoptimHelper.getDecimalValue(sAmount) == null && !String.isEmpty(sAmount)){
                return 'ERROR-010: NOT VALID AMOUNT VALUE: MUST ENTER NUMERIC VALUE. (ROW ' + this.lineIndex + ')';
            }
            if (mode == true && !isPrenego) { // isYearlyDistribution
                if (this.checkedAmount != this.amount) {
                    return 'ERROR-014: NOT VALID AMOUNT VALUE: "' + this.amount + '". (ROW ' +  this.lineIndex + ')';
                }
                for(integer i = 0; i < 12; i++) {
                    if(NegoptimHelper.getDecimalValue(sMonths[i]) == null && !String.isEmpty(sMonths[i])){
                        return 'ERROR-013: NOT VALID MONTH '+ i +'  VALUE: MUST ENTER NUMERIC VALUE. (ROW ' + this.lineIndex + ')';
                    }
                }
            }
            return null;
        }
        public Inv_BUDispatch_Details__c mapToDispatchDetail(Boolean mode, Integer seq) {
            Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = this.condition.Id,
                                                                                          Contract__c = this.condition.Contract__c, Inv_BUDispatch__c = this.storeID,
                                                                                          Hierarchy_level_dispatch__c = this.sectionID,
                                                                                          Sequence__c = seq, CurrencyIsoCode = this.condition.CurrencyIsoCode,
                                                                                          PG__c = this.pgID, Supplier__c = this.supplierID, Status__c = 'New');
            if (mode == true) { // isYearlyDistribution
                dispatchDetailsLine.Comment__c = this.comment;
                dispatchDetailsLine.Fix_Amount_Dispatch_M1__c = this.month1;
                dispatchDetailsLine.Fix_Amount_Dispatch_M2__c = this.month2;
                dispatchDetailsLine.Fix_Amount_Dispatch_M3__c = this.month3;
                dispatchDetailsLine.Fix_Amount_Dispatch_M4__c = this.month4;
                dispatchDetailsLine.Fix_Amount_Dispatch_M5__c = this.month5;
                dispatchDetailsLine.Fix_Amount_Dispatch_M6__c = this.month6;
                dispatchDetailsLine.Fix_Amount_Dispatch_M7__c = this.month7;
                dispatchDetailsLine.Fix_Amount_Dispatch_M8__c = this.month8;
                dispatchDetailsLine.Fix_Amount_Dispatch_M9__c = this.month9;
                dispatchDetailsLine.Fix_Amount_Dispatch_M10__c = this.month10;
                dispatchDetailsLine.Fix_Amount_Dispatch_M11__c = this.month11;
                dispatchDetailsLine.Fix_Amount_Dispatch_M12__c = this.month12;
            }
            else {
                String fieldNameComment = 'Comment_M' + seq + '__c';	                	
                String fieldNameFixAmount = 'Fix_Amount_Dispatch_M' + seq + '__c';
                dispatchDetailsLine.put(fieldNameFixAmount, this.amount);
                dispatchDetailsLine.put(fieldNameComment, this.comment);
            }
            return dispatchDetailsLine;
        }
    }
    public class myException extends Exception {
        
    }
}