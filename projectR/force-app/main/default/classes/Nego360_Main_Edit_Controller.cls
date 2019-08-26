public with sharing class Nego360_Main_Edit_Controller extends NegoptimBaseController {
    
    public List<String> errors {get; set;}
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
    public String selectedMultiYearOption { get; set; }
    
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
    public boolean displayPopUpConditionDetails {get; set;}
    public boolean displayPopUpSlabs {get; set;}
    public boolean displayPopUpMultiYearSecure {get; set;}
    public List<SelectOption> listSubNegoScopes {get; set;}
    public Id subNegoScopeId {get; set;}
    // Slabs count
    public Integer[] slabs {get; set;}
    /**
    * Open the popup that match a specific popup Name
    * @param popupName
    * */
    public void showPopup() {
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
            slabs = new Integer[SlabManager.slabsCount];
            for(Integer ndx = 1; ndx <= SlabManager.slabsCount; ndx++) {
                slabs.add(ndx);
            }
            displayPopUpSlabs = true;
            Boolean isSelectedContract = false;
            Integer j = 0;
            for(Line item : matrice.linesTable) {
                if(item.lineId == lineKey && !item.isSubTotal) {
                    lineIndex = j;
                    break;
                }
                j++;
            }
        }
        if(popupName == 'multiYearSecurePopup') {
            displayPopUpMultiYearSecure = true;
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
            ////chooseSlabTarget(lineKey, cellIndex);
            matrice.linesTable[lineIndex].cells[cellIndex].sortSlabs('ASC');
        }
        if(popupName == 'cancelSlabsPopup') {
            displayPopUpSlabs = false;
        }
        if(popupName == 'multiYearSecurePopup') {
            displayPopUpMultiYearSecure = false;
        }
        else {
            // do nothing
        }
    }
    /**
    * Constructor
    * */
    public Nego360_Main_Edit_Controller() {
        errors = new List<String>();
        isReadApproval = false;
        createMode = true;
        supplierId = ApexPages.currentPage().getParameters().get('supplier');
        sNegoYear = ApexPages.currentPage().getParameters().get('negoyear');
        
        if (supplierId == null || !NegoptimHelper.validateId(supplierId)) {
            errors.add(Label.Error_NoSupplierSelected);
            // throw new NOException(Label.Error_NoSupplierSelected);
        }
        if (sNegoYear == null) {
            errors.add(Label.Error_NoNegoYearSelected);
            // throw new NOException(Label.Error_NoNegoYearSelected);
        }
        if (errors.size() == 0) {
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
                    else if(negoScopeOptions.size() == 0) {
                        errors.add('Supplier doesn\'t have NegoScopes.');
                    }
                }
            }
        }
        if(errors.size() > 0) {
            for(String error : errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
            }
        }
    }
    public PageReference goToSelectionPage() {
        PageReference pageRef = new PageReference('/apex/Nego360_Main_Selection');
        pageRef.setRedirect(true);
        return pageRef;
    }
    // Redirect to Executive Summary page
    public pageReference ExecutiveSummary() {
        for(WrapperColumn item : matrice.columns) {
            if(item.contract.Selected_Simul_For_Approval__c) {
                selectedContractId = item.contract.Id;
            }
        }
        if(selectedContractId == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No Contract selected or contract not yet saved.'));
            return null;
        }
        PageReference pageRef = Page.Nego360_ExecutiveSummary;
        pageRef.getParameters().put('id', '' + selectedContractId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    public PageReference changeMultiYearSecure() {
        for(Line item : matrice.linesTable) {
            for(Integer i = 0; i < item.cells.size(); i++) {
                Cell c = item.cells.get(i);
                c.isForSimulation = false;
                if(matrice.columns.get(i).contract.Secure_Multiyear__c == '2 years' || matrice.columns.get(i).contract.Secure_Multiyear__c == '3 years') {
                    c.isForSimulation = true;
                    c.secureYearValue = matrice.columns.get(i).contract.Secure_Multiyear__c;
                    if(c.conditionWrapper != null) {
                        if(c.conditionWrapper.condition.Value_per_Y1__c == null) {
                            c.conditionWrapper.condition.Value_per_Y1__c = c.conditionWrapper.condition.Value_per__c;
                        }
                        if(c.conditionWrapper.condition.Value_amt_Y1__c == null) {
                            c.conditionWrapper.condition.Value_amt_Y1__c = c.conditionWrapper.condition.Value_amt__c;
                        }
                        if(c.conditionWrapper.condition.Value_per_Y2__c == null) {
                            c.conditionWrapper.condition.Value_per_Y2__c = c.conditionWrapper.condition.Value_per__c;
                        }
                        if(c.conditionWrapper.condition.Value_amt_Y2__c == null) {
                            c.conditionWrapper.condition.Value_amt_Y2__c = c.conditionWrapper.condition.Value_amt__c;
                        }
                    }
                }
            }
        }
        return null;
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
            getFieldName('Contract_BU__c'), getFieldName('Parent_Contract__c'), getFieldName('Duration__c'), getFieldName('Qty1__c'), getFieldName('Total_Qty_Fact__c'),
            getFieldName('Depreciation_Rate__c'), getFieldName('Markdown_Rate_Break__c'), getFieldName('Markdown_Rate_Promo__c'),
            getFieldName('Markdown_Rate_Theft__c'), getFieldName('Rise_Rate__c'), getFieldName('Selected_Simul_For_Approval__c'),
            getFieldName('Secure_Multiyear__c'), getFieldName('VAT_Rebate_Rate__c'), getFieldName('VAT_Service_Rate__c'),
            getFieldName('VAT_Finance_Rate__c'), getFieldName('Buying_Payment_Term_Abbrev__c'), getFieldName('Services_Payment_Term_Abbrev__c')};
        if(!checkAccessibility(Contract__c.SObjectType, contractNegoFields)) {
            return null;
        }
        
        listContractNego = [SELECT Id, Name, CurrencyIsoCode, Contract_Type__c, Reference_Year__c, Supplier_Nego_Scope__c, Supplier__c,
                            TO1__c, Total_TO_Fact__c, Total_TO_Ref__c, Contract_BDate__c, Contract_EDate__c, SimulationNumber__c,
                            Contract_BU__c, Parent_Contract__c, Duration__c, Qty1__c, Total_Qty_Fact__c, Depreciation_Rate__c,
                            Markdown_Rate_Break__c, Markdown_Rate_Promo__c,  Markdown_Rate_Theft__c, Rise_Rate__c, Selected_Simul_For_Approval__c,
                            Secure_Multiyear__c, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c, Buying_Payment_Term_Abbrev__c,
                            Services_Payment_Term_Abbrev__c
                            FROM Contract__c
                            WHERE Supplier_Nego_Scope__c = :selectedNegoScopeId
                            AND((Contract_Type__c = :TYPE_CONTRACT AND CALENDAR_YEAR(Contract_EDate__c) = :(negoYear - 1) AND D_N__c = 'N')
                                OR(Contract_Type__c <> :TYPE_CONTRACT AND CALENDAR_YEAR(Contract_EDate__c) = :negoYear))
                            ORDER BY SimulationNumber__c ASC NULLS FIRST];
      
        for (Contract__c contractNego : listContractNego) {
            if (contractNego.Contract_Type__c == TYPE_CONTRACT) {
                existingContractType = true;
                existingdefaultContract = true;
                refContractId = contractNego.Id;
                listNewContractNego = new List<Contract__c>();
                listNewContractNego.add(contractNego);
                // set the Total_TO_Fact__c in TO1__c to make right calculation
                contractNego.TO1__c = contractNego.Total_TO_Fact__c;
                refTO = contractNego.Total_TO_Fact__c;
                totalRefTO = contractNego.Total_TO_Ref__c;
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
    public List<SelectOption> getListMultiYear() {
        Integer max = currentContract.Secure_Multiyear__c.contains('2') ? 2 : currentContract.Secure_Multiyear__c.contains('3') ? 3 : 0;
        List<SelectOption> options = new List<SelectOption>();
        for(Integer i = 1; i <= max; i++) {
            options.add(new SelectOption(i + ' years', 'Y+' + i));
        }
        selectedMultiYearOption = options.get(0).getValue();
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
        String[] conditionsFields = new String[] { 'Id', 'Name', getFieldName('Condition_Type__c'), getFieldName('Nego_Discount_Type__c'), getFieldName('Contract__c'), getFieldName('Value_per__c'), getFieldName('Value_amt__c'), getFieldName('Index__c') };
        if(!checkAccessibility(Contract_Discount__c.SObjectType, conditionsFields)) {
            return null;
        }
        
        listConditions = [SELECT Id, Name, Condition_Type__c, Nego_Discount_Type__c, Value_per__c, Value_amt__c, Value_per_Y1__c, Value_amt_Y1__c, Value_per_Y2__c, Value_amt_Y2__c,
                          Disc_BDate__c, Disc_EDate__c, Contract__c, Product_Scope__c, BU_Scope__c, Base_TO_Nego__c, Index__c, commercial_reference__c, Reference_condition__c,
                          slab_1__c, slab_per_1__c, slab_val_1__c, slab_2__c, slab_per_2__c, slab_val_2__c, slab_3__c, slab_per_3__c, slab_val_3__c,
                          slab_4__c, slab_per_4__c, slab_val_4__c, slab_5__c, slab_per_5__c, slab_val_5__c, slab_6__c, slab_per_6__c, slab_val_6__c,
                          slab_7__c, slab_per_7__c, slab_val_7__c, slab_8__c, slab_per_8__c, slab_val_8__c, slab_target__c, 
                          Condition_Type__r.Id, Condition_Type__r.Nego_Discount_Type__c, Condition_Type__r.Name, Condition_Type__r.Condition_status__c, Condition_Type__r.Index__c,
                          Condition_Type__r.Is_Conditional__c, Condition_Type__r.Condition_Mode__c, Contract__r.Name, Contract__r.Contract_Type__c, Contract__r.Contract_EDate__c, Contract__r.Total_TO_Fact__c,
                          Contract__r.SimulationNumber__c, Contract__r.Secure_Multiyear__c, slab_calc_method__c, Slab_Calc_Method_TO_Origin__c
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
        
        /***boolean createMode = listContractNego.size() == 1;***/
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
                ////cell.mapConditionToSlabs(wCond.condition);
            }
            // check if condition is locked
            if (wCond.contractNego.Contract_Type__c == TYPE_SIMULATION) {
                if(objectIsLocked(wCond.contractNego.Id) == true) {
                    isReadApproval = true;
                }
                if(wCond.contractNego.Secure_Multiyear__c == '2 years' || wCond.contractNego.Secure_Multiyear__c == '3 years') {
                    cell.isForSimulation = true;
                    cell.secureYearValue = wCond.contractNego.Secure_Multiyear__c;
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
    public List<Pol_Sale_Condition_Exception__c> salesConditionExceptionList { get; set; }
    public PageReference addContract() {
        Contract__c referenceContract = listNewContractNego.get(0); // ref contract is always on index 0
        Contract__c newContractNego = referenceContract.clone(false, true, false, false);
        newContractNego.Contract_BDate__c = date.newInstance(negoYear, referenceContract.Contract_BDate__c.month(), referenceContract.Contract_BDate__c.day());
        newContractNego.Contract_EDate__c = date.newInstance(negoYear, referenceContract.Contract_EDate__c.month(), referenceContract.Contract_EDate__c.day());
        newContractNego.Parent_Contract__c = referenceContract.Id;
        String columnHeaderName;
        Boolean isForSimulation = false;
        if (existingTargetType == false && addedTargetType == false) {
            newContractNego.Contract_Type__c = TYPE_TARGET;
            columnHeaderName = newContractNego.Contract_Type__c + ' ' + negoYear;
            addedTargetType = true;
        } else {
            numContractSimulation = numContractSimulation + 1;
            newContractNego.Contract_Type__c = TYPE_SIMULATION;
            newContractNego.SimulationNumber__c = numContractSimulation;
            newContractNego.Secure_Multiyear__c = NegoptimHelper.defaultPicklistValue(Contract__c.Secure_Multiyear__c.getDescribe());
            columnHeaderName = 'Round' + ' ' + numContractSimulation + ' ' + negoYear;
            if(newContractNego.Secure_Multiyear__c == '2 years' || newContractNego.Secure_Multiyear__c == '3 years') {
                isForSimulation = true;
            }
        }
        newContractNego.Name = columnHeaderName + ' *';
        WrapperColumn c = new WrapperColumn(newContractNego);
        // fetch Pol_Sale_Condition_Exception__c of reference contract if exist
        if(salesConditionExceptionList == null) {
            // TODO: Check fields security
            salesConditionExceptionList = [SELECT Id, VAT_Rebate_Rate__c, VAT_Service_Rate__c, VAT_Finance_Rate__c,
                                           Buying_Payment_Days__c, Buying_Payment_Condition__c,
                                           Services_Payment_Days__c, Services_Payment_Condition__c,
                                           Payment_term_exc1_section__c, Buying_Payment_Term_Abbrev_Exc1__c, Buying_Payment_Condition_exc1__c,
                                           Payment_term_exc2_section__c, Buying_Payment_Term_Abbrev_Exc2__c, Buying_Payment_Condition_exc2__c
                                           FROM Pol_Sale_Condition_Exception__c
                                           WHERE Contract__c = :referenceContract.Id];
        }
        if(salesConditionExceptionList.size() > 0) {
            c.salesConditionException = salesConditionExceptionList.get(0).clone(false, true, false, false);
            c.salesConditionException.Policy_Sales_Conditions__c = null;
        }
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
            condition = parentCondition.clone(false, true, false, false);
            condition.Reference_condition__c = parentCondition.Id;
            condition.Disc_BDate__c = newContractNego.Contract_BDate__c;
            condition.Disc_EDate__c = newContractNego.Contract_EDate__c;
            condition.Product_Scope__c = parentCondition.Product_Scope__c == null ? selectedNegoScopeId : parentCondition.Product_Scope__c;
            condition.BU_Scope__c = parentCondition.BU_Scope__c == null ? supplier.Country_origin__c : parentCondition.BU_Scope__c;
            condition.Contract__c = null;
            /***condition = new Contract_Discount__c(Condition_Type__c = refCell.conditionWrapper.conditionDefinition.Id,
                                                 Value_per__c = p, Value_amt__c = a, Disc_BDate__c = newContractNego.Contract_BDate__c,
                                                 Disc_EDate__c = newContractNego.Contract_EDate__c, Nego_Discount_Type__c = t,
                                                 Product_Scope__c = ns, BU_Scope__c = bu,
                                                 /**Base_TO_Nego__c = parentCondition.Base_TO_Nego__c,** / Reference_condition__c = parentCondition.Id);**/
            conditionDefinition = refCell.conditionWrapper.conditionDefinition.clone(false, true, false, false);
            // force not atteined slab conditions to have first percent and amount values of slabs by default
            if(conditionDefinition.Is_Conditional__c && (parentCondition.slab_target__c == null || parentCondition.slab_target__c == 0)) {
                condition.slab_target__c = 1;
                condition.Value_per__c = condition.slab_per_1__c;
                condition.Value_amt__c = condition.slab_val_1__c;
            }
            ConditionWrapper conditionWrapper = new ConditionWrapper(condition, conditionDefinition, newContractNego);
            
            cell = new Cell(conditionWrapper);
            if(matrice.lines.get(i).isConditional) {
                ////cell.mapConditionToSlabs(parentCondition);
            }
            cell.isReadOnly = false;
            cell.isSubTotal = false;
            cell.isEmpty = true;
            cell.type = matrice.lines.get(i).type;
            cell.amount = a;
            cell.percent = p;
            cell.computedAmount = 0;
            cell.isForSimulation = isForSimulation;
            cell.secureYearValue = newContractNego.Secure_Multiyear__c;
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
            // set default value to make calculation of total conditions correct
            // TODO: remove then add all tariff conditions in map on load (idea)
            conditionDefinition.Index__c = 'Index1';
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
            if(listContractNego.get(i).Contract_Type__c == TYPE_SIMULATION && (listContractNego.get(i).Secure_Multiyear__c == '2 years' || listContractNego.get(i).Secure_Multiyear__c == '3 years')) {
                cell.isForSimulation = true;
                cell.secureYearValue = listContractNego.get(i).Secure_Multiyear__c;
            }
            
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
        matrice.calculateIndexes();
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
        Savepoint sp = Database.setSavepoint();
        try {
            ////delete listConditionToDel;
            ////listConditionToDel = new List<Contract_Discount__c> ();
            
            // Call computeAmount to recalculate indexes
            computeAmount();
            
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
            
            // insert sales condition exceptions if exist
            for(WrapperColumn item : matrice.columns) {
                if(item.salesConditionException != null && item.contract.Contract_Type__c != TYPE_CONTRACT) {
                    item.salesConditionException.Contract__c = item.contract.Id;
                    salesConditionExceptionList.add(item.salesConditionException);
                }
            }
            if(salesConditionExceptionList != null && salesConditionExceptionList.size() > 0)
                upsert salesConditionExceptionList;
            
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
                        ////cell.mapSlabsToCondition();
                    }
                    listConditionsToSave.add(cell.conditionWrapper.condition);
                }
            }
            if (!Contract_Discount__c.sObjectType.getDescribe().isDeletable()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Contract Discounts'));
                return null;
            }
            delete listConditionToDel;
            listConditionToDel = new List<Contract_Discount__c>();
            
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
            Database.rollback(sp);
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
    // Set the cell % based on target slab selection
    // @param key: line key (lineId)
    // @param ndx: cell index
    public void chooseSlabTarget(String key, Integer ndx) {
        for(Line item : matrice.linesTable) {
            if(item.lineId == key) {
                Cell currentCell = item.cells.get(ndx);
                currentCell.slabs.sort();
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
        ////public List<IndexHead> indexManagement {get;set;}
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
            ////indexManagement = new List<IndexHead>();
            Integer colIndex = 0;
            // prepare the index management list for each contract
            /***for (Integer i = 0; i < columns.size(); i++) {
                IndexHead ndxH = new IndexHead();
                indexManagement.add(ndxH);
            }***/
            // loop over contacts and calculate their indexes value
            for (Integer j = 0; j < columns.size(); j++) {
                WrapperColumn column = columns.get(j);
                column.indexes = new IndexHead();
                for (Line l : Lines) {
                    Cell c = l.Cells.get(j);
                    String indexType = c.conditionWrapper.condition.Index__c == null ? c.conditionWrapper.conditionDefinition.Index__c : c.conditionWrapper.condition.Index__c;
                    if(indexType == 'Index1')
                        column.indexes.listIndexes.get(0).value += c.computedAmount;
                    if(indexType == 'Index2')
                        column.indexes.listIndexes.get(1).value += c.computedAmount;
                    if(indexType == 'Index3')
                        column.indexes.listIndexes.get(2).value += c.computedAmount;
                    if(indexType == 'Index4')
                        column.indexes.listIndexes.get(3).value += c.computedAmount;
                }
                ////IndexHead currentContractIndexHead = indexManagement.get(j);
                for(IndexLine item : column.indexes.listIndexes) {
                    // Calculate the indexes %
                    if(column.contract.TO1__c != NULL && column.contract.TO1__c != 0) {
                        item.percentage = item.value / column.contract.TO1__c * 100;
                    }
                    // Set scale to 0
                    item.value = item.value.setScale(0, RoundingMode.HALF_UP);
                }

                // Calculate the indexes rate
                Decimal index0 = 100;
                index0 += column.contract.Rise_Rate__c != null ? column.contract.Rise_Rate__c : 0;
                index0 -= column.contract.Depreciation_Rate__c != null ? column.contract.Depreciation_Rate__c : 0;
                index0 += column.contract.Markdown_Rate_Break__c != null ? column.contract.Markdown_Rate_Break__c : 0;
                index0 += column.contract.Markdown_Rate_Promo__c != null ? column.contract.Markdown_Rate_Promo__c : 0;
                index0 += column.contract.Markdown_Rate_Theft__c != null ? column.contract.Markdown_Rate_Theft__c : 0;
                column.index0 = index0;
                Decimal previousRate = index0;

                for(IndexLine item : column.indexes.listIndexes) {
                    item.rate = previousRate - item.percentage;
                    previousRate = item.rate;
                }
            }
            // limit all decimal part to 2 digits
            for(WrapperColumn column : columns) {
                for (IndexLine nl : column.indexes.listIndexes) {
                    nl.percentage = nl.percentage.setScale(2, RoundingMode.HALF_UP);
                    nl.rate = nl.rate.setScale(2, RoundingMode.HALF_UP);
                }
                // set the indexes in contracts
                column.setContractIndexes();
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
        public Boolean enableAmount { get; set; }
        
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
            ////this.lineId = selectedCondDefId;

            // fields to be checked
            String[] condDefFields = new String[] {'Id', 'Name', NegoptimHelper.normalizeAPIName('Nego_Discount_Type__c'), NegoptimHelper.normalizeAPIName('Index__c'), NegoptimHelper.normalizeAPIName('Is_Conditional__c'), NegoptimHelper.normalizeAPIName('Condition_Mode__c')};
            if(NegoptimHelper.checkAccessibility(Pol_Com_Condition__c.SObjectType, condDefFields)) {
                List<Pol_Com_Condition__c> listCondDef = [SELECT Id, Name, Nego_Discount_Type__c, Index__c, Is_Conditional__c, Condition_Mode__c
                                                          FROM Pol_Com_Condition__c
                                                          WHERE Id = :selectedCondDefId];
                if (listCondDef.get(0).Nego_Discount_Type__c != type) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can\'t select a ' + listCondDef.get(0).Nego_Discount_Type__c + ' type for a ' + type + '.'));
                }
                else {
                    this.lineId = listCondDef.get(0).Name + '-' + lineId;
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
                        cell.conditionWrapper.conditionDefinition.Name = listCondDef.get(0).Name;
                        cell.isDisabled = false;
                        if(this.isConditional) {
                            ////**cell.mapConditionToSlabs(null);
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
        public boolean isForSimulation { get; set; }
        public String secureYearValue { get; set; }
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
            ////this.slabs = new List<Slab>();
        }
        public Cell(ConditionWrapper cw) {
            this.conditionWrapper = cw;
            this.key = cw.condition.Id != null ? (String) cw.condition.Id : 'COPY';
            ////this.slabs = new List<Slab>();
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
            Decimal totalTO = this.conditionWrapper.condition.Base_TO_Nego__c == null || this.conditionWrapper.condition.Base_TO_Nego__c == 0 ? this.conditionWrapper.contractNego.TO1__c : this.conditionWrapper.condition.Base_TO_Nego__c;
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
        
        // Rearrenge slabs in ASC or DESC order
        // @param orderDirection: can be null or ASC or DESC
        public void sortSlabs(String orderDirection) {
            SlabManager.sortSlab(conditionWrapper.condition, orderDirection == 'ASC');
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
                this.conditionDefinition = conditionDefinition.clone();//new Pol_Com_Condition__c();
                /*this.conditionDefinition.Id = conditionDefinition.Id;
                this.conditionDefinition.Name = conditionDefinition.Name;
                this.conditionDefinition.Condition_status__c = conditionDefinition.Condition_status__c;
                this.conditionDefinition.Nego_Discount_Type__c = conditionDefinition.Nego_Discount_Type__c;*/
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
    public Contract__c currentContract { get; set; }
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
        public Pol_Sale_Condition_Exception__c salesConditionException {get;set;}
        public IndexHead indexes {get;set;}
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
            this.indexes = new IndexHead();
        }
        public void setContractIndexes() {
            this.contract.Index1__c = this.indexes.listIndexes.get(0).rate;
            this.contract.Index1_perc__c = this.indexes.listIndexes.get(0).percentage;
            
            this.contract.Index2__c = this.indexes.listIndexes.get(1).rate;
            this.contract.Index2_perc__c = this.indexes.listIndexes.get(1).percentage;
            
            this.contract.Index3__c = this.indexes.listIndexes.get(2).rate;
            this.contract.Index3_perc__c = this.indexes.listIndexes.get(2).percentage;
            
            this.contract.Index4__c = this.indexes.listIndexes.get(3).rate;
            this.contract.Index4_perc__c = this.indexes.listIndexes.get(3).percentage;
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