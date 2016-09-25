#IoT Literacy Education
This project intends to educate "IoT literacy" with Arduino, Processing, and Python.  
Components are ...  
Programs are based on XMASS projects by TadaMatz.

* Arduino  
	- mote
	- XBee End-device
* Python
	- Controller for XBee 
	- XBee Coordinator
* Processing
	- Visualizer

##Preparation
PostgreSQL must be installed. (Installation guide in Japanese: [http://www.dbonline.jp/postgresinstall/](http://www.dbonline.jp/postgresinstall/))  
PostgreSQL Server should be configurated  
Following 2 tables must be configurated.  

* motedata
	- nodeid(Integer), xbeeaddr(Integer), temperature(Numeric), destinationid(Integer), votedcounter(Integer)
* flag
	- flagid(Integer), name(Text), value(Integer)

SQL handling library for Processing needs Processing-2.2.1.  

XBee must be API mode with escaping (API=2)

##data packet payload
UplinkHeader : 'U'  
DownlinkHeader : 'D'  

###Uplink : End device to Coodrinator
Unicast to Coordinator  
{UplinkHeader(1B,[0]), ID(1B,[1]), Temperature(4B,[2~5]), destinationID(1B,[6]), name(0 ~ 10B, [7~])} (7 ~ 17 bytes in total)  
Temperature is multiplied by 10, in example, "25.3C" is sent like "0253". In the same way, "9.3C" is sent as "0093".

###Downlink : Coordinator to End device
Broadcast  
{DownlinkHeader(1B,[0]), votedCounter for ID:1(1B,[1]), voteCounter for ID:2(1B,[2]), ... , votedCounter of ID:20(1B,[20])} (21 bytes in total)  
Ex. "0123456789:;<=>?@ABC"  
value = (int)id + '0' (0x48)