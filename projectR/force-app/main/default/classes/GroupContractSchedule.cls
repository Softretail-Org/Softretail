/**
 * Group Contract Scan Batch Schedule
 * */
global with sharing class GroupContractSchedule implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GroupContractScanBatch('GroupContractSchedule', true, null, null));
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
        String cronExpression = expr == null ? '0 30 21 * * ?' : expr;
        System.schedule('GroupContractSchedule', cronExpression, new GroupContractSchedule());
    }
}