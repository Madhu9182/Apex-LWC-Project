public with sharing class CTPersonDataSchedule implements Schedulable {
    public static final String CRONExpression = '0 0 3 * * ?';
    public void execute(SchedulableContext sc){
        
        CTPersonHealthStatusDataCleanUpBatch updateHealth = new CTPersonHealthStatusDataCleanUpBatch();
        Database.executeBatch(updateHealth, 2000);

        CTLocationDataUpdateBatch updateLocationHealthStatus = new CTLocationDataUpdateBatch();
        Database.executeBatch(updateLocationHealthStatus, 2000);
    }
}