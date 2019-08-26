/*
 * Check and validate uniqueness constraint of name and supplier in negoscope (Sup_sup_NegoScope__c)
 * Update Sub NS owner when parent NS owner change.
 * NS Management.
 * Assign the supp ISO code into the NS ISO code.
 *
 **/
trigger Trg_Org_Sup_Sup_NegoScope on Sup_sup_NegoScope__c (before insert, before update, after insert, after update) {
	
	if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
		if (trigger.isUpdate) {
			Trg_Org_Sup_Sup_NegoScope_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
		}
		Trg_Org_Sup_Sup_NegoScope_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
	}
	
	if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
		Trg_Org_Sup_Sup_NegoScope_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
		if (trigger.isInsert) {
			Trg_Org_Sup_Sup_NegoScope_Handler.OnBeforeInsert(trigger.new);
		}else{
			Trg_Org_Sup_Sup_NegoScope_handler.OnBeforeUpdate(trigger.newMap, trigger.OldMap);
		}
	}
}