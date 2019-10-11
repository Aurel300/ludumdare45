class Map2<T> {
  public var data:Map<Int, Map<Int, T>> = [];
  //public var arr:Array<{x:Int, y:Int}> = [];

  public function new() {}

  public function exists(x:Int, y:Int):Bool {
    return data.exists(x) && data[x].exists(y);
  }

  public function get(x:Int, y:Int):Null<T> {
    return exists(x, y) ? data[x][y] : null;
  }

  public function set(x:Int, y:Int, val:T):Void {
    if (!data.exists(x))
      data[x] = new Map<Int, T>();
    //if (!data[x].exists(y))
    //  arr.push({x: x, y: y});
    data[x][y] = val;
  }

  public function remove(x:Int, y:Int):Void {
    if (exists(x, y))
      data[x].remove(y);
  }

  public function arr():Array<{x:Int, y:Int, value:T}> {
    return [ for (x => row in data) for (y => v in row) {x: x, y: y, value: v} ];
  }

  public function flood(fromX:Int, fromY:Int, visit:(x:Int, y:Int, value:T)->Bool):Bool {
    var queue = [{x: fromX, y: fromY}];
    var visited = new Map2<Bool>();
    var inf = 0;
    while (queue.length > 0) {//} && inf++ < 101500) {
      var cur = queue.shift();
      if (visited.exists(cur.x, cur.y))
        continue;
      visited.set(cur.x, cur.y, true);
      if (!visit(cur.x, cur.y, get(cur.x, cur.y)))
        continue;
      for (off in [
        [1, 0],
        [0, 1],
        [-1, 0],
        [0, -1]
      ]) {
        var tx = cur.x + off[0];
        var ty = cur.y + off[1];
        if (exists(tx, ty) && !visited.exists(tx, ty))
          queue.push({x: tx, y: ty});
      }
    }
    return queue.length == 0;
  }

  public function path(fromX:Int, fromY:Int, visit:(x:Int, y:Int, path:Array<{x:Int, y:Int}>, value:T)->Bool):Void {
    var queue = [{x: fromX, y: fromY, path: []}];
    var visited = new Map2<Bool>();
    while (queue.length > 0) {
      var cur = queue.shift();
      if (visited.exists(cur.x, cur.y))
        continue;
      visited.set(cur.x, cur.y, true);
      if (!visit(cur.x, cur.y, cur.path, get(cur.x, cur.y)))
        continue;
      for (off in [
        [1, 0],
        [0, 1],
        [-1, 0],
        [0, -1]
      ]) {
        var tx = cur.x + off[0];
        var ty = cur.y + off[1];
        if (exists(tx, ty) && !visited.exists(tx, ty))
          queue.push({x: tx, y: ty, path: cur.path.concat([{x: cur.x, y: cur.y}])});
      }
    }
  }
}
