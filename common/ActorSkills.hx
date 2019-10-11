class ActorSkills {
  public var canWalk:Bool = false;
  public var canLedgeGrab:Bool = false;
  public var canDoubleJump:Bool = false;
  public var canSmash:Bool = false;
  public var canAction:Array<Bool> = [];
  public var canJump:Bool = false;

  //public var canWallGrab:Bool = false;
  //public var canWallJump:Bool = false;
  //public var canCeilGrab:Bool = false;

  public var mass:IFloat = 0;
  public var groundAcc:IFloat = 0;
  public var airAcc:IFloat = 0;
  public var groundRevAcc:IFloat = 0;
  public var airRevAcc:IFloat = 0;
  public var groundDec:IFloat = 0;
  public var airDec:IFloat = 0;
  public var maxGroundVX:IFloat = 0;
  public var maxAirVX:IFloat = 0;
  public var maxJump1Power:Int = 0;
  public var attackJump1Power:Int = 0;
  public var jump1Power:IFloat = 0;
  public var maxJump2Power:Int = 0;
  public var attackJump2Power:Int = 0;
  public var jump2Power:IFloat = 0;
  public var maxJumpLPower:Int = 0;
  public var attackJumpLPower:Int = 0;
  public var jumpLPower:IFloat = 0;
  public var smashHover:Int = 10;
  public var iframes:Int = 0;
  public var maxHp:Int = 1;
  public var worth:Int = 0;
  public var damage:Int = 1;
  public var jumps:Int = 0;

  public var actions:Array<ActorAction> = [];

  public var w:IFloat = 0;
  public var h:IFloat = 0;

  public function new() {}

  public function action(id:String):ActorAction {
    for (a in actions)
      if (a.id == id)
        return a;
    return null;
  }
}
