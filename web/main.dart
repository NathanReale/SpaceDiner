import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

import 'assembler.dart';
import 'board.dart';
import 'bot.dart';

const int SCALE = 100;
const int TICK = 100; // milliseconds

const Point NOP = const Point(0, 0);
const Point LEFT = const Point(-1, 0);
const Point RIGHT = const Point(1, 0);
const Point UP = const Point(0, -1);
const Point DOWN = const Point(0, 1);

class Game {
  Game(CanvasElement canvas_) {
    board = new Board();
    bots = List<Bot>();
    bots.add(new MopBot(board, Point(1, 2)));
    bots.add(new MopBot(board, Point(5, 2)));

    canvas = canvas_;
    ctx = canvas.getContext('2d');

    canvas.onClick.listen(Click);
    canvas.onMouseWheel.listen(Wheel);
  }

  Future Run() async {
    Update(await window.animationFrame);
  }

  void Update(num timestamp) {
    if (lastTick == 0) {
      lastTick = timestamp;
    } else if (timestamp - lastTick > TICK) {
      lastTick = timestamp;
      bots.forEach((b) { b.Step(); });
    }

    Render();

    if (!finished) Run();
  }

  void Step() {
    bots.forEach((b) { b.Step(); });
    Render();
  }

  void Stop() {
    finished = true;
  }

  void Render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    board.Render(ctx, scale);
    bots.forEach((b) { b.Render(ctx, scale, b == activeBot); });

  }

  void SetProgram(Uint16List program) {
    bots.forEach((b) { b.LoadProgram(program); });
    lastTick = 0;
    finished = false;
  }

  void Click(MouseEvent e) {
    Point p = Point(e.offset.x ~/ scale, e.offset.y ~/ scale);
    for (var bot in bots) {
      if (bot.Position() == p) {
        activeBot = bot;
      }
    }
    Render();
  }

  void Wheel(WheelEvent e) {
    scale = (scale + e.deltaY).clamp(10, 100);
    print(scale);
    Render();
  }

  Board board;
  List<Bot> bots;

  Bot activeBot;

  CanvasElement canvas;
  CanvasRenderingContext2D ctx;

  num lastTick = 0;
  bool finished = false;

  num scale = 100;
}

void main() {
  CanvasElement canvas = querySelector("#canvas");

  Element right_panel = querySelector("#right-panel");
  canvas.width = right_panel.clientWidth;
  canvas.height = right_panel.clientHeight;

  TextAreaElement input = querySelector("#input");

  if (window.localStorage.containsKey('program')) {
    input.value = window.localStorage['program'];
  }

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
    window.localStorage['program'] = input.value;
    Uint16List result = Assemble(input.value);
    game.SetProgram(result);
    game.Render();
  });

  ButtonElement step = querySelector("#step");
  step.onClick.listen((Event e) {
    game.Step();
  });

}
