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

class UIList extends FlxUIGroup implements IFlxUIWidget implements IFlxUIClickable implements IHasParams {
    private var _OnChange:Void->Void = null;
	
	private var _btnBack:FlxUIButton;
    private var _lblCuItem:FlxUIText;
    private var _btnFront:FlxUIButton;

    private var list:Array<String>;
    private var prefix:String = "";
    private var suffix:String = "";

    private var index:Int = 0;

    public var list_length(get, never):Int;
    public function get_list_length():Int{ return list.length; }

    public static inline var CLICK_BACK:String = "click_back_list";
    public static inline var CLICK_FRONT:String = "click_front_list";
    public static inline var CHANGE_EVENT:String = "change_list";

    public var params(default, set):Array<Dynamic>;
	private function set_params(p:Array<Dynamic>):Array<Dynamic>{ return params = p; }

    public var skipButtonUpdate(default, set):Bool;
    private function set_skipButtonUpdate(b:Bool):Bool{
        skipButtonUpdate = b;
        return b;
    }

    public function new(X:Float = 0, Y:Float = 0, Width:Int = 100, Size:Int = 12, ?DataList:Array<String>, ?DefaultValue:Dynamic, ?OnChange:Void->Void) {
        this._OnChange = OnChange;
        super(X, Y);

        this.antialiasing = false;

        list = [];
        if (DataList != null) {list = DataList; }

        _btnBack = new UIButton(0, 0, 40, null, "<", Size, null, null, function() {c_Index(-1); });
        _lblCuItem = new FlxUIText(_btnBack.x + _btnBack.width, _btnBack.y + 3, Width - 80, "", Size);
        _lblCuItem.color = FlxColor.WHITE; _lblCuItem.alignment = CENTER;
        _btnFront = new UIButton(0, _lblCuItem.y - 3, 40, null, ">", Size, null, null, function() {c_Index(1); });
        
        _btnBack.resize(Std.int(_lblCuItem.height), Std.int(_lblCuItem.height));
        _btnFront.resize(Std.int(_lblCuItem.height), Std.int(_lblCuItem.height));
        _lblCuItem.fieldWidth = Width - _btnBack.width - _btnFront.width;
        _btnFront.label.fieldWidth = _btnFront.width;
        _btnBack.label.fieldWidth = _btnBack.width;

        _lblCuItem.x = _btnBack.x + _btnBack.width;
        _btnFront.x = _lblCuItem.x + _lblCuItem.width;

        add(_btnBack);
        add(_lblCuItem);
        add(_btnFront);

        calcBounds();

        if ((DefaultValue is Int)) { index = DefaultValue; }
        if ((DefaultValue is String)) { for (i in 0...list.length) { if (list[i] == DefaultValue) { index = i; } } }

        updateText();
    }

	public function getText() { return _lblCuItem; }
    public function contains(x:String):Bool{ return list.contains(x); }

    private function c_Index(change:Int = 0, force:Bool = false, func:Bool = true):Void {
        index += change;
        if (force) {index = change; }
        
        if (index >= list.length) {index = 0; }
        if (index < 0) {index = list.length - 1; }

        if (index < 0 || index >= list.length) { updateText(); return; }

		if (_OnChange != null && func) { _OnChange(); }

        updateText();

        if (!force) {
            if (change > 0) {_doCallback(CLICK_BACK); }
            if (change < 0) {_doCallback(CLICK_FRONT); }
        }
        _doCallback(CHANGE_EVENT);
    }
    public function change(minus:Bool = false):Void { c_Index(minus ? -1 : 1); }
    
    public function updateIndex():Void {c_Index(); }
    public function setIndex(i:Int = 0, shadow:Bool = false) {c_Index(i, true, !shadow); }
    public function setLabel(s:String, shadow:Bool = false, exists:Bool = false) {
        for (i in 0...list.length) {if (list[i] == s) {c_Index(i, true, !shadow); return; }}
        c_Index(0, true, !shadow);
    }
    
    public function updateText():Void {
        _lblCuItem.text = prefix + "NONE" + suffix;
        if (list[index] != null) {_lblCuItem.text = prefix + list[index] + suffix; }
    }

    public function setData(DataList:Array<String>):Void{list = DataList; if (index >= list.length) {setIndex(list.length - 1, true); } updateText(); }
	public function addToData(data:String):Void{list.push(data); }

    public function setWidth(Width:Float) {
        Width -= Std.int(_btnBack.width + _btnFront.width);
        if (Width < (_btnBack.width + _btnFront.width)) {Width = (_btnBack.width + _btnFront.width); }
        
        super.setSize(Width, this.height);

        _lblCuItem.width = Width - 40;
        _lblCuItem.fieldWidth = Width - 40;

        _btnFront.x = _lblCuItem.x + _lblCuItem.width;

        calcBounds();
    }

    public function getSelectedLabel():String{ return list[index]; }
	public function getSelectedIndex():Int{ return index; }

    public function setPrefix(p:String) {prefix = p; updateText(); }
    public function setSuffix(s:String) {suffix = s; updateText(); }

    private function _doCallback(event_name:String):Void{
        if (broadcastToFlxUI) {
            FlxUI.event(event_name, this, getSelectedIndex(), params);
        }
    }
}