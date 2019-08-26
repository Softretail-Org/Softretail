public class ProductToPGBatch implements database.Batchable<AggregateResult>, Database.Stateful {
    
    private NegoptimBatch nb;    
    private Integer year;
    private List<Id> supplierIds;
    private String supplierCode;
    private String query;
    
    public ProductToPGBatch(String startedFrom, Integer year, List<Id> supplierIds) {
        
        this.nb = new NegoptimBatch('Product To PG', NegoptimBatch.BatchType.Stateful, startedFrom);
        this.year = year;
        this.supplierIds = supplierIds;
        
        query = 'SELECT Mvt_Purch_Product__c Mvt_Purch_Product__c, Mvt_Purch_Product__r.Name productName, Mvt_Purch_Product__r.ProductCode productCode, Mvt_Purch_Product__r.Category__c productCategory,';
        query += ' Mvt_Purch_Product__r.Category__r.Parent_Element__c productParentCategory, Mvt_Purch_Product__r.Brand__c productBrand, Supplier__c Supplier__c, Supplier__r.Code__c supplierCode';
        query += ' FROM Sell_in_Flow__c';
        query += ' WHERE Mvt_Purch_Product__c <> NULL';
        query += ' AND Invoice_Net_Amount_woTax_Calc__c <> NULL';
        query += ' AND Year__c = ' + this.year;
        query += ' AND Supplier__c IN (\'' + String.join(this.supplierIds,'\',\'') + '\')';
        query += ' AND Mvt_Purch_Product__c NOT IN (SELECT Product__c FROM Supplier_PG_Mapping__c WHERE Supplier__c IN (\'' + String.join(this.supplierIds,'\',\'') + '\'))';
        query += ' GROUP BY Mvt_Purch_Product__c, Mvt_Purch_Product__r.Name, Mvt_Purch_Product__r.ProductCode, Mvt_Purch_Product__r.Category__c,';
        query += ' Mvt_Purch_Product__r.Category__r.Parent_Element__c, Mvt_Purch_Product__r.Brand__c, Supplier__c, Supplier__r.Code__c';
        query += ' ORDER BY supplier__c';
             
        nb.logParameter('year', year);
        nb.logParameter('supplierIds', String.join(supplierIds, ','));
        nb.logParameter('query', query);
    }
    
    public Iterable<AggregateResult> start(Database.BatchableContext bc){        
        return new AggregateResultIterable(query);
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        
        Boolean hascreateAccess = NegoptimHelper.checkCreatibility(Supplier_PG_Mapping__c.SObjectType, new String[] {NegoptimHelper.normalizeAPIName('Supplier__c')});
        List<Supplier_PG_Mapping__c> clientAssortmentListToInsert = new List<Supplier_PG_Mapping__c>();
        
        for (SObject so : scope) {
            AggregateResult aggr = (AggregateResult) so;
            Id supplierId = (Id)aggr.get('Supplier__c');
            Id prodId = (Id)aggr.get('Mvt_Purch_Product__c');
            String prodName = (String)aggr.get('productName');
            Id prodDepartment = (Id)aggr.get('productParentCategory');
            Id prodCategory = (Id)aggr.get('productCategory');
            String supplierCode= (String)aggr.get('supplierCode');
            String prodCode = (String)aggr.get('productCode');
            
            Supplier_PG_Mapping__c ca = new Supplier_PG_Mapping__c(Supplier__c = supplierId);
            ca.Name = prodName;
            ca.Product__c = prodId;
            ca.Department__c = prodDepartment;
            ca.Section__c = prodCategory;
            ca.SNA_Code__c = supplierCode + prodCode;
            ca.GIMA_Code__c = supplierCode + prodCode;
            clientAssortmentListToInsert.add(ca);
        }
       
        Savepoint sp = Database.setSavepoint();
        try {
            // Check supplierPG upsert field security
            String[] pgFields = new String[] {'Name', NegoptimHelper.normalizeAPIName('Product__c'),
                NegoptimHelper.normalizeAPIName('Supplier__c'), NegoptimHelper.normalizeAPIName('Department__c'),
                NegoptimHelper.normalizeAPIName('Section__c'), NegoptimHelper.normalizeAPIName('SNA_Code__c'),
                NegoptimHelper.normalizeAPIName('GIMA_Code__c')};

            if (NegoptimHelper.checkCreatibility(Supplier_PG_Mapping__c.SObjectType, pgFields) && clientAssortmentListToInsert.size() > 0) {
                List<Database.SaveResult> results = Database.insert(clientAssortmentListToInsert, false);
                nb.logResults(results, clientAssortmentListToInsert);
            }
        } catch(DmlException e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getDmlMessage(0) + ' - ' + e.getLineNumber());
        } catch(Exception e) {
            Database.rollback(sp);
            nb.logError('Exception: ' + e.getMessage() + ' - ' + e.getLineNumber());
        }
        nb.incrementBatchIndex();
    }
    
    public void finish(Database.BatchableContext bc) {
        nb.saveLog(bc);
        try {
            nb.sendEmail(bc, null, null);
        } catch (Exception ex) { }
    }
	
}