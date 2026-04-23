package objects.settings;

class List_Setting extends Setting {    
    public var list(default, null):Array<String>;
    public var index(default, null):Int;

    public function new(_name:String, _value:String, _list:Array<String>):Void {
        this.list = _list;
        this.index = Std.int(Math.max(this.list.indexOf(_value), 0));
        super(_name);
    }
    
    override public function get_value():String { return list[index]; }

    public function toggle(_value:Int = 0):Void { index += _value; limit(); }
    public function set(id:Int):Void { index = id; limit(); }
    public function find(_value:String) { index = list.indexOf(_value); limit(); }

    public function limit():Void {
        if (index >= list.length) {index = 0; }
        if (index < 0) {index = list.length - 1; }
    }
}