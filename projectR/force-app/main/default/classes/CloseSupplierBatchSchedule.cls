/**
 * Schedule Class related to CloseSupplierBatch
 * */
global with sharing class CloseSupplierBatchSchedule implements Schedulable {
    
    Id country;
    
    // constructor1 - used from Administration screen of Scheduled Jobs
    global CloseSupplierBatchSchedule() {
        this.country = null;
    }
    // constructor2 - can be used from Apex code
    // ex:
	// System.schedule('Close Supplier Batch', '0 10 10 1/1 * ? *', new CloseSupplierBatchSchedule(null));
    global CloseSupplierBatchSchedule(Id c) {
        this.country = c;
    }
    // execute
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new CloseSupplierBatch('CloseSupplierBatchSchedule', country));
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
        String cronExpression = expr == null ? '0 30 21 * * ?' : expr;
        System.schedule('CloseSupplierBatchSchedule', cronExpression, new CloseSupplierBatchSchedule());
    } 
}