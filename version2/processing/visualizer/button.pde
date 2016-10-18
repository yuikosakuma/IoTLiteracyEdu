ArrayList<DynamicButton> dynamicButtons= new ArrayList<DynamicButton>();

class DynamicButton {
  String name;
  float x, y, w, h;
  float position_x_ratio, position_y_ratio, width_ratio, height_ratio;
  String label;
  color color_label;
  color color_default;
  color color_clicked;

  DynamicButton(String _name, String _label, color _color_default, color _color_clicked, color _color_label, float _position_x_ratio, float _position_y_ratio, float _width_ratio, float _height_ratio) {
    name = _name;
    label = _label;
    color_default = _color_default;
    color_clicked = _color_clicked;
    color_label = _color_label;
    position_x_ratio = _position_x_ratio;
    position_y_ratio = _position_y_ratio;
    width_ratio = _width_ratio;
    height_ratio = _height_ratio;
  }

  boolean check(int tx, int ty) {
    if (x <= tx && tx <= x + w && y <= ty && ty <= y + h) {
      fill(color_clicked);
      rect(x, y, w, h);
      return true;
    }
    return false;
  }


  void update() {
    x = position_x_ratio * width;
    y = position_y_ratio * height;
    w = width_ratio * width;
    h = height_ratio * height;
  }

  void update(float _x, float _y, float _w, float _h) {
    x = _x;
    y = _y;
    w = _w;
    h = _h;
  }

  void display() {
    noStroke();
    fill(color_default);
    rect(x, y, w, h);
    textAlign(CENTER, CENTER);
    textSize(width/10);
    fill(color_label);
    text(label, x + w/2, y + h/2);
  }
};

void init_dynamicButton() {
  dynamicButtons.add(new DynamicButton("button_space", "broad\ncast", 
  color(255, 20), color(191, 20), color(191, 20), 0, 0, 0.5, 0.5));
  dynamicButtons.add(new DynamicButton("button_27", "exit", 
  color(255, 20), color(191, 20), color(191, 20), 0.5, 0, 0.5, 0.25));
  dynamicButtons.add(new DynamicButton("button_R", "refresh", 
  color(127, 20), color(191, 20), color(191, 20), 0.5, 0.25, 0.5, 0.25));
  dynamicButtons.add(new DynamicButton("button_p", "position", 
  color(127, 20), color(191, 20), color(191, 20), 0, 0.5, 0.5, 0.5));
  dynamicButtons.add(new DynamicButton("button_s", "sort", 
  color(255, 20), color(191, 20), color(191, 20), 0.5, 0.5, 0.5, 0.5));
}

void loop_dynamicButton() {
  for (DynamicButton tmpButton : dynamicButtons) {
    tmpButton.update();
    tmpButton.display();
  }
}

void mouseClicked_dynamicButton() {
  for (DynamicButton tmpButton : dynamicButtons) {
    if (tmpButton.check(mouseX, mouseY)) {
      if (tmpButton.name == "button_space") {
        updateBroadcastFlagOnDB(1, 0, 0);
      } else if (tmpButton.name == "button_R") { 
        refreshDB("connectiontest");
      } else if (tmpButton.name == "button_27") {
        exit();
      } else if (tmpButton.name == "button_p") {
        positionType++;
        if (positionType > 5) positionType = 0;
      } else if (tmpButton.name == "button_s") {
        sortType++;
        if (sortType > 2) sortType = 0;
      }
    }
  }
}

//
//void mouseClicked() {
//  mouseClicked_dynamicButton();
//}
//
//void setup() {
//  //size(1200, 800);
//  //size(800, 600);
//  size(320, 240);
//  frame.setResizable(true);
//  //  surface.setResizable(true);
//  init_dynamicButton();
//}
//
//void draw() {
//  background(0);
//  fill(255, 0, 0);
//  ellipse(width/2, height/2, width, height);
//
//  loop_dynamicButton();
//}