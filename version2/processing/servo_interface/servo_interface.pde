int LEDstate = 0;
float theta = -PI;
boolean servo_locked = true;
int flag_on = 0;
int flag_off = 0;
boolean ONrectOver = false;
boolean OFFrectOver = false;
boolean servoOver = false;
PImage img;

void setup() {
  size(600, 800);
  surface.setResizable(true);

  //***** Make a new instance of a PImage by loading an image file *****
  img = loadImage("servo_bg.png");
}

void draw() {
  //***** If LED BUTTON IS PUSHED *****
  if (flag_on == 1) {
    //api_send_LED();
    flag_on = 0;
  } else if (flag_off == 1) {
    //api_send_LED();
    flag_off = 0;
  }

  updatedisplay();
}

void updatedisplay() {  
  float w = (float)width;
  float h = (float)height;
  float center_x = w/2;
  float center_y = h*3/8;
  float r = w/4;
  float d2 = w/40;
  float end_x = 0.0;
  float end_y = 0.0;

  float ONrectX = w*29/120; //145;      //Rect X Position
  float ONrectY = h*3/4; //600;      //Rect Y Position
  float ONrectSize = w/12; //50;    //Rect Size

  float OFFrectX = w*61/120; //305;      //Rect X Position
  float OFFrectY = h*3/4;      //Rect Y Position
  float OFFrectSize = w/12;    //Rect Size

  //***** If Unservo_locked, Update Position *****
  if (servo_locked == false) {
    float theta_tmp = atan2(mouseY - center_y, mouseX - center_x);
    if (-PI <= theta_tmp && theta_tmp <= 0) theta = theta_tmp;
  }
  end_x = cos(theta) *  r + center_x;
  end_y = sin(theta) * r + center_y;

  if (overRect(ONrectX, ONrectY, ONrectSize*3, ONrectSize) ) {
    ONrectOver = true;
  } else {
    ONrectOver = false;
  }

  if (overRect(OFFrectX, OFFrectY, OFFrectSize*3, OFFrectSize) ) {
    OFFrectOver = true;
  } else {
    OFFrectOver = false;
  }

  background(255);
  image(img, 0, 0, w, h*3/4);
  //***** Draw Servo Image *****
  fill(10);
  rect(w*5/12, h*3/16, w/6, h/4); //  rect(250, 150, 100, 200);
  fill(40);
  rect(w*5/12, h*3/20, w/6, h*3/80); //  rect(250, 120, 100, 30);
  rect(w*5/12, h*7/16, w/6, h*3/80);  //rect(250, 350, 100, 30);
  fill(255);
  ellipse(w/2, h*27/160, w*3/120, h*3/160); //  ellipse(300, 135, 15, 15);
  ellipse(w/2, h*73/160, w*3/120, h*3/160);//  ellipse(300, 365, 15, 15);
  fill(40);
  ellipse(center_x, center_y, w*18/120, h*18/160);//  ellipse(center_x, center_y, 90, 90);
  fill(255);
  strokeWeight(w*5/120);//25);
  stroke(200);
  line(center_x, center_y, end_x, end_y);
  fill(255, 100, 100);
  noStroke();
  ellipse(end_x, end_y, d2, d2);

  //***** Draw LED Image *****
  fill(255, 0, 0);
  ellipse(w/2, h*7/8, w/12, w/12); //  ellipse(300, 700, 50, 50);

  if (LEDstate == 1) {
    fill(255, 0, 0, 80);
  } else {
    fill(0, 255, 255, 90);
  }
  ellipse(w/2, h*7/8, w/12, w/12);//  ellipse(300, 700, 50, 50);

  //***** Draw LED Switch Image
  if (LEDstate == 1) fill(0, 0, 255);
  else fill(200);
  rect(ONrectX, ONrectY, ONrectSize*3, ONrectSize);
  if (LEDstate == 0) fill(0, 0, 255);
  else fill(200);
  rect(OFFrectX, OFFrectY, OFFrectSize*3, OFFrectSize);

  textSize(w*4/100); //24);
  textAlign(CENTER);
  fill(255, 255, 255);
  text("ON", w*44/120, h*125/160); //  text("ON", 220, 625);
  text("OFF", w*76/120, h*125/160); //  text("OFF", 380, 625);
}

void mousePressed()
{
  if ( overServo() ) {
    //***** Unlock Position *****
    servo_locked = false;
  }

  if (ONrectOver) {
    flag_on = 1;
    LEDstate = 1;
  }
  if (OFFrectOver) {
    flag_off = 1;
    LEDstate = 0;
  }
}

void mouseReleased()
{

  //***** Lock Position *****
  servo_locked = true;

  //***** Calculate Angle *****
  if (-PI <= theta && theta <= 0)
  {
    float temp = degrees(theta) + 180;
    int tx = (int)temp;
    //***** Broadcast Data *****
    println(tx);
    //api_send(tx);
  }
}

//***** Check if Over Rect *****
boolean overRect(float x, float y, float width, float height) 
{
  if (mouseX >= x && mouseX <= x+width && 
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

//***** Check if Over Rect *****
boolean overServo() 
{
  if (mouseX >= 0 && mouseX <= 600 && 
    mouseY >= 0 && mouseY <= 600) {
    return true;
  } else {
    return false;
  }
}