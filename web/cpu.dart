import 'dart:typed_data';
import 'dart:html';

class CPU {

  CPU() {
    ram = new Uint16List(0x10000);
  }

  void LoadRam(Uint16List ram_) {
    ram = Uint16List.fromList(ram_.toList());
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

  // TODO: Only redraw the actual register values instead of the entire table.
  // TODO: Move this out of the CPU class.
  void Render(DivElement div) {
    TableElement reg = div.querySelector(".registers");
    reg.innerHtml = "<thead><tr><th>Register</th><th>Value</th></tr></thead>"
        "<tbody><tr>"
        "<td>PC</td><td>0x" + pc.toRadixString(16).padLeft(4, '0') +"</td></tr>"
        "<td>SP</td><td>0x" + sp.toRadixString(16).padLeft(4, '0') +"</td></tr>"
        "<td>A</td><td>0x" + a.toRadixString(16).padLeft(4, '0') +"</td></tr>"
        "<td>B</td><td>0x" + b.toRadixString(16).padLeft(4, '0') +"</td></tr>"
        "<td>C</td><td>0x" + c.toRadixString(16).padLeft(4, '0') +"</td></tr>"
        "</tbody>";

    TableElement mem = div.querySelector("table.ram");
    mem.innerHtml = "<thead><tr><th>Address</th><th>Value</th></tr></thead>"
        "<tbody></tbody>";

    TableSectionElement mem_table = mem.querySelector("tbody");
    for (int i = 0; i < 100; i++) {
      var row = mem_table.addRow();
      if (i == pc) row.classes.add('active');
      row.addCell().text = i.toRadixString(16);
      row.addCell().text = ram[i].toRadixString(16).padLeft(4, '0');
    }

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