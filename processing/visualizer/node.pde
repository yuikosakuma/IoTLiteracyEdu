class Node {
  //data from database
  String id;
  int src16addr;
  int src64addrH;
  int src64addrL;
  int type;
  int updateCount;
  String updateTime;
  int orderOfArrival;

  //data to draw GUI on processing (this program)
  float drawX;
  float drawY;

  //constructor
  Node(String _id, int _src16addr, int _src64addrH, int _src64addrL, int _type, int _updateCount, String _updateTime, int _orderOfArrival) {
    id = _id;
    src16addr = _src16addr;
    src64addrH = _src64addrH;
    src64addrL = _src64addrL;
    type = _type;
    updateCount = _updateCount;
    updateTime = _updateTime;
    orderOfArrival = _orderOfArrival;

    drawX = -1;
    drawY = -1;
  }

  void updateFromDB(int _src16addr, int _updateCount, String _updateTime, int _orderOfArrival) {
    src16addr = _src16addr;
    updateCount = _updateCount;
    updateTime = _updateTime;
    orderOfArrival = _orderOfArrival;
  }

  void updateDrawParameter(float _drawX, float _drawY) {
    drawX = _drawX;
    drawY = _drawY;
  }

  void drawNode() {
    fill(255, 100);
    stroke(255, 0, 0);
    strokeWeight(3);
    ellipse(drawX, drawY, 40, 40);
    textSize(11);
    fill(255);
    textAlign(CENTER);
    text("id :" + id + "\n"
      + "16 :" + hex(src16addr, 4) + "\n"
//      + "64H:" + hex(src64addrH, 8) + "\n"
      + "64L:" + hex(src64addrL, 8) + "\n"
//      + "Typ:" + type + "\n"
//      + "#UP:" + updateCount + "\n"
      + "TUP:"  + updateTime + "\n"
      + "OoA:"  + orderOfArrival + "\n"
      , drawX, drawY);
    noFill();
    noStroke();
  }
}