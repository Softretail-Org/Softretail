public with sharing class StaffManagementController extends NegoptimBaseController {
    
    /* Global Variables */
    // List of users used for sorting .
    public List<User> sUsers {get; set;}
    // To display records per page.
    public Integer record {get; set;}
    // Total number of records.
    public Integer total {get; set;}
    // Count of users records.
    private Integer totalRecords = 0;
    // Used for pagination.
   	public Integer counter;
   	// Used for pagination.
   	private Integer LimitSize = 5;
   	// Used for sorting to determine the arrow direction.
   	public Boolean isASC1 {get; set;}
   	public Boolean isASC2 {get; set;}
   	public Boolean isASC3 {get; set;}
   	public Boolean isASC4 {get; set;}
   	// Used for sorting to determine which field is sorted: users name, roles, profiles or last connection.
   	public String sortField {get; set;}
   	// If isINIT is true, then the initial list of users is taken into consideration, else, sUsers list is taken into consideration.
   	public Boolean isINIT {get; set;}   	
   	// SOQL contatenation.
   	private String soql;
   	// Variable used to get user name from the visualforce page for searching.
   	public String searchParam {get;set;}
   	// Value of the user name input, used for search procedure.
   	public String fullNameValue {get; set;}
   	// Current year used in SOQLs.
   	public Integer currentYear;
   	// Used to display the popup.
  	public boolean displayPopup {get; set;}
  	// Each popup contains one Role Details: Role Id, Role Name and information about the corresponding users.
  	public RoleDetailsWrapper wRoleDetails {get; set;}
  	// Embedded class in RoleDetailsWrapper. 
    public UserDetailsWrapper wUserDetail {get; set;}
    // Used to get user role Id from the visual force page.
    public Id roleId {get; set;}
    public Set<Id> NSIdSet {get; set;} //<< It should be a local variable.
    // Used for unit test.
    public List<Id> NSIds {get; set;} //<< It should be a local variable.
    // Lookup input field: change owner.
    public Sup_sup_NegoScope__c NegoS {get; set;} 
  	// Roles details.
  	public List<RoleWrapper> wRoles {get; set;}
  	// Used to know if a role has contracts details: popup.
  	public Boolean hasContractDetails {get; set;}
    // Lookup owner Id.
  	public Id newOwnerId {get; set;} //<< It should be a local variable.
  	
  	public List<RoleHierarchyWrapper> summary {get; set;}
  	
  	// Constructor.
    public StaffManagementController() {
    	counter = 0;
    	currentYear = System.Today().year();
    	total = totalRecords = [SELECT count()
    							FROM User
    							WHERE IsActive = True];
    	record = LimitSize;
    	isASC1 = true;
    	isASC2 = true;
    	isASC3 = true;
    	isASC4 = true;
    	sortField = 'Name';
    	isINIT = true;
    	getRoles();
    }
    
    // Get users - User Structure block.
    public List<User> getUsers() {
		List<User> users = new List<User>();
		if (sortField == 'Name') {
  			if (isASC1 == True) {
    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							WHERE IsActive = True
							ORDER BY Name ASC LIMIT :limitsize OFFSET:counter];
	    	} else {
	    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							ORDER BY Name DESC LIMIT :limitsize OFFSET:counter];
	    	}
  		}
  		if (sortField == 'UserRoleId') {
  			if (isASC2 == True) {
    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							WHERE IsActive = True
							ORDER BY UserRole.Name ASC LIMIT :limitsize OFFSET:counter];
	    	} else {
	    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							WHERE IsActive = True
							ORDER BY UserRole.Name DESC LIMIT :limitsize OFFSET:counter];
	    	}
  		}
  		if (sortField == 'ProfileId') {
  			if (isASC3 == True) {
	    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							WHERE IsActive = True
							ORDER BY Profile.Name ASC LIMIT :limitsize OFFSET:counter];
	    	} else {
	    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							WHERE IsActive = True
							ORDER BY Profile.Name DESC LIMIT :limitsize OFFSET:counter];
	    	}
  		}
  		if (sortField == 'LastLoginDate') {
  			if (isASC4 == True) {
	    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							WHERE IsActive = True
							ORDER BY LastLoginDate ASC LIMIT :limitsize OFFSET:counter];
	    	} else {
	    		users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
							FROM User
							WHERE IsActive = True
							ORDER BY LastLoginDate DESC LIMIT :limitsize OFFSET:counter];
	    	}
  		}
        return users;
    }
    // User records limitation.
   	public void displayRecordsPerPage() {
   		isINIT = True;
   		List<User> users = new List<User>();
   		users.clear();
      	limitsize = record;
       	users = [SELECT Id, Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate, UserName, IsActive
	   				FROM User
	       			WHERE IsActive = True LIMIT :record OFFSET :counter];
    }
    // Called when the user hit on "First Page" button.
 	public PageReference firstBtn() {
 		isINIT = true;
 		counter = 0;
        return null;
    }
    // Called when the user hit on "Previous" button.
  	public PageReference prvBtn() {
  		isINIT = true;
  		counter = counter - limitsize;
		return null;
    }
    // Called when the user hit on "Next" button.
 	public PageReference NxtBtn() {
 		if (fullNameValue == Null || fullNameValue == '') {
 			isINIT = true;
 		} else {
 			isINIT = False;
 		}
 		counter = counter + limitsize;
 		if (counter == totalRecords) {
        	counter = counter - LimitSize;
        }
        return null;
    }
    // Called when the user hit on "Last Page" button.
 	public PageReference lstBtn() {
 		isINIT = true;
 		counter = totalRecords - math.mod(totalRecords, LimitSize);
        if (counter == totalRecords) {
        	counter = counter - LimitSize;
        }
        return null;
    }
    // Turn the page to the next.
    public Boolean getNxt() {
    	if((counter + LimitSize) >= totalRecords) return true;
    	else return false;
    }
    // Turn the page to the previous.
    public Boolean getPrv() {
  		if(counter == 0) return true;
      	else return false;
  	}
  	// Called when the user hit on ▲ or ▼ in each column for sorting asc or desc.
  	public void sorting() {
  		soql = 'SELECT Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate FROM User ';
  		soql += 'WHERE IsActive = True ' ;
  		isINIT = False;
  		if (sortField == 'Name') {
  			if (isASC1 == True) {
	  			isASC1 = False;
	  			soql += 'ORDER BY ' + sortField + ' DESC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		} else {
	  			isASC1 = True;
	  			soql += 'ORDER BY ' + sortField + ' ASC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		}
  		}
  		if (sortField == 'UserRoleId') {
  			if (isASC2 == True) {
	  			isASC2 = False;
	  			soql += 'ORDER BY UserRole.Name DESC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		} else {
	  			isASC2 = True;
	  			soql += 'ORDER BY UserRole.Name ASC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		}
  		}
  		if (sortField == 'ProfileId') {
  			if (isASC3 == True) {
	  			isASC3 = False;
	  			soql += 'ORDER BY Profile.Name DESC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		} else {
	  			isASC3 = True;
	  			soql += 'ORDER BY Profile.Name ASC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		}
  		}
  		if (sortField == 'LastLoginDate') {
  			if (isASC4 == True) {
	  			isASC4 = False;
	  			soql += 'ORDER BY ' + sortField + ' DESC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		} else {
	  			isASC4 = True;
	  			soql += 'ORDER BY ' + sortField + ' ASC ';
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  		}
  		}
  	}
  	// Called when the user hit on "Search" button.
  	public void searchUser() {
  		isINIT = True;
  		soql = 'SELECT Name, UserRoleId, UserRole.Name, ProfileId, Profile.Name, LastLoginDate FROM User ';
  		soql += 'WHERE IsActive = True ' ;
  		if (fullNameValue == Null || fullNameValue == '') {
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Put your text please!'));
  		} else {
  			if (searchParam == 'Name') {
	  			isINIT = False;
	  			soql += 'AND Name LIKE \'' + String.escapeSingleQuotes(fullNameValue) + '%\' ';
	  			if (sortField != Null) {
	  				soql += 'ORDER BY ' + sortField + ' ASC ';
	  			}
	  			soql += 'LIMIT ' + limitsize + ' OFFSET ' + counter + ' ';
	  			sUsers = Database.query(soql);
	  			total = sUsers.size();
	  		}
  		}
  	}
  	// Fetch roles which have users, with their details.
  	public List<RoleWrapper> getRoles() {
  		/* Local Variables */
  		// Creation of a list of role wapper.
  		wRoles = new List<RoleWrapper>();
  		RoleWrapper wrapper;
  		//Set<roleId>.
  		////Set<Id> rolesSet = new Set<Id>();
  		// Map<user, roleId>.
  		Map<User, Id> roleIdMap = new Map<User, Id>();
  		// Get Roles: Map<roleId, parentRole>.
  		////Map<Id, UserRole> roleMap = new Map<Id, UserRole>();
  		// To map User Id and the count of the NS related to it: Map<user Id, NS count>.
  		Map<Id, Integer> countNSMap = new Map<Id, Integer>();
  		// To map User Id and the count of the contracts related to it: Map<user Id, contract count>.
  		Map<Id, Integer> countContractMap = new Map<Id, Integer>();
  		// Mapping between User Id and the total TO for each contract related to it: Map<user Id, total TO>.
  		Map<Id, Decimal> baseTOMap = new Map<Id, Decimal>();
  		/****for (UserRole role : [SELECT Id, Name, ParentRoleId FROM UserRole]) {
  			roleMap.put(role.Id, role);
  		}****/
        Map<Id, RoleWrapper> wRoleMap = new Map<Id, RoleWrapper>();
        for (User user : [SELECT Id, Name, UserRoleId, UserRole.Name, UserRole.ParentRoleId
                          FROM User
                          WHERE IsActive = True
                          ORDER BY Name ASC
                          LIMIT 2]) {
                              ////rolesSet.add(user.UserRoleId);
                              roleIdMap.put(user, user.UserRoleId);
                              UserWrapper wUser = new UserWrapper(user);
                              // Fill wrapper
                              if(!wRoleMap.containsKey(user.UserRoleId)) {
                                  wrapper = new RoleWrapper(user.UserRoleId, user.UserRole.Name);
                                  wrapper.wUsers.add(wUser);
                                  wRoleMap.put(user.UserRoleId, wrapper);
                              }
                              else {
                                  wRoleMap.get(user.UserRoleId).wUsers.add(wUser);
                              }
                          }
        wRoles = wRoleMap.values();
  		// Fill role wrapper: userRoleId, roleName.
  		/****for (Id rId : roleMap.keySet()) {
  			for (Id userRoleId : rolesSet) {
  				if (rId == userRoleId) {
  					wrapper = new RoleWrapper();
  					wrapper.userRoleId = rId;
  					wrapper.roleName = roleMap.get(rId).Name;
  					wRoles.add(wrapper);
  				} else {
  					// TODO: wUser without role.
  				}
  			}
  		}
  		// Fill wapper: wUsers.
  		for (RoleWrapper w : wRoles) {
  			for (User user : roleIdMap.keySet()) {
  				if (w.userRoleId == roleIdMap.get(user)) {
  					UserWrapper wUser = new UserWrapper();
  					wUser.user = user;
  					w.wUsers.add(wUser);
  				} else { 
  					
  				}
  			}
  		}****/
  		// Get the count of NS based on owners.
  		for (AggregateResult agg : [SELECT count(Id) c, OwnerId u
  									FROM Sup_sup_NegoScope__c 
  									WHERE OwnerId IN :roleIdMap.keySet()
  									AND Status__c = 'Active'
  									GROUP BY OwnerId]) {
  			// Mapping between User Id and the count of the NS related to it: Map<user Id, NS count>.
  			countNSMap.put((Id)agg.get('u'), (Integer)agg.get('c'));
  		}
  		// Fill wrapper: count of NS for each user.  		
  		for (RoleWrapper wR : wRoles) {
  			for (UserWrapper wU : wR.wUsers) {
  				for (Id uId : countNSMap.keySet()) {
		  			if (wU.user.Id == uId) {
		  				wU.NSCount = countNSMap.get(uId);
		  				wU.NSCountSim = countNSMap.get(uId);
		  				break;
		  			}
	  			}
  			}
  		}
  		// Get the count of Contracts based on owners.
  		for (AggregateResult agg : [SELECT count(Id) c, Supplier_Nego_Scope__r.ownerId u, sum(Total_TO_Fact__c) t
		  							FROM Contract__c 
		  							WHERE Supplier_Nego_Scope__r.ownerId IN : roleIdMap.keySet()
	  								AND Contract_Type__c = 'Contract'
	  								AND CALENDAR_YEAR(Contract_BDate__c) = :currentYear
    								AND CALENDAR_YEAR(Contract_EDate__c) = :currentYear
                                    AND Supplier_Nego_Scope__r.Status__c = 'Active'
		  							GROUP BY Supplier_Nego_Scope__r.ownerId]) {
  			// Mapping between User Id and the count of the contracts related to it: Map<user Id, contract count>.
  			// Mapping between User Id and the total TO for each contract related to it: Map<user Id, total TO>.
  			countContractMap.put((Id)agg.get('u'), (Integer)agg.get('c'));
  			baseTOMap.put((Id)agg.get('u'), (Decimal)agg.get('t'));
  		}
  		// Fill wrapper: count of contract for each user.
  		for (RoleWrapper wR : wRoles) {
  			for (UserWrapper wU : wR.wUsers) {
  				for (Id uId : countContractMap.keySet()) {
		  			if (wU.user.Id == uId) {
		  				wU.contractCount = countContractMap.get(uId);
		  				wU.totalTO = baseTOMap.get(uId);
		  				wU.contractCountSim = countContractMap.get(uId);
		  				wU.totalTOSim = baseTOMap.get(uId);
		  				break;
		  			}
	  			}
  			}
  		}
  		return wRoles;
  	}
  	// Fetch role hierarchy (or summary) + Sorting + Calculation.
  	public List<RoleHierarchyWrapper> getHierarchy() {
  		//List<RoleWrapper>
  		RoleHierarchyWrapper wrapper = new RoleHierarchyWrapper();
    	return wrapper.hierarchyCalculation(wRoles, wrapper.sortHierarchy(wrapper.fillRoleHierarchy(wRoles)));
  	}
  	// 
  	public void submit() {
  		//
  	}
    // Close popup.
  	public void closePopup() {
        displayPopup = false;
        wRoleDetails = new RoleDetailsWrapper();
    }
    // Show popup.
    public void showPopup() {
    	hasContractDetails = False;
    	NegoS = new Sup_sup_NegoScope__c();
        displayPopup = true;
        loadPopup();
    }
    // Load popup
    private void loadPopup() {
        Set<Id> roleIdSet = new Set<Id>();
        NSIdSet = new Set<Id>();
        // Fill RoleDetailsWrapper.
        for (RoleWrapper wS : wRoles) {
        	if (roleId == wS.userRoleId) {
    			for (UserWrapper wU : wS.wUsers) {
    				if (!roleIdSet.contains(roleId)) {
        				roleIdSet.add(roleId);
	        			wRoleDetails = new RoleDetailsWrapper();
	        			wRoleDetails.roleId = roleId;
	        			wRoleDetails.roleName = wS.roleName;
	        		}
        		}
        	}
        }
        List<Id> userIds = new List<Id>();
        String strQry = 'SELECT Id, Name, UserRoleId FROM User WHERE IsActive = True';
        if (wRoleDetails != Null && wRoleDetails.roleId != Null) {
        	strQry += ' AND UserRoleId = \'' + wRoleDetails.roleId + '\'';
        } else {
        	wRoleDetails = new RoleDetailsWrapper();
        	strQry += ' AND UserRoleId = NULL';
        }
        strQry += ' LIMIT 2';
        List<User> users = Database.query(strQry);
        for (User user : users) {
        		//if (wRoleDetails.roleId == user.UserRoleId) {
			wUserDetail = new UserDetailsWrapper();
			wUserDetail.userId = user.Id;
			wUserDetail.userName = user.Name;
			wRoleDetails.wUserDetails.add(wUserDetail);
        		//}
    		userIds.add(user.Id);
        }
        for (Sup_sup_NegoScope__c NS : [SELECT Id, Name, OwnerId, Owner.Name,
        									(SELECT Id, Name, Total_TO_Fact__c, Supplier_Nego_Scope__r.ownerId
    										FROM Contracts1__r
	        								WHERE Contract_Type__c = 'Contract'
	        								AND CALENDAR_YEAR(Contract_BDate__c) = :currentYear
	        								AND CALENDAR_YEAR(Contract_EDate__c) = :currentYear
	        								AND Supplier_Nego_Scope__r.ownerId IN :userIds
	        								LIMIT 10)
        								FROM Sup_sup_NegoScope__c
        								WHERE Status__c = 'Active'
        								AND ownerId IN :userIds
        								LIMIT 2]) {
        	for (UserDetailsWrapper wUserDetail : wRoleDetails.wUserDetails) {
    			for (Contract__c c : NS.Contracts1__r) {
    				if (wUserDetail.userId == c.Supplier_Nego_Scope__r.ownerId) { // No benefit
    					hasContractDetails = true;
    					OwnerDetailsWrapper wOwnerDetail = new OwnerDetailsWrapper();
    					wOwnerDetail.cId = c.Id;
    					wOwnerDetail.cName = c.Name;
    					wOwnerDetail.cTO = c.Total_TO_Fact__c;
    					wOwnerDetail.NSName = NS.Name;
    					wOwnerDetail.NSOwner = NS.Owner.Name;
    					wOwnerDetail.NSId = NS.Id;
    					wOwnerDetail.NSOwnerId = NS.OwnerId;
    					wUserDetail.wOwnerDetails.add(wOwnerDetail);
    					if (!NSIdSet.contains(NS.Id)) {
    						NSIdSet.add(NS.Id);
    					}
    				}
    			}
        	}
        }
        NSIds = new List<Id>(NSIdSet);
    }
    // Change owner.
  	public PageReference changeOwner() {
        // check security on updateNS fields
        String[] NSFields = new String[] { 'OwnerId'};
            if(!checkUpdatibility(Sup_sup_NegoScope__c.SObjectType, NSFields)){
                return null;
            }
        
  		newOwnerId = NegoS.OwnerId;
  		List<OwnerDetailsWrapper> wSelectedOwnerDetails = new List<OwnerDetailsWrapper>();
  		// Map<NS Id, NS Owner Id>
	    Map<Id, Id> idsMap = new Map<Id, Id>();
  		// NS list for update.
  		List<Sup_sup_NegoScope__c> NSs = new List<Sup_sup_NegoScope__c>();
  		if (newOwnerId == Null) {
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Select_an_owner));
  			return Null;
  		}
	    for (UserDetailsWrapper wUserDetail : wRoleDetails.wUserDetails) {
	    	for (OwnerDetailsWrapper wOwnerDetail : wUserDetail.wOwnerDetails) {
	    		if (wOwnerDetail.isSelected == true) {
		            wSelectedOwnerDetails.add(wOwnerDetail);
		        }
	    	}
	    }
	    if (wSelectedOwnerDetails.size() != 0) {
	    	for (OwnerDetailsWrapper item : wSelectedOwnerDetails) {
		    	if (item.NSOwnerId == newOwnerId) {
		    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Select_new_owner));
	  				return Null;
		    	}
		    }
	    } else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MSG_Select_Contract_Details));
			return Null;
		}
  		for (OwnerDetailsWrapper wSelectedOwnerDetail : wSelectedOwnerDetails) {
  			wSelectedOwnerDetail.NSOwnerId = newOwnerId;
  			idsMap.put(wSelectedOwnerDetail.NSId, wSelectedOwnerDetail.NSOwnerId);
  		}
  		for (Sup_sup_NegoScope__c negoScope : [SELECT Id, OwnerId
  												FROM Sup_sup_NegoScope__c
  												WHERE Id IN : idsMap.keySet()
  												AND Status__c = 'Active'
  												LIMIT 10]) {
  			negoScope.OwnerId = idsMap.get(negoScope.Id);
	  		NSs.add(negoScope);
  		}
  		try {
  			update NSs;
  		} catch (DMLException e) {
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.MSG_Read_permission_exception));
  			return Null;
  		}
  		displayPopup = false;
  		PageReference retURL = new PageReference('/apex/StaffManagement');
      	retURL.setRedirect(true);
      	return retURL;
  	}
  	
  	/* Wrapper classes. */
  	// Role having users.
  	public class RoleWrapper {
  		
  		public Id userRoleId {get; set;}
  		public String roleName {get; set;}
  		public List<UserWrapper> wUsers {get; set;}
  		
  		public RoleWrapper(Id roleId, String name) {
            userRoleId = roleId;
            roleName = name;
  			wUsers = new List<UserWrapper>();
  		}
  		
        public Id getParentRoleId(Id userRoleId, List<UserRole> urs) {
            for(UserRole ur : urs) {
                if(ur.Id == userRoleId) {
                    return ur.ParentRoleId;
                }
            }
            return null;
        }
  	}
  	// Users details.
  	public class UserWrapper {
  		
  		public User user {get; set;}
  		// Fact part.
  		public Integer contractCount {get; set;}
  		public Integer NSCount {get; set;}
  		public Decimal totalTO {get; set;}
  		public String sTotalTO {
            get {
                return this.totalTO != null ? this.totalTO.format() : '';
            }
            set {
                if (this.totalTO.format() != value) {
                    this.totalTO = NegoptimHelper.getDecimalValue(value);
                }
            }
        }
  		public Decimal contractPercentage {get; set;}
  		public String sContractPercentage {
            get {
                return NegoptimHelper.formatPercentageValue(this.contractPercentage, False);
            }
            set;
        }
  		public Decimal NSPercentage {get; set;}
  		public String sNSPercentage {
            get {
                return NegoptimHelper.formatPercentageValue(this.NSPercentage, False);
            }
            set;
        }
  		public Decimal TOPercentage {get; set;}
  		public String sTOPercentage {
            get {
                return NegoptimHelper.formatPercentageValue(this.TOPercentage, False);
            }
            set;
        }
  		// Simulation part.
  		public Integer contractCountSim {get; set;}
  		public Integer NSCountSim {get; set;}
  		public Decimal totalTOSim {get; set;}
        public String sTotalTOSim {
            get {
                return this.totalTOSim != null ? this.totalTOSim.format() : '';
            }
            set {
                if (this.totalTOSim.format() != value) {
                    this.totalTOSim = NegoptimHelper.getDecimalValue(value);
                }
            }
        }
  		public Decimal contractPercentageSim {get; set;}
  		public String sContractPercentageSim {
            get {
                return NegoptimHelper.formatPercentageValue(this.contractPercentageSim, False);
            }
            set;
        }
  		public Decimal NSPercentageSim {get; set;}
  		public String sNSPercentageSim {
            get {
                return NegoptimHelper.formatPercentageValue(this.NSPercentageSim, False);
            }
            set;
        }
  		public Decimal TOPercentageSim {get; set;}
  		public String sTOPercentageSim {
            get {
                return NegoptimHelper.formatPercentageValue(this.TOPercentageSim, False);
            }
            set;
        }
  		
        public UserWrapper(User u) {
            user = u;
            contractCountSim = 0;
            NSCountSim = 0;
            totalTOSim = 0;
            sTotalTOSim = String.valueOf(0);
            contractPercentageSim = 0;
            NSPercentageSim = 0;
            TOPercentageSim = 0;
        }
    }
  	// Summary.
  	public class RoleHierarchyWrapper {
  		
  		public UserRole userRole {get; set;}
  		public Integer level {get; set;}
  		public Id userRoleId {get; set;}
  		public Id parentId {get; set;}
  		public Set<Id> parentIds {get; set;}
  		public Set<Id> childrenIds {get; set;}
  		// SUM of SUM in the head part without ROOT.
  		public Integer contractCountH {get; set;}
  		public Integer NSCountH {get; set;}
  		public Decimal totalTOH {get; set;}
        public String sTotalTOH {
            get {
                return this.totalTOH != null ? this.totalTOH.format() : '';
            }
            set;
        }
  		public Decimal contractPercentageH {get; set;}
  		public String sContractPercentageH {
            get {
                return NegoptimHelper.formatPercentageValue(this.contractPercentageH, False);
            }
            set;
        }
  		public Decimal NSPercentageH {get; set;}
  		public String sNSPercentageH {
            get {
                return NegoptimHelper.formatPercentageValue(this.NSPercentageH, False);
            }
            set;
        }
  		public Decimal TOPercentageH {get; set;}
  		public String sTOPercentageH {
            get {
                return NegoptimHelper.formatPercentageValue(this.TOPercentageH, False);
            }
            set;
        }
  		public Integer contractCountSimH {get; set;}
  		public Integer NSCountSimH {get; set;}
  		public Decimal totalTOSimH {get; set;}
  		public String sTotalTOSimH {
           	get {
                return this.totalTOSimH != null ? this.totalTOSimH.format() : '';
            }
            set;
        }
  		public Decimal contractPercentageSimH {get; set;}
  		public String sContractPercentageSimH {
            get {
                return NegoptimHelper.formatPercentageValue(this.contractPercentageSimH, False);
            }
            set;
        }
  		public Decimal NSPercentageSimH {get; set;}
  		public String sNSPercentageSimH {
            get {
                return NegoptimHelper.formatPercentageValue(this.NSPercentageSimH, False);
            }
            set;
        }
  		public Decimal TOPercentageSimH {get; set;}
  		public String sTOPercentageSimH {
            get {
                return NegoptimHelper.formatPercentageValue(this.TOPercentageSimH, False);
            }
            set;
        }
  		// ROOT SUMs.
  		private Integer rootContractCountH = 0;
  		private Integer rootNSCountH = 0;
  		private Decimal rootTotalTOH = 0;
  		private Decimal rootContractPercentageH = 100.00;
  		private Decimal rootNSPercentageH = 100.00;
  		private Decimal rootTOPercentageH = 100.000;
  		private Integer rootContractCountSimH = 0;
  		private Integer rootNSCountSimH = 0;
  		private Decimal rootTotalTOSimH = 0;
  		private Decimal rootContractPercentageSimH = 100.00;
  		private Decimal rootNSPercentageSimH = 100.00;
  		private Decimal rootTOPercentageSimH = 100.000;
  		
  		public RoleHierarchyWrapper () {
  			parentIds = new Set<Id>();
  			childrenIds = new Set<Id>();
  		}
  		
  		private Map<Id, List<UserRole>> hierarchy {
			get {
				if (hierarchy == null) {
					hierarchy = new Map<Id, List<UserRole>>();
		            for (UserRole role : [SELECT ParentRoleId, Name FROM UserRole LIMIT 2]) {
		                if (!hierarchy.containsKey(role.ParentRoleId))
		                    hierarchy.put(role.ParentRoleId, new List<UserRole>());
		                hierarchy.get(role.ParentRoleId).add(role);
		            }
		        }
		        return hierarchy;
		    }
		    private set;
		}
		//
  		private Set<Id> getSubHierarchyExclusive(Id userRoleId) {
	    	Set<Id> roleIds = new Set<Id>();
	    	for (UserRole childRole : getChildren(userRoleId)) {
	        	roleIds.add(childRole.Id);
	        	roleIds.addAll(getSubHierarchyExclusive(childRole.Id));
	    	}
	    	return roleIds;
		}
		//
		private List<UserRole> getChildren(Id userRoleId) {
	   		return hierarchy.containsKey(userRoleId) ? hierarchy.get(userRoleId) : new List<UserRole>();
		}
		// Fill Role Hierarchy
  		public List<RoleHierarchyWrapper> fillRoleHierarchy(List<RoleWrapper> wRoles) {
	  		/* Local Variables */
	  		List<UserRole> urs = [SELECT Id, ParentRoleId, Name FROM UserRole LIMIT 2];
	  		// <role Id, set of parent role Ids>
	  		Map<Id, Set<Id>> roleWithParentsMap = new Map<Id, Set<Id>>();
	  		// Create set of all parents roles.
	  		Set<Id> allRoleParents = new Set<Id>();
	  		// Creation of Role hierarchy wrapper.
	  		List<RoleHierarchyWrapper> wHList = new List<RoleHierarchyWrapper>();
	  		// Map role Id and exsting roles. <role id, role hierarchy wrapper>
	  		Map<Id, RoleHierarchyWrapper> existingRolesMap = new Map<Id, RoleHierarchyWrapper>();
	  		for (RoleWrapper w : wRoles) {
	            Set<Id> parentRoleIds = new Set<ID>();
	            Id parentId = w.getParentRoleId(w.userRoleId, urs);
	        	while(parentId != null) {
	    			parentRoleIds.add(parentId);
	            	parentId = w.getParentRoleId(parentId, urs);
	            }
	            parentRoleIds.add(Null);
	            if (parentRoleIds != null) {
	            	parentRoleIds.add(w.userRoleId);
	            }
	            roleWithParentsMap.put(w.userRoleId, parentRoleIds);
	  		}
	  		// Fill all parents roles in a set.
	  		for (Set<Id> item : roleWithParentsMap.values()) {
	  			for (Id i : item) {
	  				if (i != Null) {
	  					allRoleParents.add(i);
	  				}
	  			}
	  		}
	  		// Fill wrapper.	
	  		for (UserRole uRole : [SELECT Id, Name, ParentRoleId FROM UserRole WHERE Id IN : allRoleParents LIMIT 2]) {
	  			RoleHierarchyWrapper wH = new RoleHierarchyWrapper();
	  			wH.userRole = uRole;
	  			wH.userRoleId = uRole.Id;
	  			wH.parentId = uRole.ParentRoleId;
	  			wH.parentIds = roleWithParentsMap.get(uRole.Id);
	  			wHList.add(wH);
	  		}
	  		// Get and fill levels. // First step.
	  		for (RoleHierarchyWrapper wH : wHList) {
	  			if (wH.parentId == NULL && wH.parentIds == Null) { //ROOT
	  				wH.level = 1;
	  			}
	  			if (wH.parentId != NULL && wH.parentIds != Null) {
	  				// Get size of the list of parent Ids.
	  				Integer level = wH.parentIds.size() - 1;
	  				wH.level = level;
	  				existingRolesMap.put(wH.userRoleId, wH);
	  			}
  			}
  			// Fill levels of the n on existing roles. // First step. I cannot iterate the loop in the same time.
	  		for (RoleHierarchyWrapper w : wHList) {
	  			if (!(w.parentId != NULL && w.parentIds != Null)) {
		  			if (w.level != 1) {
		  				for (Id existingRoleId : existingRolesMap.keySet()) {
		  					if (w.userRole.Id == existingRolesMap.get(existingRoleId).parentId) {
		  						w.level = existingRolesMap.get(existingRoleId).level - 1;
		  					}
		  				}
		  			}
	  			}
	  		}
  			return wHList;
  		}
  		// Sorting Role Hierarchy Wrapper.
  		public Set<RoleHierarchyWrapper> sortHierarchy(List<RoleHierarchyWrapper> wHList) {
  			// Used for sorting. map<RoleHierarchyWrapper, level>
  			Map<RoleHierarchyWrapper, Integer> sortedMap = new Map<RoleHierarchyWrapper, Integer>();
  			// Sorting summary wrapper order by level: ASC.
  			for (Integer i = 0 ; i < wHList.size() ; i++) {
				for (Integer j = i+1 ; j <= wHList.size()-1 ; j++) {
	  				Integer x = 0 ;
	  				UserRole u = new UserRole();
	  				Id rId;
	  				Id pId;
	  				Set<Id> pIds = new Set<Id>();
	  				if (wHList.get(i).level > wHList.get(j).level) {
					   	// userRole
					   	u = wHList.get(i).userRole;
					   	wHList.get(i).userRole = wHList.get(j).userRole  ;
					   	wHList.get(j).userRole = u;
					   	// Level
	   					x = wHList.get(i).level;
					   	wHList.get(i).level = wHList.get(j).level  ;
					   	wHList.get(j).level = x;
					   	// userRoleId
					   	rId = wHList.get(i).userRoleId;
					   	wHList.get(i).userRoleId = wHList.get(j).userRoleId  ;
					   	wHList.get(j).userRoleId = rId;
					   	// parentId
					   	pId = wHList.get(i).parentId;
					   	wHList.get(i).parentId = wHList.get(j).parentId  ;
					   	wHList.get(j).parentId = pId;
					   	// parentIds
					   	pIds = wHList.get(i).parentIds;
					   	wHList.get(i).parentIds = wHList.get(j).parentIds  ;
					   	wHList.get(j).parentIds = pIds;
					  }
				}
				sortedMap.put(wHList.get(i), wHList.get(i).level);
			}
			return sortedMap.keySet();
  		}
	  	// Summary calculation.
	  	public List<RoleHierarchyWrapper> hierarchyCalculation(List<RoleWrapper> wRoles, Set<RoleHierarchyWrapper> sortedRoleHierarchySet) {
	  		// User for children filtering.
			Set<Id> currentRoleIds = new Set<Id>();
			// <corresponding user role ID, head wrapper>
			Map<Id, RoleHierarchyWrapper> currentRoleIdsMap = new Map<Id, RoleHierarchyWrapper>();
			// Set of children Ids.
			Set<Id> childrenIds = new Set<Id>();
  			// Fill the summary part. Calculate the sums.
	  		for (RoleHierarchyWrapper wH : sortedRoleHierarchySet) {
	  			for (RoleWrapper wN : wRoles) {
	  				if (wH.userRole.Id == wN.userRoleId) {
	  					Integer sumContractCount = 0;
			  			Integer sumNSCount = 0;
			  			Decimal sumTotalTOH = 0;
			  			Integer sumContractCountSim = 0;
			  			Integer sumNSCountSim = 0;
			  			Decimal sumTotalTOSimH = 0;
			  			for (UserWrapper wU : wN.wUsers) {
			  				if (wU.ContractCount != NULL) {
			  					sumContractCount += wU.contractCount;
			  				}
			  				if (wU.NSCount != NULL) {
			  					sumNSCount += wU.NSCount;
			  				}
			  				if (wU.totalTO != NULL) {
			  					sumTotalTOH += wU.totalTO;
			  				}
			  				if (wU.contractCountSim != NULL) {
			  					sumContractCountSim += wU.contractCountSim;
			  				}
			  				if (wU.NSCountSim != NULL) {
			  					sumNSCountSim += wU.NSCountSim;
			  				}
			  				if (wU.totalTOSim != NULL) {
			  					sumTotalTOSimH += wU.totalTOSim;
			  				}
			  			}
			  			// Allocate the sums to the Staff Wrapper.
			  			wH.contractCountH = sumContractCount;
			  			wH.NSCountH = sumNSCount;
			  			wH.totalTOH = sumTotalTOH;
			  			wH.contractCountSimH = sumContractCountSim;
			  			wH.NSCountSimH = sumNSCountSim;
			  			wH.totalTOSimH = sumTotalTOSimH;
	  				}
		  		}
	  		}
			// Children filtering.
			for (RoleHierarchyWrapper wH : sortedRoleHierarchySet) {
				currentRoleIds.add(wH.userRoleId);
				currentRoleIdsMap.put(wH.userRoleId, wH);
			}
			// Fill children Ids in the Wrapper. <set of children Ids, head wrapper>
			for (RoleHierarchyWrapper wH : sortedRoleHierarchySet) {
				childrenIds = wH.getSubHierarchyExclusive(wH.userRoleId);
				for (Id childId : childrenIds) {
					if (currentRoleIds.contains(childId)) {
						wH.childrenIds.add(childId);
					}
				}
			}
			// Calculation (without percentage),
			for (RoleHierarchyWrapper wH : sortedRoleHierarchySet) {
				Integer sumContractCount = 0;
				Integer sumNSCountH = 0;
				Decimal sumtotalTOH = 0;
				Integer sumContractCountSimH = 0;
				Integer sumNSCountSimH = 0;
				Decimal sumtotalTOSimH = 0;
				if (wH.childrenIds.size() == 0) {
					wH.contractCountH += 0;
				} else {
					RoleHierarchyWrapper childWrapper;
					for (Id childId : wH.childrenIds) {
						new RoleHierarchyWrapper();
						if (currentRoleIds.contains(childId)) { // It must be mandatory contained!
							childWrapper = currentRoleIdsMap.get(childId);
							if (childWrapper.contractCountH == Null) {
								childWrapper.contractCountH = 0;
							} else {
								sumContractCount += childWrapper.contractCountH;
							}
							if (childWrapper.NSCountH == Null) {
								childWrapper.NSCountH = 0;
							} else {
								sumNSCountH += childWrapper.NSCountH;
							}
							if (childWrapper.totalTOH == Null) {
								childWrapper.totalTOH = 0;
							} else {
								sumtotalTOH += childWrapper.totalTOH;
							}
							if (childWrapper.contractCountSimH == Null) {
								childWrapper.contractCountSimH = 0;
							} else {
								sumContractCountSimH += childWrapper.contractCountSimH;
							}
							if (childWrapper.NSCountSimH == Null) {
								childWrapper.NSCountSimH = 0;
							} else {
								sumNSCountSimH += childWrapper.NSCountSimH;
							}
							if (childWrapper.totalTOSimH == Null) {
								childWrapper.totalTOSimH = 0;
							} else {
								sumtotalTOSimH += childWrapper.totalTOSimH;
							}
						}
					}
				}
				if (wH.contractCountH != Null) {
					wH.contractCountH += sumContractCount;
					wH.rootContractCountH = wH.contractCountH;
				}
				if (wH.NSCountH != Null) {
					wH.NSCountH += sumNSCountH;
					wH.rootNSCountH = wH.NSCountH;
				}
				if (wH.totalTOH != Null) {
					wH.totalTOH += sumtotalTOH;
					wH.rootTotalTOH = wH.totalTOH;
				}
				if (wH.contractCountSimH != Null) {
					wH.contractCountSimH += sumContractCountSimH;
					wH.rootContractCountSimH = wH.contractCountSimH;
				}
				if (wH.NSCountSimH != Null) {
					wH.NSCountSimH += sumNSCountSimH;
					wH.rootNSCountSimH = wH.NSCountSimH;
				}
				if (wH.totalTOSimH != Null) {
					wH.totalTOSimH += sumtotalTOSimH;
					wH.rootTotalTOSimH = wH.totalTOSimH;
				}
			}
			// Root
			for (RoleHierarchyWrapper wH : sortedRoleHierarchySet) {
				// Test on the ROOT.
				if (wH.userRole.ParentRoleId == Null) {
					RoleHierarchyWrapper childWrapper;
					Integer rootSumContractCount = 0;
					Integer rootSumNSCountH = 0;
					Decimal rootSumtotalTOH = 0;
					Integer rootSumContractCountSimH = 0;
					Integer rootSumNSCountSimH = 0;
					Decimal rootSumtotalTOSimH = 0;
					for (Id childId : wH.childrenIds) {
						if (currentRoleIds.contains(childId)) {
							if (currentRoleIdsMap.get(childId).level == 2) {
								rootSumContractCount += currentRoleIdsMap.get(childId).rootContractCountH;
								rootSumNSCountH += currentRoleIdsMap.get(childId).rootNSCountH;
								rootSumtotalTOH += currentRoleIdsMap.get(childId).rootTotalTOH;
								rootSumContractCountSimH += currentRoleIdsMap.get(childId).rootContractCountSimH;
								rootSumNSCountSimH += currentRoleIdsMap.get(childId).rootNSCountSimH;
								rootSumtotalTOSimH += currentRoleIdsMap.get(childId).rootTotalTOSimH;
							}
						}
					}
					// Count.
					if (wH.contractCountH == Null) {
						wH.contractCountH = 0;
					}
					if (wH.NSCountH == Null) {
						wH.NSCountH = 0;
					}
					if (wH.totalTOH == Null) {
						wH.totalTOH = 0;
					}
					if (wH.contractCountSimH == Null) {
						wH.contractCountSimH = 0;
					}
					if (wH.NSCountSimH == Null) {
						wH.NSCountSimH = 0;
					}
					if (wH.totalTOSimH == Null) {
						wH.totalTOSimH = 0;
					}
					wH.contractCountH += rootSumContractCount;
					wH.NSCountH += rootSumNSCountH;
					wH.totalTOH += rootSumtotalTOH;
					wH.contractCountSimH += rootSumContractCountSimH;
					wH.NSCountSimH += rootSumNSCountSimH;
					wH.totalTOSimH += rootSumtotalTOSimH;
					// Percentage.
					if (wH.contractPercentageH == Null) {
						wH.contractPercentageH = 0;
					}
					if (wH.NSPercentageH == Null) {
						wH.NSPercentageH = 0;
					}
					if (wH.TOPercentageH == Null) {
						wH.TOPercentageH = 0;
					}
					if (wH.contractPercentageSimH == Null) {
						wH.contractPercentageSimH = 0;
					}
					if (wH.NSPercentageSimH == Null) {
						wH.NSPercentageSimH = 0;
					}
					if (wH.TOPercentageSimH == Null) {
						wH.TOPercentageSimH = 0;
					}
					wH.contractPercentageH += wH.rootContractPercentageH;
					wH.NSPercentageH += wH.rootNSPercentageH;
					wH.TOPercentageH += wH.rootTOPercentageH;
					wH.contractPercentageSimH += wH.rootContractPercentageSimH;
					wH.NSPercentageSimH += wH.rootNSPercentageSimH;
					wH.TOPercentageSimH += wH.rootTOPercentageSimH;
				}
			}
			// Head percentage.
			Decimal countContractsOnRoot;
			Decimal countNSOnRoot;
			Decimal countTOOnRoot;
			Decimal countContractsSimOnRoot;
			Decimal countNSSimOnRoot;
			Decimal countTOSimOnRoot;
			for (RoleHierarchyWrapper wH : sortedRoleHierarchySet) {
				// Get root percentage value.
				if (wH.level == 1) {
					countContractsOnRoot = wH.contractCountH;
					countNSOnRoot = wH.NSCountH;
					countTOOnRoot = wH.totalTOH;
					countContractsSimOnRoot = wH.contractCountSimH;
					countNSSimOnRoot = wH.NSCountSimH;
					countTOSimOnRoot = wH.totalTOSimH;
				}
			}
			// Fill head percentage values.
			for (RoleHierarchyWrapper wH : sortedRoleHierarchySet) {
				// Fill all head wrapper without root.
				if (wH.userRole.ParentRoleId != Null) {
					if (countContractsOnRoot != 0 && countNSOnRoot != 0 && countTOOnRoot != 0) {
						wH.contractPercentageH = (wH.contractCountH * 100 / countContractsOnRoot).setScale(2);
						wH.NSPercentageH = (wH.NSCountH * 100 / countNSOnRoot).setScale(2);
						wH.TOPercentageH = (wH.totalTOH * 100 / countTOOnRoot).setScale(3);
						if (wH.contractPercentageSimH == Null) {
							wH.contractPercentageSimH = 0;
						}
						if (wH.contractCountSimH == Null) {
							wH.contractCountSimH = 0;
						}
						if (wH.NSPercentageSimH == Null) {
							wH.NSPercentageSimH = 0;
						}
						if (wH.NSCountSimH == Null) {
							wH.NSCountSimH = 0;
						}
						if (wH.TOPercentageSimH == Null) {
							wH.TOPercentageSimH = 0;
						}
						if (wH.totalTOSimH == Null) {
							wH.totalTOSimH = 0;
						}
						if (countContractsSimOnRoot != 0) {
							wH.contractPercentageSimH += (wH.contractCountSimH * 100 / countContractsSimOnRoot).setScale(2);
						}
						if (countNSSimOnRoot != 0) {
							wH.NSPercentageSimH += (wH.NSCountSimH * 100 / countNSSimOnRoot).setScale(2);
						}
						if (countTOSimOnRoot != 0) {
							wH.TOPercentageSimH += (wH.totalTOSimH * 100 / countTOSimOnRoot).setScale(3);
						}
						// Fill staff percentage values.
						for (RoleWrapper wS : wRoles) {
							if (wH.userRoleId == wS.userRoleId) {
								for (UserWrapper wU : wS.wUsers) {
									// Contract percentage values.
									if (wU.contractPercentage == Null) {
										wU.contractPercentage = 0;
									}
									if (wU.contractCount == Null) {
										wU.contractCount = 0;
									}
									if (wH.contractPercentageH == Null) {
										wH.contractPercentageH = 0;
									}
									if (wH.contractCountH != Null && wU.contractCountSim != Null) {
										if (wH.contractCountH != 0) {
											wU.contractPercentage = (wU.contractCount * wH.contractPercentageH / wH.contractCountH).setScale(2);
										}
										if (wH.contractCountSimH != 0) {
											wU.contractPercentageSim = (wU.contractCountSim * wH.contractPercentageSimH / wH.contractCountSimH).setScale(2);
										}
									}
									// NS percentage values.
									if (wU.NSPercentage == Null) {
										wU.NSPercentage = 0;
									}
									if (wU.NSCount == Null) {
										wU.NSCount = 0;
									}
									if (wH.NSPercentageH == Null) {
										wH.NSPercentageH = 0;
									}
									if (wH.NSCountH != Null && wU.NSCountSim != Null) {
										if (wH.NSCountH != 0) {
											wU.NSPercentage = (wU.NSCount * wH.NSPercentageH / wH.NSCountH).setScale(2);
										}
										if (wH.NSCountSimH != 0) {
											wU.NSPercentageSim = (wU.NSCountSim * wH.NSPercentageSimH / wH.NSCountSimH).setScale(2);
										}
									}
									// Total TO percentage values.
									if (wU.TOPercentage == Null) {
										wU.TOPercentage = 0;
									}
									if (wU.totalTO == Null) {
										wU.totalTO = 0;
									}
									if (wH.TOPercentageH == Null) {
										wH.TOPercentageH = 0;
									}
									if (wH.totalTOH != Null && wU.totalTOSim != Null) {
										if (wH.totalTOH != 0) {
											wU.TOPercentage = (wU.totalTO * wH.TOPercentageH / wH.totalTOH).setScale(3);
										}
										if (wH.totalTOSimH != 0) {
											wU.TOPercentageSim = (wU.totalTOSim * wH.TOPercentageSimH / wH.totalTOSimH).setScale(3);
										}
									}
								}
							}
						}
					}
				}
			}
  			return new List<RoleHierarchyWrapper>(sortedRoleHierarchySet);
  		}
  	}
  	
  	// Popup: Contract details.
  	public class RoleDetailsWrapper {
  		
  		public Id roleId {get; set;}
  		public String roleName {get; set;}
  		public List<UserDetailsWrapper> wUserDetails {get; set;}
  		
  		public RoleDetailsWrapper () {
  			wUserDetails = new List<UserDetailsWrapper>();
  		}
  	}
  	// Popup: Users details.
  	public class UserDetailsWrapper {
  		
  		public Id userId {get; set;}
  		public String userName {get; set;}
  		public List<OwnerDetailsWrapper> wOwnerDetails {get; set;}
  		
  		public UserDetailsWrapper () {
  			wOwnerDetails = new List<OwnerDetailsWrapper>();
  		}
  	}
  	// Popup: Owner details.
  	public class OwnerDetailsWrapper {
  		
  		public Id cId {get; set;}
  		public String cName {get; set;}
  		public Decimal cTO {get; set;}
  		public String sCTO {
            get {
                return this.cTO != null ? this.cTO.format() : '';
            }
            set;
        }
  		public String NSName {get; set;}
  		public String NSOwner {get; set;}
  		public Id NSId {get; set;}
  		public Boolean isSelected {get; set;}
  		public Id NSOwnerId {get; set;}
  		
  		public OwnerDetailsWrapper () {
  			isSelected = False;
  		}
  	}
}