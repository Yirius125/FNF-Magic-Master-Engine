package objects.ui;

import flixel.addons.ui.FlxUIGroup;
import flixel.util.FlxDestroyUtil;
import flixel.addons.ui.FlxUIText;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxG;

using utils.Files;
using StringTools;

class UITabContainer extends FlxUIGroup {
    public static var dragged:UITabContainer = null;
    public static var focused:UITabContainer = null;

    private var body:UIContainer;
    private var tab:UIContainer;

    private var lblTabTitle:FlxUIText;
    private var hideButton:UIButton;

    private var _offset:FlxPoint = FlxPoint.get(0, 0);
    public var _bounds:FlxPoint = FlxPoint.get(0, 0);

    public var isHidden(default, null):Bool = false;
    
    public var display_width(get, never):Int;
    public function get_display_width():Int { return body.display_width; }

    public function new(_x:Float = 0, _y:Float = 0, _width:Float = 200, _height:Float = 200, _tab_height:Float = 50, _title:String, _size:Int = 12, ?_back_image:String, ?_front_image:String):Void {
        super(_x, _y);

        tab = new UIContainer(0, 0, _width, _tab_height, _back_image, _front_image); add(tab);
        body = new UIContainer(0, _tab_height, _width, _height, _back_image, _front_image); add(body);

        lblTabTitle = new FlxUIText(0, 0, 0, _title, _size); addTab(lblTabTitle);

        hideButton = new UIButton(0, -4, 30, 16, "", 1, null, 0xffe01a1a, ()->{switchTab(); });
        hideButton.x = width - hideButton.width - (body.list_width * 2);
        addTab(hideButton);

        body.active = false;

        _bounds.set(FlxG.width, FlxG.height);
    }

    private function addTab(Object:FlxSprite, Offset:Float = 0, Scroll:Bool = false):FlxSprite { return tab.addPlus(Object, Offset, Scroll); }
    public function addBody(Object:FlxSprite, Offset:Float = 5, Scroll:Bool = true):FlxSprite { return body.addPlus(Object, Offset, Scroll); }

    public function switchTab(?_value:Bool):Void {
        isHidden = _value != null ? _value : !isHidden;
        tab.alpha = isHidden ? 0.5 : 1;
        body.active = !isHidden;
    }

    override public function update(elapsed:Float):Void {
        if (FlxG.mouse.justPressed && isOverlaping() && focused != this && (focused == null || (focused != null && !focused.isOverlaping()))) {
            focused = this;

            if (FlxG.state.members.contains(this)) {
                FlxG.state.remove(this, true);
                FlxG.state.add(this);
            }
        }
        if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(tab) && dragged != this && (focused == null || (focused != null && (focused == this || (focused != this && !focused.isOverlaping()))))) {
            _offset.set(FlxG.mouse.x - x, FlxG.mouse.y - y);
            if (!isHidden) {body.active = true; }
            dragged = this;
        }
        if (dragged == this) {
            setPosition(FlxG.mouse.x - _offset.x, FlxG.mouse.y - _offset.y);
            y = Math.min(Math.max(y, 0), _bounds.y - tab.height);
            x = Math.min(Math.max(x, 0), _bounds.x - width);
            if (!FlxG.mouse.pressed) {dragged = null; }
        }

        body.active = focused == this && !isHidden;
        tab.active = focused == this;

        super.update(elapsed);
    }

    public function isOverlaping():Bool {
        return FlxG.mouse.overlaps(isHidden ? tab : this);
    }

	override public function draw():Void {
        if (!isHidden) {body.draw(); }
        tab.draw();

        #if FLX_DEBUG if (FlxG.debugger.drawDebug) { drawDebug(); } #end
    }

	public function resize(_w:Float, _h:Float):Void {
        if (tab != null) {tab.resize(_w, _h); }
        if (body != null) {body.resize(_w, _h); }
        if (hideButton != null) {hideButton.x = width - hideButton.width - body.list_width - 5; }
    }
    
	override public function destroy():Void {
        body = FlxDestroyUtil.destroy(body);
        tab = FlxDestroyUtil.destroy(tab);
        lblTabTitle = FlxDestroyUtil.destroy(lblTabTitle);
        hideButton = FlxDestroyUtil.destroy(hideButton);
    
        if (focused == this) {focused = null; }
    
        super.destroy();
    }
}