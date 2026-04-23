
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Dialogue;
import states.PlayState;
import flixel.FlxSprite;
import utils.Songs;
import utils.Files;
import utils.Paths;
import flixel.FlxG;

var whiteScreen:FlxSprite;
var dialogue:Dialogue;

function preload():Void {
    if (!Songs.isStoryMode || PlayState.count > 1) { return; }

    whiteScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
    whiteScreen.cameras = [camBHUD];
    whiteScreen.screenCenter();
    whiteScreen.alpha = 0;

    add(whiteScreen);
}

function startSong(next:Void->Void):Void {
    if (!Songs.isStoryMode || PlayState.count > 1) { return false; }

    FlxG.sound.playMusic(Files.getSound(Paths.music("Lunchbox", "stages/school")));
    FlxG.sound.music.fadeIn();
    
    FlxTween.tween(whiteScreen, {alpha: 0.5}, 3, {ease: FlxEase.linear});
    FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.linear, onComplete: function(twn) {
        dialogue = new Dialogue(Files.getJson(Paths.dialogue(PlayState.SONG.song)), {onComplete: function() { onEndDialogue(stnextartCountdown); }});
        dialogue.cameras = [camBHUD];
        add(dialogue);
    }});

    return true;
}

function onEndDialogue(next:Void->Void):Void {
    FlxG.sound.music.fadeOut();
    FlxTween.tween(whiteScreen, {alpha: 0}, 1, {ease: FlxEase.linear});
    FlxTween.tween(camHUD, {alpha: 1}, 1, {ease: FlxEase.linear, onComplete: function(twn) { next(); }});
}