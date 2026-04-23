package objects.game;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.addons.ui.FlxUIGroup;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.FlxSprite;

class LifeBar extends FlxUIGroup {
    public var leftBar(default, null):FlxSprite;
    public var rightBar(default, null):FlxSprite;

    public var min:Float = 0;
    public var max:Float = 2;

    public var value(default, set):Float = 1;
    public function set_value(_value:Float):Float {
        if (_value > max) { _value = max; }
        if (_value < min) { _value = min; }
        
        value = _value;
        updateBar();        
        return value = _value;
    }

    public var frame_value(get, never):Float;
    public function get_frame_value():Float { 
        return 
            flipBar ? 
                rightBar.frameWidth - ((value - min) * rightBar.frameWidth / (max - min)) : 
                (value - min) * rightBar.frameWidth / (max - min)
        ; 
    }

    public var width_value(get, never):Float;
    public function get_width_value():Float { return frame_value * rightBar.scale.x; }
    
    public var flipBar(default, set):Bool = false;
    public function set_flipBar(_value:Bool):Bool {
        flipBar = _value; updateBar();
        return flipBar = _value;
    }

    public function new(_x:Float, _y:Float, _imageBar:String, _colorLeft:FlxColor = FlxColor.LIME, _colorRight:FlxColor = FlxColor.GREEN):Void {
        super(x, y);

        leftBar = new FlxSprite().loadGraphic(_imageBar);
        leftBar.color = _colorLeft;

        rightBar = new FlxSprite().loadGraphic(_imageBar);
        rightBar.color = _colorRight;

        add(leftBar);
        add(rightBar);

        calcBounds();
        
        updateBar();
    }

    public function loadBarGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):Void {
        var l_leftColor = leftBar.color;
        var l_rightColor = rightBar.color;

        leftBar.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
        rightBar.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);

        leftBar.color = l_leftColor;
        rightBar.color = l_rightColor;
    }

    public function setColors(?_colorLeft:FlxColor, ?_colorRight:FlxColor):Void { 
        if (_colorRight != null) { rightBar.color = _colorRight; }
        if (_colorLeft != null) { leftBar.color = _colorLeft; }
    }

    public function setBarScale(_width:Float = 0, _height:Float = 0):Void { for (m in members) {m.scale.set(_width, _height); m.updateHitbox(); } calcBounds(); }
    public function setBarSize(_width:Float = 0, _height:Float = 0):Void { for (m in members) {m.setGraphicSize(_width, _height); m.updateHitbox(); } calcBounds(); }

    public function updateBar():Void {
        leftBar.clipRect = new FlxRect(0, 0, frame_value, leftBar.frameHeight);
        rightBar.clipRect = new FlxRect(frame_value, 0, rightBar.frameWidth - frame_value, rightBar.frameHeight);
    }
}