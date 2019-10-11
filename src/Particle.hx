@:structInit
class Particle {
  public static var ch = new Chance(0xF00DD00F);

  public static function land(at:Actor):Void {
    for (right in [false, true]) {
      at.room.particles.push({
        tx: 64,
        ty: 0,
        tflip: !right,
        x: at.x - 8,
        y: at.y + at.skills.h.half() - 16,
        vx: new IFloat(right ? 1 : -1),
        vy: new IFloat(-1),
        ax: new IFloat(right ? -1 : 1),
        ay: 0,
        phase: 0,
        xpp: 6,
        frameMod: 7,
        frames: 7
      });
    }
  }

  public static function smoke(at:Actor, max:Int):Void {
    var h = max >> 1;
    for (i in 0...h + ch.mod(h)) {
      at.room.particles.push({
        tx: 176,
        ty: 0,
        tflip: ch.bool(),
        x: at.x + ch.rangeI(-5, 5) - 8,
        y: at.y + ch.rangeI(-5, 5) - 8,
        vx: new IFloat(ch.rangeI(-8, 8)),
        vy: new IFloat(-2),
        ax: 0,
        ay: new IFloat(-1),
        phase: 0,
        xpp: 6,
        frameMod: 5,
        frames: 5
      });
    }
  }

  public static function smokeAt(room:Room, x:Int, y:Int, max:Int):Void {
    var h = max >> 1;
    for (i in 0...h + ch.mod(h)) {
      room.particles.push({
        tx: 176,
        ty: 0,
        tflip: ch.bool(),
        x: x + ch.rangeI(-5, 5) - 8,
        y: y + ch.rangeI(-5, 5) - 8,
        vx: new IFloat(ch.rangeI(-8, 8)),
        vy: new IFloat(-2),
        ax: 0,
        ay: new IFloat(-1),
        phase: 0,
        xpp: 6,
        frameMod: 5,
        frames: 5
      });
    }
  }

  public static function walk(at:Actor):Void {
    if (ch.float() > .7)
      return;
    at.room.particles.push({
      tx: 176,
      ty: 0,
      tflip: at.direction,
      x: at.x - 8,
      y: at.y + at.skills.h.half() - 10,
      vx: new IFloat(-8 + ch.mod(17)),
      vy: new IFloat(-2),
      ax: 0,
      ay: new IFloat(-1),
      phase: 0,
      xpp: 4,
      frameMod: 5,
      frames: 5
    });
  }

  public var tx:Int = 0;
  public var ty:Int = 0;
  public var tflip:Bool = false;
  public var x:IFloat = 0;
  public var y:IFloat = 0;
  public var vx:IFloat = 0;
  public var vy:IFloat = 0;
  public var ax:IFloat = 0;
  public var ay:IFloat = 0;
  public var phase:Int = 0;
  public var xpp:Int = 1;
  public var frameOff:Int = 0;
  public var frameMod:Int = 1;
  public var frames:Int = 1;
  public var dalpha:Float = 1.0;
  public var dalphaV:Float = 0.0;
  public var glow:Float = 0.0;
}
