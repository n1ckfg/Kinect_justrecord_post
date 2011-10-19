import proxml.*;

String readFilePath = "data";
String readFileName = "shot";
String readFileType = "tga";
String readString = "";
String writeFilePath = "render";
String writeFileName = "shot";
String writeFileType = "tga";
String writeString = "";
int shotNumOrig = 1;
int shotNum = shotNumOrig;
int readFrameNumOrig = 1;
int readFrameNum = readFrameNumOrig;
int readFrameNumMax;
int writeFrameNum = readFrameNum;

File dataFolder;
String[] numFiles; 
int[] timestamps;
int nowTimestamp, lastTimestamp;
float recordedFps = 30; //fps you shot at
float errorAllow = 10; //ms to forgive
String verdict = "";

PImage img;

proxml.XMLElement xmlFile;
XMLInOut xmlIO;
boolean loaded = false;

void setup() {
  countFolder();
  size(640, 480, P2D);
    xmlIO = new XMLInOut(this);
  try {
    xmlIO.loadElement(readFilePath + "/" + readFileName + shotNum + ".xml"); //loads the XML
  }
  catch(Exception e) {
    //if loading failed 
    println("Loading Failed");
  }
}

void xmlEvent(proxml.XMLElement element) {
  //this function is ccalled by default when an XML object is loaded
  xmlFile = element;
  //parseXML(); //appelle la fonction qui analyse le fichier XML
  loaded = true;
  readTimestamps();
}


void draw() {
    if(loaded){
  if (readFrameNum<readFrameNumMax) {
    readString = readFilePath + "/" + readFileName + shotNum + "/" + readFileName + shotNum + "_frame" + readFrameNum + "." + readFileType;
    println("read: " + readString + "     timestamp: " + timestamps[readFrameNum]);
    img = loadImage(readString);
    image(img,0,0);
    if (!checkTimestamps()) {
    writeFile(1);
    readFrameNum++;
    }else{
    writeFile(2);
    readFrameNum++;
    }
  } else {
    exit();
  }
    }
}

void countFolder() {
  dataFolder = new File(sketchPath, readFilePath + "/" + readFileName + shotNum+"/");
  numFiles = dataFolder.list();
  readFrameNumMax = numFiles.length;
}

void writeFile(int reps){
  for(int i=0;i<reps;i++){
    writeString = writeFilePath + "/" + writeFileName + shotNum + "/" + writeFileName + shotNum + "_frame"+writeFrameNum+"."+writeFileType;
    saveFrame(writeString);
    println("written: " + writeString + verdict);
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

boolean checkTimestamps() {
  float q = timestamps[readFrameNum]-timestamps[readFrameNum-1];
  float qq = (1000/recordedFps)+errorAllow;
  verdict = "     diff: " + q + "   min: " + qq;
  if (readFrameNum>readFrameNumOrig && q > qq) {
      return true;
    } else {
      return false;
    }
  }
 

