public class GenerateAssortmentTargetDetailsBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    private Assortment_BU__c budgetAssortment;
    private Map<Id, Assortment_BU__c> targetAssortmentsMap;
    
    public GenerateAssortmentTargetDetailsBatch(String startedFrom, Id dVBudgetId) {
        this.nb = new NegoptimBatch('GenerateAssortmentTargetDetailsBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.nb.logParameter('dVBudgetId', dVBudgetId);
        // fetch budget assortment
        this.budgetAssortment = [SELECT Id, Name, BU_Target__c, BU_Source__c, Orga_HE__c, Orga_HE__r.Path__c, Year__c, Ass_BDate__c, Ass_EDate__c
                                 FROM Assortment_BU__c
                                 WHERE Id = :dVBudgetId];
        // fetch target assortments head
        targetAssortmentsMap = new Map<Id, Assortment_BU__c>();
        for (Assortment_BU__c item : [SELECT Id, BU_Target__c FROM Assortment_BU__c
                                      WHERE RecordType.DeveloperName = 'Target'
                                      AND Assortment_Type__c = 'In'
                                      AND Year__c = :this.budgetAssortment.Year__c
                                      AND BU_Source__c = :this.budgetAssortment.BU_Target__c
                                      AND Orga_HE__c = :this.budgetAssortment.Orga_HE__c])
        {
            targetAssortmentsMap.put(item.BU_Target__c, item);
        }
        
        query = '';
        query += ' SELECT Id, Product__c';
        query += ' FROM Assortment_Detail__c';
        query += ' WHERE Assortment_BU__c = \'' + dVBudgetId + '\'';
        query += ' AND Version__c = NULL';
        nb.logParameter('query', query);
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        
        List<Assortment_Detail__c> targetDetailsToInsert = new List<Assortment_Detail__c>();
        Set<Id> productsIdSet = new Set<Id>();
        Set<String> existingTargetDetailsKeySet = new Set<String>();
        Map<String, Assortment_Detail__c> histoDetailsMap = new Map<String, Assortment_Detail__c>();
        for (Assortment_Detail__c detail : scope) {
            productsIdSet.add(detail.Product__c);            
        }
        for (Assortment_Detail__c targetDetail : [SELECT Product__c, Assortment_BU__r.BU_Target__c
                                                  FROM Assortment_Detail__c
                                                  WHERE Assortment_BU__c IN :this.targetAssortmentsMap.values()
                                                  AND Product__c IN :productsIdSet])
        {
            existingTargetDetailsKeySet.add(targetDetail.Product__c + '-' + targetDetail.Assortment_BU__r.BU_Target__c);
        }
        for (Assortment_Detail__c item : [SELECT Id, Product__c, Category__c, Assortment_BU__r.BU_Target__c,
                                          Client_Status__c, Ass_BU_Cluster__c
                                          FROM Assortment_Detail__c
                                          WHERE Product__c IN :productsIdSet
                                          AND Assortment_BU__r.RecordType.DeveloperName = 'Nego'
                                          AND Assortment_BU__r.Status__c = 'Validated'
                                          AND Assortment_BU__r.Assortment_Type__c = 'Out'
                                          AND Assortment_BU__r.Year__c = :(this.budgetAssortment.Year__c - 1)
                                          AND Assortment_BU__r.BU_Source__c = :this.budgetAssortment.BU_Target__c
                                          AND Assortment_BU__r.Orga_HE__c = :this.budgetAssortment.Orga_HE__c
                                          AND Version__c = NULL
                                          AND Category__c <> NULL
                                          AND Product__r.isActive = TRUE
                                          AND Status__c = 'Validated'])
        {
            histoDetailsMap.put(item.Product__c + '-' + item.Assortment_BU__r.BU_Target__c, item);
        }
        String key;
        for (Id productId : productsIdSet) {
            for (Id buId : targetAssortmentsMap.keySet()) {
                key = productId + '-' + buId;
                if (!existingTargetDetailsKeySet.contains(key)) {
                    Assortment_Detail__c targetDetail = new Assortment_Detail__c (Product__c = productId,
                                                                                  Assortment_BU__c = targetAssortmentsMap.get(buId).Id);
                    if (histoDetailsMap.containsKey(key)) {
                        Assortment_Detail__c item = histoDetailsMap.get(key);
                        targetDetail.Client_Status__c = item.Client_Status__c;
                        targetDetail.Ass_BU_Cluster__c = item.Ass_BU_Cluster__c;
                        targetDetail.ref_Client_Assortment__c = item.Id;
                    }
                    targetDetail.Record_date__c = Date.newInstance(Integer.valueOf(budgetAssortment.Year__c), 1, 1);
                    targetDetail.Status__c = 'In preparation';
                    targetDetailsToInsert.add(targetDetail);
                }
            }
        }
        
        try {
            // check security on insert Assortment_Detail__c
            String[] assortmentDetailFields = new String[] {NegoptimHelper.normalizeAPIName('Product__c'), NegoptimHelper.normalizeAPIName('Assortment_BU__c'),
                NegoptimHelper.normalizeAPIName('ref_Client_Assortment__c'), NegoptimHelper.normalizeAPIName('Ass_BU_Cluster__c'), NegoptimHelper.normalizeAPIName('Client_Status__c'),
                NegoptimHelper.normalizeAPIName('Record_date__c'), NegoptimHelper.normalizeAPIName('Status__c')};
            
            if(NegoptimHelper.checkCreatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                insert targetDetailsToInsert;
            }
        } catch (Exception ex) {
            nb.logError(ex);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.sendEmail(bc, null, null);
    }
    
}