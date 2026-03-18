package states;

import flixel.group.FlxGroup.FlxTypedGroup;
import objects.notes.Note.Event_Data;
import objects.songs.Song.Song_File;
import flixel.sound.FlxSoundGroup;
import objects.utils.EventList;
import substates.PauseSubState;
import objects.notes.StrumLine;
import objects.game.Character;
import objects.scripts.Script;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.sound.FlxSound;
import objects.game.Alphabet;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import states.GitarooPause;
import objects.game.HudBar;
import objects.notes.Note;
import objects.game.Stage;
import objects.songs.Song;
import objects.game.Icon;
import lime.utils.Assets;
import flixel.FlxObject;
import flixel.FlxSprite;
import utils.Highscore;
import utils.Players;
import utils.Magic;
import utils.Songs;
import flixel.FlxG;
import haxe.Timer;
import haxe.Json;

#if (hxCodec >= "2.6.1") import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0") import VideoHandler as MP4Handler;
#else import vlc.MP4Handler; #end

#if desktop
import utils.Discord;
#end

using utils.Files;
using StringTools;

class PlayState extends MusicBeatState {
	public var strumLeftPos:Float = 100;
	public var strumMiddlePos:Float = 100;
	public var strumRightPos:Float = 100;

	public var strumOffset:Float = 30;
	public var strumUpOffset:Float = 40;
	public var strumDownOffset:Float = 60;

	private static var prevCamFollow:FlxObject;

	public static var sickEmote:Float = 0.1;
	public var emoteBeat:Int = 0;

	public static var song:Song_File = null;
	public static var count:Int = 0;
	
	public var introAssets:Array<{asset:String, sound:String}> = [
		{asset:null, sound: 'intro3'},
		{asset:'ready', sound: 'intro2'},
		{asset:'set', sound: 'intro1'},
		{asset:'go', sound: 'introGo'}
	];

    public var curSection(get, never):Int;
	inline function get_curSection():Int{ return Std.int(conductor.getCurStep() / 16); }

	// Hud Stuff
	public var healthBar:HudBar;
	
    public var popScore:Alphabet;
    public var rankIcon:FlxSprite;
    public var rankTween:FlxTween;

	//Audio Properties
	public var inst:FlxSound;
	public var voices:FlxSoundGroup;

	//Strumlines
	public var strums:FlxTypedGroup<StrumLine>;
	public var strumPlayer:StrumLine;

	//Song Stats
	public var song_Length:Float = 0;
	public var song_Time:Float = 0;

	public var lastScore:Int = 0;
	public var highscore:Int = 0;

	public var events:EventList = new EventList();
	
	// Gameplay Bools
	public var defaultBumps:Bool = true;
	public var followChar:Bool = true;
	public var defaultZoom:Float = 1;
	public var zoomMult:Float = 1;
	public var iconMult:Float = 1;

	public var zoomMap:Map<String, Float> = new Map<String, Float>();
	
    public var camFollow:FlxObject;
	
	public var stage:Stage;

	//Other Bools
	public var songGenerated:Bool = false;
	public var songStarted:Bool = false;
	public var songPlaying:Bool = false;
	public var onGameOver:Bool = false;
	public var onResults:Bool = false;
	public var isPaused:Bool = false;

	public var doStartCountdown:Bool = true;
	public var lockStageCamera:Bool = true;
	public var showHudOnStart:Bool = true;
	public var hideOnResults:Bool = true;
	public var canPause:Bool = false;
	public var canReset:Bool = true;

	public var lastPlayer:Int = 0;

	// Pause Properties
	public var timers:Array<FlxTimer> = [];
	public var tweens:Array<FlxTween> = [];

	// PreMethods
	public function doSing(cur_strum:StrumLine, note:Note, isMiss:Bool = false):Void { // Do Sing to Characters
		var song_animation:String = note.singAnimation + (isMiss ? "miss" : "");
		var section_strum = cur_strum.data.sections[curSection];

		if (section_strum != null && section_strum.changeAlt) { song_animation += '-alt'; }

		var character_list:Array<Int> = cur_strum.data.characters;
		if (section_strum != null && section_strum.changeCharacters) { character_list = section_strum.characters; }

		for (id in character_list) {
			var new_character:Character = stage.getCharacterById(id);
			if (new_character == null) { continue; }

			new_character.singAnim((note.typeHit == "Hold" && new_character.curAnim.contains("sing")) ? new_character.curAnim : song_animation, note.typeHit != "Hold", false);
		}
	}
	public function doRank(_strum:StrumLine, _note:Note, _combo:Int, _score:Float, _rank:String, _pop_image:String):Void {
		if (rankTween != null) { rankTween.cancel(); } 
		
		rankIcon.revive();
		rankIcon.loadGraphic(Paths.styleImage(_pop_image, song.style).getGraphic());
		rankIcon.scale.set(0.7, 0.7); 
		rankIcon.updateHitbox(); 
		rankIcon.alpha = 1;
		rankIcon.setPosition(_strum.x + (_strum.width / 2) - (rankIcon.width / 2), _strum.y + 300);
		
		popScore.setPosition(rankIcon.x, rankIcon.y + rankIcon.height); 
		popScore.popScore(_combo, song.style);
		
		rankTween = FlxTween.tween(rankIcon, { y: rankIcon.y - 25, alpha: 0 }, 0.5, { ease: FlxEase.quadOut, onComplete: (twn:FlxTween) -> { rankIcon.kill(); } });
	}
	public function doStart():Void { // Start Song
		songPlaying = true;

		if (doStartCountdown) { 
			if (showHudOnStart) { FlxTween.tween(camHUD, { alpha: 1 }, (conductor.crochet / 1000) * (introAssets.length + 1), { ease: FlxEase.quadInOut }); }
			conductor.position = 0 - (conductor.crochet * (introAssets.length + 1));

			startCountdown(startSong); 
		} else { 
			if (showHudOnStart) { camHUD.alpha = 1; }

			startSong(); 
		}
	}
	public function doEnd():Void { // End Song
		scripts.call('songEnded');

		if (Songs.playlist.length > 0) { Songs.play(Songs.isStoryMode); return; }
		
		doResults(lastPlayer);
	};	
	public function startCountdown(onComplete:Void->Void = null):Void {
		var swagCounter:Int = 0;

		timers.push(new FlxTimer().start(conductor.crochet / 1000, (tmr:FlxTimer) -> {
			if (introAssets[swagCounter] != null) {
				if (introAssets[swagCounter].sound != null) { FlxG.sound.play(Paths.styleSound(introAssets[swagCounter].sound, song.style).getSound(), 0.6); }
			
				if (introAssets[swagCounter].asset != null) {
					var iAssets:FlxSprite = new FlxSprite().loadGraphic(Paths.styleImage(introAssets[swagCounter].asset, song.style));
					iAssets.scrollFactor.set(0, 0);
					iAssets.updateHitbox();
					iAssets.screenCenter();
					iAssets.camera = camBHUD;
					add(iAssets);

					FlxTween.tween(iAssets, { alpha: 0 }, conductor.crochet / 1000, { ease: FlxEase.cubeInOut, onComplete: (twn:FlxTween) -> { iAssets.destroy(); } });
				}
			}

			if (swagCounter == introAssets.length) { if (onComplete != null) { onComplete(); } }

			swagCounter++;
		}, introAssets.length + 1));
	}

	override public function create() {
		song = Songs.playlist.length > 0 ? Songs.playlist[0] : Song.load('Tutorial-Normal-Normal');
		super.create();

		strumRightPos = FlxG.width - 100;
		strumMiddlePos = FlxG.width / 2;

		PlayState.count++;
		
		persistentUpdate = true;
		persistentDraw = true;

		stage = new Stage(song.stage, song.characters);
		add(stage);
	
		defaultZoom = stage.zoom;

		conductor.position = -5000;

		strums = new FlxTypedGroup<StrumLine>();
		strums.cameras = [camHUD];
		add(strums);
			
        camFollow = prevCamFollow != null ? prevCamFollow : new FlxObject(0, 0, 1, 1);
		if (prevCamFollow != null) {prevCamFollow = null; }
		camFollow.screenCenter();
		add(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		FlxG.camera.zoom = stage.zoom;
		FlxG.fixedTimestep = false;
		FlxG.mouse.visible = false;

		camHUD.alpha = 0;

		generateHud();		
		generateSong();

		#if desktop
		Discord.change("Playing " + song.song, null);
		Magic.setWindowTitle("Playing " + song.song);
		#end
	}

	private function generateSong():Void {
		conductor.changeBPM(song.bpm);
		conductor.mapBPMChanges(song);

		//Loading Instrumental
		inst = new FlxSound().loadEmbedded(Paths.inst(song.song, song.category).getSound(), false, false, endSong);
		inst.looped = false;
		inst.onComplete = endSong.bind();
		FlxG.sound.list.add(inst);
		
		song_Length = inst.length;

		//Loading Voices
		voices = new FlxSoundGroup();		
		voices.sounds = [];

		if (song.voices) {
            for (i in 0...song.strums.length) {
				if (song.strums[i].characters.length <= 0) { continue; }
				if (song.characters.length <= song.strums[i].characters[0]) { continue; }
				var voice_path:String = Paths.voice(i, song.characters[song.strums[i].characters[0]][0], song.song, song.category);
				if (!Paths.exists(voice_path)) { continue; }
				var voice = new FlxSound().loadEmbedded(voice_path.getSound());
				FlxG.sound.list.add(voice);
				voices.add(voice);
            }
        }
		
		if (voices.sounds.length <= 0) {
			var voice = new FlxSound();
			FlxG.sound.list.add(voice);
			voices.add(voice);
		}

		//Loading Strumlines
		for (i in 0...song.strums.length) {
			var new_strum = new StrumLine(0, 0, song.strums[i].keys, 448, null, song.strums[i].style, null);
			
			new_strum.onHIT = function(note:Note) { doSing(new_strum, note, false); };
			new_strum.onMISS = function(note:Note) { doSing(new_strum, note, true); };

			new_strum.scrollspeed = song.speed;
			new_strum.conductor = conductor;
			new_strum.bpm = song.bpm;
			
			new_strum.alpha = 0;
			new_strum.x = (FlxG.width / 2) - (new_strum.width / 2);
			new_strum.y = Settings.get("DownScroll") ? FlxG.height - new_strum.height - 30 : 30;

			new_strum.load(song.strums[i]);
			new_strum.ID = i;

			strums.add(new_strum);
		}

		if (Songs.players.length <= 0) { Songs.players = [song.player]; }

		for (i in Songs.players) {
			var cur_strum:StrumLine = strums.members[i];
			if (cur_strum == null) { continue; }

			cur_strum.isUsing = true;

			var strumCharacter:Character = stage.getCharacterById(song.strums[i].characters[0]);

			if (Songs.players.length > 1) {
				cur_strum.controlsId = i;
				cur_strum.onGAME_OVER = () -> { };
			} else {
				strumPlayer = cur_strum;

				cur_strum.controlsId = 0;

				healthBar.life = strumPlayer.life;
				healthBar.setPlayer(strumCharacter.icon, strumCharacter.barcolor, cur_strum);

				cur_strum.onGAME_OVER = () -> { doGameOver(i); };
				cur_strum.onRANK = (_note:Note, _score:Float, _rank:String, _pop_image:String) -> { doRank(cur_strum, _note, cur_strum.combo, _score, _rank, _pop_image); };
			}
		}

		for (i in 0...strums.length) {
			var l_curStrum = strums.members[i];

			if (l_curStrum.isUsing) { continue; }
			if (song.strums[i].friendly) { continue; }
			
			var strumCharacter:Character = stage.getCharacterById(song.strums[i].characters[0]);

			healthBar.setOpponent(strumCharacter.icon, strumCharacter.barcolor);
		}
		
		// Loading Events
		events.conductor = conductor;
		events.clear();
		for (event in song.events) {
			var event_data:Event_Data = Note.getEventData(event);

			for (cur_action in event_data.eventData) {
				var action_script:Script = scripts.get(cur_action[0]);
				if (action_script == null) { trace('Null Event: ${cur_action[0]}'); continue; }
				
				action_script.call("preload_event", cast(cur_action[1], Array<Dynamic>));
			}
			
			events.push(event_data.strumTime, ()-> {
				for (cur_action in event_data.eventData) {
					var action_script:Script = scripts.get(cur_action[0]);
					if (action_script == null) { trace('Null Event: ${cur_action[0]}'); continue; }

					action_script.call("execute", cast(cur_action[1], Array<Dynamic>));
				}
			});
		}
		add(events);

		for (i in 0...strums.length) {
			var l_curStrum = strums.members[i];

			for (_note in l_curStrum.notelist) {
				for (cur_action in _note.otherData) {
					var action_script:Script = scripts.get(cur_action[0]);
					if (action_script == null) { trace('Null Event: ${cur_action[0]}'); continue; }
					
                	action_script.setVar("_note", _note);
					action_script.call("preload_event", cast(cur_action[1], Array<Dynamic>));
				}
			}
		}

		scripts.call('preload');
		
		checkScroll();
		updateStrums();

		songGenerated = true;
		scripts.complex("startSong", [], () -> { doStart(); });
	}
	private function generateHud():Void {
		healthBar = new HudBar(0, 0, Paths.styleImage("healthBar_back", song.style), Paths.styleImage("healthBar_front", song.style));
		healthBar.camera = camHUD;
		add(healthBar);

        rankIcon = new FlxSprite();
		rankIcon.camera = camHUD;
        add(rankIcon);
        rankIcon.kill();
        
        popScore = new Alphabet(0, 0, []);
		popScore.camera = camHUD;
        add(popScore);
	}

	override public function update(elapsed:Float) {
		if (Songs.players.length == 1) {
			if (lastScore != strumPlayer.score) { healthBar.setScore(lastScore = strumPlayer.score); }
			if (healthBar.life != strumPlayer.life) { healthBar.life = strumPlayer.life; }
		} else { }

		if (canControlle) {
			if (songPlaying) {
				if (controls.check("Pause") && canPause) {
					pauseAndOpen(
						"substates.PauseSubState", [
							() -> {
								if (!songGenerated) { isPaused = false; pauseSong(false); return; }

								checkScroll();

								startCountdown(() -> {
									persistentUpdate = true;
									persistentDraw = true;
									canControlle = true;
									isPaused = false;
									pauseSong(false);
								});
							}
						],
						true
					);

					return;
				} else if (FlxG.keys.justPressed.SEVEN && !Songs.isStoryMode) {
					persistentUpdate = false;

					inst.destroy();
					for (s in voices.sounds) { s.destroy(); }

					VoidState.clearAssets = false;
					states.editors.ChartEditorState.song = song;
					MusicBeatState.switchState("states.editors.ChartEditorState", []);

					return;
				} else if (controls.check("Reset") && canReset) { 
					doGameOver(Songs.players[0]); 
					
					return; 
				}
			}			
		}

		if (songPlaying) {			
			// conductor.position = inst.time;
			conductor.position += FlxG.elapsed * 1000;
	
			if (!isPaused) {
				song_Time += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;
	
				// Interpolation type beat
				if (conductor.lastPosition != conductor.position) {
					song_Time = (song_Time + conductor.position) / 2;
					conductor.lastPosition = conductor.position;
					// conductor.position += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}	
			// conductor.lastPosition = inst.time;
		
			if (followChar) { Character.setCamera(stage.getCharacterById(Character.getFocus(song, curSection)), camFollow, lockStageCamera ? stage : null); }

			if (healthBar.defaultBumps = Settings.get("BumpingCamera") && defaultBumps) {
				FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultZoom, FlxG.elapsed * 3.125);
				camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, FlxG.elapsed * 3.125);
			}
		}
		
		super.update(elapsed);
	}

	public var last_conductor:Float = -10000;
	public function resyncVocals():Void{
		if (!songPlaying) { return; }

		for (sound in voices.sounds) { sound.pause(); }
	
		inst.play();
		conductor.position = inst.time;
		for (sound in voices.sounds) {
			sound.time = conductor.position;
			sound.play();
		}

		if (conductor.position < last_conductor) { endSong(); }
		last_conductor = conductor.position;
	}

	public function pauseSong(pause:Bool = true) {
		songPlaying = !pause;

		if (!songPlaying) {
			if (inst != null) {
				inst.pause();
				for (sound in voices.sounds) { sound.pause(); }
			}

			for (timer in timers) { if (timer != null) { timer.active = false; }}
			for (tween in tweens) { if (tween != null) { tween.active = false; }}
		} else {
			if (songGenerated && inst != null) { resyncVocals(); }	

			for (timer in timers) { if (timer != null) { timer.active = true; }}
			for (tween in tweens) { if (tween != null) { tween.active = true; }}
		}
		
		scripts.call('paused', [pause]);
	}

	public function pauseAndOpen(substate:String, args:Array<Dynamic>, hasEasterEgg:Bool = false, per_update:Bool = false, per_draw:Bool = true) {
		if (isPaused) { return; }

		persistentUpdate = per_update;
		persistentDraw = per_draw;
		isPaused = true;

		pauseSong();

		// 1 / 1000 chance for Gitaroo Man easter egg
		if (hasEasterEgg && FlxG.random.bool(0.1)) {
			trace('GITAROO MAN EASTER EGG');
			MusicBeatState.switchState("states.GitarooPause", []);
		} else {
			canControlle = false;
			loadSubState(substate, args);
		}
	}
	
	var previousFrameTime:Int = 0;
	function startSong():Void{
		trace("Starting Song");

		previousFrameTime = FlxG.game.ticks;
		
		conductor.position = 0;

		inst.play(true);
		for (sound in voices.sounds) {sound.play(true); }
				
		canPause = true;
		resyncVocals();

		songStarted = true;
		scripts.call('songStarted');
	}

	var songEnded:Bool = false;
	function endSong():Void {
		if (songEnded) { return; }
		songEnded = true;

		trace("Ending Song");

		songPlaying = false;
		canPause = false;
		isPaused = true;

		inst.stop();
		for (sound in voices.sounds) {sound.stop(); }
		
		lastPlayer = Songs.players[0];

		var song_score:Int = 0;
		for (s in Songs.players) { song_score += strums.members[s].score; }

		highscore = Highscore.save(Paths.format(song.song, true), song_score, song.difficulty, song.category);
		Songs.next(song_score);
		
		if (Songs.playlist.length <= 0) {
			NGio.unlockMedal(60961);
			Highscore.saveWeek(Songs.weekName, Songs.total_score, song.difficulty, song.category);

			inst.destroy();
			for (s in voices.sounds) { s.destroy(); }
		} else {
			prevCamFollow = camFollow;
		}

		scripts.complex("endSong", [], () -> { doEnd(); });
	}

	function doGameOver(_player:Int):Void {
		onGameOver = true;

		camHUD.visible = false;
		//camFHUD.visible = false;

		var chars:Array<Character> = [];
		var char:Array<Int> = song.strums[_player].characters;

		var l_section:Int = Std.int(Math.min(curSection, song.strums[_player].sections.length));
		
		if (song.strums[_player].sections[l_section].changeCharacters) { char = song.strums[_player].sections[l_section].characters; }
		for (i in char) { chars.push(stage.getCharacterById(i)); stage.getCharacterById(i).visible = false; }

		pauseAndOpen("substates.GameOverSubstate", [chars, song.style], false, false);
	}
	function doResults(_player:Int):Void {
		onResults = true;
		
		camHUD.visible = false;
		//camFHUD.visible = false;
		
		var chars:Array<Character> = [];
		var char:Array<Int> = song.strums[_player].characters;
		if (
			song.strums[_player] != null && 
			song.strums[_player].sections[curSection] != null && 
			song.strums[_player].sections[curSection].changeCharacters
		) { char = song.strums[_player].sections[curSection].characters; }

		for (i in char) { 
			chars.push(stage.getCharacterById(i)); 
			if (hideOnResults) { stage.getCharacterById(i).visible = false; }
		}

		persistentUpdate = false;
		persistentDraw = true;
		canControlle = false;

		loadSubState("substates.ResultSubstate", [
			chars, 
			song.style, 
			strumPlayer.score, 
			strumPlayer.hits, 
			strumPlayer.max_combo, 
			strumPlayer.misses, 
			strumPlayer.rankList, 
			highscore
		]);
	}

	override public function onFocusLost():Void {
		super.onFocusLost();

		if (!songStarted || !canPause || !Settings.get("PauseOnLostFocus", "GeneralSettings")) { return; }

		pauseAndOpen(
			"substates.PauseSubState",
			[
				() -> {
					checkScroll();
					startCountdown(() -> {
						persistentUpdate = true;
						persistentDraw = true;
						canControlle = true;
						isPaused = false;
						pauseSong(false);
					});
				}
			],
			true
		);
	}

	override function stepHit():Void {
		super.stepHit();
		
		if (
			songPlaying && 
			(
				(inst.time > conductor.position + 20 || inst.time < conductor.position - 20) ||
				(voices.sounds.length > 0 && (inst.time > voices.sounds[0].time + 20 || inst.time < voices.sounds[0].time - 20))
			)
		) { resyncVocals(); }
		
		//trace('${inst.time} / ${inst.length}');
	}

	override function beatHit():Void {
		super.beatHit();

		if (Settings.get("BumpingCamera") && defaultBumps) {
			if (curBeat % 2 == 0) {
				// Beat Icons
				healthBar.bumpIcons(iconMult);
			}

			if (curBeat % 4 == 0) {
				// Beat Cameras
				FlxG.camera.zoom += 0.015 * zoomMult;
				camHUD.zoom += 0.03 * zoomMult;
			}
		}

		if (song.sections[curSection] != null) {
			if (song.sections[curSection].changeBPM) {
				conductor.changeBPM(song.sections[curSection].bpm);
				FlxG.log.add('CHANGED BPM!');
				trace('Changed BPM');
			}
		}
	}
	
	function updateStrums():Void {
		var l_used:Array<Bool> = [false, false];

		for (strum in strums) {
			strum.alpha = 0;
			
			if (!song.strums[strum.ID].playable) { continue; }

			var l_character:Character = stage.getCharacterById(Character.getFocus(song, curSection, strum.ID));
			var l_side:Int = l_character.onRight ? 1 : 0;

			if (l_used[l_side]) { continue; }
			l_used[l_side] = true;

			strum.alpha = 1;
			strum.x = 
				(Settings.get("Onlynotes") || Settings.get("MiddleScroll")) ? 
					(strumMiddlePos - strum.width / 2) : 
					(l_character.onRight ? strumLeftPos : (strumRightPos - strum.width))
			;
		}
	}

	public function checkScroll():Void {
		healthBar.y = Settings.get("DownScroll") ? strumUpOffset : FlxG.height - healthBar.height - strumDownOffset;
		healthBar.screenCenter(X);

		for (strum in strums) {
			if (!strum.moveByScroll) { continue; }

			strum.y = Settings.get("DownScroll") ? FlxG.height - strum.staticnotes.height - strumOffset : strumOffset;
			for (n in strum.notelist) { n.playAnim(n.animation.curAnim.name, true); }
			strum.forEachNote((n:Note) -> { n.playAnim(n.animation.curAnim.name, true); });
		}
		
		scripts.call('checkScroll');
	}
}
