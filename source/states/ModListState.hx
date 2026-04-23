package states;

import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.ui.FlxUIGroup;
import objects.menu.MenuButton;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.game.ModCard;
import flixel.FlxSprite;
import flixel.FlxG;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class ModListState extends MusicBeatState {
	public var options:Array<Dynamic> = [
		{ option: "reload", display:"reload", color: 0xff45ff98 },
		{ option: "enableall", display:"enableall", color: 0xff96ff6d },
		{ option: "toggleall", display:"toggleall", color: 0xff6d88ff },
		{ option: "disableall", display:"disableall", color: 0xffff6d6d },
		{ option: "save", display:"save", color: 0xffe26dff },
	];

	public var arrOptions:Array<MenuButton> = [];
	public var gpMods:FlxTypedGroup<ModCard>;
	public var gpOptions:FlxUIGroup;

	public var _onConfirm:String;

	public var curOption:Int = 4;
	public var curMod:Int = 0;
	public var curTab:Int = 1;

	override function create() {
		if (onConfirm != null) { _onConfirm = onConfirm; onConfirm = null; }
		Paths.useMods = false;
		Magic.unload();

		// Updating Discord Rich Presence
		Discord.change("Configuring Mods", null);
		Magic.setWindowTitle('Configuring Mods');

		super.create();
		
        FlxG.sound.playMusic(Paths.music('break_song').getSound());

		var l_background = new FlxSprite().loadGraphic(Paths.image('menuBG').getGraphic());
		l_background.setGraphicSize(FlxG.width, FlxG.height);
        l_background.color = 0xff1eb386;
		l_background.screenCenter();
		add(l_background);

        var backGrid:FlxSprite = FlxGridOverlay.create(50, 50, 100, 100, true, 0x6c000000, 0x13000000);
        var backDrop:FlxBackdrop = new FlxBackdrop(backGrid.pixels);
        backDrop.velocity.set(50, 50);
		add(backDrop);

		gpOptions = new FlxUIGroup();
		gpOptions.cameras = [camHUD];
		add(gpOptions);

		for (option in options) {
			var curButton:MenuButton = new MenuButton(0, 0, Language.getText('opt_${option.display}'), 0.3, option.method, {enableColor: option.color});
			curButton.callAfterTransition = false;
			arrOptions.push(curButton);
			gpOptions.add(curButton);
		}
		
		var backMenu:FlxSprite = Magic.roundRect(0, 0, Std.int(FlxG.width) - 60, Std.int(arrOptions[0].height) + 20, 15, 15, 0x62000000);
		gpOptions.insert(0, backMenu);

		arrOptions[2].setPosition((backMenu.width / 2) - (arrOptions[2].width / 2), 10);
		for (i in 0...arrOptions.length) {
			var curButton:MenuButton = arrOptions[i];
			switch (options[i].option) {
				case "reload": {
					curButton.setPosition(10, 10);
					curButton.callAfterTransition = true;
				}
				case "enableall": {
					curButton.setPosition(arrOptions[2].x - curButton.width - 10, 10); 
				}
				case "disableall": {
					curButton.setPosition(arrOptions[2].x + arrOptions[2].width + 10, 10); 
				}
				case "save": {
					curButton.callAfterTransition = true;
					curButton.setPosition(backMenu.width - curButton.width - 10, 10);
				}
			}
		}

		gpOptions.screenCenter(X);
		gpOptions.y = FlxG.height - gpOptions.height - 30;
		
		gpMods = new FlxTypedGroup<ModCard>();
		gpMods.cameras = [camBHUD];
		createModCards();
		add(gpMods);

		camBHUD.zoom = 0.7;

		changeOption(4, true);
	}

	public function createModCards():Void {
		gpMods.clear();
		
		for (mod in Mods.list) {
			var curModCard:ModCard = new ModCard(0, 30, 426, 570, mod);
			curModCard.showTabId("hidden");

			curModCard.callbacks.set("enable", ()->{
				canControlle = false;
				curModCard.canControlle = true;
				
				curModCard.showTabId("normal");
				curModCard.changeOption(curModCard.options.indexOf(curModCard.optEnable), true);

				FlxTween.cancelTweensOf(gpOptions);
				FlxTween.cancelTweensOf(curModCard);

				FlxTween.tween(gpOptions, {y: FlxG.height + 30}, 0.2, { ease: FlxEase.quadInOut });
				FlxTween.tween(curModCard, {y: (FlxG.height / 2) - (curModCard.height / 2)}, 0.2, { ease: FlxEase.quadInOut });
			});
			curModCard.callbacks.set("disable", ()->{
				canControlle = true;
				curModCard.canControlle = false;

				curModCard.showTabId("hidden");

				FlxTween.cancelTweensOf(gpOptions);
				FlxTween.cancelTweensOf(curModCard);

				FlxTween.tween(curModCard, {y: 30}, 0.2, { ease: FlxEase.quadInOut });
				FlxTween.tween(gpOptions, {y: FlxG.height - gpOptions.height - 30}, 0.2, { ease: FlxEase.quadInOut });
			});

			curModCard.callbacks.set("onLeft", ()->{curMod = curModCard.id; sortMods(); });
			curModCard.callbacks.set("onRight", ()->{curMod = curModCard.id; sortMods(); });

			gpMods.add(curModCard);
		}
	}

	override function update(elapsed:Float) {		
		super.update(elapsed);

        Magic.sortMembersByX(cast gpMods, (FlxG.width / 2), curMod, 30);

		if (!canControlle) { return; }

		switch (curTab) {
			case 0:{
				if (controls.check("MenuDown")) {changeTab(1); }
				if (controls.check("MenuLeft")) {changeMod(-1); }
				if (controls.check("MenuRight")) {changeMod(1); }
				if (controls.check("MenuAccept")) {gpMods.members[curMod].callbacks.get("enable")(); }
			}
			case 1:{
				if (controls.check("MenuUp")) {changeTab(-1); }
				if (controls.check("MenuLeft")) {changeOption(-1); }
				if (controls.check("MenuRight")) {changeOption(1); }
				if (controls.check("MenuAccept")) {chooseOption(); }
			}
		}
	}

	public function sortMods():Void {
		gpMods.members.sort(function(a, b) {
			if (a.id < b.id) return -1;
			else if (a.id > b.id) return 1;
			else return 0;
		});
	}

	public function changeTab(_value:Int = 0, _force:Bool = false):Void {
		curTab = _force ? _value : curTab + _value;
		if (curTab < 0) {curTab = 1; }
		if (curTab > 1) {curTab = 0; }

		switch (curTab) {
			case 0:{
				FlxTween.cancelTweensOf(camBHUD);
				FlxTween.tween(camBHUD, {zoom: 1}, 0.1, {ease: FlxEase.quadInOut});

				for (option in arrOptions) {option.disable(); }
			}
			case 1:{
				FlxTween.cancelTweensOf(camBHUD);
				FlxTween.tween(camBHUD, {zoom: 0.7}, 0.1, {ease: FlxEase.quadInOut});

				for (mod in gpMods) {mod.showTabId("hidden"); }
				arrOptions[curOption].enable();
			}
		}
				
        if (!_force) { FlxG.sound.play(Paths.sound("scrollMenu").getSound(), 0.5); }
	}

	public function changeMod(_value:Int = 0, _force:Bool = false):Void {
		var lastMod = curMod; curMod = _force ? _value : curMod + _value;

		if (curMod < 0) {curMod = Mods.list.length - 1; }
		if (curMod >= Mods.list.length) {curMod = 0; }
		
		if (lastMod != curMod) {
			if (gpMods.members[lastMod].callbacks.exists("unselect")) {gpMods.members[lastMod].callbacks.get("unselect")(); }
			if (gpMods.members[curMod].callbacks.exists("select")) {gpMods.members[curMod].callbacks.get("select")(); }
		}
		
        if (!_force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound(), 0.5); }
	}

	public function changeOption(_value:Int = 0, _force:Bool = false):Void {
		curOption = _force ? _value : curOption + _value;

		if (curOption < 0) { curOption = options.length - 1; }
		if (curOption >= options.length) { curOption = 0; }

		for (option in arrOptions) { option.disable(); }
		arrOptions[curOption].enable();
		
        if (!_force) { FlxG.sound.play(Paths.sound("scrollMenu").getSound(), 0.5); }
	}

	public function chooseOption():Void {
		var cur_option = arrOptions[curOption];
		switch (options[curOption].option) {
			case "reload": {
				canControlle = false;
				Mods.reload();
				
				if (curMod < 0) {curMod = Mods.list.length - 1; }
				if (curMod >= Mods.list.length) {curMod = 0; }
	
				createModCards();
				canControlle = true;
			}
			case "enableall": {
				for (mod in Mods.list) {mod.enabled = true; }
				for (mod in cast(MusicBeatState.state, ModListState).gpMods.members) {
					mod.optEnable.enableColor = 0xff61c54d;
					mod.showTabId("hidden");
				}
			}
			case "toggleall":{
				for (mod in Mods.list) {mod.enabled = !mod.enabled; }
				for (mod in cast(MusicBeatState.state, ModListState).gpMods.members) {
					mod.optEnable.enableColor = mod.mod.enabled ? 0xff61c54d : 0xffc54d4d;
					mod.showTabId("hidden");
				}
			}
			case "disableall":{
				for (mod in Mods.list) {mod.enabled = false; }
				for (mod in cast(MusicBeatState.state, ModListState).gpMods.members) {
					mod.optEnable.enableColor = 0xffc54d4d;
					mod.showTabId("hidden");
				}
			}
			case "save":{
				canControlle = false;
				Paths.useMods = true;
				Magic.reload();
				
				var l_state:String = Mods.getVar("initialState");
				if (l_state == null) { l_state = _onConfirm; }
				if (l_state == null) { l_state = "states.TitleState"; }

				MusicBeatState.switchState(l_state, []);
			}
		}
		cur_option.click();
	}
}