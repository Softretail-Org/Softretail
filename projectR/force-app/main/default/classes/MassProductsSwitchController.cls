public with sharing class MassProductsSwitchController extends NegoptimBaseController {
    
    // logged in user Id
    private Id loggedUser = UserInfo.getUserId();
    
    // fields to display from settings
    private final String OBJECT_NAME = 'Product2';
    private String staticFields;
    private NegoptimSettings settings;
    public GridSettingsManager gridSettingsManager {get; set;}
    private List<String> dynamicFields;
    
    private Map<Id, ProductWrapper> productWrapperMap = new Map<Id, ProductWrapper>();
    private Map<Id, ProductWrapper> productsMap = new Map<Id, ProductWrapper>();
    private String assortmentDetailsSelectClause {
        get {
            if (String.isBlank(assortmentDetailsSelectClause)) {
                assortmentDetailsSelectClause = 'SELECT Fact_WD_Marketbased__c, Movement_Date__c, Ass_BU_Cluster__c, Ass_BU_Cluster__r.Name, Assortment_BU__r.BU_Target__c, Product__c,';
                assortmentDetailsSelectClause += 'Assortment_BU__r.Id, Assortment_BU__r.Name, Assortment_BU__r.BU_source__r.Name';
            }
            return assortmentDetailsSelectClause;
        }
        set;
        
    }
    private String assortmentDetailsWhereClause {
        get {
            String dateToCompare = Datetime.now().format('yyyy-MM-dd');
            String whereClause = '';
            whereClause += ' WHERE Assortment_BU__r.BU_Target__r.Status__c = \'Open\'';
            whereClause += ' AND Assortment_BU__r.BU_Target__r.Related_Client__c <> NULL';
            whereClause += ' AND Assortment_BU__r.BU_Target__r.Related_Client__r.Status__c = \'Active\'';
            whereClause += ' AND Assortment_BU__r.BU_Target__r.RecordType.DeveloperName = \'Banner\'';
            whereClause += ' AND Assortment_BU__r.Status__c <> \'Closed\'';
            whereClause += ' AND Assortment_BU__r.Assortment__c = \'Deal\'';
            whereClause += ' AND Assortment_BU__r.recordType.developerName = \'Nego\'';
            whereClause += ' AND Assortment_BU__r.Ass_BDate__c <= ' + dateToCompare;
            whereClause += ' AND Assortment_BU__r.Ass_EDate__c >= ' + dateToCompare;
            whereClause += ' AND Version__c = NULL';
            if (String.isNotBlank(this.buSourceFilter)) {
                this.buSourceFilter = String.escapeSingleQuotes(this.buSourceFilter);
                List<String> formats = this.buSourceFilter.remove(' ').split(',');
                whereClause += ' AND Assortment_BU__r.BU_Target__r.Format_Origin__c INCLUDES (\'' + String.join(formats, '\',\'') + '\')';
            }
            return whereClause;
        }
        set;
    }
    private Set<Id> referenceProductsIdSet = new Set<Id>();
    
    // month options map: monthNumber => monthName (+ All history option [key=13])
    public Map<Integer, String> options {get; set;}
    //// public List<Orga_BU__c> orgaBUList {get; set;}
    public List<Assortment_BU__c> assortmentBUList {get; set;}
    // products standard Set Controller
    public ApexPages.StandardSetController productsStdSetCtrl {get; set;}
    // list to group products by category
    public List<List<ProductWrapper>> ProductWrappersByCategoryList {get; set;}
    // filter values
    public String searchTerm {get; set;}
    public String selectedMonths {get; set;}
    public Boolean onlySwitchProduct {get; set;}
    public Boolean onlyRennoProduct {get; set;}
    public List<SelectOption> channels {get; set;} // filter by channels
    public String buSourceFilter {get; set;}
    // result ordering
    public String orderField {get; set;}
    public String orderDirection {get; set;}
    // switch product selection
    public Id referenceProductId {get; set;}
    public Id IntroducedProductId {get; set;}
    // pagination fields
    public Integer pageSize {get; set;}
    public Integer noOfRecords {get; set;}
    public List<SelectOption> pageSizes {get; set;}
    // excel page fields
    public String xmlheader {
        get {
            return '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        }
    }
    // excel xml header
    public Component.Apex.OutputText getXmlHeaderContent() {
        Component.Apex.OutputText objText = new Component.Apex.OutputText(escape = false);
        objText.value = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>'; 
        return objText;
    }
    public List<String> listOfMonthSelected {get; set;} // to display selected month in Excel:    
    
    /**
     * @description constructor
	*/
    public MassProductsSwitchController(Apexpages.StandardController stdCtrl) {
        // initialize the months filter options
        options = new Map<Integer, String> {
			13 => Label.All_History,
			1 => Label.Abbreviation_January,
			2 => Label.Abbreviation_February,
			3 => Label.Abbreviation_March,
			4 => Label.Abbreviation_April,
			5 => Label.Abbreviation_May,
			6 => Label.Abbreviation_June,
			7 => Label.Abbreviation_July,
			8 => Label.Abbreviation_August,
			9 => Label.Abbreviation_September,
			10 => Label.Abbreviation_October,
			11 => Label.Abbreviation_November,
			12 => Label.Abbreviation_December
        };
        this.onlySwitchProduct = true;
        this.onlyRennoProduct = false;
        this.selectedMonths = String.valueOf(Date.today().month());
        this.buSourceFilter = 'none';
        this.orderField = 'Name';
        this.orderDirection = 'ASC';
        // BU Formats for channels
        this.channels = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Orga_BU__c.Format_Origin__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry pickListVal : ple){
            this.channels.add(new SelectOption(pickListVal.value, pickListVal.label));
        }
        this.channels.add(new SelectOption(Label.LBL_All, Label.LBL_All));
        this.pageSize = 10;
        pageSizes = new List<SelectOption>();
        pageSizes.add(new SelectOption('10', '10'));
        pageSizes.add(new SelectOption('25', '25'));
        pageSizes.add(new SelectOption('50', '50'));
        pageSizes.add(new SelectOption('100', '100'));
        this.ProductWrappersByCategoryList = new List<List<ProductWrapper>>();
        
        // fill static fields
        this.staticFields = 'Reference_Product__c,Reference_Product__r.Name,Reference_Product__r.Product_EAN__c,Reference_Product__r.Retail_Price_Reco__c,';
        this.staticFields += 'Reference_Product__r.Market_Introduction_Date__c,Reference_Product__r.Market_End_Of_Life_Date__c,';
        this.staticFields += 'Reference_Product__r.Average_Weekly_Sales_Hyper__c,Reference_Product__r.Average_Weekly_Sales_Super__c,';
        this.staticFields += 'Retail_Price_Reco__c,Average_Weekly_Sales_Hyper__c,Average_Weekly_Sales_Super__c,Category__c,Category__r.Path__c,Category__r.Name';
        // load gloabal settings
        settings = GlobalSettingsManager.loadGlobalSettings();
        // get fields from Grid Settings
        String metadataDeveloperName = settings.productSwitchGridLayout;
        this.gridSettingsManager = new GridSettingsManager(OBJECT_NAME, this.staticFields, metadataDeveloperName);
        // make dynamic fields values lower case
        dynamicFields = new List<String>();
        for (GridSettingsManager.FieldWrapper field : this.gridSettingsManager.GRID_FIELDS)
            dynamicFields.add(field.fieldName.toLowerCase());
        /*this.gridSettingsManager.DYNAMIC_FIELDS.clear();
        this.gridSettingsManager.DYNAMIC_FIELDS.addAll(dynamicFields);*/
        //
        for (String errorMessage : this.gridSettingsManager.ERRORS) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
        // get products on load
        this.searchProducts();
    }
    
    /**
     * @description go to first page of the products standard set controller
	*/
    public void first() {
        productsStdSetCtrl.first();
        this.setupData();
    }
    
    /**
     * @description go to the next page of the products standard set controller
	*/
    public void next() {
        productsStdSetCtrl.next();
        this.setupData();
    }
    
    /**
     * @description go to the previous page of the products standard set controller
	*/
    public void previous () {
        productsStdSetCtrl.previous();
        this.setupData();
    }
    
    /**
     * @description go to the last page of the products standard set controller
	*/
    public void last() {
        productsStdSetCtrl.last();
        this.setupData();
    }
    
    /**
     * @description
	*/
    public void refreshPageSize() {
        this.productsStdSetCtrl.setPageSize(this.pageSize);
        this.setupData();
    }
    
    /**
     * @description builds a query based on the filter criteria specified on page
     * fetches assortment details of the introduced products by inner query
	*/
    private String buildQuery() {
        selectedMonths = String.isBlank(selectedMonths) ? String.valueOf(Date.today().month()) : selectedMonths;
        this.selectedMonths = String.escapeSingleQuotes(this.selectedMonths).remove(' ');
        // add assortment details inner query
        List<String> innerQueries = new List<String>();
        String innerQuery = assortmentDetailsSelectClause + ' FROM Assortment_BU_Details__r';
        innerQuery += ' WHERE Client_Status__c <> NULL';
        innerQuery += ' ORDER BY Assortment_BU__r.Name';
        innerQueries.add(innerQuery);
        // add where clause
        List<String> conditions = new List<String>();
        conditions.add('category__c <> NULL');
        // apply search term
        if (String.isNotBlank(this.searchTerm)) {
            String searchName = '\'%' + String.escapeSingleQuotes(this.searchTerm) + '%\'';
            // ONLY apply searchTerm on searchable Fields displayed as columns in grid
            List<String> searchableFields = new List<String> {'Name', 'Product_EAN__c', 'ProductCode', 'ProductCode2__c'};
                List<String> searchConditions = new List<String>();
            for (String field : searchableFields) {
                if (dynamicFields.contains(field.toLowerCase())) {
                    searchConditions.add(field + ' LIKE ' + searchName);
                }
            }
            searchConditions.add('Reference_Product__r.Name LIKE ' + searchName);
            searchConditions.add('Reference_Product__r.Product_EAN__c LIKE ' + searchName);
            searchConditions.add('Category__r.Name LIKE ' + searchName);
            searchConditions.add('Category__r.Elt_Code__c LIKE ' + searchName);
            conditions.add('(' + String.join(searchConditions, ' OR ') + ')');
        }
        conditions.add('CALENDAR_MONTH(Market_Introduction_Date__c) In (' + selectedMonths + ')');
        conditions.add('CALENDAR_YEAR(Market_Introduction_Date__c) = ' + Date.today().year());
        conditions.add('isActive = TRUE');
        // only switch
        if (this.onlySwitchProduct)
            conditions.add('isSwitch__c = TRUE ');
        // only renno
        else if (this.onlyRennoProduct)
            conditions.add('isRenovation__c = TRUE ');
        // add Order By
        String orderBy = 'Category__c ASC';
        if (orderDirection.equals('ASC') || orderDirection.equals('DESC'))
            orderBy += ', ' + orderField + ' ' + orderDirection;
        
        String query = this.gridSettingsManager.buildQuery(innerQueries, conditions, orderBy);
        return query;
    }
    
    /**
     * @description change order direction between DESC and ASC
	*/
    public void toggleOrderDirection() {
        if (orderDirection.equals('ASC')) orderDirection = 'DESC';
        else orderDirection = 'ASC';
        searchProducts();        
    }
    
    /**
     * @description loads products 
	*/
    public void searchProducts() {
        if(this.gridSettingsManager.ERRORS.isEmpty()) {
            String dateToCompare = Datetime.now().format('yyyy-MM-dd');
            String assortmentQuery = '';
            assortmentQuery += ' SELECT Id, Name, BU_Source__r.Name';
            assortmentQuery += ' FROM Assortment_BU__c';
            assortmentQuery += ' WHERE BU_Target__r.Status__c = \'Open\'';
            assortmentQuery += ' AND BU_Target__r.Related_Client__c <> NULL';
            assortmentQuery += ' AND BU_Target__r.Related_Client__r.Status__c = \'Active\'';
            assortmentQuery += ' AND BU_Target__r.RecordType.DeveloperName = \'Banner\'';
            assortmentQuery += ' AND Status__c <> \'Closed\'';
            assortmentQuery += ' AND Assortment__c = \'Deal\'';
            assortmentQuery += ' AND recordType.developerName = \'Nego\'';
            assortmentQuery += ' AND Ass_BDate__c <= ' + dateToCompare;
            assortmentQuery += ' AND Ass_EDate__c >= ' + dateToCompare;
            if (String.isNotBlank(this.buSourceFilter)) {
                this.buSourceFilter = String.escapeSingleQuotes(this.buSourceFilter);
                List<String> formats = this.buSourceFilter.remove(' ').split(',');
                assortmentQuery += ' AND BU_Target__r.Format_Origin__c INCLUDES (\'' + String.join(formats, '\',\'') + '\')';
            }
            assortmentQuery += ' Order BY Name';
            this.assortmentBUList = Database.query(assortmentQuery);
            
            String query = this.buildQuery();
            productsStdSetCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            productsStdSetCtrl.setPageSize(this.pageSize);
            this.noOfRecords = productsStdSetCtrl.getResultSize();
            this.setupData();
        }
    }
    
    /**
     * @description loops on the current page of records in the standard set controller and creates 
     * a ProductWrapper instance for each product while linking each product to its convenient assortment details
	*/
    private void setupData() {
       /// this.assortmentBUList.clear();
        Set<Id> referenceProductsIdSet = new Set<Id>();
        Map<Id, List<Assortment_Detail__c>> productDetailsMap = new Map<Id, List<Assortment_Detail__c>>();
        Map<Id, List<ProductWrapper>> categoryToProductWrapperMap = new Map<Id, List<ProductWrapper>>();
        
        productWrapperMap.clear();
        ProductWrappersByCategoryList.clear();
        
        List<Product2> productsList = (List<Product2>) productsStdSetCtrl.getRecords();
        // get Set<String> of EltCode that are LvL1 of all products in the page using the path
        Set<String> lvl1EltCodeCategorySet = new Set<String>();   					
        for (Product2 item : productsList) {
            lvl1EltCodeCategorySet.add(item.Category__r.Path__c.split('\\|')[1]);	
        }
        // get List<Orga_HE__c> of categories
        List<Orga_HE__c> lvl1CategoryList = [SELECT Id, Name, Path__c FROM Orga_HE__c WHERE Elt_Code__c IN :lvl1EltCodeCategorySet];
        for (Product2 item : productsList) {
            ProductWrapper productWrapper;
            if (this.productsMap.containsKey(item.Id)) {
                productWrapper = this.productsMap.get(item.Id);
            } else {
                // finding product level category
                Orga_HE__c category;
                for (Orga_HE__c cat : lvl1CategoryList) {
                    if (item.Category__r.Path__c.startsWith(cat.Path__c)) {
                        category = cat;
                        break;
                    }
                }
                Product2 product = item.clone(true, true, true, true);
                // add reference Product Id to referenceProductsIdSet
                if (product.Reference_Product__c != null)
                    referenceProductsIdSet.add(product.Reference_Product__c);
                // create an instance of the reference product
                Product2 referenceProduct = product.Reference_Product__r;
                // user can change reference product only if it does not belong to any assotrment detail with the client status field filled.
                Boolean isUpdatable = true;
                for (Assortment_Detail__c item1 : product.Assortment_BU_Details__r) {
                    isUpdatable = false;
                    break;
                }
                productWrapper = new ProductWrapper(referenceProduct, product, category,isUpdatable);
                this.productsMap.put(product.Id, productWrapper);
            }
            // grouping by level 1 categories
            productWrapperMap.put(item.Id, productWrapper);
            if (!categoryToProductWrapperMap.containsKey(productWrapper.category.Id))
                categoryToProductWrapperMap.put(productWrapper.category.Id, new List<ProductWrapper>());
            categoryToProductWrapperMap.get(productWrapper.category.Id).add(productWrapper);
        }
        // query the details of the reference products
        String query = assortmentDetailsSelectClause;
        query += ' FROM Assortment_Detail__c';
        query +=  assortmentDetailsWhereClause;
        query += ' AND Product__c IN (\'' + String.join(new List<Id>(referenceProductsIdSet), '\',\'') + '\')';
        query += ' ORDER BY Assortment_BU__r.Name';
        // assign reference product assortment details
        
        for (Assortment_Detail__c detail : Database.query(query)) {
            if (!productDetailsMap.containsKey(detail.Product__c))
                productDetailsMap.put(detail.Product__c, new List<Assortment_Detail__c>());
            productDetailsMap.get(detail.Product__c).add(detail);
        }
        for (ProductWrapper productWrapper : productWrapperMap.values()) {
            List<Assortment_Detail__c> detailsList = productWrapper.referenceProduct != null 
                && productDetailsMap.containsKey(productWrapper.referenceProduct.Id) ? productDetailsMap.get(productWrapper.referenceProduct.Id) : new List<Assortment_Detail__c>();
            if (!this.productsMap.get(productWrapper.introducedProduct.Id).detailsMap.isEmpty())
                detailsList = this.productsMap.get(productWrapper.introducedProduct.Id).detailsMap.values();
            fillDetailsMap(productWrapper, detailsList);
        }
        ProductWrappersByCategoryList.addAll(categoryToProductWrapperMap.values());
    }
    
    public boolean getNoData() {
        return productsStdSetCtrl.getRecords().isEmpty();
    }
    
    /**
     * @description switches or assignes a reference product and auto assigns the fields:
     * and also reloads the assortment details of the newly selected reference product
     * note: the newly selected reference product isn't accepted unless it isn't being refrenced by any other product
	*/
    public void switchProduct() {
        ProductWrapper productWrapper = productsMap.get(this.introducedProductId);
        Product2 introducedProduct = productWrapper.introducedProduct;
        Id newReferenceProductId = introducedProduct.Reference_Product__c;
        // if blank assign loaded value
        if (String.isBlank(newReferenceProductId)) {
            introducedProduct.Retail_Price_Reco__c = productWrapper.retailPriceReco;
            introducedProduct.Average_Weekly_Sales_Hyper__c = productWrapper.avgWeeklySalsHyper;
            introducedProduct.Average_Weekly_Sales_Super__c = productWrapper.avgWeaklySalesSuper;
            productWrapper.ReferenceProduct = null;
            referenceProductsIdSet.remove(referenceProductId);
            return;
        }
        // if the old reference product and the new reference product are the same
        if (newReferenceProductId == this.referenceProductId) return;
        
        // if selected reference Product is already a reference
        if (referenceProductsIdSet.contains(newReferenceProductId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'already a reference'));
            return;
        }
        
        // get the reference product by query
        String query = 'SELECT Name, Product_EAN__c, Retail_Price_Reco__c, Market_Introduction_Date__c,';
        query += ' Market_End_Of_Life_Date__c, Average_Weekly_Sales_Hyper__c, Average_Weekly_Sales_Super__c,';
        query += ' (' + assortmentDetailsSelectClause;
        query += ' FROM Assortment_BU_Details__r';
        query += assortmentDetailsWhereClause + ' AND Client_Status__c <> Null';
        query += ' ORDER BY Assortment_BU__r.BU_Target__r.Related_Client__r.Name, Assortment_BU__r.BU_Target__r.Name )';
        query += ' FROM Product2';
        query += ' WHERE Id = \'' + newReferenceProductId + '\' AND Product_Reference_Type__c = null';
        List<Product2> referenceProducts = Database.query(query);
        
        if (!referenceProducts.isEmpty()) {
            Product2 referenceProduct = referenceProducts[0];
            // add the reference product id to referenceProductsIdSet
            referenceProductsIdSet.add(referenceProduct.Id);
            // remove the olf reference product id from referenceProductsIdSet
            referenceProductsIdSet.remove(this.referenceProductId);
            // auto fill fields if null and assortment information
            productWrapper.ReferenceProduct = referenceProduct;
            introducedProduct.Retail_Price_Reco__c = introducedProduct.Retail_Price_Reco__c == null ?
                referenceProduct.Retail_Price_Reco__c : introducedProduct.Retail_Price_Reco__c;
            introducedProduct.Average_Weekly_Sales_Hyper__c = introducedProduct.Average_Weekly_Sales_Hyper__c == null ?
                referenceProduct.Average_Weekly_Sales_Hyper__c : introducedProduct.Average_Weekly_Sales_Hyper__c;
            introducedProduct.Average_Weekly_Sales_Super__c = introducedProduct.Average_Weekly_Sales_Super__c == null ?
                referenceProduct.Average_Weekly_Sales_Super__c : introducedProduct.Average_Weekly_Sales_Super__c;
            fillDetailsMap(productWrapper, referenceProduct.Assortment_BU_Details__r);
        }
    }
    
    private void fillDetailsMap(ProductWrapper productWrapper, List<Assortment_Detail__c> referenceProductDetails) {
        productWrapper.detailsMap.clear();
        for (Assortment_Detail__c detail : referenceProductDetails) {
            if (detail != null) {
                productWrapper.detailsMap.put(detail.Assortment_BU__c, detail);
                productWrapper.switchStatusMap.put(detail.Assortment_BU__c, false);
            }
        }
        for (Assortment_Detail__c detail : productWrapper.introducedProduct.Assortment_BU_Details__r) {
            if (!productWrapper.detailsMap.containsKey(detail.Assortment_BU__c)) {
                productWrapper.detailsMap.put(detail.Assortment_BU__c, null);
                productWrapper.switchStatusMap.put(detail.Assortment_BU__c, true);
            }
        }
    }
    
    public void save() {
        List<Product2> toUpdate = new List<Product2>();
        for (ProductWrapper pw : productsMap.values()) {
            toUpdate.add(pw.introducedProduct);   
        }
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM , Label.MSG_Successfully_Saved));
            } catch (Exception ex) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error'));
            }
        }
    }
    
    public PageReference downloadExcel() {
        try {
            PageReference pageRef = Page.MassProductsSwitchExcel;
            listOfMonthSelected = selectedMonths.split(',');
            pageRef.setRedirect(false);
            this.pageSize = this.noOfRecords;
            this.searchProducts();
            return pageRef;
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + ex.getMessage()));
            return null;
        }
    }
        
    public class ProductWrapper {
        public Product2 referenceProduct {get; set;}
        public Product2 introducedProduct {get; set;}
        public Orga_HE__c category {get; set;}
        public Map<Id, Assortment_Detail__c> detailsMap {get; set;}
        public Map<Id, Boolean> switchStatusMap {get; set;}
        public Boolean isUpdatable {get; set;}
        
        private Decimal retailPriceReco;
        private Decimal avgWeeklySalsHyper;
        private Decimal avgWeaklySalesSuper;
        
        public ProductWrapper(Product2 referenceProduct, Product2 introducedProduct,Orga_HE__c category, Boolean isUpdatable) {
            this.referenceProduct = referenceProduct;
            this.introducedProduct = introducedProduct;
            this.category = category;
            this.isUpdatable = isUpdatable;
            this.detailsMap = new Map<Id, Assortment_Detail__c>();
            this.switchStatusMap = new Map<Id, Boolean>();
            
            this.retailPriceReco = this.introducedProduct.Retail_Price_Reco__c;
            this.avgWeeklySalsHyper = this.introducedProduct.Average_Weekly_Sales_Hyper__c;
            this.avgWeaklySalesSuper = this.introducedProduct.Average_Weekly_Sales_Super__c;
        }
        
        public String getDetailsMapKeySet() {
            return JSON.serialize(detailsMap.keySet());
        }
    }
}