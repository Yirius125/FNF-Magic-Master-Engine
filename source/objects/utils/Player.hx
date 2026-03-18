package objects.utils;

import objects.utils.Controls;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxSignal;
import flixel.input.gamepad.FlxGamepad;

class Player {
    public var id(default, null):Int;
    public var controls(default, null):Controls;

	public function new(_id:Int) {
		this.controls = new Controls('player_$id');
		this.id = _id;
	}

    public function destroy():Void {
        controls.destroy();
    }
}
