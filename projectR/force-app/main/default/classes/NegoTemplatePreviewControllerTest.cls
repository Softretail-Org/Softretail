@isTest
private class NegoTemplatePreviewControllerTest {
    
    private static Account account;
    private static NegoTemplate__c template;
    private static Mass_Print_Job__c job;
    private static Negoptim_Document__c document;
    
    static void init() {
        
        account = new Account(Name='Account', AccountNumber='Acc', Site='Site', CurrencyIsoCode='EUR');
        insert account;     
        template = new NegoTemplate__c (Name='Test Template');
        template.ObjectType__c = 'Account';
        template.Mass_Print_Order_by_Field__c = 'Name';
        template.Body__c = 'Account Name = {{!Account.Name}} site is {{!Account.Site}}';
        insert template;
        job = new Mass_Print_Job__c(ObjectType__c='SinglePrintJob');
        insert job;
        document = new Negoptim_Document__c(head__c='head', body__c='body', content_size__c=8,Mass_Print_Job__c=job.Id );
        insert document;
    }
    
    static testmethod void case_document() {
        init();
        PageReference pageRef = Page.NegoTemplatePreview;
        pageref.getParameters().put('did', document.Id);
        Test.setCurrentPage(pageRef);
        NegoTemplatePreviewController ctrl = new NegoTemplatePreviewController();
        ctrl.pageAction();
        String content = '<head>' + document.Head__c + '</head>' ;
        content += '<body>' + document.Body__c + '</body>';
        System.assertEquals(content, ctrl.content);
    }
    
    static testmethod void case_record() {
        init();
        PageReference pageRef = Page.NegoTemplatePreview;
        pageref.getParameters().put('rid', account.Id);
        pageref.getParameters().put('tid', template.Id);
        Test.setCurrentPage(pageRef);
        NegoTemplatePreviewController ctrl = new NegoTemplatePreviewController();
        ctrl.pageAction();
        String content = '<head>' + document.Head__c + '</head>' ;
        content += '<body>' + document.Body__c + '</body>';
        System.assert(!content.equals(ctrl.content));
    }

}