ArrayList<Node> nodes;

class Node {
  float x, y;
  int nodeid;
  int xbeeaddr;
  float temperature;
  int destinationid;
  int votedcounter;
  String name;
  String lastupdate;
  int volume;
  YSFGraph ysfgraph;

  Node() {
    x = 0.0;
    y = 0.0;
    nodeid = 0;
    xbeeaddr = 0;
    temperature = 0.0;
    destinationid = 0;
    votedcounter = 0;
    name = "";
    lastupdate = "";
    volume = 0;
    ysfgraph = new YSFGraph();
  }
  Node(int _nodeid, int _xbeeaddr, float _temperature, int _destinationid, int _votedcounter, String _name, String _lastupdate, int _volume) {
    nodeid = _nodeid;
    xbeeaddr = _xbeeaddr;
    temperature = _temperature;
    destinationid = _destinationid;
    votedcounter = _votedcounter;
    name = _name;
    lastupdate = _lastupdate;
    volume = _volume;
    ysfgraph = new YSFGraph();
  }

  void updateDrawParameter(float _x, float _y) {
    x = _x;
    y = _y;
  }

  void updateDataFromDB(int _nodeid, int _xbeeaddr, float _temperature, int _destinationid, int _votedcounter, String _name, String _lastupdate, int _volume) {
    nodeid = _nodeid;
    xbeeaddr = _xbeeaddr;
    temperature = _temperature;
    destinationid = _destinationid;
    votedcounter = _votedcounter;
    name = _name;
    volume = _volume;
    try {
      if (!_lastupdate.equals(lastupdate)) ysfgraph.addValue(temperature); //add new value to graph only when new data is receved
    }
    catch(NullPointerException e) {
    } 
    lastupdate = _lastupdate;
  }

  void drawNode() {
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
      + "name:" + name.trim() + "\n"
      + "lastupdate:" + lastupdate + "\n"
      , x, y);
    noFill();
    noStroke();
  }
};

void nodes_init() {
  nodes = new ArrayList<Node>();
}

void nodes_display() {
  //===> data fetch from database 
  int nodesNumber = nodes.size();
  int i = 0;
  int squareNumber = ceil(sqrt(nodesNumber));

  //displaying and sort
  //dynamic position calculation <===
  switch(positionType) {
  case 1: //linear
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
        (i + 0.5)/ nodesNumber *  width, 
        (i + 0.5)/ nodesNumber * height);
      i++;
    }
    for (Node tempNode : nodes) {
      tempNode.drawNode();
    }
    break;
  case 2: //Square Grid
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
        (i % squareNumber + 0.5) / squareNumber *  width, 
        (i / squareNumber + 0.5) / squareNumber * height);
      //      println(i + " " + i / squareNumber);
      i++;
    }
    for (Node tempNode : nodes) {
      tempNode.drawNode();
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
    for (Node tempNode : nodes) {
      tempNode.drawNode();
    }
    break;
  case 4: 
    int cellWidth = width / squareNumber;
    int cellHeight = height / squareNumber;

    //graphs by Nakatsuka
    i = 0;
    for (Node tempNode : nodes) {
      tempNode.ysfgraph.drawGraph(
        (i % squareNumber) *  cellWidth + 0.34 * cellWidth, 
        (i / squareNumber) * cellHeight + cellHeight, 
        0.66 * cellWidth, 
        0.75 * cellHeight, 
        color(255), 
        15, 40, 
        tempNode.lastupdate);
      i++;
    }

    //cells by Niwacchi
    i = 0;    
    for (Node tempNode : nodes) {
      displayCell(tempNode.nodeid, tempNode.temperature, tempNode.volume, tempNode.name, 
        (i % squareNumber) * cellWidth, 
        (i/ squareNumber) * cellHeight + cellHeight, 
        cellWidth, 
        cellHeight);
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