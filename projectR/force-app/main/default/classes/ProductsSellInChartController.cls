global with sharing class ProductsSellInChartController {
    
    Sup_Supplier__c supplier {get; set;}
    public Integer year {get; set;}
    Set<Id> brandDistributorSet = new Set<Id>();
    Integer countProducts {get; set;}
    public Integer countPositiveSellInWithoutAssortment {get; set;}
    public Decimal percentPositiveSellInWithoutAssortment {
        get {
            Decimal d = Decimal.valueOf(this.countPositiveSellInWithoutAssortment);
            return this.countProducts > 0 ? (d * 100)/this.countProducts : 0;
        }
        set;
    }
    public String sPercentPositiveSellInWithoutAssortment {
        get {
            return NegoptimHelper.formatPercentageValue(this.percentPositiveSellInWithoutAssortment, true);
        }
        set;
    }

    public ProductsSellInChartController(ApexPages.StandardController stdController) {
        string selectYear = ApexPages.CurrentPage().getParameters().get('selectYear');
        if(String.isNotBlank(selectYear)){
            year = Integer.valueOf(selectYear);
        }
        else{
            year = Date.today().year();
        }
        supplier = (Sup_Supplier__c)stdController.getRecord();
        countProducts = 0;
        countPositiveSellInWithoutAssortment = 0;
        percentPositiveSellInWithoutAssortment = 0;
        load();
    }
    
    private void load() {
        // get brand distributor list
        for(Sup_Bra_Distributor__c item :[SELECT Brand__c FROM Sup_Bra_Distributor__c WHERE Supplier__c = :supplier.Id]){
            if(!brandDistributorSet.contains(item.Brand__c)){
                brandDistributorSet.add(item.Brand__c);
            }
        }
        // get products count.
        countProducts = [SELECT COUNT() FROM Product2 WHERE Brand__c IN :brandDistributorSet AND IsActive = TRUE];
    }
        
    // The actual chart data
    public List<Data> getChartData() {
        Integer countPositiveSellInWithAssortment = [SELECT COUNT(Id), Mvt_Purch_Product__c FROM Sell_in_Flow__c
                                                     WHERE Mvt_Purch_Product__c <> null
                                                     AND Supplier__c = :supplier.Id
                                                     AND Invoice_Net_Amount_woTax_Calc__c > 0
                                                     AND Mvt_Purch_Product__c IN (SELECT Product__c FROM Supplier_PG_Mapping__c WHERE Supplier__c = :supplier.Id)
                                                     AND Mvt_Purch_Product__r.Brand__c IN :brandDistributorSet
                                                     AND Year__c = :year
                                                     AND Mvt_Purch_Product__r.IsActive = TRUE
                                                     GROUP BY Mvt_Purch_Product__c LIMIT 1000].size();
        countPositiveSellInWithoutAssortment = [SELECT COUNT(Id), Mvt_Purch_Product__c FROM Sell_in_Flow__c
                                                WHERE Mvt_Purch_Product__c <> null
                                                AND Supplier__c = :supplier.Id
                                                AND Invoice_Net_Amount_woTax_Calc__c <> null
                                                AND Invoice_Net_Amount_woTax_Calc__c > 0
                                                AND Mvt_Purch_Product__c NOT IN (SELECT Product__c FROM Supplier_PG_Mapping__c WHERE Product__c <> null AND Supplier__c = :supplier.Id)
                                                AND Mvt_Purch_Product__r.Brand__c IN :brandDistributorSet
                                                AND Year__c = :year
                                                AND Mvt_Purch_Product__r.IsActive = TRUE
                                                GROUP BY Mvt_Purch_Product__c LIMIT 1000].size();
        Integer countAssortmentWithNegativeSellIn = [SELECT COUNT(Id), Product__c FROM Supplier_PG_Mapping__c
                                                     WHERE Product__c <> null
                                                     AND Supplier__c = :supplier.Id
                                                     AND Product__c IN (SELECT Mvt_Purch_Product__c FROM Sell_in_Flow__c
                                                                        WHERE Mvt_Purch_Product__c <> null
                                                                        AND Supplier__c = :supplier.Id
                                                                        AND Invoice_Net_Amount_woTax_Calc__c <= 0
                                                                        AND Year__c = :year)
                                                     AND Brand__c IN :brandDistributorSet
                                                     AND Product__r.IsActive = TRUE
                                                     GROUP BY Product__c].size();        
        Integer countAssortmentWithoutSellIn = [SELECT COUNT(Id), Product__c FROM Supplier_PG_Mapping__c
                                                WHERE Product__c <> null
                                                AND Supplier__c = :supplier.Id
                                                AND Product__c NOT IN (SELECT Mvt_Purch_Product__c FROM Sell_in_Flow__c
                                                                       WHERE Mvt_Purch_Product__c <> null
                                                                       AND Supplier__c = :supplier.Id
                                                                       AND Year__c = :year)
                                                AND Brand__c IN :brandDistributorSet
                                                AND Product__r.IsActive = TRUE
                                                GROUP BY Product__c].size();
        Integer countOthers = countProducts - (countPositiveSellInWithAssortment + countPositiveSellInWithoutAssortment + countAssortmentWithNegativeSellIn +countAssortmentWithoutSellIn);
        List<Data> data = new List<Data>();
        data.add(new Data(Label.LBL_Sell_in_0_In_Ass, countPositiveSellInWithAssortment, '#b6e32e'));
        data.add(new Data(Label.LBL_Sell_in_0_not_In_ass, countPositiveSellInWithoutAssortment, '#ff5858'));
        data.add(new Data(Label.LBL_Sell_in_equal_0_In_ass, countAssortmentWithNegativeSellIn + countAssortmentWithoutSellIn, '#ffc862'));
        data.add(new Data(Label.LBL_Others, countOthers, '#fff'));
        return data;
    }
        
    // Wrapper class
    global class Data {
        public String name { get; set; }
        public Integer data { get; set; }
        public String codeColor { get; set; }
        public Data(String name, Integer data, String codeColor) {
            this.name = name;
            this.data = data;
            this.codeColor = codeColor;
        }
    }
}