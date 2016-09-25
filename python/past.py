#based on 160419TSIBPXMASSControllerBatteryRefineOverlapSaveDataAll

import serial
import time
import array
import sys

import psycopg2
from psycopg2.extensions import adapt, register_adapter, AsIs
import datetime
import random

def readSerial(ser): #can process the Escape mode API = 2
    var = ord(ser.read())
    if(var == 0x7D):
        var = ord(ser.read()) ^ 0x20
    return var

def chrWithEscape(value):
    var = chr(value)
    if(value == 0x7E or value == 0x7D or value == 0x11 or value == 0x13):
        var = chr(0x7D) + chr(value ^ 0x20)
    return var

def makeHoppingPacketFromNodeAddress(header, addrs, payload): #making hopping packet by nodeID
    # print "make hopping packet: ",
    packet = chr(header)
    packet += chr(len(addrs) + 48 - 2)
    packet += chr(len(addrs) + 48)
    for tempAddr in addrs:
        sp4 = chr(tempAddr % 256) #dst64addr Low
        tempAddr = tempAddr / 256
        sp3 = chr(tempAddr % 256)
        tempAddr = tempAddr / 256
        sp2 = chr(tempAddr % 256)
        tempAddr = tempAddr / 256
        sp1 = chr(tempAddr % 256)
        packet += sp1 + sp2 + sp3 + sp4
    # print ""
    return packet + payload

def makeHoppingPacketFromNodeID(header, nodeIDs, payload): #making hopping packet by nodeID
    print "make hopping packet: ",
    packet = chr(header)
    packet += chr(len(nodeIDs) + 48 - 2)
    packet += chr(len(nodeIDs) + 48)
    for tempid in nodeIDs:
        print "-->", tempid,
        tempAddr = addrDict[tempid]
        sp4 = chr(tempAddr % 256) #dst64addr Low
        tempAddr = tempAddr / 256
        sp3 = chr(tempAddr % 256)
        tempAddr = tempAddr / 256
        sp2 = chr(tempAddr % 256)
        tempAddr = tempAddr / 256
        sp1 = chr(tempAddr % 256)

        packet += sp1 + sp2 + sp3 + sp4
    print ""
    return packet + payload

def makeZigBeeTransmitRequestPacket(dst64addrH, dst64addrL, dst16addr, payLoad): #Frame type = 0x10 packet sender
    length = 1 + 1 + 8 + 2 + 1 + 1 + len(payLoad)

    frameData = chr(0x10) #frameType
    frameData += chr(0x01) #frameID

    sp8 = chr(dst64addrH % 256) #dst64addr High
    dst64addrH = dst64addrH / 256
    sp7 = chr(dst64addrH % 256)
    dst64addrH = dst64addrH / 256
    sp6 = chr(dst64addrH % 256)
    dst64addrH = dst64addrH / 256
    sp5 = chr(dst64addrH % 256)

    sp12 = chr(dst64addrL % 256) #dst64addr Low
    dst64addrL = dst64addrL / 256
    sp11 = chr(dst64addrL % 256)
    dst64addrL = dst64addrL / 256
    sp10 = chr(dst64addrL % 256)
    dst64addrL = dst64addrL / 256
    sp9 = chr(dst64addrL % 256)

    frameData += sp5 + sp6 + sp7 + sp8 + sp9 + sp10 + sp11 + sp12

    frameData += chr((dst16addr / 256) % 256) #dst16addr
    frameData += chr(dst16addr % 256)

    frameData += chr(0x00) #Broadcast radius
    frameData += chr(0x00) #options

    frameData += payLoad #data payload

    checksum = 0 #checksum calculation
    for i in frameData:
        checksum += ord(i)
    checksum = 0xFF - ord(chr(checksum % 256))
    # print "checksum:", checksum

    tempPacket = chr((length / 256) % 256) + chr(length % 256) + frameData + chr(checksum)

    sendPacket = chr(0x7E)
    for i in tempPacket:
        sendPacket += chrWithEscape(ord(i))

    print "===> send", length, "bytes data. Data: ", payLoad
    # print "     hex:",
    # for i in sendPacket:
    #     print hex(ord(i)),
    # print ""

    return sendPacket

def extractAddrFromReceivePayload(tempPayload):
    allHop = tempPayload[2]
    returnAddr = []
    for j in range (0, allHop - 48): #/ tempPayload: addrA, addrB, addrC ===> sendPayload: addrC, addrB, addrA
        tempAddr = tempPayload[3 + 4 * j] * 256 * 256 * 256\
            + tempPayload[4 + 4 * j] * 256 * 256\
            + tempPayload[5 + 4 * j] * 256\
            + tempPayload[6 + 4 * j]
        returnAddr.append(tempAddr)
        # print "tempAddr", str(hex(tempAddr))
        # print "returnAddr[", str(j), "]: ", str(hex(returnAddr[j]))                             
    return returnAddr

def makeResponceSynchroPayload(serverAveTime, routeId, wakeUpTime, sleepTime):
    payload = 'R'
    payload += '%010d' % int(serverAveTime)
    #add wakeuptime
    payload += chr(routeId)
    payload += '%010d' % wakeUpTime
    #add sleep time 
    payload += chr(routeId)
    payload += '%010d' % sleepTime
    return payload

def getRouteIdFromAddress(tempAddr, addrs):
    for i in range(0, len(addrs)):
        if addrs[i] == tempAddr:
            return i
            break
    else:
        print "I cannot find the tempAddr in my list"
        return -1


if __name__ == "__main__":
    #database intialization <===
    print "database initialization start"
    conn = psycopg2.connect(host="localhost", database="ECORS_DEMO", user="postgres", password="mypgsql")
    # conn = psycopg2.connect(host="10.24.10.95:5432", database="ECORS_DEMO", user="postgres", password="mypgsql")
    cur = conn.cursor()
    cur.execute("UPDATE node SET visible=0")
    conn.commit()
    cur.close()
    print "database initialization end"
    #===>database

    #serial port initialization <===
    print "serial port initialization start"
    port = '/dev/ttyUSB0' #XBee Explorer via USB that is for raspberry pi
    # port = 'COM81' #XBee Explorer
    # serialPort = serial.Serial(port, 9600, timeout = 1)
    serialPort = serial.Serial(port, 115200, timeout = 1)
    print port + " is opend"
    time.sleep(2) #wait for establishing stable serial connection
    print "serial port initialization end"
    #===> serial port 

    #get addrDict from xbeeid table in DB
    print "addrDict initialization start"
    addrDict = {}
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) from xbeeid")
    num = cur.fetchone()[0]
    cur.close()
    for i in range(0, num):
        cur = conn.cursor()
        cur.execute("SELECT src64addrl from xbeeid WHERE nodeid=%s", [i])
        tempAddr =  cur.fetchone()[0]
        addrDict[i] = tempAddr
        cur.close()
    for i in range(0, len(addrDict)):
        print i, hex(addrDict[i])
    print "addrDict initialization end"

    #prepare route used in real network
    print "currentRoutes initialization start"
    currentRoutes = {} #set of allroutes is stored
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) from route")
    num = cur.fetchone()[0]
    cur.close()
    for i in range(0, num):
        cur = conn.cursor()
        cur.execute("SELECT route FROM route WHERE routeid=%s", [i])
        tempRoute = cur.fetchone()
        tempRoute = [int(item) for item in tempRoute[0].split(",")]
        currentRoutes[i] = tempRoute
        cur.close()
    for i in range(0, len(currentRoutes)):
        print currentRoutes[i]
    print "currentRoutes initialization end"

    pastSecond = time.time() - 15 # to send command firstly

    pastSeconds = [time.time()] * len(addrDict)
    wakeUpTimes = [int(time.time() * 10)] * len(addrDict)
    sleepTimes = [int(time.time() * 10)] * len(addrDict)
    sPacketCatchFlag = [False] * len(addrDict)

    beforeSecond = time.time()
    serialPastSecond = time.time()
    senoSecond = time.time()
    sleepSecond = time.time()
    sleepFlag = False
    wakeUpPastMillis = time.time()

    loopCounter = 1
    phase = 0 # 0 : Route Notification, 1 : Data Aggregation
    currentRouteId = 1 #routeId is corresponding to sensorId
    intervalOfRouteSelection = 3
    routeNotificationPhaseInterval = 60 #sec
    routeNotificationSkipCounter = 0
    skipNumber = 1 #if send 3 'Q' packet to node and no responces, then go to next node
    routeNotificationSendInterval = 1 #sec
    dataAggregationWakeUpInterval = 7 #sec
    dataAggregationSendInterval = 1 #sec
    dataAggregationOverlapInterval = 3 #sec
    
    #initialization
    notificationStartSecond = time.time() - beforeSecond
    notificationFinishFlag = False
    loopStartSecond = time.time()
    for i in range(0, len(addrDict)):
        sleepTimes[i] = int((time.time() - beforeSecond + routeNotificationPhaseInterval) * 10)
        wakeUpTimes[i] = sleepTimes[i] + (i - 1) * dataAggregationWakeUpInterval * 10 - dataAggregationOverlapInterval * 10
        print str(i), str(sleepTimes[i]),  str(wakeUpTimes[i])
        # wakeUpTimes[i] = sleepTimes[i] + (i - 1) * dataAggregationWakeUpInterval * 10

    #database initialization
    cur = conn.cursor()
    cur.execute("UPDATE currentinfo SET time=%s, loopcounter=%s, currentrouteid=%s, phase=%s, intervalofrouteselection=%s, routenotificationphaseinterval=%s,  \
        skipnumber=%s, routenotificationsendinterval=%s, dataaggregationwakeupinterval=%s, dataaggregationsendinterval=%s, dataaggregationoverlapinterval=%s\
        WHERE id=0", [int((time.time() - beforeSecond)*10) , loopCounter, currentRouteId, phase,\
        intervalOfRouteSelection, routeNotificationPhaseInterval, skipNumber, routeNotificationSendInterval,\
        dataAggregationWakeUpInterval, dataAggregationSendInterval, dataAggregationOverlapInterval])
    conn.commit()
    cur.close()
    for i in range(0, len(addrDict)):
        cur = conn.cursor()
        cur.execute("UPDATE node SET time=%s, loopcounter=%s, currentrouteid=%s \
        WHERE node.nodeid=%s", [int((time.time() - beforeSecond)*10) , loopCounter, currentRouteId, i])
        conn.commit()
        cur.close()

    #main loop
    try:
        while time.time() - beforeSecond < 60 * 60 * 3: #escaping time to avoid serial port monopoly
            if time.time() - serialPastSecond > 1.0:
                serialPastSecond = time.time()
                print "time %0.1f RouteId %d loop %d phase %d" % (time.time() - beforeSecond, currentRouteId, loopCounter, phase)

                cur = conn.cursor()
                cur.execute("UPDATE currentinfo SET time=%s, loopcounter=%s, currentrouteid=%s, phase=%s \
                WHERE id=0", [int((time.time() - beforeSecond)*10) , loopCounter, currentRouteId, phase])
                conn.commit()
                cur.close()
            
            # phase processing
            if phase == 0:
                if time.time() - beforeSecond - notificationStartSecond > routeNotificationPhaseInterval: #go to aggregatin phase
                    print "----- NOW move to Data Aggregation Phase -----"
                    if notificationFinishFlag:
                        notificationFinishFlag = False
                    currentRouteId = 1
                    wakeUpPastMillis = time.time()
                    for i in range(0, len(addrDict)):
                        sleepTimes[i] = wakeUpTimes[i] + dataAggregationWakeUpInterval * 10 + dataAggregationOverlapInterval * 10
                        wakeUpTimes[i] = sleepTimes[i] + dataAggregationWakeUpInterval * (len(addrDict) - 2) * 10 - dataAggregationOverlapInterval * 10
                        sPacketCatchFlag[i] = False
                        
                        cur = conn.cursor()
                        cur.execute("UPDATE node SET visible=%s \
                        WHERE node.nodeid=%s", [int(sPacketCatchFlag[i]) ,i])
                        conn.commit()
                        cur.close()

                        print str(i), str(sleepTimes[i]),  str(wakeUpTimes[i])
                    phase = 1
                else:
                    if not notificationFinishFlag:
                        if sPacketCatchFlag[currentRouteId]:
                            # sPacketCatchFlag[currentRouteId] = False
                            currentRouteId += 1
                            if currentRouteId >= len(addrDict):
                                currentRouteId = 1
                                # notificationFinishFlag = True
                                # print "all notification done. go to data aggregation phase"
                        else:
                            if time.time() - pastSecond > routeNotificationSendInterval:
                                pastSecond = time.time()

                                temp = makeZigBeeTransmitRequestPacket(0x0013A200, addrDict[currentRoutes[currentRouteId][1]], 0xFFFE, \
                                    makeHoppingPacketFromNodeID(0xf4, currentRoutes[currentRouteId], "Q"))
                                serialPort.write(temp) 

                                routeNotificationSkipCounter += 1
                                if routeNotificationSkipCounter >= skipNumber:
                                    print "~_~_~_~_~_~_ skip this route[%d]!! next time!! _~_~_~_~_~_~" % currentRouteId
                                    routeNotificationSkipCounter = 0
                                    currentRouteId += 1
                                    if currentRouteId >= len(addrDict):
                                        currentRouteId = 1

            elif phase == 1:
                if time.time() - wakeUpPastMillis > dataAggregationWakeUpInterval:
                    wakeUpPastMillis = time.time()
                    currentRouteId += 1
                    print "----> next route: %d <-----" % currentRouteId
                    if currentRouteId >= len(addrDict):
                        currentRouteId = 1
                        loopCounter += 1
                        loopStartSecond = time.time()

                        for i in range(0, len(addrDict)):
                            sPacketCatchFlag[i] = False
                            cur = conn.cursor()
                            cur.execute("UPDATE node SET visible=%s \
                            WHERE node.nodeid=%s", [int(sPacketCatchFlag[i]) ,i])
                            conn.commit()
                            cur.close()

                        print "-=-=-=-=-= loop %d " % loopCounter,

                        if loopCounter % intervalOfRouteSelection == intervalOfRouteSelection - 1:
                            print " NEXT: move to Route Notification phase =-=-=-=-=-=-"
                            for i in range(0, len(addrDict)): # define next sleep and wakeup time
                                sleepTimes[i] = wakeUpTimes[i] + dataAggregationWakeUpInterval * 10 + dataAggregationOverlapInterval * 10
                                wakeUpTimes[i] = sleepTimes[i] + (len(addrDict) - 1 - i) * dataAggregationWakeUpInterval * 10 #wakeup at the same time
                                print str(i), str(sleepTimes[i]),  str(wakeUpTimes[i])
                        elif loopCounter % intervalOfRouteSelection == 0:
                            print " NOW!: move to Route Notification phase =-=-=-=-=-=-"
                            for i in range(0, len(addrDict)):
                                sleepTimes[i] = wakeUpTimes[i] + routeNotificationPhaseInterval * 10
                                wakeUpTimes[i] = sleepTimes[i] + (i - 1) * dataAggregationWakeUpInterval * 10 - dataAggregationOverlapInterval * 10
                                print str(i), str(sleepTimes[i]),  str(wakeUpTimes[i])
                            notificationStartSecond = time.time() - beforeSecond

                            #change routes
                            print "-=-=-=-=-=-= change currentRoutes from DB=-=-=-=-=-=-"
                            #prepare route used in real network
                            print "currentRoutes update start"
                            currentRoutes = {} #set of allroutes is stored
                            cur = conn.cursor()
                            cur.execute("SELECT COUNT(*) from route")
                            num = cur.fetchone()[0]
                            cur.close()
                            for i in range(0, num):
                                cur = conn.cursor()
                                cur.execute("SELECT route FROM route WHERE routeid=%s", [i])
                                tempRoute = cur.fetchone()
                                tempRoute = [int(item) for item in tempRoute[0].split(",")]
                                currentRoutes[i] = tempRoute
                                cur.close()
                            for i in range(0, len(currentRoutes)):
                                print currentRoutes[i]
                            print "currentRoutes update end"
                            phase = 0
                        else:
                            print " =-=-=-=-=-"
                            for i in range(0, len(addrDict)):
                                sleepTimes[i] = wakeUpTimes[i] + dataAggregationWakeUpInterval * 10 + dataAggregationOverlapInterval * 10
                                wakeUpTimes[i] = sleepTimes[i] + dataAggregationWakeUpInterval * (len(addrDict) - 2) * 10 - dataAggregationOverlapInterval * 10
                                print str(i), str(sleepTimes[i]),  str(wakeUpTimes[i])


                elif not sPacketCatchFlag[currentRouteId]:
                    if time.time() - pastSecond > dataAggregationSendInterval:
                        pastSecond = time.time()
                          
                        temp = makeZigBeeTransmitRequestPacket(0x0013A200, addrDict[currentRoutes[currentRouteId][1]], 0xFFFE, \
                            makeHoppingPacketFromNodeID(0xf4, currentRoutes[currentRouteId], "Q"))
                        serialPort.write(temp)                    

            #incoming data processing when data is in serial port
            if serialPort.inWaiting() > 0:
                var = readSerial(serialPort)
                if(var == 0x7E):
                    pastMeasureTime = time.time()

                    frameData = []
                    frameData.append(var)

                    frameData.append(readSerial(serialPort))
                    frameData.append(readSerial(serialPort))
                    frameLength = frameData[1] * 256 + frameData[2]
                    # print "<=== received hex:", hex(var), hex(frameData[1]), hex(frameData[2]),

                    counter = 0
                    checksumsum = 0
                    while counter < frameLength + 1:
                        var = readSerial(serialPort)
                        frameData.append(var)
                        checksumsum += var
                        # print hex(var),
                        counter += 1
                    # print ""

    ##                print "frameLength:", frameLength,
    ##                print "frameData:", frameData
    ##                print "checksumsum:", hex(checksumsum)

                    frameType = frameData[3]
                    # print "frameType:", hex(frameType)

                    # if(frameType == 0x8B): #ZigBee Transmit Status
                    #     print "ZigBee Transmit Status"
                    #     frameId = frameData[4]
                    #     dst16addr = frameData[5] * 256 + frameData[6]
                    #     transmitRetryCount = frameData[7]
                    #     deliveryStatus = frameData[8]
                    #     discoveryStatus = frameData[9]
                    #     print "frameId:", frameId, "dst16addr:", hex(dst16addr), "transmitRetryCount:", transmitRetryCount, "deliveryStatus:", deliveryStatus, "discoveryStatus:", discoveryStatus

                    if(frameType == 0x90): #ZigBee Receive Packet Response
                        print "<=== ZigBee Receive Packet: ",
                        src64addrH = 0
                        for i in range(0,4):
                            src64addrH += frameData[i + 4] * pow(256,(3 - i))
                        src64addrL = 0
                        for i in range(0,4):
                            src64addrL += frameData[i + 8] * pow(256,(3 - i))
                        src16addr = frameData[12] * 256 + frameData[13]
                        receiveOptions = frameData[14]
                        receiveData = []
                        for i in range(15, frameLength + 3):
                            receiveData.append(frameData[i])
                        print "str(bytearray(receiveData)):", str(bytearray(receiveData))

                        payloadType = receiveData[0]

                        # print "payloadType: ", str(hex(payloadType)), "chr(payloadType): ", str(chr(payloadType))


                        if (payloadType == 0xF4): # //time synchroniztion packet
                            if receiveData[2 + (receiveData[2] - 48) * 4 + 1] == ord('S'): #this time this node become server of time
                                serverReceiveMillis = time.time() * 10 - beforeSecond * 10 #*10 for ms order. 1460443822.0 = time.mktime(time.struct_time(tm_year=2016, tm_mon=4, tm_mday=12, tm_hour=15, tm_min=50, tm_sec=17, tm_wday=1, tm_yday=103, tm_isdst=0) //20161460443662 max of 32bit = 4294967295

                                #//make return packet
                                allHop = receiveData[2]
                                
                                receiveAddr = extractAddrFromReceivePayload(receiveData) #extract addr from packet

                                # routeId = 1
                                # routeId = getRouteIdFromAddress(receiveAddr[0], addr) #in python -1 in list indicates the last index of list
                                
                                #get source node id from xbeeid DB
                                cur = conn.cursor()
                                cur.execute("SELECT xbeeid.nodeid FROM xbeeid WHERE xbeeid.src64addrl=%s",\
                                            [receiveAddr[0]])
                                routeId = cur.fetchone()[0]
                                cur.close()

                                sPacketCatchFlag[routeId] = True #flag set to true

                                receiveBatteryLevel = 0
                                for i in range(0,4):
                                    receiveBatteryLevel += (receiveData[2 + (receiveData[2] - 48) * 4 + 1 + 1 + (1 + i)] - 48) * pow(10, (3 - i)) #'S' + ',' + batteryLevel(4 digit)
                                print " routeId [%d] receiveBatteryLevel:" % routeId, receiveBatteryLevel

                                cur = conn.cursor()
                                cur.execute("UPDATE node SET batterylevel=%s, visible=%s, time=%s, loopcounter=%s, currentrouteid=%s \
                                WHERE node.nodeid=%s", [receiveBatteryLevel,int(sPacketCatchFlag[routeId]) , int((time.time() - beforeSecond)*10) , loopCounter, currentRouteId, routeId])
                                conn.commit()
                                cur.close()

                                # wakeUpTime = int(time.time() * 10 - beforeSecond * 10 + 60)
                                # sleepTime = wakeUpTime - 30
                                wakeUpTime = wakeUpTimes[routeId]
                                sleepTime = sleepTimes[routeId]

                                serverSendMillis = time.time() * 10 - beforeSecond * 10;
                                serverAverageMillis = int((serverReceiveMillis + serverSendMillis) / 2)

                                sendPayload = makeResponceSynchroPayload(serverAverageMillis, routeId, wakeUpTime, sleepTime)

                                reversedReceiveAddr = []
                                for i in reversed(receiveAddr):
                                    reversedReceiveAddr.append(i)

                                temp = makeZigBeeTransmitRequestPacket(0x0013A200, reversedReceiveAddr[1], 0xFFFE, \
                                    makeHoppingPacketFromNodeAddress(0xF4, reversedReceiveAddr, sendPayload))
                                serialPort.write(temp)
                                # time.sleep(1)

                        print "time.time() - pastMeasureTime: ", str(time.time() - pastMeasureTime)
    finally:
        serialPort.close()
        print port + " is closed"