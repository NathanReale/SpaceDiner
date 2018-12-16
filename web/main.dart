import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:typed_data';

import 'assembler.dart';
import 'board.dart';
import 'bot.dart';

const int SCALE = 100;
const int TICK = 1000; // milliseconds

const Point NOP = const Point(0, 0);
const Point LEFT = const Point(-1, 0);
const Point RIGHT = const Point(1, 0);
const Point UP = const Point(0, -1);
const Point DOWN = const Point(0, 1);

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
    board.Render(ctx, SCALE);
    bot.Render(ctx, SCALE);

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
