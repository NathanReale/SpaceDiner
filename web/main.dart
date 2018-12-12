import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

import 'computer.dart';
import 'assembler.dart';

const int scale = 100;
const int TICK = 1000; // milliseconds

const Point NOP = const Point(0, 0);
const Point LEFT = const Point(-1, 0);
const Point RIGHT = const Point(1, 0);
const Point UP = const Point(0, -1);
const Point DOWN = const Point(0, 1);



class Board {
  Board() {
    this._board = [
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 1, 0, 1, 1, 1, 0],
      [0, 2, 2, 1, 1, 2, 2, 1, 1, 0],
      [0, 2, 2, 1, 1, 2, 2, 1, 1, 0],
      [0, 1, 1, 1, 1, 0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    ];
  }

  void Render(CanvasRenderingContext2D ctx) {

    int width = this._board.length;
    int height = this._board[0].length;

    for (int r = 0; r < width; r++) {
      for (int c = 0; c < height; c++) {
        switch (this._board[r][c]) {
          case 0:
            ctx.setFillColorRgb(100, 0, 0);
            break;
          case 1:
            ctx.setFillColorRgb(0, 100, 0);
            break;
          case 2:
            ctx.setFillColorRgb(0, 0, 100);
            break;
        }
        ctx.fillRect(c*scale, r*scale, scale, scale);
      }
    }
  }

  // Get the value at a given position.
  int GetPosition(Point p) {
    return _board[p.y][p.x];
  }

  List<List<int>> _board;
}

abstract class Bot {
  Bot(Board b) {
    _board = b;
    _computer = Computer();
  }

  void Render(CanvasRenderingContext2D ctx);
  bool Step();

  Point Position() { return position; }
  void SetCrash(bool err) { crash = err; }
  void LoadProgram(Uint16List prgm) {
    _computer.LoadRam(prgm);
  }

  Point position;
  bool crash = false;

  Board _board;
  Computer _computer;
}

class MopBot extends Bot {
  MopBot(Board b) : super(b) {
    position = new Point(1, 1);
    _computer.RegisterHardware(MotorHardware(0xFFFF, (Point p) => _move = p));
  }

  void Render(CanvasRenderingContext2D ctx) {
    if (crash) {
      ctx.setFillColorRgb(255, 0, 0);
    } else {
      ctx.setFillColorRgb(0, 255, 0);
    }
    ctx..beginPath()
        ..arc(position.x*scale + (scale / 2), position.y*scale + (scale / 2),
            scale / 2, 0, 2*pi)
        ..fill();
  }

  bool Step() {
    _computer.Step();
    if (_move != null) {
      Point newPosition = position + _move;
      if (_board.GetPosition(newPosition) == 0) {
        SetCrash(true);
        return false;
      } else {
        position = newPosition;
      }
      _move = null;
    }
    return true;
  }

  void Move(Point p) {
    position = position + p;
  }

  Point _move = null;

}

class Game {
  Game(CanvasElement canvas_) {
    board = new Board();
    bot = new MopBot(board);

    canvas = canvas_;
    ctx = canvas.getContext('2d');
  }

  Future Run() async {
    Update(await window.animationFrame);
  }

  void Update(num timestamp) {
    if (lastTick == 0) {
      lastTick = timestamp;
    } else if (timestamp - lastTick > TICK) {
      lastTick = timestamp;
      if (!bot.Step()) {
        finished = true;
      }
    }

    Render();

    if (!finished) Run();
  }

  void Step() {
    if (!bot.Step()) {
      finished = true;
    }

    Render();
  }

  void Stop() {
    finished = true;
  }

  void Render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    board.Render(ctx);
    bot.Render(ctx);

  }

  void SetProgram(Uint16List program_) {
    bot = new MopBot(board);
    bot.LoadProgram(program_);
    lastTick = 0;
    finished = false;
  }

  Board board;
  MopBot bot;

  CanvasElement canvas;
  CanvasRenderingContext2D ctx;

  num lastTick = 0;
  bool finished = false;
}

void main() {
  CanvasElement canvas = querySelector("#canvas");

  Element right_panel = querySelector("#right-panel");
  canvas.width = right_panel.clientWidth;
  canvas.height = right_panel.clientHeight;

  TextAreaElement input = querySelector("#input");
  TableSectionElement memory = querySelector("#memory table tbody");

  Game game = new Game(canvas);
  game.Render();

  // Resize the canvas and re-render when the window changes size.
  window.onResize.listen((e) {
    canvas.width = right_panel.clientWidth;
    canvas.height = right_panel.clientHeight;
    game.Render();
  });

  // Run the user input when they click execute.
  ButtonElement execute = querySelector("#execute");
  execute.onClick.listen((Event e) {
    game.Run();
  });

  ButtonElement terminate = querySelector("#terminate");
  terminate.onClick.listen((Event e) {
    game.Stop();
  });

  ButtonElement assemble = querySelector("#assemble");
  assemble.onClick.listen((Event e) {
    Uint16List result = Assemble(input.value);
    memory.children.clear();
    for (int i = 0; i < 100; i++) {
      var row = memory.addRow();
      row.addCell().text = i.toRadixString(16);
      row.addCell().text = result[i].toRadixString(16);
    }
    game.SetProgram(result);
  });

  ButtonElement step = querySelector("#step");
  step.onClick.listen((Event e) {
    game.Step();
  });

}
