/**
 * @author: ULiT
*/

public with sharing class CombineDocumentsController {
    
    /**
     * @description the HTML head of the combined document
	***************************************************************************************************************** */
    public String head {get; set;}
    
    /**
     * @description the HTML body of the combined document
	***************************************************************************************************************** */
    public String body {get; set;}
    
    /**
     * @description constructor
     * it fetches Negoptim_Document__c records from the database into a standard set controller of page size 25 in order to combine the documents 
     * without excceding any limits
	***************************************************************************************************************** */
    public CombineDocumentsController() {
        
        String jobId = Apexpages.currentPage().getParameters().get('jid');
        String templateId = Apexpages.currentPage().getParameters().get('tid');
        Integer numberOfIteration = Integer.ValueOf(Apexpages.currentPage().getParameters().get('nbIterations'));
        Integer iteration = Integer.ValueOf(Apexpages.currentPage().getParameters().get('iteration'));
        Integer totalNumberOfRecords = [SELECT COUNT() 
                                        FROM Negoptim_Document__c 
                                        WHERE Mass_Print_Job__c = :jobId AND Template__c = :templateId AND version__c = 'New'];
        List<Decimal> smartDivisionResults = NegoptimHelper.smartDivision(totalNumberOfRecords, numberOfIteration, 0);
        ApexPages.StandardSetController documentsSetCtrl = new ApexPages.StandardSetController( 
            Database.getQueryLocator(
                [SELECT Head__c, Body__c
                 FROM Negoptim_Document__c
                 WHERE Mass_Print_Job__c = :jobId AND Template__c = :templateId AND version__c = 'New'
                 ORDER BY AutoNum__c]));
        Integer pageSize = 25;
        documentsSetCtrl.setPageSize(pageSize);
        for (Integer i = 0; i < iteration*2; i++) {
            documentsSetCtrl.next();
        }
        body = '';
        for (Integer i = 0; i < 2; i++) {
            for (Negoptim_Document__c nd : (List<Negoptim_Document__c>) documentsSetCtrl.getRecords()) {
                if (String.isEmpty(head)) {
                    head = nd.Head__c ;
                }
                body += nd.Body__c;
            }
            if (documentsSetCtrl.getHasNext()) {
                documentsSetCtrl.next();
            } else {
                break;
            }
        }
    }
}