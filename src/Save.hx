class Save {
  static var alpha = "wlpWLPgameGAME_!".split("");
  static var hex = "0123456789abcdef".split("");
  static var key = {
      var skey = "n!ov3r3ng33redRea//y_?!?".split("").map(s -> s.charCodeAt(0));
      [ for (i in 0...20) for (s in [0, 4]) (skey[i] >> s) & 0xF ];
    };

  public static var best:Int = 0;

  public static function save(score:Int):Void {
    if (score < best)
      return;
    best = score;
    //js.Browser.document.querySelector("#best_page").innerText = 'Best score: $score';
    var seq = []; // last in seq = MSb
    var rtime = score;
    while (rtime > 0) {
      seq.push(rtime & 1);
      rtime = rtime >> 1;
    }
    seq.reverse(); // last in seq = LSb
    var st = 0;
    var pos = 0;
    var pdata = [ while (pos < seq.length) {
        var subLen = 0;
        while (seq[pos] == st) { subLen++; pos++; }
        st = 1 - st;
        StringTools.hex(subLen, 2).toLowerCase();
      } ].join("");
    var data = "";
    for (i in 0...pdata.length) data += alpha[(hex.indexOf(pdata.charAt(i)) + key[i]) % 16];
    data = 'wallpunch=$data; expires=Sat, 10 Jul 2023 19:49:00 GMT; path=/';
    untyped __js__('document.cookie = {0}', data);
  }

  public static function init():Void {
    var nameEQ = "wallpunch=";
    var ca:Array<String> = untyped __js__('document.cookie.split(";")');
    var data = "";
    for (c in ca) {
      while (c.charAt(0) == " ") c = c.substr(1);
      if (c.indexOf(nameEQ) == 0) data = c.substr(nameEQ.length);
    }
    var pdata = "";
    for (i in 0...data.length) {
      var io = alpha.indexOf(data.charAt(i));
      if (io == -1) return;
      pdata += hex[(io + 16 - key[i]) % 16];
    }
    var st = 0;
    var seq = [];
    while (pdata.length > 0) {
      if (pdata.length % 2 != 0) return;
      var subLen = pdata.substr(0, 2);
      pdata = pdata.substr(2);
      var len = Std.parseInt("0x" + subLen);
      for (i in 0...len) seq.push(st);
      st = 1 - st;
    }
    if (seq.length > 20) return;
    var res = 0;
    // last in seq = LSb
    for (s in seq) res = (res << 1) | s;
    best = res;
    //js.Browser.document.querySelector("#best_page").innerText = 'Best score: $best';
  }
}
