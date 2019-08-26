public class GridSettingsController {
    public static List<String> standardObjectNameList = new List<String>{'Product2'};
    // This method retrieves all object list from Salesforce Org
    // You can filter out object list here, as per you use case
    @AuraEnabled(cacheable=true)
    public static List<ObjectWrapper> getObjects() {
        List<ObjectWrapper> objectList = new List<ObjectWrapper>();
        for (Schema.SObjectType sObjType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult objResult = sObjType.getDescribe();
            String objectName = objResult.getName();
            /*if (objResult.isCustom() || (objResult.isAccessible() && !objResult.isDeprecatedAndHidden() && !objResult.isCustomSetting() && objResult.getRecordTypeInfos().size() > 0 && objResult.isCreateable() &&
                                         !objResult.isCustom() && !objectName.contains('__') &&
                                         !objectName.containsignorecase('history') && !objectName.containsignorecase('tag') &&
                                         !objectName.containsignorecase('share') && !objectName.containsignorecase('feed')))*/
            if(objResult.isCustom() || standardObjectNameList.contains(objResult.getName()))
            {
                objectList.add(new ObjectWrapper(objectName, objResult.getLabel(), objResult.isCustom()));
            }
        }
        return objectList;
    }
    
    // fill Grid Settings List
    @AuraEnabled
    public static Map<String, Grid_Settings__mdt> getGridLayouts() {
        Map<String, Grid_Settings__mdt> results = new Map<String, Grid_Settings__mdt>();
        for(Grid_Settings__mdt item : [SELECT DeveloperName, MasterLabel, Language,
                                       NamespacePrefix, Label, QualifiedApiName, Object_Name__c, Columns__c
                                       FROM Grid_Settings__mdt
                                       ORDER BY Object_Name__c, MasterLabel
                                       LIMIT 1000])
        {
            item.Columns__c = String.isBlank(item.Columns__c) ? '[]' : item.Columns__c;
            results.put(item.DeveloperName, item);
        }
        return results;
    }
    
    // get all fields related to object
    @AuraEnabled
    public static Map<String, String> getAllFields(String objectName) {
        Map<String, schema.SObjectField> objectFieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Schema.DisplayType fieldType;
        String fieldLabel, fieldName;
        Map<String, String> fieldMap = new Map<String, String>();
        for(string key : objectFieldsMap.keySet()) {
            fieldType = objectFieldsMap.get(key).getDescribe().getType();
            fieldLabel = objectFieldsMap.get(key).getDescribe().getLabel();
            fieldName = objectFieldsMap.get(key).getDescribe().getName();
            if(fieldType == Schema.DisplayType.REFERENCE) {
                fieldLabel += ' >';
            }
            fieldMap.put(fieldName, fieldLabel);
        }
        return fieldMap;
    }
    
    // get all reference fields related to selected field
    @AuraEnabled
    public static Map<String, String> getAllReferenceFields(String fieldName, String objectName) {
        Map<String, String> fieldsMap = new Map<String, String>();
        String fieldReferenceName = '';
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(NegoptimHelper.normalizeAPIName(objectName)).getDescribe().fields.getMap().get(NegoptimHelper.normalizeAPIName(fieldName)).getDescribe();
        for(Schema.SObjectType fieldReference : fieldResult.getReferenceTo()) {
            fieldReferenceName = fieldReference.getDescribe().getName();
            Map<String, schema.SObjectField> fieldsReferenceMap = Schema.getGlobalDescribe().get(fieldReferenceName).getDescribe().fields.getMap();
            for(string key : fieldsReferenceMap.keySet()) {
                // Special cases
                if(fieldName.contains('__c')) fieldName = fieldName.replace('__c', '__r');
                if(fieldName == 'OwnerId' || fieldName == 'CreatedById' || fieldName == 'LastModifiedById' || fieldName == 'RecordTypeId') {
                    fieldName = fieldName.replace('Id', '');
                }
                fieldsMap.put(fieldName + '.' + fieldsReferenceMap.get(key).getDescribe().getName(), fieldsReferenceMap.get(key).getDescribe().getLabel());
            }
        }
        return fieldsMap;
    }
    
    // Get fields label for grid settings
    @AuraEnabled
    public static Map<String, FieldWrapper> getGridSettingsFieldsLabel(String objectName, String columns) {
        Map<String, FieldWrapper> templateFieldsMap = new Map<String, FieldWrapper>();
        List<FieldWrapper> gridFields = (List<FieldWrapper>) JSON.deserialize(columns, List<FieldWrapper>.class);
        Map<String, schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        Integer separatorIndex = 0;
        for(FieldWrapper field : gridFields) {
            FieldWrapper fieldWrapper = new FieldWrapper();
            if(field.fieldName.equals('')) {
                field.fieldLabel='--- Separator(' + (separatorIndex++) + ') ---';
                field.fieldName='Separator' + separatorIndex++;
                templateFieldsMap.put(field.fieldname, field);
                continue;
            }
            List<String> fields = field.fieldName.Split('\\.');
            String fieldName, fieldLabel, fieldReferenceName = '';
            if(fields.size() == 1) {
                fieldName = field.fieldName;
                fieldLabel = fieldMap.get(fields.get(0)).getDescribe().getLabel();
            } else {
                // case field is lookup
                String lookupField = fields.get(0).replace('_r', '_c');
                // Special cases
                if(lookupField == 'Owner' || lookupField == 'CreatedBy' || lookupField == 'LastModifiedBy' || lookupField == 'RecordType') {
                    lookupField += 'Id';
                } else {
                    lookupField = NegoptimHelper.normalizeAPIName(lookupField);
                }
                if(fieldMap.containsKey(lookupField)) {
                    fieldLabel = fieldMap.get(lookupField).getDescribe().getLabel();
                }
                Schema.DescribeFieldResult fieldResult = fieldMap.get(lookupField).getDescribe();
                for(Schema.SObjectType fieldReference : fieldResult.getReferenceTo()) {
                    fieldReferenceName = fieldReference.getDescribe().getName();                    
                    Map<String, schema.SObjectField> fieldsReferenceMap = Schema.getGlobalDescribe().get(fieldReferenceName).getDescribe().fields.getMap();
                    for(string key : fieldsReferenceMap.keySet()) {
                        if(key.toLowerCase() == fields.get(1).toLowerCase()) {
                            fieldLabel += ' .' + fieldsReferenceMap.get(key).getDescribe().getLabel();
                            fieldName = lookupField + '.' + field.fieldName;
                        }
                    }
                }
            }
            field.fieldName = fieldName;
            field.fieldLabel = fieldLabel;
            field.isInputField = field.isInputField;
            field.bgColor = field.bgColor;
            templateFieldsMap.put(fieldName, field);
        }
        return templateFieldsMap;
    }
    
    @AuraEnabled
    public static String save(String objectName, String selectedTemplate, String templateName, String columns) {
        String metadataRecordName = String.isNotBlank(selectedTemplate) ? selectedTemplate : templateName.replaceAll('[^a-zA-Z0-9\\s+]', '').replaceAll('\\s+', '_');
        Grid_Settings__mdt metadataRecord;
        try {
            if(String.isNotBlank(selectedTemplate)) {
                metadataRecord = [SELECT DeveloperName, MasterLabel, Language,
                                  NamespacePrefix, Label, QualifiedApiName, Object_Name__c, Columns__c
                                  FROM Grid_Settings__mdt WHERE DeveloperName = :selectedTemplate];
            }
            // Set up custom metadata to be created in the subscriber org.
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'Grid_Settings__mdt.' + metadataRecordName;
            customMetadata.label = metadataRecord != null ? metadataRecord.Label : templateName;
            // Add all the field values
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = 'Object_Name__c';
            customField.value = objectName;
            customMetadata.values.add(customField);
            customField = new Metadata.CustomMetadataValue();
            customField.field = 'Columns__c';
            customField.value = columns;
            customMetadata.values.add(customField);
            Id jobId = null;
            if(!Test.isRunningTest()) {
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                mdContainer.addMetadata(customMetadata);
                
                // Setup deploy callback, MyDeployCallback implements
                // the Metadata.DeployCallback interface 
                CustomMetadataCallback callback = new CustomMetadataCallback();
                
                // Enqueue custom metadata deployment
                // jobId is the deployment ID
                jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
            }
            return jobId;
        } catch(Exception ex) {
            System.assert(false,ex.getMessage());
            return 'Error while creating new button.';
        }
    }
    
    //Object wrapper class having object properties like name, label and isCustom
    public class ObjectWrapper {
        @AuraEnabled public String objectName;
        @AuraEnabled public String objectLabel;
        @AuraEnabled public Boolean isCustom;
        ObjectWrapper(String objectName, String objectLabel, Boolean isCustom){
            this.objectName = objectName;
            this.objectLabel = objectLabel;
            this.isCustom = isCustom;
        }
    }
    
    public class FieldWrapper {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public Boolean isInputField;
        @AuraEnabled public String bgColor;
    }
}