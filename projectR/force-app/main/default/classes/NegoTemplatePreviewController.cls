/**
 * @author ULiT
 * 
***************************************************************************************************************** */

public with sharing class NegoTemplatePreviewController {
    
    public String fileName {get; set;}
    public String content {get; private set;}
    /**
     * @description to indicate whether or not to launch template action(ApprovalProcess)
	*/
    private Boolean isPreview;
    
    public NegoTemplatePreviewController() {
        
    }
    
    public pageReference pageAction() {
        try {
            Negoptim_Document__c document;
            if (apexpages.currentPage().getParameters().get('preview') != null) {
                isPreview = Boolean.valueOf(apexpages.currentPage().getParameters().get('preview'));
            } else {
                isPreview = false;
            }
            //in case used by GenerateNegoptimDocumentsBatch
            if (apexpages.currentPage().getParameters().get('did') != null) {
                String sDocId = apexpages.currentPage().getParameters().get('did');
                Id docId = Id.valueOf(sDocId);
                document = [SELECT Head__c, Body__c FROM Negoptim_Document__c WHERE Id = :docId];
            } else {
                //in case used by SingleRecordPrintController
                String templateId = Id.valueOf(apexpages.currentPage().getParameters().get('tid'));
                String recordId = Id.valueOf(apexpages.currentPage().getParameters().get('rid'));
                document = (new NegoTemplateParser(templateId, new List<Id> {recordId}, isPreview)).parse().get(0);
            }
            fileName = 'Printed Document';
            content = '<head>' + document.Head__c + '</head>' ;
            content += '<body>';
            content += document.Body__c;
            content += '</body>';
        } catch (NegoTemplateParser.ParserException ex) {
            content = '<div style="font-size:24; color:red";>' + ex.getMessage() + '</div>';
        } catch (Exception ex) {
            content = 'An exception accured while creating this document<br/>';
        }
        return null;
    }
    
    // return the content
    public Component.Apex.OutputText getCustomContent() {
        Component.Apex.OutputText objText = new Component.Apex.OutputText(escape = false);
        objText.value = content; 
        return objText;
    }    
}