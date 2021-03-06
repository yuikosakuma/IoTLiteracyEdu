int pastTime = millis(); 

void setup() {
  //  fullScreen();

  size(1200, 800);
  //size(800, 600);
  //size(320, 240);
  //frame.setResizable(true); //for proceesing-2
  surface.setResizable(true); //for processing-3
  init_db();

  init_dynamicButton();

  nodes_init();
}

void draw() {
  int pastTime = millis();
  background(0);

  calculateVoteOnDB("connectiontest");

  String flagtestStr = updateAllDataFromDB("flagtest");
  String connectiontestStr = updateAllDataFromDB("connectiontest");

  ////display DB in Table looks <====
  //  textAlign(LEFT);
  //  textSize(height / 30);
  //  fill(255, 100);
  //  text(flagtestStr, 0* width/3 +10, 60);
  //  text(connectiontestStr, 1 * width/3 +10, 60);
  //  noFill();
  ////====> display DB in Table looks

  changeSortType();

  fill(255);
  textAlign(LEFT, TOP);
  textSize(height / 10);
  text("Visualizer", 5, 0);
  displaySortType(5, height / ceil(sqrt(nodes.size())) * 5 / 8);
  displayTempRanking(5 + width * 3 / 8, height / ceil(sqrt(nodes.size())) / 4);
  displayVCRanking(5 + width * 6 / 8, height / ceil(sqrt(nodes.size())) / 4); 

  nodes_display();

  loop_dynamicButton();

  //loop time and framerate drawing <===
  int interval = millis() - pastTime;
  println("one loop by millis() interval: " + interval + "ms frameRate: " + frameRate);
  //textAlign(LEFT);
  //textSize(15);
  //fill(255, 200);
  //pastTime = millis();
  //text("one loop by millis() interval: " + interval + "ms frameRate: " + frameRate, 10, 30);
  //noFill();
  //===> loop time and framerate drawing
}

void keyPressed() {
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
  case 27:
    exit();
  default: 
    break;
  }
}

void mousePressed() {
  mouseClicked_dynamicButton();
}