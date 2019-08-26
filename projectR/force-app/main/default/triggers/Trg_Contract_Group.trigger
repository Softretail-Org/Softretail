/**
* Change owner Id of Contract Group and replaced by owner NegoScope Id
* Change the Status of Contract Group if the Header_Integration_Status is updated or deleted
* TODO Handler
**/
trigger Trg_Contract_Group on Contract_Group__c (before insert, before update, after update) {
    
    if (Trigger.isBefore) {
        if(Trigger.isInsert){
            for(Contract_Group__c item : Trigger.New) {
                if((item.Header_Integration_Status__c != null &&  (item.Header_Integration_Status__c == 'Updated' || item.Header_Integration_Status__c == 'Deleted'))
                   && item.Status__c != 'Updated'){
                       item.Status__c = 'Updated';
                   }
            }
        }
        if (Trigger.isUpdate) {
            Set<Id> negoScopeSet = new Set<Id>();
            Map<Id, Sup_sup_NegoScope__c> negoScopeMap = new Map<Id, Sup_sup_NegoScope__c>();
            for(Contract_Group__c item : Trigger.New) {
                if(item.Supplier_NegoScope__c != null && item.Supplier_NegoScope__c != Trigger.OldMap.get(item.Id).Supplier_NegoScope__c){
                    negoScopeSet.add(item.Supplier_NegoScope__c);
                }
            }
            if(negoScopeSet.size() > 0){
                negoScopeMap = new Map<Id, Sup_sup_NegoScope__c>([SELECT Id, OwnerId FROM Sup_sup_NegoScope__c WHERE Id IN :negoScopeSet]);
            }
            for(Contract_Group__c item : Trigger.New) {
                // Update status contract group if update this fields
                if(((item.Header_Integration_Status__c != Trigger.OldMap.get(item.Id).Header_Integration_Status__c && 
                     (item.Header_Integration_Status__c == 'Updated' || item.Header_Integration_Status__c == 'Deleted')) ||
                    (item.Contract_type__c != Trigger.OldMap.get(item.Id).Contract_type__c) || 
                    (item.Contract_Number__c != Trigger.OldMap.get(item.Id).Contract_Number__c) ||
                    (item.Contract_Name_duplicated__c != Trigger.OldMap.get(item.Id).Contract_Name_duplicated__c) ||
                    (item.Comment__c != Trigger.OldMap.get(item.Id).Comment__c) ||
                    (item.Start_Date__c != Trigger.OldMap.get(item.Id).Start_Date__c) ||
                    (item.End_date__c != Trigger.OldMap.get(item.Id).End_date__c) ||
                    (item.Negotiated_TO__c != Trigger.OldMap.get(item.Id).Negotiated_TO__c))
                   &&(item.Status__c != 'Updated' && item.Status__c != 'Validated')){
                       item.Status__c = 'Updated';
                   }
                if(negoScopeMap.containsKey(item.Supplier_NegoScope__c) && negoScopeMap.get(item.Supplier_NegoScope__c).OwnerId != item.OwnerId){
                    item.OwnerId = negoScopeMap.get(item.Supplier_NegoScope__c).OwnerId;
                }
            }
        }
    }
    if (Trigger.isAfter) {        
        // Delete all conditions related to contract deleted
        // Update Start/End date conditions if Start/End contract group is updated
        if (Trigger.isUpdate) {
            // Fill map of contract group
            Map<Id, Contract_Group__c> contractGroupMap = new Map<Id, Contract_Group__c>();
            for(Contract_Group__c item : Trigger.New) {
                if ((item.Status__c != Trigger.OldMap.get(item.Id).Status__c && item.Status__c == 'Deleted') ||
                    item.Start_Date__c != Trigger.OldMap.get(item.Id).Start_Date__c ||
                    item.End_date__c != Trigger.OldMap.get(item.Id).End_date__c) {
                        contractGroupMap.put(item.Id, item);
                    }
            }
            // Get all conditions filter by contract group ids
            if(contractGroupMap.size() > 0){
                List<Contract_Group_Detail__c> conditions = new List<Contract_Group_Detail__c>();
                Boolean conditionIsUpdated;
                for(Contract_Group_Detail__c item : [SELECT Id, Name, Contract_List_Group__c,
                                                     Disc_BDate__c, Disc_EDate__c, Status__c
                                                     FROM Contract_Group_Detail__c
                                                     WHERE Contract_List_Group__c IN :contractGroupMap.keySet()])
                {
                    Contract_Group__c contractGroup = contractGroupMap.get(item.Contract_List_Group__c);
                    conditionIsUpdated = false;
                    if(contractGroup.Status__c != Trigger.OldMap.get(contractGroup.Id).Status__c && contractGroup.Status__c == 'Deleted'){
                        item.Status__c = 'Deleted';
                        conditionIsUpdated = true;
                    }
                    if(contractGroup.Start_Date__c != Trigger.OldMap.get(contractGroup.Id).Start_Date__c){
                        item.Disc_BDate__c = contractGroup.Start_Date__c;
                        conditionIsUpdated = true;
                    }
                    if(contractGroup.End_date__c != Trigger.OldMap.get(contractGroup.Id).End_date__c){
                        item.Disc_EDate__c = contractGroup.End_date__c;
                        conditionIsUpdated = true;
                    }
                    if(conditionIsUpdated == true){
                        conditions.add(item);
                    }
                }
                if(conditions.size() > 0) update conditions;
            }
        }
    }
}