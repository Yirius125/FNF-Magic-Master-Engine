package objects.menu;

import objects.utils.Controls;
import objects.game.Alphabet;
import flixel.FlxG;

using utils.Files;

class MenuList extends Alphabet {
    public var list(default, null):Array<String> = [];
    public var curOption(default, null):Int = 0;
    public var setting(default, null):String;
    
    public var isSelected:Bool = false;
    public var controls:Controls;

    public function new(_x:Float, _y:Float, _list:Array<String>, _index:Int = 0, ?_setting:String):Void {
        setting = _setting;
        curOption = _index;
        list = _list;
        super(_x, _y, {font: "easy_font", scale: 0.7, text: list[curOption].toLowerCase()});
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (!isSelected) { return; }

        if (controls.check("MenuLeft", JUST_PRESSED)) {change(-1); }
        else if (controls.check("MenuRight", JUST_PRESSED)) {change(1); }
    }

    public function change(_value:Int, _force:Bool = false):Void {
        curOption = _force ? _value : curOption + _value;

		if (curOption < 0) {curOption = list.length - 1; }
		if (curOption >= list.length) {curOption = 0; }
        
        if (setting != null) {Settings.get_setting(setting).set(curOption); }
        
        setText({font: "easy_font", scale: 0.7, text: list[curOption].toLowerCase()});
		if (!_force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound()); }
    }
}