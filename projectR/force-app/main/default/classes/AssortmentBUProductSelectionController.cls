/**
 * @author ULiT
 * @date 21/09/2018
 * @description product selection page to generate Assortment Details for an instance of Assortment_BU
 * */
public with sharing class AssortmentBUProductSelectionController extends NegoptimBaseController {
    
    private Assortment_BU__c instance;
    private List<ProductWrapper> productWrapperList;
    private Map<Id, Product2> productsMap;
    
    private Map<Id, Orga_HE__c> allElementsMap;
    private Map<Id, Set<Id>> elementsTree;
    
    /**
     * @description the last executed query to fetch the products
     */
    private String executedQuery;
    private Set<Id> existingProductsInAssortment;
    private Set<Id> selectedProductsIdSet;
    
    public String searchString {get; set;}
    public LookupValue brandLookup {get; set;}
    public LookupValue categoryLookup {get; set;}
    public ApexPages.StandardSetController productStdSetCtrl {get; set;}
    public Integer pageSize {get; set;}
    public List<SelectOption> pageSizes {get; set;}
    public Integer noOfRecords {get; set;}
    
    /**
     * @description constructor
     * */
    public AssortmentBUProductSelectionController(ApexPages.StandardController stdCtrl) {
        List<String> fields =new List<String> {'Orga_HE__c', 'Orga_HE__r.Level__c', 'Orga_HE__r.Elt_Code__c', 'Orga_HE__r.Path__c', 'BU_source__r.Related_Client__c'}; 
        if (!Test.isRunningTest())
            stdCtrl.addFields(fields);
        this.instance = (Assortment_BU__c) stdCtrl.getRecord();
        this.productsMap = new Map<Id, Product2>();
        String pathToSearch = this.instance.Orga_HE__r.Level__c == 0 ? this.instance.Orga_HE__r.Elt_Code__c + '|' : '|' + this.instance.Orga_HE__r.Elt_Code__c + '|';
        this.allElementsMap = new Map<Id, Orga_HE__c>([SELECT Parent_Element__c
                                                       FROM Orga_HE__c
                                                       WHERE Path__c LIKE :String.format('%{0}%', new List<String>{pathToSearch})
                                                       OR Path__c LIKE :this.instance.Orga_HE__r.Path__c
                                                       ORDER BY Level__c DESC
                                                       LIMIT 1000]);
        this.elementsTree = new Map<Id, Set<Id>>();
        for (Orga_HE__c item : this.allElementsMap.values()) {
            if (!this.elementsTree.containsKey(item.Id))
                this.elementsTree.put(item.Id, new Set<Id>());
            if (!this.elementsTree.containsKey(item.Parent_Element__c))
                this.elementsTree.put(item.Parent_Element__c, new Set<Id>());    
            this.elementsTree.get(item.Parent_Element__c).add(item.Id);
        }
        // Load existing assortments products in a set
        this.existingProductsInAssortment = new Set<Id>();
        this.selectedProductsIdSet = new Set<Id>();
        for (Assortment_Detail__c item : [SELECT Product__c FROM Assortment_Detail__c WHERE Assortment_BU__c = :this.instance.Id]) {
            this.existingProductsInAssortment.add(item.Product__c);
            this.selectedProductsIdSet.add(item.Product__c);
        }
        this.productWrapperList = new List<ProductWrapper>();
        this.pageSize = 10;
        this.pageSizes = new List<SelectOption>();
        this.pageSizes.add(new SelectOption('5', '5'));
        this.pageSizes.add(new SelectOption('10', '10'));
        this.pageSizes.add(new SelectOption('25', '25'));
        this.pageSizes.add(new SelectOption('50', '50'));
        this.pageSizes.add(new SelectOption('75', '75'));
        this.pageSizes.add(new SelectOption('100', '100'));
        this.resetFilter();
    }
    
    public List<ProductWrapper> getProductRecords() {
        productWrapperList = new List<ProductWrapper>();
        // map product Id -> contentId
        Map<Id, Id> productContentDocumentsMap = new Map<Id, Id>();
        for (Product2 p : (List<Product2>) productStdSetCtrl.getRecords()) {
            ProductWrapper tempWrapper = new ProductWrapper(p, this.selectedProductsIdSet.contains(p.Id));
            if (p.AttachedContentDocuments != null && !p.AttachedContentDocuments.isEmpty()) {
                productContentDocumentsMap.put(p.Id, p.AttachedContentDocuments[0].ContentDocumentId);
            }
            productsMap.put(p.Id, p);
            productWrapperList.add(tempWrapper);
        }
        Map<Id, ContentDocument> contentDocuments = new Map<Id, ContentDocument>([SELECT LatestPublishedVersionId
                                                                                  FROM ContentDocument
                                                                                  WHERE Id IN :productContentDocumentsMap.values()]);
        for (ProductWrapper item : productWrapperList) {
            if (productContentDocumentsMap.containsKey(item.product.Id)) {
                item.productImageId = contentDocuments.get(productContentDocumentsMap.get(item.product.Id)).LatestPublishedVersionId;
                item.isFile = true;
            }
        }
        return productWrapperList;
    }
    
    private void processSelections() {
        for (ProductWrapper pw : this.productWrapperList) {
            if (pw.isSelected) {
                this.selectedProductsIdSet.add(pw.product.Id);
            } else if (this.selectedProductsIdSet.contains(pw.product.Id)) {
                this.selectedProductsIdSet.remove(pw.product.Id);
            }
        }
    }
    
    // pagination
    public PageReference first() {
        this.processSelections();
        this.productStdSetCtrl.first();
        return null;
    }
    
    public PageReference previous() {
        this.processSelections();
        this.productStdSetCtrl.previous();
        return null;
    }
    
    public PageReference next() {
        this.processSelections();
        this.productStdSetCtrl.next();
        return null; 
    }
    
    public PageReference last() {
        this.processSelections();
        this.productStdSetCtrl.last();
        return null;
    }
    
    public PageReference refreshPageSize() {
        this.processSelections();
        productStdSetCtrl.setPageSize(pageSize);
        return null;
    }
    
    public PageReference searchProducts() {
        this.processSelections();
        String query = this.buildQuery();
        this.productStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        this.productStdSetCtrl.setPageSize(this.pageSize);
        this.noOfRecords = productStdSetCtrl.getResultSize();
        this.executedQuery = query;
        return null;
    }
    
    public PageReference resetFilter() {
        this.processSelections();
        searchString = '';
        this.brandLookup = new LookupValue(true);
        this.categoryLookup = new LookupValue(true);
        return this.searchProducts();
    }
    
    private String buildQuery() {
        String query = 'SELECT Name, Product_EAN__c, Brand__c, Category__c, Category__r.Parent_Element__c,';
        // Attachment inner SELECT
        query += ' (SELECT Id FROM Attachments';
        query += ' WHERE ContentType IN (\'image/gif\', \'image/jpeg\', \'image/png\', \'image/jpg\')';
        query += ' ORDER BY CreatedDate DESC LIMIT 1),';
        // AttachedContentDocuments inner SELECT
        query += ' (SELECT ContentDocumentId FROM AttachedContentDocuments';
        query += ' WHERE FileType IN (\'gif\', \'jpeg\', \'png\', \'jpg\')';
        query += ' ORDER BY CreatedDate DESC LIMIT 1)';
        query += ' FROM Product2';
        
        String whereClause = '';
        // TODO: filter by owner?
        ////if (String.isNotBlank(instance.BU_source__r.Related_Client__c))
            ////whereClause = buildWhere(whereClause, 'Product_MasterSupplier__c = \'' + String.escapeSingleQuotes(instance.BU_source__r.Related_Client__c) + '\'');
        
        // search string
        if (String.isNotBlank(searchString)) {
            String condition = ' ((Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')';
            condition += ' OR (ProductCode LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\')';
            condition += ' OR (Product_EAN__c LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'))';
            whereClause = buildWhere(whereClause, condition);
        }
        
        // category filter
        if (String.isNotBlank(categoryLookup.value)) {
            Set<Id> selectedIds = new Set<Id>();
            for (String str : String.escapeSingleQuotes(categoryLookup.value).split(',')) {
                selectedIds.add(Id.valueOf(str));
            }
            String condition = 'Category__c IN (\'' + String.join(new List<Id>(this.getChildElements(selectedIds)), '\',\'') + '\')';
            whereClause = buildWhere(whereClause, condition);
        } else if (String.isNotBlank(categoryLookup.label)) {
            String condition = 'Category__c IN (\'' + String.join(new List<Id>(this.getChildElements(categoryLookup.label)), '\',\'') + '\')';
            whereClause = buildWhere(whereClause,  condition);
        } else {
            String condition = 'Category__c IN (\'' + String.join(new List<Id>(this.allElementsMap.keySet()), '\',\'') + '\')';
            whereClause = buildWhere(whereClause, condition);
        }
        
        // brand filter
        if (String.isNotBlank(brandLookup.value)) {
            List<String> selectedBrandsIds = String.escapeSingleQuotes(brandLookup.value).split(',');
            whereClause = buildWhere(whereClause, ' Brand__c IN (\'' + String.join(selectedBrandsIds, '\',\'') +'\')');
        } else if (String.isNotBlank(brandLookup.label)) {
            String condition =  '(Brand__r.Name LIKE \'%' + String.escapeSingleQuotes(brandLookup.label) + '%\'' ;
            condition += ' OR Brand__r.Brand_code__c LIKE \'%' + String.escapeSingleQuotes(brandLookup.label) + '%\')';
            whereClause = buildWhere(whereClause, condition);
        }
        query += whereClause;
        query += ' ORDER BY Name';
        query += ' LIMIT 10000';
        return query;
    }
    
    private String buildWhere(String whereClause, String condition) {
        return String.isEmpty(whereClause) ? ' WHERE ' + condition : whereClause + ' and ' + condition;
    }
    
    private Set<Id> getChildElements(String parentElement) {
        String str =  '%' + String.escapeSingleQuotes(parentElement) + '%';
        return this.getChildElements(new Map<Id, Orga_HE__c>([SELECT Id
                                                              FROM Orga_HE__c
                                                              WHERE Name LIKE :str
                                                              OR Elt_Code__c LIKE :str
                                                              OR Parent_Element__r.Name LIKE :str
                                                              OR Parent_Element__r.Elt_Code__c LIKE :str]).keySet());
    }
    // Recursive method
    private Set<Id> getChildElements(Set<Id> parentElementsIdSet) {
        Set<Id> childElementsIds = new Set<Id>();
        for (Id item : parentElementsIdSet) {
            childElementsIds.add(item);
            if (this.elementsTree.containsKey(item))
                childElementsIds.addAll(this.getChildElements(this.elementsTree.get(item)));
        }
        return childElementsIds;
    }
    
    private Boolean inspectDMLResults(List<Database.UpsertResult> results, List<sObject> records) {
        Boolean success = true;
        for (sObject record : records) {
            Database.UpsertResult result = results[records.indexOf(record)];
            if (!result.isSuccess()) {
                success = false;
                String errorMessage = record + ' :';
                Database.Error[] errs = result.getErrors();
                for (Database.Error err : errs) {
                    errorMessage += err.getFields() + ':' +err.getStatusCode() + ' - ' + err.getMessage() + '\n';
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            }
        }
        if (success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved));
        }
        return success;
    }
    
    /**
     * @description saves an Assortment_Detail__c record for each record fetched in the last executed product query
     */
    public PageReference importAll() {
        //this procedure could reach a LIMIT if the query fetched more that 1000 records
        List<String> AssortmentDetailFields = new List<String> {
            Assortment_Detail__c.fields.Assortment_BU__c.getDescribe().getName(),
            Assortment_Detail__c.fields.Product__c.getDescribe().getName()
        };
        if (checkCreatibility(Assortment_Detail__c.SObjectType, AssortmentDetailFields)) {
            List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();
            for (Product2 item : Database.query(executedQuery)) {
                if (!existingProductsInAssortment.contains(item.Id)) {
                    assortmentDetails.add(new Assortment_Detail__c(Assortment_BU__c = this.instance.Id, 
                                                                   Product__c = item.Id));
                }
            }
            List<Database.UpsertResult> results = Database.upsert(assortmentDetails, false);
            if (this.inspectDMLResults(results, assortmentDetails)) {
                for (Assortment_Detail__c item : assortmentDetails) {
                    this.existingProductsInAssortment.add(item.Product__c);
                    this.selectedProductsIdSet.add(item.Product__c);
                }
            }
        }
        return null;
    }
    /**
     * @description saves an Assortment_Detail__c record for selected products and deletes any that are not selected
     */
    public PageReference importSelected() {
        this.processSelections();
        List<String> AssortmentDetailFields = new List<String> {
            Assortment_Detail__c.fields.Assortment_BU__c.getDescribe().getName(),
            Assortment_Detail__c.fields.Product__c.getDescribe().getName()
        };
        if (checkCreatibility(Assortment_Detail__c.SObjectType, AssortmentDetailFields)) {
            List<Assortment_Detail__c> assortmentDetails = new List<Assortment_Detail__c>();
            for (Id key : this.selectedProductsIdSet) {
                if (!existingProductsInAssortment.contains(key)) {
                    assortmentDetails.add(new Assortment_Detail__c(Assortment_BU__c = this.instance.Id, 
                                                                   Product__c = key, Category__c = productsMap.get(key).Category__c));
                }
            }
            List<Database.UpsertResult> results = Database.upsert(assortmentDetails, false);
            if (this.inspectDMLResults(results, assortmentDetails)) {
                for (Assortment_Detail__c item : assortmentDetails) {
                    this.existingProductsInAssortment.add(item.Product__c);
                    this.selectedProductsIdSet.add(item.Product__c);
                }
            }
        }
        if (checkDeletibility(Assortment_Detail__c.SObjectType)) {
            Set<Id> toDeleteProductDetailsIdSet = new Set<Id>();
            for (Id key : this.existingProductsInAssortment) {
                if (!this.selectedProductsIdSet.contains(key)) {
                    toDeleteProductDetailsIdSet.add(key);
                }
            }
            delete [SELECT Id FROM Assortment_Detail__c
                    WHERE Assortment_BU__c = :this.instance.Id
                    AND Product__c IN :toDeleteProductDetailsIdSet];
            for (Id key : toDeleteProductDetailsIdSet) {
                this.existingProductsInAssortment.remove(key);
                this.selectedProductsIdSet.remove(key);
            }
            
        }
        return null;
    }
    
    public class ProductWrapper {
        public Product2 product {get; set;}
        public Boolean isSelected {get; set;}
        public Id productImageId {get; set;}
        public Boolean isFile {get; set;}
        
        public ProductWrapper(Product2 product, Boolean isSelected ) {
            this.product = product;
            this.isSelected = isSelected;
            this.productImageId = this.product.attachments.isEmpty() ? null : this.product.attachments[0].id;
            this.isFile = false;
        }
    }
}