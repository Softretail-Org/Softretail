/*
* 1- Create to do list with task duration
* 2- Generate the list of all the tasks of the event in retroplanning according to the start date of the event
* Task of the event = new campaign event with the event for parent and record type = task
* 3- Execute PromoConditionSynchroBatch for generate conditions and dispatch details if status=Validated
**/
trigger Trg_Commercial_Plan on Commercial_Plan__c (before insert, after insert, after update) {
    if(Trigger.isBefore) {
        if (Trigger.isInsert) {
            for (Commercial_Plan__c item : Trigger.new) {
                item.Status__c = 'In preparation';
            }
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            
            Map<String, Id> eventRecordTypeByNameMap = NegoptimHelper.getObjectRecordTypeMapIds(Commercial_Plan__c.SObjectType);
            List<Id> recordTypes = new List<Id>();
            recordTypes.add(eventRecordTypeByNameMap.get('TODO_inRFP'));
            recordTypes.add(eventRecordTypeByNameMap.get('Todo'));
            //construct a map of parentPlanId -> List<ChildCommercialPlan>
            Map<Id, List<Commercial_Plan__c>> ChildCommercialPlansMap = new Map<Id, List<Commercial_Plan__c>>();
            
            if (Trigger.isUpdate) {
                // delete any existing child commercial plans if the updated plan has a new Task_List_Reference or the existing 
                // Task_List_Reference has been removed
                List<Id> toDeleteList = new List<Id>();
                for (Commercial_Plan__c parentPlan : Trigger.new) {
                    if (Trigger.oldMap.get(parentPlan.Id).Task_List_Reference__c != parentPlan.Task_List_Reference__c) {
                        toDeleteList.add(parentPlan.Id);
                    }
                }
                if(!toDeleteList.isEmpty()) {
                    try {
                        delete [SELECT Id FROM Commercial_Plan__c WHERE Commercial_Animation_Plan_Parent__c IN :toDeleteList AND RecordTypeId IN :recordTypes];
                    } catch (DMLException ex) {
                    }
                }
                //load a map of ParentCommercialPlan.Id -> List<ChildCommercialPlans>
                for (Commercial_Plan__c commercialPlan : [SELECT Name, Commercial_Animation_Plan_Parent__c, Start_Date__c, End_Date__c
                                                          FROM Commercial_Plan__c
                                                          WHERE Commercial_Animation_Plan_Parent__c IN :Trigger.new
                                                          AND RecordTypeId IN :recordTypes])
                {
                    if (ChildCommercialPlansMap.containsKey(commercialPlan.Commercial_Animation_Plan_Parent__c)) {
                        ChildCommercialPlansMap.get(commercialPlan.Commercial_Animation_Plan_Parent__c).add(commercialPlan);
                    } else {
                        ChildCommercialPlansMap.put(commercialPlan.Commercial_Animation_Plan_Parent__c, new List<Commercial_Plan__c>{commercialPlan});
                    }
                }
                //update comercial plan dates for child Commercial plans when the date is changed for parent commercial plan
                List<Commercial_Plan__c> toUpdateList = new List<Commercial_Plan__c>();
                for (Id parentId : ChildCommercialPlansMap.keySet()) {
                    Integer delta = Trigger.oldMap.get(parentId).Start_Date__c.daysBetween(Trigger.newMap.get(parentId).Start_Date__c);
                    if (delta != 0) {
                        for (Commercial_Plan__c childPlan : ChildCommercialPlansMap.get(parentId)) {
                            childPlan.Start_Date__c = childPlan.Start_Date__c.addDays(delta);
                            childPlan.End_Date__c = childPlan.End_Date__c.addDays(delta);                            
                            toUpdateList.add(childPlan);
                        }
                    }
                }
                if(!toUpdateList.isEmpty()) {
                    try {
                        update toUpdateList;
                    } catch (Exception ex) {
                    }
                }
                
                List<Id> commercialPlanIds = new List<Id>();
                for(Commercial_Plan__c item : Trigger.new) {
                    if((item.Status__c == 'Validated' || item.Status__c == 'Validate with fact data') && (item.Status__c != Trigger.OldMap.get(item.Id).Status__c)){
                        commercialPlanIds.add(item.Id);
                    }
                }
                // Call PromoConditionSynchroBatch for generate conditions and dispatch details
                if(!System.isBatch() && commercialPlanIds.size() > 0){
                    Database.executeBatch(new PromoConditionSynchroBatch('Trg_Commercial_Plan', commercialPlanIds));
                }
            }
            
            Set<Id> taskSet = new Set<Id>();
            Map<Id, List<Commercial_Plan_Task_List__c>> taskListMap = new Map<Id, List<Commercial_Plan_Task_List__c>>();
            Map<Id, String> eventRecordTypeByIdMap = NegoptimHelper.getObjectRecordTypeMapDeveloperNames(Commercial_Plan__c.SObjectType);
            for(Commercial_Plan__c item : Trigger.new) {
                String recordTypeName = eventRecordTypeByIdMap.get(Item.RecordTypeId);
                if(item.Task_List_Reference__c != null && recordTypeName != 'Todo' && recordTypeName != 'TODO_inRFP') {
                    taskSet.add(item.Task_List_Reference__c);
                }
            }
            if(!taskSet.isEmpty()) {
                // get task list
                for(Commercial_Plan_Task_List__c item : [SELECT Id, Name, Commercial_Plan_Task__c, Step__c, Duration_nb_day__c, Is_Supplier_RFP_step__c
                                                         FROM Commercial_Plan_Task_List__c
                                                         WHERE Commercial_Plan_Task__c IN :taskSet
                                                         ORDER BY Step__c DESC])
                {
                    if(taskListMap.containsKey(item.Commercial_Plan_Task__c)) {
                        taskListMap.get(item.Commercial_Plan_Task__c).add(item);
                    }
                    else {
                        taskListMap.put(item.Commercial_Plan_Task__c, new List<Commercial_Plan_Task_List__c> { item });
                    }
                }
                // add new event with record type = 'Task'
                // loop over existing commercial plans to avoid creating 2 events for the same task item
                List<Commercial_Plan__c> events = new List<Commercial_Plan__c>();
                for(Commercial_Plan__c item : Trigger.new) {
                    Date startDate = item.Start_Date__c;
                    String recordTypeName = eventRecordTypeByIdMap.get(Item.RecordTypeId);
                    if(item.Task_List_Reference__c != null && recordTypeName != 'Todo' && recordTypeName != 'TODO_inRFP') {
                        if (taskListMap.get(item.Task_List_Reference__c) != null) {
                            for(Commercial_Plan_Task_List__c taskLine : taskListMap.get(item.Task_List_Reference__c)) {
                                if(taskLine.Duration_nb_day__c == null) continue;
                                if (ChildCommercialPlansMap.get(item.Id) != null) {
                                    //check if the difference between the start date and end date of a commercial plan is equal to the duration of the task item
                                    //to skip creating a new event
                                    Boolean flag = false;
                                    for (Commercial_Plan__c cp : ChildCommercialPlansMap.get(item.Id)) {
                                        if (cp.Start_Date__c.daysBetween(cp.End_Date__c) == taskLine.Duration_nb_day__c) {
                                            flag = true;
                                            break;
                                        }
                                    }
                                    if (flag) continue;
                                }
                                Commercial_Plan__c newEvent = new Commercial_Plan__c(Name = item.Name + '-' + taskLine.Step__c,
                                                                                     Commercial_Animation_Plan_Parent__c = item.Id,                                                                                 
                                                                                     Task_List_Reference__c = null, Supplier__c = item.Supplier__c,
                                                                                     BU_Target__c = item.BU_Target__c, Condition_Code__c = item.Condition_Code__c);
                                newEvent.Start_Date__c = startDate != null && taskLine.Duration_nb_day__c != null ? startDate.addDays(-Integer.valueOf(taskLine.Duration_nb_day__c)) : null;
                                newEvent.End_Date__c = newEvent.Start_Date__c != null && taskLine.Duration_nb_day__c != null ? newEvent.Start_Date__c.addDays(Integer.valueOf(taskLine.Duration_nb_day__c)) : null;
                                startDate = startDate != null && taskLine.Duration_nb_day__c != null ? startDate.addDays(-Integer.valueOf(taskLine.Duration_nb_day__c)) : null;
                                if(taskLine.Is_Supplier_RFP_step__c == true) {
                                    newEvent.RecordTypeId = eventRecordTypeByNameMap.get('TODO_inRFP');
                                }
                                else {
                                    newEvent.RecordTypeId = eventRecordTypeByNameMap.get('Todo');
                                }
                                events.add(newEvent);
                            }
                        }
                    }
                }
                if(!events.isEmpty())
                    insert events;
            }
        }
    }
}