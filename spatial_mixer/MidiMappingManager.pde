class MidiMappingManager {
  ArrayList<MidiMapping> mappings = new ArrayList<MidiMapping>();
  HashMap<String, MidiMapping> midiLookup = new HashMap<String, MidiMapping>(); // Lookup table

  MidiMappingManager() {
    // Constructor
  }

  void loadMappings(String jsonFilePath) {
    try {
      JSONObject json = loadJSONObject(jsonFilePath);
      JSONArray mappingsArray = json.getJSONArray("midiMappings");

      for (int i = 0; i < mappingsArray.size(); i++) {
        JSONObject mappingObj = mappingsArray.getJSONObject(i);

        String type = mappingObj.getString("type");
        String name = mappingObj.getString("name");
        String parameter = mappingObj.getString("parameter");
        String action = mappingObj.getString("action");

        // Create a new mapping based on type
        MidiMapping mapping;

        if (type.equals("cc")) {
          int channel = mappingObj.getInt("channel");
          int[] controllerRange = new int[2];
          controllerRange[0] = mappingObj.getJSONArray("controllerRange").getInt(0);
          controllerRange[1] = mappingObj.getJSONArray("controllerRange").getInt(1);

          int[] valueRange = new int[2];
          valueRange[0] = mappingObj.getJSONArray("valueRange").getInt(0);
          valueRange[1] = mappingObj.getJSONArray("valueRange").getInt(1);

          mapping = new CCMapping(name, parameter, action, channel, controllerRange, valueRange);

          if (mappingObj.hasKey("trackOffset")) {
            ((CCMapping) mapping).trackOffset = mappingObj.getInt("trackOffset");
          }

          // Add to lookup table
          for (int controller = controllerRange[0]; controller <= controllerRange[1]; controller++) {
            String key = generateKey("cc", channel, controller);
            midiLookup.put(key, mapping);
          }
        } else if (type.equals("sysex")) {
          mapping = new SysExMapping(name, parameter, action);

          if (mappingObj.hasKey("pattern")) {
            ((SysExMapping) mapping).setPattern(mappingObj.getString("pattern"));
          } else if (mappingObj.hasKey("prefix") && mappingObj.hasKey("suffix")) {
            ((SysExMapping) mapping).setPrefix(mappingObj.getString("prefix"));
            ((SysExMapping) mapping).setSuffix(mappingObj.getString("suffix"));
          }
        } else {
          println("Unknown mapping type: " + type);
          continue;
        }

        if (mappingObj.hasKey("description")) {
          mapping.description = mappingObj.getString("description");
        }

        mappings.add(mapping);
      }

      println("Loaded " + mappings.size() + " MIDI mappings");
    } catch (Exception e) {
      println("Error loading MIDI mappings: " + e.getMessage());
      e.printStackTrace();
    }
  }

  MidiMapping findMappingForCC(int channel, int number) {
    String key = generateKey("cc", channel, number);
    return midiLookup.get(key);
  }

  ArrayList<MidiMapping> findMappingsForSysEx(byte[] data) {
    ArrayList<MidiMapping> matches = new ArrayList<MidiMapping>();

    for (MidiMapping mapping : mappings) {
      if (mapping instanceof SysExMapping) {
        SysExMapping sysExMapping = (SysExMapping) mapping;

        // Check if this mapping matches the received SysEx message
        if (sysExMapping.matches(data)) {
          matches.add(sysExMapping);
        }
      }
    }

    return matches;
  }

  // Generate a unique key for the lookup table
  String generateKey(String type, int channel, int number) {
    return type + ":" + channel + ":" + number;
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
