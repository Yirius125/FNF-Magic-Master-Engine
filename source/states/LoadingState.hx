package states;

import openfl.utils.Assets as OpenFlAssets;
import objects.notes.Note.Event_Data;
import objects.notes.Note.Note_Data;
import objects.songs.Song.Song_File;
import openfl.display.BitmapData;
import objects.notes.NoteSplash;
import objects.notes.StrumLine;
import objects.notes.StrumNote;
import objects.game.Character;
import objects.scripts.Script;
import openfl.utils.AssetType;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import objects.songs.Song;
import objects.notes.Note;
import flixel.FlxSprite;
import flixel.FlxState;
import lime.app.Future;
import utils.Scripts;
import haxe.io.Path;
import flixel.FlxG;
import haxe.Json;

#if sys
import sys.thread.FixedThreadPool;
import sys.thread.Thread;
import sys.thread.Mutex;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class LoadingState extends MusicBeatState {
	public static var globalStuff:Array<Dynamic> = [];
	public var toLoadStuff:Array<Dynamic> = [];

	public var sprBackground:FlxSprite;
	public var sprShape1:FlxSprite;
	public var sprShape2:FlxSprite;
	public var sprShape3:FlxSprite;
	public var sprShape4:FlxSprite;

	private var tempLoadingStuff:Array<Dynamic> = [];
	private var currentCount:Int = 0;
	private var totalCount:Int = 0;
	
	private var withMusic:Bool = false;
	
	private var thdPool:FixedThreadPool;
	private var thdMutex:Mutex;

	public var isPreloading(default, null):Bool = true;
	public var isLoading(default, null):Bool = false;
	public var isEnding(default, null):Bool = false;
	public var allLoaded(default, null):Bool = false;
	public var canEnding:Bool = false;

	public var TARGET:MusicBeatState;
	
	public static function cacheGlobal(_element):Void { LoadingState.globalStuff.push(_element); }

	public function new(_target:MusicBeatState, _toLoadStuff:Array<Dynamic>, withMusic:Bool = false):Void {
		if (_toLoadStuff == null) { _toLoadStuff = []; }
		this.toLoadStuff = _toLoadStuff;
		this.withMusic = withMusic;
		this.TARGET = _target;

		for (i in globalStuff) { toLoadStuff.push(i); }

		super();
	}

	override function create():Void {
		if (!withMusic && FlxG.sound.music != null) { FlxG.sound.music.stop(); }
		FlxG.mouse.visible = false;
		
		sprBackground = new FlxSprite().loadGraphic(Paths.image('menuBG'));
		sprBackground.setGraphicSize(FlxG.width, FlxG.height);
        sprBackground.color = 0xffff8cf7;
		sprBackground.screenCenter();
		add(sprBackground);

		sprShape1 = new FlxSprite(0, 0).makeGraphic(FlxG.width, 100, FlxColor.BLACK); add(sprShape1);
        sprShape2 = new FlxSprite(0, 105).makeGraphic(FlxG.width, 5, FlxColor.BLACK); add(sprShape2);
        sprShape3 = new FlxSprite(0, FlxG.height - 110).makeGraphic(FlxG.width, 5, FlxColor.BLACK); add(sprShape3);
        sprShape4 = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, FlxColor.BLACK); add(sprShape4);
				
		canEnding = true;

		super.create();
		
		thdMutex = new Mutex();
		new Future<Bool>(() -> { preLoadStuff(); return true; }, false).then((_) -> new Future<Bool>(() -> { loadStuff(); return true; }, false));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		allLoaded = currentCount >= totalCount;
		if (canEnding && !isEnding && allLoaded) { onLoad(); }
	}

	private function preLoadStuff():Void {
		tempLoadingStuff.push({ type: IMAGE, instance: Paths.image("icon-face", "icons") });
		tempLoadingStuff.push({ type: SOUND, instance: Paths.sound("confirmMenu") });
		tempLoadingStuff.push({ type: MUSIC, instance: Paths.music("break_song") });
		tempLoadingStuff.push({ type: MUSIC, instance: Paths.music("freakyMenu") });
		tempLoadingStuff.push({ type: SOUND, instance: Paths.sound("cancelMenu") });
		tempLoadingStuff.push({ type: SOUND, instance: Paths.sound("scrollMenu") });
		tempLoadingStuff.push({ type: MUSIC, instance: Paths.music("breakfast") });
		tempLoadingStuff.push({ type: IMAGE, instance: Paths.image("alphabet") });
		
		for (stuff in toLoadStuff) {			
			switch (stuff.type) {
				case "SONG": {
					var _song:Song_File = cast stuff.instance;

					tempLoadingStuff.push({ type: SOUND, instance: Paths.inst(_song.song, _song.category) });

					if (_song.voices) {
						for (i in 0..._song.strums.length) {
							if (_song.strums[i].characters.length <= 0) { continue; }
							if (_song.characters.length <= _song.strums[i].characters[0]) { continue; }

							var voice_path:String = Paths.voice(i, _song.characters[_song.strums[i].characters[0]][0], _song.song, _song.category);
							if (!Paths.exists(voice_path)) { continue; }
							
							tempLoadingStuff.push({ type: SOUND, instance: voice_path });
						}
					}

					for (p in StrumLine.ranks) {
						tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage(p.popup, _song.style) });
					}

					if ((TARGET is PlayState)) {
						for (p in cast(TARGET, PlayState).introAssets) {
							if (p.asset != null) { tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage(p.asset, _song.style) }); }
							if (p.sound != null) { tempLoadingStuff.push({ type: SOUND, instance: Paths.styleSound(p.sound, _song.style) }); }
						}
					}

					tempLoadingStuff.push({ type: MUSIC, instance: Paths.styleMusic('gameOverEnd', _song.style) });
					tempLoadingStuff.push({ type: SOUND, instance: Paths.styleSound('missnote1', _song.style) });
					tempLoadingStuff.push({ type: SOUND, instance: Paths.styleSound('missnote2', _song.style) });
					tempLoadingStuff.push({ type: SOUND, instance: Paths.styleSound('missnote3', _song.style) });
					tempLoadingStuff.push({ type: MUSIC, instance: Paths.styleMusic('gameOver', _song.style) });
					tempLoadingStuff.push({ type: MUSIC, instance: Paths.styleMusic('results', _song.style) });
					
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num0', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num1', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num2', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num3', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num4', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num5', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num6', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num7', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num8', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('num9', _song.style) });
					
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('healthBar_back', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('healthBar_front', _song.style) });

					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/highscoreNew', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/maxcombo', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/missed', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/results', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/scorePopin', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/systemBack', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/systemFront', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/topBarBlack', _song.style) });
					tempLoadingStuff.push({ type: IMAGE, instance: Paths.styleImage('result_menu/totalnotes', _song.style) });

					var stage_script:Script = Scripts.quick(Paths.stage(_song.stage));
					if (stage_script != null) { 
						stage_script.name = _song.stage;
						stage_script.call("cache", [tempLoadingStuff]); 
					}

					var song_script:Script = Scripts.quick(Paths.handlers(Song.format(_song.song, _song.category, _song.difficulty)));
					if (song_script != null) {
						song_script.parent = TARGET;
						song_script.name = "Song_Handlers";
						TARGET.scripts.set("Song_Handlers", song_script);
        				TARGET.scripts.m_piorityList.insert(0, "Song_Handlers");
					}

					for (char in _song.characters) { Character.cache(tempLoadingStuff, char[0], char[4]); }

					for (event in _song.events) {
						var cur_Event:Event_Data = Note.getEventData(event);
						if (cur_Event == null || cur_Event.isBroken) { continue; }

						for (cur_action in cur_Event.eventData) {
							var l_curPath:String = Paths.event(cur_action[0], _song.stage, _song.song);
							if (!Paths.exists(l_curPath)) { continue; }

							var script_event:Script = TARGET.scripts.get(cur_action[0]);
							if (script_event == null) {
								script_event = Scripts.quick(l_curPath);
								script_event.name = cur_action[0];

								script_event.call("cache", [tempLoadingStuff]);
								TARGET.scripts.set(cur_action[0], script_event);
							}
							if (script_event == null) { continue; }

							var l_cacheArray:Array<Dynamic> = (cast(cur_action[1], Array<Dynamic>)).copy();
							l_cacheArray.insert(0, tempLoadingStuff);
							
							script_event.call("cache_event", l_cacheArray);
						}
					}

					for (strum in _song.strums) {
						tempLoadingStuff.push({ type: IMAGE, instance: Paths.note('${NoteSplash.SPLASH_DEFAULT}_Splash', strum.style) });
						tempLoadingStuff.push({ type: IMAGE, instance: Paths.note(StrumNote.IMAGE_DEFAULT, strum.style) });

						for (section in strum.sections) {
							for (note in section.notes) {
								var cur_Note:Note_Data = Note.getNoteData(note);
								var note_events:Array<Dynamic> = [];

								if (cur_Note.eventData != null) { note_events = cur_Note.eventData.copy(); }

								if (cur_Note.preset != null && cur_Note.preset != "Default") {
									var preset_path:String = Paths.preset(cur_Note.preset);
									if (Paths.exists(preset_path)) {
										for (event in cast(preset_path.getJson().Events, Array<Dynamic>)) {
											note_events.push(event);
										}
									}
								}

								for (cur_action in note_events) {
									var l_curPath:String = Paths.event(cur_action[0], _song.stage, _song.song);
									if (!Paths.exists(l_curPath)) { continue; }

									var script_event:Script = TARGET.scripts.get(cur_action[0]);
									if (script_event == null) {
										script_event = Scripts.quick(l_curPath);
										script_event.name = cur_action[0];

										TARGET.scripts.set(cur_action[0], script_event);
										script_event.call("cache", [tempLoadingStuff]);
									}
									if (script_event == null) { continue; }

									var l_cacheArray:Array<Dynamic> = (cast(cur_action[1], Array<Dynamic>)).copy();
									l_cacheArray.insert(0, tempLoadingStuff);
									
									script_event.call("cache_event", l_cacheArray);
								}
							}
						}
					}

					continue;
				}
				case "PRELOAD": {
					if (stuff.instance != null) { stuff.instance(this); }
					
					continue;
				}
			}

			tempLoadingStuff.push(stuff);
		}
		
		TARGET.scripts.call("cache", [tempLoadingStuff]);
		
		totalCount = tempLoadingStuff.length;
		isPreloading = false;
		isLoading = true;
	}

	private function loadStuff():Void {
		thdPool = new FixedThreadPool(1);

		for (l_item in tempLoadingStuff) {
			if (l_item.type == null || l_item.instance == null) { trace("Error | " + l_item); continue; }
			
			switch (l_item.type) {
				default: { trace(l_item); currentCount++; }
				case SOUND, MUSIC: { createThread(() -> { Files.getSound(l_item.instance); currentCount++; }); }
				case IMAGE: { createThread(() -> { Files.getBitmap(l_item.instance); currentCount++; }); }
				case TEXT: { createThread(() -> { Files.getText(l_item.instance); currentCount++; }); }
				case "FUNCTION": { createThread(() -> { l_item.instance(); currentCount++; }); }
			}
		}
	}

	private function createThread(_func:Void -> Void, _trace:String = ""):Void {
		thdPool.run(() -> { 
			try { 
				thdMutex.acquire(); 

				_func(); 

				thdMutex.release(); 
			} catch(e:Dynamic) { 
				trace('Error on Loading $_trace: $e'); 

				thdMutex.release(); 
			} 
		});
	}

	private function onLoad():Void {
		if (isEnding) { return; } 
		isEnding = true;
		
		for (l_item in tempLoadingStuff) { 
			if (l_item.type != IMAGE) { continue; }

			Files.getGraphic(l_item.instance, false, false); 
        	Files.getAtlas(l_item.instance);
		}
		
		trace('Loaded All -> $TARGET');
		
		VoidState.clearAssets = false;
		MusicBeatState._switchState(TARGET);
	}
}