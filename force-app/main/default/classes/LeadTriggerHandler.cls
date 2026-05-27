/**
 * @description Handler class for Lead trigger operations
 */
public with sharing class LeadTriggerHandler {
    /**
     * @description Creates follow-up tasks for new leads
     * @param newLeadList List of Lead records to create tasks for
     */
    public static void createTask(List<Lead> newLeadList){
        createTaskInternal(newLeadList);
    }
    
    /**
     * @description Internal implementation for task creation with CRUD checks
     * @param newLeadList List of Lead records to create tasks for
     */
    private static void createTaskInternal(List<Lead> newLeadList){
        // Guard clause to reduce branching and handle null/empty inputs
        if(newLeadList == null || newLeadList.isEmpty()){
            return;
        }
        
        // Check CRUD permissions before DML operation
        if(!Schema.sObjectType.Task.isCreateable()){
            throw new DmlException('Insufficient permissions to create Task records');
        }
        
        List<Task> taskList = new List<Task>();
        for(Lead ls : newLeadList){
            taskList.add(buildTaskFromLead(ls));
        }
        
        if(!taskList.isEmpty()){
            insert taskList;
        }
    }
    
    /**
     * @description Builds a Task record from a Lead record
     * @param ls Lead record to create task for
     * @return Task Constructed task record
     */
    private static Task buildTaskFromLead(Lead ls){
        Task t = new Task();
        t.WhoId = ls.Id;
        t.Subject = 'Follow up for ' + ls.FirstName + ' ' + ls.LastName;
        t.Priority = 'High';
        t.Status = 'Not Started';
        // Do not set OwnerId explicitly to avoid INVALID_CROSS_REFERENCE_KEY in test contexts.
        // Let Salesforce assign the default owner (current running user) for the created Task.
        return t;
    }
}