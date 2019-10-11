class Tile {
  public static inline var TW = 16;
  public static inline var TH = 16;
  public static inline var TWH = 8;
  public static inline var THH = 8;

  public var type:TileType = Full;
  public var vis:Array<Array<TileVis>> = [];
  public var edge:EdgeType = Inside;
  public var setTs:Int = 0;
  public var damage:Int = 0;

  public function new() {}
}
