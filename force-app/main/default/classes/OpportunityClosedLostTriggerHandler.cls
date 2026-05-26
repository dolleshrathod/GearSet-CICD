/**
 * Handler class for OpportunityClosedLostTrigger.
 * Implements business logic for creating follow-up Tasks when Opportunities are Closed Lost.
 */
public with sharing class OpportunityClosedLostTriggerHandler {
    
    private static final String CLOSED_LOST_STAGE = 'Closed Lost';
    private static final String TASK_SUBJECT = 'Follow up on Closed Lost Opportunity';
    private static final Integer FOLLOW_UP_DAYS = 3;
    
    /**
     * Handles after update trigger context for Opportunity.
     * Creates follow-up Tasks for Opportunities that transition to Closed Lost stage.
     * 
     * @param newOpportunities List of new Opportunity records from Trigger.new
     * @param oldOpportunityMap Map of old Opportunity records from Trigger.oldMap
     */
    public static void handleAfterUpdate(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunityMap) {
        // Guard clause for null inputs
        if (newOpportunities == null || newOpportunities.isEmpty() || oldOpportunityMap == null) {
            return;
        }
        
        List<Task> tasksToInsert = new List<Task>();
        
        // Iterate through opportunities to find those that became Closed Lost
        for (Opportunity newOpp : newOpportunities) {
            Opportunity oldOpp = oldOpportunityMap.get(newOpp.Id);
            
            // Check if stage changed to Closed Lost
            if (newOpp.StageName == CLOSED_LOST_STAGE && 
                oldOpp != null && 
                oldOpp.StageName != CLOSED_LOST_STAGE) {
                
                tasksToInsert.add(createFollowUpTask(newOpp));
            }
        }
        
        // Insert tasks if any were created (DML outside loop)
        if (!tasksToInsert.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.insert(tasksToInsert, false);
                
                // Log any partial failures
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error error : results[i].getErrors()) {
                            System.debug(LoggingLevel.ERROR, 
                                'Error creating follow-up Task for Opportunity ' + 
                                tasksToInsert[i].WhatId + ': ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 
                    'Exception creating follow-up Tasks: ' + e.getMessage());
                throw new OpportunityClosedLostException(
                    'Failed to create follow-up tasks for Closed Lost opportunities', e);
            }
        }
    }
    
    /**
     * Creates a follow-up Task for a Closed Lost Opportunity.
     * 
     * @param opp The Opportunity that was Closed Lost
     * @return Task record ready for insertion
     */
    private static Task createFollowUpTask(Opportunity opp) {
        Task followUpTask = new Task();
        followUpTask.Subject = TASK_SUBJECT;
        followUpTask.WhatId = opp.Id;
        followUpTask.OwnerId = opp.OwnerId;
        followUpTask.ActivityDate = Date.today().addDays(FOLLOW_UP_DAYS);
        followUpTask.Status = 'Not Started';
        followUpTask.Priority = 'Normal';
        followUpTask.Description = 'Follow up with customer regarding the Closed Lost opportunity: ' + opp.Name;
        
        return followUpTask;
    }
    
    /**
     * Custom exception for OpportunityClosedLostTriggerHandler errors.
     */
    public class OpportunityClosedLostException extends Exception {}
}