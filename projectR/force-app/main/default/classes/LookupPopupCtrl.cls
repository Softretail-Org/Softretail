public with sharing class LookupPopupCtrl {
    public String mode {get;set;} // RECENT | SEARCH | NEW
    
    public String searchTerm {get;set;}
    public List<String> searchFields {get;set;}
    public List<String> formFields {get;set;}
    public String sObjectName {get;set;}
    public String mainField {get;set;}
    public String whereClause {get;set;}
    public String componentId {get;set;}
    public String selectedIds {get;set;}
    public Boolean canCreate {get;set;}
    public Boolean multiSelect {get;set;}
    Set<Id> selectedRecordsIds = new Set<Id>();
    Map<Id, RecordWrapper> selectedRecordMap = new Map<Id, RecordWrapper>();    
    public String selectedRecords {get;set;}
    
    public List<RecordWrapper> recordList {get;set;}
    // display sort and number for standard list controllers
    public Integer recPerPage {get; set;}
    Public Integer noOfRecords {get; set;}
    public list<SelectOption> recPerPageOption {get; set;}
    public String sortFieldSave;
    string queryResult;
    
    public SObject recordNew {get;set;}
    
    public LookupPopupCtrl() {
        this.mode = 'RECENT';
        this.mainField = ApexPages.currentPage().getParameters().get('fieldLabel');
        this.sObjectName = ApexPages.currentPage().getParameters().get('sObjectName');
        this.searchFields = this.formatFields(ApexPages.currentPage().getParameters().get('searchFields'));
        this.formFields = this.formatFields(ApexPages.currentPage().getParameters().get('formFields'));
        this.whereClause = ApexPages.currentPage().getParameters().get('where');
        this.searchTerm = ApexPages.currentPage().getParameters().get('searchTerm');
        this.componentId = ApexPages.currentPage().getParameters().get('componentId');
        this.canCreate = Boolean.valueOf(ApexPages.currentPage().getParameters().get('canCreate'));
        this.multiSelect = Boolean.valueOf(ApexPages.currentPage().getParameters().get('multiSelect'));
        this.selectedIds = ApexPages.currentPage().getParameters().get('selectedIds');
                
        //records for page initialization
        recPerPageOption = new List<SelectOption>();
        recPerPageOption.add(new SelectOption('5','5'));
        recPerPageOption.add(new SelectOption('10','10'));
        recPerPageOption.add(new SelectOption('25','25'));
        recPerPageOption.add(new SelectOption('50','50'));
        recPerPageOption.add(new SelectOption('100','100'));
        recPerPage = 10;
        sortFieldSave = SortField;
        
        // case Multi-Select Records
        if(this.multiSelect){
            this.searchTerm = '';            
            if(String.isNotBlank(this.selectedIds)){
                fillSelectedRecordsOnLoad();
            }
            buildRecordQuery();
        }
        else if(String.isNotBlank(this.searchTerm)) {
            this.search();            
        } 
        else {
            loadRecentlyViewedRecords();
        }
    }
    
    // fill selected records on load
    public void fillSelectedRecordsOnLoad() {
        String fieldList = String.join(this.searchFields, ',');        
        String query = 'SELECT ' + String.escapeSingleQuotes(fieldList) + ' FROM ' + String.escapeSingleQuotes(this.sObjectName) + ' ';
        query += 'WHERE Id IN (\'' + String.join(String.escapeSingleQuotes(this.selectedIds).split(','), '\',\'') +'\')';
        
        List<sObject> records = Database.query(query);
        if(records != null && records.size() > 0){
            for (SObject item : records) {
                RecordWrapper record = new RecordWrapper(item, true);
                selectedRecordsIds.add(item.Id);
                selectedRecordMap.put(item.Id, record);
            }
        }
        processRecordSelection();
    }
    
    private List<String> formatFields(String fieldListAsString) {
        Set<String> fields = new Set<String>();
        fields.add(this.mainField);
        for (String field : fieldListAsString.split(','))
        {
            fields.add(field.trim());
        }
        List<String> fieldList = new List<String>();
        fieldList.addAll(fields);
        return fieldList;
    }
        
    public void loadRecentlyViewedRecords() {
        StdSetControllerRecord = null;        
        String fieldList = String.join(this.searchFields, ',');        
        queryResult = 'SELECT ' + String.escapeSingleQuotes(fieldList) + ' FROM ' + String.escapeSingleQuotes(this.sObjectName) + ' WHERE (LastViewedDate != null) ';
        queryResult += 'ORDER BY ' + String.escapeSingleQuotes(SortField) + ' ' + String.escapeSingleQuotes(SortDirection) + ' LIMIT 10000';
    }
    
    public void search() {
        this.mode = 'SEARCH';
        // Get selected records
        processRecordSelection();
        this.selectedIds = null;
        
        if (String.isEmpty(this.searchTerm)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.MSG_ENTER_SEARCH));
            return;
        }
        if (this.searchTerm.length() <= 1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.MSG_Enter_Search_Length));
            return;
        }
        try {
            buildRecordQuery();
        }
        catch(DmlException ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ex.getDmlMessage(0)));
        } catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ex.getMessage()));
        }
    }
            
    // paging through the Record list
    public ApexPages.StandardSetController StdSetControllerRecord {
        get {
            if(StdSetControllerRecord == null) {
                if(String.isNotBlank(queryResult)){
                    try{
                        StdSetControllerRecord = new ApexPages.StandardSetController(Database.getQueryLocator(queryResult));
                        if(recPerPage == null) recPerPage = 10;
                        // sets the number of records in each page set
                        StdSetControllerRecord.setPageSize(recPerPage);
                        // sets the total records
                        noOfRecords = StdSetControllerRecord.getResultSize();
                    } catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() + ' - ' + e.getLineNumber()));
                    }
                }
                else{
                    ////StdSetControllerRecord = new ApexPages.StandardSetController(new List<SObject>());
                }
            }
            return StdSetControllerRecord;
        }
        set;
    }
    
    /* Get records */
    public List<RecordWrapper> getRecords(){
        try{
            recordList = new List<RecordWrapper>();
            if(StdSetControllerRecord != null){
                for (SObject item : (List<SObject>)StdSetControllerRecord.getRecords()) {
                    RecordWrapper record = new RecordWrapper(item, selectedRecordsIds.contains(item.Id));
                    recordList.add(record);
                }
            }
            return recordList;
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage() + ' - ' + e.getLineNumber()));
            return new List<RecordWrapper>();
        }
    }
    
    // Select records
    public void processRecordSelection() {
        selectedRecords = '';
        if(recordList != null && recordList.size() > 0){
            for(RecordWrapper item : recordList) {
                if (item.selected) {
                    if(!selectedRecordsIds.contains(item.record.Id)){
                        selectedRecordsIds.add(item.record.Id);
                        selectedRecordMap.put(item.record.Id, item);
                    }
                }
                else {
                    selectedRecordsIds.remove(item.record.Id);
                    selectedRecordMap.remove(item.record.Id);
                }
            }
        }
        if(selectedRecordMap.size() > 0){
            Set<String> selectedRecordsName = new Set<String>();
            for(RecordWrapper item : selectedRecordMap.values()){
                selectedRecordsName.add(String.valueOf(item.record.get(this.mainField)));
            }
            this.selectedRecords = String.escapeSingleQuotes(String.join(new List<String>(selectedRecordsName), ','));
        }
    }
    
    // build query command
    public void buildRecordQuery() {
        this.mode = 'SEARCH';
        processRecordSelection();
        StdSetControllerRecord = null;
        
        String fieldList = String.join(this.searchFields, ',');
        String queryWhere = this.whereClause != null ? ' WHERE ' + String.escapeSingleQuotes(this.whereClause) : '';
        
        queryResult = 'SELECT ' + String.escapeSingleQuotes(fieldList) + ' FROM ' + String.escapeSingleQuotes(this.sObjectName) + ' ';
        String likeExpressions = '';
        for (String fieldname : this.searchFields) {
            likeExpressions += String.isNotBlank(likeExpressions) ? ' OR ' : '(';
            likeExpressions += '('+ fieldname + ' LIKE \'%' + (String.isNotBlank(this.searchTerm) ? String.escapeSingleQuotes(this.searchTerm) : '') + '%\')';
        }
        if(String.isNotBlank(likeExpressions)) likeExpressions += ')';
        
        queryWhere = buildWhere(queryWhere, likeExpressions);
        
        // case Multi-Select Records
        /*if(this.multiSelect && String.isNotBlank(this.selectedIds)){
            queryWhere = buildWhere(queryWhere, 'Id IN (\'' + String.join(this.selectedIds.split(','), '\',\'') +'\')');
        }*/
        
        queryResult += queryWhere;
        queryResult += ' ORDER BY ' + String.escapeSingleQuotes(SortField) + ' ' + String.escapeSingleQuotes(SortDirection) + ' LIMIT 10000';
    }
    
    // build soql string for where criteria 
    public String BuildWhere(String QW, String Cond) {
        if (QW == '') {
            return ' WHERE ' + Cond;
        } else {
            return QW + ' AND ' + Cond;
        }
    }
    
    // return sort direction. Default ascending(asc)
    public String SortDirection {
        get { if (SortDirection == null) { SortDirection = 'asc'; } return SortDirection; }
        set;
    }
    
    // return sort by field. Default to Name
    public String SortField {
        get { if (SortField == null) { SortField = this.searchFields[0]; } return SortField; }
        set;
    }
    
    // toggles the sorting of query from asc<-->desc
    public void SortToggle() {
        SortDirection = SortDirection.equals('asc') ? 'desc NULLS LAST' : 'asc';
        // sort sequence when sorted field is changed
        if (sortFieldSave != SortField) {
            SortDirection = 'asc';
            sortFieldSave = SortField;
        }
        // run the query again
        if(this.mode == 'RECENT'){
            loadRecentlyViewedRecords();
        }
        else {
            buildRecordQuery();
        }
    }
    
    // Changes the size of pagination of Record Grid
    public PageReference refreshPageSize() {
        processRecordSelection();
        StdSetControllerRecord.setPageSize(recPerPage);
        return null;
    }
        
    // returns the first page of records
    public void first() {
        processRecordSelection();
        StdSetControllerRecord.first();
    }
    
    // returns the last page of records
    public void last() {
        processRecordSelection();
        StdSetControllerRecord.last();
    }
    
    // returns the previous page of records
    public void previous() {
        processRecordSelection();
        StdSetControllerRecord.previous();
    }
    
    // returns the next page of records
    public void next() {
        processRecordSelection();
        StdSetControllerRecord.next();
    }
    
    // Get selected records
    public PageReference getSelectedRecord() {
        processRecordSelection();
        String selectedRecordIds = String.join(new List<Id>(selectedRecordsIds), ',');
        if(selectedRecordsIds.size() == 0) selectedRecords = '';
        return new PageReference('"javascript:window.opener.' + this.componentId +
                                 'setValue("/"' + selectedRecords + '"/"", \'' + selectedRecordIds + '\');window.close();');
    }
    
    // remove selected records and initialize counter
    public PageReference resetRecord() {
        recordList.clear();
        selectedRecordsIds.clear();
        selectedRecordMap.clear();
        selectedRecords = '';
        searchTerm = '';
        this.selectedIds = null;
        ////processRecordSelection();
        ////queryResult = '';
        ////StdSetControllerRecord = null;
        ////noOfRecords = 0;
        
        // run the query again
        if(this.mode == 'RECENT'){
            loadRecentlyViewedRecords();
        }
        else {
            buildRecordQuery();
        }
        return null;
    }
        
    public PageReference newRecord(){
        this.mode = 'NEW';
        this.recordNew = Schema.getGlobalDescribe().get(sObjectName).newSObject();
        return null;
    }
    
    public PageReference saveNewRecord(){
        insert this.recordNew;
        if (this.recordNew.Id != null)
        {
            Id recordId = this.recordNew.Id;
            this.recordNew = (SObject)Database.query('SELECT Id, ' + String.escapeSingleQuotes(this.mainField) + ' FROM ' + String.escapeSingleQuotes(this.sObjectName) + ' WHERE Id =: recordId');
            return new PageReference('javascript:window.opener.' + this.componentId + 'setValue(\'' + this.recordNew.get(this.mainField) + '\', \'' + this.recordNew.Id + '\');window.close();');
            
        } else {
            return null;
        }
    }
    
    /* Record Wrapper */
    public class RecordWrapper {
        public boolean selected {get;set;}
        public SObject record {get;set;}
        public RecordWrapper(SObject record, boolean selected){
            this.record = record;
            this.selected = selected;
        }
    }
}