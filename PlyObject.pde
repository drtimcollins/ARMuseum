// Loader for 3D .ply files. Data is encapsulated in the PlyObject class.
// Rendering to PShapes for the full mesh, wireframe and pointcloud versions.

import java.io.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

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

  void calculateBoxLimits(){
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
  
  PShape getMesh(){    
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
  
  PShape getWireFrame(){
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

  PShape getPointCloud(){
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
  PVector toPolar(PVector v){
    return new PVector(atan2(v.x, v.z), PVector.angleBetween(v, new PVector(0,1,0)));
  }
  void makeTex(){
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

  PlyObject copy(){
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
  PlyObject copy(PMatrix3D A){
    PlyObject o = copy();
    for(int n = 0; n < Nv; n++)
      A.mult(o.v[n], o.v[n]);    
    return o;
  }
  void append(PlyObject p){
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

  void readHeader(String filename){
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
  void setUv(ByteBuffer b){
    for(int m = 0; m < 6; m++)
      uv[m] = b.getFloat();    
  }  
  Face copy(){
    Face f = new Face(this);
    return f;
  }
  void offset(int o){
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
