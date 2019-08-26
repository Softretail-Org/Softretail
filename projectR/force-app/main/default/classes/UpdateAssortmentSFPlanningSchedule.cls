/**
 * @author ULiT
 * @date 7-5-2018
 * @description executes UpdateAssortmentSFPlanningBatch on a daily basis at 12 am
 * */
global class UpdateAssortmentSFPlanningSchedule implements Schedulable {
	
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateAssortmentSFPlanningBatch('UpdateAssortmentSFPlanningSchedule', null));
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
        String cronExpression = expr == null ? '0 0 0 ? * *' : expr;
        System.schedule('UpdateAssortmentSFPlanningSchedule', cronExpression, new UpdateAssortmentSFPlanningSchedule());
    }
}