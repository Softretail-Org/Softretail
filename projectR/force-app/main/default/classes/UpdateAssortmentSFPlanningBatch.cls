/**
 * @author ULiT
 * @date 4-5-2019
 * @description queries all Assortment_SF_Planning__c with isLast__c = TRUE, if the SF_Code__c has changed, the batch create a new record with updated fields and code
 * and sets isLast__c to false in the original record. other wise, if the Extraction Status isn't extract, the batch updates the status to extract
 * */
public with sharing class UpdateAssortmentSFPlanningBatch implements Database.Batchable<SObject> {
    private NegoptimBatch nb;
    private String query;
    private Date dateToCompare;
    
    public UpdateAssortmentSFPlanningBatch( String startedFrom, Date dateToCompare) {
        this.nb = new NegoptimBatch('UpdateAssortmentSFPlanningBatch', NegoptimBatch.BatchType.Stateless, startedFrom);
        this.dateToCompare = dateToCompare == null ? Date.today() : dateToCompare;
        query = 'SELECT Id, Assortment_BU__c, Product__c, Record_Date__c, Release_Date__c, Business_Unit__c,';
        query += ' Planning_status__c, Type__c, Movement_Date__c, Extraction_Status__c, IsLast__c, SF_Code__c, Ext_id__c, Generation_Date__c';
        query += ' FROM Assortment_SF_Planning__c WHERE IsLast__c = TRUE';
        query += ' AND Movement_Date__c <> NULL';
        nb.logParameter('Query', query);
        nb.logParameter('dateToCompare', this.dateToCompare.format());
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Assortment_SF_Planning__c> scope) {
        List<Assortment_SF_Planning__c> listToUpsert = new List<Assortment_SF_Planning__c>();
        String formatedDate = Datetime.newInstanceGmt(Date.today().year(), Date.today().month(), Date.today().day()).format('YYYYMMdd');
        for (Assortment_SF_Planning__c item : scope) {
            String code;
            // TODO: Move to Helper method
            if(item.SF_Code__c == NULL || item.SF_Code__c.equals('D') || item.SF_Code__c.equals('S')) {  
                if (dateToCompare < item.Movement_Date__c)
                    code = 'D';
                else if (dateToCompare >= item.Movement_Date__c && dateToCompare < item.Movement_Date__c.addDays(60))
                    code = 'S';
                else if (dateToCompare >= item.Movement_Date__c.addDays(60))
                    code = null;
            } else if(item.SF_Code__c.equals('A') || item.SF_Code__c.equals('N') || item.SF_Code__c.equals('O')) {
                if (dateToCompare < item.Movement_Date__c)
                    code = 'A';
                else if (dateToCompare >= item.Movement_Date__c && dateToCompare < item.Movement_Date__c.addDays(60))
                    code = 'N';
                else if (dateToCompare >= item.Movement_Date__c.addDays(60))
                    code = 'O';
            } else if(item.SF_Code__c == null || item.SF_Code__c.equals('P')) {
                if (dateToCompare < item.Movement_Date__c)
                    code = null;
                else code = 'P';
            }
            if (item.SF_Code__c != code) {
                Assortment_SF_Planning__c newRecord = item.clone(false, true, false, false);
                List<String> itemExtId = item.Ext_id__c.split('-');
                itemExtId.remove(itemExtId.size() - 1);
                String newExtId = String.join(itemExtId, '-') + '-' + formatedDate;
                newRecord.SF_Code__c = code;
                newRecord.Generation_Date__c = Date.today();
                newRecord.Ext_id__c = newExtId;
                newRecord.Extraction_Status__c = 'Extract';
                newRecord.IsLast__c = true;
                listToUpsert.add(newRecord);
                item.IsLast__c = false;
                nb.logMessage('record <a href="/' + item.Id + '" target="_blank">' + item.Ext_id__c + '</a>: code updated from <span style="color:red">' +
                              item.SF_Code__c + '</span> to <span style="color:green">' + code + '</span> in a new record');
            } else {
                if (item.Extraction_Status__c == null || !item.Extraction_Status__c.equals('Extract'))
                    item.Extraction_Status__c = 'Extract';
            }
            listToUpsert.add(item);
        }
        
        try {
            // check security on upsert Assortment_SF_Planning__c fields
            String[] assortmentSFPlanningFields = new String[] {NegoptimHelper.normalizeAPIName('SF_Code__c'), NegoptimHelper.normalizeAPIName('Generation_Date__c'),
                NegoptimHelper.normalizeAPIName('Ext_id__c'), NegoptimHelper.normalizeAPIName('Extraction_Status__c'), NegoptimHelper.normalizeAPIName('IsLast__c')};
            if(!listToUpsert.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Assortment_SF_Planning__c.SObjectType, assortmentSFPlanningFields) &&
                   NegoptimHelper.checkUpdatibility(Assortment_SF_Planning__c.SObjectType, assortmentSFPlanningFields))
                {
                    List<Database.UpsertResult> results = Database.upsert(listToUpsert, false);
                    nb.logResults(results, listToUpsert);
                }
            }            
        } catch (Exception ex) {
            nb.logError(ex);
            System.debug('ex >>>> ' + ex.getMessage() + ' - Line: ' + ex.getLineNumber());
        }
        // save log
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.sendEmail(bc, null, null);
    }
}