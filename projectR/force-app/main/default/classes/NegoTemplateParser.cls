/**
 * @author hawly
 * @description parser engine that generates content for Nego Templates 
 * 
************************************************************************************************************************************* */
public class NegoTemplateParser {
    /****************************************************** VARIABLE DECLERATION ******************************************************/
    
    /**
     * @description replace any missing or unvailable data value with an empty string
     ******************************************************************************************************************************** */
    private static final String EMPTY = '';
    
    //different regular expressions used to parse different parts of the template
    /**
     * @description to find a field token of the format {{!fieldName}}
     * ^< is used to skid related lists
     ******************************************************************************************************************************** */ 
    private static final String FIELD_TOKEN_REGEX = '\\{\\{!([^<].+?)\\}\\}';
    
    /**
     * @description to seperate fields and format in field tokens
     ******************************************************************************************************************************** */ 
    private static final String FIELD_FORMAT_REGEX = '(.+?)\\s(.+)';
    
    /**
     * @description to find a related list xml document
    ******************************************************************************************************************************** */
    private static final String RELATED_LIST_XML_REGEX = '<!--\\{\\{!(.+?)\\}\\}-->';
    
    /**
     * to find html style tags used to encapsulate css code for the generated related list table
    ******************************************************************************************************************************** */
    private static final String STYLE_TAG_REGEX = '<style type="text/css">(.+?)</style>';
    
    /**
     * @description Map of WrapperChildRelationship indexed by their position in the template
    ******************************************************************************************************************************** */
    private Map<Integer, WrapperChildRelationship> childRelationshipMap;
    /**
     * @description list of inner select queries for validated related lists
    ******************************************************************************************************************************** */
    private List<String> innerSelectQueries;//initiated in parseXml()
    /**
     * @description list records fetched from the query
    ******************************************************************************************************************************** */
    private List<SObject> records;
    /**
     * @description validated fields from the template
    ******************************************************************************************************************************** */
    private Map<String, Schema.SObjectField> validFieldsMap;
    /**
     * @description list Ids of the records to generate documents for
    ******************************************************************************************************************************** */
    private List<Id> recordsIds;
    /**
     * @description the template to use in generating documents
    ******************************************************************************************************************************** */
    private NegoTemplate__c template;
    /**
     * @description the api name of the object type of the records to print
    ******************************************************************************************************************************** */
    private final String apiName;
    /**
     * @description the SObject of the records to print
    ******************************************************************************************************************************** */
    private SObject mainSObject;
    /**
     * @description Map of validated fields
    ******************************************************************************************************************************** */
    private Map<String, Schema.SObjectField> fieldMap;
    /**
     * @description to indicate if engine is used in preview mode. if true the parser won't launch the action (ApprovalProcess)
    ******************************************************************************************************************************** */
    private Boolean isPreview;
    
    /*************************************************** END OF VARIABLE DECLERATION **************************************************/
    
    
    /**
     * @description constructor
     * @param negoTemplate the template to be used as base to generate documents
     * @param recordIds a list of Ids of the records for which documents will be generated (1 document for each record)
     * @param isPreview to indicate if in preview mode
     ******************************************************************************************************************************** */
    public NegoTemplateParser(Id templateId, List<Id> recordsIds, Boolean isPreview) {
        this.template = [SELECT Name, First_Page_Header__c, First_Page_Footer__c, Different_First_Page_Header_Footer__c, ObjectType__c,
                         Remaining_Pages_Footer__c, Body__c, Remaining_Pages_Header__c, Mass_Print_Order_by_Field__c, Action_Unique_Name__c,
                         Display_Page_Numbers__c, Page_Height__c, Measurement_Unit__c, Page_Width__c,
                         Page_Margin_Top__c, Page_Margin_Right__c, Page_Margin_Bottom__c, Page_Margin_left__c,
                         Page_Size__c, Orientation__c, Header_Margin__c, Footer_Margin__c, Attachment_Name__c
                         FROM NegoTemplate__c
                         WHERE Id = :templateId];
        this.recordsIds = recordsIds;
        this.isPreview = isPreview;
        // Get the API name of the records sObject
        apiName = this.recordsIds.get(0).getSobjectType().getDescribe().getName();
        //in case the printed record isn't of the same object type associated to the template
        if (!apiName.equalsIgnoreCase(this.template.ObjectType__c)) {
            throw new ParserException('Invalid Template');
        }
        if(Schema.getGlobalDescribe().get(apiName) != null) {
            // Get SObject from the API name
            mainSObject = Schema.getGlobalDescribe().get(apiName).newSObject();
            fieldMap = mainSObject.getSobjectType().getDescribe().fields.getMap();
        }
    }
    
    public NegoTemplateParser(List<Id> recordIds) {
        this.recordsIds = recordIds;
        // Get the API name of the records sObject
        this.apiName = this.recordsIds.get(0).getSobjectType().getDescribe().getName();
        if(Schema.getGlobalDescribe().get(apiName) != null) {
            // Get SObject from the API name
            mainSObject = Schema.getGlobalDescribe().get(apiName).newSObject();
            fieldMap = mainSObject.getSobjectType().getDescribe().fields.getMap();
        }
    }
    
    /**
     * @description this is the only public method
     * constructs a NegoptimDocument for each record and if isPreview = false then it launches the aprovalProcess
     *  of the template once for each record
     * @return List of WrapperTemplate 
     ******************************************************************************************************************************** */
    public List<Negoptim_Document__c> parse() {
        //save point is used to rollback any changes made by the approval process if the engine fails to generate documents
        SavePoint sp = Database.setSavepoint();
        try {
            List<Negoptim_Document__c> generatedDocumentsList = new List<Negoptim_Document__c>();
            // Get the List the approval process to execute for each record
            String approvalProcessDeveloperName = this.template.Action_Unique_Name__c;
            if ([SELECT COUNT() FROM ProcessDefinition WHERE DeveloperName = :approvalProcessDeveloperName] != 1) {
                isPreview = true;
            }
            for (Id recId : recordsIds) {
                // If the engine is running to generate a preview -> don't execute approval process
                if (!this.isPreview) {
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setProcessDefinitionNameOrId(approvalProcessDeveloperName);
                    req.setObjectId(recId);
                    req.setSubmitterId(UserInfo.getUserId());
                    req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                    Approval.ProcessResult result = Approval.process(req);
                }
            }
            // Parse the template Body
            Map<id, String> bodyMap = parse(template.Body__c);
            // Parse the template first page Header (Currently used as the header for the entire document)
            Map<id, String> header1Map;
            if (String.isNotBlank(this.template.First_Page_Header__c))
                header1Map = parse(template.First_Page_Header__c);
            // Parse the template first page  Footer (Currently used as the footer for the entire document)
            Map<id, String> footer1Map;
            if (String.isNotBlank(this.template.First_Page_Footer__c))
                footer1Map = parse(template.First_Page_Footer__c);
            // Parse the Name
            Map<Id, String> namesMap;
            if (String.isNotBlank(this.template.Attachment_Name__c)) {
                namesMap = parse(template.Attachment_Name__c);
            }
            Negoptim_Document__c document;
            //
            String measuringUnit = this.template.Measurement_Unit__c == null ? 'mm' : this.template.Measurement_Unit__c;
            Decimal headerMargin = this.template.Header_Margin__c == null ? 0 : this.template.Header_Margin__c;
            Decimal footerMargin = this.template.Footer_Margin__c == null ? 0 : this.template.Footer_Margin__c;
            if (records != null && !records.isEmpty()) {
                for (Sobject rec : records) {
                    // first page header div and it's style
                    String header1Element = '';
                    if (header1Map != null) {
                        String header1Style = 'position: running(header);';
                        header1Style += 'margin-top: ' + headerMargin + measuringUnit +';';
                        header1Element += '<div class="header" ';
                        header1Element += ' style="' + header1Style + '" ';
                        header1Element += '>';
                        header1Element += header1Map.get(rec.Id);
                        header1Element += '</div> \n';
                    }
                    // first page footer div and it's style
                    String footer1Element = '';
                    if (footer1Map != null) {
                        String footer1Style = 'position:fixed; ';
                        footer1Style += 'bottom: 0; ';
                        footer1Style += 'margin-bottom: ' + footerMargin + measuringUnit +';';
                        footer1Element += '<div class="footer" ';
                        footer1Element += ' style="' + footer1Style + '" ';
                        footer1Element += '>';
                        footer1Element += footer1Map.get(rec.Id);
                        footer1Element += '</div> \n';
                    }
                    String body = '';
                    // add header div to body
                    body += header1Element;
                    // add footer div to body
                    body += footer1Element;
                    // Extract the css for related list tables in an Array of Strings
                    // (element at index 0 is the body content without the related lists css)
                    List<String> relatedListsStyleList = extractStyleTags(bodyMap.get(rec.Id));
                    body += relatedListsStyleList.remove(0);
                    
                    // page size
                    String sizeAttribute = '';
                    if (String.isNotBlank(this.template.Page_Size__c)) {
                        sizeAttribute = this.template.Page_Size__c  + ' ';
                    } else {
                        if (this.template.Page_Height__c != null && this.template.Page_Width__c != null) {
                            sizeAttribute = this.template.Page_Height__c + measuringUnit + ' ';
                            sizeAttribute += this.template.Page_Width__c +  measuringUnit + ' ';
                        }
                    }
                    if (String.isNotBlank(sizeAttribute))
                        sizeAttribute += this.template.Orientation__c != null ? this.template.Orientation__c : 'portrait';
                    sizeAttribute = String.isNotBlank(sizeAttribute) ? 'size: ' + sizeAttribute + ';\n' : '';
                    
                    // page margins
                    String margins = '';
                    if (this.template.Page_Margin_Top__c != null)
                        margins += 'margin-top: ' + this.template.Page_Margin_Top__c + measuringUnit + ';\n';
                    if (this.template.Page_Margin_Right__c != null)
                        margins += 'margin-right: ' + this.template.Page_Margin_Right__c + measuringUnit + ';\n';
                    if (this.template.Page_Margin_Bottom__c != null)
                        margins += 'margin-bottom: ' + this.template.Page_Margin_Bottom__c + measuringUnit + ';\n';
                    if (this.template.Page_Margin_left__c != null)
                        margins += 'margin-left: ' + this.template.Page_Margin_Left__c + measuringUnit + ';\n';
                      
                    // Document style in head tag
                    String headStyle = '<style>';
                    headStyle += '@page {\n';
                    // page settings
                    headStyle += sizeAttribute;
                    headStyle += margins;
                    // header
                    headStyle += ' @top-center {\n';
                    headStyle += 'content: element(header);\n';
                    headStyle += '}\n';
                    // footer
                    headStyle += ' @bottom-center {\n';
                    headStyle += 'content: element(footer);\n';
                    headStyle += '}\n';
                    //closing @page
                    headStyle += '}\n';
                    headStyle += String.join(relatedListsStyleList, '\n');
                    headStyle += '</style>\n';
                    
                    if(records.indexOf(rec) < records.size() - 1) {
                        body += '<div style="display: block; page-break-before: always;"/>';
                    }
                    Integer size = headStyle.length() + body.length();
                    String attachmentName = namesMap == null ? this.template.Name + ' - '+ system.now() : namesMap.get(rec.Id);
                    if (attachmentName.length() > 80)
                        attachmentName = attachmentName.substring(0,79);
                    document = new Negoptim_Document__c(Name = attachmentName, Head__c = headStyle, Body__c = body, template__c = this.template.Id,
                                                        Content_Size__c = size, version__c = 'New', Parent_Record_Id__c = rec.Id);
                    generatedDocumentsList.add(document);
                }
            }
            return generatedDocumentsList;
        } catch (Exception ex) {
            Database.rollback(sp);
            return null;
        }
    }
    
    /**
     * @description parses the string passed as parameter and generates a string where all tokens are replaced with real time value from
     * the database.
     * it goes through the following steps
     * 1-remove all line breaks from source
     * 2-extract and validate fields from source
     * 3-extract and parse xml markup in source
     * 4-generate a query that contains all validated fields and inner queries of all validated child relationships
     * 5-execute the query
     * 6-replace the tokens with there equivalent values (fields with real-time values & relatedLists with HTML tables)
     * @param the string to parse: template Body
     * @return a map recordID -> generatedString
     ******************************************************************************************************************************** */
    public Map<Id, String> parse(String source) {
        Map<id, String> generatedContentMap = new Map<Id, String>();
        if (String.isEmpty(source)) {
            for (Id recordId : recordsIds) {
                generatedContentMap.put(recordId, source);
            }                
        }
        String output = '';
        // Test if the body is null or empty to exit.
        if (source == null || source == '')
            return generatedContentMap;
        source = removeLineBreaks(source);
        // Instantiate a Pattern object and compile.
        Pattern p = Pattern.compile(FIELD_TOKEN_REGEX);
        // Instantiate a Matcher object which take the template body as parameter.
        Matcher matcher = p.matcher(source);
        validFieldsMap = extractFields(source, matcher);
        parseXml(extractXml(source));
        records = database.query(generateQuery(validFieldsMap)) ;//queryResults(validFieldsMap);
        for(SObject item : records) {
            output = replaceFieldTokensWithValues(item, source);
            output = generateHtmlFromRelatedLists(item, output);
            generatedContentMap.put(item.Id, output);
        }
        return generatedContentMap;
    }  
    
    /**
     * @description remove all line breaks (\n, \r) from the String passed as parameter
     * @param source
     * @return the resultant String without any line breaks
     ******************************************************************************************************************************** */
    private static String removeLineBreaks(String source) {
        
        String regexr = '\\r';
        Pattern pr = Pattern.compile(regexr);
        Matcher mr = pr.matcher(source);
        while (mr.find()) {
            source = source.replace(mr.group(), '');
        }
        
        String regexn = '\\n';
        Pattern pn = Pattern.compile(regexn);
        Matcher mn = pn.matcher(source);
        while (mn.find()) {
            source = source.replace(mn.group(), '');
        }
        return source;
    }
    
    /**
     * @ return Map of valid fields matching FIELD_TOKEN_REGEX
     ******************************************************************************************************************************** */
    private Map<String, Schema.SObjectField> extractFields(String templateBody, Matcher matcher) {
        Map<String, Schema.SObjectField> fields = new Map<String, Schema.SObjectField>();
        // When matcher.find() is true, split and validate each fiels.
        Pattern p = Pattern.compile(FIELD_FORMAT_REGEX);
        while (matcher.find()) {
            // List of fields as String.
            String field = matcher.group(1);
            Matcher m = p.matcher(field);
            if (m.find()){
                field = m.group(1);
            }
            List<String> theFields =  field.split('\\.');
            String temp = theFields.remove(0);
            if (temp == this.apiName ) { // to check if merge field contains object name
                SObjectField theField = validateField(apiName, theFields);
                if (theField != null) {
                    fields.put(field.toLowerCase(), theField);
                }
            }
        }
        return fields;
    }
    
    /**
     * @param a list of strings representing an sObject field split by the . to seperate lookups
     * @param odjName the api name of the sObject that has the field
     * @return an SObjectField if the field exists
     * @return null if the field isn't found
     ******************************************************************************************************************************** */
    private Schema.SObjectField validateField(String objName, List<String> theFields) {
        SObjectField result = null;
        // Get SObject of the object name string value.
        SObject sObj = Schema.getGlobalDescribe().get(objName).newSObject();
        // Check if the field name is validated or not and return.
        Map<String, Schema.SObjectField> fieldMap = sObj.getSobjectType().getDescribe().fields.getMap();
        if(theFields.size() == 1) {
            result = fieldMap.get(theFields.get(0));
        }
        else if (theFields.size() != 0) {
            String lookupField = theFields.get(0).replace('_r', '_c');
            // Special cases
            if(lookupField == 'Owner') lookupField += 'Id';
            if(fieldMap.containsKey(lookupField)) {
                Schema.SObjectField field = fieldMap.get(lookupField);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                List<Schema.sObjectType> sObjectTypeList = fieldDescribe.getReferenceTo();
                if (sObjectTypeList.size() > 0) {
                    theFields.remove(0);
                    if(sObjectTypeList.size() == 2) {
                        result = validateField(sObjectTypeList.get(1).getDescribe().getName(), theFields);
                    }
                    result = validateField(sObjectTypeList.get(0).getDescribe().getName(), theFields);
                }
            }
        }
        return result;
    }
    
    /**
     * @param record
     * @param source
     * @return String where all tokens are replaced with their values
     * @description replaces all field tokens in source with their values from record
     ******************************************************************************************************************************** */
    private String replaceFieldTokensWithValues(sObject record, String source) {
        String body = source;
        sObject originalRecord = record;
        Pattern p = Pattern.compile(FIELD_TOKEN_REGEX);
        Matcher matcher = p.matcher(source);
        Pattern p2 = Pattern.compile(FIELD_FORMAT_REGEX);
        // While the matcher is found, replace the matcher by the result got from database.
        while (matcher.find()) {
            String token = matcher.group(1);
            Matcher m = p2.matcher(token);
            String format='';
            if (m.find()){
                token = m.group(1);
                format = m.group(2);
            }
            // insert today's date if token is variable
            if (token.equalsIgnoreCase('#DocumentDate')) {
                if (String.isEmpty(format)) {
                    source = source.replace(matcher.group(), NegoptimTemplatesHelper.formatDate(Date.today(), format));
                } else {
                    source = source.replace(matcher.group(), NegoptimTemplatesHelper.formatDate(Date.today(), 'dd/MM/yyyy'));
                }
            } else if(!validFieldsMap.containsKey(token.toLowerCase())) {
                //TODO: SEND ERROR REPORT
                source = source.replace(matcher.group(), EMPTY);
                continue;
            } else {
                DisplayType currentFieldType = validFieldsMap.get(token.toLowerCase()).getDescribe().getType();
                List<String> currentFields = token.split('\\.');
                currentFields.remove(0); // remove sobject name
                record = originalRecord;
                if (currentFields.size() > 1) {
                    for(Integer i = 0; i < currentFields.size(); i++) {
                        if(record != null) {
                            record = record.getSObject(currentFields.remove(0));
                            if (!currentFields[0].equalsIgnoreCase(String.valueOf(validFieldsMap.get(token.toLowerCase())))
                                && i == currentFields.size() - 1) {
                                i--;
                            }
                        } else {
                            break;
                        }
                    }
                }
                try {
                    // iterate to next match if no data for reference fields
                    if(record == null) {
                        source = source.replace(matcher.group(), EMPTY);
                        continue;
                    }
                    //currentFields[0] = currentFields[0].replace('__r', '__c');
                    if(record.get(currentFields[0]) == null) {
                        source = source.replace(matcher.group(), EMPTY);
                    } else {
                        String currentFieldValue = String.valueOf(record.get(currentFields[0]));
                        // Format currencies
                        if(currentFieldType == Schema.DisplayType.CURRENCY || currentFieldType == Schema.DisplayType.INTEGER
                           ||currentFieldType == Schema.DisplayType.DOUBLE || currentFieldType == Schema.DisplayType.PERCENT) {
                               Decimal d = (Decimal)Decimal.valueOf(currentFieldValue);
                               if (!String.isEmpty(format)){
                                   currentFieldValue = NegoptimTemplatesHelper.formatDecimal(d, format);
                               } else {
                                   currentFieldValue = d + '';
                               }
                           }
                        // Format dates
                        if(currentFieldType == Schema.DisplayType.DATE || currentFieldType == Schema.DisplayType.DATETIME) {
                            Date d = (Date)Date.valueOf(currentFieldValue);
                            if (!String.isEmpty(format)){
                                currentFieldValue = NegoptimTemplatesHelper.formatDate(d, format);
                            } else {
                                currentFieldValue = d + '';
                            }
                        }
                        // Format text fields
                        if (currentFieldType == Schema.DisplayType.TEXTAREA) {
                            String text = currentFieldValue;
                            currentFieldValue = formateLineBreaks(text);
                        }
                        source = source.replace(matcher.group(), currentFieldValue);
                    }
                } catch(Exception ex) {
                    source = source.replace(matcher.group(), 'Somthing Went Terribly Wrong');
                }
            }
        }   
        return source;
    }
    
    /**
     * @description replaces line breaks with <br/>
     * @parameter text the text that contains line breaks (\n \r \n\r)
     * @return String
	*/
    private String formateLineBreaks(String text) {
        return text.replace('\r\n', '<br/>').replace('\n', '<br/>').replace('\r', '<br/>');
    }
    
    /**
     * @description parses the string passed as parameter and extracts all xml
     * @param content
     * @return Map each xml is pushed to the map as value with a key the index in with it was found
     ******************************************************************************************************************************** */
    public Map<integer, Dom.Document> extractXml(String content) {
        integer keyIndex = 1;
        Map<integer, Dom.Document> xmlMap = new Map<integer, Dom.Document>();
        Pattern p = Pattern.compile(RELATED_LIST_XML_REGEX);
        Matcher m = p.matcher(content);
        while(m.find()){
            String xmlString = m.group(1);
            Dom.Document doc = new Dom.Document();
            doc.load(xmlString);
            xmlMap.put(keyIndex++, doc);
        }
        return xmlMap;        
    }
    
    /*
     * @description
     * parses a map of xml documents in order to:
     * 1 - create a list of inner queries (one query of every child relationship)
     * 2- create maps that contain necessary data to replace field names with their values in related lists
     ******************************************************************************************************************************** */
    public void parseXml(Map<integer, Dom.Document> xmlMap) {
        Dom.Document xmlDoc = new Dom.Document();
        Map<String, List<String>> relationshipFieldsMap = new Map<String, List<String>>();
        Map<String, List<String>> relationshipConditionsMap = new Map<String, List<String>>();
        childRelationshipMap = new Map<Integer, WrapperChildRelationship>();
        
        for (Integer keyIndex : xmlMap.keySet()) {
            WrapperChildRelationship wRelationship = new WrapperChildRelationship();
            wRelationship.index = keyIndex;
            childRelationshipMap.put(keyIndex, wRelationship);
            xmlDoc = xmlMap.get(keyIndex);
            Dom.XMLNode root = xmlDoc.getRootElement();
            String childRelationshipName;
            SObjectType childSObject;
            for (Dom.XmlNode child : root.getChildElements()) {
                String childName = child.getName();
                if (childName.equalsignoreCase('listname')) {
                    ChildRelationship childRelationship = validateRelationship(apiName, child.getText());
                    if (childRelationship != null) {
                        childSObject = childRelationship.getChildSObject();
                        childRelationshipName = childRelationship.getRelationshipName();
                        if (! relationshipFieldsMap.containsKey(childRelationshipName)) {
                            relationshipFieldsMap.put(childRelationshipName, new List<String>());
                        }
                        wRelationship.relationshipName = childRelationshipName;
                    } else {
                        childRelationshipMap.remove(keyIndex);
                        break;
                    }
                } else if (childName.equalsIgnoreCase('column')) {
                    String field = child.getText();
                    SObjectField columnField = NegoptimTemplatesHelper.validateField(childSObject.getDescribe().getName(),
                                                                                     field.split('\\.'));
                    if (columnField == null) {
                        WrapperColumn wc = new WrapperColumn();
                        wc.field = '';
                        childRelationshipMap.get(keyIndex).columns.add(wc);
                        continue;
                    }
                    WrapperColumn wc = new WrapperColumn();
                    wc.prefix = child.getAttribute('prefix', '') == null ? '' : child.getAttribute('prefix', '');
                    wc.postfix = child.getAttribute('postfix', '') == null ? '' : child.getAttribute('postfix', '');
                    wc.nullpostfix = child.getAttribute('nullpostfix', '') == null ? '' : child.getAttribute('nullpostfix', '');
                    wc.colspan = child.getAttribute('colspan', '') == null ? 0 : Integer.valueOf(child.getAttribute('colspan', ''));
                    wc.newrow = child.getAttribute('newrow', '') == null ? false : Boolean.valueOf(child.getAttribute('newrow', ''));
                    wc.field = child.getText();
                    DisplayType currentFieldType = columnField.getDescribe().getType();
                    wc.isNumber = (currentFieldType == Schema.DisplayType.CURRENCY || currentFieldType == Schema.DisplayType.INTEGER
                        ||currentFieldType == Schema.DisplayType.DOUBLE || currentFieldType == Schema.DisplayType.PERCENT);
                    wc.isDate = (currentFieldType == Schema.DisplayType.DATE || currentFieldType == Schema.DisplayType.DATETIME);
                    if (wc.isNumber) wc.format = child.getAttribute('format-number', '') == null ? '' : child.getAttribute('format-number', '');
                    if (wc.isDate) wc.format = child.getAttribute('format-date', '') == null ? '' : child.getAttribute('format-date', '');
                    if (!relationshipFieldsMap.containsKey(childRelationshipName)) {
                        relationshipFieldsMap.put(childRelationshipName, new List<String>{child.getText()});
                    } else {
                        if (!relationshipFieldsMap.get(childRelationshipName).contains(child.getText())){
                            relationshipFieldsMap.get(childRelationshipName).add(child.getText());
                        }
                    }                   
                    //childRelationshipMap.get(keyIndex).fields.add(child.getText());
                    childRelationshipMap.get(keyIndex).columns.add(wc);
                } else if (childName.equalsIgnoreCase('where')) {
                    if (!relationshipConditionsMap.containsKey(childRelationshipName)) {
                        relationshipConditionsMap.put(childRelationshipName, new List<String>{child.getText()});
                    } else {
                        relationshipConditionsMap.get(childRelationshipName).add(child.getText());
                    }
                    wRelationship.condition = child.getText();
                } else if (childName.equalsIgnoreCase('class')) {
                    wRelationship.style = child.getText();
                }
            }
        }
        integer numberOfRelationships = relationshipFieldsMap.size();
        innerSelectQueries = new List<String>(); 
        for(String key : relationshipFieldsMap.keySet()) {
            String selectClaus = 'SELECT';
            String fromClaus = 'FROM';
            String whereClaus = '';
            selectClaus += ' ' + String.join(relationshipFieldsMap.get(key), ',') + ' ';
            fromClaus += ' ' + key + ' '; 
            if (!relationshipConditionsMap.isEmpty()) {
                if (relationshipConditionsMap.containsKey(key)){
                    whereClaus += ' WHERE ' + String.join(relationshipConditionsMap.get(key), 'or') + ' ';   
                }
            }
            String str ='(' + selectClaus + fromClaus + whereClaus + ')';
            innerSelectQueries.add(str);
        }
    }
    
    /**
     * @description validate relationships of name relationshipName that belongs to objName
     * @param objName
     * @param relationshipName
     * @return ChildRelationship object relative to relationshipName
     ******************************************************************************************************************************** */
    private Schema.ChildRelationship validateRelationship(String objName, String relationshipName) {
        ChildRelationship cr;
        SObject sObj = Schema.getGlobalDescribe().get(objName).newSObject();
        for(ChildRelationship item: sObj.getSobjectType().getDescribe().getChildRelationships()) {
            if(item.getRelationshipName() == relationshipName) {
                cr = item;
                break;
            }
        }
        return cr;
    }
 
    
    /**
     * @description replace related lists with html tabels  
     ******************************************************************************************************************************** */ 
    private String generateHtmlFromRelatedLists(Sobject record, String source) {
        integer key = 1;
        Pattern xmlPattern = Pattern.compile(RELATED_LIST_XML_REGEX);
        Matcher xmlMatcher = xmlPattern.matcher(source);
        
        String query;
        while(xmlMatcher.find()) {
            String htmlTable = '<tbody>';
            if (childRelationshipMap.containsKey(key)) {
                List<WrapperColumn> wcolumnList = childRelationshipMap.get(key).columns;
                String uniqueId = childRelationshipMap.get(key).style;
                list<sObject> childRecords = record.getSObjects(childRelationshipMap.get(key).relationshipName);
                integer rowCount = 0;
                if (childRecords != null) {
                    for (sObject item : childRecords) {
                        sObject originalRecord = item;
                        htmlTable += math.mod(rowCount++, 2) == 0 ? ('<tr class="' + uniqueId +'RowEven">') : ('<tr class="' + uniqueId +'RowOdd">');
                            integer colCount = 0;
                        for (WrapperColumn wc : wcolumnList) {
                            htmlTable += '<td class="' + uniqueId + 'col' + colCount++ + '">';
                            String field = wc.field;
                            String[] fArray = field.split('\\.');
                            item = originalRecord;
                            for (Integer i = 1; i < fArray.size(); i++){
                                if(item != null) {
                                    item = item.getSObject(fArray.remove(0));
                                }
                            }
                            if (item == null) {
                                htmlTable += wc.nullpostfix;
                            } else {
                                String formatedValue = String.IsEmpty(fArray[0]) || fArray[0] == null ?
                                    '' : String.valueOf(item.get(fArray[0]));
                                if (String.IsEmpty(formatedValue) || formatedValue == null || formatedValue == 'null'){
                                    htmlTable += wc.nullpostfix;
                                    continue;
                                }
                                if (String.isNotEmpty(wc.format)) {
                                    if (wc.isNumber) {
                                        formatedValue = NegoptimTemplatesHelper.formatDecimal(Decimal.valueOf(formatedValue), wc.format);
                                    }
                                    if (wc.isDate) {
                                        formatedValue = NegoptimTemplatesHelper.formatDate(DateTime.valueOf(formatedValue), wc.format);
                                    }
                                }
                                htmlTable += wc.prefix + ' ' ;
                                htmlTable += formatedValue;
                                htmlTable += + ' ' + wc.postfix;
                            }
                            htmlTable += '</td>';
                        }
                        htmlTable += '</tr>';
                    }
                }
                htmlTable += '</tbody>';
                source = source.replace(xmlMatcher.group(), htmlTable);
                key += 1;
            }
        }
        return source;
    }
    
    /**
     * description Build the query
     * 1-with validated fields
     * 2-with inner select to validated child relationships
     * 3-order by the template's order field
     * 4-limit 1000 records
     ******************************************************************************************************************************** */
    private String generateQuery(Map<String, Schema.SObjectField> columnsMap) {
        List<String> columns = new List<String>();
        for(String key : columnsMap.keySet()) {
            List<String> temp = key.split('\\.');
            temp.remove(0);
            String str = String.join(temp, '.');
            if(columnsMap.get(key).getDescribe().getType() == Schema.DisplayType.PICKLIST ||
               columnsMap.get(key).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST)
            {
                if (!columns.contains('toLabel('+str+')'))
                    columns.add('toLabel('+str+')');
            }
            else {
                if (!columns.contains(str))
                    columns.add(str);
            }
        }
        // Build the query which select the fields from the current object.
        String q = 'SELECT ';
        if(columns.size() > 0) {
            q += String.join(columns, ', ');
            if (!columns.contains('id')) {
                q += ', id';
            }
        }
        if (! innerSelectQueries.isEmpty() && innerSelectQueries != null) {
            q += ', ' + String.join(innerSelectQueries, ', ');
        }
        q += ' FROM ' + apiName;
        q += ' WHERE Id IN (\'' + String.join(recordsIds, '\',\'') +'\')';
        if (template != null && template.Mass_Print_Order_by_Field__c != null) {
            String[] field = template.Mass_Print_Order_by_Field__c.split('\\.');
            if (this.validateField(this.apiName, field) != null) {
                q += ' ORDER BY ' + template.Mass_Print_Order_by_Field__c;
            }
        }
        q += ' LIMIT 1000';
        return q;
    }
    
    /**
     * @description
     ******************************************************************************************************************************** */
    public static List<String> extractStyleTags(String source) {
        List<String> extractedStylesList = new List<String>();
        Pattern stylePattern = Pattern.compile(STYLE_TAG_REGEX);
        Matcher styleMatcher = stylePattern.matcher(source);
        while (styleMatcher.find()) {
            extractedStylesList.add(styleMatcher.group(1));
            source = source.replace(styleMatcher.group(), ' ');
        }
        if (!extractedStylesList.isEmpty()) {
            extractedStylesList.add(0, source);
        } else {
            extractedStylesList.add(source);
        }
        return extractedStylesList;
    }
      
    /********************************************************* WRAPPER CLASSES ********************************************************/
    
    /**
     * wrapper class for a related list
     * 
     ******************************************************************************************************************************** */
    public Class WrapperChildRelationship {
        public Integer index;
        public String relationshipName;
        public List<WrapperColumn> columns;
        public String condition;
        public String style;
        public integer selectionLimit;
        public String orderBy;
        
        public WrapperChildRelationship () {
           columns = new List<WrapperColumn>();
        }
    }
    
    public Class WrapperColumn {
        public String field;
        public String prefix;
        public String postfix;
        public String nullpostfix;
        public Integer colspan;
        public Boolean newrow;
        public Boolean isDate;
        public Boolean isNumber;
        public String format;
    }
    
    /****************************************************** END OF WRAPPER CLASSES *****************************************************/
    public class ParserException extends Exception {
        
    }
}