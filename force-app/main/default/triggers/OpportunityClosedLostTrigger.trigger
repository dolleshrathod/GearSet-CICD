/**
 * Trigger for Opportunity object to handle Closed Lost scenarios.
 * Creates follow-up Tasks when Opportunities are marked as Closed Lost.
 */
trigger OpportunityClosedLostTrigger on Opportunity (after update) {
    OpportunityClosedLostTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}