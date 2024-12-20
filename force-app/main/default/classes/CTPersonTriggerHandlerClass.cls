public with sharing class CTPersonTriggerHandlerClass {
    
    public static void beforeInsert(List<Person__c> newRecords){
        //Before Insert operation for Person__c object
        // make sure the health status is green
        // generate unique token for each record
        for(Person__c person : newRecords){
            //update person status to green
            person.Health_Status__c = 'Green';
            //generate a unique token
            person.Token__c = CTPersonController.getToken(person.Mobile__c);
        }
    }

    // Before update operation for Person__c
    public static void beforeUpdate(List<Person__c> newRecords, Map<Id, Person__c> oldRecords){
        for(Person__c person : newRecords){
            // check if the status changed in this transaction
            // also update Status_Update_Date__c
            if(person.Health_Status__c != oldRecords.get(person.Id).Health_Status__c){
                person.Status_Update_Date__c = Date.today();
            }
        }
    }

    public static void afterUpdate(List<Person__c> newRecords, Map<Id, Person__c> oldRecords){
        // create a set to store the health status changes records
        Set<Id> statusChanges = new Set<Id>();
        // create a set to store whose status change to Red 
        Set<Id> redStatus = new Set<Id>();
        for(Person__c person : newRecords){
            if(person.Health_Status__c != oldRecords.get(person.Id).Health_Status__c){
                statusChanges.add(person.Id);
            }
            if(person.Health_Status__c == 'Red' && oldRecords.get(person.Id).Health_Status__c != 'Red'){
                redStatus.add(person.Id);
            }
        }

        // already processed records 
        // The purpose of this already processed set is to ignore the duplicate processing
        Set<Id> alreadyProcessed = new Set<Id>();
        // so I will pass this already processed set to all my methods so that they can update whatever they are processing in that method to this Set.
        alreadyProcessed.addAll(redStatus);

        // add cohabitants to orange 
        // add primary contacts to orange 
        // add neighbours to yelow
        // add secondary contacts to yellow
        Set<Id> orangeStatus = new Set<Id>();
        Set<Id> yellowStatus = new Set<Id>();

        // build a list of person records to update so that we can call the update DML statement on that list
        List<Person__c> personToUpdate = new List<Person__c>();

        // lets add cohabitants
        orangeStatus.addAll(CTPersonController.getCohabitants(redStatus, alreadyProcessed));
        // lets add primaryContacts
        Set<Id> primaryContacts = CTPersonController.getPrimaryContacts(redStatus, alreadyProcessed);
        orangeStatus.addAll(primaryContacts);
        // lets add neighbours
        yellowStatus.addAll(CTPersonController.getNeighbours(redStatus, alreadyProcessed));
        // lets add secondaryContacts
        yellowStatus.addAll(CTPersonController.getSecondaryContacts(primaryContacts, alreadyProcessed));

        for (Id pid : orangeStatus) {
            personToUpdate.add(new Person__c(Id=pid, Health_Status__c = 'Orange'));
        }

        for (Id pid : yellowStatus) {
            personToUpdate.add(new Person__c(Id=pid, Health_Status__c = 'Yellow'));
        }

        if(personToUpdate.size() > 0){
            update personToUpdate;
        }

        List<Location_Tracing__c> locationTraces = CTLocationTracingController.getLocationsByPersonIds(statusChanges);
        if(locationTraces != null && locationTraces.size() > 0){
            Set<Id> locationIds = new Set<Id>();
            for (Location_Tracing__c trace : locationTraces) {
                locationIds.add(trace.Location__c);
            }
            CTLocationController.updateRedScore(locationIds);
        }
    }
}