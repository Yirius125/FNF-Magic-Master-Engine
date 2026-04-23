package objects.ui;

import flixel.addons.ui.interfaces.IFlxUIClickable;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IHasParams;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUI;
import objects.ui.UIButton;

using utils.Files;
using StringTools;

class UIValueChanger extends FlxUIGroup implements IFlxUIWidget implements IFlxUIClickable implements IHasParams {
    private var _OnChange:Float->Void = null;
	
    private var _lblCuItem:FlxUIInputText;
	private var _btnMinus:UIButton;
    private var _btnPlus:UIButton;

    public static inline var CLICK_MINUS:String = "value_changer_minus";
    public static inline var CLICK_PLUS:String = "value_changer_plus";
    public static inline var CHANGE_EVENT:String = "value_changer_change";

    public var params(default, set):Array<Dynamic>;
	private function set_params(p:Array<Dynamic>):Array<Dynamic>{ return params = p; }

    public var skipButtonUpdate(default, set):Bool;
    private function set_skipButtonUpdate(b:Bool):Bool{
        skipButtonUpdate = b;
        return b;
    }
    
    public var value(get, never):Float;
	inline function get_value():Float { return Std.parseFloat(_lblCuItem.text); }

    public function new(X:Float = 0, Y:Float = 0, Width:Int = 100, _value:Float = 0, ?OnChange:Float->Void, ?text:FlxUIInputText) {
        super(X, Y);
        
        this.antialiasing = false;

        _btnMinus = new UIButton(0, 0, 20, null, "-", null, function() {c_Index(-1); });

		if (text != null) {
			_lblCuItem = text;
            _lblCuItem.text = '$_value';
			_lblCuItem.setPosition(_btnMinus.x + _btnMinus.width, _btnMinus.y + 1);
		} else {
			_lblCuItem = new FlxUIInputText(_btnMinus.x + _btnMinus.width, _btnMinus.y + 1, Width - 40, "0", 8);
			_lblCuItem.alignment = CENTER;
            _lblCuItem.text = '$_value';
		}

        _btnMinus = new UIButton(0, 0, 20, Std.int(_lblCuItem.height) + 2, "-", null, function() {c_Index(-1); });
        _btnPlus = new UIButton(_lblCuItem.x + _lblCuItem.width, _lblCuItem.y - 1, 20, Std.int(_lblCuItem.height) + 2, "+", null, function() {c_Index(1); });

        add(_lblCuItem);
        add(_btnMinus);
        add(_btnPlus);

        calcBounds();
    }

	public function getText() { return _lblCuItem; }

    var isMinus:Bool = false;
    private function c_Index(change:Float = 0):Void{
		if (_OnChange != null) {_OnChange(change); }
        if (change > 0) {isMinus = true; _doCallback(CLICK_PLUS); }
        if (change < 0) {isMinus = false; _doCallback(CLICK_MINUS); }
        _doCallback(CHANGE_EVENT);
    }
    public function change(minus:Bool = false):Void { c_Index(minus ? -1 : 1); }

    public function setWidth(Width:Float) {
        Width -= Std.int(_btnMinus.width + _btnPlus.width);
        if (Width < (_btnMinus.width + _btnPlus.width)) {Width = (_btnMinus.width + _btnPlus.width); }
        
        super.setSize(Width, this.height);

        _lblCuItem.width = Width - 40;
        _lblCuItem.fieldWidth = Width - 40;

        _btnPlus.x = _lblCuItem.x + _lblCuItem.width;

        calcBounds();
    }

    private function _doCallback(event_name:String):Void{
        if (broadcastToFlxUI) {
            FlxUI.event(event_name, this, isMinus, params);
        }
    }
}