package objects.notes;

import objects.notes.StrumNote.Note_Animation_Data;
import objects.notes.StrumNote.Note_Graphic_Data;
import flixel.addons.ui.interfaces.IResizable;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxShaderColorSwap;
import objects.notes.Note.Note_Data;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.addons.ui.FlxUIGroup;
import objects.notes.NoteSplash;
import objects.notes.StrumNote;
import haxe.format.JsonParser;
import objects.utils.Controls;
import objects.scripts.Script;
import flixel.tweens.FlxTween;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import haxe.DynamicAccess;
import objects.notes.Note;
import sys.thread.Thread;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.FlxObject;
import states.PlayState;
import flixel.FlxG;
import haxe.Timer;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class StaticNotes extends FlxUIGroup {
    public var line_width:Int = 160;
    public var keys:Int = 4;
    
    public var line_height(get, never):Int;
	inline function get_line_height():Int { return Std.int(line_width / keys); }
    
    public var strum_size(get, never):Int;
    public function get_strum_size():Int { return line_height; }
    
    public var statics(default, null):Array<StrumNote> = [];

    public var image:String = StrumNote.IMAGE_DEFAULT;
    public var style:String = StrumNote.STYLE_DEFAULT;
    public var type:String = Settings.get("NoteSkin");

    public function new(X:Float, Y:Float, ?_keys:Int, ?_width:Int, ?_image:String, ?_style:String, ?_type:String) {
        if (_width != null) {this.line_width = _width; }
        if (_image != null) {this.image = _image; }
        if (_style != null) {this.style = _style; }
        if (_keys != null) {this.keys = _keys; }
        if (_type != null) {this.type = _type; }
        super(X, Y);
                        
        changeKeys(keys, line_width, true);
    }
    
    public function playId(id:Int, anim:String, force:Bool = false) {
        var curStrum:StrumNote = statics[id];
        if (curStrum == null) { return; }
        curStrum.playAnim(anim, force);
    }

    public function loadNotes(?_image:String, ?_style:String, ?_type:String) {
        if (_image != null) {image = _image; } if (_style != null) {style = _style; } if (_type != null) {type = _type; }
        for (key in statics) {key.loadNote(image, style, type); }
    }

    public function changeKeys(_keys:Int, ?_size:Int, ?force:Bool = false) {
        if ((this.keys == _keys && !force) || _keys <= 0) { return; }
        this.keys = _keys;
        
        if (_size != null) { this.line_width = _size; }
        var strumSize:Int = Std.int(line_width / keys);
        
        while (statics.length > 0) {
            var cur_note = statics.shift();
            this.remove(cur_note);
            cur_note.destroy();
        }

        for (i in 0...keys) {
            var strum:StrumNote = new StrumNote(i, keys, image, style, type);
            strum.setGraphicSize(strumSize, strumSize);
            strum.updateHitbox();
            
            strum.x += strumSize * i;
            strum.ID = i;
            
            strum.playAnim('idle');
            
            add(strum);
            statics.push(strum);
        }
    }
}