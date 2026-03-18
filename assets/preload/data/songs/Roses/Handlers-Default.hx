import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Dialogue;
import flixel.util.FlxTimer;
import states.PlayState;
import flixel.FlxSprite;
import flixel.FlxObject;
import utils.Songs;
import utils.Files;
import utils.Paths;
import flixel.FlxG;
import haxe.Timer;

var whiteScreen:FlxSprite;
var redScreen:FlxSprite;
var dialogue:Dialogue;

var senpaidies:FlxSprite;

function preload():Void {
    if (!Songs.isStoryMode || PlayState.count > 1) { return; }
    
    whiteScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
    whiteScreen.cameras = [camBHUD];
    whiteScreen.screenCenter();
    whiteScreen.alpha = 0;

    redScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFE0000);
    redScreen.cameras = [camBHUD];
    redScreen.screenCenter();
    redScreen.alpha = 0;

    senpaidies = new FlxSprite(0,-120);
    senpaidies.cameras = [camBHUD];
    senpaidies.frames = Files.getAtlas(Paths.image("senpaiCrazy", "stages/schoolEvil"));
    senpaidies.animation.addByPrefix("die", "Senpai Pre Explosion instance 1", 24, false);
    senpaidies.scale.set(6,6); senpaidies.updateHitbox();
    senpaidies.antialiasing = false;
    senpaidies.alpha = 0;

    add(whiteScreen);
    add(redScreen);
    add(senpaidies);
}

function startSong(next:Void->Void):Void {
    if (!Songs.isStoryMode || PlayState.count > 1) { return false; }

    FlxG.sound.play(Files.getSound(Paths.sound("ANGRY_TEXT_BOX", "stages/schoolEvil")));
    
    FlxTween.tween(whiteScreen, {alpha: 0.5}, 3, {ease: FlxEase.linear});
    FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function(twn:FlxTween) {
        dialogue = new Dialogue(Files.getJson(Paths.dialogue(PlayState.SONG.song)), {onComplete: () -> { onEndDialogue(next); }});
        dialogue.cameras = [camBHUD];
        add(dialogue);
    }});

    return true;
}

function endSong(next:Void->Void):Void {
    if (!Songs.isStoryMode || PlayState.count > 1) { return false; }

    camFHUD.fade(0xFFFF0000, 1, true);
    FlxG.sound.play(Files.getSound(Paths.sound("ANGRY", "stages/schoolEvil")));

    FlxTween.tween(camHUD, {alpha: 0}, 2, {ease: FlxEase.linear});
    var evil_timer:FlxTimer = new FlxTimer().start(2, function(tmr:FlxTimer) {
        camFHUD.fade(0xFFFF0000, 1, true);
        FlxG.sound.play(Files.getSound(Paths.sound("ANGRY", "stages/schoolEvil")));
        FlxG.sound.playMusic(Files.getSound(Paths.music("LunchboxScary", "stages/schoolEvil")));

        FlxG.sound.music.fadeIn(2, 0, 1, (twn:FlxTween) -> {
            FlxG.sound.play(Files.getSound(Paths.sound("ANGRY", "stages/schoolEvil")));
            FlxG.sound.play(Files.getSound(Paths.sound("Senpai_Dies", "stages/schoolEvil")), 1, false, null, true, next);

            camFHUD.fade(0xFFFF0000, 0.8, true);
            redScreen.alpha = 1;
            senpaidies.animation.play("die");
            FlxTween.tween(senpaidies, {alpha: 1}, 1, {ease: FlxEase.linear});
            var fade_timer = new FlxTimer().start(3.2, () -> {camFHUD.fade(0xFFFFFFFF, 1.6); });
        });
    });
    
    return true;
}

function onEndDialogue(next:Void->Void):Void {
    FlxTween.tween(whiteScreen, {alpha: 0}, 1, {ease: FlxEase.linear});
    FlxTween.tween(camHUD, {alpha: 1}, 1, {ease: FlxEase.linear, onComplete: function(twn:FlxTween) { next(); }});
}