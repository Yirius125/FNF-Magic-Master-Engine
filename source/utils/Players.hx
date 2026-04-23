package utils;

import flixel.input.gamepad.FlxGamepad;
import objects.utils.Controls;
import flixel.util.FlxSignal;
import objects.utils.Player;
import flixel.FlxCamera;
import flixel.FlxG;

class Players {
    private static var list(default, null):Array<Player> = [];
    public inline static function get(_id:Int):Player { return list[_id]; }

    public static var length(get, never):Int;
    public static function get_length():Int { return list.length; }

    public static function init():Void {
        while (list.length > 0) { list.pop().destroy(); }

        list.push(new Player(0)); //Adding Principal Player One
        get(0).controls.useKeyboard = true; // Forcing Keyboard to Player 1
        
        //Adding Controller Players
        for (i in 0...FlxG.gamepads.numActiveGamepads) {
            if (i == 0 && FlxG.gamepads.getByID(0) != null) { get(0).controls.addGamepad(0); continue; }

            if (FlxG.gamepads.getByID(i) != null) {
                var new_player:Player = new Player(i);
                new_player.controls.addGamepad(i);
                list.push(new_player);
            }
        }
	}
}
