//Thankyou Niwa-cchi!!!

//void setup() {
//  size(600, 600);
//  smooth();
//  noStroke();
//}


color selectColorBasedOnTemperature(float temp) {
  color c;
  if (temp < 25) c = color(0, constrain((temp+25)*10, 0, 255), 255, 250);
  else if (temp < 27) c = color(0, 255, constrain(255-temp*10, 0, 255), 250);
  else if (temp < 30) c = color(constrain((temp-27)*10, 0, 255), 255, 0, 250);
  else if (temp < 35) c = color(255, constrain(255-(temp-30)*10, 0, 255), 0, 250);
  else c = color(255, 0, 0, 150);
  return c;
}

void displayCell(int ID, float Temp, int Volume, String name, float x, float y, float w, float h) {
  textAlign(LEFT);
  stroke(79, 0, 178);
  if (w/40<h/40)  strokeWeight(w/40);
  else strokeWeight(h/40);
  strokeJoin(ROUND);
  int tsize=0;
  if (w/15<=h/15) { 
    tsize=int(w)/10;
  } else { 
    tsize=int(h)/10;
  }
  PFont myFont = loadFont("BerlinSansFB-Reg-48.vlw");
  textFont(myFont);

  //color selection of background
  //fill(selectColorBasedOnTemperature(Temp));
  fill(0, 0, 0, 0);
  rect(x, y, w, h);

  //left window
  fill(0, 0, 0);
  textSize(tsize*2);
  text("Temp", x+w/3+w/20, y+3*h/10);
  textSize(tsize*2.5);
  text(nfc(Temp, 1), x+w/3+w/15, y+h*3/5);
  fill(255, 255, 200);
  rect(x, y+0*h/4, w/3, 3 * h/4);
  rect(x, y+0*h/4, w/3, h/4);
  fill(0, 0, 0);
  textSize(tsize);
  text("ID", x+w/40, y+h/10+0*h/4);
  textSize(tsize * 2.0);
  text(ID, x+w/8, y+h/5+0*h/4);

  //volume
  fill(255);
  noStroke();
  arc(x+w/6, y+11*h/16, w/3.5, w/3.5, radians(180), radians(360));

  fill(0, 0, 0);
  textSize(tsize);
  text("Volume", x+w/40, y+h/10+1*h/4);
  text(Volume, x+w/40, y+h/5+1*h/4);
  float angle = map((float)Volume, 0, 1023, 0, 179);
  stroke(79, 0, 178);
  line(x+w/6, y+11*h/16, x+w/6 + cos(radians(angle + 180)) * w/7, y+11*h/16 + sin(radians(angle + 180)) * w/7);

  //name window
  fill(255, 129, 25);
  rect(x, y+h*3/4, w, h/4);
  fill(255, 255, 255);
  textSize(tsize*2);
  text(name, x+w/20, y+h/5+h*3/4);
}

//int i=0;
//
//void draw() {
//  stroke(0, 0, 0);
//  strokeJoin(MITER);
//  fill(0, 0, 0);
//  rect(0, 0, width, height);
//  for (int k = 0; k < 5; k++) {
//    for (int j = 0; j < 5; j++) {
//      displayCell(1, float(i), 1, 1, "ohno", k * width/5, j * height/5, width/5, height/5);
//    }
//  }
//  delay(100);
//  i++;
//}