/**
 * @author ULiT
 * @description inserts an attachment for every Negoptim_Document__c record, by going thru the page NegoTemplatePreview
 * or NegoTemplatePreviewDocument
***************************************************************************************************************** */
public class GenerateAttachmentsBatch implements Database.Batchable<Id> {
    
    private NegoptimBatch nb;
    private List<Id> negoptimDocumentsId;
    private List<Id> recordsId;
    private String templateName;
    private String templateFormat;
    private NegoTemplate__c template;
    private Boolean sendEmails;
    private Map<Id, SObject> recordsMap;
    private List<Attachment> attachmentList = new List<Attachment>();
    private Map<Id, Negoptim_Document__c> negoptimDocumentsMap;
    
    public GenerateAttachmentsBatch( String startedFrom, List<Id> negoptimDocumentsId,
                                    List<Id> recordsId, Id templateId, Boolean emailWhenPrinting) 
    {
        nb = new NegoptimBatch('GenerateAttachmentsBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.negoptimDocumentsId = negoptimDocumentsId;
        this.recordsId = recordsId;
        this.template = [SELECT Name, Template_Format__c, ObjectType__c, Send_Email_When_Printing__c,
                         Document_Recipient__c, Email_Body__c, Email_Subject__c, Document_Recipient_Cc__c,
                         Sender_Display_Name__c
                         FROM NegoTemplate__c 
                         WHERE Id = :templateId];
        this.templateName = template.Name;
        this.templateFormat = template.Template_Format__c;
        this.negoptimDocumentsMap = new Map<Id, Negoptim_Document__c> ([SELECT Name, Parent_Record_Id__c FROM Negoptim_Document__c WHERE Id IN :negoptimDocumentsId]);
        this.sendEmails = this.template.Send_Email_When_Printing__c || emailWhenPrinting;
        if (String.isBlank(this.template.Document_Recipient__c) 
            || !NegoptimTemplatesHelper.isValidField(template.ObjectType__c, template.Document_Recipient__c.split('\\.'))) {
            this.sendEmails = false;
        }
        if (sendEmails) {
            //fetch email addresses
            String emailRecipientsQuery = 'SELECT ' +  template.Document_Recipient__c;
            emailRecipientsQuery += ' FROM ' + template.ObjectType__c;
            emailRecipientsQuery += ' WHERE Id IN (\'' + String.join(recordsId, '\',\'') + '\')';
            recordsMap = new Map<Id, SObject>(Database.query(emailRecipientsQuery));
            nb.logParameter('emailRecipientsQuery', emailRecipientsQuery);
        }
        nb.logParameter('negoptimDocumentsId size', this.negoptimDocumentsId.size());
        nb.logParameter('negoptimDocumentsId', this.negoptimDocumentsId);
        nb.logParameter('recordsId', this.recordsId);
        nb.logParameter('templateName', templateName);
    }
    
    public Iterable<Id> start(Database.BatchableContext bc) {
        return this.negoptimDocumentsId;
    }
    
    public void execute(Database.BatchableContext bc, List<Id> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            Messaging.SingleEmailMessage email;
            for (Id docId : scope) {
                String attachmentName = negoptimDocumentsMap.get(docId).Name;
                //generate Attachament record to insert
                PageReference pageRef;
                Attachment attach = new Attachment();
                attach.ParentId = negoptimDocumentsMap.get(docId).Parent_Record_Id__c; //// recordsId[scope.indexOf(docId)];
                if (this.templateFormat == null || this.templateFormat.equalsIgnoreCase('PDF')) {
                    pageRef = Page.NegoTemplatePreview;
                    attach.name  = attachmentName + '.pdf';
                    attach.ContentType = 'application/pdf';
                } else if (this.templateFormat.equalsIgnoreCase('Word Document')) {
                    pageRef = Page.NegoTemplatePreviewDoc;
                    attach.name  = attachmentName + '.doc';
                    attach.ContentType = 'application/msWord';
                } else continue;
                pageRef.getParameters().put('did', docId);
                Blob fileContent;
                if (Test.IsRunningTest()) {
                    fileContent = Blob.valueOf('UNIT.TEST');
                } else {
                    fileContent = pageRef.getContent();
                }
                attach.Body = fileContent;
                attachmentList.add(attach);
                /*if (this.sendEmails) {
                    //creating the email attachments
                    Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
                    email_att.setBody(attach.Body);
                    email_att.setContentType(attach.ContentType);
                    email_att.setFileName(attach.Name);
                    email_att.setinline(false);
                    //creating the single email
                    email = new Messaging.SingleEmailMessage();
                    ////email.setSenderDisplayName('NegOptim Templates');
                    //get the toAddress
                    SObject record = this.recordsMap.get(attach.ParentId);
                    List<String> currentFields = this.template.Document_Recipient__c.split('\\.');
                    if (currentFields[0] == this.template.ObjectType__c) 
                        currentFields.remove(0); // remove sobject name
                    
                    if (currentFields.size() > 1) {
                        for(Integer i = 0; i < currentFields.size(); i++) {
                            if(record != null) {
                                record = record.getSObject(currentFields.remove(0));
                            }
                        }
                    }
                    String toAddress = String.valueOf(record.get(currentFields[0]));
                    email.setToAddresses(new List<String> {toAddress});
                    ////email.setCcAddresses(ccList);
                    ////email.setBccAddresses(bccList);
                    email.setFileAttachments(new List<Messaging.EmailFileAttachment> {email_att});
                    email.setSubject(this.template.Email_Subject__c);
                    email.setHtmlBody(this.template.Email_Body__c);
                    emailList.add(email);
                }*/
            }
            
            // check security on insert attachment fields
            String[] attachmentCreateFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
            
            if (attachmentList != null && !attachmentList.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Attachment.SObjectType, attachmentCreateFields)) {
                    List<Database.SaveResult> results = Database.insert(attachmentList);
                    nb.logResults(results, attachmentList);
                }
            }
            //send the emails
            if (this.sendEmails) {
                List<Messaging.SingleEmailMessage> emailList = NegoptimTemplatesHelper.generateEmailList(this.recordsMap, attachmentList, this.template.Id);
                Messaging.sendEmail(emailList);
            }						
            
        } catch (NoAccessException e) {
            nb.logError('NoAccessException: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch(DmlException e) {
            nb.logError('DMLException: ' + e.getMessage() + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.saveLog(bc);
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.sendEmail(bc,null, null);
    }
    
}