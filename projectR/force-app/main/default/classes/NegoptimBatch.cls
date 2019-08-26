//TODO Add debug log
/**
 * @author ULiT
 * @date feb-27-2018
 * @group Negoptim Support
 * @description Initiate an instance of this class in a batch to ease logging and sending emails of the batch's summary. 
********************************************************************************************************************************************* */

public class NegoptimBatch {
    
    public final String BATCH_SUMMARY = 'Batch_Summary_Email_Template';
    public final String EMAIL_TEMPLATE_2 = 'Unavailable';
    public final String EMAIL_TEMPLATE_3 = 'Unavailable';
    public final String EMAIL_TEMPLATE_4 = 'Unavailable';
    
	/**
	 * @description The name of the batch where an instance of this class is initiated
	***************************************************************************************************************************************** */
    private String batchName;
    /**
     * @description identifies where the batch started from, it could be another batch or a scheduler or other
	***************************************************************************************************************************************** */
    private String startedFrom = 'Undefined';
    /**
     * @description A map that holds the batch index as key and a set of error strings as value.
     * It is used to keep track of error messages per batch
	***************************************************************************************************************************************** */
    private Map<Integer, Set<String>> errorByBatchIndex;
    /**
     * @description a map take batch index as key and set of message as value.
     ************************************************************************************/
      private List<String> messages;
    /**
     * @description 'Stateful' or 'Stateless'
	***************************************************************************************************************************************** */
    private BatchType bt;
    /**
     * @description The AsyncApexJob of the batch where an instance of this class is initiated
	***************************************************************************************************************************************** */
    private AsyncApexJob asyncApexJob;
    /**
     * @description A map to keep track of relevent information and input data helpful in debug. Example: the query
	***************************************************************************************************************************************** */
    private Map<String, Object> parameters;
    /**
     * @description The index of the current batch of the current apex job
	***************************************************************************************************************************************** */
    private Integer batchIndex = 0;
    /**
     * @description Used to keep track of the Log__c object to avoid inserting 2 logs for the same Job
	***************************************************************************************************************************************** */
	private Log__c log;
    /**
     * @param batchName The name of the batch where an instance of this class is being initiated
     * @param batchType The batch type of the batch where an instance of this class is being initiated (Stateful or Stateless)
     * @example NegoptimBatch negoptimBatch = new NegoptimBatch('Mass Distribution','Stateful');
	***************************************************************************************************************************************** */
    public NegoptimBatch(String batchName, BatchType batchType, String startedFrom) {
        this.batchName = batchName;
        this.bt = batchType;
        this.startedFrom = startedFrom;
        this.errorByBatchIndex = new Map<Integer, Set<String>>();
        this.messages = new List<String>();
        this.parameters = new Map<String, Object>();
    }
    
  	/**
     * @param results A list of Database.SaveResults
     * @param records A list of sObject representing updated or inserted records
     * @return void
     * @description logs the failed results of an insert or update DML method
	***************************************************************************************************************************************** */
    public void logResults(List<Database.SaveResult> results, List<sObject> records) {
        
        for (sObject record : records) {
            Database.SaveResult result = results[records.indexOf(record)]; 
            if (!result.isSuccess()) {
                String errorMessage;
                if (record.Id != null) {
                    errorMessage = record.get('Name') + '(' + record.Id + ') : ';
                } else {
                    errorMessage = String.valueOf(record);
                }
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs) {
                    errorMessage += err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '<br/>';
                }
                logError(errorMessage);
            }
        }
    }
    
    /**
     * @param results A list of Database.UndeleteResult
     * @param records A list of sObject representing updated or inserted records
     * @return void
     * @description logs the failed results of an undelete DML method
	***************************************************************************************************************************************** */
    public void logResults(List<Database.UndeleteResult> results, List<sObject> records) {
        
        for (sObject record : records) {
            Database.UndeleteResult result = results[records.indexOf(record)];
            if (!result.isSuccess()) {
                String errorMessage = record.get('Name') + '(' + record.Id + ') : ';
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs){
                    errorMessage += err.getStatusCode() + ' - ' + err.getMessage() + '<br/>';
                }
                logError(errorMessage);
            }
        }
    }
    
    /**
     * @param results A list of Database.UpsertResult
     * @param records A list of sObject representing updated or inserted records
     * @return void
     * @description logs the failed results of an upsert DML method
	***************************************************************************************************************************************** */
    public void logResults(List<Database.UpsertResult> results, List<sObject> records) {
        
        for (sObject record : records) {
            Database.UpsertResult result = results[records.indexOf(record)];
            if (!result.isSuccess()) {
                String errorMessage;
                if (record.Id != null) {
                    errorMessage = record.get('Name') + '(' + record.Id + ') : ';
                } else {
                    errorMessage = String.valueOf(record);
                }
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs) {
                    errorMessage += err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '<br/>';
                }
                logError(errorMessage);
            }
        }
    }
    /**
     * @return void
     * @description increments the batch count.
     * It is CRITICAL to call this method at the end of a batch execute method
	***************************************************************************************************************************************** */
    public void incrementBatchIndex() {
        batchIndex++;
    }
    
    /**
     * @param error String representing an error message
     * @return void
     * @description Add the error message passed as parameter to the set of errors of the current batch
	***************************************************************************************************************************************** */
    public void logError(String error) {
        if (errorByBatchIndex.containsKey(batchIndex)) {
            errorByBatchIndex.get(batchIndex).add(error);
        } else {
            errorByBatchIndex.put(batchIndex, new Set<string> {error});
        }
    }
    /**
     * method that return string represent the message of current batch
     */
     public void logMessage(String message) {
            messages.add(message);
    }
    /**
     * @param error String representing an Exception message
     * @return void
     * @description Add the Exception message passed as parameter to the set of Exceptions
	***************************************************************************************************************************************** */
    public void logError(Exception ex) {
        if(ex instanceof DmlException) {
            logError('<span style="color: red;">Exception: Line: ' + ex.getLineNumber() + ' - ' + ex.getDmlMessage(0)+'</span>');
        }
        else {
            logError('<span style="color: red;">Exception: Line: ' + ex.getLineNumber() + ' - ' + ex.getMessage()+'</span>');
        }
    }
    
    /**
     * @param parameterName
     * @param value
     * @return void
     * @description adds a new parameter to the map of parameters to be logged
	***************************************************************************************************************************************** */
    public void logParameter(String parameterName, Object value) {
        this.parameters.put(parameterName, value);
    }
    
    /**
     * @param bc Database.BatchableContext
     * @return void
     * @description inserts a new log to the database by using NegoptimLog.saveApexBatchLog
     * This method is called in the finish method of the batch where an instance of this class is being initiated
	***************************************************************************************************************************************** */
    public Log__c saveLog(Database.BatchableContext bc) {
        this.asyncApexJob = getAsyncApexJob(bc);
 
        if (this.bt == NegoptimBatch.BatchType.Stateless) {
            List<Log__c> logList = [SELECT NumberOfWarnings__c, TraceLog__c
                                    FROM Log__c
                                    WHERE Apex_Job_ID__c = :this.asyncApexJob.Id];
            if (!logList.isEmpty()) {
                this.log = logList[0];
            }
        }
        this.log = NegoptimLog.mapToLog(this);
        try {
            // check security on upsert Log__c
            String[] logFields = new String[] { NegoptimHelper.normalizeAPIName('Apex_Job_ID__c'), NegoptimHelper.normalizeAPIName('Class_Name__c'),
                NegoptimHelper.normalizeAPIName('Started_From__c'), NegoptimHelper.normalizeAPIName('JobItemsProcessed__c'), NegoptimHelper.normalizeAPIName('CompletedDate__c'),
                NegoptimHelper.normalizeAPIName('NumberOfErrors__c'), NegoptimHelper.normalizeAPIName('JobType__c'), NegoptimHelper.normalizeAPIName('MethodName__c'),
                NegoptimHelper.normalizeAPIName('NumberOfWarnings__c'), NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Submitted_Date__c'),
                NegoptimHelper.normalizeAPIName('TotalJobItems__c'), NegoptimHelper.normalizeAPIName('status_detail__c'), NegoptimHelper.normalizeAPIName('TraceLog__c')};

            if(NegoptimHelper.checkCreatibility(Log__c.SObjectType, logFields) &&
               NegoptimHelper.checkUpdatibility(Log__c.SObjectType, logFields))
                {
                    Database.UpsertResult result = Database.upsert(log, false);
                }
        } catch (DMLException ex) { }
        return this.log;
    }
    
    /**
     * @param bc Passed from the finish method of the batch where an instance of this class was initiated
     * @param templateUniqueName the unique name of the email template to be used. The developer can use the predefined template names. (see class properties)
     * @return void
     * @description Uses the provided email template to send an email of the Batch Process.
     * if the name of the template passed as parameter is invalid, an email with be send with the body as
     * the batch's trace log as body and the batch name followed by 'Batch Summary' as subject.
    ***************************************************************************************************************************************** */ 
    public void sendEmail(Database.BatchableContext bc, String templateUniqueName) {
        saveLog(bc);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSenderDisplayName('Negoptim By ULiT');
        mail.setReplyTo('no-reply@negoptim.com');
        mail.setToAddresses(new String[] {UserInfo.getUserId()});
        try {
            Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateUniqueName].Id; //TODO: Make field in NegoptimHelper  
            mail.setTargetObjectId(this.getFakeContactId());
            mail.setTemplateId(emailTemplateId);
            mail.setWhatId(log.Id);
            mail.setSaveAsActivity(false);
        } catch (Exception ex) {
            mail.setSubject(this.BatchName + ' Batch Summary');
            mail.setHtmlBody(this.generateTraceLog());
        }
        sendEmail(mail);
    }
    
    /**
     * @param bc Passed from the finish method of the batch where an instance of this class was initiated
     * @param customHtmlBody The body of the email in HTML markup. If null it will be subtituted with the trace log of the batch where an instance of this class was initiated
     * @param customSubject The subject of the email. If null it will be substituted with the name of the batch followed by 'Batch Summary'
     * @return void
     * @description Use this method to send a custom email of the batch results in the finish method.
     * This method saves a log in the database, therefor there is no need to call saveLog().
	***************************************************************************************************************************************** */
    public void sendEmail(Database.BatchableContext bc, String customHtmlBody, String customSubject) {
        saveLog(bc);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSenderDisplayName('NegOptim by ULiT');
        mail.setReplyTo('no-reply@negoptim.com');
        mail.setToAddresses(new String[] {UserInfo.getUserId()});
        if (customHtmlBody == null) {
            customHtmlBody = this.generateTraceLog();
        }
        if (customSubject == null) {
            customSubject = this.batchName + ' Batch Summary';
        }
        mail.setHtmlBody(customHtmlBody);
        mail.setSubject(customSubject);
        sendEmail(mail);
    }
    
    public void sendMessages(Database.BatchableContext bc) {
        String subject = this.batchName + ' Messages';
        sendEmail(bc, this.getMessageTraceLog(), subject);
    }
    
    private void sendEmail(Messaging.SingleEmailMessage mail) {
        Integer used = Limits.getEmailInvocations();
        Integer emailLimit = Limits.getLimitEmailInvocations();
        if(used >= emailLimit) {
        } else {
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            } catch(System.EmailException ex) { }
        }
    }
    /**
     * @return an HTML String of the batch's trace log
     * @description generates an HTML markup of the batch information and status including error messages
	***************************************************************************************************************************************** */
    public String generateTraceLog() {
        String traceLog = generateTraceLogHeader();//updateHeaderTraceLog(getHeaderTraceLog(), getNumberOfErrors());
        traceLog += getWarningTraceLog();
        traceLog += getMessageTraceLog();
        return traceLog;
    }
    
    /**
     * @return trace log header
     * @description generate log header
	***************************************************************************************************************************************** */
    public String generateTraceLogHeader() {
        String LineSeparator = '<hr/>';
        String newLine = '<br/>';
        String traceLog = lineSeparator;
        traceLog += '<b>Batch Name: </b>' + batchName + newLine;
        traceLog += '<b>Started From: </b>' + startedFrom + newLine;
        traceLog += '<b>Source: </b>' + UserInfo.getOrganizationName() + newLine;
        traceLog += '<b>Result: </b>';
        //display results in colors depending on the job status
        traceLog += '<span style="font-weight: bold;color: ';        
        if(this.asyncApexJob.NumberOfErrors == 0 && this.getNumberOfErrors() == 0) {
            traceLog += 'green;">Successful';
        } else if(this.asyncApexJob.NumberOfErrors > 0) {
            traceLog += 'red;">Failed';
        } else if(this.getNumberOfErrors() > 0) {
            traceLog += 'orange;">Warning';
        }
        traceLog += '</span>';
        traceLog += lineSeparator;        
        //Insert Parameters
        if(parameters != null && !parameters.isEmpty()) {
            traceLog += '<u>Log Summary</u>' + newLine;
            traceLog += '<ul>';
            for(String key : parameters.keySet()) {
            	String param = '';
            	if(parameters.get(key) != null)
            		param = String.valueOf(parameters.get(key)).escapeHtml4();
                traceLog += '<li>' + '<b>' + key + '</b>' +  ': ' +  param  + '</li>';
            }
            traceLog += '</ul>';
            traceLog += lineSeparator;
        }
        //Log details and warning messages
        traceLog += '<u>Trace Log</u>' + newLine;
        traceLog += 'The batch Apex job processed ' + asyncApexJob.TotalJobItems + ' batches with '+ asyncApexJob.NumberOfErrors + ' failures.' + newLine;
        if (!String.isEmpty(this.asyncApexJob.ExtendedStatus)) {
            traceLog += '<div style="color: red;"><b>Failure Details: ' + this.asyncApexJob.ExtendedStatus + '</b></div>';
        }
        traceLog += 'Warning Messages (' + getNumberOfErrors() + ' messages)' + newLine;
        
        return traceLog;
    }
    
    /**
     * @return an HTML String of the STATLESS batch's trace log
     * @description generates an HTML markup of the Statless batch error messages
	***************************************************************************************************************************************** */
    public String getWarningTraceLog() {
        String LineSeparator = '<hr/>';
        String newLine = '<br/>';
        String traceLog = '';
        for(Integer key : errorByBatchIndex.keySet()) {

            Set<String> errors = errorByBatchIndex.get(key);            
            if(!errors.isEmpty()) {
                traceLog += '<u>' + 'Batch ' + key + '</u>' + newLine;
                
                traceLog += 'Warning messages:' + newLine;
                traceLog += '<ol>';
                
                for(String warning : errors) {
                    traceLog += '<li>' + warning + '</li>';
                }
                traceLog += '</ol>';
                traceLog += LineSeparator;
            }
        }
        return traceLog;
    }
    /**
     * get the trace log of message.
     *****/
    public String getMessageTraceLog() {
        String LineSeparator = '<hr/>';
        String newLine = '<br/>';
        String traceLog = '<b>Batch Messages</b>' + newLine;
        try {
            traceLog += String.join(messages, newLine);
            traceLog += LineSeparator;
        } catch (StringException ex) { }
        return traceLog;
    }
    
     /**
     * @return a count of all Errors
     * @description loop over error map and calculate the number of errors
	***************************************************************************************************************************************** */
    public Integer getNumberOfErrors() {
        Integer count = 0;
    	if(errorByBatchIndex == null || errorByBatchIndex.isEmpty()) {
    		return count;
    	}
    	
    	for(Integer key : errorByBatchIndex.keySet()) {
    		if(errorByBatchIndex.get(key) != null){
    			count += errorByBatchIndex.get(key).size();
    		}
    	}
    	return count;
    }
    /**
    * @description get number of messages
	*/
    public Integer getNumberOfMessages() {
        return messages == null ? 0 : messages.size();
    }
    
    public String getBatchName() {
    	return this.batchName;
    }
    
    public AsyncApexJob getAsyncApexJob() {
        return this.asyncApexJob;
    }
    //Make sure that the profile running the batch has access to AsyncApexJob
    public AsyncApexJob getAsyncApexJob(Database.BatchableContext bc) {
        String[] fields = new String[] {'Status', 'NumberOfErrors', 'TotalJobItems', 'JobItemsProcessed',
            'CompletedDate', 'MethodName', 'CreatedBy.name', 'CreatedDate', 'ExtendedStatus'};
		//	if (NegoptimHelper.checkAccessibility(Schema.getGlobalDescribe().get('AsyncApexJob'), fields)) {
				if (this.asyncApexJob == null) {
					this.asyncApexJob = [SELECT Status, NumberOfErrors, TotalJobItems, JobItemsProcessed,
										 CompletedDate, MethodName,	CreatedBy.name, CreatedDate, ExtendedStatus
										 FROM AsyncApexJob WHERE Id = :bc.getJobId()];
				}
				return this.asyncApexJob;
		/*	} else {
				return null;
			}*/
    }
    
    public integer getErrorNumberByBatchIndex() {
        if (this.errorByBatchIndex.containsKey(batchIndex)) {
            return this.errorByBatchIndex.get(batchIndex).size();
        } else {
            return 0;
        }
    }
    
    public String getStartedFrom() {
        return this.startedFrom;
    }
    
    public Log__c getLog() {
        return log;
    }
    
    public NegoptimBatch.BatchType getBatchType() {
        return this.bt;
    }
    
    private Id getFakeContactId() {//TODO: move to NegoptimHelper
        Contact fakeContact;
        id contactId;
        String fakeContactName = '**DONT DELETE**';
        try {
            fakeContact = [SELECT Id FROM Contact WHERE Name = :fakeContactName];
            contactId = fakeContact.Id;
            fakeContact.Email = UserInfo.getUserEmail();
        } catch (Exception ex) {
            fakeContact = new Contact(FirstName='**DONT', LastName='DELETE**', Email=UserInfo.getUserEmail());
            contactId = fakeContact.Id;
        }
        // check security on Contact
        String[] contactFields = new String[] {NegoptimHelper.normalizeAPIName('FirstName'), NegoptimHelper.normalizeAPIName('LastName'), NegoptimHelper.normalizeAPIName('Email')};
        if(NegoptimHelper.checkCreatibility(Contact.SObjectType, contactFields) && NegoptimHelper.checkUpdatibility(Contact.SObjectType, contactFields)) {
            upsert fakeContact;
        }
        return fakeContact.Id;
    }   
    
    public enum BatchType {
        Stateless,
        Stateful
    }
}