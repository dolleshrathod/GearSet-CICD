@isTest
private class LeadTriggerHandlerTest {
    @isTest static void testCreateTaskSingleLead() {
        // Prepare test lead
        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company'
        );
        insert l;
        // Re-query to ensure all fields (including Id/OwnerId) are populated as expected by handler
        l = [SELECT Id, FirstName, LastName, OwnerId FROM Lead WHERE Id = :l.Id];

        // Call the handler
        Test.startTest();
        LeadTriggerHandler.createTask(new List<Lead>{ l });
        Test.stopTest();
        
        // Verify Task created and fields set correctly
        List<Task> tasks = [SELECT Id, WhoId, Subject, Priority, Status, OwnerId FROM Task WHERE WhoId = :l.Id];
        System.assertEquals(1, tasks.size(), 'One task should be created for the lead');
        Task t = tasks[0];
        System.assertEquals(l.Id, t.WhoId, 'Task WhoId should reference the Lead Id');
        System.assertEquals('Follow up for '+ l.FirstName + ' ' + l.LastName, t.Subject, 'Subject should include lead name');
        System.assertEquals('High', t.Priority, 'Priority should be High');
        System.assertEquals('Not Started', t.Status, 'Status should be Not Started');
        System.assertEquals(l.OwnerId, t.OwnerId, 'OwnerId should match Lead owner');
    }
    
    @isTest static void testCreateTaskBulkAndEmptyList() {
        // Prepare multiple leads
        List<Lead> leadList = new List<Lead>();
        for(Integer i=0; i<5; i++){
            leadList.add(new Lead(
                FirstName = 'Bulk' + i,
                LastName = 'Lead',
                Company = 'Company' + i,
                OwnerId = UserInfo.getUserId()
            ));
        }
        insert leadList;
        // Re-query to ensure fields populated
        leadList = [SELECT Id, FirstName, LastName, OwnerId FROM Lead WHERE Id IN :leadList];

        // Call handler for bulk leads
        Test.startTest();
        LeadTriggerHandler.createTask(leadList);
        Test.stopTest();
        
        // Verify tasks created for all leads
        Set<Id> leadIds = new Set<Id>();
        for(Lead ld : leadList) {
            leadIds.add(ld.Id);
        }
        List<Task> tasks = [SELECT Id, WhoId FROM Task WHERE WhoId IN :leadIds];
        System.assertEquals(leadList.size(), tasks.size(), 'A task should be created for each lead in bulk');
        
        // Call handler with empty list - should not throw and should not create additional tasks
        Integer beforeCount = [SELECT Id FROM Task].size();
        Test.startTest();
        LeadTriggerHandler.createTask(new List<Lead>());
        Test.stopTest();
        Integer afterCount = [SELECT Id FROM Task].size();
        System.assertEquals(beforeCount, afterCount, 'No new tasks should be created when handler invoked with empty list');
    }
}