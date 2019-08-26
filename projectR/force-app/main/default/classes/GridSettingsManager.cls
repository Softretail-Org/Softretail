/**
 * @author ULiT
 * @date 16/3/2019
 * @description Manages the settings for pages with daynamic grids
 * specify in the constructor the Sobject ApiName, the static fields that are mandaory for the back-end controller, and the developerName of the metadata record 
 * that registers the fields to be dispalyed in the dynamic grid
 * the constructors does the necessary validations and fills the attributes  
*/

public class GridSettingsManager {
    
    private final String OBJECT_NAME;
    private final String STATIC_FIELDS;
    ////private Boolean toExport = false;
    
    public final List<String> ALL_FIELDS {get; set;}
    public final List<FieldWrapper> GRID_FIELDS {get; set;}
    public final List<String> ERRORS {get; set;}
    public Map<String, Map<String, String>> picklistValuesMap {get; set;}
        
    public GridSettingsManager(String objectName, String staticFields, String metadataDeveloperName) {
        this.OBJECT_NAME = objectName;
        this.STATIC_FIELDS = staticFields;
        this.picklistValuesMap =new Map<String, Map<String, String>>();
        ALL_FIELDS = new List<String>();
        ERRORS = new List<String>();
        try {
            if(String.isNotBlank(STATIC_FIELDS)) this.ALL_FIELDS.addAll(STATIC_FIELDS.toLowerCase().split(','));
            if(String.isNotBlank(metadataDeveloperName)) {
                // load fields of the selected grid from custom metadata type
                List<Grid_Settings__mdt> gridLayouts = [SELECT Columns__c, Object_Name__c FROM Grid_Settings__mdt WHERE DeveloperName = :metadataDeveloperName];
                if(!gridLayouts.isEmpty()) {
                    Grid_Settings__mdt gridLayout = gridLayouts[0];
                    if (!OBJECT_NAME.equalsIgnoreCase(gridLayout.Object_Name__c)) {
                        this.ERRORS.add('Template Object not Compatible with page Object');
                    }
                    List<FieldWrapper> savedGridFields = (List<FieldWrapper>) JSON.deserialize(gridLayout.Columns__c, List<FieldWrapper>.class);
                    this.GRID_FIELDS = new List<FieldWrapper>();
                    String previousFieldvalue = savedGridFields.isEmpty() ? '' : savedGridFields.get(0).fieldName;
                    for(FieldWrapper field : savedGridFields) {
                        field.isBorderColumn = previousFieldvalue.equals('');
                        previousFieldvalue = NegoptimHelper.normalizeAPIName(field.fieldName);
                        if (!field.fieldName.equals('')) {
                            List<String> fields = NegoptimHelper.normalizeAPIName(field.fieldName).split('\\.');
                            Schema.SObjectField fieldResult = NegoptimHelper.validateField(gridLayout.Object_Name__c, fields.clone());
                            if (fieldResult != null) {
                                DescribeFieldResult dfr = fieldResult.getDescribe();
                                field.fieldLabel = dfr.getLabel();
                                field.fieldType = dfr.getType();
                                field.isCalculated = dfr.isCalculated();
                                field.scale = dfr.getScale();
                                field.isReference = fields.size() > 1;
                                if (field.fieldType == DisplayType.Picklist) {
                                    this.picklistValuesMap.put(field.fieldName, new Map<String, String>());
                                    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                                        this.picklistValuesMap.get(field.fieldName).put(pe.getValue(), pe.getLabel());
                                    }
                                }
                                // insert fields to query
                                if(!this.ALL_FIELDS.contains(field.fieldName.toLowerCase())) {
                                    this.ALL_FIELDS.add(field.fieldName.toLowerCase());
                                }
                                this.GRID_FIELDS.add(field);
                            }
                        }
                    }
                } else {
                    this.ERRORS.add('Grid settings not found.');
                }
            } else {
                this.ERRORS.add('Grid settings not found.');
            }
        } catch(Exception e) {
            this.ERRORS.add('Error Occured:' + e.getStackTraceString() + ' - ' + e.getLineNumber());
        }
    }
    
    /**
     * @param innerQueries a list of String each string represents a well-constructed inner query(without the parantheses)
     * @param whereClause a string of conditions for the query
     * @param order BY a string of the order by clause (without ORDER BY)
     * @return String a well constructed query
     * @description builds a string query including the static fields and dynamic fields and the inner queries
	*/    
    public String buildQuery(List<String> innerQueries, List<String> conditions, String orderBy) {
        String query = 'SELECT ';
        /*List<String> fieldsList = new List<String>();
        for (String fieldName : this.ALL_FIELDS) {
            Schema.SObjectField fieldResult = NegoptimHelper.validateField(OBJECT_NAME, fieldName.split('\\.'));
            if (fieldResult != null) {
                fieldsList.add(fieldResult.getDescribe().getType() == DisplayType.PICKLIST && this.toExport ? 'toLabel(' + fieldName + ')' : fieldName);
            }
        }
        query += !fieldsList.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(fieldsList), ',')) : '';
        query += !fieldsList.isEmpty() && innerQueries!= null && !innerQueries.isEmpty() ? ',' : '';*/
        query += !this.ALL_FIELDS.isEmpty() ? String.escapeSingleQuotes(String.join(new List<String>(this.ALL_FIELDS), ',')) : '';
        query += !this.ALL_FIELDS.isEmpty() && innerQueries!= null && !innerQueries.isEmpty() ? ',' : '';
        query += (innerQueries != null && !innerQueries.isEmpty()) ? ' (' + String.join(innerQueries, '),(') + ')' : '';
        query += ' FROM ' + this.OBJECT_NAME;
        query += conditions != null && !conditions.isEmpty() ? ' WHERE ' + String.join(conditions, ' AND ') : '';
        orderBy = String.isNotBlank(orderBy) && orderBy.containsIgnoreCase('ORDER BY') ? orderBy.removeStart('').removeStartIgnoreCase('order by') : orderBy;
        query += String.isNotBlank(orderBy) ? ' ORDER BY ' + orderBy : '';
        query += ' LIMIT 10000';
        return query;
    }
    
    /*public void setToExport(Boolean toExport) {
        this.toExport = toExport;
    }*/
    
    public class FieldWrapper {
        public String fieldName {get; set;}
        public String fieldLabel {get; set;}
        public String bgColor {get; set;}
        public Schema.DisplayType fieldType {get; set;}
        public String stringFieldType {
            get {return String.valueOf(fieldType);}
            set;
        }
        public Boolean isSortable {
            get {
                return fieldType == DisplayType.Date || fieldType == DisplayType.Time || fieldType == DisplayType.DateTime
                    || fieldType == DisplayType.Double || fieldType == DisplayType.Integer || fieldType == DisplayType.Long
                    || fieldType == DisplayType.Percent || fieldType == DisplayType.Currency
                    || fieldType == DisplayType.Picklist || fieldType == DisplayType.String;
            }
            set;
        }
        public Boolean isReference {get; set;}
        public Boolean isInputField {get; set;}
        public Boolean isCalculated {get; set;}
        public Boolean isBorderColumn {get; set;}
        public Integer scale {get; set;}
        
        public FieldWrapper(String fieldName, Boolean isInputField){
            this.fieldName = fieldName;
            this.isInputField = isInputField;
        }
    }
    
}