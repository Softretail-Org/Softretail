/**
 * Batchable class used to generate Invoices
 * Loop over conditions
 * Create Invoice head / contract / month
 * Create Invoice detail for each condition
 * Update The Already Invoiced for conditions
 **/
public with sharing class GenerateInvoicesBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private NegoptimBatch nb;
    public final String query;
    public final Id country;
    public final List<Id> contractIds;
    public final List<Id> conditionIds;
    public final Date invoiceDate;
    // Global Settings for last closing day
    public Integer closingDay = GlobalSettingsManager.loadGlobalSettings().invoiceMaxClosingDay;
    
    // Constructor.
    public GenerateInvoicesBatch(String startedFrom, Id countryId, List<Id> cIds, List<Id> conditionIds, Date invDate) {
        this.nb = new NegoptimBatch('GenerateInvoicesBatch', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.country = countryId;
        this.contractIds = cIds;
        this.conditionIds = conditionIds;
        this.invoiceDate = invDate;
        String q = 'SELECT Id, CurrencyIsoCode, VAT_Rebate_Rate__c, VAT_Service_Rate__c, Supplier__c, Contract_BU__c,';
        q += ' Reference_Year__c, Balancing_Contract__c, Default_Sales_Conditions__r.Services_Payment_Days__c,';
        q += ' (SELECT Id, Name, CurrencyIsoCode, Condition_Type__c, Disc_BDate__c, Disc_EDate__c, Product_Scope__c,';
        q += ' BU_Scope__c, BU_Scope__r.Business_Unit_Type__c, Value_amt__c, Value_per__c, Y_Actu__c, Already_Invoiced__c,';
        q += ' Condition_Type__r.VAT_Type__c, Condition_Type__r.Acc_Document_Type__c, Condition_Type__r.Accounting_Document_Type_Balance__c,';
        q += ' YTD_Nego__c, Already_Invoiced_Edited__c, Invoice_base__c, first_invoice_date__c, Invoice_period__c,';
        q += ' Nego_Discount_Type__c, Invoice_sequence__c, Payment_Condition__c, Payment_Days__c, comments__c, Valid__c';
        q += ' FROM Contract_Discounts__r';
        String innerWhereClause = '';
        if (!startedFrom.equals('ContractBalancingBatch')) {
            innerWhereClause = this.buildWhere(innerWhereClause, 'Valid__c = TRUE');
            q += innerWhereClause;
        }
        if(this.conditionIds != null && this.conditionIds.size() > 0) {
            innerWhereClause = this.buildWhere(innerWhereClause, ' Id IN (\'' + String.join(this.conditionIds, '\',\'') +'\')');
            q += innerWhereClause;
        }
        q += ') ';
        q += 'FROM Contract__c WHERE Contract_Type__c = \'Contract\'';
        if(this.country != null) {
            q += ' AND Contract_BU__c = \'' + this.country + '\'';
        }
        if(this.contractIds != null && this.contractIds.size() > 0) {
            q += ' AND Id IN (\'' + String.join(this.contractIds, '\',\'') +'\')';
        }
        ////else if(this.invoiceDate != null) {
        ////    q += ' AND Reference_Year__c = ' + this.invoiceDate.year() + '';
        ////}
        // Don't filter on reference year unless there are no filters on the contractIds or conditionIds
        if((this.contractIds == null || this.contractIds.isEmpty())
            && (this.conditionIds == null || this.conditionIds.isEmpty())
            && this.invoiceDate != null)
        {
            q += ' AND Reference_Year__c = ' + this.invoiceDate.year() + '';
        }
        // Set the final variable.
        this.query = q;
        // push inputs to log
        nb.logParameter('counrty', this.country);
        nb.logParameter('contractIds', this.contractIds);
        nb.logParameter('conditionIds', this.conditionIds);
        nb.logParameter('invoiceDate', this.invoiceDate);
        nb.logParameter('query', this.query);
        nb.logParameter('closingDay', this.closingDay);
    }
    // Start method.
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    // Execute method.
    public void execute(Database.BatchableContext bc, List<Contract__c> scope) {
        // Load map of currencies with exchange rate.
        Map<String, Double> currencies = NegoptimHelper.getCurrencyMap();
        // List of new invoices to add.
        List<Invoice__c> invoiceHeadList = new List<Invoice__c>();
        // List of new invoices details to add.
        List<Invoice_Detail__c> invoiceDetailsList = new List<Invoice_Detail__c>();
        // List of old invoices details to delete.
        List<Invoice_Detail__c> invoiceDetailsToDelete = new List<Invoice_Detail__c>();
        // List of all conditions to be updated.
        List<Contract_Discount__c> conditionsList = new List<Contract_Discount__c>();
        // Populate the list of conditions.
        for (Contract__c contract : scope) {
            for(Contract_Discount__c condition : contract.Contract_Discounts__r) {
                conditionsList.add(condition);
            }
        }
        // List of Id corresponding to invoices lines to be deleted
        Set<Id> invoicesIdsToDelete = new Set<Id>();
        // Get all invoices lines for conditions not having an invoice head number
        Map<Id, List<Invoice_Detail__c>> oldInvoicesLinesMap = new Map<Id, List<Invoice_Detail__c>>();
        // TODO: filter only condition for Planning mode
        for(Invoice_Detail__c item : [SELECT Id, Discount__c, Invoice_Value__c, Invoice__c, Invoice__r.Inv_Date__c
                                      FROM Invoice_Detail__c
                                      WHERE Discount__c IN :conditionsList
                                      AND Invoice__r.Invoice_Number__c IN ('', null)])
        {
            if(!invoicesIdsToDelete.contains(item.Invoice__c)) {
                invoicesIdsToDelete.add(item.Invoice__c);
            }
            if(oldInvoicesLinesMap.containsKey(item.Discount__c)) {
                oldInvoicesLinesMap.get(item.Discount__c).add(item);
            }
            else {
                oldInvoicesLinesMap.put(item.Discount__c, new List<Invoice_Detail__c>{item});
            }
        }
        List<WrapperInvoice> wInvoiceList = new List<WrapperInvoice>();
        // List of wrapper invoice details
        List<WrapperInvoiceDetail> wInvoiceDetailList = new List<WrapperInvoiceDetail>();
        // Loop over result and populate the list of wrapper invoices.
        for (Contract__c contract : scope) {
            WrapperInvoiceDetail wInvoiceDetail = new WrapperInvoiceDetail(contract);
            for(Contract_Discount__c condition : contract.Contract_Discounts__r) {
                List<Invoice_Detail__c> oldInvoicesLines = oldInvoicesLinesMap.get(condition.id);
                WrapperCondition wCondition = new WrapperCondition(contract, condition, oldInvoicesLines, invoiceDate, closingDay);
                if(wCondition.isPlanning && oldInvoicesLines != null && oldInvoicesLines.size() > 0) {
                    invoiceDetailsToDelete.addAll(oldInvoicesLines);
                }
                wCondition.generateInvoicesLines();
                for(WrapperInvoiceLine item : wCondition.wInvoiceLines) {
                    // Push into Map by Document type key
                    if(!wInvoiceDetail.invoiceLineMap.containsKey(item.key)) {
                        List<WrapperInvoiceLine> invoiceLines = new List<WrapperInvoiceLine>();
                        invoiceLines.add(item);
                        wInvoiceDetail.invoiceLineMap.put(item.key, invoiceLines);
                    }
                    else {
                        wInvoiceDetail.invoiceLineMap.get(item.key).add(item);
                    }
                }
            }
            wInvoiceDetailList.add(wInvoiceDetail);
        }
        
        // Build the wrapper for invoices head
        for (WrapperInvoiceDetail item : wInvoiceDetailList) {
            for (String key : item.invoiceLineMap.keySet()) {
                String docType = item.invoiceLineMap.get(key).get(0).docType;
                Date invoiceDate = item.invoiceLineMap.get(key).get(0).invoiceDate;
                Date invoiceDueDate = item.invoiceLineMap.get(key).get(0).invoiceDueDate;
                Integer sequence = invoiceDate.month();
                Integer year = Integer.valueOf(item.contract.Reference_Year__c);//invoiceDate.year();
                WrapperInvoice wInvoice = new WrapperInvoice();
                // Create new Invoice Head for each Accounting Document Type and contract.
                Invoice__c invoice = new Invoice__c(Inv_Date__c = invoiceDate, Inv_Supplier__c = item.contract.Supplier__c, Inv_Contract__c = item.contract.Id,
                                                    Inv_Business_Unit__c = item.contract.Contract_BU__c, Sequence_Number__c = sequence, Inv_FiscalYear__c = year,
                                                    Status_BDate__c = invoiceDate, Inv_DueDate__c = invoiceDueDate, Acc_Document_Type__c = docType, CurrencyIsoCode = item.contract.CurrencyIsoCode);
                // FOR MPX ONLY
                ////if(this.nb.getStartedFrom().equalsIgnoreCase('PenaltiesScanSynchroBatch')) {
                    ////invoice.Inv_Business_Unit__c = item.invoiceLineMap.get(key).get(0).invoiceDetail.Inv_Detail_BU__c;
                ////}
                // Set the due date depending on payment terms for rendering
                // TODO: manage the case of exceptions
                /***if(item.contract.Default_Sales_Conditions__r.Services_Payment_Days__c == null) {
                    invoice.Inv_DueDate__c = invoiceDate + 1;
                }
                else {
                    invoice.Inv_DueDate__c = invoiceDate + Integer.valueOf(item.contract.Default_Sales_Conditions__r.Services_Payment_Days__c);
                }***/
                wInvoice.invoice = invoice;
                for(WrapperInvoiceLine invLine : item.invoiceLineMap.get(key)) {
                     wInvoice.invoiceLines.add(invLine.invoiceDetail);
                }
                ////wInvoice.invoiceLines = item.invoiceLineMap.get(key);
                wInvoiceList.add(wInvoice);
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
            // check security on update condition fields
            String[] conditionUpdateFields = new String[] { NegoptimHelper.normalizeAPIName('Already_Invoiced__c'),
                NegoptimHelper.normalizeAPIName('Already_Invoiced_Edited__c'), NegoptimHelper.normalizeAPIName('Invoicing_plan_generated__c')};
            
            // check security on insert invoice fields
            String[] invoiceCreateFields = new String[] { 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Inv_Date__c'), 
                NegoptimHelper.normalizeAPIName('Inv_Supplier__c'), NegoptimHelper.normalizeAPIName('Inv_Contract__c'), 
                NegoptimHelper.normalizeAPIName('Inv_Business_Unit__c'), NegoptimHelper.normalizeAPIName('Sequence_Number__c'),
                NegoptimHelper.normalizeAPIName('Inv_FiscalYear__c'), NegoptimHelper.normalizeAPIName('Status_BDate__c'),
                NegoptimHelper.normalizeAPIName('Inv_DueDate__c'), NegoptimHelper.normalizeAPIName('Acc_Document_Type__c')};
            
            // check security on insert invoice line fields
            String[] invoiceDetailCreateFields = new String[]{ 'CurrencyIsoCode', NegoptimHelper.normalizeAPIName('Discount__c'),
                NegoptimHelper.normalizeAPIName('Inv_Detail_BU__c'), NegoptimHelper.normalizeAPIName('Inv_Detail_Condition__c'),
                NegoptimHelper.normalizeAPIName('Invoice__c'), NegoptimHelper.normalizeAPIName('Invoice_Value__c'),
                NegoptimHelper.normalizeAPIName('Inv_VAT_Percent__c'), NegoptimHelper.normalizeAPIName('Inv_VAT_Code__c')};
            
            if(NegoptimHelper.checkUpdatibility(Contract_Discount__c.SObjectType, conditionUpdateFields) && 
               NegoptimHelper.checkCreatibility(Invoice__c.SObjectType, invoiceCreateFields) && 
               NegoptimHelper.checkCreatibility(Invoice_Detail__c.SObjectType, invoiceDetailCreateFields) && 
               NegoptimHelper.checkDeletibility(Invoice__c.SObjectType) && 
               NegoptimHelper.checkDeletibility(Invoice_Detail__c.SObjectType))
            {
                // delete old invoice lines.
                delete invoiceDetailsToDelete;
                // delete invoices head with empty value
                if(invoicesIdsToDelete.size() > 0) {
                    // List of invoices head with value = 0 to delete.
                    delete [SELECT Id FROM Invoice__c WHERE Inv_value__c = 0 AND Id IN :invoicesIdsToDelete];
                }
                // Insert invoices head.
                for (WrapperInvoice item : wInvoiceList) {
                    if(item.invoiceLines.size() > 0) {
                        invoiceHeadList.add(item.invoice);
                    }
                }
                insert invoiceHeadList;
                // Insert invoices details.
                for (WrapperInvoice item : wInvoiceList) {
                    if(item.invoiceLines.size() > 0) {
                        for (Invoice_Detail__c line : item.invoiceLines) {
                            // Set corresponding invoice head Id.
                            line.Invoice__c = item.invoice.Id;
                            invoiceDetailsList.add(line);
                        }
                    }
                }
                String[] invoiceFields = new String[] {NegoptimHelper.normalizeAPIName('Invoice__c')};
                if(NegoptimHelper.checkCreatibility(Invoice_Detail__c.SObjectType, invoiceFields)) {
                    insert invoiceDetailsList;
                }
                // Update already invoice in conditions.
                update conditionsList;
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch (Exception e) {
            // Roll everything back in case of error.
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        String countryName = 'N/A';
        Integer year = invoiceDate != null ? invoiceDate.year() : System.today().year();
        try {
            if(country != null)
                countryName = [SELECT Id, Name FROM Orga_BU__c WHERE Id = :country LIMIT 1].Name;
        } catch(DmlException e) {
            nb.logError('Exception: ' + e.getDMLMessage(0) + ' - ' + e.getLineNumber());
        }
        String customSubject = nb.getBatchName() + ' - ' + countryName + '/'+ year + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
    
    public String buildWhere(String whereClause, String condition) {
        return String.isBlank(whereClause) ? ' WHERE ' + condition : ' AND ' + condition;
    }
    
    /* Wrapper Class for Invoice. */
    public class WrapperInvoice {
        
        ////public Contract__c contract {get; set;}
        public Invoice__c invoice {get; set;}
        public List<Invoice_Detail__c> invoiceLines {get; set;}
        
        public WrapperInvoice() {
            invoiceLines = new List<Invoice_Detail__c>();
        }
    }
    /* Wrapper Class for Invoice Line */
    public class WrapperInvoiceLine {
        
        public Invoice_Detail__c invoiceDetail {get; set;}
        public String docType {get; set;}
        public Date invoiceDate {get; set;}
        public Date invoiceDueDate {get; set;}        
        public String key {
            get {
                return docType + invoiceDate.year() + invoiceDate.month() + invoiceDate.day()
                    + invoiceDueDate.year() + invoiceDueDate.month() + invoiceDueDate.day();
            }
            set;
        }
        
        public WrapperInvoiceLine(Invoice_Detail__c invDetail, String t, Date invDate, Date dueDate) {
            this.docType = t;
            invoiceDetail = invDetail;
            invoiceDate = invDate;
            invoiceDueDate = dueDate;
        }
    }
    /* Wrapper Class for Invoice Details. */
    public class WrapperInvoiceDetail {
        
        public Contract__c contract {get; set;}
        public Map<String, List<WrapperInvoiceLine>> invoiceLineMap {get; set;}
        
        public WrapperInvoiceDetail(Contract__c c) {
            contract = c;
            invoiceLineMap = new Map<String, List<WrapperInvoiceLine>>();
        }
    }
    /* Wrapper Class for Condition */
    public class WrapperCondition {
        
        public Contract__c contract {get; set;}
        public Contract_Discount__c condition {get; set;}
        public List<WrapperInvoiceLine> wInvoiceLines {get; set;}
        public Boolean isActual {get; set;}
        public Boolean isPlanning {get; set;}
        // Used in case of deletion/regeneration 
        public List<Invoice_Detail__c> oldInvoiceLines {get; set;}
        // Sum of old invoices lines to delete
        public Decimal sumInvoiced {get; set;}
        // List of dates of old invoices lines to delete
        public Set<Date> oldInvoicesDates {get; set;}
        private Date selectedDate;
        private Integer closingDay;
        
        public WrapperCondition(Contract__c cont, Contract_Discount__c cond, List<Invoice_Detail__c> invoiceLines, Date selectedDate, Integer closingDay) {
            contract = cont;
            condition = cond;
            wInvoiceLines = new List<WrapperInvoiceLine>();
            isActual = false;
            isPlanning = false;
            if(condition.Invoice_base__c == 'Actual (YTD)') {
                isActual = true;
            }
            else if(condition.Invoice_base__c == 'Negotiated' || condition.Invoice_base__c == 'Forecasted') {
                isPlanning = true;
                oldInvoiceLines = invoiceLines != null ? invoiceLines : new List<Invoice_Detail__c>();
                sumInvoiced = 0;
                oldInvoicesDates = new Set<Date>();
                for(Invoice_Detail__c item : oldInvoiceLines) {
                    sumInvoiced += item.Invoice_Value__c != null ? item.Invoice_Value__c : 0;
                    oldInvoicesDates.add(item.Invoice__r.Inv_Date__c);
                }
            }
            else { // in this case, do not generate invoices
                
            }
            this.selectedDate = selectedDate;
            this.closingDay = closingDay;
        }
        
        public List<Date> generateInvoicesDates(Date conditionFirstInvoiceDate, Date conditionEndDate, Integer periodValue,
                                                Integer sequence, Date selectedDate, Integer closingDay)
        {
            //first invoice date is in the future
            ////if (conditionFirstInvoiceDate > Date.today()) return new List<Date>();
            //condition end date has past
            if (conditionEndDate < Date.today()) return new List<Date> {conditionEndDate};
                
            List<Date> dateList = new List<Date>();
            Integer month;
            Integer year;
            //get first invoice date if period is 1 (Month) OR get month and year of invoice first date
            if (periodValue == 1) {
                Date firstInvoiceDate;
                // if closingDay & selectedDate are both NULL -> Noramle case (MAF, Schedule)
                if (closingDay == null && selectedDate == null) {
                    selectedDate = Date.today();
                    closingDay = 31;
                    // if closingDay is NOT NULL -> check selectedDate value and make sure it's not null
                } else if (closingDay != null) {
                    // if selectedDate is NULL -> selectedDate = today
                    selectedDate = selectedDate == null ? Date.today() : selectedDate;
                }
                // if closingDay NOT NULL respect the following: 
                // if selectedDate <= closingDay -> invoiceDate is the end of previous month
                // if selectedDate > maxClosingDay -> invoiceDate is selectedDate
                if (closingDay != null) {
                    if (selectedDate.day() > closingDay) {
                        firstInvoiceDate = selectedDate;
                        month = selectedDate.month();
                        year = selectedDate.year();
                    } else {
                        month = selectedDate.month() == 1 ? 12 : selectedDate.month() - 1;
                        year = month == 12 ? selectedDate.year() - 1 : selectedDate.year();
                        firstInvoiceDate = NegoptimHelper.getLastDayOfMonth(year, month);
                    }
                } else {
                    // if closingDay is null -> invoiceDate is the end of the month selectedDate.month()
                    month = selectedDate.month();
                    year = selectedDate.year();
                    firstInvoiceDate = NegoptimHelper.getLastDayOfMonth(year, month);
                }
                //check if invoiceDate respects criteria 
                if (firstInvoiceDate >= conditionFirstInvoiceDate
                    && firstInvoiceDate <= conditionEndDate
                    && !dateList.contains(firstInvoiceDate))
                {
                    dateList.add(firstInvoiceDate);
                }
                //increment month to be used later to generate forcasted invoice dates 
                Integer nextMonth = month + sequence > 12 ? Math.Mod(month + sequence, 12) : month + sequence;
                year = nextMonth <= month ? ++year : year;
                month = nextMonth;
            } else { //get first invoice month and year
                // set closingDay and selectedDate values to default if null
                year = selectedDate.year();
                closingDay = closingDay == null ? 31 : closingDay;
                selectedDate = selectedDate == null ? Date.today() : selectedDate;
                Integer selectedDateDay = selectedDate.day();
                Integer selectedDateMonth = selectedDate.month();
                switch on periodValue {
                    // case trimester
                    when 3 {
                        if (selectedDate >= Date.newInstance(Date.today().year() - 1, 12, closingDay) && selectedDate < Date.newInstance(Date.today().year(), 6, closingDay)) {
                            month = 3;
                        } else if (selectedDate >= Date.newInstance(Date.today().year(), 6, closingDay) && selectedDate < Date.newInstance(Date.today().year(), 9, closingDay)) {
                            month = 6;
                        } else if (selectedDate >= Date.newInstance(Date.today().year(), 9, closingDay) && selectedDate < Date.newInstance(Date.today().year() + 1, 1, closingDay)) {
                            month = 9;
                        } else {
                            month = 12;
                            year = selectedDate.month() == 12 ? year : --year;
                        }
                    }
                    // case semester
                    when 6 {
                        // condition expends on more that 1 year
                        if (selectedDate < Date.newInstance(year, 1, closingDay)
                            && NegoptimHelper.getLastDayOfMonth(year - 1, 12) >= conditionFirstInvoiceDate)
                        {
                            month = 12;
                            year = year - 1;
                        } else {
                            month = 6;
                        }
                    }
                    when 12 {
                        month = 12;
                        if (selectedDate < Date.newInstance(year, 1, closingDay)) year = year - 1;
                    }
                }
            }
            Date nextExpectedDate = NegoptimHelper.getLastDayOfMonth(year, month);
            while (nextExpectedDate <= conditionEndDate) {
                if (nextExpectedDate >= conditionFirstInvoiceDate && !dateList.contains(nextExpectedDate)) dateList.add(nextExpectedDate);
                //increment month (and  year if necessary)
                integer increment = sequence * periodValue;
                Integer nextMonth = month + increment > 12 ? Math.Mod(month + increment, 12) : month + increment;
                year = nextMonth <= month ? year + 1 : year;
                nextExpectedDate = NegoptimHelper.getLastDayOfMonth(year, nextMonth);
                month = nextMonth;
            }
            // add conditionEndDate to list if it's not already in there
            if (!dateList.contains(conditionEndDate)) dateList.add(conditionEndDate);
            
            return dateList;
        }
        
        public void generateInvoicesLines() {
            Decimal totalAmountToInvoice, amountAlreadyInvoiced;
            List<Date> invoicesDates;
            if (!this.condition.Valid__c) {
                invoicesDates = new List<Date> {this.condition.Disc_EDate__c};
                amountAlreadyInvoiced = condition.Already_Invoiced__c != null ? condition.Already_Invoiced__c : 0;
                totalAmountToInvoice = amountAlreadyInvoiced * (-1);
                this.condition.Already_Invoiced__c = (this.condition.Already_Invoiced__c != null) ? this.condition.Already_Invoiced__c + totalAmountToInvoice : totalAmountToInvoice;
            } else {
                Decimal YTD;
                Date conditionFirstInvoiceDate = condition.first_invoice_date__c != null ? condition.first_invoice_date__c : condition.Disc_BDate__c;
                Integer sequence = condition.Invoice_sequence__c != null ? Integer.valueOf(condition.Invoice_sequence__c) : 1;
                Integer periodValue = 1; // Default value is Month
                switch on condition.Invoice_period__c {
                    when 'Month' {
                        periodValue = 1;
                    }
                    when 'Trimester' {
                        periodValue = 3;
                    }
                    when 'Semester' {
                        periodValue = 6;
                    }
                    when 'Year' {
                        periodValue = 12;
                    }
                }
                invoicesDates = generateInvoicesDates(conditionFirstInvoiceDate,
                                                      condition.Disc_EDate__c,
                                                      periodValue,
                                                      sequence,
                                                      selectedDate,
                                                      closingDay);
                // Actual Invoicing 'Actual (YTD)'
                if(isActual) {
                    YTD = condition.Y_Actu__c != null ? condition.Y_Actu__c : 0;
                    amountAlreadyInvoiced = condition.Already_Invoiced__c != null ? condition.Already_Invoiced__c : 0;
                    totalAmountToInvoice = YTD - amountAlreadyInvoiced;
                    // their are an invoice line to generate
                    if(invoicesDates.size() > 0) {
                        Date invoiceDate = invoicesDates.get(0);
                        if (invoiceDate < Date.today()
                            || closingDay == null
                            || selectedDate.day() > closingDay)
                        {
                            invoicesDates.clear();
                            invoicesDates.add(invoiceDate);
                            condition.Already_Invoiced__c = (condition.Already_Invoiced__c != null) ? condition.Already_Invoiced__c + totalAmountToInvoice : totalAmountToInvoice;
                        } else {
                            invoicesDates.clear();
                        }
                    }
                }
                // Invoice planning (Negotiated or Forecasted)
                else if(isPlanning) {
                    YTD = condition.YTD_Nego__c != null ? condition.YTD_Nego__c : 0; 
                    ////amountAlreadyInvoiced = condition.Already_Invoiced_Edited__c != null ? condition.Already_Invoiced_Edited__c : 0;
                    amountAlreadyInvoiced = condition.Already_Invoiced__c != null ? condition.Already_Invoiced__c : 0;
                    totalAmountToInvoice = YTD - amountAlreadyInvoiced + sumInvoiced;
                    
                    // refresh the original list after removing already invoiced lines with invoice head having a number
                    if(oldInvoicesDates.size() > 0) {
                        // transform list dates to Set to remove unnecessary
                        Set<Date> allDates = new Set<Date>();
                        allDates.addAll(invoicesDates);
                        
                        Set<Date> ignoredDates = new Set<Date>();
                        ignoredDates.addAll(invoicesDates);
                        
                        ignoredDates.removeAll(oldInvoicesDates);
                        allDates.removeAll(ignoredDates);
                        
                        invoicesDates.clear();
                        invoicesDates.addAll(allDates);
                    }
                    if(invoicesDates.size() > 0) {
                        ////condition.Already_Invoiced_Edited__c = (condition.Already_Invoiced_Edited__c != null) ? condition.Already_Invoiced_Edited__c + totalAmountToInvoice - sumInvoiced : totalAmountToInvoice - sumInvoiced;
                        condition.Already_Invoiced__c = (condition.Already_Invoiced__c != null) ? condition.Already_Invoiced__c + totalAmountToInvoice - sumInvoiced : totalAmountToInvoice - sumInvoiced;
                    }
                }
            }
            // Generate invoice lines and set the already invoiced
            if((isActual || isPlanning) && totalAmountToInvoice != 0 && invoicesDates.size() > 0) {
                fillInvoiceLines(invoicesDates, totalAmountToInvoice);
                condition.Invoicing_plan_generated__c = true;
            }
        }
        
        private void fillInvoiceLines(List<Date> invoicesDates, Decimal totalAmountToInvoice) {
            String vatType = condition.Condition_Type__r.VAT_Type__c;
            Decimal vatPercent = 0;
            if (vatType == 'Service') {
                vatPercent = contract.VAT_Service_Rate__c != null ? contract.VAT_Service_Rate__c : vatPercent;
            }
            else if (vatType == 'Rebate') {
                vatPercent = contract.VAT_Rebate_Rate__c != null ? contract.VAT_Rebate_Rate__c : vatPercent;
            }
            List<Decimal> amountValues = NegoptimHelper.smartDivision(totalAmountToInvoice, invoicesDates.size(), 2);
            
            for(Integer i = 0; i < invoicesDates.size(); i++) {
                Invoice_Detail__c invoiceDetail = new Invoice_Detail__c(Discount__c = condition.Id, Inv_Detail_BU__c = condition.BU_Scope__c,
                                                                        Inv_Detail_Condition__c = condition.Condition_Type__c, Invoice_detail_nego_disc_type__c = condition.Nego_Discount_Type__c,
                                                                        Invoice_Value__c = amountValues.get(i), Inv_VAT_Percent__c = vatPercent, Inv_VAT_Code__c = 121,
                                                                        Inv_Detail_Comment__c = condition.comments__c, Cond__c = condition.Value_per__c, CurrencyIsoCode = contract.CurrencyIsoCode);
                // Get invoice due date based on invoice date / payment condition / payment term days
                Date dueDate = NegoptimHelper.getDueDate(invoicesDates.get(i), Integer.valueOf(condition.Payment_Days__c), condition.Payment_Condition__c);
                // use Accounting_Document_Type_Balance__c instead of Acc_Document_Type__c when contract is balanced
                String docType = !contract.Balancing_Contract__c ? condition.Condition_Type__r.Acc_Document_Type__c : condition.Condition_Type__r.Accounting_Document_Type_Balance__c;
                wInvoiceLines.add(new WrapperInvoiceLine(invoiceDetail, docType, invoicesDates.get(i), dueDate));
            }
        }
    }
}