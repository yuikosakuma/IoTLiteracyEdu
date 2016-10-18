ArrayList<DynamicButton> dynamicButtons= new ArrayList<DynamicButton>();

class DynamicButton {
  String name;
  int x, y, w, h;
  String label;
  color color_label;
  color color_default;
  color color_clicked;

  DynamicButton(String _name, String _label, color _color_label, color _color_default, color _color_clicked) {
    name = _name;
    label = _label;
    color_label = _color_label;
    color_default = _color_default;
    color_clicked = _color_clicked;
  }

  boolean check(int tx, int ty) {
    if (x <= tx && tx <= x + w && y <= ty && ty <= y + h) {
      fill(color_clicked);
      rect(x, y, w, h);
      return true;
    }
    return false;
  }

  void update(int _x, int _y, int _w, int _h) {
    x = _x;
    y = _y;
    w = _w;
    h = _h;
  }

  void display() {
    fill(color_default);
    rect(x, y, w, h);
    fill(color_label);
    text(label, x + w/2, y + h/2);
  }
};

void init_dynamicButton() {
  dynamicButtons.add(new DynamicButton("my_button", "my_label", color(255), color(127), color(0)));
}

void loop_dynamicButton() {
  for (DynamicButton tmpButton : dynamicButtons) {
    tmpButton.update(width/2, height/2, width/2, height/2);
    tmpButton.display();
  }
}

void mouseClicked_dynamicButton() {
  for (DynamicButton tmpButton : dynamicButtons) {
    println(tmpButton.check(mouseX, mouseY));
  }
}

void mouseClicked() {
  mouseClicked_dynamicButton();
}

void setup() {
  //size(1200, 800);
  //size(800, 600);
  size(320, 240);
  frame.setResizable(true);
  //  surface.setResizable(true);
  init_dynamicButton();
}

void draw() {
  background(0);
  fill(255, 0, 0);
  ellipse(width/2, height/2, width, height);

  loop_dynamicButton();
}

