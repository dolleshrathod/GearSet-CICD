public class ContactOutboundServices {
	@future(callout = true)
    public static void sendContactData(Id ContactId){
        Contact con = [SELECT ID, FirstName, LastName, Email FROM Contact WHERE Id =: ContactId LIMIT 1];
			
		Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://webhook.site/cc83d4fd-cce6-45f1-8d1d-45b489cbfb59');
		req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        
        Map<String,Object> data = new Map<String,Object>();
		data.put('First Name',con.FirstName);
		data.put('Last Name',con.LastName);
        data.put('Email',con.Email);
        
        req.setBody(JSON.serialize(data));
        
        HttpResponse res = http.send(req);
        
        System.debug('Response : '+ res.getBody());
        
        
    }
}