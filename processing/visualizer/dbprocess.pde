import de.bezier.data.sql.*;    
import java.util.*;

PostgreSQL pgsql;
boolean connection;

void init_db() {
  //SQL initialization <===
  String user     = "postgres";
  String pass     = "mypgsql";
  String database = "iotedu";

//  pgsql = new PostgreSQL(this, "localhost", database, user, pass );
  pgsql = new PostgreSQL(this, "10.24.129.183", database, user, pass );

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

//        for (int i = 1; i < rawNumber + 1; i++) {
//          pgsql.query( "UPDATE " + tableName + " SET xbeeaddr=0, temperature=0, destinationid=0, votedcounter=0, name=" + "yourname" + " WHERE nodeid=" + i);
//        }
          pgsql.query( "UPDATE " + tableName + " SET xbeeaddr=0, temperature=0, destinationid=0, votedcounter=0, name=\'yourname\'");
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

void calculateVoteOnDB(String tableName) {
  connection = pgsql.connect();
  println("calculateVoteOnDB. pgsql connection:" + connection);
  if (connection) {
    try {
      int rawNumber = 0;
      pgsql.query( "SELECT COUNT(*) FROM " + tableName ); // query the number of entries in table "testtable"
      if ( pgsql.next() ) {    // results found? I cant under stand why here is "next"
        rawNumber = pgsql.getInt(1);
        println("rows in " + tableName + " : " + rawNumber);

        pgsql.query( "SELECT destinationid FROM " + tableName + " ORDER BY nodeid"); 
        int[] tmp_counter = new int[rawNumber+1];
        while ( pgsql.next () ) {
          int tmp_dst_id = pgsql.getInt(1);
          tmp_counter[tmp_dst_id]++; //calculation
        }
        print("tmp_counter: ");
        for (int i = 0; i < tmp_counter.length; i++) {
          print(" [" + i + "]:" + tmp_counter[i]);
        }
        println("");

        //put it to database
        for (int i = 1; i < tmp_counter.length; i++) {
          pgsql.query( "UPDATE " + tableName + " SET votedcounter=" + tmp_counter[i] + " WHERE nodeid=" + i);
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
}

void updateAllDataFromDB(String tableName, String drawTextStr, int display_x, int display_y) {
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

        if (tableName == "connectiontest") { //update data
          //check we have the Node or not <===
          boolean foundFlag = false; //ooo if i was in python ... however... I can do it with flag. ugly...
          for (Node tempNode : nodes) { //oooohhhh ugly.
            if (int(tempRaw[0]) == tempNode.nodeid) {//compare 64 bit source addres LOW and found update data
              tempNode.updateDataFromDB(int(tempRaw[0]), int(tempRaw[1]), float(tempRaw[2]), int(tempRaw[3]), int(tempRaw[4]), tempRaw[5]);
              break;
            }
          }
          if (!foundFlag) {//not found insert new data
            nodes.add(new Node(int(tempRaw[0]), int(tempRaw[1]), float(tempRaw[2]), int(tempRaw[3]), int(tempRaw[4]), tempRaw[5]));
          }          //check we have the Node or not ===>
        }
      }
      textAlign(LEFT);
      textSize(12);
      fill(255, 100);
      text(drawTextStr, display_x, display_y);
      print("print all from " + tableName + "\n" + drawTextStr);
      noFill();
    }
    catch(Exception e) {
      println( tableName + " is not available");
    }
    pgsql.close();
  } else {
    println("connect failer"); // yay, connection failed !
  }
  //===> data fetch from database
}

void updateBroadcastFlagOnDB() {
  connection = pgsql.connect();
  println("pgsql connection:" + connection);
  if (connection) {
    try {
      pgsql.query("UPDATE flagtest SET value=1 WHERE flagid=1"); //here is very HARD CODED. of course, I tried WHERE flagtest.name=broadcastflag, but it did not work
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

