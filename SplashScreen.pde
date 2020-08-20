// The opening 'home' splashscreen.

class SplashScreen {
  Control[] controls;
//  PImage im;
  
  SplashScreen() {
    controls = new Control[6];

    controls[0] = new Title(50, 50, displayWidth-100, 120,"THE AUGMENTED REALITY MUSEUM APP");
    controls[1] = new Label(50, 775, displayWidth-100, 100,"The Augmented Reality Museum App is part of");
    controls[2] = new Link(50, 875, displayWidth-100, 100,"THE VIRTUAL CUNEIFORM RECONSTRUCTION PROJECT","http://virtualcuneiform.org/ARMuseum.html");    
    controls[3] = new Button((displayWidth-500)/2, 600, 500, 120, "Start AR Museum");
    controls[4] = new Label(50, 1000, displayWidth-100, (displayWidth-100)/2.11,loadImage("partners.png"));
//    im = loadImage("splashImage.png");  
    controls[5] = new Label(0,200,displayWidth,displayWidth*483.0/1012.0, loadImage("splashImage.png")); 
}

  void draw() {
	  start2D();
    background(255);
    for (int n = 0; n < controls.length; n++) {
      controls[n].draw();
    }            
//    image(im,0,200,displayWidth,displayWidth*im.height/im.width);

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
