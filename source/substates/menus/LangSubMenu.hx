package substates.menus;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Alphabet;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Timer;

using utils.Files;
using StringTools;

class LangSubMenu extends SubMenu {
    public var optionGroup:FlxTypedGroup<Alphabet>;
    public var curOption:Int = 0;

    public var menuBack:FlxSprite;
    public var optionBack:FlxSprite;

    public function new(onClose:Void->Void = null):Void {
        super(onClose, 400, 500);
    }

    override function create():Void {
        super.create();

        var lblTitle:Alphabet = new Alphabet(0, backSprite.y + 40, {bold: true, animated: true, scale: 0.5, text: "Language"});
        lblTitle.screenCenter(X);
        group.add(lblTitle);

        menuBack = Magic.roundRect(backSprite.x + 30, backSprite.y + 100, Std.int(backSprite.width) - 60, 370, 15, 15, 0x70000000);
        group.add(menuBack);

        optionBack = new FlxSprite(menuBack.x).makeGraphic(Std.int(menuBack.width), 35, FlxColor.WHITE);
        optionBack.alpha = 0.7;
        group.add(optionBack);

        optionGroup = new FlxTypedGroup<Alphabet>();
        for (cur_lang in Language.list) {
            var cur_option:Alphabet = new Alphabet(0, menuBack.y, {bold: true, animated: true, scale: 0.4, text: cur_lang});
            cur_option.screenCenter(X);
            optionGroup.add(cur_option);
        }
        group.add(optionGroup);

        changeOption(0, true);

        FlxTween.tween(optionBack, {alpha: 0.3}, 1, {ease: FlxEase.quadInOut, type: FlxTween.PINGPONG});
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (optionGroup.length > 0) {
            Magic.sortMembersByY(cast optionGroup, menuBack.y + (menuBack.height / 2) - (optionGroup.members[curOption].height / 2), curOption);
            optionBack.y = optionGroup.members[curOption].y - 5;
        }

        if (!canControlle) { return; }

        if (controls.check("MenuUp")) {changeOption(-1); }
        if (controls.check("MenuDown")) {changeOption(1); }
        if (controls.check("MenuAccept")) {chooseOption(); }
    }

    public function changeOption(_value:Int = 0, _force:Bool = false):Void {
        curOption = _force ? _value : curOption + _value;

        if (curOption >= optionGroup.length) {curOption = optionGroup.length - 1; canControlle = true; return; }
        if (curOption < 0) {curOption = 0; canControlle = true; return; }

        if (!_force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound(), 0.5); }

        for (i in 0...optionGroup.length) {
            var cur_option = optionGroup.members[i];

            FlxTween.cancelTweensOf(cur_option);
            FlxTween.tween(cur_option, {alpha: 1 - (Math.abs(curOption - i) * 0.3)}, 0.1, {ease: FlxEase.quadOut});
        }
    }

    public function chooseOption():Void {
        canControlle = false;
        FlxG.sound.play(Paths.sound("confirmMenu").getSound(), 0.5);

        cast(Settings.get_setting("Language"), objects.settings.List_Setting).set(curOption);
        Language.load();
        
        FlxG.save.data.first = true;
        
        Settings.save();
        FlxG.save.flush();
        
        FlxFlicker.flicker(optionGroup.members[curOption]);
        Timer.delay(()->{doClose(); }, 1000);
    }
}
