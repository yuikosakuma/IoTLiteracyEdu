import controlP5.*;

ControlP5 cp5;

ArrayList<Button> buttonArray = new ArrayList<Button>();

void init_controlP5() {
  cp5 = new ControlP5(this);

  buttonArray.add(myAddButton("button_space", "broad\ncast", color(127, 20), 0, 0, width/2, height/2));
  buttonArray.add(myAddButton("button_R", "Refresh", color(255, 20), width/2, 0, width/2, height/2));
  buttonArray.add(myAddButton("button_p", "Position", color(255, 20), 0, height/2, width/2, height/2));
  buttonArray.add(myAddButton("button_s", "Sort", color(127, 20), width/2, height/2, width/2, height/2));
}

void loop_controlP5() {
  fill(191, 50);
  textAlign(CENTER, CENTER);
  textSize(width/10);
  for (Button tmp_button : buttonArray) {
    text(tmp_button.getStringValue(), tmp_button.getPosition()[0] + tmp_button.getWidth()/2, tmp_button.getPosition()[1] + tmp_button.getHeight()/2);
  }
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