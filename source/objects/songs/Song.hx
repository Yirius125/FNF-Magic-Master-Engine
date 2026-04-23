package objects.songs;

import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import haxe.format.JsonParser;
import openfl.events.Event;
import objects.notes.Note;
import haxe.DynamicAccess;
import lime.utils.Assets;
import haxe.Exception;
import flixel.FlxG;
import haxe.Json;

#if desktop
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

typedef Song_File = {
	var song:String;
	var category:String;
	var difficulty:String;

	var bpm:Float;
	var speed:Float;

	var voices:Bool;

	var player:Int;

	var style:String;

	var stage:String;
	var characters:Array<Dynamic>;

	var sections:Array<GeneralSection_Data>;
	var strums:Array<Strum_Data>;
	var events:Array<Dynamic>;
}

typedef Event_File = {
	var events:Array<Dynamic>;
}

typedef Strum_Data = {
	var friendly:Bool;
	var playable:Bool;
	var style:String;
	var keys:Int;
	var characters:Array<Int>;
	var sections:Array<Section_Data>;
}

typedef Section_Data = {
	var notes:Array<Dynamic>;

	var characters:Array<Int>;
	var changeCharacters:Bool;

	var changeAlt:Bool;
}

typedef GeneralSection_Data = {
	var bpm:Float;
	var changeBPM:Bool;
	
	var lengthInSteps:Int;

	var strum:Int;
	var character:Int;
}

class Song {
	public static function format(name:String, category:String, difficulty:String):String {
		var format_name:String = Paths.format(name, true);
		format_name += '-' + Paths.format(category, true);
		format_name += '-' + Paths.format(difficulty, true);
		return format_name;
	}
	public static function getNameData(json_name:String):{name:String, category:String, difficulty:String} {
		var toReturn:{name:String, category:String, difficulty:String} = {name: "Test", category: "Normal", difficulty: "Normal"};
		var data_array:Array<String> = json_name.split("-");

		toReturn.name = data_array[0] != null ? data_array[1] : "Test";
		toReturn.category = data_array[1] != null ? data_array[1] : "Normal";
		toReturn.difficulty = data_array[2] != null ? data_array[2] : "Normal";

		return toReturn;
	}

	public static function load(format_song:String):Song_File {
		if (format_song == null) {format_song = "Test-Normal-Normal"; }

		var rawJson:String = Paths.chart(format_song).getText().trim();
		var rawEvents:String = Paths.events(format_song).getText().trim();

		while(!rawJson.endsWith("}") && rawJson.length > 0) {rawJson = rawJson.substr(0, rawJson.length - 1); }
		while(!rawEvents.endsWith("}") && rawEvents.length > 0) {rawEvents = rawEvents.substr(0, rawEvents.length - 1); }
		
		var song:Song_File = convert_song(format_song, rawJson);
		var events:Event_File = convert_events(rawEvents);
		parse(song, events);

		return song;
	}

	public static function convert_events(rawEvents:String):Event_File {
		var dynamic_events:Dynamic = cast Json.parse(rawEvents);

		if (dynamic_events.events == null) { dynamic_events.events = []; }

		var song_events:Event_File = cast dynamic_events;

		if (song_events.events == null) { song_events.events = []; }

		return song_events;
	}
	public static function convert_song(json_name:String, rawSong:String):Song_File {
		var _global_song:Dynamic = cast Json.parse(rawSong);
		if (_global_song.song == null) { _global_song.song = {}; }

		var data_name = getNameData(json_name);

		var dynamic_data:Dynamic = _global_song.song;

		if (dynamic_data.song == null) { dynamic_data.song = data_name.name; }
		if (dynamic_data.category == null) { dynamic_data.category = data_name.category; }
		if (dynamic_data.difficulty == null) { dynamic_data.difficulty = data_name.difficulty; }
		
		if (dynamic_data.player == null) { dynamic_data.player = 1; }

		if (dynamic_data.bpm == null) { dynamic_data.bpm = 100; }
		if (dynamic_data.speed == null) { dynamic_data.speed = 1; }
		if (dynamic_data.stage == null) { dynamic_data.stage = "Stage"; }
		
		if (dynamic_data.style == null) { dynamic_data.style = "Default"; }
		
		if (dynamic_data.voices == null) { dynamic_data.voices = dynamic_data.needsVoices != null ? dynamic_data.needsVoices : true; }
		
		if (dynamic_data.characters == null) {
			dynamic_data.characters = [
				["Girlfriend", [540,50], 1, false, "Default", "GF", 0],
				["Daddy_Dearest", [100, 100], 1, true, "Default", "DAD", 0],
				["Boyfriend", [770, 100], 1, false, "Default", "BF", 0]
			];

			if (dynamic_data.gfVersion != null) { dynamic_data.characters[0][0] = dynamic_data.gfVersion; dynamic_data.gfVersion = null; }
			else if (dynamic_data.player3 != null) { dynamic_data.characters[0][0] = dynamic_data.player3; dynamic_data.player3 = null; }
			else if (dynamic_data.gf != null) { dynamic_data.characters[0][0] = dynamic_data.gf; dynamic_data.gf = null; }

			if (dynamic_data.player2 != null) { dynamic_data.characters[1][0] = dynamic_data.player2; dynamic_data.player2 = null; }
			if (dynamic_data.player1 != null) { dynamic_data.characters[2][0] = dynamic_data.player1; dynamic_data.player1 = null; }
		}

		if (dynamic_data.strums == null) {
			dynamic_data.strums = [
				{playable: true, style: "Default", keys: 4, characters: [1], sections: []},
				{playable: true, style: "Default", keys: 4, characters: [2], sections: []}
			];

			if (dynamic_data.notes != null) {
				for (section in cast(dynamic_data.notes, Array<Dynamic>)) {
					var dad_section:Section_Data = {characters: [], changeCharacters: false, changeAlt: section.altAnim, notes: []};
					var bf_section:Section_Data = {characters: [], changeCharacters: false, changeAlt: section.altAnim, notes: []};

					for (note in cast(section.sectionNotes, Array<Dynamic>)) {
						if (section.mustHitSection) {
							if (note[1] < 4) {
								bf_section.notes.push(note);
							} else if (note[1] > 3) {
								note[1] = note[1] % 4;
								dad_section.notes.push(note);
							}
						} else{
							if (note[1] < 4) {
								dad_section.notes.push(note);
							} else if (note[1] > 3) {
								note[1] = note[1] % 4;
								bf_section.notes.push(note);
							}
						}
					}

					dynamic_data.strums[0].sections.push(dad_section);
					dynamic_data.strums[1].sections.push(bf_section);
				}
			}
		}

		if (dynamic_data.sections == null) {
			dynamic_data.sections = [];

			if (dynamic_data.notes != null) {
				for (section in cast(dynamic_data.notes, Array<Dynamic>)) {
					dynamic_data.sections.push({
						bpm: section.bpm != null ? section.bpm : dynamic_data.bpm,
						changeBPM: section.changeBPM != null ? section.changeBPM : false,
						lengthInSteps: section.lengthInSteps != null ? section.lengthInSteps : 16,
						strum: section.mustHitSection ? 1 : 0,
						character: 0
					});
				}
			}
		}

		if (dynamic_data.notes != null) { dynamic_data.notes = null; }
		
		if (dynamic_data.events == null) { dynamic_data.events = []; }

		return cast dynamic_data;
	}

	public static function parse(song_data:Song_File, ?event_data:Event_File):Void {
		if (song_data.song == null) { song_data.song = "Test"; }
		if (song_data.category == null) { song_data.category = "Normal"; }
		if (song_data.difficulty == null) { song_data.difficulty = "Normal"; }

		if (song_data.bpm <= 0) { song_data.bpm = 100; }
		if (song_data.speed <= 0) { song_data.speed = 3; }
		
		if (song_data.style == null) { song_data.style = "Default"; }
		if (song_data.stage == null) { song_data.stage = "Stage"; }
		
		if (song_data.characters == null) {
			song_data.characters = [
				["Girlfriend", [540,50], 1, false, "Default", "GF", 0],
				["Daddy_Dearest", [100, 100], 1, true, "Default", "OPP", 0],
				["Boyfriend", [770, 100], 1, false, "Default", "BF", 0]
			];
		}

		if (song_data.strums == null) { song_data.strums = []; }
		if (song_data.strums.length <= 0) { song_data.strums.push({ friendly: false, playable: true, style: "Default", keys: 4, characters:[], sections:[] }); }
		
		if (song_data.sections == null) { song_data.sections = []; }
		while (song_data.sections.length < song_data.strums[0].sections.length) { song_data.sections.push({bpm: song_data.bpm, changeBPM: false, lengthInSteps: 16, strum: 0, character: 0}); }
		
		for (strum in song_data.strums) {
			if (strum.keys <= 0) { strum.keys = 4; }
			if (strum.style == null) { strum.style = "Default"; }
			if (strum.characters == null) { strum.characters = []; }

			if (strum.sections == null) { strum.sections = []; } else {
				for (section in strum.sections) {
					if (section.characters == null) { section.characters = []; }
					if (section.notes == null) { section.notes = []; } else { for (note in section.notes) { Note.set_note(note, Note.convNoteData(Note.getNoteData(note))); } }
				}
			}
		}

		for (section in song_data.sections) { if (section.lengthInSteps <= 0) { section.lengthInSteps = 16; } }

		if (song_data.events == null) { song_data.events = []; }

		if (event_data != null) {
			for (event in event_data.events) {
				var cur_data = Note.getEventData(event);
				cur_data.isExternal = true;

				Note.set_note(event, Note.convEventData(cur_data));

				var has_note:Bool = false;
				for (check_event in song_data.events) { if (Note.compare(cur_data, Note.getEventData(check_event), false)) { has_note = true; break; } }
				if (has_note) { continue; }

				song_data.events.push(event);
			}
		}
	}
}