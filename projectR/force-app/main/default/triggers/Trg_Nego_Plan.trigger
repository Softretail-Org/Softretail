trigger Trg_Nego_Plan on Nego_Plan__c (before insert, before update) {
    
	if (Trigger.isBefore) {
		for (Nego_Plan__c negoPlan : System.Trigger.new) {
			if (System.Trigger.isInsert) {
				for (Integer i = 1 ; i <= 3 ; i++) {
					if (negoPlan.get('NEGO_MOM_RDV' + i + '__c') != Null) {
						negoPlan.put('NEGO_MOM_RDV' + i + '__c', system.today().format() + '\n' + negoPlan.get('NEGO_MOM_RDV' + i + '__c'));
					}
				}
				if (negoPlan.NEGO_Keynote_Marketing_Plan__c != Null) {
					negoPlan.NEGO_Keynote_Marketing_Plan__c = system.today().format() + '\n' + negoPlan.NEGO_Keynote_Marketing_Plan__c;
				}
			}
			if (System.Trigger.isUpdate) {
				for (Integer i = 1 ; i <= 3 ; i++) {
					if (negoPlan.get('NEGO_MOM_RDV' + i + '__c') != Null && negoPlan.get('NEGO_MOM_RDV' + i + '__c') != System.Trigger.oldMap.get(negoPlan.Id).get('NEGO_MOM_RDV' + i + '__c')) {
	         			String oldString = (String)negoPlan.get('NEGO_MOM_RDV' + i + '__c');
	         			if (!oldString.contains(system.today().format())) {
	         				oldString.replace(string.valueOf(system.today()), '');
	         				negoPlan.put('NEGO_MOM_RDV' + i + '__c', system.today().format() + '\n' + negoPlan.get('NEGO_MOM_RDV' + i + '__c'));
	         			}
	         		}
				}
         		if (negoPlan.NEGO_Keynote_Marketing_Plan__c != System.Trigger.oldMap.get(negoPlan.Id).NEGO_Keynote_Marketing_Plan__c) {
         			String oldString = negoPlan.NEGO_Keynote_Marketing_Plan__c;
         			if (oldString != Null && !oldString.contains(system.today().format())) {
         				oldString.replace(string.valueOf(system.today()), '');
         				negoPlan.NEGO_Keynote_Marketing_Plan__c = system.today().format() + '\n' + negoPlan.NEGO_Keynote_Marketing_Plan__c;
         			}
         		}
	 		}
		}
	}
}