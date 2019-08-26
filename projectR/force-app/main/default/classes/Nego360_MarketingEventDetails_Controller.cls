public with sharing class Nego360_MarketingEventDetails_Controller extends NegoptimBaseController{
    
    public Id commercialPlanId;
    public String eventName;
    public List<EventsDetailWrapper> listEventsDetailWrapper {get; set;}
    public List<SelectOption> eventsTypeOptions {get; set;}
    public List<SelectOption> suppliersOptions {get; set;}
    public List<SelectOption> statusOptions {get; set;}
    public List<SelectOption> usersOptions {get; set;}
    public List<SelectOption> attachTypeOptions {get; set;}
    public String[] valuesEventType {get; set;}
    public String[] valuesSuppliers {get; set;}
    public String[] valuesUsers {get; set;}
    public String[] valuesAttachType {get; set;}
    public String valuesView {get; set;}
    public Boolean isList {get; set;}
    public String valuesStatus {get; set;}
    public String sortDirection{get; set;}
    private String sortExp;
    public integer counter{get; set;} 
    public integer limitSize=20; 
    public integer totalCount {get; set;}
    public Boolean isLoadMore {get; set;}
    
    public String sortExpression {
        get
        {
            return sortExp;
        }
        set
        {
            //if the column is clicked on then switch between Ascending and Descending modes
            if (value == sortExp)
                sortDirection = (sortDirection == 'ASC')? 'DESC' : 'ASC';
            else
                sortDirection = 'ASC';
            sortExp = value;
        }
    }
    
    
    public Nego360_MarketingEventDetails_Controller(ApexPages.StandardController stdController) {
        commercialPlanId = stdController.getId();
        valuesEventType = new String[]{};
        valuesSuppliers = new String[]{};
        valuesUsers = new String[]{};
        valuesAttachType = new String[]{};
        isList = true;   
        isLoadMore = false;
        counter = 0;
        getTotalRowsCount();
        Map<Id, Commercial_Plan_Detail__c> eventDetailsMap;
        if(commercialPlanId == null) {
            // get a Map of all event details for the current year
            eventDetailsMap = new Map<Id, Commercial_Plan_Detail__c>([SELECT Id, Name, CreatedById, CreatedBy.Name, Statut__c,
                                                                      Commercial_Event__r.Name, Supplier__r.Name, Supplier__c,
                                                                      Nego_Scope__r.Name, Commercial_Event__r.Start_Date__c,
                                                                      Commercial_Event__r.End_Date__c, Even__c, From_prenego_budget__c,
                                                                      Product__r.Name
                                                                      FROM Commercial_Plan_Detail__c
                                                                      WHERE CALENDAR_YEAR(Event_Start_Date__c) = :System.today().year()
                                                                      LIMIT :limitSize]);
        } else {
            eventDetailsMap = new Map<Id, Commercial_Plan_Detail__c>([SELECT Id, Name, CreatedById, CreatedBy.Name, Statut__c,
                                                                      Commercial_Event__r.Name, Supplier__r.Name, Supplier__c,
                                                                      Nego_Scope__r.Name, Commercial_Event__r.Start_Date__c,
                                                                      Commercial_Event__r.End_Date__c, Even__c, From_prenego_budget__c,
                                                                      Product__r.Name
                                                                      FROM Commercial_Plan_Detail__c
                                                                      WHERE Commercial_Event__c = :commercialPlanId]);
        }
        
        
        listEventsDetailWrapper = new List<EventsDetailWrapper>();
        eventsDetailWrapper EventsDetailWrapper;
        // @todo Add fonction or wrapper to minimize the code and use it in constructor and filter
        Map<Id, List<Attachment>> mapAttachement = new Map<Id, List<Attachment>>();
        // get a list of all atachment to desired event details
        List<Attachment> listAttachement =[SELECT Id, Name, Body, ContentType, Parentid 
                                           FROM Attachment
                                           WHERE Parentid IN:eventDetailsMap.keySet()];
        if(listAttachement != null && listAttachement.size() > 0) {
            for (Attachment attachement : listAttachement) {
                if(mapAttachement.containsKey(attachement.Parentid)) {
                    List<Attachment> lstAttach= mapAttachement.get(attachement.Parentid);
                    lstAttach.add(attachement);
                    mapAttachement.put(attachement.Parentid, lstAttach);
                } else {
                    mapAttachement.put(attachement.Parentid,new List<Attachment> { attachement });
                }
            }
        }
        
        Map<Id, String> mapSupplier = new Map<Id, String>();
        Map<Id, String> mapUsers = new Map<Id, String>();
        Set<String> attachmentTypeSet = new Set<String>();
        // loop over event details to add them to EventsDetailWrapper wrapper  and then sent to the page 
        List<FileWrapper> listFileWrapper;
        fileWrapper FileWrapper;
        Boolean isImage;
        
        for (Id id : eventDetailsMap.keySet()) { 
            
            Commercial_Plan_Detail__c eDetail  = eventDetailsMap.get(id);
            String beginDate = DateTime.newInstance(eDetail.Commercial_Event__r.Start_Date__c.year(),eDetail.Commercial_Event__r.Start_Date__c.month(),eDetail.Commercial_Event__r.Start_Date__c.day()).format('YYYY-MM-d');
            String endDate = DateTime.newInstance(eDetail.Commercial_Event__r.End_Date__c.year(),eDetail.Commercial_Event__r.End_Date__c.month(),eDetail.Commercial_Event__r.End_Date__c.day()).format('YYYY-MM-d');
            List<Attachment> lstAttach = new List<Attachment>();
            listFileWrapper = new List<FileWrapper>();
            if(mapAttachement.get(id) != null) {
                lstAttach =  mapAttachement.get(id);
                // loop on attachement 
                for (Attachment attach : lstAttach) { 
                    isImage = false;
                    // check if file is an image or not
                    // Todo : maybe create image checker function
                    if(attach.ContentType=='image/jpeg' || attach.ContentType=='image/png' ||
                       attach.ContentType=='image/gif' || attach.ContentType=='image/jpg')
                    {
                        isImage = true;
                    }
                    if(attach.ContentType != null) {    
                        attachmentTypeSet.add(attach.ContentType);
                    }
                    /***if(attach.Name != ''){
                        fileUrl = System.URL.getSalesforceBaseURL()+'/'+attach.Name;
                    } else {
                        fileUrl = 'https://s-media-cache-ak0.pinimg.com/564x/5c/c6/d9/5cc6d9872253e554e2c56fb80581753c.jpg';
                    }***/
                    fileWrapper = new FileWrapper(attach.Id, attach.Name, attach.ContentType, isImage);
                    listFileWrapper.add(fileWrapper);
                }
            }
            String fileUrl;
            eventsDetailWrapper = new EventsDetailWrapper(eDetail, beginDate, endDate,'/' + eDetail.Id, fileUrl, listFileWrapper);
            listEventsDetailWrapper.add(eventsDetailWrapper);
            // create supplier map to add only supplier that have events to the filter  
            if(!mapSupplier.containsKey(eDetail.Supplier__r.Id)) {    
                mapSupplier.put(eDetail.Supplier__r.Id,eDetail.Supplier__r.Name);
            }   
            // create user  map to add only user that have events to the filter  
            if(!mapUsers.containsKey(eDetail.CreatedById)) {    
                mapUsers.put(eDetail.CreatedById,eDetail.CreatedBy.Name);
            }            
        }
        // event type picklist
        List<Schema.PicklistEntry> plEventsType = Commercial_Plan__c.Event_Type__c.getDescribe().getPicklistValues();
        eventsTypeOptions = new List<SelectOption>();
        // choiceOptionsStatus.add(new SelectOption('','')); 
        for(Schema.PicklistEntry ple : plEventsType) {
            eventsTypeOptions.add(new SelectOption(ple.getValue(),ple.getLabel()));
        }
        // supplier picklist 
        suppliersOptions = new List<SelectOption>();        
        for (Id key : mapSupplier.keySet()) {
            if (mapSupplier.get(key) != null)
                suppliersOptions.add(new SelectOption(key,mapSupplier.get(key)));
        }
        // status picklist
        List<Schema.PicklistEntry> plEventsStatus = Commercial_Plan_Detail__c.Statut__c.getDescribe().getPicklistValues();
        statusOptions = new List<SelectOption>();
        statusOptions.add(new SelectOption('',''));
        for(Schema.PicklistEntry ple : plEventsStatus) {
            statusOptions.add(new SelectOption(ple.getValue(),ple.getLabel()));
        }
        // users picklist 
        usersOptions = new List<SelectOption>();        
        for (Id key : mapUsers.keySet()) {
            usersOptions.add(new SelectOption(key,mapUsers.get(key)));
        }
        // attach picklist 
        attachTypeOptions = new List<SelectOption>();        
        for (String key : attachmentTypeSet) {
            attachTypeOptions.add(new SelectOption(key, key));
        }
    }
    
    
    // Filter on events details
    public PageReference getEventDetailsFilter() {
        // construct the query to get data based on filter
        string query = 'SELECT Id, Name, CreatedById, CreatedBy.Name,';
        query += ' Statut__c, Commercial_Event__r.Name,';
        query += ' Supplier__r.Name, Supplier__c , Nego_Scope__r.Name,Commercial_Event__r.Start_Date__c,';
        query += ' Commercial_Event__r.End_Date__c, Even__c, From_prenego_budget__c, Product__r.Name';
        query += ' FROM Commercial_Plan_Detail__c';
        query += ' WHERE CALENDAR_YEAR(Event_Start_Date__c) = ' + System.today().year();
        
        if(valuesAttachType != null  &&  valuesAttachType.size() > 0) {
            List<Attachment> listAttachement =[SELECT Parentid
                                               FROM Attachment
                                               WHERE ContentType IN :valuesAttachType];
            List<String> listEventId = new List<String>();
            for(Attachment attachement : listAttachement){
                listEventId.add(attachement.Parentid);
            }
            if(listEventId != null && listEventId.size() > 0){
                List<String> eventIdList = new List<String>();
                //securing by variable sanitization
                for(String strList : listEventId){
                    eventIdList.add(String.escapeSingleQuotes(strList));
                }
                query += ' AND Id IN (\'' + String.join(eventIdList, '\',\'') +'\')';
            }                         
            
        }
        if(valuesEventType != null && valuesEventType.size() > 0) {
            List<String> eventTypeList = new List<String>();
            //securing by variable sanitization
            for(String strList : valuesEventType){
                eventTypeList.add(String.escapeSingleQuotes(strList));
            }
            query += ' AND Commercial_Event__r.Event_Type__c IN (\'' + String.join(eventTypeList, '\',\'') +'\')';
        }
        if(valuesSuppliers != null && valuesSuppliers.size() > 0) {
            List<String> supplierList = new List<String>();
            //securing by variable sanitization
            for(String strList : valuesSuppliers){
                supplierList.add(String.escapeSingleQuotes(strList));
            }
            query += ' AND Supplier__c IN (\'' + String.join(supplierList, '\',\'') +'\')'; 
        }
        if(valuesStatus != null &&  valuesStatus != '') {
            query += ' AND Statut__c =\'' + String.escapeSingleQuotes(valuesStatus) +'\'';
        }
        if(valuesUsers != null &&  valuesUsers.size() > 0) {
            List<String> usersList = new List<String>();
            //securing by variable sanitization
            for(String strList : valuesUsers){
                usersList.add(String.escapeSingleQuotes(strList));
            }
            query += ' AND CreatedById IN (\'' + String.join(usersList, '\',\'') +'\')';
        }
        if(sortExpression != null && sortDirection != null){
            String sortFullExp = sortExpression  + ' ' + sortDirection;
            query += ' ORDER BY ' + sortFullExp;
        }
        
        List<Commercial_Plan_Detail__c> eventDetailsWithoutLimit = new List<Commercial_Plan_Detail__c>();
        
        eventDetailsWithoutLimit = Database.query(query);
        totalCount = eventDetailsWithoutLimit.size();
        if(counter >= 0) {
            query += ' LIMIT ' + limitSize + ' OFFSET '+counter;	
        }

        Map<Id, Commercial_Plan_Detail__c> eventFilterDetailsMap = new Map<Id, Commercial_Plan_Detail__c>((List<Commercial_Plan_Detail__c>)Database.query(query));
        
        // @todo Add fonction or wrapper to minimize the code and use it in constructor and filter
        Map<Id, List<Attachment>> mapAttachement = new Map<Id, List<Attachment>>();
        // get a list of all atachment to desired event details
        List<Attachment> listAttachement = [SELECT Id, Name, Body, ContentType, Parentid
                                            FROM Attachment
                                            WHERE Parentid IN:eventFilterDetailsMap.keySet()];
        if(listAttachement != null && listAttachement.size() > 0) {
            for (Attachment attachement : listAttachement) {
                if(mapAttachement.containsKey(attachement.Parentid)) {
                    List<Attachment> lstAttach= mapAttachement.get(attachement.Parentid);
                    lstAttach.add(attachement);
                    mapAttachement.put(attachement.Parentid, lstAttach);
                }else{
                    mapAttachement.put(attachement.Parentid,new List<Attachment>{ attachement });
                }
            }
        }
        Map<Id, String> mapSupplier = new Map<Id, String>();
        // loop over event details to add them to EventsDetailWrapper wrapper  and then sent to the page
        List<FileWrapper> listFileWrapper;
        fileWrapper FileWrapper;
        Boolean isImage;
        eventsDetailWrapper EventsDetailWrapper;

        if(isLoadMore == false){
            listEventsDetailWrapper = new List<EventsDetailWrapper>();
        }
        for (Id id : eventFilterDetailsMap.keySet()) {
            
            Commercial_Plan_Detail__c eDetail  = eventFilterDetailsMap.get(id);
            String beginDate = DateTime.newInstance(eDetail.Commercial_Event__r.Start_Date__c.year(),eDetail.Commercial_Event__r.Start_Date__c.month(),eDetail.Commercial_Event__r.Start_Date__c.day()).format('YYYY-MM-d');
            String endDate = DateTime.newInstance(eDetail.Commercial_Event__r.End_Date__c.year(),eDetail.Commercial_Event__r.End_Date__c.month(),eDetail.Commercial_Event__r.End_Date__c.day()).format('YYYY-MM-d');
            List<Attachment> lstAttach = new List<Attachment>();
            listFileWrapper = new List<FileWrapper>();
            if(mapAttachement.get(id) != null) {
                lstAttach =  mapAttachement.get(id);
                for (Attachment attach : lstAttach) {
                    isImage = false;
                    // check if file is an image or not
                    // Todo : maybe create image checker function
                    if(attach.ContentType=='image/jpeg' || attach.ContentType=='image/png' || 
                       attach.ContentType=='image/gif' || attach.ContentType=='image/jpg') {
                           isImage = true;
                       }
                    fileWrapper = new FileWrapper(attach.Id, attach.Name, attach.ContentType, isImage);
                    listFileWrapper.add(fileWrapper);
                }
            }
            String fileUrl;
            
            eventsDetailWrapper = new EventsDetailWrapper(eDetail, beginDate, endDate,'/' + eDetail.Id, fileUrl, listFileWrapper);
            listEventsDetailWrapper.add(eventsDetailWrapper);
        }
        return null;
    }
    
    // Go to first page
    public PageReference First() {
        counter = 0 ;
        getEventDetailsFilter();
        return null;
    }
    
    // Go to previous page
    public PageReference Previous() { 
        counter -= limitSize;
        getEventDetailsFilter();
        return null;
    }
    // Go to next page
    public PageReference Next() {
        counter += limitSize;
        getEventDetailsFilter(); 
        return null;
    }
    // Go to last page
    public PageReference End() {
        if (math.mod(totalCount, limitSize) > 0) {
            counter = totalCount - math.mod(totalCount, limitSize);
        }else{
            counter = totalCount - math.mod(totalCount, limitSize)-1;
        }
        getEventDetailsFilter();
        return null;
    }
    // return number of rows in grid 
    public Integer getTotalRowsCount() {
        
        totalCount = [select count() from Commercial_Plan_Detail__c WHERE Id != NULL];
        return totalCount;
        
    }
    
    public Integer getPageNumber() {
        return counter/limitSize + 1;   
    }
    
    public Integer getTotalPages() {    	
        if (math.mod(totalCount, limitSize) > 0) {
            return totalCount/limitSize + 1;
        } else {
            return (totalCount/limitSize);
        }
    }
    
    public PageReference viewMode() {
        // check if mode list or grid
        if(valuesView == 'list') {
            isLoadMore = false;
            counter = 0;
            isList = true;
        } 
        if(valuesView == 'grid') {
            isList = false;       
        }
        getEventDetailsFilter(); 
        return null;
    } 
    // load more 
    public PageReference loadMore() {
        counter += limitSize;
        isLoadMore = true;
        getEventDetailsFilter(); 
        return null;
    }
    
    public void resetFilter() {
        valuesStatus = Null;
        valuesEventType = Null;
        valuesUsers = Null;
        valuesSuppliers = Null;
        valuesAttachType = Null;
        getEventDetailsFilter();
    }
    
    /** wrapper class for events details  **/
    public class EventsDetailWrapper {
        public Commercial_Plan_Detail__c eventDetails {get; set;}
        public String url {get; set;}
        public String eBDate {get; set;}
        public String eEDate {get; set;}
        public String defaultImageUrl {get; set;}
        public List<FileWrapper> fileWrapper{get; set;}
        
        public EventsDetailWrapper(Commercial_Plan_Detail__c eventDetails,String eBDate, String eEDate, String url,String defaultImageUrl, List<fileWrapper> fileWrapper) {
            this.eventDetails = eventDetails;
            this.eBDate = eBDate;
            this.eEDate = eEDate;
            this.url = url;
            this.defaultImageUrl = url;
            
            this.fileWrapper = fileWrapper;
        }
    }
    
    /** wrapper class to handle file manipulation  **/
    public class FileWrapper {
        public String Id {get; set;}
        public String name {get; set;}
        public String contentType  {get; set;}
        public Boolean isImage {get; set;}
        
        public FileWrapper(String Id, String name, String contentType, Boolean isImage) {
            this.Id = Id; 
            this.name = name;
            this.contentType = contentType;
            this.isImage = isImage;
        }
    }
}