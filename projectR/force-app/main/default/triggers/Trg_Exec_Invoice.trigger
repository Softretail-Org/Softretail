/**
 * Invoice number Generation based on Invoice_Number_Prefix__c. [before insert]
 * Re-calculate the AlreadyInvoiced of the condition when deleting an Invoice. [before delete]
 */
trigger Trg_Exec_Invoice on Invoice__c (before insert, before update, after update, before delete, after delete) {
    
    if(Trigger.isInsert && Trigger.isBefore) {
        Trg_Exec_Invoice_Handler.OnBeforeInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isBefore) {
        Trg_Exec_Invoice_Handler.OnBeforeUpdate(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isAfter) {
        Trg_Exec_Invoice_Handler.OnAfterUpdate(Trigger.new, Trigger.OldMap);
    }
    else if(Trigger.isDelete && Trigger.isBefore) {
        Trg_Exec_Invoice_Handler.OnBeforeDelete(Trigger.old);
    }
}