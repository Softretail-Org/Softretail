/**
 * Batchable class used to scan invoices payment group
 * Case Criteria: Status = New or Invoice_Reference__c = NULL
 * INTEGRITY CONTROL: 
 * a- Check Mandatory fields
 * b- Check Warning fields
 * DATA MAPPING:
 * - Invoice Control : Check If Invoice Group not exists
 **/ 
global with sharing class GroupInvoicePaymentScanBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public String query;
    public static Map<String, string> paymentGroupFieldNameLabels;
    public final Boolean doPaymentGroupSynchro;
    public final List<String> paymentGroupIds;
    
    /* Constructor */
    public GroupInvoicePaymentScanBatch(String startedFrom, Boolean doSynchro, List<Id> ids) {
        
        this.nb = new NegoptimBatch('GroupInvoicePaymentScanBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        doPaymentGroupSynchro = doSynchro;
        paymentGroupIds = ids;
        
        String q = 'SELECT Id, Name, Invoice_year__c, Invoice_Date__c, Invoice_Number__c, ';
        q += 'Payment_Date__c, Invoice_Amount__c, Origin_Supplier_Code__c, Detail_Integration_Status__c, ';
        q += 'Invoice_Reference__c, Status__c, Error_desc__c, Warning_Desc__c, Action_ToDo__c, Action_Done__c, Last_Scan_Date__c, ';
        q += 'Invoice_Editor_Site_code__c, Payment_Editor_Site_code__c, Payment_Mode_Code__c, ';
        q += 'Payment_Nature_Code__c, Payment_term__c, Payment_Number__c, Payment_Batch_Number__c ';
        q += 'FROM Invoice_Payment_Group__c ';
        q += 'WHERE (Invoice_Reference__c = NULL OR Status__c = \'New\') ';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        q += ' Order By Invoice_Number__c, Payment_Mode_Code__c ';   
        query = q;
        // push inputs to log
        nb.logParameter('doPaymentGroupSynchro', this.doPaymentGroupSynchro);
        nb.logParameter('paymentGroupIds', paymentGroupIds);
        nb.logParameter('query', this.query);
    }
    
    /* Start method implementation.*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    /* Execute method execute.*/
    public void execute(Database.BatchableContext bc, List<Invoice_Payment_Group__c> scope) {
        /* 1. Prepare Declaration. */
        // List of Id
        Set<Id> paymentIdSet = new Set<Id>();
        // Map between Invoice Number and  List of Invoice Group Payment object
        Map<String, List<Invoice_Payment_Group__c>> paymentGroupMap = new Map<String, List<Invoice_Payment_Group__c>>();
        // List of invoices group payment to Update.
        List<Invoice_Payment_Group__c> invoicePaymentGroupList = new List<Invoice_Payment_Group__c>();
        // Map between Invoice Number and WrapperInvoicePaymentGroup
        Map<String, WrapperInvoicePaymentGroup> paymentLineMap = new Map<String, WrapperInvoicePaymentGroup>();
        // List of wrapper invoice payment detail
        List<WrapperPaymentLine> wPaymentLineList = new List<WrapperPaymentLine>();
        // Map<key, Invoice Group>
        Map<String, Invoice_Group__c> invoiceGroupMap = new Map<String, Invoice_Group__c>();
        // Describe all fields for Invoice_Payment_Group__c.
        paymentGroupFieldNameLabels = NegoptimHelper.GetMandatoryFieldLabels(Invoice_Payment_Group__c.SObjectType);
        
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on read payment group fields
            String[] paymentGroupAccessFields = new String[] { 'Id', 'Name', NegoptimHelper.normalizeAPIName('Invoice_year__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Date__c'), NegoptimHelper.normalizeAPIName('Invoice_Number__c'), 
                NegoptimHelper.normalizeAPIName('Payment_Date__c'), NegoptimHelper.normalizeAPIName('Invoice_Amount__c'),
                NegoptimHelper.normalizeAPIName('Origin_Supplier_Code__c'), NegoptimHelper.normalizeAPIName('Detail_Integration_Status__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Reference__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Error_desc__c'), NegoptimHelper.normalizeAPIName('Warning_Desc__c'),
                NegoptimHelper.normalizeAPIName('Action_ToDo__c'), NegoptimHelper.normalizeAPIName('Action_Done__c'),
                NegoptimHelper.normalizeAPIName('Last_Scan_Date__c'), NegoptimHelper.normalizeAPIName('Invoice_Editor_Site_code__c'),
                NegoptimHelper.normalizeAPIName('Payment_Editor_Site_code__c'), NegoptimHelper.normalizeAPIName('Payment_Mode_Code__c'),
                NegoptimHelper.normalizeAPIName('Payment_Nature_Code__c'), NegoptimHelper.normalizeAPIName('Payment_term__c'),
                NegoptimHelper.normalizeAPIName('Payment_Number__c'), NegoptimHelper.normalizeAPIName('Payment_Batch_Number__c')};
                    
            // check security on read invoice group fields
            String[] invoiceGroupAccessFields = new String[] { 'Id', 'Name',NegoptimHelper.normalizeAPIName('Invoice_Linked__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Number__c'), NegoptimHelper.normalizeAPIName('Invoice_Date__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Editor_Site_code__c'), NegoptimHelper.normalizeAPIName('Origin_Supplier_Code__c')};

            /* 2. Prepare Load Data. */
            for(Invoice_Payment_Group__c item : scope){
                // Fill list of Id
                paymentIdSet.add(item.Id);
                // Fill Map Payment Group
                if(item.Invoice_Number__c != null){
                    if(paymentGroupMap.containsKey(item.Invoice_Number__c)){
                        if(item.Payment_Mode_Code__c == '8')
                            paymentGroupMap.get(item.Invoice_Number__c).add(0, item);
                        else
                            paymentGroupMap.get(item.Invoice_Number__c).add(item);
                    }
                    else{
                        paymentGroupMap.put(item.Invoice_Number__c, new List<Invoice_Payment_Group__c>{ item });
                    }
                }
                else{
                    WrapperPaymentLine wline= new WrapperPaymentLine(item);
                    // Check Mandatory Fields.
                    wline.CheckMandatoryFields();
                    wline.paymentGroup.Error_desc__c = wline.errorDescMessage;
                    wline.paymentGroup.Status__c = 'Rejected';
                    wPaymentLineList.add(wline);
                }
            }
            
            // Fill Invoice Group Map
            if(NegoptimHelper.checkAccessibility(Invoice_Group__c.SObjectType, invoiceGroupAccessFields)){
                for(Invoice_Group__c item : [SELECT Id, Name, Invoice_Linked__c, Invoice_Number__c, Invoice_Date__c,
                                             Invoice_Editor_Site_code__c, Origin_Supplier_Code__c
                                             FROM Invoice_Group__c
                                             WHERE Invoice_Number__c <> NULL AND Invoice_Date__c <> NULL
                                             AND Invoice_Editor_Site_code__c <> NULL AND Origin_Supplier_Code__c <> NULL
                                             AND Invoice_Number__c IN :paymentGroupMap.keySet()]) 
                {
                    String key = item.Invoice_Number__c + item.Invoice_Editor_Site_code__c + item.Invoice_Date__c.year() + + item.Origin_Supplier_Code__c;
                    if(!invoiceGroupMap.containsKey(key)) {
                        invoiceGroupMap.put(key, item);
                    }
                }
            }            
            
            // Fill Payment Group Wrapper
            for(Invoice_Payment_Group__c item : [SELECT Id, Name, Invoice_year__c, Invoice_Date__c, Invoice_Number__c,
                                                 Payment_Date__c, Invoice_Amount__c, Origin_Supplier_Code__c, Detail_Integration_Status__c,
                                                 Invoice_Reference__c, Status__c, Error_desc__c, Warning_Desc__c, Action_ToDo__c, Action_Done__c, Last_Scan_Date__c,
                                                 Invoice_Editor_Site_code__c, Payment_Editor_Site_code__c, Payment_Mode_Code__c,
                                                 Payment_Nature_Code__c, Payment_term__c, Payment_Number__c, Payment_Batch_Number__c
                                                 FROM Invoice_Payment_Group__c
                                                 WHERE Status__c <> 'New'
                                                 AND Invoice_Number__c IN :paymentGroupMap.keySet()
                                                 AND Id NOT IN :paymentIdSet])
            {
                WrapperInvoicePaymentGroup wPaymentGroup;
                if(paymentLineMap.containsKey(item.Invoice_Number__c)) {
                    wPaymentGroup = paymentLineMap.get(item.Invoice_Number__c);                                                     
                }
                else{
                    wPaymentGroup = new WrapperInvoicePaymentGroup(item.Invoice_Number__c);
                    paymentLineMap.put(item.Invoice_Number__c, wPaymentGroup);
                }
                if(!wPaymentGroup.isSynchronized && (item.Status__c == 'Synchronized' || item.Status__c == 'Validated') && item.Payment_Mode_Code__c != '3' && item.Payment_Mode_Code__c != '8' && item.Payment_Mode_Code__c != '9'){
                    wPaymentGroup.isSynchronized = true;
                }
                if(!wPaymentGroup.paymentModeCodeMap.containsKey(item.Payment_Mode_Code__c)){
                    wPaymentGroup.paymentModeCodeMap.put(item.Payment_Mode_Code__c, item);
                }
            }
                
            /* 3. Prepare Scan Process. */
            if(NegoptimHelper.checkAccessibility(Invoice_Payment_Group__c.SObjectType, paymentGroupAccessFields) && 
               NegoptimHelper.checkAccessibility(Invoice_Group__c.SObjectType, invoiceGroupAccessFields))
            {
                for(String invKey : paymentGroupMap.keySet()) {
                    WrapperInvoicePaymentGroup wPaymentGroup;
                    if(paymentLineMap.containsKey(invKey)){
                        wPaymentGroup = paymentLineMap.get(invKey);                
                    }
                    else {
                        wPaymentGroup = new WrapperInvoicePaymentGroup(invKey);
                    }
                    for(Invoice_Payment_Group__c item : paymentGroupMap.get(invKey)){
                        WrapperPaymentLine wline= new WrapperPaymentLine(item);
                        // INTEGRITY CONTROL: a- Check Mandatory fields
                        wline.CheckMandatoryFields();
                        if(!wline.scanIsValid) {
                            // Error
                        }
                        // INTEGRITY CONTROL: b- Check Warning fields
                        wline.CheckWarningFields();
                        // Check if all payment is rejected for the same invoice number
                        if(wPaymentGroup.isRejected){
                            wline.scanIsValid = false;
                            wline.actionDoneMessage += wPaymentGroup.rejectedMessage + '\n';
                        }
                        else{
                            // Check if payment line exist
                            if(wPaymentGroup.paymentModeCodeMap.size() > 0){
                                // Case 0: if exist line synchronized other for payment code=8,9
                                if(wPaymentGroup.isSynchronized){
                                    wline.scanIsValid = false;
                                    wline.actionToDoMessage += Label.MSG_Payment_Cant_Applied_Already_Recovered_Invoice + '\n';
                                    wPaymentGroup.isRejected = true;
                                    wPaymentGroup.rejectedMessage = Label.MSG_Payment_Cant_Applied_Already_Recovered_Invoice;
                                }
                                // if exist line not synchro and not deleted
                                else if(wline.isValidLine){
                                    // Case 1: if line with payment code=8
                                    if(item.Payment_Mode_Code__c == '8'){
                                        wline.scanInvoice = true;
                                    }
                                    // Case 2: if line with payment code=9
                                    else if(item.Payment_Mode_Code__c == '9'){
                                        if(wPaymentGroup.isExistCM){
                                            wline.scanInvoice = true;
                                        }
                                        else{
                                            wline.paymentGroup.Status__c = 'Temporary blocked';
                                            wline.actionDoneMessage += Label.MSG_CM_Requiered + '\n';
                                            wPaymentGroup.isTemporaryblocked = true;
                                        }
                                    }
                                    // Case 3: if line with payment code=7,6,4
                                    else if(item.Payment_Mode_Code__c == '7' ||  item.Payment_Mode_Code__c == '6' || item.Payment_Mode_Code__c == '4'){
                                        if((wPaymentGroup.isExistCM && wPaymentGroup.isExistCR) || (!wPaymentGroup.isExistCM && !wPaymentGroup.isExistCR)){
                                            if(wPaymentGroup.isTemporaryblocked){
                                                wline.paymentGroup.Status__c = 'Temporary blocked';
                                                wline.actionDoneMessage += Label.MSG_Validated_CR_Requiered + '\n';
                                            }
                                            else{
                                                wline.scanInvoice = true;
                                            }
                                        }
                                        else{
                                            wline.paymentGroup.Status__c = 'Temporary blocked';
                                            wline.actionDoneMessage += Label.MSG_CM_AND_CR_Requiered + '\n';
                                            wPaymentGroup.isRejected = true;
                                            wPaymentGroup.rejectedMessage = Label.MSG_Payment_Already_Exist;
                                        }
                                    }
                                    // Case 4: if line with payment code=3
                                    else if(item.Payment_Mode_Code__c == '3'){
                                        wline.scanInvoice = true;
                                    }
                                    // Case 5: if line with payment code=5
                                    else {
                                        wline.scanInvoice = true;
                                    }
                                }
                            }
                            else {
                                wline.scanInvoice = true;
                            }
                        }
                        // DATA MAPPING: 1- Invoice Control : Check If Invoice Group Reference not exists
                        if(wline.scanInvoice){
                            wline.scanInvoicePaymentGroup(invoiceGroupMap);
                        }
                        // Check status after scan payment
                        if(wline.scanInvoice){
                            if(!wline.scanIsValid){
                                // Update all next payment status = 'Rejected'
                                if(item.Payment_Mode_Code__c == '8'){
                                    wPaymentGroup.isRejected = true;
                                    wPaymentGroup.rejectedMessage = Label.MSG_Payment_CM_Rejected;
                                }
                                if(wline.paymentGroup.Payment_Mode_Code__c == '9' && wPaymentGroup.isExistCM){
                                    wPaymentGroup.isRejected = true;
                                    wPaymentGroup.rejectedMessage = Label.MSG_Payment_CR_Rejected;
                                }
                            }
                            // check if current payment line is validated
                            if(!wPaymentGroup.isSynchronized && wline.paymentGroup.Status__c == 'Validated' && item.Payment_Mode_Code__c != '3' && 
                               item.Payment_Mode_Code__c != '8' && item.Payment_Mode_Code__c != '9'){
                                   wPaymentGroup.isSynchronized = true;
                               }
                            // Update previous payment with status = 'Validated'
                            if(wline.paymentGroup.Status__c == 'Validated' && (item.Payment_Mode_Code__c == '8' || item.Payment_Mode_Code__c == '9')){
                                if(wPaymentGroup.paymentModeCodeMap.size() > 0){
                                    for(Invoice_Payment_Group__c prvPaymentGroup: wPaymentGroup.paymentModeCodeMap.values()){
                                        if(item.Payment_Mode_Code__c == '9' && prvPaymentGroup.Payment_Mode_Code__c == '8' && prvPaymentGroup.Status__c == 'Rejected'){
                                            continue;
                                        }
                                        if(!wPaymentGroup.isSynchronized && prvPaymentGroup.Status__c == 'Rejected'){
                                            WrapperPaymentLine prvline= new WrapperPaymentLine(prvPaymentGroup);
                                            prvline.CheckMandatoryFields();
                                            if(!prvline.scanIsValid) {
                                                // Error
                                            }
                                            // INTEGRITY CONTROL: b- Check Warning fields
                                            prvline.CheckWarningFields();
                                            prvline.scanInvoice = true;
                                            prvline.scanInvoicePaymentGroup(invoiceGroupMap);
                                            if(!prvline.scanIsValid) prvline.paymentGroup.Status__c = 'Rejected';
                                            prvline.paymentGroup.Error_desc__c = prvline.errorDescMessage;
                                            prvline.paymentGroup.Warning_Desc__c = prvline.warningDescMessage;
                                            prvline.paymentGroup.Action_ToDo__c = prvline.actionToDoMessage;
                                            prvline.paymentGroup.Action_done__c = prvline.actionDoneMessage;
                                            prvline.paymentGroup.Last_Scan_Date__c = System.now();
                                            wPaymentLineList.add(prvline);
                                            // check if payment line is validated
                                            if(prvline.paymentGroup.Status__c == 'Validated' && prvline.paymentGroup.Payment_Mode_Code__c != '3' && 
                                               prvline.paymentGroup.Payment_Mode_Code__c != '8' && prvline.paymentGroup.Payment_Mode_Code__c != '9'){
                                                   wPaymentGroup.isSynchronized = true;
                                               }
                                        }
                                    }
                                }
                            }
                        }
                        if(!wline.scanIsValid) wline.paymentGroup.Status__c = 'Rejected';
                        wline.paymentGroup.Error_desc__c = wline.errorDescMessage;
                        wline.paymentGroup.Warning_Desc__c = wline.warningDescMessage;
                        wline.paymentGroup.Action_ToDo__c = wline.actionToDoMessage;
                        wline.paymentGroup.Action_done__c = wline.actionDoneMessage;
                        wline.paymentGroup.Last_Scan_Date__c = System.now();
                        // Fill Payment Line Wrapper
                        if(!paymentLineMap.containsKey(item.Invoice_Number__c)){
                            paymentLineMap.put(item.Invoice_Number__c, wPaymentGroup);
                        }
                        if(!wPaymentGroup.paymentModeCodeMap.containsKey(item.Payment_Mode_Code__c)){
                            wPaymentGroup.paymentModeCodeMap.put(item.Payment_Mode_Code__c, wline.paymentGroup);
                        }
                        wPaymentLineList.add(wline);
                    }
                }
            }
            String[] paymentGroupUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Reference__c'), NegoptimHelper.normalizeAPIName('Error_desc__c'),
                NegoptimHelper.normalizeAPIName('Warning_Desc__c'), NegoptimHelper.normalizeAPIName('Action_ToDo__c'),
                NegoptimHelper.normalizeAPIName('Action_done__c'), NegoptimHelper.normalizeAPIName('Last_Scan_Date__c')};                        
                                       
            if(NegoptimHelper.checkUpdatibility(Invoice_Payment_Group__c.SObjectType, paymentGroupUpdateFields)){
                for (WrapperPaymentLine item : wPaymentLineList) {                
                    invoicePaymentGroupList.add(item.paymentGroup);
                }
                // Update invoice payment group
                if(invoicePaymentGroupList != null && invoicePaymentGroupList.size() > 0){
                    List<Database.SaveResult> results = Database.update(invoicePaymentGroupList, false);
                    nb.logResults(results, invoicePaymentGroupList);
                }
            }
        }
        catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        }
        catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        if(doPaymentGroupSynchro) {
            Database.executeBatch(new GroupInvoicePaymentSynchroBatch('GroupInvoicePaymentScanBatch', doPaymentGroupSynchro, paymentGroupIds));            
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper Class for Invoice Payment Group */
    public class WrapperInvoicePaymentGroup {
        public String invoiceNumber {get; set;}
        public Map<String, Invoice_Payment_Group__c> paymentModeCodeMap {get; set;}
        public Boolean isSynchronized {get; set;}
        public Boolean isRejected {get; set;}
        public Boolean isTemporaryblocked {get; set;}
        public String rejectedMessage {get; set;}
        public WrapperInvoicePaymentGroup(String invNumber) {
            invoiceNumber = invNumber;
            paymentModeCodeMap= new Map<String, Invoice_Payment_Group__c>();
            isSynchronized = false;
            isRejected = false;
            isTemporaryblocked = false;
            rejectedMessage = '';
        }
        public Boolean isExistCM {
            get {                
                return paymentModeCodeMap.containsKey('8') && paymentModeCodeMap.get('8').Status__c != 'Deleted';
            }
            set;
        }
        public Boolean isExistCR {
            get {                
                return paymentModeCodeMap.containsKey('9') && paymentModeCodeMap.get('9').Status__c != 'Deleted';
            }
            set;
        }
    }
    
    /* Wrapper Class for Payment Line */
    public class WrapperPaymentLine {
        Invoice_Payment_Group__c paymentGroup {get; set;}
        Boolean scanInvoice {get; set;}
        Boolean scanIsValid {get; set;}
        String errorDescMessage {get; set;}
        String warningDescMessage {get; set;}
        String actionToDoMessage {get; set;}
        String actionDoneMessage {get; set;}
        public WrapperPaymentLine(Invoice_Payment_Group__c payment) {
            paymentGroup = payment;
            scanInvoice = false;
            scanIsValid = true;
            errorDescMessage = '';
            warningDescMessage = '';
            actionToDoMessage = '';
            actionDoneMessage = '';
        }
        public Boolean isValidLine {
            get {
                return paymentGroup.Status__c != 'Synchronized' && paymentGroup.Status__c != 'Deleted';
            }
            set;
        }
        // Check Warning fields
        public void CheckWarningFields() {
            // INTEGRITY CONTROL: b- Check Warning fields
            if(paymentGroup.Payment_Batch_Number__c == null){
                this.warningDescMessage += Label.MSG_Invoice_Chrono_Not_Exist + '\n';
            }
        }
        // scan payment group
        public void scanInvoicePaymentGroup(Map<String, Invoice_Group__c> invoiceGroupMap) {
            String key = '';
            if(paymentGroup.Invoice_Number__c != null && paymentGroup.Invoice_Editor_Site_code__c != null && paymentGroup.Invoice_Date__c != null && paymentGroup.Origin_Supplier_Code__c != null){
                key = paymentGroup.Invoice_Number__c + paymentGroup.Invoice_Editor_Site_code__c + paymentGroup.Invoice_Date__c.year() + paymentGroup.Origin_Supplier_Code__c;
            }
            if(paymentGroup.Invoice_Reference__c == null && paymentGroup.Status__c != 'Deleted' && String.IsNotBlank(key)){
                if(!invoiceGroupMap.containsKey(key)){
                    this.actionToDoMessage += string.format(Label.MSG_Invoice_Not_Exist, new String[]{ paymentGroup.Name }) + '\n';
                    if(this.scanInvoice && paymentGroup.Payment_Mode_Code__c != '5') this.scanIsValid = false;
                }
                else if(invoiceGroupMap.containsKey(key) && String.IsBlank(invoiceGroupMap.get(key).Invoice_Linked__c)){
                    paymentGroup.Invoice_Reference__c = invoiceGroupMap.get(key).Id;
                    this.actionToDoMessage += string.format(Label.MSG_Invoice_Not_Linked, new String[]{ paymentGroup.Name }) + '\n';
                    if(this.scanInvoice && paymentGroup.Payment_Mode_Code__c != '5') this.scanIsValid = false;
                }
                else{
                    paymentGroup.Invoice_Reference__c = invoiceGroupMap.get(key).Id;
                    this.actionDoneMessage += string.format(Label.MSG_Payment_Linked_To_Invoice, new String[]{ paymentGroup.Name, invoiceGroupMap.get(key).Name }) + '\n';
                    if(this.scanInvoice && paymentGroup.Payment_Mode_Code__c != '5') paymentGroup.Status__c = 'Validated';
                }
            }
            else {
                if(this.scanInvoice && paymentGroup.Payment_Mode_Code__c != '5') paymentGroup.Status__c = 'Validated';
            }
            if(this.scanInvoice && paymentGroup.Payment_Mode_Code__c == '5') paymentGroup.Status__c = 'Deleted';
        }
        // Check Mandatory Fields
        public void CheckMandatoryFields() {
            if(paymentGroup.Invoice_Editor_Site_code__c == null || paymentGroup.Payment_Editor_Site_code__c == null ||
               paymentGroup.Invoice_Date__c == null || paymentGroup.Invoice_Number__c == null ||
               paymentGroup.Payment_Date__c == null || paymentGroup.Invoice_Amount__c == null || paymentGroup.Payment_Mode_Code__c == null ||             
               paymentGroup.Payment_Nature_Code__c == null || paymentGroup.Payment_term__c == null || paymentGroup.Origin_Supplier_Code__c == null ||
               paymentGroup.Detail_Integration_Status__c == null || paymentGroup.Payment_Number__c == null || paymentGroup.Payment_Batch_Number__c == null)
            {
                if(paymentGroup.Invoice_Editor_Site_code__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Invoice_Editor_Site_code__c') }) + '\n';                
                if(paymentGroup.Payment_Editor_Site_code__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Payment_Editor_Site_code__c') }) + '\n';                
                if(paymentGroup.Invoice_Date__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Invoice_Date__c') }) + '\n';                
                if(paymentGroup.Invoice_Number__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Invoice_Number__c') }) + '\n';               
                if(paymentGroup.Payment_Date__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Payment_Date__c') }) + '\n';
                if(paymentGroup.Invoice_Amount__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Invoice_Amount__c') }) + '\n';
                if(paymentGroup.Payment_Mode_Code__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Payment_Mode_Code__c') }) + '\n';
                if(paymentGroup.Payment_Nature_Code__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Payment_Nature_Code__c') }) + '\n';
                if(paymentGroup.Payment_term__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Payment_term__c') }) + '\n';           
                if(paymentGroup.Origin_Supplier_Code__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Origin_Supplier_Code__c') }) + '\n';
                if(paymentGroup.Detail_Integration_Status__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Detail_Integration_Status__c') }) + '\n';
                if(paymentGroup.Payment_Number__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Payment_Number__c') }) + '\n';
                if(paymentGroup.Payment_Batch_Number__c == null) errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ paymentGroupFieldNameLabels.get('Payment_Batch_Number__c') }) + '\n';
                this.scanIsValid = false;
            }
        }
    }
}