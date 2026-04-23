package states;

import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.addons.ui.FlxUIButton;
import objects.songs.Song.Song_File;
import utils.Songs.Category_Data;
import flixel.util.FlxGradient;
import objects.songs.SongList;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.Alphabet;
import flash.text.TextField;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import objects.songs.Song;
import lime.utils.Assets;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxG;
import utils.Magic;
import haxe.Json;


#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class FreeplayState extends MusicBeatState {
	public static var curDifficulty:String = "Normal";
	public static var curCategory:String = "Normal";
	public static var curSong:Int = 0;

	public var onSelect:Song_File->Void = null;

	var songs:SongList;

	var background:FlxSprite;

	var grpSongs:FlxTypedGroup<Alphabet>;
    var grpArrows:FlxTypedGroup<FlxSprite>;
	
	var infoAlpha:Alphabet;
    var scoreAlpha:Alphabet;
	
    var difficulty:FlxSprite;
    var category:FlxSprite;

    var curOption:Int = 1;

	public function new(?onConfirm:String, ?onBack:String, ?_onSelect:Song_File->Void) {
		this.onSelect = _onSelect;
		super(onConfirm, onBack);
	}

	override function create() {
		if (FlxG.sound.music == null || (FlxG.sound.music != null && !FlxG.sound.music.playing)) { FlxG.sound.playMusic(Paths.music('freakyMenu').getSound()); }
		if (onSelect == null) { onSelect = chooseSong; }

		#if desktop
		// Updating Discord Rich Presence
		Discord.change('Selecting', '[Freeplay]');
		Magic.setWindowTitle('Freeplay', 1);
		#end

		songs = new SongList().setup();
		songs.removeHiddens();
		
		background = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
		background.setGraphicSize(FlxG.width, FlxG.height);
		background.scrollFactor.set(0, 0);
        background.color = 0xfffffd75;
		background.screenCenter();
		add(background);
		
		var back_1:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, 100, [FlxColor.BLACK, FlxColor.BLACK, 0x00000000]);
		add(back_1);
		
		var gradient:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, 100, [0x00000000, FlxColor.BLACK, 0x00000000]);
		gradient.y = (FlxG.height / 2) - (gradient.height / 2);
		add(gradient);
		
		grpSongs = new FlxTypedGroup<Alphabet>();
		for (i in 0...songs.list.length) {
			var songText:Alphabet = new Alphabet(0, 0, [{bold: true, text: Paths.format(songs.get(i).song)}]);

			if (Highscore.isLock(songs.get(i).keyLock)) {
				var cText:String = "";
				while(cText.length < songText.text.length) { cText = '${cText}?'; }
				songText.text = cText; songText.loadText();
			}

			songText.screenCenter(X);
			songText.ID = i;
			
			grpSongs.add(songText);
		}
		add(grpSongs);
		
        difficulty = new FlxSprite(FlxG.width + 1000, 0);
        add(difficulty);

        category = new FlxSprite(-1000, 0);
        add(category);
		
        //Adding Arrows
        grpArrows = new FlxTypedGroup<FlxSprite>();
        for (i in 0...2) {
            var arrow_1:FlxSprite = new FlxSprite();
            arrow_1.frames = Paths.image('arrows').getAtlas();
            arrow_1.animation.addByPrefix('idle', 'Arrow Idle');
            arrow_1.animation.addByPrefix('over', 'Arrow Over', false);
            arrow_1.animation.addByPrefix('hit', 'Arrow Hit', false);
            arrow_1.scale.set(0.3, 0.3);
            arrow_1.updateHitbox();
            
            switch (i) {
                case 0:{arrow_1.angle = 90; }
                case 1:{arrow_1.angle = 270; }
            }

			arrow_1.screenCenter(X);

            grpArrows.add(arrow_1);
            arrow_1.ID = i;
        }
        add(grpArrows);
		
        infoAlpha = new Alphabet(0, 30, Language.get("freeplay_info_1"));
        add(infoAlpha);
		
        scoreAlpha = new Alphabet(0, 0, [{text:"PlaceHolder"}]);
        add(scoreAlpha);

		changeSong();
		
		super.create();
	}

	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8) {FlxG.sound.music.volume += 0.5 * FlxG.elapsed; }

		Magic.sortMembersByY(cast grpSongs, (FlxG.height / 2), curSong, 25);
	
		if (canControlle) {
			if (controls.check("MenuLeft", JUST_PRESSED)) {changeOption(-1); }
			if (controls.check("MenuRight", JUST_PRESSED)) {changeOption(1); }

			switch (curOption) {
				case 0:{
					if (controls.check("MenuUp", JUST_PRESSED)) {changeCategory(-1); }
					if (controls.check("MenuDown", JUST_PRESSED)) {changeCategory(1); }
	
					for (a in grpArrows.members) {Magic.lerpX(cast a, category.x+(category.width/2)-(a.width/2)); }	
					grpArrows.members[0].y = category.y - grpArrows.members[0].height - 5;
					grpArrows.members[1].y = category.y + category.height + 5;

					Magic.lerpX(cast difficulty, FlxG.width + 10);
					Magic.lerpX(cast category, 250 - (category.width / 2));
					for (s in grpSongs) {s.x = FlxMath.lerp(s.x, FlxG.width - s.width - 5, 0.1); }
				}
				case 1:{
					if (controls.check("MenuUp", JUST_PRESSED)) {changeSong(-1); }
					if (controls.check("MenuDown", JUST_PRESSED)) {changeSong(1); }
	
					for (a in grpArrows.members) {Magic.lerpX(cast a, (FlxG.width / 2) - (a.width / 2)); }
					grpArrows.members[0].y = (FlxG.height / 2) - (grpSongs.members[curSong].height / 2) - grpArrows.members[0].height - 5;
					grpArrows.members[1].y = (FlxG.height / 2) + (grpSongs.members[curSong].height / 2) + 5;
					
					Magic.lerpX(cast difficulty, FlxG.width - (difficulty.width / 2));
					Magic.lerpX(cast category, -(category.width / 2));
					for (s in grpSongs) {s.x = FlxMath.lerp(s.x, (FlxG.width / 2) - (s.width / 2), 0.1); }
				}
				case 2:{
					if (controls.check("MenuUp", JUST_PRESSED)) {changeDifficulty(-1); }
					if (controls.check("MenuDown", JUST_PRESSED)) {changeDifficulty(1); }
					
					for (a in grpArrows.members) {Magic.lerpX(cast a, difficulty.x+(difficulty.width/2)-(a.width/2)); }	
					grpArrows.members[0].y = difficulty.y - grpArrows.members[0].height - 5;
					grpArrows.members[1].y = difficulty.y + difficulty.height + 5;
					
					Magic.lerpX(cast difficulty, (FlxG.width - 250) - (difficulty.width / 2));
					Magic.lerpX(cast category, -category.width - 10);
					for (s in grpSongs) {s.x = FlxMath.lerp(s.x, 5, 0.1); }
				}
			}

			if (controls.check("MenuAccept", JUST_PRESSED)) {selectSong(); }
		}
		
		super.update(elapsed);		
	}
	
    function changeOption(value:Int = 0, force:Bool = false):Void {
		curOption += value; if (force) {curOption = value; }

        if (curOption > 2) {curOption = 0; }
        if (curOption < 0) {curOption = 2; }
	}
	
	var cur_tween_color:FlxTween;
	public function changeSong(change:Int = 0, force:Bool = false):Void {
		curSong += change; if (force) {curSong = change; }

		if (curSong < 0) {curSong = songs.length - 1; }
		if (curSong >= songs.length) {curSong = 0; }

		for (s in grpSongs) {s.alpha = 0.5; }

		if (grpSongs.members.length <= 0) { return; }
		grpSongs.members[curSong].alpha = 1;

		if (cur_tween_color != null) {cur_tween_color.cancel(); }
		cur_tween_color = FlxTween.color(background, 0.5, background.color, FlxColor.fromString(songs.get(curSong).color), {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {cur_tween_color = null; }});

		changeCategory();
	}
	
    function changeCategory(value:Int = 0, force:Bool = false):Void {
        var cat_list:Array<String> = []; for (cur_cat in songs.get(curSong).categories) {cat_list.push(cur_cat.name); }
        var cur_cat:Int = cat_list.indexOf(curCategory);
		if (cur_cat == -1) {
			curCategory = cat_list[0];
			changeCategory();
			return;
		}

		cur_cat += value; if (force) {cur_cat = value; }

		if (cur_cat < 0) {cur_cat = cat_list.length - 1; }
		if (cur_cat >= cat_list.length) {cur_cat = 0; }

        curCategory = cat_list[cur_cat];
		if (curCategory == null) { return; }

        category.loadGraphic(Paths.image('categories/${Paths.format(curCategory.toLowerCase(), true)}').getGraphic());
        category.y = (FlxG.height / 2) - (category.height / 2);
        
        changeDifficulty();
    }

    function changeDifficulty(value:Int = 0, force:Bool = false):Void {
        var cat_list:Array<Category_Data> = songs.get(curSong).categories;
		var cat_names:Array<String> = []; for (cur_cat in cat_list) {cat_names.push(cur_cat.name); }
        var cur_cat:Int = cat_names.indexOf(curCategory);
		var diff_list:Array<String> = cat_list[cur_cat].difficulties;
		var cur_diff:Int = diff_list.indexOf(curDifficulty);
		
		if (cur_diff == -1) {
			curDifficulty = diff_list[0];
			changeDifficulty();
			return;
		}

		cur_diff += value; if (force) {cur_diff = value; }

		if (cur_diff < 0) {cur_diff = diff_list.length - 1; }
		if (cur_diff >= diff_list.length) {cur_diff = 0; }

        curDifficulty = diff_list[cur_diff];

        difficulty.loadGraphic(Paths.image('difficulties/${Paths.format(curDifficulty.toLowerCase(), true)}').getGraphic());
        difficulty.y = (FlxG.height / 2) - (difficulty.height / 2);
		
		var song_score:Float = Highscore.get(Paths.format(songs.get(curSong).song, true), curDifficulty, curCategory);
        scoreAlpha.cur_data = [{scale:0.3, bold:true, text:'${Language.getText('gmp_score')}: ${song_score}'}];
        scoreAlpha.loadText(); scoreAlpha.screenCenter(X);
		
		FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }

	function selectSong():Void {
		FlxG.sound.play(Paths.sound("confirmMenu").getSound());
		
		var songInput:String = Song.format(songs.get(curSong).song, curCategory, curDifficulty);
		trace('Song File: ${songInput}');

		var songdata:Song_File = Song.load(songInput);
		onSelect(songdata);
	}
	function chooseSong(_song:Song_File):Void {
		Songs.quickPlay(_song, FlxG.keys.pressed.SHIFT);
	}
}