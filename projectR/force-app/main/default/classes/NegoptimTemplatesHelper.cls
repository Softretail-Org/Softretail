/**
* @author ULiT
* @description helper class to the parser engine
* to format dates and numbers
*/
public class NegoptimTemplatesHelper {
    
    // Months in French
    private static Map<String, String> months_fr = new Map<String, String> {
		'january' => 'janvier',
		'february' => 'février',
		'march' => 'mars',
		'april' => 'avril',
		'may' => 'mai',
		'june' => 'juin',
		'july' => 'juillet',
		'august' => 'août',
		'september' => 'septembre',
		'october' => 'octobre',
		'november' => 'novembre',
		'december' => 'décembre'
    };
    // Months abrivation in French
    private static Map<String, String> monthsAbreviation_fr = new Map<String, String> {
		'jan' => 'janv.',
		'feb' => 'févr.',
		'mar' => 'mars',
		'apr' => 'avril',
		'may' => 'mai',
		'june' => 'juin',
		'july' => 'juil.',
		'aug' => 'août',
		'sept' => 'sept.',
		'oct' => 'oct.',
		'nov' => 'nov.',
		'dec' => 'déc.'
    };    
    
    // Days in French
    private static Map<String, String> days_fr = new Map<String, String> {
		'monday' => 'Lundi.',
		'tuesday' => 'Mardi.',
		'wednesday' => 'Mercredi',
		'thursday' => 'Jeudi',
		'friday' => 'Vendredi',
		'saturday' => 'Samedi',
		'sunday' => 'Dimanche'
    };
    // Days abrivation in french
    private static Map<String, String> daysAbreviation_fr = new Map<String, String> {
		'mon' => 'Lun',
		'tue' => 'Mar',
		'wed' => 'Mer',
		'thu' => 'Jeu',
		'fri' => 'ven',
		'saturday' => 'Sam',
		'sun' => 'Dim'
    };
        
    /**
     * @description
     * possible formats:
     * ####
     * #,###
     * #,###.##
     * #.###
     * #.###,##
     * # ###
     * # ###,##
    */
    public static String formatDecimal(Decimal value, String format) {
        if (format.equals('####')) {
            return Integer.valueOf(value) + '';
        }
        
        String decimalSeperator;
        String centSeperator;
        String regex;
        
        String result = value.format();        
        String splitRegex = result.contains(',') ? ',' : '\\.';
        list<String> splitList = result.split(splitRegex);
        
        if (format.contains(',') && format.contains('.') || format.contains(',') && format.contains(' ')) {
            regex = '#(.)###(.)##';
            Pattern p = Pattern.compile(regex);
            Matcher m = p.matcher(format);
            if (m.find()) {
                decimalSeperator = m.group(1);
                centSeperator = m.group(2);
            }
            if (splitList.size() == 1) {
                result = splitList[0].replace(',', decimalSeperator);
                result +=  centSeperator + '00';
            } else {
                result = splitList[0].replace(',', decimalSeperator);
                result += centSeperator + splitList[1].rightPad(2, '0');
            }
        } else {
            regex = '#(.)###';
            Pattern p = Pattern.compile(regex);
            Matcher m = p.matcher(format);
            if (m.find()) {
                decimalSeperator = m.group(1);
            }
            result = splitList[0].replace(',', decimalSeperator);
        }
        
        return result;
    }
    
    /*
     * @description 
     * suported formats
     *   
    */
    public static String formatDate(DateTime value, String format) {
        String userLanguage = UserInfo.getLanguage();
        format = format.replace('Y', 'y');
        String result;
        try {
            result = value.format(format);
        } catch (Exception ex) {
            format = 'dd/MM/yyyy';
            result = value.format(format);
        }
        
        String dayName = value.format('EEEEE');
        String dayAbr = value.format('EEE');
        String monthName = value.format('MMMMM');
        String monthAbr = value.format('MMM');
        
        if (format.containsIgnoreCase('MMMMM') || format.containsIgnoreCase('MMMM')) {
            Pattern p = Pattern.compile(monthName);
            if (p.matcher(result).find()) {
                switch on userLanguage {
                    when 'fr' {
                        result = result.replace(monthName, months_fr.get(monthName.toLowerCase()));
                    }
                    when else {
                        result = monthName;
                    }
                }
                ////result = result.replace(monthName, getLabelValue(monthName));
            }
        } else {
            if (format.containsIgnoreCase('MMM')) {
                Pattern p = Pattern.compile(monthAbr);
                if (p.matcher(result).find()) {
                    switch on userLanguage {
                        when 'fr' {
                            result = result.replace(monthAbr, monthsAbreviation_fr.get(monthAbr.toLowerCase()));
                        }
                        when else {
                            result = monthAbr;
                        }
                    }
                    ////result = result.replace(monthAbr, getLabelValue('Abbreviation_' + monthName));
                }
            }
        } 
        if (format.containsIgnoreCase('EEEEE') || format.containsIgnoreCase('EEEE')) {
            Pattern p = Pattern.compile(dayName);
            if (p.matcher(result).find()) {
                switch on userLanguage {
                    when 'fr' {
                        result = result.replace(dayName, monthsAbreviation_fr.get(dayName.toLowerCase()));
                    }
                    when else {
                        result = dayName;
                    }
                }
                ////result = result.replace(dayName, getLabelValue(dayName));
            }
        } else if (format.containsIgnoreCase('EEE')) {
            Pattern p = Pattern.compile(dayAbr);
            if (p.matcher(result).find()) {
                switch on userLanguage {
                    when 'fr' {
                        result = result.replace(dayAbr, monthsAbreviation_fr.get(dayAbr.toLowerCase()));
                    }
                    when else {
                        result = dayAbr;
                    }
                }
                ////result = result.replace(dayAbr, getLabelValue('Abbreviation_' + dayAbr));
            }
        }
        return result;
    }
    /**
     * @descriprion hack to dynamically get the value of a custom label by name
    */
    private static String getLabelValue(String labelName) {
        Component.Apex.OutputText output = new Component.Apex.OutputText();
        output.expressions.value = '{!$Label.' + labelName + '}';
        try {
            output.expressions.value = '{!$Label.' + labelName + '}';
        } catch (Exception e) {
            output.expressions.value = 'XXX';
        }
        return String.valueOf(output.value);
    }
    
    /**
     * @description returns active template of the object type reflected from recordId
     * @param recordId used to get the object Api name
	*/
    public static List<NegoTemplate__c> getAvailableTemplates(Id recordId) {
        String SObjectType = recordId.getSobjectType().getDescribe().getName();
        return [SELECT Name, Description__c, ObjectType__c, Mass_Print_Order_By_Field__c
                FROM NegoTemplate__c
                WHERE ObjectType__c = :SObjectType AND isActive__c = true];
    }
    
    /**
     * @param objectName Object API Name
     * @param the fields a list of lookup relationships that end with a field name: lookup1__r.lookup2__r.field__c
     * or objectName.lookup1__r.lookup2__r.field__c
    */
    public static Schema.SObjectField validateField(String objectName, List<String> theFields) {
        SObjectField result = null;
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
	 * @param objectName Object API Name
	 * @param the fields a list of lookup relationships that end with a field name: lookup1__r.lookup2__r.field__c
	 * or objectName.lookup1__r.lookup2__r.field__c
	*/
    public static Boolean isValidField(String objectName, List<String> theFields) {
        return NegoptimTemplatesHelper.validateField(objectName, theFields) != null;
    }
    /**
     * @param recordsMap a map of the printed records (ID -> record)
     * @param attachments a list of attachments: an email will be creating for each attachment
     * @param templateObjectType
     * @param templateDocumentRecipient
     * @param subject email subject
     * @param body email body
	*/
    public static List<Messaging.SingleEmailMessage> generateEmailList(Map<Id, SObject> recordsMap, List<Attachment> attachments, Id templateId) {
        List<Id> recordIds = new List<Id>(recordsMap.keySet());
        NegoTemplateParser engine = new NegoTemplateParser(recordIds);
        NegoTemplate__c template = [SELECT Id, ObjectType__c, Email_Subject__c, Email_Body__c,
                                    Document_Recipient__c, Document_Recipient_Cc__c, Sender_Display_Name__c
                                    FROM NegoTemplate__c WHERE Id = :templateId];
        Map<Id, String> emailSubjectsMap = engine.parse(template.Email_Subject__c);
        Map<Id, String> emailBodiesMap = engine.parse(template.Email_Body__c);
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;
        List<String> ccList = template.Document_Recipient_Cc__c.replace(',', ';').split(';');
        for (Attachment attach : attachments) {
            //creating the email attachments
            Messaging.EmailFileAttachment email_att = new Messaging.EmailFileAttachment();
            email_att.setBody(attach.Body);
            email_att.setContentType(attach.ContentType);
            email_att.setFileName(attach.Name);
            email_att.setinline(false);
            //creating the single email
            email = new Messaging.SingleEmailMessage();
            email.setSenderDisplayName(template.Sender_Display_Name__c);
            //get the toAddress
            SObject record = recordsMap.get(attach.ParentId);
            List<String> currentFields = template.Document_Recipient__c.split('\\.');
            if (currentFields[0] == template.ObjectType__c) 
                currentFields.remove(0); // remove sobject name
            
            if (currentFields.size() > 1) {
                for(Integer j = 0; j < currentFields.size(); j++) {
                    if(record != null) {
                        record = record.getSObject(currentFields.remove(0));
                    }
                }
            }
            String toAddress = String.valueOf(record.get(currentFields[0]));
            email.setToAddresses(new List<String> {toAddress});
            email.setCcAddresses(ccList);
            ////email.setBccAddresses(bccList);
            email.setFileAttachments(new List<Messaging.EmailFileAttachment> {email_att});
            email.setSubject(emailSubjectsMap.get(attach.ParentId));
            email.setHtmlBody(emailBodiesMap.get(attach.ParentId));
            emailList.add(email);
        }
        return emailList;
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
}