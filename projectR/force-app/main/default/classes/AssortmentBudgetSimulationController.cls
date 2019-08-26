/**
* @author ULiT
* @date 01/02/2019
* @description AssortmentBudgetSimulationController
* */
public with sharing class AssortmentBudgetSimulationController extends NegoptimBaseController {
    
    private Assortment_BU__c instance; // assortment budget en cours
    private Integer extId;
    private Map<String, Id> recordTypes = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_BU__c.sObjectType);
    private Map<String, Schema.SObjectField> assortmentDetailsFieldsMap = Schema.SObjectType.Assortment_Detail__c.fields.getMap();
    private List<Assortment_Detail__c> cumulDetailsToUpsert = new List<Assortment_Detail__c>();
    private Boolean openPage {get; set;}
    private List<String> productFields;
    //
    private Map<Id, Assortment_BU__c> negoAssortmentsMap;
    private Map<Id, Assortment_Detail__c> budgetDetailsMap = new Map<Id, Assortment_Detail__c>();
    private Set<Id> introProductsInAssortmentIdSet = new Set<Id>();
    //
    public List<CategoryWrapper> data {get; set;}
    public List<Orga_BU__c> clientCircuitList {get; set;}
    public String categoriesIdSet_serialized {get; set;}
    public String CategoryTree_serialized {get; set;}
    public String fieldNames_serialized {get; set;}
    public String treeFields_serialized {get; set;}
    public String instanceLongName {get; set;}
    public String fieldsScaleMap_serialized {get; set;}
    // filters
    public String searchTerm {get; set;}
    public Boolean introProducts {get; set;}
    public Boolean histoProducts {get; set;}
    public List<SelectOption> buFormats {get; set;}
    public String selectedBUFormats {get; set;}
    // dynamic columns
    public GridSettingsManager gridSettingsManager {get; set;}
    public Boolean readOnlyUser {get; set;} // indicates if user is allowed to edit page
    public Boolean initialSave {get; set;}
    
    // pagination variables
    public ObjectIterable productsObjectIterable {get; set;}
    private List<Id> pageResults = new List<Id>();
    public Integer noOfRecords {get; set;}
    public Integer pageSize {get; set;}
    public List<SelectOption> pageSizeOptions {get; set;}
    
    public List<String> fieldNames {get; private set;}
    
    public String subTotalsMap_serialized {get; set;}
    
    public AssortmentBudgetSimulationController (ApexPages.StandardController stdCtrl) {
        // load NegoptimSettings
        NegoptimSettings settings =  GlobalSettingsManager.loadGlobalSettings();
        // setup gridSettingsManager
        String staticFields = 'Name,Category__c,Category__r.Name,Category__r.Long_Name__c,Product_EAN__c,ProductCode2__c,IsInnovation__c,recordType.developerName,Market_End_of_Life_Date__c';
        String metadataDeveloperName = settings.assortmentBudgetSimulatorGridLayout;
        gridSettingsManager = new GridSettingsManager('Product2', staticFields, metadataDeveloperName);
        productFields = new List<String>();
        for (String fieldName : gridSettingsManager.ALL_FIELDS) {
            productFields.add('Product__r.' + fieldName);
        }
        // check user profile against custom settings
        List<String> budgetProfiles = settings.assortmentBudgetSimulatorProfile;
        String userProfile = UserInfo.getProfileId();
        this.readOnlyUser = budgetProfiles == null || budgetProfiles.isEmpty() || !budgetProfiles.contains(userProfile);
        // add needed fields to standard controller
        List<String> fields = new List<String> {'Assortment_type__c', 'BU_source__c', 'BU_source__r.BU_Code__c', 'BU_Target__c',
            'BU_Target__r.Format_Origin__c', 'Orga_HE__r.Path__c', 'Year__c', 'Long_Name__c'};
        if (!System.Test.isRunningTest()) {
            stdCtrl.addFields(fields);
        }
        this.instance = (Assortment_BU__c) stdCtrl.getRecord();
        if (String.isBlank(this.instance.Id)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Assortment'));
        } else {
            this.instanceLongName = this.instance.Long_Name__c;
            // pagination fields
            this.pageSize = 25;
            this.noOfRecords = 0;
            this.pageSizeOptions = new List<SelectOption>();
            this.pageSizeOptions.add(new SelectOption('25', '25'));
            this.pageSizeOptions.add(new SelectOption('50', '50'));
            this.pageSizeOptions.add(new SelectOption('75', '75'));
            this.pageSizeOptions.add(new SelectOption('100', '100'));
            //fields
            List<String> assortmentDetailFields = new List<String>();
            assortmentDetailFields.add('Fact_WD_MarketBased_Pts__c');
            assortmentDetailFields.add('New_Client_WD_MarketBased_Pts__c');
            assortmentDetailFields.add('L4L_Client_WD_Marketbased_Pts__c');
            assortmentDetailFields.add('Ref_Client_WD_MarketBased_Nego_Pts__c');
            Map<String, Integer> fieldsScaleMap = new Map<String, Integer>();
            for (String fieldName : assortmentDetailFields) {
                fieldsScaleMap.put(fieldName, (Integer) assortmentDetailsFieldsMap.get(fieldName.toLowerCase()).getDescribe().scale);
            }
            this.fieldsScaleMap_serialized = JSON.serialize(fieldsScaleMap);
            //filtres
            this.introProducts = true;
            this.histoProducts = true;
            this.buFormats = new List<SelectOption>();
            Schema.DescribeFieldResult fieldResult = Orga_BU__c.Format_Origin__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            Map<String, String> pickListValuesMap = new Map<String, String>();
            for (Schema.PicklistEntry pickListVal : ple) {
                pickListValuesMap.put(pickListVal.value, pickListVal.label);
            }
            List<String> availableBUFormats = new List<String>();
            if (String.isNotBlank(this.instance.BU_Target__r.Format_Origin__c)) {
                availableBUFormats = this.instance.BU_Target__r.Format_Origin__c.split(';');
            }
            for (String availableBUFormat : availableBUFormats) {
                this.buFormats.add(new SelectOption(availableBUFormat, pickListValuesMap.get(availableBUFormat)));
            }
            if (buFormats.size() > 1) {
                this.buFormats.add(new SelectOption(Label.LBL_All, Label.LBL_All));
            }
            this.fieldNames = new List<String>();
            this.fieldNames.add('Nego-Fact_WD_MarketBased_Pts__c');
            this.fieldNames.add('Nego-New_Client_WD_MarketBased_Pts__c');
            this.fieldNames.add('Nego-L4L_Client_WD_Marketbased_Pts__c');
            this.fieldNames.add('Budget-New_Client_WD_MarketBased_Pts__c');
            this.fieldNames.add('Target-New_Client_WD_MarketBased_Pts__c');
            this.fieldNames_serialized = JSON.serialize(this.fieldNames);
            
            try {
                extId = Integer.valueOf([SELECT AutoNum__c FROM Assortment_BU__c WHERE AutoNum__c <> NULL ORDER BY AutoNum__c DESC LIMIT 1].AutoNum__c);
                extId = extId == null ? 0 : extId + 1;
                System.debug('max autoNum >>' + extId);
            } catch (QueryException ex) {
                System.debug('Exception >> ' + ex.getStackTraceString());
                extId = 0;
            }
            this.clientCircuitList = new List<Orga_BU__c>();
            this.search();
            this.calculateSubTotals();
            
            Integer budgetDetailsCount = Database.countQuery('SELECT Count() FROM Assortment_Detail__c WHERE Assortment_BU__c = \'' + this.instance.Id + '\'');
            this.initialSave = budgetDetailsCount == noOfRecords;
            
            // fancy tree
            Id budgetHEId = String.isBlank(this.instance.Orga_HE__c) ? NegoptimHelper.getRootId() : this.instance.Orga_HE__c;
            HierarchyElementTree het = new HierarchyElementTree(new Set<Id> {budgetHEId});
            
            Map<Id, CategoryTreeWrapper> categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
            Map<Id, CategoryTreeWrapper> hierarchyTree = new Map<Id, CategoryTreeWrapper>();
            Map<Id, Orga_HE__c> parentCategories = new Map<Id, Orga_HE__c>();
            Set<Id> relatedCategoryIds = new Set<Id>();
            Map<Id, Id> parentChildMap = new Map<Id, Id>();
            List<String> treeFields = new list<String>();
            
            // add Ref_Client_WD_MarketBased_Nego_Pts__c to Budget totals in tree
            ////treeFields.add(this.instance.BU_Target__c + '-Nego-Ref_Client_WD_MarketBased_Nego_Pts__c');
            /*for (String field : this.fieldNames) {
                treeFields.add(this.instance.BU_Target__c + '-' + field);
            }*/
            treeFields.add(this.instance.BU_Target__c + '-Nego-Fact_WD_MarketBased_Pts__c');
            treeFields.add(this.instance.BU_Target__c + '-Nego-New_Client_WD_MarketBased_Pts__c');
            treeFields.add(this.instance.BU_Target__c + '-Nego-L4L_Client_WD_Marketbased_Pts__c');
            treeFields.add(this.instance.BU_Target__c + '-Nego-Ref_Client_WD_MarketBased_Nego_Pts__c');
            treeFields.add(this.instance.BU_Target__c + '-Budget-New_Client_WD_MarketBased_Pts__c');
            treeFields.add(this.instance.BU_Target__c + '-Target-New_Client_WD_MarketBased_Pts__c');
            // add Gap to budget totals in tree
            treeFields.add(this.instance.BU_Target__c + '-gap');
            
            for (Orga_BU__c bu : clientCircuitList) {
                for (String field : this.fieldNames) {
                    treeFields.add(bu.Id + '-' + field);
                }
            }
            
            this.treeFields_serialized = JSON.serialize(treeFields);
            // navigate inversely from top level
            Integer rootLevel = (Integer) het.allElementsList[het.allElementsList.size() - 1].Level__c;
            for (Integer i = het.allElementsList.size() - 1; i >= 0; i--) {
                Orga_HE__c item = het.allElementsList.get(i);
                CategoryTreeWrapper node = new CategoryTreeWrapper(treeFields);
                CategoryTreeWrapper parentNode = hierarchyTree.get(item.Parent_Element__c);
                node.title = item.Long_Name__c;
                node.key = item.Id;
                node.folder = item.Level__c <= rootLevel + 1;
                if (parentNode != null) {
                    node.path = parentNode.path + '' + item.Id;
                    node.parentId = item.Parent_Element__c;
                } else {
                    node.path = item.Id;
                    categoryTreeMap.put(item.Id, node);
                }
                hierarchyTree.put(item.Id, node);
            }
            for (Orga_HE__c item : het.allElementsList) {
                if (hierarchyTree.containsKey(item.Parent_Element__c)) {
                    hierarchyTree.get(item.Parent_Element__c).children.add(hierarchyTree.get(item.Id));
                }
            }
            this.CategoryTree_serialized = JSON.serialize(categoryTreeMap.values());
        }
    }
    
    /**
     * @description
     * executes 2 aggregation queries: the first fetchs the Ids of products in Nego and Conso Assortments in the previous year
     * and the second fetches the Ids of new Products introduced in the budget year
     * the methods adds both sets of Ids to an Itarable and excludes any Introduced product that is already included in a Nego or Conso Assortment
     * in the previous year
     * 
	*/
    public void search() {
        List<String> assortmentsConditions = new List<String>();
        assortmentsConditions.add('BU_Source__c = \'' + this.instance.BU_Target__c + '\'');
        assortmentsConditions.add('Orga_HE__c = \'' + this.instance.Orga_HE__c + '\'');
        assortmentsConditions.add('Assortment_type__c = \'Out\'');
        assortmentsConditions.add('Status__c = \'Validated\'');
        assortmentsConditions.add('Year__c = ' + (this.instance.Year__c - 1));
        assortmentsConditions.add('BU_Target__r.Layer_Budget_Display__c = TRUE');
        assortmentsConditions.add('recordType.DeveloperName IN (\'Nego\', \'Conso\')');
        if (String.isNotBlank(this.selectedBUFormats)) {
            List<String> selectedBUFormatsList = this.selectedBUFormats.split(',');
            assortmentsConditions.add('BU_Target__r.Format_Origin__c INCLUDES (\'' + String.escapeSingleQuotes(String.join(selectedBUFormatsList, '\',\'')) + '\')');
        }
        
        String negoAssortmentsQuery = 'SELECT Id, BU_Target__c, BU_Target__r.Name,';
        negoAssortmentsQuery += ' BU_Target__r.Weighted_Distribution_Manual__c, BU_Target__r.Weighted_Distribution_Manual_N1__c';
        negoAssortmentsQuery += ' FROM Assortment_BU__c';
        negoAssortmentsQuery += ' WHERE ' + String.join(assortmentsConditions, ' AND ');
        negoAssortmentsQuery += ' ORDER BY BU_Target__r.Name ASC';
        System.debug('search >> negoAssortmentsQuery >> ' + negoAssortmentsQuery);
        List<Assortment_BU__c> negoAssortmentsList = Database.query(negoAssortmentsQuery);
        this.negoAssortmentsMap = new Map<Id, Assortment_BU__c>(negoAssortmentsList);
        this.clientCircuitList.clear();
        for (Assortment_BU__c item : negoAssortmentsList) {
            if (!this.clientCircuitList.contains(item.BU_Target__r)) {
                this.clientCircuitList.add(item.BU_Target__r);
            }
        }
        
        List<Id> productsIdList = new List<Id>();
        if (histoProducts) {
            String query = 'SELECT Product__c productId FROM Assortment_Detail__c';
            query += ' WHERE ' + String.join(this.getHistoConditions(), ' AND ');
            if (String.isNotBlank(this.searchTerm)) {
                query += ' AND (Product__r.Name LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                query += ' OR Product__r.Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                query += ' OR Product__r.ProductCode LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                query += ' OR Product__r.Category__r.Name LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                query += ' OR Product__r.Category__r.Long_Name__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                query += ' OR Product__r.Category__r.Elt_Code__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\')';
            }
            query += ' GROUP BY Product__c, Product__r.Name, Category__r.Name, Category__r.Path__c';
            query += ' ORDER BY Category__r.Path__c ASC, Product__r.Name ASC';
            System.debug('search >> query >> ' + query);
            List<AggregateResult> aggregateResults = Database.query(query);
            for (AggregateResult result : aggregateResults) {
                productsIdList.add(Id.valueOf(String.valueOf(result.get('productId'))));
            }
            System.debug('aggregateResults.size >>>> ' + aggregateResults);
        }
        if (introProducts) {
            String introducedProductsQuery = 'SELECT Id FROM Product2';
            introducedProductsQuery += ' WHERE isActive = TRUE AND CALENDAR_YEAR(Market_Introduction_Date__c) = ' + this.instance.Year__c;
            if (this.instance.Orga_HE__c != null && this.instance.Orga_HE__r.Path__c != null) {
                introducedProductsQuery += ' AND Category__r.Path__c LIKE \'' +  String.escapeSingleQuotes(this.instance.Orga_HE__r.Path__c) + '%\'';
            }
            if (String.isNotBlank(this.searchTerm)) {
                introducedProductsQuery += ' AND (Name LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                introducedProductsQuery += ' OR Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                introducedProductsQuery += ' OR ProductCode LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                introducedProductsQuery += ' OR Category__r.Name LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                introducedProductsQuery += ' OR Category__r.Long_Name__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
                introducedProductsQuery += ' OR Category__r.Elt_Code__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\')';
            }
            System.debug('search >> introducedProductsQuery >> ' + introducedProductsQuery);
            List<Product2> introducedProductsList = Database.query(introducedProductsQuery);
            for (Product2 product : introducedProductsList) {
                if(!productsIdList.contains(product.Id)) {
                    productsIdList.add(product.Id);
                } else {
                    this.introProductsInAssortmentIdSet.add(product.Id);
                }
            }
        }
        this.productsObjectIterable = new ObjectIterable(productsIdList);
        if (productsIdList.size() > this.pageSize) {
            this.productsObjectIterable.setPageSize = this.pageSize;
        } else {
            this.productsObjectIterable.setPageSize = productsIdList.size();
        }
        this.noOfRecords = productsIdList.size();
        this.setPageResults(this.productsObjectIterable.next());
        this.setupData();
    }
    
    private void setupData() {
        try {
            Map<Id, ProductWrapper> histoProductsMap = new Map<Id, ProductWrapper>();
            List<Assortment_Detail__c> negoAssortmentDetailList = new List<Assortment_Detail__c>();
            Map<Id, Assortment_Detail__c> cumulDetailsMap_by_product = new Map<Id, Assortment_Detail__c>();
            
            String assortmentDetailQuery = this.buildQuery();
            System.debug('assortmentDetailQuery >> ' + assortmentDetailQuery);
            /*Map<Id, Assortment_BU__c> targetAssortmentMap = new Map<Id, Assortment_BU__c>();*/
            Map<String, Assortment_Detail__c> targetAssortmentDetailMap = new Map<String, Assortment_Detail__c>();
            
            List<Assortment_Detail__c> allAssortmentDetailsList = database.query(assortmentDetailQuery);
            for (Assortment_Detail__c detail : allAssortmentDetailsList) {
                if (detail.Assortment_BU__c == this.instance.Id) {
                    cumulDetailsMap_by_product.put(detail.Product__c, detail);
                } else if (detail.Assortment_BU__r.RecordType.DeveloperName.equals('Target')) {
                    /*if (!targetAssortmentMap.containsKey(detail.Assortment_BU__c)) {
                        targetAssortmentMap.put(detail.Assortment_BU__r.BU_Target__c, detail.Assortment_BU__r);
                    }*/
                    targetAssortmentDetailMap.put('' + detail.Assortment_BU__r.BU_Target__c + detail.Product__c, detail);
                } else {
                    negoAssortmentDetailList.add(detail);
                }
            }
            /*// Build the Map of BU with categories with clusters
            for (Assortment_Detail__c detail : negoAssortmentDetailList) {
                if (!targetAssortmentMap.containsKey(detail.Assortment_BU__r.BU_Target__c)) {
                    Assortment_BU__c validAssortment = new Assortment_BU__c();
                    validAssortment.Name = 'Target - ' + detail.Assortment_BU__r.BU_Target__r.Name + ' - ' + this.instance.Year__c;
                    validAssortment.BU_Source__c = detail.Assortment_BU__r.BU_Source__c;
                    validAssortment.BU_Target__c = detail.Assortment_BU__r.BU_Target__c;
                    validAssortment.Orga_HE__c = detail.Assortment_BU__r.Orga_HE__c;
                    validAssortment.Ass_BDate__c = this.instance.Ass_BDate__c;
                    validAssortment.Ass_EDate__c = this.instance.Ass_EDate__c;
                    validAssortment.Year__c = this.instance.Year__c;
                    validAssortment.Assortment_type__c = 'In';
                    validAssortment.Assortment__c = 'Target';
                    validAssortment.Status__c = 'Open (in bulding process)';
                    validAssortment.AutoNum__c = getExtId();
                    validAssortment.RecordTypeId = recordTypes.get('Target');
                    validAssortment.Assortment_Parent_Objective__c = this.instance.Id;
                    targetAssortmentMap.put(detail.Assortment_BU__r.BU_Target__c, validAssortment);
                }
            }*/
            // fetch histo details
            for (Assortment_Detail__c detail : negoAssortmentDetailList) {
                if (!histoProductsMap.containsKey(detail.Product__c)) {
                    Assortment_Detail__c cumulDetail;
                    if (cumulDetailsMap_by_product.containsKey(detail.Product__c)) {
                        cumulDetail = cumulDetailsMap_by_product.get(detail.Product__c);
                    }
                    else {
                        cumulDetail = new Assortment_Detail__c(Assortment_BU__c = this.instance.Id,
                                                               Product__c = detail.Product__c);
                    }
                    if (!this.budgetDetailsMap.containsKey(detail.Product__c)) {
                        this.budgetDetailsMap.put(detail.Product__c, cumulDetail.clone(true));
                    }
                    cumulDetail = this.budgetDetailsMap.get(detail.Product__c);
                    if (!this.cumulDetailsToUpsert.contains(cumulDetail)) {
                        this.cumulDetailsToUpsert.add(cumulDetail);
                    }
                    histoProductsMap.put(detail.Product__c, new ProductWrapper(detail.Product__r, cumulDetail));
                }
                String key = '' + detail.Assortment_BU__r.BU_Target__c + detail.Product__c;
                Assortment_Detail__c targetDetail = targetAssortmentDetailMap.containsKey(key) ? targetAssortmentDetailMap.get(key) : new Assortment_Detail__c();
                histoProductsMap.get(detail.Product__c).details.add(new DetailWrapper(detail, targetDetail));
            }            
            // fill data
            Map<Id, CategoryWrapper> categoryWrapperMap = new Map<Id,CategoryWrapper>();
            for (ProductWrapper pw : histoProductsMap.values()) {
                List<DetailWrapper> detailWrapperList = new List<DetailWrapper>();
                Integer leap = 0;
                for (Integer i = 0; i < pw.details.size(); i++) {
                    for (Integer j = i+leap; j < clientCircuitList.size(); j++) {
                        Id buTargetId = pw.details.get(i).buId;
                        if (buTargetId == clientCircuitList.get(j).Id) {
                            String key = '' + clientCircuitList.get(j).Id + pw.product.Id;
                            pw.details.get(i).targetDetail = targetAssortmentDetailMap.containsKey(key) ? targetAssortmentDetailMap.get(key) : new Assortment_Detail__c();
                            detailWrapperList.add(pw.details.get(i));
                            break;
                        } else {
                            DetailWrapper dw = new DetailWrapper();
                            String key = '' + clientCircuitList.get(j).Id + pw.product.Id;
                            dw.targetDetail = targetAssortmentDetailMap.containsKey(key) ? targetAssortmentDetailMap.get(key) : new Assortment_Detail__c();
                            detailWrapperList.add(dw);
                            leap++;
                        }
                    }
                }
                
                for(Integer i = detailWrapperList.size(); i < clientCircuitList.size(); i++) {
                    DetailWrapper dw = new DetailWrapper();
                    String key = '' + clientCircuitList.get(i).Id + pw.product.Id;
                    dw.targetDetail = targetAssortmentDetailMap.containsKey(key) ? targetAssortmentDetailMap.get(key) : new Assortment_Detail__c();
                    detailWrapperList.add(dw);
                }
                pw.details = detailWrapperList;
                if (!categoryWrapperMap.containsKey(pw.product.Category__c)) {
                    categoryWrapperMap.put(pw.product.Category__c, new CategoryWrapper(pw.product.Category__c, pw.product.Category__r.Long_Name__c));
                }
                categoryWrapperMap.get(pw.product.Category__c).products.add(pw);
            }
            // for intro products            
            List<DetailWrapper> details = new List<DetailWrapper>();
            List<String> conditions = new List<String>();
            conditions.add('CALENDAR_YEAR(Market_Introduction_Date__c) = ' +  (Integer) this.instance.Year__c);
            conditions.add('Id IN (\'' + String.join(this.pageResults, '\',\'') + '\')');
            conditions.add('Id NOT IN (\'' + String.join(new List<Id>(this.introProductsInAssortmentIdSet), '\',\'') + '\')');
            if (this.instance.Orga_HE__c != null && this.instance.Orga_HE__r.Path__c != null) {
                conditions.add('Category__r.Path__c LIKE \'' +  String.escapeSingleQuotes(this.instance.Orga_HE__r.Path__c) + '%\'');
            }
            String introProductQuery = gridSettingsManager.buildQuery(null, conditions, 'Name ASC');
            System.debug('setup >> introProductQuery >> ' + introProductQuery);
            List<Product2> introducedProductsList = Database.query(introProductQuery);
            
           /* for (Product2 product : introducedProductsList) {
                for (orga_BU__c clientCircuit : clientCircuitList) {
                    if (!targetAssortmentDetailMap.containsKey('' + clientCircuit.Id + product.Id)) {
                        Assortment_Detail__c targetDetail;
                        targetDetail = new Assortment_Detail__c();
                        targetDetail.Product__c = product.Id;
                        if (targetAssortmentMap.get(clientCircuit.Id).Id == null) 
                            targetDetail.Assortment_BU__r = new Assortment_BU__c(AutoNum__c = targetAssortmentMap.get(clientCircuit.Id).AutoNum__c);
                        else
                            targetDetail.Assortment_BU__c = targetAssortmentMap.get(clientCircuit.Id).Id;
                    }
                }
            }*/
            
            for (Product2 product : introducedProductsList) {
                // cumul
                Assortment_Detail__c cumulDetail;
                if (cumulDetailsMap_by_product.containsKey(product.Id))
                    cumulDetail = cumulDetailsMap_by_product.get(product.Id);
                else {
                    cumulDetail = new Assortment_Detail__c(Assortment_BU__c = this.instance.Id,
                                                           Product__c = product.Id);
                }
                if (!this.budgetDetailsMap.containsKey(product.Id)) {
                    this.budgetDetailsMap.put(product.Id, cumulDetail.clone(true));
                }
                cumulDetail = this.budgetDetailsMap.get(product.Id);
                this.cumulDetailsToUpsert.add(cumulDetail);
                details.clear();
                for (Orga_BU__c clientCircuit : clientCircuitList) {
                    DetailWrapper dw = new DetailWrapper(new Assortment_Detail__c(), targetAssortmentDetailMap.get('' + clientCircuit.Id + product.Id));
                    dw.buId = clientCircuit.Id;
                    details.add(dw);
                }
                ProductWrapper pw = new ProductWrapper(product, cumulDetail, details);
                if (!categoryWrapperMap.containsKey(product.Category__c))
                    categoryWrapperMap.put(product.Category__c, new CategoryWrapper(product.Category__c, product.Category__r.Long_Name__c));
                categoryWrapperMap.get(product.Category__c).products.add(pw);
            }
            data = categoryWrapperMap.values();
            this.categoriesIdSet_serialized = JSON.serialize(categoryWrapperMap.keySet());
            //
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_Error_Occurred));
            System.debug('Exception ex >>> ' + ex.getMessage() + ' --- ' + ex.getStackTraceString());
        }
    } 
    
    private void calculateSubTotals() {
        Map<String, Map<String, Decimal>> subTotalsMap = new Map<String, Map<String, Decimal>>();
        String key;
        string budgetKey;
        
        String aggregateQuery = 'SELECT Category__c categoryId, Assortment_BU__r.BU_Target__c clientCircuitId, Assortment_BU__r.RecordType.DeveloperName recordType,';
        aggregateQuery += ' SUM(New_Client_WD_MarketBased_Pts__c) New_Client_WD_Marketbased_Pts__c, ';
        aggregateQuery += ' SUM(L4L_Client_WD_MarketBased_Pts__c) L4L_Client_WD_Marketbased_Pts__c, ';
        aggregateQuery += ' SUM(Fact_WD_MarketBased_Pts__c) Fact_WD_MarketBased_Pts__c,';
        aggregateQuery += ' SUM(Ref_Client_WD_MarketBased_Nego_Pts__c) Ref_Client_WD_MarketBased_Nego_Pts__c';
        aggregateQuery += ' FROM Assortment_Detail__c';
        aggregateQuery += ' WHERE (';
        aggregateQuery += '(' + String.join(this.getHistoConditions(), ' AND ') + ')';
        aggregateQuery += ' OR (' + String.join(this.getTargetConditions(), ' AND ') + 'AND Status__c = \'Validated\'' + ')';
        aggregateQuery += ' OR Assortment_BU__c = \'' + this.instance.Id + '\'';
        aggregateQuery += ' )';
        aggregateQuery += ' GROUP BY Category__c, Assortment_BU__r.BU_Target__c, Assortment_BU__r.RecordType.DeveloperName';
        System.debug('calculateSubTotals >> aggregateQuery_1 >> ' + aggregateQuery);
        for (AggregateResult result : Database.query(aggregateQuery)) {
            key = result.get('clientCircuitId') + '-' + result.get('categoryId');
            budgetKey = this.instance.BU_Target__c + '-' + result.get('categoryId');
            
            if (!subTotalsMap.containsKey(key)) {
                subTotalsMap.put(key, new Map<String, Decimal>());
            }
            if (!subTotalsMap.containsKey(budgetKey)) {
                subTotalsMap.put(budgetKey, new Map<String, Decimal>());
            }
            
            Map<String, Decimal> valuesMap = subTotalsMap.get(key);
            Map<String, Decimal> budgetValuesMap = subTotalsMap.get(budgetKey);
            
            Decimal value = result.get('New_Client_WD_MarketBased_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('New_Client_WD_MarketBased_Pts__c'))) : 0;
            
            String recordType = String.valueOf(result.get('recordType'));
            recordType = recordType.equals('Conso') ? 'Nego' : recordType;
            valuesMap.put(recordType + '-New_Client_WD_MarketBased_Pts__c', value);
            if (recordType.equals('Nego') || recordType.equals('Target')) {
                if (!budgetValuesMap.containsKey(recordType + '-New_Client_WD_MarketBased_Pts__c')) {
                    budgetValuesMap.put(recordType + '-New_Client_WD_MarketBased_Pts__c', value);
                } else {
                    Decimal oldValue = budgetValuesMap.get(recordType + '-New_Client_WD_MarketBased_Pts__c');
                    value += oldValue;
                    budgetValuesMap.put(recordType  + '-New_Client_WD_MarketBased_Pts__c', value);
                }
                if (recordType.equals('Nego')) {
                    value = result.get('Fact_WD_MarketBased_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('Fact_WD_MarketBased_Pts__c'))) : 0;
                    valuesMap.put(recordType + '-Fact_WD_MarketBased_Pts__c', value);
                    
                    if (!budgetValuesMap.containsKey(recordType + '-Fact_WD_MarketBased_Pts__c')) {
                        budgetValuesMap.put(recordType + '-Fact_WD_MarketBased_Pts__c', value);
                    } else {
                        Decimal oldValue = budgetValuesMap.get(recordType + '-Fact_WD_MarketBased_Pts__c');
                        value += oldValue;
                        budgetValuesMap.put(recordType + '-Fact_WD_MarketBased_Pts__c', value);
                    }
                    value = result.get('L4L_Client_WD_Marketbased_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('L4L_Client_WD_Marketbased_Pts__c'))) : 0;
                    valuesMap.put(recordType + '-L4L_Client_WD_Marketbased_Pts__c', value);
                    
                    if (!budgetValuesMap.containsKey(recordType + '-L4L_Client_WD_Marketbased_Pts__c')) {
                        budgetValuesMap.put(recordType + '-L4L_Client_WD_Marketbased_Pts__c', value);
                    } else {
                        Decimal oldValue = budgetValuesMap.get(recordType + '-L4L_Client_WD_Marketbased_Pts__c');
                        value += oldValue;
                        budgetValuesMap.put(recordType + '-L4L_Client_WD_Marketbased_Pts__c', value);
                    }
                    
                    value = result.get('Ref_Client_WD_MarketBased_Nego_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('Ref_Client_WD_MarketBased_Nego_Pts__c'))) : 0;
                    if (!budgetValuesMap.containsKey(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c')) {
                        budgetValuesMap.put(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c', value);
                    } else {
                        Decimal oldValue = budgetValuesMap.get(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c');
                        value += oldValue;
                        budgetValuesMap.put(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c', value);
                    }
                }
            }
            
        }
        
        aggregateQuery = 'SELECT Product__c productId, Assortment_BU__r.RecordType.DeveloperName recordType,';
        aggregateQuery += ' SUM(New_Client_WD_MarketBased_Pts__c) New_Client_WD_Marketbased_Pts__c, ';
        aggregateQuery += ' SUM(L4L_Client_WD_MarketBased_Pts__c) L4L_Client_WD_Marketbased_Pts__c, ';
        aggregateQuery += ' SUM(Fact_WD_MarketBased_Pts__c) Fact_WD_MarketBased_Pts__c,';
        aggregateQuery += ' SUM(Ref_Client_WD_MarketBased_Nego_Pts__c) Ref_Client_WD_MarketBased_Nego_Pts__c';
        aggregateQuery += ' FROM Assortment_Detail__c';
        aggregateQuery += ' WHERE (';
        aggregateQuery += '(' + String.join(this.getHistoConditions(), ' AND ') + ')';
        aggregateQuery += ' OR (' + String.join(this.getTargetConditions(), ' AND ') + 'AND Status__c = \'Validated\'' + ')';
        aggregateQuery += ' OR Assortment_BU__c = \'' + this.instance.Id + '\'';
        aggregateQuery += ' )';
        aggregateQuery += ' GROUP BY Product__c, Assortment_BU__r.RecordType.DeveloperName';
        System.debug('calculateSubTotals >> aggregateQuery_2 >> ' + aggregateQuery);
        for (AggregateResult result : Database.query(aggregateQuery)) {
            key = String.valueOf(result.get('productId'));
            if (!subTotalsMap.containsKey(key)) {
                subTotalsMap.put(key, new Map<String, Decimal>());
            }
            Map<String, Decimal> valuesMap = subTotalsMap.get(key);
            Decimal value = result.get('New_Client_WD_MarketBased_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('New_Client_WD_MarketBased_Pts__c'))) : 0;
            String recordType = String.valueOf(result.get('recordType'));
            recordType = recordType.equals('Conso') ? 'Nego' : recordType;
            if (!valuesMap.containsKey(recordType + '-New_Client_WD_MarketBased_Pts__c')) {
                valuesMap.put(recordType + '-New_Client_WD_MarketBased_Pts__c', value);
            } else {
                Decimal oldValue = valuesMap.get(recordType + '-New_Client_WD_MarketBased_Pts__c');
                value += oldValue;
                valuesMap.put(recordType + '-New_Client_WD_MarketBased_Pts__c', value);
            }
            if (recordType.equals('Nego')) {
               /* if (!valuesMap.containsKey(recordType + '-New_Client_WD_MarketBased_Pts__c')) {
                    valuesMap.put(recordType + '-New_Client_WD_MarketBased_Pts__c', value);
                } else {
                    Decimal oldValue = valuesMap.get(recordType + '-New_Client_WD_MarketBased_Pts__c');
                    value += oldValue;
                    valuesMap.put(recordType + '-New_Client_WD_MarketBased_Pts__c', value);
                }*/
                value = result.get('Fact_WD_MarketBased_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('Fact_WD_MarketBased_Pts__c'))) : 0;
                if (!valuesMap.containsKey(recordType + '-Fact_WD_MarketBased_Pts__c')) {
                    valuesMap.put(recordType + '-Fact_WD_MarketBased_Pts__c', value);
                } else {
                    Decimal oldValue = valuesMap.get(recordType + '-Fact_WD_MarketBased_Pts__c');
                    value += oldValue;
                    valuesMap.put(recordType + '-Fact_WD_MarketBased_Pts__c', value);
                }
                
                value = result.get('L4L_Client_WD_Marketbased_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('L4L_Client_WD_Marketbased_Pts__c'))) : 0;
                if (!valuesMap.containsKey(recordType + '-L4L_Client_WD_Marketbased_Pts__c')) {
                    valuesMap.put(recordType + '-L4L_Client_WD_Marketbased_Pts__c', value);
                } else {
                    Decimal oldValue = valuesMap.get(recordType + '-L4L_Client_WD_Marketbased_Pts__c');
                    value += oldValue;
                    valuesMap.put(recordType + '-L4L_Client_WD_Marketbased_Pts__c', value);
                }
                
                value = result.get('Ref_Client_WD_MarketBased_Nego_Pts__c') != null ? Decimal.valueOf(String.valueOf(result.get('Ref_Client_WD_MarketBased_Nego_Pts__c'))) : 0;
                if (!valuesMap.containsKey(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c')) {
                    valuesMap.put(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c', value);
                } else {
                    Decimal oldValue = valuesMap.get(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c');
                    value += oldValue;
                    valuesMap.put(recordType + '-Ref_Client_WD_MarketBased_Nego_Pts__c', value);
                }
            }
        }
        
        for (Map<String, Decimal> valuesMap : subTotalsMap.values()) {
            Decimal targetWD = 0, budgetWD = 0;
            if (valuesMap.containsKey('Target-New_Client_WD_MarketBased_Pts__c')) {
                targetWD = valuesMap.get('Target-New_Client_WD_MarketBased_Pts__c');
            }
            if (valuesMap.containsKey('Budget-New_Client_WD_MarketBased_Pts__c')) {
                budgetWD = valuesMap.get('Budget-New_Client_WD_MarketBased_Pts__c');
            } else if (valuesMap.containsKey('Nego-L4L_Client_WD_Marketbased_Pts__c')) {
                budgetWD = valuesMap.get('Nego-L4L_Client_WD_Marketbased_Pts__c');
            }
            valuesMap.put('gap', (targetWD - budgetWD));
        }
        this.subTotalsMap_serialized = JSON.serialize(subTotalsMap);
    }
    
    private String buildQuery() {
        String assortmentDetailQuery = '';
        assortmentDetailQuery += ' SELECT Id, Name, Category__c, Category__r.Name, Category__r.Path__c, Category__r.Long_Name__c, Product__c, Year__c,Assortment_BU__r.Ass_BDate__c, Assortment_BU__r.Ass_EDate__c,';
        assortmentDetailQuery += !productFields.isEmpty() ? String.escapeSingleQuotes(String.join(productFields, ',')) + ',' : '';
        assortmentDetailQuery += ' Assortment_BU__r.BU_Target__c,Assortment_BU__r.BU_source__c, Assortment_BU__r.RecordType.DeveloperName, Assortment_BU__r.Orga_HE__c, Assortment_BU__r.Orga_HE__r.Path__c,';
        assortmentDetailQuery += ' Assortment_BU__r.Year__c, Fact_WD_MarketBased__c, Fact_WD_MarketBased_Pts__c, New_Client_WD_ClientBased__c, New_Client_ProductNumber__c, New_Client_ND_ClientBased__c,';
        assortmentDetailQuery += ' Ref_Client_Assortment__c, New_Client_WD_MarketBased__c, New_Client_WD_MarketBased_Pts__c, Ass_BU_Cluster__r.Weighted_Distribution_Manual__c, Assortment_BU__r.Status__c,';
        assortmentDetailQuery += ' Ass_BU_Cluster__r.Weighted_Distribution_Manual_N1__c, Ass_BU_Cluster__r.Weighted_Distribution_Manual_P1__c,';
        assortmentDetailQuery += ' Ass_BU_Cluster__r.Weighted_Distribution_Manual_P2__c, Client_Status__c, Ass_BU_Cluster__c, Assortment_BU__r.BU_Target__r.Name, Status__c,';
        assortmentDetailQuery += ' Assortment_BU__r.BU_Target__r.Weighted_Distribution_Manual__c, Assortment_BU__r.BU_Target__r.Weighted_Distribution_Manual_N1__c, L4L_Client_WD_MarketBased_Pts__c';
        assortmentDetailQuery += ' FROM Assortment_Detail__c';
        assortmentDetailQuery += ' WHERE Product__c IN (\'' + String.join(this.pageResults, '\',\'') + '\')';
        assortmentDetailQuery += ' AND (';
        assortmentDetailQuery += '(' + String.join(this.getHistoConditions(), ' AND ') + ')';
        assortmentDetailQuery += ' OR (' + String.join(this.getTargetConditions(), ' AND ') + ')';
        assortmentDetailQuery += ' OR Assortment_BU__c = \'' + this.instance.Id + '\'';
        assortmentDetailQuery += ' )';
        assortmentDetailQuery += ' ORDER BY Category__r.Path__c ASC, Product__r.Name ASC, Assortment_BU__r.BU_Target__r.Name ASC';
        return assortmentDetailQuery;
    }
    
    private List<String> getHistoConditions() {
        List<String> histoConditions = new List<String>();
        histoConditions.add('Version__c = NULL');
        histoConditions.add('Category__c <> NULL');
        histoConditions.add('Status__c = \'Validated\'');
        histoConditions.add('Product__r.isActive = TRUE');
        histoConditions.add('Assortment_BU__c IN (\'' + String.join(new List<Id>(this.negoAssortmentsMap.keySet()), '\',\'') + '\')');
        return histoConditions;
    }
    
    private List<String> getTargetConditions() {
        List<String> targetConditions = new List<String>();
        targetConditions.add('Version__c = NULL');
        targetConditions.add('Category__c <> NULL');
        targetConditions.add('Product__r.isActive = TRUE');
        targetConditions.add('Assortment_BU__r.BU_Source__c = \'' + String.escapeSingleQuotes(this.instance.BU_Target__c) + '\'');
        targetConditions.add('Assortment_BU__r.Orga_HE__c = \'' + String.escapeSingleQuotes(this.instance.Orga_HE__c) + '\'');
        targetConditions.add('Assortment_BU__r.Assortment_type__c = \'IN\'');
        targetConditions.add('Assortment_BU__r.Year__c = ' + this.instance.Year__c);
        targetConditions.add('Assortment_BU__r.RecordType.DeveloperName = \'Target\'');
        return targetConditions;
    }
    
    public void first() {
        this.setPageResults(this.productsObjectIterable.first());
        this.setupData();
    }
    
    public void next() {
        this.setPageResults(this.productsObjectIterable.next());
        this.setupData();
    }
    
    public void previous() {
        this.setPageResults(this.productsObjectIterable.previous());
        this.setupData();
    }
    
    public void last() {
        this.setPageResults(this.productsObjectIterable.last());
        this.setupData();
    }
    
    public void refreshPageSize() {
        this.setPageResults(this.productsObjectIterable.setPageSize(pageSize));
        this.setupData();
    }
    
    private void setPageResults(List<Object> results) {
        this.pageResults.clear();
        for (Object o : results) {
            this.pageResults.add(Id.valueOf(String.valueOf(o)));
        }
    }
    
    private Integer getExtId() {
        return extId++;
    }
    
    public void save() {
        try {
            if (!cumulDetailsToUpsert.isEmpty()) {
                // Check Assortment_Detail__c upsert field security
                String[] assortmentDetailFields = new List<String>{getFieldName('Product__c'), getFieldName('New_Client_WD_MarketBased__c'), getFieldName('Record_date__c'),
                    getFieldName('Client_Status__c'), getFieldName('Ass_BU_Cluster__c'), getFieldName('Ref_Client_Assortment__c'), getFieldName('Status__c')};
                        String[] assortmentDetailCreateFields = new List<String>{getFieldName('Assortment_BU__c')};
                            assortmentDetailCreateFields.addAll(assortmentDetailFields);
                if(checkCreatibility(Assortment_Detail__c.SObjectType, assortmentDetailCreateFields) &&
                   checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields))
                {
                    upsert cumulDetailsToUpsert;
                }
            }
            this.initialSave = true;
            this.calculateSubTotals();
            futureSave(this.instance.Id, subTotalsMap_serialized);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        } catch (DmlException ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(0)));
        } catch (Exception ex) {
            System.debug('ex.getStackTraceString() >>>>>>>>>>>>>> ' + ex.getStackTraceString());
            System.debug('ex >>>>>>>>>>>>>> ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    public void requestForApproval() {
        SavePoint sp = Database.setSavePoint();
        try {
            // Check Assortment_BU__c update field security
            String[] assortmentBUFields = new List<String>{'Name', 'RecordTypeId', 'ownerId', getFieldName('Status__c'), getFieldName('BU_Source__c'), getFieldName('BU_Target__c'),
                getFieldName('Orga_HE__c'), getFieldName('Ass_BDate__c'), getFieldName('Ass_EDate__c'), getFieldName('Year__c'), getFieldName('Assortment_type__c'),
                getFieldName('Assortment__c'), getFieldName('Assortment_Parent_Objective__c'), getFieldName('Assortment_Parent__c')};
                    String[] assortmentBUUpdateFields = new List<String>{getFieldName('Status__c')};
                        
                        if(checkCreatibility(Assortment_BU__c.SObjectType, assortmentBUFields) &&
                           checkUpdatibility(Assortment_BU__c.SObjectType, assortmentBUUpdateFields))
                    {
                        // update budget status to 'Request for Approval'
                        this.instance.Status__c = 'Request for Approval';     
                        update this.instance;
                        
                        this.instanceLongName = [SELECT Long_Name__c FROM Assortment_BU__c WHERE Id = :this.instance.Id].Long_Name__c;
                        // insert target assortments head
                        Map<Id, Assortment_BU__c> targetAssortmentsMap = new Map<Id, Assortment_BU__c>();
                        List<Assortment_BU__c> targetAssortmentsToInsert = new List<Assortment_BU__c>();
                        for (Assortment_BU__c item : [SELECT Id, BU_Target__c FROM Assortment_BU__c
                                                      WHERE RecordType.DeveloperName = 'Target'
                                                      AND Assortment_Type__c = 'In'
                                                      AND Year__c = :this.instance.Year__c
                                                      AND BU_Source__c = :this.instance.BU_Target__c
                                                      AND Orga_HE__c = :this.instance.Orga_HE__c])
                        {
                            targetAssortmentsMap.put(item.BU_Target__c, item);
                        }
                        
                        for (Assortment_BU__c item : [SELECT Id, BU_Target__c, OwnerId FROM Assortment_BU__c
                                                      WHERE RecordType.DeveloperName = 'Nego'
                                                      AND Status__c = 'Validated'
                                                      AND Assortment_Type__c = 'Out'
                                                      AND Year__c = :(this.instance.Year__c - 1)
                                                      AND BU_Source__c = :this.instance.BU_Target__c
                                                      AND Orga_HE__c = :this.instance.Orga_HE__c])
                        {
                            if (!targetAssortmentsMap.containsKey(item.BU_Target__c)) {
                                Assortment_BU__c targetAssortment = new Assortment_BU__c(Name = 'buId',
                                                                                         BU_Source__c = this.instance.BU_Target__c,
                                                                                         BU_Target__c = item.BU_Target__c,
                                                                                         Orga_HE__c = this.instance.Orga_HE__c,
                                                                                         Ass_BDate__c = this.instance.Ass_BDate__c,
                                                                                         Ass_EDate__c = this.instance.Ass_EDate__c,
                                                                                         Year__c = this.instance.Year__c,
                                                                                         Assortment_type__c = 'In',
                                                                                         Assortment__c = 'Target',
                                                                                         Status__c = 'Open (in bulding process)',
                                                                                         RecordTypeId = recordTypes.get('Target'),
                                                                                         Assortment_Parent_Objective__c = this.instance.Id,
                                                                                         Assortment_Parent__c = item.Id,
                                                                                         ownerId = item.ownerId);
                                targetAssortmentsToInsert.add(targetAssortment);
                            }
                        }
                        
                        insert targetAssortmentsToInsert;
                        
                        // execute batch to insert target assortment details
                        Database.executeBatch(new GenerateAssortmentTargetDetailsBatch('BudgetSimulationController', this.instance.Id), 20);
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Target_Assortment_Creation_Started));
                    }
        } catch (Exception ex) {
            Database.rollback(sp);
        }
    }
    
    public void validate() {
        try {
            this.instance.Status__c = 'Validated';
            // check security on update Assortment_BU__c
            String[] assortmentBUFields = new String[] {getFieldName('Status__c')};
            if(checkUpdatibility(Assortment_BU__c.SObjectType, assortmentBUFields)) {
                update this.instance;
            }
            this.instanceLongName = [SELECT Long_Name__c FROM Assortment_BU__c WHERE Id = :this.instance.Id].Long_Name__c;
        } catch (Exception ex) {
            System.debug('ex.getStackTraceString() >>>>>>>>>>>>>> ' + ex.getStackTraceString());
            System.debug('ex >>>>>>>>>>>>>> ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    @future
    private static void futureSave(Id assortmentBudgetId, String subTotalsMap_serialized) {
        
        Map<String, Map<String, Decimal>> subTotalsMap = (Map<String, Map<String, Decimal>>) JSON.deserialize(subTotalsMap_serialized, Map<String, Map<String, Decimal>>.class);
        Map<String, Id> recordTypes = NegoptimHelper.getObjectRecordTypeMapIds(Assortment_BU__c.sObjectType);
        List<Assortment_Detail__c> cumulDetailsToUpsert = new List<Assortment_Detail__c>();
        Map<String, Schema.SObjectField> assortmentDetailsFieldsMap = Schema.SObjectType.Assortment_Detail__c.fields.getMap();
        Integer extId;
        try {
            extId = Integer.valueOf([SELECT AutoNum__c FROM Assortment_BU__c WHERE AutoNum__c <> NULL ORDER BY AutoNum__c DESC LIMIT 1].AutoNum__c);
            extId = extId == null ? 0 : extId + 1;
            System.debug('max autoNum >>' + extId);
        } catch (QueryException ex) {
            System.debug('Exception >> ' + ex.getStackTraceString());
            extId = 0;
        }
        
        Assortment_BU__c budgetAssortment = [SELECT Id, Name, BU_Target__c, BU_Source__c, Orga_HE__c, Orga_HE__r.Path__c, Year__c, Ass_BDate__c, Ass_EDate__c
                                             FROM Assortment_BU__c
                                             WHERE Id = :assortmentBudgetId];
        
        String assortmentDetailQuery = '';
        assortmentDetailQuery += ' SELECT Id, Name, Category__c, Category__r.Name, Category__r.Path__c, Category__r.Long_Name__c, Product__c, Year__c,Assortment_BU__r.Ass_BDate__c, Assortment_BU__r.Ass_EDate__c,';
        assortmentDetailQuery += ' Assortment_BU__r.BU_Target__c,Assortment_BU__r.BU_source__c, Assortment_BU__r.RecordType.DeveloperName, Assortment_BU__r.Orga_HE__c, Assortment_BU__r.Orga_HE__r.Path__c,';
        assortmentDetailQuery += ' Assortment_BU__r.Year__c, Fact_WD_MarketBased_Pts__c, New_Client_WD_ClientBased__c, New_Client_ProductNumber__c, New_Client_ND_ClientBased__c,';
        assortmentDetailQuery += ' Ref_Client_Assortment__c, New_Client_WD_MarketBased_Pts__c, Ass_BU_Cluster__r.Weighted_Distribution_Manual__c, Assortment_BU__r.Status__c,';
        assortmentDetailQuery += ' Ass_BU_Cluster__r.Weighted_Distribution_Manual_N1__c, Ass_BU_Cluster__r.Weighted_Distribution_Manual_P1__c,';
        assortmentDetailQuery += ' Ass_BU_Cluster__r.Weighted_Distribution_Manual_P2__c, Client_Status__c, Ass_BU_Cluster__c, Assortment_BU__r.BU_Target__r.Name,';
        assortmentDetailQuery += ' Assortment_BU__r.BU_Target__r.Weighted_Distribution_Manual__c, Assortment_BU__r.BU_Target__r.Weighted_Distribution_Manual_N1__c';
        assortmentDetailQuery += ' FROM Assortment_Detail__c';
        assortmentDetailQuery += ' WHERE Assortment_BU__c = \'' + String.escapeSingleQuotes(budgetAssortment.id) + '\'';
        assortmentDetailQuery += ' OR (Assortment_BU__r.BU_Source__c = \'' + String.escapeSingleQuotes(budgetAssortment.BU_Target__c) + '\'';
        assortmentDetailQuery += ' AND Assortment_BU__r.Orga_HE__c = \'' + String.escapeSingleQuotes(budgetAssortment.Orga_HE__c) + '\'';
        assortmentDetailQuery += ' AND Assortment_BU__r.Assortment_type__c = \'Out\'';
        assortmentDetailQuery += ' AND Assortment_BU__r.Status__c = \'Validated\'';
        assortmentDetailQuery += ' AND Category__c <> NULL';
        assortmentDetailQuery += ' AND Product__r.isActive = TRUE';
        assortmentDetailQuery += ' AND Version__c = NULL';
        assortmentDetailQuery += ' AND Status__c = \'Validated\'';
        assortmentDetailQuery += ' AND ((Assortment_BU__r.Year__c = ' + (budgetAssortment.Year__c - 1);
        assortmentDetailQuery += ' AND Assortment_BU__r.RecordType.DeveloperName = \'Nego\')';
        assortmentDetailQuery += ' OR ';
        assortmentDetailQuery += ' (Assortment_BU__r.Year__c = ' + budgetAssortment.Year__c;
        assortmentDetailQuery += ' AND Assortment_BU__r.RecordType.DeveloperName = \'L4L\')))';
        assortmentDetailQuery += ' ORDER BY Product__r.Name, Assortment_BU__r.BU_Target__r.Name';
        
        Set<Id> histoProductsIdSet = new Set<Id>();
        List<Assortment_Detail__c> negoAssortmentDetailList = new List<Assortment_Detail__c>();
        Map<Id, Assortment_Detail__c> cumulDetailsMap_by_product = new Map<Id, Assortment_Detail__c>();

        // query 
        List<Assortment_Detail__c> allAssortmentDetailsList = database.query(assortmentDetailQuery);
        for (Assortment_Detail__c detail : allAssortmentDetailsList) {
            if (detail.Assortment_BU__c == budgetAssortment.Id) {
                cumulDetailsMap_by_product.put(detail.Product__c, detail);
            } else {
                negoAssortmentDetailList.add(detail);
            }
        }
        // fetch histo details
        for (Assortment_Detail__c detail : negoAssortmentDetailList) {
            if (!histoProductsIdSet.contains(detail.Product__c)) {
                Assortment_Detail__c cumulDetail;
                if (cumulDetailsMap_by_product.containsKey(detail.Product__c)) {
                    cumulDetail = cumulDetailsMap_by_product.get(detail.Product__c);
                } else {
                    cumulDetail = new Assortment_Detail__c(Assortment_BU__c = budgetAssortment.Id,
                                                           Product__c = detail.Product__c);
                    if (subTotalsMap.containsKey(detail.Product__c) && subTotalsMap.get(detail.Product__c).containsKey('Nego-L4L_Client_WD_Marketbased_Pts__c')) {
                        cumulDetail.New_Client_WD_MarketBased__c = subTotalsMap.get(detail.Product__c).get('Nego-L4L_Client_WD_Marketbased_Pts__c');
                    }
                }
                cumulDetailsToUpsert.add(cumulDetail);
                histoProductsIdSet.add(detail.Product__c);
            }
        }
        // for intro products
        String introProductQuery = 'SELECT Id FROM Product2';
        introProductQuery += ' WHERE isActive = TRUE AND CALENDAR_YEAR(Market_Introduction_Date__c) = ' +  (Integer) budgetAssortment.Year__c;
        if (budgetAssortment.Orga_HE__c != null && budgetAssortment.Orga_HE__r.Path__c != null) {
            introProductQuery += ' AND Category__r.Path__c LIKE \'' +  String.escapeSingleQuotes(budgetAssortment.Orga_HE__r.Path__c) + '%\'';
        }
        System.debug('futureSave >> introProductQuery >> ' + introProductQuery);
        List<Product2> introProductsList = Database.query(introProductQuery);
        for (Product2 product : introProductsList) {
            Assortment_Detail__c cumulDetail;
            if (cumulDetailsMap_by_product.containsKey(product.Id))
                cumulDetail = cumulDetailsMap_by_product.get(product.Id);
            else {
                cumulDetail = new Assortment_Detail__c(Assortment_BU__c = budgetAssortment.Id,
                                                       Product__c = product.Id,
                                                       New_Client_WD_MarketBased__c = 0);
            }
            cumulDetailsToUpsert.add(cumulDetail);
        }
        
        System.Savepoint sp = Database.setSavepoint();
        try {
            if (!cumulDetailsToUpsert.isEmpty()) {
                // Check Assortment_Detail__c upsert field security
                String[] assortmentDetailFields = new List<String>{NegoptimHelper.normalizeAPIName('Product__c'), NegoptimHelper.normalizeAPIName('New_Client_WD_MarketBased__c'),
                    NegoptimHelper.normalizeAPIName('Record_date__c'), NegoptimHelper.normalizeAPIName('Client_Status__c'), NegoptimHelper.normalizeAPIName('Ass_BU_Cluster__c'),
                    NegoptimHelper.normalizeAPIName('Ref_Client_Assortment__c'), NegoptimHelper.normalizeAPIName('Status__c')};                
                        String[] assortmentDetailCreateFields = new List<String>{NegoptimHelper.normalizeAPIName('Assortment_BU__c')};
                            assortmentDetailCreateFields.addAll(assortmentDetailFields);
                if(NegoptimHelper.checkCreatibility(Assortment_Detail__c.SObjectType, assortmentDetailCreateFields) &&
                   NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields))
                {
                    upsert cumulDetailsToUpsert;
                }
            }
        } catch (Exception ex) {
            System.debug('ex.getStackTraceString() >>>>>>>>>>>>>> ' + ex.getStackTraceString());
            System.debug('ex >>>>>>>>>>>>>> ' + ex);
            Database.rollback(sp);
        }
    }
    
    private Assortment_Detail__c clone(Assortment_Detail__c detail) {
        Assortment_Detail__c cloneDetail = new Assortment_Detail__c();
        if (detail != null) {
            Map<String, Object> populatedFields = detail.getPopulatedFieldsAsMap();
            for (String fieldName : populatedFields.keySet()) {
                fieldName = fieldName.replace('__r', '__c');
                if (!fieldName.equalsIgnoreCase('Assortment_BU__c') && !fieldName.equalsIgnoreCase('Id')
                    && !assortmentDetailsFieldsMap.get(fieldName.toLowerCase()).getDescribe().isAutoNumber()
                    && !assortmentDetailsFieldsMap.get(fieldName.toLowerCase()).getDescribe().isCalculated())
                {
                    cloneDetail.put(fieldName, populatedFields.get(fieldName));
                }
            }
        }
        return cloneDetail;
    }
    
    private static Assortment_Detail__c clone(Assortment_Detail__c detail, Map<String, Schema.SObjectField> assortmentDetailsFieldsMap) {
        Assortment_Detail__c cloneDetail = new Assortment_Detail__c();
        if (detail != null) {
            Map<String, Object> populatedFields = detail.getPopulatedFieldsAsMap();
            for (String fieldName : populatedFields.keySet()) {
                fieldName = fieldName.replace('__r', '__c');
                if (!fieldName.equalsIgnoreCase('Assortment_BU__c') && !fieldName.equalsIgnoreCase('Id')
                    && !assortmentDetailsFieldsMap.get(fieldName.toLowerCase()).getDescribe().isAutoNumber()
                    && !assortmentDetailsFieldsMap.get(fieldName.toLowerCase()).getDescribe().isCalculated())
                {
                    cloneDetail.put(fieldName, populatedFields.get(fieldName));
                }
            }
        }
        return cloneDetail;
    }
    
    public class DetailWrapper {
        public Assortment_Detail__c histoDetail {get; set;}
        public Assortment_Detail__c targetDetail {get; set;}
        public Id buId {get; set;}
        
        public DetailWrapper() {
            this.histoDetail = new Assortment_Detail__c();
            this.targetDetail = new Assortment_Detail__c();
        }
        
        public DetailWrapper (Assortment_Detail__c histoDetail, Assortment_Detail__c targetDetail) {
            this.histoDetail = histoDetail;
            this.targetDetail = targetDetail;
            if (histoDetail.Assortment_BU__c != null)
                buId = histoDetail.Assortment_BU__r.BU_Target__c;
        }
    }
    
    public class ProductWrapper {
        public Product2 product {get; set;}
        public List<DetailWrapper> details {get; set;}
        public Assortment_Detail__c cumulDetail {get; set;}
        
        public ProductWrapper(Product2 product, Assortment_Detail__c cumulDetail, List<DetailWrapper> details) {
            this.product = product;
            this.cumulDetail = cumulDetail;
            this.details = details;
        }
        
        public ProductWrapper(Product2 product, Assortment_Detail__c cumulDetail) {
            this.product = product;
            this.cumulDetail = cumulDetail;
            this.details = new List<DetailWrapper>();
        }
    }
    
    public class CategoryWrapper {
        public List<ProductWrapper> products {get; set;}
        public Id categoryId {get; set;}
        public String categoryName {get; set;}
        
        public CategoryWrapper(Id categoryId, String categoryName) {
            this.categoryId = categoryId;
            this.categoryName = categoryName;
            this.products  = new List<ProductWrapper>();
        }
    }
    
    /** Wrapper class for Category Tree. */
    public class CategoryTreeWrapper {
        private String title;
        private String key;
        private boolean folder;
        private String path;
        private String parentId {get; set;}
        private List<CategoryTreeWrapper> children {get; set;}
        private Map<String, Decimal> sums {get; set;}
        
        public CategoryTreeWrapper(List<String> fieldNames) {
            this.children = new List<CategoryTreeWrapper>();
            this.sums = new Map<String, Decimal>();
            for (String fieldName : fieldNames) {
                this.sums.put(fieldName, 0);
            }
        }
    }
}