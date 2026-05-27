/**
 * Test Data Factory for creating test records across all test classes.
 * Centralizes test data creation to maintain consistency and reduce duplication.
 */
@isTest
public class TestDataFactory {
    
    /**
     * Creates Account records for testing.
     * 
     * @param count Number of Accounts to create
     * @param doInsert Whether to insert records immediately
     * @return List of Account records
     */
    public static List<Account> createAccounts(Integer count, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        
        for (Integer i = 0; i < count; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i
            );
            accounts.add(acc);
        }
        
        if (doInsert) {
            insert accounts;
        }
        
        return accounts;
    }
    
    /**
     * Creates Opportunity records for testing.
     * 
     * @param accounts List of Accounts to associate with Opportunities
     * @param stageName Initial stage name for the Opportunities
     * @param doInsert Whether to insert records immediately
     * @return List of Opportunity records
     */
    public static List<Opportunity> createOpportunities(List<Account> accounts, String stageName, Boolean doInsert) {
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for (Integer i = 0; i < accounts.size(); i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = accounts[i].Id,
                StageName = stageName,
                CloseDate = Date.today().addDays(30),
                Amount = 10000 + (i * 1000)
            );
            opportunities.add(opp);
        }
        
        if (doInsert) {
            insert opportunities;
        }
        
        return opportunities;
    }
    
    /**
     * Creates Opportunity records with field overrides for testing.
     * 
     * @param count Number of Opportunities to create
     * @param accountId Account to associate with Opportunities
     * @param stageName Initial stage name
     * @param fieldOverrides Map of field API names to values for customization
     * @param doInsert Whether to insert records immediately
     * @return List of Opportunity records
     */
    public static List<Opportunity> createOpportunitiesWithOverrides(
        Integer count, 
        Id accountId, 
        String stageName, 
        Map<String, Object> fieldOverrides,
        Boolean doInsert) {
        
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for (Integer i = 0; i < count; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = accountId,
                StageName = stageName,
                CloseDate = Date.today().addDays(30),
                Amount = 10000
            );
            
            // Apply field overrides
            if (fieldOverrides != null) {
                for (String fieldName : fieldOverrides.keySet()) {
                    opp.put(fieldName, fieldOverrides.get(fieldName));
                }
            }
            
            opportunities.add(opp);
        }
        
        if (doInsert) {
            insert opportunities;
        }
        
        return opportunities;
    }
}