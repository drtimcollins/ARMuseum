# ARMuseum
Augmented Reality Museum for Android. Written using Processing for Android.

## Tabs:
* **ARMuseum**     - Main setup() and draw() functions. setup() initialises display, loads 3D object file and initialises the ARTracker. In draw(), either the splash-screen is displayed or the AR interface itself. 
* **PlyObject**    - Loader for 3D .ply files. Data is encapsulated in the PlyObject class. Rendering to PShapes for the full mesh, wireframe and pointcloud versions.
* **ObjectShapes** - Class to load and store a collection of objects representing the mesh, pointcloud and wireframe forms.
* **SplashScreen** - The opening 'home' splashscreen displaying info, link to VCTR www page and button to enter the AR app.
* **ARButtonBar**  - Class to handle the 2D buttons on the main AR display
* **Controls**     - Various classes implementing controls (buttons and labels) used for the 2D interaction and for the splashscreen
* **Draw2D**       - Functions to enable 2D drawing for the interaction buttons and the splashscreen