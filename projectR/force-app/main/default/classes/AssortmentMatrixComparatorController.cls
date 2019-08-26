/**
 * @author ULiT
 * @date 18/05/2019
 * @description AssortmentClientMatrix
 * */
public with sharing class AssortmentMatrixComparatorController extends NegoptimBaseController {
        
    private List<AggregateResult> pageResults;
    private Map<Id, Assortment_Detail__c> assortmentDetailsMap = new Map<Id, Assortment_Detail__c>(); // used to persist changed assortment details during pagination
    
    public Orga_BU__c orgaBU {get; set;}
    public Assortment_BU__c assortmentBU {get; set;}
    public String selectedRecordType {get; set;}
    public String negoRecordType {get; set;}
    public String targetRecordType {get; set;}
    public String title {get; set;}
    public GridSettingsManager gridSettingsManager {get; set;}
    public List<String> fieldsToSum {get; set;}
    public List<Id> assortmentsIdList {get; set;}
    public Map<Id, Assortment_BU__c> assortmentsMap {get; set;}
    public List<CategoryWrapper> categoryWrapperList {get; set;}
    // pagination
    public ListIterable productsListIterable {get; private set;}
    public Integer pageSize {get; set;}
    public Integer noOfRecords {get; private set;}
    public List<SelectOption> pageSizeOptions {get; private set;}
    
    //filters
    public String searchTerm {get; set;}
    
    //serialized data
    public String categoriesIdSet_serialized {get; private set;}
    public String assortmentsIdSet_serialized {get; private set;}
    public String gridFields_serialized {get; private set;}
    public String assortmentDetailsMap_serialized {get; private set;}
    public String subTotalsMap_serialized {get; private set;}
    public String treeFields_serialized {get; private set;}
    public String CategoryTree_serialized {get; private set;}
    // read from view
    public String changedAssortmentDetailsIdSet_serialized {get; set;}
    // assortment validation
    public Id assortmentToValidateId {get; set;}
    
    public AssortmentMatrixComparatorController() {
        String metadataDeveloperName = GlobalSettingsManager.loadGlobalSettings().assortmentMatrixComparatorGridLayout;
        String staticFields = 'Id,Ass_BU_Cluster__c,Client_Status__c,Year__c,Assortment_BU__c,Assortment_BU__r.Name,Assortment_BU__r.Long_Name__c,Assortment_BU__r.BU_Source__c,';
        staticFields += 'Assortment_BU__r.BU_Source__r.SiteOfSales_Number__c,Assortment_BU__r.BU_Source__r.SiteOfSales_Number_N1__c,';
        staticFields += 'Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P1__c,Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P2__c,';
        staticFields += 'Assortment_BU__r.BU_Target__c,Assortment_BU__r.Orga_HE__c,Assortment_BU__r.Orga_HE__r.Path__c,Assortment_BU__r.Year__c,';
        staticFields += 'Category__c,Category__r.Path__c,Category__r.Long_Name__c,Product__c, Product__r.Name,Product__r.IsInnovation__c,Product__r.Gold__c,';
        staticFields += 'Product__r.VIP__c,Product__r.ProductCode,Product__r.Product_EAN__c,Product__r.recordType.developerName,Product__r.Market_End_of_Life_Date__c,';
        staticFields += 'Last_History__c';
        
        this.gridSettingsManager = new GridSettingsManager('Assortment_Detail__c', staticFields, metadataDeveloperName);
        // get fields to include in totals
        this.fieldsToSum = new List<String>();
        for (GridSettingsManager.FieldWrapper field : this.gridSettingsManager.GRID_FIELDS) {
            if ((field.fieldType == DisplayType.Double || field.fieldType == DisplayType.Integer || field.fieldType == DisplayType.Long
                 || field.fieldType == DisplayType.Percent || field.fieldType == DisplayType.Currency) && !field.isReference)
            {
                this.fieldsToSum.add(field.fieldName);
            }
        }
        
        Map<String, String> recordTypeMap = new Map<String, String>();
        // If sObjectType is wrong, then an Exception is thrown.
        // Check Accessibility.
        if(NegoptimHelper.checkAccessibilityFields(Schema.SObjectType.RecordType.fields.getMap(), new String [] {'Id', 'DeveloperName'})) {
            List<RecordType> rtList = [SELECT toLabel(Name), DeveloperName FROM RecordType WHERE SobjectType = 'Assortment_BU__c' AND IsActive = true];
            for(RecordType item : rtList) {
                recordTypeMap.put(item.DeveloperName, item.Name);
            }
        }
        this.negoRecordType = recordTypeMap.get('Nego');
        this.targetRecordType = recordTypeMap.get('Target');
        this.selectedRecordType = 'Nego';
        this.orgaBU = new Orga_BU__c();
        this.assortmentBU = new Assortment_BU__c(Year__c = Date.today().year());
        // pagination fields [Product2]
        this.pageSize = 25;
        this.noOfRecords = 0;
        this.pageSizeOptions = new List<SelectOption>();
        this.pageSizeOptions.add(new SelectOption('25', '25'));
        this.pageSizeOptions.add(new SelectOption('50', '50'));
        this.pageSizeOptions.add(new SelectOption('75', '75'));
        this.pageSizeOptions.add(new SelectOption('100', '100'));
    }
    
    public void changePageScope() {
        List<String> formatOrigin = orgaBU.Format_Origin__c.split(';');
        Set<String> foramtOriginLabelSet = new Set<String>();
        this.categoryWrapperList = new List<CategoryWrapper>();
        this.assortmentsMap = new Map<Id, Assortment_BU__c>();
        this.title = null;
        String query = 'SELECT Id, Name, Status__c, Year__c, Orga_HE__r.Name, BU_Target__r.Country_Origin__r.Name, toLabel(BU_Target__r.Format_Origin__c)';
        query += ' FROM Assortment_BU__c';
        query += ' WHERE BU_Target__r.Format_Origin__c INCLUDES (\'' + String.join(formatOrigin,'\',\'') + '\')';
        query += ' AND BU_Target__r.Country_Origin__c = \'' + this.orgaBU.Country_Origin__c + '\'';
        query += ' AND Orga_HE__c = \'' + this.assortmentBU.Orga_HE__c + '\'';
        query += ' AND Year__c = ' + this.assortmentBU.Year__c;
        query += ' AND RecordType.DeveloperName = \'' + String.escapeSingleQuotes(this.selectedRecordType) + '\'';
        query += ' ORDER BY BU_Target__r.Name, Name';
        System.debug('assortments query >>> ' + query);
        for (Assortment_BU__c assortment : Database.query(query)) {
            this.assortmentsMap.put(assortment.Id, assortment);
            foramtOriginLabelSet.addAll(assortment.BU_Target__r.Format_Origin__c.split(';'));
            if (String.isBlank(this.title)) {
                this.title = (selectedRecordType == 'Nego' ? negoRecordType : targetRecordType) + ' | ' + assortment.BU_Target__r.Country_Origin__r.Name + ' | ' + assortment.Orga_HE__r.Name + ' | {0} | ' + assortment.Year__c;
            }
        }
        if (String.isNotBlank(this.title)) {
            this.title = String.format(this.title, new String[] {String.join(new List<String>(foramtOriginLabelSet), '+')});
        }
        this.assortmentsIdList = new List<Id> (assortmentsMap.keySet());
        this.assortmentsIdSet_serialized = JSON.serialize(this.assortmentsMap.keySet());
        // fancy tree
        Id budgetHEId = String.isBlank(this.assortmentBU.Orga_HE__c) ? NegoptimHelper.getRootId() : this.assortmentBU.Orga_HE__c;
        HierarchyElementTree het = new HierarchyElementTree(new Set<Id> {budgetHEId});
        
        Map<Id, CategoryTreeWrapper> categoryTreeMap = new Map<Id, CategoryTreeWrapper>();
        Map<Id, CategoryTreeWrapper> hierarchyTree = new Map<Id, CategoryTreeWrapper>();
        Map<Id, Orga_HE__c> parentCategories = new Map<Id, Orga_HE__c>();
        Set<Id> relatedCategoryIds = new Set<Id>();
        Map<Id, Id> parentChildMap = new Map<Id, Id>();
        List<String> treeFields = new list<String>();
        
        for (String field : this.fieldsToSum) {
            treeFields.add('conso-' + field);
        }
        for (Id assortmentId : this.assortmentsMap.keySet()) {
            for (String field : this.fieldsToSum) {
                treeFields.add(assortmentId + '-' + field);
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
        //
        this.search();
        this.calculateSubTotals();
    }
    
    public void backToFilterPage() {
        this.productsListIterable = null;
        this.noOfRecords = 0;
    }
    
    public void search() {
        String query = 'SELECT Product__c productId FROM Assortment_Detail__c';
        query += ' WHERE ' + String.join(this.getConditions(), ' AND ');
        if (String.isNotBlank(this.searchTerm)) {
            query += ' AND (Product__r.Name LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
            query += ' OR Product__r.Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
            query += ' OR Product__r.ProductCode LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
            query += ' OR Product__r.Category__r.Long_Name__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
            query += ' OR Product__r.Category__r.Elt_Code__c LIKE \'%' + String.escapeSingleQuotes(this.searchTerm) + '%\')';
        }
        query += ' GROUP BY Product__c, Product__r.Name, Category__r.Path__c';
        query += ' ORDER BY Category__r.Path__c, Product__r.Name';
        System.debug('search query >>> ' + query);
        List<AggregateResult> aggregateResults = Database.query(query);
        this.productsListIterable = new ListIterable(aggregateResults);
        if (aggregateResults.size() > this.pageSize) {
            this.productsListIterable.setPageSize = this.pageSize;
        } else {
            this.productsListIterable.setPageSize = aggregateResults.size();
        }
        this.noOfRecords = aggregateResults.size();
        this.pageResults = this.productsListIterable.next();
        this.setupData();
    }
    
    public void setupData() {
        List<Id> productsIdList = new List<Id>();
        for (AggregateResult result : this.pageResults) {
            productsIdList.add(Id.valueOf(String.valueOf(result.get('productId'))));
        }
        
        List<String> conditions = this.getConditions();
        conditions.add('Product__c IN (\'' + String.join(productsIdList, '\',\'') + '\')');
        String orderBy = 'Category__r.Path__c, Product__r.Name';
        String query = this.gridSettingsManager.buildQuery(null, conditions, orderBy);
        System.debug('setupData query >>> ' + query);
        List<Assortment_Detail__c> assortmentDetailsList = Database.query(query);
        
        Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> assortmentBUClusterMap = AssortmentUtility.getAssortmentBUClustersMap(assortmentDetailsList);
        
        Map<Id, ProductWrapper> productWrapperMap = new Map<Id, ProductWrapper>();
        Map<Id, CategoryWrapper> categoryWrapperMap = new Map<Id, CategoryWrapper>();
        
        for (Assortment_Detail__c detail : assortmentDetailsList) {
            if (!this.assortmentDetailsMap.containsKey(detail.Id)) {
                this.assortmentDetailsMap.put(detail.Id, detail.clone(true));
            }
            Assortment_Detail__c clonedDetail = this.assortmentDetailsMap.get(detail.Id);
            if (!productWrapperMap.containsKey(detail.Product__c)) {
                productWrapperMap.put(detail.Product__c, new ProductWrapper(clonedDetail));
            }
            List<Orga_BU__c> clusters = new List<Orga_BU__c>();
            if (assortmentBUClusterMap.containsKey(clonedDetail.Assortment_BU__r.BU_Target__c)
                && assortmentBUClusterMap.get(clonedDetail.Assortment_BU__r.BU_Target__c).containsKey(clonedDetail.Category__c))
            {
                clusters = assortmentBUClusterMap.get(clonedDetail.Assortment_BU__r.BU_Target__c).get(clonedDetail.Category__c).values();
            }
            productWrapperMap.get(detail.Product__c).addAssortmentDetail(clonedDetail, clusters);
        }
        // clear variables to save up on heap size
        assortmentBUClusterMap = null;
        assortmentDetailsList = null;
        for (Id key : productWrapperMap.keySet()) {
            ProductWrapper productWrapper = productWrapperMap.get(key);
            if (!categoryWrapperMap.containsKey(productWrapper.referenceDetail.Category__c))
                categoryWrapperMap.put(productWrapper.referenceDetail.Category__c, new CategoryWrapper(productWrapper.referenceDetail));
            categoryWrapperMap.get(productWrapper.referenceDetail.Category__c).products.add(productWrapper);
        }
        categoryWrapperList = categoryWrapperMap.values();
        
        // serialize data
        this.categoriesIdSet_serialized = JSON.serialize(categoryWrapperMap.keySet());
        this.gridFields_serialized = JSON.serialize(this.gridSettingsManager.GRID_FIELDS);
        this.assortmentDetailsMap_serialized = JSON.serialize(this.assortmentDetailsMap);
    }
    
    private void calculateSubTotals() {
        Map<String, Map<String, Decimal>> subTotalsMap = new Map<String, Map<String, Decimal>>();
        // grouped by Category and Assortment_BU
        String query = 'SELECT Category__c categoryId, Assortment_BU__c assortmentId';
        for (String fieldName : fieldsToSum) {
                query += ', SUM(' + fieldName + ') ' + fieldName;
        }
        query += ' FROM Assortment_Detail__c';
        query += ' WHERE ' + String.join(this.getConditions(), ' AND ');
        query += ' GROUP BY Category__c, Assortment_BU__c';
        System.debug('category totals query >>> ' + query);
        for (AggregateResult result : Database.query(query)) {
            String key = Id.valueOf(String.valueOf(result.get('assortmentId'))) + '-' + Id.valueOf(String.valueOf(result.get('categoryId')));
            String consoKey = 'conso-' + Id.valueOf(String.valueOf(result.get('categoryId')));
            subTotalsMap.put(key, new Map<String, Decimal>());
            if (!subTotalsMap.containsKey(consoKey)) {
                subTotalsMap.put(consoKey, new Map<String, Decimal>());
            }
            Map<String, Decimal> values = subTotalsMap.get(consoKey);
            for (String fieldName : fieldsToSum) {
                Decimal newValue = result.get(fieldName) == null ? 0 : Decimal.valueOf(String.valueOf(result.get(fieldName)));
                subTotalsMap.get(key).put(fieldName, newValue);
                if(!values.containsKey(fieldName)) {
                    values.put(fieldName, 0);
                }
                Decimal total = values.get(fieldName);
                values.put(fieldName, total + newValue);
            }
        }
        // grouped by product
        query = 'SELECT Product__c productId';
        for (String fieldName : fieldsToSum) {
                query += ', SUM(' + fieldName + ') ' + fieldName;
        }
        query += ' FROM Assortment_Detail__c';
        query += ' WHERE ' + String.join(this.getConditions(), ' AND ');
        query += ' GROUP BY Product__c';
        System.debug('conso totals query >>> ' + query);
        for (AggregateResult result : Database.query(query)) {
            String key = Id.valueOf(String.valueOf(result.get('productId')));
            subTotalsMap.put(key, new Map<String, Decimal>());
            for (String fieldName : fieldsToSum) {
                subTotalsMap.get(key).put(fieldName, result.get(fieldName) == null ? 0 : Decimal.valueOf(String.valueOf(result.get(fieldName))));
            }
        }
        
        
        this.subTotalsMap_serialized = JSON.serialize(subTotalsMap);
    }
    
    private List<String> getConditions() {
        List<String> conditions = new List<String>();
        conditions.add('Version__c = NULL');
        conditions.add('Product__r.isActive = TRUE');
        conditions.add('Assortment_BU__c IN (\'' + String.join(this.assortmentsIdList,'\',\'') + '\')');
        return conditions;
    }
    
    public void first() {
        persistChangedDetails();
        this.pageResults = this.productsListIterable.first();
        this.setupData();
    }
    
    public void next() {
        persistChangedDetails();
        this.pageResults = this.productsListIterable.next();
        this.setupData();
    }
    
    public void previous() {
        persistChangedDetails();
        this.pageResults = this.productsListIterable.previous();
        this.setupData();
    }
    
    public void last() {
        persistChangedDetails();
        this.pageResults = this.productsListIterable.last();
        this.setupData();
    }
    
    public void refreshPageSize() {
        persistChangedDetails();
        this.pageResults = this.productsListIterable.setPageSize(pageSize);
        this.setupData();
    }
    
    private void persistChangedDetails() {
        if (String.isNotBlank(this.changedAssortmentDetailsIdSet_serialized)) {
            Set<Id> changedAssortmentDetailsIdSet = (Set<Id>) JSON.deserialize(changedAssortmentDetailsIdSet_serialized, Set<Id>.class);
            for (Id key : assortmentDetailsMap.keySet()) {
                if (!changedAssortmentDetailsIdSet.contains(key)) {
                    this.assortmentDetailsMap.remove(key);
                }
            }
        } else {
            this.assortmentDetailsMap.clear();
        }
    }
    
    @RemoteAction
    public static String save(String assortmentDetailsList_serialized, String gridField_serialized) {
        String returnMessage;
        List<GridSettingsManager.FieldWrapper> gridFields = (List<GridSettingsManager.FieldWrapper>) JSON.deserialize(gridField_serialized, List<GridSettingsManager.FieldWrapper>.class);
        try {
            List<Assortment_Detail__c> assortmentDetailsList = (List<Assortment_Detail__c>) JSON.deserialize(assortmentDetailsList_serialized, List<Assortment_Detail__c>.class);
            // Check Assortment_Detail__c upsert field security
            String[] assortmentDetailFields = new List<String>();
            for (GridSettingsManager.FieldWrapper fieldWrapper : gridFields) {
                if(fieldWrapper.isInputField && !fieldWrapper.isCalculated && !fieldWrapper.fieldName.contains('.'))
                {
                    assortmentDetailFields.add(NegoptimHelper.normalizeAPIName(fieldWrapper.fieldName));
                }
            }
            if(NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
                update assortmentDetailsList;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
            returnMessage = Label.MSG_Successfully_Saved;
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage() + ' - Line: ' + ex.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_Error_Occurred));
            returnMessage = Label.MSG_Error_Occurred;
        }
        return returnMessage;
    }
    
    @RemoteAction
    public static Assortment_Detail__c calculateKPI(String assortmentDetail_serialized, String gridField_serialized) {
        Assortment_Detail__c assortmentDetail = (Assortment_Detail__c) JSON.deserialize(assortmentDetail_serialized, SObject.Class);
        List<GridSettingsManager.FieldWrapper> gridFields = (List<GridSettingsManager.FieldWrapper>) JSON.deserialize(gridField_serialized, List<GridSettingsManager.FieldWrapper>.class);
        SavePoint sp = Database.setSavepoint();
        // Check Assortment_Detail__c upsert field security
        String[] assortmentDetailFields = new List<String>();
        for (GridSettingsManager.FieldWrapper fieldWrapper : gridFields) {
            if(fieldWrapper.isInputField && !fieldWrapper.isCalculated && !fieldWrapper.fieldName.contains('.'))
            {
                assortmentDetailFields.add(NegoptimHelper.normalizeAPIName(fieldWrapper.fieldName));
            }
        }
        if(NegoptimHelper.checkUpdatibility(Assortment_Detail__c.SObjectType, assortmentDetailFields)) {
            update assortmentDetail;
        }
        String query = 'SELECT Id, Assortment_BU__c, Category__c, Product__c';
        for (GridSettingsManager.FieldWrapper field : gridFields) {
            query += ',' + field.fieldName;
        }
        query += ' FROM Assortment_Detail__c';
        query += ' WHERE Id = \'' + assortmentDetail.Id + '\'';
        Assortment_Detail__c detail = Database.query(query);
        Database.rollback(sp);
        return detail;
    }
    
    public void validateAssortment() {
        if (String.isNotBlank(this.assortmentToValidateId) && this.assortmentsMap.containsKey(this.assortmentToValidateId)) {
            List<String> assortmentUpdateFields = new List<String> {getFieldName('Status__c')};
            if (checkUpdatibility(Assortment_BU__c.SObjectType, assortmentUpdateFields)) {
                try {
                    this.assortmentsMap.get(this.assortmentToValidateId).Status__c = 'Validated';
                    update this.assortmentsMap.get(this.assortmentToValidateId);
                } catch (DMLException ex) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDMLMessage(0)));
                }
            }
        }
    }
    
    public class CategoryWrapper {
        public Assortment_Detail__c referenceDetail {get; set;}
        public List<ProductWrapper> products {get; set;}
        
        public CategoryWrapper(Assortment_Detail__c referenceDetail) {
            this.referenceDetail = referenceDetail;
            this.products = new List<ProductWrapper>();
        }
    }
    
    public class ProductWrapper {
        public Assortment_detail__c referenceDetail {get; set;}
        public Map<Id, DetailWrapper> detailsMap {get; set;}
        public String keySet {
            get {
                return JSON.serialize(detailsMap.keySet());
            }
            private set;
        }
        
        public ProductWrapper(Assortment_Detail__c referenceDetail) {
            this.referenceDetail = referenceDetail;
            this.detailsMap = new Map<Id, DetailWrapper>();
        }
        
        public void addAssortmentDetail(Assortment_Detail__c detail, List<Orga_BU__c> clusters) {
            this.detailsMap.put(detail.Assortment_BU__c, new DetailWrapper(detail, clusters));
        }
    }
    
    public class DetailWrapper {
        public Assortment_Detail__c detail {get; set;}
        public List<SelectOption> clustersSelectOptions {get; set;}
        
        public DetailWrapper (Assortment_Detail__c detail, List<Orga_BU__c> clusters) {
            this.detail = detail;
            this.clustersSelectOptions = new List<SelectOption>();
            if (detail.Ass_BU_Cluster__c == null) {
                this.clustersSelectOptions.add(new SelectOption('', ''));
            }
            for (Orga_BU__c cluster : clusters) {
                this.clustersSelectOptions.add(new SelectOption(cluster.Id, cluster.Name));
            }
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