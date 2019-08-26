/**
 * Schedule class to run CommercialPlanScanBatch
 **/
global with sharing class CommercialPlanScanSchedule implements Schedulable {
    // Start Execute
    global void execute(SchedulableContext sc) {
        ID BatchId = Database.executeBatch(new CommercialPlanScanBatch('CommercialPlanScanSchedule', null, null, null, true, true));
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
        String cronExpression = expr == null ? '0 30 21 * * ?' : expr;
        System.schedule('CommercialPlanScanSchedule', cronExpression, new CommercialPlanScanSchedule());
    }
}