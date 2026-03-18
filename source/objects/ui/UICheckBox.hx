package objects.ui;

import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIGroup;
import flixel.system.FlxAssets;
import flixel.addons.ui.FlxUI;

using utils.Files;
using StringTools;

class UICheckBox extends FlxUICheckBox {
	public var _callback:Bool->Void;
    
    public function new(X:Float = 0, Y:Float = 0, LabelW:Int = 100, ?Label:String, Size:Int = 8, DefaultValue:Bool = false, ?Callback:Bool->Void, ?Box:Dynamic, ?Check:Dynamic, ?Params:Array<Dynamic>):Void {
        super(X, Y, Box, Check, Label, LabelW, Params);
        _callback = Callback;
        mark.visible = false;
        textY = 5;

        button.label.setFormat(FlxAssets.FONT_DEFAULT, Size);

        box.frames = Paths.image("checkbox").getAtlas();
        box.animation.addByPrefix("play", "Check Box selecting animation", 30, false);
        box.setGraphicSize(0, Std.int(button.label.height) - 5); box.updateHitbox();
        box.animation.play("play", true, !checked);
        box.y += 5;

        button.resize(LabelW, Std.int(button.label.height));

        anchorLabelX(); 
        anchorLabelY();

        checked = DefaultValue;
        box.antialiasing = true;
        this.antialiasing = true;
    }
    
	override private function set_checked(b:Bool):Bool {
        box.animation.play("play", true, !b);

        return checked = b;
    }

	override public function anchorLabelY():Void {
		if (button == null) { return; }
        
        button.y = box.y + box.height - button.height + textY;
	}
    
	override private function _clickCheck():Void {
        if (!visible) { return; }
        
        checked = !checked;
        if (_callback != null) {_callback(checked); }
        if (broadcastToFlxUI) {FlxUI.event(FlxUICheckBox.CLICK_EVENT, this, checked, params); }
    }
}