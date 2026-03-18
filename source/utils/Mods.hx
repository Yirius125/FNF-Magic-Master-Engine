package utils;

import objects.scripts.Script;
import lime.tools.AssetType;
import haxe.DynamicAccess;
import objects.utils.Mod;
import hscript.Interp;
import flixel.FlxG;
import haxe.Json;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class Mods {
    public static var saved:Array<{name:String, enabled:Bool}> = [];
    public static var list(default, null):Array<Mod> = [];
    
    public static var mod_scripts:Map<String, Script> = [];

    public static final unload_states:Array<String> = [
        "substates.CustomScriptSubState",
        "substates.MusicBeatSubstate",
        "states.CustomScriptState",
        "substates.FadeSubState",
        "states.PreLoaderState",
        "states.MusicBeatState",
        "states.ModListState",
        "states.LoadingState",
        "states.VoidState",
    ];
    public static final unload_sripts:Array<String> = [
        "substates.CustomScriptSubState",
        "substates.MusicBeatSubstate",
        "states.CustomScriptState",
        "substates.FadeSubState",
        "states.PreLoaderState",
        "states.MusicBeatState",
    ];

    public static var hide_vanilla(get, never):Bool;
    static function get_hide_vanilla() {
        for (mod in list) {if (!mod.enabled) { continue; } if (mod.hide_vanilla) { return true; } if (mod.exclusive) {break; }}
        return false;
    };

    public static function same():Bool {
        if (list.length <= 0) { return true; }
        if (saved.length != list.length) { return false; }
        for (i in 0...list.length) {if (list[i].name == saved[i].name) { continue; } return false; }
        return true;
    }

    public static function init():Void {
        if (FlxG.save.data.mods != null) {saved = FlxG.save.data.mods; } //Loading Saved Mods
        Mods.reload(); // Load Mods from Files
    }

    public static function unload():Void {
        Mods.call("exit");
        
        Scripts.global_scripts.clear();
        Mods.mod_scripts.clear();
    }
    public static function reload():Void {
        Mods.list = []; // Clear Mod List

        //Adding Mods from Archives
        #if (desktop && sys)
        if (FileSystem.exists('mods')) {
            var path_list:Array<String> = FileSystem.readDirectory('mods');

            for (cur_path in path_list) {
                var mod_path:String = FileSystem.absolutePath('mods/${cur_path}');
                if (!FileSystem.isDirectory(mod_path)) { continue; }
                list.push(new Mod(mod_path));
            }
        }
        #end

        // Sorting Mods from Saved
        var cur_saved:Array<{name:String, enabled:Bool}> = saved.copy();
        while(cur_saved.length > 0) {
            var cur_mod:{name:String, enabled:Bool} = cur_saved.pop();
            
            for (mod in list) {
                if (cur_mod.name != mod.name) { continue; }
                mod.enabled = cur_mod.enabled;

                list.remove(mod);
                list.insert(0, mod);
                
                break;
            }
        }
    }

    public static function save():Void {
        Mods.saved = []; 
        
        for (mod in Mods.list) { Mods.saved.push({name: mod.name, enabled: mod.enabled}); }
        
        FlxG.save.data.mods = saved;
        FlxG.save.flush();
        
        Scripts.global_scripts.clear();
        Mods.mod_scripts.clear();

        for (mod in list) {
            if (!mod.enabled) { continue; }
            
            var list_path:String = FileSystem.absolutePath('${mod.path}/scripts');
            if (!FileSystem.exists(list_path)) { if (mod.exclusive) { break; } continue; }
            
            var script_list:Array<String> = FileSystem.readDirectory(list_path);
            for (i in 0...script_list.length) {
                if (!script_list[i].endsWith(".hx")) { continue; }
                var cur_script:String = script_list[i].replace(".hx", "");
                
                if (unload_sripts.contains(cur_script)) { continue; }

                var new_script = new Script();
                new_script.name = cur_script;
                new_script.mod = mod.name;
                new_script.load('${list_path}/${script_list[i]}', true);

                if (cur_script == "Mod") { Mods.mod_scripts.set(mod.name, new_script); continue; }
                if (new_script.getVar('isGlobal')) { Scripts.global_scripts.set(cur_script, new_script); continue; }

                new_script.destroy();
            }

            if (mod.exclusive) { break; }
        }
    }

    public static function getVar(_name:String):Dynamic {
        var l_curVar = null;

		for (key => s in Mods.mod_scripts) {  
            if (l_curVar != null) { break; }
            l_curVar = s.getVar(_name); 
        }

        return l_curVar;
    }
    
    public static function get(_name:String):Mod {
        for (mod in Mods.list) { if (mod.name != _name) { continue; } return mod; }

        return null;
    }

    public static function call(name:String, arguments:Array<Dynamic> = null):Void {
		if (arguments == null) { arguments = []; }

		for (key => s in Mods.mod_scripts) { s.call(name, arguments); }
	}
}
