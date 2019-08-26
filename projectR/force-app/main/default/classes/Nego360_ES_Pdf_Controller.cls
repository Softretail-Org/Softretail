/**
 * Executive Summary for Simulation Contract
 * used for pdf and email because we got error
 * on generation of pdf when using same controller,
 * it seems rendered the same page that contains
 * non valid components for getContentAsPDF()
 * */
public with sharing class Nego360_ES_Pdf_Controller extends NegoptimBaseController {
    
    public Nego360_ExecutiveSummary_Controller ctrlr {get; set;}
    
    ////public String documentURL = System.URL.getSalesforceBaseURL().toExternalForm() + '/servlet/servlet.FileDownload?file=';
    public String documentURL = System.URL.getSalesforceBaseURL().toExternalForm() + '/servlet/servlet.ImageServer?id=';
    ////public String assetsURL = System.URL.getSalesforceBaseURL().toExternalForm() + NegoptimHelper.GetResourceURL('Assets') + '/assets/img/';
    List<Document> imagesDocumentList;
    public String imgLeft {
        get {
            return documentURL + getImageId('left');
        }
        set;
    }
    public String imgRight {
        get {
            return documentURL + getImageId('right') + '&oid=' + UserInfo.getOrganizationId();
            // return assetsURL + 'right-arrow.png';
        }
        set;
    }
    public String imgUp {
        get {
            return documentURL + getImageId('up') + '&oid=' + UserInfo.getOrganizationId();
            // return assetsURL + 'up-arrow.png';
        }
        set;
    }
    public String imgDown {
        get {
            return documentURL + getImageId('down') + '&oid=' + UserInfo.getOrganizationId();
            // return assetsURL + 'down-arrow.png';
        }
        set;
    }
    
    // Constructor
    public Nego360_ES_Pdf_Controller() {
        String selectedContractId = ApexPages.currentPage().getParameters().get('id');
        ApexPages.currentPage().getParameters().put('id', selectedContractId);
        ctrlr = new Nego360_ExecutiveSummary_Controller();
        imagesDocumentList = [SELECT Id, Name from Document WHERE Folder.Name = 'Public' AND Name LIKE '%_arrow']; 
        if(imagesDocumentList.size() == 0) {
            System.debug('### ARROW IMAGES NOT FOUND IN DOCUMENT ###');
        }
    }
    
    public String getImageId(String str) {
        for(Document item : imagesDocumentList) {
            if(item.Name.contains(str)) {
                return item.Id;
            }
        }
        System.debug('### IMAGE ' + str + ' NOT FOUND IN DOCUMENT ###');
        return '';
    }
}