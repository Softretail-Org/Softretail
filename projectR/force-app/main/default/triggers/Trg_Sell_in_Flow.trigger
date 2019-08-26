/**
 * Attach contract to sell in flow on before insert/update
 * Update product and PG last peice on before insert/update
 * */
trigger Trg_Sell_in_Flow on Sell_in_Flow__c (before insert, before update, after insert, after update) {
    if(trigger.isBefore){
        if (trigger.isInsert || trigger.isUpdate){
            if(!system.isBatch()) {
                Trg_Sell_in_Flow_Handler.reparentingSellin(trigger.new, trigger.OldMap, null, null, null, null, null, null, null, false);
            }
        }
    }
    if(Trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
            Trg_Sell_in_Flow_Handler.OnAfterInsertOrUpdate(trigger.new, trigger.OldMap);
        }
    }
}