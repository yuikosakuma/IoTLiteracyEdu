int pastTime = millis(); 

void setup() {
  size(1200, 1200);
  init_db();
}

void draw() {
  background(0);

  nodes_init();  

  calculateVoteOnDB("connectiontest");

  displayAllDataFromDB("flagtest", "", 10, 60);
  displayAllDataFromDB("connectiontest", "", 410, 60);

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

void keyPressed() {
  switch(key) {
  case ' ':
    connection = pgsql.connect();
    println("pgsql connection:" + connection);
    if (connection) {
      try {
        pgsql.query("UPDATE flagtest SET value=1 WHERE flagid=1"); //here is very HARD CODED. of course, I tried WHERE flagtest.name=broadcastflag, but it did not work
      }        
      catch(Exception e) {
      }
      pgsql.close();
    } else {
      println("connect failer"); // yay, connection failed !
    }
    break;
  case 'p' :
    positionType++;
    if (positionType > 4) positionType = 0;
    break;  
  case 's' :
    sortType++;
    if (sortType > 2) sortType = 0;
    break;    
  default: 
    break;
  }
}

