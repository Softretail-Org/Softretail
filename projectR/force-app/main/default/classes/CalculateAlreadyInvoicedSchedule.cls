/**
 * Calculate Already Invoiced Schedule
 * */
public with sharing class CalculateAlreadyInvoicedSchedule implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CalculateAlreadyInvoicedBatch('CalculateAlreadyInvoicedSchedule', null));
    }
    /**
     * @param expr: valid cron expression
     */
    public static void run(String expr) {
        String cronExpression = expr == null ? '0 30 23 * * ?' : expr;
        System.schedule('CalculateAlreadyInvoicedSchedule', cronExpression, new CalculateAlreadyInvoicedSchedule());
    }
}