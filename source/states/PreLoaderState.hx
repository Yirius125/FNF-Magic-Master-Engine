package states;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxGridOverlay;
import openfl.utils.Assets as OpenFlAssets;
import flixel.input.gamepad.FlxGamepad;
import flixel.system.ui.FlxSoundTray;
import flixel.addons.ui.FlxUIState;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import objects.utils.Controls;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.FlxSubState;
import io.newgrounds.NG;
import flixel.FlxSprite;
import utils.Highscore;
import flixel.FlxState;
import utils.Language;
import utils.Players;
import openfl.Assets;
import flixel.FlxG;
import utils.Magic;
import haxe.Timer;
import utils.Mods;

#if desktop
import utils.Discord;
import sys.thread.Thread;
import sys.FileSystem;
import sys.io.File;
#end

#if windows
import utils.native.Windows;
#end

import substates.menus.SubMenu;
import substates.menus.LangSubMenu;
import substates.menus.YesNoSubMenu;

import substates.CustomScriptSubState;
import substates.InformationSubState;
import substates.MusicBeatSubstate;
import substates.GameOverSubstate;
import substates.SettingsSubState;
import substates.ResultSubState;
import substates.PauseSubState;
import substates.FadeSubState;

import states.editors.CharacterEditorState;
import states.editors.StageEditorState;
import states.editors.ChartEditorState;
import states.editors.XMLEditorState;
import states.PlayerSelectorState;
import states.CustomScriptState;
import states.MusicBeatState;
import states.StoryMenuState;
import states.FreeplayState;
import states.MainMenuState;
import states.GitarooPause;
import states.LoadingState;
import states.ModListState;
import states.PopLangState;
import states.CreditsState;
import states.PopModState;
import states.TitleState;
import states.PlayState;
import states.VoidState;

import objects.notes.NoteSplash;

using StringTools;

class PreLoaderState extends FlxUIState {
	public var nextState:Array<Dynamic> = ["states.TitleState", []];
	public var subStateList:Array<Dynamic> = [];

	override public function create():Void {		
		FlxG.autoPause = false;
		Paths.useMods = false;
		
		super.create();
		
    	FlxG.mouse.visible = false;

		FlxAssets.FONT_DEFAULT = "assets/fonts/funkin.ttf";
		
		#if windows Windows.resetBorderColor(); #end
		Players.init();

		if (!FlxG.save.data.first) { subStateList.push(["substates.menus.LangSubMenu", [()->{ FlxG.resetState(); }]]); }
		if (!Mods.same()) { subStateList.push(["substates.menus.YesNoSubMenu", [
			Language.get("mod_advert"), 
			()->{
				nextState[0] = "states.ModListState";
				nextState[1] = ["states.MainMenuState"];
			}, 
			()->{ }
		]]); }

		checkSubMenu();
	}

	override function closeSubState():Void {
		super.closeSubState();

		Timer.delay(()->{ checkSubMenu(); }, 300);		
	}

	public function checkSubMenu():Void {
		if (subStateList.length > 0) {
			var cur_menu = subStateList.shift();
			loadSubState(cur_menu[0], cur_menu[1]);
			
			return;
		}
		
		Paths.useMods = true;		
		Magic.reload(); 

		if (nextState[0] == "states.TitleState") {
			var l_modState:String = Mods.getVar("initialState");
			if (l_modState != null) { nextState[0] = l_modState; }
		}

		MusicBeatState.switchState(nextState[0], nextState[1]);
	}

	public function loadSubState(substate:String, args:Array<Any>):Void {
		var to_create:Class<FlxSubState> = Type.resolveClass(substate) != null ? cast Type.resolveClass(substate) : null;
		if (to_create == null) { trace("Null SubState"); return; }
		var new_substate:FlxSubState = cast Type.createInstance(to_create, args);
		openSubState(new_substate);
	}
}