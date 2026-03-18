package objects.settings;

using StringTools;

class Category {
    public var name(default, null):String;
    public var id(default, null):String;

    public var settings(default, null):Array<Setting> = [];

    public function new(_name):Void {
        this.name = _name;
        this.id = 'category_${this.name.toLowerCase().replace(" ", "_")}';
    }

    public function get(_setting:String):Dynamic {
        var cur_setting:Setting = setting(_setting);
        if (cur_setting == null) { return null; }
        return cur_setting.value;
    }
    public function push(_setting:Setting):Void {
        settings.push(_setting);
    }

    public function setting(_name:String):Setting {
        for (_setting in settings) {
            if (_setting.name != _name) { continue; }
            return _setting;
        }
        return null;
    }

    public function toString():String { return '{name: ${name}, settings: ${settings}}'; }
}