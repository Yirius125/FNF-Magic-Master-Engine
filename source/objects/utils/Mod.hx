package objects.utils;

import lime.tools.AssetType;
import flixel.util.FlxSave;
import haxe.DynamicAccess;
import hscript.Interp;
import flixel.FlxG;
import utils.Mods;
import haxe.Json;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class Mod {
    public var outdated(get, never):Bool;
    public function get_outdated():Bool { return engine_version == Magic.version; }

    public var id(get, never):Int;
    public function get_id():Int { return Mods.list.indexOf(this); }

    public var name(default, null):String = "Magic Master Engine' Mod";
    public var description(default, null):String = "A Friday Night Funkin' Mod.";

    public var display(default, null):String = "Magic Master Engine' Mod";
    
    public var version(default, null):String = "1.0";
    public var engine_version(default, null):String = "Outdated";

    public var exclusive(default, null):Bool = false;

    public var hide_vanilla(default, null):Bool = false;

    public var save(default, null):FlxSave;
    public var path(default, null):String;

    public var enabled:Bool = true;

    public function new(folder:String) {
        this.path = folder;

        var json_data:Dynamic = {};
        var mod_info_path = '$path/mod.json';
        if (Paths.exists(mod_info_path)) { json_data = mod_info_path.getJson(); }

        this.name = json_data.name != null ? json_data.name : this.name;
        this.description = json_data.description != null ? json_data.description : this.description;

        this.display = json_data.display != null ? json_data.display : this.display;

        this.exclusive = json_data.exclusive != null ? json_data.exclusive : false;
        
        this.hide_vanilla = json_data.hide_vanilla != null ? json_data.hide_vanilla : false;
        
        this.version = json_data.version != null ? json_data.version : this.version;
        this.engine_version = json_data.engine_version != null ? json_data.engine_version : this.engine_version;

		this.save = new FlxSave();
		this.save.bind('mod_${this.name}', 'Yirius125');
    }

    public function toString():String { return '{ name: ${name}, version: ${version}, exclusive: ${exclusive}, hide_vanilla: ${hide_vanilla}, enabled: ${enabled} }'; }
}