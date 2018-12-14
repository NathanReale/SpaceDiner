import 'dart:typed_data';

RegExp label_exp = RegExp(r"^[a-zA-Z]+$");
const List<String> registers = ["A", "B", "C", "PC", "SP"];

int ParseValue(String val, Map<String, int> labels) {

  // Handle base registers.
  int index = registers.indexOf(val);
  if (index != -1) return index;

  // Indirect registers.
  if (val.startsWith("[") && val.endsWith("]")) {
    String newVal = val.substring(1, val.length-1);
    int index = registers.indexOf(newVal);
    if (index != -1) return index + 0x8;

    int literal = int.tryParse(newVal, radix:16);
    if (literal != null) {
      return 0x11;
    }
  }

  switch (val) {
    case "PUSH":
      return 0x12;
    case "POP":
      return 0x12;
    case "PEAK":
      return 0x13;
  }

  // Literal value.
  int literal = int.tryParse(val, radix:16);
  if (literal != null) {
    if (-1 <= literal && literal <= 0x1f) return literal + 0x20;
    return 0x10;
  }

  // Label.
  if (label_exp.hasMatch(val)) {
    if (labels.containsKey(val)) {
      int offset = labels[val];
      if (-1 <= offset && offset <= 0x1f) return offset + 0x20;
      return 0x10;
    }
    // Could be a label we haven't seen yet.
    return 0x10;
  }

  print("Unable to parse value: $val");
  return -1;
}

Uint16List Assemble(String program) {
  Uint16List result = Uint16List(0x10000);
  int result_counter = 0;

  Map<String, int> labels = Map<String, int>();
  Map<int, String> pending_labels = Map<int, String>();


  List<String> lines = program.split("\n");
  for (var i = 0; i < lines.length; i++) {
    // Skip comments.
    if (lines[i].startsWith(";")) continue;

    List<String> parts = lines[i].split(new RegExp(r"\s+"));
    if (parts.length == 0) continue;

    String cmd = parts[0].toLowerCase();

    // Keep track of labels.
    if (cmd.startsWith(":")) {
      labels[cmd.substring(1)] = result_counter;
      continue;
    }

    if (parts.length < 2) {
      print("Arguments missing on line $i");
      continue;
    }

    int op_code = 0;
    int a_value = 0;
    int b_value = 0;

    bool has_a = true;

    switch (cmd) {
      case "set":
        op_code = 0x01;
        break;
      case "add":
        op_code = 0x02;
        break;
      case "sub":
        op_code = 0x03;
        break;
      case "jze":
        op_code = 0x08;
        break;
      case "jnz":
        op_code = 0x09;
        break;
      case "jsr":
        op_code = 0x0F;
        has_a = false;
        break;
      default:
        print("Unknown operation on line $i: $cmd");
        continue;
    }

    b_value = ParseValue(parts[1], labels);
    if (has_a) a_value = ParseValue(parts[2], labels);

    if (a_value == -1 || b_value == -1) {
      print("Error parsing arguments on line $i");
      continue;
    }

    result[result_counter++] = op_code + (a_value << 4) + (b_value << 10);

    if (b_value == 0x10) {
      int res = int.tryParse(parts[1], radix:16);
      if (res != null) {
        result[result_counter++] = res;
      } else {
        if (labels.containsKey(parts[1])) {
          result[result_counter++] = labels[parts[1]];
        } else {
          result[result_counter] = -1;
          pending_labels[result_counter++] = parts[1];
        }
      }
    } else if (b_value == 0x11) {
      int res = int.tryParse(parts[1].substring(1, parts[1].length-1), radix:16);
      if (res != null) {
        result[result_counter++] = res;
      }
    }
    if (a_value == 0x10) {
      int res = int.tryParse(parts[2], radix:16);
      if (res != null) {
        result[result_counter++] = res;
      } else {
        if (labels.containsKey(parts[1])) {
          result[result_counter++] = labels[parts[2]];
        } else {
          result[result_counter] = -1;
          pending_labels[result_counter++] = parts[2];
        }
      }
    } else if (a_value == 0x11) {
      int res = int.tryParse(parts[2].substring(1, parts[2].length-1), radix:16);
      if (res != null) {
        result[result_counter++] = res;
      }
    }
  }

  // Fill in any pending labels.
  pending_labels.forEach((offset, label) {
    if(labels.containsKey(label)) {
      result[offset] = labels[label];
    } else {
      print("Unknown label: $label");
    }
  });

  return result;
}

