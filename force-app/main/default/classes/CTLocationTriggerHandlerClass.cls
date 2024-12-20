public with sharing class CTLocationTriggerHandlerClass {
    
    public static void beforeInsert(List<Location__c> newRecords){
        for(Location__c location : newRecords){
            location.Status__c = 'Green';
        }
    }

    public static void beforeUpdate(List<Location__c> newRecords, Map<Id, Location__c> oldRecords){
        for(Location__c location : newRecords){
            if(location.Status__c != oldRecords.get(location.Id).Status__c){
                location.Status_Update_Date__c = Date.today();
            }
        }
    }

    public static void afterUpdate(List<Location__c> newRecords, Map<Id, Location__c> oldRecords){
        Set<Id> statusChange = new Set<Id>();
        for(Location__c location : newRecords){
            if(location.Status__c == 'Red' && oldRecords.get(location.Id).Status__c != 'Red'){
                statusChange.add(location.Id);
            }
        }
        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByLocationIds(statusChange);
        Set<Id> personId = new Set<Id>();
        for(Location_Tracing__c trace : locationTraces){
            personId.add(trace.Person__c);
        }
        
        List<Person__c> peopleToUpdate = new List<Person__c>(); 
        for(Id pId : personId){
            peopleToUpdate.add(new Person__c(Id = pId, Health_Status__c = 'Yellow'));
        }
        if(peopleToUpdate.size() > 0){
            update peopleToUpdate;
        }
    }
}