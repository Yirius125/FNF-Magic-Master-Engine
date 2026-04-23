package objects.ui;

import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IHasParams;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.FlxUI;
import flixel.util.FlxColor;

using utils.Files;
using StringTools;

class UINumericStepper extends FlxUIGroup implements IFlxUIWidget implements IFlxUIClickable implements IHasParams {
    public static inline var CHANGE_EVENT:String = "change_stepper";
    public static inline var CLICK_BACK:String = "click_minus";
    public static inline var CLICK_FRONT:String = "click_plus";

    private var _OnChange:Void->Void = null;
	
	private var _btnMinus:FlxUIButton;
    private var _lblCuItem:FlxUIText;
    private var _btnPlus:FlxUIButton;

    private var prefix:String = "";
    private var suffix:String = "";

    public var step:Float = 1;

	public var min(default, set):Float = 0;
	private function set_min(f:Float):Float {
		min = f;
		if (value < min) { value = min; }
		return min;
	}

	public var max(default, set):Float = 10;
	private function set_max(f:Float):Float {
		max = f;
		if (value > max) { value = max; }
		return max;
	}

	public var value(default, set):Float = 0;
	private function set_value(f:Float):Float {
		value = f;
		if (value < min) { value = min; }
		if (value > max) { value = max; }
		if (_lblCuItem != null) {
			var displayValue:Float = value;
            _lblCuItem.text = decimalize(displayValue, decimals);
		}
		return value;
	}

	public var decimals(default, set):Int = 0;
	private function set_decimals(i:Int):Int {
		decimals = i;
		if (i < 0) { decimals = 0; }
		value = value;
		return decimals;
	}

    public var params(default, set):Array<Dynamic>;
	private function set_params(p:Array<Dynamic>):Array<Dynamic>{ return params = p; }

    public var skipButtonUpdate(default, set):Bool;
    private function set_skipButtonUpdate(b:Bool):Bool{
        skipButtonUpdate = b;
        return b;
    }

    public function new(X:Float = 0, Y:Float = 0, Width:Int = 100, Size:Int = 12, DefaultValue:Float = 0, Step:Float = 1, Min:Float = 0, Max:Float = 999, Decimals:Int = 0, ?OnChange:Void->Void):Void {
        this._OnChange = OnChange;
		this.min = Min;
		this.max = Max;
        this.step = Step;
		this.decimals = Decimals;
		this.value = DefaultValue;
        super(X, Y);

        _btnMinus = new UIButton(0, 0, 40, null, "-", Size, null, null, _onMinus);
        _lblCuItem = new FlxUIText(_btnMinus.x + _btnMinus.width, _btnMinus.y, Width - 80, '${value}', Size);
        _lblCuItem.color = FlxColor.WHITE; _lblCuItem.alignment = CENTER;
        _btnPlus = new UIButton(0, _lblCuItem.y, 40, null, "+", Size, null, null, _onPlus);
        
        _btnMinus.resize(Std.int(_lblCuItem.height), Std.int(_lblCuItem.height));
        _btnPlus.resize(Std.int(_lblCuItem.height), Std.int(_lblCuItem.height));
        _lblCuItem.fieldWidth = Width - _btnMinus.width - _btnPlus.width;
        _btnPlus.label.fieldWidth = _btnPlus.width;
        _btnMinus.label.fieldWidth = _btnMinus.width;

        _lblCuItem.x = _btnMinus.x + _btnMinus.width;
        _btnPlus.x = _lblCuItem.x + _lblCuItem.width;

        add(_btnMinus);
        add(_lblCuItem);
        add(_btnPlus);

        calcBounds();
    }

	public function getText() { return _lblCuItem; }

    public function setWidth(Width:Float) {
        Width -= Std.int(_btnMinus.width + _btnPlus.width);
        if (Width < (_btnMinus.width + _btnPlus.width)) {Width = (_btnMinus.width + _btnPlus.width); }
        
        super.setSize(Width, this.height);

        _lblCuItem.width = Width - 40;
        _lblCuItem.fieldWidth = Width - 40;

        _btnPlus.x = _lblCuItem.x + _lblCuItem.width;

        calcBounds();
    }

    public function setPrefix(p:String) {prefix = p; }
    public function setSuffix(s:String) {suffix = s; }

	private function _onPlus():Void
	{
		value += step;
		_doCallback(CHANGE_EVENT);
		_doCallback(CLICK_FRONT);
	}

	private function _onMinus():Void
	{
		value -= step;
		_doCallback(CHANGE_EVENT);
		_doCallback(CLICK_BACK);
	}

    private function _doCallback(event_name:String):Void {
        if (broadcastToFlxUI) {
			FlxUI.event(event_name, this, value, params);
        }
    }

	private inline function decimalize(f:Float, digits:Int):String {
		var tens:Float = Math.pow(10, digits);
		return Std.string(Math.round(f * tens) / tens);
	}
}