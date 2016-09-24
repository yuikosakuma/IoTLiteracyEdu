import de.bezier.data.sql.*;    
import java.util.*;

PostgreSQL pgsql;
boolean connection;


void setup()
{
  size(1200, 600);

  //SQL initialization <===
  String user     = "postgres";
  String pass     = "mypgsql";
  String database = "iotedu";

  pgsql = new PostgreSQL(this, "localhost", database, user, pass );

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

int pastTime = millis(); 

void draw() {
  background(0);

  //data fetch from database <===
  connection = pgsql.connect();
  println("pgsql connection:" + connection);
  if (connection) {
    String tableName = "flagtest";
    String drawTextStrXBeetest = "";

    try {
      int rawNumber = 0;
      int columnNumber = 0;
      pgsql.query( "SELECT COUNT(*) FROM " + tableName ); // query the number of entries in table "testtable"
      if ( pgsql.next() ) {    // results found? I cant under stand why here is "next"
        rawNumber = pgsql.getInt(1);
        drawTextStrXBeetest += "rows in " + tableName + " : " + rawNumber ;  // nice, then let's report them back
      }

      pgsql.query( "SELECT * FROM " + tableName); // now let's query all entries from tableName

        String [] columnNames = pgsql.getColumnNames();
      columnNumber = columnNames.length;
      drawTextStrXBeetest += " column number: " + columnNumber +"\n";
      for (String temp : columnNames) {
        drawTextStrXBeetest += temp + " ";
      }
      drawTextStrXBeetest += "\n";

      while ( pgsql.next () ) {
        String tempRaw [] = new String [columnNumber]; //
        for (int i = 1; i < columnNames.length + 1; i++) {
          tempRaw[i-1] = pgsql.getString(i);
          drawTextStrXBeetest += pgsql.getString(i) + " ";
        }
        drawTextStrXBeetest += "\n";
      }
      textAlign(LEFT);
      textSize(12);
      fill(255, 100);
      text(drawTextStrXBeetest, 10, 60);
      print("print all from " + tableName + "\n" + drawTextStrXBeetest);
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

  //loop time and framerate drawing <===
  textAlign(LEFT);
  textSize(15);
  fill(255, 200);
  int interval = millis() - pastTime;
  pastTime = millis();
  text("one loop by millis() interval: " + interval + "ms frameRate: " + frameRate, 10, 30);
  noFill();
  //===> loop time and framerate drawing
}

void keyPressed() {
  switch(key) {
  case ' ':
    connection = pgsql.connect();
    println("pgsql connection:" + connection);
    if (connection) {
      try {
        pgsql.query("UPDATE flagtest SET value=1 WHERE flagid=1");
      }        
      catch(Exception e) {
      }
      pgsql.close();
    } else {
      println("connect failer"); // yay, connection failed !
    }
    break;
  default: 
    break;
  }
}

