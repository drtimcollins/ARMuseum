// The opening 'home' splashscreen.

class SplashScreen {
  Control[] controls;

  SplashScreen() {
    controls = new Control[5];

    controls[0] = new Title(50, 100, displayWidth-100, 120,"THE AUGMENTED REALITY MUSEUM APP");
    controls[1] = new Label(50, 650, displayWidth-100, 100,"The Augmented Reality Museum App is part of");
    controls[2] = new Link(50, 750, displayWidth-100, 100,"THE VIRTUAL CUNEIFORM RECONSTRUCTION PROJECT","http://virtualcuneiform.org/");    
    controls[3] = new Button((displayWidth-500)/2, 400, 500, 120, "Start AR Museum");
    controls[4] = new Label(50, 1000, displayWidth-100, (displayWidth-100)/2.11,loadImage("partners.png"));
    
  }

  void draw() {
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
