public with sharing class Nego360_Main_Edit_Controller_v2 extends NegoptimBaseController {
    
    private String supplierId;
    public Integer negoYear { get; set; }
    private String sNegoYear;
    public Id refContractId { get; set; }
    public Id selectedContractId {get; set;}
    public Decimal refTO {get; set;}
    public Decimal totalRefTO {get; set;}
    
    private final String TYPE_CONTRACT = 'Contract';
    private final String TYPE_TARGET = 'Target';
    private final String TYPE_SIMULATION = 'Simulation';
    
    public String CONDITION_POPUP  { get; set; }//= 'conditionDetailsPopup';
    
    public Sup_Supplier__c supplier { get; set; }
    public Id selectedNegoScopeId { get; set; }
    
    public List<Contract__c> listContractNego { get; set; }
    private List<Contract_Discount__c> listConditions;
    private boolean createMode;
    
    public Matrice matrice { get; set; }
    
    public String selectedLineLabel { get; set; }
    //public String selectedLineType {get; set;}
    //test
    public Integer selectedLineNumber { get; set; }
    
    public Integer numContractSimulation { get; set; }
    private Integer numNewLine;
    
    public List<Contract__c> listNewContractNego { get; set; }
    
    public Boolean existingContractType { get; set; }
    public Boolean existingTargetType { get; set; }
    public Boolean existingdefaultContract { get; set; }
    
    
    private Boolean addedTargetType;
    private Boolean testSupplierAccess = true;
    private Boolean testNegoScopeAccess = true;
    public  Boolean isReadApproval { get; set; }
        
    private final Integer MIN_NUM_LINES_BY_CONDITION_TYPES = 0;
    
    public String selectedCondDefIdInPicklist { get; set; }
    
    private Set<Id> listSelectedCondDefIdInPicklist;
    
    public boolean collpaseNegoScopePanel { get; set; }
    
	public boolean acitvatedApproval = false;
    public ProcessInstance contractProcessInstance { get; set; }
    public String[] approversIdsList { get; set; }
    public Boolean showSendApprovalButton {get;set;}

    public Integer lineIndex {get; set;}
    public Integer cellIndex {get; set;}
    public String lineKey {get; set;}
    // Id for the selected cell
    public String cellKey {get; set;}
    
    public boolean displayPopup {get; set;}
    public String popupName {
        get;
        set {
            popupName = value;
        }
    }
    public boolean displayPopUpExecutiveSummary {get; set;}
    public boolean displayPopUpConditionDetails {get; set;}
    public boolean displayPopUpSlabs {get; set;}
    public List<SelectOption> listSubNegoScopes {get; set;}
    public Id subNegoScopeId {get; set;}

    /**
    * Open the popup that match a specific popup Name
    * @param popupName
    * */
    public void showPopup() {
        if(popupName == 'openPopUpExecutiveSummary') {
            // get the selected contract id for the comparison
            for(WrapperColumn item : matrice.columns) {
                if(item.contract.Selected_Simul_For_Approval__c) {
                    selectedContractId = item.contract.Id;
                    item.isLocked = objectIsLocked(selectedContractId);
                }
            }
            if(selectedContractId != null) {
                displayPopUpExecutiveSummary = true;
                String selectedStatus = getContractStatus(selectedContractId);
                contractProcessInstance = getContractProcessInstance(selectedContractId);
                showSendApprovalButton = (contractProcessInstance == null || contractProcessInstance.Status != 'Pending') && selectedStatus == 'In preparation';
                executiveSummary(selectedContractId);
            }
            else {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'No Contract selected or contract not yet saved.');
            	ApexPages.addMessage(myMsg);
            }
        }
        if(popupName == 'conditionDetailsPopup') {
            Boolean isSelectedContract = false;
            Integer i = 0, j = 0;
            for(WrapperColumn item : matrice.columns) {
                if(item.contract.Selected_Simul_For_Approval__c) {
                    cellIndex = i;
                    isSelectedContract = true;
                }
                i++;
            }
            for(Line item : matrice.linesTable) {
                if(item.lineId == lineKey && !item.isSubTotal) {
                    lineIndex = j;
                }
                j++;
            }
            if(isSelectedContract) {
                displayPopUpConditionDetails = true;
            }
            else {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'No Contract selected or contract not yet saved.');
                ApexPages.addMessage(myMsg);
            }
        }
        if(popupName == 'slabsPopup') {
            displayPopUpSlabs = true;
        }
        else {
            // do nothing
        }
    }
    /**
    * Close opened popup that match a specific popup Name
    * @param popupName
    * */
    public void closePopup() {
        if(popupName == 'closePopUpExecutiveSummary') {
            displayPopUpExecutiveSummary = false;
            isReadApproval = objectIsLocked(selectedContractId);
            selectedContractId = null;
        }
        if(popupName == 'conditionDetailsPopup') {
            displayPopUpConditionDetails = false;
            Id ns;
            for(Line item : matrice.linesTable) {
                if(item.lineId == lineKey) {
                    ns = item.negoScope;
                }
            }
        }
        if(popupName == 'slabsPopup') {
            displayPopUpSlabs = false;
            chooseSlabTarget(lineKey, cellIndex);
        }
        if(popupName == 'cancelSlabsPopup') {
            displayPopUpSlabs = false;
        }
        else {
            // do nothing
        }
    }
    /**
    * Constructor
    * */
    public Nego360_Main_Edit_Controller_v2() {
        isReadApproval = false;
        createMode = true;
        supplierId = ApexPages.currentPage().getParameters().get('supplier');
        sNegoYear = ApexPages.currentPage().getParameters().get('negoyear');
        
        if (supplierId == null) {
            throw new NOException(Label.Error_NoSupplierSelected);
        }
        if (sNegoYear == null) {
            throw new NOException(Label.Error_NoNegoYearSelected);
        }
        
        this.collpaseNegoScopePanel = false;
        
        negoYear = Integer.valueOf(sNegoYear);
        
        // fields to be checked
        String[] suppliersFields = new String[] { 'Id', 'Name' };
        testSupplierAccess = checkAccessibility(Sup_Supplier__c.SObjectType, suppliersFields);
        
        if (testSupplierAccess) {
            List<Sup_Supplier__c> listSuppliers = [SELECT Id, Name,Country_origin__c,CurrencyIsoCode FROM Sup_Supplier__c WHERE Id = :supplierId];
            if (listSuppliers.size() > 0) {
                supplier = listSuppliers.get(0);
            }
            
            // Si ce paramètre est renseigné, c'est qu'on revient sur la page après une sauvegarde
            String sSelectedNegoId = ApexPages.currentPage().getParameters().get('negoid');
            if (sSelectedNegoId != null && !sSelectedNegoId.trim().equals('')) {
                selectedNegoScopeId = sSelectedNegoId;
                this.collpaseNegoScopePanel = true;
                init();
                return;
            }
            
            // fields to be checked
            String[] negoScopeFields = new String[] { 'Id', 'Name', getFieldName('Supplier__c') };
            testNegoScopeAccess = checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeFields);
            if (testNegoScopeAccess) {
                List<SelectOption> negoScopeOptions = getListNegoScopes();
                if (negoScopeOptions.size() == 1) {
                    selectedNegoScopeId = negoScopeOptions.get(0).getValue();
                    this.collpaseNegoScopePanel = true;
                    init();
                    return;
                }
            }
        }
    }
    public PageReference goToSelectionPage() {
        PageReference pageRef = new PageReference('/apex/Nego360_Main_Selection_v2');
        pageRef.setRedirect(true);
        return pageRef;
    }
    /**
     * Load the brief/notes corresponding to the selected year and negoscope
     * */
    public void loadNegoPlan() {
        List<Nego_Plan__c> negoplanList = [SELECT Id, NEGO_MOM_RDV1__c, NEGO_MOM_RDV2__c, NEGO_MOM_RDV3__c, NEGO_Keynote_Marketing_Plan__c
                                           FROM Nego_Plan__c
                                           WHERE Nego_Scope__c = :selectedNegoScopeId
                                           AND Nego_Year__c = :negoYear];
        if(negoplanList != null && negoplanList.size() > 0) {
            negoPlan = negoplanList.get(0);
        }
        else {
            negoPlan = new Nego_Plan__c();
            negoPlan.Nego_Scope__c = selectedNegoScopeId;
            negoPlan.Nego_Year__c = negoYear;
        }
    }
    /**
     * Save th nego plan for this negotiation
     * */
    public void saveNegoPlan() {
        try {
            // Add date at the begining
            // TODO: do not repeat the date each time if field was filled
            // fields to be checked
            String [] negoPlanFields = new String [] {getFieldName('NEGO_MOM_RDV1__c'),getFieldName('NEGO_MOM_RDV2__c'),getFieldName('NEGO_MOM_RDV3__c')};
            negoPlan.NEGO_MOM_RDV1__c = (negoPlan.NEGO_MOM_RDV1__c != null && negoPlan.NEGO_MOM_RDV1__c != '') ? Date.today().format() + '\n' + negoPlan.NEGO_MOM_RDV1__c : '';
            negoPlan.NEGO_MOM_RDV2__c = (negoPlan.NEGO_MOM_RDV2__c != null && negoPlan.NEGO_MOM_RDV2__c != '') ? Date.today().format() + '\n' + negoPlan.NEGO_MOM_RDV2__c : '';
            negoPlan.NEGO_MOM_RDV3__c = (negoPlan.NEGO_MOM_RDV3__c != null && negoPlan.NEGO_MOM_RDV3__c != '') ? Date.today().format() + '\n' + negoPlan.NEGO_MOM_RDV3__c : '';
            
            if(checkCreatibility(Nego_Plan__c.SObjectType, negoPlanFields)
               && checkUpdatibility(Nego_Plan__c.SObjectType, negoPlanFields)) {
                upsert negoPlan;
            }
        }
        catch (DMLException e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
            ApexPages.addMessage(myMsg);
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Plan was saved successfully'));
    }
    
    
    public void approvalProcess(Id contractId){
        try{
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            
            //optional comment
            req.setComments('Submitted for approval. Please approve.');
            // contrat id 
            req.setObjectId(contractId);
            // user submitter 
            req.setSubmitterId(UserInfo.getUserId());
            List<Id> approvers = new List<Id>();
			approvers.add(UserInfo.getUserId());
            req.setNextApproverIds(approvers);
			
            // submit the approval request for processing
            Approval.ProcessResult result = Approval.process(req);

            // fill the approval users Id
            approversIdsList = new List<String>();
            for(Id uid : result.actorIds) {
                if(uid != null ) { // skip the first item because it is null
                    approversIdsList.add(uid);
                }
            }
          acitvatedApproval = true;          
        } catch(Exception e) {
            acitvatedApproval = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + e.getMessage()));
        }
    }
    public void attachPdfToObjectAndEmail(Id contractId){
        if(contractId!=null){
            try {
                
                // check security on insert attachment fields
                String[] attachmentFields = new String[]{ 'Name', 'Body', 'ParentId', 'ContentType' };
                    if(!checkCreatibility(Attachment.SObjectType, attachmentFields)){
                        return;
                    }
                
                PageReference pg;
                pg = Page.Nego360_ExecutiveSummary_Pdf;               
                pg.getParameters().put('supplier', '' + supplierId);
                pg.getParameters().put('negoyear', sNegoYear);
                pg.getParameters().put('negoid', '' + selectedNegoScopeId);
                pg.getParameters().put('conId', '' + selectedContractId);     
                Blob reportPdf = Test.isRunningTest() ? Blob.valueOf('UNIT.TEST') :  pg.getContentAsPDF();

                Attachment attachmentPDF = new Attachment();
                attachmentPdf.parentId = contractId;
                attachmentPdf.name = 'Round -'+ system.now()+'.pdf';
                attachmentPdf.body = reportPdf;
       			insert attachmentPDF;
                
                //String [] contractFields = new String [] {'Id','Name'};
               
                Contract__c con = [select CreatedBy.name,Name from Contract__c where id = :contractId];
                
                String body;
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                
                message.toAddresses = approversIdsList; // we can add contact ids also
                message.subject = 'Approval required for '+con.Name + '+ Attachment';
                body = 'Good morning Dears,<br>';
                body+= con.CreatedBy.name+' has created the contract '+con.Name+' that requested validation<br><br>';
                body+= 'Please approve this contract.<br>';
                body+= 'by going to this link : '+system.URL.getSalesforceBaseUrl().toExternalForm()+'/'+contractId+' <br>';
                body+= 'Kind regards,<br>';
                body+= con.CreatedBy.name+'<br>';
                body+= generateEmail();
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attachmentPDF.Name);
                efa.setBody(attachmentPDF.Body);
                message.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                message.htmlBody = body;
               // @todo : check why we get insufficent insert id error 
               //// if(checkCreatibility(Schema.SObjectType.Contract__c.fields.getMap(), contractFields)) {
                 
                Messaging.SingleEmailMessage[] messages = 
                    new List<Messaging.SingleEmailMessage> {message};
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results[0].success) {
                } else {
                }
                    
                //// }
                
                
            } catch(Exception e) {
                acitvatedApproval = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ' Error:' + e.getMessage()));
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'No simulation contract'));
        }
    }   
    public PageReference submitApproval() {
        Id contractId = selectedContractId;
        if(contractId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ' Error: No Simulation Contract'));
            return null;
        }
        else {
            // approve process 
            try{
                approvalProcess(contractId);
                // attach pdf to object and email
                if(acitvatedApproval==true){
                    attachPdfToObjectAndEmail(contractId);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Approval Process was sent'));                }
            } catch(Exception e) {
                acitvatedApproval = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Submit approval Error:' + e.getMessage()));
            }
        }
        popupName = 'closePopUpExecutiveSummary';
        closePopup();
        return null;
    }
    public String getSummaryStatus(Decimal summaryStatusValue){
        String SummaryStatus;
        String instanceUrl = System.URL.getSalesforceBaseURL().toExternalForm();
        String imgResourceUrl = instanceUrl + NegoptimHelper.GetResourceURL('Assets')+'/assets/img';
        String imgLeft = '<img  src="'+ imgResourceUrl+'/left.jpg" />';
        String imgUp =  '<img  src="'+ imgResourceUrl+'/up.jpg" />';
        String imgDown =  '<img  src="'+ imgResourceUrl+'/down.jpg" />';
        
        if(summaryStatusValue > 0 ){
            SummaryStatus = imgUp;
        }
        if(summaryStatusValue < 0 ){
            SummaryStatus = imgDown;
        }
        if(summaryStatusValue == 0 ){
            SummaryStatus = imgLeft;
        }
        
        return SummaryStatus;
    }

    public String generateEmail(){
        String html = '',approvalDateStr;
        if(negoPlan.NEGO_Keynote_Marketing_Plan__c==null) negoPlan.NEGO_Keynote_Marketing_Plan__c='';
        if(negoPlan.NEGO_MOM_RDV1__c==null) negoPlan.NEGO_MOM_RDV1__c='';
        if(negoPlan.NEGO_MOM_RDV2__c==null) negoPlan.NEGO_MOM_RDV2__c='';
        if(negoPlan.NEGO_MOM_RDV3__c==null) negoPlan.NEGO_MOM_RDV3__c='';
        if(contractProcessInstance==null) approvalDateStr ='' ;
        else approvalDateStr = contractProcessInstance.CreatedDate.format();
        //main table
		html+='<table border="0" cellpadding="0" cellspacing="0" style="width:700px;" >';
        // title execuive summary 
        html+='<tr padding="3px" bgcolor="#39B1D9"  style="font-size: 10px;color:#fffffd;background-color:#39B1D9"><td padding="3px" colspan="2" style="padding:3px;">' + Label.LBL_Executive_Summary + '</td></tr>';
        //begin main information
        html+='<tr><td>';
        //table contain 2 table 
	    html+='<table border="0" cellpadding="0" cellspacing="0" style="width:700px;" >';
        html+='<tr>';
        //first table
        html+='<td>';
        html+='<table border="0" cellpadding="5" cellspacing="0" width="300" style="width:300px;">';
        html+='<tr style="font-size: 10px;"><td colspan="2"><b>' + Label.LBL_Country_Scope + ':</b> ' + currentContract.Contract_BU__r.Name + '</td></tr>';
        html+='<tr style="font-size: 10px;"><td colspan="2"><b>' + Label.LBL_Supplier_Name + ':</b> ' + supplier.Name + '</td></tr>';
        html+='<tr style="font-size: 10px;"><td colspan="2"><b>' + Label.LBL_NegoScope + ':</b> ' + currentContract.Supplier_Nego_Scope__r.Name + '</td></tr>';
        html+='<tr style="font-size: 10px;"><td><b>' + Label.LBL_NS_Dpt_rank + '</b> 1</td><td><b>' + Label.LBL_Dpt_Weight + '</b> 35.2%</td></tr>';
        html+='<tr style="font-size: 10px;"><td><b>' + Label.LBL_NS_Supplier_rank + '</b> 1</td><td><b>' + Label.LBL_Supplier_Weight + '</b> 35.2%</td></tr>';
        html+='</table>';
        html+='</td>';
        //end first table
        //second table
        html+='<td>';
        html+='<table border="0" cellpadding="5" cellspacing="0" width="300" style="width:300px;">';
        html+='<tr style="font-size: 10px;"><td colspan="3"><b>' + Label.LBL_Contract_year + ':</b> ' + negoYear + ' </td></tr>';
        html+='<tr style="font-size: 10px;"><td colspan="3"><b>' + Label.LBL_Date_of_Submit_for_approval + ':</b> ' + approvalDateStr + '</td></tr>';
        html+='<tr style="font-size: 10px;"><td colspan="3"><b>' + Label.LBL_Status_validation + ':</b> 1/2</td></tr>';
        html+='<tr style="font-size: 10px;"><td width="100"></td><td width="200">' + Label.LBL_Catman + '<br />' + Label.LBL_Head_Of_Department + '<br/>' + Label.LBL_Country_Finance + '</td><td width="100"></td></tr>';
        html+='</table>';
        html+='</td>';
        //end second table
        html+='</tr>';
        html+='</table>';
        html+='</td></tr>';
        //end main information
        // begin second row of big main table contain 2 table ( executive data and keynote marketing plan)
        html+='<tr>';
        html+='<td>';
        html+='<table border="0" cellpadding="0" cellspacing="0" style="width:720px;" >';
        html+='<tr>';
        html+='<td style="width:700px;" valign="top">';
        // first table : executive 
        html+='<table border="0" cellpadding="0" cellspacing="0" width="720" style="width:720px;border-top-left-radius: 10px;  border-top-right-radius: 10px;border: 1px solid #eaeaea; border-top: 3px solid #1797c0;padding: 10px;">';
        html+='<tr><td>';
        // table contain al data of exeecutve summary  
        html+='<table border="0" cellpadding="0" cellspacing="0" width="420"  style="width:420px;border: 1px solid gray;">';
        for(GroupConditionsWrapper itemData: conditionExtraDataList){
            if(itemData.valueNew==null) itemData.valueNew=0;
            html+='<tr style="font-size: 10px;"><td style="border-bottom: 1px solid gray;">'+itemData.conditionType+'</td><td style="border-bottom: 1px solid gray;"></td><td style="border-bottom: 1px solid gray;">'+itemData.valueRef+'</td><td style="border-bottom: 1px solid gray;">'+itemData.valueNew+'</td><td style="border-bottom: 1px solid gray;"></td><td style="border-bottom: 1px solid gray;"></td></tr>';		
        } 
        html+='</table>';      
        //end table contacin al data of exeecutve summary  
        // second table : executive 
        html+='<table border="0" cellpadding="0" cellspacing="0" width="420"  style="width:420px;border: 1px solid gray;">';
        html+='<tr bgcolor="#39B1D9" style="text-align:center;font-size: 10px;font-weight:bold;background-color:#f2f3f3"><td>' + Label.LBL_Type + '</td><td>NS</td><td>' + Label.LBL_Reference_contract + '</td> <td>' + Label.LBL_New_contract + '</td><td></td><td></td></tr>';
        for(ExecutiveSummaryRecord eSummaryMap: executiveSummaryMap.keySet()){
            html += '<tr style="font-size: 10px;">';
            html += '<td style="padding:5px">'+eSummaryMap.conditionName+'</td>';
            html += '<td style="padding:5px">'+eSummaryMap.negoscopeName+'</td>';
            html += '<td style="padding:5px">'+eSummaryMap.sPercentageRef+' | '+eSummaryMap.sValueRef+'</td>';
            html += '<td style="padding:5px">'+eSummaryMap.sPercentageNew+' | '+eSummaryMap.sValueNew+'</td>';
            html += '<td>'+getSummaryStatus(eSummaryMap.percentageStatus)+'</td>';
            html += '<td>'+getSummaryStatus(eSummaryMap.valueStatus)+'</td>';
            html += '</tr>';
        }
        html+='</table>';  
        // end second tableexecutive summary table 
       
        // third table : executive summary detailed
        html+='<table border="0" cellpadding="0" cellspacing="0" width="420" style="width:420px;border: 1px solid gray;"><tr><td><table border="0" cellpadding="0" cellspacing="0" width="400" style="width:400px;">';
        for(ExecutiveSummaryRecord eSummaryMap: executiveSummaryMap.keySet()){
            html+='<tr align="left" style="text-align:left;font-size: 10px;font-weight:bold;"><td padding="5px" colspan="5" style="padding:5px">'+eSummaryMap.conditionName+'</td></tr>';
            
            for(ExecutiveSummaryRecord eDetailMap: executiveSummaryMap.get(eSummaryMap)){
                html+='<tr bgcolor="#ffffff"  style="text-align:center;font-size: 10px;font-weight:bold;background-color:#ffffff"><td style="padding:5px">'+eDetailMap.conditionName+'</td><td  style="padding:5px;">'+eDetailMap.percentageRef+' | '+eDetailMap.valueRef+'</td><td style="padding:5px;">'+eDetailMap.percentageNew+' | '+eDetailMap.valueNew+'</td><td>'+getSummaryStatus(eSummaryMap.percentageStatus)+'</td> <td>'+getSummaryStatus(eSummaryMap.valueStatus)+'</td></tr>';
            }
        }
        html+='</table></td></tr></table>';
        // end third table : executive summary detailed
        html+='</td>';
        
        html+='<td style="width:250px;" valign="top">';
        // sec table : keynote
        // begin key note 
        html+='<table border="0" cellpadding="0" cellspacing="0" width="250px" style="width:250px;border-top-left-radius: 10px;  border-top-right-radius: 10px;border: 1px solid #eaeaea; border-top: 3px solid #1797c0;padding: 10px;">';
        html+='<tr><td>';
        html+='<table border="0" cellpadding="0" cellspacing="0" width="250"  style="width:250px">';
        html+='<tr bgcolor="#39B1D9"  style="font-size: 10px;color:#fffffd;background-color:#39B1D9"><td style="padding:5px">Key note / Marketing plan from supplier</td></tr>';
        html+='<tr style="font-size: 10px;"><td style="border-bottom: 1px solid gray;padding:5px">'+negoPlan.NEGO_Keynote_Marketing_Plan__c+'</td></tr>';		
        html+='</table>';      
        html+='</td></tr>';
        html+='</table>';
        // end key note
        html+='</td>';
        html+='</tr>';
        html+='</table>';
        html+='</td>';
        html+='</tr>';
        html+='</table>';
        html+='</td>';
        // end second row of big main table
       // begin third row :Details of Progressive Rebates
        html+='</tr>';
        html+='<tr>';
        html+='<td>';  
        // begin table : Details of Progressive Rebates 
        html+='<table border="0" cellpadding="0" cellspacing="0" width="720"  style="width: 720px; padding: 10px; border: 1px solid #eaeaea;">';
        html+='<tr><td>'+Label.LBL_Reference_contract+'</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>';
        html+='<tr style="font-size: 10px;background-color:#f2f3f3;"><td>Condition Name</td>';
        html+='<td>Slab 1 - Threshold</td>';
        html+='<td>Slab 1 - %</td>';
        html+='<td>Slab 2 - Threshold</td>';
        html+='<td>Slab 2 - %</td>';
        html+='<td>Slab 3 - Threshold</td>';
        html+='<td>Slab 3 - %</td>';
        html+='<td>Slab 4 - Threshold</td>';
        html+='<td>Slab 4 - %</td>';
        html+='<td>Slab 5 - Threshold</td>';
        html+='<td>Slab 5 - %</td>';
        html+='<td>Slab 6 - Threshold</td>';
        html+='<td>Slab 6 - %</td>';
        html+='<td>Nego Scope Name</td>';
		html+='</tr>';
      
        for(Contract_Discount__c progressConditionItem : refProgressiveConditions){
            html += '<tr style="font-size: 10px;">';
            html += '<td>'+progressConditionItem.Condition_Type__r.Name+'</td>';
            html += '<td>'+progressConditionItem.Slab_1__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_1__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_2__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_2__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_3__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_3__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_4__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_4__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_5__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_5__c+'</td>';
            html += '<td>'+progressConditionItem.slab_6__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_6__c+'</td>';
            html += '<td>'+progressConditionItem.Product_Scope__r.Name+'</td>';
            html += '</tr>';
        }
        html+='</table>';  
        // end  table : Details of Progressive Rebates 
        // 
        // begin table : Details of Progressive Rebates  2
        html+='<table border="0" cellpadding="0" cellspacing="0" width="720" style="width: 720px; padding: 10px; border: 1px solid #eaeaea;">';
        html+='<tr><td>'+Label.LBL_New_contract+'</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>';
        html+='<tr style="font-size: 10px;background-color:#f2f3f3;"><td>Condition Name</td>';
        html+='<td>Slab 1 - Threshold</td>';
        html+='<td>Slab 1 - %</td>';
        html+='<td>Slab 2 - Threshold</td>';
        html+='<td>Slab 2 - %</td>';
        html+='<td>Slab 3 - Threshold</td>';
        html+='<td>Slab 3 - %</td>';
        html+='<td>Slab 4 - Threshold</td>';
        html+='<td>Slab 4 - %</td>';
        html+='<td>Slab 5 - Threshold</td>';
        html+='<td>Slab 5 - %</td>';
        html+='<td>Slab 6 - Threshold</td>';
        html+='<td>Slab 6 - %</td>';
        html+='<td>Nego Scope Name</td>';
		html+='</tr>';
      
        for(Contract_Discount__c progressConditionItem : newProgressiveConditions){
            html += '<tr style="font-size: 10px;">';
            html += '<td>'+progressConditionItem.Condition_Type__r.Name+'</td>';
            html += '<td>'+progressConditionItem.Slab_1__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_1__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_2__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_2__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_3__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_3__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_4__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_4__c+'</td>';
            html += '<td>'+progressConditionItem.Slab_5__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_5__c+'</td>';
            html += '<td>'+progressConditionItem.slab_6__c+'</td>';
            html += '<td>'+progressConditionItem.slab_per_6__c+'</td>';
            html += '<td>'+progressConditionItem.Product_Scope__r.Name+'</td>';
            html += '</tr>';
        }
        html+='</table>';  
        // end  table : Details of Progressive Rebates 2
        // 
        html+='</td>';
        html+='</tr>';
        // end third row
        
        // begin fourth row :Exceptions and comments in contract
        html+='<tr>';
        html+='<td>';  
        // begin Exceptions and comments in contract 
        html+='<table border="0" cellpadding="0" cellspacing="0" width="700px" style="width:700px;border-top-left-radius: 10px;  border-top-right-radius: 10px;border: 1px solid #eaeaea; border-top: 3px solid #1797c0;padding: 10px;">';
        html+='<tr><td>';
        html+='<table border="0" cellpadding="0" cellspacing="0" width="700px"  style="width:700px">';
        html+='<tr bgcolor="#39B1D9"  style="font-size: 10px;color:#fffffd;background-color:#39B1D9"><td style="padding:3px;color:#ffffff;font-weight:bold">Exceptions and comments in contract</td></tr>';
        html+='<tr style="font-size: 10px;"><td style="border-bottom: 1px solid gray;">Return:'+refContract.Default_Sales_Conditions__r.Return_Authorization1__c+'</td></tr>';		
        html+='<tr style="font-size: 10px;"><td style="border-bottom: 1px solid gray;">Merchandiser:'+refContract.Default_Sales_Conditions__r.Merchandiser_Authorization__c+'</td></tr>';		
        html+='</table>';      
        html+='</td></tr>';
        html+='</table>';
        // end Exceptions and comments in contract
        html+='</td>';
        html+='</tr>';
        // end fourth row
        
        // begin fifth row :Negotiation RDV minutes
        html+='<tr>';
        html+='<td>';  
        // begin Negotiation RDV minutes 
        html+='<table border="0" cellpadding="0" cellspacing="0" width="700px" style="width:700px;border-top-left-radius: 10px;  border-top-right-radius: 10px;border: 1px solid #eaeaea; border-top: 3px solid #1797c0;padding: 10px;">';
        html+='<tr><td>';
        html+='<table border="0" cellpadding="0" cellspacing="0" width="700px"  style="width:700px">';
        html+='<tr bgcolor="#39B1D9"  style="font-size: 10px;color:#fffffd;background-color:#39B1D9"><td style="padding:3px;color:#ffffff;font-weight:bold">Negotiation RDV minutes</td></tr>';
        html+='<tr style="font-size: 10px;"><td style="border-bottom: 1px solid #eaeaea;padding:5px">'+ negoPlan.NEGO_MOM_RDV1__c+'</td></tr>';		
        html+='<tr style="font-size: 10px;"><td style="border-bottom: 1px solid #eaeaea;padding:5px">'+negoPlan.NEGO_MOM_RDV2__c+'</td></tr>';		
        html+='<tr style="font-size: 10px;"><td style="border-bottom: 1px solid #eaeaea;padding:5px">'+negoPlan.NEGO_MOM_RDV3__c+'</td></tr>';		
        html+='</table>';      
        html+='</td></tr>';
        html+='</table>';
        // end Negotiation RDV minutes
        html+='</td>';
        html+='</tr>';


        html+='</table>';	
        //end main table
        return html;
    }
    /**
     * Return the selected contract status
     * */
    public String getContractStatus(Id selectedContractId) {
        List<Contract__c> contracts = [SELECT Status__c
                                       FROM Contract__c
                                       WHERE Id = :selectedContractId
                                       LIMIT 1];
        if(contracts != null && contracts.size() > 0 ) {
            return contracts.get(0).Status__c;
        }
        else {
            return '';
        }
    }
    public ProcessInstance getContractProcessInstance(Id selectedContractId) {
        List<ProcessInstance> processInstanceList = [SELECT TargetObjectId, SubmittedById, Status, ProcessDefinitionId, CreatedDate, CompletedDate
                                                     FROM ProcessInstance
                                                     WHERE TargetObjectId = :selectedContractId
                                                     ORDER BY CreatedDate DESC];
        if(processInstanceList != null && processInstanceList.size() > 0 ) {
            return processInstanceList.get(0);
        }
        else {
            return null;
        }
    }
    /**
     * init
     * */
    public PageReference init() {
        numContractSimulation = 0;
        numNewLine = 0;
        existingContractType = false;
        existingTargetType = false;
        addedTargetType = false;
        existingdefaultContract = false;
        selectedCondDefIdInPicklist = null;
        
        // fields to be checked
        String[] contractNegoFields = new String[] { 'Id', 'Name', getFieldName('Contract_Type__c'), getFieldName('Reference_Year__c'),
            getFieldName('Supplier_Nego_Scope__c'), getFieldName('Supplier__c'), getFieldName('TO1__c'), getFieldName('Total_TO_Fact__c'),
            getFieldName('Total_TO_Ref__c'), getFieldName('Contract_BDate__c'), getFieldName('Contract_EDate__c'), getFieldName('SimulationNumber__c'),
            getFieldName('Contract_BU__c'), getFieldName('Parent_Contract__c'), getFieldName('Qty1__c'), getFieldName('Total_Qty_Fact__c'),
            getFieldName('Depreciation_Rate__c'), getFieldName('Markdown_Rate_Break__c'), getFieldName('Markdown_Rate_Promo__c'),
            getFieldName('Markdown_Rate_Theft__c'), getFieldName('Rise_Rate__c'), getFieldName('Selected_Simul_For_Approval__c')};
        if(!checkAccessibility(Contract__c.SObjectType, contractNegoFields)) {
            return null;
        }
        
        listContractNego = [SELECT Id, Name, CurrencyIsoCode, Contract_Type__c, Reference_Year__c, Supplier_Nego_Scope__c, Supplier__c,
                            TO1__c, Total_TO_Fact__c, Total_TO_Ref__c, Contract_BDate__c, Contract_EDate__c, SimulationNumber__c,
                            Contract_BU__c, Parent_Contract__c, Qty1__c, Total_Qty_Fact__c, Depreciation_Rate__c,
                            Markdown_Rate_Break__c, Markdown_Rate_Promo__c,  Markdown_Rate_Theft__c, Rise_Rate__c, Selected_Simul_For_Approval__c
                            FROM Contract__c
                            WHERE Supplier_Nego_Scope__c = :selectedNegoScopeId
                            AND((Contract_Type__c = :TYPE_CONTRACT AND CALENDAR_YEAR(Contract_EDate__c) = :(negoYear - 1) AND D_N__c = 'N')
                                OR(Contract_Type__c <> :TYPE_CONTRACT AND CALENDAR_YEAR(Contract_EDate__c) = :negoYear)
                                OR(Contract_Type__c = :TYPE_CONTRACT AND CALENDAR_YEAR(Contract_EDate__c) = :negoYear))
                            ORDER BY Contract_Type__c, Contract_BDate__c, SimulationNumber__c ASC NULLS FIRST];

        for (Contract__c contractNego : listContractNego) {
            if (contractNego.Contract_Type__c == TYPE_CONTRACT) {
                listNewContractNego = new List<Contract__c>();
                listNewContractNego.add(contractNego);
                // set the Total_TO_Fact__c in TO1__c to make right calculation
                contractNego.TO1__c = contractNego.Total_TO_Fact__c;
                if(contractNego.Reference_Year__c == (negoYear - 1)) {
                    existingContractType = true;
                    existingdefaultContract = true;
                    refContractId = contractNego.Id;
                    refTO = contractNego.Total_TO_Fact__c;
                }
            }
            if (contractNego.Contract_Type__c == TYPE_TARGET) {
                existingTargetType = true;
            }
            
            if (contractNego.Contract_Type__c == TYPE_SIMULATION) {
                createMode = false;
                try {
                    if(Approval.isLocked(contractNego.Id) == true) {
                        isReadApproval = true;
                    } 
                }
                catch(Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Enable record locking and unlocking in Apex'));
                }
                if (contractNego.SimulationNumber__c > numContractSimulation) {
                    numContractSimulation = Integer.valueOf(contractNego.SimulationNumber__c);
                }
            }
        }

        // throw new NOException('Simulation Number: ' + numContractSimulation);
        
        if (!existingContractType) {
            Contract__c newContractNego = new Contract__c();
            newContractNego.Name = 'Contract ' + (negoYear - 1);
            newContractNego.Contract_Type__c = TYPE_CONTRACT;
            newContractNego.Supplier_Nego_Scope__c = selectedNegoScopeId;
            newContractNego.Supplier__c = supplierId;
            newContractNego.D_N__c = 'N';
            newContractNego.Contract_BDate__c = date.newInstance(negoYear - 1, 1, 1);
            newContractNego.Contract_EDate__c = date.newInstance(negoYear - 1, 12, 31);
            newContractNego.Contract_BU__c = supplier.Country_origin__c;
            newContractNego.CurrencyIsoCode = supplier.CurrencyIsoCode;
            if (listContractNego.size() > 0) {
                listContractNego.add(0, newContractNego);
            } else {
                listContractNego.add(newContractNego);
            }
            listNewContractNego = new List<Contract__c>();
            listNewContractNego.add(newContractNego);
            // columnHeaderName = newContractNego.Contract_Type__c + ' ' + (negoYear - 1);
            existingContractType = true;
        }
        retrieveMapListConditions();
        loadNegoPlan();
        return null;
    }
    /*
     * Load Nego scope list by supplier
     * @return List of Select Option used in radio button component
     * */
    public List<SelectOption> getListNegoScopes() {
        
        // fields to be checked
        String[] negoScopeFields = new String[] { 'Id', 'Name', getFieldName('Supplier__c') };
        if(!checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeFields)) {
            return null;
        }
        
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name, Supplier__c FROM Sup_sup_NegoScope__c WHERE Supplier__c = :supplierId and Parent_Nego_Scope__c = null];
        List<SelectOption> options = new List<SelectOption> ();
        for (Sup_sup_NegoScope__c negoScope : listNegoScopes) {
            options.add(new SelectOption(negoScope.Id, negoScope.Name));
        }
        return options;
    }
    /**
     * Load Nego scope children list by parent nego scope
     * */
    public List<SelectOption> getSubNegoScopes(String negoScopeId) {
        // fields to be checked
        String[] negoScopeFields = new String[] { 'Id', 'Name', getFieldName('Supplier__c') };
        if(!checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeFields)) {
            return null;
        }
        
        List<Sup_sup_NegoScope__c> subNSList = [SELECT id, Name
                                                FROM Sup_sup_NegoScope__c
                                                WHERE Parent_Nego_Scope__c = :selectedNegoScopeId];
        List<SelectOption> options = new List<SelectOption>();
        for (Sup_sup_NegoScope__c item : subNSList) {
            options.add(new SelectOption(item.Id, item.Name));
        }
        return options;
    }
    public Boolean getShowConditionTable() {
        return selectedNegoScopeId != null && listContractNego != null;
    }
    
    public Sup_sup_NegoScope__c getNegoScope() {
        // fields to be checked
        String[] negoScopeFields = new String[] { 'Id', 'Name' };
        if(!checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeFields)) {
            return null;
        }
        
        List<Sup_sup_NegoScope__c> listNegoScopes = [SELECT Id, Name FROM Sup_sup_NegoScope__c WHERE Id = :selectedNegoScopeId];
        Sup_sup_NegoScope__c negoScope = listNegoScopes.get(0);
        return negoScope;
    }
    
    public PageReference retrieveMapListConditions() {
        // if(listContractNego.size() == 1) {
        //   createBlankMatrice();
        //   matrice.setNumberLines();
        //   matrice.calculTotals();
        //   return null;
        // }
        
        // fields to be checked
        String[] conditionsFields = new String[] { 'Id', 'Name', getFieldName('Condition_Type__c'), getFieldName('Contract__c'), getFieldName('Value_per__c'), getFieldName('Value_amt__c'), getFieldName('Index__c') };
        if(!checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields)) {
            return null;
        }
        
        listConditions = [SELECT Id, Name, Condition_Type__c, Value_per__c, Value_amt__c, Disc_BDate__c, Disc_EDate__c, Contract__c,
                          Product_Scope__c, BU_Scope__c, Base_TO_Nego__c, Index__c, commercial_reference__c,
                          slab_1__c, slab_per_1__c, slab_val_1__c, slab_2__c, slab_per_2__c, slab_val_2__c, slab_3__c, slab_per_3__c, slab_val_3__c,
                          slab_4__c, slab_per_4__c, slab_val_4__c, slab_5__c, slab_per_5__c, slab_val_5__c, slab_6__c, slab_per_6__c, slab_val_6__c, slab_target__c, 
                          Condition_Type__r.Id, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Name, Condition_Type__r.Condition_status__c,
                          Condition_Type__r.Is_Conditional__c, Condition_Type__r.Condition_Mode__c, Contract__r.Name, Contract__r.Contract_Type__c, Contract__r.Contract_EDate__c, Contract__r.Total_TO_Fact__c,
                          Contract__r.SimulationNumber__c 
                          FROM Contract_Discount__c
                          WHERE Contract__c = :listContractNego AND Condition_Type__r.Condition_status__c = 'Open' ORDER BY Contract__c, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Name];
		
        Map<String, Map<String, List<Contract_Discount__c>>> linesTypeMap = new Map<String, Map<String, List<Contract_Discount__c>>>();
        // Map the condition type with its max count
        Map<String, Integer> conditionTypeMaxCountMap = new Map<String, Integer>();
        // Map the contract having max count of conditions with the type
        Map<String, Id> conditionTypeContractMap = new Map<String, Id>();
        for (Contract_Discount__c item : listConditions) {
            if(linesTypeMap.containsKey(item.Contract__c)) {
                if(linesTypeMap.get(item.Contract__c).containsKey(item.Condition_Type__r.Name)) {
                    Integer listSize = linesTypeMap.get(item.Contract__c).get(item.Condition_Type__r.Name).size();
                    if(conditionTypeMaxCountMap.get(item.Condition_Type__r.Name) <= listSize) {
                        conditionTypeMaxCountMap.put(item.Condition_Type__r.Name, listSize + 1);
                        conditionTypeContractMap.put(item.Condition_Type__r.Name, item.Contract__c);
                    }
                    linesTypeMap.get(item.Contract__c).get(item.Condition_Type__r.Name).add(item);
                }
                else {
                    linesTypeMap.get(item.Contract__c).put(item.Condition_Type__r.Name, new List<Contract_Discount__c> {item});
                    if(conditionTypeMaxCountMap.get(item.Condition_Type__r.Name) == null) {
                        conditionTypeMaxCountMap.put(item.Condition_Type__r.Name, 1);
                        conditionTypeContractMap.put(item.Condition_Type__r.Name, item.Contract__c);
                    }
                }
            }
            else {
                Map<String, List<Contract_Discount__c>> linesTypeMapValue = new Map<String, List<Contract_Discount__c>>();
                linesTypeMapValue.put(item.Condition_Type__r.Name, new List<Contract_Discount__c> {item});
                linesTypeMap.put(item.Contract__c, linesTypeMapValue);
                if(conditionTypeMaxCountMap.get(item.Condition_Type__r.Name) == null) {
                    conditionTypeMaxCountMap.put(item.Condition_Type__r.Name, 1);
                    conditionTypeContractMap.put(item.Condition_Type__r.Name, item.Contract__c);
                }
            }
        }
        
        // List of wrapper conditions
        List<ConditionWrapper> wrapperConditionsList = new List<ConditionWrapper>();
        for(String key : conditionTypeMaxCountMap.keySet()) {
            Integer maxConditions = conditionTypeMaxCountMap.get(key);
            for (Contract__c contract : listContractNego) {
                List<Contract_Discount__c> conditions = linesTypeMap.get(contract.Id) != null ? linesTypeMap.get(contract.Id).get(key) : null;
                Id mainContractId = conditionTypeContractMap.get(key);
                // copy then push all conditions if not exists for current contract in loop
                if(conditions == null) {
                    List<Contract_Discount__c> toCopyConditions = linesTypeMap.get(mainContractId).get(key);
                    wrapperConditionsList.addAll(copyConditionsToContract(contract, toCopyConditions));
                }
                else {
                    // push existing conditions
                    for (Contract_Discount__c condition : conditions) {
                        ConditionWrapper cw = new ConditionWrapper(condition, condition.Condition_Type__r, condition.Contract__r);
                        wrapperConditionsList.add(cw);
                    }
                    // copy remaining conditions to match the contract having the max count
                    Integer currentCondtitionsCount = conditions.size();
                    Integer diff = maxConditions - currentCondtitionsCount;
                    if(diff > 0) {
                        List<Contract_Discount__c> toCopyConditions = new List<Contract_Discount__c>();
                        for(Integer ndx = currentCondtitionsCount; ndx < maxConditions; ndx++) {
                            toCopyConditions.add(linesTypeMap.get(mainContractId).get(key).get(ndx));
                        }
                        wrapperConditionsList.addAll(copyConditionsToContract(contract, toCopyConditions));
                    }
                }
            }
        }

        /********
        refContractConditionsList = new List<Contract_Discount__c>();
        List<ConditionWrapper> wrappedConditions = new List<ConditionWrapper>();
        for (Contract_Discount__c cond : listConditions) {
            // fill the list of main contract conditions to be used as default conditions for others type
            if(refContractId != null && cond.Contract__c == refContractId) {
                refContractConditionsList.add(cond);
            }
            ConditionWrapper cw = new ConditionWrapper(cond, cond.Condition_Type__r, cond.Contract__r);
            wrappedConditions.add(cw);
        }
        
        // On crée localement les conditions qui n'existent pas
        for (Contract__c contractNego : listContractNego) {
            for (Contract_Discount__c cond1 : listConditions) {
                if (cond1.Contract__c == contractNego.Id) {
                    continue; // skips to the next iteration of the loop
                }
                boolean existsForContract = false;
                for (Contract_Discount__c cond2 : listConditions) {
                    if (cond2.Contract__c == contractNego.Id && cond1.Condition_Type__r.Name == cond2.Condition_Type__r.Name) {
                        existsForContract = true;
                        break; // exits the entire loop
                    }
                }
                
                if (!existsForContract) {
                    Contract_Discount__c newCond = new Contract_Discount__c();
                    newCond.Condition_Type__c = cond1.Condition_Type__c;
                    newCond.Contract__c = contractNego.Id;
                    newCond.Value_per__c = null;
                    newCond.Value_amt__c = null;
                    newCond.Disc_BDate__c = contractNego.Contract_BDate__c;
                    newCond.Disc_EDate__c = contractNego.Contract_EDate__c;
                    newCond.Product_Scope__c = cond1.Product_Scope__c;
                    newCond.BU_Scope__c = cond1.BU_Scope__c;
                    newCond.Nego_Discount_Type__c = cond1.Condition_Type__r.Nego_Discount_Type__c;
                    
                    Pol_Com_Condition__c cDef = new Pol_Com_Condition__c();
                    cDef.Id = cond1.Condition_Type__c;
                    cDef.Name = cond1.Condition_Type__r.Name;
                    cDef.Condition_status__c = cond1.Condition_Type__r.Condition_status__c;
                    cDef.Nego_Discount_Type__c = cond1.Condition_Type__r.Nego_Discount_Type__c;
                    cDef.Is_Conditional__c = cond1.Condition_Type__r.Is_Conditional__c;
                    
                    ConditionWrapper newCw = new ConditionWrapper(newCond, cDef, contractNego);
                    wrappedConditions.add(newCw);
                }
            }
        }
        ********/

        /***boolean createMode = false;
        Integer year = negoYear - 1;
        if(listContractNego.size() == 1 && listContractNego.get(0).Contract_EDate__c.Year() == year) {
        	createMode = true;
        }***/
        retrieveExistingMatrice(wrapperConditionsList/*wrappedConditions*/, createMode);
		
        matrice.setNumberLines();
        matrice.calculTotals();
        matrice.calculateIndexes();
        return null;
    }
    // clone a condition with empty values
    private List<ConditionWrapper> copyConditionsToContract(Contract__c contract, List<Contract_Discount__c> conditions) {
        List<ConditionWrapper> conditionWrapperList = new List<ConditionWrapper>();
        for(Contract_Discount__c item : conditions) {
            Contract_Discount__c newCondition = new Contract_Discount__c(Contract__c = contract.Id,
                                                                         Nego_Discount_Type__c = item.Condition_Type__r.Nego_Discount_Type__c,
                                                                         Condition_Type__c = item.Condition_Type__c);
            // Make condition for reference contract empty because it's not used
            if(contract.Contract_Type__c != TYPE_CONTRACT) {
                newCondition.Value_per__c = null;
                newCondition.Value_amt__c = null;
                newCondition.Disc_BDate__c = contract.Contract_BDate__c;
                newCondition.Disc_EDate__c = contract.Contract_EDate__c;
                newCondition.Product_Scope__c = item.Product_Scope__c;
                newCondition.BU_Scope__c = item.BU_Scope__c;
            }
            Pol_Com_Condition__c conditionDef = new Pol_Com_Condition__c();
            conditionDef.Id = item.Condition_Type__c;
            conditionDef.Name = item.Condition_Type__r.Name;
            conditionDef.Condition_status__c = item.Condition_Type__r.Condition_status__c;
            conditionDef.Nego_Discount_Type__c = item.Condition_Type__r.Nego_Discount_Type__c;
            conditionDef.Is_Conditional__c = item.Condition_Type__r.Is_Conditional__c;
            newCondition.Condition_Type__r = conditionDef;
            conditionWrapperList.add(new ConditionWrapper(newCondition, conditionDef, contract));
        }
        return conditionWrapperList;
    }
    
    // public ConditionWrapper(Contract_Discount__c condition, Pol_Com_Condition__c conditionDefinition, Contract__c contractNego) {
    
    //       if(contractNego.Id == null) {
    //         this.condition = new Contract_Discount__c();
    //         this.conditionDefinition = new Pol_Com_Condition__c();
    //         this.conditionDefinition.Name = conditionDefinition.Name;
    //         this.conditionDefinition.Condition_status__c = conditionDefinition.Condition_status__c;
    //         this.conditionDefinition.Nego_Discount_Type__c = conditionDefinition.Nego_Discount_Type__c;
    //       }
    //       else {
    //         this.condition = condition;
    //         this.conditionDefinition = conditionDefinition;
    //       }
    
    //       this.contractNego = contractNego;
    
    //     }
    
    
    // @TestVisible
    // private void createBlankMatrice() {
    //   // Contract__c newContractNego = new Contract__c(Supplier_Nego_Scope__c = selectedNegoScopeId, Supplier__c = supplierId, Contract_EDate__c = date.newInstance(negoYear-1, 12, 31),
    //   //                                                           Contract_BDate__c = date.newInstance(negoYear-1, 1, 1));
    //   // newContractNego.Contract_Type__c = 'Contract';
    //   // listContractNego.add(newContractNego);
    
    
    //   Contract__c newContractNego = listContractNego.get(0);
    
    //   matrice = new Matrice();
    //   matrice.columnsIds = new List<String>();
    //   matrice.lines = new List<Line>();
    //   matrice.columnsIds.add(newContractNego.Contract_Type__c + ' ' + String.valueOf(negoYear - 1));
    
    //   Cell cell;
    //   Contract_Discount__c condition;
    //   Pol_Com_Condition__c conditionDefinition;
    
    //   Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
    //   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    //   for(Schema.PicklistEntry f : ple) {
    //     for(Integer i = 1 ; i <= MIN_NUM_LINES_BY_CONDITION_TYPES ; i++) {
    //       cell = new Cell();
    //       condition = new Contract_Discount__c(Value_per__c = 0, Value_amt__c = 0);
    //       conditionDefinition = new Pol_Com_Condition__c(Name = 'New line ' + numNewLine);
    //       numNewLine++;
    
    //       cell.isReadOnly = true;
    //       cell.isSubTotal = false;
    //       cell.isEmpty = true;
    //       cell.type = f.getValue();
    //       cell.amount = 0;
    //       cell.percent = 0;
    //       cell.computedAmount = 0;
    //       cell.conditionWrapper = new ConditionWrapper(condition, conditionDefinition, newContractNego);
    //       cell.conditionWrapper.conditionDefinition.Condition_status__c = 'Open';
    //       cell.conditionWrapper.conditionDefinition.Nego_Discount_Type__c = f.getValue();
    
    //       matrice.put(newContractNego.Contract_Type__c + ' ' + String.valueOf(negoYear - 1), conditionDefinition.Name, cell);
    //     }
    //   }
    
    //   for(Line line : matrice.lines) {
    //     line.isNewLine = true;
    //   }
    
    //   // On ajoute les le contrat Target
    //   addContract();
    //   // On ajoute la simulation 1
    //   addContract();
    // }
    
    
    private void retrieveExistingMatrice(List<ConditionWrapper> wrappedConditions, boolean createMode) {
        matrice = new Matrice();
        //matrice.columnsIds = new List<String>();
        matrice.lines = new List<Line>();

        for (Contract__c contractNego : listContractNego) {
            String columnId = contractNego.Contract_Type__c == TYPE_SIMULATION
                ? contractNego.Contract_Type__c + ' ' + contractNego.SimulationNumber__c + ' ' + contractNego.Contract_EDate__c.year()
                : contractNego.Contract_Type__c + ' ' + contractNego.Contract_EDate__c.year();
            // in case more than one ref contract
            if(contractNego.Id != null) {
                columnId += '-' + contractNego.Id;
            }
            matrice.columnsIds.add(columnId);
            WrapperColumn c = new WrapperColumn(contractNego);
            if(contractNego.Contract_Type__c == TYPE_SIMULATION && selectedContractId == null) {
                ////c.selected = true;
                selectedContractId = contractNego.Id;
				c.isLocked = objectIsLocked(selectedContractId);
            }
            matrice.columns.add(c);
        }
        
        // numContractSimulation = 0;

        String prevContractId = null;
        Cell cell;
        for (ConditionWrapper wCond : wrappedConditions) {
            cell = new Cell(wCond);
            if(wCond.condition.Condition_Type__r.Is_Conditional__c || wCond.conditionDefinition.Is_Conditional__c) {
                cell.mapConditionToSlabs(wCond.condition);
            }
            // check if condition is locked
            if (wCond.contractNego.Contract_Type__c == TYPE_SIMULATION) {
                if(objectIsLocked(wCond.contractNego.Id) == true) {
                    isReadApproval = true;
                }
            }
            cell.isReadOnly = wCond.contractNego.Contract_Type__c == TYPE_CONTRACT || isReadApproval;
            cell.isSubTotal = false;
            cell.isEmpty = wCond.contractNego.Contract_Type__c == TYPE_CONTRACT && wCond.condition.Id == null;
            cell.type = wCond.conditionDefinition.Nego_Discount_Type__c;
            cell.computedAmount = 0;
            cell.amount = wCond.condition.Value_amt__c;
            cell.percent = wCond.condition.Value_per__c;
            ////cell.conditionWrapper = wCond; //new ConditionWrapper(condition, condition.Condition_Type__r, condition.Contract__r);
            // cell.conditionWrapper.conditionDefinition.Condition_status__c = 'Open';
            // cell.conditionWrapper.conditionDefinition.Nego_Discount_Type__c = condition.Condition_Type__r.Nego_Discount_Type__c;
            
            
            String lineId = matrice.getlineId(wCond.contractNego.Id, wCond.conditionDefinition.Name);//// wCond.conditionDefinition.Name;
            String columnId = wCond.contractNego.Contract_Type__c == TYPE_SIMULATION
                ? wCond.contractNego.Contract_Type__c + ' ' + wCond.contractNego.SimulationNumber__c + ' ' + wCond.contractNego.Contract_EDate__c.year()
                : wCond.contractNego.Contract_Type__c + ' ' + wCond.contractNego.Contract_EDate__c.year();
            // in case more than one ref contract
            if(wCond.contractNego.Id != null) {
                columnId += '-' + wCond.contractNego.Id;
            }
            matrice.put(columnId, lineId, cell);
        }

        if (createMode) {

            // On ajoute les le contrat Target
            addContract();
            // On ajoute la simulation 1
            addContract();
            
            // On ajoute 3 conditions vides par type
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry f : ple) {
                for (Integer i = 1; i <= MIN_NUM_LINES_BY_CONDITION_TYPES; i++) {
                    addCondition(f.getValue());
                }
            }
            
            matrice.sortMatriceLinesByConditionType();
        }
        
        // Cell cell;
        // for(Contract_Discount__c condition : listConditions) {
        //     cell = new Cell();
        //     cell.isReadOnly = condition.Contract__r.Contract_Type__c == 'Contract' ? true : false;
        //     cell.isSubTotal = false;
        //     cell.isEmpty = false;
        //     cell.type = condition.Condition_Type__r.Nego_Discount_Type__c;
        //     cell.computedAmount = 0;
        //     cell.amount = condition.Value_amt__c;
        //     cell.percent = condition.Value_per__c;
        //     cell.conditionWrapper = new ConditionWrapper(condition, condition.Condition_Type__r, condition.Contract__r);
        //     cell.conditionWrapper.conditionDefinition.Condition_status__c = 'Open';
        //     cell.conditionWrapper.conditionDefinition.Nego_Discount_Type__c = condition.Condition_Type__r.Nego_Discount_Type__c;
        
        
        //     String lineId = condition.Condition_Type__r.Name;
        //     String columnId = condition.Contract__r.Contract_Type__c == 'Simulation'
        //                           ? condition.Contract__r.Contract_Type__c + ' ' + condition.Contract__r.SimulationNumber__c + ' ' + condition.Contract__r.Contract_EDate__c.year()
        //                           : condition.Contract__r.Contract_Type__c + ' ' + condition.Contract__r.Contract_EDate__c.year();
        //     matrice.put(columnId, lineId, cell);
        // }
        computeAmount();
    }
    
    public List<Contract_Discount__c> refContractConditionsList { get; set; }
    public PageReference addContract() {
        Contract__c newContractNego = new Contract__c(Supplier_Nego_Scope__c = selectedNegoScopeId, Supplier__c = supplierId, Contract_EDate__c = date.newInstance(negoYear, 12, 31),
                                                      Contract_BDate__c = date.newInstance(negoYear, 1, 1),Contract_BU__c=listNewContractNego.get(0).Contract_BU__c,Parent_Contract__c=listNewContractNego.get(0).Id,CurrencyIsoCode = listNewContractNego.get(0).CurrencyIsoCode);
        String columnHeaderName;
        if (existingTargetType == false && addedTargetType == false) {
            newContractNego.Contract_Type__c = TYPE_TARGET;
            columnHeaderName = newContractNego.Contract_Type__c + ' ' + negoYear;
            addedTargetType = true;
        } else {
            numContractSimulation = numContractSimulation + 1;
            newContractNego.Contract_Type__c = TYPE_SIMULATION;
            newContractNego.SimulationNumber__c = numContractSimulation;
            columnHeaderName = 'Round' + ' ' + numContractSimulation + ' ' + negoYear;
        }
        newContractNego.Name = columnHeaderName + ' *';
        newContractNego.TO1__c = refTO;
        newContractNego.Total_TO_Ref__c = totalRefTO;
        WrapperColumn c = new WrapperColumn(newContractNego);
        matrice.columnsIds.add(columnHeaderName);
        matrice.columns.add(c);
        
        listContractNego.add(newContractNego);
        
        Cell cell;
        Contract_Discount__c condition;
        Pol_Com_Condition__c conditionDefinition;

        for (Integer i = 0; i < matrice.lines.size(); i++) {
            Cell refCell = matrice.lines.get(i).cells.get(0);
            Decimal a = refCell.amount;
            Decimal p = refCell.percent;
            String t = matrice.lines.get(i).type;
            Contract_Discount__c parentCondition = refCell.conditionWrapper.condition;
            Id ns = parentCondition.Product_Scope__c == null ? selectedNegoScopeId : parentCondition.Product_Scope__c;
            Id bu = parentCondition.BU_Scope__c == null ? supplier.Country_origin__c : parentCondition.BU_Scope__c;
            condition = new Contract_Discount__c(Condition_Type__c = refCell.conditionWrapper.conditionDefinition.Id,
                                                 Value_per__c = p, Value_amt__c = a, Disc_BDate__c = newContractNego.Contract_BDate__c,
                                                 Disc_EDate__c = newContractNego.Contract_EDate__c, Nego_Discount_Type__c = t,
                                                 Product_Scope__c = ns, BU_Scope__c = bu,
                                                 /**Base_TO_Nego__c = parentCondition.Base_TO_Nego__c,**/ Reference_condition__c = parentCondition.Id);
            conditionDefinition = new Pol_Com_Condition__c(Condition_status__c = 'Open', Nego_Discount_Type__c = t);
            ConditionWrapper conditionWrapper = new ConditionWrapper(condition, conditionDefinition, newContractNego);
            
            cell = new Cell(conditionWrapper);
            if(matrice.lines.get(i).isConditional) {
                cell.mapConditionToSlabs(parentCondition);
            }
            cell.isReadOnly = false;
            cell.isSubTotal = false;
            cell.isEmpty = true;
            cell.type = matrice.lines.get(i).type;
            cell.amount = a;
            cell.percent = p;
            cell.computedAmount = 0;
            // cell.conditionWrapper.condition.Condition_Type__c = matrice.lines.get(i).cells.get(0).conditionWrapper.condition.Condition_Type__c;
            matrice.put(columnHeaderName, matrice.lines.get(i).lineId, cell);
        }
        matrice.calculTotals();
        matrice.calculateIndexes();
        return null;
    }
    
    
    // Ajout d'une condition depuis la page
    public PageReference addCondition() {
        String selectedLineType = selectedLineLabel.remove('Total ');
        PageReference pRef = this.addCondition(selectedLineType);
        matrice.sortMatriceLinesByConditionType();
        matrice.calculTotals();
        return pRef;
    }
    
    private PageReference addCondition(String type) {
        Cell cell;
        Contract_Discount__c condition;
        Pol_Com_Condition__c conditionDefinition;
        numNewLine = numNewLine + 1;

        for (Integer i = 0; i < matrice.columnsIds.size(); i++) {
            Contract__c contract = listContractNego.get(i);
            //condition = new Contract_Discount__c(Value_per__c = 0, Value_amt__c = 0, Contract__c = listContractNego.get(i).Id);
            condition = new Contract_Discount__c(Contract__c = contract.Id, Disc_BDate__c = contract.Contract_BDate__c,
                                                 Disc_EDate__c = contract.Contract_EDate__c, Nego_Discount_Type__c = type,
                                                 Product_Scope__c = contract.Supplier_Nego_Scope__c, BU_Scope__c = contract.Contract_BU__c);
            conditionDefinition = new Pol_Com_Condition__c(Name = 'New line ' + numNewLine, Condition_status__c = 'Open', Nego_Discount_Type__c = type);
            ConditionWrapper conditionWrapper = new ConditionWrapper(condition, conditionDefinition, listContractNego.get(i));
            cell = new Cell(conditionWrapper);

            cell.isReadOnly = listContractNego.get(i).Contract_Type__c == TYPE_CONTRACT; // && existingContractType == true ? true : false;
            cell.isDisabled = true;
            cell.isSubTotal = false;
            cell.isEmpty = true;
            cell.type = type;
            cell.amount = 0;
            cell.percent = 0;
            cell.computedAmount = 0;
            
            //cell.conditionWrapper.conditionDefinition.Name = matrice.lines;
            matrice.put(matrice.columnsIds.get(i), conditionDefinition.Name, cell);
        }
        
        Line theNewLine = matrice.lines.get(matrice.lines.size() - 1);
        theNewLine.isNewLine = true;
        // matrice.sortMatriceLinesByConditionType();
        // matrice.calculTotals();
        return null;
    }
    
    
    // public PageReference reinitValuesContractN() {
    //   for(Integer i = 0 ; i<matrice.lines.size() ; i++) {
    //     if(matrice.lines.get(i).numLine == selectedLineNumber) {
    //       for(Cell cell : matrice.lines.get(i).cells) {
    //         if(cell.conditionWrapper.contractNego.Contract_Type__c != 'Contract') {
    //           cell.conditionWrapper.condition.Value_amt__c = null;
    //           cell.conditionWrapper.condition.Value_per__c = null;
    //           cell.computedAmount = 0;
    //           cell.amount = 0;
    //           cell.percent = 0;
    //         }
    //       }
    //       break;
    //     }
    //   }
    
    //   matrice.calculTotals();
    //   return null;
    // }
    
    
    private List<Contract_Discount__c> listConditionToDel = new List<Contract_Discount__c> ();
    public PageReference deleteCondition() {
        // for(Integer i = 0 ; i<matrice.lines.size() ; i++) {
        //   if(matrice.lines.get(i).numLine == selectedLineNumber) {
        //     matrice.lines.remove(i);
        //     break;
        //   }
        // }
        // matrice.setNumberLines();
        // matrice.calculTotals();
        
        Line targetLine = null;
        Integer lineIndex;
        for (Integer i = 0; i<matrice.lines.size(); i++) {
            if (matrice.lines.get(i).numLine == selectedLineNumber) {
                // matrice.lines.remove(i);
                targetLine = matrice.lines.get(i);
                lineIndex = i;
                break;
            }
        }
        
        boolean isOnMainContract = false;
        for (Cell cell : targetLine.cells) {
            if (cell.conditionWrapper.contractNego.Contract_Type__c == TYPE_CONTRACT && cell.conditionWrapper.condition.Id != null) {
                isOnMainContract = true;
            }
            // if(cell.conditionWrapper.contractNego.Contract_Type__c != 'Contract') {
            //   // cell.conditionWrapper.toDelete = true;
            //   cell.conditionWrapper.condition.Value_amt__c = null;
            //   cell.conditionWrapper.condition.Value_per__c = null;
            //   cell.computedAmount = 0;
            //   cell.amount = 0;
            //   cell.percent = 0;
            //   if(cell.conditionWrapper.condition.Id != null) {
            //     listConditionToDel.add(cell.conditionWrapper.condition);
            //   }
            // }
        }
        
        for (Cell cell : targetLine.cells) {
            if (cell.conditionWrapper.contractNego.Contract_Type__c != TYPE_CONTRACT) {
                // cell.conditionWrapper.toDelete = true;
                cell.conditionWrapper.condition.Value_amt__c = null;
                cell.conditionWrapper.condition.Value_per__c = null;
                cell.computedAmount = 0;
                cell.amount = 0;
                cell.percent = 0;
                // Si la condition n'est pas sur le contrat N-1 alors ont sait que la ligne va être supprimée de la matrice
                // >> On peut ajouter la condtion aux conditions à delete
                // >> Sinon on ne l'ajoute pas car elle reste sur le tableau, la cellule est juste vidée et peut-être remodifiée
                // >> Il faudra checker lors de la sauvegarde : si les montants sont à 0 et la condition a un id, alors il faudra la delete à ce moment
                if (!isOnMainContract && cell.conditionWrapper.condition.Id != null) {
                    listConditionToDel.add(cell.conditionWrapper.condition);
                }
            }
        }
        
        if (!isOnMainContract) {
            matrice.lines.remove(lineIndex);
        }
        
        matrice.setNumberLines();
        matrice.calculTotals();
        return null;
    }
    
    /*
    public PageReference recalculatePercent() {
        for(Line line : matrice.lines) {
            for(Integer i = 0 ; i<line.cells.size() ; i++) {
                line.cells.get(i).conditionWrapper.contractNego = listContractNego.get(i);
                line.cells.get(i).conditionWrapper.calculatePercent();
            }
        }
        matrice.calculTotals();
        return null;
    }
    
    
    public PageReference recalculateAmount() {
        for(Line line : matrice.lines) {
            for(Integer i = 0 ; i<line.cells.size() ; i++) {
                line.cells.get(i).conditionWrapper.contractNego = listContractNego.get(i);
                line.cells.get(i).conditionWrapper.calculateAmount();
            }
        }
        matrice.calculTotals();
        return null;
    }
    */
    
    public PageReference computeAmount() {
        for (Line line : matrice.lines) {
            for (Integer i = 0; i<line.cells.size(); i++) {
                try {
                    line.cells.get(i).conditionWrapper.contractNego = listContractNego.get(i);
                    line.cells.get(i).computeAmount();
                } catch(Exception e) {
                    String columnName = matrice.columnsIds.get(i);
                    throw new NOException(line.lineId + ' - ' + i + ' (' + columnName + ') - ' + line.cells.get(i));
                }
            }
        }
        matrice.calculTotals();
        matrice.calculateIndexes();
        return null;
    }
    
    
    public PageReference saveContracts() {
        
        if (selectedNegoScopeId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Error_MustSelectNegoScope));
            return null;
        }
        
        for (Integer i = 0; i<matrice.lines.size(); i++) {
            String lineIdi = matrice.lines.get(i).lineId;
            if (lineIdi == null || lineIdi.trim().equals('')) {
                continue;
            }
            // Check if 2 lines on the same condition
            /*********
            for (Integer j = 0; j < matrice.lines.size(); j++) {
                if (i != j && lineIdi == matrice.lines.get(j).lineId) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Error_TwolinesOnSameCondition));
                    return null;
                }
            }
            *********/
        }
        
        if (!Contract_Discount__c.sObjectType.getDescribe().isDeletable()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Contract Discounts'));
            return null;
        }
        
        try {
            ////delete listConditionToDel;
            listConditionToDel = new List<Contract_Discount__c> ();
            
            List<Contract_Discount__c> listNewConditionsToSave = new List<Contract_Discount__c> ();
            List<Contract_Discount__c> listExistingConditionsToSave = new List<Contract_Discount__c> ();
            List<Contract_Discount__c> listConditionsToSave = new List<Contract_Discount__c> ();
            List<Pol_Com_Condition__c> listConditionDefinitionToSave = new List<Pol_Com_Condition__c> ();
            List<Contract__c> listContractNegoToSave = new List<Contract__c> ();
            
            // Sauvegarde des contrats existants et nouveaux sauf le contrat Contract N-1
            for (Integer i = 0; i<listContractNego.size(); i++) {
                Contract__c aContract = listContractNego.get(i);
                String contractType = aContract.Contract_Type__c;
                // Ignore save for ref contract
                if (contractType == TYPE_CONTRACT) {
                    continue;
                }
                
                // Generate a contract number for new contracts
                if(aContract.Id == NULL) {
                    String contractNumber = contractType.substring(0, 3) + '-' + DateTime.now().getTime();
                    if (contractType == TYPE_TARGET) {
                        aContract.name = 'Target ' + negoYear;
                        aContract.SimulationNumber__c = 0;
                    } else {
                        if (contractType == TYPE_SIMULATION) {
                            aContract.name = 'Round ' + aContract.SimulationNumber__c + ' ' + negoYear;
                            contractNumber += '-' + aContract.SimulationNumber__c;
                            aContract.D_N__c = 'N';
                        }
                    }
                    aContract.Contract_Numbder__c = contractNumber;
                }
                listContractNegoToSave.add(aContract);
            }
            
            // fields to be checked
            String[] contractNegoToSaveFields = new String[] { 'Name', getFieldName('Contract_BU__c'), getFieldName('Comment__c'), getFieldName('Contract_EDate__c'),
                getFieldName('Contract_Numbder__c'), getFieldName('Contract_BDate__c'),
                getFieldName('Contract_Type__c'), getFieldName('Duration__c'), getFieldName('Duration_type__c'), getFieldName('Parent_Contract__c'),
                getFieldName('SimulationNumber__c'), getFieldName('Status__c'), getFieldName('Status_BDate__c'), getFieldName('Status_EDate__c'), getFieldName('Supplier__c'),
                getFieldName('Supplier_Nego_Scope__c'), getFieldName('Tactite_reconduction__c'), getFieldName('TO1__c') };
                    
                    if(!checkCreatibility(Contract__c.SObjectType, contractNegoToSaveFields)) {
                        return null;
                    }
            
            // fields to be checked
            String[] contractNegoToSaveFields2 = new String[] { 'Name', getFieldName('Contract_BU__c'), getFieldName('Comment__c'), getFieldName('Contract_EDate__c'),
                getFieldName('Contract_Numbder__c'), getFieldName('Contract_BDate__c'),
                getFieldName('Contract_Type__c'), getFieldName('Duration__c'), getFieldName('Duration_type__c'), getFieldName('Parent_Contract__c'),
                getFieldName('SimulationNumber__c'), getFieldName('Status__c'), getFieldName('Status_BDate__c'), getFieldName('Status_EDate__c'),
                getFieldName('Supplier_Nego_Scope__c'), getFieldName('Tactite_reconduction__c'), getFieldName('TO1__c') };
                    if(!checkUpdatibility(Contract__c.SObjectType, contractNegoToSaveFields2)) {
                        return null;
                    }
            upsert listContractNegoToSave;
            // in case we have no contract we save all contract to have the id of parent contract
            // add assign it to child contract ( simulate / target )
            if(existingdefaultContract == false) {
                if(listContractNegoToSave!= null && listContractNegoToSave.size()> 0) {
                    List<Contract__c> newSavedContract = new List<Contract__c>();
                    String contractId;
                    
                    for(Contract__c savedContract : listContractNegoToSave) {
                        if(savedContract.Contract_Type__c == TYPE_CONTRACT) {
                            contractId = savedContract.Id;
                        } else {
                            savedContract.Parent_Contract__c = contractId;
                            newSavedContract.add(savedContract);
                        }
                    }
                    upsert newSavedContract;
                }	
            }
            
            //upsert listContractNego;
            // Sauvegarde des conditions existantes et nouvelles (Contract_Discount__c)
            for (Line line : matrice.lines) {
                if (line.lineId == null || line.lineId.trim().equals('')) {
                    continue;
                }
                for (Integer i = 0; i<listContractNego.size(); i++) {
                    Cell cell = line.cells.get(i);
                    
                    // if(listContractNego.get(i).SimulationNumber__c == 2) {
                    //   throw new NOException('' + cell.conditionWrapper.condition + ' - CondDef: ' + cell.conditionWrapper.conditionDefinition);
                    // }
                    
                    if (cell.isSubTotal || cell.conditionWrapper.condition.Condition_Type__c == null || cell.isReadOnly == true) {
                        continue;
                    }
                    
                    // if(cell.conditionWrapper.toDelete) {
                    //   continue;
                    // }
                    
                    if ((cell.conditionWrapper.condition.Value_amt__c == null || cell.conditionWrapper.condition.Value_amt__c <= 0) && (cell.conditionWrapper.condition.Value_per__c == null || cell.conditionWrapper.condition.Value_per__c <= 0)) {
                        // Il s'agit d'une condition qui existait déjà en base et qui a été reset
                        if (cell.conditionWrapper.condition.Id != null) {
                            listConditionToDel.add(cell.conditionWrapper.condition);
                        }
                        continue;
                    }
                    
                    cell.conditionWrapper.contractNego = listContractNego.get(i);
                    if (cell.conditionWrapper.condition.Contract__c == null) {
                        cell.conditionWrapper.condition.Contract__c = listContractNego.get(i).Id;
                    }
                    cell.conditionWrapper.condition.Disc_BDate__c = cell.conditionWrapper.condition.Disc_BDate__c != null ? cell.conditionWrapper.condition.Disc_BDate__c : listContractNego.get(i).Contract_BDate__c;
                    cell.conditionWrapper.condition.Disc_EDate__c = cell.conditionWrapper.condition.Disc_EDate__c != null ? cell.conditionWrapper.condition.Disc_EDate__c : listContractNego.get(i).Contract_EDate__c;
                    cell.conditionWrapper.condition.CurrencyIsoCode = listContractNego.get(i).CurrencyIsoCode;

                    if(cell.conditionWrapper.condition.Product_Scope__c == null) {
                        cell.conditionWrapper.condition.Product_Scope__c = listContractNego.get(i).Supplier_Nego_Scope__c;
                    }
                    if(cell.conditionWrapper.condition.BU_Scope__c == null) {
                        cell.conditionWrapper.condition.BU_Scope__c = listContractNego.get(i).Contract_BU__c;
                    }
                    // set the slabs for conditional lines cell only
                    if(line.isConditional) {
                        cell.mapSlabsToCondition();
                    }
                    listConditionsToSave.add(cell.conditionWrapper.condition);
                }
            }
            if (!Contract_Discount__c.sObjectType.getDescribe().isDeletable()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Contract Discounts'));
                return null;
            }
            delete listConditionToDel;
            
            // fields to be checked
            String[] conditionsToSaveFields = new String[] { getFieldName('Value_per__c'), getFieldName('Value_amt__c'),
                getFieldName('Disc_BDate__c'), getFieldName('Disc_EDate__c'), getFieldName('Condition_Type__c'), getFieldName('Contract__c'),
                getFieldName('Contract_Group__c'), getFieldName('Rank__c'), getFieldName('Status__c'), getFieldName('Nego_Discount_Type__c') };
                    if(!checkCreatibility(Contract_Discount__c.SObjectType, conditionsToSaveFields)) {
                        return null;
                    }
            // fields to be checked
            String[] conditionsToSaveFields2 = new String[] { getFieldName('Value_per__c'), getFieldName('Value_amt__c'),
                getFieldName('Disc_BDate__c'), getFieldName('Disc_EDate__c'), getFieldName('Condition_Type__c'),
                getFieldName('Contract_Group__c'), getFieldName('Rank__c'), getFieldName('Status__c'), getFieldName('Nego_Discount_Type__c') };
                    if(!checkUpdatibility(Contract_Discount__c.SObjectType, conditionsToSaveFields2)) {
                        return null;
                    }

            upsert listConditionsToSave;
            
            // refresh the matrice
            refreshMatrix();
            // save Nego Plan
            saveNegoPlan();
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.ContractsSaved));
            PageReference pRef = ApexPages.currentPage();
            pRef.getParameters().put('supplier', '' + supplierId);
            pRef.getParameters().put('negoyear', sNegoYear);
            pRef.getParameters().put('negoid', '' + selectedNegoScopeId);
            pRef.setRedirect(false);
            return pRef;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }
    /**
     * Refresh Matrix after submit action
     * */
    public void refreshMatrix() {
        createMode = false;
        selectedContractId = null;
        retrieveMapListConditions();
    }
    
    public Contract__c refContract {get;set;}
    /**
     * open popup to generate executive summary
     * */
    public PageReference executiveSummary(Id selectedContractId) {
        executiveSummaryMap = new Map<ExecutiveSummaryRecord, List<ExecutiveSummaryRecord>>();
        conditionExtraDataList = new List<GroupConditionsWrapper>();
        try {
            ////Contract__c refContract;
            // load contracts
            List<Contract__c> contracts = [SELECT c.Id, c.Name, c.Contract_Type__c, c.Supplier__c, c.Contract_BDate__c, c.Total_TO_Fact__c,
                                           c.Total_TO__c, c.Total_TO_Actu__c, c.Buying_Payment_Term_Abbrev__c, c.Services_Payment_Term_Abbrev__c,
                                           c.Supplier_Nego_Scope__r.Name, c.Contract_BU__r.Name,
                                           c.Default_Sales_Conditions__r.Merchandiser_Authorization__c, c.Default_Sales_Conditions__r.Return_Authorization1__c,
                                           Index1_perc__c, Index2_perc__c, Index3_perc__c, Index4_perc__c, Index5_perc__c,
                                           (SELECT Condition_Type__c, Condition_Type__r.Name, Nego_Discount_Type__c, Contract__c, Value_amt__c,
                                            Value_per__c, Y_Actu__c, Product_Scope__c, Product_Scope__r.Name, Is_Conditional__c,
                                            slab_1__c, slab_per_1__c, slab_2__c, slab_per_2__c, slab_3__c, slab_per_3__c, slab_4__c,
                                            slab_per_4__c, slab_5__c, slab_per_5__c, slab_6__c, slab_per_6__c
                                            FROM Contract_Discounts__r ORDER BY Condition_Type__r.Name),
                                           (SELECT Merchandiser_Authorization__c, Return_Authorization1__c
                                            FROM Sales_Conditions_Exception__r)
                                           FROM Contract__c c
                                           WHERE ((c.Contract_Type__c = :TYPE_CONTRACT AND CALENDAR_YEAR(Contract_BDate__c) = :(negoYear-1))
                                                  OR Id = :selectedContractId)
                                           AND Supplier__c = :supplierId
                                           AND Supplier_Nego_Scope__c = :selectedNegoScopeId];
            for(Contract__c item : contracts) {
                if(item.Contract_Type__c == TYPE_CONTRACT) {
                    refContract = item;
                }
                else {
                    currentContract = item;
                }
            }
            if(refContract == null) {
                refContract = new Contract__c();
                ////ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Contract not exist with the selected Nego Scope for the year ' + (negoYear - 1));
                ////ApexPages.addMessage(myMsg);
                ////return null;
            }
            if(currentContract == null) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Simulation not exist with the selected Nego Scope for the year ' + negoYear);
                ApexPages.addMessage(myMsg);
                return null;
            }
            /*
            // load previous contract
            List<Contract__c> previousContracts = [SELECT c.Total_TO__c, c.Total_TO_Actu__c, c.Supplier_Nego_Scope__r.Name, c.Supplier__c, c.Name, c.Id, c.Contract_BU__r.Name, c.Contract_BDate__c, c.Total_TO_Fact__c,
                                                   (SELECT Condition_Type__c, Condition_Type__r.Name, Nego_Discount_Type__c, Contract__c, Value_amt__c, Value_per__c, Y_Actu__c, Product_Scope__c, Product_Scope__r.Name, Is_Conditional__c,
                                                    slab_1__c, slab_per_1__c, slab_2__c, slab_per_2__c, slab_3__c, slab_per_3__c, slab_4__c, slab_per_4__c, slab_5__c, slab_per_5__c, slab_6__c, slab_per_6__c
                                                    From Contract_Discounts__r)
                                                   FROM Contract__c c
                                                   WHERE c.Contract_Type__c = :TYPE_CONTRACT
                                                   AND Supplier__c = :supplierId
                                                   AND Supplier_Nego_Scope__c = :selectedNegoScopeId
                                                   AND CALENDAR_YEAR(Contract_BDate__c) = :(negoYear-1)
                                                   Limit 1];
            
            if(previousContracts != null && previousContracts.size() > 0) {
                refContract = previousContracts.get(0);
            }
            else {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Contract not exist with the selected Nego Scope for the year ' + (negoYear - 1));
            	ApexPages.addMessage(myMsg);
                return null;
            }
            // load current simulation
            List<Contract__c> currentContracts = [SELECT c.Total_TO__c, c.Total_TO_Actu__c, c.Supplier_Nego_Scope__r.Name, c.Supplier__c, c.Name, c.Id, c.Contract_BU__r.Name, c.Contract_BDate__c,
                                                  (SELECT Condition_Type__c, Condition_Type__r.Name, Nego_Discount_Type__c, Contract__c, Value_amt__c, Value_per__c, Y_Actu__c, Product_Scope__c, Product_Scope__r.Name, Is_Conditional__c,
                                                   slab_1__c, slab_per_1__c, slab_2__c, slab_per_2__c, slab_3__c, slab_per_3__c, slab_4__c, slab_per_4__c, slab_5__c, slab_per_5__c, slab_6__c, slab_per_6__c
                                                   From Contract_Discounts__r)
                                                  FROM Contract__c c
                                                  WHERE Id = :selectedContractId
                                                  //c.Contract_Type__c = :TYPE_SIMULATION
                                                  AND Supplier__c = :supplierId
                                                  AND Supplier_Nego_Scope__c = :selectedNegoScopeId
                                                  AND CALENDAR_YEAR(Contract_BDate__c) = :negoYear
                                                  Limit 1];
            if(currentContracts != null && currentContracts.size() > 0) {
                currentContract = currentContracts.get(0);
            }
            else {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Simulation not exist with the selected Nego Scope for the year ' + negoYear);
            	ApexPages.addMessage(myMsg);
                return null;
            }*/
            String refContratID = refContract.Id, newContractID = currentContract.Id;
            Set<ExecutiveSummaryRecord> executiveSummarySet = new Set<ExecutiveSummaryRecord>();
            refProgressiveConditions = new List<Contract_Discount__c>();
            newProgressiveConditions = new List<Contract_Discount__c>();
            Decimal totalRefConditions = 0, totalNewConditions = 0;
            
            totalRefConditions += refContract.Index1_perc__c != null ? refContract.Index1_perc__c : 0;
            totalRefConditions += refContract.Index2_perc__c != null ? refContract.Index2_perc__c : 0;
            totalRefConditions += refContract.Index3_perc__c != null ? refContract.Index3_perc__c : 0;
            totalRefConditions += refContract.Index4_perc__c != null ? refContract.Index4_perc__c : 0;
            
            totalNewConditions += currentContract.Index1_perc__c != null ? currentContract.Index1_perc__c : 0;
            totalNewConditions += currentContract.Index2_perc__c != null ? currentContract.Index2_perc__c : 0;
            totalNewConditions += currentContract.Index3_perc__c != null ? currentContract.Index3_perc__c : 0;
            totalNewConditions += currentContract.Index4_perc__c != null ? currentContract.Index4_perc__c : 0;
            
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
                item.calculateDiffByConditionsType();
                List<ExecutiveSummaryRecord> detailsList = item.executiveSummaryConditionsDetails();
                executiveSummaryMap.put(item, detailsList);
            }
            Contract__c targetContract;
            for(Contract__c c : listContractNego) {
                if(c.Contract_Type__c == TYPE_TARGET) {
                    targetContract = c;
                    continue;
                }
            }
            // Extra Data
            conditionExtraDataList.add(new GroupConditionsWrapper('YTD Purchases', refContract.Total_TO_Fact__c, null));
            conditionExtraDataList.add(new GroupConditionsWrapper('Target', null, targetContract != null ? targetContract.TO1__c : null));
            conditionExtraDataList.add(new GroupConditionsWrapper('Negotiated Budget', null, currentContract.Total_TO__c));
            // add total conditions
            GroupConditionsWrapper totalconditions = new GroupConditionsWrapper('Total Condition', totalRefConditions, totalNewConditions);
            totalconditions.isPercentage = true;
            conditionExtraDataList.add(totalconditions);
            // add total conditions
            GroupConditionsWrapper paymentTerms = new GroupConditionsWrapper('Payment Terms', null, null);
            paymentTerms.sValueRef = refContract.Buying_Payment_Term_Abbrev__c; //Services_Payment_Term_Abbrev__c
            paymentTerms.sValueNew = currentContract.Buying_Payment_Term_Abbrev__c;
            conditionExtraDataList.add(paymentTerms);
        } catch (Exception e) {
            displayPopUpExecutiveSummary = false;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    // Set the cell % based on target slab selection
    // @param key: line key (lineId)
    // @param ndx: cell index
    public void chooseSlabTarget(String key, Integer ndx) {
        for(Line item : matrice.linesTable) {
            if(item.lineId == key) {
                Cell currentCell = item.cells.get(ndx);
                for (Slab s : currentCell.slabs) {
                    if (s.slabTarget) {
                        currentCell.conditionWrapper.condition.slab_target__c = s.slabIndex;
                        currentCell.conditionWrapper.condition.value_per__c = s.percentage;
                        currentCell.conditionWrapper.condition.value_amt__c = s.value;
                    }
                }
            }
        }
    }
    /**
     * 
	 * */
    public class Matrice {
        public List<WrapperColumn> columns { get; set; }
        public List<String> columnsIds { get; set; } // Nom des colonnes (Contract 20xx, Target 20xx, Simul n 20xx,...); A remplir en premier;
        public List<Line> lines { get; set; } // Lignes de la matrice sans les sous-totaux et totaux
        public List<Line> linesTable { get; set; } // Lignes de la matrice avec les sous-totaux et totaux
        private Map<String, Line> totalsLines;
        public List<IndexHead> indexManagement {get;set;}
        public Map<String, Map<String, Integer>> linesTypeMap {get; set;} // Map contract Ids with condition types for counting
        public Matrice() {
            this.columns = new List<WrapperColumn>();
            this.columnsIds = new List<String>();
            this.linesTypeMap = new Map<String, Map<String, Integer>>();
        }
        // Fill the map by contract ids as key and value
        // also a map og condition definition type with value 
        // list of key corresponding on count of each type
        public String getlineId(Id contractId, String conditionType) {
            Integer count = 0;
            if(linesTypeMap.containsKey(contractId)) {
                if(linesTypeMap.get(contractId).containsKey(conditionType)) {
                    count = linesTypeMap.get(contractId).get(conditionType) + 1;
                    linesTypeMap.get(contractId).put(conditionType, count);
                }
                else {
                    linesTypeMap.get(contractId).put(conditionType, count);
                }
            }
            else {
                Map<String, Integer> linesTypeMapValue = new Map<String, Integer>();
                linesTypeMapValue.put(conditionType, count);
                linesTypeMap.put(contractId, linesTypeMapValue);
            }
            return count == 0 ? conditionType : conditionType + ' (' + count + ')';
        }
        
        public void put(String aColumnId, String aLineId, Cell aCell) {
            Integer colIndex = 0;
            for (Integer i = 0; i<columnsIds.size(); i++) {
                if (columnsIds.get(i) == aColumnId) {
                    colIndex = i;
                    break;
                }
            }
            aCell.index = colIndex;
            Line aLine = null;
            for (Line l : lines) {
                if (l.lineId == aLineId) {
                    aLine = l;
                    break;
                }
            }
            if (aLine == null) {
                aLine = createLine(aLineId, aCell.conditionWrapper.condition);
            }
            if (columnsIds.size() > aLine.cells.size()) {
                aLine.cells.add(new Cell());
            }
            aLine.cells.set(colIndex, aCell); // Attention, vérifier que l'ajout à un index i, ne remplace pas la valeur en i; Sinon il faut décaler;
            aLine.type = aLine.cells.get(0).type;
            
            
            String[] conditionModes = aCell.conditionWrapper.condition.Condition_Type__r.Condition_Mode__c != null ? aCell.conditionWrapper.condition.Condition_Type__r.Condition_Mode__c.split(';') : new List<String>();
            for(Integer ndx = 0; ndx < conditionModes.size(); ndx++) {
                if(conditionModes[ndx] == '%') {
                    aLine.enablePercentage = true;
                }
                else if(conditionModes[ndx] == 'U' || conditionModes[ndx] == 'F') {
                    aLine.enableAmount = true;
                }
            }
        }
        /**
        * Calculate the Indexes for each contract
        * @param List of contracts ordered
        * */
        public void calculateIndexes() {
            indexManagement = new List<IndexHead>();
            Integer colIndex = 0;
            // prepare the index management list for each contract
            for (Integer i = 0; i < columns.size(); i++) {
                IndexHead ndxH = new IndexHead();
                indexManagement.add(ndxH);
            }
            // loop over contacts and calculate their indexes value
            for (Integer j = 0; j < columns.size(); j++) {
                for (Line l : Lines) {
                    Cell c = l.Cells.get(j);
                    if(c.conditionWrapper.condition.Index__c == 'Index1')
                        indexManagement.get(j).listIndexes.get(0).value += c.computedAmount;
                    if(c.conditionWrapper.condition.Index__c == 'Index2')
                        indexManagement.get(j).listIndexes.get(1).value += c.computedAmount;
                    if(c.conditionWrapper.condition.Index__c == 'Index3')
                        indexManagement.get(j).listIndexes.get(2).value += c.computedAmount;
                    if(c.conditionWrapper.condition.Index__c == 'Index4')
                        indexManagement.get(j).listIndexes.get(3).value += c.computedAmount;
                }
                IndexHead currentContractIndexHead = indexManagement.get(j);
                for(IndexLine item : currentContractIndexHead.listIndexes) {
                    // Set scale to 0
                    item.value = item.value.setScale(0, RoundingMode.HALF_UP);
                    // Calculate the indexes %
                    if(columns.get(j).contract.TO1__c != NULL && columns.get(j).contract.TO1__c != 0) {
                        item.percentage = item.value / columns.get(j).contract.TO1__c * 100;
                    }
                }

                // Calculate the indexes rate
                Decimal index0 = 100;
                index0 += columns.get(j).contract.Rise_Rate__c != null ? columns.get(j).contract.Rise_Rate__c : 0;
                index0 -= columns.get(j).contract.Depreciation_Rate__c != null ? columns.get(j).contract.Depreciation_Rate__c : 0;
                index0 += columns.get(j).contract.Markdown_Rate_Break__c != null ? columns.get(j).contract.Markdown_Rate_Break__c : 0;
                index0 += columns.get(j).contract.Markdown_Rate_Promo__c != null ? columns.get(j).contract.Markdown_Rate_Promo__c : 0;
                index0 += columns.get(j).contract.Markdown_Rate_Theft__c != null ? columns.get(j).contract.Markdown_Rate_Theft__c : 0;
                columns.get(j).index0 = index0;
                Decimal previousRate = index0;

                for(IndexLine item : currentContractIndexHead.listIndexes) {
                    item.rate = previousRate - item.percentage;
                    previousRate = item.rate;
                }
            }
            // limit all decimal part to 2 digits
            for (IndexHead nh : indexManagement) {
                for (IndexLine nl : nh.listIndexes) {
                    nl.percentage = nl.percentage.setScale(2, RoundingMode.HALF_UP);
                    nl.rate = nl.rate.setScale(2, RoundingMode.HALF_UP);
                }
            }
            // set the indexex in contracts
            for (Integer k = 0; k < columns.size(); k++) {
                columns.get(k).contract.Index1__c = indexManagement.get(k).listIndexes.get(0).rate;
                columns.get(k).contract.Index1_perc__c = indexManagement.get(k).listIndexes.get(0).percentage;
                
                columns.get(k).contract.Index2__c = indexManagement.get(k).listIndexes.get(1).rate;
                columns.get(k).contract.Index2_perc__c = indexManagement.get(k).listIndexes.get(1).percentage;
                
                columns.get(k).contract.Index3__c = indexManagement.get(k).listIndexes.get(2).rate;
                columns.get(k).contract.Index3_perc__c = indexManagement.get(k).listIndexes.get(2).percentage;
                
                columns.get(k).contract.Index4__c = indexManagement.get(k).listIndexes.get(3).rate;
                columns.get(k).contract.Index4_perc__c = indexManagement.get(k).listIndexes.get(3).percentage;
            }
        }
        
        private Line createLine(String aLineId, Contract_Discount__c condition) {
            Line newLine = new Line(columnsIds, aLineId, aLineId, lines);
            newLine.isConditional = condition.Condition_Type__r.Is_Conditional__c;
            lines.add(newLine);
            return newLine;
        }
        
        
        private void calculTotals() {
            List<Schema.PicklistEntry> conditionTypesPLE = Pol_Com_Condition__c.Nego_Discount_Type__c.getDescribe().getPicklistValues();
            Map<String, Line> totalsLines = new Map<String, Line> ();
            for (Schema.PicklistEntry ctPLE : conditionTypesPLE) {
                String conditionType = ctPLE.getValue();
                String label = 'Total ' + ctPLE.getLabel();
                Line aTotalLine = new Line(columnsIds, conditionType, label, lines);
                aTotalLine.isSubTotal = true;
                totalsLines.put(conditionType, aTotalLine);
                
                for (Integer i = 0; i < aTotalLine.cells.size(); i++) {
                    Cell totalCell = totalsLines.get(conditionType).cells.get(i);
                    totalCell.amount = 0;
                    totalCell.percent = 0;
                    totalCell.computedAmount = 0;
                    totalCell.isSubTotal = true;
                    totalCell.isReadOnly = true;
                }
            }
            
            for (Line l : lines) {
                for (Integer i = 0; i<l.cells.size(); i++) {
                    String cellType = l.type; //l.cells.get(i).type;
                    String colId = columnsIds.get(i);
                    Decimal contractTO = columns.get(i).contract.TO1__c;
                    Decimal conditionPercent;
                    Decimal realPercent;
                    
                    // make also the flag is conditional on a total lines to secure calculation (without progressive)
                    if(l.isConditional) {
                        totalsLines.get(cellType).isConditional = true;
                    }
                    // try {
                    if(totalsLines.get(cellType) != null && l.cells.get(i).conditionWrapper != null) {
                        totalsLines.get(cellType).cells.get(i).amount += l.cells.get(i).conditionWrapper.condition.Value_amt__c != null ? l.cells.get(i).conditionWrapper.condition.Value_amt__c : 0;
                        conditionPercent = l.cells.get(i).conditionWrapper.condition.Value_per__c != null ? l.cells.get(i).conditionWrapper.condition.Value_per__c : 0;
                        // count the base TO of condition if not null
                        if(l.cells.get(i).conditionWrapper.condition.Base_TO_Nego__c != null && contractTO != null && contractTO != 0) {
                            realPercent = conditionPercent * l.cells.get(i).conditionWrapper.condition.Base_TO_Nego__c / contractTO;
                        }
                        else {
                            realPercent = conditionPercent;
                        }
                        totalsLines.get(cellType).cells.get(i).percent += realPercent;
                        totalsLines.get(cellType).cells.get(i).computedAmount += l.cells.get(i).computedAmount != null ? l.cells.get(i).computedAmount : 0;
                    }
                    // } catch(Exception e) {
                    //   throw new NOException(l.cells.get(i) + ' - CellType: ' + cellType + ' - LineId: ' + l.lineId + ' - ColsId: ' + colId);
                    // }
                }
            }
            
            Line totalGlobalLine = new Line(columnsIds, 'Totals', 'Totals', lines);
            totalGlobalLine.isSubTotal = false;
            totalGlobalLine.isGlobalTotal = true;
            totalsLines.put('Total', totalGlobalLine);
            
            for (Integer i = 0; i<totalsLines.get('Total').cells.size(); i++) {
                totalsLines.get('Total').cells.get(i).amount = 0;
                totalsLines.get('Total').cells.get(i).percent = 0;
                totalsLines.get('Total').cells.get(i).computedAmount = 0;
                totalsLines.get('Total').cells.get(i).isSubTotal = false;
                totalsLines.get('Total').cells.get(i).isGlobalTotal = true;
                totalsLines.get('Total').cells.get(i).isReadOnly = true;
            }
            
            for (String key : totalsLines.keySet()) {
                for (Integer i = 0; i<totalsLines.get(key).cells.size(); i++) {
                    if (key != 'Total') {
                        totalsLines.get('Total').cells.get(i).amount += totalsLines.get(key).cells.get(i).amount != null ? totalsLines.get(key).cells.get(i).amount : 0;
                        totalsLines.get('Total').cells.get(i).percent += totalsLines.get(key).cells.get(i).percent != null ? totalsLines.get(key).cells.get(i).percent : 0;
                        totalsLines.get('Total').cells.get(i).computedAmount += totalsLines.get(key).cells.get(i).computedAmount != null ? totalsLines.get(key).cells.get(i).computedAmount : 0;
                    }
                }
            }
            
            // Set the Total secure line
            Line totalSecureLine = new Line(columnsIds, 'TotalSecure', 'Total secure', lines);
            totalSecureLine.isSubTotal = false;
            totalSecureLine.isGlobalTotal = true;
            totalsLines.put('TotalSecure', totalSecureLine);
            
            for (Integer i = 0; i<totalsLines.get('TotalSecure').cells.size(); i++) {
                totalsLines.get('TotalSecure').cells.get(i).amount = 0;
                totalsLines.get('TotalSecure').cells.get(i).percent = 0;
                totalsLines.get('TotalSecure').cells.get(i).computedAmount = 0;
                totalsLines.get('TotalSecure').cells.get(i).isSubTotal = false;
                totalsLines.get('TotalSecure').cells.get(i).isGlobalTotal = true;
                totalsLines.get('TotalSecure').cells.get(i).isReadOnly = true;
            }
            for (String key : totalsLines.keySet()) {
                for (Integer i = 0; i<totalsLines.get(key).cells.size(); i++) {
                    Boolean isConditionalLine = totalsLines.get(key).isConditional;
                    if (key != 'Total' && key != 'TotalSecure' && !isConditionalLine) {
                        totalsLines.get('TotalSecure').cells.get(i).amount += totalsLines.get(key).cells.get(i).amount != null ? totalsLines.get(key).cells.get(i).amount : 0;
                        totalsLines.get('TotalSecure').cells.get(i).percent += totalsLines.get(key).cells.get(i).percent != null ? totalsLines.get(key).cells.get(i).percent : 0;
                        totalsLines.get('TotalSecure').cells.get(i).computedAmount += totalsLines.get(key).cells.get(i).computedAmount != null ? totalsLines.get(key).cells.get(i).computedAmount : 0;
                    }
                }
            }
            // calculate the computed rate for total lines
            for (Integer i = 0; i< totalGlobalLine.cells.size(); i++) {
                Decimal contractTO = columns.get(i).contract.TO1__c;
                if(contractTO != null && contractTO != 0) {
                    totalGlobalLine.cells.get(i).computedRate = totalGlobalLine.cells.get(i).computedAmount / contractTO * 100;
                    totalSecureLine.cells.get(i).computedRate = totalSecureLine.cells.get(i).computedAmount / contractTO * 100;
                }
            }
            // Set the progress line
            Line progressLine = new Line(columnsIds, 'Progress', 'Progress', lines);
            progressLine.isSubTotal = false;
            progressLine.isGlobalTotal = true;
            totalsLines.put('Progress', progressLine);
            
            for (Integer i = 0; i<totalsLines.get('Progress').cells.size(); i++) {
                totalsLines.get('Progress').cells.get(i).isSubTotal = false;
                totalsLines.get('Progress').cells.get(i).isGlobalTotal = true;
                totalsLines.get('Progress').cells.get(i).isReadOnly = true;
                if(i > 0) {
                    totalsLines.get('Progress').cells.get(i).isProgress = true;
                }
            }
            Cell refCell = totalsLines.get('Total').cells.get(0);
            for (String key : totalsLines.keySet()) {
                for (Integer i = 0; i < totalsLines.get(key).cells.size(); i++) {
                    if (key != 'Progress' && i > 0) { // ignore the column one (ref contract)
                        Cell totalCell = totalsLines.get('Total').cells.get(i);
                        totalsLines.get('Progress').cells.get(i).amount = refCell.amount != 0 ? ((totalCell.amount - refCell.amount) / refCell.amount) * 100 : 0;
                        totalsLines.get('Progress').cells.get(i).percent = refCell.percent != 0 ? ((totalCell.percent - refCell.percent) / refCell.percent) * 100 : 0;
                        totalsLines.get('Progress').cells.get(i).computedAmount = refCell.computedAmount != 0 ? ((totalCell.computedAmount - refCell.computedAmount) / refCell.computedAmount) * 100 : 0;
                    }
                }
            }
            
            linesTable = new List<Line>();
            for (Schema.PicklistEntry ctPLE : conditionTypesPLE) {
                String conditionType = ctPLE.getValue();
                for (Line l : lines) {
                    if (l.cells.get(0).type == conditionType) {
                        linesTable.add(l);
                    }
                }
                linesTable.add(totalsLines.get(conditionType));
            }
            linesTable.add(totalsLines.get('TotalSecure'));
            linesTable.add(totalsLines.get('Total'));
            linesTable.add(totalsLines.get('Progress'));
        }
        
        
        private void setNumberLines() {
            for (Integer i = 0; i<lines.size(); i++) {
                lines.get(i).numLine = i + 1;
            }
        }
        
        
        private void sortMatriceLinesByConditionType() {
            Map<String, List<Line> > mapLinesByType = new Map<String, List<Line>> ();
            for (Line line : lines) {
                if (!mapLinesByType.containsKey(line.type)) {
                    mapLinesByType.put(line.type, new List<Line>());
                }
                mapLinesByType.get(line.type).add(line);
            }
            
            lines = new List<Line>();
            for (String key : mapLinesByType.keySet()) {
                lines.addAll(mapLinesByType.get(key));
            }
            setNumberLines();
        }
        
    }
    /**
     * 
     * */
    public class Line {
        public String lineId { get; set; } // Nom des Pol_Com_Condition__c.label__c; A remplir en premier;
        public String lineLabel { get; set; }
        public List<Cell> cells { get; set; }
        public String type { get; set; } // Type des Pol_Com_Condition__c.Nego_Discount_Type__c des cellules composants la ligne
        public Boolean isNewLine { get; set; }
        public Boolean newLineNumber { get; set; }
        public Integer numLine { get; set; }
        public Boolean isSelectListDisabled { get; set; }
        public String idConditionType { get; set; }
        public Boolean isConditional { get; set; }
        public Boolean isSubTotal { get; set; }
        public Boolean isGlobalTotal { get; set; }
        public Boolean enablePercentage { get; set; }
        public Boolean enableAmount{ get; set; }
        
        public Id selectedCondDefId { get; set; }
        public Id negoScope { get; set; }
        
        private List<Line> lines;
        
        public Line(List<String> columnsIds, String lineId, String lineLabel, List<Line> lines) {
            this.cells = new List<Cell>();
            this.lineId = lineId;
            this.lineLabel = lineLabel;
            this.isNewLine = false;
            for (Integer i = 0; i<columnsIds.size(); i++) {
                this.cells.add(new Cell());
            }
            this.isSelectListDisabled = false;
            this.isConditional = false;
            this.isSubTotal = false;
            this.isGlobalTotal = false;
            this.lines = lines;
        }
        
        public boolean getShowAddLineButton() {
            return this.isSubTotal && !this.isGlobalTotal;
        }
        
        public List<SelectOption> getConditionsDefOptions() {
            List<SelectOption> condDefOptions = new List<SelectOption>();
            // fields to be checked
            String[] allConditionsDefFields = new String[] {'Id', 'Name', NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'), NegoptimHelper.normalizeAPIName('Index__c')};
            if(NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, allConditionsDefFields)) {
                List<Pol_Com_Condition__c> allConditionsDef = [SELECT Id, Name, Nego_Discount_Type__c, Index__c FROM Pol_Com_Condition__c ORDER BY Name LIMIT 999];
                condDefOptions.add(new SelectOption('', ''));
                for (Pol_Com_Condition__c cd : allConditionsDef) {
                    if (cd.Nego_Discount_Type__c == this.type) {
                        condDefOptions.add(new SelectOption(cd.Id, cd.Name));
                    }
                }
            }
            // The below code retire a condition if already used
            /**********
            for (Line line : lines) {
                for (Integer i = 0; i < condDefOptions.size(); i++) {
                    if (condDefOptions.get(i).getLabel() == line.cells.get(0).conditionWrapper.conditionDefinition.Name) {
                        condDefOptions.remove(i);
                    }
                }
            }
            **********/
            return condDefOptions;
        }
        
        public PageReference testAction() {
            if (lineId == '' || lineId == null) {
                return null;
            }
            this.lineId = selectedCondDefId;

            // fields to be checked
            String[] condDefFields = new String[] {'Id', 'Name', NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'), NegoptimHelper.normalizeAPIName('Is_Conditional__c'), NegoptimHelper.normalizeAPIName('Condition_Mode__c')};
            if(NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, condDefFields)) {
                List<Pol_Com_Condition__c> listCondDef = [SELECT Id, Name, Nego_Discount_Type__c, Is_Conditional__c, Condition_Mode__c
                                                          FROM Pol_Com_Condition__c
                                                          WHERE Id = :lineId];
                if (listCondDef.get(0).Nego_Discount_Type__c != type) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can\'t select a ' + listCondDef.get(0).Nego_Discount_Type__c + ' type for a ' + type + '.'));
                }
                else {
                    this.lineId = listCondDef.get(0).Name;
                    ////this.lineLabel = listCondDef.get(0).Name;
                    this.isSelectListDisabled = true;
                    this.isConditional = listCondDef.get(0).Is_Conditional__c;
                    String[] conditionModes = listCondDef.get(0).Condition_Mode__c != null ? listCondDef.get(0).Condition_Mode__c.split(';') : new List<String>();
                    for(Integer ndx = 0; ndx < conditionModes.size(); ndx++) {
                        if(conditionModes[ndx] == '%') {
                            this.enablePercentage = true;
                        }
                        else if(conditionModes[ndx] == 'U' || conditionModes[ndx] == 'F') {
                            this.enableAmount = true;
                        }
                    }
                    for (Cell cell : this.cells) {
                        this.idConditionType = listCondDef.get(0).Id;
                        cell.conditionWrapper.condition.Condition_Type__c = this.idConditionType;
                        cell.conditionWrapper.conditionDefinition.Name = lineId;
                        cell.isDisabled = false;
                        if(this.isConditional) {
                            cell.mapConditionToSlabs(null);
                        }
                    }
                }
            }
            return null;
        }
    }
    /*
     * 
     * */
    public class Cell {
        public Integer index { get; set; }
        public String key { get; set; }
        public boolean isReadOnly { get; set; }
        private boolean isDisabled;
        public boolean isSubTotal { get; set; }
        public boolean isGlobalTotal { get; set; }
        public boolean isProgress { get; set; }
        public ConditionWrapper conditionWrapper { get; set; }
        public boolean isEmpty { get; set; }
        public String type { get; set; }
        public List<Slab> slabs { get; set; }
        
        public Decimal amount { get; set; }
        public Decimal percent { get; set; }
        public Decimal computedAmount { get; set; }
        public Decimal computedRate { get; set; }
        
        // constructors
        public Cell() {
            this.key = 'NEW';
            this.slabs = new List<Slab>();
        }
        public Cell(ConditionWrapper cw) {
            this.conditionWrapper = cw;
            this.key = cw.condition.Id != null ? (String) cw.condition.Id : 'COPY';
            this.slabs = new List<Slab>();
        }
        public String sComputedAmount {
            get {
                return this.computedAmount != null /*&& this.amount> 0*/ ? this.computedAmount.setScale(0).format() : '';
                //return this.computedAmount.setScale(0).format();
            }
            set;
        }
        
        public String sComputedRate {
            get {
                return NegoptimHelper.formatPercentageValue(this.computedRate, true);
            }
            set;
        }
        // public String getSAmount() {
        //   return
        // }
        public String sAmount {
            get {
                return this.amount != null /*&& this.amount> 0*/ ? this.amount.setScale(2).format() : '';
            }
            set;
        }
        public String sPercent {
            get {
                String decimalSep = NegoptimHelper.getDecimalSeparator();
                String sPercent = this.percent != null /*&& this.percent> 0*/ ? this.percent.setScale(2).format() : '';
                if (sPercent != null && sPercent.trim() != '' && !sPercent.contains(decimalSep)) {
                    sPercent += decimalSep + '00';
                }
                else if (sPercent != null && sPercent.contains(decimalSep)) {
                    decimalSep = decimalSep == '.' ? '\\.' : decimalSep;
                    if (sPercent.split(decimalSep) [1].length()<2) {
                        sPercent += '0';
                    }
                }
                return sPercent;
                
                // return this.percent != null && this.percent> 0 ? this.percent.setScale(2).format() : '';
            }
            set;
        }
        
        public boolean getIsDisabled() {
            return this.isDisabled != null && this.isDisabled;
        }
        
        public void computeAmount() {
            Decimal totalTO = this.conditionWrapper.condition.Base_TO_Nego__c == null ? this.conditionWrapper.contractNego.TO1__c : this.conditionWrapper.condition.Base_TO_Nego__c;
            Decimal percent = this.conditionWrapper.condition.Value_per__c;
            Decimal amount = this.conditionWrapper.condition.Value_amt__c;
            this.computedAmount = 0;
            if (totalTO != null && totalTO> 0) {
                if (percent != null && percent> 0) {
                    this.computedAmount += (totalTO * percent) / 100;
                }
                if (amount != null && amount> 0) {
                    this.computedAmount += amount;
                }
                // this.computedAmount = ((totalTO * percent) / 100) + (amount != null ? this.conditionWrapper.condition.Value_amt__c : 0);
            }
        }
        
        // Load new Slabs for new conditions
        private void loadNewSlabs() {
            for(Integer i = 1; i <= 6; i++) {
                this.slabs.add(new Slab(i, 1));
            }
        }
        // Load Condition data into Slab        
        public void mapConditionToSlabs(Contract_Discount__c refCondition) {
            Contract_Discount__c c = conditionWrapper.condition;
            if(c != null) {
                if(c.Id == null && refCondition == null) {
                    this.loadNewSlabs();
                }
                else {
                    c = c.Id != null ? c : refCondition;
                    // set default target to slab 1 if not exist
                    c.slab_Target__c = c.slab_Target__c == null ? 1 : c.slab_Target__c;
                    Slab newSlab1 = new Slab(1, c.slab_Target__c);
                    newSlab1.threshold = c.slab_1__c;
                    newSlab1.percentage = c.slab_per_1__c;
                    newSlab1.value = c.slab_val_1__c;
                    this.slabs.add(newSlab1);
                    
                    Slab newSlab2 = new Slab(2, c.slab_Target__c);
                    newSlab2.threshold = c.slab_2__c;
                    newSlab2.percentage = c.slab_per_2__c;
                    newSlab2.value = c.slab_val_2__c;
                    this.slabs.add(newSlab2);
                    
                    Slab newSlab3 = new Slab(3, c.slab_Target__c);
                    newSlab3.threshold = c.slab_3__c;
                    newSlab3.percentage = c.slab_per_3__c;
                    newSlab3.value = c.slab_val_3__c;
                    this.slabs.add(newSlab3);
                    
                    Slab newSlab4 = new Slab(4, c.slab_Target__c);
                    newSlab4.threshold = c.slab_4__c;
                    newSlab4.percentage = c.slab_per_4__c;
                    newSlab4.value = c.slab_val_4__c;
                    this.slabs.add(newSlab4);
                    
                    Slab newSlab5 = new Slab(5, c.slab_Target__c);
                    newSlab5.threshold = c.slab_5__c;
                    newSlab5.percentage = c.slab_per_5__c;
                    newSlab5.value = c.slab_val_5__c;
                    this.slabs.add(newSlab5);
                    
                    Slab newSlab6 = new Slab(6, c.slab_Target__c);
                    newSlab6.threshold = c.slab_6__c;
                    newSlab6.percentage = c.slab_per_6__c;
                    newSlab6.value = c.slab_val_6__c;
                    this.slabs.add(newSlab6);
                }
            }
        }
        // Map slab list to the condition properties on save
        public void mapSlabsToCondition() {
            Integer j = 1; // index or real condition slab
            this.slabs.sort();
            for(Integer i = 1; i <= 6; i++) {
                Slab slabItem = this.slabs.get(i - 1);
                if(!slabItem.isEmpty()) {
                    this.conditionWrapper.condition.put('slab_' + j + '__c', slabItem.threshold);
                    this.conditionWrapper.condition.put('slab_per_' + j + '__c', slabItem.percentage);
                    this.conditionWrapper.condition.put('slab_val_' + j + '__c', slabItem.value);
                    j++;
                }                
            }
        }
    }
    /**
     * 
     * */
    public class ConditionWrapper {
        public Contract_Discount__c condition { get; set; }
        public Pol_Com_Condition__c conditionDefinition { get; set; }
        public Contract__c contractNego { get; set; }
        
        public boolean toDelete { get; set; }
        
        public ConditionWrapper(Contract_Discount__c condition, Pol_Com_Condition__c conditionDefinition, Contract__c contractNego) {

            if (contractNego.Id == null) {
                this.condition = condition.clone(); //new Contract_Discount__c(Nego_Discount_Type__c = condition.Nego_Discount_Type__c, Value_per__c = condition.Value_per__c, Value_amt__c = condition.Value_amt__c);
                this.conditionDefinition = new Pol_Com_Condition__c();
                this.conditionDefinition.Id = conditionDefinition.Id;
                this.conditionDefinition.Name = conditionDefinition.Name;
                this.conditionDefinition.Condition_status__c = conditionDefinition.Condition_status__c;
                this.conditionDefinition.Nego_Discount_Type__c = conditionDefinition.Nego_Discount_Type__c;
            }
            else {
                this.condition = condition;
                this.conditionDefinition = conditionDefinition;
            }
            this.contractNego = contractNego;
            this.toDelete = false;
        }
        
        public void calculateAmount() {
            if (this.contractNego.TO1__c != null && this.condition.Value_per__c != null && this.contractNego.TO1__c > 0 && this.condition.Value_per__c > 0) {
                this.condition.Value_amt__c = ((this.condition.Value_per__c * this.contractNego.TO1__c) / 100).setScale(0);
            }
        }
        
        public void calculatePercent() {
            if (this.contractNego.TO1__c != null && condition.Value_amt__c != null && this.contractNego.TO1__c > 0 && condition.Value_amt__c > 0) {
                this.condition.Value_per__c = ((this.condition.Value_amt__c * 100) / this.contractNego.TO1__c).setScale(2);
            }
        }
    }
    /**
     * Group Conditions Wrapper class used in executive summary popup
     * */
    public class GroupConditionsWrapper {
        public String conditionType { get; set; }
        public String conditionName { get; set; }
        public Decimal valueRef { get; set; }
        public String sValueRef {
            get {
                if(this.isPercentage)
                    return NegoptimHelper.formatPercentageValue(this.valueRef, true);
                return this.valueRef != null ? this.valueRef.format() : this.sValueRef;
            }
            set;
        }
        public Decimal valueNew { get; set; }
        public String sValueNew {
            get {
                if(this.isPercentage)
                    return NegoptimHelper.formatPercentageValue(this.valueNew, true);
                return this.valueNew != null ? this.valueNew.format() : '';
            }
            set;
        }
        public Decimal diff { get; set; }
        public Boolean isAmount { get; set; }
        public Boolean isPercentage { get; set; }
        
        public GroupConditionsWrapper(String condition, Decimal val1, Decimal val2) {
            this.conditionType = condition;
            this.valueRef = val1;
            this.valueNew = val2;
            this.diff = (val1 != NULL && val2 != NULL) ? val2 - val1 : NULL;
            this.isPercentage = false;
        }
        public void buildConditionsMap(List<Contract_Discount__c> previous, List<Contract_Discount__c> current) {
            
        }
    }
    public Contract__c currentContract { get; set; }
    public List<GroupConditionsWrapper> conditionExtraDataList { get; set; }
    public Map<ExecutiveSummaryRecord, List<ExecutiveSummaryRecord>> executiveSummaryMap { get; set; }
    public List<Contract_Discount__c> refProgressiveConditions { get; set; }
    public List<Contract_Discount__c> newProgressiveConditions { get; set; }
    public class ExecutiveSummaryRecord implements Comparable {
        public String conditionName { get; set; }
        public String negoscopeName { get; set; }
        public Decimal percentageRef { get; set; }
        public String sPercentageRef {
            get {
                return NegoptimHelper.formatPercentageValue(this.percentageRef, true);
            }
            set;
        }
        public Decimal percentageNew { get; set; }
        public String sPercentageNew {
            get {
                return NegoptimHelper.formatPercentageValue(this.percentageNew, true);
            }
            set;
        }
        public Decimal valueRef { get; set; }
        public String sValueRef {
            get {
                return this.valueRef != null ? this.valueRef.format() : '';
            }
            set;
        }
        public Decimal valueNew { get; set; }
        public String sValueNew {
            get {
                return this.valueNew != null ? this.valueNew.format() : '';
            }
            set;
        }
        public Decimal percentageStatus { get; set; }
        public Decimal valueStatus { get; set; }
        public List<Contract_Discount__c> conditionsListRef { get; set; }
        public List<Contract_Discount__c> conditionsListNew { get; set; }
        
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
        public void calculateDiffByConditionsType() {
            for(Contract_Discount__c item : this.conditionsListRef) {
                if(item.Value_per__c != null) {
                    this.percentageRef += item.Value_per__c;
                }
                if(item.Value_amt__c != null) {
                    this.valueRef += item.Value_amt__c;
                }
            }
            for(Contract_Discount__c item : this.conditionsListNew) {
                if(item.Value_per__c != null) {
                    this.percentageNew += item.Value_per__c;
                }
                if(item.Value_amt__c != null) {
                    this.valueNew += item.Value_amt__c;
                }
            }
            this.percentageStatus = (percentageRef != NULL && percentageNew != NULL) ? percentageNew - percentageRef : NULL;
            this.valueStatus = (valueRef != NULL && valueNew != NULL) ? valueNew - valueRef : NULL;
        }
        public List<ExecutiveSummaryRecord> executiveSummaryConditionsDetails() {
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
                item.calculateDiffByConditionsType();
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
    public class IndexHead {
        public List<IndexLine> listIndexes {get;set;}
        
        public IndexHead() {
            listIndexes = new List<IndexLine>();
            Schema.DescribeFieldResult fieldResult = Pol_Com_Condition__c.Index__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry item : ple) {
                IndexLine ndxL = new IndexLine(item.getLabel());
                listIndexes.add(ndxL);
            }
        }
    }
    
    public class IndexLine {
        public String name {get;set;}
        public Decimal rate {get;set;}
        public String sRate {
            get {
                return NegoptimHelper.formatPercentageValue(this.rate, false);
            }
            set;
        }
        public Decimal percentage {get;set;}
        public String sPercentage {
            get {
                return NegoptimHelper.formatPercentageValue(this.percentage, false);
            }
            set;
        }
        public Decimal value {get;set;}
        public String sValue {
            get {
                return this.value != null ? this.value.format() : '';
            }
            set;
        }
        
        public IndexLine(String indexName) {
            this.name= indexName;
            this.rate =  0;
            this.percentage =  0;
            this.value =  0;
        }
    }
    public class NOException extends Exception { }
    
    public Nego_Plan__c negoPlan { get; set; }
    /**
     * Wrapper class for matix columns
     * */
    public class WrapperColumn {
        public Contract__c contract {get;set;}
        public Decimal index0 {get;set;}
        public String sIndex0 {
            get {
                return this.index0 != null ? this.index0.format() : '';
            }
            set;
        }
        ////public Boolean selected {get;set;}
		public Boolean isLocked {get;set;}
        
        public WrapperColumn(Contract__c c) {
            this.contract = c;
            ////this.selected =  false;
			this.isLocked =  false;
        }
    }
    /**
     * Wrapper class for condition Slabs
     * */
    public class Slab implements Comparable {
        public Integer slabIndex {get;set;}
        public Decimal threshold {get;set;}
        public String sThreshold {
            get {
                return this.threshold != null ? this.threshold.format() : '';
            }
            set;
        }
        public Decimal percentage {get;set;}
        public String sPercentage {
            get {
                return NegoptimHelper.formatPercentageValue(this.percentage, false);
            }
            set;
        }
        public Decimal value {get;set;}
        public String sValue {
            get {
                return this.value != null ? this.value.format() : '';
            }
            set;
        }
        public Boolean slabTarget {get;set;}
        
        public Slab(Integer ndx, Decimal target) {
            this.slabIndex = ndx;
            this.slabTarget = target != null && (Integer)target == ndx ? true : false;
        }
        // check if the threshold in null
        public Boolean isEmpty() {
            return this.threshold == null || this.threshold == 0;
        }
        public Integer compareTo(Object compareTo) {
            Slab compareToSlab = (Slab)compareTo;
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            if (threshold > compareToSlab.threshold) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (threshold < compareToSlab.threshold) {
                // Set return value to a negative value.
                returnValue = -1;
            }
            return returnValue;
        }
    }
    
   /**
	 * return if object is loscked or no .
	 * @param objId: objetc Id
	 * */   
    public boolean objectIsLocked(Id objId){
    	boolean isLocked = false;
    	try {
 			isLocked = Approval.isLocked(objId);
 		}
        catch(Exception e) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Enable record locking and unlocking in Apex'));
        }
        return isLocked;
    }
    
    // List<ConditionTypeWrapper> conditionsTypes
    
    // public class ConditionType {
    //   public List<ConditionsDefinition> conditionsDef;
    
    
    //   public void generateTotalConditionLine() {
    //     Map<String, Decimal> totalByContract = new Map<String, ConditionWrapper>();
    
    //     for(ConditionsDefinition wCondDef : conditionsDef) {
    //       for(ConditionWrapper wCond : wCondDef.conditionsWrapped) {
    //         String key = wCondDef.wCond.contractNego.Name;
    //         if(!totalByContract.containsKey(key)) {
    //           totalByContract.put(key, 0);
    //         }
    //         totalByContract.put(key, totalByContract.get(key) + wCond.condition.Value_amt__c);
    //       }
    //     }
    
    
    
    //     ConditionsDefinition wCondDefTotal = new ConditionsDefinition();
    //     wCondDefTotal.conditionsWrapped = new List<ConditionWrapper>();
    
    //     for(Contract__c contract : contracts) {
    //       String key = contract.Name;
    //       if(totalByContract.containsKey(key)) {
    //         ConditionWrapper wCond = new ConditionWrapper(contract, totalByContract.get(key));
    //         wCondDefTotal.add(wCond);
    //       }
    //     }
    
    //     conditionsDef.add(wCondDefTotal);
    //   }
    
    // }
    
    
    // public class ConditionsDefinition {
    //   public Pol_Com_Condition__c conditionDefinition {get; set;}
    //   public List<ConditionWrapper> conditionsWrapped {get; set;}
    
    //   public boolean isTotal = false;
    // }
    
    
    
    // public class ConditionWrapper {
    //   public Contract_Discount__c condition {get; set;}
    //   public Pol_Com_Condition__c conditionDefinition {get; set;}
    //   public Contract__c contractNego {get; set;}
    
    
    //   public Decimal amount {get; set;}
    //   public Decimal percent {get; set;}
    
    //   public ConditionWrapper(Contract_Discount__c condition, Pol_Com_Condition__c conditionDefinition, Contract__c contractNego) {
    //     if(contractNego.Id == null) {
    //       this.condition = new Contract_Discount__c();
    
    //       this.conditionDefinition = new Pol_Com_Condition__c();
    //       this.conditionDefinition.Name = conditionDefinition.Name;
    //       this.conditionDefinition.Condition_status__c = conditionDefinition.Condition_status__c;
    //       this.conditionDefinition.Nego_Discount_Type__c = conditionDefinition.Nego_Discount_Type__c;
    //     }
    //     else {
    //       this.condition = condition;
    //       this.conditionDefinition = conditionDefinition;
    //     }
    
    //     this.contractNego = contractNego;
    //   }
    
    
    //   public ConditionWrapper(Contract__c contractNego, Decimal amount) {
    //     this.contractNego = contractNego;
    //     this.amount = amount;
    //   }
    // }
    
    
    // public class NegoScopeWrapper {
    //   public Sup_sup_NegoScope__c negoScope {get; set;}
    //   public Boolean isSelected {get; set;}
    
    //   public NegoScopeWrapper() {
    //     isSelected = false;
    //   }
    
    //   public NegoScopeWrapper(Nego_Scope__c negoScope, Boolean isSelected) {
    //     this.negoScope = negoScope;
    //     this.isSelected = isSelected;
    //   }
    // }
    
}