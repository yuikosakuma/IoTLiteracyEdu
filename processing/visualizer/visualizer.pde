
void setup()
{
  size(1200, 600);

  init_db();
}

int pastTime = millis(); 

void draw() {
  background(0);

  displayAllDataFromDB("flagtest", "", 10, 60);
  displayAllDataFromDB("connectiontest", "", 410, 60);

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
  default: 
    break;
  }
}

