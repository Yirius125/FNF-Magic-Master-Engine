package states;

import objects.ui.UINumericStepper;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.addons.ui.FlxUIButton;
import objects.songs.Song.Song_File;
import flixel.util.FlxGradient;
import objects.game.Character;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flash.text.TextField;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import lime.utils.Assets;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxG;
import haxe.Json;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class PlayerSelectorState extends MusicBeatState {
	public var song:Song_File;
	
	public var background:FlxSprite;

	public var cursorGroup:FlxTypedGroup<FlxSprite>;
	public var charGroup:FlxTypedGroup<Character>;
	public var strumGroup:FlxTypedGroup<FlxSprite>;
	
	public function new(_selSong:Song_File, ?onConfirm:String, ?onBack:String) {
		song = _selSong;
		super(onConfirm, onBack);
	}

	override function create() {
		super.create();
		
        #if desktop
		// Updating Discord Rich Presence
		Discord.change('Selecting', '[Song Selector]');
		Magic.setWindowTitle('Selector', 1);
		#end		

		background = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
		background.setGraphicSize(FlxG.width, FlxG.height);
		background.scrollFactor.set(0, 0);
        background.color = 0xfffffd75;
		background.screenCenter();
		add(background);

		var playable_strums:Array<Int> = [];
		for (i in 0...song.strums.length) {
			if (!song.strums[i].playable) { continue; }
			playable_strums.push(i);
		}

		if (playable_strums.length <= 0) {MusicBeatState.switchState(onBack, []); }

		var cur_width:Float = 5; 
		strumGroup = new FlxTypedGroup<FlxSprite>();
		charGroup = new FlxTypedGroup<Character>();
		for (i in 0...playable_strums.length) {
			var cur_strum = song.strums[playable_strums[i]];
			var new_stage:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mini_stage').getGraphic());
			new_stage.setGraphicSize(Std.int((FlxG.width - 20) / playable_strums.length)); new_stage.updateHitbox();
			new_stage.setPosition(cur_width, FlxG.height - (new_stage.height / 2)); cur_width += new_stage.width + 10;

			if (cur_strum.characters.length > 0) {
				var char_data:Array<Dynamic> = song.characters[cur_strum.characters[0]];
				var new_char:Character = new Character(0, 0, char_data[0], char_data[4], char_data[5]);
				new_char.characterSprite.setGraphicSize(Std.int((new_stage.width / 2) - 10)); new_char.characterSprite.updateHitbox();
				new_char.characterSprite.setPosition(new_stage.x + (new_stage.width / 2) - (new_char.characterSprite.width / 2), new_stage.y - new_char.characterSprite.height + 90);
				new_char.turnLook(char_data[3]);
				charGroup.add(new_char);
			}

			strumGroup.add(new_stage);
		}
		add(strumGroup);
		add(charGroup);

		Songs.players = [];

		cursorGroup = new FlxTypedGroup<FlxSprite>();
		for (i in 0...Players.length) {
			Songs.players.push(0);

			var new_cursor:FlxSprite = new FlxSprite(100, 100);
			if (i == 0) {new_cursor.loadGraphic(Paths.image("keyboard_icon").getGraphic()); }
			else {new_cursor.loadGraphic(Paths.image("controller_icon").getGraphic()); }
			new_cursor.setGraphicSize(150); new_cursor.updateHitbox();
			cursorGroup.add(new_cursor);
		}
		add(cursorGroup);
	}

	override function update(elapsed:Float) {
		for (i in 0...Players.length) {
			var cur_cursor = cursorGroup.members[i];
			var cur_grid = strumGroup.members[Songs.players[i]];
			if (cur_grid != null) {Magic.lerpX(cur_cursor, (cur_grid.x + (cur_grid.width / 2) - (cur_cursor.width / 2))); }
		}

		if (canControlle) {
			if (controls.check("MenuAccept", JUST_PRESSED)) {goToSong(); }
			for (i in 0...Players.length) {
				if (Players.get(i).controls.check("MenuLeft", JUST_PRESSED)) {changeStrum(i, -1); }
				if (Players.get(i).controls.check("MenuRight", JUST_PRESSED)) {changeStrum(i, 1); }
			}
        }

        super.update(elapsed);		
	}

	function changeStrum(_id:Int, _change:Int):Void {
		if (Songs.players.length <= _id) { return; }
		Songs.players[_id] += _change;

		if (Songs.players[_id] < 0) {Songs.players[_id] = strumGroup.members.length -1; }
		if (Songs.players[_id] >= strumGroup.members.length) {Songs.players[_id] = 0; }
	}

	function goToSong():Void {
		Songs.quickPlay(song, FlxG.keys.pressed.SHIFT);
	}
}