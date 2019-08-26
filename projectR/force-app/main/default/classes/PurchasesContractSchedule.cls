/**
 * Purchases Contract Schedule
 * */
global with sharing class PurchasesContractSchedule implements Schedulable {
	
    Id country;
	Integer year;
	
    global PurchasesContractSchedule(Id c, Integer y) {
        this.country = c;
   		this.year = y;
    }
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new PurchasesContractBatch('PurchasesContractSchedule', country, year));
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
        String cronExpression = expr == null ? '0 30 21 * * ?' : expr;
        System.schedule('PurchasesContractSchedule', cronExpression, new PurchasesContractSchedule(null, null));
    }
}