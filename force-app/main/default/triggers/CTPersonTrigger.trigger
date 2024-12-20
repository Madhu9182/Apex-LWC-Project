trigger CTPersonTrigger on Person__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            // todo : Update health status to green 
            // todo : generate unique token for the person record
            CTPersonTriggerHandlerClass.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            CTPersonTriggerHandlerClass.beforeUpdate(Trigger.new, Trigger.oldMap);
        }

        when AFTER_UPDATE {
            CTPersonTriggerHandlerClass.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}