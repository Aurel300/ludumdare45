enum ActorState {
  Idle;
  Walk;
  Jumping(type:JumpType);
  LedgeGrabbing(right:Bool, box:Box);
  Hurt(air:Bool);
  Action(action:ActorAction, phase:Int);
}

enum JumpType {
  Fell;
  Normal;
  Double;
  Ledge;
  Smash;
}
