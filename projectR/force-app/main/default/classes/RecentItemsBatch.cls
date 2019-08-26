/**
 * Batchable class used to refresh the recent items manually for all users
 **/
global with sharing class RecentItemsBatch implements Database.Batchable<SObject> {
    private NegoptimBatch nb;
    public String query;
    // Creation list of sObject Names.
    public Set<String> objectNames;
    
    /* Constructor */
    public RecentItemsBatch(String startedFrom, List<String> objNames) {
        nb = new NegoptimBatch('Recent Items Batch', NegoptimBatch.BatchType.Stateless, startedFrom);
        objectNames = new Set<String>(objNames);
        String q = 'SELECT Id, Name, UserRoleId FROM User WHERE IsActive = True AND Id = \''+ UserInfo.getUserId() + '\'';
        query = q;
        nb.logParameter('query', query);
    }
    /* Start method implementation.*/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    /* Execute method implementation.*/
    public void execute(Database.BatchableContext bc, List<User> scope) {
        List<SObjectType> customObjectList = new List<SObjectType>();
        List<schema.sObjectType> allObjects = schema.getGlobalDescribe().Values();
        for(schema.SObjectType objTyp :allObjects){
            if(objTyp.getDescribe().isCustom() && objectNames.contains(objTyp.getDescribe().getName())){
                customObjectList.add(objTyp);
            }
        }
        Savepoint sp = Database.setSavepoint();
        try {
            for (User user : scope){
                for(SObjectType objType : customObjectList){
                    String sObjectName = objType.getDescribe().getName();
                    Map<String, Schema.SObjectField> fieldsMap = objType.getDescribe().fields.getMap();
                    // Check Accessibility.
                    if(!NegoptimHelper.checkAccessibility(objType, new String [] {'Id'})) {
                        continue;
                    }
                    if(fieldsMap.keySet().contains('lastvieweddate')){
                        query = 'SELECT Id, Name, LastViewedDate FROM ' + sObjectName + ' ORDER BY LastViewedDate DESC FOR VIEW';
                        Database.query(query);
                    }
                }
            }
        } catch(DMLException e) {
            nb.logError(e);
            Database.rollback(sp);
        }
        nb.saveLog(bc);
    }
    // Finish method.
    public void finish(Database.BatchableContext bc) {
        String customSubject = nb.getBatchName() + ': ' + nb.getAsyncApexJob(bc).Status;
        nb.sendEmail(bc, null, customSubject);
    }
}