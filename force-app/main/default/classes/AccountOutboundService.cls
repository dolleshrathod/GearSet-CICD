public class AccountOutboundService {
	
	@future(callout=true)
  	public static void sendAccountData(Id accountId) {

       // Step 1: Fetch Account
       Account acc = [
           SELECT Id, Name, Industry, Phone
           FROM Account
           WHERE Id = :accountId
           LIMIT 1
       ];

       // Step 2: Create HTTP objects
       Http http = new Http();
       HttpRequest req = new HttpRequest();

       // Step 3: Use Named Credential
       req.setEndpoint('callout:WebHook_NC');
       req.setMethod('POST');
       req.setHeader('Content-Type', 'application/json');

       // Step 4: Prepare JSON Data
       Map<String, Object> data = new Map<String, Object>();
       data.put('Name', acc.Name);
       data.put('Industry', acc.Industry);
       data.put('Phone', acc.Phone);

       // Step 5: Convert to JSON
       req.setBody(JSON.serialize(data));

       // Step 6: Send Request
       HttpResponse res = http.send(req);

       // Step 7: Debug response
       System.debug('Response: ' + res.getBody());
   }

}