// Class to handle the 2D buttons on the main AR display

class ARButtonBar {
  Button b;
  Button[] vb, ab;
  PImage bIm;
  String[] vbIm = {"pointCloud.png", "wireframe.png", "wireTex.png", "tex.png"};
  String[] abIm = {"autoline1.png", "autoline2.png", "gridOn.png", "help.png"};
  Label techInfo;

  ARButtonBar() {
    b = new Button(10, dispHeight-10-100, 100, 100, loadImage("rotate.png"));
    vb = new Button[4];
    ab = new Button[4];
    techInfo = new Label(50, 650, displayWidth-100, 300, "Technical info");

    for (int n = 0; n < 4; n++)
      vb[n] = new Button(width+20-130*(4-n), dispHeight-10-100, 100, 100, loadImage(vbIm[n]));
    for (int n = 0; n < 4; n++)
      ab[n] = new Button(n<2 ? 10+130*n : width+20-130*(4-n), 30, 100, 100, loadImage(abIm[n]));
  }
  void draw() {
    start2D();
    b.draw();
    for (int n = 0; n < 4; n++)
      vb[n].draw();
    for (int n = 0; n < 4; n++)
      ab[n].draw();


    if(guiMode == GuiModes.ARINTERFACE){
      if (b.isClicked) {
        b.isClicked = false;
        rot = 0.05 - rot;
      }
      if (vb[0].isClicked) objMode = objModes.POINTCLOUD;
      if (vb[1].isClicked) objMode = objModes.WIREFRAME;
      if (vb[2].isClicked) objMode = objModes.WIRETEX;
      if (vb[3].isClicked) objMode = objModes.FULL;    
      if (ab[0].isClicked) alignMode = (alignMode==alignModes.ALIGNED) ? alignModes.FREE : alignModes.ALIGNED;
      if (ab[1].isClicked) alignMode = (alignMode==alignModes.OVERLAP) ? alignModes.FREE : alignModes.OVERLAP;
      if (ab[2].isClicked) gridOn = !gridOn;
    }
    if (ab[3].isClicked) guiMode = (guiMode == GuiModes.HELPSCREEN) ? GuiModes.ARINTERFACE :  GuiModes.HELPSCREEN;

    for (int n = 0; n < 4; n++)
      vb[n].isClicked = false;
    for (int n = 0; n < 4; n++)
      ab[n].isClicked = false;
  }

  void draw(String x) {  // Used for debugging to display extra technical info in the middle of the display
    techInfo.labelText = x;
    draw();
    techInfo.draw();
  }

  boolean hitTest() {
    boolean result = b.hitTest();
    for (int n = 0; n < 4; n++) result = result || vb[n].hitTest();
    for (int n = 0; n < 4; n++) result = result || ab[n].hitTest();
    return result;
  }
}
