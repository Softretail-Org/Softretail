/**
 * Check and validate uniqueness constraint of name and code in Product Structure (Orga_HE__c)
 * Ensure that there is on root node
 * Closing a parent element will close any related elements
 * */
trigger Trg_Org_HE on Orga_HE__c (before insert, before update, before delete, after insert, after update) {

	Orga_HE__c HERoot;
	//public recursiveHelper rh{ get; set; }

    if (Trigger.isBefore) {
    	if(System.Trigger.isInsert) {
    		// Check if Root node exist	   
		    try {
		        HERoot = [SELECT Id, Name FROM Orga_HE__c WHERE Level__c = 0 AND Parent_Element__c = NULL limit 1];
		    } catch(Exception e) {
		        HERoot = null;
		    }
    	}
        
        if (System.Trigger.isInsert || System.Trigger.isUpdate) {
            Set<Id> parentIds = new Set<Id>();
            for (Orga_HE__c item : trigger.new) {
                if (item.Parent_Element__c != null) {
                    parentIds.add(item.Parent_Element__c);
                }
            }
            // Set the level based on the parent value
            Map<Id, Orga_HE__c> orgaHEMap = new Map<Id, Orga_HE__c>([SELECT Id, Name, Level__c, Path__c FROM Orga_HE__c WHERE Id = :parentIds]);
            for (Orga_HE__c item : trigger.new) {
                if (item.Parent_Element__c == null || !orgaHEMap.containsKey(item.Parent_Element__c)) {
                    item.Level__c = 0;
                    continue;
                }
                item.Level__c = orgaHEMap.get(item.Parent_Element__c).Level__c + 1;
            }
			      
			Map<String, Orga_HE__c> HECodeMap = new Map<String, Orga_HE__c>();			
            for (Orga_HE__c item : System.Trigger.new) {
                // parent check
                if (System.Trigger.isInsert) {
                    if (HERoot != null && item.Parent_Element__c == null) {
                        item.Level__c.addError(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Root_Level);   	
                    }
                }
                
                if (System.Trigger.isInsert || (System.Trigger.isUpdate && (item.Elt_Code__c != System.Trigger.oldMap.get(item.Id).Elt_Code__c))) {
                    // Make sure another new Product structure element isn't also a duplicate by code 
                    if (HECodeMap.containsKey(item.Elt_Code__c)) {
                        item.addError(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value);
                    } else {
                        HECodeMap.put(item.Elt_Code__c,item);
                    }
                    if (item.Parent_Element__c != null) 
                        item.Path__c = orgaHEMap.get(item.Parent_Element__c).Path__c + '|' + item.Elt_code__c;
                    else
                        item.Path__c = item.Elt_code__c;
                }
                // Element can change parent for identical parent level only
                if (System.Trigger.isUpdate) {
                    if (item.Level__c != System.Trigger.oldMap.get(item.Id).Level__c) {
                        item.Parent_Element__c.addError(System.Label.MSG_Chose_Identical_Parent_Element_Level);
                    }
                }
            }
            // Using a single database query, find all the HE in the database that have the same name as any 
            // of the Hes being inserted or updated.   
            for (Orga_HE__c he : [SELECT Elt_Code__c FROM Orga_HE__c WHERE Elt_Code__c IN :HECodeMap.KeySet()]) {
                Orga_HE__c newHE = HECodeMap.get(he.Elt_Code__c);
                if (newHE != null) newHE.Elt_Code__c.addError(System.Label.MSG_Product_Structure_Already_Exists_With_The_Same_Code_Value);    
            }
	    }
	    
		if (System.Trigger.isDelete) {
            // Fill parent HE Map for check if related to childrens
            Map<Id, List<Orga_HE__c>> parentHEMap = new Map<Id, List<Orga_HE__c>>();
            for (Orga_HE__c item : [SELECT Id, Level__c, Parent_Element__c
                                    FROM Orga_HE__c
                                    WHERE Parent_Element__c IN :Trigger.old]) 
            {
                if (!parentHEMap.containsKey(item.Parent_Element__c)) {
                    parentHEMap.put(item.Parent_Element__c, new List<Orga_HE__c>{item});
                } else {
                    parentHEMap.get(item.Parent_Element__c).add(item);
                }
            }
            for (Orga_HE__c item : Trigger.old) {
                // check if delete the root HE
                if (item.Level__c == 0 && item.Parent_Element__c == null) {
                    item.addError(System.Label.MSG_Can_Not_Delete_Root_Element);
                }
                // check if delete the HE have childrens
                else if (parentHEMap.containsKey(item.Id)) {
                    item.adderror(System.Label.MSG_Cannot_Delete_Record);
                }
            }
		}
        
        /***
		if (System.Trigger.isUpdate) {
            Boolean isClosed = false;
            String heId;
            //Closing a parent element will close any child elements
            Savepoint sp = Database.setSavepoint();
            for(Orga_HE__c ps : trigger.new) {
                if(ps.Status__c=='Closed'){
                    isClosed = true ;
                    heId = ps.Id;	
                }
            }
            
            if(isClosed==true && CheckRecursive.runOnce()){ 
                // To Do : handle limitation of 1000 element in a list on update , might do a batch with multiple list
                // to do  : by pass field filter 		 	 
                rh = new recursiveHelper();
                
                Map<ID,ID> mapHeId = new Map<ID,ID>();  
                mapHeId.put(heId,heId);
                Map<Decimal,List<Id>>  mapChildHeIds = rh.getAllIds(mapHeId);	  
                List<Decimal> keyList = new List<Decimal>(); 
                keyList.addAll(mapChildHeIds.keySet());
                list<Orga_HE__c> updateAllChildElementList = new List<Orga_HE__c>();
                
                for(Integer i = keyList.size()-1; i>=0;i--){
                    List<Id> lstChildIds = mapChildHeIds.get(keyList.get(i));
                    
                    for(Orga_HE__c allChildElement: [SELECT Name,Status__c FROM Orga_HE__c WHERE  Status__c != 'Closed' AND Id IN :lstChildIds])
                    {
                        allChildElement.Status__c='Closed';	 		   			
                        updateAllChildElementList.add(allChildElement);	    
                    }
                    if(updateAllChildElementList!=NULL && updateAllChildElementList.size()>0){	
                        try{
                            update updateAllChildElementList;
                            
                        }
                        catch(exception ex){
                            Database.rollback(sp);
                        }
                    }
                }
            }
		}
		***/
    }
    
    if (Trigger.isAfter) {
        
        if (System.Trigger.isUpdate) {
            // Update path for children
            Set<String> updatedItemsPathsList = new Set<String>();
            List<Orga_HE__c> orgaHEsToUpdate = new List<Orga_HE__c>();
            for (Orga_HE__c item : trigger.new) {
                if (item.Path__c != System.Trigger.oldMap.get(item.Id).Path__c)
                    updatedItemsPathsList.add(String.format('%{0}%', new List<String>{Trigger.oldMap.get(item.id).Path__c + '|'}));
            }
            for (Orga_HE__c item : [SELECT Id, Path__c, Elt_Code__c, Parent_Element__c, Parent_Element__r.Path__c
                                    FROM Orga_HE__c
                                    WHERE Path__c LIKE :updatedItemsPathsList
                                    ORDER BY Level__c ASC])
            {
                if (item.Parent_Element__c != null ) {
                    item.Path__c = item.Parent_Element__r.Path__c + '|' + item.Elt_Code__c;
                } else 
                    item.Path__c = item.Elt_Code__c;
                orgaHEsToUpdate.add(item);
            }
            if (!orgaHEsToUpdate.isEmpty()) update orgaHEsToUpdate;
        }
    }
}