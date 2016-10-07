import controlP5.*;

ControlP5 cp5;

class MyButton {
  Button button;
  int x, y, w, h;

  MyButton(Button _button) {
    button = _button;
  }

  void update(int _x, int _y, int _w, int _h) {
    x = _x;
    y = _y;
    w = _w;
    h = _h;

    tmp_button.setPosition(x, y)
      .setSize(w, h)
        .updateSize();
    text(button.getStringValue(), 
    button.getPosition()[0] + button.getWidth()/2, 
    button.getPosition()[1] + button.getHeight()/2);
  }
};

ArrayList<MyButton> buttonArray = new ArrayList<MyButton>();

void init_controlP5() {
  cp5 = new ControlP5(this);

  buttonArray.add(MyButton(myAddButton("button_space", "broad\ncast", color(127, 20), 0, 0, width/2, height/2)));
  buttonArray.add(MyButton(myAddButton("button_R", "Refresh", color(255, 20), width/2, 0, width/2, height/2)));
  buttonArray.add(MyButton(myAddButton("button_p", "Position", color(255, 20), 0, height/2, width/2, height/2)));
  buttonArray.add(MyButton(myAddButton("button_s", "Sort", color(127, 20), width/2, height/2, width/2, height/2)));
}

void loop_controlP5() {
  fill(191, 50);
  textAlign(CENTER, CENTER);
  textSize(width/10);

  buttonArray.get(0).update(0, 0, width/2, height/2);
  buttonArray.get(1).update(width/2, 0, width/2, height/2);
  buttonArray.get(2).update(0, height/2, width/2, height/2);
  buttonArray.get(3).update(width/2, height/2, width/2, height/2);
}

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
}

Button myAddButton(String nameOfFunction, String stringValue, color c, int x, int y, int w, int h) {
  return cp5.addButton(nameOfFunction)
    .setPosition(x, y)
      .setLabel("")
        .setStringValue(stringValue)
          .setSize(w, h)
            .setColorActive(c) 
              .setColorBackground(c) 
                .setColorCaptionLabel(c) 
                  .setColorForeground(c);
}

void displayButtonStr(String label, color c, int x, int y) {
}

public void button_space() {
  updateBroadcastFlagOnDB();
}

public void button_R() {
  refreshDB("connectiontest");
}

public void button_p() {
  positionType++;
  if (positionType > 5) positionType = 0;
}

public void button_s() {
  sortType++;
  if (sortType > 2) sortType = 0;
}

