package utils;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IEventGetter;
import flixel.addons.ui.interfaces.IFlxUIButton;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.transition.TransitionData;
import flixel.addons.ui.interfaces.IResizable;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxStringUtil;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxGradient;
import flixel.system.FlxAssets;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flash.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Json;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class Language {
    public static var list(get, never):Array<String>;
    public static function get_list():Array<String> {
        var toReturn:Array<String> = [];

        for (path in Paths.readDirectory('assets/data/lang/')) {
            if (!path.endsWith(".json")) { continue; }
            var cur_lang:String = path.split("_")[1].replace(".json", "");
            if (toReturn.contains(cur_lang)) { continue; }
            toReturn.push(cur_lang);
        }

        return toReturn;
    }

    public static var current(default, null):String = "English";
    private static var data:Map<String, Dynamic> = [];

    public static function init():Void {
        var saved_lang:String = Settings.get("Language");
        if (saved_lang == null) {saved_lang = current; }
        Language.load(saved_lang);
    }

    public static function load(?new_lang:String):Void {
        if (new_lang == null) {new_lang == Settings.get("Language"); }
        current = Paths.exists(Paths.getPath('data/lang/lang_${new_lang}.json', TEXT)) ? new_lang : "English"; 

        var new_data:Map<String, Dynamic> = [];
        for (cur_path in Paths.readFile('assets/data/lang/lang_${current}.json')) {
            var file_content:Dynamic = cur_path.getJson();
            for (key in Reflect.fields(file_content)) { new_data.set(key, Reflect.getProperty(file_content, key)); }
        }

        data = new_data;
    }

    public static function getText(key:String):String { return data.exists(key) ? data.get(key) : key; }
    public static function get(key:String):Dynamic { return data.exists(key) ? data.get(key) : key; }
}