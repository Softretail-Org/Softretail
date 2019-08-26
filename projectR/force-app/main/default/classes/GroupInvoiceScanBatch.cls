/**
 * Batchable class used to scan invoices group
 * Case Criteria: (Status__c <> \'Synchronized\' AND Status__c <> \'Synchronized without Condition\')
 *             OR (Status__c = \'Synchronized without Condition\' AND CreatedDate > :selectedDate)
 * INTEGRITY CONTROL: 
 * a- Check Mandatory fields
 * b- Check Warning fields
 * DATA MAPPING:
 * 1- Supplier Control : Check If Supplier not exists OR Supplier Code is not in Group Contract OR not linked to a BU Supplier
 * 2- Contract Control: Check if Contract not exists OR contract code is not in group contract OR not linked to a BU contract
 * 3- Conditions Control: Check if Condition not exists OR condition line is not in group contract detail or not linked to a BU contract line
 **/
global with sharing class GroupInvoiceScanBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    private String query;
    public final Date selectedDate;
    public static Map<String, string> invoiceGroupFieldNameLabels;
    public final Boolean doInvoiceGroupSynchro;
    public final List<String> invoiceGroupIds;
    
    /* Constructor */
    public GroupInvoiceScanBatch(String startedFrom, Boolean doSynchro, List<Id> ids, Date d) {
        
        this.nb = new NegoptimBatch('GroupInvoiceScanBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        selectedDate = d;
        doInvoiceGroupSynchro = doSynchro;
        invoiceGroupIds = ids;
        String q = 'SELECT Id, Name, Document_type__c, Invoice_Year__c, Invoice_Date__c, Invoice_Due_Date__c, ';
        q += 'Invoice_Number__c, Origin_Condition_Line__c, Origin_Contract_Number__c, Header_Integration_Status__c, ';
        q += 'Inv_batch_Chrono__c, Amount_wo_Tax__c, Amount_w_Tax__c, Warning_Desc__c, Origin_Stock_Owner__c, Stock_Owner__c, ';
        q += 'Supplier__c, Supplier__r.Code__c, Origin_Supplier_Code__c, Contract_reference__c, Condition_Reference__c, ';
        q += 'Action_ToDo__c, Action_done__c, Error_desc__c, Status__c, Last_Scan_Date__c, Invoice_Batch_Number__c ';
        q += 'FROM Invoice_Group__c ';
        q += 'WHERE ((Status__c <> \'Synchronized\' AND Status__c <> \'Synchronized without Condition\')';
        q += selectedDate != null ? ' OR (Status__c = \'Synchronized without Condition\' AND CreatedDate > :selectedDate))' : ')';
        if(ids != null && ids.size() > 0) {
            q += ' AND Id IN (\'' + String.join(ids, '\',\'') +'\') ';
        }
        query = q;
        // push inputs to log
        nb.logParameter('doInvoiceGroupSynchro', this.doInvoiceGroupSynchro);
        nb.logParameter('invoiceGroupIds', this.invoiceGroupIds);
        nb.logParameter('selectedDate', this.selectedDate);
        nb.logParameter('query', this.query);
    }
    
    /* Start method implementation.*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    /* Execute method implementation.*/
    public void execute(Database.BatchableContext bc, List<Invoice_Group__c> scope) {        
        /* 1. Prepare Declaration. */
        Set<String> originSupplierCodeSet = new Set<String>();
        Set<String> originContractNumberSet = new Set<String>();
        Set<String> originConditionLineSet = new Set<String>();
        // List of Origin supplier code
        Set<String> originStockOwnerSet = new Set<String>();
        // Map<Origin_Stock_owner__c, Orga_BU__c DataBase>.
        Map<String, Orga_BU__c> originStockOwnerMap = new Map<String, Orga_BU__c>();
        // Map<Origin Supplier Code, Contract_Group__c>
        Map<String, Contract_Group__c> supContractGroupMap = new Map<String, Contract_Group__c>();
        // Map<Origin Contract Number, Contract_Group__c>
        Map<String, Contract_Group__c> originContractNumberMap = new Map<String, Contract_Group__c>();
        // Map between key = (Origin Contract Number + Origin Condition Number) and group contract detail
        Map<String, Contract_Group_Detail__c> originConditionLineMap = new Map<String, Contract_Group_Detail__c>();
        // List of invoices to Update.
        List<Invoice_Group__c> invoiceGroupList = new List<Invoice_Group__c>();
        // List of wrapper invoice group
        List<WrapperInvoiceGroupLine> wInvoiceGroupList = new List<WrapperInvoiceGroupLine>();
        // Describe all fields for Invoice_Group__c.
        invoiceGroupFieldNameLabels = NegoptimHelper.GetMandatoryFieldLabels(Invoice_Group__c.SObjectType);

        Savepoint sp = Database.setSavepoint();
        try {
            // check security on read invoice group fields
            String[] invoiceGroupAccessFields = new String[] { 'Id', 'Name',NegoptimHelper.normalizeAPIName('Document_type__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Year__c'), NegoptimHelper.normalizeAPIName('Invoice_Date__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Due_Date__c'), NegoptimHelper.normalizeAPIName('Invoice_Number__c'),
                NegoptimHelper.normalizeAPIName('Origin_Condition_Line__c'), NegoptimHelper.normalizeAPIName('Origin_Contract_Number__c'),
                NegoptimHelper.normalizeAPIName('Header_Integration_Status__c'), NegoptimHelper.normalizeAPIName('Inv_batch_Chrono__c'),
                NegoptimHelper.normalizeAPIName('Amount_wo_Tax__c'), NegoptimHelper.normalizeAPIName('Amount_w_Tax__c'),
                NegoptimHelper.normalizeAPIName('Warning_Desc__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                NegoptimHelper.normalizeAPIName('Origin_Supplier_Code__c'), NegoptimHelper.normalizeAPIName('Contract_reference__c'),
                NegoptimHelper.normalizeAPIName('Condition_Reference__c'), NegoptimHelper.normalizeAPIName('Action_ToDo__c'),
                NegoptimHelper.normalizeAPIName('Action_done__c'), NegoptimHelper.normalizeAPIName('Error_desc__c'),
                NegoptimHelper.normalizeAPIName('Status__c'), NegoptimHelper.normalizeAPIName('Last_Scan_Date__c'),
                NegoptimHelper.normalizeAPIName('Invoice_Batch_Number__c'), NegoptimHelper.normalizeAPIName('Origin_Stock_Owner__c'),
                NegoptimHelper.normalizeAPIName('Stock_Owner__c')};
            
            // check security on read contract group fields
            String[] contractGroupAccessFields = new String[] {'Id', NegoptimHelper.normalizeAPIName('Contract_Number__c'),
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Origin_Supplier_Code__c'),
                NegoptimHelper.normalizeAPIName('Contract_linked__c')};
            
            // check security on read condition group fields
            String[] conditionGroupAccessFields = new String[] {'Id', NegoptimHelper.normalizeAPIName('Origin_Disc_Code2__c'),
                NegoptimHelper.normalizeAPIName('Condition_Linked__c')};
            
            /* 2. Prepare Load Data. */
            for(Invoice_Group__c item : scope) {
                // Fill supplier code list
                if(String.IsNotBlank(item.Origin_Supplier_Code__c)){
                    originSupplierCodeSet.add(item.Origin_Supplier_Code__c);
                }
                // Fill origine contract number list
                if(String.IsNotBlank(item.Origin_Contract_Number__c)){
                    originContractNumberSet.add(item.Origin_Contract_Number__c);
                }
                // Fill origine condition number list
                if(String.IsNotBlank(item.Origin_Condition_Line__c)){
                    if(String.ValueOf(item.Origin_Condition_Line__c).isNumeric()){
                        originConditionLineSet.add(String.valueOf(Integer.valueof(item.Origin_Condition_Line__c)));
                    }
                    else{
                        originConditionLineSet.add(item.Origin_Condition_Line__c);
                    }
                }
                // Fill all stock owner code
                if(String.isNotBlank(item.Origin_Stock_owner__c)) {
                    originStockOwnerSet.add(item.Origin_Stock_owner__c);
                } else {
                    originStockOwnerSet.add(null);
                }
            }
            
            if(NegoptimHelper.checkAccessibility(Contract_Group__c.SObjectType, contractGroupAccessFields) &&
               NegoptimHelper.checkAccessibility(Contract_Group_Detail__c.SObjectType, conditionGroupAccessFields))
            {
                for(Contract_Group__c item : [SELECT Id, Name, Contract_Number__c, Supplier__c, Origin_Supplier_Code__c, Supplier__r.Code__c, Contract_linked__c,
                                              (SELECT Id, Name, Origin_Disc_Code2__c, Condition_Linked__c FROM Group_Contract_Details__r)
                                              FROM Contract_Group__c
                                              WHERE (Origin_Supplier_Code__c IN :originSupplierCodeSet OR Contract_Number__c IN :originContractNumberSet)
                                              AND Status__c <> 'New'
                                              ORDER BY End_date__c DESC])
                {
                    if(originSupplierCodeSet.contains(item.Origin_Supplier_Code__c) && !supContractGroupMap.containsKey(item.Origin_Supplier_Code__c)) {
                        supContractGroupMap.put(item.Origin_Supplier_Code__c, item);
                    }
                    if(originContractNumberSet.contains(item.Contract_Number__c)) {
                        // Fill contracts group
                        if(!originContractNumberMap.containsKey(item.Contract_Number__c)){
                            originContractNumberMap.put(item.Contract_Number__c, item);
                        }
                        // Fill conditions related to contract group              
                        for(Contract_Group_Detail__c condition : item.Group_Contract_Details__r){
                            if(String.IsNotBlank(condition.Origin_Disc_Code2__c)){
                                String originDiscCode = String.ValueOf(condition.Origin_Disc_Code2__c).isNumeric() ? 
                                    String.valueOf(Integer.valueof(condition.Origin_Disc_Code2__c)) : condition.Origin_Disc_Code2__c;
                                if(originConditionLineSet.contains(originDiscCode)){
                                    String key = item.Contract_Number__c + originDiscCode;
                                    if(!originConditionLineMap.containsKey(key)){                        
                                        originConditionLineMap.put(key, condition);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Get all stock owner
            if(!originStockOwnerSet.isEmpty()) {
                // Single Instance of BusinessUnitHelper
                BusinessUnitHelper buHelper = BusinessUnitHelper.getInstance(null, null);
                originStockOwnerMap = buHelper.getBUByExtIds(originStockOwnerSet, 'Warehouse');
            }
            
            /* 3. Prepare Scan Process. */
            if(NegoptimHelper.checkAccessibility(Invoice_Group__c.SObjectType, invoiceGroupAccessFields) &&
               NegoptimHelper.checkAccessibility(Contract_Group__c.SObjectType, contractGroupAccessFields) &&
               NegoptimHelper.checkAccessibility(Contract_Group_Detail__c.SObjectType, conditionGroupAccessFields))
            {
                for(Invoice_Group__c item : scope) {
                    WrapperInvoiceGroupLine wline = new WrapperInvoiceGroupLine(item);
                    // INTEGRITY CONTROL: a- Check Mandatory fields
                    wline.CheckMandatoryFields();
                    if(!wline.scanIsValid) {
                        // Error
                    }
                    // INTEGRITY CONTROL: b- Check Warning fields
                    wline.CheckWarningFields();
                    // DATA MAPPING : Check Supplier, Contract Group and Contract Group Detail
                    if(supContractGroupMap.containsKey(item.Origin_Supplier_Code__c)) {
                        wline.refSuppLierCG = supContractGroupMap.get(item.Origin_Supplier_Code__c);
                    }
                    if(originContractNumberMap.containsKey(item.Origin_Contract_Number__c)) {
                        wline.refContractGroup = originContractNumberMap.get(item.Origin_Contract_Number__c);
                    }
                    if(wline.refContractGroup != null && item.Origin_Condition_Line__c != null) {
                        String originConditionLine = String.ValueOf(item.Origin_Condition_Line__c).isNumeric() ? 
                            String.valueOf(Integer.valueof(item.Origin_Condition_Line__c)) : item.Origin_Condition_Line__c;
                        String key = item.Origin_Contract_Number__c + originConditionLine;
                        if(originConditionLineMap.containsKey(key)){
                            wline.refContractGroupDetail = originConditionLineMap.get(key);
                        }
                    }
                    // get stock owner
                    if(originStockOwnerMap.containsKey(item.Origin_Stock_owner__c)) {
                        wline.refStockOwner = originStockOwnerMap.get(item.Origin_Stock_owner__c);
                    }
                    // Scan Invoice Group
                    wline.scanInvoiceGroup();
                    // Fill Scan Results
                    if(!wline.scanIsValid) {
                        wline.invoiceGroup.Status__c = 'Rejected';
                    }
                    else{
                        wline.invoiceGroup.Status__c = 'Validated';
                    }
                    wline.invoiceGroup.Error_desc__c = wline.errorDescMessage;
                    wline.invoiceGroup.Warning_Desc__c = wline.warningDescMessage;
                    wline.invoiceGroup.Action_ToDo__c = wline.actionToDoMessage;
                    wline.invoiceGroup.Action_done__c = wline.actionDoneMessage;
                    wline.invoiceGroup.Last_Scan_Date__c = System.now();
                    wInvoiceGroupList.add(wline);
                }
            }
            // check security on update invoice group fields
            String[] invoiceGroupUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Contract_reference__c'),
                NegoptimHelper.normalizeAPIName('Condition_reference__c'), NegoptimHelper.normalizeAPIName('Error_desc__c'),
                NegoptimHelper.normalizeAPIName('Warning_Desc__c'), NegoptimHelper.normalizeAPIName('Action_ToDo__c'),
                NegoptimHelper.normalizeAPIName('Action_done__c'), NegoptimHelper.normalizeAPIName('Last_Scan_Date__c'),
                NegoptimHelper.normalizeAPIName('Stock_Owner__c')};
           
            if(NegoptimHelper.checkUpdatibility(Invoice_Group__c.SObjectType, invoiceGroupUpdateFields)){
                for (WrapperInvoiceGroupLine item : wInvoiceGroupList) {
                    invoiceGroupList.add(item.invoiceGroup);
                }
                // Update invoice group
                if(invoiceGroupList != null && invoiceGroupList.size() > 0) {
                    List<Database.SaveResult> results = Database.update(invoiceGroupList, false);
                    nb.logResults(results, invoiceGroupList);
                }
            }
        } 
        catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        }
        catch (Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        if(doInvoiceGroupSynchro) {
            Database.executeBatch(new GroupInvoiceSynchroBatch('GroupInvoiceScanBatch', doInvoiceGroupSynchro, invoiceGroupIds));            
        }
        // Get the Job.
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper Class for Invoice Group Line */
    public class WrapperInvoiceGroupLine {
        Invoice_Group__c invoiceGroup {get; set;}
        Contract_Group__c refSuppLierCG {get; set;}
        Contract_Group__c refContractGroup {get; set;}
        Contract_Group_Detail__c refContractGroupDetail {get; set;}
        Orga_BU__c refStockOwner {get; set;}
        String supplierCode {get; set;}
        Boolean scanIsValid {get; set;}
        String errorDescMessage {get; set;}
        String warningDescMessage {get; set;}
        String actionToDoMessage {get; set;}
        String actionDoneMessage {get; set;}
        public WrapperInvoiceGroupLine(Invoice_Group__c invoice) {
            invoiceGroup = invoice;
            refSuppLierCG = null;
            refContractGroup = null;
            refContractGroupDetail = null;
            refStockOwner = null;
            supplierCode = null;
            scanIsValid = true;
            errorDescMessage = '';
            warningDescMessage = '';
            actionToDoMessage = '';
            actionDoneMessage = '';
        }
        // scan invoice group
        public void scanInvoiceGroup() {
            // DATA MAPPING: 1- Supplier Control :
            // Check If Supplier not exists OR Supplier Code is not in Group Contract OR not linked to a Supplier)
            if(invoiceGroup.Supplier__c == null){
                if(String.IsNotBlank(invoiceGroup.Origin_Supplier_Code__c)){
                    if(this.refSuppLierCG == null){
                        this.actionToDoMessage = string.format(Label.MSG_Supplier_code_Not_Exist, new String[]{ invoiceGroup.Origin_Supplier_Code__c }) + '\n';
                        this.scanIsValid = false;
                    }
                    else if(this.refSuppLierCG != null && String.IsBlank(this.refSuppLierCG.Supplier__c)){
                        this.actionToDoMessage += string.format(Label.MSG_Supplier_Not_Linked_BU_Supplier, new String[]{ invoiceGroup.Origin_Supplier_Code__c }) + '\n';
                        this.scanIsValid = false;
                    }
                    else{
                        invoiceGroup.Supplier__c = this.refSuppLierCG.Supplier__c;
                        this.supplierCode = this.refSuppLierCG.Supplier__r.Code__c;
                        this.actionDoneMessage = string.format(Label.MSG_Supplier_BU_Linked_To_Supplier_Code, new String[]{ this.refSuppLierCG.Supplier__r.Code__c, invoiceGroup.Origin_Supplier_Code__c }) + '\n';
                    }
                }
            }
            else {
                this.supplierCode = invoiceGroup.Supplier__r.Code__c;
            }
            // DATA MAPPING: 2- Contract Control:
            // Check if Contract not exists OR contract code is not in group contract OR not linked to a BU contract
            if(this.scanIsValid && invoiceGroup.Contract_reference__c == null){
                if(String.IsNotBlank(invoiceGroup.Origin_Contract_Number__c)){
                    if(this.refContractGroup == null){
                        this.actionToDoMessage += string.format(Label.MSG_Contract_Code_Not_Exist, new String[]{ invoiceGroup.Origin_Contract_Number__c }) + '\n';
                    }
                    else if(this.refContractGroup != null && this.refContractGroup.Supplier__r.Code__c != this.supplierCode){
                        this.actionToDoMessage += string.format(Label.MSG_Contract_Code_Exist_Supplier_Code_Not_Matching, new String[]{ invoiceGroup.Origin_Contract_Number__c, supplierCode }) + '\n';
                        this.scanIsValid = False;
                    }
                    else if(this.refContractGroup != null && String.IsBlank(refContractGroup.Contract_linked__c)){
                        this.actionToDoMessage += string.format(Label.MSG_Contract_Not_Linked_To_BU_Contract, new String[]{ invoiceGroup.Origin_Contract_Number__c }) + '\n';
                    }
                    else{
                        invoiceGroup.Contract_reference__c = this.refContractGroup.Id;
                        this.actionDoneMessage += Label.MSG_Contract_Linked_Automatically + '\n';
                    }
                }
            }
            // DATA MAPPING: 3- Conditions Control:
            // Check if Condition not exists OR condition line is not in group contract detail or not linked to a BU contract line
            if(this.scanIsValid && invoiceGroup.Condition_reference__c == null){
                if(String.IsNotBlank(invoiceGroup.Origin_Condition_Line__c)){
                    if(this.refContractGroupDetail == null){
                        this.actionToDoMessage += string.format(Label.MSG_Contract_Line_Not_Exist, new String[]{ invoiceGroup.Origin_Condition_Line__c }) + '\n';
                    }
                    else if(this.refContractGroupDetail != null && String.IsBlank(refContractGroupDetail.Condition_Linked__c)){
                        this.actionToDoMessage += string.format(Label.MSG_Contract_Line_Not_Linked_To_BU_Contract_Line, new String[]{ invoiceGroup.Origin_Condition_Line__c }) + '\n';
                    }
                    else{
                        invoiceGroup.Condition_reference__c = this.refContractGroupDetail.Id;
                        this.actionDoneMessage += Label.MSG_Contract_Line_Linked_Automatically + '\n';
                    }
                }
            }
            // check stock owner
            if(this.invoiceGroup.Stock_owner__c == null) {
                if(this.refStockOwner == null) {
                    this.scanIsValid = false;
                    this.actionToDoMessage += Label.MSG_Stock_Owner_Not_Found + '\n';
                } else {
                    this.invoiceGroup.Stock_Owner__c = this.refStockOwner.Id;
                }
            }
        }
        // Check Mandatory Fields
        public void CheckMandatoryFields() {
            if(invoiceGroup.Document_type__c == null || invoiceGroup.Invoice_Year__c == null ||
               invoiceGroup.Invoice_Date__c == null || invoiceGroup.Invoice_Due_Date__c == null || 
               invoiceGroup.Invoice_Number__c == null || invoiceGroup.Origin_Condition_Line__c == null || 
               invoiceGroup.Origin_Contract_Number__c == null || invoiceGroup.Origin_Supplier_Code__c == null || 
               invoiceGroup.Header_Integration_Status__c == null || invoiceGroup.Invoice_Batch_Number__c == null) 
            {
                if(invoiceGroup.Document_type__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Document_type__c') }) + '\n';
                if(invoiceGroup.Invoice_Year__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Invoice_Year__c') }) + '\n';               
                if(invoiceGroup.Invoice_Date__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Invoice_Date__c') }) + '\n';                
                if(invoiceGroup.Invoice_Due_Date__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Invoice_Due_Date__c') }) + '\n';               
                if(invoiceGroup.Invoice_Number__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Invoice_Number__c') }) + '\n';
                if(invoiceGroup.Origin_Condition_Line__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Origin_Condition_Line__c') }) + '\n';
                if(invoiceGroup.Origin_Contract_Number__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Origin_Contract_Number__c') }) + '\n';
                if(invoiceGroup.Origin_Supplier_Code__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Origin_Supplier_Code__c') }) + '\n';
                if(invoiceGroup.Header_Integration_Status__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Header_Integration_Status__c') }) + '\n';
                if(invoiceGroup.Invoice_Batch_Number__c == null) this.errorDescMessage += string.format(Label.MSG_MandatoryFields, new String[]{ invoiceGroupFieldNameLabels.get('Invoice_Batch_Number__c') }) + '\n';
                this.scanIsValid = false;
            }
        }
        // Check Warning fields
        public void CheckWarningFields() {
            // INTEGRITY CONTROL: b- Check Warning fields
            if(invoiceGroup.Invoice_Batch_Number__c == NULL){
                this.warningDescMessage += Label.MSG_Invoice_Chrono_Not_Exist + '\n';
            }
            if(((invoiceGroup.Document_type__c == 'A' || invoiceGroup.Document_type__c == 'D') &&
                (invoiceGroup.Amount_wo_Tax__c > 0 || invoiceGroup.Amount_w_Tax__c > 0)) ||
               ((invoiceGroup.Document_type__c != 'A' || invoiceGroup.Document_type__c != 'D') &&
                (invoiceGroup.Amount_wo_Tax__c < 0 || invoiceGroup.Amount_w_Tax__c < 0))){
                    this.warningDescMessage += Label.MSG_Invoice_Amount_Not_Have_Sign_Document_Type + '\n';
                }
            if((invoiceGroup.Amount_wo_Tax__c > 0 && invoiceGroup.Amount_w_Tax__c < 0) || 
               (invoiceGroup.Amount_wo_Tax__c < 0 && invoiceGroup.Amount_w_Tax__c > 0)){
                   this.warningDescMessage += Label.MSG_Amount_WTax_WoTax_Not_Have_Same_Sign;
               }
        }
    }
}