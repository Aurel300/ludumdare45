abstract Dirs(Int) from Int to Int {
  public var up(get, never):Bool;
  public var right(get, never):Bool;
  public var down(get, never):Bool;
  public var left(get, never):Bool;

  inline function get_up():Bool return (this & 1) != 0;
  inline function get_right():Bool return (this & 2) != 0;
  inline function get_down():Bool return (this & 4) != 0;
  inline function get_left():Bool return (this & 8) != 0;
}
