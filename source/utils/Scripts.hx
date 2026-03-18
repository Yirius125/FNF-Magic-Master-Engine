package utils;

import objects.scripts.Script;

class Scripts {
    public static var global_scripts:Map<String, Script> = [];

    public static function contains(key:String):Bool { 
        for (cur_key => s in global_scripts) {
            if (cur_key != key) { continue; }
            return true;
        }
        return false;
    }

    public static function set(key:String, script:Script):Void { global_scripts.set(key, script); }
    public static function get(key:String):Script { return global_scripts.get(key); }

    public static function load(key:String, file:String):Void {
        if (global_scripts.exists(key)) { return; }
        var new_script = new Script();
        new_script.load(file, true);
        new_script.name = key;
        if (new_script.program == null) { return; }
        global_scripts.set(key, new_script);
    }

    public static function quick(file:String, ?name:String):Script {
        var new_script = new Script();
        new_script.load(file, true);

        if (new_script.program == null) { return null; }

        new_script.name = name;
        
        return new_script;
    }
}