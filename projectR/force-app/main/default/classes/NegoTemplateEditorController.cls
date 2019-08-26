/**
 * @author ULiT
 * @description controller class for page NegoTemplateEditor
**************************************************************************************************************************** */

public with sharing class NegoTemplateEditorController extends NegoptimBaseController {
    
    private final NegoTemplate__c instance;
    /**
     * @description needed to override the standard quick save method
     *********************************************************************************************************************** */
    private ApexPages.StandardController standard;
    
    public String fieldToInsert{get; set;}
        
    //popups
    public boolean popupInsertField {get; set;}
    public boolean popupInsertRelatedList {get; set;}
    public boolean popupBrowseAction {get; set;}
    public boolean popupBrowseFields {get; set;}
    
    //variables related to insert field popup
    public boolean richValueFlag {get;set;}
    public final List<SelectOption> numberFormats {get; set;}
    public final List<SelectOption> dateFormats {get; set;}
    public List<fieldsSelectList> selectLists {get; set;}
    
    //variables related to insert related list popup
    public List<SelectOption> childRelationships {get; set;}
    public String selectedChildRelationship {get; set;}
    public List<fieldsSelectList> relatedListSelectLists {get; set;}
    
    public List<ApprovalProcessWrapper> actionsWrapperList {get; set;}
   //// public List<OrderFieldListWrapper> OrderFieldListWrapperList {get; set;}
    public String generatedVisualforceCode {get; set;}
    
    /**
     * @description constructor
    *********************************************************************************************************************** */
    public NegoTemplateEditorController(ApexPages.StandardController sc) {
        
        //load number format options
        numberFormats = new List<SelectOption>();
        numberFormats.add(new SelectOption('####','####'));
        numberFormats.add(new SelectOption('#,###','#,###'));
        numberFormats.add(new SelectOption('#,###.##','#,###.##'));
        numberFormats.add(new SelectOption('# ###','# ###'));
        numberFormats.add(new SelectOption('# ###,##','# ###,##'));
        numberFormats.add(new SelectOption('# ###.##','# ###.##'));
        numberFormats.add(new SelectOption('#.###','#.###'));
        numberFormats.add(new SelectOption('#.###,##','#.###,##'));
        //load date format options
        dateFormats = new List<SelectOption>();
        dateFormats.add(new SelectOption('M/d/yyyy','M/d/yyyy'));
        dateFormats.add(new SelectOption('MMMMM dd, yyyy','MMMMM dd, yyyy'));
        dateFormats.add(new SelectOption('MMMMM d, yyyy','MMMMM d, yyyy'));
        dateFormats.add(new SelectOption('MMM d, yyyy','MMM d, yyyy'));
        dateFormats.add(new SelectOption('MM/dd/yyyy','MM/dd/yyyy'));
        dateFormats.add(new SelectOption('M/d/yyyy','M/d/yyyy'));
        dateFormats.add(new SelectOption('M/d/yy','M/d/yy'));
        dateFormats.add(new SelectOption('dd MMMMM, yyyy','dd MMMMM, yyyy'));
        dateFormats.add(new SelectOption('d MMMMM, yyyy','d MMMMM, yyyy'));
        dateFormats.add(new SelectOption('d MMM, yyyy','d MMM, yyyy'));
        dateFormats.add(new SelectOption('dd/MM/yyyy','dd/MM/yyyy'));
        dateFormats.add(new SelectOption('d/MM/yy','d/MM/yy'));
        
        if (!Test.isRunningTest()) sc.AddFields(new List<String>{'Id'});
        if (sc.getId() != null) {
            standard = sc;
            this.instance = (NegoTemplate__c) sc.getRecord();
            popupInsertField = false;
            popupInsertRelatedList = false;
            popupBrowseAction = false;
            popupBrowseFields = false;
            selectLists = new List<fieldsSelectList>();
            resetFieldsSelectLists();
            ////selectLists.add(new fieldsSelectList(instance.ObjectType__c, instance.ObjectType__c));       
            relatedListSelectLists = new List<fieldsSelectList>();
            //initialize childRelationships
            childRelationships = getChildRelationships();
            if(!childRelationships.isEmpty())
                selectedChildRelationship = childRelationships[0].getValue();
            childRelationships = sortSelectOptions(childRelationships);
            resetChildRelationshipFields();
            actionsWrapperList = getActionList();
         ////   refreshOrderFieldsLists();
            generatedVisualforceCode = generateVisualforceCode();
        }
    }
    
    /**
     * @description get all SObject API names
     * @return List<SelectOption>
    *********************************************************************************************************************** */
    public List<SelectOption> getObjectTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '-- Choose Object Type --'));
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        List<String> entities = new List<String>(schemaMap.keySet());
        entities.sort();
        for (String name : entities) {
            if(!name.containsignorecase('history') && !name.containsignorecase('tag')&&
               !name.containsignorecase('share') && !name.containsignorecase('feed'))
                options.add(new SelectOption(name, name));
        }
        return options;
    }
    
    /**
     * @description refreshes the insert field popup by loading the appropriate field lists based on user selections
     * 
     *********************************************************************************************************************** */ 
    public void refreshInsertFieldPopup() {
        
        Integer index = Integer.valueOf(fieldToInsert.split(':')[2]);
        String temp = fieldToInsert.split(':')[0];
        List<String> lookupSequence = temp.split('\\.');
        String referenceTo = lookupSequence[lookupSequence.size() - 1];
        fieldsSelectList currentList;
        fieldsSelectList nextList = null;
        for(fieldsSelectList item : selectLists) {
            if (item.index == index) {
                currentList = item;
            }
            if (item.index == index + 1) {
                nextList = item;
            }
        }
        
        if (nextList == null)  {
            nextList = new fieldsSelectList(currentList.refrencedSObjectApiName, referenceTo, index + 1);
            selectLists.add(nextList);
            
        } else {
            nextList.sObjectApiName = currentList.refrencedSObjectApiName;
            nextList.referenceTo = referenceTo;
        }
        nextList.prefix = getPrefix(index + 1);
        nextList.updateFields(popupInsertField && popupBrowseFields); 
    }
    
    /**
     * @description to load field lists in relatedList popup
     * 
    *********************************************************************************************************************** */
    public void refreshInsertRelatedListPopup() {
        
        Integer index = Integer.valueOf(fieldToInsert.split(':')[2]);
        String temp = fieldToInsert.split(':')[0];
        List<String> lookupSequence = temp.split('\\.');
        String referenceTo = lookupSequence[lookupSequence.size() - 1];
        fieldsSelectList currentList;
        fieldsSelectList nextList = null;
        for(fieldsSelectList item : relatedListSelectLists) {
            if (item.index == index) {
                currentList = item;
            }
            if (item.index == index + 1) {
                nextList = item;
            }
        }
        
        if (nextList == null)  {
            nextList = new fieldsSelectList(currentList.refrencedSObjectApiName, referenceTo, index + 1);
            relatedListSelectLists.add(nextList);
            
        } else {
            nextList.sObjectApiName = currentList.refrencedSObjectApiName;
            nextList.referenceTo = referenceTo;
        }
        nextList.prefix = getRelatedListPrefix(index + 1);
        nextList.updateFields();
    }
    /**
     * @description reset the first list of fields in the relatedList popup whenever the user changes the selected child relationship 
     * 
    */
    public void resetChildRelationshipFields() {
        String childSObjectName;
        if(instance.ObjectType__c != null){
        for (ChildRelationship item : 
             Schema.getGlobalDescribe()
             .get(instance.ObjectType__c)
             .getDescribe()
             .getChildRelationships()) {
                 if (item.getRelationshipName() == selectedChildRelationship) {
                     childSObjectName = item.getChildSObject().getDescribe().getName();
                 }
             }
        }
        FieldsSelectList fls = null;
        if(childSObjectName != null && selectedChildRelationship != null)
          fls = new FieldsSelectList(childSObjectName, selectedChildRelationship);
        relatedListSelectLists = null;
        if(fls != null)
            relatedListSelectLists = new List<FieldsSelectList> {fls};
    }
    
    /**
     * @description
    *********************************************************************************************************************** */
    public pageReference hidePopup() {
        if (popupBrowseAction) {
            String selectedAction = '';
            for (ApprovalProcessWrapper apw : actionsWrapperList) {
                if (apw.isSelected) {
                    selectedAction = apw.developerName;
                    break;
                }
            }
            this.instance.Action_Unique_Name__c = selectedAction;
            popupBrowseAction = false;
        }
        if(popupBrowseFields && popupInsertField) {
            //this.instance.Mass_Print_Order_by_Field__c = this.fieldToInsert;
            popupInsertField = false;
            popupBrowseFields = false;
        }
        return null;
    }
    
    /**
     * @description closes any open popup without doing any changes
    *********************************************************************************************************************** */
    public pageReference cancelPopup() {
        popupInsertField = false;
        popupInsertRelatedList = false;
        popupBrowseAction = false;
        popupBrowseFields = false;
        /*selectLists.clear();
        selectLists.add(new fieldsSelectList(instance.ObjectType__c, instance.ObjectType__c)); */
        resetFieldsSelectLists();
        relatedListSelectLists.clear();
        //call this method after closing popup to remove all selection by user
        resetChildRelationshipFields();
        return null;
    }
    
    /**
     * @description
     *
    */
    public void resetFieldsSelectLists() {
        fieldsSelectList fsl = new fieldsSelectList(instance.ObjectType__c, instance.ObjectType__c);
        fsl.updateFields(popupInsertField && popupBrowseFields);
        selectLists.clear();
        selectLists.add(fsl);
    }
    
    /*
     * @description override standard quick save in order to add sucess apex message
    *********************************************************************************************************************** */
    public pageReference QuickSave(){
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Successfully saved!'));
        standard.save();
        return null;
    }
    
     /*
     * @description sorting of field select lists
     * @param sortingList the list to sort
     * @return List<SelectOption> sorted list
    *********************************************************************************************************************** */
    public List<SelectOption> sortSelectOptions(List<SelectOption> sortingList) {
        for (Integer i = 0; i < sortingList.size(); i++) {
            for (Integer j = i; j > 0; j--) {
                if (sortingList[j-1].getLabel() > sortingList[j].getLabel()){
                    SelectOption temp = sortingList[j];
                    sortingList[j] = sortingList[j-1];
                    sortingList[j-1] = temp;
                }
            }
        }
        return sortingList;
    }
    
    /**
     * @description load the fields by which the user can order the mass printed documents
    *********************************************************************************************************************** */
   /* public pageReference refreshOrderFieldsLists() {
        if (OrderFieldListWrapperList == null || OrderFieldListWrapperList.isEmpty()) {
            OrderFieldListWrapperList =  new List<OrderFieldListWrapper> {new OrderFieldListWrapper(this.instance.ObjectType__c, '')};
        } else {
            String prefix = '';
            for (OrderFieldListWrapper oflw : OrderFieldListWrapperList) {
                if (!oflw.objectApiName.equalsIgnoreCase(this.instance.ObjectType__c)) {
                    prefix += oflw.objectApiName.replace('__c', '__r');
                }
            }
            if (!String.isEmpty(prefix)){
                prefix += '.';
            }
            if(fieldToInsert != null && fieldToInsert.contains('>')) {
                Schema.DescribeFieldResult result = Schema.getGlobalDescribe()
                    .get(this.OrderFieldListWrapperList[OrderFieldListWrapperList.size() - 1].objectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(fieldToInsert.remove('>').remove('null'))
                    .getDescribe();
                String objName = result.getReferenceTo().get(0).getDescribe().getName(); 
                OrderFieldListWrapperList.add(new OrderFieldListWrapper(objName, prefix));
            }
        }
        return null;
    }*/
    
    /**
     * @description loads the list of predefined approval processes for the template objectType
     * @return List<ApprovalProcessWrapper>
    *********************************************************************************************************************** */
    private List<ApprovalProcessWrapper> getActionList() {
        List<ApprovalProcessWrapper> wList = new List<ApprovalProcessWrapper>();
        List<ProcessDefinition> processList = [SELECT Name, developerName, description
                                               FROM ProcessDefinition
                                               WHERE TableEnumOrId = :instance.ObjectType__c AND State = 'Active'];
        for (ProcessDefinition pd : processList) {
            wList.add(new ApprovalProcessWrapper(pd));
        }
        return wList;
    }
    
    private String generateVisualforceCode() {
        String source_code = '<apex:page standardController="' + this.instance.ObjectType__c + '" recordSetVar="recSetVar"\n';
        source_code += 'extensions="NegoTemplateMassPrintController"\n';
        source_code += 'tabStyle="' + this.instance.ObjectType__c + '"\n';
        source_code += 'id="thePage" action="{!pageAction}" >\n';
        source_code += '<apex:stylesheet value="{!URLFOR($Resource.Assets, \'assets/css/app.css\')}" />\n';
        source_code += '<apex:form id="theForm" >\n';
        source_code += '<apex:pageMessages id="messages" escape="false"/>\n';
        source_code += '<apex:actionStatus id="globalloading">\n';
        source_code += '<apex:facet name="start">\n';
        source_code += '<div class="loading-overlay">\n';
        source_code += '<div class="loader-img"></div>\n';
        source_code += '<div class="loading-block">{!$Label.Loading}</div>\n';
        source_code += '</div>\n';
        source_code += '</apex:facet>\n';
        source_code += '</apex:actionStatus>\n';
        source_code += '<apex:actionPoller id="printStatusActionPoller" action="{!pollerAction}" interval="5"\n';
        source_code += 'enabled="{!printingInProgress}" reRender="templatesPageBlockTable, printBtn, combineBtn, messages" />\n';
        source_code += '<apex:pageBlock >\n';
        source_code += '<apex:pageBlockSection columns="1" collapsible="false" title="{!$Label.Available_Templates}">\n';
        source_code += '<apex:pageBlockTable value="{!wAvailableTemplates}" var="item" id="templatesPageBlockTable">\n';
        source_code += '<apex:column width="1%" >\n';
        source_code += '<apex:inputCheckbox value="{!item.isSelected}" />\n';
        source_code += '</apex:column>\n';
        source_code += '<apex:column headerValue="{!$ObjectType.NegoTemplate__c.fields.Name.label}"\n';
        source_code += 'value="{!item.template.Name}" width="10%" />\n';
        source_code += '<apex:column headerValue="{!$ObjectType.NegoTemplate__c.fields.Description__c.label}"\n';
        source_code += 'value="{!item.template.Description__c}" width="20%" />\n';
        source_code += '<apex:column headerValue="{!$ObjectType.NegoTemplate__c.fields.Mass_Print_Order_by_Field__c.label}"\n';
        source_code += 'value="{!item.template.Mass_Print_Order_by_Field__c}" width="10%" />\n';
        source_code += '<apex:column headerValue="{!$ObjectType.NegoTemplate__c.fields.Send_Email_When_Printing__c.label}" width="1%" >\n';
        source_code += '<apex:inputField value="{!item.template.Send_Email_When_Printing__c}"\n';
        source_code += 'rendered="{!item.template.Document_Recipient__c!=null}" />\n';
        source_code += '<apex:outputField value="{!item.template.Send_Email_When_Printing__c}"\n';
        source_code += 'rendered="{!item.template.Document_Recipient__c==null}" />\n';
        source_code += '</apex:column>\n';
        source_code += '<apex:column headerValue="Status" value="{!item.status}" width="10%" />\n';
        source_code += '</apex:pageBlockTable>\n';
        source_code += '</apex:pageBlockSection>\n';
        source_code += '<apex:pageBlockSection id="recordsSection" columns="1" title="{!$Label.Records_To_Print}" >\n';
        source_code += '<apex:pageBlockTable id="recordsTable" value="{!RecordList}" var="item">\n';
        source_code += '<apex:column width="5%" >\n';
        source_code += '<apex:facet name="header">\n';
        source_code += '<apex:commandButton value="{!$Label.Clear_Selected}" action="{!ClearSelected}" reRender="recordsSection, messages" />\n';
        source_code += '</apex:facet>\n';
        source_code += '<apex:commandLink action="{!removeRow}" reRender="recordsTable" >\n';
        source_code += '<apex:image url="/img/func_icons/remove12_on.gif" title="{!$Label.remove}" />\n';
        source_code += '<apex:param assignTo="{!toRemoveRecordId}" value="{!item.Id}" name="toRemoveRecordId" />\n';
        source_code += '</apex:commandLink>\n';
        source_code += '</apex:column>\n';
        source_code += '<apex:column headerValue="{!$ObjectType.Invoice__c.fields.Name.label}" width="10%">\n';
        source_code += '<apex:outputLink value="/{!item.Id}" target="_BLANK" >\n';
        source_code += '<apex:outputText value="{!item[\'Name\']}" />\n';
        source_code += '</apex:outputLink>\n';
        source_code += '<apex:facet name="footer">\n';
        source_code += '<apex:outputPanel >\n';
        source_code += '<apex:commandButton value="{!$Label.LBL_First}" action="{!recordsStdSetCtrl.first}" reRender="recordsTable"\n';
        source_code += 'disabled="{!!recordsStdSetCtrl.HasPrevious}" />\n';
        source_code += '<apex:commandButton value="{!$Label.LBL_Previous}" action="{!recordsStdSetCtrl.previous}" reRender="recordsTable"\n';
        source_code += 'disabled="{!!recordsStdSetCtrl.HasPrevious}" />\n';
        source_code += '<apex:commandButton value="{!$Label.LBL_Next}" action="{!recordsStdSetCtrl.next}" reRender="recordsTable"\n';
        source_code += 'disabled="{!!recordsStdSetCtrl.HasNext}" />\n';
        source_code += '<apex:commandButton value="{!$Label.LBL_Last}" action="{!recordsStdSetCtrl.last}" reRender="recordsTable"\n';
        source_code += 'disabled="{!!recordsStdSetCtrl.HasNext}" />\n';
        source_code += '<apex:outputText rendered="{!noOfRecords > 0}" style="text-align: right" >\n';
        source_code += '{!(recordsStdSetCtrl.pageNumber * size)+1-size}-{!IF((recordsStdSetCtrl.pageNumber * size)>noOfRecords, noOfRecords,\n';
        source_code += '(recordsStdSetCtrl.pageNumber * size))} of {!noOfRecords}\n';
        source_code += '</apex:outputText>\n';
        source_code += '</apex:outputPanel>\n';
        source_code += '</apex:facet>\n';
        source_code += '</apex:pageBlockTable>\n';
        source_code += '</apex:pageBlockSection>\n';
        source_code += '<apex:pageBlockButtons location="top" >\n';
        source_code += '<apex:commandButton value="{!$Label.Print}" action="{!print}" id="printBtn" status="globalloading"\n';
        source_code += 'rendered="false" disabled="{!printingInProgress}"\n';
        source_code += 'reRender="printBtn, combineBtn, printStatusActionPoller, templatesPageBlockTable, messages" />\n';
        source_code += '<apex:commandButton value="{!$Label.Combine}" action="{!combine}" id="combineBtn" status="globalloading"\n';
        source_code += 'rendered="false" disabled="{!printingInProgress}"\n';
        source_code += 'reRender="printStatusActionPoller, templatesPageBlockTable, messages" />\n';
        source_code += '<apex:commandButton value="{!$Label.Print_Combine}" action="{!printAndCombine}" id="printAndCombineBtn" status="globalloading"\n';
        source_code += 'rendered="true" disabled="{!printingInProgress}"\n';
        source_code += 'reRender="printBtn, combineBtn, printStatusActionPoller, templatesPageBlockTable, messages"/>\n';
        source_code += '<apex:commandButton value="{!$Label.Go_To_Email_Page}" action="{!redirectToMailingPage}" id="mailBtn" status="globalloading"\n';
        source_code += 'rendered="false" disabled="{!printingInProgress}" />\n';
        source_code += '<apex:commandButton action="{!cancel}" value="{!$Label.Cancel}" />\n';
        source_code += '</apex:pageBlockButtons>\n';
        source_code += '</apex:pageBlock>\n';
        source_code += '</apex:form>\n';
        source_code += '</apex:page>\n';
                                              
        return source_code;
    }
    
    /*
     * @description get the prefix of the related list
     * @param index
     * @return String
    *********************************************************************************************************************** */ 
    private String getRelatedListPrefix(Integer index) {
        List<String> temp = new List<String>();
        temp.add(relatedListSelectLists[0].refrencedSObjectApiName.replace('__c', '__r'));
        for (integer i = 1; i <= index; i++) {
            temp.add(relatedListSelectLists[i].referenceTo.replace('__c', '__r'));
        }
        return String.join(temp, '.');
    }
    
    /**
     * @description loads the list of available child relationships 
     * @return List<SelectOption>
    *********************************************************************************************************************** */
    private List<SelectOption> getChildRelationships() {
        List<SelectOption> options = new List<SelectOption>();
        if(instance.ObjectType__c != null){
            for (ChildRelationship item : 
                 Schema.getGlobalDescribe()
                 .get(instance.ObjectType__c)
                 .getDescribe()
                 .getChildRelationships()) {
                     String value = 'null';
                     if (item.getRelationshipName() != null) {
                         value = item.getRelationshipName();
                         options.add(new SelectOption(value, value));
                     }                              
                 }
        }
        return options;
    }
    
    
    /**
     * @description constructs a prefix of fields by concatenating the object name and lookup relationships
     * @param index
     * @return String the prefix
    *********************************************************************************************************************** */
    private String getPrefix(Integer index) {
        List<String> temp = new List<String>();
        temp.add(selectLists[0].refrencedSObjectApiName);
        for (integer i = 1; i <= index; i++) {
            temp.add(selectLists[i].referenceTo.replace('__c', '__r'));
        }
        return String.join(temp, '.');
    }

    public class fieldsSelectList {
        
        public final Integer index {get; set;}
        public String sObjectApiName {get; set;}
        public String prefix {get; set;}
        public String referenceTo {get; set;}
        public String refrencedSObjectApiName {get; set;}
        public List<SelectOption> fields {get; set;}
        
        /**
         * @description use this contructor to initialise the first select list (fields of the templates sObject)
        */
        public fieldsSelectList(String templateSObject, String prefix) {
            this.Index = 0;
            this.refrencedSObjectApiName = templateSObject;
            this.prefix = prefix;
            //this.updateFields();
        }
        
        public fieldsSelectList(String sObjectApiName, String referenceTo, Integer index) {
            this.sObjectApiName = sObjectApiName;
            this.referenceTo = referenceTo;
            this.index = index;
        }
        
        public void updateFields() {
            updateFields(false);
        }
        
        /***/
        public void updateFields(Boolean filter) {
            if (sObjectApiName != null) {
                this.refrencedSObjectApiName = getSObjectApiName();
            }
            Map<String, schema.SObjectField> fieldsMap =null;
            if(this.refrencedSObjectApiName!=null){
                fieldsMap = Schema.getGlobalDescribe()
                    .get(this.refrencedSObjectApiName)
                    .getDescribe()
                    .fields.getMap();
            }
            List<SelectOption> fieldOptions = new List<SelectOption>();
            if(fieldsMap != null ) {
                for (String key : fieldsMap.keySet()) {
                    String value =  prefix + '.' + key;
                    String text = fieldsMap.get(key).getDescribe().getLabel();
                    DisplayType fieldType = fieldsMap.get(key).getDescribe().getType();
                    if (filter && !isOrderableOrReferenceField(fieldType)) continue;
                    if (fieldType == DisplayType.Double || fieldType == DisplayType.Currency  || fieldType == DisplayType.Percent) {
                        value += ':number';
                    } else if (fieldType == DisplayType.Date || fieldType == DisplayType.DateTime) {
                        value += ':date';
                    } else if (fieldType == DisplayType.TextArea) {
                        value += ':rich';
                    } else if (fieldType == DisplayType.Reference) {
                        text += ' >';
                        value += ':reference';
                        value += ':' + this.index;
                    }
                    fieldOptions.add(new SelectOption(value, text));
                } 
            }
            this.fields = fieldOptions;
        }
        
        /***/
        private String getSObjectApiName () {            
            Schema.DescribeFieldResult result = Schema.getGlobalDescribe()
                .get(this.sObjectApiName)
                .getDescribe()
                .fields.getMap()
                .get(this.referenceTo)
                .getDescribe();
            return result.getReferenceTo().get(0).getDescribe().getName(); 
        }
        
        private boolean isOrderableOrReferenceField(DisplayType fieldType) {
            return fieldType == DisplayType.Currency
                || fieldType == DisplayType.Date
                || fieldType == DisplayType.DateTime
                || fieldType == DisplayType.Double
                || fieldType == DisplayType.Integer
                || fieldType == DisplayType.Percent
                || fieldType == DisplayType.String
                || fieldType == DisplayType.Time
                || fieldType == DisplayType.Reference;
        }
    }
    
    public class ApprovalProcessWrapper {
        
        public boolean isSelected {get; set;}
        public String name {get; set;}
        public String developerName {get; set;}
        public String description {get; set;}
        
        public ApprovalProcessWrapper(ProcessDefinition pd) {
            this.isSelected = false;
            this.name = pd.name;
            this.developerName = pd.DeveloperName;
            this.description = pd.description;
        }
    }
    
    /*public class OrderFieldListWrapper {
        
        public List<SelectOption> fieldsList {get; set;}
        public String objectApiName {get; set;}
        public String prefix {get; set;}
        public OrderFieldListWrapper(String objectApiName, String prefix) {
            this.prefix = prefix;
            this.objectApiName = objectApiName;
            Map<String, schema.SObjectField> fieldsMap = Schema.getGlobalDescribe()
                .get(this.objectApiName)
                .getDescribe()
                .fields.getMap();
          
            fieldsList = new List<SelectOption>();
            for (String key : fieldsMap.keySet()) {
                DisplayType fieldType = fieldsMap.get(key).getDescribe().getType();
                if(isOrderableOrReferenceField(fieldType)) {
                    String label = fieldsMap.get(key).getDescribe().getLabel();
                    String apiName = this.prefix + key;
                    if (fieldType == DisplayType.Reference) {
                        label += ' >';
                        apiName += '>';
                    }
                    fieldsList.add(new SelectOption(apiName, label));
                }
            }
            
        }
        
        private boolean isOrderableOrReferenceField(DisplayType fieldType) {
            return fieldType == DisplayType.Currency
                || fieldType == DisplayType.Date
                || fieldType == DisplayType.DateTime
                || fieldType == DisplayType.Double
                || fieldType == DisplayType.Integer
                || fieldType == DisplayType.Percent
                || fieldType == DisplayType.String
                || fieldType == DisplayType.Time
                || fieldType == DisplayType.Reference;
        }
        
    }*/
}