package objects.notes;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxCustomShader;
import objects.songs.Conductor;
import objects.scripts.Script;
import haxe.format.JsonParser;
import flixel.tweens.FlxTween;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using utils.Files;

class StrumEvent extends StrumNote {
    public var conductor:Conductor = null;
    public var strumTime:Float = 0;
    public var isExternal:Bool = false;
    public var isBroke:Bool = false;

    public function new(_strumtime:Float, _conductor:Conductor = null, _isExternal:Bool = false, _isBroke:Bool = false) {
        this.strumTime = _strumtime;
        this.conductor = _conductor;
        this.isExternal = _isExternal;
        this.isBroke = _isBroke;
        super(-1, 4, isExternal ? "Laptop" : "EventIcon");
        playAnim("BeEvent");
	}

    override public function loadNote(?_image:String, ?_style:String, ?_type:String) {
        if (_image != null) {image = _image; } if (_style != null) {style = _style; } if (_type != null) {type = _type; }

        notePath = Paths.note(image, style, type);

        frames = notePath.getAtlas();    
        if (frames == null) { return; }

        animation.addByPrefix("BeEvent", "BeEvent", 30, false);
        animation.addByPrefix("AfEvent", "AfEvent", 30, false);
        animation.addByPrefix("OffEvent", "OffEvent", 30, false);
    }

    var _lastAnim:String = "";
    override function update(elapsed:Float) {
		super.update(elapsed);

        if (isExternal && isBroke) {
            if (_lastAnim != "OffEvent") {playAnim("OffEvent"); _lastAnim = "OffEvent"; }
        } else if (conductor != null && strumTime < conductor.position) {
            if (_lastAnim != "AfEvent") {playAnim("AfEvent"); _lastAnim = "AfEvent"; }
        } else{
            if (_lastAnim != "BeEvent") {playAnim("BeEvent"); _lastAnim = "BeEvent"; }
        }
	}
}