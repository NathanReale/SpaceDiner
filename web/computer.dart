import 'dart:math';
import 'dart:typed_data';

import 'cpu.dart';

class Computer {
  Computer() {
    _cpu = CPU();
    _hardware = List<Hardware>();
  }

  void LoadRam(Uint16List ram) {
    _cpu.LoadRam(ram);
  }

  void RegisterHardware(Hardware h) {
    h.SetCPU(_cpu);
    _hardware.add(h);
  }

  void Step() {
    _cpu.Step();
    for (Hardware h in _hardware) {
      h.Step();
    }
  }

  CPU _cpu;
  List<Hardware> _hardware;
}

abstract class Hardware {
  Hardware () {}
  void SetCPU(cpu) { _cpu = cpu; }
  void Step() {}

  CPU _cpu;
}

class MotorHardware extends Hardware {
  MotorHardware(int address, Function move) {
    _address = address;
    _move = move;
  }
  void Step() {
    int val = _cpu.ram[_address];

    if (val & 0x1 > 0) { // Up
      _move(Point(0, -1));
    } else if (val & 0x2 > 0) { // Down
      _move(Point(0, 1));
    } else if (val & 0x4 > 0) { // Left
      _move(Point(-1, 0));
    } else if (val & 0x8 > 0) { // Right
      _move(Point(1, 0));
    }

    _cpu.ram[_address] = 0;

  }

  int _address;
  Function _move;
}