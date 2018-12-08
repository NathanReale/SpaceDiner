import 'dart:async';
import 'dart:html';
import 'dart:math';

const int scale = 100;
const int TICK = 1000; // 1000 milliseconds

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
      [0, 1, 1, 1, 1, 2, 2, 1, 1, 0],
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
    return _board[p.x][p.y];
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

    String cmd = commands[pc].toUpperCase();
    pc += 1;

    switch (cmd) {
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

  Future run() async {
    update(await window.animationFrame);
  }

  void update(num timestamp) {
    if (lastTick == 0) {
      lastTick = timestamp;
    } else if (timestamp - lastTick > TICK) {
      lastTick = timestamp;
      if (!bot.Step()) {
        finished = true;
      }
    }
    Render();
    if (!finished) run();
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

  Game game = new Game(canvas);
  game.Render();

  // Resize the canvas and re-render when the window changes size.
  window.onResize.listen((e) {
    canvas.width = right_panel.clientWidth;
    canvas.height = right_panel.clientHeight;
  });

  ButtonElement execute = querySelector("#execute");
  execute.onClick.listen((Event e) {
    game.SetProgram(input.value);
    game.run();
  });

}
