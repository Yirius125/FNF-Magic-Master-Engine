
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import utils.Paths;
import flixel.FlxG;
import haxe.Timer;

var blackScreen:FlxSprite;

function preload():Void {
    blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
    blackScreen.cameras = [camFHUD];
    blackScreen.visible = false;
    blackScreen.screenCenter();
    add(blackScreen);
}

function endSong(next:Void->Void):Void {
    blackScreen.visible = true;
    
    FlxG.sound.play(Paths.sound("Lights_Shut_off","stages/mall"));

    new FlxTimer().start(1, (_tmr:FlxTimer) -> { next(); });   
}