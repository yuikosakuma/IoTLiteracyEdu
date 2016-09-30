int pastTime = millis(); 

void setup() {
  size(1200, 1200);
  init_db();
}

void draw() {
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

void keyPressed() {
  switch(key) {
  case ' ':
    updateBroadcastFlagOnDB();
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

