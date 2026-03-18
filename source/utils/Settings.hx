package utils;

import objects.settings.Number_Setting;
import objects.settings.Bool_Setting;
import objects.settings.List_Setting;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import objects.settings.Category;
import objects.settings.Setting;
import flixel.util.FlxSave;
import objects.notes.Note;
import flixel.FlxG;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Settings {
    private static var current:Array<Category> = [];
	private static var _save:FlxSave;

    public static var categories(get, never):Array<String>;
    public static function get_categories():Array<String> {
        var toReturn:Array<String> = [];
        for (cat in current) {toReturn.push(cat.name); }
        return toReturn;
    }

    public static function init():Void {
		Settings._save = new FlxSave();
		Settings._save.bind('settings', 'Yirius125/Magic Master Engine');

        Settings.reset();
    }
    
    public static function reset():Void {
        Settings.current = [];

        // General Settings | Category
        Settings.push_setting(new List_Setting("Language", "English", Language.list), "GeneralSettings");
        Settings.push_setting(new Bool_Setting("Player2Pad", false), "GeneralSettings");
        Settings.push_setting(new Bool_Setting("PauseOnLostFocus", true), "GeneralSettings");

        // Game Settings | Category
        Settings.push_setting(new Bool_Setting("DownScroll", false), "GameSettings");
        Settings.push_setting(new Bool_Setting("MiddleScroll", false), "GameSettings");
        Settings.push_setting(new Bool_Setting("MissSounds", true), "GameSettings");
        Settings.push_setting(new Bool_Setting("MuteOnMiss", true), "GameSettings");

        // Offset & Scroll | Category
        Settings.push_setting(new List_Setting("ScrollType", "Scaled", ["Scaled", "Forced", "Disabled"]), "OffsetScroll");
        Settings.push_setting(new Number_Setting("ScrollSpeed", 1, 0.1, 10, 0.1), "OffsetScroll");
        Settings.push_setting(new Number_Setting("NoteOffset", 0, null, null, 0.1), "OffsetScroll");
        
        // Visual Settings | Category
        Settings.push_setting(new List_Setting("NoteSkin", "Default", Note.getTypes()), "VisualSettings");
        Settings.push_setting(new Bool_Setting("SplashNotes", true), "VisualSettings");
        Settings.push_setting(new Bool_Setting("MoveCamera", true), "VisualSettings");
        Settings.push_setting(new Bool_Setting("BumpingCamera", true), "VisualSettings");
        
        // Graphic Settings | Category
        Settings.push_setting(new Bool_Setting("UseGpu", true), "GraphicSettings");
        Settings.push_setting(new Number_Setting("Framerate", 60, 30, 240, 1), "GraphicSettings");
        Settings.push_setting(new Bool_Setting("Antialiasing", true), "GraphicSettings");
        Settings.push_setting(new Bool_Setting("Animated", true), "GraphicSettings");
        Settings.push_setting(new Bool_Setting("Onlynotes", false), "GraphicSettings");
        
        // Other Settings | Category
        Settings.push_setting(new Bool_Setting("VisibleMemory", true), "OtherSettings");
        Settings.push_setting(new Bool_Setting("FlashingLights", true), "OtherSettings");
        Settings.push_setting(new Bool_Setting("Violence", true), "OtherSettings");
        Settings.push_setting(new Bool_Setting("Gore", true), "OtherSettings");
        Settings.push_setting(new Bool_Setting("NotSafeForWork", true), "OtherSettings");
        
        // Cheat Settings | Category
        Settings.push_setting(new Bool_Setting("BotPlay", false), "CheatSettings");
        Settings.push_setting(new Bool_Setting("Practice", false), "CheatSettings");
        Settings.push_setting(new Number_Setting("Damage", 1, 0, 2, 0.1), "CheatSettings");
        Settings.push_setting(new Number_Setting("Healing", 1, 0, 2, 0.1), "CheatSettings");
    }
    
    public static function load():Void {
        if (_save.data.settings == null) {trace("No Settings Saved"); return; }

        for (setting in cast(_save.data.settings, Array<Dynamic>)) {
            var cur_setting = get_setting(setting.name, setting.category);
            if (cur_setting == null) { continue; }

            if ((cur_setting is Bool_Setting)) {
                (cast(cur_setting, Bool_Setting)).toggle(setting.value);
            } else if ((cur_setting is List_Setting)) {
                (cast(cur_setting, List_Setting)).find(setting.value);
            } else if ((cur_setting is Number_Setting)) {
                (cast(cur_setting, Number_Setting)).set(setting.value);
            }
        }

        Main.Info.visible = Settings.get("VisibleMemory");
        FlxG.drawFramerate = FlxG.updateFramerate = Settings.get("Framerate");
        
		trace("Settings Loaded Successfully!");     
    }
    public static function save():Void {
        var to_save:Array<{name:String, category:String, value:Dynamic}> = [];

        for (category in current) {
            for (setting in category.settings) {
                to_save.push({
                    name: setting.name,
                    category: category.name,
                    value: setting.value
                });
            }
        }

        if (_save.data.settings == null) {_save.data.settings = []; }
        for (setting in cast(_save.data.settings, Array<Dynamic>)) {
            if (get_setting(setting.name, setting.category) != null) { continue; }
            to_save.push(setting);
        }

        _save.data.settings = to_save;
        _save.flush();
        
        Main.Info.visible = Settings.get("VisibleMemory");
        FlxG.drawFramerate = FlxG.updateFramerate = Settings.get("Framerate");
        
		trace("Settings Saved Successfully!");
    }

    public static function get(_setting:String, ?_category:String):Dynamic {
        if (_category != null) {
            var cur_category:Category = get_category(_category);
            if (cur_category == null) { return null; }
            return cur_category.get(_setting);
        }

        for (cur_category in current) {
            if (cur_category.setting(_setting) == null) { continue; }
            return cur_category.get(_setting);
        }

        return null;
    }

    public static function push_category(_name:String):Void {
        var new_category:Category = new Category(_name);
        
        current.push(new_category);
    }
    public static function get_category(_name:String):Category {
        for (_cat in current) {
            if (_cat.name != _name) { continue; }
            return _cat;
        }
        return null;
    }

    public static function push_setting(_setting:Setting, _category:String):Void {
        if (get_category(_category) == null) {push_category(_category); }
        var cur_category:Category = get_category(_category);
        if (cur_category == null) { return; }
        cur_category.push(_setting);
    }
    public static function get_setting(_setting:String, ?_category:String):Dynamic {
        if (_category != null) {
            var cur_category:Category = get_category(_category);
            if (cur_category == null) { return null; }
            return cur_category.setting(_setting);
        }

        for (cur_category in current) {
            if (cur_category.setting(_setting) == null) { continue; }
            return cur_category.setting(_setting);
        }
        
        return null;
    }
}