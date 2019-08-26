/**
* Integrity Constraint to check duplication
* in fields of 'Code__c' with 'Country_origin__c'
* and 'Name' with 'Country_origin__c'
* and 'Code' with 'Country_origin__c'
* and 'Fiscal number' with 'Country_origin__c' (Intracomm, Siren, Siret)
* Creation of default NS when a supplier is created 
* */
trigger Trg_Org_Supplier on Sup_Supplier__c (before insert, before update,after insert,after update) {
    
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
    	Trg_Org_Supplier_Handler.OnBeforeInsertOrUpdate(trigger.new, trigger.OldMap);
		if (trigger.isInsert) {
			Trg_Org_Supplier_Handler.OnBeforeInsert(trigger.new);
		}
		if (trigger.isUpdate) {
			Trg_Org_Supplier_Handler.OnBeforeUpdate(trigger.new, trigger.OldMap);
		}
	}
    if (trigger.isAfter) {
		if (trigger.isInsert) {
			Trg_Org_Supplier_Handler.OnAfterInsert(trigger.new);
		}
		if (trigger.isUpdate) {
			Trg_Org_Supplier_Handler.OnAfterUpdate(trigger.new, trigger.OldMap);
		}
	}
}