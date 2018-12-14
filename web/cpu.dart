import 'dart:typed_data';

class CPU {

  CPU() {
    ram = new Uint16List(0x10000);
  }

  void LoadRam(Uint16List ram_) {
    ram = ram_;
  }

  int GetValue(int op) {
    switch (op) {
      case 0x0:
        return a;
      case 0x1:
        return b;
      case 0x2:
        return c;
      case 0x3:
        return pc;
      case 0x4:
        return sp;
      case 0x8:
        return ram[a];
      case 0x9:
        return ram[b];
      case 0xa:
        return ram[c];
      case 0xb:
        return ram[pc];
      case 0xc:
        return ram[sp];
      case 0x10: // next word
        return ram[pc++];
      case 0x11: // [next word]
        return ram[ram[pc++]];
      case 0x12: // POP
        return ram[sp++];
      case 0x13: // PEAK
        return ram[sp];
    }

    if (op >= 0x1f) return op - 0x20;

    return -1;
  }

  void SetValue(int op, int value) {
    // Make sure the value is within the 16 bit limits.
    while (value < 0) value += 0x10000;
    value = value % 0x10000;

    switch (op) {
      case 0x0:
        a = value;
        break;
      case 0x1:
        b = value;
        break;
      case 0x2:
        c = value;
        break;
      case 0x3:
        pc = value;
        break;
      case 0x4:
        sp = value;
        break;
      case 0x8:
        ram[a] = value;
        break;
      case 0x9:
        ram[b] = value;
        break;
      case 0xa:
        ram[c] = value;
        break;
      case 0xb:
        ram[pc] = value;
        break;
      case 0xc:
        ram[sp] = value;
        break;
      case 0x11:
        ram[ram[pc++]] = value;
        break;
      case 0x12: // PUSH
        ram[--sp] = value;
        break;
      default:
        print("Error setting value: $op");
        break;
    }

  }

  void Step() {
    int cmd = ram[pc++];
    print("cmd = $cmd");

    int op = cmd & 0xF;
    int b_op = (cmd & 0xFC00) >> 10;
    int a_op = (cmd & 0x3F0) >> 4;

    int b_value = GetValue(b_op);

    switch (op) {
      case 0x0: // NOP
        break;
      case 0x1: // SET
        SetValue(a_op, b_value);
        break;
      case 0x2: // ADD
        int a_value = GetValue(a_op);
        SetValue(a_op, a_value + b_value);
        break;
      case 0x3: // SUB
        int a_value = GetValue(a_op);
        SetValue(a_op, a_value - b_value);
        break;
      case 0x8: // JZE
        int a_value = GetValue(a_op);
        if (b_value == 0) {
          pc = a_value;
        }
        break;
      case 0x9: // JNZ
        int a_value = GetValue(a_op);
        if (b_value != 0) {
          pc = a_value;
        }
        break;
      case 0xF: // JSR
        ram[--sp] = pc;
        pc = b_value;
        break;

      default:
        print("Unimplemented command: $op");
    }

    print("After step: A=$a B=$b C=$c PC=$pc SP=$sp");
  }

  void Reset() {
    pc = 0;
    sp = 0xFFFF;
    a = b = c  = 0;
  }

  // Registers
  int pc = 0;
  int sp = 0xFFFF;
  int a = 0;
  int b = 0;
  int c = 0;

  // Ram
  Uint16List ram;
}