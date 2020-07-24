// Class to load and store a collection of objects representing the mesh, pointcloud and wireframe forms.

class ObjectShapes{
  PShape arObj, pcObj, wfObj;
  PlyObject pObj, qObj;
  float offset;
  String[] labelText;
  PVector[] boxCorners = new PVector[8];
  PVector[] labelCorners = new PVector[4];
  boolean labelSelected = false;
  float labelWidth  = .04;
  float labelHeight = .015;
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
      labelCorners[n] = new PVector(labelWidth * (float(n&1)-0.5), labelHeight * (float((n>>1)&1)-0.5), 0);
    }
    
    labelText = new String[2];
    labelText[0] = objInfo[i].getString("label0");
    labelText[1] = objInfo[i].getString("label1");    
  }
  
  PVector[] getScreenBox(){
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
  
  PVector[] getLabelBox(){
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
  
  float hitTest(float x, float y){
    PVector[] b = getScreenBox();
    if(x > b[1].x && x < b[0].x && y > b[1].y && y < b[0].y)
      return b[1].z;
    else
      return -1;
  }
  
  float labelHitTest(float x, float y){
    PVector[] b = getLabelBox();
    if(x > b[1].x && x < b[0].x && y > b[1].y && y < b[0].y)
      return b[1].z;
    else
      return -1;
  }  
  
  void drawPlynth(){
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
    fill(labelSelected ? #1EAEDB : 255);
    box(labelWidth,labelHeight,.002);
    translate(0,0,-0.0011);
    fill(0);
    textAlign(CENTER,CENTER);
    scale(0.001);
    textSize(5);
    text(labelText[0],0,-3);
    text(labelText[1],0,3);
    fill(255);
    image(infoIcon, 15.5, -6, 3.5, 3.5); 
    popMatrix();
  }
}
