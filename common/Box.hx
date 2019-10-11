class Box implements Collide {
  public static function tileFull(x:Int, y:Int, streak:Int, ledgeL:Bool, ledgeR:Bool):Box {
    var ret = new Box();
    ret.x = x * Tile.TW;
    ret.y = y * Tile.TH;
    ret.w = streak * Tile.TW;
    ret.h = Tile.TH;
    ret.mass = 10 * streak;
    ret.ledgeGrab = (ledgeL ? 8 : 0) + (ledgeR ? 2 : 0);
    ret.isRoom = true;
    ret.roomX = x;
    ret.roomY = y;
    ret.roomW = streak;
    ret.update();
    return ret;
  }

  public var x:IFloat = 0;
  public var y:IFloat = 0;
  public var w:IFloat = 0;
  public var h:IFloat = 0;
  public var vx:IFloat = 0;
  public var vy:IFloat = 0;
  public var mass:IFloat = 0;
  public var ledgeGrab:Dirs = 0;
  public var wallGrab:Dirs = 0;

  public var isRoom:Bool = false;
  public var roomX:Int = 0;
  public var roomY:Int = 0;
  public var roomW:Int = 0;

  public var x2:IFloat = 0;
  public var y2:IFloat = 0;

  public function new() {}

  public function update():Void {
    x2 = x + w - new IFloat(1);
    y2 = y + h - new IFloat(1);
  }

  public function check(ox:IFloat, oy:IFloat, x:IFloat, y:IFloat):Bool {
    return x >= this.x && y >= this.y && x <= this.x2 && y <= this.y2;
  }
}
