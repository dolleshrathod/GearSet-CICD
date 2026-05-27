// Whenever a new Account is created , automatically populate the 
// Description field with welcome Message
trigger AccountTrigger on Account (before insert,before update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            AccountTriggerHandler.beforeInsert(Trigger.New);
            
        }
        if(Trigger.isUpdate){
            AccountTriggerHandler.afterUpdateAnnualRevenue(Trigger.New,Trigger.oldMap);
        }
    }

    if(Trigger.isAfter){
        if(Trigger.isUpdate){
			AccountTriggerHandler.afterUpdate(Trigger.New,Trigger.oldMap);
            AccountTriggerHandler.afterUpdateAnnualRevenue(Trigger.New,Trigger.oldMap);
        }
    }
}