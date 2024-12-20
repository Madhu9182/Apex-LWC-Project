public with sharing class CTPeopleTracingController {
    
    public static List<People_Tracing__c> getTraces(String recordId){
        return [SELECT Id, Contact_Date__c, Person_1__c, Person_1__r.Health_Status__c, Person_1__r.Token__c,  Person_2__c, Person_2__r.Health_Status__c, Person_2__r.Token__c 
                    FROM People_Tracing__c 
                    WHERE Person_1__c =: recordId 
                    OR Person_2__c =:recordId
                    ORDER BY Contact_Date__c DESC];
    }

    public static List<People_Tracing__c> checkDuplicates(List<People_Tracing__c> newPeopleTraces){
        // first we are going to identify all the unique ids based on that we are query existing records and we are going to constructe a map and we are going to find the duplicates same as CTLocationTracingController class method(checkDuplicates)
        // unique personids
        Set<Id> personIds = new Set<Id>();
        for(People_Tracing__c trace : newPeopleTraces){
            personIds.add(trace.Person_1__c);
            personIds.add(trace.Person_2__c);
        }
        // list of duplicate records
        List<People_Tracing__c> duplicates = new List<People_Tracing__c>();
        // creating map of Id and set of Id 
        // Person1, [Person2, Person3, ....] checking if one person leaving traces with other persons
        Map<Id, Set<Id>> mapOfExistingRecords = new Map<Id, Set<Id>>();
        // Query existing records
        List<People_Tracing__c> existingRecords = [SELECT Id, Person_1__c, Person_2__c
                                                    FROM People_Tracing__c 
                                                    WHERE Person_1__c IN: personIds
                                                    OR Person_2__c IN: personIds];

        // Iterating over existing records to built mapOfExistingRecords
        // first check if existing records list is empty or not 
        if( existingRecords != null && existingRecords.size() > 0){
            for(People_Tracing__c trace : existingRecords){
                if (! mapOfExistingRecords.containsKey(trace.Person_1__c)){
                    mapOfExistingRecords.put(trace.Person_1__c, new Set<Id>());
                }
                //getting the person 1(key) and adding the value(person 2 or traces)
                mapOfExistingRecords.get(trace.Person_1__c).add(trace.Person_2__c);


                // same for person 2 since person 1 can be person 2 as well 
                if(! mapOfExistingRecords.containsKey(trace.Person_2__c)){
                    mapOfExistingRecords.put(trace.Person_2__c, new Set<Id>());
                }
                // getting the person 2(key) and adding the value(Person 1 or traces)
                mapOfExistingRecords.get(trace.Person_2__c).add(trace.Person_1__c);
            }
            // Now iterate over newPeopleTraces to check duplicates 
            // each of the new records we are going to find the duplciates in the existing records
            for(People_Tracing__c trace : newPeopleTraces){
                // check for duplicates in Map comparing with new records
                if(
                    (mapOfExistingRecords.containsKey(trace.Person_1__c) && mapOfExistingRecords.get(trace.Person_1__c).contains(trace.Person_2__c))
                    || 
                    (mapOfExistingRecords.containsKey(trace.Person_2__c) && mapOfExistingRecords.get(trace.Person_2__c).contains(trace.Person_1__c))
               ){
                duplicates.add(trace);
               }
            }
        } 
        return duplicates;
    }
}