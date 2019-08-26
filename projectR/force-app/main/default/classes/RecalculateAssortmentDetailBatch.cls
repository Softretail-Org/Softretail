/*
 * Recalculate L4L WD(ClientBased,MarketBased)/ND
 **/ 
public class RecalculateAssortmentDetailBatch implements Database.Batchable<SObject> {

    private NegoptimBatch nb;
    private String query;
    private Boolean L4LOnly;
    
    public RecalculateAssortmentDetailBatch(String startedFrom, List<Id> buSourceList, List<Id> buTargetList, Integer year, Boolean L4LOnly, Boolean inPreparationOnly) {
        this.nb = new NegoptimBatch('RecalculateAssortmentDetailBatch', NegoptimBatch.BatchType.Stateless, startedFrom);
        this.L4LOnly = L4LOnly;
        query = 'SELECT Id, Product__c, Year__c, Category__c, Category__r.Path__c, Assortment_BU__c, Assortment_BU__r.Ass_BDate__c,';
        query += ' Assortment_BU__r.BU_Source__c, Assortment_BU__r.BU_Target__c, Assortment_BU__r.Orga_HE__c, Assortment_BU__r.Orga_HE__r.Path__c,';
        query += ' Ass_BU_Cluster__c, Assortment_BU__r.BU_Source__r.SiteOfSales_Number_N1__c, Assortment_BU__r.BU_Source__r.SiteOfSales_Number__c,';
        query += ' Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P1__c, Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P2__c,';
        query += ' New_Client_WD_MarketBased__c, New_Client_WD_ClientBased__c, New_Corp_WD_MarketBased__c, New_Corp_WD_ClientBased__c, New_Client_ND_MarketBased__c,';
        query += ' New_Client_ND_ClientBased__c, New_Corp_ND_MarketBased__c, New_Corp_ND_ClientBased__c, New_Client_ProductNumber__c, L4L_Client_WD_MarketBased__c,';
        query += ' L4L_Client_WD_ClientBased__c, L4L_Client_ND_MarketBased__c, L4L_Client_ND_ClientBased__c, L4L_Client_ProductNumber__c';
        query += ' FROM Assortment_Detail__c';
        query += ' WHERE Version__c = NULL AND Assortment_BU__r.Assortment_type__c = \'Out\' AND Assortment_BU__r.RecordType.DeveloperName = \'Nego\'';
        if(year != null) {
            query += ' AND Year__c = ' + year;
        } else {
            query += ' AND Year__c = ' + Date.today().year();
        }
        if(buSourceList != null && buTargetList != null) {
            query += ' AND (Assortment_BU__r.BU_Source__c IN (\'' + String.join(buSourceList, '\',\'') +'\') OR Assortment_BU__r.BU_Target__c IN (\'' + String.join(buTargetList, '\',\'') +'\'))';
        } else {
            if(buSourceList != null) {
                query += ' AND Assortment_BU__r.BU_Source__c IN (\'' + String.join(buSourceList, '\',\'') +'\')';
            }
            if(buTargetList != null) {
                query += ' AND Assortment_BU__r.BU_Target__c IN (\'' + String.join(buTargetList, '\',\'') +'\')';
            }
        }
        if (inPreparationOnly) {
            query += ' AND Status__c = \'In preparation\'';
        }
        nb.logParameter('buSourceList', buSourceList);
        nb.logParameter('buTargetList', buTargetList);
        nb.logParameter('year', year);
        nb.logParameter('L4LOnly', L4LOnly);
        nb.logParameter('inPreparationOnly', inPreparationOnly);
        nb.logParameter('query', query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();        
        Savepoint sp = Database.setSavepoint();
        try {
            Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> assortmentBUClustersMap = AssortmentUtility.getAssortmentBUClustersMap(scope);
            for (Assortment_Detail__c item : scope) {
                Id buId = item.Assortment_BU__r.BU_Target__c;
                if (assortmentBUClustersMap.containsKey(buId) && assortmentBUClustersMap.get(buId).containsKey(item.Category__c)) {
                    List<Orga_BU__c> clusters = assortmentBUClustersMap.get(buId).get(item.Category__c).values();
                    if (L4LOnly) {
                        item.L4L_Client_WD_MarketBased__c = AssortmentUtility.getL4LWDMarketBased(item, clusters);
                        item.L4L_Client_WD_ClientBased__c = AssortmentUtility.getL4LWDClientBased(item, clusters);
                        item.L4L_Client_ND_MarketBased__c = AssortmentUtility.getL4LNDMarketBased(item, clusters);
                        item.L4L_Client_ND_ClientBased__c = AssortmentUtility.getL4LNDClientBased(item, clusters);
                        item.L4L_Client_ProductNumber__c = AssortmentUtility.getL4LOffsetCumul(item, clusters);
                    } else {
                        AssortmentUtility.assignKPI(item, clusters);
                    }
                    assortmentDetails.add(item);
                }
            }
            // check security on Assortment_Detail__c fields
            String[] assortmentDetailFields = new String[] {NegoptimHelper.normalizeAPIName('L4L_Client_WD_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('L4L_Client_WD_ClientBased__c'), NegoptimHelper.normalizeAPIName('L4L_Client_ND_MarketBased__c'),
                NegoptimHelper.normalizeAPIName('L4L_Client_ND_ClientBased__c'), NegoptimHelper.normalizeAPIName('L4L_Client_ProductNumber__c')};
            
            if(NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                // update assortment details
                if(!assortmentDetails.isEmpty()) {
                    List<Database.SaveResult> results = Database.update(assortmentDetails, false);
                    nb.logResults(results, assortmentDetails);
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
    
    public void finish(Database.BatchableContext bc) {
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}