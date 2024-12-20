public with sharing class CTLocationDataUpdateBatch implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> healthToUpdate = new List<String>{'Red' , 'Orange' , 'Yellow'}; 
        Date today = Date.today();
        Date fourteenDaysAgo = today - 14;
        return Database.getQueryLocator('SELECT Id, Status_Update_Date__c, Status__c FROM Location__c WHERE Status_Update_Date__c =: fourteenDaysAgo AND Status__c IN: healthToUpdate' );
    }

    public void execute(Database.BatchableContext bc, List<Location__c> scope){
        for(Location__c statusUpdate : scope){
            statusUpdate.Status__c = 'Green';
        }

        update scope;
    }

    public void finish(Database.BatchableContext bc){
        System.debug('Batch job completed');
    }
}