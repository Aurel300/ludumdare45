class ActorInput {
  public var left(default, null):Bool = false;
  public var right(default, null):Bool = false;
  public var down(default, null):Bool = false;
  public var downPressed(default, null):Bool = false;
  public var up(default, null):Bool = false;
  public var jump(default, null):Bool = false;
  public var jumpPressed(default, null):Bool = false;
  public final actions:Array<Bool>;
  public final actionsPressed:Array<Bool>;

  public function new(count:Int) {
    actions = [ for (i in 0...count) false ];
    actionsPressed = [ for (i in 0...count) false ];
  }

  public function tick(?left:Bool = false, ?right:Bool = false, ?down:Bool = false, ?up:Bool = false, ?jump:Bool = false, actions:Array<Bool>):Void {
    downPressed = (!this.down && down);
    jumpPressed = (!this.jump && jump);
    for (i in 0...this.actions.length)
      actionsPressed[i] = (i < actions.length && !this.actions[i] && actions[i]);
    this.left = left;
    this.right = right;
    this.down = down;
    this.up = up;
    this.jump = jump;
    for (i in 0...this.actions.length)
      this.actions[i] = (i < actions.length && actions[i]);
  }

  public function clearSignals():Void {
    downPressed = false;
    jumpPressed = false;
    for (i in 0...actions.length)
      actionsPressed[i] = false;
  }
}
