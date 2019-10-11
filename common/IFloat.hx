abstract IFloat(Int) {
  public static inline final MULT_SHIFT = 6;
  public static inline final MULT = 1 << MULT_SHIFT;
  public static inline final MULTH = 1 << (MULT_SHIFT - 1);
  public static inline final FRAC_MASK = MULT - 1;
  public static inline final TRIM_MASK = 0xFFFFFFFF ^ FRAC_MASK;

  @:from static inline function fromFloat(r:Float):IFloat
    return new IFloat(Math.round(r * MULT));

  @:from static inline function fromInt(r:Int):IFloat
    return new IFloat(r << MULT_SHIFT);

  @:to inline function toFloat():Float
    return raw / MULT;

  public inline function new(raw:Int)
    this = raw;

  public var raw(get, never):Int;
  inline function get_raw():Int return this;

  public var zero(get, never):Bool;
  inline function get_zero():Bool return this == 0;

  @:commutative @:op(A + B) inline function add(other:IFloat):IFloat
    return new IFloat(raw + other.raw);

  @:op(A + B) inline function addI(other:Int):IFloat
    return new IFloat(raw + (other << MULT_SHIFT));

  @:op(A - B) inline function sub(other:IFloat):IFloat
    return new IFloat(raw - other.raw);

  @:op(A - B) inline function subI(other:Int):IFloat
    return new IFloat(raw - (other << MULT_SHIFT));

  @:commutative @:op(A * B) inline function mul(other:IFloat):IFloat
    return new IFloat((raw * other.raw) >> MULT_SHIFT);

  @:op(A * B) inline function mulI(other:Int):IFloat
    return new IFloat(raw * other);

  @:op(A / B) inline function div(other:IFloat):IFloat
    return new IFloat(Std.int((raw << MULT_SHIFT) / other.raw));

  @:op(A > B) inline function gt(other:IFloat):Bool
    return raw > other.raw;

  @:op(A >= B) inline function gte(other:IFloat):Bool
    return raw >= other.raw;

  @:op(A < B) inline function lt(other:IFloat):Bool
    return raw < other.raw;

  @:op(A <= B) inline function lte(other:IFloat):Bool
    return raw <= other.raw;

  @:op(A > B) inline function gtI(other:Int):Bool
    return raw > (other << MULT_SHIFT);

  @:op(A >= B) inline function gteI(other:Int):Bool
    return raw >= (other << MULT_SHIFT);

  @:op(A < B) inline function ltI(other:Int):Bool
    return raw < (other << MULT_SHIFT);

  @:op(A <= B) inline function lteI(other:Int):Bool
    return raw <= (other << MULT_SHIFT);

  @:op(-A) inline function neg():IFloat
    return new IFloat(-raw);

  public inline function trim():IFloat
    return new IFloat(raw & TRIM_MASK);

  public inline function frac():IFloat
    return new IFloat(raw & FRAC_MASK);

  public inline function negpos(neg:Bool, pos:Bool):IFloat
    return new IFloat(neg != pos ? (neg ? -raw : raw) : 0);

  public inline function round():Int
    return (raw + MULTH) >> MULT_SHIFT;

  public inline function half():IFloat
    return new IFloat(raw >> 1);

  public inline function abs():IFloat
    return new IFloat(raw < 0 ? -raw : raw);

  public inline function max(other:IFloat):IFloat
    return new IFloat(raw > other.raw ? raw : other.raw);

  public inline function min(other:IFloat):IFloat
    return new IFloat(raw < other.raw ? raw : other.raw);

  public inline function sign():Int
    return raw > 0 ? 1 : (raw < 0 ? -1 : 0);

  public inline function clamp(min:IFloat, max:IFloat):IFloat
    return new IFloat(raw > max.raw ? max.raw : (raw < min.raw ? min.raw : raw));
}
