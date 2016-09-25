// updated matz 20160211

import de.bezier.data.sql.*;    
import java.util.*;

PostgreSQL pgsql;
boolean connection;

ArrayList<Node> nodes;

int positionType = 0;

void setup()
{
  size(1200, 600);

  //SQL initialization <===
  String user     = "postgres";
  String pass     = "mypgsql";
  String database = "ECORS_DEMO";

  //  pgsql = new PostgreSQL(this, "localhost", database, user, pass );
  pgsql = new PostgreSQL(this, "10.24.128.28:5432", database, user, pass ); //raspberry pi postgreSQL server

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

  //draw nodes initialization <===
  nodes = new ArrayList<Node>();
  //===> draw nodes initialization
}

int pastTime = millis(); 

void draw() {
  nodes.clear();
  background(0);

  //data fetch from database <===
  connection = pgsql.connect();
  println("pgsql connection:" + connection);
  if (connection) {
    String tableName = "xbeeid";
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
          //          print(temp[i-1] + " ");
          if (i == 2 || i == 3) {
            drawTextStrXBeetest += "0x" + hex(pgsql.getInt(i), 8) + " ";
          } else {
            drawTextStrXBeetest += pgsql.getString(i) + " ";
          }
        }
        //        println("");
        drawTextStrXBeetest += "\n";

        //        //check we have the Node or not <===
        //        boolean foundFlag = false; //ooo if i was in python ... however... I can do it with flag. ugly...
        //        for ( Node tempNode : nodes) {
        //          if (int(tempRaw[3]) == tempNode.src64addrL) {//compare 64 bit source addres LOW and found update data
        //            foundFlag = true;
        //            tempNode.updateFromDB(int(tempRaw[1]), int(tempRaw[5]), tempRaw[6], int(tempRaw[7]));
        //            break;
        //          }
        //        }
        //        if (!foundFlag) {//not found insert new data
        //          nodes.add(new Node(tempRaw[0], int(tempRaw[1]), int(tempRaw[2]), int(tempRaw[3]), int(tempRaw[4]), 
        //          int(tempRaw[5]), tempRaw[6], int(tempRaw[7])));
        //        }
        //        //check we have the Node or not ===>
      }
      textAlign(LEFT);
      textSize(12);
      fill(255, 100);
      text(drawTextStrXBeetest, 10, 60);
      print("print all from " + tableName + "\n" + drawTextStrXBeetest);
      //      println(nodes.size());
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

  //data fetch from database <===
  connection = pgsql.connect();
  println("pgsql connection:" + connection);
  if (connection) {
    String tableName = "node";
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
          //          print(temp[i-1] + " ");
          if (i == 2) {
            drawTextStrXBeetest += "0x" + hex(pgsql.getInt(i), 4) + " ";
          } else {
            drawTextStrXBeetest += pgsql.getString(i) + " ";
          }
        }
        //        println("");
        drawTextStrXBeetest += "\n";
      }
      textAlign(LEFT);
      textSize(12);
      fill(255, 100);
      text(drawTextStrXBeetest, 310, 60);
      print("print all from " + tableName + "\n" + drawTextStrXBeetest);
      //      println(nodes.size());
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

  //data fetch from database <===
  connection = pgsql.connect();
  println("pgsql connection:" + connection);
  if (connection) {
    String tableName = "route";
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
        //        println("");
        drawTextStrXBeetest += "\n";
      }
      textAlign(LEFT);
      textSize(12);
      fill(255, 100);
      text(drawTextStrXBeetest, 810, 60);
      print("print all from " + tableName + "\n" + drawTextStrXBeetest);
      //      println(nodes.size());
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



  float nodesNumber = nodes.size();
  int i = 0;
  switch(positionType) {
  case 0: //list
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(0, 0);
      i++;
    }
    break; 
  case 1: //linear
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
      (i + 0.5)/ nodesNumber *  width, 
      (i + 0.5)/ nodesNumber * height);
      i++;
    }
    break;
  case 2: //Square Grid
    int squareNumber = ceil(sqrt(nodesNumber));
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
      (i % squareNumber + 0.5) / squareNumber *  width, 
      (i / squareNumber + 0.5) / squareNumber * height);
      //      println(i + " " + i / squareNumber);
      i++;
    }
    break;
  case 3: //circle
    float circleX = 0.35*width;
    float circleY = 0.35*height;
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
      circleX * cos((float) i / nodesNumber *  2 * PI) + 0.5 * width, 
      circleY * sin((float) i / nodesNumber *  2 * PI) + 0.5 * height);
      i++;
    }
    break;
  }
  //dynamic position calculation <===

  //===> dynamic position calculation

  //drawing Nodes or something like that <===
  for (Node tempNode : nodes) {
    tempNode.drawNode();
  }
  // ===> drawing Nodes

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
  case 'p' :
    positionType++;
    if (positionType > 3) positionType = 0;
    break;
  case 'i': //initialize class
    nodes.clear();
    break;
  case 'q':
    pgsql.close();
    exit();
  case 'n':
    connection = pgsql.connect();
    println("pgsql connection:" + connection);
    if (connection) {
      try {
        pgsql.query("UPDATE route SET route='1,2,3,4,5' WHERE routeid=6");
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