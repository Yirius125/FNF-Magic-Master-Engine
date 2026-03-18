package states;

import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetManifest;
import flixel.util.FlxGradient;
import lime.utils.AssetLibrary;
import openfl.utils.AssetType;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import sys.thread.Thread;
import flixel.FlxSprite;
import lime.app.Promise;
import flixel.ui.FlxBar;
import flixel.FlxState;
import lime.app.Future;
import haxe.io.Path;
import flixel.FlxG;
import haxe.Json;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class VoidState extends FlxState {
    public static var clearAssets:Bool = true;
    public var target:FlxState;

    public function new(_target:FlxState):Void {
        this.target = _target;
        super();
    }

	override function create() {
		if (clearAssets) { Files.clearMemoryAssets(); } else { trace("Not Clearing"); }
        clearAssets = true;
        FlxG.switchState(target);
    }
}