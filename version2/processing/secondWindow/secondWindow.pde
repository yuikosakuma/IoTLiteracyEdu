//second window based on http://3846masa.blog.jp/archives/1038375725.html

SecondApplet second;

void settings() {
  size(400, 400);
}

void setup() {
  second = new SecondApplet(this);
}

void draw() {
  background(frameCount % 255);
}