public class AccountTriggerHandler {
	// Before Insert
    public static void beforeInsert(List<Account> accList){
        for(Account acc : accList){
            if(acc.Rating == null){
                acc.Rating = 'Warm';
            }
        }
    }


	// After Update 
    public static void afterUpdate(List<Account> newAccList, Map<Id,Account> oldAccMap){
        for(Account acc : newAccList){
            Account oldAcc = oldAccMap.get(acc.Id);

            if(acc.Rating == 'Hot' && oldAcc.Rating != 'Hot'){
                	System.debug('Old Rating Value => '+ oldAcc.Rating + ' New Rating Value =>'+acc.Rating);
            }
        }
    }

    public static void afterUpdateAnnualRevenue(List<Account> newAccList, Map<Id,Account> oldAccMap){
      List<Account> updatedAccount = new List<Account>();  
		for(Account acc : newAccList){
            Account oldAcc = oldAccMap.get(acc.Id);
            
            if(acc.AnnualRevenue >= 1000000 && acc.AnnualRevenue !=  oldAcc.AnnualRevenue){
                acc.Industry = 'Banking';
                updatedAccount.add(acc);
            }
        }
        if(!updatedAccount.isEmpty()){
            update updatedAccount;
        }
    }
    	
}