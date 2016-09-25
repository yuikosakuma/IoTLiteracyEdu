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
      if tmp_value == 1: #clicked
        print "triger to send broadcast packet!!"
        cur = conn.cursor()
        cur.execute("UPDATE flagtest SET value=%s WHERE flagtest.name=%s", [0, "broadcastflag"])
        conn.commit()
        cur.close()

      # time.sleep(1)
  except KeyboardInterrupt:
    print 'keyboard interrupt exit'
    exit()