/**
 * WDConsolidationSchedule
 * @author ULiT
 * */
global class WDConsolidationSchedule implements Schedulable {
	
    global void execute(SchedulableContext sc) {
        Map<String, Object> myMap = new Map<String, Object>();
        Flow.Interview.Consolidate_WD consolidateWDFlow = new Flow.Interview.Consolidate_WD(myMap);
        consolidateWDFlow.start();
    }
    /**
     * @param expr: valid cron expression
     */
    global static void run(String expr) {
        String cronExpression = expr == null ? '0 0 0 1 1 ?' : expr;
        System.schedule('WDConsolidationSchedule', cronExpression, new WDConsolidationSchedule());
    }
}