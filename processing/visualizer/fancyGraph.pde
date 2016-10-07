//By Nakatsuka!!!
import processing.serial.*;

class YSFGraph {
  FloatList list;

  YSFGraph() {
    list = new FloatList();
  }

  void drawGraph(float x, float y, float w, float h, color c, float min, float max) {    // x axis, y axis, width, height, red, green, blue
    strokeWeight(1);
    stroke(255, 50);
    fill(c);
    rect(x, y, w, h);
    // width of rectangle
    float rectwidth = w / 50;
    float rectHeight = 0;
    if (list.size() > 0) {
      for (int i = 0; i < list.size(); i++) {
        fill(selectColorBasedOnTemperature(list.get(i)));
        rectHeight = map(constrain(list.get(i), min, max), min, max, 0, h);
        rect(x + rectwidth * i, y + h, rectwidth, -rectHeight);
      }
    }
  }

  void addValue(float x) {
    //println("add value in ysfgraph");
    list.append(x);
    if (list.size() > 50) { // until the graph reaches the right end
      // pop unwanted prior numbers
      list.reverse();
      list.pop();
      list.reverse();
    }
  }
}