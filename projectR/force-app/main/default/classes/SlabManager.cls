public class SlabManager {
	
	public static final Integer slabsCount = 8;
    
    public static void sortSlab(Contract_Discount__c discount, Boolean isAsc) {
        if(discount == null) {
            discount = new Contract_Discount__c();
        }
        
        Slab[] slabsList = new List<Slab>();
        for(Integer ndx = 1; ndx <= slabsCount; ndx++) {
            Decimal threshold = (Decimal) discount.get('slab_' + ndx + '__c');
            if(threshold == null)
                continue;
            
            Decimal percentage = (Decimal) discount.get('slab_per_' + ndx + '__c');
            Decimal amount = (Decimal) discount.get('slab_val_' + ndx + '__c');
            Boolean isTarget = discount.slab_target__c == ndx;
            discount.put('slab_' + ndx + '__c', null);
            discount.put('slab_per_' + ndx + '__c', null);
            discount.put('slab_val_' + ndx + '__c', null);
            
            slabsList.add(new Slab(threshold, percentage, amount, isTarget, isAsc));
        }
        discount.slab_target__c = null;
        // sort
        slabsList.sort();
        for(Integer ndx = 1; ndx <= slabsCount; ndx++) {
            
            if(slabsList.size() >= ndx) {
                Slab wrapper = slabsList.get(ndx-1);
                
                discount.put('slab_' + ndx + '__c', wrapper.threshold);
                discount.put('slab_per_' + ndx + '__c', wrapper.percentage);
                discount.put('slab_val_' + ndx + '__c', wrapper.amount);
                
                if(wrapper.isTarget) {
                    discount.slab_target__c = ndx;
                }
            } else {
                discount.put('slab_' + ndx + '__c', null);
                discount.put('slab_per_' + ndx + '__c', null);
                discount.put('slab_val_' + ndx + '__c', null);
            }
        }
        // Set % and amount according to the target
        if(discount.slab_target__c != null && discount.slab_target__c != 0) {
            discount.value_per__c = (Decimal) discount.get('slab_per_' + discount.slab_target__c + '__c');
            discount.value_amt__c = (Decimal) discount.get('slab_val_' + discount.slab_target__c + '__c');
        } else {
            discount.value_per__c = null;
            discount.value_amt__c = null;
        }
    }
    /** Inner Class **/
    private class Slab implements Comparable {
        private Decimal threshold;
        private Decimal percentage;
        private Decimal amount;
        private Boolean isTarget;
        private Boolean isAsc = true;
        
        public Slab(Decimal threshold, Decimal percentage, Decimal amount, Boolean isTarget, Boolean isAsc) {
            this.threshold = threshold;
            this.percentage = percentage;
            this.amount = amount;
            this.isTarget = isTarget;
            this.isAsc = isAsc;
        }
        
        public Integer compareTo(Object obj) {
            
            if(isAsc)
                return compareASC(obj);
            else
                return compareDesc(obj);
        }
        
        private Integer compareASC(Object compareTo){
            Slab compareToOppy = (Slab)compareTo;
            
            if (threshold > compareToOppy.threshold) {
                return 1;
            } else if (threshold < compareToOppy.threshold) {
                return -1;
            } else {
                return 0;
            }
        }
        
        private Integer compareDESC(Object compareTo){
            Slab compareToOppy = (Slab)compareTo;
            
            if (threshold > compareToOppy.threshold) {
                return -1;
            } else if (threshold < compareToOppy.threshold) {
                return 1;
            } else {
                return 0;
            }
        }
    }
}