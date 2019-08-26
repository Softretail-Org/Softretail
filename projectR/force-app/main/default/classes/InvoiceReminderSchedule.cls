/*
 * Schedule Class related to InvoiceReminderBatch
 */ 
global with sharing class InvoiceReminderSchedule implements Schedulable {
    Id country;
    
    global InvoiceReminderSchedule(Id c) {
        this.country = c;
    }
    
    global void execute(SchedulableContext sc) {
        Integer reminderLevel = 0, reminderValue = 0;
        String reminderDescription;
        List<Id> reminderBUIds = new List<Id>();
        NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        if(negoSettings.reminderLevel != null){
            reminderBUIds = negoSettings.reminderBUManagedList;
            if(negoSettings.reminderValue1 != null){
                reminderValue = negoSettings.reminderValue1;
                reminderDescription = negoSettings.reminderDescription1;
                Database.executeBatch(new InvoiceReminderBatch('InvoiceReminderSchedule', null, reminderBUIds, 1, reminderValue, reminderDescription));
            }
            if(negoSettings.reminderValue2 != null){
                reminderValue = negoSettings.reminderValue2;
                reminderDescription = negoSettings.reminderDescription2;
                Database.executeBatch(new InvoiceReminderBatch('InvoiceReminderSchedule', null, reminderBUIds, 2, reminderValue, reminderDescription));
            }
            if(negoSettings.reminderValue3 != null){
                reminderValue = negoSettings.reminderValue3;
                reminderDescription = negoSettings.reminderDescription3;
                Database.executeBatch(new InvoiceReminderBatch('InvoiceReminderSchedule', null, reminderBUIds, 3, reminderValue, reminderDescription));
            }
        }
        else{
            Database.executeBatch(new InvoiceReminderBatch('InvoiceReminderSchedule', null, reminderBUIds, 0, 0, null));            
        }
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
    	// 0 = Second,0 = Minute,0 = Hour,* = All days,* = All months,? = No specific value
        // '0 0 0 * * ?'
        String cronExpression = expr == null ? '0 30 23 * * ?' : expr;
        System.schedule('InvoiceReminderSchedule', cronExpression, new InvoiceReminderSchedule(null));
    }
}