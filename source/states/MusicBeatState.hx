package states;

import flixel.addons.transition.FlxTransitionableState;
import objects.songs.Conductor.BPMChangeEvent;
import openfl.utils.Assets as OpenFlAssets;
import substates.CustomScriptSubState;
import flixel.system.FlxCustomShader;
import flixel.addons.ui.FlxUIState;
import haxe.rtti.CType.Abstractdef;
import substates.MusicBeatSubstate;
import objects.scripts.ScriptList;
import objects.ui.UITabContainer;
import objects.songs.Conductor;
import objects.utils.Controls;
import flixel.tweens.FlxTween;
import substates.FadeSubState;
import objects.scripts.Script;
import flixel.util.FlxTimer;
import flixel.math.FlxRect;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxState;
import utils.Players;
import flixel.FlxG;
import utils.Mods;

using utils.Files;
using StringTools;

class MusicBeatState extends FlxUIState {
	public static var state:MusicBeatState;

	public var conductor:Conductor = new Conductor();

	public var onBack:String;
	public var onConfirm:String;
	
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var controls(get, never):Controls;
	inline function get_controls():Controls { return Players.get(0).controls; }

	private function getControls(_Id:Int):Controls { return Players.get(_Id).controls; }
	
	public var canControlle:Bool = false;

    public var scripts:ScriptList = new ScriptList();

	public var camGame:FlxCamera;
	public var camFGame:FlxCamera;
	public var camBHUD:FlxCamera;
	public var camHUD:FlxCamera;
	public var camFHUD:FlxCamera;
	
	public function new(?onConfirm:String, ?onBack:String) {
		this.onBack = onBack;
		this.onConfirm = onConfirm;

		super();
	}

	override function create() {
		state = this;
		persistentUpdate = false;
				
        FlxG.mouse.visible = false;

		FlxG.game.setFilters([]);
		
		camGame = new FlxCamera();
		camFGame = new FlxCamera();
		camBHUD = new FlxCamera();
		camHUD = new FlxCamera();
		camFHUD = new FlxCamera();

		camFGame.bgColor.alpha = 0;
		camBHUD.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camFHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camFGame);
		FlxG.cameras.add(camBHUD);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camFHUD);

		FlxCamera.defaultCameras = [camGame];
		
		super.create();

		scripts.call('create');

		Files.clearUnusedAssets();
		
		openSubState(new FadeSubState());

		canControlle = true;
	}

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.F1 && FlxG.keys.pressed.SHIFT) { MusicBeatState.switchState("states.MainMenuState", []); return; }

		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0) { stepHit(); }

		if (canControlle) {
			if (controls.check("MenuAccept") && onConfirm != null) { 
				canControlle = false; 
				
				MusicBeatState.switchState(onConfirm, []); 
			}
			if (controls.check("MenuBack") && onBack != null) { 
				canControlle = false; 
				
				FlxG.sound.play(Paths.sound("cancelMenu").getSound()); 
				MusicBeatState.switchState(onBack, []); 
			}
		}

		super.update(elapsed);
		

		scripts.call('update', [elapsed]);

		for (shader in FlxCustomShader.shaders) {
			if (shader == null) { FlxCustomShader.shaders.remove(shader); continue; }
			shader.update(elapsed);
		}
	}

	private function updateBeat():Void { curBeat = Math.floor(curStep / 4); }

	private function updateCurStep():Void {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for (i in 0...conductor.bpmChangeMap.length) {
			if (conductor.position >= conductor.bpmChangeMap[i].songTime) { lastChange = conductor.bpmChangeMap[i]; }
		}

		curStep = lastChange.stepTime + Math.floor((conductor.position - lastChange.songTime) / conductor.stepCrochet);
	}

	public function stepHit():Void {
		if (curStep % 4 == 0) { beatHit(); }

		scripts.call('stepHit', [curStep]);
	}

	public function beatHit():Void {
		scripts.call('beatHit', [curBeat]);
	}
	
	override public function onFocus():Void {
		scripts.call('onFocus');
	}
	override public function onFocusLost():Void {
		scripts.call('onFocusLost');
	}

	public function addScript(_script:Script) {
		_script.parent = this; 		
		scripts.set(_script.name, _script);
	}
	
	public static function getSubState(state:String, args:Array<Any>):MusicBeatSubstate {
		var to_create:Class<FlxSubState> = Type.resolveClass(state) != null ? cast Type.resolveClass(state) : null;
		
		var new_script:Script = null;
		var script_path:{script:String, mod:String} = Paths._script(state.replace(".", "/"));
		if (script_path.script.length > 0 && Paths.exists(script_path.script) && !Mods.unload_states.contains(state)) {
			new_script = new Script();
			new_script.name = state;
			new_script.mod = script_path.mod;
			new_script.load(script_path.script, true);
			if (new_script.getVar('CustomSubState')) {
				to_create = CustomScriptSubState;
				args.insert(0, new_script);
			}
		}
		
		if (to_create == null) { return null; }
		var new_state:MusicBeatSubstate = cast Type.createInstance(to_create, args);
		if (new_script != null && !new_script.getVar('CustomSubState')) { new_script.parent = new_state; new_state.scripts.set(state, new_script); }	

		return new_state;
	}

	public function loadSubState(substate:String, args:Array<Any>):Void {
		var new_substate:FlxSubState = getSubState(substate, args);
		if (new_substate == null) { trace('Null SubState: ${substate}'); return; }
		openSubState(new_substate);
	}

	override function openSubState(SubState:FlxSubState):Void { 
		super.openSubState(SubState);

		scripts.call('onOpenSubState');
	}
	override function closeSubState():Void { 
		super.closeSubState();

		scripts.call('onCloseSubState');
	}

	public static function getState(state:String, args:Array<Any>):MusicBeatState {
		var to_create:Class<FlxState> = Type.resolveClass(state) != null ? cast Type.resolveClass(state) : null;
		
		var new_script:Script = null;
		var script_path:{script:String, mod:String} = Paths._script(state.replace(".", "/"));
		if (script_path.script.length > 0 && Paths.exists(script_path.script)) {
			new_script = new Script();
			new_script.name = state;
			new_script.mod = script_path.mod;
			new_script.load(script_path.script, true);

			if (new_script.getVar('CustomState') && !Mods.unload_states.contains(state)) {
				to_create = CustomScriptState;
				args.insert(0, new_script);
			}
		}

		if (to_create == null) { return null; }
		
		var new_state:MusicBeatState = cast Type.createInstance(to_create, args);	
		if (new_script != null) { 
			new_state.addScript(new_script); 
        	new_state.scripts.m_piorityList.insert(0, new_script.name);
		}
		
		return new_state;
	}

	public static function loadState(state:String, state_args:Array<Any>, load_args:Array<Any>):Void {
		var new_stage:FlxState = getState(state, state_args);
		if (new_stage == null) {trace('Null State: ${state}'); return; }
		load_args.insert(0, new_stage);
		_switchState(getState("states.LoadingState", load_args));
	}

	public static function switchState(state:String, args:Array<Any>):Void {
		var new_stage:FlxState = getState(state, args);
		if (new_stage == null) {trace('Null State: ${state}'); return; }
		_switchState(new_stage);
	}

	public static function _switchState(nextState:FlxState):Void {
		if (state == null) {
			FlxG.switchState(new VoidState(nextState));
		} else {
			state.scripts.call('onCloseState');
			state.canControlle = false;
			
			state.openSubState(new FadeSubState(nextState));
		}
	}
}
