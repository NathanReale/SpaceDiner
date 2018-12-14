import 'dart:math';
import 'dart:typed_data';

import 'cpu.dart';

const int MOVE_TICKS = 10;

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
    h.SetAddress(_nextAddress);
    _hardware.add(h);

    _nextAddress += 0x100;
  }

  void Step() {
    _cpu.Step();
    for (Hardware h in _hardware) {
      h.Step();
    }
  }

  void Reset() {
    _cpu.Reset();
    for (Hardware h in _hardware) {
      h.Reset();
    }

  }

  CPU _cpu;
  List<Hardware> _hardware;

  int _nextAddress = 0x8000;
}

abstract class Hardware {
  Hardware () {}

  void SetCPU(cpu) { _cpu = cpu; }
  void SetAddress(address) { _address = address; }

  void Step();
  void Reset() {}

  CPU _cpu;
  int _address;
}

class MotorHardware extends Hardware {
  MotorHardware(Function move) {
    _move = move;
  }
  void Step() {
    if (_pending_move > 0) {
      _pending_move--;
      if (_pending_move == 0) {
        _cpu.ram[_address+1] = 0x0000;
      } else {
        return;
      }
    }

    int val = _cpu.ram[_address];
    _cpu.ram[_address] = 0x0000;

    if (val & 0x1 > 0) { // Up
      _move(Point(0, -1));
    } else if (val & 0x2 > 0) { // Down
      _move(Point(0, 1));
    } else if (val & 0x4 > 0) { // Left
      _move(Point(-1, 0));
    } else if (val & 0x8 > 0) { // Right
      _move(Point(1, 0));
    } else {
      return;
    }

    _cpu.ram[_address+1] = 0xFFFF;
    _pending_move = MOVE_TICKS;
  }

  void Reset() {
    _pending_move = 0;
  }

  Function _move;
  int _pending_move = 0;
}