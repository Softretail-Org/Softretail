/**
 * @author ULiT
 * @description Trigger Trg_Assortment_Detail interface
 * */
trigger Trg_Assortment_Detail on Assortment_Detail__c (before insert, before update, after insert, after update) {
    /*if (trigger.isBefore) {
        if (trigger.isInsert || trigger.isUpdate) {
            if (trigger.isInsert) {
                Trg_Assortment_Detail_Handler.OnBeforeInsert(trigger.new);
            }
            if (trigger.isUpdate) {
                Trg_Assortment_Detail_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
            }
            Trg_Assortment_Detail_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
        }
        for (Assortment_Detail__c item : Trigger.new) {
            item.Force_Update__c = false;
        }
    }
    if (Trigger.isAfter) {
        if (trigger.isInsert || trigger.isUpdate) {
            Trg_Assortment_Detail_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
        }
    }*/
}