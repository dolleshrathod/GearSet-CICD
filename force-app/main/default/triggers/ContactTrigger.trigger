// CReate a Trigger on Contact that fires on before insert, before update 
// On Insert if the FirstName of Contact is Blank we have to set its value to "Unknown"
trigger ContactTrigger on Contact (after insert) {
    for(Contact con : Trigger.new){
        ContactOutboundServices.sendContactData(con.Id);
    }    
}