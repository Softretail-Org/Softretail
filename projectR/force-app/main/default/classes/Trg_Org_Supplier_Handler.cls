public class Trg_Org_Supplier_Handler {
	
    private static String key;
    
    public static void OnBeforeInsertOrUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	setStatusToClose(nSuppliers, oSupplierMap);
    }
    
    public static void OnBeforeInsert(List<Sup_Supplier__c> nSuppliers) {
        checkDupCodeCountryOriginOnInsert(nSuppliers);
        //checkDupNameCountryOriginOnInsert(nSuppliers);
        //checkDupIntracommCountryOriginOnInsert(nSuppliers);
        //checkDupSirenCountryOriginOnInsert(nSuppliers);
        //checkDupSiretCountryOriginOnInsert(nSuppliers);
        fetchCountriesOnInsert(nSuppliers);
    }
    
    public static void OnBeforeUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
        checkDupCodeCountryOriginOnUpdate(nSuppliers, oSupplierMap);
        //checkDupNameCountryOriginOnInsert(nSuppliers, oSupplierMap);
        //checkDupIntracommCountryOriginOnInsert(nSuppliers, oSupplierMap);
        //checkDupSirenCountryOriginOnInsert(nSuppliers, oSupplierMap);
        //checkDupSiretCountryOriginOnInsert(nSuppliers, oSupplierMap);
        fetchCountriesOnUpdate(nSuppliers, oSupplierMap);
    }
    
    public static void OnAfterInsert(List<Sup_Supplier__c> nSuppliers) {
        insertDefaultNS(nSuppliers);
    }
    
    public static void OnAfterUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
        setNegoScopeAddresses(nSuppliers, oSupplierMap);
    }
    
    /*
	 * Insert default NS.
     * @param List<Sup_Supplier__c> nSuppliers
     * On After Insert.
     **/
    private static void insertDefaultNS(List<Sup_Supplier__c> nSuppliers) {
        List<Sup_sup_NegoScope__c> negoScopes = new List<Sup_sup_NegoScope__c>();
        for(Sup_Supplier__c supplier : nSuppliers) {
            if(supplier.Is_Default_NegoScope__c) {
                String negoscopeName = System.Label.LBL_Default_NegoScope + ' - ' + supplier.Name;
                //Creation of default NS
                Sup_sup_NegoScope__c negoScope = new Sup_sup_NegoScope__c(Name = negoscopeName, CurrencyIsoCode = supplier.CurrencyIsoCode,
                                                                          OwnerId = UserInfo.getUserId(), Supplier__c = supplier.Id,
                                                                          Is_All_Brands__c = true, Is_All_HE__c = true, Is_All__c = true,
                                                                          Acc_Address_External_Synchro__c = false, Admin_Address_External_Synchro__c = false,
                                                                          Acc_Country__c = supplier.Acc_Country__c);
                negoScopes.add(negoScope);
            }
        }
        if (negoScopes.size() > 0) {
        	insert negoScopes;
        }
    }
    
    /*
	 * Assign fields on NS.
     * @param List<Sup_Supplier__c> nSuppliers
     * On After Update.
     **/
    private static void setNegoScopeAddresses(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
        List<Sup_sup_NegoScope__c> negoScopes = new List<Sup_sup_NegoScope__c>();
        Map<Id, Sup_Supplier__c>  mapSupplierAdmin = new Map<Id, Sup_Supplier__c>(), mapSupplierAcc = new Map<Id, Sup_Supplier__c>();
        for (Sup_Supplier__c supplier : nSuppliers) {
            Sup_Supplier__c oldSupplier = oSupplierMap.get(supplier.Id);
            if (supplier.Admin_Address1__c != oldSupplier.Admin_Address1__c ||
                supplier.Admin_Address2__c != oldSupplier.Admin_Address2__c ||
                supplier.Admin_City__c != oldSupplier.Admin_City__c ||
                supplier.Admin_Country__c != oldSupplier.Admin_Country__c ||
                supplier.Admin_Fax__c != oldSupplier.Admin_Fax__c ||
                supplier.Admin_Phone1__c != oldSupplier.Admin_Phone1__c ||
                supplier.Admin_Phone2__c != oldSupplier.Admin_Phone2__c ||
                supplier.Admin_PostCode__c != oldSupplier.Admin_PostCode__c ||
                supplier.Admin_Raison__c != oldSupplier.Admin_Raison__c) {
                    mapSupplierAdmin.put(supplier.Id, supplier);                    
                }
            if (supplier.Acc_Address1__c != oldSupplier.Acc_Address1__c ||
                supplier.Acc_Address2__c != oldSupplier.Acc_Address2__c ||                
                supplier.Acc_City__c != oldSupplier.Acc_City__c ||
                supplier.Acc_Country__c != oldSupplier.Acc_Country__c ||
                supplier.Acc_Fax__c != oldSupplier.Acc_Fax__c ||
                supplier.Acc_Phone1__c != oldSupplier.Acc_Phone1__c ||
                supplier.Acc_Phone2__c != oldSupplier.Acc_Phone2__c ||
                supplier.Acc_PostCode__c != oldSupplier.Acc_PostCode__c ||
                supplier.Acc_Raison__c != oldSupplier.Acc_Raison__c) {
                    mapSupplierAcc.put(supplier.Id, supplier);                    
                }
        }
        if (mapSupplierAdmin.size() > 0 || mapSupplierAcc.size() > 0) {
            negoScopes = [SELECT Id, Name, Is_All_Brands__c, Incl_NewBrand__c, Incl_NewProduct__c, Parent_Nego_Scope__c, Status__c,
            				Is_All_HE__c, Is_All__c, Supplier__c, OwnerId, Admin_Address_External_Synchro__c, Acc_Address_External_Synchro__c,
            				Acc_Address1__c, Acc_Address2__c, Acc_City__c, Acc_Contact__c, Acc_Country__c, Acc_email__c, Acc_Fax__c, Acc_Phone1__c,
                           	Acc_Phone2__c, Acc_PostCode__c, Acc_Raison__c, Admin_Address1__c, Admin_Address2__c, Admin_City__c, Admin_Contact__c,
                           	Admin_Country__c, Admin_Fax__c, Admin_Phone1__c, Admin_Phone2__c, Admin_PostCode__c, Admin_Raison__c 
                           	FROM Sup_sup_NegoScope__c
                           	WHERE (Supplier__c IN :mapSupplierAdmin.KeySet() OR Supplier__c IN :mapSupplierAcc.KeySet())
                           	AND ( Admin_Address_External_Synchro__c = true OR Acc_Address_External_Synchro__c = true)];
            if (negoScopes != null && negoScopes.size() > 0) {
                for (Sup_sup_NegoScope__c nego : negoScopes) {
                    if (nego.Admin_Address_External_Synchro__c == true && mapSupplierAdmin.containsKey(nego.Supplier__c)) {
                        nego.Admin_Address1__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_Address1__c;
                        nego.Admin_Address2__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_Address2__c;
                        nego.Admin_City__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_City__c;
                        nego.Admin_Country__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_Country__c;
                        nego.Admin_Fax__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_Fax__c;
                        nego.Admin_Phone1__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_Phone1__c;
                        nego.Admin_Phone2__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_Phone2__c;
                        nego.Admin_PostCode__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_PostCode__c;
                        nego.Admin_Raison__c = mapSupplierAdmin.get(nego.Supplier__c).Admin_Raison__c;
                    }
                    if (nego.Acc_Address_External_Synchro__c == true && mapSupplierAcc.containsKey(nego.Supplier__c)) {
                        nego.Acc_Address1__c = mapSupplierAcc.get(nego.Supplier__c).Acc_Address1__c;
                        nego.Acc_Address2__c = mapSupplierAcc.get(nego.Supplier__c).Acc_Address2__c;
                        nego.Acc_City__c = mapSupplierAcc.get(nego.Supplier__c).Acc_City__c;
                        nego.Acc_Country__c = mapSupplierAcc.get(nego.Supplier__c).Acc_Country__c;
                        nego.Acc_Phone1__c = mapSupplierAcc.get(nego.Supplier__c).Acc_Phone1__c;
                        nego.Acc_Phone2__c = mapSupplierAcc.get(nego.Supplier__c).Acc_Phone2__c;
                        nego.Acc_Fax__c = mapSupplierAcc.get(nego.Supplier__c).Acc_Fax__c;
                        nego.Acc_PostCode__c = mapSupplierAcc.get(nego.Supplier__c).Acc_PostCode__c;
                        nego.Acc_Raison__c = mapSupplierAcc.get(nego.Supplier__c).Acc_Raison__c;
                    }
                }
            }
            if (negoScopes.isEmpty() == false) {
                update negoScopes;
            }
        }
    }  
    
    private static void checkDupCodeCountryOriginOnInsert(List<Sup_Supplier__c> nSuppliers) {
    	String errMsg1 = System.Label.MSG_Code_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> codeCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCode = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin1 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	key = supplier.Code__c + '' + supplier.Country_origin__c;
	    	// Check Code__c// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
     		if (codeCountryOriginMap.containsKey(key)) {
         		supplier.addError(errMsg1);
         	} else {
         		codeCountryOriginMap.put(key, supplier);
         		supplierMapCode.put(supplier.Code__c, supplier);
         		supplierMapCountryOrigin1.put(supplier.Country_origin__c, supplier);  
     		}
     		
	    }
        for (Sup_Supplier__c supplier : [SELECT Code__c, Country_origin__c
                                        	FROM Sup_Supplier__c
                                        	WHERE Code__c IN :supplierMapCode.KeySet()
                                        	AND Country_origin__c IN :supplierMapCountryOrigin1.KeySet()]) {
	                                            key = supplier.Code__c + '' + supplier.Country_origin__c;
	                                            Sup_Supplier__c newSupplier = codeCountryOriginMap.get(key);
	        if (newSupplier != null) {
	            newSupplier.Code__c.addError(errMsg1);
	        }
        }
    }
    
    private static void checkDupCodeCountryOriginOnUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	String errMsg1 = System.Label.MSG_Code_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> codeCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCode = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin1 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	key = supplier.Code__c + '' + supplier.Country_origin__c;
	    	// Check Code__c
            if (supplier.Code__c != oSupplierMap.get(supplier.Id).Code__c ||
         		supplier.Country_origin__c != oSupplierMap.get(supplier.Id).Country_origin__c) {
         		// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
         		if (codeCountryOriginMap.containsKey(key)) {
             		supplier.addError(errMsg1);
             	} else {
             		codeCountryOriginMap.put(key, supplier);
             		supplierMapCode.put(supplier.Code__c, supplier);
             		supplierMapCountryOrigin1.put(supplier.Country_origin__c, supplier);  
         		}
     		}
	    }
        for (Sup_Supplier__c supplier : [SELECT Code__c, Country_origin__c
                                        	FROM Sup_Supplier__c
                                        	WHERE Code__c IN :supplierMapCode.KeySet()
                                        	AND Country_origin__c IN :supplierMapCountryOrigin1.KeySet()]) {
	                                            key = supplier.Code__c + '' + supplier.Country_origin__c;
	                                            Sup_Supplier__c newSupplier = codeCountryOriginMap.get(key);
	        if (newSupplier != null) {
	            newSupplier.Code__c.addError(errMsg1);
	        }
        }
    }
    
    private static void checkDupNameCountryOriginOnInsert(List<Sup_Supplier__c> nSuppliers) {
		String errMsg2 = System.Label.MSG_SupplierName_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> nameCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapSupplierName = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin2 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	key = supplier.Name + '' + supplier.Country_origin__c;
	    	// Check Name
            // Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
         	if (nameCountryOriginMap.containsKey(key)) {
         		supplier.addError(errMsg2);
         	} else {
         		nameCountryOriginMap.put(key, supplier);
             	supplierMapSupplierName.put(supplier.Name, supplier);
             	supplierMapCountryOrigin2.put(supplier.Country_origin__c, supplier);   
         	}
	    }
        for (Sup_Supplier__c supplier :[SELECT Name, Country_origin__c
                                        FROM Sup_Supplier__c
                                        WHERE Name IN :supplierMapSupplierName.KeySet()
                                        AND Country_origin__c IN :supplierMapCountryOrigin2.KeySet()]) {
		    key = supplier.Name + '' + supplier.Country_origin__c;
		    Sup_Supplier__c newSupplier = nameCountryOriginMap.get(key);
		    if (newSupplier != null) {
		        newSupplier.Name.addError(errMsg2);
		    }
   		}
    }
    
    private static void checkDupNameCountryOriginOnUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
		String errMsg2 = System.Label.MSG_SupplierName_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> nameCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapSupplierName = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin2 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	key = supplier.Name + '' + supplier.Country_origin__c;
	    	// Check Name
            if (supplier.Name != oSupplierMap.get(supplier.Id).Name || 
            	supplier.Country_origin__c != oSupplierMap.get(supplier.Id).Country_origin__c) {
         		// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
             	if (nameCountryOriginMap.containsKey(key)) {
             		supplier.addError(errMsg2);
             	} else {
             		nameCountryOriginMap.put(key, supplier);
                 	supplierMapSupplierName.put(supplier.Name, supplier);
                 	supplierMapCountryOrigin2.put(supplier.Country_origin__c, supplier);   
             	}
 			}
	    }
        for (Sup_Supplier__c supplier :[SELECT Name, Country_origin__c
                                        FROM Sup_Supplier__c
                                        WHERE Name IN :supplierMapSupplierName.KeySet()
                                        AND Country_origin__c IN :supplierMapCountryOrigin2.KeySet()]) {
		    key = supplier.Name + '' + supplier.Country_origin__c;
		    Sup_Supplier__c newSupplier = nameCountryOriginMap.get(key);
		    if (newSupplier != null) {
		        newSupplier.Name.addError(errMsg2);
		    }
   		}
    }
    
    private static void checkDupIntracommCountryOriginOnInsert(List<Sup_Supplier__c> nSuppliers) {
    	String errMsg3 = System.Label.MSG_Intracomm_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> supplierMapIntracommunity = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin3 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
         	if (!supplierMapIntracommunity.containsKey(supplier.Intracommunity_VAT_Num__c) && !supplierMapCountryOrigin3.containsKey(supplier.Country_origin__c)) {
         		supplierMapIntracommunity.put(supplier.Intracommunity_VAT_Num__c, supplier);
         		supplierMapCountryOrigin3.put(supplier.Country_origin__c, supplier);                
			}
	    }
        if (supplierMapIntracommunity.KeySet() != null) {
            for (Sup_Supplier__c supplier :[SELECT Intracommunity_VAT_Num__c, Country_origin__c
                                            FROM Sup_Supplier__c
                                            WHERE Intracommunity_VAT_Num__c IN :supplierMapIntracommunity.KeySet()
                                            AND Country_origin__c IN :supplierMapCountryOrigin3.KeySet()]) {
                if (supplier != null && supplier.Intracommunity_VAT_Num__c != null) {
                    Sup_Supplier__c newSupplier = supplierMapIntracommunity.get(supplier.Intracommunity_VAT_Num__c);
                    newSupplier.Intracommunity_VAT_Num__c.addError(errMsg3);
        		}
        	}
        }
    }
    
    private static void checkDupIntracommCountryOriginOnUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	String errMsg3 = System.Label.MSG_Intracomm_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> supplierMapIntracommunity = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin3 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	// Check Intracommunity_VAT_Num__c
            if (supplier.Intracommunity_VAT_Num__c != oSupplierMap.get(supplier.Id).Intracommunity_VAT_Num__c ||
            	supplier.Country_origin__c != oSupplierMap.get(supplier.Id).Country_origin__c) {
     			// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
	         	if (!supplierMapIntracommunity.containsKey(supplier.Intracommunity_VAT_Num__c) && !supplierMapCountryOrigin3.containsKey(supplier.Country_origin__c)) {
             		supplierMapIntracommunity.put(supplier.Intracommunity_VAT_Num__c, supplier);
             		supplierMapCountryOrigin3.put(supplier.Country_origin__c, supplier);                
    			}
        	}
	    }
        if (supplierMapIntracommunity.KeySet() != null) {
            for (Sup_Supplier__c supplier :[SELECT Intracommunity_VAT_Num__c, Country_origin__c
                                            FROM Sup_Supplier__c
                                            WHERE Intracommunity_VAT_Num__c IN :supplierMapIntracommunity.KeySet()
                                            AND Country_origin__c IN :supplierMapCountryOrigin3.KeySet()]) {
                if (supplier != null && supplier.Intracommunity_VAT_Num__c != null) {
                    Sup_Supplier__c newSupplier = supplierMapIntracommunity.get(supplier.Intracommunity_VAT_Num__c);
                    newSupplier.Intracommunity_VAT_Num__c.addError(errMsg3);
        		}
        	}
        }
    }
    
    private static void checkDupSirenCountryOriginOnInsert(List<Sup_Supplier__c> nSuppliers) {
    	String errMsg4 = System.Label.MSG_Siren_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> sirenCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapSiren = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin4 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	if(supplier.SIREN_Number__c != null && supplier.SIREN_Number__c != '') {
                key = supplier.SIREN_Number__c + '' + supplier.Country_origin__c;
        	} else {
                key = null;
            }
            // Check SIREN_Number__c
         	// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
 			if (key != null && sirenCountryOriginMap.containsKey(key)) {
         		supplier.addError(errMsg4);
     		} else {
     			sirenCountryOriginMap.put(key, supplier);
             	supplierMapSiren.put(supplier.SIREN_Number__c, supplier);
             	supplierMapCountryOrigin4.put(supplier.Country_origin__c, supplier);
            }
	    }
        if (supplierMapSiren.KeySet() != null) {
    		for (Sup_Supplier__c supplier : [SELECT SIREN_Number__c, Country_origin__c
                                             FROM Sup_Supplier__c
                                             WHERE SIREN_Number__c IN :supplierMapSiren.KeySet()
                                             AND Country_origin__c IN :supplierMapCountryOrigin4.KeySet()]) {
	     		if(supplier.SIREN_Number__c != null && supplier.SIREN_Number__c != '') {
	         		key = supplier.SIREN_Number__c + '' + supplier.Country_origin__c;
	             	Sup_Supplier__c newSupplier = sirenCountryOriginMap.get(key);
	             	if (newSupplier != null) {
	             		newSupplier.SIREN_Number__c.addError(errMsg4);
	         		}
	     		}
     		}
    	}
    }
    
    private static void checkDupSirenCountryOriginOnUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	String errMsg4 = System.Label.MSG_Siren_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> sirenCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapSiren = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin4 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	if(supplier.SIREN_Number__c != null && supplier.SIREN_Number__c != '') {
                key = supplier.SIREN_Number__c + '' + supplier.Country_origin__c;
        	} else {
                key = null;
            }
            // Check SIREN_Number__c
            if (supplier.SIREN_Number__c != oSupplierMap.get(supplier.Id).SIREN_Number__c ||
            	supplier.Country_origin__c != oSupplierMap.get(supplier.Id).Country_origin__c) {
                 // Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
         		if (key != null && sirenCountryOriginMap.containsKey(key)) {
             		supplier.addError(errMsg4);
         		} else {
 					sirenCountryOriginMap.put(key, supplier);
             		supplierMapSiren.put(supplier.SIREN_Number__c, supplier);
             		supplierMapCountryOrigin4.put(supplier.Country_origin__c, supplier);
             	}
         	}
	    }
        if (supplierMapSiren.KeySet() != null) {
    		for (Sup_Supplier__c supplier : [SELECT SIREN_Number__c, Country_origin__c
                                             FROM Sup_Supplier__c
                                             WHERE SIREN_Number__c IN :supplierMapSiren.KeySet()
                                             AND Country_origin__c IN :supplierMapCountryOrigin4.KeySet()]) {
	     		if(supplier.SIREN_Number__c != null && supplier.SIREN_Number__c != '') {
	         		key = supplier.SIREN_Number__c + '' + supplier.Country_origin__c;
	             	Sup_Supplier__c newSupplier = sirenCountryOriginMap.get(key);
	             	if (newSupplier != null) {
	             		newSupplier.SIREN_Number__c.addError(errMsg4);
	         		}
	     		}
     		}
    	}
    }
    
    private static void checkDupSiretCountryOriginOnInsert(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	String errMsg5 = System.Label.MSG_Siret_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> siretCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapSiret = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin5 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
			if(supplier.SIRET_Number__c != null && supplier.SIRET_Number__c != '') {
                key = supplier.SIRET_Number__c + '' + supplier.Country_origin__c;
            } else {
                key = null;
            }
            // Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
         	if (key != null && siretCountryOriginMap.containsKey(key)) {
         		supplier.addError(errMsg5);
 			} else {
         		siretCountryOriginMap.put(key, supplier);
             	supplierMapSiret.put(supplier.SIRET_Number__c, supplier);
             	supplierMapCountryOrigin5.put(supplier.Country_origin__c, supplier);   
         	} 
	    }
        if (supplierMapSiret.KeySet() != null) {
            for (Sup_Supplier__c supplier : [SELECT SIRET_Number__c, Country_origin__c
                                             FROM Sup_Supplier__c
                                             WHERE SIRET_Number__c IN :supplierMapSiret.KeySet()
                                             AND Country_origin__c IN :supplierMapCountryOrigin5.KeySet()]) {
         		if(supplier.SIRET_Number__c != null && supplier.SIRET_Number__c != '') {
             		key = supplier.SIRET_Number__c + '' + supplier.Country_origin__c;
                 	Sup_Supplier__c newSupplier = siretCountryOriginMap.get(key);
                 	if (newSupplier != null) {
                 		newSupplier.SIRET_Number__c.addError(errMsg5);
                 	}
             	}
         	}
		}
    }
    
    private static void checkDupSiretCountryOriginOnUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	String errMsg5 = System.Label.MSG_Siret_With_CountryOrigin_Already_Exist;
    	Map<String, Sup_Supplier__c> siretCountryOriginMap = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapSiret = new Map<String, Sup_Supplier__c>();
	    Map<String, Sup_Supplier__c> supplierMapCountryOrigin5 = new Map<String, Sup_Supplier__c>();
	    for (Sup_Supplier__c supplier : nSuppliers) {
	    	if(supplier.SIRET_Number__c != null && supplier.SIRET_Number__c != '') {
                key = supplier.SIRET_Number__c + '' + supplier.Country_origin__c;
            } else {
                key = null;
            }
            if (supplier.SIRET_Number__c != oSupplierMap.get(supplier.Id).SIRET_Number__c ||
           		supplier.Country_origin__c != oSupplierMap.get(supplier.Id).Country_origin__c) {
         		// Make sure another new supplier code corresponding to an existing supplier isn't also a duplicate.
             	if (key != null && siretCountryOriginMap.containsKey(key)) {
             		supplier.addError(errMsg5);
             	} else {
             		siretCountryOriginMap.put(key, supplier);
                 	supplierMapSiret.put(supplier.SIRET_Number__c, supplier);
                 	supplierMapCountryOrigin5.put(supplier.Country_origin__c, supplier);   
             	}
         	}
	    }
        if (supplierMapSiret.KeySet() != null) {
            for (Sup_Supplier__c supplier : [SELECT SIRET_Number__c, Country_origin__c
                                             FROM Sup_Supplier__c
                                             WHERE SIRET_Number__c IN :supplierMapSiret.KeySet()
                                             AND Country_origin__c IN :supplierMapCountryOrigin5.KeySet()]) {
         		if(supplier.SIRET_Number__c != null && supplier.SIRET_Number__c != '') {
             		key = supplier.SIRET_Number__c + '' + supplier.Country_origin__c;
                 	Sup_Supplier__c newSupplier = siretCountryOriginMap.get(key);
                 	if (newSupplier != null) {
                 		newSupplier.SIRET_Number__c.addError(errMsg5);
                 	}
             	}
         	}
		}
    }
    
    private static void fetchCountriesOnInsert(List<Sup_Supplier__c> nSuppliers) {
    	Set<String> refCountrySet = new Set<String>();
        Set<String> refCountryNameSet = new Set<String>();
        Map<String, String> refCountryCodeMap = new Map<String, String>();
        for(Sup_Supplier__c supplier : nSuppliers) {
        	if(supplier.Ref_Country__c != null) {
	            refCountrySet.add(supplier.Ref_Country__c);
	        }
        }
    	// fetch countries
        for (Country_List__c country : [SELECT Name, Country_Code__c
        								FROM Country_List__c
        								WHERE Name LIKE :refCountrySet OR Country_Code__c LIKE :refCountrySet]) {
            refCountryNameSet.add(country.Name.toUpperCase());
            refCountryCodeMap.put(country.Country_Code__c.toUpperCase(), country.Name);
        }
        for (Sup_Supplier__c supplier : nSuppliers) {
        	if (supplier.Ref_Country__c != null) {
        		if (refCountryNameSet.contains(supplier.Ref_Country__c.toUpperCase())) {
           			// Do nothings
	           	} else if(refCountryCodeMap.containsKey(supplier.Ref_Country__c.toUpperCase())) {
	               	supplier.Ref_Country__c = refCountryCodeMap.get(supplier.Ref_Country__c.toUpperCase());
	           	} else {
	           		supplier.Ref_Country__c.addError('Ref Country not exist.');
	       		}
        	}
    	}
    }
    
    private static void fetchCountriesOnUpdate(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	Set<String> refCountrySet = new Set<String>();
        Set<String> refCountryNameSet = new Set<String>();
        Map<String, String> refCountryCodeMap = new Map<String, String>();
        for(Sup_Supplier__c supplier : nSuppliers) {
        	if(supplier.Ref_Country__c != null) {
	            refCountrySet.add(supplier.Ref_Country__c);
	        }
        }
    	// fetch countries
        for (Country_List__c country : [SELECT Name, Country_Code__c
        								FROM Country_List__c
        								WHERE Name LIKE :refCountrySet OR Country_Code__c LIKE :refCountrySet]) {
            refCountryNameSet.add(country.Name.toUpperCase());
            refCountryCodeMap.put(country.Country_Code__c.toUpperCase(), country.Name);
        }
        for (Sup_Supplier__c supplier : nSuppliers) {
            if (supplier.Ref_Country__c != oSupplierMap.get(supplier.Id).Ref_Country__c && supplier.Ref_Country__c != null) {
	           	if (refCountryNameSet.contains(supplier.Ref_Country__c.toUpperCase())) {
               		// Do nothings
	           	} else if(refCountryCodeMap.containsKey(supplier.Ref_Country__c.toUpperCase())) {
	               	supplier.Ref_Country__c = refCountryCodeMap.get(supplier.Ref_Country__c.toUpperCase());
	           	} else {
               		supplier.Ref_Country__c.addError('Ref Country not exist.');
           		}
        	}
    	}
    
    	
    }
    
    /*
	 * When supplier status end date__c is greater than the current date, and status is close, then status = active.
     * @param List<Sup_Supplier__c> nSuppliers
     * On Before Insert Or Update.
     **/
    private static void setStatusToClose(List<Sup_Supplier__c> nSuppliers, Map<Id, Sup_Supplier__c> oSupplierMap) {
    	// When supplier status end date__c is greater than the current date, and status is close, then status = active.
    	for (Sup_Supplier__c supplier : nSuppliers) {
    		if (supplier.Id == Null || (supplier.Id != Null && supplier.Status_EDate__c != oSupplierMap.get(supplier.Id).Status_EDate__c)) {
	            if (supplier.Status_EDate__c > system.today() && supplier.Status__c == 'Close') {
	            	supplier.Status__c = 'Active';
	            }
	        }
    	}
    }
}