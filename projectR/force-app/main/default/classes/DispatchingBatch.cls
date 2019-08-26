/**
* Batchable class used to Dispatch the TO of conditions per contract or per selected list of conditions.
**/
public with sharing class DispatchingBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final List<Id> contractIds;
    public final List<Id> conditionIds;
    public final Date selectedDate;
    // Global Settings
    private NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
    private Integer closingDay;
    private Boolean dispatchAggregateMode;
    
    // Constructor.
    public DispatchingBatch(String startedFrom, Id countryId, List<Id> cIds, List<Id> condIds, date d) {
        this.nb = new NegoptimBatch('Dispatching of Conditions in %', NegoptimBatch.BatchType.Stateless, startedFrom);
        this.country = countryId;
        this.contractIds = cIds;
        this.conditionIds = condIds;
        this.selectedDate = d == null ? Date.today() : d;
        this.closingDay = negoSettings.invoiceMaxClosingDay;
        this.dispatchAggregateMode = negoSettings.dispatchAggregateMode;
        // Declare the query to get conditions.
        String q = 'SELECT Id, Name, CurrencyIsoCode, Contract__c, Contract__r.Supplier__c, Disc_BDate__c, Disc_EDate__c, BU_Scope__c, Product_Scope__c';
        q += ' FROM Contract_Discount__c';
        q += ' WHERE Contract__r.Contract_Type__c = \'Contract\'';
        q += ' AND (Value_per__c <> null OR Is_Conditional__c = true)';
        if(this.country != null) {
            q += ' AND Contract__r.Contract_BU__c = \'' + this.country + '\'';    
        }
        if(this.contractIds != null && this.contractIds.size() > 0) {
            q += ' AND Contract__c IN (\'' + String.join(this.contractIds, '\',\'') +'\')';
        }
        ////else if(d != null) {
        ////    q += ' AND Contract__r.Reference_Year__c = ' + this.selectedDate.year() + '';
        ////}
        if(this.conditionIds != null && this.conditionIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(this.conditionIds, '\',\'') +'\')';
        }
        // Don't filter on reference year unless there are no filters on the contractIds or conditionIds
        if((this.contractIds == null || this.contractIds.isEmpty())
            && (this.conditionIds == null || this.conditionIds.isEmpty())
            && d != null)
        {
            q += ' AND Contract__r.Reference_Year__c = ' + this.selectedDate.year() + '';
        }
        this.query = q;
        // Set default value if null or 0
        closingDay = closingDay == null || closingDay == 0 ? 31 : closingDay;
        // push inputs to log
        nb.logParameter('counrty', this.country);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('conditionIds', this.conditionIds);
        nb.logParameter('selectedDate', this.selectedDate);
        nb.logParameter('query', this.query);
        nb.logParameter('closingDay', this.closingDay);
        nb.logParameter('dispatchAggregateMode', this.dispatchAggregateMode);
    }
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method.
    public void execute(Database.BatchableContext bc, List<Contract_Discount__c> scope) {
        // Loop over conditions
        // Get the sum of total TO grouped by BU and section
        //  identified the dispatch line dl for the conditions Negoptim__Inv_BUDispatch_Details__c by BU / HE / Condition id
        // if dl exist => status = update, else create status = new dispatch head and lines + sequence
        // put total to in Base TO Dispatch
        Set<Id> setOfBU = new Set<Id>();
        Set<Integer> fiscalYearSet = new Set<Integer>();
        for(Contract_Discount__c item : scope) {
            // Fill the Set of BU
            if(!setOfBU.contains(item.BU_Scope__c)) {
                setOfBU.add(item.BU_Scope__c);
            }
            // Fill the Set of Fiscal Years
            if(item.Disc_BDate__c != null && !fiscalYearSet.contains(item.Disc_BDate__c.year())) {
                fiscalYearSet.add(item.Disc_BDate__c.year());
            }
        }
        Date dispatchDate = this.selectedDate; ////Date.today();
        Integer sequence;
        if (dispatchDate.day() <= closingDay) {
            sequence = dispatchDate.month() == 1 ? 12 : dispatchDate.month() - 1;
        } else {
            sequence = dispatchDate.month();
        }
        ////Integer fiscalYear = dispatchDate.month() == 1 ? dispatchDate.year() -1 : dispatchDate.year();
        // Load map of currencies with exchange rate.
        Map<String, Double> currencies = NegoptimHelper.getCurrencyMap();
        // Single Instance of BusinessUnitHelper
        BusinessUnitHelper buHelper = BusinessUnitHelper.getInstance(setOfBU, 1);
        // Load Map of BUs
        Map<Id, Set<Id>> businessUnitsMap = buHelper.getBUChildrenIdsMap();
        // Map each BU Id to the corresponding currency.
        Map<Id, Orga_BU__c> buCurrenciesMap = buHelper.getBUMap(true);
        // Map each BU Id to the corresponding Record type.
        Map<Id, String> buRecordTypeMap = buHelper.getBURecordTypeNameMap(true);
        // List of dispatch details to be upserted.
        List<Inv_BUDispatch_Details__c> dispatchDetailsList = new List<Inv_BUDispatch_Details__c>();
        
        /***
        List<Orga_BU__c> orgbu = [Select Id, Name, CurrencyIsoCode, Business_Unit_Type__c,
                                  (Select Entity_List__r.Id, Entity_List__r.CurrencyIsoCode, Entity_List__r.Name, Entity_List__r.Business_Unit_Type__c
                                   From List_detail1__r WHERE /*Entity_List__r.Business_Unit_Type__c <> 'Warehouse' AND* / Entity_List__r.Status__c = 'Open')
                                  From Orga_BU__c WHERE Business_Unit_Type__c IN ('Store', 'Web', 'Warehouse', 'Country', 'List', 'Group')
                                  AND Status__c = 'Open' AND Id IN :setOfBU];
        // For loop to iterate through all the queried Orga_BU records.
        ////Map<Id, List<Id>> businessUnitsMap = new Map<Id, List<Id>>();
        for(Orga_BU__c buItem: orgbu) {
            // Filter list of BU for the current BU scope of type 'Store' or 'Web'
            if(buItem.Business_Unit_Type__c == 'Store' || buItem.Business_Unit_Type__c == 'Web' || buItem.Business_Unit_Type__c == 'Warehouse') {
                ////businessUnitsMap.put(buItem.Id, new List<Id>{buItem.Id});
                buCurrenciesMap.put(buItem.Id, buItem.CurrencyIsoCode);
                buTypeMap.put(buItem.Id, buItem.Business_Unit_Type__c);
            }
            // Filter list of BU details for the current BU scope of type 'Country' or 'List' or 'Group'.
            if(buItem.Business_Unit_Type__c == 'Country' || buItem.Business_Unit_Type__c == 'List' || buItem.Business_Unit_Type__c == 'Group') {
                List<Id> businessUnitsList = new List<Id>();
                for(Orga_BU_List_Detail__c item: buItem.List_detail1__r) {
                    businessUnitsList.add(item.Entity_List__r.Id);
                    buCurrenciesMap.put(item.Entity_List__r.Id, item.Entity_List__r.CurrencyIsoCode);
                    buTypeMap.put(item.Entity_List__r.Id, item.Entity_List__r.Business_Unit_Type__c);
                }
                ////businessUnitsMap.put(buItem.Id, businessUnitsList);
            }
        }***/
        // the corresponding invoice line based on sequence
        String refInvoiceLineFieldName = 'Invoice_Ref_M' + sequence + '__c';
        // Load corresponding Invoices details
        List<Invoice_Detail__c> invoiceDetailsList = [SELECT id, Discount__c
                                                      FROM Invoice_Detail__c
                                                      WHERE Discount__c IN :scope
                                                      AND Invoice__r.Sequence_Number__c = :sequence];
        // Map conditions id to invoice details id
        Map<Id, Id> invoiceDetailsMap = new Map<Id, Id>();
        for(Invoice_Detail__c item : invoiceDetailsList) {
            invoiceDetailsMap.put(item.Discount__c, item.id);
        }
        
        List<Id> listConditionId = new List<Id>();
        List<Id> listBUId = new List<Id>();
        List<Id> listSectionId = new List<Id>();
        List<Id> listPGId = new List<Id>();
        List<Id> listDCId = new List<Id>();
        List<WrapperDispatchDetail> wDispatchDetailList = new List<WrapperDispatchDetail>();
        // Loop over conditions and create Wrapper Dispatch Details.
        for(Contract_Discount__c condition : scope) {
            Set<Id> relatedBUSet = businessUnitsMap.get(condition.BU_Scope__c);
            Double conversionRate = currencies.get(condition.CurrencyIsoCode);
            listConditionId.add(condition.Id);
            Integer beginYear, endYear, firstMonth, lastMonth;
            beginYear = condition.Disc_BDate__c != null ? condition.Disc_BDate__c.year() : 1900; // min year
            endYear = condition.Disc_EDate__c != null ? condition.Disc_EDate__c.year() : 3000; // max year
            // Get the first and last month related to the condition.
            firstMonth = condition.Disc_BDate__c != null ? condition.Disc_BDate__c.month() : 1; // January
            lastMonth = condition.Disc_EDate__c != null ? condition.Disc_EDate__c.month() : 12; // December
            if(relatedBUSet != null) {
                List<Map<String, Object>> purchases = new List<Map<String, Object>>();               
                Boolean isAllYear = firstMonth == 1 && lastMonth == 12;
                // Total of months
                Decimal total;
                Map<String, Object> purchase;
                if (this.dispatchAggregateMode) {
                    if(isAllYear) {
                        // Get group of BU / Section / Total TO.
                        for (AggregateResult ar : [SELECT BU__c bu, Section__c section, PG__c pg, DC__c dc, SUM(YTD_TO__c) totalto
                                                   FROM Purchases_Flow_PG__c
                                                   WHERE PG__c IN (SELECT Sup_PG__c FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :condition.Product_Scope__c)
                                                   AND ((BU__c IN :relatedBUSet AND DC__c = NULL)
                                                        OR DC__c IN :relatedBUSet) // Redistribute to any indirect flow
                                                   AND Year__c >= :beginYear
                                                   AND Year__c <= :endYear
                                                   AND BU__r.Status__c = 'Open' // To make sure indirect flows are also for Open stores
                                                   GROUP BY BU__c, Section__c, PG__c, DC__c, CurrencyIsoCode])
                        {
                            purchase = new Map<String, Object>();
                            purchase.put('bu', ar.get('bu'));
                            purchase.put('dc', ar.get('dc'));
                            purchase.put('section', ar.get('section'));
                            purchase.put('pg', ar.get('pg'));
                            purchase.put('totalto', ar.get('totalto'));
                            purchases.add(purchase);
                        }
                    }
                    else {
                        for (AggregateResult ar : [SELECT BU__c bu, Section__c section, PG__c pg, DC__c dc,
                                                     SUM(TO1__c) total1,
                                                     SUM(TO2__c) total2,
                                                     SUM(TO3__c) total3,
                                                     SUM(TO4__c) total4,
                                                     SUM(TO5__c) total5,
                                                     SUM(TO6__c) total6,
                                                     SUM(TO7__c) total7,
                                                     SUM(TO8__c) total8,
                                                     SUM(TO9__c) total9,
                                                     SUM(TO10__c) total10,
                                                     SUM(TO11__c) total11,
                                                     SUM(TO12__c) total12
                                                     FROM Purchases_Flow_PG__c
                                                     WHERE PG__c IN (SELECT Sup_PG__c FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :condition.Product_Scope__c)
                                                     AND ((BU__c IN :relatedBUSet AND DC__c = NULL)
                                                          OR DC__c IN :relatedBUSet) // Redistribute to any indirect flow
                                                     AND Year__c >= :beginYear
                                                     AND Year__c <= :endYear
                                                     AND BU__r.Status__c = 'Open' // To make sure indirect flows are also for Open stores
                                                     GROUP BY BU__c, Section__c, PG__c, DC__c, CurrencyIsoCode])
                        {
                            purchase = new Map<String, Object>();
                            purchase.put('bu', ar.get('bu'));
                            purchase.put('dc', ar.get('dc'));
                            purchase.put('section', ar.get('section'));
                            purchase.put('pg', ar.get('pg'));
                            purchase.put('total1', ar.get('total1'));
                            purchase.put('total2', ar.get('total2'));
                            purchase.put('total3', ar.get('total3'));
                            purchase.put('total4', ar.get('total4'));
                            purchase.put('total5', ar.get('total5'));
                            purchase.put('total6', ar.get('total6'));
                            purchase.put('total7', ar.get('total7'));
                            purchase.put('total8', ar.get('total8'));
                            purchase.put('total9', ar.get('total9'));
                            purchase.put('total10', ar.get('total10'));
                            purchase.put('total11', ar.get('total11'));
                            purchase.put('total12', ar.get('total12'));
                            purchases.add(purchase);
                        }
                    }
                }
                else {
                    if(isAllYear) {
                        // Get group of BU / Section / Total TO.
                        for (Purchases_Flow_PG__c purchaseFlow : [SELECT BU__c, Section__c, PG__c, DC__c, YTD_TO__c
                                                                  FROM Purchases_Flow_PG__c
                                                                  WHERE PG__c IN (SELECT Sup_PG__c FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :condition.Product_Scope__c)
                                                                  AND ((BU__c IN :relatedBUSet AND DC__c = NULL)
                                                                       OR DC__c IN :relatedBUSet) // Redistribute to any indirect flow
                                                                  AND Year__c >= :beginYear
                                                                  AND Year__c <= :endYear
                                                                  // To make sure indirect flows are also for Open stores
                                                                  AND BU__r.Status__c = 'Open' ])
                        {
                            purchase = new Map<String, Object>();
                            purchase.put('id', purchaseFlow.Id);
                            purchase.put('bu', purchaseFlow.BU__c);
                            purchase.put('dc', purchaseFlow.DC__c);
                            purchase.put('section', purchaseFlow.Section__c);
                            purchase.put('pg', purchaseFlow.PG__c);
                            purchase.put('totalto', purchaseFlow.YTD_TO__c);
                            purchases.add(purchase);
                        }
                    }
                    else {
                        for (Purchases_Flow_PG__c purchaseFlow : [SELECT BU__c, Section__c, PG__c, DC__c,
                                                                  TO1__c, TO2__c, TO3__c, TO4__c, TO5__c, TO6__c,
                                                                  TO7__c, TO8__c, TO9__c, TO10__c, TO11__c, TO12__c
                                                                  FROM Purchases_Flow_PG__c
                                                                  WHERE PG__c IN (SELECT Sup_PG__c FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :condition.Product_Scope__c)
                                                                  AND ((BU__c IN :relatedBUSet AND DC__c = NULL)
                                                                       OR DC__c IN :relatedBUSet) // Redistribute to any indirect flow
                                                                  AND Year__c >= :beginYear
                                                                  AND Year__c <= :endYear
                                                                  // To make sure indirect flows are also for Open stores
                                                                  AND BU__r.Status__c = 'Open'])
                        {
                            purchase = new Map<String, Object>();
                            purchase.put('id', purchaseFlow.Id);
                            purchase.put('bu', purchaseFlow.BU__c);
                            purchase.put('dc', purchaseFlow.DC__c);
                            purchase.put('section', purchaseFlow.Section__c);
                            purchase.put('pg', purchaseFlow.PG__c);
                            purchase.put('total1', purchaseFlow.TO1__c);
                            purchase.put('total2', purchaseFlow.TO2__c);
                            purchase.put('total3', purchaseFlow.TO3__c);
                            purchase.put('total4', purchaseFlow.TO4__c);
                            purchase.put('total5', purchaseFlow.TO5__c);
                            purchase.put('total6', purchaseFlow.TO6__c);
                            purchase.put('total7', purchaseFlow.TO7__c);
                            purchase.put('total8', purchaseFlow.TO8__c);
                            purchase.put('total9', purchaseFlow.TO9__c);
                            purchase.put('total10', purchaseFlow.TO10__c);
                            purchase.put('total11', purchaseFlow.TO11__c);
                            purchase.put('total12', purchaseFlow.TO12__c);
                            purchases.add(purchase);
                        }
                    }
                }
                for (Map<String, Object> ar : purchases) {
                    total = 0;
                    if(isAllYear) {
                        total = (Decimal) ar.get('totalto');
                    }
                    else {
                        for(Integer i = firstMonth; i <= lastMonth; i++) {
                            if(ar.get('total' + i) != null) {
                                total += (Decimal) ar.get('total' + i);
                            }
                        }
                    }
                    Id buId = (Id) ar.get('bu'), sectionId = (Id) ar.get('section'),
                        dcId = (Id) ar.get('dc'), pgId = (Id) ar.get('pg');
                    if(buId == null || sectionId == null) throw new DispatchingBatchException('BU or Section is null');
                    listBUId.add(buId);
                    listSectionId.add(sectionId);
                    if(dcId != null) listDCId.add(dcId);
                    if(pgId != null) listPGId.add(pgId);
                    
                    WrapperDispatchDetail wDispatchDetail = new WrapperDispatchDetail();
                    wDispatchDetail.condition = condition;
                    wDispatchDetail.buId = buId;
                    wDispatchDetail.sectionId = sectionId;
                    wDispatchDetail.dcId = dcId;
                    wDispatchDetail.pgId = pgId;
                    wDispatchDetail.storeToDC = false;
                    if(buRecordTypeMap.get(buId) != null 
                       && (buRecordTypeMap.get(buId) == 'Store'
                           || buRecordTypeMap.get(buId) == 'Web'
                           || buRecordTypeMap.get(buId) == 'Banner')
                       && dcId != null)
                    {
                        wDispatchDetail.storeToDC = true;
                    }
                    wDispatchDetail.total = total * conversionRate;
                    if (!this.dispatchAggregateMode) wDispatchDetail.purchasesFlowPG = (Id) ar.get('id');
                    wDispatchDetailList.add(wDispatchDetail);
                }
            }
        }
        // Get Dispatch heads for existing BU.
        List<Inv_BUDispatch__c> dispatchHeadList = [SELECT Id, Inv_BU__c, Inv_Fiscal_Year__c FROM Inv_BUDispatch__c
                                                    WHERE Inv_BU__c IN :listBUId AND Inv_Fiscal_Year__c IN :fiscalYearSet];
        
        Integer pos = 0;
        Map<String, Integer> dispatchHeadIndexMap = new Map<String, Integer>();
        for(Inv_BUDispatch__c item : dispatchHeadList) {
            dispatchHeadIndexMap.put(item.Inv_BU__c + String.valueOf(Integer.valueOf(item.Inv_Fiscal_Year__c)), pos);
            pos++;
        }
        // Get Dispatch Details for existing BU and section.
        Map<String, Inv_BUDispatch_Details__c> dispatchDetailsMap = new Map<String, Inv_BUDispatch_Details__c>();
        for(Inv_BUDispatch_Details__c item : [SELECT Id, Discount__c, Inv_BUDispatch__c, Hierarchy_level_dispatch__c,
                                              PG__c, Order_to_DC__c, Purchases_Flow_PG__c
                                              FROM Inv_BUDispatch_Details__c
                                              WHERE Discount__c IN :listConditionId
                                              AND Inv_BUDispatch__c IN :listBUId
                                              AND Hierarchy_level_dispatch__c IN :listSectionId
                                              /*AND Order_to_DC__c IN :listDCId*/
                                              AND PG__c IN :listPGId])
        {
            String key = item.Discount__c + '' + item.Inv_BUDispatch__c + '' + item.Hierarchy_level_dispatch__c
                + '' + item.PG__c + '' + item.Order_to_DC__c;
            if (!this.dispatchAggregateMode) key += item.Purchases_Flow_PG__c;
            dispatchDetailsMap.put(key, item);
        }
        Map<Integer, List<Inv_BUDispatch_Details__c>> mapOfNewDD = new Map<Integer, List<Inv_BUDispatch_Details__c>>();
        for (WrapperDispatchDetail item : wDispatchDetailList) {
            // No dispatch head exist for the BU.
            String dispatchHeadKey = item.buId + String.valueOf(item.fiscalYear);
            if(!dispatchHeadIndexMap.containsKey(dispatchHeadKey)) {
                // Create New dispatch head.
                Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequence, Inv_Fiscal_Year__c = item.fiscalYear,
                                                                       Inv_BU__c = item.buId, CurrencyIsoCode = buCurrenciesMap.get(item.buId).CurrencyIsoCode);
                dispatchHeadList.add(dispatchHead);
                dispatchHeadIndexMap.put(dispatchHeadKey, dispatchHeadList.size() - 1);
            }
            
            String key = item.condition.Id + '' + item.buId + '' + item.sectionId + '' + item.pgId + '' + item.dcId;
            if (!this.dispatchAggregateMode) key += item.purchasesFlowPG;
            if(!dispatchDetailsMap.containsKey(key)) {
                if(item.total == 0)
                    continue; // skips to the next iteration of the loop if no amount to dispatch
                // Create New dispatch Detail.
                Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = item.condition.Id, Contract__c = item.condition.Contract__c,
                                                                                              Supplier__c = item.condition.Contract__r.Supplier__c, Inv_BUDispatch__c = item.buId,
                                                                                              Hierarchy_level_dispatch__c = item.sectionId, PG__c = item.pgId,
                                                                                              Base_TO_Dispatch__c = item.total, Status__c = 'New',
                                                                                              Sequence__c = sequence, CurrencyIsoCode = item.condition.CurrencyIsoCode);
                // set reference to purchase
                if (!this.dispatchAggregateMode) dispatchDetailsLine.Purchases_Flow_PG__c = item.purchasesFlowPG;
                // Set reference invoice line
                dispatchDetailsLine.put(refInvoiceLineFieldName, invoiceDetailsMap.get(item.condition.Id));
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
            }
            else {
                Inv_BUDispatch_Details__c dd = dispatchDetailsMap.get(key);
                dd.Status__c = 'Updated';
                dd.Base_TO_Dispatch__c = item.total;
                dd.Sequence__c = sequence;
                // Set reference invoice line
                dd.put(refInvoiceLineFieldName, invoiceDetailsMap.get(item.condition.Id));
                // TODO: update other fields
                dispatchDetailsList.add(dd);
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
            String errorMessage = 'Exception: ' +  e.getDmlFieldNames(0) + ' ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber();
            nb.logError(errorMessage);
            Database.rollback(sp);
        } catch (Exception e) {
            nb.logError(e);
            // Roll everything back in case of error.
            Database.rollback(sp);
        }
        nb.saveLog(bc);
    }
    // Finish
    public void finish(Database.BatchableContext bc) {
        String countryName = 'N/A';
        Integer year = selectedDate != null ? selectedDate.year() : Date.today().year();
        try {
            if(this.country != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :this.country LIMIT 1].Name;
        } catch(DmlException e) {
            nb.logError('Exception: ' + e.getDMLMessage(0) + ' - ' + e.getLineNumber());
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper class for Dispatch Detail. */
    public class WrapperDispatchDetail {
        public Contract_Discount__c condition {get;set;}
        public Id buId {get; set;}
        public Id sectionId {get; set;}
        public Id dcId {get; set;}
        public Id pgId {get; set;}
        public Boolean storeToDC {get; set;}
        public Decimal total {get; set;}
        public Id purchasesFlowPG {get; set;}
        public Integer fiscalYear {
            get {
                return condition.Disc_BDate__c != null ? condition.Disc_BDate__c.year() : (System.today().month() == 1 ? System.today().year() - 1 : System.today().year());
            }
            set;
        }
    }
    
    public class DispatchingBatchException extends Exception{}
}