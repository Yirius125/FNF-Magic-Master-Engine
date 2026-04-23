package states;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
import objects.settings.List_Setting;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxGradient;
import flixel.system.FlxAssets;
import flixel.tweens.FlxTween;
import objects.game.Alphabet;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flash.geom.Rectangle;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import utils.Language;
import utils.Magic;
import flixel.FlxG;
import haxe.Json;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class PopLangState extends MusicBeatState {
    public static var curLang:Int = 0;

    public var langGroup:FlxTypedGroup<Alphabet>;

    private var toNext:String;

    override public function create():Void{
        if (onConfirm != null) {toNext = onConfirm; onConfirm = null; }
        
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
        bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height)); bg.screenCenter();
        bg.color = 0xff1dca82;

        var grid:FlxSprite = FlxGridOverlay.create(50, 50, 100, 100, true, 0x8c4d4d4d, 0x96333333);
        var dropgrid:FlxBackdrop = new FlxBackdrop(grid.pixels, XY);
        dropgrid.velocity.set(50, 50); 

        var backRect1:FlxSprite = FlxSpriteUtil.drawRoundRect(new FlxSprite(10, 10).makeGraphic(FlxG.width - 20, 100, FlxColor.TRANSPARENT), 0, 0, FlxG.width - 20, 100, 15, 15, FlxColor.BLACK);
		backRect1.alpha = 0.6;

        langGroup = new FlxTypedGroup<Alphabet>();
        for (lang in Language.list) {
            var new_lang:Alphabet = new Alphabet(0,-1000, {scale:0.7, animated: true, bold: true, text: lang});
            new_lang.screenCenter(X);
            langGroup.add(new_lang);
        }

        var lblAdvice:Alphabet = new Alphabet(0, 25, {animated: true, bold: true, text: 'Choose Your Language'});
        lblAdvice.screenCenter(X);

        add(bg);
        add(dropgrid);
        add(langGroup);
        add(backRect1);
        add(lblAdvice);

        changeLang();

        trace(controls.actions);

        super.create();
    }

    override function update(elapsed:Float) {        
        super.update(elapsed);
        
        Magic.sortMembersByY(cast langGroup, (FlxG.height / 2), curLang, 25);

		if (controls.check("MenuUp", JUST_PRESSED)) {changeLang(-1); }
		if (controls.check("MenuDown", JUST_PRESSED)) {changeLang(1); }

		if (controls.check("MenuAccept", JUST_PRESSED)) {chooseLang(); }
	}
    
	public function changeLang(change:Int = 0, force:Bool = false):Void {
		curLang += change; if (force) {curLang = change; }

		if (curLang < 0) {curLang = langGroup.length - 1; }
		if (curLang >= langGroup.length) {curLang = 0; }
	}

    public function chooseLang():Void {
        FlxG.save.data.inLang = true;

        var langSetting:List_Setting = cast Settings.get_setting("Language");
        langSetting.set(curLang);

        MusicBeatState.loadState(toNext, [], []);
    }
}