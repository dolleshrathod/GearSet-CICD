global class Vehicle {
	//Properties
	Public Integer numOfWheel;
    Public String Company;
	Public String model;
	Public Integer mfgYear;
    Public Integer doors;
	
	//Methods
    public Void display(){
        System.debug('Vehicle Details ----> Number of wheels '+numOfWheel+ ' Company =>'+Company+
						' Model => '+model + ' MFG Year => '+mfgYear+ ' Num Of Doors => '+doors );
    }

    Public String display(String Message){
        return Message;
    }
    	
}