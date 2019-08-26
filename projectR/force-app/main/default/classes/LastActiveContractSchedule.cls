/**
 * Last Active Contract Schedule
 */ 
global with sharing class LastActiveContractSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        ID BatchId = Database.executeBatch(new LastActiveContractBatch('LastActiveContractSchedule', null, null));
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
        String cronExpression = expr == null ? '0 30 21 * * ?' : expr;
        System.schedule('LastActiveContractSchedule', cronExpression, new LastActiveContractSchedule());
    }
}