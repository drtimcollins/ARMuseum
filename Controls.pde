// Various controls (buttons and labels) used for the 2D interaction and for the splashscreen

class Control {
  PVector p, s;
  Control(float x, float y, float w, float h) {
    p = new PVector(x, y);
    s = new PVector(w, h);
  }
  void draw() {}
  boolean hitTest() {
    // Return true if the mouse position is within 15 pixels of the control border
    return (mouseX > p.x-15 && mouseX < p.x+s.x+15 && mouseY > p.y-15 && mouseY < p.y+s.y+15);
  }
}

class HelpLabel extends Control {
  String labelText;
  HelpLabel(float x, float y, float w, float h, String label) {
    super(x, y, w, h);
    labelText = label;
  }
  void draw() {
    strokeWeight(2);
    textSize(30);
    fill(255,255,245);
    stroke(0);
    rect(p.x, p.y, s.x, s.y, 20);
    textAlign(CENTER, CENTER);
    fill(#007cbf);
    text(labelText, p.x+s.x/2, p.y+s.y/2);
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
  void draw() {
    isClicked = (!mousePressed && isPressed);    // True only if the mouse has just been released from the button.
    isPressed = (mousePressed && hitTest());     // True is the mouse is pressed and over the button. 

    if (isImageButton) {
      tint(isPressed ? #0088FF : #FFFFFF, isPressed ? 100 : 255);
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
  void draw() {
    isClicked = (!mousePressed && isPressed);    // True only if the mouse has just been released from the button.
    isPressed = (mousePressed && hitTest());     // True is the mouse is pressed and over the button. 
    fill(isPressed ? #FF0000 : #1EAEDB);
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

  void draw() {
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
  void draw() {
    textFont(boldFont, 50);
    textAlign(CENTER, CENTER);
    fill(#1EAEDB);
    text(labelText, p.x, p.y, s.x, s.y);
    textFont(normalFont, 40);
  }
}
