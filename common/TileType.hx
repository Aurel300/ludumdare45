enum TileType {
  Empty;
  Full;
  Block;
  Ladder;
  Portal(to:Room, dx:Int, dy:Int);
}
