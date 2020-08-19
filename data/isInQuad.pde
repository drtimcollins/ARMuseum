PVector[] v;
void setup(){
  size(500, 500);
  v = new PVector[4];
  v[0] = new PVector(29, 130);
  v[1] = new PVector(179, 14);
  v[2] = new PVector(271, 185);
  v[3] = new PVector(340, 474);
}

void draw(){
//  background(255);
  stroke(0);
  noFill();
  beginShape();
  for(int n = 0; n < 4; n++)
    vertex(v[n].x,v[n].y);
  endShape(CLOSE);
  for(int n = 0; n < 100; n++){
    PVector p = new PVector(random(500), random(500));
    fill(isInQuad(p,v) ? #00ff00 : #ff00ff);
    circle(p.x,p.y,10);
  }
}

boolean isInQuad(PVector p, PVector[] v){
  int[] d = new int[4];
  for(int n = 0; n < 4; n++)
    d[n] = signFn(p, v[n], v[(n+1)%4]);
  return (d[0] == d[1]) && (d[1] == d[2]) && (d[2] == d[3]);
}

int signFn(PVector p1,PVector p2,PVector p3){
  return ((p1.x-p3.x)*(p2.y-p3.y)-(p2.x-p3.x)*(p1.y-p3.y) > 0) ? 1 : -1;
}
