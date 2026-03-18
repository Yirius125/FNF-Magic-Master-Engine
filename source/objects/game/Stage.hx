package objects.game;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import flixel.system.FlxAssets;
import objects.scripts.Script;
import flixel.tweens.FlxTween;
import haxe.format.JsonParser;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import openfl.utils.Assets;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxG;
import utils.Mods;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class Stage extends FlxTypedGroup<Dynamic> {    
    public static var list(get, never):Array<String>;
    public static function get_list():Array<String> {
        var stageArray:Array<String> = [];
        for (i in Paths.readDirectory('assets/stages')) { if (i.contains(".hx")) { stageArray.push(i.replace(".hx","")); } }
        return stageArray;
    }

    public var stageData:Array<Dynamic> = [];
    public var characterData:Array<Dynamic> = [];

    public var curStage:String = "Stage";

    public var script:Script = null;
    public var camP_1:Array<Int>;
    public var camP_2:Array<Int>;
    public var initChar:Int = 0;
    public var zoom:Float = 0.7;

    public var character_Length(get, never):Int;
	inline function get_character_Length():Int {
        return characterData.length;
    }

    public function new(?stage:String = "Stage", ?chars:Array<Dynamic>) {
        if (chars == null) { chars = []; }
        super();

        load(stage);
        
        setCharacters(chars);
    }

    override function update(elapsed:Float) {
		super.update(elapsed);
    }

    public function load(name:String):Void {
        curStage = name;

        if (script != null) { script.destroy(); }

        script = new Script();
        script.parent = this;
        script.name = curStage;

        script.load(Paths.stage(name), true);
        reload();
    }

    public function loadSource(scr:String):Void {
        if (script != null) { script.destroy(); }

        script = new Script();
        script.parent = this;
        script.name = curStage;

        script.setup(scr, true);

        reload();
    }

    public function reload() {
        zoom = script.getVar("zoom");

        camP_1 = script.getVar("camP_1");
        camP_2 = script.getVar("camP_2");

        initChar = script.getVar("initChar");

        while (stageData.length > 0) { remove(stageData.shift(), true).destroy(); }

        script.call("create");
        
        charge();
    }

    public function charge():Void {
        clear();
        
        if (stageData.length <= 0) { for (char in characterData) { add(char); } return; }

        var current_layer:Int = 0;
        for (current_part in stageData) {
            add(current_part);
            
            for (char in characterData) {
                var char_layer:Int = Std.int(initChar + ((char is Character) ? char.curLayer : char._.layer));
                
                if (char_layer < 0) { char_layer = 0; } 
                if (char_layer >= stageData.length) { char_layer = stageData.length - 1; }

                if (char_layer == current_layer) {
                    if (current_part.scrollFactor != null) { char.scrollFactor.set(current_part.scrollFactor.x, current_part.scrollFactor.y); }
                    add(char);
                }
            }

            current_layer++;
        }
    }

    public function setCharacters(chars:Array<Dynamic>) {
        characterData = [];

        var i:Int = 0;
        for (c in chars) {
            var nChar = new Character(c[1][0], c[1][1], c[0], c[4]);
            nChar.curStatus = c[5];

            nChar.scaleCharacter(c[2]);
            nChar.turnLook(c[3]);

            nChar.ID = i;

            nChar.curLayer = c[6];

            characterData.push(nChar);

            i++;
        }

        charge();
    }

    public function getCharacterById(id:Int):Character { return characterData[id]; }
    public function getCharacterByName(_name:String):Character {
        for (char in characterData) { if (char.curCharacter == _name) { return char; } }
        return null;
    }
    public function getCharacterByStatus(_status:String):Character {
        for (char in characterData) { if (char.curStatus == _status) { return char; } }
        return null;
    }

    public function push(_object:Dynamic):Void { stageData.push(_object); }

    override function destroy():Void {
        if (script != null) { script.destroy(); script = null; }
        for (c in characterData) { if (c == null) { continue; } c.destroy(); }
        super.destroy();
    }
}