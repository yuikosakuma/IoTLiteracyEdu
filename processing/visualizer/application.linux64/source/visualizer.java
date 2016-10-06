import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import de.bezier.data.sql.*; 
import de.bezier.data.sql.mapper.*; 
import java.util.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class visualizer extends PApplet {


int pastTime = millis(); 

public void setup() {
  
  init_db();
}

public void draw() {
  background(0);

  nodes_init();  

  calculateVoteOnDB("connectiontest");

  updateAllDataFromDB("flagtest", "", 10, 60);
  updateAllDataFromDB("connectiontest", "", 410, 60);

  changeSortType();
  displaySortType(5, height / ceil(sqrt(nodes.size())) / 4);
  displayTempRanking(5 + width * 1 / 3, height / ceil(sqrt(nodes.size())) / 4);
  displayVCRanking(5 + width * 2 / 3, height / ceil(sqrt(nodes.size())) / 4); 

  nodes_display();

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

public void keyPressed() {
  switch(key) {
  case ' ':
    updateBroadcastFlagOnDB();
    break;
  case 'R':
    refreshDB("connectiontest");
    break;
  case 'p' :
    positionType++;
    if (positionType > 5) positionType = 0;
    break;  
  case 's' :
    sortType++;
    if (sortType > 2) sortType = 0;
    break;    
  default: 
    break;
  }
}





PostgreSQL pgsql;
boolean connection;

public void init_db() {
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

public void refreshDB(String tableName) {
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

public void calculateVoteOnDB(String tableName) {
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

public void updateAllDataFromDB(String tableName, String drawTextStr, int display_x, int display_y) {
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
            if (PApplet.parseInt(tempRaw[0]) == tempNode.nodeid) {//compare 64 bit source addres LOW and found update data
              tempNode.updateDataFromDB(PApplet.parseInt(tempRaw[0]), PApplet.parseInt(tempRaw[1]), PApplet.parseFloat(tempRaw[2]), PApplet.parseInt(tempRaw[3]), PApplet.parseInt(tempRaw[4]), tempRaw[5]);
              break;
            }
          }
          if (!foundFlag) {//not found insert new data
            nodes.add(new Node(PApplet.parseInt(tempRaw[0]), PApplet.parseInt(tempRaw[1]), PApplet.parseFloat(tempRaw[2]), PApplet.parseInt(tempRaw[3]), PApplet.parseInt(tempRaw[4]), tempRaw[5]));
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

public void updateBroadcastFlagOnDB() {
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
//Thankyou Niwa-cchi!!!

//void setup() {
//  size(600, 600);
//  smooth();
//  noStroke();
//}

public void displayCell(int ID, float Temp, int DstID, int voted, String name, float x, float y, int w, int h) {
   stroke(79, 0, 178);
  if (w/40<h/40)  strokeWeight(w/40);
  else strokeWeight(h/40);
  strokeJoin(ROUND);
  int tsize=0;
  if (w/15<=h/15) { 
    tsize=w/10;
  } else { 
    tsize=h/10;
  }
  PFont myFont = loadFont("BerlinSansFB-Reg-48.vlw");
  textFont(myFont);
  if (Temp<-25.5f)  fill(0, 0, 255);
  else if (Temp<0 && Temp>=-25.5f) fill(0, (Temp+25.5f)*10, 255);
  else if (Temp<25.5f && Temp>=0) fill(0, 255, 255-Temp*10);
  else if (Temp<51 && Temp>=25.5f) fill((Temp-25.5f)*10, 255, 0);
  else if (Temp<76.5f && Temp>=51) fill(255,255-(Temp-51)*10, 0);
  else fill(255, 0, 0);
  rect(x, y, w, h);
  fill(0, 0, 0);
  textSize(tsize*2);
  text("Temp", x+w/3+w/20, y+3*h/10);
  textSize(tsize*2.5f);
  text(nfc(Temp, 1), x+w/3+w/15, y+h*3/5);
  for (int i=0; i<3; i++) {
    fill(255, 255, 200);
    rect(x, y+i*h/4, w/3, h/4);
    fill(0, 0, 0);
    textSize(tsize);
    switch(i) {
    case 0:
      text("ID", x+w/40, y+h/10+i*h/4);
      break;
    case 1:
      text("D", x+w/40, y+h/10+i*h/4);
      break;
    case 2:
      text("V", x+w/40, y+h/10+i*h/4);
      break;
    default:
      break;
    }
    textSize(tsize * 2.0f);
    switch(i) {
    case 0:
      text(ID, x+w/8, y+h/5+i*h/4);
      break;
    case 1:
      text(DstID, x+w/8, y+h/5+i*h/4);
      break;
    case 2:
      text(voted, x+w/8, y+h/5+i*h/4);
      break;
    default:
      break;
    }
  }
  fill(255, 129, 25);
  rect(x, y+h*3/4, w, h/4);
  fill(255, 255, 255);
  textSize(tsize*2);
  text(name, x+w/20, y+h/5+h*3/4);
}

//int i=0;
//
//void draw() {
//  stroke(0, 0, 0);
//  strokeJoin(MITER);
//  fill(0, 0, 0);
//  rect(0, 0, width, height);
//  for (int k = 0; k < 5; k++) {
//    for (int j = 0; j < 5; j++) {
//      displayCell(1, float(i), 1, 1, "ohno", k * width/5, j * height/5, width/5, height/5);
//    }
//  }
//  delay(100);
//  i++;
//}
ArrayList<Node> nodes;

int positionType = 4;

class Node {
  float x, y;
  int nodeid;
  int xbeeaddr;
  float temperature;
  int destinationid;
  int votedcounter;
  String name;

  Node() {
    x = 0.0f;
    y = 0.0f;
    nodeid = 0;
    xbeeaddr = 0;
    temperature = 0.0f;
    destinationid = 0;
    votedcounter = 0;
    name = "";
  }
  Node(int _nodeid, int _xbeeaddr, float _temperature, int _destinationid, int _votedcounter, String _name) {
    nodeid = _nodeid;
    xbeeaddr = _xbeeaddr;
    temperature = _temperature;
    destinationid = _destinationid;
    votedcounter = _votedcounter;
    name = _name;
  }

  public void updateDrawParameter(float _x, float _y) {
    x = _x;
    y = _y;
  }

  public void updateDataFromDB(int _nodeid, int _xbeeaddr, float _temperature, int _destinationid, int _votedcounter, String _name) {
    nodeid = _nodeid;
    xbeeaddr = _xbeeaddr;
    temperature = _temperature;
    destinationid = _destinationid;
    votedcounter = _votedcounter;
    name = _name;
  }

  public void drawNode() {
    fill(255, 100);
    stroke(255, 0, 0);
    strokeWeight(3);
    ellipse(x, y, height/25, height/25);
    textSize(height / 50);
    fill(255);
    textAlign(CENTER);
    text("nodeid:" + nodeid + "\n"
      + "64L:" + hex(xbeeaddr, 8) + "\n"
      + "temp:" + temperature + "\n"
      + "d_id:" + destinationid + "\n"
      + "v_cnt:" + votedcounter + "\n"
      + "name:" + name + "\n"
      , x, y);
    noFill();
    noStroke();
  }
};

public void nodes_init() {
  nodes = new ArrayList<Node>();
}

public void nodes_display() {
  //===> data fetch from database 
  float nodesNumber = nodes.size();
  int i = 0;
  int squareNumber = ceil(sqrt(nodesNumber));
  
  //displaying and sort
  //dynamic position calculation <===
  switch(positionType) {
  case 1: //linear
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
      (i + 0.5f)/ nodesNumber *  width, 
      (i + 0.5f)/ nodesNumber * height);
      i++;
    }
    for (Node tempNode : nodes) {
      tempNode.drawNode();
    }
    break;
  case 2: //Square Grid
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
      (i % squareNumber + 0.5f) / squareNumber *  width, 
      (i / squareNumber + 0.5f) / squareNumber * height);
      //      println(i + " " + i / squareNumber);
      i++;
    }
    for (Node tempNode : nodes) {
      tempNode.drawNode();
    }
    break;
  case 3: //circle
    float circleX = 0.35f*width;
    float circleY = 0.35f*height;
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
      circleX * cos((float) i / nodesNumber *  2 * PI) + 0.5f * width, 
      circleY * sin((float) i / nodesNumber *  2 * PI) + 0.5f * height);
      i++;
    }
    for (Node tempNode : nodes) {
      tempNode.drawNode();
    }
    break;
  case 4: //cells
    for (Node tempNode : nodes) {
      displayCell(tempNode.nodeid, tempNode.temperature, tempNode.destinationid, tempNode.votedcounter, tempNode.name, 
      (i % squareNumber) *  (width / squareNumber), (i/ squareNumber) * (height / squareNumber) + (height / squareNumber), 
      width / squareNumber, height / squareNumber);
      i++;
    }
    break;
  default: //list
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(0, 0);
      i++;
    }
    for (Node tempNode : nodes) {
      tempNode.drawNode();
    }
    break;
  }
  //===> dynamic position calculation
}
int sortType = 0;

public class NodeComparatorByNodeid implements Comparator<Node> { 
  @Override public int compare(Node p1, Node p2) { 
    return p1.nodeid < p2.nodeid ? -1 : 1;
  }
} 

public class NodeComparatorByTemperature implements Comparator<Node> { 
  @Override public int compare(Node p1, Node p2) { 
    return p1.temperature > p2.temperature ? -1 : 1;
  }
} 

public class NodeComparatorByVotedcounter implements Comparator<Node> { 
  @Override public int compare(Node p1, Node p2) { 
    return p1.votedcounter > p2.votedcounter ? -1 : 1;
  }
} 

public void changeSortType() {
  //for sort
  switch(sortType) {
  case 1: //Temperature
    //destructive sort
    Collections.sort(nodes, new NodeComparatorByTemperature()); 
    break;
  case 2: //VotedCounter
    //destructive sort
    Collections.sort(nodes, new NodeComparatorByVotedcounter());   
    break;
  default: //nodeid
    //destructive sort
    Collections.sort(nodes, new NodeComparatorByNodeid()); 
    break;
  }
}

public void displaySortType(float x, float y) {
  fill(255);
  textSize(height / 20);
  String temp_str = "Sorted by:\n";
  switch(sortType) {
  case 1:
    temp_str += "Temperature";
    break;
  case 2:
    temp_str += "Voted count";
    break;
  default:
    temp_str += "Node ID";
    break;
  }
  text(temp_str, x, y);
}

public void displayTempRanking(float x, float y) {
  fill(255);
  textSize(height / 25);
  ArrayList<Node> tempList = new ArrayList<Node>(nodes);
  Collections.sort(tempList, new NodeComparatorByTemperature()); 
  String temp_str = "Temp Rank\n"
    + "1st: " + tempList.get(0).temperature + " " + tempList.get(0).name.trim() + "\n"
    + "2nd: " + tempList.get(1).temperature + " " + tempList.get(1).name.trim() + "\n"
    + "3rd: " + tempList.get(2).temperature + " " + tempList.get(2).name.trim() + "\n";
  text(temp_str, x, y);
}

public void displayVCRanking(float x, float y) {
  fill(255);
  textSize(height / 25);
  ArrayList<Node> tempList = new ArrayList<Node>(nodes);
  Collections.sort(tempList, new NodeComparatorByVotedcounter()); 
  String temp_str = "#Voted Rank\n"
    + "1st: " + tempList.get(0).votedcounter + " " + tempList.get(0).name.trim() + "\n"
    + "2nd: " + tempList.get(1).votedcounter + " " + tempList.get(1).name.trim() + "\n"
    + "3rd: " + tempList.get(2).votedcounter + " " + tempList.get(2).name.trim() + "\n";
  text(temp_str, x, y);
  text(temp_str, x, y);
}

//// ---------------------- Example ---------------------
////refer to http://java.keicode.com/lib/collections-sort.php
//
//import java.util.ArrayList; 
//import java.util.Collections; 
//
//void setup() {
//  ArrayList<Person> memberList = new ArrayList<Person>(); 
//  memberList.add(new Person(40, "Hanako")); 
//  memberList.add(new Person(50, "Taro")); 
//  memberList.add(new Person(20, "Ichiro")); 
//  for (int i=0; i<memberList.size (); i++) { 
//    System.out.format("%s - %d\n", memberList.get(i).name, memberList.get(i).age);
//  } 
//  Collections.sort(memberList, new PersonComparator()); 
//  System.out.println("--- Sorted ---"); 
//  for (int i=0; i<memberList.size (); i++) { 
//    System.out.format("%s - %d\n", memberList.get(i).name, memberList.get(i).age);
//  }
//}
//
//public class Person { 
//  public int age; 
//  public String name; 
//  public Person(int age, String name) { 
//    this.age = age; 
//    this.name = name;
//  }
//} 
//
//import java.util.Comparator; 
//public class PersonComparator implements Comparator<Person> { 
//  @Override public int compare(Person p1, Person p2) { 
//    return p1.age < p2.age ? -1 : 1;
//  }
//} 
  public void settings() {  size(320, 240); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "visualizer" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
