public with sharing class NegoTemplatePrintQueue implements Queueable, Database.AllowsCallouts {
    
    private List<Id> recordIds;
    private List<Id> templateIds;
    
    public NegoTemplatePrintQueue(List<Id> rids, List<Id> tids) {
        this.recordIds = rids;
        this.templateIds = tids;
    }
    // Execute
    public void execute(QueueableContext context) {
        List<Attachment> attachmentList = new List<Attachment>();
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on insert attachment fields
            String[] attachmentCreateFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
           
            if(NegoptimHelper.checkCreatibility(Attachment.SObjectType, attachmentCreateFields)) {
                ////for (Integer i = 0 ; i < recordIds.size() ; i++) {
                for (NegoTemplate__c item : [SELECT Id, Name, ObjectType__c FROM NegoTemplate__c WHERE Id IN :templateIds]) {
                    ////PageReference pr = new PageReference('/apex/previewPrint?tempId='+item.Id+'&id='+recordIds.get(0)+'&Object='+item.ObjectType__c);
                    //PreviewPrintController p = new PreviewPrintController(temp.Id, recordIds.get(i), temp.RelatedToType__c);
                    
                    PageReference pageRef = Page.NegoTemplatePreview;
                    pageRef.getParameters().put('tid', '' + item.id);
                    pageRef.getParameters().put('ids', '' + recordIds.get(0));
                    pageRef.setRedirect(true);
                    
                    Attachment attachmentPDF = new Attachment();
                    attachmentPDF.ParentId = recordIds.get(0);
                    attachmentPDF.Name  = item.Name + ' -'+ system.now() + '.pdf';
                    attachmentPdf.ContentType = 'application/pdf';
                    Blob reportPdf;
                    if (Test.IsRunningTest()) {
                        reportPdf = Blob.valueOf('UNIT.TEST');
                    } else {
                        reportPdf = pageRef.getContent(); // getContentAsPDF()
                    }
                    attachmentPDF.Body = reportPdf;
                    attachmentList.add(attachmentPDF);
                }
                
                if(!attachmentList.isEmpty()){
                    insert attachmentList;                
                }
                ////}
            }
        }        
        catch(DmlException e) {
            Database.rollback(sp);
        }
        catch (Exception e) {
            // Roll everything back in case of error.
            Database.rollback(sp);
        }
    }
}