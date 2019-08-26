public with sharing class GenerateLForLAssortments  implements Database.Batchable<sObject> {
    
    private final String query;
    private NegoptimBatch nb;
    private List<Assortment_BU__c> AssortmentBUNego ;
    private List<Assortment_BU__c> NegoWithL4L;
    private List<Assortment_BU__c> AssortmentBUL4L;
    private Map<String , Assortment_Detail__c> DetailsToClone;
    private Map<String , Assortment_Detail__c> ClonedDetails;
    public GenerateLForLAssortments(String startedFrom, Set<Id> AssortmentBUIdList) {
        query = 'SELECT Assortment_BU__r.Id ,Product__c ,Ass_BU_Cluster__c,Client_Status__c,Client_Clust1__c ,Client_Clust2__c ,Client_Clust3__c,';
		query += 'Client_Clust4__c ,Client_Clust5__c,Client_Clust6__c ';
        query += 'FROM Assortment_Detail__c ';
        DetailsToClone = new Map<String , Assortment_Detail__c>(); 
        ClonedDetails = new Map<String , Assortment_Detail__c>();
        this.nb = new NegoptimBatch('GenerateAssortmentSFPlanningBatch', NegoptimBatch.BatchType.Stateless, startedFrom);
        AssortmentBUL4L = new List<Assortment_BU__c>();
        NegoWithL4L = new List<Assortment_BU__c>();
        AssortmentBUNego = new List<Assortment_BU__c>();
        AssortmentBUNego =  [Select RecordType.Developername ,Year__c,Status__c,
                             Assortment_Type__c,Ass_BDAte__c,Ass_EDate__c
                             From Assortment_BU__c
                             where RecordType.Developername = 'nego'];
        List<Integer> AssortmentBUNegoToRemove = new List<Integer>();
        List<Assortment_BU__c> AssortmentBUL4L = new List<Assortment_BU__c>();

        
        for (Assortment_BU__c item : this.AssortmentBUNego) {
             Assortment_BU__c item_2 = [Select RecordType.Developername  ,Year__c,Status__c,
                                            Assortment_Type__c,Ass_BDAte__c,Ass_EDate__c,
                                            BU_Target__c,BU_Source__c,Orga_HE__c
                                            From Assortment_BU__c
                                            where RecordType.Developername  = 'L4L'
                                            And Assortment_Type__c = 'out'
                                            And Year__c = :item.Year__c-1
                                            And Status__c = :item.Status__c
                                            And Ass_BDAte__c = :item.Ass_BDAte__c-1
                                            And Ass_EDate__c = :item.Ass_EDate__c-1
                                            And BU_Target__c = :item.BU_Target__c
                                            And BU_Source__c = :item.BU_Source__c
                                            And Orga_HE__c = :item.Orga_HE__c];
            
                if (item_2 != null) {
                    if (item.Active_Children_Count__c == item_2.Active_Children_Count__c) {
                        AssortmentBUNegoToRemove.add(AssortmentBUNego.indexOf(item));
                    }else{
                        NegoWithL4L.add(item);
                        AssortmentBUNego.add(item_2);
                    }
                }
            
        }

	for (Integer item : AssortmentBUNegoToRemove)
        AssortmentBUNego.remove(item);
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Assortment_Detail__c> scope) {
        Assortment_Detail__c Clone;
        for (Assortment_Detail__c item2 : scope) {
            for (Assortment_BU__c item1 : AssortmentBUNego ) {
                if (item2.Assortment_BU__r.Id == item1.Id){
                    Clone = item2.clone(false,true,true,false);
                }
            }
        }
        
        /*for (Assortment_Detail__c item2 : scope) {
            for (Assortment_BU__c item1 : NegoWithL4L ) {
                if (item2.Assortment_BU__r.Id == item1.Id){
                    DetailsToClone.put(key, value);
                    break;
                }
            }
            for (Assortment_BU__c item1 : NegoWithL4L ) {
                if (item2.Assortment_BU__r.Id == item1.Id){
                    ClonedDetails.put(key, value);
                    break;
                }
            }
        }*/
        
    }
    
    
    public void finish(Database.BatchableContext bc) {
        
    }
}