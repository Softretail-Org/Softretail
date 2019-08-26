/**
 * @description Custom controller that uses the standard Assortment_BU__c controller
 * 				and includes the Assortment Review logic for the corresponding view.
 *				It provides the following initial functionalities:
 *					1- Display all assortment details for all clients + Filter.
 *					2- Display the assorment details for a single client + Filter.
 *					3- GOAL:
 **/
public with sharing class AssortmentReviewController {
	
	/** Variables Declaration. */
	// CheckBox for table filtering.
	public List<String> checkBoxValues {get; set;}
	public List<SelectOption> checkBoxOptions {get; set;}
	// Current Assortment BU Id. View: Used in order to show/hide Cancel button.
    public String recordId {get; set;}
    // 
    public String lastUdpdateYear {get; set;}
    // Public current record. Assortment Head. Used in the View.
    public Assortment_BU__c currentAssortmentBU {get; set;}
    // List counter, from 1 to 12, used to specify number of months.
    public List<Integer> counter {get; set;}
	//
    private List<Assortment_BU__c> assortmentBUQueryResult;
    private List<Assortment_BU__c> listAssortmentBuToSave;
    public List<clientWrapper> listClientWrapper {get; set;}
	// Interval of months.
    public Integer min {get; set;}
    public Integer max {get; set;}
    public String sSliderField {get; set;}
    
    /** Constructor. */
    public AssortmentReviewController(ApexPages.StandardController stdController) {
    	// Set default value.
    	min = 1;
    	max= 12;
    	sSliderField ='0';
        // Get the current head Assortment Id from the URL.
        recordId = stdController.getId();
        // checkBoxValues creation.
        checkBoxValues = new List<String>();
        // CheckBox Options creation + adding options.
        checkBoxOptions = new List<SelectOption>();
        checkBoxOptions.add(new SelectOption('Active Assortment Only','Active Assortment Only'));
        checkBoxOptions.add(new SelectOption('All Products','All Products'));
        // Create and Fill counter table.
        counter = new List<Integer>();
        // Fill counter.
        for (Integer i = 1; i <= 12; i++) counter.add(i);
        // 
        fetchAssortmentBU();
    }
    
    /**
     * @description Fetch Assortment BU with Details.
     * @return void
     **/
    private void fetchAssortmentBU() {
        // Run query.
        runQuery();
        List<categoryWrapper> listCategorWrapper = new List<categoryWrapper>();
        CategoryWrapper categoryWrapper;
        ClientWrapper clientWrapper;
        AssDetailWrapper assDetailWrapper;
        Map<Id,categoryWrapper> mapCategory = new Map<Id,categoryWrapper>();
        Map<Id,clientWrapper> mapClient = new Map<Id,clientWrapper>();
        //
        for(Assortment_BU__c itemAss : assortmentBUQueryResult) {
            // reset category map on new client 
            mapCategory = new Map<Id,categoryWrapper>();
            // loop on assortement details to get list of category for each client 
            for (Assortment_Detail__c itemAssDetail : itemAss.Assortment_BU_Details__r ) {  
                Decimal dnValue = 0;
                if (itemAssDetail.Ass_BU_Cluster__r.Store_nb__c != null) {
                    if (itemAss.BU_Target__r.store_nb__c != Null && itemAss.BU_Target__r.store_nb__c != 0) {
                        dnValue = math.round(itemAssDetail.Ass_BU_Cluster__r.Store_nb__c/itemAss.BU_Target__r.store_nb__c*100);  
                    }
                }
                if (mapCategory.containsKey(itemAssDetail.Category__r.Id)) {
                    // if same category we fill bu details in a wrapper in it 
                    AssDetailWrapper = new AssDetailWrapper(itemAssDetail.Last_Month_update__c, dnValue, itemAssDetail);                    
                    mapCategory.get(itemAssDetail.Category__r.Id).wAssortmentDetails.add(AssDetailWrapper);
                } else { // adding new category with new bu detail
                    AssDetailWrapper = new AssDetailWrapper(itemAssDetail.Last_Month_update__c, dnValue, itemAssDetail);                    
                    CategoryWrapper = new CategoryWrapper(itemAssDetail.Category__r.Name, itemAss.BU_source__r.Name, new List<assDetailWrapper>{ AssDetailWrapper });
                    mapCategory.put(itemAssDetail.Category__r.Id, CategoryWrapper);
                }
            }
            for (Id catId : mapCategory.keySet()) {
                CategoryWrapper catWrapperObj = mapCategory.get(catId);
                if (mapClient.containsKey(itemAss.BU_Target__r.Id)) {
                    mapClient.get(itemAss.BU_Target__r.Id).wCategories.add(catWrapperObj);
                } else {
                    ClientWrapper = new ClientWrapper(itemAss.BU_Target__r.Name);
                    ClientWrapper.wCategories.add(catWrapperObj);
                    mapClient.put(itemAss.BU_Target__r.Id, clientWrapper);
                }
            }
        }
        listClientWrapper = new List<clientWrapper>();
        for (Id clientId : mapClient.keySet()) {
            if (mapClient.containsKey(clientId)) {
                listClientWrapper.add(mapClient.get(clientId));    
            }
        }
    }
    
    /**
     * @description Run the query + Fill assortmentBUQueryResult (Single/Multiple cases).
     * @return void
     **/
  	private void runQuery() {
        String soql = 'SELECT Id, Name, Assortment_type__c, Product_Status__c, Product_type__c, Ass_BDate__c, Ass_EDate__c, Owner.Name, ';
        soql += ' BU_Target__r.Id, BU_Target__r.Name, BU_Target__r.store_nb__c, ';
        soql += ' BU_source__c, BU_Target__c, Product_Brand__c, BU_source__r.Name, ';
        soql += ' (Select Id, Name, Category__r.Id, Category__r.Name, Brand__c, Client_status__c, Ass_BU_Cluster__r.Store_nb__c, Product__c, Client_Product_Code__c, ';
        soql += ' Ass_BU_Cluster__r.Name, Product__r.Id, Product__r.Name, Product__r.ProductCode, Last_Month_update__c ';
        soql += ' From Assortment_BU_Details__r ORDER BY Category__r.Name, Brand__c, Product__r.Name ASC)';
        soql += ' FROM Assortment_BU__c'; 
  		try {
  			// Execute query.
  			if (recordId != NULL) {
                soql += ' WHERE Id =\'' + String.escapeSingleQuotes(recordId) +'\'';
                currentAssortmentBU = Database.query(soql);
                // Create and add the current Assortment head to the list in the single case.
                assortmentBUQueryResult = new List<Assortment_BU__c>();
                assortmentBUQueryResult.add(currentAssortmentBU);
            } else {
                assortmentBUQueryResult = Database.query(soql);
            }
    	} catch (Exception e) {
      		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops!'));
    	}
  	}
    
    /**
     * @description Save.
     * @return PageReference : Null
     **/
    public PageReference save() {
        List<Assortment_Detail__c> listAssortmentDetailToSave = new List<Assortment_Detail__c>();
        for(clientWrapper itemClient : listClientWrapper) {
            for(assDetailWrapper itemDetail : itemClient.wAssortmentDetails){
                if(itemDetail.buDetail != null){
                    listAssortmentDetailToSave.add(itemDetail.buDetail);
                }
            }
        }
        if (listAssortmentDetailToSave != null && listAssortmentDetailToSave.size() > 0) {
            try {
                upsert listAssortmentDetailToSave;
                // Display success message
                ApexPages.Message successMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.MSG_Successfully_Saved);
                ApexPages.addMessage(successMsg);
            } catch(DmlException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error:' + e.getMessage()));
            }
        }
        return null;
    }
    
    /**
     * @description Set the interval of months.
     * @return PageReference : Null
     **/
    public pagereference setInterval() {
        min = Integer.valueOf(sSliderField.split('-').get(0).trim());
        max = Integer.valueOf(sSliderField.split('-').get(1).trim());
        return null;
    }
    
    /** Wrapper Classes for client, category & assortment detail. */
    public class ClientWrapper {
    	
        public String clientName {get; set;}
        public List<CategoryWrapper> wCategories {get; set;}
        public List<AssDetailWrapper> wAssortmentDetails {
            get {
                List<AssDetailWrapper> allAssortment = new List<AssDetailWrapper>();
                for(CategoryWrapper item : wCategories) {
                    allAssortment.addAll(item.wAssortmentDetails);
                }
                return allAssortment;
            }
            set;
        }
        
        public ClientWrapper(String clientName) {
            this.clientName = clientName;
            this.wCategories = new List<CategoryWrapper>(); 
        }
    }
    
    private class CategoryWrapper {
    	
        public String categoryName {get; set;}
        public String buSourceName {get; set;}
        public List<AssDetailWrapper> wAssortmentDetails {get; set;}
        
        public CategoryWrapper(String categoryName, String buSourceName, List<AssDetailWrapper> wAssortmentDetails) {
            this.categoryName = categoryName;
            this.buSourceName = buSourceName;
            this.wAssortmentDetails = wAssortmentDetails; 
        }
    }
    
    private class AssDetailWrapper {
    	
        public Decimal lastMonthUpdate {get; set;}
        public Decimal dn {get; set;}
        public Assortment_Detail__c buDetail {get; set;}
        
        public AssDetailWrapper(Decimal lastMonthUpdate, Decimal dn, Assortment_Detail__c buDetail) {
            this.lastMonthUpdate = lastMonthUpdate;
            this.dn = dn;
            this.buDetail = buDetail;
        }
    }
}