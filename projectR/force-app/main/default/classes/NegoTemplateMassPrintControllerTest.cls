@isTest
private class NegoTemplateMassPrintControllerTest {
    
    private static Integer numberOfAccounts;
    private static List<Id> accountList;
    private static NegoTemplate__c template;
    
    static void init() {
        
        numberOfAccounts = 10;
        accountList = new List<Id>();
        List<Account> tempList = new List<Account>();
        for (Integer i = 0; i < numberOfAccounts; i++) {
            tempList.add(new Account(Name='Account'+i, AccountNumber='Acc'+i, Site='Site', CurrencyIsoCode='EUR'));
        }
        insert tempList;
        for (Account acc : tempList) {
            accountList.add(acc.Id);
        }
        template = new NegoTemplate__c (Name='Test Template');
        template.ObjectType__c = 'Account';
        template.Mass_Print_Order_by_Field__c = 'Name';
        template.Body__c = 'Account Name = {{!Account.Name}} site is {{!Account.Site}} date is {{!Account.LastModifiedDate dd/MMMMM/yyyy}}';
        template.Body__c += 'A number is {{!Account.AnnualRevenue # ###}}';
        template.Body__c += '<!--{{!<lineitems><class>table255</class><listname>cases</listname>';
        template.Body__c += '<column newrow="true">ContactEmail</column>';
        template.Body__c += '<column>ContactFax</column>';
        template.Body__c += '<column>CaseNumber</column>';
        template.Body__c += '</lineitems>}}-->';
        insert template;
    }
    
    static testmethod void constructor_test() {
        init();        
        Test.startTest();
        ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(
            Database.getQueryLocator(
                [SELECT Id, Name, AccountNumber
                 FROM Account
                 WHERE Id IN :accountList]));
        setCtrl.setSelected([SELECT Id, Name, AccountNumber
                             FROM Account
                             WHERE Id IN :accountList]);
        NegoTemplateMassPrintController ctrl = new NegoTemplateMassPrintController(setCtrl);
        ctrl.pageAction();
        Test.stopTest();
        System.assertEquals(1, ctrl.wAvailableTemplates.size());
    }
    
    static testmethod void print_test() {
        init();        
        Test.startTest();
        ApexPages.StandardSetController setCtrl = new ApexPages.StandardSetController(
            Database.getQueryLocator(
                [SELECT Id, Name, AccountNumber
                 FROM Account
                 WHERE Id IN :accountList]));
        setCtrl.setSelected([SELECT Id, Name, AccountNumber
                             FROM Account
                             WHERE Id IN :accountList]);
        NegoTemplateMassPrintController ctrl = new NegoTemplateMassPrintController(setCtrl);
        ctrl.pageAction();
        ctrl.wAvailableTemplates[0].isSelected = true;
        ctrl.getRecordList();
        ctrl.Print();
        ctrl.pollerAction();
        ctrl.combine();
        ctrl.ClearSelected();
        test.stopTest();
        System.assertEquals(10, [SELECT COUNT() FROM Negoptim_Document__c WHERE Version__c = 'New']);
        System.assertEquals(1, [SELECT COUNT() FROM Mass_Print_Job__c]);
        System.assertEquals(10, [SELECT COUNT() FROM Attachment WHERE ParentId IN :accountList]);
    }
    
}