/**
* Dispatch based on Redistribution Model
* */
public with sharing class BaseRedistributionModelBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final List<Id> contractIds;
    public final List<Id> conditionIds;
    public final Date selectedDate;
    public final String mode;
    
    public final String MODE_EQUALLY = 'Equally';
    public final String MODE_PURCHASES_OF_MONTH = 'Purchases of the month';
    public final String MODE_YTD_PURCHASES_Y = 'YTD Purchases (current year)';
    
    public Integer year;
    public Integer sequence;
    public Map<Id, Set<Id>> businessUnitsMap;
    public Map<Id, Orga_BU__c> buCurrenciesMap;
    public Map<Id, String> buRecordTypeMap;
    public Map<Id, List<Supplier_PG_Mapping__c>> NSPGMap;
    private Boolean dispatchAggregateMode;
    
    public BaseRedistributionModelBatch(String startedFrom, Id countryId, List<Id> cIds, List<Id> condIds, date d, String mode) {
        this.nb = new NegoptimBatch('Dispatching Based On Redistribution Model', NegoptimBatch.BatchType.Stateless, startedFrom);
    	this.country = countryId;
        this.contractIds = cIds;
        this.conditionIds = condIds;
        this.selectedDate = d != null ? d : Date.today();
        this.mode = mode;
        // Declare the query to get conditions.
        String q = 'SELECT Id, Name, CurrencyIsoCode, Disc_BDate__c, Disc_EDate__c, Product_Scope__c, BU_Scope__c, Contract__c, Base_Redistribution_Model__c, Contract__r.Supplier__c,';
        q += ' Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c, Value_amt_disp_M6__c,';
        q += ' Value_amt_disp_M7__c, Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c, Value_amt_disp_M11__c, Value_amt_disp_M12__c,';
        q += ' Value_amt__c, Value_per__c, Y_Actu__c, Condition_Type__c, BU_Scope__r.Business_Unit_Type__c';
        q += ' FROM Contract_Discount__c';       
        q += ' WHERE Contract__r.Contract_Type__c = \'Contract\'';
        q += ' AND Value_amt__c NOT IN (0, null)';
        if(this.country != null) {
            q += ' AND Contract__r.Contract_BU__c = \'' + this.country + '\'';
        }
        if(this.contractIds != null && this.contractIds.size() > 0) {
            q += ' AND Contract__c IN (\'' + String.join(this.contractIds, '\',\'') +'\')';
        }
        else if(this.selectedDate.year() != null) {
            q += ' AND Contract__r.Reference_Year__c = ' + this.selectedDate.year() + '';
        }
        if(this.conditionIds != null && this.conditionIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(this.conditionIds, '\',\'') +'\')';
        }
        if(this.mode != null) {
            q += ' AND Base_Redistribution_Model__c = \'' + this.mode + '\'';
        } else {
            q += ' AND Base_Redistribution_Model__c != null';
        }
        this.query = q;
        // Load global settings
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        Integer closingDay = GlobalSettingsManager.loadGlobalSettings().dispatchMaxClosingDay;
        closingDay = closingDay == null || closingDay == 0 ? 31 : closingDay;
        this.dispatchAggregateMode = negoSettings.dispatchAggregateMode;
        
        if (this.selectedDate.day() <= closingDay) {
        	this.year = this.selectedDate.month() == 1 ? this.selectedDate.year() - 1 : this.selectedDate.year();
            sequence = this.selectedDate.month() == 1 ? 12 : this.selectedDate.month() - 1;
        } else {
        	this.year = this.selectedDate.year();
            sequence = this.selectedDate.month();
        }
        // push inputs to log
        nb.logParameter('counrty', this.country);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('conditionIds', this.conditionIds);
        nb.logParameter('selectedDate', this.selectedDate);
        nb.logParameter('query', this.query);
        nb.logParameter('dispatchAggregateMode', this.dispatchAggregateMode);
        nb.logParameter('closingDay', closingDay);
    }
    // Start
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute
    public void execute(Database.BatchableContext bc, List<Contract_Discount__c> scope) {
        // Map to group conditions by type of Base_Redistribution_Model__c
        Map<String, List<Contract_Discount__c>> conditionsTypeMap = new Map<String, List<Contract_Discount__c>>();
        
        Set<Id> BUSet = new Set<Id>();
        Set<Id> NSSet = new Set<Id>();
        Set<Integer> fiscalYearSet = new Set<Integer>();
        for(Contract_Discount__c item : scope) {
            // Fill the conditionsTypeMap
            if(conditionsTypeMap.containsKey(item.Base_Redistribution_Model__c)) {
                conditionsTypeMap.get(item.Base_Redistribution_Model__c).add(item);
            } else {
                conditionsTypeMap.put(item.Base_Redistribution_Model__c, new List<Contract_Discount__c>{item});
            }
            // Fill the Set of BU.
            if(!BUSet.contains(item.BU_Scope__c)) {
                BUSet.add(item.BU_Scope__c);
            }
            // Fill the Set of NS.
            if(!NSSet.contains(item.Product_Scope__c)) {
                NSSet.add(item.Product_Scope__c);
            }
            // Fill the Set of Fiscal Years
            if(item.Disc_BDate__c != null && !fiscalYearSet.contains(item.Disc_BDate__c.year())) {
                fiscalYearSet.add(item.Disc_BDate__c.year());
            }
        }
        
        NSPGMap = new Map<Id, List<Supplier_PG_Mapping__c>>();
        Map<Id, List<Id>> NSPGIdMap = new Map<Id, List<Id>>();
        List<Id> sectionIdList = new List<Id>();
        // Get Ids of NegoScope PGs
        for(Sup_NS_PG__c item : [SELECT Sup_PG__c, Sup_sup_NegoScope__c, Sup_PG__r.Section__c FROM Sup_NS_PG__c WHERE sup_sup_negoscope__r.Id IN : NSSet]) {
            sectionIdList.add(item.Sup_PG__r.Section__c);
            if (NSPGMap.containsKey(item.Sup_sup_NegoScope__c)) {
                NSPGMap.get(item.Sup_sup_NegoScope__c).add(new Supplier_PG_Mapping__c(Id = item.Sup_PG__c, Section__c = item.Sup_PG__r.Section__c));
                NSPGIdMap.get(item.Sup_sup_NegoScope__c).add(item.Sup_PG__c);
            } else {
                NSPGMap.put(item.Sup_sup_NegoScope__c, new List<Supplier_PG_Mapping__c>{new Supplier_PG_Mapping__c(Id = item.Sup_PG__c, Section__c = item.Sup_PG__r.Section__c)});
                NSPGIdMap.put(item.Sup_sup_NegoScope__c, new List<Id>{item.Sup_PG__c});
            }
        }
        
        // Single Instance of BusinessUnitHelper
        BusinessUnitHelper buHelper = BusinessUnitHelper.getInstance(BUSet, 1);
        // Load Map of BUs
        businessUnitsMap = buHelper.getBUChildrenIdsMap();
        // Map each BU Id to the corresponding currency.
        buCurrenciesMap = buHelper.getBUMap(true);
        // Map each BU Id to the corresponding Record type.
        buRecordTypeMap = buHelper.getBURecordTypeNameMap(true);
        
        // Target List of conditions in MODE_EQUALLY
        if ((this.mode == null || this.mode.equals(MODE_EQUALLY)) && conditionsTypeMap.containsKey(MODE_EQUALLY)) {
            // TODO: NOT SUPPORTED YET
        }
        // Target List of conditions in MODE_PURCHASES_OF_MONTH
        if ((this.mode == null || this.mode.equals(MODE_PURCHASES_OF_MONTH)) && conditionsTypeMap.containsKey(MODE_PURCHASES_OF_MONTH)) {
            executePurchasesMode(bc, MODE_PURCHASES_OF_MONTH, conditionsTypeMap.get(MODE_PURCHASES_OF_MONTH), fiscalYearSet);
        }
        // Target List of conditions in MODE_YTD_PURCHASES_Y
        if ((this.mode == null || this.mode.equals(MODE_YTD_PURCHASES_Y)) && conditionsTypeMap.containsKey(MODE_YTD_PURCHASES_Y)) {
            executePurchasesMode(bc, MODE_YTD_PURCHASES_Y, conditionsTypeMap.get(MODE_YTD_PURCHASES_Y), fiscalYearSet);
        }
        ////nb.saveLog(bc);
    }
    // Finish
    public void finish(Database.BatchableContext bc) {
        String countryName = 'N/A';
        try {
            if(country != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
            nb.logError('Exception: ' + e.getDMLMessage(0) + ' - ' + e.getLineNumber());
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/' + this.year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    // For MODE_YTD_PURCHASES_Y and MODE_PURCHASES_OF_MONTH
    private void executePurchasesMode(Database.BatchableContext bc, String mode, List<Contract_Discount__c> conditionList, Set<Integer> fiscalYearSet) {
        String fieldDispatchName = 'Value_amt_disp_M' + sequence + '__c';
        
        List<Id> PGIds = new List<Id>();
        List<Id> BUIds = new List<Id>();
        List<WrapperCondition> wrapperConditionList = new List<WrapperCondition>();
        for(Contract_Discount__c item : conditionList) {
            WrapperCondition wCondition = new WrapperCondition(item);
            wCondition.amountTODispatch = item.get(fieldDispatchName) != null ? (Decimal)item.get(fieldDispatchName) : 0;
            if(NSPGMap.containsKey(item.Product_Scope__c)) {
                wCondition.PGs = NSPGMap.get(item.Product_Scope__c);
            }
            wCondition.BUIds = new Set<Id>(businessUnitsMap.get(item.BU_Scope__c));
            PGIds.addAll(wCondition.PGIds);
            BUIds.addAll(wCondition.BUIds);
            wrapperConditionList.add(wCondition);
        }
        List<Inv_BUDispatch_Details__c> dispatchDetailsList = new List<Inv_BUDispatch_Details__c>();
        
        Map<String, List<WrapperPurchase>> wPurchasesMap = new Map<String, List<WrapperPurchase>>();
        String fieldToAggregate = 'YTD_TO__c'; // by default MODE_YTD_PURCHASES_Y
        if(mode == MODE_PURCHASES_OF_MONTH) fieldToAggregate = 'TO' + sequence + '__c';
        string query = ' FROM Purchases_Flow_PG__c';
        query += ' WHERE PG__c IN (\'' + String.join(PGIds, '\',\'') +'\')';
        query += ' AND BU__c IN (\'' + String.join(BUIds, '\',\'') +'\')';
        query += ' AND Year__c = ' + year;
        if(this.dispatchAggregateMode) {
            query = 'SELECT SUM(' + fieldToAggregate + ') tosum, PG__c pg, BU__c bu, Section__c section, DC__c dc' 
            + query
            + ' GROUP BY PG__c, BU__c, Section__c, DC__c';
        for(AggregateResult item : Database.query(query)) {
            WrapperPurchase wPurchase = new WrapperPurchase();
            wPurchase.buId = (Id) item.get('bu');
            wPurchase.sectionId = (Id) item.get('section');
            wPurchase.dcId = (Id) item.get('dc');
            wPurchase.pgId = (Id) item.get('pg');
            wPurchase.YTD = item.get('tosum') != null ? Decimal.valueOf(String.valueOf(item.get('tosum'))) : 0;
            ////wPurchase.to1 = item.get('to1') != null ? Decimal.valueOf(String.valueOf(item.get('to1'))) : 0;
            if(wPurchasesMap.containsKey(wPurchase.key))
                wPurchasesMap.get(wPurchase.key).add(wPurchase);
            else wPurchasesMap.put(wPurchase.key, new List<WrapperPurchase>{wPurchase});
        }
        }else {
            query = 'SELECT Id, ' + fieldToAggregate + ' , PG__c , BU__c , Section__c, DC__c ' + query ;
            
            for(Purchases_Flow_PG__c item : Database.query(query)) {
                WrapperPurchase wPurchase = new WrapperPurchase();
                wPurchase.purshaseId = item.Id;
                wPurchase.buId = item.BU__c;
                wPurchase.sectionId = item.Section__c;
                wPurchase.dcId = item.DC__c;
                wPurchase.pgId = item.PG__c;
                wPurchase.YTD = item.get(fieldToAggregate)!= null ? Decimal.valueOf(String.valueOf(item.get(fieldToAggregate))) : 0;
                
                String key = wPurchase.buId + '' + wPurchase.pgId ;
                if(wPurchasesMap.containsKey(key))
                    wPurchasesMap.get(key).add(wPurchase);
                else wPurchasesMap.put(key, new List<WrapperPurchase>{wPurchase});
            }
        }
        
        List<Id> sectionIds = new List<Id>();
        List<Id> DCIds = new List<Id>();
        // Loop over conditions x corresponding purchases
        for(WrapperCondition item : wrapperConditionList) {
            item.getPurchases(wPurchasesMap); // required to fill wPurchasesList
            for(WrapperPurchase purchase : item.wPurchasesList) {
                ////BUIds.add(purchase.buId);
                sectionIds.add(purchase.sectionId);
                if(purchase.dcId != null) DCIds.add(purchase.dcId);
                ////if(purchase.pgId != null) PGIds.add(purchase.pgId);
                // Fill the wrapper.
                WrapperDispatchDetail wDispatchDetail = new WrapperDispatchDetail();
                wDispatchDetail.buId = purchase.buId;
                wDispatchDetail.sectionId = purchase.sectionId;
                wDispatchDetail.dcId = purchase.dcId;
                wDispatchDetail.pgId = purchase.pgId;
                wDispatchDetail.storeToDC = false;
                if((buRecordTypeMap.get(purchase.buId) == 'Store' || buRecordTypeMap.get(purchase.buId) == 'Web' || buRecordTypeMap.get(purchase.buId) == 'Banner') && purchase.dcId != null) {
                    wDispatchDetail.storeToDC = true;
                }
                if(!this.dispatchAggregateMode) wDispatchDetail.purshaseId = purchase.purshaseId;
                wDispatchDetail.baseTO = purchase.YTD;//p.get('tosum') != null ? Decimal.valueOf(String.valueOf(p.get('tosum'))) : 0;
                item.wDispatchDetailList.add(wDispatchDetail);
                item.totalConditionPrurchases += wDispatchDetail.baseTO;
            }
        }
        // Get Dispatch heads for existing BU.
        List<Inv_BUDispatch__c> dispatchHeadList = [SELECT Id, Inv_BU__c, Inv_Fiscal_Year__c FROM Inv_BUDispatch__c
                                                    WHERE Inv_BU__c IN :BUIds AND Inv_Fiscal_Year__c IN :fiscalYearSet];
        Integer pos = 0;
        Map<String, Integer> dispatchHeadIndexMap = new Map<String, Integer>();
        for(Inv_BUDispatch__c item : dispatchHeadList) {
            dispatchHeadIndexMap.put(item.Inv_BU__c + String.valueOf(Integer.valueOf(item.Inv_Fiscal_Year__c)), pos);
            pos++;
        }
        // Get Dispatch Details for existing BU and section.
        Map<String, Inv_BUDispatch_Details__c> dispatchDetailsMap = new Map<String, Inv_BUDispatch_Details__c>();
        for(Inv_BUDispatch_Details__c item : [SELECT Id, Discount__c, Inv_BUDispatch__c, Hierarchy_level_dispatch__c,
                                              PG__c, Order_to_DC__c
                                              FROM Inv_BUDispatch_Details__c
                                              WHERE Discount__c IN :conditionList
                                              AND Inv_BUDispatch__c IN :BUIds
                                              AND Hierarchy_level_dispatch__c IN :sectionIds
                                              /*AND Order_to_DC__c IN :listDCId*/
                                              AND PG__c IN :PGIds])
        {
            String key = item.Discount__c + '' + item.Inv_BUDispatch__c + '' + item.Hierarchy_level_dispatch__c
                + '' + item.PG__c + '' + item.Order_to_DC__c;
            dispatchDetailsMap.put(key, item);
        }
        Map<Integer, List<Inv_BUDispatch_Details__c>> mapOfNewDD = new Map<Integer, List<Inv_BUDispatch_Details__c>>();
        for(WrapperCondition wCondition : wrapperConditionList) {
            Decimal diff = 0, totalSum = 0;
            Integer latestIndex = wCondition.wDispatchDetailList.size() - 1;
            for(Integer i = 0; i < wCondition.wDispatchDetailList.size(); i++) {
                WrapperDispatchDetail item = wCondition.wDispatchDetailList.get(i);
                item.calculate(wCondition.totalConditionPrurchases, wCondition.amountTODispatch);
                Decimal total = item.amount.setscale(2, system.RoundingMode.HALF_UP);
                totalSum += total;
                // add the gap calculation to the latest record
                if(i == latestIndex) {
                    diff = wCondition.amountTODispatch - totalSum;
                    total += diff;
                }
                // No dispatch head exist for the BU.
                String dispatchHeadKey = item.buId + String.valueOf(wCondition.fiscalYear);
                if(!dispatchHeadIndexMap.containsKey(dispatchHeadKey)) {
                    Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = wCondition.fiscalYear,
                                                                           Inv_BU__c = item.buId, CurrencyIsoCode = buCurrenciesMap.get(item.buId).CurrencyIsoCode);
                    dispatchHeadList.add(dispatchHead);
                    dispatchHeadIndexMap.put(dispatchHeadKey, dispatchHeadList.size() - 1);
                }
                
                String key = wCondition.condition.Id + '' + item.buId + '' + item.sectionId + '' + item.pgId + '' + item.dcId;
                String fieldName = 'Fix_Amount_Dispatch_M' + sequence + '__c';
                if(!dispatchDetailsMap.containsKey(key)) {
                    if(total == 0)
                        continue; // skips to the next iteration of the loop if no amount to dispatch
                    // Create New dispatch Detail.
                    Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = wCondition.condition.Id, Contract__c = wCondition.condition.Contract__c,
                                                                                                  Supplier__c = wCondition.condition.Contract__r.Supplier__c, Inv_BUDispatch__c = item.buId,
                                                                                                  Hierarchy_level_dispatch__c = item.sectionId, PG__c = item.pgId, Status__c = 'New',
                                                                                                  Sequence__c = sequence, CurrencyIsoCode = wCondition.condition.CurrencyIsoCode,
                                                                                                  Purchases_Flow_PG__c = item.purshaseId);
                    dispatchDetailsLine.put(fieldName, total);
                    if(item.storeToDC) {
                        dispatchDetailsLine.Order_to_DC__c = item.dcId;
                    }
                    Integer index = dispatchHeadIndexMap.get(dispatchHeadKey);
                    if(!mapOfNewDD.containsKey(index)) {
                        mapOfNewDD.put(index, new List<Inv_BUDispatch_Details__c>{dispatchDetailsLine});
                    }
                    else {
                        mapOfNewDD.get(index).add(dispatchDetailsLine);
                    }
                    dispatchDetailsMap.put(key, dispatchDetailsLine);
                } else {
                    Inv_BUDispatch_Details__c dd = dispatchDetailsMap.get(key);
                    dd.Status__c = 'Updated';
                    dd.put(fieldName, total);
                    dd.Sequence__c = sequence;
                    dd.Purchases_Flow_PG__c = item.purshaseId; 
                    dispatchDetailsList.add(dd);
                }
                if(!dispatchAggregateMode && item.purshaseId == null) {
                    nb.logError('failed to link dispatch detail line to the purchase line >>> Many Purshases for the same BU and PG');
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            String[] dispatchHeadFields = new String[] {NegoptimHelper.normalizeAPIName('Sequence_Number__c'), NegoptimHelper.normalizeAPIName('Inv_Fiscal_Year__c'), NegoptimHelper.normalizeAPIName('Inv_BU__c')};
            String[] dispatchDetailsFieldsForCreate = new String[] {NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Base_TO_Dispatch__c'), NegoptimHelper.normalizeAPIName('Sequence__c'), NegoptimHelper.normalizeAPIName('Inv_DispatchHead__c')};
            String[] dispatchDetailsFieldsForUpdate = new String[] {NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Base_TO_Dispatch__c'), NegoptimHelper.normalizeAPIName('Sequence__c')};
            if(NegoptimHelper.checkCreatibility(Inv_BUDispatch__c.SObjectType, dispatchHeadFields)
               && NegoptimHelper.checkUpdatibility(Inv_BUDispatch__c.SObjectType, dispatchHeadFields)
               && NegoptimHelper.checkCreatibility(Inv_BUDispatch_Details__c.SObjectType, dispatchDetailsFieldsForCreate)
               && NegoptimHelper.checkUpdatibility(Inv_BUDispatch_Details__c.SObjectType, dispatchDetailsFieldsForUpdate))
            {
                upsert dispatchHeadList;
                for(Integer i : mapOfNewDD.keySet()) {
                    for(Inv_BUDispatch_Details__c item : mapOfNewDD.get(i)) {
                        item.Inv_DispatchHead__c = dispatchHeadList.get(i).Id;
                        dispatchDetailsList.add(item);
                    }
                }
                upsert dispatchDetailsList;
            }
        } catch(DmlException e) {
            nb.logError('DMLException >>>' + e.getDmlFields(0) + ' - ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
            Database.rollback(sp);
        } catch (Exception e) {
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
            // Roll everything back in case of error.
            Database.rollback(sp);
        }
        nb.saveLog(bc);
    }
    
    /* Wrapper Condition class */
    public class WrapperCondition {
        
        public Contract_Discount__c condition {get;set;}
        public Decimal amountToDispatch;
        public Decimal totalConditionPrurchases;
        public List<Supplier_PG_Mapping__c> PGs {get; set;}
        public Set<Id> BUIds {get; set;}
        public List<WrapperPurchase> wPurchasesList;
        public List<WrapperDispatchDetail> wDispatchDetailList;
        public List<Inv_BUDispatch_Details__c> dispatchDetailsList;
        public Integer fiscalYear {
            get {
                return condition.Disc_BDate__c.year();
            }
            set;
        }
        
        public List<Id> PGIds {
            get {
                List<Id> PGList = new List<Id>();
                for (Supplier_PG_Mapping__c pg : PGs) {
                    PGList.add(pg.Id);
                }
                return PGList;
            }
            set;
        }
        
        public WrapperCondition(Contract_Discount__c c) {
            condition = c;
            PGs = new List<Supplier_PG_Mapping__c>();
            PGIds = new List<Id>();
            BUIds = new Set<Id>();
            wPurchasesList = new List<WrapperPurchase>();
            wDispatchDetailList = new List<WrapperDispatchDetail>();
            dispatchDetailsList = new List<Inv_BUDispatch_Details__c>();
            totalConditionPrurchases = 0;
        }
        // create list of dispatch details if condition doesn't have any entry
        public void init(Integer sequence) {
            for (Id item : BUIds) {
                for (Supplier_PG_Mapping__c pg : PGs) {
                    Inv_BUDispatch_Details__c dispatchDetailsLine =
                        new Inv_BUDispatch_Details__c(Discount__c = condition.Id, Contract__c = condition.Contract__c,
                                                      Supplier__c = condition.Contract__r.Supplier__c, Inv_BUDispatch__c = item,
                                                      Hierarchy_level_dispatch__c = pg.Section__c, PG__c = pg.Id, Status__c = 'New',
                                                      Sequence__c = sequence, CurrencyIsoCode = condition.CurrencyIsoCode);
                    dispatchDetailsList.add(dispatchDetailsLine);
                }
            }
        }
        // get list of corresponding purchases
        public void getPurchases(Map<String, List<WrapperPurchase>> wPurchasesMap) {
            for(Id item : BUIds) {
                for(Supplier_PG_Mapping__c pg : PGs) {
                    String key = item + '' + pg.Id;
                     if(wPurchasesMap.containsKey(key)) {
                        if(wPurchasesMap.get(key).size() == 1)
                          wPurchasesList.addAll(wPurchasesMap.get(key));
                        else {
                            WrapperPurchase purshaseItem = wPurchasesMap.get(key).get(0);
                            for(Integer i = 1; i< wPurchasesMap.get(key).size(); i++) {
                                purshaseItem.YTD += wPurchasesMap.get(key).get(i).YTD;
                            }
                            purshaseItem.purshaseId = null;
                            wPurchasesList.add(purshaseItem);
                        }
                    }
                }
            }
        }
    }
    /* Wrapper class for Dispatch Detail */
    public class WrapperDispatchDetail {
        
        public Id buId {get; set;}
        public Id sectionId {get; set;}
        public Id pgId {get; set;}
        public Id dcId {get; set;}
        public Id purshaseId {get; set;}
        public Boolean storeToDC {get; set;}
        public Decimal baseTO {get; set;}
        public Decimal amount {get;set;}
        
        public void calculate(Decimal conditionTotalAmount, Decimal amountToDispatch) {
            this.amount = conditionTotalAmount != 0 ? (baseTO / conditionTotalAmount * amountToDispatch) : 0;
        }
    }
    /* Wrapper class for Purchase */
    public class WrapperPurchase {
        public Id buId {get; set;}
        public Id sectionId {get; set;}
        public Id pgId {get; set;}
        public Id dcId {get; set;}
        public Id purshaseId {get; set;}
        public Decimal YTD {get; set;}
        public Decimal to1 {get;set;}
        public Decimal to2 {get;set;}
        public Decimal to3 {get;set;}
        public Decimal to4 {get;set;}
        public Decimal to5 {get;set;}
        public Decimal to6 {get;set;}
        public Decimal to7 {get;set;}
        public Decimal to8 {get;set;}
        public Decimal to9 {get;set;}
        public Decimal to10 {get;set;}
        public Decimal to11 {get;set;}
        public Decimal to12 {get;set;}
        public String key {
            get {
                return buId + '' + pgId;
            }
            set;
        }
    }
}