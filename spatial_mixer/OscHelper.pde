import oscP5.*;
import netP5.*;

class OscHelper {
  OscP5 oscP5;
  NetAddress remoteAddress;
  ParentCallback parentCallback;
  String currentAddress; // Class-level variable for the OSC address

  // Constructor
  OscHelper(PApplet parent, int receivePort, String remoteHost, int remotePort, ParentCallback callback) {
    oscP5 = new OscP5(parent, receivePort);
    remoteAddress = new NetAddress(remoteHost, remotePort);
    parentCallback = callback;
  }

  // Set the current OSC address
  void setAddress(String address) {
    currentAddress = address;
  }

  // Send an OSC message
  void sendMessage(Object... args) {
    try {
      if (currentAddress == null || currentAddress.isEmpty()) {
        println("Error: OSC address is not set.");
        return;
      }
      OscMessage msg = new OscMessage(currentAddress);
      for (Object arg : args) {
        if (arg instanceof Integer) {
          msg.add((int) arg);
        } else if (arg instanceof Float) {
          msg.add((float) arg);
        } else if (arg instanceof String) {
          msg.add((String) arg);
        } else {
          println("Unsupported argument type: " + arg.getClass().getName());
        }
      }
      oscP5.send(msg, remoteAddress);
      println("Sent OSC message: " + currentAddress + " " + java.util.Arrays.toString(args));
    } catch (Exception e) {
      println("Error sending OSC message: " + e.getMessage());
    }
  }

  // Send a generic OSC message with a float argument
  void sendOscMessage(String address, float value) {
    setAddress(address);
    sendMessage(value);
  }

  // Send a volume message to a specific track
  void sendOscVolume(int trackNumber, float volume) {
    setAddress("/track/" + trackNumber + "/volume");
    sendMessage(volume);
  }

  // Send a pan message to a specific track
  void sendOscPan(int trackNumber, float pan) {
    setAddress("/track/" + trackNumber + "/pan");
    sendMessage(pan);
  }

  // Send a mute message to a specific track
  void sendOscMute(int trackNumber, boolean mute) {
    setAddress("/track/" + trackNumber + "/mute");
    sendMessage(mute ? 1 : 0);
  }

  // Send a solo message to a specific track
  void sendOscSolo(int trackNumber, boolean solo) {
    setAddress("/track/" + trackNumber + "/solo");
    sendMessage(solo ? 1 : 0);
  }

  // Send a head roll rotation message
  void sendHeadRoll(float roll) {
    setAddress("/head/roll");
    sendMessage(roll);
  }
  
  // Send a head yaw rotation message
  void sendHeadYaw(float yaw) {
    setAddress("/head/yaw");
    sendMessage(yaw);
  }
  
  // Send a head pitch rotation message
  void sendHeadPitch(float pitch) {
    setAddress("/head/pitch");
    sendMessage(pitch);
  }

  // Send a cube roll rotation message
  void sendCubeRoll(float roll) {
    setAddress("/cube/roll");
    sendMessage(roll);
  }
  
  // Send a cube yaw rotation message
  void sendCubeYaw(float yaw) {
    setAddress("/cube/yaw");
    sendMessage(yaw);
  }
  
  // Send a cube pitch rotation message
  void sendCubePitch(float pitch) {
    setAddress("/cube/pitch");
    sendMessage(pitch);
  }

  // Send a /ypr message with yaw, pitch, and roll values
  void sendYprMessage(float yaw, float pitch, float roll) {
    setAddress("/ypr");
    sendMessage(yaw, pitch, roll);
  }

    // Send a cube pitch rotation message
  void sendSourceAzimuth(int trackNumber,float azimuth) {
    setAddress("/track/" + trackNumber + "/azimuth");
    sendMessage(azimuth);
  }

  // Send a cube zenith rotation message
  void sendSourceZenith(int trackNumber,float zenith) {
    setAddress("/track/" + trackNumber + "/zenith");
    sendMessage(zenith);
  }



  // Handle received OSC messages
  void handleOscEvent(OscMessage msg) {
    if (parentCallback != null) {
      parentCallback.onOscMessageReceived(msg);
    } else {
      println("No callback defined for handling OSC messages.");
    }
  }
}

// Interface for parent callback
interface ParentCallback {
  void onOscMessageReceived(OscMessage msg);
}
