import 'dart:html';

const List<List<int>> STARTING_BOARD = [
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  [0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0],
  [0, 2, 2, 1, 1, 2, 2, 1, 1, 1, 0],
  [0, 2, 2, 1, 1, 2, 2, 1, 1, 1, 0],
  [0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]];


class Board {
  Board() {
    Reset();
  }

  void Render(CanvasRenderingContext2D ctx, num scale) {

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

  void SetPosition(Point p, int value) {
    _board[p.y][p.x] = value;
  }

  void Reset() {
    this._board = List<List<int>>();
    for (var row in STARTING_BOARD) {
      this._board.add(List<int>.from(row));
    }
  }

  List<List<int>> _board;
}