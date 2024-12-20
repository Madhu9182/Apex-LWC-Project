public with sharing class CTPersonHealthStatusDataCleanUpBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc){

        List<String> healthStatus = new List<String>{'Red', 'Orange', 'Yellow'};
        Date today = Date.today();
        Date fourteenDaysAgo = today - 14;
        return Database.getQueryLocator('SELECT Id, Health_Status__c FROM Person__c WHERE Status_Update_Date__c = :fourteenDaysAgo AND Health_Status__c IN :healthStatus');
    }

    public void execute(Database.BatchableContext bc, List<Person__c> scope){
        for(Person__c people : scope){
            people.Health_Status__c = 'Green';
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc){
        System.debug('Batch job completed');
    }
}