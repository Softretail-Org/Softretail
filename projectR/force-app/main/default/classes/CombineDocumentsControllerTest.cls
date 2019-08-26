@isTest
private class CombineDocumentsControllerTest {
    
    static Integer numberOfDocuments;
    static List<Negoptim_Document__c> docList;
    static Mass_Print_Job__c job;
    static NegoTemplate__c template;
    
    static void init() {
        
        template = new NegoTemplate__c(ObjectType__c='Contact');
        insert template;
        
        job =  new Mass_Print_Job__c(objectType__c='Contact');
        insert job;
        
        numberOfDocuments = 10;
        docList = new List<Negoptim_Document__c>();
        for (Integer i = 0; i <numberOfDocuments; i++) {
            docList.add(New Negoptim_Document__c(Body__c='Body', Head__c='', Content_Size__c = 4, version__c = 'New', Mass_Print_Job__c = job.Id, Template__c = template.Id));
        }
        insert docList;
        List<Id> idList = new List<id>();
        for (Negoptim_Document__c doc : docList) {
            idList.add(doc.Id);
        }
    }
    static testmethod void test() {
        init();
        PageReference pageRef = Page.CombineDocumentsPDF;
        pageRef.getParameters().put('jid', job.Id);
        pageRef.getParameters().put('tid', template.id);
        pageRef.getParameters().put('nbIterations', 1+'');
        pageRef.getParameters().put('iteration', 0+'');
        Test.setCurrentPage(pageRef);
        CombineDocumentsController ctrl = new CombineDocumentsController();
        String body = '';
        for (Negoptim_Document__c doc : docList) {
            body += doc.Body__c;
        }
        System.assertEquals(null, ctrl.head);
        System.assertEquals(body, ctrl.body);
    }
}