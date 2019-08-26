public with sharing class Org_NegoScope_Edit_Controller extends NegoptimBaseController {
    
    public Sup_sup_NegoScope__c negoScope {get; set;}
    public Sup_sup_NegoScope__c negoScopeClone {get; set;}
    public Sup_Supplier__c supplier {get; set;}
    public Sup_Supplier__c supplierToBeUpdated {get; set;}
    public Set<Id> initialBrandSet = new Set<Id>();
    public Set<Id> initialPGSet = new Set<Id>();
    public List<BrandWrapper> brandDistributorList {get; set;}
    /*** @description List of PG in Memory*/
    public List<PGWrapper> listPGWrapper {get; set;}
    
    public Boolean editMode {get; set;}
    public Boolean cloneMode {
        get {
            String clone = ApexPages.currentPage().getParameters().get('clone');
            return clone == '1';
        }
        set;
    }
    public Boolean isContactShow {get; set;}
    
    public Id currentElementId {get; set;}
    public Id elementIdToSelect {get; set;}
    public Orga_HE__c rootElement;
    public Orga_HE__c currentElement {get; set;}
    public List<Orga_HE__c> childElements {get; set;}
    public List<ElementWrapper> childElementsWrapped {get; set;}
    public List<NegoScopeElemWrapper> wNegoScopeElementList {get; set;}
    private Map<Id, Supplier_NS_HE__c> initialNSHEMap;
    private List<Supplier_NS_HE__c> listNegoScopeElementToDelete = new List<Supplier_NS_HE__c>();
    
    ////private Boolean accessOrga = true;
    private Boolean exist = false;
    
    Transient List<PGWrapper> PGRecords;
    Set<Id> initialSelectedRecords;
    Set<Id> selectedRecords = new Set<Id>();
    Set<Id> unSelectedRecords = new Set<Id>();
    public Integer size {get; set;}
    public Integer noOfRecords {get; set;}
    public List<SelectOption> paginationSizeOptions {get; set;}
    public ApexPages.StandardSetController setCtrlr {
        get {
            if(setCtrlr == null) {
                setCtrlr = new ApexPages.StandardSetController(Database.getQueryLocator(query));
                setCtrlr.setPageSize(size);  
                noOfRecords = setCtrlr.getResultSize();
            }            
            return setCtrlr;
        }
        set;
    }
    // selection and filter
    private String query;
    public String sortFieldSave;

    // Constructor
    public Org_NegoScope_Edit_Controller(ApexPages.StandardController stdController) {
        negoScope = (Sup_sup_NegoScope__c)stdController.getRecord();
        editMode = stdController.getId() != null ? true : false;
        isContactShow = false;
        sortFieldSave = sortField;
        size = 10;
        paginationSizeOptions = new List<SelectOption>();
        paginationSizeOptions.add(new SelectOption('5','5'));
        paginationSizeOptions.add(new SelectOption('10','10'));
        paginationSizeOptions.add(new SelectOption('20','20'));
        paginationSizeOptions.add(new SelectOption('50','50'));
        paginationSizeOptions.add(new SelectOption('100','100'));
        try {
            rootElement = [SELECT Id, Name, Elt_Code__c, Level__c FROM Orga_HE__c WHERE Id = :NegoptimHelper.getRootId() LIMIT 1];
            currentElementId = rootElement.Id;
            // in case no permission on creation
            if(currentElementId == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No Parent Element found in object Orga_HE__c with Level = 0')); 
            }
            if(editMode) {
                // fields to be checked
                String[] negoScopeFields = new String [] {'Id', 'Name', 'OwnerId', getFieldName('Is_All_Brands__c'), getFieldName('Is_All_HE__c'), getFieldName('Is_All__c'), getFieldName('Supplier__c')};
                checkAccessibility(Sup_sup_NegoScope__c.SObjectType, negoScopeFields);
                // Is_All__c stand for all products
                negoScope = [SELECT Id, Name, OwnerId, NS_Code_Prefix__c, NS_Code__c, NS_Section_main__c, Comment__c,
                             Supplier__c ,Supplier__r.Name, Is_All_Brands__c, Incl_NewBrand__c, Is_All__c, Incl_NewProduct__c,
                             Is_All_HE__c, Status__c, Parent_Nego_Scope__c, Stock_Owner__c,
                             Accounting_Code__c, Acc_email__c, Acc_Raison__c, Acc_PostCode__c, Acc_Phone2__c, Acc_Phone1__c, Acc_Fax__c,
                             Acc_Country__c, Acc_Contact__c, Acc_City__c, Acc_Address_External_Synchro__c, Acc_Address2__c, Acc_Address1__c,
                             Admin_Raison__c, Admin_PostCode__c, Admin_Phone2__c, Admin_Phone1__c, Admin_Fax__c, Admin_Country__c,
                             Admin_Contact__c, Admin_City__c, Admin_Address_External_Synchro__c, Admin_Address2__c, Admin_Address1__c
                             FROM Sup_sup_NegoScope__c
                             WHERE Id = :negoScope.Id];
                if(cloneMode) {
                    // in clone mode . clone object , insert , redirect the page
                    negoScopeClone = negoScope.clone(false, true, true, false);
                    ////negoScope.Id = null;
                }
                // load initial brands relation and push Brand ids into set
                checkAccessibility(Sup_NS_Brand__c.SObjectType, new String[]{'Id', getFieldName('Sup_Scope_Brand__c')});
                for(Sup_NS_Brand__c item : [SELECT Id, Sup_Scope_Brand__c
                                            FROM Sup_NS_Brand__c
                                            WHERE Sup_sup_NegoScope__c = :negoScope.Id])
                {
                    initialBrandSet.add(item.Sup_Scope_Brand__c);
                }
                if(!negoScope.Is_All__c) {
                    getProductList();
                }
            } else {
                negoScope.Is_All_Brands__c = true;
                negoScope.Is_All_HE__c = true;
                negoScope.Is_All__c = true;
                negoScope.Admin_Address_External_Synchro__c = true;
                negoScope.Acc_Address_External_Synchro__c = true;
                wNegoScopeElementList = new List<NegoScopeElemWrapper>();
                addAllElement();
                // fields to be checked
                checkAccessibility(Sup_Supplier__c.SObjectType, new String[]{'Id', 'Name'}); 
                // create negoscope from supplier page
                if(negoScope.Supplier__c != null) {
                    loadSupplier();
                }
            }
            init();
            getBrandDistributorList();
            //throw new NSException('' + listBrandsSupplierWraper);
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception: ' + e.getMessage() + ' - ' + e.getLineNumber()));
        }
        // show saved message after redirect on nego scope creation 
        String showSuccess = ApexPages.currentPage().getParameters().get('success');
        if(showSuccess == 'true') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, Label.NegoScopeSaved));
        }
    }
    
    /**
     * Get NS_HE options
     * */
    public List<SelectOption> getChoiceOptions() {
        List<Schema.PicklistEntry> ples = Supplier_NS_HE__c.Choice__c.getDescribe().getPicklistValues();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', ''));
        for(Schema.PicklistEntry item : ples) {
            options.add(new SelectOption(item.getValue(), item.getLabel()));
        }
        return options;
    }
    /**
     * Load Supplier
     * */
    public void loadSupplier() {
        String[] supFields = new String [] {'Id', 'Name', getFieldName('Name'), getFieldName('Name'), getFieldName('Name')};
        checkAccessibility(Sup_Supplier__c.SObjectType, supFields);
        supplier = [SELECT Id, Name, Acc_Address1__c , Acc_Address2__c, Acc_City__c, Acc_Country__c,
                    Acc_email__c, Acc_Fax__c, Acc_Phone1__c, Acc_Phone2__c, Acc_PostCode__c, Acc_Raison__c,
                    Admin_Address1__c, Admin_Address2__c, Admin_City__c, Admin_Country__c,
                    Admin_Fax__c, Admin_Phone1__c, Admin_Phone2__c, Admin_PostCode__c, Admin_Raison__c 
                    FROM Sup_Supplier__c
                    WHERE Id = :negoScope.Supplier__c];
    }
    /**
     * Call it when create new NS and change the supplier field
     * */
    public PageReference onChangeSupplier() {
        reset();
        getBrandDistributorList();
        getProductList();
        return null;
    }
    /**
     * RESET All
     * */
    public void reset() {
        query = null;
        setCtrlr = null;
        selectedRecords.clear();
        unSelectedRecords.clear();
    }
    /**
     * Set addreses data from supplier to negoscope
     * */
    public pageReference setAddressFromSupplier() {
        loadSupplier();
        if(editMode == false) {
            // assign supplier fields value to negoscope ( contact section ) 
            setAdminAddressFromSupplier();
            setAccountAddressFromSupplier();
        }
        return null;
    }
    /**
     * Set Admin addreses data from supplier to negoscope
     * */
    public pageReference setAdminAddressFromSupplier() {
        if(negoScope.Admin_Address_External_Synchro__c == true) {
            negoScope.Admin_Address1__c = supplier.Admin_Address1__c;
            negoScope.Admin_Address2__c = supplier.Admin_Address2__c;
            negoScope.Admin_City__c = supplier.Admin_City__c;
            negoScope.Admin_Country__c = supplier.Admin_Country__c;
            negoScope.Admin_Fax__c = supplier.Admin_Fax__c;
            negoScope.Admin_Phone1__c = supplier.Admin_Phone1__c;
            negoScope.Admin_Phone2__c = supplier.Admin_Phone2__c;
            negoScope.Admin_PostCode__c = supplier.Admin_PostCode__c;
            negoScope.Admin_Raison__c = supplier.Admin_Raison__c;
        }
        return null;
    }
    /**
     * Set Account addreses data from supplier to negoscope
     * */
    public pageReference setAccountAddressFromSupplier() {
        if(negoScope.Acc_Address_External_Synchro__c == true) {
            negoScope.Acc_Address1__c = supplier.Acc_Address1__c;
            negoScope.Acc_Address2__c = supplier.Acc_Address2__c;
            negoScope.Acc_City__c = supplier.Acc_City__c;
            negoScope.Acc_Country__c = supplier.Acc_Country__c;
            negoScope.Acc_Phone1__c = supplier.Acc_Phone1__c;
            negoScope.Acc_Phone2__c = supplier.Acc_Phone2__c;
            negoScope.Acc_Fax__c = supplier.Acc_Fax__c;
            negoScope.Acc_PostCode__c = supplier.Acc_PostCode__c;
            negoScope.Acc_Raison__c = supplier.Acc_Raison__c;
        }
        return null;
    }
    /**
     * Get List Brands Supplier
     * */
    public PageReference getBrandDistributorList() {
        if(!checkAccessibility(Sup_Brand__c.SObjectType, new String[] {'Id', 'Name', getFieldName('Brand_Owner__c')})) {
            return null;
        }
        List<BrandWrapper> wBrandList = new List<BrandWrapper>();
        for(Sup_Bra_Distributor__c item : [SELECT Name, Brand__c, Brand__r.Name, Brand__r.Brand_Owner__r.Name, Supplier__r.Name
                                           FROM Sup_Bra_Distributor__c 
                                           WHERE Sup_Bra_Distributor__c.Supplier__c = :negoScope.Supplier__c
                                           ORDER BY Name ASC])
        {
            Boolean selected = initialBrandSet.contains(item.Brand__c);
            BrandWrapper wBrand = new BrandWrapper(item, selected);
            wBrandList.add(wBrand);
        }
        brandDistributorList = wBrandList;
        return null;
    }
    /**
     * Get List of product triggered when uncheck the checkbox 'All Product' 
     * */
    public PageReference getProductList() {
        // fields to be checked
        String [] listSupplierPGFields = new String [] {'Id', 'Name', getFieldName('Supplier__c')};
            if(!checkAccessibility(Supplier_PG_Mapping__c.SObjectType, listSupplierPGFields)) {
                return null;
            }
        /***listPGWrapper = new List<PGWrapper>();
        // Get All PG for the current supplier
        for(Supplier_PG_Mapping__c item : [SELECT Id, Name, Department__c, Section__c, Status__c, Brand__c,
                                           (SELECT Id FROM Supplier_Nego_Scope_PG__r WHERE Sup_sup_NegoScope__c = :negoScope.Id)
                                           FROM Supplier_PG_Mapping__c
                                           WHERE Supplier__c = :negoScope.Supplier__c
                                           ORDER BY Name ASC])
        {
            Boolean selected = item.Supplier_Nego_Scope_PG__r.size() > 0;
            PGWrapper pgWrapper = new PGWrapper(item, selected);
            listPGWrapper.add(pgWrapper);
        }***/
        return null;
    }
    /**
     * SAVE
     * */
    public PageReference saveNegoScope() {
        Boolean redirect = !editMode || cloneMode;
        // fields to be checked
        String[] negoScopeFieldsOnC = new String[] {'Name', getFieldName('Is_All_Brands__c'), getFieldName('Is_All_HE__c'), getFieldName('Is_All__c'), getFieldName('Supplier__c')};
        String[] negoScopeFieldsOnU = new String[] {'Name','OwnerId', getFieldName('Is_All_Brands__c'), getFieldName('Is_All_HE__c'), getFieldName('Is_All__c')};
        if(!checkCreatibility(Sup_sup_NegoScope__c.SObjectType, negoScopeFieldsOnC) || !checkUpdatibility(Sup_sup_NegoScope__c.SObjectType, negoScopeFieldsOnU)) {
            return null;
        }
        
        String mainSection;
        Boolean noElementIncluded = true;
        // check if one he is selected at least
        if(wNegoScopeElementList != null && wNegoScopeElementList.size() > 0) { //TODO: condition should be on wnegoScopeElementsToCreate
            for(Integer i = 0; i < wNegoScopeElementList.size(); i++) {
                if(wNegoScopeElementList.get(i).negoScopeElem.Choice__c == 'Include') {
                    mainSection = wNegoScopeElementList.get(i).elementName;
                    noElementIncluded = false;
                    break;
                }
            }
        }

        if(noElementIncluded && !negoScope.Is_All_HE__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, Label.At_least_one_included_structure_element_must_be_selected));
            return null;
        }
        
        // get first element included and add it to main section ns
        negoscope.NS_Section_main__c = negoScope.Is_All_HE__c ? rootElement.Name : mainSection;
        
        // check duplicate of nego scope name and supplier combination 
        Boolean checkDuplication = nfv.negoScopeCheckDuplication(negoScope.name,negoScope.Supplier__c,negoScope.Id);
        if(checkDuplication == false) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Duplicate NS found.'));
            return null;
        }
        
        if(!editMode) {
            // set addresses data from suppleir to negoscope
            // miht remove it if we add process builder  ( help creation of fields value when we have default nego creation )
            setAddressFromSupplier();
        }
        Savepoint sp = Database.setSavepoint();
        Id sourceNSId;
        if(cloneMode) {
            sourceNSId = negoScope.Id;
            negoScope.Id = null;
        }
        try {
            // check security on update supplier fields
            if(!checkUpdatibility(Sup_Supplier__c.SObjectType, new String[]{getFieldName('NS_Name_Autonum__c')})) {
                return null;
            }
            // NS name auto generated
            generateNSName(true);
            if(supplierToBeUpdated != null)
                update supplierToBeUpdated;
            upsert negoScope;
        } catch(DmlException e) {
            /*if (System.StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION != e.getDmlType(0))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Duplicate NS code value.'));*/
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Insert Nego_Scope Error:' + e.getMessage()));
            Database.rollback(sp);
            return null;
        }
        //throw new NSException('' + listBrandsSupplierWraper);
        
        /*** SAVE Supplier_NS_HE__c ***/
        // TODO: prevent deleting then insert for existing relations
        if(editMode) {
            if(listNegoScopeElementToDelete.size() > 0) {
                if (!Supplier_NS_HE__c.sObjectType.getDescribe().isDeletable()) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to delete Supplier_NS_HE__c'));
                    return null;
                }
                try {
                    if(checkDeletibility(Supplier_NS_HE__c.SObjectType)) {
                        delete listNegoScopeElementToDelete;
                    }
                    for(Supplier_NS_HE__c item : listNegoScopeElementToDelete) {
                        if (initialNSHEMap.containsKey(item.structure_element__c)) initialNSHEMap.remove(item.structure_element__c);
                    }
                    listNegoScopeElementToDelete.clear();
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Delete Nego Scope Element Error:' + e.getMessage()));
                    Database.rollback(sp);
                }
            }
        }
        List<Supplier_NS_HE__c> listNegoScopeElement = new List<Supplier_NS_HE__c>();
        Supplier_NS_HE__c negoScopeElement;
        if(negoScope.Is_All_HE__c != true) {
            for(NegoScopeElemWrapper item : wNegoScopeElementList) {
                if(cloneMode) { // cloning HE from the main negoscope
                    negoScopeElement = new Supplier_NS_HE__c(Structure_Element__c = item.negoScopeElem.Structure_Element__c,
                                                             Choice__c = item.negoScopeElem.Choice__c,
                                                             Sup_sup_NegoScope__c = negoScope.Id);
                } else {
                    negoScopeElement = new Supplier_NS_HE__c();
                    negoScopeElement = item.negoScopeElem;
                }
                
                if(editMode == false) {
                    negoScopeElement.Sup_sup_NegoScope__c = negoScope.Id;
                }
                
                negoScopeElement.Name = negoScope.NS_Code__c + '-' + item.elementCode;
                initialNSHEMap.put(negoScopeElement.Structure_Element__c, negoScopeElement);
                listNegoScopeElement.add(negoScopeElement);
            }
        }
        // fields to be checked
        String [] negoScopeElementFields = new String [] {'Name', getFieldName('Structure_Element__c'), getFieldName('Sup_sup_NegoScope__c'), getFieldName('Choice__c')};
            if(!checkCreatibility(Supplier_NS_HE__c.SObjectType, negoScopeElementFields)) {
                return null;
            }
        // fields to be checked
        String [] negoScopeElementFields2 = new String [] {'Name', getFieldName('Choice__c')};
            if(!checkUpdatibility(Supplier_NS_HE__c.SObjectType, negoScopeElementFields2)) {
                return null;
            } 
        
        try {
            upsert listNegoScopeElement;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Insert List Nego_Scope_Elements Error: ' + e.getMessage()));
            return null;
        }
        
        /*** SAVE Sup_NS_Brand__c ***/
        List<Sup_NS_Brand__c> listNegoScopeBrand = new List<Sup_NS_Brand__c>();
        Set<Id> brandRelationsToRemove = new Set<Id>();
        Sup_NS_Brand__c negoScopeBrand;
        if(cloneMode)
            initialBrandSet.clear();
        if(!negoScope.Is_All_Brands__c) {
            for(BrandWrapper brandWrapper : brandDistributorList) {
                Id brandId = brandWrapper.brand.Brand__c;
                if(brandWrapper.isSelected && !initialBrandSet.contains(brandId)) {
                    negoScopeBrand = new Sup_NS_Brand__c(Sup_Scope_Brand__c = brandId, Sup_sup_NegoScope__c = negoScope.Id);
                    listNegoScopeBrand.add(negoScopeBrand);
                    initialBrandSet.add(brandId);
                } else if(!brandWrapper.isSelected && initialBrandSet.contains(brandId)) {
                    brandRelationsToRemove.add(brandId);
                    initialBrandSet.remove(brandId);
                }
            }
        } else if (brandDistributorList != null) {
            for (BrandWrapper brandWrapper : brandDistributorList) {
                initialBrandSet.add(brandWrapper.brand.Brand__c);
                brandWrapper.isSelected = true;
            }
        }
        // fields to be checked
        if(checkCreatibility(Sup_NS_Brand__c.SObjectType, new String[]{getFieldName('Sup_sup_NegoScope__c'), getFieldName('Supplier__c'), getFieldName('Sup_Scope_Brand__c')})) {
            try {
                //@todo: move to trigger
                insert listNegoScopeBrand;
            } catch(Exception e) {                  
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Insert List Nego_Scope_Brands Error: ' + e.getMessage()));
                Database.rollback(sp);
                return null;
            }
        }
        if(checkAccessibility(Sup_NS_Brand__c.SObjectType, new String[]{'Id'}) && checkDeletibility(Sup_NS_Brand__c.SObjectType)) {
            try {
                // prevent delete Sup_NS_Brand__c when its cloned
                if(checkDeletibility(Sup_NS_Brand__c.SObjectType) && !cloneMode && !brandRelationsToRemove.isEmpty()) {
                    delete [SELECT Id FROM Sup_NS_Brand__c WHERE Sup_sup_NegoScope__c = :negoScope.Id AND Sup_Scope_Brand__c IN :brandRelationsToRemove];
                }
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Delete Exist Nego_Scope Brand Error:' + e.getMessage()));
                Database.rollback(sp);
                return null;
            }
        }
        
        /*** SAVE Sup_NS_PG__c ***/
        processSelection();
        List<Sup_NS_PG__c> listNegoScopePG = new List<Sup_NS_PG__c>();
        Set<Id> pgRelationsToRemove = new Set<Id>();
        if(cloneMode) {
            initialPGSet.clear();
            for(Sup_NS_PG__c item : [SELECT Sup_PG__c FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :sourceNSId]) {
                if(!unSelectedRecords.contains(item.Sup_PG__c)) {
                    selectedRecords.add(item.Sup_PG__c);
                }
            }
        }
        // Do the management of the relations with PGs when it is particular
        if(negoScope.Is_All__c && (!negoScope.Is_All_HE__c || !negoScope.Is_All_Brands__c)) {
            // create NS_PG relations based on HE and brand scope
            // filling initial set since it might be empty if the user never unchecked 'All products' in view
            filterPG();
        }
        // List to insert
        for(Id pgId : selectedRecords) {
            if(!initialPGSet.contains(pgId)) {
                listNegoScopePG.add(new Sup_NS_PG__c(Sup_PG__c = pgId, Sup_sup_NegoScope__c = negoScope.Id, Supplier__c = negoScope.Supplier__c));
                initialPGSet.add(pgId);
            }
        }
        // List to delete
        for(Id pgId : unSelectedRecords) {
            if(initialPGSet.contains(pgId)) {
                pgRelationsToRemove.add(pgId);
                initialPGSet.remove(pgId);
            }
        }
        
        if(negoScope.Is_All__c && negoScope.Is_All_HE__c && negoScope.Is_All_Brands__c) {
            // Already the management is done in the trigger
            listNegoScopePG.clear();
            pgRelationsToRemove.clear();
        }
        // fields to be checked
        if(listNegoScopePG.size() > 0 && checkCreatibility(Sup_NS_PG__c.SObjectType, new String[] {getFieldName('Sup_sup_NegoScope__c'), getFieldName('Supplier__c'), getFieldName('Sup_PG__c')})) {
            try {
                upsert listNegoScopePG;
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Insert List Nego_Scope_PGs Error: ' + e.getMessage()));
                return null;
            }
        }
        if(pgRelationsToRemove.size() > 0 && checkAccessibility(Sup_NS_PG__c.SObjectType, new String[]{'Id'}) && checkDeletibility(Sup_NS_PG__c.SObjectType)) {
            try {
                // prevent delete Sup_NS_PG__c when its cloned
                if(checkDeletibility(Sup_NS_PG__c.SObjectType) && !cloneMode) {
                    delete [SELECT Id FROM Sup_NS_PG__c WHERE Sup_sup_NegoScope__c = :negoScope.Id AND Sup_PG__c IN :pgRelationsToRemove];
                }
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Delete Exist Nego_Scope PG Error:' + e.getMessage()));
                return null;
            }
        }
        selectedRecords.clear();
        unSelectedRecords.clear();
        setCtrlr = null;
        // End
        if(redirect) {
            PageReference pr = Page.Org_NegoScope_Edit;
            pr.getParameters().put('id', negoScope.Id);
            pr.getParameters().put('success', 'true');
            pr.setRedirect(true);
            return pr;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, Label.NegoScopeSaved));
            return null;
        }
        
    }
    /**
     * NS name auto generated
     * */
    public PageReference refreshNsName() {
        generateNSName(false);
        return null;
    }
    /**
     * Generate NS Name With or Without Autonum
     * */
    public void generateNSName(Boolean withAutoNum) {
        if(negoScope.Name == null || negoScope.Name == '') {
            if(checkAccessibility(Sup_Supplier__c.SObjectType, new String[] {'Id', 'Name', getFieldName('NS_Name_Autonum__c')})) {
                Sup_Supplier__c supplier = [SELECT Id, Name, NS_Name_Autonum__c
                                            FROM Sup_Supplier__c
                                            WHERE id = :negoScope.Supplier__c];
                String selectedElement;
                if(negoScope.Is_All_HE__c == true) {
                    selectedElement = rootElement.Name;
                } else {
                    if(wNegoScopeElementList != null && wNegoScopeElementList.size() > 0) {
                        for(Integer i = 0 ; i < wNegoScopeElementList.size() ; i++) {
                            if(wNegoScopeElementList.get(i).negoScopeElem.Choice__c == 'Include') {    
                                selectedElement = wNegoScopeElementList.get(i).elementName;
                                break;
                            }
                        }
                    }
                }
                negoScope.Name = supplier.Name + ' - ';
                if(selectedElement != null)
                    negoScope.Name += selectedElement + ' - ';
                negoscope.NS_Section_main__c = selectedElement;
                if(withAutoNum) {
                    Integer autoNum = 1;
                    if(supplier.NS_Name_Autonum__c != null) {
                        autoNum = Integer.valueOf(supplier.NS_Name_Autonum__c);
                        autoNum++;
                    }
                    negoScope.Name += autoNum;
                    supplier.NS_Name_Autonum__c = autoNum;
                    supplierToBeUpdated = supplier;
                }
            }
        }
    }
    /**
     * INIT
     * */
    public PageReference init() {
        // fields to be checked
        String [] negoScopeElemsFields = new String [] {'Id', getFieldName('Structure_Element__c'), getFieldName('Choice__c')};
        if(!checkAccessibility(Supplier_NS_HE__c.SObjectType, negoScopeElemsFields)) {
            return null;
        }
        initialNSHEMap = new Map<Id, Supplier_NS_HE__c>();
        wNegoScopeElementList = new List<NegoScopeElemWrapper>();
        for(Supplier_NS_HE__c item : [SELECT Id, Choice__c, Structure_Element__c, Structure_Element__r.Name, Structure_Element__r.Elt_Code__c, Structure_Element__r.Level__c
                                      FROM Supplier_NS_HE__c
                                      WHERE Sup_sup_NegoScope__c = :negoScope.Id])
        {
            NegoScopeElemWrapper nsew = new NegoScopeElemWrapper(item, item.Structure_Element__r.Elt_Code__c, item.Structure_Element__r.Name,
                                                                 item.Structure_Element__r.Level__c);
            wNegoScopeElementList.add(nsew);
            initialNSHEMap.put(item.Structure_Element__c, item);
        }
        if(editMode == false && negoScope.Is_All_HE__c == false) {
            addAllElement();
        }
        return refresh();
    }
    /**
     * REFRESH
     * */
    public PageReference refresh() {
        Integer maxPrevisousParent = 4;
        // fields to be checked
        String[] currentElementFields = new String [] {'Id', 'Name', getFieldName('Elt_Code__c'), getFieldName('Parent_Element__c')};
        if(!checkAccessibility(Orga_HE__c.SObjectType, currentElementFields)) {
            return null;
        }
        
        String query = 'SELECT Id, Name, Level__c, Elt_Code__c, Parent_Element__c, Parent_Element__r.Name';
        String previousPrefixe = 'Parent_Element__r';
        for(Integer i = 0; i < maxPrevisousParent; i++) {
            query += ',' + previousPrefixe + '.Parent_Element__c';
            query += ',' + previousPrefixe + '.Parent_Element__r.Name';
            previousPrefixe += '.Parent_Element__r';
        }
        query += ', (SELECT Id, Name, Level__c, Elt_Code__c, Parent_Element__c, Parent_Element__r.Name';
        query += ' FROM Orga_Hierarchy_Elements__r ORDER BY Elt_Code__c)';
        query += ' FROM Orga_HE__c WHERE Id= \'' + currentElementId + '\'';
        currentElement = Database.query(query);

        childElementsWrapped = new List<ElementWrapper>();
        for(Orga_HE__c elem : currentElement.Orga_Hierarchy_Elements__r) {
            Supplier_NS_HE__c negoScopeElem = null;
            if(wNegoScopeElementList != null && wNegoScopeElementList.size() > 0) {
                for(NegoScopeElemWrapper nsew : wNegoScopeElementList) {
                    if(nsew.negoScopeElem.Structure_Element__c == elem.Id) {
                        negoScopeElem = nsew.negoScopeElem;
                    }
                }
            }
            
            if(negoScopeElem == null) {
                negoScopeElem = new Supplier_NS_HE__c(Structure_Element__c = elem.Id, Sup_sup_NegoScope__c = negoScope.Id);
            }
            
            ElementWrapper ew = new ElementWrapper(elem, negoScopeElem);
            // add HE element to  Structure element table 
            childElementsWrapped.add(ew); 
        }
        
        return null;
    }
    /**
     * Add root element in selected structure table
     * */
    public PageReference addAllElement() {
        String [] negoScopeElementFields = new String[] {'Name', getFieldName('Structure_Element__c'), getFieldName('Sup_sup_NegoScope__c'), getFieldName('Choice__c')};
        if(!checkCreatibility(Supplier_NS_HE__c.SObjectType, negoScopeElementFields)) {
            return null;
        }
        Supplier_NS_HE__c negoScopeElement = new Supplier_NS_HE__c(Name = rootElement.Name, Structure_Element__c = rootElement.Id, Choice__c = 'Include', Sup_sup_NegoScope__c = negoScope.Id);
        NegoScopeElemWrapper nsew = new NegoScopeElemWrapper(negoScopeElement, rootElement.Elt_Code__c, rootElement.Name, rootElement.Level__c);
        for(NegoScopeElemWrapper ngsew : wNegoScopeElementList) {
            if(ngsew.negoScopeElem.Structure_Element__c == rootElement.Id) {
                exist = true;
                break;
            }
        }
        if(!exist) {
            if(wNegoScopeElementList.size() > 0) {
                Integer lastIndex = wNegoScopeElementList.size()-1;
                wNegoScopeElementList.add(lastIndex, nsew);
            } else {
                wNegoScopeElementList.add(nsew);
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Error_MustSelectNegoScope));
        }
        return null;
    }
    /**
     * Select Element
     * */
    public PageReference selectElement() {
        if(elementIdToSelect == null) {
            return null;
        }
        
        boolean elementExist = false;
        for(ElementWrapper ew : childElementsWrapped) {
            if(ew.element.Id == elementIdToSelect) {
                if(ew.negoScopeElem.Choice__c != null && ew.negoScopeElem.Choice__c != '') {
                    for(Integer i = 0; i < wNegoScopeElementList.size(); i++) {
                        if(wNegoScopeElementList.get(i).negoScopeElem.Structure_Element__c == elementIdToSelect) {
                            wNegoScopeElementList.get(i).negoScopeElem.Choice__c = ew.negoScopeElem.Choice__c;
                            elementExist = true;
                            return null;
                        }
                    }
                    if( !initialNSHEMap.keySet().contains(elementIdToSelect)) {
                        NegoScopeElemWrapper nsew = new NegoScopeElemWrapper(ew.negoScopeElem, ew.element.Elt_Code__c, ew.element.Name, ew.element.Level__c);
                        wNegoScopeElementList.add(nsew);
                        break;
                    }
                    Supplier_NS_HE__c element = initialNSHEMap.get(elementIdToSelect);
                    element.Choice__c = ew.negoScopeElem.Choice__c;
                    
                    //for (integer index = 0; index < listNegoScopeElementToDelete.size(); index++) {
                    for (Supplier_NS_HE__c itemToDelete : listNegoScopeElementToDelete) {
                        if (itemToDelete.Structure_Element__c == elementIdToSelect) {
                            if (initialNSHEMap.keySet().contains(elementIdToSelect) && !elementExist ) {
                                NegoScopeElemWrapper nsew = new NegoScopeElemWrapper(element, ew.element.Elt_Code__c, ew.element.Name, ew.element.Level__c);
                                wNegoScopeElementList.add(nsew);
                                listNegoScopeElementToDelete.remove(listNegoScopeElementToDelete.IndexOf(itemToDelete));
                                break;
                            }
                        }
                    }
                    
                } else {
                    unselectElement();
                }
                break;
            }
        }     
        return null;
    }
    /**
     * UnSelect Element
     * */
    public PageReference unselectElement() {
        if (initialNSHEMap.containsKey(elementIdToSelect)) {
            listNegoScopeElementToDelete.add(initialNSHEMap.get(elementIdToSelect));
        }
        
        for(Integer i = 0; i < wNegoScopeElementList.size(); i++) {
            if(wNegoScopeElementList.get(i).negoScopeElem.Structure_Element__c == elementIdToSelect) {
                wNegoScopeElementList.remove(i);
            }
        }
        refresh();
        return null;
    }
    
    public List<PGWrapper> getRecords() {
        if(query == null) {
            buildQuery();
        }
        PGRecords = new List<PGWrapper>();
        Boolean firstLoad = selectedRecords.size() == 0 && unSelectedRecords.size() == 0;
        for(Supplier_PG_Mapping__c item : (List<Supplier_PG_Mapping__c>) setCtrlr.getRecords()) {
            Boolean selected = (item.Supplier_Nego_Scope_PG__r.size() > 0 && firstLoad) ||
                (item.Supplier_Nego_Scope_PG__r.size() > 0 && !selectedRecords.contains(item.Id) && !unSelectedRecords.contains(item.Id)) ||
                (!firstLoad && selectedRecords.contains(item.Id) && !unSelectedRecords.contains(item.Id));
            if(item.Supplier_Nego_Scope_PG__r.size() > 0)
                initialPGSet.add(item.Id);
            if (selected) {
                selectedRecords.add(item.Id);
            } else {
                unSelectedRecords.add(item.Id);
            }
            PGWrapper wRecord = new PGWrapper(item, selected);
            PGRecords.add(wRecord);
        }
        noOfRecords = setCtrlr.getResultSize();
        return PGRecords;
    }
    // organize selected and unselected rows
    public void processSelection() {
        if (PGRecords != null) {
            for (PGWrapper item : PGRecords) {
                if (item.selected) {
                    selectedRecords.add(item.pg.Id);
                    unSelectedRecords.remove(item.pg.Id);
                } else {
                    selectedRecords.remove(item.pg.Id);
                    unSelectedRecords.add(item.pg.Id);
                }
            }
        }
    }
    // returns the first page of records
    public void first() {
        processSelection();
        setCtrlr.first();
    }
    // returns the last page of records
    public void last() {
        processSelection();
        setCtrlr.last();
    }
    // returns the previous page of records
    public void previous() {
        processSelection();
        setCtrlr.previous();
    }
    // returns the next page of records
    public void next() {
        processSelection();
        setCtrlr.next();
    }
    // Changes the size of pagination
    public PageReference refreshPageSize() {
        processSelection();
        setCtrlr.setPageSize(size);
        return null;
    }
    // Build query command for list selection change
    public void buildQuery() {
        setCtrlr = null;
        String queryWhere = '';
        query = 'SELECT Id, Name, Brand__c, Department__c, Section__c, Status__c';
        if(negoScope.Id != null) {
            query += ' ,(SELECT Id FROM Supplier_Nego_Scope_PG__r WHERE Sup_sup_NegoScope__c = \'' + negoScope.Id + '\')';
        }
        query += ' FROM Supplier_PG_Mapping__c';
        if(negoScope.Supplier__c != null) {
            query += ' WHERE Supplier__c = \'' + negoScope.Supplier__c + '\'';
        }
        query += queryWhere;
        query += ' ORDER BY ' + String.escapeSingleQuotes(sortField) + ' ' + String.escapeSingleQuotes(sortDirection) + ' LIMIT 10000';
    }
    // Build soql string for where criteria 
    public String buildWhere(String q, String condition) {
        if (q == '') {
            return ' WHERE ' + condition;
        } else {
            return q + ' AND ' + condition;
        }
    }
    // Toggles the sorting of query from asc<-->desc
    public void sortToggle() {
        sortDirection = sortDirection.equals('asc') ? 'desc NULLS LAST' : 'asc';
        // reset alpha filter and sort sequence when sorted field is changed
        if (sortFieldSave != sortField) {
            sortDirection = 'asc';
            sortFieldSave = sortField;
        }
        processSelection();
        // run the query again
        buildQuery();
    }
   /**
	* @description Return sort direction. Default ascending(asc)
    * */
    public String sortDirection {
        get {
            if (sortDirection == null) {
                sortDirection = 'asc';
            }
            return sortDirection;
        }
        set;
    }
    /**
     * @Description Return sort by field. Default set to Name
     * */
    public String sortField {
        get {
            if (sortField == null) {
                sortField = 'Name';
            }
            return sortField;
        }
        set; 
    }
    /**     
     * @description filters Supplier PG Mappings based on selected HE and Supplier Brands
     * */
    public void filterPG() {
        Set<Id> filteredPGs = new Set<Id>();
        
        Set<Id> selectedBrands = new Set<Id>();
        Set<Id> includedSections = new Set<Id>();
        Set<Id> excludedSections = new Set<Id>();
        Set<Id> includedDepartments = new Set<Id>();
        Set<Id> excludedDepartments = new Set<Id>();
        
        // To select PGs with no brand
        if(!negoscope.Is_All_Brands__c) selectedBrands.add(null);
        if(brandDistributorList != null) {
            for (BrandWrapper wbrand : brandDistributorList) {
                if (wbrand.isSelected) {
                    selectedBrands.add(wbrand.brand.Brand__c);
                }
            }
        }
        if (wNegoScopeElementList != null) {
            for (NegoScopeElemWrapper wElement : wNegoScopeElementList) {
                if (wElement.elementLevel == 1) {
                    if (wElement.negoScopeElem.Choice__c.equals('Include')) {
                        includedDepartments.add(wElement.negoScopeElem.Structure_Element__c);
                    } else {
                        excludedDepartments.add(wElement.negoScopeElem.Structure_Element__c);
                    }
                } else if (wElement.elementLevel == 2) {
                    if (wElement.negoScopeElem.Choice__c.equals('Include')) {
                        includedSections.add(wElement.negoScopeElem.Structure_Element__c);
                    } else {
                        excludedSections.add(wElement.negoScopeElem.Structure_Element__c);
                    }
                }
            }
        }
        
        List<String> whereStatement = new List<String>();
        whereStatement.add(' Supplier__c = \'' + negoscope.Supplier__c + '\'');
        if(!selectedBrands.isEmpty() && !negoscope.Is_All_Brands__c) whereStatement.add(' Brand__c IN :selectedBrands ');
        if(!includedDepartments.isEmpty()) whereStatement.add(' Department__c IN :includedDepartments ');
        if(!excludedDepartments.isEmpty()) whereStatement.add(' Department__c NOT IN :excludedDepartments ');
        if(!includedSections.isEmpty()) whereStatement.add(' Section__c IN :includedSections ');
        if(!excludedSections.isEmpty()) whereStatement.add(' Section__c NOT IN :excludedSections ');
        
        String selectQuery = 'SELECT Id FROM Supplier_PG_Mapping__c ';
        selectQuery += 'WHERE ' + String.join(whereStatement, 'AND');
        for (Supplier_PG_Mapping__c item : database.query(selectQuery)) {
            filteredPGs.add(item.Id);
        }
        // represents highlighted records in view
        initialPGSet.clear();
        for (Sup_NS_PG__c item : [SELECT Sup_PG__c, Sup_PG__r.Name FROM Sup_NS_PG__c WHERE Sup_Sup_Negoscope__c = :negoScope.Id]) {
            initialPGSet.add(item.Sup_PG__c);
        }
        selectedRecords.clear();
        unSelectedRecords.clear();
        
        for (Id pgId : filteredPGs) {
            selectedRecords.add(pgId);
        }
        
        for (Id pgId : initialPGSet) {
            if (!filteredPGs.contains(pgId)){
                unSelectedRecords.add(pgId);
            }
        }
    }
    
    //
    //
    // Class ElementWrapper
    public class ElementWrapper {
        public Orga_HE__c element {get; set;}
        public Supplier_NS_HE__c negoScopeElem {get; set;}
        
        public ElementWrapper(Orga_HE__c element, Supplier_NS_HE__c negoScopeElement) {
            this.element = element;
            this.negoScopeElem = negoScopeElement;
        }
    }
    //
    //
    // Class NegoScopeElemWrapper
    public class NegoScopeElemWrapper {
        public Supplier_NS_HE__c negoScopeElem {get; set;}
        public String elementCode {get; set;}
        public String elementName {get; set;}
        public Decimal elementLevel {get; set;}
        
        
        public NegoScopeElemWrapper(Supplier_NS_HE__c nse, String elemCode, String elemName,Decimal elemLevel) {
            this.negoScopeElem = nse;
            this.elementCode = elemCode;
            this.elementName = elemName;
            this.elementLevel = elemLevel;
        }
    }
    //
    //
    // Class BrandWrapper
    public class BrandWrapper {
        public Sup_Bra_Distributor__c brand {get; set;}
        public Boolean isSelected {get; set;}
        
        public BrandWrapper(Sup_Bra_Distributor__c brand, Boolean isSelected) {
            this.brand = brand;
            this.isSelected = isSelected;
        }
    }
    //
    //
    // Class PGWrapper
    public class PGWrapper {
        public Supplier_PG_Mapping__c pg {get; set;}
        public Boolean selected {get; set;}
        public String codeColor {
            get {
                String code = '';
                if (selected)
                    code = '#b6e32e';
                return code;
            }
            set;
        }
        public PGWrapper(Supplier_PG_Mapping__c p, Boolean sel) {
            pg = p;
            selected = sel;
        }
    }
    public class NSException extends Exception {}
}