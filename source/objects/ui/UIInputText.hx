package objects.ui;

import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIGroup;
import flixel.system.FlxAssets;

using utils.Files;
using StringTools;

class UIInputText extends FlxUIInputText {
	public var _change_callback:String->Void;
	public var _enter_callback:String->Void;
    
    public function new(X:Float = 0, Y:Float = 0, Width:Int = 100, ?Text:String, Size:Int = 8, ?ChangeCallback:String->Void, ?EnterCallback:String->Void):Void {
        super(X, Y, Width, Text, Size);
        _change_callback = ChangeCallback;
        _enter_callback = EnterCallback;
    }

	private override function onChange(action:String):Void {
		super.onChange(action);

        switch (action) {
            case FlxInputText.DELETE_ACTION, FlxInputText.BACKSPACE_ACTION, FlxInputText.INPUT_ACTION: {if (_change_callback == null) { return; } _change_callback(text); }
            case FlxInputText.ENTER_ACTION: {if (_enter_callback == null) { return; } _enter_callback(text); }
        }
	}
}