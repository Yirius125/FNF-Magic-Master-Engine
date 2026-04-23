package states;

import objects.ui.UIButton;
import objects.game.Alphabet;
import flixel.FlxSprite;
import utils.Language;
import flixel.FlxG;
import utils.Magic;
import haxe.Json;

#if (desktop && sys)
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class PopModState extends MusicBeatState {
    private var toNext:String;

    override public function create():Void{
        if (onConfirm != null) {toNext = onConfirm; onConfirm = null; } else {toNext = "states.TitleState"; }

        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
        bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height)); bg.screenCenter();
        bg.color = 0xff7dffd8;
        add(bg);
        
        var lblAdvice_1:Alphabet = new Alphabet(0,0,Language.get('mod_advert')); add(lblAdvice_1);
        lblAdvice_1.screenCenter(); lblAdvice_1.y -= 120;
        
        var btnNo = new UIButton(0, 0, 80, 80, "", Paths.image("tach"), null, function() {
            Mods.reload();
            Magic.reload();
            MusicBeatState.loadState(toNext, [], []);
        });
        btnNo.antialiasing = true;
        btnNo.screenCenter(); btnNo.y += 25; btnNo.x -= btnNo.width; add(btnNo);

        var btnYes = new UIButton(0, 0, 100, 100, "", Paths.image("like"), null, function() {MusicBeatState.switchState("states.ModListState", [TitleState, null]); });
        btnYes.antialiasing = true;
        btnYes.screenCenter(); btnYes.y += 25; btnYes.x += btnYes.width; add(btnYes);

        super.create();
        
        FlxG.mouse.visible = true;
    }
}