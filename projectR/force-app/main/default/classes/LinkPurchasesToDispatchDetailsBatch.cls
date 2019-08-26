/**
 * LinkPurchasesToDispatchDetailsBatch
 * */
public class LinkPurchasesToDispatchDetailsBatch implements Database.Batchable<SObject> {
    
    private NegoptimBatch nb;
    private Integer year;
    private String query;
    
    public LinkPurchasesToDispatchDetailsBatch(String startedFrom, List<Id> contractIds, List<Id> conditionIds, Integer year) {
        this.nb = new NegoptimBatch('LinkPurchasesToDispatchDetailsBatch' , NegoptimBatch.BatchType.Stateless, startedFrom);
        this.year = year == null ? Date.today().year() : year;
        String q = 'SELECT Inv_BUDispatch__c, Order_to_DC__c, PG__c, Hierarchy_level_dispatch__c, Purchases_Flow_PG__c';
        q += ' FROM Inv_BUDispatch_Details__c';
        q += ' WHERE Purchases_Flow_PG__c = NULL';
        q += ' AND Inv_Fiscal_Year__c = :year';
        if (conditionIds != null && !conditionIds.isEmpty())
            q += ' AND Discount__c IN (\'' + String.join(conditionIds, '\',\'') + '\')';
        if (contractIds != null && !contractIds.isEmpty())
            q += ' AND Contract__c IN (\'' + String.join(contractIds, '\',\'') + '\')';
        this.query = q;
        nb.logParameter('contractIds', contractIds);
        nb.logParameter('conditionIds', conditionIds);
        nb.logParameter('year', this.year);
        nb.logParameter('query', this.query);
    }
    
    public Iterable<SObject> start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(Database.BatchableContext bc, List<Inv_BUDispatch_Details__c> scope) {
        Set<Id> BUSet = new Set<Id>();
        Set<Id> DCSet = new Set<Id>();
        Set<Id> PGSet = new Set<Id>();
        Map<String, List<Purchases_Flow_PG__c>> purchasesMap = new Map<String,  List<Purchases_Flow_PG__c>>();
        for (Inv_BUDispatch_Details__c item : scope) {
            BUSet.add(item.Inv_BUDispatch__c);
            DCSet.add(item.Order_to_DC__c);
            PGSet.add(item.PG__c);
        }
        for (Purchases_Flow_PG__c item : [SELECT PG__c, BU__c, DC__c, Section__c
                                          FROM Purchases_Flow_PG__c
                                          WHERE PG__c IN :PGSet
                                          AND DC__c IN :DCSet
                                          AND BU__c IN :BUSet
                                          AND Year__c = :this.year])
        {
            String key = item.BU__c + '' + item.PG__c;// + '' + item.Section__c;
            if (item.DC__c != null)
                key += item.DC__c;
            if (!purchasesMap.containsKey(key))
                purchasesMap.put(key, new List<Purchases_Flow_PG__c>{item});
            else
                purchasesMap.get(key).add(item);
        }
        List<Inv_BUDispatch_Details__c> dispatchDetailsToUpdateList = new List<Inv_BUDispatch_Details__c>();
        for (Inv_BUDispatch_Details__c item : scope) {
            String key = item.Inv_BUDispatch__c + '' + item.PG__c;// + '' + item.Hierarchy_level_dispatch__c;
            if (item.Order_to_DC__c != null)
                key += item.Order_to_DC__c;
            if (purchasesMap.containsKey(key)) {
                if (purchasesMap.get(key).size() == 1) {
                    item.Purchases_Flow_PG__c = purchasesMap.get(key)[0].Id;
                    dispatchDetailsToUpdateList.add(item);
                } else 
                    nb.logMessage(purchasesMap.get(key).size() + ' Purchases_Flow_PG__c for Dispatch Detail: ' + item.Id);
            }
        }
        try {
            if (!dispatchDetailsToUpdateList.isEmpty()) {
                // check security on update Inv_BUDispatch_Details__c
                String[] invBUDispatchDetailsFields = new String[] {NegoptimHelper.normalizeAPIName('Purchases_Flow_PG__c')};
                if(NegoptimHelper.checkUpdatibility(Inv_BUDispatch_Details__c.SObjectType, invBUDispatchDetailsFields)) {
                    update dispatchDetailsToUpdateList;
                }
            }
        } catch (Exception ex) {
            nb.logError(ex);
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.sendEmail(bc, nb.getMessageTraceLog(), null);
    }
}