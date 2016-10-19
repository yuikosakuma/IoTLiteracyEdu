import de.bezier.data.sql.*;
import de.bezier.data.sql.mapper.*;

import java.util.*;
import java.text.SimpleDateFormat;
import java.sql.Timestamp;

PostgreSQL pgsql;
boolean connection;

void init_db() {
  //SQL initialization <===
  String user     = "postgres";
  String pass     = "mypgsql";
  String database = "iotedu";

  pgsql = new PostgreSQL(this, "localhost", database, user, pass );
  //pgsql = new PostgreSQL(this, "10.24.129.183", database, user, pass );

  connection = pgsql.connect();
  println("pgsql connection:" + connection);

  if (connection) {
    String tableNames [] = pgsql.getTableNames();
    println("Table names");
    for (String temp : tableNames) {
      print(temp + " ");
    }
    pgsql.close();
  } else {
    println("connect failer"); // yay, connection failed !
    exit();
  }
  //===> SQL initialization
}

void refreshDB(String tableName) {
  connection = pgsql.connect();
  println("refreshDB. pgsql connection:" + connection);
  if (connection) {
    try {
      int rawNumber = 0;
      pgsql.query( "SELECT COUNT(*) FROM " + tableName ); // query the number of entries in table "testtable"
      if ( pgsql.next() ) {    // results found? I cant under stand why here is "next"
        rawNumber = pgsql.getInt(1);
        println("rows in " + tableName + " : " + rawNumber);
        pgsql.query( "UPDATE " + tableName + " SET xbeeaddr=0, temperature=0, destinationid=0, votedcounter=0, name=\'yourname\', volume=0");
      }
    }
    catch(Exception e) {
      println( tableName + " is not available");
    }
    pgsql.close();
  } else {
    println("connect failer"); // yay, connection failed !
  }
}

String updateAllDataFromDB(String tableName) {
  String drawTextStr = "";
  //data fetch from database <===
  connection = pgsql.connect();
  println("pgsql connection:" + connection);
  if (connection) {

    try {
      int rawNumber = 0;
      int columnNumber = 0;
      pgsql.query( "SELECT COUNT(*) FROM " + tableName); // query the number of entries in table "testtable"
      if ( pgsql.next() ) {    // results found? I cant under stand why here is "next"
        rawNumber = pgsql.getInt(1);
        drawTextStr += "rows in " + tableName + " : " + rawNumber ;  // nice, then let's report them back
      }

      if (tableName == "connectiontest") {
        pgsql.query( "SELECT * FROM " + tableName + " ORDER BY nodeid"); // now let's query all entries from tableName
      } else {      
        pgsql.query( "SELECT * FROM " + tableName); // now let's query all entries from tableName
      }
      String [] columnNames = pgsql.getColumnNames();
      columnNumber = columnNames.length;
      drawTextStr += " column number: " + columnNumber +"\n";
      for (String temp : columnNames) {
        drawTextStr += temp + " ";
      }
      drawTextStr += "\n";

      while ( pgsql.next () ) {
        String tempRaw [] = new String [columnNumber]; 
        for (int i = 1; i < columnNames.length + 1; i++) {
          tempRaw[i-1] = pgsql.getString(i);
          drawTextStr += pgsql.getString(i) + " ";
        }
        drawTextStr += "\n";

        //println("tableName: " + tableName);
        if (tableName == "connectiontest") { //update data
          int tempdb_nodeid = int(tempRaw[0]);
          int tempdb_xbeeaddr = int(tempRaw[1]);
          float tempdb_temperature = float(tempRaw[2]);
          int tempdb_destinationid = int(tempRaw[3]);
          int tempdb_votedcounter = int(tempRaw[4]);
          String tempdb_name = tempRaw[5];
          String tempdb_lastupdate = tempRaw[6]; //= long(tempRaw[6]); 
          int tempdb_volume = int(tempRaw[8]);

          //check we have the Node or not <===
          boolean foundFlag = false; //ooo if i was in python ... however... I can do it with flag. ugly...
          for (Node tempNode : nodes) { //oooohhhh ugly.
            //println("int(tempRaw[0]): " + int(tempRaw[0]) + " tempNode.noeid: " + tempNode.nodeid);
            if (tempdb_nodeid == tempNode.nodeid) {//compare 64 bit source addres LOW and found update data
              foundFlag = true;
              tempNode.updateDataFromDB(tempdb_nodeid, tempdb_xbeeaddr, tempdb_temperature, tempdb_destinationid, tempdb_votedcounter, tempdb_name, tempdb_lastupdate, tempdb_volume);
              break;
            }
          }
          if (foundFlag != true) {//not found insert new data
            nodes.add(new Node(tempdb_nodeid, tempdb_xbeeaddr, tempdb_temperature, tempdb_destinationid, tempdb_votedcounter, tempdb_name, tempdb_lastupdate, tempdb_volume));
          }          //check we have the Node or not ===>
        }
      }
    }
    catch(Exception e) {
      println( tableName + " is not available");
    }
    pgsql.close();
  } else {
    println("connect failer"); // yay, connection failed !
  }
  //===> data fetch from database
  return drawTextStr;
}

void updateBroadcastFlagOnDB(int value, int angle, int led) { //value=1 for Led instruction, 2 for Servo instruction
  connection = pgsql.connect();
  println("pgsql connection:" + connection);
  if (connection) {
    try {
      pgsql.query("UPDATE flagtest SET value=" + value + ", angle=" + angle + ", led=" + led + " WHERE flagid=1"); //here is very HARD CODED. of course, I tried WHERE flagtest.name=broadcastflag, but it did not work
      println("update succeed");
    }        
    catch(Exception e) {
      println("update failed");
    }
    pgsql.close();
  } else {
    println("connect failer"); // yay, connection failed !
  }
}