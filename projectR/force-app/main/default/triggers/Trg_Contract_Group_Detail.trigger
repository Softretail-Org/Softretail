/**
* Change the Status of Contract Group Detail if the Line_Integration_Status is updated or deleted
* Change contract group status if condition status <> 'Synchronized'
**/
trigger Trg_Contract_Group_Detail on Contract_Group_Detail__c (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        for(Contract_Group_Detail__c item : Trigger.New) {
            // Update status contract group detail if update this fields
            if((((Trigger.isInsert || (Trigger.isUpdate && (item.Line_Integration_Status__c != Trigger.OldMap.get(item.Id).Line_Integration_Status__c))) &&
                (item.Line_Integration_Status__c == 'Updated' || item.Line_Integration_Status__c == 'Deleted'))||
               (Trigger.isUpdate && ((item.Percent__c != Trigger.OldMap.get(item.Id).Percent__c) || 
                                     (item.Amount__c != Trigger.OldMap.get(item.Id).Amount__c) ||
                                     (item.Disc_BDate__c != Trigger.OldMap.get(item.Id).Disc_BDate__c) ||
                                     (item.Disc_EDate__c != Trigger.OldMap.get(item.Id).Disc_EDate__c) ||
                                     (item.Comment__c != Trigger.OldMap.get(item.Id).Comment__c) ||
                                     (item.Order_Number__c != Trigger.OldMap.get(item.Id).Order_Number__c) ||
                                     (item.Rank__c != Trigger.OldMap.get(item.Id).Rank__c))))
               &&(item.Status__c != 'Updated' && item.Status__c != 'Validated')){
                   item.Status__c = 'Updated';
               }
        }
    }
    if (Trigger.isAfter) {
        
        // Update contract group status if condition status <> 'Synchronized'
        // Fill set of contract group
        Set<Id> contractGroupSet = new Set<Id>();
        for(Contract_Group_Detail__c item : Trigger.New) {
            if ((Trigger.isInsert ||
                 (Trigger.isUpdate && item.Status__c != Trigger.OldMap.get(item.Id).Status__c)) &&
                (item.Status__c != 'Synchronized' && item.Status__c != 'Synchronized as deleted' && item.Status__c != 'Deleted')) {
                    contractGroupSet.add(item.Contract_List_Group__c);
                }
        }
        // Get all contracts group filter by contract group ids
        List<Contract_Group__c> contractGroups = new List<Contract_Group__c>();
        for(Contract_Group__c item : [SELECT Id, Status__c
                                      FROM Contract_Group__c
                                      WHERE Id IN :contractGroupSet])
        {
            if(item.Status__c == 'Synchronized' || item.Status__c == 'Synchronized as deleted' || item.Status__c == 'Deleted') {
                item.Status__c = 'Updated';
                contractGroups.add(item);
            }
        }
        if(contractGroups.size() > 0) update contractGroups;        
    }
}