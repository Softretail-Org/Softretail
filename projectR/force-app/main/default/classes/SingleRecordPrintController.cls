/**
 * @author ULiT
 * 
**************************************************************************************************************************** */

public with sharing class SingleRecordPrintController {
    
    public Id recordId {get; private set;}
	//used when calling genereteEmailList to send emails
    private Map<Id, SObject> recordMap = new Map<Id, SObject>();
    
    public List<WrapperTableRow> wTableRows {get; set;}
    public String SObjectType {get; set;}
    public SObject record {get; private set;}
    public Boolean fieldSetExists {get; set;}
    public Id currentTemplateId {get; set;}
    public Id selectedAttachmentId {get; set;}
    public Boolean phaseSelectTemplates {get ;set;}
    public Boolean phaseSendEmail {get; set;}
    public List<Attachment> emailAttachmentList {get; set;}
    public String emailTo {get; set;}
    public String emailCc {get; set;}
    public String emailBcc {get; set;}
    public String emailSubject {get; set;}
    public String emailBody {get; set;}
    
    /**
     * @description constructor
     * fetches available templates
    *********************************************************************************************************************** */
    public SingleRecordPrintController() {
        recordId = Id.valueOf(apexpages.currentPage().getParameters().get('id'));
        List<String> validFields = new List<String>();
        SObjectType = recordId.getSobjectType().getDescribe().getName();
        FieldSet fieldSet = Schema.getGlobalDescribe().get(this.SObjectType).getDescribe().fieldSets.getMap().get('Field_Set');
        String query = 'SELECT ';
        fieldSetExists = false;
        if (fieldSet != null) {
            List<Schema.FieldSetMember> fieldSetMemberList = fieldSet.getFields();
            for(Schema.FieldSetMember fsm : fieldSetMemberList) {
                query += fsm.getFieldPath() + ', ';
            }
            fieldSetExists = true;
        }
        query += ' ID ';
        query += ' FROM ' + SObjectType;
        query += ' WHERE Id = ' + '\'' + recordId + '\'';
        record = Database.query(query);
        phaseSelectTemplates = true;
        phaseSendEmail = false;
        wTableRows = new List<WrapperTableRow>();
        for (NegoTemplate__c template :[SELECT Name, Description__c, Template_Format__c,
                                        ObjectType__c, Send_Email_When_Printing__c, Document_Recipient__c,
                                        Email_Subject__c, Email_Body__c, Document_Recipient_Cc__c,
                                        Sender_Display_Name__c, Attachment_Name__c
                                        FROM NegoTemplate__c
                                        WHERE ObjectType__c = :SObjectType AND isActive__c = true])
        {
            template.Template_Format__c = template.Template_Format__c == null ? 'Not Specified (PDF by default)' : template.Template_Format__c;
            wTableRows.add(new WrapperTableRow(template));
            //get only valid Document_Recipient__c fields
            if (!String.isBlank(template.Document_Recipient__c)
                && NegoptimTemplatesHelper.isValidField(SObjectType, template.Document_Recipient__c.split('\\.')))
                validFields.add(template.Document_Recipient__c);
        }
        // if there is only 1 template in the table -> it should be selected by default
        if (wTableRows.size() == 1) wTableRows[0].isSelected = true;
        //fetch all valid Document_Recipient__c
        if (!validFields.isEmpty()) {
            String emailRecipientsQuery = 'SELECT ' +  String.join(validFields, ', ');
            emailRecipientsQuery += ' FROM ' + SObjectType;
            emailRecipientsQuery += ' WHERE Id = \'' + recordId + '\'';
            recordMap = new Map<Id, SObject>(Database.query(emailRecipientsQuery));
        }
    }
    
    /**
     * @description opens a preview of the selected template in a new tab
	*/
    public PageReference previewDocument() {
        PageReference pageRef = Page.NegoTemplatePreview;
        pageRef.getParameters().put('tid', '' + currentTemplateId);
        pageRef.getParameters().put('rid', '' + recordId);
        // to indicate that the engine should not execute the aproval process
        pageRef.getParameters().put('preview','true');
        pageRef.setRedirect(true);
        return pageRef;
    }
    /**
     * @description saves an attachements for every selected template
	*/
    public PageReference saveAttachments() {
        try {
            List<Attachment> attachmentsList = new List<Attachment>();
            List<Negoptim_Document__c> documentsList = new List<Negoptim_Document__c>();
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            for (WrapperTableRow item : wTableRows) {
                if (item.isSelected && !item.isPrinted) {
                    PageReference pageRef;
                    Attachment attach = new Attachment();
                    if (item.template.Template_Format__c == null || item.template.Template_Format__c.equalsIgnoreCase('PDF')) {
                        pageRef = Page.NegoTemplatePreview;
                        attach.ContentType = 'application/pdf';
                        //// attach.name  = item.template.Name + ' - '+ system.now() + '.pdf';
                        ///attach.name  = attachmentName + '.pdf';
                    } else if (item.template.Template_Format__c.equalsIgnoreCase('Word Document')) {
                        pageRef = Page.NegoTemplatePreviewDoc;
                        attach.ContentType = 'application/msWord';
                        ////attach.name  = item.template.Name + ' - '+ system.now() + '.doc';
                    } else continue;
                    pageRef.getParameters().put('tid', '' + item.template.Id);
                    pageRef.getParameters().put('rid', '' + recordId);
                    pageRef.getParameters().put('preview','false'); //to indicate that in preview mode - the engine will launch the template Action (ApprovalProcess)
                    attach.ParentId = recordId;
                    Blob fileContent;
                    if (Test.IsRunningTest()) {
                        fileContent = Blob.valueOf('UNIT.TEST');
                    } else {
                        fileContent = pageRef.getContent();
                    }
                    attach.Body = fileContent;
                    NegoTemplateParser engine = new NegoTemplateParser(new List<Id>{recordId});
                    // TODO : Parsing template twice: once to get Name and once to get content : NOT GOOD
                    String attachmentName = String.isBlank(item.template.Attachment_Name__c) ?
                        item.template.Name + ' - '+ system.now() : engine.parse(item.template.Attachment_Name__c).get(recordId);
                    if (item.template.Template_Format__c == null || item.template.Template_Format__c.equalsIgnoreCase('PDF')) attach.name  = attachmentName + '.pdf';
                    if (item.template.Template_Format__c.equalsIgnoreCase('Word Document')) attach.name  = attachmentName + '.doc';
                    attachmentsList.add(attach);
                    item.attachment = attach;
                    item.isPrinted = true;
                    if (item.template.Send_Email_When_Printing__c) {
                        emailList.addAll(NegoptimTemplatesHelper.generateEmailList(recordMap, attachmentsList, item.template.Id));
                    }
                }
            }
            // check security on insert attachment fields
            String[] attachmentCreateFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
            if(NegoptimHelper.checkCreatibility(Attachment.SObjectType, attachmentCreateFields)) {
                insert attachmentsList;
            }
            if (!emailList.isEmpty()) {
                Messaging.sendEmail(emailList);
            }
            phaseSelectTemplates = false;
        } catch (NoAccessException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ex.getMessage()));
        } catch (Exception ex) {
        } 
        return null;
    }
    
    public PageReference emailSelected() {
        if(Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations()) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email');
            ApexPages.addMessage(myMsg);
        } else {
            emailAttachmentList = new List<Attachment>();
            for (WrapperTableRow wtr : wTableRows) {
                if (wtr.isSelected && wtr.isPrinted) {
                    emailAttachmentList.add(wtr.attachment);
                }
            }
            phaseSendEmail = true;
        }
        return null;
    }
    
    /**
     * @description removes an attachment from the email
	*/
    public Pagereference removeSelectedAttachment() {
        Integer SelectedAttachmentPosition = -1;
        for (Attachment att : emailAttachmentList) {
            if (att.Id == selectedAttachmentId) {
                SelectedAttachmentPosition = emailAttachmentList.indexOf(att);
            }
        }
        if (SelectedAttachmentPosition != -1) {
            emailAttachmentList.remove(SelectedAttachmentPosition);
        }
        return null;
    }
    
    /**
     * @description clears all attachments from the email
	*/
    public PageReference removeAllAttachments() {
        emailAttachmentList.clear();
        return null;
    }
    
    /**
     * @description sends the email
	*/
    public PageReference send() {
        String[] toList = getEmailAddresses(emailTo);
        String[] ccList = getEmailAddresses(emailCc);
        String[] bccList = getEmailAddresses(emailBcc);
        List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
        for(Attachment att : emailAttachmentList) {
            Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
            email_att.setBody(att.Body);
            email_att.setContentType(att.ContentType);
            email_att.setFileName(att.Name);
            email_att.setinline(false);
            emailAttachments.add(email_att);
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSenderDisplayName('NegOptim Templates');
        email.setToAddresses(toList);
        email.setCcAddresses(ccList);
        email.setBccAddresses(bccList);
        email.setFileAttachments(emailAttachments);
        email.setSubject(emailSubject);
        email.setHtmlBody(emailBody);
        
        if(Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations()) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email');
            ApexPages.addMessage(myMsg);   
            return null;
		} 
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});    
        } catch (System.EmailException ex) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Single Email Limit Exceeded. Cannot send this email');
            ApexPages.addMessage(myMsg);   
            return null;
        }
        return cancel();
        
    }
    
    public PageReference cancel() {
        pageReference recordPage = new PageReference('/' + recordId);
        return recordPage;
    }
    
    private String[] getEmailAddresses(String source) {
        if (source == null || String.isEmpty(source)) {
            return new String[]{};
        }
        source = source.remove(' ');
        source = source.replaceAll(',', ';');
        return source.split(';');
    }
    
    public class WrapperTableRow {
        public NegoTemplate__c template {get; set;}
        public Attachment attachment {get; set;}
        public Boolean isSelected {get; set;}
        public Boolean isPrinted {get; set;}
        
        public WrapperTableRow (NegoTemplate__c template) {
            this.template = template;
            this.attachment = new Attachment();
            this.isSelected = false;
            this.isPrinted = false;
        }
    }
}