trigger CaseTrigger on Case (after insert, after update, after delete) {
    switch on Trigger.operationType {
        when AFTER_INSERT {
            CaseTriggerHandler.updateAccountCaseCounts(Trigger.new, null);
        }
        when AFTER_UPDATE {
            CaseTriggerHandler.updateAccountCaseCounts(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE {
            CaseTriggerHandler.handleCaseDeletion(Trigger.old);
        }
        when else {
            // Optional: Handle other cases or provide default behavior
        }
    }
}