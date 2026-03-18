package objects.menu;

import objects.utils.Controls;
import objects.game.Alphabet;
import flixel.math.FlxMath;
import flixel.FlxG;

using utils.Files;

class MenuNumber extends Alphabet {
    public var setting(default, null):String;

    public var min(default, null):Null<Float>;
    public var max(default, null):Null<Float>;
    public var step(default, null):Float = 1;
    public var value(default, null):Float;
    
    public var isSelected:Bool = false;
    public var controls:Controls;

    private var holdTimer:Float = 0;
    private var cooldown:Float = 0.1;

    public function new(_x:Float, _y:Float, _value:Float, ?_min:Float, ?_max:Float, ?_step:Float, ?_setting:String):Void {
        if (_step != null) {this.step = _step; }
        this.setting = _setting;
        this.value = _value;
        this.min = _min;
        this.max = _max;

        FlxMath.roundDecimal(value, 1);

        super(_x, _y, {font: "small_numbers", text: '${value}'});
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (!isSelected) { return; }

        if (controls.check("MenuLeft", PRESSED)) {
            if (holdTimer == 0 || holdTimer > 1 && holdTimer <= 3 && cooldown >= 0.1 || holdTimer > 3 && cooldown >= 0.01) {toggle_sub(); cooldown = 0; }
            holdTimer += elapsed; cooldown += elapsed;
        } else if (controls.check("MenuRight", PRESSED)) {
            if (holdTimer == 0 || holdTimer > 1 && holdTimer <= 3 && cooldown >= 0.1 || holdTimer > 3 && cooldown >= 0.01) {toggle_add(); cooldown = 0; }
            holdTimer += elapsed; cooldown += elapsed;
        } else{
            holdTimer = 0;
            cooldown = 0;
        }
    }
    
    public function toggle_add():Void {
        this.value += this.step; FlxMath.roundDecimal(this.value, 1);
        if (this.max != null && this.value > this.max) {this.value = this.max; }

        if (setting != null) {Settings.get_setting(setting).set(value); }

        setText({font: "small_numbers", text: '${value}'});
		FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }
    public function toggle_sub():Void {
        this.value -= this.step; FlxMath.roundDecimal(this.value, 1);
        if (this.min != null && this.value < this.min) {this.value = this.min; }
        
        if (setting != null) {Settings.get_setting(setting).set(value); }

        setText({font: "small_numbers", text: '${value}'});
		FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }
}