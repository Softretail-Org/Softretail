/* (A) MAF6.1 Integrity control before removing store/DC/Web from a list (before delete)
 * Prerequisite:
 * Store BU, Warehouse BU or Web is related to a Country BU, List BU, Region BU or Group BU,
 * in which one of the following Sobjects is related to the Country BU (parent)
 *          1) Contract__c
 *          2) Contract_Discount__c
 *          3) Invoice__c
 *          4) Inv_BUDispatch_Detail__c
 * Constraint: Records of the List detail in Country BU, List BU, Region BU or Group BU must not be removed.
 * (B) MAF5.1 A store, Web or DC can't be linked two times to the same BU List (before insert, before update)
 * Description: Integrity constraint to check duplication in fields of 'Entity_List__c' on 'Orga_BU_List_Detail__c'
 * of Country BU, List BU, Region BU or Group BU.
 */
 
public class Trg_Org_Orga_BU_List_Detail_Handler {
	
    public static void OnBeforeInsert(List<Orga_BU_List_Detail__c> newBUListDetails) {
        checkDuplicationConstraintOnEntityList(newBUListDetails, null);
    }
    
    public static void OnBeforeUpdate(List<Orga_BU_List_Detail__c> newBUListDetails, Map<Id, Orga_BU_List_Detail__c> oldBUListDetailMap) {
        // check duplicate bu list
        checkDuplicationConstraintOnEntityList(newBUListDetails, oldBUListDetailMap);
        // check linked bu to entity
        List<Orga_BU_List_Detail__c> buListDetails = new List<Orga_BU_List_Detail__c>();
        Map<Id, Orga_BU_List_Detail__c> oldBUListMap = new Map<Id, Orga_BU_List_Detail__c>();
        for (Orga_BU_List_Detail__c item : newBUListDetails) {
            if (item.Entity__c != oldBUListDetailMap.get(item.Id).Entity__c || item.Entity_List__c != oldBUListDetailMap.get(item.Id).Entity_List__c) {
                buListDetails.add(item);
                oldBUListMap.put(item.Id, oldBUListDetailMap.get(item.Id));
            }
        }
        if (!buListDetails.isEmpty()) {
            checkRemoveConstraintWhenBUInRelation(buListDetails, oldBUListMap);
        }
    }
    
    public static void OnBeforeDelete(Map<Id, Orga_BU_List_Detail__c> oldBUListDetailMap) {
        // before delete
        checkRemoveConstraintWhenBUInRelation(null, oldBUListDetailMap);
    }
    
    // reparenting sell_in on after insert BU list detail
    public static void OnAfterInsert(List<Orga_BU_List_Detail__c> newBUDetails){
         if(!System.isBatch() && !System.isFuture())
           reparentingSellin(newBUDetails, true, false);
    }
    
    // reparenting sell_in on after delete BU list detail
    public static void OnAfterDelete(List<Orga_BU_List_Detail__c> deletedBUDetails){
        reparentingSellin(deletedBUDetails, false, true);
    }
    
    // Check if the BU child deleted is linked to sell_in_flow
    // On After-Delete
    private static void reparentingSellin(List<Orga_BU_List_Detail__c> BUDetails, Boolean afterInsert, Boolean afterDelete){
        List<Id> BUIds = new List<Id>();
        for (Orga_BU_List_Detail__c item : BUDetails){
            BUIds.add(item.Entity_List__c);
        }
        if(!System.isBatch() && !System.isFuture()){
           Database.executeBatch(new ReparentingSellinBatch('After Insert/Delete BU List Detail', null, null, null, null, null, null,
                                                           (afterInsert ? BUIds : null), (afterDelete ? BUIds : null), false, null, null));
        }
    }
    
    // (B) Check Linked entity (Entity_List__c) dupliation on the parent BU.
    private static void checkDuplicationConstraintOnEntityList(List<Orga_BU_List_Detail__c> newBUListDetails, Map<ID, Orga_BU_List_Detail__c> oldBUListDetailMap) {
        Map<String, Orga_BU_List_Detail__c> entityListMap = new Map<String, Orga_BU_List_Detail__c>();
        Set<Id> entitySet = new Set<Id>();
        for (Orga_BU_List_Detail__c item : newBUListDetails) {
            if(oldBUListDetailMap == null || (oldBUListDetailMap != null && ((item.Entity__c == oldBUListDetailMap.get(item.Id).Entity__c) &&
                                                                             (item.Entity_List__c != oldBUListDetailMap.get(item.Id).Entity_List__c))))
            {
                if (!entityListMap.containsKey(item.Entity_List__c) && !entitySet.contains(item.Entity__c)) {
                    entityListMap.put(item.Entity_List__c, item);
                    entitySet.add(item.Entity__c);
                }
            }
    	}
        for (Orga_BU_List_Detail__c item : [SELECT Entity_List__c, Entity__c
                                            FROM Orga_BU_List_Detail__c
                                            WHERE Entity_List__c IN :entityListMap.KeySet()
                                            AND Entity__c IN :entitySet])
        {
            Orga_BU_List_Detail__c buListDetail = entityListMap.get(item.Entity_List__c);
            buListDetail.Entity_List__c.addError(System.Label.MSG_Code_LinkedEntity_Already_Exist);
        }
    }
    
    // (A) Records of the List detail in Country BU, List BU, Region BU or Group BU must not be removed.
    private static void checkRemoveConstraintWhenBUInRelation(List<Orga_BU_List_Detail__c> newBUListDetails, Map<Id, Orga_BU_List_Detail__c> oldBUListDetailMap) {
        Boolean buLinkedToDispatch = false, buLinkedToInvoice = false, buLinkedToCondition = false, buLinkedToContract = false;
        // Mark error when delete event is occurred in the case where
        // Contract__c, Contract_Discount__c, Invoice__c or Inv_BUDispatch_Details__c
        // are related to the parent BU of the current child BU.
        List<Id> entityIds = new List<Id>(), entityListIds = new List<Id>();
        for (Orga_BU_List_Detail__c item : oldBUListDetailMap.values()) {
            entityIds.add(item.Entity__c);
            entityListIds.add(item.Entity_List__c);
        }
        Map<Id, Orga_BU__c> buResultsMap = new Map<Id, Orga_BU__c>([SELECT Id, (SELECT Id FROM Invoice_BU_Dispatch_Details1__r LIMIT 1),
                                                                    (SELECT Id FROM Invoices__r LIMIT 1),
                                                                    (SELECT Id FROM Contract_Conditions__r LIMIT 1),
                                                                    (SELECT Id FROM Contracts1__r LIMIT 1)
                                                                    FROM Orga_BU__c
                                                                    WHERE Id IN :entityIds OR Id IN :entityListIds]);
        
        Map<Id, Orga_BU_List_Detail__c> newBUListMap = new Map<Id, Orga_BU_List_Detail__c>();
        if(newBUListDetails != null) newBUListMap = new Map<Id, Orga_BU_List_Detail__c>(newBUListDetails);
        
        for (Orga_BU_List_Detail__c item : oldBUListDetailMap.values()) {
            Orga_BU_List_Detail__c buListDetail = newBUListMap.get(item.Id);
            // get result child BU
            Orga_BU__c buResult = buResultsMap.get(item.Entity_List__c);
            if(!buResult.Invoice_BU_Dispatch_Details1__r.isEmpty()) {
                item.addError(system.Label.MSG_BU_Parent_Related_To_BUDispatchDetail);
            }
            // get result parent BU
            buResult = buResultsMap.get(item.Entity__c);
            // case Update/Delete BU List
            if(buListDetail == null || (buListDetail != null && buListDetail.Entity__c != item.Entity__c)) {
                if(!buResult.Invoices__r.isEmpty()) {
                    item.Entity__c.addError(system.Label.MSG_BU_Parent_Related_To_Invoice);
                }
                else if(!buResult.Contract_Conditions__r.isEmpty()) {
                    item.Entity__c.addError(system.Label.MSG_BU_Parent_Related_To_ContractDiscount);
                }
                else if(!buResult.Contracts1__r.isEmpty()) {
                    item.Entity__c.addError(system.Label.MSG_BU_Parent_Related_To_Contract);
                }
            }
        }
    }
}