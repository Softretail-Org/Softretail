/**
 * @author ULiT
 * @description: Generate/Update SF planning records for any movement of assortment details validated
 * */
public with sharing class GenerateAssortmentSFPlanningBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    private final String query;
    private final Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> BUCategoriesClustersMap;
    
    public GenerateAssortmentSFPlanningBatch(String startedFrom, Set<Id> assortmentDetailIds) {
        this.nb = new NegoptimBatch('GenerateAssortmentSFPlanningBatch', NegoptimBatch.BatchType.Stateless, startedFrom);
        
        String q = ' SELECT Id, Assortment_BU__c, Assortment_BU__r.BU_Target__c, Product__c, Category__c,';
        q += ' Product_Code__c, Product_EAN__c, Movement_Date__c, Record_date__c, Release_Date__c, Status__c,';
        q += ' Client_Status__c, Ass_BU_Cluster__c, Ass_BU_Cluster__r.Assortment_Strat__c,';
        q += ' Last_History__c, Last_History__r.Ass_BU_Cluster__c, Last_History__r.Ass_BU_Cluster__r.Assortment_Strat__c';
        q += ' FROM Assortment_Detail__c';
        q += ' WHERE Status__c = \'Validated\'';
        q += ' AND Version__c = NULL';
        q += ' AND Client_Status__c <> NULL';
        q += ' AND Movement_Date__c <> NULL';
        if (assortmentDetailIds != null && assortmentDetailIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(new List<Id>(assortmentDetailIds), '\',\'') +'\') ';
        }
        this.query = q;
        
        // Get Map of BU Banners with categories and clusters
        this.BUCategoriesClustersMap = AssortmentUtility.getAssortmentBUClustersMap(assortmentDetailIds);
        
        // push inputs to log
        nb.logParameter('assortmentDetailIds', assortmentDetailIds);
        nb.logParameter('query', this.query);
    }
    // start
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // execute
    public void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        Map<String, Assortment_SF_Planning__c> detailSFPlanningMap = new Map<String, Assortment_SF_Planning__c>();
        for (Assortment_SF_Planning__c item : [SELECT Id, Assortment_BU_Detail__c, Business_Unit__c
                                               FROM Assortment_SF_Planning__c
                                               WHERE Assortment_BU_Detail__c IN :scope
                                               AND IsLast__c = TRUE
                                               ORDER BY Business_Unit__r.Assortment_Strat__c ASC])
        {
            String key = '' + item.Assortment_BU_Detail__c + item.Business_Unit__c;
            detailSFPlanningMap.put(key, item);
        }
        List<Assortment_SF_Planning__c> sfPlanningsToUpsert = new List<Assortment_SF_Planning__c>();
        // update and create Assortment_SF_Planning__c records
        for (Assortment_Detail__c item : scope) {
            Map<Integer, Orga_BU__c> clusters;
            if(this.BUCategoriesClustersMap != null && !this.BUCategoriesClustersMap.isEmpty() && this.BUCategoriesClustersMap.get(item.Assortment_BU__r.BU_Target__c) != null) {
                clusters = this.BUCategoriesClustersMap.get(item.Assortment_BU__r.BU_Target__c).get(item.Category__c);
            }
            if (clusters == null) {
                continue;
            }
            Boolean next = false, increase = true;
            Integer previousStratIndex = -1; // no planning generated before
            if (item.Last_History__c != null) {
                // If cluster doesn't changed
                 if (item.Ass_BU_Cluster__c == item.Last_History__r.Ass_BU_Cluster__c) {
                    continue;
                 } else if (item.Last_History__r.Ass_BU_Cluster__c != null && item.Last_History__r.Ass_BU_Cluster__r.Assortment_Strat__c != null) {
                     previousStratIndex = Integer.valueOf(item.Last_History__r.Ass_BU_Cluster__r.Assortment_Strat__c.toLowerCase().replace('strat', ''));
                 }
            }
            Integer newStratIndex;
            if (item.Ass_BU_Cluster__c != null && item.Ass_BU_Cluster__r.Assortment_Strat__c != null) {
                newStratIndex = Integer.valueOf(item.Ass_BU_Cluster__r.Assortment_Strat__c.toLowerCase().replace('strat', ''));
            } else { //make sure new index > previous index in case of unset cluster or strat not exist
                newStratIndex = clusters.size();
            }
            
            if (previousStratIndex == -1 || newStratIndex < previousStratIndex) increase = true;
            if (previousStratIndex != -1 && newStratIndex > previousStratIndex) increase = false;
            for (Integer strat : clusters.keySet()) {
                if (!increase) { // decrease
                    if (strat >= previousStratIndex && strat < newStratIndex) { // reset old records
                        String key = '' + item.Id + clusters.get(strat).Id;
                        if (detailSFPlanningMap.containsKey(key)) { // and not increase
                            // update existing SF planning to be not is last true and next
                            Assortment_SF_Planning__c sfp = detailSFPlanningMap.get(key);
                            sfp.IsLast__c = false;
                            sfPlanningsToUpsert.add(sfp);
                            // Add new SF planning for the cluster to reset the existing
                            sfPlanningsToUpsert.add(createSFPlanningRecord(item, clusters.get(strat), true));
                        }
                    }
                    if (strat == newStratIndex) { // Leave the loop
                        break;
                    }
                } else { // increase or new entries
                    if (strat == previousStratIndex) { // Leave the loop
                        break;
                    }
                    if (clusters.get(strat).Id == item.Ass_BU_Cluster__c || next) {
                        // Add new SF planning for the cluster or next
                        sfPlanningsToUpsert.add(createSFPlanningRecord(item, clusters.get(strat), false));
                        next = true;
                    }
                }
            }
        }
        try {
            // check security on Insert/update Assortment_SF_Planning__c fields
            String[] assortmentySFPlanningFields = new String[] {NegoptimHelper.normalizeAPIName('Assortment_BU_Detail__c'),
                NegoptimHelper.normalizeAPIName('Assortment_BU__c'), NegoptimHelper.normalizeAPIName('product__c'),
                NegoptimHelper.normalizeAPIName('SF_Code__c'), NegoptimHelper.normalizeAPIName('Movement_Date__c'),
                NegoptimHelper.normalizeAPIName('Record_Date__c'), NegoptimHelper.normalizeAPIName('Release_Date__c'),
                NegoptimHelper.normalizeAPIName('Generation_Date__c'), NegoptimHelper.normalizeAPIName('Ext_Id__c'),
                NegoptimHelper.normalizeAPIName('Business_Unit__c'), NegoptimHelper.normalizeAPIName('Planning_status__c'),
                NegoptimHelper.normalizeAPIName('Extraction_status__c'), NegoptimHelper.normalizeAPIName('Type__c'),
                NegoptimHelper.normalizeAPIName('IsLast__c')};
            if (!sfPlanningsToUpsert.isEmpty()) {
                if (NegoptimHelper.checkCreatibility(Assortment_SF_Planning__c.SObjectType, assortmentySFPlanningFields) &&
                    NegoptimHelper.checkUpdatibility(Assortment_SF_Planning__c.SObjectType, assortmentySFPlanningFields)) 
                {
                    List<Database.UpsertResult> results = Database.upsert(sfPlanningsToUpsert, false);
                    nb.logResults(results, sfPlanningsToUpsert);
                }
            }
        } catch(DmlException e) {
            nb.logError(e);
        } catch (Exception e) {
            nb.logError(e);
        }
        // save log
        nb.saveLog(bc);
    }
    // finish
    public void finish(Database.BatchableContext BC) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    private Assortment_SF_Planning__c createSFPlanningRecord(Assortment_Detail__c asd, Orga_BU__c cluster, Boolean isDecrease) {
        String formatedDate = Datetime.newInstanceGmt(Date.today().year(), Date.today().month(), Date.today().day()).format('YYYYMMdd');
        String externalId  = cluster.Country_Origin__r.BU_Code__c + '-' + cluster.BU_Code__c + '-' + asd.Product_Code__c + '-' + asd.Product_EAN__c + '-' + formatedDate;
        String code;
        /***if ((asd.Client_Status__c.equals('New') || asd.Client_Status__c.equals('Increase') || asd.Client_Status__c.equals('Substitute')) && Date.today() < asd.Movement_Date__c)
            code = 'A';
        if ((asd.Client_Status__c.equals('New') || asd.Client_Status__c.equals('Increase') || asd.Client_Status__c.equals('Substitute')) && Date.today() >= asd.Movement_Date__c)
            code = 'N';
        if ((asd.Client_Status__c.equals('New') || asd.Client_Status__c.equals('Increase') || asd.Client_Status__c.equals('Substitute')) && Date.today() > asd.Movement_Date__c.addDays(60))
            code = 'O';
        if ((asd.Client_Status__c.equals('Decrease') || asd.Client_Status__c.equals('Delete')) && Date.today() < asd.Movement_Date__c)
            code = 'D';
        if ((asd.Client_Status__c.equals('Decrease') || asd.Client_Status__c.equals('Delete')) && Date.today() >= asd.Movement_Date__c)
            code = 'S';
        if (asd.Client_Status__c.equals('Opportunity') && Date.today() >= asd.Movement_Date__c)
            code = 'P';
        if ((asd.Client_Status__c.equals('Decrease') || asd.Client_Status__c.equals('Delete') || asd.Client_Status__c.equals('Oppertunity')) && Date.today() >= asd.Movement_Date__c.addDays(60))
            code = null;***/
        // TODO: Move to Helper method
        if (isDecrease) {
            if (Date.today() < asd.Movement_Date__c)
                code = 'D';
            else if (Date.today() >= asd.Movement_Date__c && Date.today() < asd.Movement_Date__c.addDays(60))
                code = 'S';
            else if (Date.today() >= asd.Movement_Date__c.addDays(60))
                code = null;
        } else {
            if (Date.today() < asd.Movement_Date__c)
                code = 'A';
            else if (Date.today() >= asd.Movement_Date__c && Date.today() < asd.Movement_Date__c.addDays(60))
                code = 'N';
            else if (Date.today() >= asd.Movement_Date__c.addDays(60))
                code = 'O';
        }
        return new Assortment_SF_Planning__c(Assortment_BU_Detail__c = asd.Id,
                                             Assortment_BU__c = asd.Assortment_BU__c,
                                             product__c = asd.Product__c,
                                             SF_Code__c = code,
                                             Movement_Date__c = asd.Movement_Date__c,
                                             Record_Date__c = asd.Record_date__c,
                                             Release_Date__c = asd.Release_Date__c,
                                             Generation_Date__c = Date.today(),
                                             Ext_Id__c = externalId,
                                             Business_Unit__c = cluster.Id,
                                             Planning_status__c = 'Demand sent',
                                             Extraction_status__c = 'Extract',
                                             Type__c = 'Regular',
                                             IsLast__c = true);
    }
}