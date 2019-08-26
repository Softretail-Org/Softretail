public class NegoptimHelper {
    
    public static String FOLDER_SETTINGS_NAME = 'private';
    public static String DOCUMENT_SETTINGS_NAME = 'globalSettings';
    
    /**
     * Return Map of key = parent with value = Set of children BU Ids
     * if no children, value = itself
     * @param ids: Set of BU ids
     * */
    public static Map<Id, Set<Id>> getBUChildrenMap(Set<Id> ids) {
        Map<Id, Set<Id>> BUIdsMap = new Map<Id, Set<Id>>();
        List<Orga_BU__c> BUList = [SELECT Id, Name, Business_Unit_Type__c,
                                   (SELECT Entity_List__r.Id, Entity_List__r.Name, Entity_List__r.Business_Unit_Type__c
                                    FROM List_detail1__r
                                    WHERE Entity_List__r.Status__c = 'Open')
                                   FROM Orga_BU__c
                                   WHERE RecordType.DeveloperName IN ('Store', 'Web', 'Warehouse', 'Country', 'List', 'Group',
                                                                      'Banner', 'Assortment_Cluster')
                                   AND Status__c = 'Open'
                                   AND Id IN :ids];
        for(Orga_BU__c item : BUList) {
            if(!BUIdsMap.containsKey(item.Id)) {
                BUIdsMap.put(item.Id, new Set<Id>());
            }
            if(item.List_detail1__r.size() > 0) {
                // Cases of Business_Unit_Type__c = 'Country' or 'List' or 'Group'
                for(Orga_BU_List_Detail__c BUDetail : item.List_detail1__r) {
                    BUIdsMap.get(item.Id).add(BUDetail.Entity_List__r.Id);
                }
            } else {
                // Cases of Business_Unit_Type__c = 'Store' or 'Web' or 'Warehouse' or 'Banner'
                // put same Id if BU haven't children
                BUIdsMap.get(item.Id).add(item.Id);
            }
        }
        return BUIdsMap;
    }
    /**
     * Return Map of key = child with value = Set of parent BU Ids
     * if no parent, value = empty
     * @param ids: Set of BU ids
     * */
    public static Map<Id, Set<Id>> getBUParentsMap(Set<Id> ids) {
        Map<Id, Set<Id>> BUIdsMap = new Map<Id, Set<Id>>();
        for(Orga_BU_List_Detail__c item : [SELECT Entity__c, Entity_List__c
                                           FROM Orga_BU_List_Detail__c
                                           WHERE Entity_List__c IN :ids])
        {
            if(!BUIdsMap.containsKey(item.Entity_List__c)) {
                BUIdsMap.put(item.Entity_List__c, new Set<Id>{item.Entity__c});
            } else {
                BUIdsMap.get(item.Entity_List__c).add(item.Entity__c);
            }
        }
        return BUIdsMap;
    }
    /* Get group BU */
    public static Id getGroupBUFromGlobalSetttings() {
        Id groupBUId; String groupBUCode;
		NegoptimSettings negoSettings = GlobalSettingsManager.loadGlobalSettings();
        if(negoSettings != null){
            groupBUCode = negoSettings.groupBU;
        }
        if(String.isNotBlank(groupBUCode)){
            List<Orga_BU__c> groupBUs = [SELECT Id, Name, RecordType.Name FROM Orga_BU__c
                                         WHERE BU_Code__c =:groupBUCode AND RecordType.DeveloperName = 'Group' LIMIT 1];
            if(groupBUs != null && groupBUs.size() > 0){
                groupBUId = groupBUs.get(0).Id;
            }
        }
        if(groupBUId == null) throw new GlobalSettingsException(string.format(Label.MSG_GroupBUNotExist, new String[]{ groupBUCode }) + '\n');
        return groupBUId;
    }
    /* Get folder settings */
    public static Folder getFolderSettings() {
        List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = :FOLDER_SETTINGS_NAME LIMIT 1];
        if(folders != null && folders.size() > 0) {
            return folders.get(0);
        }
        return null;
    }
    /**
     * Return the Package prefix name if exist or empty
     * @param includeUnderscore: add the 2 underscores separator
     * */
    public static String getPackagePrefix(Boolean includeUnderscore) {
        String prefix = NegoptimHelper.class.getName().substringBefore('NegoptimHelper').substringBefore('.');
        if(prefix != '' && includeUnderscore) {
            prefix = prefix + '__';
        }
        return prefix;
    }
    /**
     * Return Component Name with/Without package prefix dependent
     * on package type (managed/unmanaged)
     * @param name: Object/Field Name without prefix
     * */
    public static String normalizeAPIName(String name) {
        String prefix = getPackagePrefix(true);
        return prefix + name;
    }
	/**
     * Check Field Level Security for reading
     * @param fieldsMap
     * */
    public static Boolean checkAccessibilityFields(Map<String, SObjectField> fieldsMap, String[] fields) {
        Boolean result = true;
        for (String field : fields) {
            // Check if the user has read access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isAccessible()) {
                result = false;
                throw new NoAccessException('Insufficient access to read ' + field);
            }
        }
        return result;
    }
    /**
     * Check Field Level Security for reading
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public static Boolean checkAccessibility(Schema.SObjectType objType, String[] fields) {
        Boolean result = true;
        // check access on read SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isAccessible()) {
            result = false;
            throw new NoAccessException('Insufficient access to read ' + sObjectName);
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has read access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isAccessible()) {
                result = false;
                throw new NoAccessException('Insufficient access to read "' + sObjectName + '.' + field + '"');
            }
        }
        return result;
    }
    /**
     * Check Field Level Security for inserting
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public static Boolean checkCreatibility(Schema.SObjectType objType, String[] fields) {
        Boolean result = true;
        // check access on insert SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isCreateable()) {
            result = false;
            throw new NoAccessException('Insufficient access to insert ' + sObjectName);
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has create access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isCreateable()) {
                result = false;
                throw new NoAccessException('Insufficient access to insert "' + sObjectName + '.' + field + '"');
            }
        }
        return result;
    }
    /**
     * Check Field Level Security for updating
     * https://developer.salesforce.com/page/Enforcing_CRUD_and_FLS
     * */
    public static Boolean checkUpdatibility(Schema.SObjectType objType, String[] fields) {
        Boolean result = true;
        // check access on updatetrue SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isUpdateable()) {
            result = false;
            throw new NoAccessException('Insufficient access to update ' + sObjectName);
        }
        Map<String, SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
        for (String field : fields) {
            // Check if the user has update access on each field
            if (fieldsMap.get(field) == null || !fieldsMap.get(field).getDescribe().isUpdateable()) {
                result = false;
                throw new NoAccessException('Insufficient access to update "' + sObjectName + '.' + field + '"');
            }
        }
        return result;
    }
    /**
     * Check SObject Level Security for Deleting
     * */
    public static Boolean checkDeletibility(Schema.SObjectType objType) {
        Boolean result = true;
        // check access on delete SObject
        String sObjectName = objType.getDescribe().getName();
        if(!objType.getDescribe().isDeletable()) {
            result = false;
            throw new NoAccessException('Insufficient access to delete ' + sObjectName);
        }
        return result;
    }
    /**
     * Get Object RecordType Id by Name
     * @param sObjectType
     * @param recordTypeName
     * @example: Id recordTypeId = NegoptimHelper.getObjectRecordTypeId(Orga_BU__c.SObjectType, 'Country');
     * */
    public static String getObjectRecordTypeId(SObjectType sObjectType, String recordTypeName) {
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        // Check Accessibility.
        if(!checkAccessibilityFields(Schema.SObjectType.RecordType.fields.getMap(), new String [] {'Id'})) {
        	return Null;
        }
        RecordType rt;
        try {
            rt = [SELECT Id FROM RecordType WHERE SobjectType = :sObjectName AND DeveloperName = :recordTypeName LIMIT 1];
        } catch (Exception ex) {
            // If recordTypeName is wrong, then an Exception is thrown.
            throw new RecordTypeException('Record type "'+ recordTypeName +'" does not exist.');
        }
        //Return the record type id
        return rt.Id;
    }
    /**
     * Get Object RecordType Name by Id
     * @param sObjectType
     * @param recordTypeId
     * @example: String recordTypeName = NegoptimHelper.getObjectRecordTypeName(Orga_BU__c.SObjectType, '01224000000RmMHAA0');
     * */
    public static String getObjectRecordTypeName(SObjectType sObjectType, Id recordTypeId) {
        // Generate a map of tokens for all the Record Types for the desired object
        Map<Id, Schema.RecordTypeInfo> recordTypeInfo = sObjectType.getDescribe().getRecordTypeInfosById();
    
        if(!recordTypeInfo.containsKey(recordTypeId))
            throw new RecordTypeException('Record type "'+ recordTypeId +'" does not exist.');
    
        //Retrieve the record type id by name
        return recordTypeInfo.get(recordTypeId).getName();
    }
	/**
     * Get Object RecordType Map of Name/Id
     * @param sObjectType
     * */
    public static Map<String, Id> getObjectRecordTypeMapIds(SObjectType sObjectType) {
        Map<String, Id> rtMap = new Map<String, Id>();
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        // Check Accessibility.
        if(!checkAccessibilityFields(Schema.SObjectType.RecordType.fields.getMap(), new String [] {'Id', 'DeveloperName'})) {
        	return rtMap;
        }
        List<RecordType> rtList = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = :sObjectName AND IsActive = true];
        for(RecordType item : rtList) {
            rtMap.put(item.DeveloperName, item.Id);
        }
        //Return the record type id
        return rtMap;
    }
    /**
     * Get Object RecordType Map of Id/DeveloperName
     * @param sObjectType
     * */
    public static Map<Id, String> getObjectRecordTypeMapDeveloperNames(SObjectType sObjectType) {
        Map<Id, String> rtMap = new Map<Id, String>();
        // If sObjectType is wrong, then an Exception is thrown.
        String sObjectName = sObjectType.getDescribe().getName();
        // Check Accessibility.
        if(!checkAccessibilityFields(Schema.SObjectType.RecordType.fields.getMap(), new String [] {'Id', 'DeveloperName'})) {
        	return rtMap;
        }
        List<RecordType> rtList = [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = :sObjectName AND IsActive = true];
        for(RecordType item : rtList) {
            rtMap.put(item.Id, item.DeveloperName);
        }
        //Return the record type id
        return rtMap;
    }
    /**
     * Return the Label Names of Mandatory Fields.
     * */
    public static Map<String, string> GetMandatoryFieldLabels(SObjectType sObjectType) {
        // Map<Field Name, Field Label Name>
        Map<String, string> fieldNameLabels = new Map<String, string>();
        // Describe all fields for a particular object.
        Map<String, Schema.SObjectField> fieldsByName = sObjectType.getDescribe().fields.getMap();                      
        for (Schema.SObjectField eachField : fieldsByName.values()) {
            Schema.DescribeFieldResult describe = eachField.getDescribe();
            fieldNameLabels.put(describe.getName(), describe.getLabel());
        }
        return fieldNameLabels;
    }
    
    public class RecordTypeException extends Exception {}
    public class GlobalSettingsException extends Exception {}
    public class NoAccessException extends Exception {}
    /**
     * Get Orga_HE__c root element Id
     * */
    public static Id getRootId() {
        List<Orga_HE__c> elements = [SELECT Id FROM Orga_HE__c WHERE Parent_Element__c = null];
        if(elements != NULL && elements.size() > 0) {
            return elements.get(0).Id;
        }
        else {
            Orga_HE__c root = new Orga_HE__c(Name = 'ROOT', Elt_Code__c = 'ROOT', Parent_Element__c = null, Level__c = 0, Status_BDate__c = date.newInstance(System.today().year(), 1, 1));
            insert root;
            return root.Id;
        }
    }
    /**
     * Return the Corporate Currency if exist, else return ''.
     * */
    public static String getCorporateCurrency() {
        String currencyIsoCode = '';
        List<CurrencyType> currencies = [SELECT IsoCode FROM CurrencyType WHERE IsCorporate = true LIMIT 1];
        if(currencies != null && currencies.size() > 0) {
            currencyIsoCode = currencies.get(0).IsoCode;
        }
        return currencyIsoCode;
    }
    /**
     * Return the conversion rate of a currency if exist, else return 1.
     * */
    public static Double getConversionRate(String currencyISOCode) {
        Double conversionRate = 1;
        List<currencytype> currencies = [SELECT conversionrate FROM currencytype WHERE isocode = :currencyISOCode LIMIT 1];
        if(currencies != null && currencies.size() > 0) {
            conversionRate = currencies.get(0).conversionRate;
        }
        return conversionRate;
    }
    /**
     * Return the Map of all currency iso code with the conversion rate.
     * */
    public static Map<String, Double> getCurrencyMap() {
        Map<String, Double> currencies = new Map<String, Double>();
        List<currencytype> currenciesType = [SELECT isocode, conversionrate FROM currencytype LIMIT 400];
        for(currencytype item : currenciesType) {
            currencies.put(item.isocode, item.conversionrate);
        }
        return currencies;
    }
    /**
     * Return the separator of decimal number based on user locale.
     * */
    public static String getDecimalSeparator() {
        Decimal d = 1.98;
        String sD = d.format();
        return sD.contains(',') ? ',' : '.';
    }
    /**
     * Check String if it is a decimal number.
     * */
    public static Boolean isDecimal(String s) {
        Boolean ReturnValue;
        try{
            Decimal.valueOf(s);
            ReturnValue = TRUE; 
        } catch (Exception e) {
            ReturnValue = FALSE;
        }
        return ReturnValue;
    }
    /**
     * Return the decimal value of String.
     * */
    public static Decimal getDecimalValue(String s) {
        if(s == null)
            return null;
        String str = s.normalizeSpace();
        String decimalSeparator = getDecimalSeparator();
        str = str.replaceAll(' ', '');
        if(decimalSeparator == '.') {
            str = str.replaceAll(',', '');
        }
        if(decimalSeparator == ',') {
            str = str.replace(',', '.');
        }
        if(isDecimal(str)) {
            return Decimal.valueOf(str);
        }
        return null;
    }
    /**
     * Return a string for a number with format percentage.
     * */
    public static String formatPercentageValue(Decimal d, Boolean wildcard) {
        String decimalSeparator = getDecimalSeparator();
        String sPercent = d != null ? d.setScale(2).format() : '';
        if (sPercent != null && sPercent.trim() != '' && !sPercent.contains(decimalSeparator)) {
            sPercent += decimalSeparator + '00';
        }
        else if(sPercent != null && sPercent.contains(decimalSeparator)) {
            decimalSeparator = decimalSeparator == '.' ? '\\.' : decimalSeparator;
            if (sPercent.split(decimalSeparator)[1].length() < 2) {
                sPercent += '0';
            }
        }
        if(wildcard) {
            sPercent += '%';
        }
        return sPercent;
    }
    /**
     * Return a string for a decimal with format.
     * */
    public static String formatDecimalValue(Decimal d, Integer places) {
        decimal value = d != null ? d : 0;
        String rightValue = '';
        rightValue = rightValue.rightPad(places, '0') + '1';
        String sValue = (value.setScale(places) + Decimal.valueOf('0.' + rightValue)).format();
        return sValue.substring(0, sValue.length() -1);
    }
    /**
     * Return select option list for all countries
     * */
    public static List<SelectOption> getSelectOptionsCountries(Boolean defaultOption) {
        List<SelectOption> countries = new List<SelectOption>();
        if(defaultOption) {
            countries.add(new SelectOption('', '--'));
        }
        for(Orga_BU__c item: [SELECT Id, Name, Business_Unit_Type__c
                              FROM Orga_BU__c
                              WHERE Business_Unit_Type__c = 'Country'
                              OR Business_Unit_Type__c = 'Group'
                              ORDER BY Business_Unit_Type__c DESC]) {
                                  countries.add(new SelectOption(item.Id, item.Name));
                              }
        return countries;
    }
    /**
     * Parse CSV File.
     * @param contents: the content is a string.
     * @param skipHeaders: skip first line.
     * */
    public static List<List<String>> parseCSV(String contents, Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();
        // Replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field.
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        // Now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote.
        contents = contents.replaceAll('""','DBLQT');
        // We are not attempting to handle fields with a newline inside of them.
        // So, split on newline to get the spreadsheet rows.
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
        }
        for(String line : lines) {
            // Check for blank CSV lines (only commas).
            if (line.replaceAll(',','').trim().length() == 0) break;
            List<String> fields = line.split(',');
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) allFields.remove(0);
        return allFields;
    }
    /**
     * Parse CSV File.
     * @param contents: the content is a list of lines.
     * @param skipHeaders: skip first line.
     * @param separator: CSV columns separator.
     * */
    public static List<List<String>> parseCSV(List<String> lines, Boolean skipHeaders, String separator) {
    	// set default separator to comma
    	// TODO: get CSV separator from user settings 
    	if(separator == '' || separator == null) {
    		separator = ',';
    	}
        List<List<String>> allFields = new List<List<String>>();
        for(String line : lines) {
            // Check for blank CSV lines (only commas).
            if (line.replaceAll(separator,'').trim().length() == 0) break;
            List<String> fields = line.split(separator);
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += separator + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField += separator + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            allFields.add(cleanFields);
        }
        if (skipHeaders) allFields.remove(0);
        return allFields;
    }
    
    /**
     * Parse CSV File, Header not skipped, should be used in import csv batchs
     * @param contents: the content is a list of lines.
     * @param separator: CSV columns separator.
     * */
    public static List<List<String>> parseCSV(List<String> lines, String separator){
        return parseCSV(lines, false, separator);
    }
    /**
     * get default value from picklist.
     * @param dFR: the describing field result
     * */
    public static String defaultPicklistValue(Schema.DescribeFieldResult dFR) {
    	String defaultVal = '';
		List<Schema.PicklistEntry> pickVals = dFR.getPicklistValues();
		for (Schema.PicklistEntry pv: pickVals) {
		    if (pv.isDefaultValue()) {
		        defaultVal = pv.getValue();
                break;
		    }
		}
		return defaultVal;
    }
    /**
     * get default dynamic path for static ressources.
     * @param resourceName:  the resource name
     * */
    public static String GetResourceURL(String resourceName){
        
        // Fetching the resource
        List<StaticResource> resourceList= [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName];
        
        // Checking if the result is returned or not
        if(resourceList.size() == 1) {
            
            // Getting namespace
            String namespace = resourceList[0].NamespacePrefix;
            // Resource URL
            return '/resource/' + resourceList[0].SystemModStamp.getTime() + '/' + (namespace != null && namespace != '' ? namespace + '__' : '') + resourceName; 
        }
        else return '';
    }
    /**
     * get last day date in month of a given month and year
     * */
    public static Date getLastDayOfMonth(Integer year, Integer month) {
        return Date.newInstance(year, month, Date.daysInMonth(year, month));
    }
    /**
     * get last day date in month of a given date
     * */
    public static Date getLastDayOfMonth(Date aDate) {
        if(aDate == null) {
            return Date.newInstance(1000, 1, 1);
        }
        return Date.newInstance(aDate.year(), aDate.month(), Date.daysInMonth(aDate.year(), aDate.month()));
    }
    /**
     * @param numerator
     * @param denominator
     * @param decimalPlaces
     * return list of decimals number with the safe rest
     * Ex: 1000/3 = 333.33 + 333.33 + 333.34
     * */
    public static List<Decimal> smartDivision(Decimal numerator, Integer denominator, Integer decimalPlaces) {
        
        List<Decimal> listOfDecimals = new List<Decimal>(); 
        if(numerator == null || denominator == 0) {
            return listOfDecimals;
        }
        
        Decimal divisionResult = numerator.divide(denominator, decimalPlaces),
            diff = 0, total = 0;
        Integer remainder = math.mod(Integer.valueOf(numerator), denominator);
        
        if(remainder != 0) {
            for(Integer index = 1 ; index < denominator; index++) {
                listOfDecimals.add(divisionResult);
                total += divisionResult;
            }
            diff = numerator - total;
            listOfDecimals.add(diff);
        } else { // no gap
            for(Integer index = 1; index <= denominator; index++) {
                listOfDecimals.add(divisionResult);
            }
        }
        return listOfDecimals;
    }
    /**
     * This method validates an Id length (15 or 18) and validates
     * the possible characters that should exist within an Id using regular expressions.
     * */
    static public Boolean validateId(String Idparam) {
        String id = String.escapeSingleQuotes(Idparam);
        if((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id)) {
            return true;
        }
        return false;
    }
    /**
     * Return the calculate due date based on conditions
     * @param originDate: date origin
     * @param days: days to be added based on condition
     * @param condition: condition to be transformed depend on signification
     * */
    static public Date getDueDate(Date originDate, Integer days, String condition) {
        if(days == null || condition == null) {
            return originDate;
        }
        Integer paymentDays = Integer.valueOf(days);
        Date d;
        if(condition == 'End of Month') {
            d = NegoptimHelper.getLastDayOfMonth(originDate + paymentDays);
        }
        else if(condition == 'End of Month, the 15') {
            d = NegoptimHelper.getLastDayOfMonth(originDate + paymentDays) + 15;
        }
        else if(condition == 'Net') {
            d = originDate + paymentDays;
        }
        else if(condition == 'The 10') {
            d = setOnFixDay(originDate + paymentDays, 10);
        }
        else if(condition == 'The 15') {
            d = setOnFixDay(originDate + paymentDays, 15);
        }
        else if(condition == 'The 20') {
            d = setOnFixDay(originDate + paymentDays, 20);
        }
        else if(condition == 'Twice the Month') {
            d = originDate + paymentDays;
            if(d.day() <= 15) {
                d = setOnFixDay(originDate + paymentDays, 15);
            }
            else {
                d = NegoptimHelper.getLastDayOfMonth(originDate + paymentDays);
            }
        }
        else {
            d = originDate;
        }
        return d;
    }
    static private Date setOnFixDay(Date d, Integer i) {
        if(d.day() > i) {
            d = Date.newInstance(d.year(), d.month() + 1, i);
        }
        else {
            d = Date.newInstance(d.year(), d.month(), i);
        }
        return d;
    }
    
    /**
     * @param objectName Object API Name
     * @param the fields a list of lookup relationships that end with a field name: lookup1__r.lookup2__r.field__c
     * or objectName.lookup1__r.lookup2__r.field__c
    */
    public static Schema.SObjectField validateField(String objectName, List<String> theFields) {
        SObjectField result = null;
        String prefix = getPackagePrefix(true);
        if (!objectName.startsWith(prefix)) {
            objectName = prefix + objectName;
        }
        // Get SObject of the object name string value.
        SObject sObj = Schema.getGlobalDescribe().get(objectName).newSObject();
        // Check if the field name is validated or not and return.
        Map<String, Schema.SObjectField> fieldMap = sObj.getSobjectType().getDescribe().fields.getMap();
        if (theFields[0].equalsIgnoreCase(objectName)) {
            theFields.remove(0);
        }
        if(theFields.size() == 1) {
            result = fieldMap.get(theFields.get(0));
        }
        else if (theFields.size() != 0) {
            String lookupField = theFields.get(0).replace('_r', '_c');
            // Special cases
            if(lookupField == 'Owner' || lookupField == 'CreatedBy' || lookupField == 'LastModifiedBy' || lookupField == 'RecordType') {
                lookupField += 'Id';
            }
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
    
    static public String decodeBlob(Blob input, String charset) {
        final String hex = EncodingUtil.convertToHex(input);
        final Integer size = hex.length() >> 1;
        final List<String> bytes = new String[size];
        for (Integer i = 0; i < size; ++i) {
            bytes.set(i, hex.mid(i << 1, 2));
        }
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), charset);
    }
    
    static public Integer getWeekNumberByDate(Date sequencedate) {
        Integer numberOfWeek;
        if(sequencedate != null) {
            Date todaydateinstance = date.newinstance(sequencedate.year(), sequencedate.month(), sequencedate.day());            
            Integer currentyear = sequencedate.year();
            
            Date yearstartdate = date.newinstance(currentyear, 01, 01);
            Date year2ndweek = yearstartdate.adddays(7).tostartofweek();
            
            if(sequencedate < year2ndweek)
                return 1;
            integer numberDaysDue = year2ndweek.daysBetween(todaydateinstance);
            
            if(math.mod(numberDaysDue,7)==0)
                numberOfWeek = math.MOD(Integer.valueof(math.FLOOR( ( numberDaysDue )/7)),52)+1;
            else
                numberOfWeek = math.MOD(Integer.valueof(math.FLOOR( ( numberDaysDue )/7)),52)+2;
        }
        return numberOfWeek;
    }
}