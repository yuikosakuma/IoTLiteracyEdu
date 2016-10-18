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

void displayCell(int ID, float Temp, int DstID, int voted, String name, float x, float y, float w, float h) {
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

  fill(0, 0, 0);
  textSize(tsize*2);
  text("Temp", x+w/3+w/20, y+3*h/10);
  textSize(tsize*2.5);
  text(nfc(Temp, 1), x+w/3+w/15, y+h*3/5);
  for (int i=0; i<3; i++) {
    fill(255, 255, 200);
    rect(x, y+i*h/4, w/3, h/4);
    fill(0, 0, 0);
    textSize(tsize);
    switch(i) {
    case 0:
      text("ID", x+w/40, y+h/10+i*h/4);
      break;
    case 1:
      text("D", x+w/40, y+h/10+i*h/4);
      break;
    case 2:
      text("V", x+w/40, y+h/10+i*h/4);
      break;
    default:
      break;
    }
    textSize(tsize * 2.0);
    switch(i) {
    case 0:
      text(ID, x+w/8, y+h/5+i*h/4);
      break;
    case 1:
      text(DstID, x+w/8, y+h/5+i*h/4);
      break;
    case 2:
      text(voted, x+w/8, y+h/5+i*h/4);
      break;
    default:
      break;
    }
  }
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