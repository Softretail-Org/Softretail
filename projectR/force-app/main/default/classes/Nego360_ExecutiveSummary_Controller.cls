/**
 * Executive Summary for Simulation Contract
 * used in page and pdf
 * */
public with sharing class Nego360_ExecutiveSummary_Controller extends NegoptimBaseController {
    
    public List<String> errors {get; set;}
    public String contentType {get; set;} // content type used to render the pdf or html
    
    public String selectedContractId;
    public String selectedMultiYearOption {get; set;}
    
    private final String TYPE_CONTRACT = 'Contract';
    private final String TYPE_TARGET = 'Target';
    private final String TYPE_SIMULATION = 'Simulation';
    
    public Contract__c currentContract {get; set;} // TODO: override by simulationContract
    public Contract__c simulationContract {get; set;}
    public Contract__c refContract {get;set;}
    public Nego_Plan__c negoPlan {get; set;}
    
    public List<GlobalSummaryWrapper> gswList {get; set;}
    public Map<ExecutiveSummaryRecord, List<ExecutiveSummaryRecord>> executiveSummaryMap {get; set;}
    public List<Contract_Discount__c> refProgressiveConditions {get; set;}
    public List<Contract_Discount__c> newProgressiveConditions {get; set;}
    
    public ProcessInstance contractProcessInstance {get; set;}
    public Boolean showSendApprovalButton {
        get {
            return simulationContract.Status__c == 'In preparation'
                && (contractProcessInstance == null || contractProcessInstance.Status != 'Pending');
        }
        set;
    }

    // Constructor
    public Nego360_ExecutiveSummary_Controller() {
        
        errors = new List<String>();
        String selectedContractId = ApexPages.currentPage().getParameters().get('id');
        if (selectedContractId == null || !NegoptimHelper.validateId(selectedContractId)) {
            errors.add('Invalid Contract Id');
        }
        if (errors.size() == 0) {
            // render page as pdf or html
            contentType = ApexPages.currentPage().getParameters().get('contentType');
            if(contentType == null)
                contentType = 'pdf';
            List<Contract__c> contracts = [SELECT Id, Name, Reference_Year__c, Contract_BU__c, Status__c, CreatedBy.Name,
                                           Supplier_Nego_Scope__c, Supplier__c, Parent_Contract__c, Contract_Type__c
                                           FROM Contract__c
                                           WHERE Id = :selectedContractId
                                           AND Contract_Type__c = :TYPE_SIMULATION];
            if(contracts.size() > 0) {
                simulationContract = contracts.get(0);
                executiveSummary();
                loadNegoPlan();
                // Check if an approval already sent
                contractProcessInstance = getContractProcessInstance();
                if(contractProcessInstance != null && contractProcessInstance.Status == 'Pending') {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Approval Already sent.'));
                }
            }
            else {
                errors.add('Simulation Contract not exist.');
            }
        }
        // Display error messages if any
        for(String error : errors) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
        }
    }
    // Back to negotiate page
    public PageReference back() {
        PageReference pageRef = Page.Nego360_Main_Edit;
        pageRef.getParameters().put('supplier', '' + simulationContract.Supplier__c);
        pageRef.getParameters().put('negoyear', String.valueOf(simulationContract.Reference_Year__c));
        pageRef.getParameters().put('negoid', '' + simulationContract.Supplier_Nego_Scope__c);
        pageRef.setRedirect(true);
        return pageRef;
    }
    // Dispaly multi year radios if is the case
    public List<SelectOption> getListMultiYear() {
        Integer max = currentContract.Secure_Multiyear__c.contains('2') ? 2 : currentContract.Secure_Multiyear__c.contains('3') ? 3 : 0;
        List<SelectOption> options = new List<SelectOption>();
        for(Integer i = 1; i <= max; i++) {
            options.add(new SelectOption(i + ' years', 'Y+' + i));
        }
        selectedMultiYearOption = options.get(0).getValue();
        return options;
    }
    // Get Contract Approval Process Instance if exist
    public ProcessInstance getContractProcessInstance() {
        List<ProcessInstance> processInstanceList = [SELECT TargetObjectId, SubmittedById, Status, ProcessDefinitionId, CreatedDate, CompletedDate
                                                     FROM ProcessInstance
                                                     WHERE TargetObjectId = :simulationContract.Id
                                                     ORDER BY CreatedDate DESC];
        if(processInstanceList != null && processInstanceList.size() > 0 ) {
            return processInstanceList.get(0);
        }
        else {
            return null;
        }
    }
    // Load the brief/notes corresponding to the selected year and negoscope
    public void loadNegoPlan() {
        List<Nego_Plan__c> negoplanList = [SELECT Id, NEGO_MOM_RDV1__c, NEGO_MOM_RDV2__c, NEGO_MOM_RDV3__c, NEGO_Keynote_Marketing_Plan__c
                                           FROM Nego_Plan__c
                                           WHERE Nego_Scope__c = :simulationContract.Supplier_Nego_Scope__c
                                           AND Nego_Year__c = :simulationContract.Reference_Year__c];
        if(negoplanList != null && negoplanList.size() > 0) {
            negoPlan = negoplanList.get(0);
        }
        else {
            negoPlan = new Nego_Plan__c();
            negoPlan.Nego_Scope__c = simulationContract.Supplier_Nego_Scope__c;
            negoPlan.Nego_Year__c = simulationContract.Reference_Year__c;
        }
    }
    // Generate executive summary
    public PageReference executiveSummary() {
        gswList = new List<GlobalSummaryWrapper>();
        try {
            // load contracts
            List<Contract__c> contracts = [SELECT c.Id, c.Name, c.Contract_Type__c, c.Supplier__c, c.Contract_BDate__c, c.Total_TO_Fact__c,
                                           c.Total_TO__c, c.Total_TO_Actu__c, c.Buying_Payment_Term_Abbrev__c, c.Services_Payment_Term_Abbrev__c,
                                           c.Supplier__r.Name, c.Supplier_Nego_Scope__r.Name, c.Contract_BU__r.Name, c.TO1__c,
                                           c.Default_Sales_Conditions__r.Merchandiser_Authorization__c, c.Default_Sales_Conditions__r.Return_Authorization1__c,
                                           Index1_perc__c, Index2_perc__c, Index3_perc__c, Index4_perc__c, Index5_perc__c, Secure_Multiyear__c,
                                           (SELECT Condition_Type__c, Condition_Type__r.Name, Nego_Discount_Type__c, Contract__c, Value_per__c, Value_amt__c,
                                            Value_per_Y1__c, Value_amt_Y1__c, Value_per_Y2__c, Value_amt_Y2__c,
                                            Y_Actu__c, Product_Scope__c, Product_Scope__r.Name, Is_Conditional__c,
                                            slab_1__c, slab_per_1__c, slab_2__c, slab_per_2__c, slab_3__c, slab_per_3__c, slab_4__c,
                                            slab_per_4__c, slab_5__c, slab_per_5__c, slab_6__c, slab_per_6__c
                                            FROM Contract_Discounts__r ORDER BY Condition_Type__r.Name),
                                           (SELECT Merchandiser_Authorization__c, Return_Authorization1__c
                                            FROM Sales_Conditions_Exception__r)
                                           FROM Contract__c c
                                           WHERE (Id = :simulationContract.Id
                                                  OR (c.Contract_Type__c = :TYPE_CONTRACT AND CALENDAR_YEAR(Contract_BDate__c) = :(Integer.valueOf(simulationContract.Reference_Year__c)-1) AND D_N__c = 'N')
                                                  OR (c.Contract_Type__c = :TYPE_TARGET AND Parent_Contract__c = :simulationContract.Parent_Contract__c))
                                           AND Supplier__c = :simulationContract.Supplier__c
                                           AND Supplier_Nego_Scope__c = :simulationContract.Supplier_Nego_Scope__c];
            Contract__c targetContract;
            for(Contract__c item : contracts) {
                if(item.Contract_Type__c == TYPE_CONTRACT) {
                    refContract = item;
                }
                else if(item.Contract_Type__c == TYPE_TARGET) {
                    targetContract = item;
                }
                else {
                    currentContract = item;
                    //selectedMultiYearOption = currentContract.Secure_Multiyear__c;
                }
            }
            if(refContract == null) {
                refContract = new Contract__c();
                ////ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Contract not exist with the selected Nego Scope for the year ' + (negoYear - 1));
                ////ApexPages.addMessage(myMsg);
                ////return null;
            }
            if(currentContract == null) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Simulation not exist with the selected Nego Scope for the year ' + simulationContract.Reference_Year__c);
                ApexPages.addMessage(myMsg);
                return null;
            }
            
            refreshExecutiveSummary();
            
            Decimal totalRefConditions = 0, totalNewConditions = 0;
            
            totalRefConditions += refContract.Index1_perc__c != null ? refContract.Index1_perc__c : 0;
            totalRefConditions += refContract.Index2_perc__c != null ? refContract.Index2_perc__c : 0;
            totalRefConditions += refContract.Index3_perc__c != null ? refContract.Index3_perc__c : 0;
            totalRefConditions += refContract.Index4_perc__c != null ? refContract.Index4_perc__c : 0;
            
            totalNewConditions += currentContract.Index1_perc__c != null ? currentContract.Index1_perc__c : 0;
            totalNewConditions += currentContract.Index2_perc__c != null ? currentContract.Index2_perc__c : 0;
            totalNewConditions += currentContract.Index3_perc__c != null ? currentContract.Index3_perc__c : 0;
            totalNewConditions += currentContract.Index4_perc__c != null ? currentContract.Index4_perc__c : 0;
            
            // Extra Data
            gswList.add(new GlobalSummaryWrapper('YTD Purchases', refContract.Total_TO_Fact__c, null));
            gswList.add(new GlobalSummaryWrapper(targetContract.Name, null, targetContract != null ? targetContract.TO1__c : null));
            gswList.add(new GlobalSummaryWrapper('Negotiated Budget', null, currentContract.Total_TO__c));
            // add total conditions
            GlobalSummaryWrapper totalconditions = new GlobalSummaryWrapper('Total Condition', totalRefConditions, totalNewConditions);
            totalconditions.isPercentage = true;
            gswList.add(totalconditions);
            // add total conditions
            GlobalSummaryWrapper paymentTerms = new GlobalSummaryWrapper('Payment Terms', null, null);
            paymentTerms.sValueRef = refContract.Buying_Payment_Term_Abbrev__c; //Services_Payment_Term_Abbrev__c
            paymentTerms.sValueNew = currentContract.Buying_Payment_Term_Abbrev__c;
            gswList.add(paymentTerms);
        } catch (Exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    private void refreshExecutiveSummary() {
        Boolean is2Years = selectedMultiYearOption == '2 years', is3Years = selectedMultiYearOption == '3 years';
        Integer nthYear = is2Years ? 2 : is3Years ? 3 : 1;
        executiveSummaryMap = new Map<ExecutiveSummaryRecord, List<ExecutiveSummaryRecord>>();
        String refContratID = refContract.Id, newContractID = currentContract.Id;
        Set<ExecutiveSummaryRecord> executiveSummarySet = new Set<ExecutiveSummaryRecord>();
        refProgressiveConditions = new List<Contract_Discount__c>();
        newProgressiveConditions = new List<Contract_Discount__c>();
        // loop over conditions of reference contract and add to the Set
        for(Contract_Discount__c item : refContract.Contract_Discounts__r) {
            if(item.Is_Conditional__c) {
                refProgressiveConditions.add(item);
            }
            ////totalRefConditions += item.Value_per__c != null ? item.Value_per__c : 0;
            ExecutiveSummaryRecord esr = new ExecutiveSummaryRecord(item.Nego_Discount_Type__c, item.Product_Scope__r.Name);
            if(!executiveSummarySet.contains(esr)) {
                esr.conditionsListRef.add(item);
                executiveSummarySet.add(esr);
            }
            else {
                for(ExecutiveSummaryRecord itemOfSet : executiveSummarySet) {
                    if(itemOfSet.conditionName == item.Nego_Discount_Type__c && itemOfSet.negoscopeName == item.Product_Scope__r.Name) {
                        itemOfSet.conditionsListRef.add(item);
                        break;
                    }
                }
            }
        }
        // loop over conditions of simulation contract and add to the Set
        for(Contract_Discount__c item : currentContract.Contract_Discounts__r) {
            if(item.Is_Conditional__c) {
                newProgressiveConditions.add(item);
            }
            ////totalNewConditions += item.Value_per__c != null ? item.Value_per__c : 0;
            ExecutiveSummaryRecord esr = new ExecutiveSummaryRecord(item.Nego_Discount_Type__c, item.Product_Scope__r.Name);
            if(!executiveSummarySet.contains(esr)) {
                esr.conditionsListNew.add(item);
                executiveSummarySet.add(esr);
            }
            else {
                for(ExecutiveSummaryRecord itemOfSet : executiveSummarySet) {
                    if(itemOfSet.conditionName == item.Nego_Discount_Type__c && itemOfSet.negoscopeName == item.Product_Scope__r.Name) {
                        itemOfSet.conditionsListNew.add(item);
                        break;
                    }
                }
            }
        }
        // calculate percentage and amount and group conditions
        for(ExecutiveSummaryRecord item : executiveSummarySet) {
            item.calculateDiffByConditionsType(nthYear);
            List<ExecutiveSummaryRecord> detailsList = item.executiveSummaryConditionsDetails(nthYear);
            executiveSummaryMap.put(item, detailsList);
        }
    }
    public PageReference changeYear() {
        refreshExecutiveSummary();
        return null;
    }
    public PageReference submitApproval() {
        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            // pass object id 
            req.setObjectId(simulationContract.Id);
            // set submitter
            req.setSubmitterId(UserInfo.getUserId());
            // set Next Approver Ids
            req.setNextApproverIds(new List<Id>{UserInfo.getUserId()});
            // optional comment
            req.setComments('Submitted for approval. Please approve.');
            // submit the approval request for processing
            Approval.ProcessResult result = Approval.process(req);
            // fill the approval users Id
            List<Id> approversIdsList = new List<Id>();
            for(Id uid : result.actorIds) {
                if(uid != null ) { // skip the first item because it is null
                    approversIdsList.add(uid);
                }
            }
            attachPdfToObjectAndEmail(approversIdsList);
            // Reload Simulation Contract to get new status
            simulationContract.Status__c = [SELECT Status__c FROM Contract__c WHERE Id = :simulationContract.Id].Status__c;
            contractProcessInstance = getContractProcessInstance();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Approval Process was sent'));
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
        return null;
    }
    public void attachPdfToObjectAndEmail(List<Id> approversIdsList) {
        PageReference pg = Page.Nego360_ExecutiveSummary_Pdf;
        pg.getParameters().put('id', '' + simulationContract.Id);
        pg.getParameters().put('contentType', '');
        
        Blob reportPdf;
        try {
            // check security on insert attachment fields
            String[] attachmentFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
                if(!checkCreatibility(Attachment.SObjectType, attachmentFields)){
                    return;
                }
            reportPdf = Test.isRunningTest() ? Blob.valueOf('UNIT.TEST') : pg.getContentAsPDF();                        
            // Insert new Attachment to the record
            Attachment attachmentPDF = new Attachment();
            attachmentPdf.parentId = simulationContract.Id;
            attachmentPdf.name = simulationContract.Name + ' -'+ system.now() + '.pdf';
            attachmentPdf.ContentType = 'application/pdf';
            attachmentPdf.body = reportPdf;
            insert attachmentPDF;
            // Email
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = approversIdsList; // we can add contact ids also
            message.subject = 'Approval required for ' + simulationContract.Name + ' + Attachment';
            // Attach file to email
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setContentType('application/pdf');
            efa.setFileName(attachmentPDF.Name);
            efa.setInline(false);
            efa.setBody(attachmentPDF.Body);
            message.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
            // Set email body
            String body = 'Good morning Dears,<br>';
            body += simulationContract.CreatedBy.Name + ' has created the contract ' + simulationContract.Name + ' that requested validation<br><br>';
            body += 'Please approve this contract.<br>';
            body += 'by going to this link : ' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + simulationContract.Id + '<br>';
            body += 'Kind regards,<br>';
            body += simulationContract.CreatedBy.Name + '<br>';
            
            body += pg.getContent().toString();
            message.htmlBody = body;
            
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            if (results[0].success) {
            } else {
            }
        } catch (VisualforceException e) {
            reportPdf = Blob.valueOf('Some Text');
        } catch (System.EmailException ex){
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, e.getMessage()));
        }
    }
    
    /**
    * Global Summary Wrapper class
    * */
    public class GlobalSummaryWrapper {
        public String label {get; set;}
        public Decimal valueRef {get; set;}
        public String sValueRef {
            get {
                return this.valueRef != null ? this.valueRef.format() : this.sValueRef;
            }
            set;
        }
        public Decimal valueNew {get; set;}
        public String sValueNew {
            get {
                return this.valueNew != null ? this.valueNew.format() : '';
            }
            set;
        }
        public Decimal diff {get; set;}
        public Boolean isAmount {get; set;}
        public Boolean isPercentage {get; set;}
        
        public GlobalSummaryWrapper(String l, Decimal val1, Decimal val2) {
            this.label = l;
            this.valueRef = val1;
            this.valueNew = val2;
            this.diff = (val1 != NULL && val2 != NULL) ? val2 - val1 : NULL;
        }
    }
    /**
    * Executive Summary Record class
    * */
    public class ExecutiveSummaryRecord implements Comparable {
        public String conditionName {get; set;}
        public String negoscopeName {get; set;}
        public Decimal percentageRef {get; set;}
        public String sPercentageRef {
            get {
                return NegoptimHelper.formatPercentageValue(this.percentageRef, true);
            }
            set;
        }
        public Decimal percentageNew {get; set;}
        public String sPercentageNew {
            get {
                return NegoptimHelper.formatPercentageValue(this.percentageNew, true);
            }
            set;
        }
        public Decimal valueRef {get; set;}
        public String sValueRef {
            get {
                return this.valueRef != null ? this.valueRef.format() : '';
            }
            set;
        }
        public Decimal valueNew {get; set;}
        public String sValueNew {
            get {
                return this.valueNew != null ? this.valueNew.format() : '';
            }
            set;
        }
        public Decimal percentageStatus {get; set;}
        public Decimal valueStatus {get; set;}
        public List<Contract_Discount__c> conditionsListRef {get; set;}
        public List<Contract_Discount__c> conditionsListNew {get; set;}
        
        public ExecutiveSummaryRecord(String name, String ns) {
            this.conditionName = name;
            this.negoscopeName = ns;
            this.percentageRef = 0;
            this.percentageNew = 0;
            this.valueRef = 0;
            this.valueNew = 0;
            this.conditionsListRef = new List<Contract_Discount__c>();
            this.conditionsListNew = new List<Contract_Discount__c>();
        }
        public void calculateDiffByConditionsType(Integer nthYear) {
            for(Contract_Discount__c item : this.conditionsListRef) {
                if(item.Value_per__c != null) {
                    this.percentageRef += item.Value_per__c;
                }
                if(item.Value_amt__c != null) {
                    this.valueRef += item.Value_amt__c;
                }
            }
            Decimal percentage, amount;
            for(Contract_Discount__c item : this.conditionsListNew) {
                percentage = item.Value_per__c;
                amount = item.Value_amt__c;
                if(nthYear == 2) {
                    percentage = item.Value_per_Y1__c != null ? item.Value_per_Y1__c : item.Value_per__c;
                    amount = item.Value_amt_Y1__c != null ? item.Value_amt_Y1__c : item.Value_amt__c;
                }
                if(nthYear == 3) {
                    percentage = item.Value_per_Y2__c != null ? item.Value_per_Y2__c : item.Value_per__c;
                    amount = item.Value_amt_Y2__c != null ? item.Value_amt_Y2__c : item.Value_amt__c;
                }
                if(percentage != null) {
                    this.percentageNew += percentage;
                }
                if(amount != null) {
                    this.valueNew += amount;
                }
            }
            this.percentageStatus = (percentageRef != NULL && percentageNew != NULL) ? percentageNew - percentageRef : NULL;
            this.valueStatus = (valueRef != NULL && valueNew != NULL) ? valueNew - valueRef : NULL;
        }
        public List<ExecutiveSummaryRecord> executiveSummaryConditionsDetails(Integer nthYear) {
            Set<ExecutiveSummaryRecord> executiveSummaryDetailsSet = new Set<ExecutiveSummaryRecord>();
            for(Contract_Discount__c conditionRef : this.conditionsListRef) {
                ExecutiveSummaryRecord newESR = new ExecutiveSummaryRecord(conditionRef.Condition_Type__r.Name, conditionRef.Product_Scope__r.Name);
                if(!executiveSummaryDetailsSet.contains(newESR)) {
                    newESR.conditionsListRef.add(conditionRef);
                    executiveSummaryDetailsSet.add(newESR);
                }
                else {
                    for(ExecutiveSummaryRecord itemOfSet : executiveSummaryDetailsSet) {
                        if(itemOfSet.conditionName == conditionRef.Condition_Type__r.Name && itemOfSet.negoscopeName == conditionRef.Product_Scope__r.Name) {
                            itemOfSet.conditionsListRef.add(conditionRef);
                            break;
                        }
                    }
                }
            }
            for(Contract_Discount__c conditionNew : this.conditionsListNew) {
                ExecutiveSummaryRecord newESR = new ExecutiveSummaryRecord(conditionNew.Condition_Type__r.Name, conditionNew.Product_Scope__r.Name);
                if(!executiveSummaryDetailsSet.contains(newESR)) {
                    newESR.conditionsListNew.add(conditionNew);
                    executiveSummaryDetailsSet.add(newESR);
                }
                else {
                    for(ExecutiveSummaryRecord itemOfSet : executiveSummaryDetailsSet) {
                        if(itemOfSet.conditionName == conditionNew.Condition_Type__r.Name && itemOfSet.negoscopeName == conditionNew.Product_Scope__r.Name) {
                            itemOfSet.conditionsListNew.add(conditionNew);
                            break;
                        }
                    }
                }
            }
            for(ExecutiveSummaryRecord item : executiveSummaryDetailsSet) {
                item.calculateDiffByConditionsType(nthYear);
            }
            return new List<ExecutiveSummaryRecord>(executiveSummaryDetailsSet);
        }
        public Boolean equals(Object obj) {
            if (obj instanceof ExecutiveSummaryRecord) {
                ExecutiveSummaryRecord p = (ExecutiveSummaryRecord)obj;
                return (conditionName.equals(p.conditionName) && negoscopeName.equals(p.negoscopeName));
            }
            return false;
        }
        public Integer hashCode() {
            return (31 * conditionName.hashCode()) ^ conditionName.hashCode();

        }
        public Integer compareTo(Object compareTo) {
            ExecutiveSummaryRecord esr = (ExecutiveSummaryRecord)compareTo;
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (conditionName != esr.conditionName || negoscopeName != esr.negoscopeName) {
                returnValue = -1;
            } else {
                returnValue = 0;
            }
            return returnValue;
        }
    }
}