@:structInit
class Damage {
  public static function melee(actor:Actor, ?vx:IFloat, ?vy:IFloat):Damage {
    var ret:Damage = {
      x: actor.x,
      y: actor.y,
      mvx: (vx == null ? actor.vx * actor.skills.mass : vx),
      mvy: (vy == null ? actor.vy * actor.skills.mass : vy),
      w: actor.skills.w,
      h: actor.skills.h,
      player: actor.type == Player,
      amount: actor.skills.damage
    };
    actor.room.nextDamage.push(ret);
    return ret;
  }

  public static function deal(room:Room, x:IFloat, y:IFloat, mvx:IFloat, mvy:IFloat, w:IFloat, h:IFloat, ?player:Bool = false):Void {
    room.nextDamage.push({
      x: x,
      y: y,
      mvx: mvx,
      mvy: mvy,
      w: w,
      h: h,
      player: player
    });
  }

  public var x:IFloat;
  public var y:IFloat;
  public var mvx:IFloat;
  public var mvy:IFloat;
  public var w:IFloat;
  public var h:IFloat;
  public var player:Bool = false; // dealt BY player
  public var amount:Int = 1;
  public var hit:Bool = false;
}
