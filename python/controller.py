#based on 160419TSIBPXMASSControllerBatteryRefineOverlapSaveDataAll

import serial
import time
import array
import sys

import psycopg2
from psycopg2.extensions import adapt, register_adapter, AsIs
import datetime
import random

if __name__ == "__main__":
  #database intialization <===
  print "database initialization start"
  conn = psycopg2.connect(host="localhost", database="iotedu", user="postgres", password="mypgsql")
  print "database initialization end"
  #===>database

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

  try:
    while True:
      cur = conn.cursor()
      cur.execute("SELECT value FROM flagtest WHERE name=%s", ["broadcastflag"])
      tmp_value = cur.fetchone()[0]
      conn.commit()
      cur.close()
      # print "tmp_value", tmp_value,
      if tmp_value == 1: #clicked
        print "triger to send broadcast packet!!"
        cur = conn.cursor()
        cur.execute("UPDATE flagtest SET value=%s WHERE flagtest.name=%s", [0, "broadcastflag"])
        conn.commit()
        cur.close()
      # else:
        # print "nothing happens... wait...",

      # print ""
      # time.sleep(1)
  except KeyboardInterrupt:
    print 'keyboard interrupt exit'
    exit()


  #get addrDict from xbeeid table in DB
  # print "addrDict initialization start"
  # addrDict = {}
  # cur = conn.cursor()
  # cur.execute("SELECT COUNT(*) from xbeeid")
  # num = cur.fetchone()[0]
  # cur.close()
  # for i in range(0, num):
  # cur = conn.cursor()
  # cur.execute("SELECT src64addrl from xbeeid WHERE nodeid=%s", [i])
  # tempAddr =  cur.fetchone()[0]
  # addrDict[i] = tempAddr
  # cur.close()

  # #prepare route used in real network
  # print "currentRoutes initialization start"
  # currentRoutes = {} #set of allroutes is stored
  # cur = conn.cursor()
  # cur.execute("SELECT COUNT(*) from route")
  # num = cur.fetchone()[0]
  # cur.close()
  # for i in range(0, num):
  # cur = conn.cursor()
  # cur.execute("SELECT route FROM route WHERE routeid=%s", [i])
  # tempRoute = cur.fetchone()
  # tempRoute = [int(item) for item in tempRoute[0].split(",")]
  # currentRoutes[i] = tempRoute
  # cur.close()
  # for i in range(0, len(currentRoutes)):
  # print currentRoutes[i]
  # print "currentRoutes initialization end"


  # #main loop
  # cur = conn.cursor()
  # cur.execute("UPDATE node SET visible=%s \
  # WHERE node.nodeid=%s", [int(sPacketCatchFlag[i]) ,i])
  # conn.commit()
  # cur.close()

  # cur = conn.cursor()
  # cur.execute("SELECT COUNT(*) from route")
  # num = cur.fetchone()[0]
  # cur.close()

