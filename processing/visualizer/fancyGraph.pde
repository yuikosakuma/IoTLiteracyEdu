//By Nakatsuka!!!
import processing.serial.*;
import java.util.TimeZone;

class YSFGraph {
  FloatList list;

  YSFGraph() {
    list = new FloatList();
  }

  void drawGraph(float x, float y, float w, float h, color c, float min, float max, String lastupdate) {    // x axis, y axis, width, height, red, green, blue
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

    //display lastupdate time
    try {
      String ts = Timestamp.valueOf(lastupdate).toString();
      //println(ts);
      ts = split(ts, ".")[0];
      ts = ts.trim();
      String ts_f [] = split(split(ts, " ")[0], "-");
      String ts_b [] = split(split(ts, " ")[1], ":");

      Calendar cal = Calendar.getInstance();
      cal.setTimeZone(TimeZone.getTimeZone("UTC"));
      cal.set(int(ts_f[0]), int(ts_f[1]), int(ts_f[2]), int(ts_b[0]), int(ts_b[1]), int(ts_b[2]));
      //println(ts);
      cal.get(Calendar.HOUR_OF_DAY); //this is needed to valdate???
      cal.setTimeZone(TimeZone.getTimeZone("JST"));
      cal.get(Calendar.HOUR_OF_DAY);
      Date date = cal.getTime();
      SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
      String text = sdf.format(date);
      //println(text);
      fill(127);
      textSize(height / 50);
      textAlign(RIGHT, TOP);
      text(text, x + w, y);
    }
    catch(Exception e) {
    };
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