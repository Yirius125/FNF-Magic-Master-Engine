package objects.menu;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.effects.FlxFlicker;
import objects.game.Alphabet;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;

using utils.Files;
using StringTools;

class MenuButton extends Alphabet {
    public var clickCall:Void->Void = ()->{};
    
    public var skipTransition:Bool = false;
    public var callAfterTransition:Bool = true;

    public var enabled(default, null):Bool = false;

    public var disableColors:Bool = false;
    public var animatedButton:Bool = false;

    public var enableColor:FlxColor = FlxColor.WHITE;
    public var disableColor:FlxColor = FlxColor.BLACK;

    private var clickTimer:FlxTimer;

    public function new(x:Float = 0, y:Float = 0, display:String = "Button", scale:Float = 1, ?onClick:Void->Void, ?options:Dynamic):Void {
        if (options == null) {options = {}; }
        if (options.disableColor != null) {this.disableColor = options.disableColor; }
        if (options.enableColor != null) {this.enableColor = options.enableColor; }
        if (onClick != null) {this.clickCall = onClick; }
        super(x, y, []);

        this.cur_data = [{animated: true, bold: true, text: display, scale: scale}];
        this.backColor = FlxColor.WHITE;
        this.useBack = true;
        this.loadText();
        this.disable();
    }

    public function enable():Void { 
        enabled = true;
        if (!disableColors) { back.color = enableColor; }
        if (animatedButton && back.animation.curAnim.name != "enable") { back.animation.play("enable"); } 
    }
    public function disable():Void {
        enabled = false;
        if (!disableColors) { back.color = disableColor; }
        if (animatedButton && back.animation.curAnim.name != "disable") { back.animation.play("disable"); } 
    }

    public function click():Void {
        if (animatedButton && back.animation.curAnim.name != "click") { back.animation.play("click"); } 
        if (!skipTransition) {action(); }

        if (clickCall == null) { return; }
        if (!callAfterTransition || skipTransition) {clickCall(); return; }
        if (clickTimer != null) {clickTimer.reset(1); return; }
        clickTimer = new FlxTimer().start(1, function(tmr:FlxTimer) {clickCall(); });
    }

    public function action():Void {
        FlxG.sound.play(Paths.sound("confirmMenu").getSound(), 0.5);
        FlxFlicker.stopFlickering(back);
        FlxFlicker.flicker(back);
    }
}