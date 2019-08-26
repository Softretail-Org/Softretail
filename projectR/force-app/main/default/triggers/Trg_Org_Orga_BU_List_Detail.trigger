/* (A) MAF6.1 Integrity control before removing store/DC/Web from a list (before delete)
 * (B) MAF5.1 A store, Web or DC can't be linked two times to the same BU List (before insert, before update)
 */

trigger Trg_Org_Orga_BU_List_Detail on Orga_BU_List_Detail__c (before insert, before update, before delete, after insert, after delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert) {
            Trg_Org_Orga_BU_List_Detail_Handler.OnBeforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            Trg_Org_Orga_BU_List_Detail_Handler.OnBeforeUpdate(Trigger.New, Trigger.OldMap);
        }
        if(Trigger.isDelete) {
            Trg_Org_Orga_BU_List_Detail_Handler.OnBeforeDelete(Trigger.OldMap);
        }
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert) {
            Trg_Org_Orga_BU_List_Detail_Handler.OnAfterInsert(Trigger.new);
        }
        if(Trigger.isDelete) {
            Trg_Org_Orga_BU_List_Detail_Handler.OnAfterDelete(Trigger.old);
        }
    }
}