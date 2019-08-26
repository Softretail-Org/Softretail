/**
 * @author ULiT
 * */
public class ReportsGridCmpController {
    
    @AuraEnabled
    public static List<Report> getReportByFolderName(String id) {
        List<Folder> folderName = [SELECT Id, Name FROM Folder WHERE Id = :id];
        List<Report> reportList = null;
        if(!folderName.isEmpty()) {
            reportList = [SELECT Id, Name, DeveloperName 
                          FROM Report 
                          WHERE FolderName = :folderName.get(0).Name
                          ORDER BY Name];
        }
        return reportList;
    }
    
    @AuraEnabled
    public static List<Orga_HE__c> getAllCategoriesLevel1() {
        List<Orga_HE__c> categories = [SELECT Id, Name, path__c
                                       FROM Orga_HE__c
                                       WHERE Level__c = 1
                                       ORDER BY Name];
        return categories;
    }
    
    @AuraEnabled
    public static List<Orga_BU__c> getBannersWithMasterBu() {
        List<Orga_BU__c> banners = [SELECT Id, Name
                                    FROM Orga_BU__c
                                    WHERE RecordType.DeveloperName = 'Banner'
                                    AND IsMasterBU__c = true
                                    ORDER BY Name];
        return banners;
    }
    
    @AuraEnabled
    public static String getFolderNameById(String id) {
        List<Folder> folderName = [SELECT Id, Name, DeveloperName
                                   FROM Folder
                                   WHERE Id = :id];
        if(folderName.size() != 0)
            return folderName.get(0).Name+'_'+folderName.get(0).DeveloperName;
        else
            return '';
    }
}