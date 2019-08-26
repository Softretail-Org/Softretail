public with sharing class MarketDataCollectionImportController {
    
    @AuraEnabled public String nielsenFileFormat {get; set;}
    @AuraEnabled public String processingMessage {get; set;}
    @AuraEnabled public String errorMessage {get; set;}
    @AuraEnabled public String flowType {get; set;}
    @AuraEnabled public String categoryName {get; set;}
    @AuraEnabled public Boolean isWeekly {get; set;}
    @AuraEnabled public Boolean isMonthly {get; set;}
    @AuraEnabled public Integer year {get; set;}
    @AuraEnabled public Integer month {get; set;}
    
    @AuraEnabled
    public static MarketDataCollectionImportController initClass() {
        // create class instance
        MarketDataCollectionImportController instance = new MarketDataCollectionImportController();
        instance.nielsenFileFormat = 'Nielsen file format: Weekly(Nielsen_Category_WWWYYYY_4SDDMMYYYY), Monthly(Nielsen_Category_MWWYYYY_4SDDMMYYYY)';
        instance.processingMessage = '';
        instance.errorMessage = '';
        instance.flowType = null;
        instance.categoryName = null;
        instance.isWeekly = false;
        instance.isMonthly = false;
        instance.year = null;
        instance.month = null;
        // return class instance
        return instance ;
    }
    
    @AuraEnabled
    public static MarketDataCollectionImportController import(String fileName, Map<String, Id> fileIdMap, MarketDataCollectionImportController instance) {
        try {
            if (!fileIdMap.isEmpty()) {
                List<Orga_BU__c> masterBUs = [SELECT Id, Name, RecordType.Name FROM Orga_BU__c WHERE IsMasterBU__c = true LIMIT 1];
                if (!masterBUs.isEmpty()) {
                    Id masterBUId = masterBUs.get(0).Id;
                    if(String.isNotBlank(instance.flowType) && String.isNotBlank(instance.categoryName) && (instance.isWeekly || instance.isMonthly) && instance.year != null && instance.month != null) {
                        Id batchInstanceId = Database.executeBatch(new MarketDataCollectionImportBatch('MarketDataCollectionImportController', fileIdMap, 1, masterBUId,
                                                                                                       instance.flowType, instance.categoryName, instance.isWeekly, instance.isMonthly, 
                                                                                                       instance.year, instance.month, null, null), 1500);
                        // set value in class properties
                        instance.processingMessage = string.format(Label.MSG_Job_In_Progress, new String[]{'Market Data Collection Import', (String)batchInstanceId});
                        instance.errorMessage = '';
                    } else {
                        instance.errorMessage = string.format(Label.MSG_Invalid_File_Format, new String[]{ fileName }) + ' \n' + instance.nielsenFileFormat + ' \n';
                    }
                } else {
                    instance.errorMessage = Label.MSG_MasterBU_Not_Exist;
                }
            }
        } catch (Exception ex) {
            if(!fileIdMap.isEmpty()) {
                if (NegoptimHelper.checkDeletibility(ContentDocument.SObjectType)) {
                    DELETE [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileIdMap.values())];
                }
            }
            instance.errorMessage = ex.getMessage() + ' - ' + ex.getLineNumber();
        }
        return instance;
    }
    
    @AuraEnabled
    public static String getObjectType() {
        // Passing the sObject name in the method, it could be multiple objects too
        return getDescribedObjects( new List<String>{'ContentVersion'} );
    }
    
    public static String getDescribedObjects(List<String> lstSObjectType) {
        // Globally desribe all the objects
        Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
        // Create a JSON string with object field labels and picklist values
        String allObjJSON = '{';
        // Iterate over the list of objects and describe each object
        for(String sObjectType : lstSObjectType) {
            if(allObjJSON != '{') allObjJSON += ', ';
            allObjJSON += '"' + sObjectType + '": ';
            DescribeSObjectResult describeResult = globalDescribe.get(sObjectType).getDescribe();
            Map<String, Schema.SObjectField> desribedFields = describeResult.fields.getMap();
            String objJSON = '{';
            for(String fieldName : desribedFields.keySet()) {
                // Descirbe the field
                Schema.SObjectField field = desribedFields.get(fieldName);
                Schema.DescribeFieldResult f = field.getDescribe();
                if(objJSON != '{') objJSON += ', ';
                // Get the field label and append in the JSON string
                objJSON += '"' + f.getName() + '": ' + '{ "label" : "' + f.getLabel() + '"';
                // if it's a picklist field then also add the picklist options
                if(field.getDescribe().getType() == Schema.DisplayType.PICKLIST) {
                    List <Schema.PicklistEntry> picklistValues = field.getDescribe().getPickListValues();
                	List<String> pickListOptions = new List<String>();
                    pickListOptions.add('{ "label": "--None--", "value": null }');                    
                    for (Schema.PicklistEntry pe : picklistValues) {
                        pickListOptions.add('{ "label": "' + pe.getLabel() + '", "value": "' + pe.getValue() + '" }');
                    }
                    objJSON += ', "picklistOptions": [' + String.join(pickListOptions, ', ') + ']';
                }
                objJSON += '}';
            }
            objJSON += '}';
            allObjJSON += objJSON;
        }
        // Close the object in the JSON String
        allObjJSON += '}';
        return allObjJSON;
    }
    
    @AuraEnabled
    public static List<ContentVersion> getContentVersions(Map<String, Id> fileIdMap) {
        return [SELECT Id, Title, Description, FileType, Owner.Name, VersionNumber, CreatedBy.Name, ContentSize FROM ContentVersion
                WHERE Id IN :fileIdMap.values()];
    }
    
    @AuraEnabled
    public static String getMarketHeadTabURL() {
        String URL;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        for(Schema.DescribeTabSetResult tsr : tabSetDesc) {
            tabDesc.addAll(tsr.getTabs());
        }
        String sObjectName = Market_Data_Collection_Head__c.SObjectType.getDescribe().getName();
        for(Schema.DescribeTabResult tr : tabDesc) {
            if(sObjectName == tr.getSobjectName()) {
                URL = tr.getUrl();
                break;
            }
        }
        return URL;
    }
    
    @AuraEnabled
    public static Id saveFile(String fileName, String fileContents, Integer fileNumber, String fileId) {
        String title;
        try {
            if (fileId == '' || fileId == null) {
                fileContents = EncodingUtil.urlDecode(fileContents, 'UTF-8');
                Integer extIndex = fileName.lastindexOf('.');
                String fname = filename.substring(0, extIndex);
                String ftype = filename.substring(extIndex + 1, filename.length());
                title = fname + '_' + fileNumber + '.' + ftype;
                ContentVersion cv = new ContentVersion(versionData = EncodingUtil.base64Decode(fileContents),
                                                                   title = title, pathOnClient = fileName, IsMajorVersion = false);
                // check security on insert ContentVersion
                String[] contentVersionFields = new String[] {'versionData', 'title', 'pathOnClient', 'IsMajorVersion'};
                if(NegoptimHelper.checkCreatibility(ContentVersion.SObjectType, contentVersionFields)) {
                    insert cv;
                    fileId = cv.Id;
                }
            } else {
                appendFile(fileId, fileContents);
            }
        } catch(Exception ex) {
            throw new AuraHandledException( title + '\n' + ex.getStackTraceString() + ' - ' + ex.getLineNumber());
        }
        return Id.valueOf(fileId);
    }
    
    private static void appendFile(Id fileId, String fileContents) {
        String title;
        try {
            fileContents = EncodingUtil.urlDecode(fileContents, 'UTF-8');
            ContentVersion cv = [SELECT Id, title, versionData FROM ContentVersion WHERE Id =: fileId];
            title = cv.title;
            String existingBody = EncodingUtil.base64Encode(cv.versionData);
            cv.versionData = EncodingUtil.base64Decode(existingBody + fileContents);
            // check security on updated ContentVersion
            String[] contentVersionFields = new String[] {'versionData'};
            if(NegoptimHelper.checkUpdatibility(ContentVersion.SObjectType, contentVersionFields)) {
                update cv;
            }
        } catch(Exception ex) {
            throw new AuraHandledException( title + '\n' + ex.getStackTraceString() + ' - ' + ex.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static MarketDataCollectionImportController validateFileName(String fileName, MarketDataCollectionImportController instance) {
        try {
            // get category, sequence, year from filename
            List<String> filenames = fileName.split('_');
            if(filenames.size() == 4) {
                // get Flow type picklist value
                instance.flowType = filenames[0];
                if(String.isBlank(instance.flowType)) instance.errorMessage += Label.MSG_Flow_Type_Not_Exist + ' \n';
                
                // get category name
                if(String.isNotBlank(filenames[1]) && filenames[1].length() > 0) {
                    instance.categoryName = filenames[1].substring(0, filenames[1].length());
                    if(String.isBlank(instance.categoryName)) instance.errorMessage += Label.MSG_Category_Not_Exist + ' \n';
                } else {
                    instance.errorMessage += string.format(Label.MSG_Invalid_File_Format, new String[]{ fileName }) + ' \n' + instance.nielsenFileFormat + ' \n';
                }
                
                // get period type and sequence/year
                String periodDate = filenames[2];
                if(periodDate.length() == 7) {
                    String periodType = filenames[2].substring(0, 1);
                    if(periodType == 'W') instance.isWeekly = true;
                    else if(periodType == 'M') instance.isMonthly = true;
                    if(!instance.isWeekly && !instance.isMonthly) {
                        instance.errorMessage += string.format(Label.MSG_Invalid_File_Format, new String[]{ fileName }) + ' \n' + instance.nielsenFileFormat + ' \n';
                    }
                    // check valid month/year
                    String month = periodDate.substring(1, 3);
                    String year = periodDate.substring(3, 7);
                    if(month.isNumeric() && Integer.valueOf(month) > 0 && Integer.valueOf(month) <= 12) instance.month = Integer.valueOf(month);
                    else instance.errorMessage += string.format(Label.MSG_Invalid_Month, new String[]{ '(' + month + ')' }) + '\n';
                    if(year.isNumeric()) instance.year = Integer.valueOf(year);
                    else instance.errorMessage += string.format(Label.MSG_Invalid_Year, new String[]{ '(' + year + ')' }) + '\n';
                } else {
                    instance.errorMessage += string.format(Label.MSG_Invalid_Import_Date_Format, new String[]{ '(' + periodDate + ')' }) + ' \n' + instance.nielsenFileFormat + ' \n';
                }
            } else {
                instance.errorMessage += string.format(Label.MSG_Invalid_File_Format, new String[]{ fileName }) + ' \n' + instance.nielsenFileFormat + ' \n';
            }
        } catch (Exception ex) {
            instance.errorMessage = ex.getMessage() + ' - ' + ex.getLineNumber();
        }
        return instance;
    }
    
    public class ErrorException extends Exception {}
}