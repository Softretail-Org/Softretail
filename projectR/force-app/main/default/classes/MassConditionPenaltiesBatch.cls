public with sharing class MassConditionPenaltiesBatch implements Database.batchable<String>, Database.Stateful {
    
    private NegoptimBatch nb;
    //This used to prevent the header size check
    private boolean isFirstRow = true;
    private Integer columnHeaderNumber = 0;
    
    private String contentData;
    private String separator;
    private String dateFormat = 'dd/mm/yyyy';
    
    public MassConditionPenaltiesBatch(String startedFrom, Blob contentData, String selectedSeparator) {
        this.nb = new NegoptimBatch('MassConditionPenaltiesBatch', NegoptimBatch.BatchType.Stateful, startedFrom);

        try {
            this.contentData = contentData.toString(); //this.contentData = EncodingUtil.base64Encode(contentData);
        } catch(Exception e) {
            this.contentData = '';
            nb.logError(e);
        }
        this.separator = selectedSeparator; // TODO: Read from global settings
        try {
            NegoptimSettings settings = GlobalSettingsManager.loadGlobalSettings();
            dateFormat = settings.csvDateFormat;
        } catch (Exception e) {
            nb.logError(e);
        }
        
    }
    
    public Iterable<String> start(Database.batchableContext batchableContext) {
        return new CSVIterator(this.contentData, CSVParser.crlf);
    }
    
    public void execute(Database.BatchableContext batchableContext, List<String> scope) {
        // Parsing CSV file.
        List<List<String>> records = NegoptimHelper.parseCSV(scope, separator);
        // Prepare Data.
        // Declaration of a map of suppliers code with CSV row.
        List<WrapperRow> wRows = new List<WrapperRow>();
        // Fill the initial map.
        Integer lineInd = 0;
        Savepoint sp = Database.setSavepoint();
        try {
            // check security on insert supply penalty fields
            String[] penaltyFields = new String[] { NegoptimHelper.normalizeAPIName('Year__c'),
                NegoptimHelper.normalizeAPIName('Month__c'), NegoptimHelper.normalizeAPIName('NS_Code__c'), 
                NegoptimHelper.normalizeAPIName('Supplier_code__c'), NegoptimHelper.normalizeAPIName('Section_Code__c'),
                NegoptimHelper.normalizeAPIName('Condition_Name__c'), NegoptimHelper.normalizeAPIName('Penalty_Number__c'),
                NegoptimHelper.normalizeAPIName('Penalty_Value__c'), NegoptimHelper.normalizeAPIName('Service_Rate_Target__c'),
                NegoptimHelper.normalizeAPIName('Service_Rate_Fact__c'), NegoptimHelper.normalizeAPIName('Penalty_Date__c'),
                NegoptimHelper.normalizeAPIName('Appro_Name__c'), NegoptimHelper.normalizeAPIName('Appro_Email__c'),
                NegoptimHelper.normalizeAPIName('Supplier_Name__c'), NegoptimHelper.normalizeAPIName('Supplier_Email__c'),
                NegoptimHelper.normalizeAPIName('Comment__c'), NegoptimHelper.normalizeAPIName('Status__c'),
                NegoptimHelper.normalizeAPIName('NS_Code_Prefix__c'), NegoptimHelper.normalizeAPIName('Last_Integration_Date__c')};
            Boolean isPenaltyAccess = NegoptimHelper.checkCreatibility(Supply_Penalty__c.SObjectType, penaltyFields);
            
	        for(List<String> row : records) {
	            lineInd++;
                
                if(isFirstRow) {
                    columnHeaderNumber = row.size();
                    isFirstRow = false;
                    continue;
                }
                
                if (row.size() != columnHeaderNumber) {
                    for(Integer i = row.size() ; i < columnHeaderNumber ; i++){
                        row.add('');
                    }
                }
                
	            WrapperRow wRow = new WrapperRow();
	            wRow.lineIndex = lineInd;
                wRow.year = NegoptimHelper.getDecimalValue(row[0]);
                wRow.month = NegoptimHelper.getDecimalValue(row[1]);
	            wRow.supplierCode = row[2];
	            wRow.secttionCode = row[3];
	            wRow.conditionName = row[4];
	            wRow.penaltiesNumber = NegoptimHelper.getDecimalValue(row[5]);
                wRow.penaltiesValue = NegoptimHelper.getDecimalValue(row[6]);
                wRow.serviceRateTarget = NegoptimHelper.getDecimalValue(row[7]);
                wRow.serviceRateFact = NegoptimHelper.getDecimalValue(row[8]);
                wRow.penaltyDate = NegoptimDate.parseDate(row[9], dateFormat);
	            wRow.approName = row[10];
	            wRow.approEmail = row[11];
	            wRow.supplierName = row[12];
	            wRow.supplierEmail = row[13];
	            wRow.comment = row[14];
                wRow.negoScopeCode = row[15];
                wRow.negoScopeCodePrefix = row[16];
	            wRows.add(wRow);
            }
            List<Supply_Penalty__c> penalties = new List<Supply_Penalty__c>();
            for (WrapperRow wRow : wRows) {
                Supply_Penalty__c penalty = new Supply_Penalty__c(Year__c = wRow.year, Month__c = wRow.month, NS_Code_Prefix__c = wRow.negoScopeCodePrefix.trim(),
                                                                  NS_Code__c = wRow.negoScopeCode.trim(), Supplier_code__c = wRow.supplierCode,
                                                                  Section_Code__c = wRow.secttionCode, Condition_Name__c = wRow.conditionName,
                                                                  Penalty_Number__c = wRow.penaltiesNumber, Penalty_Value__c = wRow.penaltiesValue,
                                                                  Service_Rate_Target__c = wRow.serviceRateTarget, Service_Rate_Fact__c = wRow.serviceRateFact,
                                                                  Penalty_Date__c = wRow.penaltyDate, Appro_Name__c = wRow.approName, Appro_Email__c = wRow.approEmail,
                                                                  Supplier_Name__c = wRow.supplierName, Supplier_Email__c = wRow.supplierEmail, Comment__c = wRow.comment,
                                                                  Status__c = 'New', Last_Integration_Date__c = System.now());
                penalties.add(penalty);
            }
            // insert penalties
            if(penalties != null && penalties.size() > 0) {
                List<Database.SaveResult> results = Database.insert(penalties, false);
                nb.logResults(results, penalties);
            }
        } catch(NegoptimDate.NegoptimDateException ex) {
            nb.logError(ex);
        } catch(DMLException ex) {
            Database.rollback(sp);
			nb.logError(ex);
        } catch (Exception ex) {
            Database.rollback(sp);
            nb.logError(ex);
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ' - ' + '/'+ System.now() + ': ';
        nb.sendEmail(bc, null, customSubject);
    }
    
    /* Wrapper that contain CSV columns. */
    private class WrapperRow {
        
        private Integer lineIndex;
        private Decimal year;
        private Decimal month;
        private String negoScopeCode;
        private String negoScopeCodePrefix; // MPX or NAT
        private String supplierCode;
        private String secttionCode;
        private String conditionName;
        private Decimal penaltiesNumber;
        private Decimal penaltiesValue;
        private Decimal serviceRateTarget;
        private Decimal serviceRateFact;
        private Date penaltyDate;
        private String approName;
        private String approEmail;
        private String supplierName;
        private String supplierEmail;
        private String comment;
    }
}