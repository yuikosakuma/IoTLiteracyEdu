#based on 160419TSIBPXMASSControllerBatteryRefineOverlapSaveDataAll
#To do: handle minus value of Thermister. This program does not stop but value could be crazy

import serial
import time
import array
import sys

import psycopg2
from psycopg2.extensions import adapt, register_adapter, AsIs
import datetime
import random

ID_PACKET_OFFSET = '0'
UPLINK_HEADER = 'U'
DOWNLINK_HEADER = 'D'

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

    print "===> send", length, "bytes data. Data: ", payLoad
    # print "     hex:",
    # for i in sendPacket:
    #     print hex(ord(i)),
    # print ""

    return sendPacket

if __name__ == "__main__":
  #database intialization <===
  print "database initialization start"
  conn = psycopg2.connect(host="localhost", database="iotedu", user="postgres", password="mypgsql")
  print "database initialization end"
  #===>database
  
  #<=== Serial port initialization
  print "serial port initialization start"
  port = '/dev/ttyUSB0' #XBee Explorer via USB that is for raspberry pi
  # port = 'COM7' #XBee Explorer
  # port = 'COM17'
  serialPort = serial.Serial(port, 9600, timeout = 1)
  print port + " is opend"
  time.sleep(2) #wait for establishing stable serial connection
  print "serial port initialization end"
  #===> Serial port initialization

  #<=== initial data printing
  cur = conn.cursor()
  cur.execute("SELECT * FROM connectiontest ORDER BY nodeid")
  result = cur.fetchall()
  print result
  if result == []:
    print "oh... no data"
  else:
    print "yeah... we have data"
    for row in result:
      print row
  conn.commit()
  cur.close()  
  #===> initial data printing

  try:
    while True:
      #<=== packet receiving
      if serialPort.inWaiting() > 0: #if something is in serial port
        var = readSerial(serialPort)
        if(var == 0x7E): #and if this is the XBee packet

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

          #print "frameLength:", frameLength,
          #print "frameData:", frameData
          #print "checksumsum:", hex(checksumsum)

          frameType = frameData[3]
          # print "frameType:", hex(frameType)

          if(frameType == 0x90): #ZigBee Receive Packet Response
            #print "<=== ZigBee Receive Packet: ",
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
            #print "str(bytearray(receiveData)):", str(bytearray(receiveData))

            payloadType = receiveData[0]
            # print "payloadType: ", str(hex(payloadType)), "chr(payloadType): ", str(chr(payloadType))
            if payloadType == ord(UPLINK_HEADER) and len(receiveData) > 7:
              tmp_id = int(receiveData[1] - ord(ID_PACKET_OFFSET))
              tmp_temperature = float(receiveData[2] - ord(ID_PACKET_OFFSET)) * 100 + float(receiveData[3] - ord(ID_PACKET_OFFSET) ) * 10 + float(receiveData[4] - ord(ID_PACKET_OFFSET)) * 1 + float(receiveData[5] - ord(ID_PACKET_OFFSET)) * 0.1
              tmp_dst_id = int(receiveData[6] - ord(ID_PACKET_OFFSET))
              tmp_name = receiveData[7:len(receiveData)]
              tmp_name_str = ""
              for c in tmp_name:
                tmp_name_str += chr(c)
              
              print "len:", frameLength, "data:", str(bytearray(receiveData)).strip()
              print  "id:", tmp_id, "temp:", tmp_temperature, "d_id:", tmp_dst_id, "name:", tmp_name_str.strip()

              #update database
              cur = conn.cursor()
              cur.execute("UPDATE connectiontest SET temperature=%s, destinationid=%s, xbeeaddr=%s, name=%s, lastupdate=%s WHERE connectiontest.nodeid=%s", \
                [tmp_temperature, tmp_dst_id, src64addrL, tmp_name_str, datetime.datetime.utcnow(), tmp_id])
              conn.commit()
              cur.close()
      #===> packet receiving

      #<=== broadcast packet sending
      cur = conn.cursor()
      cur.execute("SELECT value FROM flagtest WHERE name=%s", ["broadcastflag"])
      tmp_value = cur.fetchone()[0]
      conn.commit()
      cur.close()
      if tmp_value == 1: #clicked
        print "triger to send broadcast packet!!"
        cur = conn.cursor()
        cur.execute("UPDATE flagtest SET value=%s WHERE flagtest.name=%s", [0, "broadcastflag"])
        conn.commit()
        cur.close()

        #broadcast packet sending
        cur = conn.cursor()
        cur.execute("SELECT votedcounter FROM connectiontest ORDER BY nodeid")
        votedcounter_result = cur.fetchall()
        conn.commit()
        cur.close()  

        broadcast_packet_str = "" + DOWNLINK_HEADER
        print broadcast_packet_str
        print votedcounter_result
        if votedcounter_result == []:
          print "oh... no data"
        else:
          print "yeah... we have data"
          for i in votedcounter_result:
            broadcast_packet_str += chr(i[0] + ord(ID_PACKET_OFFSET))
        print broadcast_packet_str

        temp = makeZigBeeTransmitRequestPacket(0x00000000, 0x0000FFFF, 0xFFFE, broadcast_packet_str)
        serialPort.write(temp)
        time.sleep(1)

      #===> broadcast packet sending
      

  finally:
    serialPort.close()
    print port + " is closed."
    print "finish program"
