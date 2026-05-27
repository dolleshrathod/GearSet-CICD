trigger LeadTrigger on Lead (after insert) {
	LeadTriggerHandler.createTask(Trigger.new);
}