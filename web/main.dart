import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

import 'cpu.dart';
import 'assembler.dart';

const int scale = 100;
const int TICK = 1000; // milliseconds

const Point NOP = const Point(0, 0);
const Point LEFT = const Point(-1, 0);
const Point RIGHT = const Point(1, 0);
const Point UP = const Point(0, -1);
const Point DOWN = const Point(0, 1);

class Computer {
  Computer() {}

  void Step() {
    _cpu.Step();
  }

  CPU _cpu;
}

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
    board = b;
  }

  void Render(CanvasRenderingContext2D ctx);
  bool Step();

  Point Position() { return position; }
  void SetCrash(bool err) { crash = err; }
  void LoadProgram(String prgm) {
    program = new Program(prgm);
  }

  Point position;
  bool crash = false;

  Board board;
  Program program;
}

class MopBot extends Bot {
  MopBot(Board b) : super(b) {
    position = new Point(1, 1);
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
    Point newPosition = position + program.Step();
    if (board.GetPosition(newPosition) == 0) {
      SetCrash(true);
      return false;
    } else {
      position = newPosition;
    }
    return true;
  }

  void Move(Point p) {
    position = position + p;
  }

}

class Program {
  Program(String program) {
    commands = program.split("\n");
  }

  Point Step() {
    if (pc >= commands.length) {
      return NOP;
    }

    List<String> line = commands[pc].toUpperCase().split(" ");
    pc += 1;

    switch (line[0]) {
      case "LEFT":
        return LEFT;
      case "RIGHT":
        return RIGHT;
      case "UP":
        return UP;
      case "DOWN":
        return DOWN;
      case "LOOP":
        pc = 0;
        return NOP;
      case "JUMP":
        pc = int.parse(line[1]);
        return NOP;
    }

    return NOP;
  }

  int pc = 0;
  List<String> commands;
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

  void Stop() {
    finished = true;
  }

  void Render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    board.Render(ctx);
    bot.Render(ctx);

  }

  void SetProgram(String program_) {
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

  CPU cpu = CPU();

  // Resize the canvas and re-render when the window changes size.
  window.onResize.listen((e) {
    canvas.width = right_panel.clientWidth;
    canvas.height = right_panel.clientHeight;
    game.Render();
  });

  // Run the user input when they click execute.
  ButtonElement execute = querySelector("#execute");
  execute.onClick.listen((Event e) {
    game.SetProgram(input.value);
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
    cpu.LoadRam(result);
  });

  ButtonElement step = querySelector("#step");
  step.onClick.listen((Event e) {
    cpu.Step();
  });

}
