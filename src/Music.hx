class Music {
  static var vAtmo:Array<Float>;
  static var vDrum:Array<Float>;
  static var vLead:Array<Float>;
  static var iAtmo:Array<String> = ["A1", "A2", "A3"];
  static var iDrum:Array<String> = ["B1", "B2"];
  public static var iLead:Array<String> = ["C3", "C4"];
  static var cAtmo:Array<Int>;
  static var cDrum:Array<Int>;
  static var cLead:Array<Int>;
  static var hAtmo:Array<howler.Howl>;
  static var hDrum:Array<howler.Howl>;
  static var hLead:Array<howler.Howl>;
  public static var enabled:Bool = true;

  public static function enable(to:Bool):Void {
    enabled = to;
    if (cAtmo == null)
      return;
    if (!to) {
      for (i in 0...cAtmo.length) hAtmo[i].volume(vAtmo[i] = 0, cAtmo[i]);
      for (i in 0...cDrum.length) hDrum[i].volume(vDrum[i] = 0, cDrum[i]);
      for (i in 0...cLead.length) hLead[i].volume(vLead[i] = 0, cLead[i]);
    }
  }

  public static function init():Void {
    vAtmo = [ for (i in 0...iAtmo.length) 0.0 ];
    vDrum = [ for (i in 0...iDrum.length) 0.0 ];
    vLead = [ for (i in 0...iLead.length) 0.0 ];
    var all = iAtmo.concat(iDrum).concat(iLead);
    Main.aMusic.loadSignal.on(_ -> {
      hAtmo = [ for (id in iAtmo) Asset.ids[id + ".mp3"].sound ];
      cAtmo = [ for (howl in hAtmo) {
        var ch = howl.play();
        howl.loop(true, ch);
        howl.volume(0.01, ch);
        ch;
      } ];
      hDrum = [ for (id in iDrum) Asset.ids[id + ".mp3"].sound ];
      cDrum = [ for (howl in hDrum) {
        var ch = howl.play();
        howl.loop(true, ch);
        howl.volume(0.01, ch);
        ch;
      } ];
      hLead = [ for (id in iLead) Asset.ids[id + ".mp3"].sound ];
      cLead = [ for (howl in hLead) {
        var ch = howl.play();
        howl.loop(true, ch);
        howl.volume(0.01, ch);
        ch;
      } ];
    });
  }

  public static function tick(atmo:Int, drum:Int, lead:Int):Void {
    if (cAtmo == null)
      return;
    if (!enabled) {
      atmo = drum = lead = -1;
    }
    for (i in 0...cAtmo.length) hAtmo[i].volume(vAtmo[i] = vAtmo[i] * .97 + (i == atmo ? .6 : 0) * .03, cAtmo[i]);
    for (i in 0...cDrum.length) hDrum[i].volume(vDrum[i] = vDrum[i] * .97 + (i == drum ? .6 : 0) * .03, cDrum[i]);
    for (i in 0...cLead.length) hLead[i].volume(vLead[i] = vLead[i] * .97 + (i == lead ? .6 : 0) * .03, cLead[i]);
  }
}
