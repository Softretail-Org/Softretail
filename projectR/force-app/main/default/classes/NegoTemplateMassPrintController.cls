/**
 * @author ULiT
 * @describtion the controller class for mass printing records in NegOptim Templates.
 * it is used by all mass print pages added by the user
********************************************************************************************************************* */

public with sharing class NegoTemplateMassPrintController extends NegoptimBaseController {
    
    /**
     * @description used to call cancel()
	*/
    private ApexPages.StandardSetController stdSetCtrl;
    /**
     * @description the Id of the Mass_Print_Job__c, it is used to specify the queue of records to print
    ***************************************************************************************************************** */
   private Id JobId;
    
    /**
     * @description collection of Ids to be printed
    ***************************************************************************************************************** */
    private Set<Id> selectedRecordsId;
    
    /**
     * @description it maps the Id of an async apex job to a templateWrapper object in order to keep track of documents to combine them
    ***************************************************************************************************************** */
    private Map<Id, WrapperTemplate> batchMap = new Map<Id, WrapperTemplate>();
    
    /**
     * 
    ***************************************************************************************************************** */
    public ApexPages.StandardSetController recordsStdSetCtrl {get; set;}
    
    /**
     * @description a list of available templates that could be used to generate documents displayed on page
    ***************************************************************************************************************** */
    public List<WrapperTemplate> wAvailableTemplates {get; set;}
    
    /**
     * @description a list of the selected records to print, displayed on page
    ***************************************************************************************************************** */
    public List<SObject> recordsList {get; set;}
    
    /**
     * @description to indicate if there are any printing jobs in progress
    ***************************************************************************************************************** */
    public Boolean printingInProgress {get; set;}
    
    /**
     * @description the object type of records to print
    ***************************************************************************************************************** */
    private String objectType;
    
    /**
     * @description the list of selected records to be added to the print queue
    ***************************************************************************************************************** */
    private List<SObject> selectedSObjects;
    
    /**
     * @description the id of the record to remove from this print queue: sent from the mass print page
	*/
    public Id toRemoveRecordId {get; set;}
    
    public Integer size {get; set;}
    public Integer noOfRecords {
        get {
            return noOfRecords == null ? 0 : noOfRecords;
        }
        set;
    }
    private String orderField = 'Name';
    /**
     * @description controller
     * loads the selected records from stdSetCtrl and initiates the variable objectType
     * @parameter stdSetCtrl
    ***************************************************************************************************************** */
    public NegoTemplateMassPrintController(ApexPages.StandardSetController stdSetCtrl) {
        this.stdSetCtrl = stdSetCtrl;
        selectedSObjects = stdSetCtrl.getSelected();
        if (!selectedSObjects.isEmpty()) {
            objectType = selectedSObjects[0].Id.getSobjectType().getDescribe().getName();
        }
    }
    
    /**
     * @description the first action executed by the page
     * 1-fetches the Mass_Print_Job__c specific to the object type, if none exist -> insert new record
     * 2-loads the records to print from the queue (Negoptim_Document__c records) and adds the newly selected records if any
     * 3-fetches available templates
     * 4-query the selectedRecords from the database to be displayed on page
    ***************************************************************************************************************** */
    public PageReference pageAction() {
        //get the Mass_Print_Job to properly handel selected records
        List<Mass_Print_Job__c> jobList;
        List<String> massPrintJobFields = new List<String> {Mass_Print_Job__c.fields.ObjectType__c.getDescribe().getName()};
        if (checkAccessibility(Mass_Print_Job__c.getSObjectType(), massPrintJobFields)) {  
            jobList = [SELECT Id FROM Mass_Print_Job__c WHERE ObjectType__c = :objectType LIMIT 1];
        } else return null;
        if (jobList == null || jobList.isEmpty()) {
            try {
                if (checkCreatibility(Mass_Print_Job__c.getSObjectType(), massPrintJobFields)) {
                    Mass_Print_Job__c printJob = new Mass_Print_Job__c(ObjectType__c = objectType);
                    insert printJob;
                    this.jobId = printJob.Id;
                } else return null;
            } catch (DMLException ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred while creating a print job'));
                return null;
            }
        } else {
            this.jobId = jobList[0].Id;
        }
        this.selectedRecordsId = new Set<Id>();
        List<String> negoptimDocumentFields = new List<String> {
                Negoptim_Document__c.fields.Mass_Print_Job__c.getDescribe().getName(),
                Negoptim_Document__c.fields.Content_Size__c.getDescribe().getName(),
                Negoptim_Document__c.fields.parent_record_Id__c.getDescribe().getName()};
        if (checkAccessibility(Negoptim_Document__c.getSObjectType(), negoptimDocumentFields)) {
            for (Negoptim_Document__c negoDoc : [SELECT parent_record_Id__c
                                                 FROM Negoptim_Document__c
                                                 WHERE Mass_Print_Job__c = :jobId AND Content_Size__c = 0])
            {
                this.selectedRecordsId.add(ID.valueOf(negoDoc.parent_record_Id__c));
            }
        } else return null;
        //Check if any of the newly selected records is not added to the print queue and add them
        List<Negoptim_Document__c> docsToInsert = new List<Negoptim_Document__c>();
        for (SObject so : selectedSObjects) {
            if (!selectedRecordsId.contains(so.Id)) {
                docsToInsert.add(new Negoptim_Document__c(Mass_Print_Job__c = jobId, Content_Size__c = 0, parent_record_Id__c = so.Id));
                selectedRecordsId.add(so.Id);
            }
        }
        try {
            if (checkCreatibility(Negoptim_Document__c.getSObjectType(), negoptimDocumentFields)) {
                insert docsToInsert;
            } else return null;
        } catch (DMLException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error adding records to print queue'));
            return null;
        }
        this.wAvailableTemplates = new List<WrapperTemplate>();
        List<String> negoTemplateFields = new List<String> {
                NegoTemplate__c.fields.Name.getDescribe().getName(),
                NegoTemplate__c.fields.Description__c.getDescribe().getName(),
                NegoTemplate__c.fields.Mass_Print_Order_By_Field__c.getDescribe().getName(),
                NegoTemplate__c.fields.ObjectType__c.getDescribe().getName(),
                NegoTemplate__c.fields.isActive__c.getDescribe().getName(),
                NegoTemplate__c.fields.Document_Recipient__c.getDescribe().getName(),
                NegoTemplate__c.fields.Send_Email_When_Printing__c.getDescribe().getName()};
                    
        if (checkAccessibility(NegoTemplate__c.getSObjectType(), negoTemplateFields)) {
            List<NegoTemplate__c> templates = [SELECT Name, Description__c, Mass_Print_Order_By_Field__c, 
                                               Document_Recipient__c, Send_Email_When_Printing__c
                                               FROM NegoTemplate__c
                                               WHERE ObjectType__c = :objectType AND isActive__c = true];
            if (!templates.isEmpty()) {
                for (NegoTemplate__c template : templates) {
                    this.wAvailableTemplates.add(new WrapperTemplate(template));
                    if (String.isNotBlank(template.Mass_Print_Order_By_Field__c)) {
                        this.orderField = template.Mass_Print_Order_By_Field__c;
                    }
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no active templates for ' + objectType));
                return null;
            }
        }
        this.setUpStdSetCtrl();
        this.recordsList = new List<SObject>();
        printingInProgress = false;
        
        return null;
    }
    
    /**
     * @description loads the records to be displayed on page from the standerd set controller
     * @return List<WrapperObject>
    ***************************************************************************************************************** */
    public List<SObject> getRecordList() {
        recordsList = new List<SObject>();
        if (recordsStdSetCtrl != null ) {
            for (SObject so : recordsStdSetCtrl.getRecords()) {
                boolean selected = false;
                if (selectedRecordsId.contains(so.Id)) {
                    selected = true;
                }
                recordsList.add(so);
            }
        }
        return recordsList;
    }
    
    /**
     * @description generate 1 attachement for each record and each template
    ***************************************************************************************************************** */
    public PageReference print() {
        if (selectedRecordsId != null && !selectedRecordsId.isEmpty()) {
            printingInProgress = true;
            batchMap.clear();
            for (WrapperTemplate wt : wAvailableTemplates) {
                if (wt.isSelected) {
                    Id batchInstanceId = Database.executeBatch(new GenerateNegoptimDocumentsBatch('MassRecordPrintController', new List<Id>(selectedRecordsId),
                                                                                                  wt.template.Id, true, false, wt.template.Send_Email_When_Printing__c), 25);
                    wt.status = 'Printing ...';
                    batchMap.put(batchInstanceId, wt);
                } else {
                    wt.status = 'Not Selected For Printing';
                }
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No records to print'));
        }
        return null;
    }
    
    public PageReference printAndCombine() {
        if (selectedRecordsId != null && !selectedRecordsId.isEmpty()) {
           //// printingInProgress = true;
            batchMap.clear();
            for (WrapperTemplate wt : wAvailableTemplates) {
                if (wt.isSelected) {
                    Id batchInstanceId = Database.executeBatch(new GenerateNegoptimDocumentsBatch('MassRecordPrintController', new List<Id>(selectedRecordsId),
                                                                                                  wt.template.Id, true, true, wt.template.Send_Email_When_Printing__c), 25);
                    wt.status = 'Print has started';
                    batchMap.put(batchInstanceId, wt);
                } else {
                    wt.status = 'Not Selected For Printing';
                }
            }
            String msg = 'The Print job';
            msg += batchMap.size() > 1  ? 's  have' : ' has';
            msg += ' started, You will be notified by email when printing and combining is complete.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.print_job_started_page_message));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No records to print'));
        }
        return null;
    }
    
    /**
     * @description combines every 50 generated documents per template in one file
    ***************************************************************************************************************** */
    public PageReference combine() {
        
        List<Id> templateIds = new List<Id>();
        List<String> templateNames = new List<String>();
        for (WrapperTemplate item : wAvailableTemplates) {
            if (item.isSelected) {
                templateIds.add(item.template.id);
                templateNames.add(item.template.Name);
            }
        }
        Database.executeBatch(new CombineDocumentsBatch('NegoTemplateMassPrintController',templateIds, jobId), 4);
        String privateFolder = [SELECT id FROM Folder WHERE name = 'private'].Id;
        String msg = 'Combining documents for templates ';
        msg += String.join(templateNames, ', ');
        msg += '<br/>You can find the results in the \'private\' folder in Documents';
        msg += '<a href="/' + privateFolder + '" target="_blank">View</a>';
        msg += '<br/>When the job is done you notified by Email';
        ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.INFO, msg));
        return null;
    }
    
    /**
     * @description checks on the progress of the print jobs if any
    ***************************************************************************************************************** */
    public PageReference pollerAction() {
        Integer count = 0;
        for (AsyncApexJob apexJob : [SELECT Status FROM AsyncApexJob WHERE Id IN :batchMap.keySet()]) {
            String jobStatus = apexJob.status;
            if (batchMap.get(apexJob.Id) != null) {
                if (jobStatus.equalsIgnoreCase('completed')) {
                    batchMap.get(apexJob.Id).status = 'Succesfully Printed';
                    ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.INFO, 'You will be notified by email when printing is complete'));
                    count ++;
                }
                if (jobStatus.equalsIgnoreCase('failed')) {
                    batchMap.get(apexJob.Id).status = 'Failed to Print';
                    ApexPages.addMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, 'Job Failed'));
                    count ++;
                }
            }
            if (count == batchMap.size()) {
                printingInProgress = false;
            }
        }
        return null;
    }
    
    /**
     * @description clears the print queue and returns to the tab(main grid)
    ***************************************************************************************************************** */
    public PageReference ClearSelected() {
        List<Negoptim_Document__c> toClearList = [SELECT Id
                                                  FROM Negoptim_Document__c
                                                  WHERE Mass_Print_Job__c = :jobId AND Content_Size__c = 0];
        try {
            if (checkDeletibility(Negoptim_Document__c.SObjectType)) {
                delete toClearList;
                this.recordsStdSetCtrl = null;
                this.selectedRecordsId.clear();
            }
        } catch(DMLException ex) { }
        return stdSetCtrl.cancel();
    }
    
    /**
     * @description redirects user to standard page of sending emails
    */
    public PageReference redirectToMailingPage() {
        PageReference pr = new PageReference('/_ui/core/email/author/EmailAuthor');
        return pr;
    }
    
    /**
     * @description
	*/
    public void removeRow() {
        try {
            if (checkDeletibility(Negoptim_Document__c.SObjectType)) {
                DELETE [SELECT Id FROM Negoptim_Document__c WHERE Parent_Record_Id__c = :toRemoveRecordId AND Mass_Print_Job__c = :jobId];
                selectedRecordsId.remove(toRemoveRecordId);
                this.setUpStdSetCtrl();
            }
        } catch (DMLException ex) { }
    }
    
    /**
     * @description
     * 
	*/
    private void setUpStdSetCtrl() {
        try {
            List<String> objectTypeFields = new List<String>(Schema.getGlobalDescribe().get(ObjectType).getDescribe().fields.getMap().keySet());
            String fields = String.join(objectTypeFields, ', ');
            String query = 'SELECT ' + fields +' FROM ';
            query += ObjectType + ' WHERE Id IN (\'';
            query += String.join(new List<Id>(selectedRecordsId), '\',\'') + '\')';
            query += String.isNotBlank(this.orderField) ? ' ORDER BY ' + this.orderField : '';
            size = this.recordsStdSetCtrl != null ? this.recordsStdSetCtrl.getPageSize() : 25;
            Integer pageNumber = this.recordsStdSetCtrl != null ? this.recordsStdSetCtrl.getPageNumber() : 1;
            this.recordsStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            this.recordsStdSetCtrl.setPageSize(size);
            this.recordsStdSetCtrl.setPageNumber(pageNumber);
            noOfRecords = this.recordsStdSetCtrl.getResultSize();
        } catch (exception ex) { }
    }
    
    public class WrapperTemplate {
        public NegoTemplate__c template {get; set;}
        public Boolean isSelected {get; set;}
        public String status {get; set;}
        
        public WrapperTemplate (NegoTemplate__c template) {
            this.template = template;
            this.isSelected = false;
            this.status = '';
        }
    }
    
}