public with sharing Class CTPersonController {
    //get a unique string
    public static String getToken(String mobileNo){
        // converting a mobile no into blob obj
        Blob value = Blob.valueOf(mobileNo);    
        // generating into a secure token and this return into a blob obj
        Blob hash = Crypto.generateDigest('MD5', value); 
        // To get the string using encodeutility to convert a blob obj to string
        return EncodingUtil.base64Encode(hash);   
    }

    //
    public static List<Person__c> getRecentHealthChanges(){
        return [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                FROM Person__c 
                ORDER BY Status_Update_Date__c DESC 
                NULLS LAST];
    }

    //search a person by name, mobileno or token
    public static List<Person__c> searchPeople(String searchTerm){
        searchTerm = searchTerm + '%';
        return [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                FROM Person__c 
                WHERE Name LIKE :searchTerm 
                OR Mobile__c LIKE :searchTerm
                OR Token__c LIKE :searchTerm
                ORDER BY Status_Update_Date__c DESC
                NULLS LAST];
    }
    
    // search a person by id
    public static Person__c getPersonById(String personId){
        List<Person__c> people = [SELECT Id, Name, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                                    FROM Person__c 
                                    WHERE Id =: personId];
        if(people != null && people.size() > 0){
            return people[0];
        } 
        return null;
    }


    // this will return map(health status, [how many persons])
    // the no of persons in each health status
    // get count of people in each health status 
    public static Map<String, Integer> getHealthStatusCount(){
        Map<String, Integer> healthCountMap = new Map<String, Integer>();
        for(AggregateResult ar : [SELECT Health_Status__c, COUNT(Id) total
                                    FROM Person__c 
                                    GROUP BY Health_Status__c]){
            healthCountMap.put(String.valueOf(ar.get('Health_Status__c')), Integer.valueOf(ar.get('total')));
        }
        return healthCountMap;
    }

    // we need to find all those new person records which are cohabitants it will expect set<Id>
    public static Set<Id> getCohabitants(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<String> healthStatuses = new List<String>{'Green' , 'Yellow'};
        // SOQL to get the cohabitants
        // we are going to specify the Ids for whom we are going to identify the cohabitants
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds) 
                                                AND Contact_Type__c = 'Cohabitant'
                                                AND (Person_1__r.Health_Status__c IN :healthStatuses OR Person_2__r.Health_Status__c IN :healthStatuses)];
        // we are going to buid this cohabitants after excluding duplicates 
        Set<Id> cohabitants = new Set<Id>();
        // checking for duplicate person ids
        // Each of this pt record we are going to get the person_1 id and person_2 id and we are going to compare whether it exists in personIds or not
        // if personIds are not having person 1 and 2 Id's then we are adding to cohabitants
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                cohabitants.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                cohabitants.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return cohabitants;
    }

    //Same as we are going to get Neighbours
    public static Set<Id> getNeighbours(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds) 
                                                AND Contact_Type__c = 'Neighbour'
                                                AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')];
       
        Set<Id> neighbours = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                neighbours.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                neighbours.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return neighbours;
    }

    // we are going to find the primary contacts
    // when person 2 directly meeting to person 1 so the person 2 will be the primary contacts of person 1
    // when person 3 meets person 2 then person 3 will be the secodary contacts of person 1 and primary contacts for person 2 
    public static Set<Id> getPrimaryContacts(Set<Id> personIds, Set<Id> alreadyProcessed){
        List<String> healthStatuses = new List<String>{'Yellow' , 'Green'};
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :personIds OR Person_2__c IN :personIds) 
                                                AND Contact_Type__c = 'Other'
                                                AND Contact_Date__c = LAST_N_DAYS : 10
                                                AND (Person_1__r.Health_Status__c IN :healthStatuses OR Person_2__r.Health_Status__c IN :healthStatuses)];
       
        Set<Id> primaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                primaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                primaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return primaryContacts;
    }

    // we are going to find the secondary contacts
    // when person 2 directly meeting to person 1 so the person 2 will be the primary contacts of person 1
    // when person 3 meets person 2 then person 3 will be the secodary contacts of person 1 and primary contacts for person 2 
    // In this method there is a little cache instead of passing personIds we need to pass primary contacts to this method to find secodary contacts
    public static Set<Id> getSecondaryContacts(Set<Id> primaryContactsIds, Set<Id> alreadyProcessed){
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c 
                                                FROM People_Tracing__c 
                                                WHERE (Person_1__c IN :primaryContactsIds OR Person_2__c IN :primaryContactsIds) 
                                                AND Contact_Type__c = 'Other'
                                                AND Contact_Date__c = LAST_N_DAYS : 10
                                                AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')];
       
        Set<Id> secondaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                secondaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                secondaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return secondaryContacts;
    }
}