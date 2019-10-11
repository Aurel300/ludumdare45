class Room {
  public static var map:Array<Room>;
  public static var ch:Chance;
  public static var chVis:Chance;

  public static function init():Void {
    map = [];
    #if LD_DEBUG
    ch = new Chance(0xF10B7742);
    #else
    ch = new Chance(Std.int(Math.random() * 0x7FFFFFFF));
    #end
    chVis = new Chance(0xE1E51111);
  }

  public static function gxyAny(x:Int, y:Int):Bool {
    var ret = [];
    for (room in map) {
      if (x >= room.x && x < room.x + room.w && y >= room.y && y < room.y + room.h) {
        if (room.xy(x - room.x, y - room.y).edge != Outside)
          return true;
      }
    }
    return false;
  }

  public static function gxy(x:Int, y:Int):Array<Tile> {
    var ret = [];
    for (room in map) {
      if (x >= room.x && x < room.x + room.w && y >= room.y && y < room.y + room.h) {
        var t = room.xy(x - room.x, y - room.y);
        if (t.edge != Outside)
          ret.push(t);
      }
    }
    return ret;
  }

  public static function generate(from:Room, rx:Int, ry:Int, dx:Int, dy:Int):Bool {
    // "worms"
    var touchMap = new Map2<GenType>();
    var tilesTouched = 0;
    var changes:Array<{x:Int, y:Int, from:Null<GenType>}>;
    function undoSet():Void {
      changes = [];
    }
    function undoReset():Void {
      for (ri in 0...changes.length) {
        var change = changes[changes.length - 1 - ri];
        if (change.from == null) {
          touchMap.remove(change.x, change.y);
        } else {
          touchMap.set(change.x, change.y, change.from);
        }
      }
      changes = null;
    }
    function touched(x:Int, y:Int):Bool {
      return touchMap.exists(x, y);
    }
    function touch(x:Int, y:Int, type:GenType):Void {
      tilesTouched++;
      if (changes != null)
        changes.push({x: x, y: y, from: touchMap.get(x, y)});
      touchMap.set(x, y, type);
    }
    var orX = rx + from.x;
    var orY = ry + from.y;
    function edible(x:Int, y:Int):Bool {
      var dfX = x - orX;
      var dfY = y - orY;
      if (dfX == 0 && dfY == 0) return true;
      var sx = dfX > 0 ? 1 : (dfX < 0 ? -1 : 0);
      var sy = dfY > 0 ? 1 : (dfY < 0 ? -1 : 0);
      if (dfX >= -2 && dfX <= 2 && dfY >= -2 && dfY <= 2) {
        return (sx == dx && sy == dy);
      }
      if (dx != 0 ? (sx == 0 || sx == -dx) : (sy == 0 || sy == -dy))
        return false;
      return !gxyAny(x, y);
    }
    function worm(x:Int, y:Int, dx:Int, dy:Int, food:Int, fatigue:Int):Int {
      if (!edible(x, y) || food == 0 || fatigue >= 5)
        return food;
      var any = false;
      if (!touched(x, y)) {
        touch(x, y, Wormed);
        any = true;
      }
      /*for (o in [
        [0, 0],
        [-1, 0],
        [0, -1],
        [1, 0],
        [0, 1]
      ]) {
        if (!touched(x + o[0], y + o[1]) && edible(x + o[0], y + o[1])) {
          touch(x + o[0], y + o[1], Wormed);
          any = true;
        }
      }*/
      fatigue = (any ? 0 : fatigue + 1);
      if (ch.float() < .6) {
        var tdx = dx;
        var sign = (ch.bool() ? 1 : -1);
        dx = dy * sign;
        dy = tdx * sign;
      }
      x += dx;
      y += dy;
      if (food >= 5 && ch.mod(food) >= 5) {
        var split = ch.mod(food - 3);
        food -= split;
        food += worm(x, y, dx, dy, split, 0);
      }
      return worm(x, y, dx, dy, food, fatigue);
    }
    var food = 5;
    var worms = 0;
    while (food > 0 && worms < 100) {
      food = worm(orX, orY, dx, dy, food, 0);
      worms++;
    }
    if (tilesTouched < 5)
      return false;
    // sets
    var setsPlaced = [];
    var setAttempts = 0;
    var setKeys = new Map2<Bool>();
    var touchArr = touchMap.arr();
    while (setsPlaced.length < 2 && setAttempts < 20) {
      var set = ch.member(Set.categories["decor"]);
      var target = ch.member(touchArr);
      var access = ch.member(set.access);
      var sox = target.x - access.x;
      var soy = target.y - access.y;
      var canPlace = true;
      var si = 0;
      for (sy in 0...set.h) {
        for (sx in 0...set.w) {
          var st = set.tiles[si++];
          var x = sox + sx;
          var y = soy + sy;
          var t = gxy(x, y);
          if (!(switch (st) {
            case Any: true;
            case Full:
              var ok = true;
              for (t in gxy(x, y)) {
                if (t.type != Full) {
                  ok = false;
                  break;
                }
              }
              ok && (!touched(x, y) || touchMap.get(x, y).match(Wormed | Placed(Full)));
            case Access(_) | Empty | Monster(_) | Treasure | Shopkeeper | Ladder | Key:
              !gxyAny(x, y) && (!touched(x, y) || touchMap.get(x, y).match(Wormed));
          })) {
            //trace("fail on", st, x, y, sx, sy);
            canPlace = false;
            break;
          }
        }
        if (!canPlace)
          break;
      }
      if (canPlace) {
        undoSet();
        setKeys.set(sox + set.keyX, soy + set.keyY, true);
        var si = 0;
        for (sy in 0...set.h) {
          for (sx in 0...set.w) {
            var st = set.tiles[si++];
            var x = sox + sx;
            var y = soy + sy;
            switch (st) {
              case Access(_): touch(x, y, touched(x, y) ? Placed(Empty) : Placed(Full));
              case Full: touch(x, y, Placed(Full));
              case Any:
              case Monster(big): touch(x, y, PlacedMonster(big, false));
              case Treasure: touch(x, y, PlacedMonster(false, true));
              case _: touch(x, y, Placed(Empty));
            }
          }
        }
        var keysReachable = 0;
        if (!touchMap.flood(orX, orY, (x, y, tile) -> {
          if (!tile.match(Wormed | Placed(Empty) | PlacedMonster(_, _)))
            return false;
          if (setKeys.exists(x, y)) {
            keysReachable++;
            //trace('key $x $y reachable with ${path.map(p -> '${p.x},${p.y}').join(" ")}');
          }
          return true;
        })) return false;
        if (keysReachable == setsPlaced.length + 1) {
          //trace("adding", sox + set.keyX, soy + set.keyY);
          setsPlaced.push({
            x: sox,
            y: soy,
            w: set.w,
            h: set.h
          });
          changes = null;
        } else {
          setKeys.remove(sox + set.keyX, soy + set.keyY);
          undoReset();
        }
      }
      setAttempts++;
    }
    //trace("gen results", setsPlaced, setAttempts);
    // canonise
    var minTouchedX = 1000000;
    var maxTouchedX = -1000000;
    var minTouchedY = 1000000;
    var maxTouchedY = -1000000;
    for (set in setsPlaced) {
      if (set.x < minTouchedX) minTouchedX = set.x;
      if (set.x + set.w - 1 > maxTouchedX) maxTouchedX = set.x + set.w - 1;
      if (set.y < minTouchedY) minTouchedY = set.y;
      if (set.y + set.h - 1 > maxTouchedY) maxTouchedY = set.y + set.h - 1;
    }
    if (!touchMap.flood(orX, orY, (x, y, tile) -> {
      if (x < minTouchedX) minTouchedX = x;
      if (x > maxTouchedX) maxTouchedX = x;
      if (y < minTouchedY) minTouchedY = y;
      if (y > maxTouchedY) maxTouchedY = y;
      if (!tile.match(Wormed | Placed(Empty) | PlacedMonster(_, _)))
        return false;
      if (tile == Wormed)
        touchMap.set(x, y, WormedReachable);
      return true;
    })) return false;
    // difficulty
    var touchArr = touchMap.arr();
    var add = 0;
    var addAttempts = 0;
    while (add < Game.difficulty && addAttempts < 20) {
      var pos = ch.member(touchArr);
      if (!touched(pos.x, pos.y + 1) || !touchMap.get(pos.x, pos.y + 1).match(Placed(Empty))) {
        addAttempts++;
        continue;
      }
      touchMap.set(pos.x, pos.y, PlacedMonster(false, false));
      add++;
    }
    // blit
    if (dx != 1 || dy != 0) minTouchedX--;
    if (dx != -1 || dy != 0) maxTouchedX++;
    if (dx != 0 || dy != 1) minTouchedY--;
    if (dx != 0 || dy != -1) maxTouchedY++;
    var w = maxTouchedX + 1 - minTouchedX;
    var h = maxTouchedY + 1 - minTouchedY;
    var to:Room = new Room(Empty, minTouchedX, minTouchedY, w, h);
    from.xy(rx, ry).type = Portal(to, dx, dy);
    if (from.within(rx + dx, ry + dy))
      from.xy(rx + dx, ry + dy).type = Empty;
    //trace("from portal", rx, ry);
    from.update();
    for (y in 0...h) {
      for (x in 0...w) {
        if (touched(x + to.x, y + to.y)) {
          switch (touchMap.get(x + to.x, y + to.y)) {
            case WormedReachable:
              to.xy(x, y).type = Empty;
            case PlacedMonster(big, treasure):
              to.xy(x, y).type = Empty;
              if (treasure)
                Enemy.spawnChest(to, x, y);
              else
                Enemy.spawn(to, x, y, big);
            case Placed(t):
              to.xy(x, y).type = t;
            case _:
          }
        }
      }
    }
    var tx = rx + from.x - to.x;
    var ty = ry + from.y - to.y;
    to.xy(tx, ty).type = Portal(from, -dx, -dy);
    if (to.within(tx - dx, ty - dy))
      to.xy(tx - dx, ty - dy).type = Empty;
    //trace("to portal", rx + from.x - to.x, ry + from.y - to.y);
    //trace("global portal", rx + from.x, ry + from.y);
    to.update();
    to.melody = ch.bool() ? from.melody : ch.rangeI(0, Music.iLead.length);
    /*
    for (key in setKeys.arr()) {
      var vis = new TileVis(0, 0);
      to.xy(key.x - to.x, key.y - to.y).vis[3].push(vis);
    }
    */
    return true;
  }

  public final type:RoomType;
  public final id:Int;
  public var x:Int;
  public var y:Int;
  public var w:Int;
  public var h:Int;
  public var tiles:Array<Tile>;
  public var tileBoxes:Array<Box> = [];
  public var damage:Array<Damage> = [];
  public var nextDamage:Array<Damage> = [];
  public var boxes:Array<Box> = [];
  public var actors:Array<Actor> = [];
  public var particles:Array<Particle> = [];
  public var portals:Array<{x:Int, y:Int, to:Room, dx:Int, dy:Int}> = [];
  public var alpha:Float = 0.0;
  public var roomDamageCD:Int = 0;
  public var enemies:Int = 0;
  public var melody:Int = 1;

  public function new(type:RoomType, x:Int, y:Int, w:Int, h:Int) {
    id = Room.map.length;
    Room.map.push(this);
    this.type = type;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    tiles = [ for (y in 0...h) for (x in 0...w) new Tile() ];
  }

  public function punch(punchX:Int, punchY:Int, punchDX:Int, punchDY:Int):Void {
    if (roomDamageCD > 0 || !within(punchX, punchY))
      return;
    var tile = xy(punchX, punchY);
    if (tile.type != Full || !tile.edge.match(Edge | Inside))
      return;
    roomDamageCD = 10;
    tile.damage++;
    if (tile.damage <= 5) {
      tile.vis[2].push(new TileVis(9 + tile.damage - 1, 6));
      if (tile.damage < 5) {
        shake(20);
        Particle.smokeAt(
          this,
          punchX * Tile.TW + Tile.TWH - punchDX * Tile.TWH,
          punchY * Tile.TH + Tile.THH - punchDY * Tile.THH, 9
        );
        return;
      }
    }
    if (tile.damage == 5) {
      Particle.smokeAt(
        this,
        punchX * Tile.TW + Tile.TWH,
        punchY * Tile.TH + Tile.THH, 29
      );
      if (tile.edge != Edge || !Room.generate(this, punchX, punchY, punchDX, punchDY)) {
        if (punchX == 0 || punchX == w - 1 || punchY == 0 || punchY == h - 1)
          return;
        // TODO: check other room tiles for Outside
        tile.type = Empty;
        Sfx.play("room_wall");
        update();
      } else {
        Game.scoreGain(100);
        Sfx.play("room_generate");
        shake(50);
      }
    }
  }

  public function update():Void {
    detectEdges();
    updateTiles();
    polish();
  }

  public function detectEdges():Void {
    // mark all walls as outside, everything else as inside
    var outside = tiles.map(t -> t.type == Full);
    // mark walls which have 3 outside neighbours and 1 inside as edge
    function isOutside(x:Int, y:Int):Bool {
      if (x >= 0 && x < w && y >= 0 && y < h)
        return outside[x + y * w];
      return true;
    }
    for (y in 0...h) for (x in 0...w) {
      xy(x, y).edge = (if (isOutside(x, y)) {
        var count = (isOutside(x, y - 1) ? 1 : -1)
          + (isOutside(x + 1, y) ? 1 : -1)
          + (isOutside(x, y + 1) ? 1 : -1)
          + (isOutside(x - 1, y) ? 1 : -1);
        var countDiag = count + (isOutside(x - 1, y - 1) ? 1 : -1)
          + (isOutside(x + 1, y - 1) ? 1 : -1)
          + (isOutside(x + 1, y + 1) ? 1 : -1)
          + (isOutside(x - 1, y + 1) ? 1 : -1);
        if (count > 2)
          countDiag == 8 ? Outside : OutsideVis;
        else if (count == 2)
          Edge;
        else
          Inside;
      } else {
        Inside;
      });
    }
    // anything near portals is inside
    function isPortal(x:Int, y:Int):Bool {
      if (x >= 0 && x < w && y >= 0 && y < h)
        return xy(x, y).type.match(Portal(_, _, _));
      return false;
    }
    for (y in 0...h) for (x in 0...w) {
      var portalNearby = false;
      for (oy in -1...2) for (ox in -1...2) {
        if (isPortal(x + ox, y + oy)) {
          portalNearby = true;
          break;
        }
      }
      if (portalNearby)
        xy(x, y).edge = Inside;
    }
  }

  public function updateTiles():Void {
    // https://stackoverflow.com/questions/5919298/
    tileBoxes = [];
    portals = [];
    for (y in 0...h) {
      var streak = 0;
      var type:TileType = Empty;
      function flush(x:Int):Void {
        if (streak == 0)
          return;
        if (type == Full) {
          var left = false;
          var right = false;
          var x1 = x - streak;
          var x2 = x - 1;
          if (y > 0) {
            left = (x1 > 0 && xy(x1 - 1, y).type != Full && xy(x1 - 1, y - 1).type != Full && xy(x1, y - 1).type != Full);
            right = (x2 < w - 1 && xy(x2 + 1, y).type != Full && xy(x2 + 1, y - 1).type != Full && xy(x2, y - 1).type != Full);
          }
          tileBoxes.push(Box.tileFull(x1, y, streak, left, right));
        }
      }
      for (x in 0...w) {
        var ctype = xy(x, y).type;
        switch (ctype) {
          case Portal(to, dx, dy):
            portals.push({x: x, y: y, to: to, dx: dx, dy: dy});
          case _:
        }
        if (streak == 0) {
          type = ctype;
          streak++;
        } else if (type == ctype) {
          streak++;
        } else {
          flush(x);
          type = ctype;
          streak = 1;
        }
      }
      flush(w);
    }
    //trace('$x $y portals: ${portals.map(p -> {x: p.x, y: p.y, dx: p.dx, dy: p.dy, to: '${p.to.x} ${p.to.y}'})}');
  }

  var mossMap:Array<Int>;
  var decorMap:Array<Int>;

  public function polish():Void {
    for (y in 0...h) {
      for (x in 0...w) {
        var tile = xy(x, y);
        for (i in 0...5)
          tile.vis[i] = [];
        var chkf = (t:Tile) -> t.type == tile.type;
        function chk(x:Int, y:Int):Bool {
          if (x >= 0 && x < w && y >= 0 && y < h)
            return chkf(xy(x, y));
          return true;
        }
        switch (tile.type) {
          case Empty | Portal(_, _, _):
            chkf = t -> t.type.match(Empty | Portal(_, _, _));
            var vis = new TileVis(0, 8 + tile.setTs);
            vis.auto([chk(x, y - 1), chk(x + 1, y), chk(x, y + 1), chk(x - 1, y)]);
            tile.vis[1].push(vis);
          case Full:
            //var vis = new TileVis(0, tile.edge == Edge ? 0 : 4);//4 + tile.setTs);
            var vis = new TileVis(0, 4 + tile.setTs);
            vis.auto([chk(x, y - 1), chk(x + 1, y), chk(x, y + 1), chk(x - 1, y)]);
            tile.vis[2].push(vis);
            if (tile.damage > 0)
              tile.vis[2].push(new TileVis(9 + (tile.damage > 5 ? 5 : tile.damage) - 1, 6));
          case _:
        }
      }
    }
    if (mossMap == null) {
      var i = -1;
      mossMap = [];
      decorMap = [];
      for (y in 0...h) for (x in 0...w) {
        i++;
        mossMap[i] = 0;
        if (y == 0 || x == 0 || x == w - 1)
          continue;
        switch (tiles[i].type) {
          case Full:
            mossMap[i] = (chVis.float() > .9 ? 0 : chVis.mod(3));
          case Empty:
            mossMap[i] = (chVis.float() > .15 ? 0 : chVis.mod(8));
          case _:
        }
        mossMap[i] *= (chVis.bool() ? 1 : -1);
        decorMap[i] = (chVis.float() > .4 ? 0 : chVis.mod(6));
        decorMap[i] *= (chVis.bool() ? 1 : -1);
        if (decorMap[i] != 0 && x > 1) decorMap[i - 1] = 0;
      }
    }
    var i = -1;
    for (y in 0...h) for (x in 0...w) {
      i++;
      if (mossMap[i] == 0)
        continue;
      var m = mossMap[i];
      var flip = m < 0;
      if (flip) m = -m;
      switch (tiles[i].type) {
        case Full:
          var above = [ for (ox in -1...2) xy(x + ox, y - 1).type != Full ];
          var left = mossMap[i - 1] != 0;
          var right = mossMap[i + 1] != 0;
          if (!above[1])
            continue;
          var vis = new TileVis(5, 4 + m);
          vis.toy = -Tile.THH;
          vis.tflip = flip;
          tiles[i].vis[2].push(vis);
          if (above[0] && !left) {
            var vis = new TileVis(4, 4 + m);
            vis.tox = -Tile.TW;
            vis.toy = -Tile.THH;
            tiles[i].vis[2].push(vis);
          }
          if (!above[0]) {
            var vis = new TileVis(7, 4 + m);
            vis.tox = -Tile.TWH;
            vis.toy = -Tile.THH;
            tiles[i].vis[2].push(vis);
          }
          if (above[2] && !right) {
            var vis = new TileVis(6, 4 + m);
            vis.tox = Tile.TW;
            vis.toy = -Tile.THH;
            tiles[i].vis[2].push(vis);
          }
          if (!above[2]) {
            var vis = new TileVis(8, 4 + m);
            vis.tox = Tile.TWH;
            vis.toy = -Tile.THH;
            tiles[i].vis[2].push(vis);
          }
          if (tiles[i - 1].type == Full && tiles[i + 1].type == Full && decorMap[i] != 0) {
            var d = decorMap[i];
            var flip = d < 0;
            if (flip) d = -d;
            var vis = new TileVis(9 + d * 2, 4);
            vis.tox = -8;
            vis.toy = -32;
            vis.tw = 32;
            vis.th = 32;
            vis.tflip = flip;
            tiles[i].vis[1].push(vis);
          }
        case Empty:
          var vis = new TileVis(0, 7);
          vis.tx = 4 * Tile.TW + m * 24;
          vis.tox = -4;
          vis.toy = -4;
          vis.tw = 24;
          vis.th = 24;
          vis.tflip = flip;
          tiles[i].vis[1].push(vis);
        case _:
      }
    }
  }

  public inline function xy(x:Int, y:Int):Tile {
    return tiles[x + y * w];
  }

  public inline function within(x:Int, y:Int):Bool {
    return x >= 0 && y >= 0 && x < w && y < h;
  }

  public function tick():Void {
    if (roomDamageCD > 0)
      roomDamageCD--;
    var tmp = nextDamage;
    nextDamage = damage;
    damage = tmp;
    nextDamage.resize(0);
  }
}

enum GenType {
  Wormed;
  WormedReachable;
  Placed(t:TileType);
  PlacedMonster(big:Bool, treasure:Bool);
}
