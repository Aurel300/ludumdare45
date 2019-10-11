class Render {
  public static function shake(delta:Int):Void {
    Main.ren.shakeAmount += Particle.ch.rangeI(delta >> 1, delta << 1);
  }

  public static function toast(text:String, ?priority:Bool = false):Void {
    if (priority && Main.ren.toasts.length > 0) {
      if (Main.ren.toasts[0].ph < 300)
        Main.ren.toasts[0].ph = 300;
      Main.ren.toasts.insert(1, {
        ph: 0,
        text: text,
        y: H + 4
      });
      Main.ren.toasts.resize(2);
      return;
    }
    Main.ren.toasts.push({
      ph: 0,
      text: text,
      y: H + 4
    });
  }

  public static inline final W:Int = 300;
  public static inline final H:Int = 240;
  public static inline final WH:Int = 300 >> 1;
  public static inline final HH:Int = 240 >> 1;

  var cameraX:Float;
  var cameraVX:Float;
  var cameraY:Float;
  var shakeAmount:Int = 0;
  var toasts:Array<{ph:Int, text:String, y:Float}> = [];
  var lightX:Float;
  var lightY:Float;
  var lightRadius:Float;
  var lightPhase = 0;

  var surf:Surface;
  var vertexCount = 0;
  var bufferPosition:Buffer;
  var bufferUV:Buffer;
  var bufferAlpha:Buffer;
  var uniformLight:Uniform;
  var texW:Int = 512;
  var texH:Int = 512;

  var debugRooms:String->Void;
  var debugRender:String->Void;
  var renderCalls = 0;

  public function new(canvas:js.html.CanvasElement) {
    surf = new Surface({
      el: canvas,
      buffers: [
        bufferPosition = new Buffer("aPosition", F32, 3),
        bufferUV = new Buffer("aUV", F32, 2),
        bufferAlpha = new Buffer("aAlpha", F32, 2),
      ],
      uniforms: [
        uniformLight = new Uniform("uLight", 4)
      ]
    });
    Main.aShade.loadSignal.on(asset -> {
      surf.loadProgram(asset.pack["vert.c"].text, asset.pack["frag.c"].text);
    });
    Main.aPng.loadSignal.on(asset -> {
      //trace("png loaded");
      surf.updateTexture(0, asset.pack["game.png"].image);
    });
    Glewb.rate(delta -> {
      if (Main.aPng.loading)
        return;
      surf.render(0x321E33, () -> {
        vertexCount = 0;
        renderCalls = 1;
        Text.baseShake++;
        Text.shakePhase = 0;
        tick(delta);
        debugRender('$renderCalls');
      });
    });
    debugRooms = Debug.text("rooms rendered");
    debugRender = Debug.text("render calls");

    Main.input.mouse.up.on(e -> {
      var x = (e.x / 2);
      var y = (e.y / 2);
      if (x >= W - 3 - 32 && x < W - 3 - 32 + 16 && y >= 3 && y < 3 + 16)
        Sfx.enable(!Sfx.enabled);
      if (x >= W - 3 - 16 && x < W - 3 - 16 + 16 && y >= 3 && y < 3 + 16)
        Music.enable(!Music.enabled);
    });
    Main.input.keyboard.up.on(e -> {
      if (e == KeyR)
        start();
    });
  }

  public function start():Void {
    Game.reset();

    cameraX = player.room.x * Tile.TW + (player.x:Float) - WH;
    cameraVX = 0;
    cameraY = player.room.y * Tile.TH + (player.y:Float) - HH;
    lightX = player.x.round() + player.room.x * Tile.TW - (cameraX + cameraVX);
    lightY = player.y.round() + player.room.y * Tile.TH - (cameraY);
    lightRadius = 0.8;

    toast("move with $s$$ ` @ #");
    toast("jump with $s$bX");
    toast("you can $s$bdouble jump$s$b and $s$bgrab ledges");
    toast("punch with $s$bC");
    toast("drop-punch by $s$bjumping$s$b, then pressing $s$b@");
    toast("$b$spunch the walls!$b$s");
  }

  public function tick(delta:Float):Void {
    if (player == null || player.room == null)
      return;
    for (actor in player.room.actors)
      actor.tick(delta);
    Music.tick(
      player.room.id == 0 ? -1 : ((player.hp > 3 || player.hp == 0) ? 0 : (player.hp > 1 ? 1 : 2)),
      player.room.id == 0 ? -1 : (player.room.enemies > 0 ? 1 : 0),
      player.room.melody
    );
    cameraX = cameraX * .95 + (player.room.x * Tile.TW + (player.x:Float) - WH) * .05;
    cameraVX = cameraVX * .993 + (player.direction ? 40 : -40) * .007;
    cameraY = cameraY * .95 + (player.room.y * Tile.TH + (player.y:Float) - HH) * .05;
    lightX = lightX * .95 + (player.x.round() + player.room.x * Tile.TW - (cameraX + cameraVX)) * .05;
    lightY = lightY * .95 + (player.y.round() + player.room.y * Tile.TH - (cameraY)) * .05;
    uniformLight.dataF32[0] = lightX;
    uniformLight.dataF32[1] = lightY;
    uniformLight.dataF32[2] = lightRadius + Math.sin(lightPhase / 100.0) * 0.2 + Math.random() * 0.01;
    uniformLight.dataF32[3] = 0.7 * lightRadius + Math.sin(130 + lightPhase / 140.0) * 0.2 + Math.random() * 0.01;
    lightPhase++;
    lightRadius = 0.4 + (player.hp / player.skills.maxHp) * 0.4;
    var rendered = 0;
    var shX = 0.0;
    var shY = 0.0;
    if (shakeAmount > 0) {
      var min = shakeAmount / 25;
      if (min < 1) min = 1;
      shX = Particle.ch.float(min) * Particle.ch.float(min) * Particle.ch.sign();
      shY = Particle.ch.float(min) * Particle.ch.float(min) * Particle.ch.sign();
      if (shakeAmount > 60)
        shakeAmount -= 3;
      else if (shakeAmount > 30)
        shakeAmount -= 2;
      else
        shakeAmount--;
    }
    function renderRoom(room:Room):Void {
      room.tick();
      room.enemies = 0;
      room.alpha = room.alpha * .93 + (room == player.room ? 1.0 : .3) * .07;
      var ox:Int = room.x * Tile.TW - Math.round(cameraX + cameraVX + shX);
      var oy:Int = room.y * Tile.TH - Math.round(cameraY + shY);
      if (ox < -room.w * Tile.TW || ox >= W || oy < -room.h * Tile.TH || oy >= H)
        return;
      rendered++;
      for (layer in -2...3) {
        var i = -1;
        for (y in 0...room.h) for (x in 0...room.w) {
          i++;
          if (room.tiles[i].edge == Outside)
            continue;
          for (vis in room.tiles[i].vis[layer + 2]) {
            //var selected = (layer == 0 && room == player.room && x == player.punchX && y == player.punchY && room.tiles[i].edge == Edge);
            draw(
              ox + x * Tile.TW + vis.tox,
              oy + y * Tile.TH + vis.toy,
              vis.tx, vis.ty, vis.tw, vis.th,
              1.0, room.alpha, vis.tflip
            );
            if (vis.text != null)
              Text.render(ox + x * Tile.TW + vis.tox, oy + y * Tile.TH + vis.toy, vis.text, .2, 1.3 + room.alpha);
          }
        }
        if (layer == 0) {
          for (actor in room.actors) {
            if (actor == player)
              continue;
            if (actor.type == Enemy)
              room.enemies++;
            draw(
              ox + actor.x.round() + actor.tox,
              oy + actor.y.round() + actor.toy,
              actor.baseTx + actor.tx,
              actor.baseTy + actor.ty,
              actor.tw, actor.th, actor.alpha, room.alpha + actor.glow, actor.tflip
            );
          }
          if (room == player.room)
            draw(
              ox + player.x.round() + player.tox,
              oy + player.y.round() + player.toy,
              player.baseTx + player.tx,
              player.baseTy + player.ty,
              player.tw, player.th, player.alpha, room.alpha + player.glow, player.tflip
            );
          room.particles = [ for (p in room.particles) {
            draw(
              ox + p.x.round(),
              oy + p.y.round(),
              p.tx + ((p.frameOff + Std.int(p.phase / p.xpp)) % p.frameMod) * 16, p.ty,
              16, 16, p.dalpha, room.alpha + p.glow, p.tflip
            );
            p.x += p.vx;
            p.y += p.vy;
            p.vx += p.ax;
            p.vy += p.ay;
            p.dalpha += p.dalphaV;
            p.phase++;
            if (p.phase >= p.frames * p.xpp || p.dalpha < 0)
              continue;
            p;
          } ];
        }
      }
    }
    for (room in Room.map) {
      if (room == player.room)
        continue;
      renderRoom(room);
    }
    renderRoom(player.room);

    for (i in 0...player.skills.maxHp) {
      draw(
        3 + i * 12,
        3 - (i == (lightPhase >> 3) % Std.int(5 + (player.hp / player.skills.maxHp) * 80) ? 2 : 0),
        224 + (player.hp > i ? 16 : 0), 96,
        16, 16, 0.9, -1, false
      );
    }
    Text.render(player.skills.maxHp * 12 + 10, 5, 'score: $$b${Game.score}$$b $$s${Game.difficulty == 0 ? "" : 'x${(2 + Game.difficulty) >> 1}.${Game.difficulty % 2 == 0 ? "0" : "5"}'}$$s', .4);
    if (toasts.length > 0) {
      var cur = toasts[0];
      //trace(cur);
      Text.render(WH - (Text.width(cur.text) >> 1), Math.round(cur.y), cur.text, .9);
      cur.y = cur.y * .95 + (cur.ph < 300 ? H - 16 : H + 4) * .05;
      cur.ph++;
      if (cur.ph > 400)
        toasts.shift();
    }
    draw(
      W - 3 - 32, 3,
      320, 264 + (Sfx.enabled ? 0 : 16),
      16, 16, 0.5, -1, false
    );
    draw(
      W - 3 - 16, 3,
      336, 264 + (Music.enabled ? 0 : 16),
      16, 16, 0.5, -1, false
    );

    debugRooms('${rendered}');
  }

  public function draw(x:Int, y:Int, tx:Int, ty:Int, tw:Int, th:Int, ?alpha:Float = 1.0, ?dalpha:Float = 1.0, ?flip:Bool = false):Void {
    surf.indexBuffer.writeUI16(vertexCount);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 2);
    surf.indexBuffer.writeUI16(vertexCount + 1);
    surf.indexBuffer.writeUI16(vertexCount + 3);
    surf.indexBuffer.writeUI16(vertexCount + 2);

    var gx1:Float = ((flip ? x + tw : x) - WH) / WH;
    var gx2:Float = ((flip ? x : x + tw) - WH) / WH;
    var gy1:Float = (H - y - HH) / HH;
    var gy2:Float = ((H - y - th) - HH) / HH;

    bufferPosition.writeF32(gx1);
    bufferPosition.writeF32(gy1);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx2);
    bufferPosition.writeF32(gy1);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx1);
    bufferPosition.writeF32(gy2);
    bufferPosition.writeF32(0);
    bufferPosition.writeF32(gx2);
    bufferPosition.writeF32(gy2);
    bufferPosition.writeF32(0);

    var gtx1 = (tx) / texW;
    var gtx2 = (tx + tw) / texW;
    var gty1 = (ty) / texH;
    var gty2 = (ty + th) / texH;

    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty1);
    bufferUV.writeF32(gtx1);
    bufferUV.writeF32(gty2);
    bufferUV.writeF32(gtx2);
    bufferUV.writeF32(gty2);

    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);
    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);
    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);
    bufferAlpha.writeF32(alpha);
    bufferAlpha.writeF32(dalpha);

    vertexCount += 4;

    if (vertexCount > 400) {
      surf.renderFlush();
      vertexCount = 0;
      renderCalls++;
    }
  }
}
