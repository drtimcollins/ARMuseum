// Main file for the AR Museum containing setup, draw etc

import processing.ar.*;

ARTracker tracker;
ARAnchor[] anchor;
PImage gridImage;
float angle;
float rot = 0;
float scaleFactor = 0.001;  // Convert mm to m
JSONObject[] objInfo;
ObjectShapes[] objShapes;
int objIndex = 0;
int Nobj;
boolean justPlaced = false;
boolean pMouseState = false;
boolean gridOn = true;
int selectedIndex = -1;
boolean isSelectionLabel;
PImage infoIcon;
PFont boldFont, normalFont;

float plynthSize   = .025;
float plynthHeight = .020;
float plynthBase   = .030;

enum GuiModes {SPLASHSCREEN, HELPSCREEN, ARINTERFACE};
enum objModes {POINTCLOUD, WIREFRAME, WIRETEX, FULL};
enum alignModes {FREE, ALIGNED, OVERLAP};

GuiModes   guiMode   = GuiModes.SPLASHSCREEN;
objModes   objMode   = objModes.FULL;
alignModes alignMode = alignModes.FREE;

SplashScreen splash;    // The spashscreen 2D display.
ARButtonBar bb;         // 2D Buttons on main AR interface.
HelpScreen helper;

void setup() {
  fullScreen(AR);
  textureMode(NORMAL);
  //String[] fl = PFont.list(); printArray(fl);

  JSONArray json = loadJSONArray("objectInfo.json");
  Nobj = json.size();
  objInfo = new JSONObject[Nobj];
  objShapes = new ObjectShapes[Nobj];
  anchor = new ARAnchor[Nobj];
  for (int n = 0; n < Nobj; n++)
  {
    objInfo[n] = json.getJSONObject(n);
    objShapes[n] = new ObjectShapes(n);
  }
  gridImage = loadImage("grid.png");
  infoIcon  = loadImage("info.png");
  boldFont  = createFont("SansSerif-Bold", 50);
  normalFont  = createFont("SansSerif", 40);
  textFont(normalFont);

  tracker = new ARTracker(this);
  tracker.start();

  init2D();
  splash = new SplashScreen();
  bb = new ARButtonBar();
  helper = new HelpScreen();
}

void draw() {
  textureWrap(REPEAT);

  if (guiMode == GuiModes.SPLASHSCREEN) {
    splash.draw();
  } else if(guiMode == GuiModes.HELPSCREEN){
    helper.draw();
    
  } else {
    lights();

    if (alignMode != alignModes.FREE) objIndex = 0; // All objects are placed relative to a single anchor

    if (mousePressed && !pMouseState) {
      onMouseDown();
      if (selectedIndex >= 0 && alignMode == alignModes.FREE && !isSelectionLabel) objIndex = selectedIndex;
    }
    pMouseState = mousePressed;

    if (mousePressed && !bb.hitTest() && !isSelectionLabel) {
      // Create new anchor at the current touch point
      if (anchor[objIndex] != null) anchor[objIndex].dispose();
      ARTrackable hit = tracker.get(mouseX, mouseY);
      if (hit != null) {
        anchor[objIndex] = new ARAnchor(hit);
        justPlaced = true;
      } else anchor[objIndex] = null;
    }
    if (!mousePressed && justPlaced) {
      justPlaced = false;
      objIndex = ((objIndex+1) % Nobj);
    }
    if (!mousePressed && isSelectionLabel) {
      println("Label clicked");
      objShapes[selectedIndex].infoVisible = !objShapes[selectedIndex].infoVisible;
      objShapes[selectedIndex].labelSelected = false;
      isSelectionLabel = false;
    }

    for (int n = 0; n < Nobj; n++) {
      if (getAnchor(n) != null) {
        getAnchor(n).attach();        
        PVector T = getPlacement(n);
        //        translate(getPlacement(n), objShapes[n].offset, 0);  // Lift object so base is at surface-level.
        translate(T.x, plynthHeight+0.001, T.z);
        if(alignMode != alignModes.OVERLAP || n != 3){ // BODGE: Item 3 is the envelope contents
          objShapes[n].drawPlynth();
          objShapes[n].drawInfo();
        }
        translate(0, T.y, 0);
        rotateY(angle);
        if (objMode == objModes.WIRETEX || objMode == objModes.FULL)
          shape(objShapes[n].arObj);
        if (objMode == objModes.POINTCLOUD)
          shape(objShapes[n].pcObj);
        if (objMode == objModes.WIRETEX || objMode == objModes.WIREFRAME)
          shape(objShapes[n].wfObj);
        getAnchor(n).detach();
      }
    }    

    // Draw trackable planes
    if (gridOn) {
      for (int i = 0; i < tracker.count(); i++) {
        ARTrackable trackable = tracker.get(i);
        if (!trackable.isTracking()) continue;

        pushMatrix();
        trackable.transform();
        noStroke();
        fill(255);
        beginShape();
        texture(gridImage);
        float[] points = trackable.getPolygon();
        for (int n = 0; n < points.length / 2; n++) {
          float x = points[2 * n];
          float z = points[2 * n + 1];
          vertex(x, 0, z, x*3.0, z*3.0);
        }
        endShape();
        popMatrix();
      }
    }
    fill(255);
    bb.draw();

    angle += rot;
  }
}

// Processing AR bug-fix. These settings are made on set-up but some get lost if the app is paused then resumed.
void onResume() {  
  super.onResume();
  getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
    | View.SYSTEM_UI_FLAG_FULLSCREEN
    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
}

void onMouseDown() {
  float bestZ = 10.0;
  int bestn = -1;
  boolean isLabel = false;
  for (int n = 0; n < Nobj; n++) {
    objShapes[n].labelSelected = false;
    if (getAnchor(n) != null) {
      getAnchor(n).attach();
      PVector T = getPlacement(n);
      translate(T.x, plynthHeight, T.z);
      float ht = objShapes[n].labelHitTest(mouseX, mouseY);
      if (ht > 0 && ht < bestZ) {
        bestZ = ht;
        bestn = n;
        isLabel = true;
      }
      if(objShapes[n].infoVisible){
        ht = objShapes[n].infoHitTest(mouseX, mouseY);
        if (ht > 0 && ht < bestZ) {
          bestZ = ht;
          bestn = n;
          isLabel = true;
        }        
      }


      translate(0, T.y, 0);
      rotateY(angle);
      ht = objShapes[n].hitTest(mouseX, mouseY);
      if (ht > 0 && ht < bestZ) {
        bestZ = ht;
        bestn = n;
        isLabel = false;
      }

      getAnchor(n).detach();
    }
  }
  selectedIndex = bestn;
  isSelectionLabel = isLabel;
  if (isLabel) objShapes[bestn].labelSelected = true;
}

ARAnchor getAnchor(int index) {
  if (alignMode == alignModes.FREE)
    return anchor[index];
  else
    return anchor[0];
}

PVector getPlacement(int index) { // Calculate offset needed for an object
  PVector t = new PVector(0, 0, 0);

  if (alignMode == alignModes.ALIGNED)
    t.x = float(index)*0.075;
  else if (alignMode == alignModes.OVERLAP)
    t.x = float(index<3 ? index : 2)*0.075;

  t.y = objShapes[index].offset;

  return t;
}
