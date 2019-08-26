/**
 * Controller used for custom lookup popup pages
 * used for NS and BU till find a solution with standard filters
 * */
public with sharing class CustomLookupController extends NegoptimBaseController {
    
    public Sup_sup_NegoScope__c ns {get; set;} // new NS to create
    public List<Sup_sup_NegoScope__c> results {get; set;} // search results
    public List<Pol_Com_Condition__c> resultsTariff {get; set;} // search results
    public string searchString {get; set;} // search keyword
    public string caseString {get; set;} // search keyword
    public string conditionType {get; set;} // search keyword
    public Id supplierId {get; set;}
    public Id buId {get; set;}
    public Id negoId {get; set;}
    
    public CustomLookupController() {
        ns = new Sup_sup_NegoScope__c();
        // get the current search string
        caseString = System.currentPageReference().getParameters().get('case');
        searchString = System.currentPageReference().getParameters().get('lksrch');
        supplierId = (Id) System.currentPageReference().getParameters().get('suppId');
        buId = (Id) System.currentPageReference().getParameters().get('buId');
        negoId = (Id) System.currentPageReference().getParameters().get('negoId');
        runSearch();
    }    
    // performs the keyword search
    public PageReference search() {
        runSearch();
        return null;
    }    
    // prepare the query and issue the search command
    private void runSearch() {
        // TODO prepare query string for complex serarches & prevent injections
        if(caseString == 'productscope') {
            results = performNSSearch(searchString);
        }
        if(caseString == 'tarifflookup') {
            conditionType = System.currentPageReference().getParameters().get('conditionType');
            resultsTariff = performTariffConditionSearch(searchString);
        }
    }
    // run the search on Negoscope and return the records found.
    private List<Sup_sup_NegoScope__c> performNSSearch(string searchString) {
        // Check fields security 
        String[] supNegoScopeObjFields = new String[] {'Id', 'Name', getFieldName('Status__c'), getFieldName('NS_Code__c'), getFieldName('Supplier__c'), getFieldName('Parent_Nego_Scope__c')};	 
            if(!checkAccessibility(Sup_sup_NegoScope__c.SObjectType, supNegoScopeObjFields)) return null;
        
        String soql = 'SELECT id, Name, Status__c, NS_Code__c, Supplier__r.Name, Parent_Nego_Scope__r.Name, Is_All_Brands__c, Is_All_HE__c, Is_All__c, LastModifiedDate, CreatedDate ';
        soql += 'FROM Sup_sup_NegoScope__c ';
        soql += 'WHERE Supplier__c =  \'' + supplierId +'\'';
        if(String.isNotBlank(searchString)){
            soql += ' AND Name LIKE \'%' + String.escapeSingleQuotes(searchString) + '%\'';
        }
        if(String.isNotBlank(negoId)) {
            soql += ' AND (Parent_Nego_Scope__c = \'' + negoId + '\' OR Id = \'' + negoId +'\')';
        }
        soql += ' LIMIT 25';
        return database.query(soql);
    }
    // run the search on tariff conditions and return the records found.
    private List<Pol_Com_Condition__c> performTariffConditionSearch(string searchString) {
        // Check fields security 
        String[] conditionFields = new String[] {'Id', 'Name', getFieldName('Master_BU__c'), getFieldName('Condition_Mode__c'), getFieldName('Nego_Discount_Type__c')};	 
        if(!checkAccessibility(Pol_Com_Condition__c.SObjectType, conditionFields)) return null;
        
        String soql = 'SELECT id, Name, Master_BU__r.Name, Condition_Mode__c, Index__c, Is_Conditional__c, VAT_Type__c, Comment__c';
        soql += ' FROM Pol_Com_Condition__c';
        soql += ' WHERE (Master_BU__c =  \'' + buId +'\'';
        soql += ' OR Master_BU__c = NULL)';
        if(String.isNotBlank(searchString)){
            soql += ' AND (Name LIKE \'%' + String.escapeSingleQuotes(searchString) +'%\'';
            soql += ' OR Condition_Code__c LIKE \'%' + String.escapeSingleQuotes(searchString) +'%\'';
            soql += ' OR Ext_id__c LIKE \'%' + String.escapeSingleQuotes(searchString) +'%\')';
        }
        if(String.isNotBlank(conditionType)){
            soql += ' AND Nego_Discount_Type__c  = \'' + String.escapeSingleQuotes(conditionType) + '\'';
        }
        soql += ' LIMIT 25';
        List<Pol_Com_Condition__c> results = new List<Pol_Com_Condition__c>();
        for (Pol_Com_Condition__c pm : database.query(soql)) {
            pm.Comment__c = pm.name.replace('\'','\\\'');
            results.add(pm);
        }
        return results;//database.query(soql);
    }
    // used by the visualforce page to send the link to the right dom element
    public string getFormTag() {
        return System.currentPageReference().getParameters().get('frm');
    }
    // used by the visualforce page to send the link to the right dom element for the text box
    public string getTextBox() {
        return System.currentPageReference().getParameters().get('txt');
    }
    // used to clear the lookup search 
    public PageReference clearSearch() {
        searchString = NULL;
        runSearch();
        return null;
    }
}