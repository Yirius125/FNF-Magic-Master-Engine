package substates;

import objects.songs.Conductor.BPMChangeEvent;
import flixel.addons.ui.FlxUISubState;
import objects.scripts.ScriptList;
import objects.songs.Conductor;
import objects.utils.Controls;
import objects.scripts.Script;
import states.MusicBeatState;
import flixel.util.FlxColor;
import flixel.FlxSubState;
import flixel.FlxCamera;
import utils.Players;
import flixel.FlxG;
import utils.Mods;

using utils.Files;
using StringTools;

class MusicBeatSubstate extends FlxUISubState {
	public var conductor:Conductor = new Conductor();

	public var onClose:Void->Void = function() {};

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;

	public var curCamera:FlxCamera;
	
	public var controls(get, never):Controls;
	inline function get_controls():Controls { return Players.get(0).controls; }
	private function getControls(_Id:Int):Controls { return Players.get(_Id).controls; }
	public var canControlle:Bool = false;
	
	public var scripts:ScriptList = new ScriptList();

	public function new(onClose:Void->Void = null) {
		if (onClose != null) { this.onClose = onClose; }
		super();
	}

	override function create() {
		curCamera = new FlxCamera();
		curCamera.bgColor.alpha = 0;
		FlxG.cameras.add(curCamera);

		super.create();
		
		this.camera = curCamera;
				
		FlxG.mouse.visible = false;

		scripts.call('create');
	}

	override function update(elapsed:Float) {
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		curBeat = Math.floor(curStep / 4);

		if (oldStep != curStep && curStep > 0) { stepHit(); }

		scripts.call('update', [elapsed]);

		super.update(elapsed);
	}

	private function updateCurStep():Void{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}

		for (i in 0...conductor.bpmChangeMap.length) { if (conductor.position > conductor.bpmChangeMap[i].songTime) { lastChange = conductor.bpmChangeMap[i]; }}
		curStep = lastChange.stepTime + Math.floor((conductor.position - lastChange.songTime) / conductor.stepCrochet);
	}

	public function stepHit():Void {
		if (curStep % 4 == 0) { beatHit(); }

		scripts.call('stepHit', [curStep]);
	}

	public function beatHit():Void {
		//do literally nothing dumbass

		scripts.call('beatHit', [curBeat]);
	}

	public function loadSubState(substate:String, args:Array<Any>):Void {
		var new_substate:FlxSubState = MusicBeatState.getSubState(substate, args);
		if (new_substate == null) {trace('Null SubState: ${substate}'); return; }
		openSubState(new_substate);
	}

	override function close():Void {
		scripts.call('onClose');

		onClose();

		FlxG.cameras.remove(curCamera);
		curCamera.destroy();

		super.close();
	}

	override function destroy() {		
		super.destroy();
	}
}
