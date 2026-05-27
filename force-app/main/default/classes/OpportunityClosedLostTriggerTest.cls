/**
 * Test class for OpportunityClosedLostTrigger and OpportunityClosedLostTriggerHandler.
 * Tests task creation when Opportunities transition to Closed Lost stage.
 */
@isTest
private class OpportunityClosedLostTriggerTest {
    
    private static final String PROSPECTING_STAGE = 'Prospecting';
    private static final String CLOSED_LOST_STAGE = 'Closed Lost';
    private static final String CLOSED_WON_STAGE = 'Closed Won';
    private static final Integer FOLLOW_UP_DAYS = 3;
    
    /**
     * Setup test data for all test methods.
     * Creates 251 Accounts with associated Opportunities to test bulk operations.
     */
    @TestSetup
    static void setupTestData() {
        List<Account> accounts = TestDataFactory.createAccounts(251, true);
        List<Opportunity> opportunities = TestDataFactory.createOpportunities(accounts, PROSPECTING_STAGE, true);
    }
    
    /**
     * Test that a Task is created when a single Opportunity transitions to Closed Lost.
     */
    @isTest
    static void shouldCreateTask_WhenSingleOpportunityClosedLost() {
        // Given
        Opportunity opp = [SELECT Id, StageName, OwnerId, Name FROM Opportunity LIMIT 1];
        Date expectedDueDate = Date.today().addDays(FOLLOW_UP_DAYS);
        
        // When
        Test.startTest();
        opp.StageName = CLOSED_LOST_STAGE;
        update opp;
        Test.stopTest();
        
        // Then
        List<Task> tasks = [SELECT Id, Subject, WhatId, OwnerId, ActivityDate, Status, Priority, Description 
                           FROM Task 
                           WHERE WhatId = :opp.Id];
        
        Assert.areEqual(1, tasks.size(), 'Exactly one Task should be created for Closed Lost Opportunity');
        Assert.areEqual('Follow up on Closed Lost Opportunity', tasks[0].Subject, 
            'Task subject should match expected value');
        Assert.areEqual(opp.Id, tasks[0].WhatId, 'Task should be related to the Opportunity');
        Assert.areEqual(opp.OwnerId, tasks[0].OwnerId, 'Task owner should match Opportunity owner');
        Assert.areEqual(expectedDueDate, tasks[0].ActivityDate, 
            'Task due date should be today plus 3 days');
        Assert.areEqual('Not Started', tasks[0].Status, 'Task status should be Not Started');
        Assert.areEqual('Normal', tasks[0].Priority, 'Task priority should be Normal');
        Assert.isTrue(tasks[0].Description.contains(opp.Name), 
            'Task description should contain Opportunity name');
    }
    
    /**
     * Test bulk operation with 251 Opportunities transitioning to Closed Lost.
     * Validates governor limit compliance and bulkification.
     */
    @isTest
    static void shouldCreateTasks_WhenBulkOpportunitiesClosedLost() {
        // Given
        List<Opportunity> opportunities = [SELECT Id, StageName FROM Opportunity];
        Date expectedDueDate = Date.today().addDays(FOLLOW_UP_DAYS);
        
        Assert.areEqual(251, opportunities.size(), 'Test setup should create 251 Opportunities');
        
        // When
        Test.startTest();
        for (Opportunity opp : opportunities) {
            opp.StageName = CLOSED_LOST_STAGE;
        }
        update opportunities;
        Test.stopTest();
        
        // Then
        List<Task> tasks = [SELECT Id, WhatId, ActivityDate FROM Task];
        
        Assert.areEqual(251, tasks.size(), 'Should create 251 Tasks for bulk Closed Lost Opportunities');
        
        // Verify all tasks have correct due date
        for (Task t : tasks) {
            Assert.areEqual(expectedDueDate, t.ActivityDate, 
                'All tasks should have due date of today plus 3 days');
        }
        
        // Verify each Opportunity has exactly one Task
        Set<Id> opportunityIds = new Set<Id>();
        for (Task t : tasks) {
            Assert.isFalse(opportunityIds.contains(t.WhatId), 
                'Each Opportunity should have exactly one Task');
            opportunityIds.add(t.WhatId);
        }
    }
    
    /**
     * Test that no Task is created when Opportunity stage changes but not to Closed Lost.
     */
    @isTest
    static void shouldNotCreateTask_WhenStageChangedButNotClosedLost() {
        // Given
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        
        // When
        Test.startTest();
        opp.StageName = CLOSED_WON_STAGE;
        update opp;
        Test.stopTest();
        
        // Then
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        Assert.areEqual(0, tasks.size(), 'No Task should be created when stage changes to Closed Won');
    }
    
    /**
     * Test that no Task is created when Opportunity is already Closed Lost and updated.
     */
    @isTest
    static void shouldNotCreateTask_WhenAlreadyClosedLost() {
        // Given
        Opportunity opp = [SELECT Id, StageName, Amount FROM Opportunity LIMIT 1];
        opp.StageName = CLOSED_LOST_STAGE;
        update opp;
        
        // Clear any tasks created by first update
        delete [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        
        // When
        Test.startTest();
        opp.Amount = 5000; // Change different field while staying Closed Lost
        update opp;
        Test.stopTest();
        
        // Then
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        Assert.areEqual(0, tasks.size(), 
            'No additional Task should be created when Opportunity remains Closed Lost');
    }
    
    /**
     * Test that no Task is created when Opportunity is inserted as Closed Lost.
     * Trigger only fires on update, not insert.
     */
    @isTest
    static void shouldNotCreateTask_WhenInsertedAsClosedLost() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // When
        Test.startTest();
        Opportunity newOpp = new Opportunity(
            Name = 'New Closed Lost Opp',
            AccountId = acc.Id,
            StageName = CLOSED_LOST_STAGE,
            CloseDate = Date.today()
        );
        insert newOpp;
        Test.stopTest();
        
        // Then
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :newOpp.Id];
        Assert.areEqual(0, tasks.size(), 
            'No Task should be created when Opportunity is inserted as Closed Lost');
    }
    
    /**
     * Test handler behavior with null inputs.
     */
    @isTest
    static void shouldHandleGracefully_WhenNullInputs() {
        // Given/When
        Test.startTest();
        try {
            OpportunityClosedLostTriggerHandler.handleAfterUpdate(null, null);
            OpportunityClosedLostTriggerHandler.handleAfterUpdate(new List<Opportunity>(), null);
            // Then - no exception thrown
            Assert.isTrue(true, 'Handler should handle null inputs gracefully');
        } catch (Exception e) {
            Assert.fail('Handler should not throw exception for null inputs: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test that Tasks are created with correct ownership when Opportunities have different owners.
     */
    @isTest
    static void shouldCreateTasksWithCorrectOwnership_WhenMultipleOwners() {
        // Given
        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
        if (users.size() < 2) {
            // Skip test if we don't have multiple users
            return;
        }
        
        List<Opportunity> opportunities = [SELECT Id, StageName FROM Opportunity LIMIT 2];
        opportunities[0].OwnerId = users[0].Id;
        opportunities[1].OwnerId = users[1].Id;
        update opportunities;
        
        // When
        Test.startTest();
        for (Opportunity opp : opportunities) {
            opp.StageName = CLOSED_LOST_STAGE;
        }
        update opportunities;
        Test.stopTest();
        
        // Then
        Map<Id, Task> tasksByOppId = new Map<Id, Task>();
        for (Task t : [SELECT Id, WhatId, OwnerId FROM Task WHERE WhatId IN :opportunities]) {
            tasksByOppId.put(t.WhatId, t);
        }
        
        Assert.areEqual(2, tasksByOppId.size(), 'Should create two Tasks');
        Assert.areEqual(users[0].Id, tasksByOppId.get(opportunities[0].Id).OwnerId, 
            'First Task owner should match first Opportunity owner');
        Assert.areEqual(users[1].Id, tasksByOppId.get(opportunities[1].Id).OwnerId, 
            'Second Task owner should match second Opportunity owner');
    }
    
    /**
     * Test that multiple stage transitions in the same transaction are handled correctly.
     */
    @isTest
    static void shouldCreateTask_WhenMultipleStageChangesInTransaction() {
        // Given
        List<Opportunity> opportunities = [SELECT Id, StageName FROM Opportunity LIMIT 3];
        
        // First update - change to intermediate stage
        for (Opportunity opp : opportunities) {
            opp.StageName = 'Qualification';
        }
        update opportunities;
        
        // When
        Test.startTest();
        // Second update - change to Closed Lost
        for (Opportunity opp : opportunities) {
            opp.StageName = CLOSED_LOST_STAGE;
        }
        update opportunities;
        Test.stopTest();
        
        // Then
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :opportunities];
        Assert.areEqual(3, tasks.size(), 
            'Should create Tasks for all three Opportunities that transitioned to Closed Lost');
    }
}