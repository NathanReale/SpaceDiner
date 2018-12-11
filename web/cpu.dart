import 'dart:typed_data';

class CPU {

  CPU() {
    pc = 0x0;
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
        return h;
      case 0x4:
        return pc;
      case 0x9:
        return ram[a];
      case 0xa:
        return ram[b];
      case 0xb:
        return ram[c];
      case 0xc:
        return ram[h];
      case 0xd:
        return ram[pc];
    }

    if (op == 0x10) return ram[pc++];
    if (op == 0x11) return ram[ram[pc++]];
    if (op >= 0x1f) return op - 0x20;

    return -1;
  }

  void SetValue(int op, int value) {
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
        h = value;
        break;
      case 0x4:
        pc = value;
        break;
      case 0x9:
        ram[a] = value;
        break;
      case 0xa:
        ram[b] = value;
        break;
      case 0xb:
        ram[c] = value;
        break;
      case 0xc:
        ram[h] = value;
        break;
      case 0xd:
        ram[pc] = value;
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
    int a_value = GetValue(a_op);

    switch (op) {
      case 0x0: // NOP
        break;
      case 0x1: // SET
        SetValue(a_op, b_value);
        break;
      case 0x2: // ADD
        SetValue(a_op, a_value + b_value);
        break;
      case 0x3: // SUB
        SetValue(a_op, a_value - b_value);
        break;
      case 0x8: // JZE
        if (b_value == 0) {
          pc = a_value;
        }
        break;
      case 0x9: // JNZ
        if (b_value != 0) {
          pc = a_value;
        }
        break;

      default:
        print("Unimplemented command: $op");
    }

    print("After step: A=$a B=$b C=$c H=$h PC=$pc");
  }

  // Registers
  int pc;
  int a;
  int b;
  int c;
  int h;

  // Ram
  Uint16List ram;
}