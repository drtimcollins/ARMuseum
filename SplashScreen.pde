// The opening 'home' splashscreen.

class SplashScreen {
  Control[] controls;
//  PImage im;
  
  SplashScreen() {
    controls = new Control[6];

    controls[0] = new Title(50, 20, displayWidth-100, 120,"THE AUGMENTED REALITY MUSEUM APP");
//    controls[1] = new Label(50, 775, displayWidth-100, 100,"The Augmented Reality Museum App is part of");
    controls[1] = new Link(50, 740, displayWidth-100, 150,"THE VIRTUAL CUNEIFORM TABLET RECONSTRUCTION PROJECT","https://virtualcuneiform.org/ARMuseum.html");    
    controls[3] = new Button((displayWidth-500)/2, 580, 500, 120, "Start AR Museum");
    controls[2] = new Label(50, 1000, displayWidth-100, (displayWidth-100)/2.11f,loadImage("partners.png"));
    controls[4] = new Label(0,170,displayWidth,displayWidth*483.0f/1012.0f, loadImage("splashImage.png")); 
    controls[5] = new Link(50, 870, displayWidth-100, 150, feedbackRequest, feedbackURL);
    ((Link)controls[5]).size = 30;
}

  void draw() {
	  start2D();
    background(255);
    for (int n = 0; n < controls.length; n++) {
      controls[n].draw();
    }            

    if (((Button)controls[3]).isClicked) {
      ((Button)controls[3]).isClicked = false;
      guiMode = GuiModes.ARINTERFACE;
    }
  }
}
