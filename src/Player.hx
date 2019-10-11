import Actor.ProbeType;

class Player extends Actor {
  static var probeDebug:String->Void;
  static var stateDebug:String->Void;
  static var jumpDebug:String->Void;
  static var roomDebug:String->Void;

  var walkPhase:Int = 0;

  public function new() {
    var skills = new ActorSkills();
    skills.canWalk = true;
    skills.canLedgeGrab = true;
    skills.canDoubleJump = true;
    skills.canSmash = true;
    skills.canJump = true;
    skills.mass = 1;
    skills.groundAcc = new IFloat(9);
    skills.airAcc = new IFloat(11);
    skills.groundRevAcc = new IFloat(39);
    skills.airRevAcc = new IFloat(29);
    skills.groundDec = new IFloat(9);
    skills.airDec = new IFloat(9);
    skills.maxGroundVX = new IFloat(104);
    skills.maxAirVX = new IFloat(120);
    skills.maxJump1Power = 22;
    skills.attackJump1Power = 14;
    skills.jump1Power = new IFloat(8);
    skills.maxJump2Power = 20;
    skills.attackJump2Power = 16;
    skills.jump2Power = new IFloat(7);
    skills.maxJumpLPower = 20;
    skills.attackJumpLPower = 16;
    skills.jumpLPower = new IFloat(7);
    skills.smashHover = 26;
    skills.iframes = 90;
    skills.maxHp = 3;
    skills.jumps = 1;  
    skills.w = 8;
    skills.h = 12;
    skills.actions.push({
      id: "punch-1",
      enterFrom: (_, p, h) -> p && state.match(Idle | Walk | Action({id: "punch-2"}, _ > 9 => true)),
      tick: (_, ph, p, h) -> {
        if (ph <= 12) {
          vx = new IFloat([0, -16, -72, 0, 5, 31, 75, 81, 81, 81, 75, 61, 27][ph]);
          if (!direction)
            vx = -vx;
        }
        if (ph == 3)
          Sfx.play("punch_miss");
        if (ph > 14) {
          capWalk(skills.groundAcc, skills.groundRevAcc, skills.groundDec);
          capFall()
          || capJump()
          || capKeepAction(ph, 28);
        } else
          capKeepAction(ph, 28);
      }
    });
    skills.canAction.push(true);
    skills.actions.push({
      id: "punch-2",
      enterFrom: (_, p, h) -> p && state.match(Action({id: "punch-1"}, _ > 14 => true)),
      tick: (_, ph, p, h) -> {
        if (ph <= 7) {
          vx = new IFloat([36, 75, 105, 105, 105, 75, 61, 27][ph]);
          if (!direction)
            vx = -vx;
        }
        if (ph == 1)
          Sfx.play("punch_miss");
        if (ph > 9) {
          capWalk(skills.groundAcc, skills.groundRevAcc, skills.groundDec);
          capFall()
          || capJump()
          || capKeepAction(ph, 23);
        } else
          capKeepAction(ph, 23);
      }
    });
    skills.canAction.push(true);
    skills.actions.push({
      id: "punch-air",
      enterFrom: (_, p, h) -> p && !jumpPunched && state.match(Jumping(Normal | Double | Ledge | Fell)),
      tick: (_, ph, p, h) -> {
        jumpPunched = true;
        if (ph <= 7) {
          vx = new IFloat([36, 75, 105, 105, 105, 75, 61, 27][ph]);
          vy = 0;
          if (!direction)
            vx = -vx;
        }
        if (ph == 1)
          Sfx.play("punch_miss");
        if (ph > 9) {
          capKeepAction(ph, 16)
          || capJumpControl(Double);
          capDamage(true)
          || capGrabLedges()
          || capLand()
          || capWalk(skills.airAcc, skills.airRevAcc, skills.airDec);
          capCeiling();
        } else {
          capBottom(true);
          capCeiling();
          capKeepAction(ph, 16);
        }
      }
    });
    skills.canAction.push(true);
    if (probeDebug == null) {
      probeDebug = Debug.text("player probes");
      stateDebug = Debug.text("player state");
      jumpDebug = Debug.text("jump power");
      roomDebug = Debug.text("player room");
    }
    super(Player, skills, new ActorInput(3));
    baseTx = 64;
    baseTy = 16;
    tw = 16;
    th = 16;
  }

  override public function transition(from:ActorState, to:ActorState):Void {
    if (from.match(Jumping(Smash))) {
      Particle.smoke(this, 10);
      room.punch(Std.int(x / Tile.TW), Std.int(y / Tile.TH) + 1, 0, 1);
    }
  }

  override public function death():Void {
    Save.save(Game.score);
    Sfx.play("player_death");
    Render.toast("$s$bgame over$b$s", true);
    Render.toast("R to restart", false);
  }

  override public function tick(delta:Float):Void {
    if (!dead)
      input.tick(
        Main.input.keyboard.held[Key.ArrowLeft],
        Main.input.keyboard.held[Key.ArrowRight],
        Main.input.keyboard.held[Key.ArrowDown],
        Main.input.keyboard.held[Key.ArrowUp],
        Main.input.keyboard.held[Key.KeyX],
        [
          Main.input.keyboard.held[Key.KeyC],
          Main.input.keyboard.held[Key.KeyC],
          Main.input.keyboard.held[Key.KeyC],
        ]
      );
    else
      input.tick([false, false]);
    probeDebug(probes.map(p -> p.hit ? "1" : "0").join(""));
    stateDebug('${state}');
    jumpDebug('${jumpPunched} ${jumpTicks}');
    roomDebug('${room.x} ${room.y}');
    super.tick(delta);

    // animate
    alpha = (iframes > 0 ? .5 + Math.sin(iframes / 2) * .5 : 1);
    tx = 0;
    ty = 0;
    tox = -8;
    toy = -9;
    tflip = !direction;
    switch (state) {
      case _ if (dead):
        ty = 2;
        vx = vy = 0;
      case Walk if (!wallBlock):
        tx = [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2][statePhase % 24];
      case Idle | Walk:
        tx = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1][(statePhase >> 2) % 12];
        ty = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1][(statePhase >> 2) % 12];
      case Hurt(_):
        if (statePhase == 1)
          Sfx.play("player_hurt");
        ty = 2;
      case Action({id: "punch-1"}, phase):
        //tx = [3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 5, 3, 3, 3, 3, 4, 4, 4, 4, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 7][pphase];
        tx = [3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 5, 3, 3, 3, 3, 4, 4, 4, 4][phase];
        if (phase >= 8 && phase < 14) {
          Damage.melee(this, new IFloat(direction ? 153 : -153), new IFloat(-30));
          var dx = direction ? 1 : -1;
          room.punch(Std.int((x + dx * 6) / Tile.TW), Std.int(y / Tile.TH), dx, 0);
        }
      case Action({id: "punch-2"}, phase):
        tx = [4, 4, 4, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 7, 3, 3, 3, 3, 4, 4, 4, 4][phase];
        if (phase >= 3 && phase < 9) {
          Damage.melee(this, new IFloat(direction ? 153 : -153), new IFloat(-30));
          var dx = direction ? 1 : -1;
          room.punch(Std.int((x + dx * 6) / Tile.TW), Std.int(y / Tile.TH), dx, 0);
        }
      case Action({id: "punch-air"}, phase):
        tx = 8;
        ty = 2;
        if (phase >= 3 && phase < 9) {
          Damage.melee(this, new IFloat(direction ? 53 : -53), new IFloat(20));
          var dx = direction ? 1 : -1;
          room.punch(Std.int((x + dx * 6) / Tile.TW), Std.int(y / Tile.TH), dx, 0);
        }
      case LedgeGrabbing(right, _):
        if (statePhase < 39)
          tx = [2, 2, 2, 3, 3, 3, 2, 2, 2, 4, 4, 4, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 4, 4, 4, 4, 4, 4][statePhase];
        else
          tx = 2;
        ty = 1;
        tox = -8 + (right ? 1 : -1);
        toy = -8;
      case Jumping(jt):
        if (jt == Smash) {
          if (statePhase > 20)
            Damage.melee(this, 0, new IFloat(-50));
          if (statePhase == 1)
            Sfx.play("drop_punch");
          tx = statePhase >= 22 ? (6 + ((statePhase >> 1) % 2)) : [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6][statePhase];
          ty = 2;
          tflip = false;
        } else {
          if (vy < -2 || statePhase < 4)
            tx = 5;
          else if (vy < -1)
            tx = 6;
          else if (vy < 0)
            tx = 7;
          else
            tx = 8;
          ty = 1;
        }
      case _:
    }
    tx *= 16;
    ty *= 16;

    statePhase++;
  }
}
