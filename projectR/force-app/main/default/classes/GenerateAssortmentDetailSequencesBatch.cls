/*
 * Generate assortment details sequences and assortment matrix reviews
 */ 
public with sharing class GenerateAssortmentDetailSequencesBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    private final String query;
    
    // Constructor.
    public GenerateAssortmentDetailSequencesBatch(String startedFrom, Set<Id> assortmentDetailIds) {
        this.nb = new NegoptimBatch('GenerateAssortmentDetailSequencesBatch', NegoptimBatch.BatchType.Stateless, startedFrom);
        
        String q = ' SELECT Id, Assortment_BU__c, Year__c, Ass_BU_Cluster__c, Ref_BU_Cluster__c, Product__c, Product__r.RecordType.DeveloperName, Category__c, Record_date__c, Movement_Date__c, Client_Status__c,';
        q += ' Assortment_BU__r.RecordType.DeveloperName, Assortment_BU__r.BU_Source__c, Assortment_BU__r.BU_Target__c, New_Client_ND_MarketBased__c, New_Client_ND_ClientBased__c, New_Client_WD_MarketBased__c, New_Client_WD_ClientBased__c, New_Client_Quantity_SEQ__c,';
        q += ' Fact_ND_MarketBased__c, Fact_ND_ClientBased__c, Fact_WD_MarketBased__c, Fact_WD_ClientBased__c, Fact_SellOut_Tone_SEQ__c, Fact_SellOut_Quantity_SEQ__c, Fact_SellOut_SEQ__c,';
        q += ' Ref_Corp_Assortment__c, Ref_Client_ND_ClientBased__c, Ref_Client_WD_MarketBased__c, Ref_Client_WD_ClientBased__c, Last_History__c, Status__c,';
        q += ' Last_History__r.New_Client_ND_MarketBased__c, Last_History__r.New_Client_ND_ClientBased__c, Last_History__r.New_Client_WD_MarketBased__c, Last_History__r.New_Client_WD_ClientBased__c, Last_History__r.New_Client_Quantity_SEQ__c,';
        q += ' (SELECT Id, Product__c, Assortment_Detail__c, Assortment__c, Movement_Date__c, Record_date__c, Sequence__c, Year__c,';
        q += ' New_ND_MarketBased__c, New_ND_ClientBased__c, New_WD_MarketBased__c, New_WD_ClientBased__c, New_SellOut_Tone__c, New_SellOut_Quantity__c, New_SellOut__c,';
        q += ' Fx_ND_MarketBased__c, Fx_ND_ClientBased__c, Fx_WD_MarketBased__c, Fx_WD_ClientBased__c, Fx_SellOut_Tone__c, Fx_SellOut_Quantity__c, Fx_SellOut__c,';
        q += ' Fact_ND_MarketBased__c, Fact_ND_ClientBased__c, Fact_WD_MarketBased__c, Fact_WD_ClientBased__c, Fact_SellOut_Tone__c, Fact_SellOut_Quantity__c, Fact_SellOut__c,';
        q += ' Budget_ND_MarketBased__c, Budget_ND_ClientBased__c, Budget_WD_MarketBased__c, Budget_WD_ClientBased__c, Budget_SellOut_Tone__c, Budget_SellOut_Quantity__c, Budget_SellOut__c';
        q += ' FROM Assortment_Detail_Sequences__r)';
        q += ' FROM Assortment_Detail__c';
        q += ' WHERE Status__c = \'Validated\'';
        q += ' AND Version__c = NULL';
        q += ' AND Movement_Date__c <> NULL';
        q += ' AND Client_Status__c <> NULL';
        if(assortmentDetailIds != null && assortmentDetailIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(new List<Id>(assortmentDetailIds), '\',\'') +'\') ';
        }
        this.query = q;
        // push inputs to log
        nb.logParameter('assortmentDetailIds', assortmentDetailIds);
        nb.logParameter('query', this.query);
    }
    
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Start Execute
    public void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        Set<Id> refAssortmentDetailSet = new Set<Id>();
        Set<Id> buSourceSet = new Set<Id>();
        Set<Id> buTargetSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        Set<Id> assortmentBUSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        Set<Id> categorySet = new Set<Id>();
        // get old assortment details sequences
        Map<Id, Map<Integer, Assortment_Detail_Sequence__c>> assortmentDetailSequencesMap = new Map<Id, Map<Integer, Assortment_Detail_Sequence__c>>();
        List<Assortment_Detail_Sequence__c> assortmentDetailSequences = new List<Assortment_Detail_Sequence__c>();
        List<Assortment_Matrix_review__c> assortmentMatrixReviews = new List<Assortment_Matrix_review__c>();
        Savepoint sp = Database.setSavepoint();
        try {
            for (Assortment_Detail__c item : scope) {
                assortmentBUSet.add(item.Assortment_BU__c);
                if (item.Product__c != null && !productSet.contains(item.Product__c)) {
                    productSet.add(item.Product__c);
                }
                if(item.Category__c != null && !categorySet.contains(item.Category__c)) {
                    categorySet.add(item.Category__c);
                }
                if(item.Ref_Corp_Assortment__c != null && !refAssortmentDetailSet.contains(item.Ref_Corp_Assortment__c)) {
                    refAssortmentDetailSet.add(item.Ref_Corp_Assortment__c);
                }
                // get assortment sequences
                for(Assortment_Detail_Sequence__c assortmentDetailSequence : item.Assortment_Detail_Sequences__r) {
                    if(!assortmentDetailSequencesMap.containsKey(item.Id)) {
                        Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = new Map<Integer, Assortment_Detail_Sequence__c>();
                        sequencesMap.put(Integer.valueOf(assortmentDetailSequence.Sequence__c), assortmentDetailSequence);
                        assortmentDetailSequencesMap.put(item.Id, sequencesMap);
                    } else {
                        Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = assortmentDetailSequencesMap.get(item.Id);
                        sequencesMap.put(Integer.valueOf(assortmentDetailSequence.Sequence__c), assortmentDetailSequence);
                        assortmentDetailSequencesMap.put(item.Id, sequencesMap);
                    }
                }
            }
            // get assortment BU list
            Map<Id, Assortment_BU__c> assortmentBUsMap = new Map<Id, Assortment_BU__c>();
            for(Assortment_BU__c item : [SELECT Id, BU_source__c, BU_Target__c, Year__c, RecordType.DeveloperName, Assortment_parent__c, Assortment_Parent_Objective__c,
                                         BU_Target__r.Weighted_Distribution_InnovRise_M1__c, BU_Target__r.Weighted_Distribution_InnovRise_M2__c,
                                         BU_Target__r.Weighted_Distribution_InnovRise_M3__c, BU_Target__r.Weighted_Distribution_InnovRise_M4__c,
                                         BU_Target__r.Weighted_Distribution_InnovRise_M5__c, BU_Target__r.Weighted_Distribution_InnovRise_M6__c,
                                         BU_Target__r.Weighted_Distribution_InnovRise_M7__c, BU_Target__r.Weighted_Distribution_InnovRise_M8__c,
                                         BU_Target__r.Weighted_Distribution_InnovRise_M9__c, BU_Target__r.Weighted_Distribution_InnovRise_M10__c,
                                         BU_Target__r.Weighted_Distribution_InnovRise_M11__c, BU_Target__r.Weighted_Distribution_InnovRise_M12__c,
                                         
                                         BU_Target__r.Weighted_Distribution_SwitchRise_M1__c, BU_Target__r.Weighted_Distribution_SwitchRise_M2__c,
                                         BU_Target__r.Weighted_Distribution_SwitchRise_M3__c, BU_Target__r.Weighted_Distribution_SwitchRise_M4__c,
                                         BU_Target__r.Weighted_Distribution_SwitchRise_M5__c, BU_Target__r.Weighted_Distribution_SwitchRise_M6__c,
                                         BU_Target__r.Weighted_Distribution_SwitchRise_M7__c, BU_Target__r.Weighted_Distribution_SwitchRise_M8__c,
                                         BU_Target__r.Weighted_Distribution_SwitchRise_M9__c, BU_Target__r.Weighted_Distribution_SwitchRise_M10__c,
                                         BU_Target__r.Weighted_Distribution_SwitchRise_M11__c, BU_Target__r.Weighted_Distribution_SwitchRise_M12__c,
                                         
                                         BU_Target__r.Weighted_Distribution_StopRise_M1__c, BU_Target__r.Weighted_Distribution_StopRise_M2__c,
                                         BU_Target__r.Weighted_Distribution_StopRise_M3__c, BU_Target__r.Weighted_Distribution_StopRise_M4__c,
                                         BU_Target__r.Weighted_Distribution_StopRise_M5__c, BU_Target__r.Weighted_Distribution_StopRise_M6__c,
                                         BU_Target__r.Weighted_Distribution_StopRise_M7__c, BU_Target__r.Weighted_Distribution_StopRise_M8__c,
                                         BU_Target__r.Weighted_Distribution_StopRise_M9__c, BU_Target__r.Weighted_Distribution_StopRise_M10__c,
                                         BU_Target__r.Weighted_Distribution_StopRise_M11__c, BU_Target__r.Weighted_Distribution_StopRise_M12__c
                                         
                                         FROM Assortment_BU__c
                                         WHERE Id IN :assortmentBUSet])
            {
                if (item.BU_source__c != null && !buSourceSet.contains(item.BU_source__c)) {
                    buSourceSet.add(item.BU_source__c);
                }
                if (item.BU_Target__c != null && !buTargetSet.contains(item.BU_Target__c)) {
                    buTargetSet.add(item.BU_Target__c);
                }
                if (item.Year__c != null && !yearSet.contains(Integer.valueOf(item.Year__c))) {
                    yearSet.add(Integer.valueOf(item.Year__c));
                }
                assortmentBUsMap.put(item.Id, item);
            }
            // get reference assortment Details
            Map<Id, Assortment_Detail__c> refAssortmentDetailsMap = new Map<Id, Assortment_Detail__c>();
            Map<Id, Map<Integer, Assortment_Detail_Sequence__c>> refAssortmentDetailSequencesMap = new Map<Id, Map<Integer, Assortment_Detail_Sequence__c>>();
            if(!refAssortmentDetailSet.isEmpty()) {
                for(Assortment_Detail__c item : [SELECT Id, Product__c, Category__c, Assortment_BU__c,
                                                 New_Client_ND_ClientBased__c, New_Client_ND_MarketBased__c, New_Client_WD_ClientBased__c, New_Client_WD_MarketBased__c,
                                                 (SELECT Id, Product__c, Assortment_Detail__c, Assortment__c, Movement_Date__c, Record_date__c, Sequence__c, Year__c,
                                                  Budget_ND_MarketBased__c, Budget_ND_ClientBased__c, Budget_WD_MarketBased__c, Budget_WD_ClientBased__c, Budget_SellOut_Tone__c,
                                                  Budget_SellOut_Quantity__c, Budget_SellOut__c FROM Assortment_Detail_Sequences__r)
                                                 FROM Assortment_Detail__c
                                                 WHERE Id IN :refAssortmentDetailSet
                                                 AND Status__c = 'Validated' AND Assortment_BU__r.RecordType.DeveloperName = 'Target'])
                {
                    for(Assortment_Detail_Sequence__c assortmentDetailSequence : item.Assortment_Detail_Sequences__r) {
                        if(!refAssortmentDetailSequencesMap.containsKey(item.Id)) {
                            Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = new Map<Integer, Assortment_Detail_Sequence__c>();
                            sequencesMap.put(Integer.valueOf(assortmentDetailSequence.Sequence__c), assortmentDetailSequence);
                            refAssortmentDetailSequencesMap.put(item.Id, sequencesMap);
                        } else {
                            Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = refAssortmentDetailSequencesMap.get(item.Id);
                            sequencesMap.put(Integer.valueOf(assortmentDetailSequence.Sequence__c), assortmentDetailSequence);
                            refAssortmentDetailSequencesMap.put(item.Id, sequencesMap);
                        }
                    }
                    refAssortmentDetailsMap.put(item.Id, item);
                }
            }
            
            // get old assortment Matrix reviews
            Map<String, Map<Integer, Assortment_Matrix_review__c>> assortmentMatrixReviewMap = new Map<String, Map<Integer, Assortment_Matrix_review__c>>();
            for(Assortment_Matrix_review__c item : [SELECT Id, BU_Source__c, BU_Target__c, Category__c, Produit__c, Sequence__c, Year__c,
                                                    Name__c, ND__c, WD__c, SellOut_Quantity__c, SellOut_Tone__c, SellOut__c
                                                    FROM Assortment_Matrix_review__c
                                                    WHERE BU_Source__c IN :buSourceSet AND BU_Target__c IN :buTargetSet
                                                    AND Produit__c IN :productSet AND Year__c IN :yearSet])
            {
                String key = item.BU_Source__c + '' + item.BU_Target__c + '' + item.Produit__c + '' + Integer.valueOf(item.Year__c) + '' + item.Name__c;
                if(!assortmentMatrixReviewMap.containsKey(key)) {
                    Map<Integer, Assortment_Matrix_review__c> assortmentMatrixMap = new Map<Integer, Assortment_Matrix_review__c>();
                    assortmentMatrixMap.put(Integer.valueOf(item.Sequence__c), item);
                    assortmentMatrixReviewMap.put(key, assortmentMatrixMap);
                } else {
                    Map<Integer, Assortment_Matrix_review__c> assortmentMatrixMap = assortmentMatrixReviewMap.get(key);
                    assortmentMatrixMap.put(Integer.valueOf(item.Sequence__c), item);
                    assortmentMatrixReviewMap.put(key, assortmentMatrixMap);
                }
            }
            // process generate asoortment detail sequences and assortment matrix reviews
            for(Assortment_Detail__c item : scope) {
                // get assortment BU
                Assortment_BU__c assortmentBU = assortmentBUsMap.get(item.Assortment_BU__c);
                
                Boolean isBudget = assortmentBU.RecordType.DeveloperName == 'Target' ? true : false;
                // get reference assortment details
                Assortment_Detail__c refAssortmentDetail;
                if(assortmentBU.RecordType.DeveloperName == 'Nego' && item.Ref_Corp_Assortment__c != null) {
                    refAssortmentDetail = refAssortmentDetailsMap.get(item.Ref_Corp_Assortment__c);
                }
                // get assortment detail sequences list
                Map<Integer, Assortment_Detail_Sequence__c> sequencesMap = assortmentDetailSequencesMap.get(item.Id);
                if(sequencesMap == null) sequencesMap = new Map<Integer, Assortment_Detail_Sequence__c>();
                Integer year = item.Movement_Date__c != null ? item.Movement_Date__c.year() : Date.today().year();
                Integer month = item.Movement_Date__c != null ? item.Movement_Date__c.month() : Date.today().month();
                Integer day = item.Movement_Date__c != null ? item.Movement_Date__c.day() : Date.today().day();
                Integer monthDays = Date.daysInMonth(year, month);
                
                // generate assortment detail sequences
                Integer WDSequence = 1;
                for(Integer i = 1; i <= 12; i++) {
                    Decimal WDInnovRise = assortmentBU.BU_Target__r != null && assortmentBU.BU_Target__r.get('Weighted_Distribution_InnovRise_M'+ WDSequence +'__c') != null ?
                        Decimal.valueOf(String.valueOf(assortmentBU.BU_Target__r.get('Weighted_Distribution_InnovRise_M'+ WDSequence +'__c'))) : null;
                    Decimal WDSwitchRise = assortmentBU.BU_Target__r != null && assortmentBU.BU_Target__r.get('Weighted_Distribution_SwitchRise_M'+ WDSequence +'__c') != null ?
                        Decimal.valueOf(String.valueOf(assortmentBU.BU_Target__r.get('Weighted_Distribution_SwitchRise_M'+ WDSequence +'__c'))) : null;
                    Decimal WDStopRise = assortmentBU.BU_Target__r != null && assortmentBU.BU_Target__r.get('Weighted_Distribution_StopRise_M'+ WDSequence +'__c') != null ?
                        Decimal.valueOf(String.valueOf(assortmentBU.BU_Target__r.get('Weighted_Distribution_StopRise_M'+ WDSequence +'__c'))) : null;
                    
                    Assortment_Detail_Sequence__c assortmentDetailSequence;
                    if(sequencesMap != null && sequencesMap.containsKey(i)) {
                        assortmentDetailSequence = sequencesMap.get(i);
                    } else {
                        // insert assortment detail sequence
                        assortmentDetailSequence = new Assortment_Detail_Sequence__c(Assortment_Detail__c = item.Id, Assortment__c = item.Assortment_BU__c, Sequence__c = i, Year__c = year);
                    }
                    if(item.Client_Status__c == 'New' || item.Client_Status__c == 'Delete' || item.Client_Status__c == 'Substitute') {
                        Decimal WDRise = item.Client_Status__c == 'New' ? WDInnovRise : item.Client_Status__c == 'Substitute' ? WDSwitchRise : WDStopRise;
                        if(WDRise != null) WDRise = WDRise/100;
                        if(item.Client_Status__c == 'New' || item.Client_Status__c == 'Substitute') {
                            if(i < month) {
                                // New
                                if(assortmentDetailSequence.Id == null) {
                                    assortmentDetailSequence.New_ND_MarketBased__c = null;
                                    assortmentDetailSequence.New_ND_ClientBased__c = null;
                                    assortmentDetailSequence.New_WD_MarketBased__c = null;
                                    assortmentDetailSequence.New_WD_ClientBased__c = null;
                                    ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                    assortmentDetailSequence.New_SellOut_Quantity__c = null;
                                    assortmentDetailSequence.New_SellOut__c = null;
                                }
                                // Fx
                                if(assortmentDetailSequence.Id == null) {
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = null;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = null;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = null;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = null;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = null;
                                    assortmentDetailSequence.Fx_SellOut__c = null;
                                } else {
                                    assortmentDetailSequence.Fx_ND_MarketBased__c = 0;
                                    assortmentDetailSequence.Fx_ND_ClientBased__c = 0;
                                    assortmentDetailSequence.Fx_WD_MarketBased__c = 0;
                                    assortmentDetailSequence.Fx_WD_ClientBased__c = 0;
                                    ////assortmentDetailSequence.Fx_SellOut_Tone__c = 0;
                                    assortmentDetailSequence.Fx_SellOut_Quantity__c = 0;
                                    assortmentDetailSequence.Fx_SellOut__c = 0;
                                }
                            }
                            if(i == month) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null ? item.New_Client_Quantity_SEQ__c * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.New_SellOut__c = null;
                                
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise * (monthDays - day + 1)/monthDays : null;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                                WDSequence++;
                            }
                            if(i > month) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                assortmentDetailSequence.New_SellOut__c = null;
                                
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise : null;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise : null;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                                WDSequence++;
                            }
                        }
                        if(item.Client_Status__c == 'Delete') {
                            if(i < month && assortmentDetailSequence.Id == null) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                assortmentDetailSequence.New_SellOut__c = null;
                                                                
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                            }
                            if(i == month) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = item.Last_History__r.New_Client_ND_MarketBased__c != null ? item.Last_History__r.New_Client_ND_MarketBased__c * (day - 1)/monthDays : null;
                                assortmentDetailSequence.New_ND_ClientBased__c = item.Last_History__r.New_Client_ND_ClientBased__c != null ? item.Last_History__r.New_Client_ND_ClientBased__c * (day - 1)/monthDays : null;
                                assortmentDetailSequence.New_WD_MarketBased__c = item.Last_History__r.New_Client_WD_MarketBased__c != null ? item.Last_History__r.New_Client_WD_MarketBased__c * (day - 1)/monthDays : null;
                                assortmentDetailSequence.New_WD_ClientBased__c = item.Last_History__r.New_Client_WD_ClientBased__c != null ? item.Last_History__r.New_Client_WD_ClientBased__c * (day - 1)/monthDays : null;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = item.Last_History__r.New_Client_Quantity_SEQ__c != null ? item.Last_History__r.New_Client_Quantity_SEQ__c * (day - 1)/monthDays : null;
                                assortmentDetailSequence.New_SellOut__c = null;
                                
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = item.Last_History__r.New_Client_ND_MarketBased__c != null ? item.Last_History__r.New_Client_ND_MarketBased__c * (day - 1 + (WDRise != null ? WDRise : 0) * (monthDays - day + 1))/monthDays : null;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.Last_History__r.New_Client_ND_ClientBased__c != null ? item.Last_History__r.New_Client_ND_ClientBased__c * (day - 1 + (WDRise != null ? WDRise : 0) * (monthDays - day + 1))/monthDays : null;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.Last_History__r.New_Client_WD_MarketBased__c != null ? item.Last_History__r.New_Client_WD_MarketBased__c * (day - 1 + (WDRise != null ? WDRise : 0) * (monthDays - day + 1))/monthDays : null;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.Last_History__r.New_Client_WD_ClientBased__c != null ? item.Last_History__r.New_Client_WD_ClientBased__c * (day - 1 + (WDRise != null ? WDRise : 0) * (monthDays - day + 1))/monthDays : null;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = item.Last_History__r.New_Client_Quantity_SEQ__c != null ? item.Last_History__r.New_Client_Quantity_SEQ__c * (day - 1 + (WDRise != null ? WDRise : 0) * (monthDays - day + 1))/monthDays : null;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                                WDSequence++;
                            }
                            if(i > month) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = 0;
                                assortmentDetailSequence.New_ND_ClientBased__c = 0;
                                assortmentDetailSequence.New_WD_MarketBased__c = 0;
                                assortmentDetailSequence.New_WD_ClientBased__c = 0;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = 0;
                                assortmentDetailSequence.New_SellOut_Quantity__c = 0;
                                assortmentDetailSequence.New_SellOut__c = 0;
                                
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null && WDRise != null ? item.New_Client_ND_MarketBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null && WDRise != null ? item.New_Client_ND_ClientBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null && WDRise != null ? item.New_Client_WD_MarketBased__c * WDRise : null;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null && WDRise != null ? item.New_Client_WD_ClientBased__c * WDRise : null;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null && WDRise != null ? item.New_Client_Quantity_SEQ__c * WDRise : null;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                                WDSequence++;
                            }
                        }
                    }
                    else if(item.Ass_BU_Cluster__c != null && item.Ass_BU_Cluster__c == item.Ref_BU_Cluster__c) {
                        // New
                        if(assortmentDetailSequence.Id == null || (assortmentDetailSequence.Id != null && i > month)) { // case insert and update(sequence>month)
                            assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                            assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                            assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                            assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                            ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                            assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                            assortmentDetailSequence.New_SellOut__c = null;
                        }
                        else if(assortmentDetailSequence.Id != null && i == month) { // case update (sequence=month)
                            assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                            assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                            assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                            assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                            ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                            assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c != null ? item.New_Client_Quantity_SEQ__c * (monthDays - day + 1)/monthDays : null;
                            assortmentDetailSequence.New_SellOut__c = null;
                        }
                        
                        // Fx   
                        if(assortmentDetailSequence.Id == null) {
                            assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                            assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                            assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                            assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                            ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                            assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                            assortmentDetailSequence.Fx_SellOut__c = null;
                        }
                    }
                    else if(item.Client_Status__c == 'Increase' || item.Client_Status__c == 'Decrease' || item.Client_Status__c == 'Keep') {
                        if(i < month) {
                            // New
                            if(assortmentDetailSequence.Id == null) { // case insert with sequence < month
                                assortmentDetailSequence.New_ND_MarketBased__c = null;////item.Ref_Client_ND_MarketBased__c;
                                assortmentDetailSequence.New_ND_ClientBased__c = item.Ref_Client_ND_ClientBased__c;
                                assortmentDetailSequence.New_WD_MarketBased__c = item.Ref_Client_WD_MarketBased__c;
                                assortmentDetailSequence.New_WD_ClientBased__c = item.Ref_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = null;
                                assortmentDetailSequence.New_SellOut__c = null;
                            }
                            
                            // Fx
                            if(assortmentDetailSequence.Id == null) {
                                assortmentDetailSequence.Fx_ND_MarketBased__c = null;////item.Ref_Client_ND_MarketBased__c;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.Ref_Client_ND_ClientBased__c;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.Ref_Client_WD_MarketBased__c;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.Ref_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = null;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                            } else {
                                ////assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                                ////assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                                ////assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1)/monthDays : null;
                                ////assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1)/monthDays : null;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                ////assortmentDetailSequence.Fx_SellOut_Quantity__c = null;
                                ////assortmentDetailSequence.Fx_SellOut__c = null;
                            }
                        }
                        
                        if(i >= month) { // case insert or update with sequence >= month                            
                            if(assortmentDetailSequence.Id == null || (assortmentDetailSequence.Id != null && i > month)) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                assortmentDetailSequence.New_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                assortmentDetailSequence.New_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                assortmentDetailSequence.New_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                assortmentDetailSequence.New_SellOut__c = null;
                                
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = item.New_Client_ND_MarketBased__c;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = item.New_Client_ND_ClientBased__c;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = item.New_Client_WD_MarketBased__c;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = item.New_Client_WD_ClientBased__c;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = item.New_Client_Quantity_SEQ__c;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                            } else if(assortmentDetailSequence.Id != null && i == month) {
                                // New
                                assortmentDetailSequence.New_ND_MarketBased__c = ((item.Last_History__r.New_Client_ND_MarketBased__c != null ? item.Last_History__r.New_Client_ND_MarketBased__c * (day - 1) : 0) + (item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_ND_ClientBased__c = ((item.Last_History__r.New_Client_ND_ClientBased__c != null ? item.Last_History__r.New_Client_ND_ClientBased__c * (day - 1) : 0) + (item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_WD_MarketBased__c = ((item.Last_History__r.New_Client_WD_MarketBased__c != null ? item.Last_History__r.New_Client_WD_MarketBased__c * (day - 1) : 0) + (item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_WD_ClientBased__c = ((item.Last_History__r.New_Client_WD_ClientBased__c != null ? item.Last_History__r.New_Client_WD_ClientBased__c * (day - 1) : 0) + (item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                                assortmentDetailSequence.New_SellOut_Quantity__c = ((item.Last_History__r.New_Client_Quantity_SEQ__c != null ? item.Last_History__r.New_Client_Quantity_SEQ__c * (day - 1) : 0) + (item.New_Client_Quantity_SEQ__c != null ? item.New_Client_Quantity_SEQ__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.New_SellOut__c = null;
                                
                                // Fx
                                assortmentDetailSequence.Fx_ND_MarketBased__c = ((item.Last_History__r.New_Client_ND_MarketBased__c != null ? item.Last_History__r.New_Client_ND_MarketBased__c * (day - 1) : 0) + (item.New_Client_ND_MarketBased__c != null ? item.New_Client_ND_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_ND_ClientBased__c = ((item.Last_History__r.New_Client_ND_ClientBased__c != null ? item.Last_History__r.New_Client_ND_ClientBased__c * (day - 1) : 0) + (item.New_Client_ND_ClientBased__c != null ? item.New_Client_ND_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_WD_MarketBased__c = ((item.Last_History__r.New_Client_WD_MarketBased__c != null ? item.Last_History__r.New_Client_WD_MarketBased__c * (day - 1) : 0) + (item.New_Client_WD_MarketBased__c != null ? item.New_Client_WD_MarketBased__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_WD_ClientBased__c = ((item.Last_History__r.New_Client_WD_ClientBased__c != null ? item.Last_History__r.New_Client_WD_ClientBased__c * (day - 1) : 0) + (item.New_Client_WD_ClientBased__c != null ? item.New_Client_WD_ClientBased__c * (monthDays - day + 1) : 0))/monthDays;
                                ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                                assortmentDetailSequence.Fx_SellOut_Quantity__c = ((item.Last_History__r.New_Client_Quantity_SEQ__c != null ? item.Last_History__r.New_Client_Quantity_SEQ__c * (day - 1) : 0) + (item.New_Client_Quantity_SEQ__c != null ? item.New_Client_Quantity_SEQ__c * (monthDays - day + 1) : 0))/monthDays;
                                assortmentDetailSequence.Fx_SellOut__c = null;
                            }
                        }
                    }
                    
                    if(isBudget) {
                        // New
                        assortmentDetailSequence.New_ND_MarketBased__c = null;
                        assortmentDetailSequence.New_ND_ClientBased__c = null;
                        assortmentDetailSequence.New_WD_MarketBased__c = null;
                        assortmentDetailSequence.New_WD_ClientBased__c = null;
                        ////assortmentDetailSequence.New_SellOut_Tone__c = null;
                        assortmentDetailSequence.New_SellOut_Quantity__c = null;
                        assortmentDetailSequence.New_SellOut__c = null;
                        
                        assortmentDetailSequence.Budget_ND_MarketBased__c = assortmentDetailSequence.Fx_ND_MarketBased__c;
                        assortmentDetailSequence.Budget_ND_ClientBased__c = assortmentDetailSequence.Fx_ND_ClientBased__c;
                        assortmentDetailSequence.Budget_WD_MarketBased__c = assortmentDetailSequence.Fx_WD_MarketBased__c;
                        assortmentDetailSequence.Budget_WD_ClientBased__c = assortmentDetailSequence.Fx_WD_ClientBased__c;
                        ////assortmentDetailSequence.Budget_SellOut_Tone__c = null;
                        assortmentDetailSequence.Budget_SellOut_Quantity__c = assortmentDetailSequence.Fx_SellOut_Quantity__c;
                        assortmentDetailSequence.Budget_SellOut__c = assortmentDetailSequence.Fx_SellOut__c;
                        
                        // Fx
                        assortmentDetailSequence.Fx_ND_MarketBased__c = null;
                        assortmentDetailSequence.Fx_ND_ClientBased__c = null;
                        assortmentDetailSequence.Fx_WD_MarketBased__c = null;
                        assortmentDetailSequence.Fx_WD_ClientBased__c = null;
                        ////assortmentDetailSequence.Fx_SellOut_Tone__c = null;
                        assortmentDetailSequence.Fx_SellOut_Quantity__c = null;
                        assortmentDetailSequence.Fx_SellOut__c = null;
                    }
                    
                    // Fact (get assortment review detail)
                    if(!isBudget) {
                        assortmentDetailSequence.Fact_ND_MarketBased__c = item.Fact_ND_MarketBased__c;
                        assortmentDetailSequence.Fact_ND_ClientBased__c = item.Fact_ND_ClientBased__c;
                        assortmentDetailSequence.Fact_WD_MarketBased__c = item.Fact_WD_MarketBased__c;
                        assortmentDetailSequence.Fact_WD_ClientBased__c = item.Fact_WD_ClientBased__c;
                        ////assortmentDetailSequence.Fact_SellOut_Tone__c = item.Fact_SellOut_Tone__c;
                        assortmentDetailSequence.Fact_SellOut_Quantity__c = item.Fact_SellOut_Quantity_SEQ__c;
                        assortmentDetailSequence.Fact_SellOut__c = item.Fact_SellOut_SEQ__c;
                    }
                    
                    // get Budget for assortment Nego
                    // get reference assortment detail sequences list
                    if(!isBudget && refAssortmentDetail != null) {
                        Map<Integer, Assortment_Detail_Sequence__c> refSequencesMap = refAssortmentDetailSequencesMap.get(refAssortmentDetail.Id);
                        if(refSequencesMap.containsKey(i)) {
                            Assortment_Detail_Sequence__c refAssortmentDetailSequence = sequencesMap.get(i);
                            if(refAssortmentDetailSequence != null) {
                                assortmentDetailSequence.Budget_ND_MarketBased__c = refAssortmentDetailSequence.Budget_ND_MarketBased__c;
                                assortmentDetailSequence.Budget_ND_ClientBased__c = refAssortmentDetailSequence.Budget_ND_ClientBased__c;
                                assortmentDetailSequence.Budget_WD_MarketBased__c = refAssortmentDetailSequence.Budget_WD_MarketBased__c;
                                assortmentDetailSequence.Budget_WD_ClientBased__c = refAssortmentDetailSequence.Budget_WD_ClientBased__c;
                                ////assortmentDetailSequence.Budget_SellOut_Tone__c = null;
                                assortmentDetailSequence.Budget_SellOut_Quantity__c = refAssortmentDetailSequence.Budget_SellOut_Quantity__c;
                                assortmentDetailSequence.Budget_SellOut__c = refAssortmentDetailSequence.Budget_SellOut__c;
                            }
                        }
                    }
                    
                    assortmentDetailSequence.Movement_Date__c = item.Movement_Date__c;
                    assortmentDetailSequence.Record_date__c = item.Record_date__c;
                    assortmentDetailSequences.add(assortmentDetailSequence);
                    sequencesMap.put(i, assortmentDetailSequence);
                }
                
                // generate assortment matrix reviews
                Set<String> matrixNameSet;
                if(isBudget) {
                    matrixNameSet = new Set<String>{'Budget'};
                } else {
                     matrixNameSet = new Set<String>{'Budget', 'Negotiated', 'Forecast'};
                }
                for(String matrixName : matrixNameSet) {
                    for(Integer i = 1; i <= 12; i++) {
                        Assortment_Detail_Sequence__c assortmentDetailSequence = sequencesMap.get(i);
                        String keyMatrix = assortmentBU.BU_source__c + '' + assortmentBU.BU_Target__c + '' + item.Product__c + '' + Integer.valueOf(assortmentBU.Year__c) + '' + matrixName;
                        Map<Integer, Assortment_Matrix_review__c> assortmentMatrixMap = assortmentMatrixReviewMap.get(keyMatrix);
                        Assortment_Matrix_review__c assortmentMatrixReview;
                        if(assortmentMatrixMap != null && assortmentMatrixMap.containsKey(i)) {
                            assortmentMatrixReview = assortmentMatrixMap.get(i);
                        } else {
                            // insert assortment Matrix review
                            assortmentMatrixReview = new Assortment_Matrix_review__c(BU_Source__c = assortmentBU.BU_source__c,
                                                                                     BU_Target__c = assortmentBU.BU_Target__c,
                                                                                     Produit__c = item.Product__c,
                                                                                     Sequence__c = i,
                                                                                     Year__c = year,
                                                                                     Name__c = matrixName);
                        }
                        if(matrixName == 'Budget') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.Budget_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.Budget_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.Budget_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.Budget_WD_MarketBased__c;
                        }
                        if(matrixName == 'Negotiated') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.New_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.New_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.New_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.New_WD_MarketBased__c;
                        }
                        if(matrixName == 'Forecast') {
                            assortmentMatrixReview.ND__c = assortmentDetailSequence.Fx_ND_ClientBased__c;
                            assortmentMatrixReview.WD__c = assortmentDetailSequence.Fx_WD_ClientBased__c;
                            assortmentMatrixReview.ND_Marketbase__c = assortmentDetailSequence.Fx_ND_MarketBased__c;
                            assortmentMatrixReview.WD_Marketbase__c = assortmentDetailSequence.Fx_WD_MarketBased__c;
                        }
                        assortmentMatrixReviews.add(assortmentMatrixReview);
                    }
                }
            }
            
            // check security on Assortment_Detail_Sequence__c fields
            String[] assortmentDetailSequenceFields = new String[] {NegoptimHelper.normalizeAPIName('New_ND_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('New_ND_ClientBased__c'), NegoptimHelper.normalizeAPIName('New_WD_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('New_WD_ClientBased__c'), NegoptimHelper.normalizeAPIName('New_SellOut_Quantity__c'),
                NegoptimHelper.normalizeAPIName('New_SellOut__c'), NegoptimHelper.normalizeAPIName('Fx_ND_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('Fx_ND_ClientBased__c'), NegoptimHelper.normalizeAPIName('Fx_WD_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('Fx_WD_ClientBased__c'), NegoptimHelper.normalizeAPIName('Fx_SellOut_Quantity__c'),
                NegoptimHelper.normalizeAPIName('Fx_SellOut__c'), NegoptimHelper.normalizeAPIName('Fact_ND_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('Fact_ND_ClientBased__c'), NegoptimHelper.normalizeAPIName('Fact_WD_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('Fact_WD_ClientBased__c'), NegoptimHelper.normalizeAPIName('Fact_SellOut_Quantity__c'),
                NegoptimHelper.normalizeAPIName('Fact_SellOut__c'), NegoptimHelper.normalizeAPIName('Budget_ND_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('Budget_ND_ClientBased__c'), NegoptimHelper.normalizeAPIName('Budget_WD_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('Budget_WD_ClientBased__c'), NegoptimHelper.normalizeAPIName('Budget_SellOut_Quantity__c'),
                NegoptimHelper.normalizeAPIName('Budget_SellOut__c'), NegoptimHelper.normalizeAPIName('Movement_Date__c'),
                NegoptimHelper.normalizeAPIName('Record_date__c'), NegoptimHelper.normalizeAPIName('Sequence__c'), NegoptimHelper.normalizeAPIName('Year__c')};
            
            String[] assortmentDetailSequenceInsertedFields = new String[]{NegoptimHelper.normalizeAPIName('Assortment_Detail__c'), NegoptimHelper.normalizeAPIName('Assortment__c')};
            assortmentDetailSequenceInsertedFields.addAll(assortmentDetailSequenceFields);
            
            // check security on Assortment_Matrix_review__c fields
            String[] assortmentMatrixReviewFields = new String[] {NegoptimHelper.normalizeAPIName('ND__c'), NegoptimHelper.normalizeAPIName('WD__c'),
                NegoptimHelper.normalizeAPIName('ND_Marketbase__c'), NegoptimHelper.normalizeAPIName('WD_Marketbase__c')};
            
            String[] assortmentMatrixReviewInsertedFields = new String[]{NegoptimHelper.normalizeAPIName('BU_Source__c'),
                NegoptimHelper.normalizeAPIName('BU_Target__c'), NegoptimHelper.normalizeAPIName('Produit__c'), NegoptimHelper.normalizeAPIName('Sequence__c'),
                NegoptimHelper.normalizeAPIName('Year__c'), NegoptimHelper.normalizeAPIName('Name__c')};
            assortmentMatrixReviewInsertedFields.addAll(assortmentMatrixReviewFields);
            
            if(NegoptimHelper.checkCreatibility(Assortment_Detail_Sequence__c.SObjectType, assortmentDetailSequenceInsertedFields) &&
               NegoptimHelper.checkUpdatibility(Assortment_Detail_Sequence__c.SObjectType, assortmentDetailSequenceFields) &&
               NegoptimHelper.checkCreatibility(Assortment_Matrix_review__c.SObjectType, assortmentMatrixReviewInsertedFields) &&
               NegoptimHelper.checkUpdatibility(Assortment_Matrix_review__c.SObjectType, assortmentMatrixReviewFields))
            {
                // upsert assortment detail sequences
                if(!assortmentDetailSequences.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(assortmentDetailSequences, false);
                    nb.logResults(results, assortmentDetailSequences);
                }
                // upsert assortment matrix reviews
                if(!assortmentMatrixReviews.isEmpty()) {
                    List<Database.UpsertResult> results = Database.upsert(assortmentMatrixReviews, false);
                    nb.logResults(results, assortmentMatrixReviews);
                }
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.saveLog(bc);
    }
    
    // Finish method implementation.
    public void finish(Database.BatchableContext BC) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}