/**
* Batchable class used to scan group Commercial Plan
**/
public with sharing class PromoConditionSynchroBatch implements Database.Batchable<SObject>, Database.stateful {
    
    private NegoptimBatch nb;
    private final String query;
    private Set<Id> contractIdSet;
    private Set<Id> conditionIdSet;
    // Global Settings for last closing day
    public Integer closingDay = GlobalSettingsManager.loadGlobalSettings().invoiceMaxClosingDay;
    
    // Constructor.
    public PromoConditionSynchroBatch(String startedFrom, List<Id> ids) {
        
        this.nb = new NegoptimBatch('Promo Condition Synchro Batch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.contractIdSet = new Set<Id>();
        this.conditionIdSet = new Set<Id>();
        
        String q = 'SELECT Id, Name, CurrencyIsoCode, Condition_Code__c, BU_Target__c, Event_Code__c, Start_Date__c, End_Date__c,';
        q += ' Supplier__c, Supplier__r.Name, Reference_Year__c, Contribution_Validated__c, Status__c, Action_ToDo__c,';
        q += ' (SELECT Id, Name, Statut__c, CurrencyIsoCode, Commercial_Event__c, Action_done__c, Contract__c, Contract__r.Supplier_Nego_Scope__c,';
        q += ' Contract__r.Contract_BU__c, Nego_Scope__c, Prenego_envelop__c, Supplier__c, Supplier__r.Code__c, Product__c,';
        q += ' Product__r.Name, Product__r.ProductCode, Product__r.Category__c, Product__r.Category__r.Parent_Element__c, Product__r.Brand__c, Product__r.Brand__r.Name,';
        q += ' COGS__c, Contribution_Unit_Quantity__c, Contribution_Unit_Amount__c, Regular_Purchase_Price__c, Regular_Sales_Price__c, Promo_Purchase_Price__c, Promo_Sales_Price__c, Volume_Period_Reference__c,';
        q += ' COGS_Init__c, Contribution_Unit_Quantity_Init__c, Contribution_Unit_Amount_Init__c, Regular_Purchase_Price_Init__c, Regular_Sales_Price_Init__c, Promo_Purchase_Price_Init__c, Promo_Sales_Price_Init__c, Volume_Reached__c';
        q += ' FROM Marketing_Event_Detail__r)';
        q += ' FROM Commercial_Plan__c WHERE (Status__c = \'Validated\' OR Status__c = \'Validate with fact data\')';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\')';
        }
        query = q;
        // push inputs to log
        nb.logParameter('commercialPlanIds', ids);
        nb.logParameter('query', this.query);
        // Set default value if null or 0
        closingDay = closingDay == null || closingDay == 0 ? 31 : closingDay;
    }
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Start Execute
    public void execute(Database.BatchableContext bc, List<Commercial_Plan__c> scope) {
        List<CommercialPlanWrapper> commercialPlanWrapperList = new List<CommercialPlanWrapper>();
        Set<String> conditionCodeSet = new Set<String>();
        Set<Id> businessUnitSet = new Set<Id>();
        Set<Integer> referenceYearSet = new Set<Integer>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> supplierSet = new Set<Id>();
        Set<Id> contractSet = new Set<Id>();
        Set<Id> conditionSet = new Set<Id>();
        Set<Id> negoScopeSet = new Set<Id>();
        Map<Id, Contract__c> contractMap = new Map<Id, Contract__c>();
        for(Commercial_Plan__c item : scope) {
            CommercialPlanWrapper wCommercialPlan = new CommercialPlanWrapper(item);
            
            // Fill condition code list
            if(item.Condition_Code__c != null){
                conditionCodeSet.add(item.Condition_Code__c);
            }
            if(item.Supplier__c != null){
                supplierSet.add(item.Supplier__c);
            }
            for(Commercial_Plan_Detail__c commercialPlanDetail : item.Marketing_Event_Detail__r) {
                if(commercialPlanDetail.Product__c != null && !productIdSet.contains(commercialPlanDetail.Product__c)) {
                    productIdSet.add(commercialPlanDetail.Product__c);
                }
                if(commercialPlanDetail.Contract__r.Supplier_Nego_Scope__c != null && !negoScopeSet.contains(commercialPlanDetail.Contract__r.Supplier_Nego_Scope__c)) {
                    negoScopeSet.add(commercialPlanDetail.Contract__r.Supplier_Nego_Scope__c);
                }
                wCommercialPlan.commercialPlanDetails.add(commercialPlanDetail);
            }
            
            // Fill contract and condition list
            if(wCommercialPlan.commercialPlanDetails.size() > 0){
                Commercial_Plan_Detail__c commercialPlanDetail = wCommercialPlan.commercialPlanDetails.get(0);
                if(wCommercialPlan.contractId == null && commercialPlanDetail.Contract__c != null){
                    contractSet.add(commercialPlanDetail.Contract__c);
                    wCommercialPlan.contractId = commercialPlanDetail.Contract__c;
                }
                if(wCommercialPlan.conditionId == null && commercialPlanDetail.Prenego_envelop__c != null){
                    conditionSet.add(commercialPlanDetail.Prenego_envelop__c);
                    wCommercialPlan.conditionId = commercialPlanDetail.Prenego_envelop__c;
                }
            }
            commercialPlanWrapperList.add(wCommercialPlan);
        }
        // Get contracts
        List<Contract__c> contracts = [SELECT Id, Name, CurrencyIsoCode, Supplier_Nego_Scope__c, Reference_Year__c, Contract_BU__c,
                                       (SELECT Id, Contract__c, CurrencyIsoCode, Nego_Discount_Type__c, Condition_Type__c, Value_amt__c, BU_Scope__c,
                                        Status__c, Disc_BDate__c, Disc_EDate__c, Is_Prenego_Envelop__c, Valid__c,
                                        Value_amt_event_M1__c, Value_amt_event_M2__c, Value_amt_event_M3__c, Value_amt_event_M4__c,
                                        Value_amt_event_M5__c, Value_amt_event_M6__c, Value_amt_event_M7__c, Value_amt_event_M8__c,
                                        Value_amt_event_M9__c, Value_amt_event_M10__c, Value_amt_event_M11__c, Value_amt_event_M12__c,
                                        Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c,
                                        Value_amt_disp_M5__c, Value_amt_disp_M6__c, Value_amt_disp_M7__c, Value_amt_disp_M8__c,
                                        Value_amt_disp_M9__c, Value_amt_disp_M10__c, Value_amt_disp_M11__c, Value_amt_disp_M12__c                                                      
                                        FROM Contract_Discounts__r WHERE Id IN :conditionSet)
                                       FROM Contract__c WHERE Id IN :contractSet];
        
        if(contracts != null && contracts.size() > 0) {
            contractMap = new Map<Id, Contract__c>(contracts);
        }
        
        // Get Policy Tariff condition.
        Map<String, Pol_Com_Condition__c> tarrifConditionMap = new Map<String, Pol_Com_Condition__c>();
        List<Pol_Com_Condition__c> tarrifConditions = [SELECT Id, Name, Condition_Code__c, Nego_Discount_Type__c FROM Pol_Com_Condition__c
                                                       WHERE Nego_Discount_Type__c <> NULL AND Condition_Code__c <> NULL 
                                                       AND Condition_Code__c IN :conditionCodeSet];
        if(tarrifConditions != null && tarrifConditions.size() > 0) {
            for(Pol_Com_Condition__c item : tarrifConditions){
                tarrifConditionMap.put(item.Condition_Code__c, item);
            }
        }
        
        // Map supplier PG
        Map<String, Supplier_PG_Mapping__c> supplierPGMap = new Map<String, Supplier_PG_Mapping__c>();
        Set<Id> pgSet = new Set<Id>();
        // Map NS_PG
        Map<Id, Set<Id>> nsPGMap = new Map<Id, Set<Id>>();
        // Get PG List and NS based on supplier PG.
        for(Supplier_PG_Mapping__c item : [SELECT Id, Product__c, Supplier__c, Section__c,
                                           (SELECT Id, Name, Sup_sup_NegoScope__c, Sup_PG__c FROM Supplier_Nego_Scope_PG__r
                                            WHERE Sup_sup_NegoScope__c IN :negoScopeSet)
                                           FROM Supplier_PG_Mapping__c
                                           WHERE Supplier__c IN :supplierSet])
        {
            String keyPG = item.Supplier__c + '' + item.Product__c;
            if(!supplierPGMap.containsKey(keyPG)) {
                supplierPGMap.put(keyPG, item);
                pgSet.add(item.Id);
            }
            
            for(Sup_NS_PG__c nsPG : item.Supplier_Nego_Scope_PG__r) {
                if(!nsPGMap.containsKey(nsPG.Sup_sup_NegoScope__c)) {
                    nsPGMap.put(nsPG.Sup_sup_NegoScope__c, new Set<Id> {nsPG.Sup_PG__c});
                } else {
                    nsPGMap.get(nsPG.Sup_sup_NegoScope__c).add(nsPG.Sup_PG__c);
                }
            }
        }

        // Get brand distributor based on supplier
        Set<String> brandDistributorSet = new Set<String>();
        for(Sup_Bra_Distributor__c item :[SELECT Brand__c, Supplier__c FROM Sup_Bra_Distributor__c WHERE Supplier__c IN :supplierSet]){
            String key = item.Supplier__c + '' + item.Brand__c;
            if(!brandDistributorSet.contains(key)){
                brandDistributorSet.add(key);
            }
        }
        
        //------------------ Conditions Process ---------------------//
        List<Supplier_PG_Mapping__c> clientAssortmentListToInsert = new List<Supplier_PG_Mapping__c>();
        ////List<Sup_NS_PG__c> nsPGListToInsert = new List<Sup_NS_PG__c>();
        List<Contract_Discount__c> conditionList = new List<Contract_Discount__c>();
        Map<Id, Commercial_Plan_Detail__c> commercialPlanDetailMap = new Map<Id, Commercial_Plan_Detail__c>();
        List<Commercial_Plan__c> commercialPlanList = new List<Commercial_Plan__c>();
        Map<Integer, CommercialPlanWrapper> promoConditionsMap = new Map<Integer, CommercialPlanWrapper>();
        Integer index = 0;
        for(CommercialPlanWrapper item : commercialPlanWrapperList) {
            // fill contract and condition
            if(item.contractId != null) {
                item.contract = contractMap.get(item.contractId);
                businessUnitSet.add(item.commercialPlan.BU_Target__c);
                referenceYearSet.add(Integer.valueOf(item.contract.Reference_Year__c));
                Map<Id, Contract_Discount__c> conditionLineMap = new Map<Id, Contract_Discount__c>(item.contract.Contract_Discounts__r);
                if(item.conditionId != null ) {
                    item.condition = conditionLineMap.get(item.conditionId);
                }
            } else {
                item.isValid = false;
                item.errorPromoMessage = System.Label.MSG_ContractNotExist + '\n';
            }
            // check if NS is not empty 
            if(item.contract != null && !nsPGMap.keySet().contains(item.contract.Supplier_Nego_Scope__c)) {
                item.isValid = false;
                item.errorPromoMessage += string.format(System.Label.MSG_NS_Empty, new String[]{ item.commercialPlan.Name }) + '\n';
            }
            // check if condition exist
            item.tarrifCondition = tarrifConditionMap.get(item.commercialPlan.Condition_Code__c);
            if(item.tarrifCondition == null) {
                item.isValid = false;
                item.errorPromoMessage += string.format(System.Label.MSG_Tarrif_Condition_Not_Found, new String[]{ item.commercialPlan.Name }) + '\n';
            }
            
            if(item.isValid && item.contract != null) {
                for(Commercial_Plan_Detail__c commercialPlanDetail : item.commercialPlanDetails) {
                    // check if brand distributor contains product brand
                    String keyBrand = item.commercialPlan.Supplier__c + '' + commercialPlanDetail.Product__r.Brand__c;
                    String errorPromoDetailMessage = '';
                    Boolean isValidPromoDetail = true;
                    if(!brandDistributorSet.contains(keyBrand)) {
                        item.isValid = false;
                        isValidPromoDetail = false;
                        errorPromoDetailMessage = string.format(System.Label.MSG_Supplier_Not_Distribute_Brand, new String[]{ item.commercialPlan.Name, item.commercialPlan.Supplier__r.Name, commercialPlanDetail.Product__r.Brand__r.Name }) + '\n';
                    }
                    
                    // check valid promo detail
                    if(!isValidPromoDetail) {
                        commercialPlanDetail.Action_done__c = errorPromoDetailMessage;
                        nb.logError(errorPromoDetailMessage);
                        commercialPlanDetailMap.put(commercialPlanDetail.Id, commercialPlanDetail);
                        continue;
                    } else if(String.isNotBlank(commercialPlanDetail.Action_done__c)) {
                        commercialPlanDetail.Action_done__c = '';
                        commercialPlanDetailMap.put(commercialPlanDetail.Id, commercialPlanDetail);
                    }
                    
                    // insert PG if not exist
                    String keyPG = item.commercialPlan.Supplier__c + '' + commercialPlanDetail.Product__c;
                    if(!supplierPGMap.containsKey(keyPG)) {
                        Supplier_PG_Mapping__c pg = new Supplier_PG_Mapping__c(Name = commercialPlanDetail.Product__r.Name,
                                                                               Supplier__c = item.commercialPlan.Supplier__c,
                                                                               Product__c = commercialPlanDetail.Product__c,
                                                                               Brand__c = commercialPlanDetail.Product__r.Brand__c,
                                                                               Department__c = commercialPlanDetail.Product__r.Category__r.Parent_Element__c,
                                                                               Section__c = commercialPlanDetail.Product__r.Category__c,
                                                                               SNA_Code__c = commercialPlanDetail.Supplier__r.Code__c + commercialPlanDetail.Product__r.ProductCode,
                                                                               GIMA_Code__c = commercialPlanDetail.Supplier__r.Code__c + commercialPlanDetail.Product__r.ProductCode);                        
                        clientAssortmentListToInsert.add(pg);
                    }
                }
            } else if(!item.isValid && String.isNotBlank(item.errorPromoMessage)) {
                for(Commercial_Plan_Detail__c commercialPlanDetail : item.commercialPlanDetails) {
                    commercialPlanDetail.Action_done__c = item.errorPromoMessage;
                    commercialPlanDetailMap.put(commercialPlanDetail.Id, commercialPlanDetail);
                }
                nb.logError(item.errorPromoMessage);
            }
            
            // generate conditions
            if(item.isValid && item.contract != null && item.tarrifCondition != null) {
                if(item.condition != null){
                    item.updateContractLine();
                }
                else {
                    item.generateContractLine();
                }
                conditionList.add(item.condition);
                promoConditionsMap.put(index, item);
                index++;
                if(String.isNotBlank(item.commercialPlan.Action_ToDo__c)) {
                    item.commercialPlan.Action_ToDo__c = '';
                    commercialPlanList.add(item.commercialPlan);
                }
            } else {
                item.commercialPlan.Action_ToDo__c = System.Label.MSG_Error_Occurred;
                if(item.commercialPlan.Status__c == 'Validated') {
                    item.commercialPlan.Status__c = 'In preparation';
                } else if(item.commercialPlan.Status__c == 'Validate with fact data') {
                    item.commercialPlan.Status__c = 'Update with fact data';
                }
                commercialPlanList.add(item.commercialPlan);
            }
        }
        
        Savepoint sp = Database.setSavepoint();
        try {
            // Check supplierPG insert field security
            String[] supplierPGFields = new String[] {'Name', NegoptimHelper.normalizeAPIName('Product__c'), NegoptimHelper.normalizeAPIName('Nego_Scope__c'), 
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Department__c'),
                NegoptimHelper.normalizeAPIName('Section__c'), NegoptimHelper.normalizeAPIName('SNA_Code__c'), NegoptimHelper.normalizeAPIName('GIMA_Code__c')};    
            
            if (NegoptimHelper.checkCreatibility(Supplier_PG_Mapping__c.SObjectType, supplierPGFields) && clientAssortmentListToInsert.size() > 0) {
                List<Database.SaveResult> results = Database.insert(clientAssortmentListToInsert, false);
                nb.logResults(results, clientAssortmentListToInsert);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results.get(i);
                    Supplier_PG_Mapping__c pg = clientAssortmentListToInsert.get(i);
                    if (result.isSuccess()){
                        String key = pg.Supplier__c + '' + pg.Product__c;
                        if(!supplierPGMap.containsKey(key)) {
                            supplierPGMap.put(key, pg);
                            pgSet.add(pg.Id);
                        }
                    }
                }
            }
            
            // Check contract line upsert field security
            String[] conditionFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Product_Scope__c'), 
                NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'), NegoptimHelper.normalizeAPIName('Condition_Type__c'),
                NegoptimHelper.normalizeAPIName('Value_amt__c'), NegoptimHelper.normalizeAPIName('BU_Scope__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Disc_BDate__c'),
                NegoptimHelper.normalizeAPIName('Disc_EDate__c'), NegoptimHelper.normalizeAPIName('Is_Prenego_Envelop__c'),
                NegoptimHelper.normalizeAPIName('Valid__c'), NegoptimHelper.normalizeAPIName('Invoice_base__c'),
                NegoptimHelper.normalizeAPIName('Invoice_period__c'), NegoptimHelper.normalizeAPIName('first_invoice_date__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_event_M1__c'), NegoptimHelper.normalizeAPIName('Value_amt_event_M2__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_event_M3__c'), NegoptimHelper.normalizeAPIName('Value_amt_event_M4__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_event_M5__c'), NegoptimHelper.normalizeAPIName('Value_amt_event_M6__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_event_M7__c'), NegoptimHelper.normalizeAPIName('Value_amt_event_M8__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_event_M9__c'), NegoptimHelper.normalizeAPIName('Value_amt_event_M10__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_event_M11__c'), NegoptimHelper.normalizeAPIName('Value_amt_event_M12__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M1__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M2__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M3__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M4__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M5__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M6__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M7__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M8__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M9__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M10__c'),
                NegoptimHelper.normalizeAPIName('Value_amt_disp_M11__c'), NegoptimHelper.normalizeAPIName('Value_amt_disp_M12__c'),
                NegoptimHelper.normalizeAPIName('Commercial_Reference__c')};
            
            String[] conditionInsertFields = new String [] {NegoptimHelper.normalizeAPIName('Contract__c')};
            conditionInsertFields.addAll(conditionFields);
            
            // upsert conditions
            List<CommercialPlanWrapper> promoList = new List<CommercialPlanWrapper>();
            if(NegoptimHelper.checkCreatibility(Contract_Discount__c.SObjectType, conditionInsertFields) &&
               NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionFields) &&
               conditionList.size() > 0)
            {
                List<Database.UpsertResult> results = Database.upsert(conditionList, false);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results.get(i);
                    Contract_Discount__c condition = conditionList.get(i);
                    CommercialPlanWrapper wCommercialPlan = promoConditionsMap.get(i);
                    if (!result.isSuccess()){
                        String errorMessage = '';
                        Database.Error[] errs = result.getErrors();
                        for (Database.Error err : errs){
                            errorMessage += err.getFields() + ' : ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                        }
                        nb.logError(errorMessage);
                    } else {
                        wCommercialPlan.condition = condition;
                        wCommercialPlan.conditionId = condition.Id;
                        for(Commercial_Plan_Detail__c item : wCommercialPlan.commercialPlanDetails) {
                            if(String.isBlank(item.Prenego_envelop__c)) {
                                if(commercialPlanDetailMap.containsKey(item.Id)) item = commercialPlanDetailMap.get(item.Id);
                                item.Prenego_envelop__c = condition.Id;
                                // fill history promo detail
                                item.COGS_Init__c = item.COGS__c;
                                item.Contribution_Unit_Quantity_Init__c  = item.Contribution_Unit_Quantity__c;
                                item.Contribution_Unit_Amount_Init__c = item.Contribution_Unit_Amount__c;
                                item.Regular_Purchase_Price_Init__c = item.Regular_Purchase_Price__c;
                                item.Regular_Sales_Price_Init__c = item.Regular_Sales_Price__c;
                                item.Promo_Purchase_Price_Init__c = item.Promo_Purchase_Price__c;
                                item.Promo_Sales_Price_Init__c = item.Promo_Sales_Price__c;
                                item.Volume_Reached__c = item.Volume_Period_Reference__c;
                                commercialPlanDetailMap.put(item.Id, item);
                            }
                        }
                        promoList.add(wCommercialPlan);
                    }
                }
            }
            
            // Check commercial plan detail update field security
            String[] commercialPlanDetailFields = new String [] {NegoptimHelper.normalizeAPIName('Prenego_envelop__c'), NegoptimHelper.normalizeAPIName('Action_done__c')};            
            
            // update commercial plan details
            if(NegoptimHelper.checkUpdatibility(Commercial_Plan_Detail__c.SObjectType, commercialPlanDetailFields) && !commercialPlanDetailMap.isEmpty()) {
                List<Database.SaveResult> results = Database.update(commercialPlanDetailMap.values(), false);
                nb.logResults(results, commercialPlanDetailMap.values());
            }
            
            // Check commercial plan update field security
            String[] commercialPlanFields = new String [] {NegoptimHelper.normalizeAPIName('Action_ToDo__c')};            
            
            // update commercial plan
            if(NegoptimHelper.checkUpdatibility(Commercial_Plan__c.SObjectType, commercialPlanFields) && commercialPlanList.size() > 0) {
                List<Database.SaveResult> results = Database.update(commercialPlanList, false);
                nb.logResults(results, commercialPlanList);
            }
                        
            //--------------------- Dispatching Process -----------------------//
            // List of dispatch details to be upserted
            List<Inv_BUDispatch_Details__c> dispatchDetailsList = new List<Inv_BUDispatch_Details__c>();
            Map<String, List<Inv_BUDispatch_Details__c>> newDispatchDetailsMap = new Map<String, List<Inv_BUDispatch_Details__c>>();
            if(promoList.size() > 0) {
                // Load Map of BUs
                Map<Id, Set<Id>> businessUnitsMap = NegoptimHelper.getBUChildrenMap(businessUnitSet);
                List<Id> listBUId = new List<Id>();
                if(businessUnitsMap.size() > 0) {
                    for(Id buId : businessUnitsMap.keySet()) {
                        listBUId.addAll(businessUnitsMap.get(buId));
                    }
                }
                // Get Dispatch heads for existing BU.
                List<Inv_BUDispatch__c> dispatchHeadList = [SELECT Id, Inv_BU__c, Inv_Fiscal_Year__c FROM Inv_BUDispatch__c
                                                            WHERE Inv_BU__c IN :listBUId AND Inv_Fiscal_Year__c IN :referenceYearSet];
                // Map BU and dispatch head
                Map<String, Inv_BUDispatch__c> dispatchHeadMap = new Map<String, Inv_BUDispatch__c>();
                for(Inv_BUDispatch__c item : dispatchHeadList) {
                    String key = item.Inv_BU__c + '' + String.valueOf(Integer.valueOf(item.Inv_Fiscal_Year__c));
                    dispatchHeadMap.put(key, item);
                }
                
                // Get Dispatch Details for existing BU and section.
                Map<String, Inv_BUDispatch_Details__c> dispatchDetailsMap = new Map<String, Inv_BUDispatch_Details__c>();
                for(Inv_BUDispatch_Details__c item : [SELECT Id, Inv_DispatchHead__c, Discount__c, Inv_BUDispatch__c,
                                                      Hierarchy_level_dispatch__c, PG__c, Order_to_DC__c
                                                      FROM Inv_BUDispatch_Details__c
                                                      WHERE Discount__c IN :conditionList
                                                      AND Inv_BUDispatch__c IN :listBUId])
                {
                    String key = item.Discount__c + '' + item.Inv_BUDispatch__c + '' + item.PG__c;
                    dispatchDetailsMap.put(key, item);
                }
                
                //get last closing day
                Integer sequenceClosingDay;
                Date dispatchDate = Date.today();
                if (dispatchDate.day() <= closingDay) {
                    sequenceClosingDay = dispatchDate.month() == 1 ? 12 : dispatchDate.month() - 1;
                } else {
                    sequenceClosingDay = dispatchDate.month();
                }
                // Get purchase flow pg list
                Map<String, Purchases_Flow_PG__c> purchaseFlowPGMap = new Map<String, Purchases_Flow_PG__c>();
                for(Purchases_Flow_PG__c item : [SELECT Id, Name, Year__c, Sequence__c, BU__c, PG__c
                                                 FROM Purchases_Flow_PG__c
                                                 WHERE PG__c IN :pgSet
                                                 AND BU__c IN :listBUId])
                {
                    String key = item.Year__c + '' + item.BU__c + '' + item.PG__c;
                    purchaseFlowPGMap.put(key, item);
                }
                for(CommercialPlanWrapper item : promoList) {
                    Integer sequenceStartPromo = item.commercialPlan.Start_Date__c.month();
                    // fill list of contract and condition for generate invoice batch
                    this.contractIdSet.add(item.contractId);
                    this.conditionIdSet.add(item.conditionId);
                    
                    List<Id> BUListIds = new List<Id>();
                    if(businessUnitsMap.size() > 0) {
                        BUListIds.addAll(businessUnitsMap.get(item.commercialPlan.BU_Target__c));
                    }
                    Integer referenceYear = Integer.valueOf(item.contract.Reference_Year__c);
                    // Loop over BU and create Dispatch Head.
                    for(Id buId : BUListIds) {
                        // No dispatch head exist for the BU.
                        String dispatchHeadKey = buId + '' + String.valueOf(referenceYear);
                        if(!dispatchHeadMap.containsKey(dispatchHeadKey)) {
                            // Create New dispatch head.
                            Inv_BUDispatch__c dispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = sequenceClosingDay, Inv_Fiscal_Year__c = referenceYear,
                                                                                   Inv_BU__c = buId, CurrencyIsoCode = item.condition.CurrencyIsoCode);
                            dispatchHeadList.add(dispatchHead);
                            dispatchHeadMap.put(dispatchHeadKey, dispatchHead);
                        }
                        
                        for(Commercial_Plan_Detail__c commercialPlanDetail : item.commercialPlanDetails){
                            // Get PG
                            String keyPG = commercialPlanDetail.Supplier__c + '' + commercialPlanDetail.Product__c;
                            Supplier_PG_Mapping__c supplierPG = supplierPGMap.get(keyPG);                
                            if(supplierPG == null) continue;
                            // Get Purchase_Flow_PG
                            String keyPurchase = String.valueOf(referenceYear) + '' + buId + '' + supplierPG.Id;
                            Purchases_Flow_PG__c purchase = purchaseFlowPGMap.get(keyPurchase);
                            // Fill dispatch details
                            String keyDispatch = item.condition.Id + '' + buId + '' + supplierPG.Id;
                            if(!dispatchDetailsMap.containsKey(keyDispatch)) {
                                // Create New dispatch Detail.
                                Inv_BUDispatch_Details__c dispatchDetailsLine = new Inv_BUDispatch_Details__c(Discount__c = item.conditionId, 
                                                                                                              Contract__c = item.contractId,
                                                                                                              Purchases_Flow_PG__c = purchase != null ? purchase.Id : null,
                                                                                                              Supplier__c = item.commercialPlan.Supplier__c, 
                                                                                                              Inv_BUDispatch__c = buId,
                                                                                                              Hierarchy_level_dispatch__c = supplierPG.Section__c, 
                                                                                                              PG__c = supplierPG.Id,
                                                                                                              Status__c = 'New',
                                                                                                              Sequence__c = sequenceClosingDay, 
                                                                                                              CurrencyIsoCode = item.condition.CurrencyIsoCode);
                                String fieldNameFixAmount = 'Fix_Amount_Dispatch_M' + sequenceStartPromo + '__c';
                                dispatchDetailsLine.put(fieldNameFixAmount, commercialPlanDetail.Contribution_Unit_Amount__c);
                                
                                if(!newDispatchDetailsMap.containsKey(dispatchHeadKey)) {
                                    newDispatchDetailsMap.put(dispatchHeadKey, new List <Inv_BUDispatch_Details__c>{dispatchDetailsLine});
                                }
                                else {
                                    newDispatchDetailsMap.get(dispatchHeadKey).add(dispatchDetailsLine);
                                }
                            }
                            else {
                                // update dispatch details
                                Inv_BUDispatch_Details__c dispatchDetailsLine = dispatchDetailsMap.get(keyDispatch);
                                String fieldNameFixAmount;
                                // case update promo fact
                                if(item.commercialPlan.Status__c == 'Validate with fact data') {
                                    //
                                }
                                // reset all fix amount dispatch
                                for(Integer i = 1; i <= 12; i++) {
                                    fieldNameFixAmount = 'Fix_Amount_Dispatch_M' + i + '__c';             
                                    dispatchDetailsLine.put(fieldNameFixAmount, null);                
                                }
                                dispatchDetailsLine.Sequence__c = sequenceClosingDay;
                                dispatchDetailsLine.Status__c = 'Updated';
                                fieldNameFixAmount = 'Fix_Amount_Dispatch_M' + sequenceStartPromo + '__c';
                                dispatchDetailsLine.put(fieldNameFixAmount, commercialPlanDetail.Contribution_Unit_Amount__c);
                                dispatchDetailsList.add(dispatchDetailsLine);
                            }
                        }
                    }
                }
                
                // check security on upsert dispatch fields
                String[] dispatchHeadFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Sequence_Number__c'), 
                    NegoptimHelper.normalizeAPIName('Inv_Fiscal_Year__c'), NegoptimHelper.normalizeAPIName('Inv_BU__c')};
                
                // check security on upsert dispatch detail fields
                String[] dispatchDetailFields = new String[] {'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Contract__c'),
                    NegoptimHelper.normalizeAPIName('Sequence__c'), NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                    NegoptimHelper.normalizeAPIName('Inv_BUDispatch__c'), NegoptimHelper.normalizeAPIName('Hierarchy_level_dispatch__c'), 
                    NegoptimHelper.normalizeAPIName('PG__c'), NegoptimHelper.normalizeAPIName('Order_to_DC__c'),
                    NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M1__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M2__c'),
                    NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M3__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M4__c'),                    
                    NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M5__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M6__c'),
                    NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M7__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M8__c'),
                    NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M9__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M10__c'),
                    NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M11__c'), NegoptimHelper.normalizeAPIName('Fix_Amount_Dispatch_M12__c')};                                       
                        
                String [] dispatchDetailsFieldsForCreate = new String [] {NegoptimHelper.normalizeAPIName('Discount__c'), NegoptimHelper.normalizeAPIName('Inv_DispatchHead__c')};
                dispatchDetailsFieldsForCreate.addAll(dispatchDetailFields);
                
                if(NegoptimHelper.checkCreatibility(Inv_BUDispatch__c.SObjectType, dispatchHeadFields) &&
                   NegoptimHelper.checkUpdatibility(Inv_BUDispatch__c.SObjectType, dispatchHeadFields) &&
                   NegoptimHelper.checkCreatibility(Inv_BUDispatch_Details__c.SObjectType, dispatchDetailsFieldsForCreate) &&
                   NegoptimHelper.checkUpdatibility(Inv_BUDispatch_Details__c.SObjectType, dispatchDetailFields))
                {
                    // upsert dispatch head list
                    if(dispatchHeadList.size() > 0){
                        List<Database.UpsertResult> dispatchHeadResults = Database.upsert(dispatchHeadList, false);
                        nb.logResults(dispatchHeadResults, dispatchHeadList);
                    }
                    for(String key : newDispatchDetailsMap.keySet()) {
                        Inv_BUDispatch__c dispatchHead = dispatchHeadMap.get(key);
                        List<Inv_BUDispatch_Details__c> ddList = newDispatchDetailsMap.get(key);
                        if(dispatchHead != null && ddList != null && ddList.size() > 0){
                            for(Inv_BUDispatch_Details__c item : ddList) {
                                item.Inv_DispatchHead__c = dispatchHead.Id;
                                dispatchDetailsList.add(item);
                            }
                        }
                    }
                    // upsert dispatch details
                    if(dispatchDetailsList.size() > 0){
                        List<Database.UpsertResult> dispatchDetailResults = Database.upsert(dispatchDetailsList, false);
                        nb.logResults(dispatchDetailResults, dispatchDetailsList);
                    }
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        // Generate Invoices Batch.
        if (contractIdSet != null && contractIdSet.size() > 0 && conditionIdSet != null && conditionIdSet.size() > 0) {
            Database.executeBatch(new GenerateInvoicesBatch('PromoConditionSynchroBatch', null, new List<Id>(contractIdSet), new List<Id>(conditionIdSet), Date.today()));
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
        
    /* Commercial Plan Wrapper Class */
    public class CommercialPlanWrapper {
        
        public Commercial_Plan__c commercialPlan {get; set;}
        public List<Commercial_Plan_Detail__c> commercialPlanDetails {get; set;}
        public Contract__c contract {get; set;}
        public Contract_Discount__c condition {get; set;}
        public Pol_Com_Condition__c tarrifCondition {get; set;}
        public Id contractId {get; set;}
        public Id conditionId {get; set;}
        Boolean isValid {get; set;}
        String errorPromoMessage {get; set;}
        
        public CommercialPlanWrapper(Commercial_Plan__c cp) {
            this.commercialPlan = cp;
            this.commercialPlanDetails = new List<Commercial_Plan_Detail__c>();
            this.isValid = true;
            this.errorPromoMessage = '';
        }
        
        // update conditions
        private void updateContractLine() {
            this.condition.Value_amt__c = this.commercialPlan.Contribution_Validated__c;
            this.condition.Disc_BDate__c = this.commercialPlan.Start_Date__c;
            this.condition.Disc_EDate__c = this.commercialPlan.End_Date__c;
            
            String fieldValueAmtEventName, fieldValueAmtDispName;
            for(Integer i = 1; i <= 12; i++) {
                fieldValueAmtEventName = 'Value_amt_event_M' + i + '__c';
                fieldValueAmtDispName = 'Value_amt_disp_M' + i + '__c';
                this.condition.put(fieldValueAmtEventName, null);
                this.condition.put(fieldValueAmtDispName, null);
            }
            Decimal existingAmountValue = 0; String existingAmountEventName = '', newAmountEventName = '';
            Integer sequence = commercialPlan.Start_Date__c.month(); // amount should be distributed on start month only
            fieldValueAmtEventName = 'Value_amt_event_M' + sequence + '__c';
            fieldValueAmtDispName = 'Value_amt_disp_M' + sequence + '__c';
            existingAmountEventName = (String) this.condition.get(fieldValueAmtEventName);
            newAmountEventName = commercialPlan.Name + '' + commercialPlan.Start_Date__c.format() + '' + commercialPlan.End_Date__c.format();
            existingAmountValue = (Decimal) this.condition.get(fieldValueAmtDispName);
            if(existingAmountEventName != newAmountEventName){
                this.condition.put(fieldValueAmtEventName, newAmountEventName);
            }
            if(existingAmountValue != commercialPlan.Contribution_Validated__c){
                this.condition.put(fieldValueAmtDispName, commercialPlan.Contribution_Validated__c);
            }
        }
        
        // Create new condition
        private void generateContractLine() {
            this.condition = new Contract_Discount__c(Contract__c = this.contractId,
                                                      Product_Scope__c = this.contract.Supplier_Nego_Scope__c,
                                                      Nego_Discount_Type__c = this.tarrifCondition.Nego_Discount_Type__c,
                                                      Condition_Type__c = this.tarrifCondition.Id,
                                                      Value_amt__c = this.commercialPlan.Contribution_Validated__c,
                                                      BU_Scope__c = this.commercialPlan.BU_Target__c,
                                                      Status__c = 'Open',
                                                      Disc_BDate__c = this.commercialPlan.Start_Date__c,
                                                      Disc_EDate__c = this.commercialPlan.End_Date__c,
                                                      Is_Prenego_Envelop__c = false,
                                                      Valid__c = true,
                                                      Invoice_base__c = 'Actual (YTD)',
                                                      Invoice_period__c = 'Month',
                                                      first_invoice_date__c = NegoptimHelper.getLastDayOfMonth(this.commercialPlan.Start_Date__c),
                                                      CurrencyIsoCode = this.contract.CurrencyIsoCode,
                                                      Commercial_Reference__c = this.commercialPlan.Name);
            Integer sequence = commercialPlan.Start_Date__c.month(); // amount should be distributed on start month only
            String fieldValueAmtEventName = 'Value_amt_event_M' + sequence + '__c';
            String fieldValueAmtDispName = 'Value_amt_disp_M' + sequence + '__c';
            this.condition.put(fieldValueAmtEventName, this.commercialPlan.Name + '' + this.commercialPlan.Start_Date__c.format() + '' + this.commercialPlan.End_Date__c.format());
            this.condition.put(fieldValueAmtDispName, this.commercialPlan.Contribution_Validated__c);
        }
    }
}