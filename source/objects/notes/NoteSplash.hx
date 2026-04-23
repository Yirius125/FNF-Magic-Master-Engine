package objects.notes;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxShaderColorSwap;
import flixel.system.FlxCustomShader;
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

class NoteSplash extends FlxSprite {
    public static var SPLASH_DEFAULT:String = "Magic";

    public var note_path:String = "";

    public var image:String = "None";
    public var style:String = "None";
    public var type:String = "None";

    public var splash_anims:Array<String> = [];

    public var destroyOnSplash:Bool = true;

    public var parent:Dynamic = null;

    public function new(_parent:Dynamic):Void {
        this.parent = _parent;
        super();
    }

    override function update(elapsed:Float) {
		super.update(elapsed);

        if (animation.finished && destroyOnSplash) { if (parent != null) { parent.remove(this); }  this.destroy(); }
	}

    public function setup(X:Float = 0, Y:Float = 0, ?image:String, ?style:String, ?type:String):NoteSplash {
        this.image = image != null ? image : NoteSplash.SPLASH_DEFAULT;
        this.style = style != null ? style : StrumNote.STYLE_DEFAULT;
        this.type = type != null ? type : Settings.get("NoteSkin");

        this.setPosition(X, Y);

        var l_path = Paths.note('${image}_Splash', style, type);

        if (note_path == l_path) { playAnim(splash_anims[FlxG.random.int(0, splash_anims.length - 1)]); return this; }

        note_path = l_path;
        frames = note_path.getAtlas();
        
        setAnimations();

        return this;
    }

    public function setupByNote(daNote:Note, strumNote:StrumNote, ?_image:String, ?_style:String, ?_type:String):NoteSplash {        
        this.image = _image != null ? _image : daNote.splashNote != null ? daNote.splashNote : strumNote.splashNote != null ? strumNote.splashNote : NoteSplash.SPLASH_DEFAULT;
        this.style = _style != null ? _style : daNote.style != null ? daNote.style : StrumNote.STYLE_DEFAULT;
        this.type = _type != null ? _type : daNote.type != null ? daNote.type : Settings.get("NoteSkin");

        var l_path = Paths.note('${this.image}_Splash', style, type);

        if (note_path == l_path) { 
            this.playAnim(splash_anims[FlxG.random.int(0, splash_anims.length - 1)], true); 
            
            this.setGraphicSize(Std.int(daNote.width), Std.int(daNote.height));
            this.updateHitbox();

            shader = daNote.shader;
            
            return this; 
        }
        
        note_path = l_path;
        frames = note_path.getAtlas();
        this.setAnimations();
        
        this.setGraphicSize(Std.int(daNote.width), Std.int(daNote.height));
        this.updateHitbox();
        
        shader = daNote.shader;
        
        return this;
    }

    public function playAnim(anim:String, ?force:Bool = false) {
        animation.play(anim, force);
	}

    public function setAnimations():Void {
        var json_path = note_path.replace('${image}_Splash.png', 'Splash_Anims.json');
        splash_anims = [];

        if (Paths.exists(json_path)) {
            var anim_list:Array<String> = cast Reflect.getProperty(json_path.getJson(), '${image}_Splash');
            if (anim_list != null) {
                for (a in anim_list) {
                    animation.addByPrefix(a, a, 30, false);
                    splash_anims.push(a);
                }
            } else {
                animation.addByPrefix("Splash", "Splash", 30, false);
                splash_anims.push("Splash");
            }
        } else{
            animation.addByPrefix("Splash", "Splash", 30, false);
            splash_anims.push("Splash");
        }

        playAnim(splash_anims[FlxG.random.int(0, splash_anims.length - 1)], true);
    }
}