#based on 151029XBeePNPDBRMNCPostgreSQL
import serial
import time
import array

import psycopg2
from psycopg2.extensions import adapt, register_adapter, AsIs
import datetime
import time
import random

class Node:
    """A node information class has basic info of a XBee node."""
    count = 0 #class variable
    orderOfArrivalCount = 0


    def __init__(self, _id, _src16addr, _src64addrH, _src64addrL, _type, _orderOfArrival): #constructor
        print "create new instance of Node class"
        Node.count += 1 #count up sum of the all instance of Node class
        self.id = _id
        self.src16addr = _src16addr
        self.src64addrH = _src64addrH
        self.src64addrL = _src64addrL
        self.type = _type
        self.updateCount = 1
        self.updateTime = time.localtime()
        self.orderOfArrival = _orderOfArrival

    def update(self, _src16addr, _orderOfArrival):
        print "update node info"
        self.src16addr = _src16addr
        self.updateCount += 1
        self.updateTime = time.localtime()
        self.orderOfArrival = _orderOfArrival


    def printNodeInfo(self):
        print "[id 16adr 64adrH 64adrH type udCount udTime arrival]"
        print " = [", self.id, hex(self.src16addr), hex(self.src64addrH), hex(self.src64addrL), hex(self.type), \
        self.updateCount, time.strftime("%a,%d %b %Y %H:%M:%S", self.updateTime), self.orderOfArrival, "]"

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

    print "===> send", length, "bytes data", payLoad
    print "     hex:",
    for i in sendPacket:
        print hex(ord(i)),
    print ""

    return sendPacket

def atCommandPacket(atCommand, parameterValue): #Frame type = 0x08
    length = 1 + 1 + 2 + len(parameterValue)

    frameData = chr(0x08) #frameType
    frameData += chr(0x01) #frameID

    frameData += atCommand #at command

    if(parameterValue != ""):
        frameData += chr(parameterValue)

    checksum = 0 #checksum calculation
    for i in frameData:
        checksum += ord(i)
    checksum = 0xFF - ord(chr(checksum % 256))
    # print "checksum:", checksum

    tempPacket = chr((length / 256) % 256) + chr(length % 256) + frameData + chr(checksum)

    sendPacket = chr(0x7E)
    for i in tempPacket:
        sendPacket += chrWithEscape(ord(i))

    print "===> send:", atCommand 
    print "     hex:", 
    for i in sendPacket:
        print hex(ord(i)),
    print ""

    return sendPacket

def makeHoppingPacketFromNodeID(nodeIDs, payload): #making hopping packet by nodeID
    print "make hopping packet: "
    packet = chr(0xf0)
    packet += chr(len(nodeIDs) + 48)
    packet += chr(len(nodeIDs) + 48)
    for tempid in nodeIDs:
        for tempNodeClass in nodeClassList:
            # print "tempid", tempid, " tempNodeClass.id", tempNodeClass.id
            if(tempid == tempNodeClass.id): #if the node already exists, update node
                print "-->", tempid,
                dst64addrL = tempNodeClass.src64addrL
                sp4 = chr(dst64addrL % 256) #dst64addr Low
                dst64addrL = dst64addrL / 256
                sp3 = chr(dst64addrL % 256)
                dst64addrL = dst64addrL / 256
                sp2 = chr(dst64addrL % 256)
                dst64addrL = dst64addrL / 256
                sp1 = chr(dst64addrL % 256)

                packet += sp1 + sp2 + sp3 + sp4

                break;
        else:
            print "Oh ... (a) node(s) not found"
            return ""
    print ""
    return packet + payload

if __name__ == "__main__":
    #database intialization <===
    print "database initialization start"

    conn = psycopg2.connect(host="localhost", database="testdb", user="postgres", password="mypgsql")
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS xbeetest")
    cur.execute("CREATE TABLE xbeetest \
        (id text PRIMARY KEY, src16addr integer, src64addrh integer, src64addrl integer, \
            type integer, updatecount integer, updatetime timestamp, orderofarrival integer);")
    conn.commit()
    cur.close()
    
    print "database initialization end"
    #===>database

    #serial port initialization <===
    print "serial port initialization start"

    port = 'COM40'
    port = 'COM20'
    serialPort = serial.Serial(port, 9600, timeout = 1)
    print port + " is opend"

    time.sleep(2) #wait for establishing stable serial connection

    nodeClassList = []

    nodeClassList.append(Node("lo", 0, 0, 0, -1, 0))
    nodeClassList[0].updateCount = 0

    #insert data to the database <===
    cur = conn.cursor()
    cur.execute("INSERT INTO xbeetest (id, src16addr, src64addrh, src64addrl, type,\
        updatecount, updatetime, orderofarrival) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)", \
    ["lo", 0, 0, 0, -1, 0, datetime.datetime.now().strftime( '%Y-%m-%d %H:%M:%S' ), 0])
    conn.commit()
    cur.close()
    #===> insert data to the database

    serialPort.write(atCommandPacket("SH", "")) #check local information
    serialPort.write(atCommandPacket("SL", ""))
    serialPort.write(atCommandPacket("MY", ""))
    serialPort.write(atCommandPacket("ND", "")) ##firstly ND command executed to search nodes

    time.sleep(5)

    print "serial port initialization end"
    #===> serial port 

    #main loop
    beforeTime = time.time()
    while time.time() - beforeTime < 100:
        if serialPort.inWaiting() > 0:
            var = readSerial(serialPort)
            if(var == 0x7E):
                frameData = []
                frameData.append(var)

                frameData.append(readSerial(serialPort))
                frameData.append(readSerial(serialPort))
                frameLength = frameData[1] * 256 + frameData[2]
                print "<=== received hex:", hex(var), hex(frameData[1]), hex(frameData[2]),

                counter = 0
                checksumsum = 0
                while counter < frameLength + 1:
                    var = readSerial(serialPort)
                    frameData.append(var)
                    checksumsum += var
                    print hex(var),
                    counter += 1
                print ""

##                print "frameLength:", frameLength,
##                print "frameData:", frameData
##                print "checksumsum:", hex(checksumsum)

                frameType = frameData[3]
                print "frameType:", hex(frameType)

                if(frameType == 0x88): #AT command Response
                    FrameID = frameData[4]
                    ATcommand = chr(frameData[5]) + chr(frameData[6])
                    commandStatus = frameData[7]
                    print "FrameID:", hex(FrameID), 
                    print "ATcommand:", ATcommand, 
                    print "commandStatus:", commandStatus
                    if(commandStatus != 0x0):
                        print "AT command is invalid"
                        continue
               
                    if(ATcommand[0] == 'N' and ATcommand[1] == 'D'): #ND command response
                        src16addr = frameData[8] * 256 + frameData[9]
                        src64addrH = 0
                        for i in range(0,4):
                            src64addrH += frameData[i + 10] * pow(256,(3 - i))
                        src64addrL = 0
                        for i in range(0,4):
                            src64addrL += frameData[i + 14] * pow(256,(3 - i))
                        sh = frameData[18]
                        sl = frameData[19]
                        networkAddr = frameData[20] * 256 + frameData[21]
                        deviceType = frameData[22]
                        statusOfDevice = frameData[23]
                        profileId = frameData[24] * 256 + frameData[25]
                        manufacuturerId = frameData[26] * 256 + frameData[27]
##                        print "src16addr: ", hex(src16addr)
##                        print "src64addrH: ", hex(src64addrH)
##                        print "src64addrL: ", hex(src64addrL)
##                        print "networkAddr: ", hex(networkAddr)
##                        print "deviceType: ", hex(deviceType)
                        
                        Node.orderOfArrivalCount += 1

                        for tempNode in nodeClassList:
                            if(src64addrL == tempNode.src64addrL): #if the node already exists, update node
                                tempNode.update(src16addr, Node.orderOfArrivalCount)
                                tempNode.printNodeInfo()

                                #update data on database <===
                                cur = conn.cursor()
                                cur.execute("UPDATE xbeetest SET src16addr=%s, updatecount=%s, updatetime=now(), \
                                    orderofarrival=%s WHERE src64addrl=%s", [src16addr, tempNode.updateCount, Node.orderOfArrivalCount,\
                                    tempNode.src64addrL])
                                conn.commit()
                                cur.close()
                                #===> update data

                                break;
                        else: #No node is found, create new instance of node class
                            tempNode = Node("n" + str(Node.count), src16addr, src64addrH, src64addrL, deviceType, Node.orderOfArrivalCount)
                            tempNode.printNodeInfo()
                            nodeClassList.append(tempNode)

                            #insert data to the database <===
                            cur = conn.cursor()
                            cur.execute("INSERT INTO xbeetest (id, src16addr, src64addrh, src64addrl, type,\
                                updatecount, updatetime, orderofarrival) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)", \
                            ["n" + str(Node.count - 1), src16addr, src64addrH, src64addrL, deviceType, tempNode.updateCount, \
                            datetime.datetime.now().strftime( '%Y-%m-%d %H:%M:%S' ), Node.orderOfArrivalCount])
                            conn.commit()
                            cur.close()
                            #===> insert data to the database


                    elif(ATcommand[0] == 'S' and ATcommand[1] == 'H'): # SH command response
                        local64addrH = 0
                        for i in range(0,4):
                            local64addrH += frameData[i + 8] * pow(256,(3 - i))
                        nodeClassList[0].src64addrH = local64addrH
                        #update data on database <===
                        cur = conn.cursor()
                        cur.execute("UPDATE xbeetest SET src64addrh=%s, updatetime=now() WHERE id=%s", \
                            [local64addrH, "lo"])
                        conn.commit()
                        cur.close()
                        #===> update data


                    elif(ATcommand[0] == 'S' and ATcommand[1] == 'L'): # SL command response
                        local64addrL = 0
                        for i in range(0,4):
                            local64addrL += frameData[i + 8] * pow(256,(3 - i))
                        nodeClassList[0].src64addrL = local64addrL
                        #update data on database <===
                        cur = conn.cursor()
                        cur.execute("UPDATE xbeetest SET src64addrl=%s, updatetime=now() WHERE id=%s", \
                            [local64addrL, "lo"])
                        conn.commit()
                        cur.close()
                        #===> update data

                    elif(ATcommand[0] == 'M' and ATcommand[1] == 'Y'): # MY command response
                        local16addr = frameData[8] * 256 + frameData[9]
                        nodeClassList[0].update(local16addr, 0)
                        nodeClassList[0].printNodeInfo()
                        #update data on database <===
                        cur = conn.cursor()
                        cur.execute("UPDATE xbeetest SET src16addr=%s, updatetime=now(), updatecount=%s\
                         WHERE id=%s", [local16addr, nodeClassList[0].updateCount, "lo"])
                        conn.commit()
                        cur.close()
                        #===> update data

                    elif(ATcommand[0] == 'D' and ATcommand[1] == 'B'): # DB command response
                        rawDBvalue = frameData[8]
                        print "rawDBvalue: ", hex(rawDBvalue), "...-", rawDBvalue, "dBm"                        

                elif(frameType == 0x8B): #ZigBee Transmit Status
                    print "ZigBee Transmit Status"
                    frameId = frameData[4]
                    dst16addr = frameData[5] * 256 + frameData[6]
                    transmitRetryCount = frameData[7]
                    deliveryStatus = frameData[8]
                    discoveryStatus = frameData[9]
                    print "frameId:", frameId, "dst16addr:", hex(dst16addr), "transmitRetryCount:", transmitRetryCount, "deliveryStatus:", deliveryStatus, "discoveryStatus:", discoveryStatus

                elif(frameType == 0x90): #ZigBee Receive Packet Response
                    print "ZigBee Receive Packet"
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


        else:
            var = raw_input("Type command:")
            if(var == "ND"):
                Node.orderOfArrivalCount = 0
                serialPort.write(atCommandPacket("ND", ""))
                # temp = chr(0x7E) + chr(0x00) + chr(0x04) + chr(0x08) + chr(0x01) + chr(0x4E) + chr(0x44) + chr(0x64)
##                temp = "\x7E\x00\x04\x08\x01\x4E\x44\x64"
                time.sleep(5)
            elif(var == "lo"):
                serialPort.write(atCommandPacket("SH", "")) #check local information
                serialPort.write(atCommandPacket("SL", ""))
                serialPort.write(atCommandPacket("MY", ""))
                time.sleep(1)
            elif(var == "DB"):
                serialPort.write(atCommandPacket("DB", ""))
                time.sleep(1)
            elif(var == "MY"):
                serialPort.write(atCommandPacket("MY", ""))
                time.sleep(1)
            elif(len(var) == 1 and ord('0') <= ord(var) and ord(var) < ord('0') + Node.count):
                temp = makeZigBeeTransmitRequestPacket(nodeClassList[ord(var) - 48].src64addrH, \
                    nodeClassList[ord(var) - 48].src64addrL, 0xFFFE, 
                    makeHoppingPacketFromNodeID(['lo'], "Hello " + nodeClassList[ord(var) - 48].id)) #echo back
                serialPort.write(temp)
                time.sleep(1)
                serialPort.write(atCommandPacket("DB",""))
            elif(var == "broadcast"):
                temp = makeZigBeeTransmitRequestPacket(0x00000000, 0x0000FFFF, 0xFFFE, "broadcast test packet")
                serialPort.write(temp)
                time.sleep(1)
            elif(var == "test"): #test all alive nodes
                tempIdList = []
                for tempNodeClass in reversed(nodeClassList):
                    tempIdList.append(tempNodeClass.id)
                temp = makeZigBeeTransmitRequestPacket(nodeClassList[1].src64addrH, \
                    nodeClassList[1].src64addrL, 0xFFFE, \
                    makeHoppingPacketFromNodeID(tempIdList, "Hopping function test"))
                serialPort.write(temp)
                time.sleep(1)
            elif(var == "printNode"):
                print "===== nodeClassList ====="
                for value in nodeClassList:
                    value.printNodeInfo()
            elif(var == "exit"):
                break
            else:
                print "invalid command input"

    serialPort.close()
    print port + " is closed"