package objects.settings;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Setting {
    public var name(default, null):String;
    public var id(default, null):String;

    public var value(get, never):Dynamic;
    public function get_value():Dynamic { return null; }

    public function new(_name):Void {
        this.name = _name;
        this.id = 'setting_${this.name.toLowerCase().replace(" ", "_")}';
    }

    public function toString():String { return '{name: ${name}, value: ${value}}'; }
}