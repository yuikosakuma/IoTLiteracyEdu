# IoT Literacy Education
This project intends to educate "IoT literacy" with Arduino, Processing, and Python.  
Components are ...  
Programs are based on XMASS projects by TadaMatz.

* Arduino  
	- mote
	- XBee Router
* Python
	- Controller for XBee 
	- XBee Coordinator
* Processing
	- Visualizer

## 勉強の手順

1. Arduinoのノードを作り、スタンドアローンで試す
2. XBeeの設定
	1. XBeeにテプラでIDを貼り、アドレスとの対応をメモっておく
	2. X-CTUのインストール
	3. X-CTUでFirmwareの設定(CoordinatorやRouter, PAN ID, API enable = 2)
4. XBeeの通信テスト
	1. 送信はArduinoプログラム（送信アドレスを合わせること）
	2. 受信
		1. X-CTUでやってみる
		3. Pythonでやってみる（Serialライブラリを使う）
3. Databaseの構築
	1. PostgreSQL、pgAdminのインストール
	2. テーブルを構築（flagtest, connectiontest）カラムもつくる
3. PythonによるDatabase操作を試す
4. センサデータを定期的にXBeeで送信し、Pythonで受信してDatabaseに蓄える
5. ProcessingによるDatabase操作を試す
6. ProcessingでDatabaseを読み、データを視覚化する

## Preparation
PostgreSQL must be installed. (Installation guide in Japanese: [http://www.dbonline.jp/postgresinstall/](http://www.dbonline.jp/postgresinstall/))  
PostgreSQL Server should be configurated  
Following 2 tables must be configurated. Please refer to ```sql/setup.sql``` also.    
Install `psycopg2` for python.

* connectiontest
	- nodeid(Primary key, Integer), xbeeaddr(Integer), temperature(Numeric), destinationid(Integer), votedcounter(Integer), name(text), lastupdate(Timestamp without time zone), sendflag(Integer), volume(Integer)
* flagtest
	- flagid(Primary key, Integer), name(Text), value(Integer), angle(Integer), led(Integer)

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
Then you should be able to use BezierSQLib with Processing-3.

XBee must be API mode with escaping (API=2)  
Use XBee-Arduino library as "XBee" [https://github.com/andrewrapp/xbee-arduino](https://github.com/andrewrapp/xbee-arduino) and put this in the same directory

version1 uses "dip switch array", version2 uses "volume" for application 

### version1
### data packet payload
UplinkHeader : 'U'  
DownlinkHeader : 'D' 

#### Uplink : End device to Coodrinator
Unicast to Coordinator  
{UplinkHeader(1B,[0]), ID(1B,[1]), Temperature(4B,[2~5]), destinationID(1B,[6]), name(0 ~ 10B, [7~])} (7 ~ 17 bytes in total)  
Temperature is multiplied by 10, in example, "25.3C" is sent like "0253". In the same way, "9.3C" is sent as "0093".

#### Downlink : Coordinator to End device
Broadcast  
{DownlinkHeader(1B,[0]), votedCounter for ID:1(1B,[1]), voteCounter for ID:2(1B,[2]), ... , votedCounter of ID:20(1B,[20])} (21 bytes in total)  
Ex. "0123456789:;<=>?@ABC"  
value = (int)id + '0' (0x48)

### version2
### data packet payload
UplinkHeader : 'U'  
DownlinkHeader : 'D'  
LED\_INSTRUCTION : 'L'  
SERVO\_INSTRUCTION : 'S'  

#### Uplink : End device to Coodrinator
Unicast to Coordinator  
{UplinkHeader(1B,[0]), ID(1B,[1]), Temperature(4B,[2~5]), volume(4B,[6~9]), name(0 ~ 10B, [10~])} (10 ~ 20 bytes in total)  
Temperature is multiplied by 10, in example, "25.3C" is sent like "0253". In the same way, "9.3C" is sent as "0093".
Volume is supposed to have the raw value of analogRead() of Arduino (0 ~ 1024)

#### Downlink : Coordinator to End device
Broadcast  
value in flagtest table, 1 for LED, 2 for Servo  
packet for LED controll:  
{DownlinkHeader(1B,[0]), LED\_INSTRUCTION(1B, [1]), ON/OFF(1B, [2]} (3 bytes in total)  
Ex. "DL1"  
1 for ON, 0 for OFF
packet for LED controll:  
{DownlinkHeader(1B,[0]), SERVO\_INSTRUCTION(1B, [1]), Angle(3B, [2~4]} (5 bytes in total)  
Ex. "DS104"  
The value of angle should be from 0 ~ 179

## 勉強にあたり詰まったところ
### 手順４
- 受信用に設定したXBeeとArduino上の送信用に設定したXBeeの両方で通信する
- pgadmin3はno longer supportedだそうなのでpgadmin4をダウンロード
- コンパイル時のエラー
　connectiontestの列volumeとlastupdateは存在しないので表に追加
 追加してみるとlastupdateの型timestamp without time zoneは選択できなかったので消してしまいました...
