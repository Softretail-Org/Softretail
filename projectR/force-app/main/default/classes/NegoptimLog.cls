/**
 * The aim of NegoptimLog is to save all Controllers/Batches/ Log Result in the database
 * */
public class NegoptimLog {
    
    // Convert NegoptimBatch format to NegoptimLog Format
    public static Log__c mapToLog(NegoptimBatch nb) {
        Integer maxSize = 131072;
        Boolean stateless = nb.getBatchType() == NegoptimBatch.BatchType.Stateless;
        // return the log if exist for stateful batches
        if (!stateless && nb.getLog() != null && nb.getLog().Id != null) {
            return nb.getLog();
        }
        
        String asyncJobStatus = nb.getAsyncApexJob().Status;
        Boolean isFinish = (asyncJobStatus.equals('Completed') ||asyncJobStatus.equals('Failed') || asyncJobStatus.equals('Aborted'));
         Log__c log;
        if (stateless) {
            if (nb.getLog() != null && nb.getLog().Id != null) {
                log = nb.getLog().clone(true);
            }
        }
        if(log == null) {
            log = new Log__c();
        }
        log.Apex_Job_ID__c = nb.getAsyncApexJob().Id;
        log.Class_Name__c = nb.getBatchName();
        log.Started_From__c = nb.getStartedFrom();
        log.JobItemsProcessed__c = nb.getAsyncApexJob().JobItemsProcessed;
        log.CompletedDate__c = nb.getAsyncApexJob().CompletedDate;
        log.NumberOfErrors__c = nb.getAsyncApexJob().NumberOfErrors;
        log.JobType__c = NegoApexLogTypesEnum.BatchApex.name();
        log.MethodName__c = nb.getAsyncApexJob().MethodName;
        log.NumberOfWarnings__c = nb.getNumberOfErrors();
        log.Status__c = nb.getAsyncApexJob().Status;
        log.Submitted_Date__c = nb.getAsyncApexJob().CreatedDate;
        log.TotalJobItems__c = nb.getAsyncApexJob().TotalJobItems;
        log.status_detail__c = nb.getAsyncApexJob().extendedStatus;
        if (stateless) {
            String loggedWarnings = nb.getLog() != null ? nb.getLog().TraceLog__c : '';
            Integer loggedNumberOfWarnings = nb.getLog() != null ? Integer.valueOf(nb.getLog().NumberOfWarnings__c) : 0;
            log.TraceLog__c = loggedWarnings + nb.getWarningTraceLog();
            log.NumberOfWarnings__c = loggedNumberOfWarnings + nb.getNumberOfErrors();
            if (isFinish) {
                String str = nb.generateTraceLogHeader() + (log.TraceLog__c != 'null' ? log.TraceLog__c : '');
                if (str.length() > maxSize) {
                    str = str.substring(0, maxSize);
                }
                log.TraceLog__c = str;
                ////log.TraceLog__c = nb.generateTraceLogHeader() + log.TraceLog__c;
            }
        } else {
            String str = nb.generateTraceLog();
            if (str.length() > maxSize) {
                str = str.substring(0, maxSize);
            }
            log.TraceLog__c = str;
            ////log.TraceLog__c = nb.generateTraceLog();
        }
        return log;
    }
    
    public enum NegoApexLogTypesEnum {
        Future,
        SharingRecalculation,
        ScheduledApex,
        BatchApex,
        BatchApexWorker,
        TestRequest,
        TestWorker,
        ApexToken,
        Queueable
    }
}