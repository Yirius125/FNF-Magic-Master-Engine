package objects.menu;

import objects.utils.Controls;
import flixel.FlxSprite;
import flixel.FlxG;

using utils.Files;

class MenuBool extends FlxSprite {
    public var value(default, null):Bool = false;
    public var setting(default, null):String;
    
    public var isSelected:Bool = false;
    public var controls:Controls;

    public function new(_x:Float, _y:Float, _value:Bool, ?_setting:String):Void {
        setting = _setting;
        value = _value;
        super(_x, _y);

        frames = Paths.image("checkbox").getAtlas();
        animation.addByPrefix("play", "Check Box selecting animation", 30, false);
        animation.play("play", true, !value);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (!isSelected) { return; }

        if (controls.check("MenuAccept", JUST_PRESSED)) {toggle(); }
    }

    public function toggle(?_value:Bool):Void {
        value = _value != null ? _value : !value;
        animation.play("play", true, !value);

        if (setting != null) {Settings.get_setting(setting).toggle(value); }

		FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }
}