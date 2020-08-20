class HelpScreen{
  HelpLabel[] labels;
  String[] helpText = {"Surface grid (on/off)", "Help (open/close)", "Reconstruct Exhibits", "Arrange Exhibits", "Wireframe", "Wireframe + Texture", "Full Texture", "Point cloud", "Rotate exhibits"};
  HelpScreen(){
    labels = new HelpLabel[9];
    float[] offsets = {40, 170, -40, -170, 0, 0, 0, 0, 0};
    for(int n = 0; n < 4; n++){
      labels[n] = new HelpLabel(180+offsets[n], 200 + 80*n, displayWidth-360, 60, helpText[n]);
    }
    for(int n = 0; n < 5; n++){
      labels[n+4] = new HelpLabel(180+offsets[n+4], dispHeight-10-100-70-80 - 80*n, displayWidth-360, 60, helpText[n+4]);
    }
    
//    stroke(200,200,50);
//    line(bb.vb[1].p.x, bb.vb[1].p.y - bb.vb[1].s.y/2, bb.vb[1].p.x, labels[4].p.y - labels[4].s.y/2);
  }
  
  void draw(){  
//    background(255);
    fill(255);
    bb.draw();
    for(int n = 0; n < labels.length; n++){
      labels[n].draw();
    }
    noFill();
    
//    stroke(200,200,255);
//    strokeWeight(8);
//    drawLines();   
    stroke(#1EAEDB); 
    strokeWeight(4);
    drawLines();
  }
  
  void drawLines(){
    line(bb.vb[1].p.x + bb.vb[1].s.x/2, bb.vb[1].p.y, bb.vb[1].p.x + bb.vb[1].s.x/2, labels[4].p.y+labels[4].s.y);
    beginShape();
    vertex(bb.vb[2].p.x + bb.vb[2].s.x/2, bb.vb[2].p.y);
    vertex(displayWidth-110, labels[4].p.y+labels[4].s.y);
    vertex(displayWidth-110, labels[5].p.y+labels[5].s.y);
    vertex(displayWidth-160, labels[5].p.y+labels[5].s.y/2);
    endShape();
    beginShape();
    vertex(bb.vb[3].p.x + bb.vb[3].s.x/2, bb.vb[3].p.y);
    vertex(bb.vb[3].p.x + bb.vb[3].s.x/2, labels[6].p.y+labels[6].s.y);
    vertex(displayWidth-160, labels[6].p.y+labels[6].s.y/2);
    endShape();
    beginShape();
    vertex(bb.vb[0].p.x + bb.vb[0].s.x/2, bb.vb[0].p.y);
    vertex(110, labels[4].p.y+labels[4].s.y);
    vertex(110, labels[7].p.y+labels[7].s.y);
    vertex(160, labels[7].p.y+labels[7].s.y/2);
    endShape();
    beginShape();
    vertex(bb.b.p.x + bb.b.s.x/2, bb.b.p.y);
    vertex(bb.b.p.x + bb.b.s.x/2, labels[8].p.y+labels[8].s.y);
    vertex(160, labels[8].p.y+labels[8].s.y/2);
    endShape();
    line(bb.ab[0].p.x + bb.ab[0].s.x/2, bb.ab[0].p.y + bb.ab[0].s.y, bb.ab[0].p.x + bb.ab[0].s.x/2, labels[3].p.y);
    line(bb.ab[1].p.x + bb.ab[1].s.x/2, bb.ab[1].p.y + bb.ab[1].s.y, bb.ab[1].p.x + bb.ab[1].s.x/2, labels[2].p.y);
    line(bb.ab[2].p.x + bb.ab[2].s.x/2, bb.ab[2].p.y + bb.ab[2].s.y, bb.ab[2].p.x + bb.ab[2].s.x/2, labels[0].p.y);
    line(bb.ab[3].p.x + bb.ab[3].s.x/2, bb.ab[3].p.y + bb.ab[3].s.y, bb.ab[3].p.x + bb.ab[3].s.x/2, labels[1].p.y);
 /*   beginShape();
    vertex(bb.ab[3].p.x + bb.ab[3].s.x/2, bb.ab[3].p.y + bb.ab[3].s.y);
    vertex(bb.ab[3].p.x + bb.ab[3].s.x/2, labels[1].p.y);
    vertex(displayWidth-160, labels[1].p.y+labels[1].s.y/2);
    endShape();
    beginShape();
    vertex(bb.ab[1].p.x + bb.ab[1].s.x/2, bb.ab[1].p.y + bb.ab[1].s.y);
    vertex(110, labels[0].p.y+labels[0].s.y);
    vertex(110, labels[2].p.y);
    vertex(160, labels[2].p.y+labels[2].s.y/2);
    endShape();
    beginShape();
    vertex(bb.ab[0].p.x + bb.ab[0].s.x/2, bb.ab[0].p.y + bb.ab[0].s.y);
    vertex(bb.ab[0].p.x + bb.ab[0].s.x/2, labels[3].p.y);
    vertex(160, labels[3].p.y+labels[3].s.y/2);
    endShape();  */  
  }
}
