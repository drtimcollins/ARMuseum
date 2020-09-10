class HelpScreen {
  HelpLabel[] labels;
  boolean isPressed = false;
  boolean isClicked = false;
  Link fb;

  String[] helpText = {"Surface grid (on/off)", "Help (open/close)", "Reconstruct Exhibits", "Arrange Exhibits", "Point cloud", "Wireframe", "Wireframe + Texture", "Full Texture", "Rotate exhibits"};
  HelpScreen() {
    labels = new HelpLabel[10];
    float[] offsets = {40, 170, -40, -170, -90, -10, 40, 250, -170};
    for (int n = 0; n < 4; n++) {
      labels[n] = new HelpLabel(180+offsets[n], 200 + 80*n, displayWidth-360, 60, helpText[n]);
    }
    for (int n = 0; n < 5; n++) {
      labels[n+4] = new HelpLabel(180+offsets[n+4], dispHeight-10-100-70-80 - 80*(n==4?n-1:n), displayWidth-(n==2 ? 360 : 440), 60, helpText[n+4]);
    }
    labels[9] = new HelpLabel(20, dispHeight/2 - 120, displayWidth-40, 100, "The AR Museum App (version 0.9.1)");
    labels[9].isMain = true;
    fb = new Link(20, dispHeight/2+10, displayWidth-40, 120, feedbackRequest, feedbackURL);
    fb.size = 30; fb.hasBG = true;
  }

  void draw() {  
    noLights();
    isClicked = (!mousePressed && isPressed);    // True only if the mouse has just been released
    isPressed = mousePressed;                 

    fill(255);
    bb.draw();
    for (int n = 0; n < labels.length; n++) {
      labels[n].draw();
    }
    fb.draw();
    noFill();

    int shorten = -10;
    stroke(#FFFFFF); 
    strokeWeight(6);
    for (int n = 0; n < 2; n++) {
      line(bb.b.p.x + bb.b.s.x/2, bb.b.p.y+shorten, bb.b.p.x + bb.b.s.x/2, labels[8].p.y+labels[8].s.y);
      line(bb.vb[0].p.x + bb.vb[0].s.x/2, bb.vb[0].p.y+shorten, bb.vb[0].p.x + bb.vb[0].s.x/2, labels[4].p.y+labels[4].s.y);
      line(bb.vb[1].p.x + bb.vb[1].s.x/2, bb.vb[1].p.y+shorten, bb.vb[1].p.x + bb.vb[1].s.x/2, labels[5].p.y+labels[5].s.y);
      line(bb.vb[2].p.x + bb.vb[2].s.x/2, bb.vb[2].p.y+shorten, bb.vb[2].p.x + bb.vb[2].s.x/2, labels[6].p.y+labels[6].s.y);
      line(bb.vb[3].p.x + bb.vb[3].s.x/2, bb.vb[3].p.y+shorten, bb.vb[3].p.x + bb.vb[3].s.x/2, labels[7].p.y+labels[7].s.y);
      line(bb.ab[0].p.x + bb.ab[0].s.x/2, bb.ab[0].p.y + bb.ab[0].s.y - shorten, bb.ab[0].p.x + bb.ab[0].s.x/2, labels[3].p.y);
      line(bb.ab[1].p.x + bb.ab[1].s.x/2, bb.ab[1].p.y + bb.ab[1].s.y - shorten, bb.ab[1].p.x + bb.ab[1].s.x/2, labels[2].p.y);
      line(bb.ab[2].p.x + bb.ab[2].s.x/2, bb.ab[2].p.y + bb.ab[2].s.y - shorten, bb.ab[2].p.x + bb.ab[2].s.x/2, labels[0].p.y);
      line(bb.ab[3].p.x + bb.ab[3].s.x/2, bb.ab[3].p.y + bb.ab[3].s.y - shorten, bb.ab[3].p.x + bb.ab[3].s.x/2, labels[1].p.y);
      stroke(#1EAEDB); 
      strokeWeight(4);
    }
    if (labels[9].isClicked)
      guiMode = GuiModes.SPLASHSCREEN;
    else if (isClicked)
      guiMode = GuiModes.ARINTERFACE;
  }
}
