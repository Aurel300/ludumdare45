import ActorState.JumpType;

class Actor {
  static var gravity = new IFloat(9);
  static var maxVY:IFloat = 3;

  public var type:ActorType;
  public var skills:ActorSkills;
  public var input:ActorInput;
  public var room:Room;
  public var hp:Int;
  public var dead:Bool = false;

  public var direction:Bool = true; // true = right
  public var x:IFloat = 0;
  public var y:IFloat = 0;
  public var lastGroundX:IFloat = 0;
  public var lastGroundY:IFloat = 0;
  public var vx:IFloat = 0;
  public var vy:IFloat = 0;
  public var jumpsLeft:Int = 0;
  public var jumpTicks:Int = 0;
  public var jumpPower:IFloat = 0;
  public var jumpAttack:Int = 0;
  public var jumpPunched:Bool = false;
  public var iframes:Int = 0;

  public var baseTx:Int = 0;
  public var baseTy:Int = 0;
  public var tx:Int = 0;
  public var ty:Int = 0;
  public var tw:Int = 0;
  public var th:Int = 0;
  public var tox:Int = 0;
  public var toy:Int = 0;
  public var tflip:Bool = false;
  public var alpha:Float = 1;
  public var glow:Float = 0;
  public var ethereal:Bool = false;

  var state:ActorState = Idle;
  var statePhase:Int = 0;
  var wallBlockP:Bool = false;
  var wallBlock:Bool = false;
  var oldX:IFloat = 0;
  var oldY:IFloat = 0;
  var probes:Array<Probe>;
  var probesX:Array<Probe>;
  //var probesY:Array<Probe>;

  public function new(type:ActorType, skills:ActorSkills, input:ActorInput) {
    this.type = type;
    this.skills = skills;
    this.input = input;
    hp = skills.maxHp;
    createProbes();
  }

  public function death():Void {
    // override
  }

  public function transition(from:ActorState, to:ActorState):Void {
    // override
  }

  public function createProbes():Void {
    probes = [ for (i in 0...ProbeType.Last) new Probe(i, skills) ];
    probesX = [ for (i in 0...ProbeType.Last) new Probe(i, skills) ];
    //probesY = [ for (i in 0...ProbeType.Last) new Probe(i, skills) ];
  }

  inline function alignProbeX(p:Probe, toX:IFloat):Void {
    x = toX - p.x;
  }

  inline function alignProbeY(p:Probe, toY:IFloat):Void {
    y = toY - p.y;
  }

  function updateProbes(probes:Array<Probe>, moveX:Bool, moveY:Bool):Void {
    for (probe in probes) {
      probe.hits.resize(0);
      var ox = oldX + probe.x;
      var oy = oldY + probe.y;
      var x = (moveX ? x : oldX) + probe.x;
      var y = (moveY ? y : oldY) + probe.y;
      for (boxes in [room.tileBoxes, room.boxes]) for (box in boxes) {
        if (box.check(ox, oy, x, y)) {
          probe.hits.push(box);
        }
      }
    }
  }

  public function goto(state:ActorState):Void {
    switch [this.state, state] {
      case [Idle, Idle] | [Walk, Walk] | [LedgeGrabbing(_, _), LedgeGrabbing(_, _)] | [Hurt(_), Hurt(_)]:
      case [Jumping(a), Jumping(b)]:
        if (a != b) {
          transition(this.state, state);
          statePhase = 0;
        }
      case [Action(a, _), Action(b, _)]:
        if (a != b)
          transition(this.state, state);
      case _:
        if (this.state.match(Hurt(_))) {
          iframes = skills.iframes;
        }
        transition(this.state, state);
        statePhase = 0;
    }
    this.state = state;
  }

  function updateAll():Void {
    updateProbes(probes, true, true);
    updateProbes(probesX, true, false);
  }

  public function moveTo(target:Room):Void {
    if (room != null) {
      room.actors.remove(this);
      x += room.x * Tile.TW;
      y += room.y * Tile.TH;
    }
    //trace("passed", target.x, target.y);
    room = target;
    if (target != null) {
      room.actors.push(this);
      x -= room.x * Tile.TW;
      y -= room.y * Tile.TH;
    }
  }

  public function tick(delta:Float):Void { // TODO: cap at 60 per second based on deltas
    if (room == null)
      return;

    oldX = x;
    oldY = y;
    wallBlockP = wallBlock;
    wallBlock = false;

    var maxVX = (state.match(Jumping(_)) ? skills.maxAirVX : skills.maxGroundVX);
    vx = vx.clamp(-maxVX, maxVX);
    vy = (state.match(Jumping(Smash)) ? vy.clamp(-maxVY, maxVY * 3) : vy.clamp(-maxVY, maxVY));
    x += vx;
    y += vy;
    updateAll();

    var willDie = false;
    capAction();
    switch (state) {
      case _ if (dead):
        capFall();
      case Idle:
        capDamage(false)
        || capWalk(skills.groundAcc, skills.groundRevAcc, skills.groundDec);
        capFall()
        || capJump();
      case Walk:
        capDamage(false)
        || capWalk(skills.groundAcc, skills.groundRevAcc, skills.groundDec);
        capFall()
        || capJump();
      case Hurt(_):
        vy += statePhase < 10 ? new IFloat(0) : gravity;
        if (statePhase >= 30) {
          if (hp <= 0) willDie = true;
          else goto(Jumping(Fell));
        }
        capBottom();
        capCeiling();
      case Jumping(jt):
        capJumpControl(jt);
        ((jt == Smash && jumpTicks == 0) ? false : capDamage(true))
        || capGrabLedges()
        || capLand()
        || capWalk(skills.airAcc, skills.airRevAcc, skills.airDec);
        capCeiling();
      case LedgeGrabbing(right, box):
        capDamage(true)
        || capUngrab(right, box);
      case Action(action, phase):
        var i = skills.actions.indexOf(action);
        action.tick(this, phase, input.actionsPressed[i], input.actions[i]);
    }
    if (!state.match(LedgeGrabbing(_, _)))
      capWalls();
    if (state.match(Idle | Walk | LedgeGrabbing(_, _)) && probes[FootL].hit && probes[FootR].hit) {
      jumpPunched = false;
      lastGroundX = x;
      lastGroundY = y;
      jumpsLeft = skills.jumps;
    }
    if (iframes > 0)
      iframes--;
    input.clearSignals();

    for (portal in room.portals) {
      var cx = portal.x * Tile.TW + Tile.TWH;
      var cy = portal.y * Tile.TH + Tile.THH;
      var pass = false;
      if (portal.dx != 0) {
        // horizontal
        var cy1 = cy - 9;
        var cy2 = cy + 9;
        cx += portal.dx * 3;
        if (y >= cy1 && y <= cy2 && (oldX < cx) != (x < cx)) {
          pass = true;
        }
      } else {
        // vertical
        var cx1 = cx - 9;
        var cx2 = cx + 9;
        cy += portal.dy * 1;
        if (x >= cx1 && x <= cx2 && (oldY < cy) != (y < cy)) {
          pass = true;
        }
      }
      if (pass) {
        if (state.match(LedgeGrabbing(_, _))) {
          jumpTicks = 0;
          jumpPower = 0;
          jumpAttack = 0;
          goto(Jumping(Fell));
        }
        moveTo(portal.to);
        break;
      }
    }

    if (willDie && !dead) {
      goto(Idle);
      dead = true;
      death();
      if (!type.match(Player | Chest))
        moveTo(null);
    }
  }

  function capDamage(air:Bool):Bool {
    if (iframes > 0 || type == VParticle || dead)
      return false;
    for (d in room.damage) {
      if (d.player == (type != Player) && (x - d.x).abs() < (skills.w + d.w).half() && (y - d.y).abs() < (skills.h + d.h).half()) {
        if (d.player) {
          if (!d.hit)
            Sfx.play("punch_hit");
          d.hit = true;
        }
        Particle.smoke(this, 7);
        goto(Hurt(air));
        hp--;
        vx = d.mvx / skills.mass;
        vy = d.mvy / skills.mass;
        return true;
      }
    }
    return false;
  }

  function capAction():Void {
    for (i in 0...skills.actions.length) {
      if (!skills.canAction[i])
        continue;
      if (skills.actions[i].enterFrom(this, input.actionsPressed[i], input.actions[i])) {
        goto(Action(skills.actions[i], 0));
        break;
      }
    }
  }

  function capKeepAction(phase:Int, max:Int):Bool {
    if (phase + 1 < max) {
      switch (state) {
        case Action(a, _):
          goto(Action(a, phase + 1));
        case _:
      }
      return true;
    }
    goto(Jumping(Fell));
    return false;
  }

  function capBottom(?force:Bool = false):Bool {
    if (ethereal)
      return false;
    if (vy > 0 || force) {
      if (probes[FootL].hit || probes[FootR].hit) {
        var align:IFloat = 1000000;
        for (hit in probes[FootL].hits) align = align.min(hit.y);
        for (hit in probes[FootR].hits) align = align.min(hit.y);
        alignProbeY(probes[FootL], align);
        updateAll();
        if (vy > 1)
          Particle.land(this);
        vy = 0;
        return true;
      }
    }
    return false;
  }

  function capLand():Bool {
    if (ethereal)
      return false;
    if (capBottom()) {
      if (state.match(Jumping(Smash)))
        shake(10);
      Sfx.play("land");
      goto(vx.zero ? Idle : Walk);
      return true;
    }
    return false;
  }

  function capGrabLedges():Bool {
    if (!skills.canLedgeGrab || state.match(Jumping(Smash)))
      return false;
    if (vy >= 0) {
      function check(probe:Probe, right:Bool):Box {
        var align:IFloat = 1000000;
        var box:Box = null;
        for (hit in probe.hits) {
          if ((right ? hit.ledgeGrab.right : hit.ledgeGrab.left) && probe.y + y <= hit.y + 2) {
            if (hit.y < align) {
              align = hit.y;
              box = hit;
            }
          }
        }
        return box;
      }
      if (input.left && probes[LedgeL].hit) {
        var box = check(probes[LedgeL], true);
        if (box != null) {
          alignProbeX(probes[ChestL], box.x2);
          alignProbeY(probes[LedgeL], box.y);
          goto(LedgeGrabbing(false, box));
          direction = false;
          return true;
        }
      }
      if (input.right && probes[LedgeR].hit) {
        var box = check(probes[LedgeR], false);
        if (box != null) {
          alignProbeX(probes[ChestR], box.x);
          alignProbeY(probes[LedgeR], box.y);
          goto(LedgeGrabbing(true, box));
          direction = true;
          return true;
        }
      }
    }
    return false;
  }

  function capFall():Bool {
    if (ethereal)
      return false;
    if (!probes[FootL].hit && !probes[FootR].hit) {
      goto(Jumping(Fell));
      return true;
    }
    return false;
  }

  function capJumpControl(jt:JumpType):Bool {
    if ((jt == Fell || jt == Normal || jt == Ledge || jt == Double) && jumpsLeft > 0 && input.jumpPressed && skills.canDoubleJump) {
      vy = vy.min(0);
      jumpsLeft--;
      jumpPunched = false;
      jumpTicks = skills.maxJump2Power;
      jumpPower = skills.jump2Power;
      jumpAttack = skills.attackJump2Power;
      goto(Jumping(jt = Double));
      Sfx.play("jump2", .1);
    }
    if (jt != Smash && input.downPressed && vy < 1 && skills.canSmash) {
      vy = 0;
      jumpsLeft = 0;
      jumpTicks = skills.smashHover;
      goto(Jumping(jt = Smash));
    }
    var held = input.jump;
    if (jt == Smash) {
      held = true;
      jumpPower = 0;
    }
    if ((jumpTicks >= jumpAttack || held) && jumpTicks > 0) {
      vy = -jumpPower * jumpTicks--;
    } else {
      jumpTicks = 0;
      vy = vy.max(0) + (jt == Smash ? gravity * 5 : gravity);
    }
    return true;
  }

  function capJump():Bool {
    if (input.jumpPressed && skills.canJump) {
      y -= 1;
      jumpPunched = false;
      jumpsLeft = skills.jumps;
      jumpTicks = skills.maxJump1Power;
      jumpPower = skills.jump1Power;
      jumpAttack = skills.attackJump1Power;
      goto(Jumping(Normal));
      Sfx.play("jump", .1);
    }
    return false;
  }

  function capWalls():Void {
    if (ethereal)
      return;
    if (vx <= 0) {
      if (probesX[ChestL].hit || probesX[ShinL].hit) {
        var align:IFloat = -1000000;
        for (hit in probesX[ChestL].hits) align = align.max(hit.x2);
        for (hit in probesX[ShinL].hits) align = align.max(hit.x2);
        alignProbeX(probesX[ChestL], align);
        wallBlock = true;
      }
    }
    if (vx >= 0) {
      if (probesX[ChestR].hit || probesX[ShinR].hit) {
        var align:IFloat = 1000000;
        for (hit in probesX[ChestR].hits) align = align.min(hit.x);
        for (hit in probesX[ShinR].hits) align = align.min(hit.x);
        alignProbeX(probesX[ChestR], align);
        wallBlock = true;
      }
    }
  }

  function capCeiling():Void {
    if (ethereal)
      return;
    if (vy < 0) {
      if (probes[BonkL].hit || probes[BonkR].hit) {
        var align:IFloat = -1000000;
        for (hit in probes[BonkL].hits) align = align.max(hit.y2);
        for (hit in probes[BonkR].hits) align = align.max(hit.y2);
        alignProbeY(probes[BonkL], align);
        updateAll();
        jumpTicks = 0;
        vy = vy.max(0);
      }
    }
  }

  function capWalk(acc:IFloat, revAcc:IFloat, dec:IFloat):Bool {
    if (!skills.canWalk) {
      if (!state.match(Jumping(_) | Action(_, _)))
        goto(Idle);
      return false;
    }
    if (input.left != input.right && !state.match(Jumping(Smash))) {
      if ((input.left && vx > 0) || (input.right && vx < 0))
        vx += revAcc.negpos(input.left, input.right);
      else
        vx += acc.negpos(input.left, input.right);
    } else
      vx = (vx.abs() - dec).max(0) * vx.sign();
    if (!state.match(Jumping(_) | Action(_, _))) {
      if (!vx.zero && !wallBlockP && statePhase % 12 == 6) {
        Particle.walk(this);
      }
      goto(vx.zero ? Idle : Walk);
    }
    if (vx > 0)
      direction = true;
    else if (vx < 0)
      direction = false;
    return !vx.zero;
  }

  function capUngrab(right:Bool, box:Box):Bool {
    vx = box.vx;
    vy = box.vy;
    if (right)
      alignProbeX(probes[ChestR], box.x);
    else
      alignProbeX(probes[ChestL], box.x2);
    alignProbeY(probes[LedgeL], box.y);
    if (input.jumpPressed) {
      if (input.left != input.right && input.left == right) {
        // away
        jumpsLeft = skills.jumps;
        jumpTicks = skills.maxJumpLPower;
        jumpPower = skills.jumpLPower;
        jumpAttack = skills.attackJumpLPower;
        vx += right ? -skills.maxAirVX : skills.maxAirVX;
        goto(Jumping(Ledge));
      } else if (input.down) {
        // down
        jumpsLeft = skills.jumps;
        jumpTicks = 0;
        jumpPower = 0;
        jumpAttack = 0;
        goto(Jumping(Normal));
      } else {
        // up
        jumpsLeft = skills.jumps;
        jumpTicks = skills.maxJumpLPower;
        jumpPower = skills.jumpLPower;
        jumpAttack = skills.attackJumpLPower;
        goto(Jumping(Ledge));
      }
      return true;
    }
    vx = vy = 0;
    return true;
  }
}

enum abstract ProbeType(Int) from Int to Int {
  var FootL = 0;
  var FootR;
  var ShinL;
  var ShinR;
  var ChestL;
  var ChestR;
  var LedgeL;
  var LedgeR;
  var BonkL;
  var BonkR;

  var Last;
}

class Probe {
  public var x:IFloat;
  public var y:IFloat;
  public var hits:Array<Box> = [];

  public var hit(get, never):Bool;
  inline function get_hit():Bool return hits.length > 0;

  public function new(type:ProbeType, skills:ActorSkills) {
    var w1 = -skills.w.half();
    var w2 = skills.w.half() - new IFloat(1);
    var h1 = -skills.h.half();
    var h2 = skills.h.half() - new IFloat(1);
    switch (type) {
      case FootL:  x = w1 + 1; y = h2 + 1;
      case FootR:  x = w2 - 1; y = h2 + 1;
      case ShinL:  x = w1 - 1; y = h2 - 2;
      case ShinR:  x = w2 + 1; y = h2 - 2;
      case ChestL: x = w1 - 1; y = h1 + 2;
      case ChestR: x = w2 + 1; y = h1 + 2;
      case LedgeL: x = w1 - 2; y = h1 - 1;
      case LedgeR: x = w2 + 2; y = h1 - 1;
      case BonkL:  x = w1 + 1; y = h1 - 1;
      case BonkR:  x = w2 - 1; y = h1 - 1;
      case Last:
    }
  }
}
