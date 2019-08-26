global with sharing class ConditionsList extends NegoptimBaseController {

    public List<WrapperDiscountList> wDiscList {get; set;}
    public List<Contract_Discount__c> discountsOriginalList {get;set;}
    public String fileType {get;set;}
    public Blob csvFileBody {get;set;}
    public String attachmentId {get; set;}
    public Id currentConditionId {get; set;}
    public Inv_BUDispatch_Details__c currentDispatch {get; set;}
    public Contract_Discount__c clonedCondObj {get; set;}
        
    public WrapperDiscountList currentWrapperDiscount {get; set;}
    
    public List<SelectOption> getItems() {
        
        List<SelectOption> options = new List<SelectOption>(); 
        
        Schema.DescribeFieldResult fieldResult = Contract_Discount__c.Base_Redistribution_Model__c.getDescribe();
        List <Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry item : ple) {
            options.add(new SelectOption(item.getValue(), item.getLabel()));
        }
        return options;
    }
    
    public String getOption() {
        return option;
    }
    public String option = null;
    public void setOption(String option) { this.option = option; }


    public Attachment attachment {
        get {
            if (attachment == null)
                attachment = new Attachment();
            return attachment;
        }
        set;
    }
    
    global class WrapperDiscountList {
        public Integer index {get;set;}
        public Boolean isSelected {get;set;}
        public Boolean toInsert {get;set;}
        public Boolean isConditional {get;set;}
        public Boolean enablePercentage { get; set; }
        public Boolean enableAmount { get; set; }
        public Integer slabTarget {get;set;}
        public ID selNS {get;set;}
        public String nameNS {get;set;}
        public Contract_Discount__c discount {get;set;}
        public List<WrapperDispatchDetail> distpatchDetailList {get;set;}
        public List<WrapperDispatchDetail> realDistpatchDetailList {get;set;} // For size > 1000
        /**
        * Hide/Show the Amount/Percentage fields based on condition mode
        * */
        public void adjustConditionMode(String conditionMode) {
            if(conditionMode != NULL) {
                String[] conditionModes = conditionMode.split(';');
                for(Integer ndx = 0; ndx < conditionModes.size(); ndx++) {
                    if(conditionModes[ndx] == '%'){
                        this.enablePercentage = true;
                    }
                    else if(conditionModes[ndx] == 'U' || conditionModes[ndx] == 'F') {
                        this.enableAmount = true;
                    }
                }
            }
        }
        
        // Rearrenge slabs in ASC or DESC order
        // @param orderDirection: can be null or ASC or DESC
        public void sortSlabs(String orderDirection) {
            SlabManager.sortSlab(this.discount, orderDirection == 'ASC');
        }
    }
    /**
    * Wrapper class for dispatch details
    **/
    public class WrapperDispatchDetail {
        
        public Integer rowIndex {get;set;}
        public String nameBU {get;set;}
        public String section {get;set;}
        public String sectionId {get;set;}
        public String namePG {get;set;}
        public Inv_BUDispatch_Details__c distpatchDetail {get;set;}
        public Boolean isEmpty {
            get {
                Decimal total = 0;
                for(Integer i = 1; i <= 12; i++) {
                    Decimal d = (Decimal)distpatchDetail.get('Fix_Amount_Dispatch_M' + i + '__c');
                    total += d != null ? d :0;
                }
                if(total == 0)
                    return true;
                else
                    return false;
            }
            set;
        }
        
        public WrapperDispatchDetail(Integer index, String bu, String sec, String secId, String pg, Inv_BUDispatch_Details__c dispatch) {
            rowIndex = index;
            nameBU = bu;
            section = sec;
            sectionId = secId;
            namePG = pg;
            distpatchDetail = dispatch;
        }
    }
    
    /**
     * Wrapper class for Purchases Flow PG
     **/
    public class WrapperPurchasesFlowPg {
        public String buId {get;set;}
        public String pgId {get;set;}
        public Decimal amount {get;set;}
        
        public WrapperPurchasesFlowPg(String b, String p, Decimal a) {
            buId = b;
            pgId = p;
            amount = a;
        }
    }
    
    public String idContract {get;set;}
    
    public Contract_Discount__c newDiscountRecord;
    public Decimal totalYTD {get; set;}
    public List<SelectOption> contracts {get; set;}
    
    public List<Contract__c> lstContract {get;set;}
    public List<Sup_sup_NegoScope__c> lstNegoScope {get;set;}
    
    public class wContract {
        public Contract__c contract {get;set;}
        public Boolean selContract {get;set;}
    }
    
    public List<wContract> wContractLst {get;set;}
    
    public List<wContractN> wContractNLst {get;set;}
    
    public class wContractN {
        public Id NS_Id {get;set;}
        public string NS_Name {get;set;}
        public Sup_sup_NegoScope__c NS {get;set;}
        public Contract__c contract {get;set;}
        public Boolean selContract {get;set;}
    }
    
    // Manage Year and Supplier Selection
    public Sup_Supplier__c selectedSupplier {get; set;}
    public Id selectedSupplierId {get; set;}
    public Integer selectedNegoYear {get; set;}
    
    public Integer contractBeginDay {get; set;}
    public Integer contractBeginMonth {get; set;}
    public Integer contractBeginYear {get; set;}
    public Integer contractEndDay {get; set;}
    public Integer contractEndMonth {get; set;}
    public Integer contractEndYear {get; set;}
    
    public Integer discountBeginMonth {get; set;}
    public Integer discountEndMonth {get; set;}
    public Integer discountYear {get; set;}
    
    private boolean existContract = false;
    private integer nbNS = 0;
    
    public boolean displayWizardPopup {get; set;}
    public boolean showCancelButton {get; set;}
    public boolean showNextButton {get; set;}
    
    public Integer[] slabs {get; set;}
    
    public ConditionsList() {
        //idContract = 'a1k24000001SDBR';
        selectedSupplier = new Sup_Supplier__c();
        selectedNegoYear = Integer.valueOf(Date.today().year());

        slabs = new Integer[SlabManager.slabsCount];
        for(Integer ndx = 1; ndx <= SlabManager.slabsCount; ndx++) {
            slabs.add(ndx);
        }
        // Remove the lines below after finishing testing
        /*selectedSupplierId = 'a1A24000000FUkE';
        selectedNegoYear = 2016;
        SearchContract();
        runSearch();*/
    }
    
    public void addNewRowToDiscList() {
        WrapperDiscountList newRecord = new WrapperDiscountList();
        // define sobject instance with default values (the second parametre: true)
        Contract_Discount__c newDiscountRecord = (Contract_Discount__c)Contract_Discount__c.sObjectType.newSObject(null, true);
        newDiscountRecord.disc_bdate__c = contract.contract_bdate__c;
        newDiscountRecord.disc_edate__c = contract.contract_edate__c;
        newDiscountRecord.BU_Scope__c = contract.Contract_BU__c;
        Schema.DescribeFieldResult fieldNegoTypeResult = Contract_Discount__c.Nego_Discount_Type__c.getDescribe();
        Schema.DescribeFieldResult fieldPeriodResult = Contract_Discount__c.Invoice_period__c.getDescribe();
        newDiscountRecord.Nego_Discount_Type__c = NegoptimHelper.defaultPicklistValue(fieldNegoTypeResult);
        newDiscountRecord.Invoice_period__c = NegoptimHelper.defaultPicklistValue(fieldPeriodResult);
        Schema.DescribeFieldResult fieldIsPrenegoEnvResult = Contract_Discount__c.Is_Prenego_Envelop__c.getDescribe();
        newDiscountRecord.Is_Prenego_Envelop__c = (Boolean)fieldIsPrenegoEnvResult.getDefaultValue();
        newRecord.discount = newDiscountRecord;
        newRecord.index = wDiscList.size();
        newRecord.toInsert = true;
        newRecord.isConditional = false;
        newRecord.isSelected = false;
        newRecord.nameNS = contract.Supplier_Nego_Scope__r.Name;
        wDiscList.add(newRecord);
    }
    
    public PageReference SaveMultipleDiscounts() {
        List<Contract_Discount__c> discountRecordsToBeUpserted = new List<Contract_Discount__c>();
        List<Inv_BUDispatch_Details__c> dispatchDetailList = new List<Inv_BUDispatch_Details__c>();
        List<Inv_BUDispatch_Details__c> dispatchDetailListToDelete = new List<Inv_BUDispatch_Details__c>();
        Contract__c conTemp;
        try {
            conTemp = [select Name, CurrencyIsoCode, Contract_Numbder__c from Contract__c where id = :idContract];
        }
        catch (Exception ex) {
            conTemp = null;
        }
        Integer listSize = discountsOriginalList.size(), i = 0;
        if(conTemp != null && wDiscList != null && !wDiscList.isEmpty()) {
            for(WrapperDiscountList eachRecord : wDiscList){
                if (eachRecord.discount.Condition_Type__c != NULL) {
                    Contract_Discount__c discTemp = eachRecord.discount;
                    discTemp.CurrencyIsoCode = conTemp.CurrencyIsoCode;
                    // Set the main nego scope for new conditions
                    if(discTemp.Product_Scope__c == null) {
                        discTemp.Product_Scope__c = mainSelectedNS;
                    }
                    if (eachRecord.toInsert) {discTemp.Contract__c = conTemp.id;}
                    discountRecordsToBeUpserted.add(discTemp);
                }
                if(eachRecord.realDistpatchDetailList != null) {
                    for(WrapperDispatchDetail item : eachRecord.realDistpatchDetailList) {
                        if(!item.isEmpty) {
                            // ignore empty rows
                            dispatchDetailList.add(item.distpatchDetail);
                        }
                        else if(item.distpatchDetail.Id != null) {
                            // delete existing empty rows
                            dispatchDetailListToDelete.add(item.distpatchDetail);
                        }
                    }
                }
            }
            
            try {
                String [] contractDiscountFields = new String [] {NegoptimHelper.normalizeAPIName('Product_Scope__c')};
                if(checkCreatibility(Contract_Discount__c.SObjectType, contractDiscountFields)
                   && checkUpdatibility(Contract_Discount__c.SObjectType, contractDiscountFields)) {
                    upsert discountRecordsToBeUpserted;
                }
                upsert dispatchDetailList;
                if(dispatchDetailListToDelete.size() > 0) {
                    if (checkDeletibility(Inv_BUDispatch_Details__c.SObjectType)) {
                        delete dispatchDetailListToDelete;
                    }
                }
                // Display success message
                ApexPages.Message successMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved);
                ApexPages.addMessage(successMsg);
            } catch(Exception e) {
                ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
                ApexPages.addMessage(errMsg);
            }
            runSearch();
        }
        else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSG_Internal_Server_Error);
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    public PageReference DeleteMultipleDiscounts() {
        try {
            List<Contract_Discount__c> discountRecordsToBedeleted = new List<Contract_Discount__c>();
            if(wDiscList !=null && !wDiscList.isEmpty()) {
                for(WrapperDiscountList eachRecord : wDiscList){
                    if (eachRecord.discount.Condition_Type__c != NULL && eachRecord.isSelected) {
                        Contract_Discount__c discTemp = eachRecord.discount;
                        discountRecordsToBedeleted.add(discTemp);
                    }
                }
                if(discountRecordsToBedeleted.size() > 0) {
                    if (checkDeletibility(Contract_Discount__c.SObjectType)) {
                        delete discountRecordsToBedeleted;
                    }
                    runSearch();
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Deleted);
                    ApexPages.addMessage(myMsg);
                }
                else {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Select_OneLine);
                    ApexPages.addMessage(myMsg);
                }
            }
        }
        catch (DMLException e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
            ApexPages.addMessage(myMsg);
            
        }
        return null;
    }
    
    public Contract__c contract {get;set;}
    // Display the list of conditions after selecting a contract
    public boolean displayInfo {get;set;}
    // Save the selection of main Nego Scope
    public Id mainSelectedNS {get; set;}
    /**
     * Triggered when selecting a contract
     * runs the search with parameters passed via Javascript
     * */
    public PageReference runSearch() {
        idContract = null;
        Sup_sup_NegoScope__c selectedNS;// = new Sup_sup_NegoScope__c();
        for (wContractN con : wContractNLst) {
            if (con.selContract == true) {
                if (con.contract !=null) {
                    idContract = con.contract.id;
                }
                selectedNS = con.NS;
            }
        }
        displayInfo = false;
        // Set the main selection of Nego Scope
        mainSelectedNS = selectedNS.Id;
        //Contract creation
        if (idContract == null) {
            Contract__c new_con = new Contract__c();
            new_con.Name = 'Contract ' + selectedNegoYear + ' - ' + selectedNS.Name;
            new_con.Contract_Type__c ='Contract';
            // new_con.Contract_Numbder__c = 'SIM-' + DateTime.now().getTime() + '-1';
            // new_con.SimulationNumber__c = 1;
            new_con.contract_bdate__c = Date.newInstance(selectedNegoYear, 1, 1);
            new_con.contract_edate__c = Date.newInstance(selectedNegoYear, 12, 31);
            new_con.Supplier__c = selectedNS.Supplier__r.Id;
            new_con.CurrencyIsoCode = selectedNS.Supplier__r.CurrencyIsoCode;
            new_con.Contract_BU__c = selectedNS.Supplier__r.Country_origin__c;
            new_con.Supplier_Nego_Scope__c = selectedNS.Id;
            
            try {
                String [] contractFields = new String [] {'Name','CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Contract_Numbder__c'),
                NegoptimHelper.normalizeAPIName('SimulationNumber__c'), NegoptimHelper.normalizeAPIName('contract_bdate__c'),
                NegoptimHelper.normalizeAPIName('contract_edate__c'), NegoptimHelper.normalizeAPIName('Supplier__c'),
                NegoptimHelper.normalizeAPIName('Contract_BU__c'), NegoptimHelper.normalizeAPIName('Supplier_Nego_Scope__c')};
                if(checkCreatibility(Contract__c.SObjectType, contractFields))
                {
                    insert new_con;
                }
            }
            catch(DMLException e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, e.getDmlMessage(0)); 
                ApexPages.addMessage(myMsg);
            }
            idContract = new_con.Id;
            // Add new contract to list
            wContractN newWrapperContract = new wContractN();
            newWrapperContract.NS_Id = selectedNS.Id;
            newWrapperContract.NS_Name = selectedNS.Name;
            newWrapperContract.NS = selectedNS;
            newWrapperContract.contract = new_con;
            newWrapperContract.selContract = true;
            wContractNLst.add(newWrapperContract);
            
            //  displayInfo = true;
            //  wDiscList = new List<WrapperDiscountList>(); 
            //  wDiscList.Clear();
            //  addNewRowToDiscList();
        }
        if (idContract != null) {
            displayInfo = true;
            contract = [SELECT Name, contract_bdate__c, contract_edate__c, contract_numbder__c, status__c, Contract_BU__c, Supplier_Nego_Scope__r.Name, Supplier_Nego_Scope__c, CurrencyIsoCode, Last_Active_Contract__c
                        FROM Contract__c WHERE id = :idContract];
            
            // set the below varable to be used in javascript function
            contractBeginYear = contract.contract_bdate__c.year();
            contractBeginMonth = contract.contract_bdate__c.month();
            contractBeginDay = contract.contract_bdate__c.day();
            
            contractEndYear = contract.contract_edate__c.year();
            contractEndMonth = contract.contract_edate__c.month();
            contractEndDay = contract.contract_edate__c.day();
            
            wDiscList = new List<WrapperDiscountList>(); 
            
            wDiscList.Clear();
            
            List<Contract_Discount__c> discounts = [SELECT Name, Condition_type__r.Name, Condition_type__r.Nego_Discount_Type__c, Condition_type__r.is_conditional__c, Condition_type__r.Condition_Mode__c, disc_bdate__c, value_amt__c, value_per__c, Base_Quantity_Nego__c, unit_amount__c,
                                                    Value_amt_approv_M1__c, Value_amt_approv_M2__c, Value_amt_approv_M3__c, Value_amt_approv_M4__c, Value_amt_approv_M5__c, Value_amt_approv_M6__c, Value_amt_approv_M7__c, 
                                                    Value_amt_approv_M8__c, Value_amt_approv_M9__c, Value_amt_approv_M10__c, Value_amt_approv_M11__c, Value_amt_approv_M12__c,
                                                    Value_amt_event_M1__c, Value_amt_event_M2__c, Value_amt_event_M3__c, Value_amt_event_M4__c, Value_amt_event_M5__c, Value_amt_event_M6__c, Value_amt_event_M7__c,
                                                    Value_amt_event_M8__c, Value_amt_event_M9__c, Value_amt_event_M10__c, Value_amt_event_M11__c, Value_amt_event_M12__c,
                                                    Value_amt_disp_M1__c, Value_amt_disp_M2__c, Value_amt_disp_M3__c, Value_amt_disp_M4__c, Value_amt_disp_M5__c, Value_amt_disp_M6__c, Value_amt_disp_M7__c,
                                                    Value_amt_disp_M8__c, Value_amt_disp_M9__c, Value_amt_disp_M10__c, Value_amt_disp_M11__c, Value_amt_disp_M12__c, Slab_Calc_Method_TO_Origin__c, Slab_calc_method__c,
                                                    slab_1__c, slab_per_1__c, slab_val_1__c, slab_2__c, slab_per_2__c, slab_val_2__c, slab_3__c, slab_per_3__c, slab_val_3__c, slab_target__c, Base_Redistribution_Model__c,
                                                    slab_4__c, slab_per_4__c, slab_val_4__c,slab_5__c, slab_per_5__c, slab_val_5__c, slab_6__c, slab_per_6__c, slab_val_6__c,
                                                    slab_7__c, slab_per_7__c, slab_val_7__c, slab_8__c, slab_per_8__c, slab_val_8__c, Y_Actu__c, Already_Invoiced__c,
                                                    Contract__c, disc_edate__c, rank__c, all_items__c, all_BU__c, commercial_reference__c, Minimum_Guarantee__c, Invoice_period__c, Invoicing_plan_generated__c, Is_Prenego_Envelop__c, legal_reference__c, financial_reference__c,
                                                    status__c, Nego_Discount_Type__c, valid__c, is_duplicable__c, comments__c, Scope_BU__c, BU_Scope__c, Contract__r.Supplier_Nego_Scope__r.id, product_scope__c, product_scope__r.name//,
                                                    //(Select Id, Inv_BUDispatch__c, Inv_DispatchHead__c, Base_TO_Dispatch__c, Hierarchy_level_dispatch__c,
                                                    //Fix_Amount_Dispatch_M1__c, Sequence__c, Fix_Amount_Dispatch_M2__c, Fix_Amount_Dispatch_M3__c, Fix_Amount_Dispatch_M4__c,
                                                    //Fix_Amount_Dispatch_M5__c, Fix_Amount_Dispatch_M6__c, Fix_Amount_Dispatch_M7__c, Fix_Amount_Dispatch_M8__c,
                                                    //Fix_Amount_Dispatch_M9__c, Fix_Amount_Dispatch_M10__c, Fix_Amount_Dispatch_M11__c, Fix_Amount_Dispatch_M12__c,
                                                    //Status__c From Invoice_BU_Dispatch_Details__r)
                                                    FROM Contract_Discount__c WHERE Contract__r.id = :idContract order by CreatedDate]; // Nego_Discount_Type__c, disc_bdate__c, Condition_Type__c
            discountsOriginalList = new List<Contract_Discount__c>();
            
            integer count = 0;
            for(Contract_Discount__c c : discounts) {
                // push a clone object to the original discounts list
                clonedCondObj = c.clone(true,true);
                discountsOriginalList.add(c.clone());
                c.CurrencyIsoCode = contract.CurrencyIsoCode;
                WrapperDiscountList newRecord = new WrapperDiscountList();
                newRecord.discount = c;
                newRecord.index = wDiscList.size();
                newRecord.toInsert = false;
                if (c.product_scope__c != null && c.product_scope__c != contract.supplier_nego_scope__c ) {
                    newRecord.nameNS = c.product_scope__r.name;
                    newRecord.selNS = c.product_scope__c;
                } else {
                    // newRecord.nameNS = 'Full Nego Scope';
                    newRecord.nameNS = selectedNS.name;
                    newRecord.discount.product_scope__c = selectedNS.id;
                    newRecord.selNS = selectedNS.id;
                } 
                newRecord.isConditional = c.Condition_type__r.is_conditional__c;
                newRecord.adjustConditionMode(c.Condition_type__r.Condition_Mode__c);
                newRecord.isSelected = false;
                wDiscList.add(newRecord);
            }
            addNewRowToDiscList();
        }
        return null;
    }
    
    // Manage Conditional Popup
    public Boolean displayPopup {get; set;}
    public String popupName {
        get;
        // *** setter is NOT being called ***
        set {
            popupName = value;
        }
    }
    public boolean displayPopUpAmount {get; set;}
    /**
     * Close opened popup that match a specific popup Name
     * @param popupName
     * */
    public void closePopup() {
        if(popupName == 'distributeAmountPopup') {
            displayPopUpAmount = false;
        }
        if(popupName == 'CommentsPopup') {
            displayPopup = false; 
        }
        if(popupName == 'cancelCommentsPopup') {
            wDiscList[condIndexno].distpatchDetailList.get(dispatchIndexno).distpatchDetail = NULL;
            displayPopup = false;
        }
        if(popupName == 'cancelDistributeAmountPopup') {
            displayPopUpAmount = false;
            option = null;
            wDiscList[condIndexno].distpatchDetailList = NULL;
            wDiscList[condIndexno].discount = clonedCondObj;
        }
        if(popupName == 'slabPopup') {
            option = wDiscList[condIndexno].discount.Base_Redistribution_Model__c;
            // Slabs popup
            displayPopup = false;
            wDiscList[condIndexno].sortSlabs('ASC');
        }
    }
    /**
     * Open the popup that match a specific popup Name
     * @param popupName
     * */
    public void showPopup() {
        if(popupName == 'distributeAmountPopup') {
            currentWrapperDiscount = wDiscList[condIndexno];
            option = currentWrapperDiscount.discount.Base_Redistribution_Model__c;
            discountBeginMonth = currentWrapperDiscount.discount.Disc_BDate__c.month();
            discountEndMonth = currentWrapperDiscount.discount.Disc_EDate__c.month();
            discountYear = currentWrapperDiscount.discount.Disc_BDate__c.year();
            if(currentWrapperDiscount.discount != NULL){
                clonedCondObj = currentWrapperDiscount.discount.clone(true,true);
            }
      
            if(currentWrapperDiscount.discount.BU_Scope__c == NULL) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSG_Condition_No_Entity_Scope);
                ApexPages.addMessage(myMsg);
            } else {
                loadDispatchDetails(condIndexno);
                displayPopUpAmount = true;
            }
        } else if(popupName == 'commentPopup'){
            currentDispatch =  wDiscList[condIndexno].distpatchDetailList.get(dispatchIndexno).distpatchDetail;
            displayPopup = true;
        } else {
            currentWrapperDiscount = wDiscList[condIndexno];
            displayPopup = true;
        }
    }
    
   /**
    * Save and execute auto redistribute options 
    **/ 
    public PageReference updateAutoDistribute() {
        Contract_Discount__c discTemp = wDiscList[condIndexno].discount;
        discTemp.Base_Redistribution_Model__c = option;
        autoDistributeCalculation(option);
        return null;
    }
    
    /**
     * Auto distribute behavior function  
     **/
    public void autoDistributeCalculation(String option) {
        WrapperDiscountList currentCondition = wDiscList[condIndexno];
        // check if the condition have the dispatch details already loaded
        // else get the bu list of low level (store..) and get all section for the negoscope PGs
        
        List<String> sectionIds = new List<String>();
        List<Orga_HE__c> sectionsList = new List<Orga_HE__c>();
        List<Id> pgIdList = new List<Id>();
        List<WrapperPurchasesFlowPg> wrapperPurchasesFlowPgList  = new List<WrapperPurchasesFlowPg>();
        List<AggregateResult> purchasesFlowPgList  = new List<AggregateResult>();
        // Load BU
        List<Orga_BU__c> businessUnitsList = loadBU(currentCondition.discount.BU_Scope__c);
        List<Id> businessUnitsIdList = new List<Id>();
        for(Orga_BU__c item : businessUnitsList) {
            businessUnitsIdList.add(item.Id);
        }
        // Get Ids of NegoScope PGs 
        for(Supplier_PG_Mapping__c pgItem : [SELECT Id,Name, Section__c FROM Supplier_PG_Mapping__c WHERE Id IN (SELECT Sup_PG__c FROM Sup_NS_PG__c  WHERE Sup_sup_NegoScope__c = :currentCondition.discount.Product_Scope__c)]) {
            pgIdList.add(pgItem.Id);
        }
        if(option == 'Purchases of the month' && false) { // Choice stopped

            // get sum of TO of the current month 
            Integer currentMonth = Integer.valueOf(Date.today().month());
            String TOField = 'TO'+currentMonth+'__c';
            string query= 'Select SUM('+TOField+')  tosum ,PG__c pg, BU__c bu FROM Purchases_Flow_PG__c WHERE Id != null ';
            query += ' AND PG__c IN (\'' + String.join(pgIdList, '\',\'') +'\')';
            query += ' AND BU__c IN (\'' + String.join(businessUnitsIdList, '\',\'') +'\')';
            query += ' GROUP BY PG__c, BU__c';
            
            purchasesFlowPgList = Database.query(query);
            Map<String, Decimal> mapPurchases = new Map<String, Decimal>();
            Decimal totalPurchasesAmount = 0;
            // calculate total TO of each store and pg & store value in map
            //Calculate sum of total TO
            for(AggregateResult purchasesItem : purchasesFlowPgList) { 
                String purchasesKey = purchasesItem.get('pg') + '' + purchasesItem.get('bu');
                Decimal toSum =  (Decimal) purchasesItem.get('tosum');
                mapPurchases.put(purchasesKey, toSum);
                totalPurchasesAmount += toSum; 
            }
            
            //sum TO devided by the total Sum To
            for(String key: mapPurchases.keySet()) {
                Decimal amount = 0 ;
                if(totalPurchasesAmount != 0 ){
                    amount = mapPurchases.get(key)/totalPurchasesAmount;
                }
                mapPurchases.put(key, amount);
            }
            
            // division value  of each row is multiplied  by the total amout of conidtion
            String fieldDispatchName = 'Value_amt_disp_M'+currentMonth+'__c';
            Decimal conditionTotalAmount = (decimal)currentCondition.discount.get(fieldDispatchName);
            
            for(AggregateResult purchasesItem : purchasesFlowPgList) { 
                String purchasesKey = purchasesItem.get('pg') + '' + purchasesItem.get('bu');
                Decimal finalAmount = 0;
                if(conditionTotalAmount!= null)
                    finalAmount = mapPurchases.get(purchasesKey)*conditionTotalAmount;
                
                WrapperPurchasesFlowPg wrapperPurchasesFlowPg = new WrapperPurchasesFlowPg((String)purchasesItem.get('bu'), (String)purchasesItem.get('pg'), finalAmount);
                wrapperPurchasesFlowPgList.add(wrapperPurchasesFlowPg);
            } 
    
            // update values of current month
            for(WrapperDispatchDetail ddItem : currentCondition.distpatchDetailList) {
                for(WrapperPurchasesFlowPg pfItem : wrapperPurchasesFlowPgList) {
                    if(pfItem.buId == ddItem.distpatchDetail.Inv_BUDispatch__c && pfItem.pgId == ddItem.distpatchDetail.PG__c){
                        // assign amount to list 
                        String fieldName = 'Fix_Amount_Dispatch_M'+currentMonth+'__c';
                        ddItem.distpatchDetail.put(fieldName,pfItem.amount.setScale(2));
                    }     
                }
            }
        }
        if(option == 'Equally') {
            Integer rowCount = businessUnitsList.size() * pgIdList.size();
            if(selectedNegoYear == system.today().year()) {
                Integer currentMonth = system.today().month();
                Integer startMonth ;
                // calculate start month depend on current month and condition begin month
                if(currentMonth > discountBeginMonth) {
                    startMonth = currentMonth;
                } else if(currentMonth <  discountBeginMonth) {
                    startMonth = discountBeginMonth;
                } else {
                    startMonth = currentMonth;
                }
                // Get Purchases to link to dispatch details
                Map<String, Purchases_Flow_PG__c> purchasesMap = new Map<String, Purchases_Flow_PG__c>();
                Boolean dispatchAggregateMode = GlobalSettingsManager.loadGlobalSettings().dispatchAggregateMode;
                if(!dispatchAggregateMode) {
                    for (Purchases_Flow_PG__c item : [SELECT BU__c, Section__c, PG__c, DC__c
                                                      FROM Purchases_Flow_PG__c
                                                      WHERE PG__c IN (SELECT Sup_PG__c FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :currentCondition.discount.Product_Scope__c)
                                                      AND ((BU__c IN :businessUnitsIdList AND DC__c = NULL)
                                                           OR DC__c IN :businessUnitsIdList) // Redistribute to any indirect flow
                                                      AND Year__c >= :selectedNegoYear
                                                      AND Year__c <= :selectedNegoYear
                                                      // To make sure indirect flows are also for Open stores
                                                      AND BU__r.Status__c = 'Open' ])
                    {
                        String key = item.PG__c + '' + item.BU__c;
                        if (item.DC__c != null) key += item.DC__c;
                        purchasesMap.put(key, item);
                    }
                }
                Decimal finalAmount = 0;
                // add values to a list to pass it to smart function
                for(Integer m = startMonth;m <= discountEndMonth;m++) {
                    List<Decimal> listOfDispatchValue = new List<Decimal>(); 
                    String fieldDispatchName = 'Value_amt_disp_M' + m + '__c';
                    Decimal conditionTotalAmount = (decimal)currentCondition.discount.get(fieldDispatchName);
                    if(conditionTotalAmount != null && conditionTotalAmount != 0) {
                        listOfDispatchValue = NegoptimHelper.smartDivision(conditionTotalAmount,rowCount,2);
                        if(listOfDispatchValue.size() == currentCondition.distpatchDetailList.size()) {
                            Integer index = 0;
                            for(WrapperDispatchDetail ddItem : currentCondition.distpatchDetailList) {
                                String fieldName = 'Fix_Amount_Dispatch_M' + m + '__c';
                                ddItem.distpatchDetail.put(fieldName, listOfDispatchValue.get(index));
                                // Link to purchase
                                String key = ddItem.distpatchDetail.PG__c + '' + ddItem.distpatchDetail.Inv_BUDispatch__c;
                                if (ddItem.distpatchDetail.Order_to_DC__c != null) key += ddItem.distpatchDetail.Order_to_DC__c;
                                if (purchasesMap.containsKey(key)) ddItem.distpatchDetail.Purchases_Flow_PG__c = purchasesMap.get(key).Id;
                                index++;
                            }
                        }
                    }
                }
            } 
        }
    }
    // Load Dispatch Details
    public void loadDispatchDetails(Integer conditionIndex) {
        // check if the condition have the dispatch details already loaded
        // else get the bu list of low level (store..) and get all section for the negoscope PGs
        WrapperDiscountList currentCondition = wDiscList[condIndexno];
        if(currentCondition.distpatchDetailList == NULL || currentCondition.distpatchDetailList.size() == 0) {
            List<Inv_BUDispatch_Details__c> distpatchDetailList = [SELECT Id, Status__c, Sequence__c, Inv_DispatchHead__c, Inv_BUDispatch__c, Hierarchy_level_dispatch__c, PG__C,
                                                                   Comment__c,Comment_M1__c, Comment_M2__c, Comment_M3__c, Comment_M4__c, Comment_M5__c, Comment_M6__c, Comment_M7__c,
                                                                   Comment_M8__c, Comment_M9__c, Comment_M10__c, Comment_M11__c, Comment_M12__c,
                                                                   Fix_Amount_Dispatch_M1__c, Fix_Amount_Dispatch_M2__c, Fix_Amount_Dispatch_M3__c, Fix_Amount_Dispatch_M4__c,
                                                                   Fix_Amount_Dispatch_M5__c, Fix_Amount_Dispatch_M6__c, Fix_Amount_Dispatch_M7__c, Fix_Amount_Dispatch_M8__c,
                                                                   Fix_Amount_Dispatch_M9__c, Fix_Amount_Dispatch_M10__c, Fix_Amount_Dispatch_M11__c, Fix_Amount_Dispatch_M12__c,
                                                                   Discount__c, Base_TO_Dispatch__c, Supplier__c, Contract__c
                                                                   FROM Inv_BUDispatch_Details__c
                                                                   WHERE Discount__c = :currentCondition.discount.Id
                                                                   AND Order_to_DC__c = null];

            List<Orga_BU__c> businessUnitsList = loadBU(currentCondition.discount.BU_Scope__c);
            List<Supplier_PG_Mapping__c> pgList = [SELECT Id, Name, Section__c, Section__r.Name, SNA_Code__c FROM Supplier_PG_Mapping__c
                                                       WHERE Id IN (SELECT Sup_PG__c FROM Sup_NS_PG__c
                                                                    WHERE Sup_sup_NegoScope__c = :currentCondition.discount.Product_Scope__c)];           
            
            
            // Build Dispatch Details List
            currentCondition.distpatchDetailList = new List<WrapperDispatchDetail>();
            currentCondition.realDistpatchDetailList = new List<WrapperDispatchDetail>();
            List<Inv_BUDispatch__c> dispatchHeadList = [SELECT Id, Inv_BU__c FROM Inv_BUDispatch__c WHERE Inv_BU__c = :businessUnitsList AND Inv_Fiscal_Year__c = :selectedNegoYear];
            for(Orga_BU__c bu : businessUnitsList) {
                Integer countDispatchHeads = dispatchHeadList.size();
                for(Inv_BUDispatch__c dh : dispatchHeadList) {
                    if(bu.Id == dh.Inv_BU__c) {
                        // TODO: add to list of non changeable
                    }
                    else {
                        countDispatchHeads--;
                    }
                }
                if(countDispatchHeads == 0) {
                    // Create new Dispatch Head for this BU
                    Inv_BUDispatch__c newDispatchHead = new Inv_BUDispatch__c(Sequence_Number__c = 1, Inv_Fiscal_Year__c = selectedNegoYear, Inv_BU__c = bu.Id);
                    dispatchHeadList.add(newDispatchHead);
                }
            }
            upsert dispatchHeadList;
            Inv_BUDispatch__c dispatchHead;
            Integer counter = 0;
            // List of the rest of dispatch details when main list size > 1000
            List<WrapperDispatchDetail> remainderWDDList = new List<WrapperDispatchDetail>();
            for(Orga_BU__c bu : businessUnitsList) {
                dispatchHead = null;
                for(Inv_BUDispatch__c dh : dispatchHeadList) {
                    if(bu.Id == dh.Inv_BU__c) {
                        dispatchHead = dh;
                    }
                }
                for(Supplier_PG_Mapping__c item : pgList) {
                    Integer countDispatchDetails = distpatchDetailList.size();
                    WrapperDispatchDetail wDispatchDetail = null;
                    for(Inv_BUDispatch_Details__c ddl : distpatchDetailList) {
                        if(bu.Id == ddl.Inv_BUDispatch__c && item.Section__c == ddl.Hierarchy_level_dispatch__c && item.Id == ddl.PG__c) {
                            wDispatchDetail = new WrapperDispatchDetail(currentCondition.distpatchDetailList.size(),bu.Name, item.Section__r.Name, item.Section__c, item.SNA_Code__c, ddl);
                         }
                        else {
                            countDispatchDetails--;
                        }
                    }
                    if(countDispatchDetails == 0) {
                        Inv_BUDispatch_Details__c dispatchDetail = new Inv_BUDispatch_Details__c(Inv_DispatchHead__c = dispatchHead.Id, Supplier__c = selectedSupplierId, Contract__c = currentCondition.discount.Contract__c,
                                                                                                 Discount__c = currentCondition.discount.Id, Inv_BUDispatch__c = bu.Id, Hierarchy_level_dispatch__c = item.Section__c,
                                                                                                 Base_TO_Dispatch__c = 0, PG__c = item.Id, Status__c = 'New', Sequence__c = Date.today().Month());
                        wDispatchDetail = new WrapperDispatchDetail(currentCondition.distpatchDetailList.size(), bu.Name, item.Section__r.Name, item.Section__c, item.SNA_Code__c, dispatchDetail);
                    }
                    if (counter < 1000) {
                        currentCondition.distpatchDetailList.add(wDispatchDetail);
                    } else {
                        remainderWDDList.add(wDispatchDetail);
                    }
                    currentCondition.realDistpatchDetailList.add(wDispatchDetail);
                    counter++;
                }
            }
            if (counter > 1000) {
                currentCondition.distpatchDetailList = new List<WrapperDispatchDetail>();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Collection size '+ counter + ' exceeds maximum of 1000. Remaining rows will not appear below.'));
            }
        }
    }
    // Load BU for dispatch details
    private List<Orga_BU__c> loadBU(Id conditionBUId) {
        List<Orga_BU__c> businessUnitsList = new List<Orga_BU__c>();
        // Get BU Record Type based from global settings
        // TODO: MOVE OUTSIDE TO CLASS PROPERTY
        List<String> recordTypeBUSettings;
        try {
            NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
            if(negoSettings != null) {
                recordTypeBUSettings = negoSettings.selectedBURTList;
            }
        } catch (Exception ex){
        }
        if (recordTypeBUSettings == null) {
            recordTypeBUSettings = new List<String>{'Store', 'Web'}; // Default Values
        }
        Set<string> recordTypeBUSettingsSet = new Set<String>(recordTypeBUSettings);
        Orga_BU__c buItem = [SELECT Id, Name, Business_Unit_Type__c FROM Orga_BU__c WHERE Id = :conditionBUId];
        // Add directly BU scope of type 'Store' or 'Web' or 'Banner'
        if(recordTypeBUSettingsSet.contains(buItem.Business_Unit_Type__c)) {
            businessUnitsList.add(buItem);
        }
        // else get children for BU scope of type 'Country' or 'List' or 'Group'
        if(buItem.Business_Unit_Type__c == 'Country' || buItem.Business_Unit_Type__c == 'List' || buItem.Business_Unit_Type__c == 'Group') {
            for(Orga_BU__c item : [SELECT Id, Name FROM Orga_BU__c WHERE Id IN (SELECT Entity_List__c FROM Orga_BU_List_Detail__c WHERE Entity__c = :conditionBUId)
                                   AND Business_Unit_Type__c IN :recordTypeBUSettings])
            {
                businessUnitsList.add(item);
            }
        }
        return businessUnitsList;
    }
    
    public integer condIndexno {get; set;} 
    public integer dispatchIndexno {get; set;}
    
    @RemoteAction
    global static String findSupplier(String searchTerm) {
        String searchTermLike = '%' + searchTerm + '%'; 
        
        List<Sup_Supplier__c> listSuppliers = [SELECT Id, Name, Code__c FROM Sup_Supplier__c WHERE Name LIKE :searchTermLike OR Code__c LIKE :searchTermLike];
        String JSONSuppliersList = JSON.serialize(listSuppliers);
        
        return JSONSuppliersList;
    }
    
    public List<SelectOption> getListYears() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer year = Date.today().year() - 2 ; year <= Date.today().year() + 3 ; year++) {
            options.add( new SelectOption(String.valueOf(year), String.valueOf(year)) );
        }
        return options;
    }
    
    public PageReference runSearchContract() {
        List<Contract__c> lstContract = [select Id, Name, Contract_Numbder__c, Supplier_Nego_Scope__c from Contract__c where supplier__r.id = :selectedSupplierId and CALENDAR_YEAR(Contract_bdate__c) = :selectedNegoYear];
        integer lstSize = lstContract.size();
        return null;
    }
    
    // Manage Contract Popup 
    public boolean displayPopup2 {get; set;}
    
    public void cancelPopup2() {
        displayPopup2 = false;
    }
    // Close the popup of contracts and load the conditions of the selected one
    public void closePopup2() {
        displayPopup2 = false;
        runSearch();
    }
    // Load the contracts for the selected supplier
    public void showPopup2() {
        SearchContract();
        displayPopup2 = true;
    }
    
    public void SearchContract() {
        //   lstContract = [select Id, Name, Supplier_Nego_Scope__r.Name, Status__c, Contract_BDate__c, Contract_EDate__c from Contract__c where supplier__r.id = :selectedSupplierId and CALENDAR_YEAR(Contract_bdate__c) = :selectedNegoYear];
        //   lstContract = [select Id, Name, (select Contract__c.id, Contract__c.Name, Contract_c.Status__c, Contract__c.Contract_BDate__c, Contract__c.Contract_EDate__c 
        //                   from Supplier_Nego_Scope__c.Contracts where CALENDAR_YEAR(Contract_bdate__c) = :selectedNegoYear) from Supplier_Nego_Scope__c where supplier__r.id = :selectedSupplierId ];
        lstNegoScope = [SELECT Id, Name, NS_Code__c , Supplier__r.CurrencyIsoCode, Supplier__r.Id, Supplier__r.Country_origin__c,
                        (SELECT id, Name, Contract_Numbder__c, Status__c, Contract_BDate__c, Contract_EDate__c
                         FROM Contracts1__r
                         WHERE CALENDAR_YEAR(Contract_BDate__c) = :selectedNegoYear
                         ORDER BY Contract_BDate__c DESC)
                        FROM Sup_sup_NegoScope__c
                        WHERE supplier__r.id = :selectedSupplierId
                        AND Parent_Nego_Scope__c = null
                        ORDER BY Name ASC];
        
        integer lstSize = lstNegoScope.size();
        nbNS = lstSize;
        
        wContractNLst = new List<wContractN>();
        wContractNLst.clear();
        
        for (integer i = 0; i < lstSize ; i++) {
            if (lstNegoScope[i].Contracts1__r !=null && !lstNegoScope[i].Contracts1__r.isEmpty()) {
                for (Contract__c con : lstNegoScope[i].Contracts1__r) {
                    wContractN contractNTemp = new wContractN();
                    contractNTemp.NS_Id = lstNegoScope[i].Id;
                    contractNTemp.NS_Name = lstNegoScope[i].Name;
                    contractNTemp.NS = lstNegoScope[i];
                    contractNTemp.contract = con;
                    contractNTemp.selContract = false;
                    wContractNLst.add(contractNTemp); 
                    existContract = true;
                }
            } else {
                wContractN contractNTemp = new wContractN();
                contractNTemp.NS_Id = lstNegoScope[i].Id;
                contractNTemp.NS_Name = lstNegoScope[i].Name;
                contractNTemp.NS = lstNegoScope[i];
                contractNTemp.selContract = false;
                wContractNLst.add(contractNTemp);
            }
        }
        if (wContractNLst.size() > 0) {
            wContractNLst.get(0).selContract = true;
        }
    }
    
    public String indexno {get;set;}
    public void recalc_slabs() {
        integer i =  Integer.valueof(indexno.trim());
        wDiscList[i].enablePercentage = false;
        wDiscList[i].enableAmount = false;
        try {
            Pol_Com_Condition__c cond = [select name, is_conditional__c, Condition_Mode__c from Pol_Com_Condition__c where id = :wDiscList[i].discount.Condition_type__c];
            wDiscList[i].isConditional = cond.is_conditional__c;
            // Adjust fields of amount/percentage based on condition mode
            wDiscList[i].adjustConditionMode(cond.Condition_Mode__c);
        } catch (Exception e) {
            wDiscList[i].isConditional = false;
        }
    }
    
    public integer condId {get; set;} 
    public void changeValid(){
        if (wDiscList[condId].discount.valid__c)
        {wDiscList[condId].discount.valid__c = false;}
        else
        {wDiscList[condId].discount.valid__c = true;}
        
    }
    
    public PageReference SaveOneDiscount() {
        List<Contract_Discount__c> discountRecordsToBeUpserted = new List<Contract_Discount__c>();
        Contract__c conTemp = [select Name, Contract_Numbder__c from Contract__c where id = :idContract];
        if(currentWrapperDiscount != null) {
            //for(WrapperDiscountList eachRecord : wDiscList){
             String [] slabFields = new String [] {NegoptimHelper.normalizeAPIName('Slab_1__c'),NegoptimHelper.normalizeAPIName('slab_per_1__c'),NegoptimHelper.normalizeAPIName('slab_val_1__c'),
                NegoptimHelper.normalizeAPIName('slab_2__c'),NegoptimHelper.normalizeAPIName('slab_per_2__c'),NegoptimHelper.normalizeAPIName('slab_val_2__c'),NegoptimHelper.normalizeAPIName('slab_3__c'),
                NegoptimHelper.normalizeAPIName('slab_per_3__c'),NegoptimHelper.normalizeAPIName('slab_val_3__c'),NegoptimHelper.normalizeAPIName('slab_4__c'),NegoptimHelper.normalizeAPIName('slab_per_4__c'),
                NegoptimHelper.normalizeAPIName('slab_val_4__c'),NegoptimHelper.normalizeAPIName('slab_5__c'),NegoptimHelper.normalizeAPIName('slab_per_5__c'),NegoptimHelper.normalizeAPIName('slab_val_5__c'),
                NegoptimHelper.normalizeAPIName('slab_6__c'),NegoptimHelper.normalizeAPIName('slab_per_6__c'),NegoptimHelper.normalizeAPIName('slab_val_6__c'),NegoptimHelper.normalizeAPIName('Contract__c')};
                         
            if (currentWrapperDiscount.discount.Condition_Type__c != NULL) {
                Contract_Discount__c discTemp = currentWrapperDiscount.discount; 
                discTemp.slab_target__c = currentWrapperDiscount.slabTarget;
                if (currentWrapperDiscount.toInsert) {
                    discTemp.Contract__c = conTemp.id;
                }
                discountRecordsToBeUpserted.add(discTemp);
            }
            if (checkCreatibility(Contract_Discount__c.SObjectType, slabFields)
                && checkUpdatibility(Contract_Discount__c.SObjectType, slabFields)) {
                upsert discountRecordsToBeUpserted;
            }
            runSearch();
        }
        return Page.Conditions_List;
    }
    
    public PageReference CancelDisc() {
        return Page.Conditions_List;
    }  
    
    public string getprefixCond() {
        Schema.DescribeSObjectResult sa = Contract_Discount__c.sObjectType.getDescribe();
        string prefix = sa.getKeyPrefix();
        String BaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        prefix = BaseURL + '/' + prefix;
        return prefix; 
    }  
    
    public PageReference showConditionForm() {
        String BaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        string curPage = ApexPages.currentPage().getURL();
        
        //PageReference acctPage = new PageReference('/' + wDiscList[condId].discount.id+'/e?retUrl=' + curPage);
        PageReference acctPage = new PageReference('/' + wDiscList[condId].discount.id + '?retUrl=' + curPage);
        acctPage.setRedirect(true);
        return acctPage;
    } 
    
    public PageReference showNegoScope() {
        String BaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        string curPage = ApexPages.currentPage().getURL();
        
        //PageReference acctPage = new PageReference('/' + wDiscList[condId].discount.id+'/e?retUrl=' + curPage);
        PageReference acctPage = new PageReference('/apex/Org_NegoScope_Edit?id=' + wDiscList[condId].discount.contract__r.Supplier_Nego_Scope__r.id);
        acctPage.setRedirect(true);
        return acctPage;
    } 
    
    //Manage Product Popup 
    public boolean displayPopup3 {get; set;}
    
    public void closePopup3() {
        displayPopup3 = false; 
        chooseProductScope();
    }     
    public void showPopup3() {
        displayPopup3 = true;
        fillProductScopeLst();
    }       
    
    // Calculate the YTD and update all conditions
    public PageReference calculateYTD() {
        List<Id> idContracts = new List<Id> {contract.Id};
        List<Id> selectedConditions = new List<Id>();
        for (WrapperDiscountList item : wDiscList) {
            if (item.isSelected) selectedConditions.add(item.discount.id);
        }
        if(idContracts != null && idContracts.size() > 0) {
            Id batchInstanceId1 = Database.executeBatch(new CalculateTOContractBatch('Conditions_List', contract.Contract_BU__c, idContracts, selectedNegoYear));
            Id batchInstanceId2 = Database.executeBatch(new CalculateBaseTOBatch('Conditions_List', contract.Contract_BU__c, idContracts, selectedConditions, selectedNegoYear));
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Calculation_Process_Completed);
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    /*
    * Generate Invoice and invoice details
    * Triggered when pressing button 'Generate Invoice'
    * */
    public PageReference generateInvoice() {
        List<Id> idContracts = new List<Id> {contract.Id};
        List<Id> selectedConditions = new List<Id>();
        for (WrapperDiscountList item : wDiscList) {
            if (item.isSelected) selectedConditions.add(item.discount.id);
        }
        Database.executeBatch(new GenerateInvoicesBatch('Conditions_List', contract.Contract_BU__c, idContracts, selectedConditions, contract.Contract_BDate__c));
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Generate_Invoice_Completed);
        ApexPages.addMessage(myMsg);
        return null;
    }
    // Dispatching
    public PageReference dispatching() {
        List<Id> selectedConditions = new List<Id>();
        
        if(wDiscList !=null && !wDiscList.isEmpty()) {
            for(WrapperDiscountList eachRecord : wDiscList){
                if (eachRecord.discount.Condition_Type__c != NULL && eachRecord.isSelected) {
                    selectedConditions.add(eachRecord.discount.Id);
                }
            }
            List<Id> conditions = (selectedConditions != null && selectedConditions.size() > 0) ? selectedConditions : null;
            //CalculationHelper.runDispatching(selectedSupplierId, Date.today(), contract.Id, contract.CurrencyIsoCode, conditions);
            Id batchInstanceId = Database.executeBatch(new DispatchingBatch('Conditions_List', contract.Contract_BU__c, new List<Id> {contract.Id}, conditions, contract.Contract_BDate__c));
        }
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, Label.MSG_Background_Dispatch_Running);
        ApexPages.addMessage(myMsg);
        return null;
    }
    // Generate GRC Rate
    public PageReference generateGRCRate() {
        List<Id> idContracts = new List<Id> {contract.Id};
        Database.executeBatch(new GenerateGRCRatesBatch('Conditions_List', contract.Contract_BU__c, idContracts, Date.today(), contract.Last_Active_Contract__c));
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Job Started');
        ApexPages.addMessage(myMsg);
        return null;
    }
    private List<Sup_sup_NegoScope__c> NSLst {get;set;}
    
    public List<wNSBrand> wNSBrandLst {get;set;}
    
    public class wNSBrand {
        public Boolean selNSBrand {get;set;}
        public Boolean disSelNSBrand {get;set;}
        public Sup_NS_Brand__c NSBrand {get;set;}
        public Sup_Brand__c Brand {get;set;}
    }
    
    public List<wrapperNegoScope> wNSLst {get;set;}
    
    public class wrapperNegoScope {
        public Integer index {get;set;}
        public Sup_sup_NegoScope__c cNS {get;set;}
        public String nameNS {get;set;}
        public String lstBrands {get;set;}
        public String lstShortBrands {get;set;}
        public String lstStruct {get;set;}
        public String lstShortStruct {get;set;}
        public String lstGroup {get;set;}
        public String lstShortGroup{get;set;}
        public Boolean selNS {get;set;}
        public List<Sup_NS_Brand__c> lstBrandObjs {get;set;}
        public List<wNSBrand> wNSBrandLst {get;set;}
    }
    
    private Sup_sup_NegoScope__c tempfullNS;
    
    public integer NSIndexno {get;set;}
    
    public void fillProductScopeLst() {
        //récupérer le nego scope du contrat sélectionné
        Contract__c contractNS = [select Supplier_Nego_Scope__c, Contract_Numbder__c from Contract__c where id = :idContract];
        tempfullNS = [select id, Name, Is_All_Brands__c, Is_All_HE__c, Supplier__c, Is_All__c, 
                      (select id,Sup_Scope_Brand__r.Brand_Owner__r.Name, Sup_Scope_Brand__r.name, Sup_Scope_Brand__c, Supplier__c from Supplier_Nego_scope_Brands__r), 
                      (select id, Structure_Element__r.name, Choice__c from Supplier_Nego_Scope_HEs__r),
                      (select id, Sup_PG__r.Name FROM Supplier_Nego_Scope_PG__r)
                      from Sup_sup_NegoScope__c where id = :contractNS.Supplier_Nego_Scope__c];
        //(select id, (select id, name from Sup_Scope_Brand__c), Supplier__c from Supplier_Nego_scope_Brands__r), 
        //initialiser le NS All Products 
        wNSLst = new List<wrapperNegoScope>();
        wrapperNegoScope wfullNS = new wrapperNegoScope();
        wfullNS.index = wNSLst.size();
        //wfullNS.nameNS = 'Full Nego Scope';
        wfullNS.nameNS = tempfullNS.Name;
        if (wDiscList[condIndexno].nameNS == null || wfullNS.nameNS == wDiscList[condIndexno].nameNS) {
            wfullNS.selNS = true;
        } else {
            wfullNS.selNS = false;
        }
        wfullNS.cNS = tempfullNS;
        //List<Sup_Brand__c> tmpLstBrandObjs = new List<Sup_Brand__c>();
        //tmpLstBrandObjs.clear();
        //tmpLstBrandObjs = [select id, Name from Sup_Brand__c where id in (select Sup_Scope_Brand__c from Sup_NS_Brand__c where Sup_sup_NegoScope__r.id = :tempfullNS.Id)];
        //wfullNS.lstBrandObjs = tmpLstBrandObjs;
        wfullNS.lstBrandObjs = tempfullNS.Supplier_Nego_scope_Brands__r;
        // id test;
        List<wNSBrand> tempwNSBrandLst = new List<wNSBrand>();
        
        if(!wfullNS.lstBrandObjs.isEmpty()){
            for (Sup_NS_Brand__c unBrand : tempfullNS.Supplier_Nego_scope_Brands__r) {
                wNSBrand tempwBrand = new wNSBrand();
                tempwBrand.selNSBrand = true;
                tempwBrand.disSelNSBrand = false;
                tempwBrand.NSBrand = unBrand;
                //tempwBrand.Brand.id = unBrand.Sup_Scope_Brand__c;
                //test = unBrand.Sup_Scope_Brand__c;
                //tempwBrand.Brand.name = unBrand.Sup_Scope_Brand__r.name;
                tempwNSBrandLst.add(tempwBrand);
            }
            wfullNS.wNSBrandLst = tempwNSBrandLst;
            List<Sup_NS_Brand__c> BrandList = new List<Sup_NS_Brand__c>();
            BrandList.clear();
            BrandList = tempfullNS.Supplier_Nego_scope_Brands__r;
            for (Sup_NS_Brand__c unBrand : BrandList) {
                if (wfullNS.lstBrands == null) {
                    wfullNS.lstBrands = unBrand.Sup_Scope_Brand__r.name;
                } else {
                    wfullNS.lstBrands = wfullNS.lstBrands + '/' + unBrand.Sup_Scope_Brand__r.name;
                }
            }
            if (wfullNS.lstBrands.length() <=30) {
                wfullNS.lstShortBrands = wfullNS.lstBrands;
            } else {
                wfullNS.lstShortBrands = wfullNS.lstBrands.substring(0, 27) + '...';
            }
            if (tempfullNS.Is_All_Brands__c) {
                wfullNS.lstShortBrands = Label.MSG_All_Brands;
            }
        }
        List<Supplier_NS_HE__c> StructList = new List<Supplier_NS_HE__c>();
        StructList.clear();
        StructList = tempfullNS.Supplier_Nego_Scope_HEs__r;
        
        Boolean flagInclude = true;
        if(!StructList.isEmpty()) {
            for (Supplier_NS_HE__c unStruct : StructList) {
                
                if (wfullNS.lstStruct == null) {
                    if (unStruct.Choice__c == 'Include') {
                        wfullNS.lstStruct = unStruct.Structure_Element__r.name;
                    } else {
                        wfullNS.lstStruct = 'Excluded: ' + unStruct.Structure_Element__r.name;
                        flagInclude = false;
                    }
                } else {
                    if (unStruct.Choice__c == 'Exclude' && flagInclude == true) {
                        wfullNS.lstStruct = wfullNS.lstStruct + ' - ' + 'Excluded: ' + unStruct.Structure_Element__r.name;
                        flagInclude = false;
                    } else {
                        wfullNS.lstStruct = wfullNS.lstStruct + '/' + unStruct.Structure_Element__r.name;
                    }
                }
            }
            
            if (wfullNS.lstStruct.length() <= 30) {
                wfullNS.lstShortStruct = wfullNS.lstStruct;
            } else {
                wfullNS.lstShortStruct =wfullNS.lstStruct.substring(0, 27) + '...';
            } 
            if (tempfullNS.Is_All_HE__c) {
                wfullNS.lstShortStruct = Label.MSG_All_Elements;
            }           
        }
        
        // kareem edit ( add product group to the list )
        // show list of prouct group in Product  Scope popoup
        List<Sup_NS_PG__c> GroupList = new List<Sup_NS_PG__c>();
        GroupList.clear();
        GroupList = tempfullNS.Supplier_Nego_Scope_PG__r;
        
        if(!GroupList.isEmpty()){
            for (Sup_NS_PG__c unGroupList : GroupList) {
                if (wfullNS.lstGroup == null) {
                    wfullNS.lstGroup = unGroupList.Sup_PG__r.Name;
                } else {
                    wfullNS.lstGroup = wfullNS.lstGroup + '/' +unGroupList.Sup_PG__r.Name;
                }
            }
            if (wfullNS.lstGroup.length() <= 30) {
                wfullNS.lstShortGroup = wfullNS.lstGroup;
            } else {
                wfullNS.lstShortGroup =wfullNS.lstGroup.substring(0, 27) + '...';
            }
            if (tempfullNS.Is_All__c) {
                wfullNS.lstShortGroup = Label.MSG_All_Products;
            }
        }
        // kareem end edit 
        wNSLst.add(wfullNS);
        
        //récupérer la liste des nego scope dont le parent est le nego scope du contrat
        // NSLst = [select id, Name, (select id, (select id, name from Sup_Scope_Brand__r) from Sup_NS_Brand__r) from Sup_sup_NegoScope__c where Parent_Nego_Scope__c = :contractNS.Supplier_Nego_Scope__c];
        NSLst = [select id, Name, Is_All_Brands__c, Is_All_HE__c, Supplier__c,
                 (select id, Sup_Scope_Brand__r.name, Sup_Scope_Brand__r.id, Sup_Scope_Brand__c from Supplier_Nego_scope_Brands__r order by Sup_Scope_Brand__r.name),
                 (select id, Structure_Element__r.name, Choice__c from Supplier_Nego_Scope_HEs__r order by Choice__c, Structure_Element__r.name),
                 (select id, Sup_PG__r.Name FROM Supplier_Nego_Scope_PG__r)
                 from Sup_sup_NegoScope__c where Parent_Nego_Scope__c = :contractNS.Supplier_Nego_Scope__c];
        
        //Remplir le wrapper
        for(Sup_sup_NegoScope__c tempNS : NSLst) {
            wrapperNegoScope tempwNS = new wrapperNegoScope();
            tempwNS.index = wNSLst.size();
            //if (wDiscList[condIndexno].nameNS != null && tempNS.id == wDiscList[condIndexno].discount.Product_Scope__c) {
            if (wDiscList[condIndexno].nameNS != null && tempNS.id == wDiscList[condIndexno].selNS) {
                tempwNS.selNS = true;
            } else {tempwNS.selNS = false;
                   }  
            tempwNS.nameNS = tempNS.Name;
            tempwNS.cNS = tempNS;
            //tmpLstBrandObjs.clear();
            //tmpLstBrandObjs = [select id, Name from Sup_Brand__c where id in (select Sup_Scope_Brand__c from Sup_NS_Brand__c where Sup_sup_NegoScope__r.id = :tempNS.Id)];         
            //tmpLstBrandObjs = tempNS.Supplier_Nego_scope_Brands__r.Sup_Scope_Brand__c;
            //tempwNS.lstBrandObjs = tmpLstBrandObjs; 
            List<wNSBrand> tempwNSBrandLst2 = new List<wNSBrand>();
            //tempwNSBrandLst.clear();
            for (Sup_NS_Brand__c unBrand : tempNS.Supplier_Nego_scope_Brands__r) {
                wNSBrand tempwBrand = new wNSBrand();
                tempwBrand.selNSBrand = true;
                tempwBrand.disSelNSBrand = false;
                tempwBrand.NSBrand = unBrand;
                //tempwBrand.Brand.id = unBrand.Sup_Scope_Brand__c;
                //tempwBrand.Brand.name = unBrand.Sup_Scope_Brand__r.name;
                tempwNSBrandLst2.add(tempwBrand);
            }
            tempwNS.wNSBrandLst = tempwNSBrandLst2;
            List<Sup_NS_Brand__c> BrandList = new List<Sup_NS_Brand__c>();
            BrandList.clear();
            BrandList = tempNS.Supplier_Nego_scope_Brands__r;
            //tempwNS.lstBrandObjs = tempNS.Supplier_Nego_scope_Brands__r;
            for (Sup_NS_Brand__c unBrand : BrandList) {
                if (tempwNS.lstBrands == null) {
                    tempwNS.lstBrands = unBrand.Sup_Scope_Brand__r.name;
                } else {
                    tempwNS.lstBrands = tempwNS.lstBrands + '/' + unBrand.Sup_Scope_Brand__r.name;
                }
            }
            if (tempwNS.lstBrands == null) {tempwNS.lstShortBrands = Label.MSG_No_Brand;}
            else {
                if (tempwNS.lstBrands.length() <= 30) {
                    tempwNS.lstShortBrands = tempwNS.lstBrands;
                } else {
                    tempwNS.lstShortBrands = tempwNS.lstBrands.substring(0, 27) + '...';
                }
            }
            if (tempNS.Is_All_Brands__c) {
                tempwNS.lstShortBrands = Label.MSG_All_Brand;
            }
            StructList.clear();
            StructList = tempNS.Supplier_Nego_Scope_HEs__r;
            flagInclude = true;
            //String sep = System.line.separator;
            for (Supplier_NS_HE__c unStruct : StructList) {
                if (tempwNS.lstStruct == null) {
                    if (unStruct.Choice__c == 'Include') {
                        tempwNS.lstStruct = unStruct.Structure_Element__r.name;
                    } else {
                        tempwNS.lstStruct = 'Excluded: ' + unStruct.Structure_Element__r.name;
                        flagInclude = false;
                    }
                } else {
                    if (unStruct.Choice__c == 'Exclude' && flagInclude == true) {
                        tempwNS.lstStruct = tempwNS.lstStruct + ' - ' + 'Excluded: ' + unStruct.Structure_Element__r.name;
                        flagInclude = false;
                    } else {
                        tempwNS.lstStruct = tempwNS.lstStruct + '/' + unStruct.Structure_Element__r.name;
                    }
                }
            }
            //tempwNS.lstShortStruct = 'All Elements';   
            if (tempwNS.lstStruct == null) {tempwNS.lstShortStruct = Label.MSG_No_Structure; }
            else {
                if (tempwNS.lstStruct.length() <= 30) {
                    tempwNS.lstShortStruct = tempwNS.lstStruct;
                } else {
                    tempwNS.lstShortStruct = 'second '+tempwNS.lstStruct.substring(0, 27) + '...';
                }
            }
            if (tempNS.Is_All_HE__c) {tempwNS.lstShortStruct = Label.MSG_All_Elements;}
            wNSLst.add(tempwNS);
        }
        //Remplir la variable lstBrands pour chaque Nego Scope
    } 
    
    public void chooseProductScope() {
        //Save added Nego Scopes
        List<Sup_sup_NegoScope__c> upLstNS = new List<Sup_sup_NegoScope__c>();
        List<Sup_NS_Brand__c> upLstNSBrand = new List<Sup_NS_Brand__c>();
        
        for (wrapperNegoScope unwNS : wNSLst) {
            Sup_sup_NegoScope__c tempNS = unwNS.cNS;
            tempNS.name = unwNS.nameNS;
            // Set current user as oener for newly created Nego Scope
            if(tempNS.Id == NULL) {
                tempNS.OwnerId = UserInfo.getUserId();
            }
            upLstNS.add(tempNS);
            if(unwNS.wNSBrandLst != NULL) {
                for (wNSBrand unNSBrand : unwNS.wNSBrandLst) {
                    if (unNSBrand.selNSBrand) {
                        Sup_NS_Brand__c tempNSBrand = unNSBrand.NSBrand;
                        upLstNSBrand.add(tempNSBrand);
                    }
                }
            }
        }
        try {
            // TODO: REACTIVATE THE CODE RELATED TO UPSERTION
            ////upsert upLstNS;
            ////upsert upLstNSBrand;
            
            //Récupérer le Nego Scope sélectionné et son nom
            Sup_sup_NegoScope__c selectedNS = new Sup_sup_NegoScope__c();
            String selectedNameNS;
            
            for (wrapperNegoScope tempwNS : wNSLst) {
                if (tempwNS.selNS == true) {
                    selectedNS = tempwNS.cNS;
                    selectedNameNS = tempwNS.nameNS;
                }
            }
            //Modifier le nom et l'id du NegoScope avec celui sélectionné pour la condition active dans le wrapper
            wDiscList[condIndexno].nameNS = selectedNameNS;
            // wDiscList[condIndexno].discount.Product_Scope__c = selectedNS.id;  
            wDiscList[condIndexno].selNS = selectedNS.id;
            wDiscList[condIndexno].discount.Product_Scope__c = selectedNS.id;
        } catch (Exception ex) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage());
            ApexPages.addMessage(myMsg);
        }
    }
    
    //Manage Brand Popup 
    public boolean displayPopup4 {get; set;}
    
    public void closePopup4() {
        displayPopup4 = false;
        refreshBrandLst();
    }     
    public void showPopup4() {
        displayPopup4 = true;
        fillNSBrandLst();
    }
    
    public void fillNSBrandLst() {
        // List<Sup_NS_Brand__c> NSbrandLst= [select id, Name, Sup_Scope_Brand__r.Name from Sup_NS_Brand__c where Sup_sup_NegoScope__r.id = :NSId];
        //Sup_Brand__c
        // List<Sup_Brand__c> NSbrandLstsel= [select id, Name from Sup_Brand__c where id in (select Sup_Scope_Brand__c from Sup_NS_Brand__c where Sup_sup_NegoScope__r.id = :NSId)];
        //    List<Sup_NS_Brand__c> NSbrandLstsel= new List<Sup_NS_Brand__c>();
        //    NSbrandLstsel.clear();
        //    NSbrandLstsel = wNSLst[NSIndexno].lstBrandObjs;
        /*   List<Sup_NS_Brand__c> NSbrandLstNsel= new List<Sup_NS_Brand__c>();
NSbrandLstNsel.clear();
//     NSbrandLstNsel = [select id, Sup_Scope_Brand__r.Name, Sup_Scope_Brand__r.id from Sup_NS_Brand__c where Sup_sup_NegoScope__r.id != :wNSLst[NSIndexno].cNS.id
//                       and supplier__c in (select supplier__c from Contract__c where id = :idContract)];*/
        //     if (NSbrandLstsel.isEmpty()) {    
        //         NSbrandLstsel= [select id, Sup_Scope_Brand__r.Name, Sup_Scope_Brand__r.id from Sup_NS_Brand__c where Sup_sup_NegoScope__r.id = :tempfullNS.Id];
        /*  NSbrandLstNsel= [select id, Name from Sup_Brand__c where id not in (select Sup_Scope_Brand__c from Sup_NS_Brand__c where Sup_sup_NegoScope__r.id = :tempfullNS.Id)
and brand_owner__c in (select supplier__c from Contract__c where id = :idContract)];*/
        //    }
        
        //    wNSBrandLst = new List<wNSBrand>();
        
        //Remplir le wrapper
        //  for(Sup_NS_Brand__c tempNSBrand : NSbrandLstsel) {
        //    wNSBrand tempwNSBrand = new wNSBrand();
        //if (wDiscList[condIndexno].nameNS != null && tempNS.id == wDiscList[condIndexno].discount.Product_Scope__c) {
        //  tempwNSBrand.selNSBrand = true;
        //  tempwNSBrand.disSelNSBrand = false;
        //} else {tempwNS.selNS = false;
        //}  
        //  tempwNSBrand.NSBrand= tempNSBrand;
        // wNSBrandLst.add(tempwNSBrand);
        //}
        /*for(Sup_NS_Brand__c tempNSBrand : NSbrandLstNsel) {
wNSBrand tempwNSBrand = new wNSBrand();
//if (wDiscList[condIndexno].nameNS != null && tempNS.id == wDiscList[condIndexno].discount.Product_Scope__c) {
tempwNSBrand.selNSBrand = false;
tempwNSBrand.disSelNSBrand = true;
//} else {tempwNS.selNS = false;
//}  
tempwNSBrand.NSBrand= tempNSBrand;
wNSBrandLst.add(tempwNSBrand);
}   */    
    } 
    
    public void chooseNSBrandLst() {
        List<Sup_NS_Brand__c> lstSelBrands = new List<Sup_NS_Brand__c>();
        
        for (wNSBrand tempwNSBrand : wNSBrandLst) {
            
            if (tempwNSBrand.selNSBrand) {
                lstSelBrands.add(tempwNSBrand.NSBrand);
            }
            
            wNSLst[NSIndexno].lstBrandObjs = lstSelBrands;
        }
        //wNSLst[NSIndexno].lstBrandObjs = wNSBrandLst;
        //Récupérer la liste des marques sélectionnées
        /*     Sup_sup_NegoScope__c selectedNS = new Sup_sup_NegoScope__c();
string selectedNameNS;

for (wNSBrand tempWNSBrand : wNSBrandLst) {
if (tempWNSBrand.selNSBrand == true) {
selectedNS = tempwNS.cNS;
selectedNameNS = tempwNS.nameNS;
}
}
//Modifier la liste des marques sélectionnées
wDiscList[condIndexno].nameNS = selectedNameNS;
wDiscList[condIndexno].discount.Product_Scope__c = selectedNS.id;      */
    }
    
    //Manage Brand Popup 
    public boolean displayPopup5 {get; set;}
    
    public void closePopup5() {
        displayPopup5 = false;
    }     
    public void showPopup5() {
        displayPopup5 = true;
        fillNSStructLst();
    }
    
    
    public List<wNSStruct> wNSStructLst {get;set;}
    
    public class wNSStruct {
        public String Choice {get;set;}
        public Orga_HE__c NSStruct {get;set;}
    }
    
    /* kareem edit */
    public List<wNSProductGroup> wNSProductGroupLst {get;set;}
    
    public class wNSProductGroup {
        public Supplier_PG_Mapping__c NSProductGroup {get;set;}
    }
    
    public void fillNSStructLst() {
        List<Orga_HE__c> NSStructLstinc= [select id, Name from Orga_HE__c where id in (select Structure_Element__c from Supplier_NS_HE__c where Sup_sup_NegoScope__r.id = :wNSLst[NSIndexno].cNS.id and Choice__c = 'Include')];
        List<Orga_HE__c> NSStructLstexc= [select id, Name from Orga_HE__c where id in (select Structure_Element__c from Supplier_NS_HE__c where Sup_sup_NegoScope__r.id = :wNSLst[NSIndexno].cNS.id and Choice__c = 'Exclude')];
        
        wNSStructLst = new List<wNSStruct>();
        
        //Remplir le wrapper
        for(Orga_HE__c tempNSStruct : NSStructLstinc) {
            wNSStruct tempwNSStruct = new wNSStruct();
            tempwNSStruct.choice = 'Included'; 
            tempwNSStruct.NSStruct = tempNSStruct;
            wNSStructLst.add(tempwNSStruct);
        }
        for(Orga_HE__c tempNSStruct : NSStructLstexc) {
            wNSStruct tempwNSStruct = new wNSStruct();
            tempwNSStruct.choice = 'Excluded';  
            tempwNSStruct.NSStruct= tempNSStruct;
            wNSStructLst.add(tempwNSStruct);
        }       
    }  
    /*
* Triggered when click button Add Nego Scope
* */
    public void addNewNS() {
        wrapperNegoScope newWNS = new wrapperNegoScope();
        Sup_sup_NegoScope__c newNS = new Sup_sup_NegoScope__c();
        newNS = tempfullNS.clone();
        newNS.Parent_Nego_Scope__c = tempfullNS.id;
        newWNS.index = wNSLst.size();
        newWNS.cNS = newNS;
        //newWNS.lstBrandObjs = tempfullNS.Supplier_Nego_scope_Brands__r;
        List<wNSBrand> tempwNSBrandLst = new List<wNSBrand>();
        for (Sup_NS_Brand__c unBrand : tempfullNS.Supplier_Nego_scope_Brands__r) {
            wNSBrand tempwBrand = new wNSBrand();
            tempwBrand.selNSBrand = true;
            tempwBrand.disSelNSBrand = false;
            tempwBrand.NSBrand = new Sup_NS_Brand__c();
            tempwBrand.NSBrand.Sup_sup_NegoScope__c = newNS.id;
            tempwBrand.NSBrand.Supplier__c = unBrand.Supplier__c;
            tempwBrand.NSBrand.Sup_Scope_Brand__c = unBrand.Sup_Scope_Brand__c;
            //tempwBrand.NSBrand.Sup_Scope_Brand__r.Name = unBrand.Sup_Scope_Brand__r.Name;
            tempwNSBrandLst.add(tempwBrand);
        }
        newWNS.wNSBrandLst = tempwNSBrandLst; 
        newWNS.lstShortBrands = Label.MSG_Choose_Brands;
        newWNS.lstShortStruct = Label.MSG_Choose_Hierarchy_Elements;
        wNSLst.add(newWNS);
    }    
    
    /*     public List<wNSBrand> wNSBrandLst {get;set;}

public class wNSBrand {
public Boolean selNSBrand {get;set;}
public Boolean disSelNSBrand {get;set;}
public Sup_NS_Brand__c NSBrand {get;set;}
}

public List<wrapperNegoScope> wNSLst {get;set;}

public class wrapperNegoScope {
public Integer index {get;set;}
public Sup_sup_NegoScope__c cNS {get;set;}
public String nameNS {get;set;}
public String lstBrands {get;set;}
public String lstShortBrands {get;set;}
public String lstStruct {get;set;}
public String lstShortStruct {get;set;}       
public Boolean selNS {get;set;}   
public List<Sup_NS_Brand__c> lstBrandObjs {get;set;}   
public List<wNSBrand> wNSBrandLst {get;set;} 
}

private Sup_sup_NegoScope__c tempfullNS;  

public integer NSIndexno {get;set;}  
*/ 
    
    public void refreshBrandLst() {
        //Refresh Brand List
        wNSLst[NSIndexNo].lstBrands = null;
        wNSLst[NSIndexNo].lstShortBrands = null;
        List<wNSBrand> BrandList = new List<wNSBrand>();
        BrandList.clear();
        BrandList = wNSLst[NSIndexno].wNSBrandLst;
        for (wNSBrand unBrand : BrandList) {
            if (unBrand.selNSBrand) {
                if (wNSLst[NSIndexNo].lstBrands == null) {
                    wNSLst[NSIndexNo].lstBrands = unBrand.NSBrand.Sup_Scope_Brand__r.name;
                } else
                {
                    wNSLst[NSIndexNo].lstBrands = wNSLst[NSIndexNo].lstBrands + '/' + unBrand.NSBrand.Sup_Scope_Brand__r.name;
                }      
                if (wNSLst[NSIndexNo].lstBrands.length() <=30) {
                    wNSLst[NSIndexNo].lstShortBrands = wNSLst[NSIndexNo].lstBrands;
                } else
                {
                    wNSLst[NSIndexNo].lstShortBrands = wNSLst[NSIndexNo].lstBrands.substring(0, 27) + '...';
                } 
                if (wNSLst[NSIndexNo].cNS.Is_All_Brands__c) {
                    wNSLst[NSIndexNo].lstShortBrands = 'All Brands';
                }  
            }
        }
    }
    
    public boolean displayPopup6 {get; set;}
    
    public void closePopup6() {
        displayPopup6 = false;  
    }     
    public void showPopup6() {
        displayPopup6 = true;
        LoadGroupLst();
    }
    
    /**
    * @author kareem zok
    * return list of product group checked in negoscope for a supplier 
    */
    public void LoadGroupLst() {
        // we load al PG id from nego scope id then we get names from these id using ( in ) 
        List<Supplier_PG_Mapping__c> NSProductGroupLstPg= [SELECT Id, Name, Department__r.Name, Section__r.Name, Status__c, Brand__r.Name
                                                               FROM Supplier_PG_Mapping__c 
                                                               WHERE id IN (SELECT s.Sup_PG__c
                                                                            FROM Sup_NS_PG__c s
                                                                            WHERE Sup_sup_NegoScope__r.id =: wNSLst[NSIndexno].cNS.id)];
        wNSProductGroupLst = new List<wNSProductGroup>();
        //Remplir le wrapper
        for(Supplier_PG_Mapping__c tempNSProductGroup : NSProductGroupLstPg) {
            wNSProductGroup tempwNSProductGroup = new wNSProductGroup();
            tempwNSProductGroup.NSProductGroup = tempNSProductGroup;
            wNSProductGroupLst.add(tempwNSProductGroup);
        }
    }
    
    // Download dispatch as CSV or Excel file.
    public PageReference export() {
        //displayDownCSV = false;
        PageReference ref;
        WrapperDiscountList currentCondition = wDiscList[condIndexno];
        if (fileType == 'isCSV') {
            ref = Page.ExportDispatchCSV;
        }
        if (fileType == 'isExcel') {
            ref = Page.ExportDispatchExcel;
        }
        ref.getParameters().put('BU', currentCondition.discount.BU_Scope__c);
        ref.getParameters().put('NS', currentCondition.discount.Product_Scope__c);
        ref.getParameters().put('Id', currentCondition.discount.Id);
        ref.getParameters().put('action', 'Export');
        ref.setRedirect(true);
        return ref;
    }
    
    @RemoteAction
    global static String attachBlob(String parentId, String attachmentId, String fileName, String contentType, String base64BlobValue) {
        //If recordId is blank this is the first part of a multi piece upload
        if(attachmentId == '' || attachmentId == null) {
            Attachment att = new Attachment(
                ParentId = parentId,
                Body = EncodingUtil.Base64Decode(base64BlobValue),
                Name = fileName,
                ContentType = contentType
            );
            String[] attchFields = new String[] {'Name', 'Body'};
            if(NegoptimHelper.checkCreatibility(Attachment.SObjectType, attchFields)) {
                insert att;
                // new attachment Id
                attachmentId = att.Id;
            }
        } else {
            for(Attachment atm : [SELECT Id, Body FROM Attachment where Id = :attachmentId]) {
                //Take the body of the current attachment, convert to base64 string, append base64 value sent from page, then convert back to binary for the body
                update new Attachment(Id = attachmentId, Body = EncodingUtil.Base64Decode(EncodingUtil.Base64Encode(atm.Body) + base64BlobValue));
            }
        }
        //Return the Id of the attachment we are currently processing
        return attachmentId;
    }
    
    public PageReference importCSV() {
        displayWizardPopup = false;
        If(attachmentId == NULL || attachmentId == '') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Check your profile permission.'));
            return null;
        }
        Attachment att;
        try {
            att = [SELECT Id, Name, Body FROM Attachment WHERE Id = :attachmentId];
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'FILE NOT FOUND.'));
            return null;
        }
        List<String> tab = att.Name.split('\\.');
        String lastElt = tab.get(tab.size()-1);
        String csvContent = att.Body.toString();
        WrapperDiscountList currentCondition = wDiscList[condIndexno];
        Integer currentMonth = Date.Today().month();
        if (lastElt == 'csv' && csvContent != '') {
            List<List<String>> contentData = NegoptimHelper.parseCSV(csvContent, true);
            ////contentData.remove(0);
            Integer rowIndex = -1;
            for (List<String> row : contentData) {
                rowIndex++;
                Integer rowSize = row.size();
                // validate rows count and add default value if not exist
                // TODO: create helper method to validate and fill empty cells if required
                if (rowSize <= 15) {
                    for (Integer i = 4 ; i <= 15 ; i++) {
                        if (rowSize == i) {
                            for (Integer j = 1 ; j <= 16 - i ; j++) {
                                row.add('');
                            }
                        }
                    }
                    contentData.set(rowIndex, row);
                }
            }
            Boolean isValidInput = true;
            for (List<String> row : contentData) {
                if (row.size() != 16) {
                    isValidInput = false;
                    break;
                }
            }
            if (isValidInput == true) {
                currentConditionId = currentCondition.discount.Id;
                for (Integer i = 0 ; i < currentCondition.realDistpatchDetailList.size() ; i++) {
                    WrapperDispatchDetail eachRecord = currentCondition.realDistpatchDetailList.get(i);
                    if(eachRecord.distpatchDetail != null) {
                        if (currentCondition.realDistpatchDetailList.size() == contentData.size()-1) {
                            if (eachRecord.nameBU != contentData.get(i+1).get(0).trim()
                                || eachRecord.section != contentData.get(i+1).get(1).trim()
                                || eachRecord.namePG != contentData.get(i+1).get(2).trim()) {
                            } else {
                                // Fill the grid regarding the current month.
                                Decimal[] ms = new Decimal[12];
                                for (Integer j = 0 ; j <= 11 ; j++) {
                                    ms[j] = NegoptimHelper.getDecimalValue(contentData.get(i+1).get(j+3));
                                }
                                for(Integer k = currentMonth; k <= 12 ; k++) {
                                    eachRecord.distpatchDetail.put('Fix_Amount_Dispatch_M' + k + '__c', ms[k-1]);
                                }
                            }
                        } else {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Invalid number of records.'));
                        }
                    }
                }
                // for normal case when size < 1000
                if(currentCondition.distpatchDetailList.size() != 0) {
                    currentCondition.distpatchDetailList = currentCondition.realDistpatchDetailList;
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSG_Invalid_File_Content));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.MSG_Invalid_File_Extension_Or_File_Empty));
        }
        return null;
    }
    
    public void uploadWizard() {
        displayWizardPopup = true;
        showCancelButton = true;
        showNextButton = true;
    }
    
    public void submitCancel() {
        displayWizardPopup = false;
    }
}