/*
 * 1- case consolidate assortment details by Assortment_BU__r.Orga_HE__c + BU_Target__r.Related_Client__c + BU_Target__r.Country_Origin + BU_Target__r.Format_Origin__c
 * 2- case reset assortment details
 */ 
public with sharing class ConsolidateAssortmentBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    private Set<Id> countrySet;
    private Set<Integer> yearSet;
    private Set<Id> buSourceSet;
    private Set<Id> assortmentDetailConsoIds;
    
    /**
     * countryIds: selected country in MassBatchForm + updated assortment details (Trigger)
     * year: selected year in MassBatchForm + updated assortment details (Trigger)
     * buSourceIds : updated assortment details (Trigger)
     **/
    public ConsolidateAssortmentBatch(String startedFrom, Set<Id> countryIds, Set<Integer> years, Set<Id> buSourceIds) {
        this.nb = new NegoptimBatch('ConsolidateAssortmentBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.countrySet = countryIds;
        this.yearSet = years;
        this.buSourceSet = buSourceIds;
        this.assortmentDetailConsoIds = new Set<Id>();
        
        query = 'SELECT Id, Product__c, Year__c, Category__c, Assortment_BU__c, Assortment_BU__r.Ass_BDate__c, Assortment_BU__r.Ass_EDate__c,';
        query += ' Assortment_BU__r.Assortment_type__c, Assortment_BU__r.Assortment__c, Assortment_BU__r.RecordTypeId,';
        query += ' Assortment_BU__r.BU_Source__r.Related_Client__c, Assortment_BU__r.BU_Source__r.Country_origin__c, Assortment_BU__r.BU_Source__r.Format_Origin__c,';
        query += ' Assortment_BU__r.BU_Target__r.Related_Client__c, Assortment_BU__r.BU_Target__r.Country_origin__c, Assortment_BU__r.BU_Target__r.Format_Origin__c,';
        query += ' Ass_BU_Cluster__c, Assortment_BU__r.BU_Source__c, Assortment_BU__r.BU_Target__c, Assortment_BU__r.Orga_HE__c, Assortment_BU__r.Orga_HE__r.Path__c,';
        query += ' Fact_WD_MarketBased__c,L4L_Client_ND_ClientBased__c,L4L_Client_ND_MarketBased__c,L4L_Client_ProductNumber__c,L4L_Client_WD_ClientBased__c,';
        query += ' L4L_Client_WD_MarketBased__c,New_Client_ND_ClientBased__c,New_Client_ND_MarketBased__c,New_Client_ProductNumber__c,New_Client_Quantity_SEQ__c,';
        query += ' New_Client_Quantity_YE__c,New_Client_WD_ClientBased__c,New_Client_WD_MarketBased__c,New_Corp_ND_ClientBased__c,New_Corp_ND_MarketBased__c,';
        query += ' New_Corp_Quantity_YE__c,New_Corp_WD_ClientBased__c,New_Corp_WD_MarketBased__c,New_Client_Unit_Cost__c,New_Corp_Unit_Cost__c';
        query += ' FROM Assortment_Detail__c';
        query += ' WHERE Status__c = \'Validated\' AND Version__c = NULL AND Product__c <> NULL AND Category__c <> NULL AND Assortment_BU__r.BU_Target__r.Related_Client__c <> NULL';
        query += ' AND Assortment_BU__r.Orga_HE__c <> NULL AND Assortment_BU__r.BU_Target__r.Format_Origin__c <> NULL AND Assortment_BU__r.BU_Target__r.Country_origin__c <> NULL';
        query += ' AND Assortment_BU__r.RecordType.DeveloperName = \'Nego\'';
        if(this.yearSet != null) {
            query += ' AND Year__c  IN (' + String.join(new List<Integer>(this.yearSet), '\',\'') + ')';
        }
        if(this.countrySet != null) {
            query += ' AND Assortment_BU__r.BU_Target__r.Country_origin__c IN (\'' + String.join(new List<Id>(countrySet), '\',\'') +'\') ';
        }
        if(this.buSourceSet != null) {
            query += ' AND Assortment_BU__r.BU_Source__c IN (\'' + String.join(new List<Id>(buSourceSet), '\',\'') +'\') ';
        }
        nb.logParameter('countryIds', countryIds);
        nb.logParameter('years', years);
        nb.logParameter('buSourceIds', buSourceIds);
        nb.logParameter('query', query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        Set<Id> buSourceSet = new Set<Id>();
        Set<Id> clientSet = new Set<Id>();
        Set<Id> countryOriginSet = new Set<Id>();
        Set<Integer> yearSet = new Set<Integer>();
        List<Assortment_BU__c> assortmentBUConsoInsertList = new List<Assortment_BU__c>();
        List<Assortment_Detail__c> assortmentDetailsUpdatedList = new List<Assortment_Detail__c>();
        Map<String, List<Assortment_Detail__c>> assortmentDetailsMap = new Map<String, List<Assortment_Detail__c>>();
        Map<String, Assortment_BU__c> assortmentBUConsoMap = new Map<String, Assortment_BU__c>();
        Map<String, Assortment_Detail__c> assortmentDetailConsoMap = new Map<String, Assortment_Detail__c>();
        Map<String, Orga_BU__c> buConsoMap = new Map<String, Orga_BU__c>();
        List<AssortmentConsoWrapper> assortmentConsoWrapperList = new List<AssortmentConsoWrapper>();
        
        for (Assortment_Detail__c item : scope) {
            if(!buSourceSet.contains(item.Assortment_BU__r.BU_Source__c)) {
                buSourceSet.add(item.Assortment_BU__r.BU_Source__c);
            }
            if(!clientSet.contains(item.Assortment_BU__r.BU_Target__r.Related_Client__c)) {
                clientSet.add(item.Assortment_BU__r.BU_Target__r.Related_Client__c);
            }
            if(item.Assortment_BU__r.BU_Target__r.Country_origin__c != null && !countryOriginSet.contains(item.Assortment_BU__r.BU_Target__r.Country_origin__c)) {
                countryOriginSet.add(item.Assortment_BU__r.BU_Target__r.Country_origin__c);
            }
            if(!yearSet.contains(Integer.valueOf(item.Year__c))) {
                yearSet.add(Integer.valueOf(item.Year__c));
            }
            String key = item.Assortment_BU__r.BU_Source__c + '' + item.Assortment_BU__r.Orga_HE__c + '' + item.Assortment_BU__r.BU_Target__r.Related_Client__c + '' +
                item.Assortment_BU__r.BU_Target__r.Country_origin__c + '' + getSortedFormatOrigin(item.Assortment_BU__r.BU_Target__r.Format_Origin__c) + '' + Integer.valueOf(item.Year__c);
            if(!assortmentDetailsMap.containsKey(key)) {
                assortmentDetailsMap.put(key, new List<Assortment_Detail__c>{item});
            } else {
                assortmentDetailsMap.get(key).add(item);
            }
        }
        // get BU conso
        if(!clientSet.isEmpty() && !countryOriginSet.isEmpty()) {
            for(Orga_BU__c item : [SELECT Id, Name, Country_origin__c, Format_Origin__c, Related_Client__c, Category__c
                                   FROM Orga_BU__c WHERE Related_Client__c IN :clientSet
                                   AND Country_origin__c IN : countryOriginSet
                                   AND Layer_Nego_Conso__c = TRUE AND Format_Origin__c <> NULL])
            {
                String keyBU = item.Related_Client__c + '' + item.Country_origin__c  + '' + getSortedFormatOrigin(item.Format_Origin__c);
                buConsoMap.put(keyBU, item);
            }
        }
        // get Assortment BU conso
        if(!buSourceSet.isEmpty() && !yearSet.isEmpty()) {
            Set<Id> assortmentBUConsoSet = new Set<Id>();
            for(Assortment_BU__c item : [SELECT Id, BU_Source__c, Orga_HE__c, BU_Source__r.Related_Client__c, BU_Source__r.Country_origin__c,
                                         BU_Target__r.Related_Client__c, BU_Target__r.Country_origin__c, BU_Target__r.Format_Origin__c, Year__c
                                         FROM Assortment_BU__c WHERE BU_Source__c IN :buSourceSet AND Year__c IN :yearSet AND RecordType.DeveloperName = 'Conso'])
            {
                String key = item.BU_Source__c + '' + item.Orga_HE__c + '' + item.BU_Target__r.Related_Client__c + '' +
                    item.BU_Target__r.Country_origin__c + '' + getSortedFormatOrigin(item.BU_Target__r.Format_Origin__c) + '' + Integer.valueOf(item.Year__c);
                assortmentBUConsoMap.put(key, item);
                assortmentBUConsoSet.add(item.Id);
            }
            // get assortment details conso
            for(Assortment_Detail__c item : [SELECT Id, Product__c, Category__c, Assortment_BU__r.BU_Source__c, Assortment_BU__r.BU_Source__r.Related_Client__c,
                                             Assortment_BU__r.Orga_HE__c, Assortment_BU__r.BU_Source__r.Country_origin__c, Assortment_BU__r.BU_Target__r.Related_Client__c,
                                             Assortment_BU__r.BU_Target__r.Country_origin__c, Assortment_BU__r.BU_Target__r.Format_Origin__c, Year__c,
                                             Fact_WD_MarketBased__c,L4L_Client_ND_ClientBased__c,L4L_Client_ND_MarketBased__c,L4L_Client_ProductNumber__c,
                                             L4L_Client_WD_ClientBased__c,L4L_Client_WD_MarketBased__c,New_Client_ND_ClientBased__c,New_Client_ND_MarketBased__c,
                                             New_Client_ProductNumber__c,New_Client_Quantity_SEQ__c,New_Client_Quantity_YE__c, New_Client_WD_ClientBased__c,
                                             New_Client_WD_MarketBased__c,New_Corp_ND_ClientBased__c,New_Corp_ND_MarketBased__c,New_Corp_Quantity_YE__c,
                                             New_Corp_WD_ClientBased__c,New_Corp_WD_MarketBased__c,New_Client_Unit_Cost__c,New_Corp_Unit_Cost__c
                                             FROM Assortment_Detail__c WHERE Assortment_BU__c IN :assortmentBUConsoSet])
            {
                String key = item.Assortment_BU__r.BU_Source__c + '' + item.Assortment_BU__r.Orga_HE__c + '' + item.Assortment_BU__r.BU_Target__r.Related_Client__c + '' +
                    item.Assortment_BU__r.BU_Target__r.Country_origin__c + '' + getSortedFormatOrigin(item.Assortment_BU__r.BU_Target__r.Format_Origin__c) + '' +
                    Integer.valueOf(item.Year__c) + '' + item.Product__c;
                assortmentDetailConsoMap.put(key, item);
            }
        }
        
        List<String> assortmentDetailsCalculateFields = new List<String>{'Fact_WD_MarketBased__c','L4L_Client_ND_ClientBased__c','L4L_Client_ND_MarketBased__c','L4L_Client_ProductNumber__c',
            'L4L_Client_WD_ClientBased__c','L4L_Client_WD_MarketBased__c','New_Client_ND_ClientBased__c','New_Client_ND_MarketBased__c','New_Client_ProductNumber__c',
            'New_Client_Quantity_SEQ__c','New_Client_Quantity_YE__c','New_Client_WD_ClientBased__c','New_Client_WD_MarketBased__c','New_Corp_ND_ClientBased__c',
            'New_Corp_ND_MarketBased__c','New_Corp_Quantity_YE__c','New_Corp_WD_ClientBased__c','New_Corp_WD_MarketBased__c','New_Client_Unit_Cost__c','New_Corp_Unit_Cost__c'};
                
        for(String key : assortmentDetailsMap.keySet()) {
            AssortmentConsoWrapper wAssortmentConso = new AssortmentConsoWrapper();
            // insert assortment BU Conso
            Assortment_BU__c assortmentBUConso;
            if(!assortmentBUConsoMap.containsKey(key)) {
                Assortment_Detail__c assortmentDetail = assortmentDetailsMap.get(key)[0];
                // get BU Conso
                String keyBU = assortmentDetail.Assortment_BU__r.BU_Target__r.Related_Client__c + '' + assortmentDetail.Assortment_BU__r.BU_Target__r.Country_origin__c + '' +
                    getSortedFormatOrigin(assortmentDetail.Assortment_BU__r.BU_Target__r.Format_Origin__c);
                if(!buConsoMap.containsKey(keyBU)) continue;
                Orga_BU__c buTarget = buConsoMap.get(keyBU);
                assortmentBUConso = new Assortment_BU__c(Name = 'Conso - ' + buTarget.Name + ' - ' + assortmentDetail.Year__c,
                                                         BU_Source__c = assortmentDetail.Assortment_BU__r.BU_Source__c,
                                                         BU_Target__c = buTarget.Id,
                                                         Orga_HE__c = assortmentDetail.Assortment_BU__r.Orga_HE__c,
                                                         Ass_BDate__c = assortmentDetail.Assortment_BU__r.Ass_BDate__c,
                                                         Ass_EDate__c = assortmentDetail.Assortment_BU__r.Ass_EDate__c,
                                                         Year__c = assortmentDetail.Year__c,
                                                         Assortment_type__c = assortmentDetail.Assortment_BU__r.Assortment_type__c,
                                                         Assortment__c = assortmentDetail.Assortment_BU__r.Assortment__c,
                                                         Status__c = 'Validated',
                                                         RecordTypeId = NegoptimHelper.getObjectRecordTypeId(Assortment_BU__c.SObjectType, 'Conso'));
                assortmentBUConsoMap.put(key, assortmentBUConso);
            } else {
                assortmentBUConso = assortmentBUConsoMap.get(key);
            }
            // insert assortment detail conso
            for(Assortment_Detail__c assortmentDetail : assortmentDetailsMap.get(key)) {
                String keyDetail = key + '' + assortmentDetail.Product__c;
                Assortment_Detail__c assortmentDetailConso;
                if(!assortmentDetailConsoMap.containsKey(keyDetail)) {
                    assortmentDetailConso = new Assortment_Detail__c(Assortment_BU__c = assortmentBUConso.Id,
                                                                     Category__c = assortmentDetail.Category__c,
                                                                     Product__c = assortmentDetail.Product__c,
                                                                     Client_Status__c = 'New', Status__c = 'Validated');
                } else {
                    assortmentDetailConso = assortmentDetailConsoMap.get(keyDetail);
                }
                // reset assortment details conso in first load
                if(assortmentDetailConso.Id != null && !this.assortmentDetailConsoIds.contains(assortmentDetailConso.Id)) {
                    for(String field : assortmentDetailsCalculateFields) {
                        if(assortmentDetailConso.get(field) != null) {
                            assortmentDetailConso.put(field, null);
                        }
                    }
                    this.assortmentDetailConsoIds.add(assortmentDetailConso.Id);
                }
                // calculate new values
                for(String field : assortmentDetailsCalculateFields) {
                    decimal newValue = 0;
                    if(assortmentDetailConso.get(field) != null) {
                        newValue = Decimal.valueOf(String.valueOf(assortmentDetailConso.get(field)));
                    }
                    if(assortmentDetail.get(field) != null) {
                        newValue += Decimal.valueOf(String.valueOf(assortmentDetail.get(field)));
                        assortmentDetailConso.put(field, newValue);
                    }
                }
                assortmentDetailConsoMap.put(keyDetail, assortmentDetailConso);
                wAssortmentConso.assortmentDetailsConsoMap.put(assortmentDetail.Product__c, assortmentDetailConso);
                assortmentDetail.WD_Conso__c = true;
                if(!wAssortmentConso.assortmentDetailsLinkedMap.containsKey(assortmentDetail.Product__c)) {
                    wAssortmentConso.assortmentDetailsLinkedMap.put(assortmentDetail.Product__c, new List<Assortment_Detail__c>{assortmentDetail});
                } else {
                    wAssortmentConso.assortmentDetailsLinkedMap.get(assortmentDetail.Product__c).add(assortmentDetail);
                }
            }
            wAssortmentConso.assortmentBUConso = assortmentBUConso;
            assortmentConsoWrapperList.add(wAssortmentConso);
        }
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on Assortment_BU__c fields
            String[] assortmentBUFields = new String[] {'Name', 'RecordTypeId', NegoptimHelper.normalizeAPIName('BU_Source__c'),NegoptimHelper.normalizeAPIName('BU_Target__c'),
                NegoptimHelper.normalizeAPIName('Orga_HE__c'),NegoptimHelper.normalizeAPIName('Ass_BDate__c'), NegoptimHelper.normalizeAPIName('Ass_EDate__c'),
                NegoptimHelper.normalizeAPIName('Year__c'),NegoptimHelper.normalizeAPIName('Assortment_type__c'), NegoptimHelper.normalizeAPIName('Assortment__c'),
                NegoptimHelper.normalizeAPIName('Status__c')};
                
            // check security on Assortment_Detail__c fields
            String[] assortmentDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Product__c'),NegoptimHelper.normalizeAPIName('Client_Status__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('WD_Conso__c')};
            String[] assortmentDetailCreateFields = new String[] {NegoptimHelper.normalizeAPIName('Assortment_BU__c')};
            for(String field : assortmentDetailsCalculateFields) {
                assortmentDetailCreateFields.add(NegoptimHelper.normalizeAPIName(field));
            }
            assortmentDetailCreateFields.addAll(assortmentDetailFields);
            
            for(AssortmentConsoWrapper item : assortmentConsoWrapperList) {
                if(item.assortmentBUConso.Id == null) {
                    assortmentBUConsoInsertList.add(item.assortmentBUConso);
                }
            }
            if(NegoptimHelper.checkCreatibility(Assortment_BU__c.SObjectType, assortmentBUFields) &&
               NegoptimHelper.checkCreatibility(Assortment_Detail__c.SObjectType, assortmentDetailCreateFields) &&
               NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields))
            {
                // insert assortment BU conso
                if(!assortmentBUConsoInsertList.isEmpty()) {
                    List<Database.SaveResult> results = Database.insert(assortmentBUConsoInsertList, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult result = results.get(i);
                        Assortment_BU__c assortmentBUConso = assortmentBUConsoInsertList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' - ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        }
                    }
                }
                // upsert assortment details conso
                Map<Id, AssortmentConsoWrapper> assortmentConsoWrapperMap = new Map<Id, AssortmentConsoWrapper>();
                List<Assortment_Detail__c> assortmentDetailConsoList = new List<Assortment_Detail__c>();
                for(AssortmentConsoWrapper item : assortmentConsoWrapperList) {
                    if(item.assortmentBUConso.Id != null) {
                        for(Assortment_Detail__c assortmentDetail : item.assortmentDetailsConsoMap.values()) {
                            if(assortmentDetail.Assortment_BU__c == null) assortmentDetail.Assortment_BU__c = item.assortmentBUConso.Id;                            
                        }
                        assortmentConsoWrapperMap.put(item.assortmentBUConso.Id, item);
                        assortmentDetailConsoList.addAll(item.assortmentDetailsConsoMap.values());
                    }
                }
                if(!assortmentDetailConsoList.isEmpty()) {
                    List<Database.UpsertResult> resultsDetail = Database.upsert(assortmentDetailConsoList, false);
                    for (Integer i = 0; i < resultsDetail.size(); i++) {
                        Database.UpsertResult result = resultsDetail.get(i);
                        Assortment_Detail__c assortmentDetailConso = assortmentDetailConsoList.get(i);
                        if (!result.isSuccess()) {
                            String errorMessage = '';
                            Database.Error[] errors = result.getErrors();
                            for (Database.Error err : errors) {
                                errorMessage += err.getFields() + ' - ' + err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                            }
                            nb.logError(errorMessage);
                        } else {
                            AssortmentConsoWrapper assortmentConsoWrapper = assortmentConsoWrapperMap.get(assortmentDetailConso.Assortment_BU__c);
                            assortmentDetailsUpdatedList.addAll(assortmentConsoWrapper.assortmentDetailsLinkedMap.get(assortmentDetailConso.Product__c));
                            if(!this.assortmentDetailConsoIds.contains(assortmentDetailConso.Id)) {
                                this.assortmentDetailConsoIds.add(assortmentDetailConso.Id);
                            }
                        }
                    }
                }
                // update assortment details
                if(!assortmentDetailsUpdatedList.isEmpty()) {
                    List<Database.SaveResult> results = Database.update(assortmentDetailsUpdatedList, false);
                    nb.logResults(results, assortmentDetailsUpdatedList);
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
    
    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Assortment Conso Wrapper Class */
    public class AssortmentConsoWrapper {
        private Assortment_BU__c assortmentBUConso {get; set;}
        private Map<Id, Assortment_Detail__c> assortmentDetailsConsoMap {get; set;}
        private Map<Id, List<Assortment_Detail__c>> assortmentDetailsLinkedMap {get; set;}
        public AssortmentConsoWrapper() {
            this.assortmentDetailsConsoMap = new Map<Id, Assortment_Detail__c>();
            this.assortmentDetailsLinkedMap = new Map<Id, List<Assortment_Detail__c>>();
        }
    }
    
    private String getSortedFormatOrigin(String formatOrigin) {
        List<String> formatsList = formatOrigin.split(';');
        formatsList.sort();
        return String.join(formatsList, ';');
    }
}