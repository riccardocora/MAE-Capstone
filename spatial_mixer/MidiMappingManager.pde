class MidiMappingManager {
  ArrayList<MidiMapping> mappings = new ArrayList<MidiMapping>();
  HashMap<String, MidiMapping> midiLookup = new HashMap<String, MidiMapping>(); // Lookup table
  HashMap<String, SysExMapping> sysExLookup = new HashMap<String, SysExMapping>(); // SysEx lookup table
  ArrayList<String> availableDevices = new ArrayList<String>(); // List of devices with mappings

  MidiMappingManager() {
    // Constructor
  }

  void loadMappings(String jsonFilePath, String selectedDevice) {
    try {
      JSONObject json = loadJSONObject(jsonFilePath);
      JSONObject devices = json.getJSONObject("devices");

      // Populate available devices
      availableDevices.clear();
      for (Object key : devices.keys()) {
        String device = (String) key; // Explicitly cast to String
        availableDevices.add(device);
      }

      // Load mappings for the selected device
      if (devices.hasKey(selectedDevice)) {
        JSONArray mappingsArray = devices.getJSONObject(selectedDevice).getJSONArray("midiMappings");
        mappings.clear();
        for (int i = 0; i < mappingsArray.size(); i++) {
          JSONObject mappingObj = mappingsArray.getJSONObject(i);
          String type = mappingObj.getString("type");
          String name = mappingObj.getString("name");
          String parameter = mappingObj.getString("parameter");
          String action = mappingObj.getString("action");

          MidiMapping mapping = createMapping(type, mappingObj, name, parameter, action);
          if (mapping != null) {
            if (mappingObj.hasKey("description")) {
              mapping.description = mappingObj.getString("description");
            }
            mappings.add(mapping);
          }
        }
        println("Loaded " + mappings.size() + " MIDI mappings for device: " + selectedDevice);
      } else {
        println("No mappings found for device: " + selectedDevice);
      }
    } catch (Exception e) {
      println("Error loading MIDI mappings: " + e.getMessage());
      e.printStackTrace();
    }
  }

  MidiMapping createMapping(String type, JSONObject mappingObj, String name, String parameter, String action) {
    if (type.equals("cc")) {
      int channel = mappingObj.getInt("channel");
      int[] controllerRange = mappingObj.getJSONArray("controllerRange").getIntArray();
      int[] valueRange = mappingObj.getJSONArray("valueRange").getIntArray();

      CCMapping ccMapping = new CCMapping(name, parameter, action, channel, controllerRange, valueRange);
      if (mappingObj.hasKey("trackOffset")) {
        ccMapping.trackOffset = mappingObj.getInt("trackOffset");
      }

      for (int controller = controllerRange[0]; controller <= controllerRange[1]; controller++) {
        midiLookup.put(generateKey("cc", channel, controller), ccMapping);
      }
      return ccMapping;
    } else if (type.equals("sysex")) {
      SysExMapping sysExMapping = new SysExMapping(name, parameter, action);
      if (mappingObj.hasKey("pattern")) {
        sysExMapping.setPattern(mappingObj.getString("pattern"));
        sysExLookup.put(mappingObj.getString("pattern"), sysExMapping);
      } else if (mappingObj.hasKey("prefix") && mappingObj.hasKey("suffix")) {
        sysExMapping.setPrefix(mappingObj.getString("prefix"));
        sysExMapping.setSuffix(mappingObj.getString("suffix"));
      }
      return sysExMapping;
    } else {
      println("Unknown mapping type: " + type);
      return null;
    }
  }

  MidiMapping findMappingForCC(int channel, int number) {
    String key = generateKey("cc", channel, number);
    return midiLookup.get(key);
  }

  ArrayList<MidiMapping> findMappingsForSysEx(byte[] data) {
    String hexString = bytesToHexString(data);
    ArrayList<MidiMapping> matches = new ArrayList<MidiMapping>();

    if (sysExLookup.containsKey(hexString)) {
      matches.add(sysExLookup.get(hexString));
    }
    return matches;
  }

  // Generate a unique key for the lookup table
  String generateKey(String type, int channel, int number) {
    return type + ":" + channel + ":" + number;
  }

  // Utility method to convert byte array to hex string
  String bytesToHexString(byte[] bytes) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < bytes.length; i++) {
      sb.append(String.format("%02X", bytes[i])); // Convert each byte to a 2-character hex string
      if (i < bytes.length - 1) {
        sb.append(" "); // Add a space between bytes for readability
      }
    }
    return sb.toString();
  }
}

// Base class for all MIDI mappings
abstract class MidiMapping {
  String name;
  String parameter;
  String action;
  String description;

  MidiMapping(String name, String parameter, String action) {
    this.name = name;
    this.parameter = parameter;
    this.action = action;
  }

  abstract float getNormalizedValue(int value);

  int getTrackNumber(int controllerNumber) {
    return 0; // Override in subclasses as needed
  }
}

// Class for Control Change (CC) mappings
class CCMapping extends MidiMapping {
  int channel;
  int[] controllerRange = new int[2];
  int[] valueRange = new int[2];
  int trackOffset = 0;

  CCMapping(String name, String parameter, String action, int channel, int[] controllerRange, int[] valueRange) {
    super(name, parameter, action);
    this.channel = channel;
    this.controllerRange = controllerRange;
    this.valueRange = valueRange;
  }

  boolean matches(int channel, int controllerNumber, int value) {
    // Check if the channel and controller number match this mapping
    if (this.channel == channel && 
        controllerNumber >= this.controllerRange[0] && 
        controllerNumber <= this.controllerRange[1]) {
      
      // For triggers that only activate on specific values
      if (action.equals("selectSource") || action.equals("toggleMute") || action.equals("toggleSolo")) {
        return value >= this.valueRange[0] && value <= this.valueRange[1];
      }
      
      // For continuous controllers like faders that work across the whole range
      return true;
    }
    
    return false;
  }

  float getNormalizedValue(int value) {
    // Map the value to a normalized range (0.0 - 1.0)
    return map(value, valueRange[0], valueRange[1], 0, 1);
  }

  int getTrackNumber(int controllerNumber) {
    // Calculate the track number based on the controller number and track offset
    return (controllerNumber - controllerRange[0]) + trackOffset;
  }
}

// Class for System Exclusive (SysEx) mappings
class SysExMapping extends MidiMapping {
  String prefix;
  String suffix;
  String pattern;
  boolean usePattern = false;

  SysExMapping(String name, String parameter, String action) {
    super(name, parameter, action);
  }

  void setPrefix(String prefix) {
    this.prefix = prefix;
    this.usePattern = false;
  }

  void setSuffix(String suffix) {
    this.suffix = suffix;
    this.usePattern = false;
  }

  void setPattern(String pattern) {
    this.pattern = pattern;
    this.usePattern = true;
  }

  boolean matches(byte[] data) {
    if (usePattern) {
      return matchesPattern(data);
    } else {
      return matchesPrefixSuffix(data);
    }
  }

  boolean matchesPrefixSuffix(byte[] data) {
    // Check if data starts with prefix and ends with suffix
    String hexString = bytesToHexString(data);
    return hexString.startsWith(prefix) && hexString.endsWith(suffix);
  }

  float getNormalizedValue(int value) {
    // For SysEx, this is more complex
    // We would need to extract the value from the SysEx message
    // For now, return a default
    return 0.5;
  }

  // Utility method to convert byte array to hex string
  String bytesToHexString(byte[] bytes) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < bytes.length; i++) {
      sb.append(String.format("%02X", bytes[i]));
      if (i < bytes.length - 1) {
        sb.append(" ");
      }
    }
    return sb.toString();
  }

  // Parse hex string pattern into byte array with range indicators
  byte[][] parsePatternToByteRanges(String pattern) {
    String[] parts = pattern.split(" ");
    byte[][] ranges = new byte[parts.length][2];

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];

      // If this is a range pattern like [00-2F]
      if (part.startsWith("[") && part.endsWith("]")) {
        String range = part.substring(1, part.length() - 1);
        String[] rangeParts = range.split("-");

        if (rangeParts.length == 2) {
          byte min = (byte) Integer.parseInt(rangeParts[0], 16);
          byte max = (byte) Integer.parseInt(rangeParts[1], 16);
          ranges[i][0] = min;
          ranges[i][1] = max;
        }
      } 
      // If this is a fixed value
      else {
        byte value = (byte) Integer.parseInt(part, 16);
        ranges[i][0] = value;
        ranges[i][1] = value;
      }
    }

    return ranges;
  }

  // Extract a value from a SysEx message based on a parameter index
  float extractValueFromSysEx(byte[] data, int paramIndex, int min, int max) {
    if (paramIndex < data.length) {
      return map(data[paramIndex] & 0xFF, 0, 127, min, max);
    }
    return 0;
  }

  // This is a more sophisticated matcher for SysEx messages
  boolean matchesPattern(byte[] data) {
    // Parse the pattern
    byte[][] patternRanges = parsePatternToByteRanges(pattern);

    // Quick length check
    if (data.length != patternRanges.length) {
      return false;
    }

    // Check each byte against its allowed range
    for (int i = 0; i < data.length; i++) {
      byte b = data[i];
      byte min = patternRanges[i][0];
      byte max = patternRanges[i][1];

      if (b < min || b > max) {
        return false;
      }
    }

    return true;
  }
}
