package substates;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import substates.menus.OptionsSubMenu;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import objects.game.Alphabet;
import flixel.sound.FlxSound;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import objects.game.Alphabet;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import objects.notes.Note;
import flixel.FlxSubState;
import states.VoidState;
import states.PlayState;
import flixel.FlxSprite;
import utils.Language;
import utils.Songs;
import utils.Magic;
import flixel.FlxG;

using utils.Files;

class PauseSubState extends MusicBeatSubstate {
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var grpBackShit:FlxTypedGroup<FlxSprite>;

	var menuItems:Array<String> = ['Resume', 'Restart', 'Options', 'Exit'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	public function new(onClose:Void->Void):Void {
		super(onClose);
	}
	
	override function create() {
		super.create();

        curCamera.bgColor = 0x5a000000;
		curCamera.alpha = 0;

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast').getSound(), true, true); pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		FlxG.sound.list.add(pauseMusic);

		grpBackShit = new FlxTypedGroup<FlxSprite>();
		var stickerList:Array<String> = Paths.readDirectory("assets/shared/images/stickers");
		for (i in 0...50) {
			if (FlxG.random.bool(50)) {
				var backnote:Note = new Note(Note.getNoteData([null, FlxG.random.int(0, 9)]), 10, null, PlayState.song != null ? PlayState.song.strums[0].style : null);
				backnote.scale.x = backnote.scale.y = FlxG.random.float(0.2, 1); backnote.updateHitbox();
				backnote.alpha = FlxG.random.float(0.05, 0.6);
				backnote.setPosition(
					FlxG.random.float(0, FlxG.width - backnote.width),
					(i * (-FlxG.height) / 50) + FlxG.random.float(-backnote.height, backnote.height)
				);
				
            	backnote.velocity.y = FlxG.random.float(30, 50);
				//backnote.velocity.y = 100;

				grpBackShit.add(backnote);
			} else {
				var backSticker:FlxSprite = new FlxSprite().loadGraphic(stickerList[FlxG.random.int(0, stickerList.length - 1)]);
				backSticker.scale.x = backSticker.scale.y = FlxG.random.float(0.05, 0.5); backSticker.updateHitbox();
				backSticker.alpha = FlxG.random.float(0.05, 0.6);
				backSticker.setPosition(
					FlxG.random.float(0, FlxG.width - backSticker.width),
					(i * (-FlxG.height) / 50) + FlxG.random.float(-backSticker.height, backSticker.height)
				);
				
            	backSticker.velocity.y = FlxG.random.float(30, 50);
				//backSticker.velocity.y = 100;

				grpBackShit.add(backSticker);
			}
		}
		add(grpBackShit);

		var levelInfo:Alphabet = new Alphabet(20, 15, {font: "tardling_font", text: Paths.format(PlayState.song.song)});
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelInfo.alpha = 0;
		add(levelInfo);

		var levelDifficulty:Alphabet = new Alphabet(20, levelInfo.y + levelInfo.height + 5, {font: "tardling_font_outline", text: PlayState.song.difficulty});
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		levelDifficulty.alpha = 0;
		add(levelDifficulty);

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		for (i in 0...menuItems.length) {
			var songText:Alphabet = new Alphabet(10, (70 * i) + 30, {font: "tardling_font_outline", scale: 1.5, text: Language.getText('pas_${menuItems[i].toLowerCase()}')});
			grpMenuShit.add(songText);
		}
		grpMenuShit.cameras = [curCamera];
		add(grpMenuShit);

		changeSelection(0, true);
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(curCamera, {alpha: 1}, 0.3, {ease: FlxEase.quadOut, onComplete: function(twn) {canControlle = true; }});
		
		scripts.call('created');
	}

	override function update(elapsed:Float) {
		if (pauseMusic.volume < 0.5) {pauseMusic.volume += 0.01 * elapsed; }

		super.update(elapsed);

		for (obj in grpBackShit.members) {
			if (obj.y > FlxG.height + 5) {
				obj.x = FlxG.random.float(0, FlxG.width - obj.width);
				obj.y = -obj.height - 5;
			}
			obj.angle += elapsed;
		}

		if (canControlle) {
			if (controls.check("MenuUp", JUST_PRESSED)) {
				changeSelection(-1);
			}
			if (controls.check("MenuDown", JUST_PRESSED)) {
				changeSelection(1);
			}
			if (controls.check("MenuAccept", JUST_PRESSED)) {
				var daSelected:String = menuItems[curSelected];
	
				switch (daSelected) {
					case "Resume":{ doClose(); }
					case "Options":{
						loadSubState("substates.SettingsSubState", []); 
					}
					case "Restart":{
						VoidState.clearAssets = FlxG.keys.pressed.SHIFT;
						Songs.play(Songs.isStoryMode);
					}
					case "Exit":{
						var cur_state = MusicBeatState.state;
						if ((cur_state is PlayState)) {		
							var cur_playstate:PlayState = cast cur_state;
							cur_playstate.inst.destroy();
							for (s in cur_playstate.voices.sounds) { s.destroy(); }
						}

						//if (states.PlayState.isDuel) {states.MusicBeatState.switchState("states.FreeplayState", [null, "states.MainMenuState", function(_song) {MusicBeatState.switchState("states.PlayerSelectorState", [_song, null, "states.MainMenuState"]); }]); }
						if (Songs.isStoryMode) {  MusicBeatState.switchState("states.StoryMenuState", [null, "states.MainMenuState"]); }
						else { MusicBeatState.switchState("states.FreeplayState", [null, "states.MainMenuState"]); }
					}
				}
			}
		}

		Magic.sortMembersByY(cast grpMenuShit, (FlxG.height / 2), curSelected);
	}

	override function destroy() {
		pauseMusic.destroy();
		super.destroy();
	}

	function changeSelection(change:Int = 0, force:Bool = false):Void {
		if (force) {curSelected = change; } else {curSelected += change; }

		if (curSelected < 0) {curSelected = menuItems.length - 1; }
		if (curSelected >= menuItems.length) {curSelected = 0; }

		for (i in 0...grpMenuShit.members.length) {
			grpMenuShit.members[i].alpha = 0.5;
			if (i == curSelected) {grpMenuShit.members[i].alpha = 1; }
		}
		
		if (!force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound()); }
	}

	public function doClose() {
		canControlle = false;
		FlxG.sound.play(Paths.sound("cancelMenu").getSound());
		FlxTween.tween(curCamera, {alpha: 0}, 0.3, {ease:FlxEase.quadOut, onComplete: function(twn) {close(); }});
	}
}
