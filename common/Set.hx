class Set {
  public static var categories:Map<String, Array<Set>>;

  public static function init(data:String):Void {
    categories = [];
    var data = data.split("\n");
    var category = "";
    var pos = 0;
    inline function next():String
      return data[pos++];
    while (pos < data.length) {
      var cmd = next().split(" ");
      if (cmd.length == 0 || cmd[0] == "")
        continue;
      switch (cmd[0]) {
        case "cat":
          category = cmd[1];
          categories[category] = [];
        case "pat":
          var mirror = false;
          for (i in 1...cmd.length) switch (cmd[i]) {
            case "mirror": mirror = true;
            case _: throw 'unknown pat mod: ${cmd[i]}';
          }
          var line = "";
          var lines = [ while ((line = next()) != "") line ];
          var w = lines[0].length;
          var h = lines.length;
          var tiles:Array<SetTile> = [ for (y in 0...h) for (x in 0...w) switch (lines[y].charAt(x)) {
            case ":": Any;
            case "+": Key;
            case "v": Access(0);
            case "<": Access(1);
            case "^": Access(2);
            case ">": Access(3);
            case "X": Full;
            case "o": Empty;
            case "m": Monster(false);
            case "M": Monster(true);
            case "T": Treasure;
            case "$": Shopkeeper;
            case "H": Ladder;
            case _: throw 'unknown set tile: ${lines[y].charAt(x)} ($y $x)';
          } ];
          try {
            categories[category].push(new Set(w, h, tiles));
            if (mirror)
              categories[category].push(new Set(w, h, [ for (y in 0...h) for (x in 0...w) tiles[(w - x - 1) + y * w] ]));
          } catch (e:Dynamic) {
            trace(e, lines);
          }
        case _:
          throw 'unknown command: $cmd';
      }
    }
  }

  public var w:Int;
  public var h:Int;
  public var keyX:Int = -1;
  public var keyY:Int = -1;
  public var tiles:Array<SetTile>;

  public var access:Array<{x:Int, y:Int}> = [];

  public function new(w:Int, h:Int, tiles:Array<SetTile>) {
    this.w = w;
    this.h = h;
    this.tiles = tiles.copy();
    var i = 0;
    for (y in 0...h) for (x in 0...w) switch (tiles[i++]) {
      case Access(_): access.push({x: x, y: y});
      case Key: keyX = x; keyY = y; this.tiles[i - 1] = Empty;
      case _:
    }
    if (keyX == -1)
      throw "no key in set";
  }
}

enum SetTile {
  Any;
  Access(from:Int);
  Full;
  Empty;
  Monster(big:Bool);
  Treasure;
  Shopkeeper;
  Ladder;
  Key;
}
