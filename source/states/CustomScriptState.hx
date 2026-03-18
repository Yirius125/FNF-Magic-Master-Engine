package states;

import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import states.editors.CharacterEditorState;
import openfl.utils.Assets as OpenFlAssets;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.text.FlxTypeText;
import states.editors.XMLEditorState;
import flixel.input.mouse.FlxMouse;
import flixel.effects.FlxFlicker;
import flixel.util.FlxGradient;
import flixel.tweens.FlxTween;
import objects.scripts.Script;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.FlxSubState;
import io.newgrounds.NG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxG;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class CustomScriptState extends MusicBeatState {
    public var custom_script:Script;

    public function new(new_script:Script, ?onConfirm:String, ?onBack:String):Void {
        custom_script = new_script;
        custom_script.parent = this;
        
        super(onConfirm, onBack);
        
        scripts.set(new_script.name, new_script);
    }
}
