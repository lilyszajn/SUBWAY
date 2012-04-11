/*Using background subtraction to display a user in front of a backdrop with a photo of a sandwich in between their hands
that changes size based on hand location. A photo is taken and printed upon button press/key press and printed using auto-printer.rb
script using a Fuji Film ASK 2500 dye-sub printer. Photos can also be uploaded to Flickr on key press using these instructions
http://frontiernerds.com/upload-to-flickr-from-processing*/

import processing.video.*;
import javax.imageio.*;
import java.awt.image.*;
//import com.aetrion.flickr.*; //for posting to flickr
//import postdata.*; //for posting to cakemix db
import processing.serial.*;

import SimpleOpenNI.*;
SimpleOpenNI kinect;

PVector prevRightHandLocation;
PVector prevLeftHandLocation;

//int[] userMap; //background subtraction for kinect

//background subtraction stuff
//int numPixels;
//int[] backgroundPixels;
Capture video; //rgb for background subtraction
float threshold = 60; //threshold for background subtraction

PImage backgroundImage; //RGB image
PImage backdropImage; //background image (jpg)
PImage[] images = new PImage[2];//array for sandwiches

PFont inches;

Serial myPort; //set up the incoming serial data from the button trigger (arduino)
int inByte = 0; //set inbyte to 0

//boolean autoCalib=true; //to be used for non-calibration use

void setup() {
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  kinect.enableRGB();

  // turn on user tracking
  kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_ALL);

  //turn on depth color alignment
  kinect.alternativeViewPointDepthToImage();

  size(640, 480); 
  fill(255, 0, 0);
  prevRightHandLocation = new PVector(0, 0, 0);
  prevLeftHandLocation = new PVector(0, 0, 0);

  //load the sandwich image
  //sandwich = loadImage("Subway.png");

  //load the background image
  backdropImage = loadImage("TECHUP.jpg");

  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);

  // Set up the camera.
  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } 
  else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i + " " + cameras[i]);
    }

    video = new Capture(this, 640, 480, cameras[1]);
    video.start();
    backgroundImage = createImage(video.width, video.height, RGB);

    // You can get the list of resolutions (width x height x fps)  
    // supported capture device by calling the resolutions()
    // method. It must be called after creating the capture 
    // object. 
    Resolution[] res = video.resolutions();
    println("Supported resolutions:");
    for (int i = 0; i < res.length; i++) { 
      println(res[i].width + "x" + res[i].height + ", " + 
        res[i].fps + " fps (" + res[i].fpsString +")");
    }
  }      
  loadPixels();

  inches = loadFont("HighwayGothicNarrow-48.vlw");//("AdobeArabic-Bold-200.vlw");
  textFont(inches, 40);
}

void draw() {
   image(backdropImage, 0, 0, width, height);
  //scale(2);
  kinect.update();
  //PImage rgbImage = kinect.rgbImage();
  // Capture video
  if (video.available()) {
    video.read();
  }
  // We are looking at the video's pixels, the memorized backgroundImage's pixels, as well as accessing the display pixels. 
  // So we must loadPixels() for all!
  loadPixels();
  video.loadPixels(); 
  backgroundImage.loadPixels();

  // Begin loop to walk through every pixel
  for (int x = 0; x < video.width; x ++ ) {
    for (int y = 0; y < video.height; y ++ ) {
      int loc = x + y*video.width; // Step 1, what is the 1D pixel location
      color fgColor = video.pixels[loc]; // Step 2, what is the foreground color

      // Step 3, what is the background color
      color bgColor = backgroundImage.pixels[loc];

      // Step 4, compare the foreground and background color
      float r1 = red(fgColor);
      float g1 = green(fgColor);
      float b1 = blue(fgColor);
      float r2 = red(bgColor);
      float g2 = green(bgColor);
      float b2 = blue(bgColor);
      float diff = dist(r1, g1, b1, r2, g2, b2);

      // Step 5, Is the foreground color different from the background color
      if (diff > threshold) {
        // If so, display the foreground color
        pixels[loc] = fgColor;
      }//difference in background vs. foreground
    }//pixel loop width
  }//pixel loop height
  updatePixels();

  // make a vector of ints to store the list of users
  IntVector userList = new IntVector();
  // write the list of detected users
  // into our vector
  kinect.getUsers(userList);

  // if we found any users
  if (userList.size() > 0) {
    // get the first user
    int userId = userList.get(0);

    // if we're successfully calibrated
    if (kinect.isTrackingSkeleton(userId)) {

      // make a vector to store the left hand
      PVector rightHand = new PVector();
      PVector leftHand = new PVector();
      //PVector head = new PVector();
      // put the position of the left hand into that vector
      float confidence = kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_LEFT_HAND, rightHand);
      kinect.getJointPositionSkeleton(userId, SimpleOpenNI.SKEL_RIGHT_HAND, leftHand);
      //set the right hand as confidence, so if the user is lost, it looks for a new one right away
      if (confidence > 0.5) {
      // convert the detected hand position
      // to "projective" coordinates
      // that will match the depth image
      PVector convertedRightHand = new PVector();
      kinect.convertRealWorldToProjective(rightHand, convertedRightHand);
      // and display it      
      PVector convertedLeftHand = new PVector();
      kinect.convertRealWorldToProjective(leftHand, convertedLeftHand);
      float subwaySizeRight = convertedRightHand.dist(convertedLeftHand);
      float subwaySizeLeft = convertedLeftHand.dist(convertedRightHand);
      float inches = subwaySizeLeft / 25.4;
      //make an array of the sandwich images
      for ( int i = 0; i< images.length; i++ )
      {
        images[i] = loadImage( i + ".png" ); //make sure images 0.png - 2.png exist
        smooth();
        image(images[i], convertedRightHand.x, convertedRightHand.y, subwaySizeLeft, 100 );   // make sure images "0.jpg" to "11.jpg" exist
      }
      //display inches 
      fill(250, 250, 210);
      scale(1.5);
      if (inches > 0) {
        text(inches + " Inches", 150, 250);
        println(inches);
      }
      //reset the hand positions
      prevRightHandLocation = convertedRightHand;
      prevLeftHandLocation = convertedLeftHand;
      }//confidence level
    }//user list
  }//tracking loop
}//draw loop

void serialEvent (Serial myPort) {
  int inByte = myPort.read();
  if (inByte == '1') {
    //reset inbyte to 0
    inByte = 0;
    println(inByte);
    String incoming = myPort.readStringUntil('\n');
    saveFrame("Subway######.jpg");
  }
}

//debugging trigger testing
void keyPressed() {
  if (key == ' ') {
    saveFrame("Subway###.jpg");
    println("picture saved!");
  }
}
void mousePressed() {
  // Copying the current frame of video into the backgroundImage object
  // Note copy takes 5 arguments:
  // The source image
  // x,y,width, and height of region to be copied from the source
  // x,y,width, and height of copy destination
  backgroundImage.copy(video, 0, 0, video.width, video.height, 0, 0, video.width, video.height);
  backgroundImage.updatePixels();
}
// user-tracking callbacks! void onNewUser(int userId) {
void onNewUser(int userID) {
  println("start pose detection"); 
  kinect.startPoseDetection("Psi", userID);
}

void onEndCalibration(int userId, boolean successful) { 
  if (successful) {
    println(" User calibrated !!!"); 
    kinect.startTrackingSkeleton(userId);
  } 
  else {
    println(" Failed to calibrate user !!!"); 
    kinect.startPoseDetection("Psi", userId);
  }
}
void onStartPose(String pose, int userId) { 
  println("Started pose for user"); 
  kinect.stopPoseDetection(userId); 
  kinect.requestCalibrationSkeleton(userId, true);
}


/*// user-tracking callbacks without calibration!
 void onNewUser(int userId)
 {
 println("onNewUser - userId: " + userId);
 println("  start pose detection");
 
 if (autoCalib)
 kinect.requestCalibrationSkeleton(userId, true);
 else    
 kinect.startPoseDetection("Psi", userId);
 }
 
 void onEndCalibration(int userId, boolean successful) {
 if (successful) { 
 println("  User calibrated !!!");
 kinect.startTrackingSkeleton(userId);
 } 
 else { 
 println("  Failed to calibrate user !!!");
 kinect.startPoseDetection("Psi", userId);
 }
 }
 void onStartPose(String pose, int userId) { 
 println("Started pose for user"); 
 kinect.stopPoseDetection(userId); 
 kinect.requestCalibrationSkeleton(userId, true);
 }*/
