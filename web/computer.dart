import 'dart:html';
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

  bool Step() {
    _cpu.Step();

    num power_usage = -1;
    for (Hardware h in _hardware) {
      h.Step();
      power_usage += h.PowerUsage();
    }

    for (Hardware h in _hardware) {
      power_usage = h.UpdatePower(power_usage);
    }

    print(power_usage);
    return power_usage < 0;
  }

  void Reset() {
    _cpu.Reset();
    for (Hardware h in _hardware) {
      h.Reset();
    }
  }

  void Render() {
    DivElement div = querySelector("#memory");
    div.innerHtml = "<table class='hardware'>" +
        "<thead><tr><th>Hardware</th><th>Status</th></tr></thead>" +
        "<tbody></tbody></table>" +
        "<table class='registers'></table>" +
        "<table class='ram'></table>";
    _cpu.Render(div);

    TableSectionElement hw = div.querySelector("table.hardware tbody");
    for (var h in _hardware) {
      var row = hw.addRow();
      row.addCell().text = h.Name();
      row.addCell().text = h.Status();
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

  num PowerUsage() { return 0; }
  num AvailablePower() { return 0; }
  num UpdatePower(num p) { return p; }

  String Name();
  String Status();

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

  num PowerUsage() {
    if (_pending_move > 0) return -1;
    return 0;
  }

  String Name() { return "Motor"; }
  String Status() {
    if (_pending_move > 0) {
      return "Moving";
    }
    return "Idle";
  }

  Function _move;
  int _pending_move = 0;
}

class MopHardware extends Hardware {
  MopHardware(Function clean) {
    _clean = clean;
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

    if (val & 0x1 > 0) { // Clean
      _clean();
    } else {
      return;
    }

    _cpu.ram[_address+1] = 0xFFFF;
    _pending_move = MOVE_TICKS;
  }

  void Reset() {
    _pending_move = 0;
  }

  num PowerUsage() {
    if (_pending_move > 0) return -1;
    return 0;
  }

  String Name() { return "Mop"; }
  String Status() {
    if (_pending_move > 0) {
      return "Cleaning";
    }
    return "Idle";
  }

  Function _clean;
  int _pending_move = 0;
}

class BatteryHardware extends Hardware {
  BatteryHardware(max_charge) {
    _max_charge = max_charge;
    _charge = _max_charge;
  }

  // Does nothing. Status is updated in the UsePower function.
  void Step() {}


  void Reset() {
    _charge = _max_charge;
  }

  num AvailablePower() { return _charge; }
  num UpdatePower(num p) {
    _charge += p;
    num ret = 0;

    if (_charge > _max_charge) {
      ret = _charge - _max_charge;
      _charge = _max_charge;
    } else if (_charge < 0) {
      ret = _charge;
      _charge = 0;
    }

    _cpu.ram[_address] = _charge ~/ _max_charge;
    return ret;
  }

  String Name() { return "Battery"; }
  String Status() {
    return ((_charge * 100) / _max_charge).toString() + "%";
  }

  num _max_charge;
  num _charge;
}