package substates;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIGroup;
import objects.notes.StrumLine;
import objects.game.Character;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Alphabet;
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
import haxe.Timer;

using utils.Files;

class ResultSubstate extends MusicBeatSubstate {
    public var grpCharacters:FlxTypedGroup<Character>;
	public var grpBackShit:FlxTypedGroup<FlxSprite>;
    public var grpRankStuff:FlxUIGroup;

    public var sprRadioFront:FlxSprite;
    public var sprRadioBack:FlxSprite;
    public var sprHighscore:FlxSprite;
    public var alpResults:Alphabet;
    public var sprTopBar:FlxSprite;
    public var sprScore:FlxSprite;
    public var alpScore:Alphabet;

    public var camFollow:FlxObject;
    public var curState:PlayState;

    public var otherCamera:FlxCamera;
    public var hudCamera:FlxCamera;

    public var scoreState:Int = 0;
    public var cooldownScore:Float = 5;
    public var charsGenerated:Bool = false;
    
    public var style:String;
    public var score:Int;
    public var notes:Int;
    public var combo:Int;
    public var misses:Int;
    public var highscore:Int;
    public var status:Map<String, Int>;
    public var characters:Array<Character>;
    
	public function new(_characters:Array<Character>, _style:String, _score:Int = 0, _notes:Int = 0, _combo:Int = 0, _misses:Int = 0, ?_status:Map<String, Int>, _highscore:Int = 0):Void {
		style = _style;
        score = _score;
        notes = _notes;
        combo = _combo;
        misses = _misses;
        status = _status;
        highscore = _highscore;
        characters = _characters;
        super();
	}
    
	override function create() {
		super.create();

        score = Std.int(Math.max(score, 0));

        otherCamera = new FlxCamera();
		otherCamera.bgColor.alpha = 0;
        otherCamera.zoom = FlxG.camera.zoom;
        otherCamera.scroll = FlxG.camera.scroll;
        
        hudCamera = new FlxCamera();
		hudCamera.bgColor.alpha = 0;

		FlxG.cameras.add(otherCamera);
		FlxG.cameras.add(hudCamera);

        if ((MusicBeatState.state is PlayState)) {curState = cast MusicBeatState.state; }
        
		var stickerList:Array<String> = Paths.readDirectory("assets/shared/images/stickers");
		grpBackShit = new FlxTypedGroup<FlxSprite>();
        grpBackShit.cameras = [otherCamera];
        for (i in 0...50) {
            var backSticker:FlxSprite = new FlxSprite().loadGraphic(stickerList[FlxG.random.int(0, stickerList.length - 1)]);
            backSticker.scale.x = backSticker.scale.y = FlxG.random.float(0.05, 0.5); backSticker.updateHitbox();
            backSticker.alpha = FlxG.random.float(0.05, 0.2);
            backSticker.scrollFactor.set(0, 0);
            backSticker.setPosition(
                FlxG.random.float(0, FlxG.width - backSticker.width),
                (i * (-FlxG.height) / 50) + FlxG.random.float(-backSticker.height, backSticker.height)
            );
            
            backSticker._.speed = FlxG.random.float(30, 50);
            backSticker._.speedAngle = FlxG.random.float(-6, 6);

            grpBackShit.add(backSticker);
		}
		add(grpBackShit);
        
        sprTopBar = new FlxSprite().loadGraphic(Paths.styleImage("result_menu/topBarBlack", PlayState.song.style));
        sprTopBar.setGraphicSize(FlxG.width); sprTopBar.updateHitbox();
        sprTopBar.y = -sprTopBar.height -5;
        sprTopBar.cameras = [hudCamera];

        sprRadioBack = new FlxSprite(-20, -184);
        sprRadioBack.frames = Paths.styleImage("result_menu/systemBack", PlayState.song.style).getAtlas();
        sprRadioBack.scale.set(sprTopBar.scale.x, sprTopBar.scale.y); sprRadioBack.updateHitbox();
        sprRadioBack.animation.addByPrefix("play", "sound system", 30, false);
        sprRadioBack.cameras = [hudCamera];
        sprRadioBack.visible = false;
        add(sprRadioBack);

        grpRankStuff = new FlxUIGroup(0, FlxG.height);
        grpRankStuff.cameras = [hudCamera];
        addScoreSprites(notes, combo, misses, status);
        add(grpRankStuff);

        sprRadioFront = new FlxSprite(-20, -5);
        sprRadioFront.frames = Paths.styleImage("result_menu/systemFront", PlayState.song.style).getAtlas();
        sprRadioFront.scale.set(sprTopBar.scale.x, sprTopBar.scale.y); sprRadioFront.updateHitbox();
        sprRadioFront.animation.addByPrefix("play", "systemFront", 30, false);
        sprRadioFront.cameras = [hudCamera];
        sprRadioFront.visible = false;
        add(sprRadioFront);

        alpScore = new Alphabet(120, 620, {font: "score-digital-numbers", text: convertScore(score)});
        for (d in alpScore.members) {d.visible = false; }
        alpScore.cameras = [hudCamera];
        add(alpScore);

        sprScore = new FlxSprite(-150, 520);
        sprScore.frames = Paths.styleImage("result_menu/scorePopin", PlayState.song.style).getAtlas();
        sprScore.scale.set(sprTopBar.scale.x, sprTopBar.scale.y); sprScore.updateHitbox();
        sprScore.animation.addByPrefix("play", "tally score", 30, false);
        sprScore.cameras = [hudCamera];
        sprScore.visible = false;
        add(sprScore);
        
        if (score >= highscore) {
            sprHighscore = new FlxSprite(335, 565);
            sprHighscore.frames = Paths.styleImage("result_menu/highscoreNew", PlayState.song.style).getAtlas();
            sprHighscore.scale.set(sprTopBar.scale.x, sprTopBar.scale.y); sprHighscore.updateHitbox();
            sprHighscore.animation.addByPrefix("play", "NEW HIGHSCORE", 30, true);
            sprHighscore.cameras = [hudCamera];
            sprHighscore.visible = false;
            add(sprHighscore);
        }

        grpCharacters = new FlxTypedGroup<Character>();
        grpCharacters.cameras = [otherCamera];
		for (i in 0...characters.length) {
            var new_character = new Character(characters[i].x, characters[i].y, characters[i].curCharacter, characters[i].curAspect, "Result");
            new_character.turnLook(characters[i].onRight);
            new_character.playAnim('Waiting', true);
            grpCharacters.add(new_character);
            new_character.noDance = true;
		}
        charsGenerated = true;
        add(grpCharacters);

        add(sprTopBar);

        alpResults = new Alphabet(0, 10, [{font: "results_font", scale: 0.8, text: Language.get("results_title")}]);
        alpResults.cameras = [hudCamera];
        alpResults.xMultiplier = 0.7;
        alpResults.loadText();
        alpResults.screenCenter(X);
        alpResults.visible = false;
        alpResults.y = 0 - alpResults.height - 10;
        add(alpResults);

        FlxG.sound.playMusic(Paths.styleMusic('results', style).getSound());
        curCamera.fade(0xffffc85d, 1, false, () -> {
            if (grpCharacters.members.length > 0) {for (char in grpCharacters) {char.playAnim('Perfect', true); }}
            if (curState != null) {curState.stage.destroy(); }
            MusicBeatState.state.persistentUpdate = false;
            MusicBeatState.state.persistentDraw = false;
            charsGenerated = false;
        });

        FlxTween.tween(FlxG.camera, {zoom: 1.4}, 2, {ease: FlxEase.quadOut});
        FlxTween.tween(otherCamera, {zoom: 1.4}, 2, {ease: FlxEase.quadOut});
        
        FlxTween.tween(sprTopBar, {y: 0}, 0.5, {ease: FlxEase.quadOut, startDelay: 2, onComplete: (twn) -> {
            sprRadioFront.animation.play("play");
            sprRadioBack.animation.play("play");
            sprScore.animation.play("play");
            sprRadioFront.visible = true;
            sprRadioBack.visible = true;
            alpResults.visible = true;
            sprScore.visible = true;

            Timer.delay(()->{
                canControlle = true;
            
                FlxTween.tween(grpRankStuff, {y: 0}, 0.1, { ease:FlxEase.quadOut });
                FlxTween.tween(alpResults, {y: 10}, 0.1, { ease:FlxEase.quadOut });

                new FlxTimer().start(0.05, (tmr)->{
                    if (tmr.elapsedLoops > alpScore.length) {
                        if (score >= highscore) {
                            sprHighscore.animation.play("play");
                            sprHighscore.visible = true;
                        }
    
                        return;
                    }
                    var curDig = alpScore.members[tmr.elapsedLoops - 1];
                    curDig.animation.play(curDig.animation.curAnim.name);
                    curDig.visible = true; 
                }, alpScore.length + 1);
            }, 500);
        }});

		camFollow = new FlxObject(characters[0].characterSprite.x + characters[0].characterSprite.width - (FlxG.width / 3), characters[0].characterSprite.y + characters[0].characterSprite.height - (FlxG.height / 2.8), 1, 1);
        add(camFollow);

        otherCamera.follow(camFollow, LOCKON, 0.01);
		FlxG.camera.follow(camFollow, LOCKON, 0.01);
    }

	override function update(elapsed:Float) {
		super.update(elapsed);
        
		for (obj in grpBackShit.members) {
			if (obj.y > FlxG.height + 5) {
				obj.x = FlxG.random.float(0, FlxG.width - obj.width);
				obj.y = -obj.height - 5;
			}
			obj.angle += elapsed * obj._.speedAngle;
			obj.y += elapsed * obj._.speed;
		}
        
        switch (scoreState) {
            case 0, 2:{
                cooldownScore -= elapsed;
                if (cooldownScore <= 0) {scoreState++; }
            }
            case 1:{
                grpRankStuff.y -= elapsed * 30;
                if (grpRankStuff.y + grpRankStuff.height < 390) {scoreState++; cooldownScore = 5; }
            }
            case 3:{
                grpRankStuff.y += elapsed * 30;
                if (grpRankStuff.y > 0) {scoreState = 0; cooldownScore = 5; }
            }
        }

        if (canControlle) {
            if (controls.check("MenuAccept", JUST_PRESSED)) { endResult(); }
        }
	}

    private function addScoreSprites(_notes:Int = 0, _combo:Int = 0, _misses:Int = 0, ?_status:Map<String, Int>):Void {
        var curHeight:Float = sprTopBar.height;

        var totalNotesSprite:FlxSprite = new FlxSprite(45, curHeight).loadGraphic(Paths.styleImage("result_menu/totalnotes", PlayState.song.style));
        totalNotesSprite.scale.set(sprTopBar.scale.x, sprTopBar.scale.y); totalNotesSprite.updateHitbox();

        var totalNotesCount:Alphabet = new Alphabet(45 + totalNotesSprite.width + 20, 0, {font: "small_numbers", text: '${_notes}'});
        totalNotesCount.y = curHeight + (totalNotesSprite.height / 2) - (totalNotesCount.height / 2);

        curHeight += totalNotesSprite.height;
        grpRankStuff.add(totalNotesSprite);
        grpRankStuff.add(totalNotesCount);

        var maxComboSprite:FlxSprite = new FlxSprite(45, curHeight).loadGraphic(Paths.styleImage("result_menu/maxcombo", PlayState.song.style));
        maxComboSprite.scale.set(sprTopBar.scale.x, sprTopBar.scale.y); maxComboSprite.updateHitbox();

        var maxComboCount:Alphabet = new Alphabet(45 + maxComboSprite.width + 20, 0, {font: "small_numbers", text: '${_combo}'});
        maxComboCount.y = curHeight + (maxComboSprite.height / 2) - (maxComboCount.height / 2);
        
        curHeight += maxComboSprite.height;
        grpRankStuff.add(maxComboSprite);
        grpRankStuff.add(maxComboCount);

        for (cur_rank in StrumLine.ranks) {
            var rankSprite:FlxSprite = new FlxSprite(45, curHeight).loadGraphic(Paths.styleImage(cur_rank.popup, PlayState.song.style));
            rankSprite.scale.set(sprTopBar.scale.x * 0.5, sprTopBar.scale.y * 0.5); rankSprite.updateHitbox();

            var rankCount:Alphabet = new Alphabet(45 + rankSprite.width + 20, 0, {font: "small_numbers", text: '${_status[cur_rank.popup]}'});
            rankCount.y = curHeight + (rankSprite.height / 2) - (rankCount.height / 2);
            
            curHeight += rankSprite.height;
            grpRankStuff.add(rankSprite);
            grpRankStuff.add(rankCount);
        }

        var missesSprite:FlxSprite = new FlxSprite(45, curHeight).loadGraphic(Paths.styleImage("result_menu/missed", PlayState.song.style));
        missesSprite.scale.set(sprTopBar.scale.x, sprTopBar.scale.y); missesSprite.updateHitbox();

        var missesCount:Alphabet = new Alphabet(missesSprite.x + missesSprite.width + 20, 0, {font: "small_numbers", text: '${_misses}'});
        missesCount.y = curHeight + (missesSprite.height / 2) - (missesCount.height / 2);
        
        curHeight += missesSprite.height;
        grpRankStuff.add(missesSprite);
        grpRankStuff.add(missesCount);
    }

    public function endResult():Void {
        canControlle = false;

        FlxG.sound.music.fadeOut(2);
        hudCamera.fade(FlxColor.BLACK, 2, false, function() {
            FlxG.sound.music.stop();
            if (Songs.isStoryMode) { states.MusicBeatState.switchState("states.MainMenuState", []); }
            else { MusicBeatState.switchState("states.FreeplayState", [null, "states.MainMenuState"]); }
        });
    }

    public function convertScore(_score:Int):String {
        var toReturn:String = '${_score}';
        while(toReturn.split("").length < 10) { toReturn = '#$toReturn'; }
        return toReturn;
    }
}