public class CombineDocumentsBatch implements Database.Batchable<String>, Database.stateful {
    
    private Integer nbRecordsLimit;
    private Long stamp;
    private Id jobId;
    private String query;
    private NegoptimBatch nb;
    private List<Document> docsList =  new List<Document>();
    
    public CombineDocumentsBatch(String stratedFrom, List<Id> templateIds, Id jobId) {
        nb = new NegoptimBatch('CombineDocumentsBatch',NegoptimBatch.BatchType.Stateful, stratedFrom);
        this.nbRecordsLimit = 50;
        this.stamp = DateTime.now().getTime();
        this.jobId = jobId;
        String q = 'SELECT Template__c templateId, Template__r.Name templateName, COUNT(Id) docCount';
        q += ' FROM Negoptim_Document__c';
        q += ' WHERE Mass_Print_Job__c =\'' + jobId +'\'';
        q += ' AND Template__c IN (\'' + String.join(templateIds, '\',\'') + '\')';
        q += ' AND version__c = \'New\'';
        q += ' GROUP BY Template__c, Template__r.Name';
        this.query = q;
        nb.logParameter('nbRecordsLimit', this.nbRecordsLimit);
        nb.logParameter('stamp', this.stamp);
        nb.logParameter('templateIds', templateIds);
        nb.logParameter('jobId', this.jobId);
        nb.logParameter('query', this.query);
    }
    
    public Iterable<String> start(Database.BatchableContext bc) {
        List<String> scope1 = new List<String>();
        for (AggregateResult result : Database.query(query) ) { 
            Integer totalNumberOfRecords = Integer.valueOf(result.get('docCount'));
            Integer numberOfIterations = totalNumberOfRecords/nbRecordsLimit;
            if (Math.mod(totalNumberOfRecords, nbRecordsLimit) > 0) {
                numberOfIterations++;
            }
            String item = String.valueOf(result.get('templateId')) + '-';
            item += String.valueOf(result.get('templateName')) + '-';
            item += numberOfIterations + '-';
            for (Integer i = 0; i < numberOfIterations; i++) {
                scope1.add(item + i);
            }
        }
        nb.logParameter('Number Of Expected Documents', scope1.size());
        return scope1;
    }
    
    public void execute(Database.BatchableContext bc, List<String> scope) {
        
        for (String item : scope) {
            Blob pdfContent;
            String templateId = item.split('-')[0];
            String numberOfIterations = item.split('-')[2];
            String i = item.split('-')[3];
            PageReference pageRef = Page.CombineDocumentsPDF;
            pageRef.getParameters().put('jid', jobId);
            pageRef.getParameters().put('tid', templateId);
            pageRef.getParameters().put('nbIterations', numberOfIterations);
            pageRef.getParameters().put('iteration', i+'');
            if (Test.IsRunningTest()) {
                pdfContent = Blob.valueOf('UNIT.TEST');
            } else {
                pdfContent = pageRef.getContentAsPDF();
            }
            String fileName = item.split('-')[1] + ':Combined Doc:' + stamp + ' - part' + i + '.pdf';
            Document doc = new Document();
            doc.name = fileName;
            doc.ContentType = 'application/pdf';
            doc.FolderId = [SELECT Id FROM Folder WHERE name = 'private'].Id;
            doc.Body = pdfContent; 
            docsList.add(doc);
        }
        try {
            // check security on insert document fields
            String[] documentCreateFields = new String[]{ 'Name', 'Body', 'FolderId', 'ContentType' };
            if(NegoptimHelper.checkCreatibility(Document.SObjectType, documentCreateFields)) {
                List<Database.SaveResult> results = Database.insert(docsList);
                nb.logResults(results, docsList);
            }
        } catch (DMLException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error inserting combined documents'));
            nb.logError(ex);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
        String emailBody = nb.generateTraceLog();
        emailBody += '<br/>';
        emailBody += 'Generated Documents: <br/>';
        for (Document doc : docsList) {
            emailBody += URL.getSalesforceBaseUrl().toExternalForm() + '/' + doc.Id + '<br/>'; 
        }
        nb.sendEmail(bc, emailBody, null);
    }
}