import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

import 'board.dart';
import 'computer.dart';

abstract class Bot {
  Bot(Board b) {
    _board = b;
    _computer = Computer();
  }

  void Render(CanvasRenderingContext2D ctx, num scale);
  bool Step();

  Point Position() { return _position; }
  void SetCrash(bool err) { _crash = err; }
  void LoadProgram(Uint16List prgm) {
    _computer.LoadRam(prgm);
  }

  Point _position;
  bool _crash = false;

  Board _board;
  Computer _computer;
}

class MopBot extends Bot {
  MopBot(Board b, Point p) : super(b) {
    _position = p;
    _computer.RegisterHardware(MotorHardware((Point p) => _move = p));
    _computer.RegisterHardware(MopHardware(Clean));
  }

  void Render(CanvasRenderingContext2D ctx, num scale) {
    // Draw the bot on the canvas.
    if (_crash) {
      ctx.setFillColorRgb(255, 0, 0);
    } else {
      ctx.setFillColorRgb(0, 255, 0);
    }
    ctx..beginPath()
      ..arc(_position.x*scale + (scale / 2), _position.y*scale + (scale / 2),
          scale / 2, 0, 2*pi)
      ..fill();

    // Update registers table.
    _computer.Render();
  }

  bool Step() {
    _computer.Step();
    if (_move != null) {
      Point newPosition = _position + _move;
      if (_board.GetPosition(newPosition) == 0) {
        SetCrash(true);
        return false;
      } else {
        _position = newPosition;
      }
      _move = null;
    }
    return true;
  }

  void Clean() {
    if (_board.GetPosition(_position) == 2) {
      _board.SetPosition(_position, 1);
    }
  }

  Point _move = null;

}