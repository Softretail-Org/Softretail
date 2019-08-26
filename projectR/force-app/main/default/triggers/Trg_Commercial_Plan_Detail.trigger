/*(A) Update Contract reference/Temp Contract and Update Line_Status__c/Extraction_Status__c [on Before-Insert-Update trigger]
 *(B) Update Total_Marketing_Events_Justified__c based on update Contribution_Total__c [on AfterInsert-Update-Delete trigger]
 */

trigger Trg_Commercial_Plan_Detail on Commercial_Plan_Detail__c (before insert, before update, after insert, after update, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            // Static method to handle (A) procedure.
            Trg_Commercial_Plan_Detail_Handler.OnBeforeInsertOrUpdate(Trigger.new, Trigger.OldMap);
        }
    }
    else if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
            // Static method to handle (B) procedure.
            Trg_Commercial_Plan_Detail_Handler.OnAfterInsertOrUpdateOrDelete(Trigger.new, Trigger.OldMap);
        }
    }
}