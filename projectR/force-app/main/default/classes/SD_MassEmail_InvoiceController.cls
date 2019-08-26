public with sharing class SD_MassEmail_InvoiceController {
    
    public List<emailMergeWrapper> listEmailMergeWrapper {get; set;}
    public Boolean isDisable {get; set;}
    public Map<Id, Boolean> selected {get; set;}  
    public Map<Id, Attachment> mapAttach {get; set;}  
    public Set<Id> selectedSupplierId = new Set<Id>();
    
    public SD_MassEmail_InvoiceController() {  
		getMassMailList();
    }
    
    public PageReference getMassMailList(){
        isDisable = true; 
        Set<Id> setJobIds = new Set<Id>();
        Set<Id> setAttchIds = new Set<Id>();
        selected = new Map<Id, Boolean>();
        List<SDOC__SDJob__c> sDocJobsList = [Select  SDOC__SDoc1__r.SDOC__Attachment_ID__c
                                             FROM SDOC__SDJob__c
                                             WHERE SDOC__Status__c = 'Completed' AND CreatedById = :UserInfo.getUserID()];        
        for(SDOC__SDJob__c jobObj : sDocJobsList) {
            setJobIds.add(jobObj.SDOC__SDoc1__r.SDOC__Attachment_ID__c);
        }						     
        mapAttach = new Map<Id, Attachment>([SELECT Id, Name, Body  FROM Attachment WHERE Id IN:setJobIds]);
        
        List<Invoice__c> invoiceList  = [SELECT Name, Inv_Supplier__r.Id, Inv_Supplier__r.Name, Inv_Supplier__r.Acc_email__c, CreatedBy.name, (SELECT Id FROM Attachments WHERE Id IN :mapAttach.keySet()) From Invoice__c ];
        listEmailMergeWrapper = new List<emailMergeWrapper>();
        for(Invoice__c invoiceObj : invoiceList) {
            for(Attachment attachObj : invoiceObj.Attachments) {
                Attachment attach = mapAttach.get(attachObj.Id);
                if(attach != NULL  && invoiceObj.Inv_Supplier__r.Acc_email__c != NULL) {
                    attachWrapper attachWrapper = new attachWrapper(attach.Id, attach.Name,attach.Body);
                    emailMergeWrapper emailMergeWrapper = new emailMergeWrapper(invoiceObj.Inv_Supplier__r.Id, invoiceObj.Inv_Supplier__r.Name, invoiceObj.Inv_Supplier__r.Acc_email__c, invoiceObj.Name, invoiceObj.CreatedBy.name, attachWrapper);
                    listEmailMergeWrapper.add(emailMergeWrapper);
                    selected.Put(invoiceObj.Inv_Supplier__r.Id, false); 
                    
                }
            }
        }
        if(listEmailMergeWrapper != null && listEmailMergeWrapper.size() > 0){
            isDisable = false;
        }
    	return null;
    }
    
    public PageReference sendInvoicesEmail(){        
        List<Id> listSuppId = new List<Id>();
        for(Id suppId : selected.keySet()){
            boolean isSelected = selected.get(suppId);
            if(isSelected == true){
                listSuppId.add(suppId);
            }
        }
        Id batchInstanceId = Database.executeBatch(new SendInvoicesMailBatch(mapAttach,listSuppId), 150);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,
                                                   'The Job for "Generating Invoices Emails" of Id ' + batchInstanceId + ' is in progress, you will receive an email when completed.'));
        return null;        
    }
   
    public PageReference clearJobList(){
        List<SDOC__SDJob__c> sDocJobsList = [Select Id   FROM SDOC__SDJob__c WHERE  CreatedById = :UserInfo.getUserID()];        
        if(sDocJobsList!= null && sDocJobsList.size() > 0){
            try {  
                if (!SDOC__SDJob__c.sObjectType.getDescribe().isDeletable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete SDJob'));
                    return null;
                }
                delete sDocJobsList;    		  
            } catch(Exception e) { 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Clear Job Email list Error:' + e.getMessage()));
                return null;
            }
            getMassMailList();
        }
        return null;
    }
    
    public class emailMergeWrapper {
        public String supplierId {get; set;}
        public String supplierName {get; set;}
        public String supplierEmail {get; set;}
        public String invoiceNumber  {get; set;}
        public String invoiceByName  {get; set;}
        public attachWrapper attach  {get; set;}
        
        public emailMergeWrapper(String SupplierId, String supplierName, String supplierEmail, String invoiceNumber, String invoiceByName, attachWrapper attach) {
			this.supplierId = supplierId;
			this.supplierName = supplierName;
			this.supplierEmail = supplierEmail;
	        this.invoiceNumber = invoiceNumber; 
	        this.invoiceByName = invoiceByName; 
	        this.attach = attach; 
        }
    }
    
     /* wrapper class to handle file manipulation   */    
    public class attachWrapper {    	
        public String Id {get; set;}
        public String name {get; set;}
        public Blob body{get; set;}
        
        public attachWrapper(String Id, String name, Blob body) {
            this.Id = Id; 
            this.name = name;
            this.body = body;
            this.body = body;
        }
    }
}