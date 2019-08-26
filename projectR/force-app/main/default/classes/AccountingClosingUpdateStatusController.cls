/**
 * @author ULiT
 * @date 25-04-2019
 * AccountingClosingUpdateStatusController
 * */
public with Sharing class AccountingClosingUpdateStatusController extends NegoptimBaseController {
    
    public Date endMonthDate {get;set;}
    private Accounting_Closing__c instance;
    
    public AccountingClosingUpdateStatusController(ApexPages.StandardController stdController) {
        instance = (Accounting_Closing__c)stdController.getRecord();
        endMonthDate = NegoptimHelper.getLastDayOfMonth(instance.Closing_Date__c);
    }
    
    public PageReference save() {
        instance.Status__c = 'Sent_to_Accounting';
        // check security on update Accounting_Closing__c
        String[] accountingClosingFields = new String[] {getFieldName('Status__c')};
        if(checkUpdatibility(Accounting_Closing__c.SObjectType, accountingClosingFields)) {
            update instance;
        }
        return null;
    }
}