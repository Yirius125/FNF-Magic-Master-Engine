package objects.utils;

import flixel.input.actions.FlxActionInputDigital;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionSet;
import flixel.input.actions.FlxAction;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput;
import flixel.util.FlxSave;
import flixel.FlxG;

using StringTools;

class Control_Input {
    public var buttons:Array<FlxGamepadInputID> = [];
    public var keys:Array<FlxKey> = [];

    public var name(default, null):String;

    public function new(_name:String, ?_keys:Array<FlxKey>, ?_buttons:Array<FlxGamepadInputID>) {
        if (buttons != null) {this.buttons = _buttons; }
        if (keys != null) {this.keys = _keys; }
        this.name = _name;
    }
}
class Action_Plus {
	inline static function isGamepad(input:FlxActionInput, deviceID:Int) {
		return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
	}
	private static function unBindAction(bind:FlxActionDigital, keys:Array<FlxKey>) {
		var i = bind.inputs.length;
		while (i-- > 0) {
			var input = bind.inputs[i];
			if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1) {bind.remove(input); }
		}
	}
	private static function unbindActionButtons(id:Int, bind:FlxActionDigital, buttons:Array<FlxGamepadInputID>) {
		var i = bind.inputs.length;
		while(i-- > 0) {
			var input = bind.inputs[i];
			if (isGamepad(input, id) && buttons.indexOf(cast input.inputID) != -1) {bind.remove(input); }
		}
	}

    public var name(default, null):String;

    public var keys(default, null):Array<FlxKey> = [];
    public var buttons(default, null):Array<FlxGamepadInputID> = [];

    private var release:FlxActionDigital;
    private var press:FlxActionDigital;
    private var hold:FlxActionDigital;

    public function new(_name:String):Void {
        this.release = new FlxActionDigital('${_name}_r');
        this.hold = new FlxActionDigital('${_name}_h');
        this.press = new FlxActionDigital('${_name}');
        this.name = _name;
    }

    public function check(_state:FlxInputState):Bool {
        if (_state == JUST_RELEASED) { return release.check(); }
        if (_state == PRESSED) { return hold.check(); }
        return press.check();
    }

	public function bindKeys(_keys:Array<FlxKey>):Void {
        for (key in _keys) {
			release.addKey(key, JUST_RELEASED);
			press.addKey(key, JUST_PRESSED);
			hold.addKey(key, PRESSED);
            
            keys.push(key);
		}
	}
	public function unbindKeys(_keys:Array<FlxKey>) {
		unBindAction(release, _keys);
		unBindAction(press, _keys);
		unBindAction(hold, _keys);
        
        for (key in _keys) { keys.remove(key); }
	}

	public function bindButtons(id:Int, _buttons:Array<FlxGamepadInputID>) {
		for (button in _buttons) {
			release.addGamepad(button, JUST_RELEASED, id);
			press.addGamepad(button, JUST_PRESSED, id);
			hold.addGamepad(button, PRESSED, id);
            
            buttons.push(button);
		}
	}
	public function unbindButtons(id:Int, _buttons:Array<FlxGamepadInputID>) {
		unbindActionButtons(id, release, _buttons);
		unbindActionButtons(id, press, _buttons);
		unbindActionButtons(id, hold, _buttons);
        
        for (button in _buttons) { buttons.remove(button); }
	}

    public function add(_controls:Controls):Void {
        _controls.add(release);
        _controls.add(press);
        _controls.add(hold);
    }
}

class Controls extends FlxActionSet {
    public static var current_key(default, null):Array<Control_Input> = [];
    public static var current(default, null):Array<Control_Input> = [];
    private static var _key_save:FlxSave;
    private static var _save:FlxSave;

    public static var keys(get, never):Array<String>;
    public static function get_keys():Array<String> {
        var toReturn:Array<String> = [];
        for (_control in current) { toReturn.push(_control.name); }
        return toReturn;
    }

    public static function get_control(_name:String):Control_Input {
        for (control in current) {
            if (control.name != _name) { continue; }
            return control;
        }
        return null;
    }
    public static function get_key_control(_name:String):Control_Input {
        for (control in current_key) {
            if (control.name != _name) { continue; }
            return control;
        }
        return null;
    }

    public static function init():Void {
		Controls._save = new FlxSave();
		Controls._save.bind('controls', 'Yirius125/Magic Master Engine/controls');

		Controls._key_save = new FlxSave();
		Controls._key_save.bind('key_controls', 'Yirius125/Magic Master Engine/controls');

        Controls.reset();
    }
    public static function reset():Void {
        Controls.current_key = [];
        Controls.current = [];

        // Menu Controls
        Controls.current.push(new Control_Input("MenuUp", [FlxKey.W, FlxKey.UP], [FlxGamepadInputID.LEFT_STICK_DIGITAL_UP, FlxGamepadInputID.DPAD_UP]));
        Controls.current.push(new Control_Input("MenuLeft", [FlxKey.A, FlxKey.LEFT], [FlxGamepadInputID.LEFT_STICK_DIGITAL_LEFT, FlxGamepadInputID.DPAD_LEFT]));
        Controls.current.push(new Control_Input("MenuDown", [FlxKey.S, FlxKey.DOWN], [FlxGamepadInputID.LEFT_STICK_DIGITAL_DOWN, FlxGamepadInputID.DPAD_DOWN]));
        Controls.current.push(new Control_Input("MenuRight", [FlxKey.D, FlxKey.RIGHT], [FlxGamepadInputID.LEFT_STICK_DIGITAL_RIGHT, FlxGamepadInputID.DPAD_RIGHT]));
        
        Controls.current.push(new Control_Input("MenuAccept", [FlxKey.ENTER, FlxKey.SPACE], [FlxGamepadInputID.START, FlxGamepadInputID.A]));
        Controls.current.push(new Control_Input("MenuBack", [FlxKey.ESCAPE], [FlxGamepadInputID.B, FlxGamepadInputID.BACK]));
        
        Controls.current.push(new Control_Input("MenuDelete", [FlxKey.BACKSPACE], [FlxGamepadInputID.B]));

        // Game Controls
        Controls.current.push(new Control_Input("Pause", [FlxKey.ENTER, FlxKey.ESCAPE], [FlxGamepadInputID.START, FlxGamepadInputID.BACK]));
        Controls.current.push(new Control_Input("Reset", [FlxKey.R], []));

        // Key Controls
        Controls.current_key.push(new Control_Input("1", [FlxKey.SPACE], []));
        Controls.current_key.push(new Control_Input("2", [FlxKey.D, FlxKey.K], []));
        Controls.current_key.push(new Control_Input("3", [FlxKey.D, FlxKey.SPACE, FlxKey.K], []));
        Controls.current_key.push(new Control_Input("4", [FlxKey.A, FlxKey.S, FlxKey.UP, FlxKey.RIGHT], []));
        Controls.current_key.push(new Control_Input("5", [FlxKey.A, FlxKey.S, FlxKey.SPACE, FlxKey.UP, FlxKey.RIGHT], []));
        Controls.current_key.push(new Control_Input("6", [FlxKey.A, FlxKey.S, FlxKey.D, FlxKey.LEFT, FlxKey.UP, FlxKey.RIGHT], []));
        Controls.current_key.push(new Control_Input("7", [FlxKey.A, FlxKey.S, FlxKey.D, FlxKey.SPACE, FlxKey.LEFT, FlxKey.UP, FlxKey.RIGHT], []));
        Controls.current_key.push(new Control_Input("8", [FlxKey.A, FlxKey.S, FlxKey.D, FlxKey.F, FlxKey.H, FlxKey.J, FlxKey.K, FlxKey.L], []));
        Controls.current_key.push(new Control_Input("9", [FlxKey.A, FlxKey.S, FlxKey.D, FlxKey.F, FlxKey.SPACE, FlxKey.H, FlxKey.J, FlxKey.K, FlxKey.L], []));
        Controls.current_key.push(new Control_Input("10", [FlxKey.A, FlxKey.S, FlxKey.D, FlxKey.F, FlxKey.V, FlxKey.B, FlxKey.H, FlxKey.J, FlxKey.K, FlxKey.L], []));

        Mods.call("onControlsLoad");
    }
    
    public static function load():Void {
        if (Controls._save.data.controls == null) { trace("No Controls Saved"); return; }
        
        // Loading Normal Controls
        for (control in cast(_save.data.controls, Array<Dynamic>)) {
            var cur_control:Control_Input = get_control(control.name);
            if (cur_control == null) { continue; }

            cur_control.buttons = control.buttons;
            cur_control.keys = control.keys;
        }

        // Loading Key Controls
        for (control in cast(_key_save.data.controls, Array<Dynamic>)) {
            var cur_control:Control_Input = get_key_control(control.name);
            if (cur_control == null) { continue; }

            cur_control.buttons = control.buttons;
            cur_control.keys = control.keys;
        }
        
		trace("Controls Loaded Successfully!");     
    }
    public static function save():Void {
        var to_save:Array<{name:String, keys:Dynamic, buttons:Dynamic}> = [];
        
        // Saving Normal Controls
        for (control in current) {
            to_save.push({
                name: control.name,
                keys: control.keys,
                buttons: control.buttons
            });
        }

        if (_save.data.controls != null) {
            for (control in cast(_save.data.controls, Array<Dynamic>)) {
                if (get_control(control.name) != null) { continue; }
                to_save.push(control);
            }
        }

        _save.data.controls = to_save.copy();
        _save.flush();

        // Saving Key Controls
        var to_save_keys:Array<{name:String, keys:Dynamic, buttons:Dynamic}> = [];

        for (control in current_key) {
            to_save_keys.push({
                name: control.name,
                keys: control.keys,
                buttons: control.buttons
            });
        }

        if (_key_save.data.controls != null) {
            for (control in cast(_key_save.data.controls, Array<Dynamic>)) {
                if (get_key_control(control.name) != null) { continue; }
                to_save_keys.push(control);
            }
        }

        _key_save.data.controls = to_save_keys;
        _key_save.flush();
        
		trace("Controls Saved Successfully!");
    }

    public var key_actions(default, null):Map<Int, Array<Action_Plus>> = [];
    public var actions(default, null):Map<String, Action_Plus> = [];
    public var gamepads(default, null):Array<Int> = [];

    public var temp_keys:Map<Int, Array<FlxKey>> = [];
    public var temp_buttons:Map<Int, Array<FlxGamepadInputID>> = [];
    
    public var hasGamepad(get, never):Bool;
    public function get_hasGamepad():Bool { return gamepads.length > 0; }

    public var useKeyboard:Bool = false;

    public function new(_name:String):Void {
        super(_name);

        for (control in current) {
            var new_action:Action_Plus = new Action_Plus(control.name);
            actions.set(control.name, new_action);
            new_action.add(this);

            new_action.bindKeys(control.keys);
        }

        for (i in 0...current_key.length) {
            var key_array:Array<FlxKey> = [];
            var action_array:Array<Action_Plus> = [];

            var control = current_key[i];
            for (ii in 0...(i + 1)) {
                var new_action:Action_Plus = new Action_Plus('${i}keys_${ii}');
                action_array.push(new_action);
                new_action.add(this);

                key_array.push(control.keys[ii]);
                new_action.bindKeys([control.keys[ii]]);
            }

            key_actions.set((i + 1), action_array);
            temp_keys.set((i + 1), key_array);
        }
    }
    
	override function update() {
		super.update();
	}

    public function addGamepad(_id:Int):Void {
        gamepads.push(_id);

        for (control in current) { actions.get(control.name).bindButtons(_id, control.buttons); }
    }

    public function check(_control:String, _state:FlxInputState = JUST_PRESSED):Bool {
        if (!actions.exists(_control)) { return false; }

        return actions.get(_control).check(_state);
    }

    public function check_keys(_keys:Int, _state:FlxInputState):Array<Bool> {
        var toReturn:Array<Bool> = [];
        
        if (!key_actions.exists(_keys)) { for (i in 0..._keys) { toReturn.push(false); } return toReturn; }
        for (action in key_actions.get(_keys)) { toReturn.push(action.check(_state)); }
        
        return toReturn;
    }

    public function data_by_key(_keys:Int, _key:FlxKey):Int {
        if (!temp_keys.exists(_keys)) { return -1; }

        return temp_keys.get(_keys).indexOf(_key);
    }
}