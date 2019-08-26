/**
 * Called from process builder to
 * Insert Redistribution Details
 * */
global class RedistributionInsertAction {

    @InvocableMethod(label='Insert Redistribution Details' description='Insert Redistribution Details.')
    public static void generateRedistributionDetails(List<Redistrib_head__c> redistributions) {

        Map<Id, List<WrapperBU>> redistributionsBUCodeMap = new Map<Id, List<WrapperBU>>();
        Set<String> allBUCodeSet = new Set<String>();

        for(Redistrib_head__c item : redistributions) {
            Set<String> BUCodeSet = new Set<String>();
            List<WrapperBU> wBUList = new List<WrapperBU>();
            for(Integer i = 1; i <= 150; i++) {
                String code = (String)item.get('BU' + i + '_Code__c');
                Decimal amount = (Decimal)item.get('BU' + i + '_Amount__c');
                if(code != null && code.trim() != '' && !BUCodeSet.contains(code.trim())) {
                    code = code.trim();
                    code = code.leftPad(4, '0');
                    WrapperBU wBU = new WrapperBU(code, amount);
                    wBUList.add(wBU);
                    BUCodeSet.add(code);
                    allBUCodeSet.add(code);
                }
            }
            if(BUCodeSet.size() > 0) {
                redistributionsBUCodeMap.put(item.Id, wBUList);
            }
        }
        
        Map<String, Id> BUCodeIdMap = new Map<String, Id>();
        if(allBUCodeSet.size() > 0) {
            for(Orga_BU__c item : [SELECT Id, BU_Code__c
                                   FROM Orga_BU__c
                                   WHERE BU_Code__c IN :allBUCodeSet
                                   AND RecordType.DeveloperName = 'Store'])
            {
                BUCodeIdMap.put(item.BU_Code__c, item.Id);
            }
        }
        // create and attach the list of Redistrib_detail__c to their parent Redistrib_head__c
        List<Redistrib_detail__c> redistributionDetailList = new List<Redistrib_detail__c>();
        if(redistributionsBUCodeMap.size() > 0) {
            for(Id key : redistributionsBUCodeMap.keySet()) {
                for(WrapperBU item : redistributionsBUCodeMap.get(key)) {
                    if(BUCodeIdMap.containsKey(item.code)) {
                        Redistrib_detail__c redistributionDetail = new Redistrib_detail__c(Redistrib_head__c = key, Store__c = BUCodeIdMap.get(item.code),
                                                                                           Redistrib_amnt_HT__c = item.amount);
                        redistributionDetailList.add(redistributionDetail);
                    }
                }
            }
        }
        if(redistributionDetailList.size() > 0) {
            Database.insert(redistributionDetailList, false);
        }
    }
    
    class WrapperBU {
        String code;
        Decimal amount;
        
        public WrapperBU(String s, Decimal d) {
            this.code = s;
            this.amount = d;
        }
    }
}