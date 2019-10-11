class Text {
  public static var baseShake:Int = 0;
  public static var shakePhase:Int = 0;

  public static function render(x:Int, y:Int, text:String, ?alpha:Float = 1.0, ?dalpha:Float = -1):Void {
    var ox = x;
    var bold = false;
    var shake = false;
    var pos = 0;
    while (pos < text.length) {
      var cc = text.charCodeAt(pos++);
      switch (cc) {
        case "\n".code:
        x = ox;
        y += 12;
        continue;
        case "$".code:
        switch (text.charCodeAt(pos++)) {
          case "b".code: bold = !bold; continue;
          case "s".code: shake = !shake; continue;
          case "$".code: cc = "$".code;
        }
        case _:
      }
      var btx = 64;
      var bty = bold ? 312 : 264;
      var tx = ((cc - 32) % 32) * 8;
      var ty = ((cc - 32) >> 5) * 16;
      Main.ren.draw(x, y + (shake ? Math.round(Math.sin((baseShake + shakePhase++ * 9) / 24) * 2) : 0), btx + tx, bty + ty, 8, 16, alpha, dalpha, false);
      x += 6;
    }
  }

  public static function width(text:String):Int {
    var max = 0;
    var x = 0;
    var pos = 0;
    while (pos < text.length) {
      var cc = text.charCodeAt(pos++);
      switch (cc) {
        case "\n".code:
        x = 0;
        continue;
        case "$".code:
        switch (text.charCodeAt(pos++)) {
          case "b".code: continue;
          case "s".code: continue;
          case "$".code: cc = "$".code;
        }
        case _:
      }
      x += 6;
      if (x > max)
        max = x;
    }
    return max;
  }
}
