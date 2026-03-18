package substates;

import flixel.group.FlxGroup.FlxTypedGroup;
import objects.settings.Number_Setting;
import objects.settings.List_Setting;
import objects.settings.Bool_Setting;
import objects.settings.Category;
import objects.menu.MenuKeyBind;
import objects.notes.StrumNote;
import objects.notes.StrumLine;
import objects.menu.MenuNumber;
import objects.utils.Controls;
import flixel.tweens.FlxTween;
import objects.menu.MenuBool;
import objects.menu.MenuList;
import objects.game.Alphabet;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxObject;
import utils.Language;
import utils.Songs;
import utils.Magic;
import flixel.FlxG;

using utils.Files;

class SettingsSubState extends MusicBeatSubstate {
	var inNoteControls:Bool = false;
	var inCategory:Bool = false;
	var inControls:Bool = false;
	var curCategory:Int = 0;
	var curOption:Int = 0;

	var curKeys:Int = 4;
	var strumline:StrumLine;
	var strumline_test:StrumLine;
	var isTestingNotes:Bool = false;

	var _category:Category;
	var catList:Array<String> = [];

	var backSprite:FlxSprite;

    var ttlSettings:Alphabet;
	var grpCategories:FlxTypedGroup<Alphabet>;
	var grpOptions:FlxTypedGroup<Dynamic>;
	var grpCheckers:FlxTypedGroup<Dynamic>;
	
	public function new(onClose:Void->Void) {
		super(onClose);
	}
	
	override function create() {
		catList = Settings.categories;
		catList.insert(0, "NoteControls");
		catList.insert(0, "Controls");
		
		super.create();
		
        curCamera.bgColor = 0x5a000000;
		curCamera.alpha = 0;

		backSprite = new FlxSprite().loadGraphic(Paths.image("pinkBack"));
		backSprite.x = -backSprite.width - 10;
		backSprite.color = FlxColor.BLACK;
        add(backSprite);

        ttlSettings = new Alphabet(0, 20, Language.get("settings_title"));
        ttlSettings.x = FlxG.width - ttlSettings.width - 20;
        add(ttlSettings);

		strumline = new StrumLine(0, 0, 4, 448);
		strumline_test = new StrumLine(0, 0, 4, 448);
		strumline_test.x = FlxG.width - strumline_test.width - 20;
		strumline_test.y = FlxG.height - strumline_test.height - 20;
		strumline_test.visible = false;
		add(strumline_test);

		grpOptions = new FlxTypedGroup<Dynamic>();
        add(grpOptions);
		grpCheckers = new FlxTypedGroup<Dynamic>();
        add(grpCheckers);

		grpCategories = new FlxTypedGroup<Alphabet>();
		for (_cat in catList) {
			var newCategory:Alphabet = new Alphabet(20, -100, {font: "tardling_font_outline", scale: 1.3, text: Language.getText('cat_${_cat.toLowerCase()}')});
			grpCategories.add(newCategory);
		}
        add(grpCategories);

		FlxTween.tween(backSprite, {x: 0}, 0.5, {ease: FlxEase.quadOut});
		FlxTween.tween(curCamera, {alpha: 1}, 1, {onComplete: function(twn) {canControlle = true; changeCategory(0, true); }});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (inCategory) {
			Magic.sortMembersByY(cast grpOptions, (FlxG.height / 2) - (grpOptions.members[curOption].height / 2), curOption, 60);
			for (i in 0...grpOptions.length) {
				var curObj = grpCheckers.members[i];

				if ((curObj is Alphabet)) {
					cast(curObj, Alphabet).y = grpOptions.members[i].y + 5;
				} else if ((curObj is MenuKeyBind)) {
					cast(curObj, MenuKeyBind).y = grpOptions.members[i].y - 20;
				} else {
					curObj.y = grpOptions.members[i].y;
				}
			}
		} else {
			Magic.sortMembersByY(cast grpCategories, (FlxG.height / 2) - (grpCategories.members[curCategory].height / 2), curCategory, 40);
		}
		
		if (canControlle) {
			if (inCategory) {
				if (inNoteControls) {
					if (curOption == 1 && (controls.check("MenuLeft", JUST_PRESSED) || controls.check("MenuRight", JUST_PRESSED))) {
						curKeys = grpCheckers.members[curOption].value;
						loadStrum();
					} else if (controls.check("MenuUp", JUST_PRESSED) && !isTestingNotes) { changeSetting(-1); }
					else if (controls.check("MenuDown", JUST_PRESSED) && !isTestingNotes) { changeSetting(1); }
					else if (controls.check("MenuAccept", JUST_PRESSED)) {
						switch (curOption) {
							case 0: { }
							case 1: {
								FlxG.sound.play(Paths.sound("scrollMenu").getSound());
								strumline_test.visible = !strumline_test.visible;
								isTestingNotes = strumline_test.visible;
							}
							default: { canControlle = false; }
						}
					} else if (controls.check("MenuBack", JUST_PRESSED)) { 
						Controls.save();
						Players.init();
						unSelectCategory(); 
					}
				}
				else if (inControls) {
					if (controls.check("MenuUp", JUST_PRESSED)) { changeSetting(-1); }
					else if (controls.check("MenuDown", JUST_PRESSED)) { changeSetting(1); }
					else if (controls.check("MenuAccept", JUST_PRESSED)) {
						if (!(grpCheckers.members[curOption] is MenuKeyBind)) {
							if (curOption == grpCheckers.length - 1) {
								Controls.reset();
								unSelectCategory();
								selectCategory();
							}
						} else { canControlle = false; }
					} else if (controls.check("MenuBack", JUST_PRESSED)) { 
						Controls.save();
						Players.init();
						unSelectCategory(); 
					}
				} else {
					if (controls.check("MenuUp", JUST_PRESSED)) { changeSetting(-1); }
					else if (controls.check("MenuDown", JUST_PRESSED)) {changeSetting(1); }
					else if (controls.check("MenuBack", JUST_PRESSED)) { unSelectCategory(); }
				}
			} else {
				if (controls.check("MenuUp", JUST_PRESSED)) {changeCategory(-1); }
				else if (controls.check("MenuDown", JUST_PRESSED)) {changeCategory(1); }
				else if (controls.check("MenuAccept", JUST_PRESSED)) {selectCategory(); }
				else if (controls.check("MenuBack", JUST_PRESSED)) { doClose(); }
			}

		} else if (((inControls || inNoteControls) && (grpCheckers.members[curOption] is MenuKeyBind) && !grpCheckers.members[curOption].isBinding)) {
			canControlle = true;
		}
	}

	function changeCategory(change:Int = 0, force:Bool = false):Void {
		if (force) {curCategory = change; } else {curCategory += change; }

		if (curCategory < 0) {curCategory = grpCategories.length - 1; }
		if (curCategory >= grpCategories.length) {curCategory = 0; }
		
		for (i in 0...grpCategories.members.length) {
			grpCategories.members[i].color = FlxColor.WHITE;
			if (i == curCategory) {grpCategories.members[i].color = 0xfffff082; }
		}
		
		if (!force) { FlxG.sound.play(Paths.sound("scrollMenu").getSound()); }
	}
	function changeSetting(change:Int = 0, force:Bool = false):Void {
		if (grpCheckers.members[curOption].isSelected != null) {grpCheckers.members[curOption].isSelected = false; }

		if (force) {curOption = change; } else {curOption += change; }

		if (curOption < 0) {curOption = grpOptions.length - 1; }
		if (curOption >= grpOptions.length) {curOption = 0; }
		
		for (i in 0...grpOptions.members.length) {
			var curOpt = grpOptions.members[i];

			if ((curOpt is Alphabet)) {
				cast(curOpt, Alphabet).color = 0xffffffff;
				if (i == curOption) {cast(curOpt, Alphabet).color = 0xff3dff94; }
			} else if ((curOpt is StrumNote)) {
				cast(curOpt, StrumNote).playAnim("static");
				if (i == curOption) {cast(curOpt, StrumNote).playAnim("confirm"); }
			}
		}
		
		if (grpCheckers.members[curOption].isSelected != null) {grpCheckers.members[curOption].isSelected = true; }
		
		if (!force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound()); }
	}

	function selectCategory():Void {
		grpCheckers.clear();
		grpOptions.clear();

		curOption = 0;

		switch (catList[curCategory]) {
			case "Controls":{
				for (_control in Controls.keys) {
					var newSetting:Alphabet = new Alphabet(20, -100, {font: "tardling_font_outline", text: Language.getText('ctr_${_control.toLowerCase()}')});
					grpOptions.add(newSetting);
					
					var newCheck:MenuKeyBind = new MenuKeyBind(20, -100, controls, _control);
					newCheck.x = newSetting.x + newSetting.width + 20;
					grpCheckers.add(newCheck);
				}
				
				var newSetting:Alphabet = new Alphabet(20, -100, {font: "tardling_font_outline", rel_position: [0, 20], text: Language.getText('ctr_resetcontrols')}); grpOptions.add(newSetting);
				var voidObject:FlxObject = new FlxObject(0, 0); grpCheckers.add(voidObject);

				inControls = true;
			}
			case "NoteControls":{
				var keyList:Array<Dynamic> = [["currentnotes", 1]];
				curKeys = 4;
				
				for (_option in keyList) {
					var newSetting:Alphabet = new Alphabet(20, -100, {font: "tardling_font_outline", text: Language.getText('ctr_${_option[0].toLowerCase()}')});
					grpOptions.add(newSetting);
					
					switch (_option[1]) {
						case 0:{
							var voidObject:FlxObject = new FlxObject(0, 0); 
							grpCheckers.add(voidObject);
						}
						case 1:{
							var newCheck:MenuNumber = new MenuNumber(20, -100, curKeys, 1, 10, 1);
							newCheck.x = newSetting.x + newSetting.width + 20;
							newCheck.controls = controls;
							grpCheckers.add(newCheck);
						}
					}
				}

				loadStrum();

				inNoteControls = true;
			}
			default:{
				_category = Settings.get_category(catList[curCategory]);
				for (_setting in _category.settings) {
					var newSetting:Alphabet = new Alphabet(20, -100, {font: "tardling_font_outline", text: Language.getText('opt_${_setting.name.toLowerCase()}') + ":"});
					grpOptions.add(newSetting);
		
					if ((_setting is Bool_Setting)) {
						var newCheck:MenuBool = new MenuBool(20, -100, _setting.value, _setting.name);
						newCheck.x = newSetting.x + newSetting.width + 20;
						newCheck.setGraphicSize(0, newSetting.height + 10);
						newCheck.updateHitbox();
						newCheck.controls = controls;
						grpCheckers.add(newCheck);
					} else if ((_setting is List_Setting)) {
						var _list_setting:List_Setting = cast _setting;
						var newCheck:MenuList = new MenuList(20, -100, _list_setting.list, _list_setting.index, _list_setting.name);
						newCheck.x = newSetting.x + newSetting.width + 20;
						newCheck.controls = controls;
						grpCheckers.add(newCheck);
					} else if ((_setting is Number_Setting)) {
						var _number_setting:Number_Setting = cast _setting;
						var newCheck:MenuNumber = new MenuNumber(20, -100, _number_setting.value, _number_setting.min, _number_setting.max, _number_setting.step, _number_setting.name);
						newCheck.x = newSetting.x + newSetting.width + 20;
						newCheck.controls = controls;
						grpCheckers.add(newCheck);
					} else {
						var voidObject:FlxObject = new FlxObject(0, 0);
						grpCheckers.add(voidObject);
					}
				}
			}
		}
		
		changeSetting(0, true);
		inCategory = true;
		
		for (i in 0...grpCategories.members.length) {
			FlxTween.cancelTweensOf(grpCategories.members[i]);
			if (i == curCategory) {FlxTween.tween(grpCategories.members[i], {y: ttlSettings.y + ttlSettings.height + 20, x: FlxG.width - grpCategories.members[i].width - 20}, 0.1, {ease: FlxEase.quadOut}); continue; }
			FlxTween.tween(grpCategories.members[i], {x: -grpCategories.members[i].width - 10}, i * 0.05 + 0.1, {ease: FlxEase.quadInOut});
		}

		FlxG.sound.play(Paths.sound("scrollMenu").getSound());
	}
	function unSelectCategory():Void {
		grpCheckers.clear();
		grpOptions.clear();

		inNoteControls = false;
		inCategory = false;
		inControls = false;
		
		for (i in 0...grpCategories.members.length) {
			FlxTween.cancelTweensOf(grpCategories.members[i]);
			FlxTween.tween(grpCategories.members[i], {x: 20}, i * 0.05 + 0.1, {ease: FlxEase.quadInOut});
		}

		FlxG.sound.play(Paths.sound("scrollMenu").getSound());
	}

	public function loadStrum():Void {
		while(grpOptions.length > 3) {grpOptions.remove(grpOptions.members[grpOptions.length - 1], true); }
		while(grpCheckers.length > 3) {grpCheckers.remove(grpCheckers.members[grpCheckers.length - 1], true); }
		
		strumline.changeKeys(curKeys);
		strumline_test.changeKeys(curKeys);

		for (i in 0...strumline.staticnotes.statics.length) {
			var strum = strumline.staticnotes.statics[i];
			strum.x = 20;
			grpOptions.add(strum);

			var newCheck:MenuKeyBind = new MenuKeyBind(20, -100, controls, '$curKeys', i);
			newCheck.x = strum.x + strum.width + 20;
			grpCheckers.add(newCheck);
		}
	}

	public function doClose() {
		Settings.save();
		Language.load();

		canControlle = false;
		FlxG.sound.play(Paths.sound("cancelMenu").getSound());
		FlxTween.tween(curCamera, {alpha: 0}, 1, {onComplete: function(twn) {close(); }});
	}

	override function destroy() {
		super.destroy();
	}
}
