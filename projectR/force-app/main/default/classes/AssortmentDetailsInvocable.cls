/**
 * Called from process builder to create
 * lines on Assortment_SF_Planning__c based on BU cluster
 * */
global class AssortmentDetailsInvocable {

    @InvocableMethod(label='Assortment Details Invocable' description='Assortment Details Invocable.')
    public static void generateAssortmentPlanning(List<Assortment_Detail__c> assortmentDetails) {
        Set<Id> BUClusterIdSet = new Set<Id>();
        Set<Id> childrenBUIdSet = new Set<Id>();
        Map<Id, Assortment_Detail__c> assortmentDetailMap = new Map<Id, Assortment_Detail__c>(assortmentDetails);
        Set<Id> assortmentDetailsIgnoredSet = new Set<Id>();
        for(Assortment_Detail__c item : assortmentDetails) {
            BUClusterIdSet.add(item.Ass_BU_Cluster__c);
        }
        /**/
        Map<Id, Set<Id>> BUIdsMap = NegoptimHelper.getBUChildrenMap(BUClusterIdSet);
        for(Id key : BUIdsMap.keySet()) {
            for(Id value : BUIdsMap.get(key)) {
                if(value != key) { // to not push parent
                    childrenBUIdSet.add(value);
                }
            }
        }
        /**/
        List<Assortment_SF_Planning__c> assortmentPlanningList = new List<Assortment_SF_Planning__c>();
        Set<Id> assortmentPlanningToDeleteSet = new Set<Id>();
        // get old assortment planning list
        for(Assortment_SF_Planning__c item : [SELECT Id, Assortment_BU_Detail__c, Business_Unit__c, Assortment_BU__c, Product__c
                                              FROM Assortment_SF_Planning__c
                                              WHERE Assortment_BU_Detail__c IN :assortmentDetailMap.keySet()])
        {
            Assortment_Detail__c assortmentDetail = assortmentDetailMap.get(item.Assortment_BU_Detail__c);
            if(BUIdsMap.containsKey(assortmentDetail.Ass_BU_Cluster__c)
               && !BUIdsMap.get(assortmentDetail.Ass_BU_Cluster__c).contains(item.Business_Unit__c))
            {
                assortmentPlanningToDeleteSet.add(item.Id);
            } else {
                if(item.Product__c != assortmentDetail.Product__c) {
                    item.Product__c = assortmentDetail.Product__c;
                    assortmentPlanningList.add(item);
                }
                assortmentDetailsIgnoredSet.add(assortmentDetail.Id);
            }
        }
        if(!assortmentPlanningToDeleteSet.isEmpty()) {
            if(NegoptimHelper.checkDeletibility(Assortment_SF_Planning__c.SObjectType)) {
                delete [SELECT Id FROM Assortment_SF_Planning__c WHERE Id IN :assortmentPlanningToDeleteSet];
            }
        }
        
        for(Assortment_Detail__c item : assortmentDetails) {
            if(assortmentDetailsIgnoredSet.contains(item.Id))
                continue;
            if(BUIdsMap.containsKey(item.Ass_BU_Cluster__c)) {
                for(Id bu : BUIdsMap.get(item.Ass_BU_Cluster__c)) {
                    Assortment_SF_Planning__c assortementPlanning = new Assortment_SF_Planning__c(Business_Unit__c = bu);
                    assortementPlanning.Assortment_BU__c = item.Assortment_BU__c;
                    assortementPlanning.Assortment_BU_Detail__c = item.Id;
                    assortementPlanning.Generation_Date__c = System.today();
                    assortementPlanning.Product__c = item.Product__c;
                    assortmentPlanningList.add(assortementPlanning);
                }
            }
        }
        // check security on upsert Assortment_SF_Planning__c fields
        String[] assortmentSFPlanningFields = new String[] {NegoptimHelper.normalizeAPIName('Assortment_BU__c'), NegoptimHelper.normalizeAPIName('Assortment_BU_Detail__c'),
                NegoptimHelper.normalizeAPIName('Product__c'), NegoptimHelper.normalizeAPIName('Generation_Date__c')};
                    
        if(!assortmentPlanningList.isEmpty()) {
            if(NegoptimHelper.checkCreatibility(Assortment_SF_Planning__c.SObjectType, assortmentSFPlanningFields) &&
               NegoptimHelper.checkUpdatibility(Assortment_SF_Planning__c.SObjectType, assortmentSFPlanningFields))
            {
                List<Database.UpsertResult> results = Database.upsert(assortmentPlanningList, false);
            }
        }
    }
}