package utils;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxCustomShader;
import flixel.input.keyboard.FlxKey;
import openfl.filters.ShaderFilter;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import objects.utils.Controls;
import openfl.geom.Rectangle;
import flixel.util.FlxColor;
import states.LoadingState;
import flixel.util.FlxSave;
import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxG;
import openfl.Lib;

#if windows
import utils.native.Windows;
#end

using StringTools;
using utils.Files;
using utils.Paths;

class Magic {
	public static final version:String = "3.0";

    public static function browser(site:String) { #if linux Sys.command('/usr/bin/xdg-open', [site, "&"]); #else FlxG.openURL(site); #end }
    public static function key(_key:FlxKey):String { return _key.toString(); }

    public static function unload():Void {
        Mods.unload();

        Windows.resetBorderColor();
        Windows.resetIcon();
        FlxG.mouse.unload();

        Controls.reset();
        Settings.reset();
    }
    public static function reload():Void {
        LoadingState.globalStuff = [];
        Files.staticAssets = [];

        Mods.save();

        Mods.call("preload");
        Mods.call("onControlsLoad");

        Settings.load();
        Controls.load();
		Language.init();

        Players.init();
        
        Mods.call("load");
    }
    
    inline public static function setWindowTitle(title:String, type:Int = 0) {
		#if desktop
        switch (type) {
            default: { Lib.application.window.title = '[FNF] Magic Master Engine (${version}): ${title}'; }
            case 1: { Lib.application.window.title = '[MME ${version}]: ${title}'; }
            case 2: { Lib.application.window.title = '${title}'; }
        }
		#end
    }
    
    public static function sortMembersByX(group:FlxTypedGroup<FlxObject>, selectedX:Float, selected:Int = 0, offset:Int = 10, delay:Float = 0.3):Void {
        if (group == null || group.members.length <= 0 || group.members[selected] == null) { return; }
        
        var selObj:FlxObject = group.members[selected];
        selObj.x = FlxMath.lerp(selObj.x, selectedX - (selObj.width / 2), delay);
        
        var leftWidth:Float = selectedX - (selObj.width / 2) - offset;
        var rightWidth:Float = selectedX + (selObj.width / 2) + offset;

        var current:Int = selected - 1;
        while(current >= 0) {
            var curObj:FlxObject = group.members[current];

            leftWidth -= curObj.width;
            curObj.x = FlxMath.lerp(curObj.x, leftWidth, delay);
            leftWidth -= offset;
            current--;
        }

        current = selected + 1;
        while(current < group.length) {
            var curObj:FlxObject = group.members[current];

            curObj.x = FlxMath.lerp(curObj.x, rightWidth, delay);
            rightWidth += curObj.width + offset;
            current++;
        }
    }

    public static function sortMembersByY(group:FlxTypedGroup<FlxObject>, selectedY:Float, selected:Int = 0, offset:Int = 10, delay:Float = 0.3):Void {
        if (group == null || group.members.length <= 0 || group.members[selected] == null) { return; }

        var selObj:FlxObject = group.members[selected];
        selObj.y = FlxMath.lerp(selObj.y, selectedY - (selObj.height / 2), delay);

        var upHeight:Float = selectedY - (selObj.height / 2) - offset;
        var downHeight:Float = selectedY + (selObj.height / 2) + offset;
        
        var current:Int = selected - 1;
        while(current >= 0) {
            var curObj:FlxObject = group.members[current];

            upHeight -= curObj.height;
            curObj.y = FlxMath.lerp(curObj.y, upHeight, delay);
            upHeight -= offset;
            current--;
        }   
        
        current = selected + 1;
        while(current < group.length) {
            var curObj:FlxObject = group.members[current];

            curObj.y = FlxMath.lerp(curObj.y, downHeight, delay);
            downHeight += curObj.height + offset;
            current++;
        }
    }

    public static function roundRect(_x:Float, _y:Float, _width:Int, _height:Int, _ellipseWidth:Float = 15, _ellipseHeight:Float = 15, _color:FlxColor = FlxColor.BLACK):FlxSprite {        
        return FlxSpriteUtil.drawRoundRect(new FlxSprite(_x, _y).makeGraphic(_width, _height, FlxColor.TRANSPARENT), 0, 0, _width, _height, _ellipseWidth, _ellipseHeight, _color);
    }
    public static function sliceRect(_x:Float, _y:Float, _width:Int, _height:Int, _image:String, _slice1:Int = 20, _slice2:Int = 20, _slice3:Int = 78, _slice4:Int = 78):FlxUI9SliceSprite {
        return new FlxUI9SliceSprite(_x, _y, _image.getGraphic(true), new Rectangle(0, 0, _width, _height), [_slice1, _slice2, _slice3, _slice4], FlxUI9SliceSprite.TILE_BOTH);
    }
    public static function customSliceRect(_x:Float, _y:Float, _width:Int, _height:Int, _image:String):{data:FlxUI9SliceSprite, info:Array<String>} {
        var slice_text:String = _image.replace('png', "txt");
        var slice_info:Array<String> = [];

        if (slice_text.exists()) { slice_info = slice_text.getText().split('\n'); }

        return {
            info: slice_info, 
            data: new FlxUI9SliceSprite(
                _x, _y, 
                _image.getGraphic(true), 
                new Rectangle(0, 0, _width, _height), 
                FlxStringUtil.toIntArray(slice_info[0]), 
                FlxUI9SliceSprite.TILE_BOTH
            )
        };
    }

    public static function lerpX(obj:Dynamic, dest:Float, ?radio:Float = 0.1):Void { obj.x = FlxMath.lerp(obj.x, dest, radio); }
    public static function lerpY(obj:Dynamic, dest:Float, ?radio:Float = 0.1):Void { obj.y = FlxMath.lerp(obj.y, dest, radio); }

    public static function doToMember(grp:FlxTypedGroup<FlxSprite>, index:Int, selFun:FlxSprite->Void, odFun:FlxSprite->Void):Void {
        if (grp == null || grp.length <= 0) { return; }

        for (i in 0...grp.members.length) {
            if (i == index) { selFun(grp.members[i]); }
            else { odFun(grp.members[i]); }
        }
    }

    public static var shaders:Map<String, FlxCustomShader> = [];
    public static function getShaderFilter(_shader:String):ShaderFilter { return new ShaderFilter(getShader(_shader)); }
    public static function getShader(_shader:String, _save:Bool = false):FlxCustomShader {
        if (shaders.exists(_shader)) {
			if (shaders.get(_shader) != null) { return shaders.get(_shader); }
            shaders.remove(_shader);
        }

        var l_newShader:FlxCustomShader = new FlxCustomShader({fragmentsrc: Files.getText(Paths.shader(_shader))});
        
        if (_save) { shaders.set(_shader, l_newShader); }

        return l_newShader;
    }
}