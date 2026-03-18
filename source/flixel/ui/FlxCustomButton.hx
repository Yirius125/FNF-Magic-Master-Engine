package flixel.ui;

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

class FlxCustomButton extends FlxButton {
	public function new(X:Float = 0, Y:Float = 0, Width:Null<Int>, Height:Null<Int>, ?Text:String, ?GraphicArgs:Array<Dynamic>, ?Color:Null<FlxColor>, ?OnClick:() -> Void) {
		super(X, Y, Text, OnClick);
        
        this.label.antialiasing = false;

		if (Width == null) {Width = Std.int(this.width); }
		if (Height == null) {Height = Std.int(this.height); }
		
        if (GraphicArgs != null) {
            if (GraphicArgs.length <= 2) {
                this.frames = GraphicArgs[0];
                for (i in (cast(GraphicArgs[1],Array<Dynamic>))) {this.animation.addByPrefix(i[0], i[1], 30, false); }
            } else{Reflect.callMethod(null, this.loadGraphic, GraphicArgs); }
        }
		this.setSize(Width, Height);
		this.setGraphicSize(Width, Height);
		this.centerOffsets();
		this.label.fieldWidth = this.width;
		if (Color != null) {this.color = Color; }
	}
}