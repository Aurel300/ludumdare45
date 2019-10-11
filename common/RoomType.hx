@:using(RoomType.RoomTypeTools)
enum RoomType {
  Spawn;
  Empty;
  Story;
  Mob;
  Boss;
  Shop;
  Chest;
  Port;
}

class RoomTypeTools {
  public static function isHostile(t:RoomType):Bool return (switch (t) {
    case Mob | Boss: true;
    case _: false;
  });
}
