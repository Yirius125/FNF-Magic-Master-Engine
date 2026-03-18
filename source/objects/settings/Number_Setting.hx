package objects.settings;

import flixel.math.FlxMath;

class Number_Setting extends Setting {    
    public var _value(default, null):Float;

    public var min(default, null):Null<Float>;
    public var max(default, null):Null<Float>;
    public var step(default, null):Float = 1;

    public function new(_name:String, _value:Float, ?_min:Float, ?_max:Float, ?_step:Float):Void {
        if (_step != null) {this.step = _step; }
        this._value = _value;
        this.min = _min;
        this.max = _max;
        super(_name);
    }
    
    override public function get_value():Float { return _value; }

    public function add():Void {
        this._value += this.step; FlxMath.roundDecimal(this._value, 1);
        if (this.max != null && this._value > this.max) {this._value = this.max; }
    }
    public function sub():Void {
        this._value -= this.step; FlxMath.roundDecimal(this._value, 1);
        if (this.min != null && this._value < this.min) {this._value = this.min; }
    }

    public function set(_value:Float):Void {
        this._value = _value; FlxMath.roundDecimal(this._value, 1);
    }
}