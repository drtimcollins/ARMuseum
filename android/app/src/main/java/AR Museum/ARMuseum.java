package AR Museum;

import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.ar.*; 
import android.util.DisplayMetrics; 
import processing.opengl.*; 
import android.view.*; 
import android.graphics.Rect; 
import java.io.*; 
import java.nio.ByteBuffer; 
import java.nio.ByteOrder; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class ARMuseum extends PApplet {

// Main file for the AR Museum containing setup, draw etc



ARTracker tracker;
ARAnchor[] anchor;
PImage gridImage;
float angle;
float rot = 0;
float scaleFactor = 0.001f;  // Convert mm to m
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

float plynthSize   = .025f;
float plynthHeight = .020f;
float plynthBase   = .030f;

enum GuiModes {SPLASHSCREEN, ARINTERFACE};
enum objModes {POINTCLOUD, WIREFRAME, WIRETEX, FULL};
enum alignModes {FREE, ALIGNED, OVERLAP};

GuiModes   guiMode   = GuiModes.SPLASHSCREEN;
objModes   objMode   = objModes.FULL;
alignModes alignMode = alignModes.FREE;

SplashScreen splash;    // The spashscreen 2D display.
ARButtonBar bb;         // 2D Buttons on main AR interface.

public void setup() {
  
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
}

public void draw() {
  textureWrap(REPEAT);

  if (guiMode == GuiModes.SPLASHSCREEN) {
    splash.draw();
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
        translate(T.x, plynthHeight+0.001f, T.z);
        objShapes[n].drawPlynth();
        objShapes[n].drawInfo();
        translate(0, T.y, 0);
        rotateY(angle);
        if (objMode ==objModes.WIRETEX || objMode == objModes.FULL)
          shape(objShapes[n].arObj);
        if (objMode != objModes.FULL)
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
          vertex(x, 0, z, x*3.0f, z*3.0f);
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
public void onResume() {  
  super.onResume();
  getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_STABLE
    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
    | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
    | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
    | View.SYSTEM_UI_FLAG_FULLSCREEN
    | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
}

public void onMouseDown() {
  float bestZ = 10.0f;
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

public ARAnchor getAnchor(int index) {
  if (alignMode == alignModes.FREE)
    return anchor[index];
  else
    return anchor[0];
}

public PVector getPlacement(int index) { // Calculate offset needed for an object
  PVector t = new PVector(0, 0, 0);

  if (alignMode == alignModes.ALIGNED)
    t.x = PApplet.parseFloat(index)*0.075f;
  else if (alignMode == alignModes.OVERLAP)
    t.x = PApplet.parseFloat(index<3 ? index : 2)*0.075f;

  t.y = objShapes[index].offset;

  return t;
}
// Class to handle the 2D buttons on the main AR display

class ARButtonBar {
  Button b;
  Button[] vb, ab;
  PImage bIm;
  String[] vbIm = {"pointCloud.png", "wireframe.png", "wireTex.png", "tex.png"};
  String[] abIm = {"autoline1.png", "autoline2.png", "gridOn.png"};
  Label techInfo;

  ARButtonBar() {
    b = new Button(10, dispHeight-10-100, 100, 100, loadImage("rotate.png"));
    vb = new Button[4];
    ab = new Button[3];
    techInfo = new Label(50, 650, displayWidth-100, 300, "Technical info");

    for (int n = 0; n < 4; n++)
      vb[n] = new Button(width+20-130*(4-n), dispHeight-10-100, 100, 100, loadImage(vbIm[n]));
    for (int n = 0; n < 3; n++)
      ab[n] = new Button(n<2 ? 10+130*n : width+20-130*(3-n), 30, 100, 100, loadImage(abIm[n]));
  }
  public void draw() {
    start2D();
    b.draw();
    for (int n = 0; n < 4; n++)
      vb[n].draw();
    for (int n = 0; n < 3; n++)
      ab[n].draw();

    if (b.isClicked) {
      b.isClicked = false;
      rot = 0.05f - rot;
    }

    if (vb[0].isClicked) objMode = objModes.POINTCLOUD;
    if (vb[1].isClicked) objMode = objModes.WIREFRAME;
    if (vb[2].isClicked) objMode = objModes.WIRETEX;
    if (vb[3].isClicked) objMode = objModes.FULL;    
    if (ab[0].isClicked) alignMode = (alignMode==alignModes.ALIGNED) ? alignModes.FREE : alignModes.ALIGNED;
    if (ab[1].isClicked) alignMode = (alignMode==alignModes.OVERLAP) ? alignModes.FREE : alignModes.OVERLAP;
    if (ab[2].isClicked) gridOn = !gridOn;

    for (int n = 0; n < 4; n++)
      vb[n].isClicked = false;
    for (int n = 0; n < 3; n++)
      ab[n].isClicked = false;
  }

  public void draw(String x) {  // Used for debugging to display extra technical info in the middle of the display
    techInfo.labelText = x;
    draw();
    techInfo.draw();
  }

  public boolean hitTest() {
    boolean result = b.hitTest();
    for (int n = 0; n < 4; n++) result = result || vb[n].hitTest();
    for (int n = 0; n < 3; n++) result = result || ab[n].hitTest();
    return result;
  }
}
// Various controls (buttons and labels) used for the 2D interaction and for the splashscreen

class Control {
  PVector p, s;
  Control(float x, float y, float w, float h) {
    p = new PVector(x, y);
    s = new PVector(w, h);
  }
  public void draw() {}
  public boolean hitTest() {
    // Return true if the mouse position is within 15 pixels of the control border
    return (mouseX > p.x-15 && mouseX < p.x+s.x+15 && mouseY > p.y-15 && mouseY < p.y+s.y+15);
  }
}

class Button extends Control {
  String labelText;
  PImage im;
  boolean isImageButton;
  boolean isPressed = false;
  boolean isClicked = false;
  Button(float x, float y, float w, float h, String label) {
    super(x, y, w, h);
    labelText = label;
    isImageButton = false;
  }
  Button(float x, float y, float w, float h, PImage img) {
    super(x, y, w, h);
    im = img;
    isImageButton = true;
  }
  public void draw() {
    isClicked = (!mousePressed && isPressed);    // True only if the mouse has just been released from the button.
    isPressed = (mousePressed && hitTest());     // True is the mouse is pressed and over the button. 

    if (isImageButton) {
      tint(isPressed ? 0xff0088FF : 0xffFFFFFF, isPressed ? 100 : 255);
      image(im, p.x, p.y, s.x, s.y);
    } else {
      strokeWeight(4);
      textSize(40);
      fill(isPressed ? 255 : 220);
      stroke(0);
      rect(p.x, p.y, s.x, s.y, 20);
      textAlign(CENTER, CENTER);
      fill(0);
      text(labelText, p.x+s.x/2, p.y+s.y/2);
    }
  }
}

class Link extends Button {
  String url;
  Link(float x, float y, float w, float h, String text, String href) {
    super(x, y, w, h, text);
    url = href;
  }
  public void draw() {
    isClicked = (!mousePressed && isPressed);    // True only if the mouse has just been released from the button.
    isPressed = (mousePressed && hitTest());     // True is the mouse is pressed and over the button. 
    fill(isPressed ? 0xffFF0000 : 0xff1EAEDB);
    textSize(40);
    textAlign(CENTER, CENTER);
    //text(labelText, p.x+s.x/2, p.y+s.y/2);
    text(labelText, p.x, p.y, s.x, s.y);
    if (isClicked) link(url);
  }
}

class Label extends Control {
  String labelText;
  PImage im;
  boolean isImage = false;
  Label(float x, float y, float w, float h, String label) {
    super(x, y, w, h);
    labelText = label;
  }  
  Label(float x, float y, float w, float h, PImage imag) {
    super(x, y, w, h);
    im = imag;
    isImage = true;
  }  

  public void draw() {
    if (isImage) {
      image(im, p.x, p.y, s.x, s.y);
    } else {
      textSize(40);
      textAlign(CENTER, CENTER);
      fill(0);
      text(labelText, p.x, p.y, s.x, s.y);
    }
  }
}

class Title extends Label {
  Title(float x, float y, float w, float h, String label) {
    super(x, y, w, h, label);
  }
  public void draw() {
    textFont(boldFont, 50);
    textAlign(CENTER, CENTER);
    fill(0xff1EAEDB);
    text(labelText, p.x, p.y, s.x, s.y);
    textFont(normalFont, 40);
  }
}
// Functions to enable 2D drawing for the interaction buttons and the splashscreen






int dispHeight;

// Find the size of the display available allowing for the bottom navigation bar
public void init2D(){ 
    DisplayMetrics dispMetrics = new DisplayMetrics();
    getActivity().getWindowManager().getDefaultDisplay().getMetrics(dispMetrics);
    dispHeight = dispMetrics.heightPixels;
}

// Set the view/projection matrices so that the 3D coordinates (x,y,0) match the 2D screen pixel (x,y)
public void start2D() {
	resetMatrix();
	((PGraphicsOpenGL)g).resetProjection();
	((PGraphicsOpenGL)g).applyProjection(2.0f/width,0,0,-1,0,-2.0f/height,0,1,0,0,1,-1,0,0,0,1);	
}


// This function is not used anymore. It was needed for debugging some display issues.
public String testMetrics(){
//  Context c = getContext();
//  WindowManager wm = (WindowManager)c.getSystemService(Context.WINDOW_SERVICE);
//  WindowMetrics metrics = wm.getCurrentMetrics();
//  View.getLocationInWindow();
//WindowMetrics metrics = windowManager.getCurrentMetrics();

 // View  v = getWindow().getDecorView().getRootView();
  Rect r1 = new Rect();
  Rect r2 = new Rect();
  Rect r3 = new Rect();
  int[] pp = new int[2];
  getWindow().getDecorView().getWindowVisibleDisplayFrame(r1);
  //getWindow().getWindowVisibleDisplayFrame(r2);
  //WindowManager.LayoutParams lp = getWindow().getAttributes();
  getWindow().getDecorView().getLocalVisibleRect(r2);
  getWindow().getDecorView().getGlobalVisibleRect(r3);
  getWindow().getDecorView().getLocationOnScreen(pp);
//  int winTop = getWindow().findViewById(Window.ID_ANDROID_CONTENT).getTop();
//  println(r);
//  println(winTop);
  return r1.toString() + "\n" + r2.toString() + "\n" + r3.toString() + "\n(" + pp[0] + ", " + pp[1] + ")";
}
// Class to load and store a collection of objects representing the mesh, pointcloud and wireframe forms.

class ObjectShapes{
  PShape arObj, pcObj, wfObj;
  PlyObject pObj, qObj;
  float offset;
  String[] labelText;
  String infoText;
  PVector[] boxCorners = new PVector[8];
  PVector[] labelCorners = new PVector[4];
  boolean labelSelected = false;
  boolean infoVisible = false;
  float labelWidth  = .04f;
  float labelHeight = .015f;
  ObjectShapes(int i){
    pObj = new PlyObject(objInfo[i].getString("meshFile"));
    qObj = new PlyObject(objInfo[i].getString("pointFile"));
    arObj = pObj.getMesh();
    pcObj = qObj.getPointCloud();
    wfObj = qObj.getWireFrame();
    offset = objInfo[i].getFloat("offset")/1000.0f;
    qObj.calculateBoxLimits();
//    arrayCopy(qObj.boxLims, boxLims);
    println("Box corners:");
    for(int n = 0; n < 8; n++){
      boxCorners[n] = new PVector(qObj.boxLims[n&1].x, qObj.boxLims[(n>>1)&1].y, qObj.boxLims[(n>>2)&1].z);
      println(boxCorners[n]);
    }
    for(int n = 0; n < 4; n++){
      labelCorners[n] = new PVector(labelWidth * (PApplet.parseFloat(n&1)-0.5f), labelHeight * (PApplet.parseFloat((n>>1)&1)-0.5f), 0);
    }
    
    labelText = new String[2];
    labelText[0] = objInfo[i].getString("label0");
    labelText[1] = objInfo[i].getString("label1");    
    infoText = objInfo[i].getString("info");    
  }
  
  public PVector[] getScreenBox(){
    PVector[] b = new PVector[2];
    b[0] = new PVector(screenX(boxCorners[0].x, boxCorners[0].y, boxCorners[0].z), 
      screenY(boxCorners[0].x, boxCorners[0].y, boxCorners[0].z),
      screenZ(boxCorners[0].x, boxCorners[0].y, boxCorners[0].z));  
    b[1] = b[0].copy();
    for(int n = 1; n < 8; n++){
      float x = screenX(boxCorners[n].x, boxCorners[n].y, boxCorners[n].z);
      float y = screenY(boxCorners[n].x, boxCorners[n].y, boxCorners[n].z);
      float z = screenZ(boxCorners[n].x, boxCorners[n].y, boxCorners[n].z);
      if(x > b[0].x) b[0].x = x;
      if(y > b[0].y) b[0].y = y;
      if(z > b[0].z) b[0].z = z;
      if(x < b[1].x) b[1].x = x;
      if(y < b[1].y) b[1].y = y;
      if(z < b[1].z) b[1].z = z;
     }
    return b;
  }
  
  public PVector[] getLabelBox(){
    PVector[] b = new PVector[2];
    pushMatrix();
    translate(0,0,plynthSize);
    rotateX(PI-asin((plynthBase-plynthSize)/plynthHeight));
    translate(0,plynthHeight/2,0);
    
    b[0] = new PVector(screenX(labelCorners[0].x, labelCorners[0].y, 0), 
      screenY(labelCorners[0].x, labelCorners[0].y, 0),
      screenZ(labelCorners[0].x, labelCorners[0].y, 0));  
    b[1] = b[0].copy();
    for(int n = 1; n < 4; n++){
      float x = screenX(labelCorners[n].x, labelCorners[n].y, 0);
      float y = screenY(labelCorners[n].x, labelCorners[n].y, 0);
      float z = screenZ(labelCorners[n].x, labelCorners[n].y, 0);
      if(x > b[0].x) b[0].x = x;
      if(y > b[0].y) b[0].y = y;
      if(z > b[0].z) b[0].z = z;
      if(x < b[1].x) b[1].x = x;
      if(y < b[1].y) b[1].y = y;
      if(z < b[1].z) b[1].z = z;
     }    
    popMatrix();    
    return b;
  }
  
  public float hitTest(float x, float y){
    PVector[] b = getScreenBox();
    if(x > b[1].x && x < b[0].x && y > b[1].y && y < b[0].y)
      return b[1].z;
    else
      return -1;
  }
  
  public float labelHitTest(float x, float y){
    PVector[] b = getLabelBox();
    if(x > b[1].x && x < b[0].x && y > b[1].y && y < b[0].y)
      return b[1].z;
    else
      return -1;
  }  
  
  public void drawPlynth(){
    noFill();
    stroke(200);
    beginShape();
    for(int n = 0; n < 4; n++)
      vertex(plynthSize * (n<2?1:-1),0,plynthSize * (n>0&&n<3?-1:1));
    endShape(CLOSE);
    beginShape();
    for(int n = 0; n < 4; n++)
      vertex(plynthBase * (n<2?1:-1),-plynthHeight,plynthBase * (n>0&&n<3?-1:1));
    endShape(CLOSE);
    for(int n = 0; n < 4; n++){
      line(plynthSize * (n<2?1:-1),0,plynthSize * (n>0&&n<3?-1:1),
        plynthBase * (n<2?1:-1),-plynthHeight,plynthBase * (n>0&&n<3?-1:1));
      endShape();
    }
    pushMatrix();
    translate(0,0,plynthSize);
    rotateX(PI-asin((plynthBase-plynthSize)/plynthHeight));
  //  rotateY(PI);
    translate(0,plynthHeight/2,0);
    fill(labelSelected ? 0xff1EAEDB : 255);
    box(labelWidth,labelHeight,.002f);
    translate(0,0,-0.0011f);
    fill(0);
    textAlign(CENTER,CENTER);
    scale(0.001f);
    textSize(5);
    text(labelText[0],0,-3);
    text(labelText[1],0,3);
    fill(255);
    image(infoIcon, 15.5f, -6, 3.5f, 3.5f); 
    popMatrix();
  }
  
  public void drawInfo(){
    if(infoVisible){
      pushMatrix();
      translate(0, 2.0f*offset + 0.04f, 0);
      rotateX(PI);
      fill(255);
      box(.07f,.05f,.002f);
      translate(0,0,-0.0011f);
      fill(0);
      textAlign(CENTER,CENTER);
      scale(0.001f);
      textSize(4);
      text(infoText,-33,-24,66,48);
      fill(255);
      popMatrix();
    }
  }
}
// Loader for 3D .ply files. Data is encapsulated in the PlyObject class.
// Rendering to PShapes for the full mesh, wireframe and pointcloud versions.





class PlyObject{ 
  PImage im = null;
  PVector []v;
  PVector []norms;
  Face[] f;
  int Nv, Nf;
  int dataStart;
  boolean hasTex;
  PVector[] boxLims = new PVector[2];
  
  PlyObject(){
    Nv = Nf = 0;
  }
  PlyObject(String filename){
    readHeader(filename+".ply");
    println(Nv);
    println(Nf);
    println(dataStart);
 
    InputStream inFile = createInput(filename+".ply");
    DataInputStream d = new DataInputStream(inFile);
    
    if(hasTex) im = loadImage(filename+".jpg");
    try {
      v = new PVector[Nv];
      norms = new PVector[Nv]; 
      f = new Face[Nf];
      
      d.skipBytes(dataStart);
      byte[] vBuff = new byte[12];
      byte[] fBuff = new byte[24];
      ByteBuffer bBuffer = ByteBuffer.allocate(24);
      bBuffer.order(ByteOrder.LITTLE_ENDIAN);
      
      // Read vertices
      for(int n = 0; n < Nv; n++){
        d.read(vBuff, 0, 12);
        bBuffer.rewind();
        bBuffer.put(vBuff);
        bBuffer.rewind();
        v[n] = new PVector(bBuffer.getFloat(), bBuffer.getFloat(), bBuffer.getFloat());  
//        v[n].x = -v[n].x;
        norms[n] = new PVector(0,0,0);
      }
  
      for(int n = 0; n < Nf; n++){
        d.read(fBuff, 0, 1);
        bBuffer.rewind();
        d.read(fBuff, 0, 12);
        bBuffer.rewind();
        bBuffer.put(fBuff);
        bBuffer.rewind();
        f[n] = new Face(bBuffer);

        if(hasTex){
          d.read(fBuff, 0, 1);
          bBuffer.rewind();
          d.read(fBuff, 0, 24);
          bBuffer.rewind();
          bBuffer.put(fBuff);
          bBuffer.rewind();
          f[n].setUv(bBuffer);          
        }
        //PVector faceNormal = (PVector.sub(v[vertexIndex[2]],v[vertexIndex[0]]).cross(PVector.sub(v[vertexIndex[1]],v[vertexIndex[0]]))).normalize();
        PVector faceNormal = (PVector.sub(v[f[n].i[0]],v[f[n].i[2]]).cross(PVector.sub(v[f[n].i[0]],v[f[n].i[1]]))).normalize();
        for(int m = 0; m < 3; m++)
          norms[f[n].i[m]].add(faceNormal);
      }
      for(int n = 0; n < Nv; n++){
        norms[n].normalize();
  //      s.setNormal(n, norms[n].x, norms[n].y, norms[n].z); 
      }
  
      inFile.close();
      } catch(IOException e) {
        e.printStackTrace();
        return;
      }
      
  }

  public void calculateBoxLimits(){
    boxLims[0] = v[0].copy();
    boxLims[1] = v[0].copy();
    for(int n = 1; n < Nv; n++){
      if(v[n].x > boxLims[0].x) boxLims[0].x = v[n].x;
      if(v[n].y > boxLims[0].y) boxLims[0].y = v[n].y;
      if(v[n].z > boxLims[0].z) boxLims[0].z = v[n].z;
      if(v[n].x < boxLims[1].x) boxLims[1].x = v[n].x;
      if(v[n].y < boxLims[1].y) boxLims[1].y = v[n].y;
      if(v[n].z < boxLims[1].z) boxLims[1].z = v[n].z;
    }
    boxLims[0].mult(scaleFactor);
    boxLims[1].mult(scaleFactor);    
  }
  
  public PShape getMesh(){    
    PShape s  = createShape();
    s.beginShape(TRIANGLES);
    if(hasTex) s.noStroke();
    for(int n = 0; n < Nf; n++){
      if(hasTex){
          for(int m = 0; m < 3; m++)
            //s.vertex(scaleFactor*v[f[n].i[m]].x, scaleFactor*v[f[n].i[m]].y, scaleFactor*v[f[n].i[m]].z, f[n].uv[m*2]*(im.width-1), (1.0f-f[n].uv[m*2+1])*(im.height-1));
            s.vertex(scaleFactor*v[f[n].i[m]].x, scaleFactor*v[f[n].i[m]].y, scaleFactor*v[f[n].i[m]].z, f[n].uv[m*2], (1.0f-f[n].uv[m*2+1]));
        } else {
          for(int m = 0; m < 3; m++)
            s.vertex(scaleFactor*v[f[n].i[m]].x, scaleFactor*v[f[n].i[m]].y, scaleFactor*v[f[n].i[m]].z);        
      }
    }
    s.endShape();    
    if(im != null) s.setTexture(im);
    return s;    
  }
  
  public PShape getWireFrame(){
    PShape s  = createShape();
    s.beginShape(TRIANGLES);
    s.noFill();
    s.stroke(0,0,200);
    s.strokeWeight(2);
    for(int n = 0; n < Nf; n++)
      for(int m = 0; m < 3; m++)
        s.vertex(scaleFactor*v[f[n].i[m]].x, scaleFactor*v[f[n].i[m]].y, scaleFactor*v[f[n].i[m]].z);        
    
    s.endShape();    
    return s;    
  }
/*
  PShape getPointCloud(){
    PShape s  = createShape();
    s.beginShape(POINTS);
    s.stroke(0,100,150);
    s.strokeWeight(10);
    for(int n = 0; n < Nv; n++)
      s.vertex(scaleFactor*v[n].x, scaleFactor*v[n].y, scaleFactor*v[n].z);        
    s.endShape();    
    return s;    
  }
*/  

  public PShape getPointCloud(){
    PlyObject s  = new PlyObject();
    s.makeTex();
    Ball b = new Ball();
    float BallRadius = 1.0f;
    
    PMatrix3D A;
    PVector azel;
    for(int n = 0; n < Nv; n++){
      A = new PMatrix3D();
      azel = toPolar(norms[n]);
      A.translate(v[n].x, v[n].y, v[n].z);  
      A.rotateY(azel.x);
      A.rotateX(azel.y);
      A.scale(BallRadius);
      s.append(b.copy(A));
    }    
    return s.getMesh();
  }
/*  
  PlyObject getWireFrame(){
    //PlyObject s  = new PlyObject();
    PlyObject s  = getPointCloud();
//    s.makeTex();
    float TubeRadius = 0.15;
    
    for(int n = 0; n < Nf; n++){
      PVector v0 = v[f[n].i[0]];
      PVector v1 = v[f[n].i[1]];
      PVector v2 = v[f[n].i[2]];
      PVector n0 = norms[f[n].i[0]];
      PVector n1 = norms[f[n].i[1]];
      PVector n2 = norms[f[n].i[2]];
  
      if(f[n].i[0] > f[n].i[1])
        s.append(new Tube(v0, v1, n0, n1, TubeRadius));
      if(f[n].i[1] > f[n].i[2])
        s.append(new Tube(v1, v2, n1, n2, TubeRadius));
      if(f[n].i[2] > f[n].i[0])     
        s.append(new Tube(v2, v0, n2, n0, TubeRadius));  
    }
        
    return s;    
  }
  */
  public PVector toPolar(PVector v){
    return new PVector(atan2(v.x, v.z), PVector.angleBetween(v, new PVector(0,1,0)));
  }
  public void makeTex(){
    im = createImage(512,512,RGB);
    im.loadPixels();
    for (int v = 0; v < 256; v++){
      int cb = color(30.3654f+0.09945f*PApplet.parseFloat(v), 108.8748f+0.36465f*PApplet.parseFloat(v), 131.325f+0.44625f*PApplet.parseFloat(v));
      int ct = color(0, 0, 255*(0.7f+0.3f*cos(TWO_PI*(PApplet.parseFloat(v-25)/154.0f))));
      for(int u = 0; u < 512; u++){
         im.pixels[u+512*(511-v)] = cb; 
         im.pixels[u+512*(255-v)] = ct;        
      }
    }
    im.updatePixels();
    hasTex =  true;
  }

  public PlyObject copy(){
    PlyObject o = new PlyObject();
    o.im = im;
    o.Nv = Nv; o.Nf = Nf;
    o.v = new PVector[Nv];
    o.norms = new PVector[Nv];
    for(int n = 0; n < Nv; n++){
      o.v[n] = v[n].copy();
      o.norms[n] = norms[n].copy();
    }
    o.f = new Face[Nf];
    for(int n = 0; n < Nf; n++)
      o.f[n] = f[n].copy();
    o.hasTex = hasTex;
    return o;
  }
  public PlyObject copy(PMatrix3D A){
    PlyObject o = copy();
    for(int n = 0; n < Nv; n++)
      A.mult(o.v[n], o.v[n]);    
    return o;
  }
  public void append(PlyObject p){
    if(Nv > 0){
    v = (PVector[])concat(v, p.v);
    norms = (PVector[])concat(norms, p.norms);
    f = (Face[])concat(f, p.f);
    for(int n = 0; n < p.f.length; n++)
      f[n+Nf].offset(Nv);
    } else {
      v = p.v;
      norms = p.norms;
      f = p.f;
    }
    Nv += p.Nv;
    Nf += p.Nf;
  }


/* Example header format:
ply
format binary_little_endian 1.0
comment VCGLIB generated
comment TextureFile shabti.jpg
element vertex 1252
property float x
property float y
property float z
element face 2500
property list uchar int vertex_indices
property list uchar float texcoord
end_header
*/

  public void readHeader(String filename){
    BufferedReader reader = createReader(filename);
    String s;
    boolean eoh = false;
    int offset = 0;
    hasTex = false;
    while(!eoh){
      try {
        s = reader.readLine();
      } catch(IOException e) {
        e.printStackTrace();
        return;
      }
      println(s);
      offset += s.length() + 1;
      if(s.startsWith("element vertex")){ Nv = parseInt(s.substring(15));  }
      if(s.startsWith("element face")){ Nf = parseInt(s.substring(13));  }
      if(s.startsWith("property list uchar float texcoord")) hasTex = true; 
      if(s.startsWith("end_header")){
        eoh = true;
        dataStart = offset;
      }
    }
    try {
      reader.close();
      } catch(IOException e) {
        e.printStackTrace();
        return;
      }
  }
}

class Face{
  int []i = new int[3];
  float []uv = new float[6];
  Face(ByteBuffer b){
    for(int m = 0; m < 3; m++){
      i[m] = b.getInt();
    }    
  }
  Face(int i0, int i1, int i2){
    i[0] = i0; i[1] = i1; i[2] = i2;
  }
  Face(int i0, int i1, int i2, PVector uv0, PVector uv1, PVector uv2){
    i[0] = i0; i[1] = i1; i[2] = i2;
    uv[0] = uv0.x; uv[1] = uv0.y;
    uv[2] = uv1.x; uv[3] = uv1.y;
    uv[4] = uv2.x; uv[5] = uv2.y;    
  }
  Face(Face f){
    arrayCopy(f.i, i);
    arrayCopy(f.uv, uv);
  }
  public void setUv(ByteBuffer b){
    for(int m = 0; m < 6; m++)
      uv[m] = b.getFloat();    
  }  
  public Face copy(){
    Face f = new Face(this);
    return f;
  }
  public void offset(int o){
    i[0] += o;
    i[1] += o;
    i[2] += o;
  }  
}
/*
class Tube extends PlyObject{
  PVector norm, anorm, d;
  Tube(){}
  Tube(PVector p0, PVector p1, PVector n0, PVector n1, float r){
    int N = 12;
    d = p0.copy().sub(p1).normalize();
    norm = p0.copy().add(n0).add(n1);
    PVector X = p0.copy().add(d.copy().mult(d.dot(norm.copy().sub(p0))));
    norm.sub(X).normalize();
    anorm = norm.copy().cross(d).normalize();
    
    PVector[] uv = new PVector[26];
    for(int n = 0; n < 26; n++)
      uv[n] = new PVector(0.1+0.8*float(n&1), 0.6+float(n)/80.0);       
    
    Nv = Nf = 2*N;
    v = new PVector[Nv];
    f = new Face[Nf];
    norms = new PVector[Nv];
    for(int n = 0; n < N; n++){
      float theta = TWO_PI * parseFloat(n) / parseFloat(N);
      norms[2*n] = norm.copy().mult(cos(theta)).add(anorm.copy().mult(sin(theta))); 
      v[2*n] = norms[2*n].copy().mult(r).add(p0);
      theta = TWO_PI * (parseFloat(n) + 0.5f) / parseFloat(N);
      norms[2*n + 1] = norm.copy().mult(cos(theta)).add(anorm.copy().mult(sin(theta)));
      v[2*n + 1] = norms[2*n + 1].copy().mult(r).add(p1);
    }
    for(int n = 0; n < Nf; n++){
      if(n % 2==1)
        f[n] = new Face(n, ((n+1)%(2*N)), ((n+2)%(2*N)), uv[n], uv[n+1], uv[n+2]);
      else
        f[n] = new Face(n, ((n+2)%(2*N)), ((n+1)%(2*N)), uv[n], uv[n+2], uv[n+1]);
    }   
  }     
}
*/

// A simple 'ball' (actually a regular octahedron) used for the points in a point cloud
class Ball extends PlyObject{
  Ball(){
    Nv = 6; Nf = 8;
    v = new PVector[Nv];
    PVector[] uv = new PVector[Nv];
    norms = new PVector[Nv];
    f = new Face[Nf];
    
    v[0] = new PVector(0, 1, 0);
    v[1] = new PVector(0, 0, 1);
    v[2] = new PVector(1, 0, 0);
    v[3] = new PVector(0, 0, -1);
    v[4] = new PVector(0, -1, 0);
    v[5] = new PVector(-1, 0, 0);
    
    for(int n = 0; n < Nv; n++){
      uv[n] = new PVector(0.5f + atan2(v[n].x,v[n].z)/7.0f, 0.25f-v[n].y*0.195f);
      norms[n] = v[n].copy();
    }
    
    f[0] = new Face(0, 1, 2, uv[0], uv[1], uv[2]);
    f[1] = new Face(0, 2, 3, uv[0], uv[2], uv[3]);
    f[2] = new Face(0, 3, 5, uv[0], uv[3], uv[5]);
    f[3] = new Face(0, 5, 1, uv[0], uv[5], uv[1]);
    f[4] = new Face(4, 2, 1, uv[4], uv[2], uv[1]);
    f[5] = new Face(4, 3, 2, uv[4], uv[3], uv[2]);
    f[6] = new Face(4, 5, 3, uv[4], uv[5], uv[3]);
    f[7] = new Face(4, 1, 5, uv[4], uv[1], uv[5]);
    
  }
}
// The opening 'home' splashscreen.

class SplashScreen {
  Control[] controls;

  SplashScreen() {
    controls = new Control[5];

    controls[0] = new Title(50, 100, displayWidth-100, 120,"THE AUGMENTED REALITY MUSEUM APP");
    controls[1] = new Label(50, 650, displayWidth-100, 100,"The Augmented Reality Museum App is part of");
    controls[2] = new Link(50, 750, displayWidth-100, 100,"THE VIRTUAL CUNEIFORM RECONSTRUCTION PROJECT","http://virtualcuneiform.org/");    
    controls[3] = new Button((displayWidth-500)/2, 400, 500, 120, "Start AR Museum");
    controls[4] = new Label(50, 1000, displayWidth-100, (displayWidth-100)/2.11f,loadImage("partners.png"));
    
  }

  public void draw() {
	  start2D();
    background(255);
    for (int n = 0; n < controls.length; n++) {
      controls[n].draw();
    }            

/*    if (((Button)controls[1]).isClicked) {
      ((Button)controls[1]).isClicked = false;
      link("http://virtualcuneiform.org/");
    }*/
    if (((Button)controls[3]).isClicked) {
      ((Button)controls[3]).isClicked = false;
      guiMode = GuiModes.ARINTERFACE;
    }
  }
}
  public void settings() {  fullScreen(AR); }
}
