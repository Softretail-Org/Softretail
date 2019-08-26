/**
 * Called from process builder to
 * Insert Invoice Payment Details
 * */
global class InvoicePaymentInsertAction {

    @InvocableMethod(label='Insert Invoice Payment Details' description='Insert Invoice Payment Details.')
    public static void generatePaymentDetails(List<Invoice_Paiement__c> invoicePayments) {
        
        Map<Id, List<String>> invoicePaymentNumbersMap = new Map<Id, List<String>>();
        Map<Id, Id> invoicePaymentParentMap = new Map<Id, Id>();
        Map<String, List<Invoice_Paiement__c>> invoicesNumberPaymentMap = new Map<String, List<Invoice_Paiement__c>>();
        Map<String, Id> recordTypeIds = NegoptimHelper.getObjectRecordTypeMapIds(Invoice_Paiement__c.SObjectType);
        
        for(Invoice_Paiement__c item : invoicePayments) {
            // Cancellation mode
            if(item.Parent_Paiement__c != null) {
                invoicePaymentParentMap.put(item.Parent_Paiement__c, item.Id);
            }
            if(item.Fast_record_Invoice_nb_list__c != null) {
                String[] invoicesNumber = item.Fast_record_Invoice_nb_list__c.split(',');
                if(invoicesNumber.size() > 0) {
                    invoicePaymentNumbersMap.put(item.Id, invoicesNumber);
                    for(String str : invoicesNumber) {
                        str = str.trim();
                        if(invoicesNumberPaymentMap.containsKey(str)) {
                            invoicesNumberPaymentMap.get(str).add(item);
                        }
                        else {
                            invoicesNumberPaymentMap.put(str, new List<Invoice_Paiement__c>{item});
                        }
                    }
                }
            }
        }
        if(invoicePaymentParentMap.size() > 0) {
            List<Invoice_Paiement_Detail__c> invoiceDetailPaymentToInsert = new List<Invoice_Paiement_Detail__c>();
            for(Invoice_Paiement_Detail__c item : [SELECT Id, Accounting_Entry_Credit__c, Accounting_Entry_debit__c, Due_Date__c,
                                                   Invoice_Line__c, Matching_Amount__c, Matching_VAT_Amount__c, Paiement__c
                                                   FROM Invoice_Paiement_Detail__c WHERE Paiement__c IN :invoicePaymentParentMap.keySet()])
            {
                Invoice_Paiement_Detail__c newRecord = item.clone(false, true, true, false);
                newRecord.Matching_Amount__c = newRecord.Matching_Amount__c != null ? newRecord.Matching_Amount__c * -1 : null;
                newRecord.Matching_VAT_Amount__c = newRecord.Matching_VAT_Amount__c != null ? newRecord.Matching_VAT_Amount__c * -1 : null;
                newRecord.Paiement__c = invoicePaymentParentMap.get(item.Paiement__c);
                invoiceDetailPaymentToInsert.add(newRecord);
            }
            String[] paymentDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Paiement__c'), 
                NegoptimHelper.normalizeAPIName('Matching_VAT_Amount__c'), NegoptimHelper.normalizeAPIName('Matching_Amount__c')};
        
            if(!invoiceDetailPaymentToInsert.isEmpty()) {
                if(NegoptimHelper.checkCreatibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailFields)) {
                    Database.insert(invoiceDetailPaymentToInsert, false);
                }
            }
        }
        // Get related Invoice details (Invoice_Detail__c) to generate list of Invoice_Paiement_Detail__c
        Map<String, List<WrapperInvoicePaymentDetail>> invoicesNumberPaymentDetailsMap = new Map<String, List<WrapperInvoicePaymentDetail>>();
        if(invoicePaymentNumbersMap.size() > 0) {
            for(Invoice__c item : [SELECT Id, Invoice_Number__c, (SELECT Id, CurrencyIsoCode, Non_Paid__c, Invoice_Detail_Value_w_VAT__c FROM Invoice_Details__r)
                                   FROM Invoice__c
                                   WHERE Invoice_Number__c IN :invoicesNumberPaymentMap.keySet()])
            {
                for(Invoice_Detail__c invoiceDetail : item.Invoice_Details__r) {
                    Invoice_Paiement_Detail__c ipd = new Invoice_Paiement_Detail__c(Invoice_Line__c = invoiceDetail.Id, CurrencyIsoCode = invoiceDetail.CurrencyIsoCode,
                                                                                    Matching_Amount__c = invoiceDetail.Invoice_Detail_Value_w_VAT__c);
                    WrapperInvoicePaymentDetail wIpd = new WrapperInvoicePaymentDetail(ipd, invoiceDetail.Non_Paid__c);
                    if(invoicesNumberPaymentDetailsMap.containsKey(item.Invoice_Number__c)) {
                        invoicesNumberPaymentDetailsMap.get(item.Invoice_Number__c).add(wIpd);
                    }
                    else {
                        invoicesNumberPaymentDetailsMap.put(item.Invoice_Number__c, new List<WrapperInvoicePaymentDetail>{wIpd});
                    }
                }
            }
        }
        // attach the list of Invoice_Paiement_Detail__c to their parent Invoice_Paiement__c
        List<Invoice_Paiement_Detail__c> ipdList = new List<Invoice_Paiement_Detail__c>();
        if(invoicesNumberPaymentDetailsMap.size() > 0) {
            for(String key : invoicesNumberPaymentMap.keySet()) {
                for(Invoice_Paiement__c item : invoicesNumberPaymentMap.get(key)) {
                    if(invoicesNumberPaymentDetailsMap.containsKey(key)) {
                        for(WrapperInvoicePaymentDetail wIpd : invoicesNumberPaymentDetailsMap.get(key)) {
                            Invoice_Paiement_Detail__c ipdNew = wIpd.invoicePaymentDetail.clone();
                            ipdNew.Paiement__c = item.Id;
                            ipdNew.Due_Date__c = item.Due_Date__c;
                            if(item.RecordTypeId != recordTypeIds.get('Standard') && item.RecordTypeId != recordTypeIds.get('Deduction')) {
                                ipdNew.Matching_Amount__c = wIpd.amountNonPaid;
                            }
                            ipdList.add(ipdNew);
                        }
                    }
                }
            }
        }
        String[] paymentDetailFields = new String[] { NegoptimHelper.normalizeAPIName('Paiement__c'), 
                NegoptimHelper.normalizeAPIName('Due_Date__c'), NegoptimHelper.normalizeAPIName('Matching_Amount__c')};
        
        if(!ipdList.isEmpty()) {
            if(NegoptimHelper.checkCreatibility(Invoice_Paiement_Detail__c.SObjectType, paymentDetailFields)) {
                Database.insert(ipdList, false);
            }
        }
    }
    
    class WrapperInvoicePaymentDetail {
        Invoice_Paiement_Detail__c invoicePaymentDetail;
        Decimal amountNonPaid;
        
        public WrapperInvoicePaymentDetail(Invoice_Paiement_Detail__c ipd, Decimal d) {
            this.invoicePaymentDetail = ipd;
            this.amountNonPaid = d;
        }
    }
}