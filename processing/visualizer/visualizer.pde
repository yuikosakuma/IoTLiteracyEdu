int pastTime = millis(); 

void setup() {
  //size(1200, 800);
  //size(800, 600);
  size(320, 240);
  frame.setResizable(true);
  //  surface.setResizable(true);
  init_db();

  init_dynamicButton();
}

void draw() {
  background(0);

  nodes_init();  

  calculateVoteOnDB("connectiontest");

  String flagtestStr = updateAllDataFromDB("flagtest");
  String connectiontestStr = updateAllDataFromDB("connectiontest");

  ////display DB in Table looks <====
  //  textAlign(LEFT);
  //  textSize(12);
  //  fill(255, 100);
  //  text(flagtestStr, 10, 60);
  //  text(connectiontestStr, 410, 60);
  //  noFill();
  ////====> display DB in Table looks

  changeSortType();
  displaySortType(5, height / ceil(sqrt(nodes.size())) / 4);
  displayTempRanking(5 + width * 3 / 8, height / ceil(sqrt(nodes.size())) / 4);
  displayVCRanking(5 + width * 6 / 8, height / ceil(sqrt(nodes.size())) / 4); 

  nodes_display();

  loop_dynamicButton();
  //  //loop time and framerate drawing <===
  //  textAlign(LEFT);
  //  textSize(15);
  //  fill(255, 200);
  //  int interval = millis() - pastTime;
  //  pastTime = millis();
  //  text("one loop by millis() interval: " + interval + "ms frameRate: " + frameRate, 10, 30);
  //  noFill();
  //  //===> loop time and framerate drawing
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

void mouseClicked() {
  mouseClicked_dynamicButton();
}

