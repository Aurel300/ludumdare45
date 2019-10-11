@:structInit
class ActorAction {
  public var id:String;
  public var enterFrom:(_:Actor, pressed:Bool, held:Bool)->Bool;
  public var tick:(_:Actor, phase:Int, pressed:Bool, held:Bool)->Void;
}
