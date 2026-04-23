package objects.settings;

class Bool_Setting extends Setting {    
    public var _value(default, null):Bool;

    public function new(_name:String, _value:Bool):Void {
        this._value = _value;
        super(_name);
    }

    override public function get_value():Bool { return _value; }

    public function toggle(_change:Null<Bool>):Void {
        this._value = _change != null ? _change : !this._value;
    }
}