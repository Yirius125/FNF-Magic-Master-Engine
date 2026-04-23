package flixel.addons.text;

import flixel.ui.*;
import flixel.util.*;
import flixel.addons.ui.*;
import flixel.addons.ui.interfaces.*;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import openfl.display.Shader;
import flixel.sound.FlxSound;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import openfl.display.GraphicsShader;
import flixel.addons.text.FlxTypeText;
import flixel.addons.ui.FlxUI.NamedFloat;
import flixel.system.FlxAssets.FlxShader;

using utils.Files;
using StringTools;

class FlxCustomTypeText extends FlxTypeText {
    public var isTyping:Bool = false;

    public function new(x:Float = 0, y:Float = 0, fieldWidth:Int = 0) {
		super(x, y, fieldWidth, "");

        completeCallback = function() {isTyping = false; };
	}

    public function startText(text:String, delay:Float) {
        isTyping = true;
		resetText(text);
		start(delay, true);
    }

    public function startData(data:Dynamic):Void {
        if (data == null) { return; }

        var final_text:String = "";
        var total_formats:Array<FlxTextFormatMarkerPair> = [];

        var delay:Float = 0.04;

        for (i in 0...data.length) {
            var cur_data:Dynamic = data[i];      

            if (cur_data.time != null) {delay = cur_data.time; }
            if (cur_data.sound != null && Paths.exists(Paths.sound(cur_data.sound))) {sounds = [FlxG.sound.load(Paths.sound(cur_data.sound).getSound())]; }
            if (cur_data.scale != null) {size = cur_data.scale; }

            total_formats.push(new FlxTextFormatMarkerPair(new FlxTextFormat(cur_data.color, cur_data.bold, false, null), '<id_${i}>'));
            final_text += '<id_${i}>${cur_data.text}<id_${i}>';
        }
        
		resetText(final_text);
        applyMarkup(final_text, total_formats);
		start(delay, true);
        
        isTyping = true;
    }
}