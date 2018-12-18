import 'dart:html';
import 'dart:typed_data';

import 'cpu.dart';
import 'hardware.dart';


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

