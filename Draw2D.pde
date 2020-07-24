// Functions to enable 2D drawing for the interaction buttons and the splashscreen

import android.util.DisplayMetrics;
import processing.opengl.*;
import android.view.*;
import android.graphics.Rect;

int dispHeight;

// Find the size of the display available allowing for the bottom navigation bar
void init2D(){ 
    DisplayMetrics dispMetrics = new DisplayMetrics();
    getActivity().getWindowManager().getDefaultDisplay().getMetrics(dispMetrics);
    dispHeight = dispMetrics.heightPixels;
}

// Set the view/projection matrices so that the 3D coordinates (x,y,0) match the 2D screen pixel (x,y)
void start2D() {
	resetMatrix();
	((PGraphicsOpenGL)g).resetProjection();
	((PGraphicsOpenGL)g).applyProjection(2.0/width,0,0,-1,0,-2.0/height,0,1,0,0,1,-1,0,0,0,1);	
}


// This function is not used anymore. It was needed for debugging some display issues.
String testMetrics(){
//  Context c = getContext();
//  WindowManager wm = (WindowManager)c.getSystemService(Context.WINDOW_SERVICE);
//  WindowMetrics metrics = wm.getCurrentMetrics();
//  View.getLocationInWindow();
//WindowMetrics metrics = windowManager.getCurrentMetrics();

 // View  v = getWindow().getDecorView().getRootView();
  Rect r1 = new Rect();
  Rect r2 = new Rect();
  Rect r3 = new Rect();
  int[] pp = new int[2];
  getWindow().getDecorView().getWindowVisibleDisplayFrame(r1);
  //getWindow().getWindowVisibleDisplayFrame(r2);
  //WindowManager.LayoutParams lp = getWindow().getAttributes();
  getWindow().getDecorView().getLocalVisibleRect(r2);
  getWindow().getDecorView().getGlobalVisibleRect(r3);
  getWindow().getDecorView().getLocationOnScreen(pp);
//  int winTop = getWindow().findViewById(Window.ID_ANDROID_CONTENT).getTop();
//  println(r);
//  println(winTop);
  return r1.toString() + "\n" + r2.toString() + "\n" + r3.toString() + "\n(" + pp[0] + ", " + pp[1] + ")";
}
