trigger CTLocationTracingTrigger on Location_Tracing__c (before insert) {

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            CTLocationTracingTriggerHandlerClass.beforeInsert(Trigger.new);
        }
    }
}