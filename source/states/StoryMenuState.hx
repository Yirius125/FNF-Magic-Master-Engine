package states;

import flixel.group.FlxGroup.FlxTypedGroup;
import utils.Songs.Category_Data;
import flixel.util.FlxGradient;
import objects.songs.WeekList;
import objects.game.Alphabet;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxG;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class StoryMenuState extends MusicBeatState {
	public static var curDifficulty:String = "Normal";
	public static var curCategory:String = "Normal";
	public static var curWeek:Int = 0;
    
    public static var curOption:Int = 1;

    public var week_image:FlxSprite;
    public var weeks:WeekList;

    public var grpWeeks:FlxTypedGroup<FlxSprite>;
    public var grpArrows:FlxTypedGroup<FlxSprite>;

    public var difficulty:FlxSprite;
    public var category:FlxSprite;
    
	var infoAlpha:Alphabet;
    var titleAlpha:Alphabet;
    var scoreAlpha:Alphabet;

	override function create() {
		if (FlxG.sound.music == null || (FlxG.sound.music != null && !FlxG.sound.music.playing)) {FlxG.sound.playMusic(Paths.music('freakyMenu').getSound()); }
		FlxG.mouse.visible = false;
        
		#if desktop
		// Updating Discord Rich Presence
		Discord.change("Selecting a Week", null);
		Magic.setWindowTitle('Selecting a Week');
		#end

        weeks = new WeekList();

        var bg = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
		bg.setGraphicSize(FlxG.width, FlxG.height);
        bg.color = FlxColor.GRAY;
		bg.screenCenter();
		add(bg);

        var shape_1:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, 60, FlxColor.BLACK);
        add(shape_1);

        week_image = new FlxSprite(0, 60);
        add(week_image);

        titleAlpha = new Alphabet(0, 0, [{text:"PlaceHolder"}]);
        add(titleAlpha);

        scoreAlpha = new Alphabet(0, 0, [{text:"PlaceHolder"}]);
        add(scoreAlpha);

        var shape_2:FlxSprite = new FlxSprite(0, 65).makeGraphic(FlxG.width, 5, FlxColor.BLACK);
        add(shape_2);

        var shape_3:FlxSprite = new FlxSprite(0, FlxG.height - 230).makeGraphic(FlxG.width, 5, FlxColor.BLACK);
        add(shape_3);

        var shape_4:FlxSprite = new FlxSprite(0, FlxG.height - 220).makeGraphic(FlxG.width, 220, FlxColor.BLACK);
        add(shape_4);
		
		super.create();

        var camWeeks:FlxCamera = new FlxCamera(0, FlxG.height - 220, FlxG.width, 220);
		camWeeks.bgColor.alpha = 0;
        camWeeks.focusOn(FlxPoint.get((FlxG.width / 2), (FlxG.height - 110)));
		FlxG.cameras.add(camWeeks);

        grpWeeks = new FlxTypedGroup<FlxSprite>();
        for (i in 0...weeks.length) {
            var spr_week:FlxSprite = new FlxSprite().loadGraphic(Paths.image('weeks/${weeks.get(i).name}').getGraphic());
            spr_week.screenCenter(X);
            grpWeeks.add(spr_week);
        }
        grpWeeks.cameras = [camWeeks];
        add(grpWeeks);

        difficulty = new FlxSprite();
        difficulty.cameras = [camWeeks];
        add(difficulty);

        category = new FlxSprite();
        category.cameras = [camWeeks];
        add(category);
        
        var shape_5:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, 110, [FlxColor.BLACK, 0x00000000]);
        shape_5.setPosition(0, FlxG.height - 220);
        shape_5.cameras = [camWeeks];
        add(shape_5);
        
        var shape_6:FlxSprite = FlxGradient.createGradientFlxSprite(FlxG.width, 110, [0x00000000, FlxColor.BLACK]);
        shape_6.setPosition(0, FlxG.height - 110);
        shape_6.cameras = [camWeeks];
        add(shape_6);

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

            grpArrows.add(arrow_1);
            arrow_1.ID = i;
        }
        grpArrows.cameras = [camWeeks];
        add(grpArrows);

        infoAlpha = new Alphabet(0, 0, Language.get("story_info_1"));
        infoAlpha.cameras = [camWeeks];
        infoAlpha.y = FlxG.height - 220;
        add(infoAlpha);
        
		changeWeek();
	}

	override function update(elapsed:Float) {		
		super.update(elapsed);

        if (controls.check("MenuAccept", JUST_PRESSED)) {chooseWeek(); }

        if (controls.check("MenuLeft", JUST_PRESSED)) {changeOption(-1); }
        if (controls.check("MenuRight", JUST_PRESSED)) {changeOption(1); }

		Magic.sortMembersByY(cast grpWeeks, (FlxG.height - 110) - (grpWeeks.members[curWeek].height / 2), curWeek);

        switch (curOption) {
            case 0:{
                if (controls.check("MenuUp", JUST_PRESSED)) {changeCategory(-1); }
                if (controls.check("MenuDown", JUST_PRESSED)) {changeCategory(1); }

                for (a in grpArrows.members) {Magic.lerpX(cast a, 250); }

                grpArrows.members[0].y = category.y - grpArrows.members[0].height - 5;
                grpArrows.members[1].y = category.y + category.height + 5;
            }
            case 1:{
                if (controls.check("MenuUp", JUST_PRESSED) || FlxG.mouse.wheel > 0) {changeWeek(-1); }
                if (controls.check("MenuDown", JUST_PRESSED) || FlxG.mouse.wheel < 0) {changeWeek(1); }

                for (a in grpArrows.members) {Magic.lerpX(cast a, (FlxG.width / 2)); }
                grpArrows.members[0].y = grpWeeks.members[curWeek].y - grpArrows.members[0].height - 5;
                grpArrows.members[1].y = grpWeeks.members[curWeek].y + grpWeeks.members[curWeek].height + 5;
            }
            case 2:{
                if (controls.check("MenuUp", JUST_PRESSED)) {changeDifficulty(-1); }
                if (controls.check("MenuDown", JUST_PRESSED)) {changeDifficulty(1); }

                for (a in grpArrows.members) {Magic.lerpX(cast a, (FlxG.width - 250)); }

                grpArrows.members[0].y = difficulty.y - grpArrows.members[0].height - 5;
                grpArrows.members[1].y = difficulty.y + difficulty.height + 5;
            }
        }
	}

    function changeOption(value:Int = 0, force:Bool = false):Void {
		curOption += value; if (force) {curOption = value; }

        if (curOption > 2) {curOption = 0; }
        if (curOption < 0) {curOption = 2; }
	}

	function changeWeek(value:Int = 0, force:Bool = false):Void {
		curWeek += value; if (force) {curWeek = value; }

		if (curWeek < 0) {curWeek = grpWeeks.members.length - 1; }
		if (curWeek >= grpWeeks.members.length) {curWeek = 0; }

        for (w in grpWeeks.members) {w.alpha = 0.5; }
        grpWeeks.members[curWeek].alpha = 1;

        titleAlpha.cur_data = [{scale: 0.6, bold: true, text: weeks.get(curWeek).title}];
        titleAlpha.loadText();
        titleAlpha.screenCenter(X);

        week_image.loadGraphic(Paths.image('story_menu/${weeks.get(curWeek).image}'));
        week_image.setGraphicSize(FlxG.width);
        week_image.screenCenter(X);

        changeCategory();
	}
    
    function changeCategory(value:Int = 0, force:Bool = false):Void {
        var cat_list:Array<String> = []; for (cur_cat in weeks.get(curWeek).categories) {cat_list.push(cur_cat.name); }
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

        category.loadGraphic(Paths.image('categories/${Paths.format(curCategory.toLowerCase(), true)}').getGraphic());
        category.setPosition(250 - (category.width / 2), (FlxG.height - 110) - (category.height / 2));
        
        changeDifficulty();
    }

    function changeDifficulty(value:Int = 0, force:Bool = false):Void {
        var cat_list:Array<Category_Data> = weeks.get(curWeek).categories;
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
        difficulty.setPosition((FlxG.width - 250) - (difficulty.width / 2), (FlxG.height - 110) - (difficulty.height / 2));
        
        scoreAlpha.cur_data = [{scale:0.4, bold:true, text:'${Language.getText('gmp_score')}: ${Highscore.getWeek(weeks.get(curWeek).name, curDifficulty, curCategory)}'}];
        scoreAlpha.loadText();
        
		FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }

    function chooseWeek():Void {
        FlxG.sound.play(Paths.sound("confirmMenu").getSound());
        
        Songs.reset();
        Songs.loadWeek(weeks.get(curWeek), curCategory, curDifficulty);
        Songs.play(true);
    }
}
