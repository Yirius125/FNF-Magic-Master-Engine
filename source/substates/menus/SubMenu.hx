package substates.menus;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUISubState;
import flixel.addons.ui.FlxUIGroup;
import flixel.util.FlxSpriteUtil;
import objects.utils.Controls;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Alphabet;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Timer;

using utils.Files;
using StringTools;

class SubMenu extends FlxUISubState {
	public var onClose:Void->Void = function() {};

    public var menuHeight:Int = 100;
    public var menuWidth:Int = 100;

	public var controls(get, never):Controls;
	inline function get_controls():Controls { return Players.get(0).controls; }
    public var canControlle:Bool = false;

	public var curCamera:FlxCamera;

    public var group:FlxTypedGroup<Dynamic>;
    public var backSprite:FlxUI9SliceSprite;

    public function new(onClose:Void->Void = null, _width:Int = 100, _height:Int = 100):Void {
		if (onClose != null) {this.onClose = onClose; }
        this.menuHeight = _height;
        this.menuWidth = _width;

        curCamera = new FlxCamera();
		curCamera.bgColor.alpha = 0;
		FlxG.cameras.add(curCamera);
        
        super();
    }

    override function create():Void {
        super.create();
        FlxG.mouse.visible = false;
        curCamera.zoom = 0.000001;
        
        //backSprite = Magic.roundRect(0, 0, menuWidth, menuHeight, 15, 15, menuColor);
        backSprite = Magic.sliceRect(0, 0, menuWidth, menuHeight, Paths.image("menu_card"));
        backSprite.cameras = [curCamera];
		backSprite.screenCenter();
        add(backSprite);

        group = new FlxTypedGroup<Dynamic>();
        group.cameras = [curCamera];
        add(group);
        
        FlxTween.tween(curCamera, {zoom: 1}, 0.3, {ease: FlxEase.backOut, onComplete: (twn)->{canControlle = true; }});
        FlxG.sound.play(Paths.sound("popUp").getSound(), 0.5);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
    }

    public function doClose():Void {
        canControlle = false;
        FlxG.sound.play(Paths.sound("popUp").getSound(), 0.5);
        FlxTween.tween(curCamera, {zoom: 0.000001}, 0.2, {ease: FlxEase.backIn, onComplete: (twn)->{close(); }});
    }

	override function close():Void {
        FlxG.cameras.remove(curCamera);
        curCamera.destroy();
        super.close();

        if (onClose != null) {onClose(); }
	}
}
