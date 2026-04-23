package objects.songs;

import objects.songs.Song.Song_File;

typedef BPMChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor {
	public var bpm:Float = 100;

	public var crochet:Float = 0; // beats in milliseconds
	public var stepCrochet:Float = 0; // steps in milliseconds

	public var position:Float = 0;
	public var lastPosition:Float = 0;
	public var lastBPMPosition:Float = 0;
	
	public var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = (safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	public var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new(bpm:Int = 100) {
		this.bpm = bpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
	}

	public function mapBPMChanges(song:Song_File) {
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.sections.length) {
			if (song.sections[i].changeBPM && song.sections[i].bpm != curBPM) {
				curBPM = song.sections[i].bpm;

				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};

				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.sections[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}
	public function mapBPMBrute(_list:Array<Dynamic>):Void {
		bpmChangeMap = [];

		var curBPM:Float = bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0..._list.length) {
			if (_list[i].bpm != curBPM) {
				curBPM = _list[i].bpm;

				var deltaSteps:Int = Math.floor(16 * _list[i].sections);

				totalSteps += deltaSteps;
				totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;

				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				
				bpmChangeMap.push(event);
			}
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public function changeBPM(newBpm:Float) {
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
	}

	public function getCurStep():Int {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		
		for (i in 0...bpmChangeMap.length) {
			if (position >= bpmChangeMap[i].songTime) { lastChange = bpmChangeMap[i]; }
		}

		lastBPMPosition = lastChange.songTime;

		return lastChange.stepTime + Math.floor((position - lastChange.songTime) / stepCrochet);
	}
}
