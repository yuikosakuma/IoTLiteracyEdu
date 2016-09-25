ArrayList<Node> nodes;

int positionType = 0;

class Node {
  float x, y;
  int nodeid;
  int xbeeaddr;
  float temperature;
  int destinationid;
  int votedcounter;
  String name;

  Node() {
    x = 0.0;
    y = 0.0;
    nodeid = 0;
    xbeeaddr = 0;
    temperature = 0.0;
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

  void updateDrawParameter(float _x, float _y) {
    x = _x;
    y = _y;
  }

  void updateDataFromDB(int _nodeid, int _xbeeaddr, float _temperature, int _destinationid, int _votedcounter, String _name) {
    nodeid = _nodeid;
    xbeeaddr = _xbeeaddr;
    temperature = _temperature;
    destinationid = _destinationid;
    votedcounter = _votedcounter;
    name = _name;
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
      + "name:" + name + "\n"
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
  float nodesNumber = nodes.size();
  int i = 0;
  int squareNumber = ceil(sqrt(nodesNumber));
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

  switch(positionType) {
  case 1: //linear
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(
      (i + 0.5)/ nodesNumber *  width, 
      (i + 0.5)/ nodesNumber * height);
      i++;
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
  default: //list
    for (Node tempNode : nodes) {
      tempNode.updateDrawParameter(0, 0);
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
}

