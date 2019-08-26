trigger Trg_Nego360_Contract_Discount on Contract_Discount__c (before insert, before update, after update) {
    
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        Trg_Nego360_Contract_Discount_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
        if (trigger.isInsert) {
            Trg_Nego360_Contract_Discount_Handler.OnBeforeInsert(trigger.new);
        }
        if (trigger.isUpdate) {
            Trg_Nego360_Contract_Discount_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
        }
    }
    if (trigger.isAfter && trigger.isUpdate) {
        Trg_Nego360_Contract_Discount_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
    }
}