/**
 * @author ULiT
 * @date 18-04-2019
 * @Description helper class that groups commun methods such as calculation for Assortment KPIs such as DV and DN and fetching assortment bu clustes
*/
public class AssortmentUtility {
    
    /**
     * @param assortmentDetailsList list of Assortment_Detail__c that must have quiered fields Assortment_BU__c, Category__c, Category__r.Path__c, 
     * Assortment_BU__r.Orga_HE__c, Assortment_BU__r.Orga_HE__r.Path__c, Assortment_BU__r.BU_Target__c
     * @return Map<Id, Map<Id, Map<Integer, Orga_BU__c>>>
     * @return NULL in case of SObjectException (fields aren't queried)
     * @description 
     * 1- loops over assortmentDetailsList and collects BU Target Ids in Set assortmentsBUTargetIdSet
     * 2- query assortment clusters under the assortment bu targets using assortmentsBUTargetIdSet, and orders the query by assortement_Strat__c (strat index), 
     *    Category__r.Level__c DESC, and Category__c, this priorities a cluster over another on the same start with a lower category level over a
     *    start with a null category
     * 3- for each detail, for each cluster
     *   > if the cluster category is child of the assortmentDetail.AssortmentBU category, and the detail category is a child of the cluster category then
     * 	    the cluster is assigned to the detail
	*/
    public static Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> getAssortmentBUClustersMap(List<Assortment_Detail__c> assortmentDetailsList) {
        try {
            Set<Id> assortmentsBUTargetIdSet = new Set<Id>();
            // the result map to return
            Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> result = new Map<Id, Map<Id, Map<Integer, Orga_BU__c>>>();
            if(assortmentDetailsList != null && !assortmentDetailsList.isEmpty()) {
                for (Assortment_Detail__c assortmentDetail : assortmentDetailsList)
                    assortmentsBUTargetIdSet.add(assortmentDetail.Assortment_BU__r.BU_Target__c);
                // get clusters corresponding to assortment details bu targets
                List<Orga_BU__c> clustersList = [SELECT Id, Name, BU_Code__c, Assortment_Strat__c, Country_Origin__c,
                                                 Country_Origin__r.BU_Code__c, Category__c, Category__r.Path__c,
                                                 Weighted_Distribution_Manual__c, Weighted_Distribution_Manual_N1__c,
                                                 Weighted_Distribution_Manual_P1__c, Weighted_Distribution_Manual_P2__c,
                                                 SiteOfSales_Number__c, SiteOfSales_Number_N1__c, SiteOfSales_Number_P1__c,
                                                 SiteOfSales_Number_P2__c
                                                 FROM Orga_BU__c
                                                 WHERE Status__c = 'Open'
                                                 AND recordType.DeveloperName = 'Assortment_Cluster'
                                                 AND Country_Origin__c IN :assortmentsBUTargetIdSet
                                                 ORDER BY Assortment_Strat__c, Category__r.Level__c DESC, Category__c];
                // loop over assortment details to fill result map
                for (Assortment_Detail__c detail : assortmentDetailsList) {
                    if (!result.containsKey(detail.Assortment_BU__r.BU_Target__c))
                        result.put(detail.Assortment_BU__r.BU_Target__c, new Map<Id, Map<Integer, Orga_BU__c>>());
                    for (Orga_BU__c cluster : clustersList) {
                        Map<Id, Map<Integer, Orga_BU__c>> detailCategoryToClustersMap = result.get(detail.Assortment_BU__r.BU_Target__c);
                        if (!detailCategoryToClustersMap.containsKey(detail.Category__c))
                            detailCategoryToClustersMap.put(detail.Category__c, new Map<Integer, Orga_BU__c>());
                        if (cluster.Country_origin__c == detail.Assortment_BU__r.BU_Target__c 
                            && (cluster.Category__c == null
                                || (cluster.Category__r.Path__c != null
                                    && cluster.Category__r.Path__c.startsWith(detail.Assortment_BU__r.Orga_HE__r.Path__c)
                                    && detail.Category__c != null && detail.Category__r.Path__c != null
                                    && detail.Category__r.Path__c.startsWith(cluster.Category__r.Path__c))))
                            detailCategoryToClustersMap.get(detail.Category__c).put(Integer.valueOf(cluster.Assortment_Strat__c.right(1)), cluster);
                    }
                }
            }
            return result;
        } catch (System.SObjectException ex) {
            return null;
        }
    }   
    
    /**
     * 
	*/
    public static Map<Id, Map<Id, Map<Integer, Orga_BU__c>>> getAssortmentBUClustersMap(Set<Id> assortmentDetailsIdSet) {
        List<Assortment_Detail__c> assortmentDetailsList = [SELECT Id, Category__c, Category__r.Path__c, Assortment_BU__c, Assortment_BU__r.BU_Target__c,
                                                            Assortment_BU__r.Orga_HE__c, Assortment_BU__r.Orga_HE__r.Path__c,Year__c
                                                            FROM Assortment_Detail__c
                                                            WHERE Id IN :assortmentDetailsIdSet];
        return AssortmentUtility.getAssortmentBUClustersMap(assortmentDetailsList);
    }
    
    /**
     * calculates the sum of Weighted Distribution Manual depending on gap
     * @parameter gap the difference between assortmentDetail year and current Year
     * @return NULL in case of SObjectException (fields aren't queried)
	*/
    public static Decimal getSumDVClusters(List<Orga_BU__c> clusters, Integer gap) {
        try {
            Decimal sumDVClusters = 0;
            if (clusters != null && !clusters.isEmpty()) {
                for (Orga_BU__c cluster : clusters) {
                    if (gap >= 1)
                        sumDVClusters += cluster.Weighted_Distribution_Manual_N1__c != null ? cluster.Weighted_Distribution_Manual_N1__c : 0;
                    if (gap == 0)
                        sumDVClusters += cluster.Weighted_Distribution_Manual__c != null ? cluster.Weighted_Distribution_Manual__c : 0;
                    if (gap == -1)
                        sumDVClusters += cluster.Weighted_Distribution_Manual_P1__c != null ? cluster.Weighted_Distribution_Manual_P1__c : 0;
                    if (gap <= -2)
                        sumDVClusters += cluster.Weighted_Distribution_Manual_P2__c != null ? cluster.Weighted_Distribution_Manual_P2__c : 0;
                }
            }
            return sumDVClusters;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    /**
     * @description calculates New_Client_WD_MarketBased__c
     * @parameter assortmentDetail must query fields for calculation are Ass_BU_Cluster__c and Year__c
     * @parameter clusters a list of Orga_BU__c of record type Assortment_Cluster that must have queried fields Weighted_Distribution_Manual_N1__c, 
     * Weighted_Distribution_Manual__c, Weighted_Distribution_Manual_P1__c, Weighted_Distribution_Manual_P2__c
     * @return decimal value of assortmentDetail New_Client_WD_MarketBased__c
     * @return NULL in case of SObjectException (fields aren't queried)
	*/
    public static Decimal getWDMarketBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = assortmentDetail.Year__c != null ? (Integer) assortmentDetail.Year__c - Date.today().year() : 1; // case like for like
            Decimal WDMarketBased = 0;
            Boolean next = false;
            if (clusters != null && !clusters.isEmpty()) {
                for (Orga_BU__c cluster : clusters) {
                    if (cluster.Id == assortmentDetail.Ass_BU_Cluster__c || next) {
                        if (gap >= 1)
                            WDMarketBased += cluster.Weighted_Distribution_Manual_N1__c != null ? cluster.Weighted_Distribution_Manual_N1__c : 0;
                        if (gap == 0)
                            WDMarketBased += cluster.Weighted_Distribution_Manual__c != null ? cluster.Weighted_Distribution_Manual__c : 0;
                        if (gap == -1)
                            WDMarketBased += cluster.Weighted_Distribution_Manual_P1__c != null ? cluster.Weighted_Distribution_Manual_P1__c : 0;
                        if (gap <= -2)
                            WDMarketBased += cluster.Weighted_Distribution_Manual_P2__c != null ? cluster.Weighted_Distribution_Manual_P2__c : 0;
                        next = true;
                    }
                }
                
            }
            return WDMarketBased;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    /**
     * @description calculates New_Client_WD_ClientBased__c
     * @parameter assortmentDetail must query fields for calculation Ass_BU_Cluster__c and Year__c
     * @parameter clusters a list of Orga_BU__c of record type Assortment_Cluster that must have queried fields Weighted_Distribution_Manual_N1__c, 
     * Weighted_Distribution_Manual__c, Weighted_Distribution_Manual_P1__c, Weighted_Distribution_Manual_P2__c
     * @return decimal value of assortmentDetail New_Client_WD_ClientBased__c
     * @return NULL in case of SObjectException (fields aren't queried)
	*/
    public static Decimal getWDClientBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year();
            Decimal sumDVClusters = getSumDVClusters(clusters, gap);
            Decimal WDMarketBased = getWDMarketBased(assortmentDetail, clusters);
            if (sumDVClusters == 0)
                return 0;
            return WDMarketBased / sumDVClusters * 100;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getOffsetCumul(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year();
            Decimal offsetCumul = 0;
            Boolean next = false;
            if (clusters != null && !clusters.isEmpty()) {
                for (Orga_BU__c cluster : clusters) {
                    if (cluster.Id == assortmentDetail.Ass_BU_Cluster__c || next) {
                        if (gap >= 1)
                            offsetCumul += cluster.SiteOfSales_Number_N1__c != null ? cluster.SiteOfSales_Number_N1__c : 0;
                        if (gap == 0)
                            offsetCumul += cluster.SiteOfSales_Number__c != null ? cluster.SiteOfSales_Number__c : 0;
                        if (gap == -1)
                            offsetCumul += cluster.SiteOfSales_Number_P1__c != null ? cluster.SiteOfSales_Number_P1__c : 0;
                        if (gap <= -2)
                            offsetCumul += cluster.SiteOfSales_Number_P2__c != null ? cluster.SiteOfSales_Number_P2__c : 0;
                        next = true;
                    }
                }
                
            }
            return offsetCumul;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getSumSOSClusters(List<Orga_BU__c> clusters, Integer gap) {
        try {
            Decimal sumSOSClusters = 0;
            if (clusters != null && !clusters.isEmpty()) {
                for (Orga_BU__c cluster : clusters) {
                    if (gap >= 1)
                        sumSOSClusters += cluster.SiteOfSales_Number_N1__c != null ? cluster.SiteOfSales_Number_N1__c : 0;
                    if (gap == 0)
                        sumSOSClusters += cluster.SiteOfSales_Number__c != null ? cluster.SiteOfSales_Number__c : 0;
                    if (gap == -1)
                        sumSOSClusters += cluster.SiteOfSales_Number_P1__c != null ? cluster.SiteOfSales_Number_P1__c : 0;
                    if (gap <= -2)
                        sumSOSClusters += cluster.SiteOfSales_Number_P2__c != null ? cluster.SiteOfSales_Number_P2__c : 0;
                }
            }
            return sumSOSClusters;
        } catch (System.SObjectException ex) {
            return 0;
        } 
    }
    
    public static Decimal getSumSOSCircuit(Assortment_Detail__c assortmentDetail) {
        /*assortmentDetail = [SELECT Assortment_BU__r.BU_Source__r.SiteOfSales_Number__c, Assortment_BU__r.BU_Source__r.SiteOfSales_Number_N1__c,
                            Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P1__c, Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P2__c, Year__c
                            FROM Assortment_Detail__c WHERE Id = :assortmentDetail.Id];*/
        Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year();
        Decimal sumSOSCircuit = 0;
        if (gap >= 1)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_N1__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_N1__c : 0;
        if (gap == 0)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number__c : 0;
        if (gap == -1)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P1__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P1__c : 0;
        if (gap <= -2)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P2__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P2__c : 0;
        return sumSOSCircuit;
    }
    
    public static Decimal getNDMarketBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year();
            Decimal sumSOSCircuit = getSumSOSCircuit(assortmentDetail);
            Decimal offsetCumul = getOffsetCumul(assortmentDetail, clusters);
            if (sumSOSCircuit == 0)
                return 0;
            return offsetCumul / sumSOSCircuit * 100;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getNDClientBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year();
            Decimal sumSOSClusters = getSumSOSClusters(clusters, gap);
            Decimal offsetCumul = getOffsetCumul(assortmentDetail, clusters);
            if (sumSOSClusters == 0)
                return 0;
            return offsetCumul / sumSOSClusters * 100;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getL4LWDMarketBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = assortmentDetail.Year__c != null ? (Integer) assortmentDetail.Year__c - Date.today().year()  + 1 : 1;
            Decimal WDMarketBased = 0;
            Boolean next = false;
            if (clusters != null && !clusters.isEmpty()) {
                for (Orga_BU__c cluster : clusters) {
                    if (cluster.Id == assortmentDetail.Ass_BU_Cluster__c || next) {
                        if (gap >= 1)
                            WDMarketBased += cluster.Weighted_Distribution_Manual_N1__c != null ? cluster.Weighted_Distribution_Manual_N1__c : 0;
                        if (gap == 0)
                            WDMarketBased += cluster.Weighted_Distribution_Manual__c != null ? cluster.Weighted_Distribution_Manual__c : 0;
                        if (gap == -1)
                            WDMarketBased += cluster.Weighted_Distribution_Manual_P1__c != null ? cluster.Weighted_Distribution_Manual_P1__c : 0;
                        if (gap <= -2)
                            WDMarketBased += cluster.Weighted_Distribution_Manual_P2__c != null ? cluster.Weighted_Distribution_Manual_P2__c : 0;
                        next = true;
                    }
                }
                
            }
            return WDMarketBased;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getL4LWDClientBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year() + 1;
            Decimal sumDVClusters = getSumDVClusters(clusters, gap);
            Decimal WDMarketBased = getl4lWDMarketBased(assortmentDetail, clusters);
            if (sumDVClusters == 0)
                return 0;
            return WDMarketBased / sumDVClusters * 100;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getL4LOffsetCumul(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year() + 1;
            Decimal offsetCumul = 0;
            Boolean next = false;
            if (clusters != null && !clusters.isEmpty()) {
                for (Orga_BU__c cluster : clusters) {
                    if (cluster.Id == assortmentDetail.Ass_BU_Cluster__c || next) {
                        if (gap >= 1)
                            offsetCumul += cluster.SiteOfSales_Number_N1__c != null ? cluster.SiteOfSales_Number_N1__c : 0;
                        if (gap == 0)
                            offsetCumul += cluster.SiteOfSales_Number__c != null ? cluster.SiteOfSales_Number__c : 0;
                        if (gap == -1)
                            offsetCumul += cluster.SiteOfSales_Number_P1__c != null ? cluster.SiteOfSales_Number_P1__c : 0;
                        if (gap <= -2)
                            offsetCumul += cluster.SiteOfSales_Number_P2__c != null ? cluster.SiteOfSales_Number_P2__c : 0;
                        next = true;
                    }
                }
                
            }
            return offsetCumul;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getL4LSumSOSCircuit(Assortment_Detail__c assortmentDetail) {
        Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year() + 1;
        Decimal sumSOSCircuit = 0;
        if (gap >= 1)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_N1__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_N1__c : 0;
        if (gap == 0)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number__c : 0;
        if (gap == -1)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P1__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P1__c : 0;
        if (gap <= -2)
            sumSOSCircuit = assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P2__c != null ? assortmentDetail.Assortment_BU__r.BU_Source__r.SiteOfSales_Number_P2__c : 0;
        return sumSOSCircuit;
    }
    
    public static Decimal getL4LNDMarketBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year() + 1;
            Decimal sumSOSCircuit = getL4LSumSOSCircuit(assortmentDetail);
            Decimal offsetCumul = getL4LOffsetCumul(assortmentDetail, clusters);
            if (sumSOSCircuit == 0)
                return 0;
            return offsetCumul / sumSOSCircuit * 100;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    public static Decimal getL4LNDClientBased(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Integer gap = (Integer) assortmentDetail.Year__c - Date.today().year();
            Decimal sumSOSClusters = getSumSOSClusters(clusters, gap);
            Decimal offsetCumul = getl4lOffsetCumul(assortmentDetail, clusters);
            if (sumSOSClusters == 0)
                return 0;
            return offsetCumul / sumSOSClusters * 100;
        } catch (System.SObjectException ex) {
            return 0;
        }
    }
    
    /**
     * @description calulates and assigns New_Client_WD_MarketBased__c, New_Client_WD_ClientBased__c, New_Corp_WD_MarketBased__c, 
     * New_Corp_WD_ClientBased__c, New_Client_ND_MarketBased__c, New_Client_ND_ClientBased__c, New_Corp_ND_MarketBased__c, New_Corp_ND_ClientBased__c,
     * and New_Client_ProductNumber__c to assortmentDetail record
     * @parameter assortmentDetail must query fields for calculation are Ass_BU_Cluster__c and Year__c
     * @parameter clusters a list of Orga_BU__c of record type Assortment_Cluster that must have queried fields Weighted_Distribution_Manual_N1__c, 
     * Weighted_Distribution_Manual__c, Weighted_Distribution_Manual_P1__c, Weighted_Distribution_Manual_P2__c
	*/
    public static void assignKPI(Assortment_Detail__c assortmentDetail, List<Orga_BU__c> clusters) {
        try {
            Decimal WDMarketBased = AssortmentUtility.getWDMarketBased(assortmentDetail, clusters);
            Decimal WDClientBased = AssortmentUtility.getWDClientBased(assortmentDetail, clusters);
            Decimal NDMarketBased = AssortmentUtility.getNDMarketBased(assortmentDetail, clusters);
            Decimal NDClientBased = AssortmentUtility.getNDClientBased(assortmentDetail, clusters);
            Decimal offsetCumul = AssortmentUtility.getOffsetCumul(assortmentDetail, clusters);
            // L4L
            Decimal L4LWDMarketBased = AssortmentUtility.getL4LWDMarketBased(assortmentDetail, clusters);
            Decimal L4LWDClientBased = AssortmentUtility.getL4LWDClientBased(assortmentDetail, clusters);
            Decimal L4LNDMarketBased = AssortmentUtility.getL4LNDMarketBased(assortmentDetail, clusters);
            Decimal L4LNDClientBased = AssortmentUtility.getL4LNDClientBased(assortmentDetail, clusters);
            Decimal L4LOffsetCumul = AssortmentUtility.getL4LOffsetCumul(assortmentDetail, clusters);
            // assignment
            assortmentDetail.New_Client_WD_MarketBased__c = WDMarketBased;
            assortmentDetail.New_Client_WD_ClientBased__c = WDClientBased;
            assortmentDetail.New_Corp_WD_MarketBased__c = WDMarketBased;
            assortmentDetail.New_Corp_WD_ClientBased__c = WDClientBased;
            assortmentDetail.New_Client_ND_MarketBased__c = NDMarketBased;
            assortmentDetail.New_Client_ND_ClientBased__c = NDClientBased;
            assortmentDetail.New_Corp_ND_MarketBased__c = NDMarketBased;
            assortmentDetail.New_Corp_ND_ClientBased__c = NDClientBased;
            assortmentDetail.New_Client_ProductNumber__c = offsetCumul;
            
            assortmentDetail.L4L_Client_WD_MarketBased__c = L4LWDMarketBased;
            assortmentDetail.L4L_Client_WD_ClientBased__c = L4LWDClientBased;
            assortmentDetail.L4L_Client_ND_MarketBased__c = L4LNDMarketBased;
            assortmentDetail.L4L_Client_ND_ClientBased__c = L4LNDClientBased;
            assortmentDetail.L4L_Client_ProductNumber__c = L4LOffsetCumul;
                        
        } catch (System.SObjectException ex) { }
    }
    
}