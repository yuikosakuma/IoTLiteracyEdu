//totally based on http://3846masa.blog.jp/archives/1038375725.html

SecondApplet second;

class SecondApplet extends PApplet {
  PApplet parent;

  int LEDstate = 0;
  float theta = -PI;
  boolean servo_locked = true;
  boolean servoOver = false;
  PImage img;

  float center_x = 0;
  float center_y = 0;

  float ONrectX = 0; //145;      //Rect X Position
  float ONrectY = 0; //600;      //Rect Y Position
  float ONrectSize = 0; //50;    //Rect Size

  float OFFrectX = 0; //305;      //Rect X Position
  float OFFrectY = 0;      //Rect Y Position
  float OFFrectSize = 0;    //Rect Size

  SecondApplet(PApplet _parent) {
    super();
    // set parent
    this.parent = _parent;
    //// init window
    try {
      java.lang.reflect.Method handleSettingsMethod =
        this.getClass().getSuperclass().getDeclaredMethod("handleSettings", null);
      handleSettingsMethod.setAccessible(true);
      handleSettingsMethod.invoke(this, null);
    } 
    catch (Exception ex) {
      ex.printStackTrace();
    }

    PSurface surface = super.initSurface();
    surface.placeWindow(new int[]{0, 0}, new int[]{0, 0});
    surface.setTitle("Control Window");

    this.showSurface();
    this.startSurface();
  }

  void settings() {
    size(400, 600);
  }

  void setup() {
    surface.setResizable(true);

    //***** Make a new instance of a PImage by loading an image file *****
  }

  void draw() {
    updatedisplay();
  }

  void updatedisplay() {  
    float w = (float)width;
    float h = (float)height;
    float r = w/4;
    float d2 = w/40;
    float end_x = 0.0;
    float end_y = 0.0;

    center_x = w/2;
    center_y = h*3/8;

    ONrectX = w*29/120; //145;      //Rect X Position
    ONrectY = h*3/4; //600;      //Rect Y Position
    ONrectSize = w/12; //50;    //Rect Size

    OFFrectX = w*61/120; //305;      //Rect X Position
    OFFrectY = h*3/4;      //Rect Y Position
    OFFrectSize = w/12;    //Rect Size

    end_x = cos(theta) *  r + center_x;
    end_y = sin(theta) * r + center_y;

    background(255);
    if (img != null) image(img, 0, 0, w, h*3/4);
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
    if (overServo()) {
      //***** Calculate Angle *****
      //***** If Unservo_locked, Update Position *****
      float theta_tmp = atan2(mouseY - center_y, mouseX - center_x);
      if (-PI <= theta_tmp && theta_tmp <= 0) { 
        theta = theta_tmp;
        float temp = degrees(theta) + 180;
        int tempAngle = (int)temp;
        //***** Broadcast Data *****
        println("instruceted angle: " + tempAngle);
        updateBroadcastFlagOnDB(2, tempAngle, 0);
        //api_send(tx);
      }
    }

    if (overRect(ONrectX, ONrectY, ONrectSize*3, ONrectSize) ) {
      LEDstate = 1;
      updateBroadcastFlagOnDB(1, 0, 1);
    }
    if (overRect(OFFrectX, OFFrectY, OFFrectSize*3, OFFrectSize)) {
      LEDstate = 0;
      updateBroadcastFlagOnDB(1, 0, 0);
    }
  }

  //***** Check if Over Rect *****
  boolean overRect(float x, float y, float w, float h) 
  {
    if (x <= mouseX && mouseX <= x+w &&  y <= mouseY && mouseY <= y+h) {
      return true;
    } else {
      return false;
    }
  }

  //***** Check if Over Rect *****
  boolean overServo() 
  {
    if (0 <= mouseX && mouseX <= width && 0 <= mouseY && mouseY <= height*3/4) {
      return true;
    } else {
      return false;
    }
  }
}