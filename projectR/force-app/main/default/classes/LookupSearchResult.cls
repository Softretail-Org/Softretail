/**
* Class used to serialize a single Lookup search result item
* The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
*/
public class LookupSearchResult {

    private Id id;
    private String sObjectType;
    private String icon;
    private String title;
    private String subtitle;
    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        String Url;
        List<LookupSearchResult> lstSearch = new List<LookupSearchResult>();
        List<SObject> SearchResult = [SELECT Id,Name FROM Product2];
        for(SObject item : SearchResult) {
            /*for(Schema.DescribeTabSetResult tsr : tabSetDesc) {            
            // Get tab info for the Sales app
                if (tsr.getLabel() == 'Products') {
                 // Get icon information for the first tab
                    Url = tsr.getTabs()[0].getIcons()[0].getUrl();
                    // Display the icon height and width of the first icon
                         }            
                    }*/
            lstSearch.add(new LookupSearchResult(item.Id , item.Id.getSObjectType().getDescribe().getName() ,'https://negoptim-qa-dev-ed.my.salesforce.com/img/icon/t4v35/standard/product_120.png' ,item.Id.getSObjectType().getDescribe().getName(),'hgfd'));
        } 
         return lstSearch;                             
    }
    public LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
    }

    @AuraEnabled
    public Id getId() {
        return id;
    }

    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }

    @AuraEnabled
    public String getIcon() {
        return icon;
    }

    @AuraEnabled
    public String getTitle() {
        return title;
    }

    @AuraEnabled
    public String getSubtitle() {
        return subtitle;
    }
}