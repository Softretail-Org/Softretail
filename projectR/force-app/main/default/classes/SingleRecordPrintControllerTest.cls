@isTest
private class SingleRecordPrintControllerTest {

    private static Account account;
    private static NegoTemplate__c template;
    
    static void init() {

        account = new Account(Name='Account', AccountNumber='Acc', Site='Site', CurrencyIsoCode='EUR');
        insert account;     
        template = new NegoTemplate__c (Name='Test Template');
        template.ObjectType__c = 'Account';
        template.Mass_Print_Order_by_Field__c = 'Name';
        template.Body__c = 'Account Name = {{!Account.Name}} site is {{!Account.Site}}';
        insert template;
    }
    
    static testmethod void constructor_test() {
        init();
        PageReference pageRef = Page.SingleRecordPrint;
        pageRef.getParameters().put('id',account.Id); 
        Test.setCurrentPage(pageRef);
        SingleRecordPrintController ctrl = new SingleRecordPrintController();
        System.assertEquals(1, ctrl.wTableRows.size());
        System.assertEquals('Account', ctrl.SObjectType);
    }
    
    static testmethod void preview_test() {
        init();
        PageReference pageRef = Page.SingleRecordPrint;
        pageRef.getParameters().put('id',account.Id); 
        Test.setCurrentPage(pageRef);
        SingleRecordPrintController ctrl = new SingleRecordPrintController();
        ctrl.currentTemplateId = template.Id;
        PageReference previewRef = ctrl.previewDocument();
        System.assertEquals(account.Id,  previewRef.getParameters().get('rid'));        
        System.assertEquals(template.Id, previewRef.getParameters().get('tid'));
    }
    
    static testmethod void saveAttachments_test() {
        init();
        PageReference pageRef = Page.SingleRecordPrint;
        pageRef.getParameters().put('id',account.Id); 
        Test.setCurrentPage(pageRef);
        SingleRecordPrintController ctrl = new SingleRecordPrintController();
        ctrl.wTableRows[0].isSelected = true;
        ctrl.saveAttachments();
        System.assertEquals(1, [SELECT COUNT() FROM Attachment WHERE ParentId = :account.Id]);
        System.assertEquals(false, ctrl.phaseSelectTemplates);
    }
    
    static testmethod void emailSelected_test() {
        init();
        PageReference pageRef = Page.SingleRecordPrint;
        pageRef.getParameters().put('id',account.Id); 
        Test.setCurrentPage(pageRef);
        SingleRecordPrintController ctrl = new SingleRecordPrintController();
        ctrl.wTableRows[0].isSelected = true;
        ctrl.saveAttachments();
        ctrl.emailSelected();
        System.assertEquals(true, ctrl.phaseSendEmail);
        System.assertEquals(1, ctrl.emailAttachmentList.size());
    }
    
    static testmethod void removeAllAttachments_test() {
        init();
        PageReference pageRef = Page.SingleRecordPrint;
        pageRef.getParameters().put('id',account.Id); 
        Test.setCurrentPage(pageRef);
        SingleRecordPrintController ctrl = new SingleRecordPrintController();
        ctrl.wTableRows[0].isSelected = true;
        ctrl.saveAttachments();
        ctrl.emailSelected();
        ctrl.removeAllAttachments();
        System.assertEquals(0, ctrl.emailAttachmentList.size());
    }
    
    static testmethod void send_test() {
        init();
        PageReference pageRef = Page.SingleRecordPrint;
        pageRef.getParameters().put('id',account.Id); 
        Test.setCurrentPage(pageRef);
        SingleRecordPrintController ctrl = new SingleRecordPrintController();
        ctrl.wTableRows[0].isSelected = true;
        ctrl.saveAttachments();
        ctrl.emailSelected();
        ctrl.emailTo = 'to1@domain.com, to2@domain.com';
        ctrl.emailCc = 'cc1@domain.com, cc2@domain.com';
        ctrl.emailBcc = '';
        ctrl.emailBody = 'body';
        ctrl.send();
        ctrl.selectedAttachmentId = ctrl.emailAttachmentList[0].id;
        ctrl.removeSelectedAttachment();
        PageReference recordPage = ctrl.cancel();
        System.assertEquals(0, ctrl.emailAttachmentList.size());
        System.assertEquals('/' + account.id, recordPage.getUrl());        
    }

}