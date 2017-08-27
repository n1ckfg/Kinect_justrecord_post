//This is a utility to post-process and check for drop frames in Kinect recordings.
//Copy the data folder recorded by Kinect_just_record before you start.

//**************************************
int sW = 640;
int sH = 480;
float recordedFps = 30; //fps you shot at
int numberOfFolders = 1;  //right now you must set this manually!
String readFilePath = "data";
String readFileName = "shot";
String readFileType = "tga"; // record with tga for speed
String writeFilePath = "render";
String writeFileName = "shot";
String writeFileType = "tga";  // render with png to save space
float zscale = 1; //orig 3, 1 looks better in 2D image but 3 looks better for OBJ
float zskew = 10;
//**************************************

String readString = "";
String writeString = "";
int shotNumOrig = 1;
int shotNum = shotNumOrig;
int readFrameNumOrig = 1;
int readFrameNum = readFrameNumOrig;
int readFrameNumMax;
int writeFrameNum = readFrameNum;
int addFrameCounter = 0;
int subtractFrameCounter = 0;
String xmlFileName = readFilePath + "/" + readFileName + shotNum + ".xml";

float[][] gray = new float[sH][sW];

File dataFolder;
String[] numFiles; 
int[] timestamps;
int nowTimestamp, lastTimestamp;
float idealInterval = 1000 / recordedFps;
float errorAllow = 0;
String diffReport = "";

PImage img,buffer;

XMLElement xmlFile;
XMLInOut xmlIO;
boolean loaded = false;

void setup() {
  size(50, 50, P3D);
  surface.setSize(sW, sH);
  
  reInit();

  //smooth();
  stroke(255);
}

void xmlLoad() {
  xmlIO = new XMLInOut(this);
  try {
    xmlIO.loadElement(xmlFileName); //loads the XML
  } catch (Exception e) {
    //if loading failed 
    println("Loading Failed");
  }
}

void reInit() {
  readFrameNum = readFrameNumOrig;
  writeFrameNum = readFrameNum;
  addFrameCounter = 0;
  subtractFrameCounter = 0;
  xmlFileName = readFilePath + "/" + readFileName + shotNum + ".xml";
  errorAllow = 0;
  loaded = false;
  countFolder();
  xmlLoad();
}

void xmlEvent(XMLElement element) {
  //this function is ccalled by default when an XML object is loaded
  xmlFile = element;
  //parseXML(); //appelle la fonction qui analyse le fichier XML
  loaded = true;
  readTimestamps();
  println("average interval: " + getAverageInterval() + " ms   |   correct interval: " + idealInterval + " ms");
}


void draw() {
  background(0);
  if (shotNum<=numberOfFolders) {
    if (loaded) {
      if (readFrameNum<readFrameNumMax) {
        readString = readFilePath + "/" + readFileName + shotNum + "/" + readFileName + shotNum + "_frame" + readFrameNum + "." + readFileType;
        println("-- read: " + readString + "     timestamp: " + timestamps[readFrameNum-1]  + " ms");
        img = loadImage(readString);
        image(img, 0, 0);
        checkTimestamps();
        if (!checkTimeAhead()&&checkTimeBehind()) { //behind and not ahead; add a missing frame
          //********************
          int q = 1;
          if (readFrameNum>readFrameNumOrig) {
            q = timestamps[readFrameNum-1] - timestamps[readFrameNum-2];
          }
          writeFile(int(q/int(idealInterval)));
          //********************
          addFrameCounter+=errorAllow/idealInterval;
          diffReport += "   ADDED FRAMES";
          errorAllow -= idealInterval;
        } else if (checkTimeAhead()&&!checkTimeBehind()) {  //ahead and not behind; skip an extra frame
          subtractFrameCounter++;
          diffReport += "   REMOVED FRAMES";
          errorAllow += idealInterval;
        } else if (!checkTimeAhead()&&!checkTimeBehind()) {  //not ahead and not behind; do nothing
          diffReport += "   OK";
          writeFile(1);
        }
        println("written: " + writeString + diffReport);
        readFrameNum++;
      } else {
        renderVerdict();
        if (shotNum==numberOfFolders) {
          exit();
        } else {
          shotNum++;
          reInit();
        }
      }
    }
  } else {
    exit();
  }
  
}

void countFolder() {
  String url = sketchPath("") + readFilePath + "/" + readFileName + shotNum;
  dataFolder = new File(url);
  numFiles = dataFolder.list();
  println(dataFolder);
  readFrameNumMax = numFiles.length+1;
}

void writeFile(int reps) {
  for (int i=0;i<reps;i++) {
    writeString = writeFilePath + "/" + writeFileName + shotNum + "/" + writeFileName + shotNum + "_frame"+writeFrameNum+"."+writeFileType;
    
    saveFrame(writeString);

    //println("written: " + writeString + diffReport);
    writeFrameNum++;
  }
}

void readTimestamps() {
  timestamps = new int[numFiles.length];
  for (int i=0;i<numFiles.length;i++) {
    timestamps[i] = int(xmlFile.getChild(i).getAttribute("timestamp"));
    println(timestamps[i]);
  }
}

void checkTimestamps() {
  if (readFrameNum>readFrameNumOrig) {
    float q = timestamps[readFrameNum-1]-timestamps[readFrameNum-2];
    diffReport = "     diff: " + int(q) + " ms" + "   min: " + int(idealInterval)+ " ms" + "   cumulative error: " + int(errorAllow) + " ms";
    errorAllow += q-idealInterval;
  }
}

boolean checkTimeBehind() {
  if (errorAllow>idealInterval) {
    return true;
  } else {
    return false;
  }
}

boolean checkTimeAhead() {
  if (errorAllow < -1 * idealInterval) {
    return true;
  } else {
    return false;
  }
}

void renderVerdict() {
  //int timeDiff = int(30*((timestamps[timestamps.length-1] - timestamps[0])/1000));
  println("SHOT" + shotNum + " COMPLETE");
  /*
   println(int(addFrameCounter) + " dropped frames added");
   println(int(subtractFrameCounter) + " extra frames removed");
   */
}

float getAverageInterval() {
  float q = ((timestamps[3] - timestamps[2]) + (timestamps[1] - timestamps[0]))/2;
  for (int i=4;i<timestamps.length/4;i++) {
    float qq = ((timestamps[i+3] - timestamps[i+2]) + (timestamps[i+1] - timestamps[i]))/2;
    q = (q+qq)/2;
  }
  return q;
}

static final int gray(color value) { 
  return max((value >> 16) & 0xff, (value >> 8 ) & 0xff, value & 0xff);
}