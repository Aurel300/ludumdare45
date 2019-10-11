import pecan.Co.co;

class Enemy extends Actor {
  static var ch = new Chance(0xD4D41575);

  static function basicSkills():ActorSkills {
    var skills = new ActorSkills();
    skills.canWalk = true;
    skills.mass = 1.5;
    skills.groundAcc = new IFloat(4);
    skills.airAcc = new IFloat(4);
    skills.groundRevAcc = new IFloat(10);
    skills.airRevAcc = new IFloat(10);
    skills.groundDec = new IFloat(8);
    skills.airDec = new IFloat(8);
    skills.maxGroundVX = new IFloat(67);
    skills.maxAirVX = new IFloat(77);
    skills.maxJump1Power = 24;
    skills.attackJump1Power = 0;
    skills.jump1Power = new IFloat(8);
    skills.w = 12;
    skills.h = 12;
    return skills;
  }

  static function spawnPlace(ret:Enemy, room:Room, rx:Int, ry:Int):Enemy {
    ret.moveTo(room);
    ret.x = rx * Tile.TW + Tile.TWH;
    ret.y = ry * Tile.TH + Tile.THH;
    return ret;
  }

  public static function spawn(room:Room, rx:Int, ry:Int, big:Bool):Void {
    if (big)
      spawnBig(room, rx, ry);
    else
      spawnSmall(room, rx, ry);
  }

  public static function spawnSmall(room:Room, rx:Int, ry:Int):Void {
    switch (ch.mod(4)) {
      case 0: spawnGreen(room, rx, ry);
      case 1: spawnGreen(room, rx, ry, true);
      case 2: spawnCrystal(room, rx, ry);
      case _: spawnCrystal(room, rx, ry, true);
    }
  }

  public static function spawnBig(room:Room, rx:Int, ry:Int):Void {
    switch (ch.mod(2)) {
      case 0: spawnWhalon(room, rx, ry);
      case _: spawnWhalon(room, rx, ry, true);
    }
  }

  public static function spawnGreen(room:Room, rx:Int, ry:Int, ?plus:Bool = false):Enemy
    return spawnPlace(new EnemyGreen(plus), room, rx, ry);
  public static function spawnCrystal(room:Room, rx:Int, ry:Int, ?plus:Bool = false):Enemy
    return spawnPlace(new EnemyCrystal(plus), room, rx, ry);
  public static function spawnWhalon(room:Room, rx:Int, ry:Int, ?plus:Bool = false):Enemy
    return spawnPlace(new EnemyWhalon(plus), room, rx, ry);
  public static function spawnChest(room:Room, rx:Int, ry:Int):Enemy
    return spawnPlace(new EnemyChest(), room, rx, ry);

  var ai:pecan.Co<Void, Void>;
  var aiSmart:Float = 1.0;
  var aiDetectX:IFloat = 190;
  var aiDetectY:IFloat = 110;

  var aiSeePlayer:Bool = false;
  var aiPlayerDX:IFloat = 0;
  var aiPlayerDY:IFloat = 0;
  var aiPlayerRight:Bool = false;

  override public function death():Void {
    if (ai != null)
      ai.terminate();
    Particle.smoke(this, Std.int(15 * skills.mass.round()));
    Sfx.play("enemy_death");
    eIdle();
    Game.scoreGain(skills.worth);
  }

  function eAI():Void {
    if (ch.float() > aiSmart)
      return;
    var player = player;
    if (player.dead || ai == null) {
      eIdle();
      return;
    }
    var dx = player.x - x;
    var dy = player.y - y;
    aiSeePlayer = (player.room == room && dx.abs() < aiDetectX && dy.abs() < aiDetectY);
    //trace(dx.round(), dy.round(), aiSeePlayer);
    aiPlayerDX = dx;
    aiPlayerDY = dy;
    if (dx < -1)
      aiPlayerRight = false;
    else if (dx > 1)
      aiPlayerRight = true;
    ai.wakeup();
  }

  inline function eJump():Void input.tick(false, false, false, false, true, []);
  inline function eIdle():Void input.tick(false, false, false, false, false, []);
  inline function eDir(right:Bool):Void input.tick(!right, right, false, false, false, []);
  inline function eLeft():Void input.tick(true, false, false, false, false, []);
  inline function eRight():Void input.tick(false, true, false, false, false, []);
}

class EnemyItem extends Enemy {
  var item:ItemType;

  public function new() {
    var i = Enemy.ch.mod(6);
    while (i == 4) i = Enemy.ch.mod(6);
    this.item = (i:ItemType);
    var skills = Enemy.basicSkills();
    skills.worth = 50;
    skills.mass = 0.5;
    skills.w = 16;
    skills.h = 16;
    super(VParticle, skills, new ActorInput(0));
    baseTx = 256;
    baseTy = 96;
    tox = -8;
    toy = -8;
    tx = (item:Int) * 16;
    ty = 0;
    tw = 16;
    th = 16;
    glow = .4;
  }

  override public function tick(delta:Float):Void {
    eAI();
    super.tick(delta);

    var player = player;
    if (!dead && !player.dead) {
      if (statePhase > 10 && (player.x - x).abs() < 16 && (player.y - y).abs() < 16) {
        Sfx.play("item");
        switch (item) {
          case Hp:
            Render.toast("+1 health");
            player.hp = (player.hp < player.skills.maxHp ? player.hp + 1 : player.hp);
          case HpMax:
            Render.toast("+1 max health");
            player.skills.maxHp++; player.hp++;
          case Diff:
            Render.toast("+1 difficulty");
            Game.difficulty++;
          case Jump:
            Render.toast("+1 jump");
            player.skills.jumps++;
          case Speed:
            /*Render.toast("+1 speed");
            player.skills.groundAcc += new IFloat(30);
            player.skills.maxGroundVX += new IFloat(20);
            player.skills.maxAirVX += new IFloat(20);*/
          case Power:
            Render.toast("+1 damage");
            player.skills.damage++;
        }
        moveTo(null);
        dead = true;
      }
    }

    switch (state) {
      case _ if (dead):
        vx = vy = 0;
      case Hurt(_):
        alpha = 0;
      case _:
    }
    statePhase++;
  }
}

class EnemyChest extends Enemy {
  public function new() {
    var skills = Enemy.basicSkills();
    skills.worth = 200;
    skills.mass = 7.2;
    skills.maxHp = 3;
    skills.w = 16;
    skills.h = 22;
    super(Chest, skills, new ActorInput(0));
    baseTx = 336;
    baseTy = 48;
    tox = -16;
    toy = -12;
    tw = 32;
    th = 24;
    glow = .2;
  }

  override public function death():Void {
    super.death();
    var i = new EnemyItem();
    i.moveTo(room);
    i.x = x;
    i.y = y - 8;
  }

  override public function tick(delta:Float):Void {
    eAI();
    super.tick(delta);

    tx = 0;
    ty = 0;
    switch (state) {
      case _ if (dead):
        vx = vy = 0;
        tx = 2;
        ty = 1;
      case Hurt(_):
        if (hp == 0) {
          tx = [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2][statePhase];
          ty = statePhase >= 5 ? 1 : 0;
        }
        else
          tx = [1, 1, 1, 1, 3, 3, 3, 3, 0, 0, 0, 0, 0, 2, 2, 2, 2, 0, 0, 0, 0, 3, 3, 3, 0, 0, 0, 2, 2, 2][statePhase];
      case _:
    }
    tx *= 32;
    ty *= 24;
    statePhase++;
  }
}

class EnemyCrystal extends Enemy {
  public var plus:Bool;
  public var targetX:IFloat;
  public var targetY:IFloat;

  var speed:Int;
  var swoop:Int = 0;
  var distance:Float = 50.0;

  public function new(plus:Bool) {
    this.plus = plus;
    var skills = Enemy.basicSkills();
    skills.maxHp = plus ? 4 : 2;
    skills.worth = plus ? 100 : 50;
    skills.mass = 0.7;
    speed = plus ? 80 : 40;
    skills.airAcc = new IFloat(speed);
    skills.airRevAcc = new IFloat(110);
    skills.airDec = new IFloat(2);
    skills.canJump = true;
    skills.h = 8;
    skills.actions.push({
      id: "shoot",
      enterFrom: (_, p, h) -> h && state.match(Jumping(Normal)),
      tick: (_, ph, p, h) -> {
        if (ph == 3)
          Sfx.play("crystal_charge");
        capKeepAction(ph, 39);
      }
    });
    skills.canAction.push(true);
    super(Enemy, skills, new ActorInput(1));
    baseTx = 352;
    baseTy = 16;
    tox = -12;
    toy = -8;
    tw = 24;
    th = 16;
    glow = plus ? .7 : .3;
    ethereal = true;
    var angle = -Math.PI * .5;
    var s = Math.sin(angle);
    var c = Math.cos(angle);
    ai = co({
      while (true) {
        if (swoop >= 0 && Enemy.ch.float() < .04) {
          angle = Enemy.ch.rangeF(.3, .9) * (Enemy.ch.bool() ? 1 : -1) - Math.PI * .5;
          s = Math.sin(angle);
          c = Math.cos(angle);
        }
        if (state.match(Jumping(Normal))) {
          distance -= 0.3;
          if (distance < 50.0)
            distance = 50.0;
          targetX = targetX * .95 + (player.lastGroundX + c * distance) * .05;
          var lswoop = this.swoop;
          targetY = lswoop < 0 ? player.lastGroundY - 6 : (targetY * .95 + (player.lastGroundY + s * distance + Math.sin(statePhase / 100) * 20) * .05);
          var dx = targetX - x;
          var dy = targetY - y;
          if ((lswoop < 0 && dy.abs() < 4) || lswoop == -1) {
            direction = aiPlayerRight;
            input.tick([true]);
            swoop = 0;
          } else if (dx.abs() < 30 && dy.abs() < 30 && 200 + Enemy.ch.mod(700) < swoop) {
            swoop = -190;
          } else {
            input.tick(
              dx < -8,
              dx > 8,
              dy > 2,
              dy < -2,
              false,
              [false]
            );
          }
        }
        swoop++;
        suspend();
      }
    }).run();
    aiSmart = .6;
  }

  override public function tick(delta:Float):Void {
    eAI();
    super.tick(delta);

    if (room != null && Enemy.ch.float() < .1) {
      room.particles.push({
        tx: 288,
        ty: 0,
        tflip: Enemy.ch.bool(),
        x: x + Enemy.ch.rangeI(-5, 5) - 8,
        y: y + Enemy.ch.rangeI(-3, 5) - 8,
        vx: new IFloat(Enemy.ch.rangeI(-1, 1)),
        vy: new IFloat(2),
        ax: 0,
        ay: new IFloat(1),
        phase: 0,
        xpp: 20 + Enemy.ch.mod(10),
        frameOff: Enemy.ch.mod(4),
        frameMod: 4,
        frames: 1,
        dalphaV: -0.03,
        glow: .3
      });
    }

    tx = 0;
    ty = 0;
    glow = plus ? .7 : .3;
    switch (state) {
      case Jumping(Normal):
        jumpTicks = 2;
        vy += new IFloat(swoop < 0 ? speed * 3 : speed).negpos(input.up, input.down);
        tx = (statePhase >> 1) % 3;
      case Jumping(Fell):
        if (statePhase > 10)
          goto(Jumping(Normal));
      case Hurt(_):
        tx = (statePhase < 5 ? 3 : 4);
        distance += 0.5;
      case Action({id: "shoot"}, phase):
        glow += (phase / 39) * .5;
        vx = 0;
        vy = 0;
        capDamage(true);
        tx = [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 1, 0][phase];
        if (phase == 35) {
          Sfx.play("crystal_shoot");
          Bullet.shoot(this);
        }
        ty = 1;
        swoop = 0;
      case _:
        goto(Jumping(Normal));
    }
    tx *= 24;
    ty *= 16;
    tflip = direction;
    statePhase++;
  }
}

class EnemyWhalon extends Enemy {
  public var plus:Bool;
  var aggro = 0.5;
  var blink:Int = 0;
  var landed:Int = 0;

  public function new(plus:Bool) {
    this.plus = plus;
    var skills = Enemy.basicSkills();
    skills.maxHp = plus ? 10 : 7;
    skills.worth = plus ? 1000 : 500;
    skills.mass = plus ? 4.5 : 4.;
    skills.groundAcc = new IFloat(1);
    skills.maxGroundVX = new IFloat(plus ? 37 : 27);
    skills.maxJump1Power = plus ? 28 : 32;
    skills.attackJump1Power = 0;
    skills.jump1Power = new IFloat(2);
    skills.canJump = true;
    skills.w = 15;
    skills.h = 23;
    skills.canSmash = true;
    super(Enemy, skills, new ActorInput(0));
    baseTx = 64;
    baseTy = plus ? 168 : 136;
    tox = -16;
    toy = -22;
    tw = 32;
    th = 32;
    var roam = 0;
    var ptarget = 0;
    ai = co({
      while (true) {
        skills.groundAcc = new IFloat(1 + Std.int(aggro * 4));
        skills.maxGroundVX = new IFloat(37 + Std.int(aggro * 80));
        var see = aiSeePlayer && Enemy.ch.float() < aggro;
        if (landed > 0) {
          eIdle();
        } else if (state.match(Jumping(Normal))) {
          if (jumpTicks == 1) {
            input.tick(false, false, true, false, false, []);
          } else {
            eIdle();
          }
        } else if (state.match(Jumping(_))) {
          eIdle();
        } else if (!see || Enemy.ch.float() < .05 - (aggro * .04)) {
          if (roam == 1) eLeft();
          else if (roam == 2) eRight();
          else eIdle();
          if (Enemy.ch.float() < .03) roam = Enemy.ch.mod(3);
        } else {
          if (Enemy.ch.float() < .03) ptarget = -40 + Enemy.ch.mod(81);
          var ptdx = (player.x - x) + ptarget;
          if (ptdx.abs() > (plus ? 24 : 80)) {
            eDir(ptdx > 0);
          } else if (Enemy.ch.float() < (plus ? .02 : .05)) {
            eJump();
          } else {
            eIdle();
          }
        }
        suspend();
      }
    }).run();
    aiSmart = plus ? .1 : .05;
  }

  override public function transition(from:ActorState, to:ActorState):Void {
    if (from.match(Jumping(Smash))) {
      Sfx.play("whalon_smash");
      Bullet.shockwave(this);
      landed = 20;
    }
  }

  override public function tick(delta:Float):Void {
    eAI();
    super.tick(delta);

    if (room != null && Enemy.ch.float() < aggro - .7)
      room.particles.push({
        tx: 176,
        ty: 0,
        tflip: Enemy.ch.bool(),
        x: x + Enemy.ch.rangeI(-12, 12) - 8,
        y: y + Enemy.ch.rangeI(-5, 5) - 17,
        vx: new IFloat(Enemy.ch.rangeI(-8, 8)),
        vy: new IFloat(-2),
        ax: 0,
        ay: new IFloat(-1),
        phase: 0,
        xpp: 6,
        frameMod: 5,
        frames: 5
      });

    tx = 0;
    ty = 0;
    if (statePhase % 30 == 29) {
      if (blink == 0 && Enemy.ch.bool())
        blink = Enemy.ch.mod(plus ? 6 : 5);
      else
        blink = 0;
    }
    toy = -22;
    switch (state) {
      case _ if (landed > 0):
        tx = 4;
        landed--;
      case Walk if (!wallBlock):
        tx = [0, 1, 0, 2][(statePhase >> 4) % 4];
        toy = tx != 0 ? -23 : -22;
      case Idle | Walk: 
        tx = [0, 3, 4, 5, 6, 7][blink];
      case Jumping(_):
        if (vy < -1 || statePhase < 4)
          tx = 3;
        else
          tx = 0;
      case Hurt(_):
        aggro += 0.005;
      case _:
    }
    if (aggro > 1) aggro = 1;
    aiSmart = (plus ? .1 : .05) + (aggro * .5) + (state.match(Jumping(_)) ? .4 : 0);
    tx *= 32;
    ty *= 32;
    tflip = direction;
    statePhase++;
  }
}

class EnemyGreen extends Enemy {
  public var plus:Bool;
  var maxDash:Int;

  public function new(plus:Bool) {
    this.plus = plus;
    var skills = Enemy.basicSkills();
    skills.maxHp = plus ? 2 : 1;
    skills.worth = plus ? 50 : 20;
    if (plus) {
      skills.canJump = true;
      skills.groundAcc = new IFloat(8);
      skills.maxGroundVX = new IFloat(87);
    }
    maxDash = (plus ? 125 : 105);
    skills.actions.push({
      id: "dash",
      enterFrom: (_, p, h) -> p && state.match(Idle | Walk),
      tick: (_, ph, p, h) -> {
        if (ph < 49) {
          vx = new IFloat([0, -32, -72, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 31, 75, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, maxDash, 85, 61, 47][ph]);
          if (!direction)
            vx = -vx;
        }
        if (ph == 10)
          Sfx.play("green_dash");
        capKeepAction(ph, 49);
      }
    });
    skills.canAction.push(true);
    super(Enemy, skills, new ActorInput(1));
    baseTx = plus ? 288 : 224;
    baseTy = 16;
    tox = -8;
    toy = -9;
    tw = 16;
    th = 16;
    ai = co({
      while (true) {
        while (!aiSeePlayer) {
          eIdle();
          suspend();
        }
        while (aiSeePlayer) {
          if (plus && aiPlayerDY < -16 && Enemy.ch.float() < .3 && !state.match(Jumping(_))) {
            eJump();
          } else if (aiPlayerDX.abs() < (plus ? 50 : 30) && Enemy.ch.bool()) {
            input.tick([true]);
          } else {
            eDir(aiPlayerRight);
          }
          suspend();
        }
      }
    }).run();
    aiSmart = plus ? .1 : .05;
  }

  override public function tick(delta:Float):Void {
    eAI();
    skills.maxGroundVX = new IFloat(input.actions[0] ? (plus ? 160 : 130) : (plus ? 87 : 67));
    super.tick(delta);

    tx = 0;
    ty = 0;
    switch (state) {
      case Walk if (!wallBlock):
        tx = [0, 1, 0, 2][(statePhase >> 2) % 4];
        ty = 1;
      case Idle | Walk:
        tx = [0, 0, 1, 0, 0, 2][(statePhase >> 4) % 6];
      case Action({id: "dash"}, phase):
        if (phase >= 16 && phase % 4 == 0) room.particles.push({
          tx: 256,
          ty: 0,
          tflip: direction,
          x: x - 8,
          y: y - 9,
          vx: new IFloat(-3 + Particle.ch.mod(7)),
          vy: new IFloat(-2),
          ax: 0,
          ay: new IFloat(-1),
          phase: 0,
          xpp: 3,
          frameMod: 2,
          frames: 7 + Particle.ch.mod(4),
          dalphaV: -.05
        });
        if (phase >= 16) Damage.melee(this, new IFloat((plus ? 170 : 130) * (direction ? 1 : -1)));
        tx = phase < 16 ? [0, 1][phase >> 3] : 2;
        ty = 2;
      case Jumping(_):
        if (vy < -1 || statePhase < 4)
          tx = 2;
        else
          tx = 1;
        ty = 2;
      case Hurt(_):
        tx = 3;
        ty = (statePhase < 5 ? 0 : 1);
      case _:
    }
    tx *= 16;
    ty *= 16;
    tflip = direction;
    statePhase++;
  }
}
