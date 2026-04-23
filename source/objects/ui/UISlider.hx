package objects.ui;

#if FLX_MOUSE
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;

class UISlider extends FlxSpriteGroup {
	public var body:FlxSprite;
	public var handle:FlxSprite;
	public var valueLabel:FlxText;

	public var value:Float;
	public var minValue:Float;
	public var maxValue:Float;
	public var decimals:Int = 0;

	public var clickSound:String;
	public var hoverSound:String;

	public var idleAlpha:Float = 1;
	public var hoverAlpha:Float = 1;

	public var callback:Float->Void = null;

	public var setVariable:Bool = true;

	public var expectedPos(get, never):Float;

	public var relativePos(get, never):Float;

	public var varString(default, set):String;

	var _bounds:FlxRect;

	public var _width:Int;
	public var _height:Int;

	var _thickness:Int;
	var _color:FlxColor;

	public var _object:Dynamic;

	var _lastPos:Float;

	var _justClicked:Bool = false;
	var _justHovered:Bool = false;

    var isVertical:Bool = false;
    public var valueVisible:Bool = true;

	public function new(X:Float = 0, Y:Float = 0, Size:Int = 8, Width:Int = 100, Height:Int = 15, IsVertical:Bool = false, Object:Dynamic, VarString:String, MinValue:Float = 0, MaxValue:Float = 10, Thickness:Int = 3, Color:Int = 0xFF000000):Void {
		super();
		x = X;
		y = Y;

		decimals = (FlxMath.getDecimals(MaxValue) > decimals ? FlxMath.getDecimals(MaxValue) : FlxMath.getDecimals(MinValue));

        isVertical = IsVertical;
		minValue = MinValue;
		maxValue = MaxValue;
		_object = Object;
		varString = VarString;
		_width = Width;
		_height = Height;
		_thickness = Thickness;
		_color = Color;

		createSlider();
	}

	function createSlider():Void {
		_bounds = FlxRect.get(x, y, _width, _height);

		var colorKey:String = "slider:W=" + _width + "H=" + _height + "C=" + _color.toHexString() + "T=" + _thickness;
		body = new FlxSprite().makeGraphic(_width, _height, 0, false, colorKey);
		body.scrollFactor.set();
        
        FlxSpriteUtil.drawLine(body, 
            isVertical ? _width / 2 : 0, 
            isVertical ? 0 : _height / 2, 
            isVertical ? _width / 2 : _width, 
            isVertical ? _height : _height / 2, 
            {color: _color, thickness: _thickness}
        );

        handle = new FlxSprite().loadGraphic(Paths.image("editor_menu/slide_button"));
        handle.setGraphicSize(isVertical ? _width : 0, isVertical ? 0 : _height); handle.updateHitbox();
        if (isVertical) {handle.y -= (handle.height / 2); } else {handle.x -= (handle.width / 2); }
		handle.scrollFactor.set();

		valueLabel = new FlxText(0, 0, 0, "", 12);
		valueLabel.scrollFactor.set();

		add(body);
		add(handle);
		add(valueLabel);
	}

	public function resize(?__width:Int, ?__height:Int):Void {
		if (__height != null) {_height = __height; }
		if (__width != null) {_width = __width; }
		
		_bounds.set(x, y, _width, _height);

		var colorKey:String = "slider:W=" + _width + "H=" + _height + "C=" + _color.toHexString() + "T=" + _thickness;
		body.makeGraphic(_width, _height, 0, false, colorKey);

        FlxSpriteUtil.drawLine(body,
            isVertical ? _width / 2 : 0,
            isVertical ? 0 : _height / 2,
            isVertical ? _width / 2 : _width,
            isVertical ? _height : _height / 2,
            {color: _color, thickness: _thickness}
        );
		
        handle.setGraphicSize(isVertical ? _width : 0, isVertical ? 0 : _height); handle.updateHitbox();
        if (isVertical) {handle.y = -(handle.height / 2); } else {handle.x = -(handle.width / 2); }
	}

	override public function update(elapsed:Float):Void {
		if (FlxMath.mouseInFlxRect(false, _bounds)) {
			#if FLX_SOUND_SYSTEM if (hoverSound != null && !_justHovered) { FlxG.sound.play(hoverSound); } #end

            valueLabel.visible = valueVisible;
			_justHovered = true;
            alpha = hoverAlpha;

			if (FlxG.mouse.pressed) {
                if (isVertical) { handle.y = FlxG.mouse.screenY - (handle.height / 2); } else { handle.x = FlxG.mouse.screenX - (handle.width / 2); }
				updateValue();

				#if FLX_SOUND_SYSTEM
				if (clickSound != null && !_justClicked) {
					FlxG.sound.play(clickSound);
					_justClicked = true;
				}
				#end
			}

			if (!FlxG.mouse.pressed) { _justClicked = false; }
		} else {
            alpha = idleAlpha;
			_justHovered = false;
            valueLabel.visible = false;
		}

		if ((FlxG.mouse.pressed) && (FlxMath.mouseInFlxRect(false, _bounds))) { updateValue(); }
		if ((varString != null) && (Reflect.getProperty(_object, varString) != null)) { value = Reflect.getProperty(_object, varString); }
        
	    valueLabel.text = Std.string(FlxMath.roundDecimal(value, decimals));

        if (isVertical) {
            if (handle.y + (handle.height / 2) != expectedPos) { handle.y = expectedPos - (handle.height / 2); }
            valueLabel.y = handle.y + handle.height + 5;
        } else {
            if (handle.x + (handle.width / 2) != expectedPos) { handle.x = expectedPos - (handle.width / 2); }
            valueLabel.x = handle.x + handle.width + 5;
        }

		super.update(elapsed);
	}

	function updateValue():Void {
		if (_lastPos == relativePos) { return; }

        if ((setVariable) && (varString != null)) { Reflect.setProperty(_object, varString, FlxMath.roundDecimal((relativePos * (maxValue - minValue)) + minValue, decimals)); }

        _lastPos = relativePos;

        if (callback != null) { callback(value); }
	}

	override public function destroy():Void {
		body = FlxDestroyUtil.destroy(body);
		handle = FlxDestroyUtil.destroy(handle);
		valueLabel = FlxDestroyUtil.destroy(valueLabel);

		_bounds = FlxDestroyUtil.put(_bounds);

		super.destroy();
	}

	function get_expectedPos():Float {
        var pos:Float = 0;
        if (isVertical) {
            pos = y + (_height * ((value - minValue) / (maxValue - minValue)));
            if (pos > y + _height) { pos = y + _height; }
            else if (pos < y) { pos = y; }
        } else {
            pos = x + (_width * ((value - minValue) / (maxValue - minValue)));
            if (pos > x + _width) { pos = x + _width; }
            else if (pos < x) { pos = x; }
        }
		return pos;
	}

	function get_relativePos():Float {
		var pos:Float = isVertical ? (handle.y + (handle.height / 2) - y) / (_height) : (handle.x + (handle.width / 2) - x) / (_width);
		if (pos > 1) { pos = 1; }
		return pos;
	}

	function set_varString(Value:String):String {
		try {
			Reflect.getProperty(_object, Value);
			varString = Value;
		} catch (e:Dynamic) {
			FlxG.log.error("Could not create UISlider - '" + Value + "' is not a valid field of '" + _object + "'");
			varString = null;
		}

		return Value;
	}

	override function set_x(value:Float):Float {
		super.set_x(value);
		updateBounds();
		return x = value;
	}
	override function set_y(value:Float):Float {
		super.set_y(value);
		updateBounds();
		return y = value;
	}

	inline function updateBounds() {
		if (_bounds == null) { return; }
        _bounds.set(x, y, _width, _height);            
	}
}
#end
