import Actor.ProbeType;

class Bullet extends Actor {
  public static function shoot(at:Actor):Void {
    var b = new Bullet(at, at.direction, 416, false);
    b.moveTo(at.room);
    b.x = at.x;
    b.y = at.y + at.skills.h.half() - 8;
  }

  public static function shockwave(at:Actor):Void {
    var b = new Bullet(at, false, 352, true);
    b.moveTo(at.room);
    b.x = at.x;
    b.y = at.y + at.skills.h.half() - 8;
    var b = new Bullet(at, true, 352, true);
    b.moveTo(at.room);
    b.x = at.x;
    b.y = at.y + at.skills.h.half() - 8;
  }

  public var right:Bool;
  public var player:Bool;
  public var ground:Bool;

  public function new(from:Actor, right:Bool, baseTx:Int, ground:Bool) {
    var skills = new ActorSkills();
    skills.w = 12;
    skills.h = 16;
    super(VParticle, skills, null);
    this.baseTx = baseTx;
    baseTy = 0;
    tx = 0;
    ty = 0;
    tw = 16;
    th = 16;
    tox = -8;
    toy = -8;
    tflip = !right;
    this.right = right;
    player = from.type == Player;
    glow = 0.8;
  }

  override public function tick(delta:Float):Void {
    oldX = x;
    oldY = y;
    wallBlock = false;

    x += new IFloat(right ? 97 : -97);
    updateAll();
    capWalls();
    tx = ((statePhase >> 1) % 4) * 16;
    statePhase++;

    if (wallBlock || (ground && !probes[FootL].hit && !probes[FootR].hit) || x < -Tile.TWH || x >= room.w * Tile.TW + Tile.TWH) {
      moveTo(null);
    } else {
      Damage.deal(room, x, y + 4, right ? 2 : -2, -1, 12, 8, player);
    }
  }
}
