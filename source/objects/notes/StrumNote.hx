package objects.notes;

import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxShaderColorSwap;
import objects.scripts.Script;
import states.MusicBeatState;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import flixel.FlxSprite;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using utils.Files;

typedef Note_Graphic_Data = {
    var animations:Array<Note_Animation_Data>;
    var antialiasing:Bool;
    var sing_animation:String;
    var color:String;
}

typedef Note_Animation_Data = {
    var anim:String;
    var symbol:String;
    var indices:Array<Int>;

    var fps:Int;
    var loop:Bool;
}

class StrumNote extends FlxSprite {
    public static var IMAGE_DEFAULT:String = "NOTE_assets";
    public static var STYLE_DEFAULT:String = "Default";

    public static var global_suffix:String = "";
    public static var global_prefix:String = "";

    public var type:String = Settings.get("NoteSkin");
    public var image:String = StrumNote.IMAGE_DEFAULT;
    public var style:String = StrumNote.STYLE_DEFAULT;
    
    public var splashNote:String = null;
    public var canSplash:Bool = true;

    public var noteData:Int = 0;
    public var noteKeys:Int = 4;

    public var playColor(default, set):FlxColor = FlxColor.TRANSPARENT;
    public function set_playColor(_value:FlxColor):FlxColor {
        shader = useColor && noteColor != "None" ? FlxShaderColorSwap.get_shader(noteColor, _value) : null;        
        return playColor = _value;
    }
    
    public var useColor(default, set):Bool = true;
    public function set_useColor(value:Bool):Bool {
        shader = value && noteColor != "None" ? FlxShaderColorSwap.get_shader(noteColor, playColor) : null;        
        return useColor = value;
    }

    public var singAnimation:String = null;

    public var notePath:String = "";
    public var noteColor:String = "None";

    public var affectNotes:Bool = true;

	public function new(_data:Int = 0, _keys:Int = 4, ?_image:String, ?_style:String, ?_type:String) {
        if (_image != null) { image = _image; }
        if (_style != null) { style = _style; }
        if (_type != null) { type = _type; }
        this.noteData = _data;
        this.noteKeys = _keys;
        super();

        loadNote();
	}

    public function setupData(_data:Int, ?_keys:Int) {
        if (_keys != null) {noteKeys = _keys; }
        noteData = _data;
        loadNote();
    }

    public function loadNote(?_image:String, ?_style:String, ?_type:String) {
        var last_anim:String = (this.animation != null && this.animation.curAnim != null) ? this.animation.curAnim.name : "static";
        if (_image != null) { image = _image; } if (_style != null) { style = _style; } if (_type != null) {type = _type; }

        notePath = Paths.note(image, style, type);
        noteColor = notePath.getColorNote();

        frames = notePath.getAtlas();
        var n_json:Note_Graphic_Data = (this is Note) ? Files.getDataNote(noteData, noteKeys, type, style) : Files.getDataStaticNote(noteData, noteKeys, type, style);
        
        playColor = n_json.color != null ? FlxColor.fromString(n_json.color) : 0xffffff;  
        antialiasing = n_json.antialiasing && !style.contains("pixel-");
        singAnimation = n_json.sing_animation;

        if (frames == null || n_json.animations == null || n_json.animations.length <= 0) { return; }

        for (anim in n_json.animations) {
            if (anim.indices != null && anim.indices.length > 0) {animation.addByIndices(anim.anim, anim.symbol, anim.indices, "", anim.fps, anim.loop); }
            else{animation.addByPrefix(anim.anim, anim.symbol, anim.fps, anim.loop); }
        }

        playAnim(last_anim);
    }
    public function addAnim(anim:String, symbol:String, fps:Int, loop:Bool):Void {
        animation.addByPrefix(anim, symbol, fps, loop);
    }

    public function playAnim(anim:String, force:Bool = false) {
		animation.play(anim, force);
	}
}