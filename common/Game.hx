class Game {
  public static var playing:Bool = false;

  public static var player:Player;
  public static var score:Int = 0;
  public static var difficulty:Int = 0;

  public static function scoreGain(s:Int):Void {
    score += s + ((s >> 1) * difficulty);
  }

  public static function reset():Void {
    Room.init();

    var w = 12;
    var h = 10;
    var spawn = new Room(Spawn, 0, 0, w, h);
    for (y in 0...h) for (x in 0...w) {
      spawn.xy(x, y).type = (y == 0 || y == h - 1 || x == 0 || x == w - 1) ? Full : Empty;
    }
    spawn.xy(5, 6).type = Full;
    spawn.xy(6, 6).type = Full;
    spawn.update();
    var title = new TileVis(0, 0);
    title.tx = 144;
    title.ty = 208;
    title.tw = 5 * Tile.TW;
    title.th = 24;
    title.tox = 8;
    //title.text = '\n\nbest score: ${Save.best}';
    spawn.xy(3, 3).vis[2].push(title);

    player = new Player();
    player.moveTo(spawn);
    player.x = (w >> 1) * 16;
    player.y = 2 * 16;

    playing = true;
    score = 0;
    difficulty = 0;
  }
}
