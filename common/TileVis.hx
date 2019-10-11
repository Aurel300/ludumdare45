class TileVis {
  public var tx:Int;
  public var ty:Int;
  public var tox:Int = 0;
  public var toy:Int = 0;
  public var tw:Int;
  public var th:Int;
  public var tflip:Bool = false;
  public var text:String;

  public function new(tx:Int, ty:Int) {
    this.tx = tx * Tile.TW;
    this.ty = ty * Tile.TH;
    tw = Tile.TW;
    th = Tile.TH;
  }

  public function auto(neigh:Array<Bool>):Void {
    var num = 0;
    for (i in 0...4) {
      if (neigh[i])
        num |= 1 << i;
    }
    tx += (num & 3) * Tile.TW;
    ty += (num >> 2) * Tile.TH;
  }
}
