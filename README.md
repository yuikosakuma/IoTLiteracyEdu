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
Install `psycopg2` for python.

* motedata
	- nodeid(Primary key, Integer), xbeeaddr(Integer), temperature(Numeric), destinationid(Integer), votedcounter(Integer)
* flag
	- flagid(Primary key, Integer), name(Text), value(Integer)

SQL handling library for Processing needs Processing-2.2.1.  
Updated!!(2016/10/6): I found the way to use BezierSQLib in Processing-3.2.1.  
I write down the way instruction to do it here.

(It should work in other Linux, I guess. And also, once you have the new compiled library, you can just copy the library under "Processing/libraries" where other libraries in)  

Step 1. Clone (or download ZIP) the repository from [https://github.com/fjenett/sql-library-processing](https://github.com/fjenett/sql-library-processing).  
Step 2. Change two lines in `build.xml`.  

```
around #L15. adapt "location" the same place where the processing.exe is in. 
Before:
<property name="processing.classes"  
	location="/Users/fjenett/Repos/processing/build/macosx/work/Processing.app/Contents/Resources/Java/" />
After:
<property name="processing.classes"  
	location="/usr/local/lib/processing-3.2.1" /> 

around #L18. adapt "location" the same place where the other libraries is in. 
Before:
<property name="processing" location="/Users/fjenett/Documents/Processing/libraries"/>   
After:
<property name="processing" location="/home/pi/sketchbook/libraries"/>   
```  

Step 3. execute `ant` command.  
Then you should be able to import BezierSQLib on GUI.

XBee must be API mode with escaping (API=2)  
Use XBee-Arduino library as "XBee" [https://github.com/andrewrapp/xbee-arduino](https://github.com/andrewrapp/xbee-arduino) and put this in the same directory

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