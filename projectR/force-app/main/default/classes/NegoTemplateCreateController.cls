/**
* NegoTemplateCreate Controller used to manage the creation
* of PDF for selected records based on choosed templates 
* */
public with sharing class NegoTemplateCreateController extends NegoptimBaseController {
    
    public final Id recordId;
    public final String sObjectType {get; set;}
    public List<SelectOption> optionsValue {get; set;}
    public Map<Id, String> availableTemplatesMap;
    public Map<Id, String> selectedTemplatesMap {get; set;}
    public String[] selectedTemplates {get; set;}
    public Id templateId {get; set;}
    
    public String emailName {get; set;}
    public String emailTo {get; set;}
    public String emailCc {get; set;}
    public String emailSubject {get; set;}
    public String emailBody {get; set;}
    public Boolean ShowPoup {get; set;}
    public String[] emails {get; set;}
    public String[] ccAddresses {get; set;}
    
    // Constructor
    public NegoTemplateCreateController() {
        String sRecordId = apexpages.currentPage().getParameters().get('id');
        recordId = Id.valueOf(sRecordId);
        sObjectType = recordId.getSobjectType().getDescribe().getName();

        optionsValue = new List<SelectOption>();
        availableTemplatesMap = new Map<Id, String>();
        selectedTemplatesMap = new Map<Id, String>();
        selectedTemplates = new String[]{};
        ShowPoup = false;
        for(NegoTemplate__c item : [SELECT Id, Name
                                    FROM NegoTemplate__c
                                    WHERE ObjectType__c = :sObjectType
                                    AND IsActive__c = true])
        {
            optionsValue.add(new selectOption(item.Id, item.Name));
            availableTemplatesMap.put(item.Id, item.Name);
        }
    }
    // Preview 
    public PageReference Preview() {
        PageReference pageRef = Page.NegoTemplatePreview;
        pageRef.getParameters().put('tid', '' + templateId);
        pageRef.getParameters().put('ids', '' + recordId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    // Save as Attachment for the record Id
    public PageReference save() {
        // check security on insert attachment fields
        String[] attachmentFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
            if(!checkCreatibility(Attachment.SObjectType, attachmentFields)){
                return null;
            }
        List<Attachment> attachments = new List<Attachment>();
        for(Integer i = 0; i < selectedTemplates.size(); i++) {
            Attachment attachmentPDF = generateAttachment(selectedTemplates[i]);
            attachments.add(attachmentPDF);
        }
        insert attachments;
        return null;
    }
    // Send email with current pdf attachment
    public PageReference sendEmailWithAttachment() {        
        // check security on insert attachment fields
        String[] attachmentFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
            if(!checkCreatibility(Attachment.SObjectType, attachmentFields)){
                return null;
            }
        
        List<Attachment> attachments = new List<Attachment>();
        List<Messaging.EmailFileAttachment> email_attachments = new List<Messaging.EmailFileAttachment>();
        for(Integer i = 0; i < selectedTemplates.size(); i++) {
            Attachment attachmentPDF = generateAttachment(selectedTemplates[i]);
            attachments.add(attachmentPDF);
        }
        for(Attachment att : attachments) {
            Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
            email_att.setBody(att.Body);
            email_att.setContentType(att.ContentType);
            email_att.setFileName(att.Name);
            email_att.setinline(false);
            email_attachments.add(email_att);
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        emails = new String[]{};
        ccAddresses = new String[]{};
        emails = emailTo.split(',');
        ccAddresses = emailCc.split(',');
        email.setToAddresses(emails);//list of email addresses
        email.setSubject(emailSubject);
        email.setCcAddresses(ccAddresses);
        email.setFileAttachments(email_attachments);
        email.setHtmlBody(emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        return null;
    }
    // Generate Attachment
    private Attachment generateAttachment(Id tid) {
        PageReference pageRef = Page.NegoTemplatePreview;
        pageRef.getParameters().put('tid', '' + tid);
        pageRef.getParameters().put('ids', '' + recordId);
        pageRef.setRedirect(true);
        
        Attachment attachmentPDF = new Attachment();
        attachmentPDF.ParentId = recordId;
        attachmentPDF.name  = availableTemplatesMap.get(tid) + ' -'+ system.now() + '.pdf';
        attachmentPdf.ContentType = 'application/pdf';
        Blob reportPdf;
        if (Test.IsRunningTest()) {
	        reportPdf = Blob.valueOf('UNIT.TEST');
	   	} else {
	        reportPdf = pageRef.getContent();
	   	}
        attachmentPDF.Body = reportPdf;
        return attachmentPDF;
    }
    // cancel method
    public PageReference Cancel() {
        PageReference page = new PageReference('/' + recordId);
        return page;
    }
    public void showSelectedTemplates() {
        selectedTemplatesMap.clear();
        for(Id item : selectedTemplates) {
            selectedTemplatesMap.put(item, availableTemplatesMap.get(item));
        }
    }
    public void showEmailPopup() {
        ShowPoup = true;
    }
    public void closePopup() {
        ShowPoup = false;
    }
}