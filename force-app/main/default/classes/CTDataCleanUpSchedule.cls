public with sharing class CTDataCleanUpSchedule implements Schedulable {
    public static final String CRON = '0 0 2 * * ?';
    public void execute(SchedulableContext sc) {
        // clearing old data of contact data last 30 days 
        CTPeopleTracingDataCleanUpBatch peopleTracingBatch = new CTPeopleTracingDataCleanUpBatch();
        // Database.executeBatch(batchable, batchSize)
        Database.executeBatch(peopleTracingBatch , 2000);

        // clearing location tracing data based on visit date older than last 30 days 
        CTLocationTracingCleanUpDataBatch locationTracing = new CTLocationTracingCleanUpDataBatch();
        Database.executeBatch(locationTracing, 2000);
        
    }
}