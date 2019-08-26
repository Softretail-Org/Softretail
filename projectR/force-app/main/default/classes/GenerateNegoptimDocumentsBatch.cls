/**
 * @author ULiT
 * @description 
 * 1-execute the parser engine for all records
 * 2-insert the Negoptim_Document__c records returned by the parser engine
 * 3-execute GenerateAttachmentsBatch to insert attachments
***************************************************************************************************************** */
public class GenerateNegoptimDocumentsBatch implements Database.Batchable<Id>, Database.stateful {
    
    private NegoptimBatch nb;
    private List<Id> recordsId;
    private NegoTemplate__c template;
    private Id jobId;
    private List<Id> generatedIds = new List<Id>();
    private Boolean generateAttachments;
    private Boolean combine;
    private Boolean emailWhenPrinting;
    
    public GenerateNegoptimDocumentsBatch(String startedFrom, List<Id> recordsId, Id templateId, Boolean generateAttachments, Boolean combine, Boolean emailWhenPrinting) {
        this.recordsId = recordsId;
        this.nb = new NegoptimBatch('GenerateNegoptimDocumentsBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.template = [SELECT Name, ObjectType__c, Template_Format__c, Mass_Print_Order_by_Field__c FROM NegoTemplate__c WHERE id = :templateId];
        String objectType = this.template.ObjectType__c;
        this.jobId = [SELECT Id FROM Mass_Print_Job__c WHERE ObjectType__c = :objectType].Id;
        this.generateAttachments = generateAttachments;
        this.combine = combine;
        this.emailWhenPrinting = emailWhenPrinting;
        nb.logParameter('Template', this.template);
        nb.logParameter('Number of Selected Records', this.recordsId.size());
        nb.logParameter('Ids', this.recordsId);
        nb.logParameter('generateAttachments', this.generateAttachments);
        nb.logParameter('combine', this.combine);
    }
    
    public Iterable<Id> start(Database.BatchableContext bc) {
        if (String.isNotBlank(this.template.Mass_Print_Order_BY_Field__c) &&
            NegoptimTemplatesHelper.isValidField(this.template.ObjectType__c, this.template.Mass_Print_Order_BY_Field__c.split('\\.')))
        {
            String query = 'SELECT Id FROM ' + this.template.ObjectType__c;
            query += ' WHERE Id IN (\'' + String.Join(this.recordsId, '\',\'') + '\')';
            query += ' ORDER BY ' + this.template.Mass_Print_Order_BY_Field__c;
            List<SObject> records = Database.query(query);
            this.recordsId = new List<Id>();
            for (SObject rec : records) 
                recordsId.add(rec.Id);
        }
        return this.recordsId;
    }
    
    public void execute(Database.BatchableContext bc, List<Id> scope) {
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on insert attachment fields
            String[] attachmentCreateFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
            NegoptimHelper.checkCreatibility(Attachment.SObjectType, attachmentCreateFields);
            NegoTemplateParser engine = new NegoTemplateParser(this.template.Id, scope, false);
            List<Negoptim_Document__c> generatedDocsList = engine.parse();
            for (Negoptim_Document__c negoDoc : generatedDocsList) {
                negoDoc.Mass_Print_Job__c = jobId;
            }
            List<String> negoptimDocumentFields = new List<String> {
                Negoptim_Document__c.fields.version__c.getDescribe().getName(),
                Negoptim_Document__c.fields.template__c.getDescribe().getName()};
            NegoptimHelper.checkAccessibility(Negoptim_Document__c.SObjectType, negoptimDocumentFields);        
            List<Negoptim_Document__c> oldDocsList = [SELECT version__c
                                                      FROM Negoptim_Document__c
                                                      WHERE template__c = :this.template.Id AND Version__c = 'New' AND Id NOT IN :generatedIds];
            for (Negoptim_Document__c negoDoc : oldDocsList) {
                negoDoc.Version__c = 'Old';                                       
            }
            List<Database.SaveResult> results = Database.update(oldDocsList);
            nb.logResults(results, oldDocsList);
            if (generatedDocsList != null && !generatedDocsList.isEmpty()) {
                results = Database.insert(generatedDocsList);
                nb.logResults(results, generatedDocsList);
            } 
            
            for (Negoptim_Document__c nd : generatedDocsList) {
                generatedIds.add(nd.Id);
            }
            
        } catch (NoAccessException ex) {
            nb.logError(ex);
        } catch(DmlException ex) {
            nb.logError(ex);
        } catch (Exception ex) {
            nb.logError(ex);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.sendEmail(bc, null, null);
        ////Boolean jobSuccessful = nb.getAsyncApexJob(bc).Status.equalsIgnoreCase('Success');
        Boolean jobSuccessful = nb.getAsyncApexJob(bc).Status.equalsIgnoreCase('Completed');
        if (generateAttachments && jobSuccessful)
            Database.executeBatch(new GenerateAttachmentsBatch('GenerateNegoptimDocumentsBatch', generatedIds, recordsId,
                                                               this.template.Id, emailWhenPrinting));
        if (combine && jobSuccessful)
            Database.executeBatch(new CombineDocumentsBatch('GenerateNegoptimDocumentsBatch', new List<Id> {this.template.Id}, this.jobId));
        if (jobSuccessful) {
            if (NegoptimHelper.checkDeletibility(Negoptim_Document__c.SObjectType)) {
                DELETE [SELECT Id FROM Negoptim_Document__c WHERE Mass_Print_Job__c = :this.jobId AND Content_Size__c = 0];
            }
        }
        
    }

    
}