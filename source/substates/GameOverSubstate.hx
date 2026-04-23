package substates;

import flixel.group.FlxGroup.FlxTypedGroup;
import objects.game.Character;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import states.MusicBeatState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import states.PlayState;
import states.VoidState;
import flixel.FlxCamera;
import flixel.FlxG;

using utils.Files;

class GameOverSubstate extends MusicBeatSubstate {
    public var characters_created:Bool = false;

    public var death_characters:FlxTypedGroup<Character>;
    public var camFollow:FlxObject;

    public var curPlaystate:PlayState;

    public var otherCamera:FlxCamera;
    public var hudCamera:FlxCamera;
    
    public var curCharacters:Array<Character>;
    public var curStyleUI:String;
    
	public function new(characters:Array<Character>, style_ui:String):Void {
        curCharacters = characters;
		curStyleUI = style_ui;
        super();
	}

    override public function create():Void {
        if ((MusicBeatState.state is PlayState)) { curPlaystate = cast MusicBeatState.state; }

        super.create();

        otherCamera = new FlxCamera();
		otherCamera.bgColor.alpha = 0;
        otherCamera.zoom = FlxG.camera.zoom;
        otherCamera.scroll = FlxG.camera.scroll.clone();
        
        hudCamera = new FlxCamera();
		hudCamera.bgColor.alpha = 0;

		FlxG.cameras.add(otherCamera);
		FlxG.cameras.add(hudCamera);

        death_characters = new FlxTypedGroup<Character>();
        death_characters.camera = otherCamera;
        add(death_characters);

        var firstCharacter:Character = null;
		for (i in 0...curCharacters.length) {
            var new_character = new Character(curCharacters[i].x, curCharacters[i].y, curCharacters[i].curCharacter, curCharacters[i].curAspect, "Death");
            new_character.turnLook(curCharacters[i].onRight);
            new_character.playAnim('firstDeath', true);
            death_characters.add(new_character);
            new_character.noDance = true;

            if (firstCharacter == null) { firstCharacter = new_character; }
		}
        characters_created = true;

		FlxG.sound.play(Paths.styleSound(firstCharacter != null ? firstCharacter.soundDeath : 'fnf_loss_sfx', curStyleUI).getSound());
        curCamera.fade(FlxColor.BLACK, 2);

		conductor.changeBPM(100);

        var l_firstCharacter:Character = death_characters.members[0];
		camFollow = new FlxObject(
            l_firstCharacter.x + l_firstCharacter.cameraPosition.x, 
            l_firstCharacter.y + l_firstCharacter.cameraPosition.y, 
            1, 1
        ); 
        add(camFollow);

        otherCamera.follow(camFollow, LOCKON, 0.01);
		FlxG.camera.follow(camFollow, LOCKON, 0.01);

		scripts.call('created');
    }

	override function update(elapsed:Float):Void {
		super.update(elapsed);

        if (characters_created && !canControlle) {
            if (death_characters.members.length > 0) {
                if (
                    death_characters.members[0].characterSprite.animation.curAnim != null && 
                    death_characters.members[0].characterSprite.animation.curAnim.finished
                ) {
                    FlxG.sound.playMusic(Paths.styleMusic('gameOver', curStyleUI).getSound());
                    for (char in death_characters) { char.playAnim('deathLoop', true); }
                    if (curPlaystate != null) { curPlaystate.stage.destroy(); }
                    MusicBeatState.state.persistentUpdate = false;
                    MusicBeatState.state.persistentDraw = false;
                    characters_created = false;
                    canControlle = true;
                }
            } else {
                FlxG.sound.playMusic(Paths.styleMusic('gameOver', curStyleUI).getSound());
                if (curPlaystate != null) { curPlaystate.stage.destroy(); }
                MusicBeatState.state.persistentUpdate = false;
                MusicBeatState.state.persistentDraw = false;
                characters_created = false;
                canControlle = true;
            }
        }

        if (canControlle) {
            if (controls.check("MenuAccept", JUST_PRESSED)) { retrySong(); }
            if (controls.check("MenuBack", JUST_PRESSED)) { exitSong(); }
        }

		if (FlxG.sound.music.playing) { conductor.position = FlxG.sound.music.time; }
	}
    
	override function beatHit() {
		super.beatHit();

        if (canControlle) {
            for (char in death_characters) { char.playAnim('deathLoop', true); }
        }
	}

    function exitSong():Void {
        canControlle = false;
        FlxG.sound.music.stop();

        if (Songs.isStoryMode) { states.MusicBeatState.switchState("states.MainMenuState", []); }
        else { MusicBeatState.switchState("states.FreeplayState", [null, "states.MainMenuState"]); }
    }

    function retrySong():Void {
        canControlle = false;

        FlxG.sound.music.stop();
        FlxG.sound.play(Paths.styleMusic('gameOverEnd', curStyleUI).getSound());

        for (char in death_characters) { char.playAnim('deathConfirm', true); }

        new FlxTimer().start(0.7, (tmr:FlxTimer) -> { 
            hudCamera.fade(FlxColor.BLACK, 2, false, () -> {
                VoidState.clearAssets = false;
                Songs.play(Songs.isStoryMode);
            });
        });
    }
}