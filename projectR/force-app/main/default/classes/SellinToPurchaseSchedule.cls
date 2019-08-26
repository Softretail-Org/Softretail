/**
 * Sell in To Purchase Schedule
 * */
public with sharing class SellinToPurchaseSchedule implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SellinToPurchaseBatch('Schedule', null , null, null, null, null, Date.Today().Year(), null));
    }
    /**
     * @param expr: valid cron expression
     */
    public static void run(String expr) {
        String cronExpression = expr == null ? '0 30 23 * * ?' : expr;
        System.schedule('SellinToPurchaseSchedule', cronExpression, new SellinToPurchaseSchedule());
    }
}