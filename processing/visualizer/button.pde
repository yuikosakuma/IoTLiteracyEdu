import controlP5.*;

ControlP5 cp5;

void init_controlP5() {
  cp5 = new ControlP5(this);

  cp5.addButton("button_s")
    .setCaptionLabel("s")
    .setSize(width/20, height/20)
    .setPosition(width/10, height/10);
}

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
}

public void button_s() {
  updateBroadcastFlagOnDB();
}