package utils;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.AssetManifest;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetLibrary;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import haxe.format.JsonParser;
import flixel.math.FlxPoint;
import flash.geom.Rectangle;
import flixel.math.FlxRect;
import flash.media.Sound;
import haxe.xml.Access;
import haxe.io.Bytes;
import haxe.io.Path;
import flixel.FlxG;
import haxe.Json;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Paths {
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	public static var useMods:Bool = true;
		
	public static function format(key:String, toFile:Bool = false) {
		if (toFile) { return key.replace(" ", "_"); }
		return key.replace("_", " ");
	}

	public static function setPath(key):String { return #if sys FileSystem.absolutePath(key) #else key #end; }
	public static function getPath(file:String, type:AssetType, ?library:String, ?mod_name:String) {
		if (mod_name != null) { return getModPath(file, mod_name); }
		if (library != null) { return getLibraryPath(file, library); }

		var levelPath = getLibraryPathForce(file, "shared");
		if (Paths.exists(levelPath)) { return levelPath; }

		return getForcedPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload") {
		return if (library == "preload" || library == "default") getForcedPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String) {
		var path = getForcedPath('$library/$file');
		if (!Paths.exists(path)) {path = '$library:assets/$library/$file'; }
		return path;
	}

	inline static function getForcedPath(file:String) {
		var path = '';
		for (mod in Mods.list) {
			if (!useMods) {break; }
			if (!mod.enabled) { continue; }
			path = '${mod.path}/assets/$file';
			if (mod.exclusive #if sys || FileSystem.exists(path) #end) {break; }
		}
		if (!OpenFlAssets.exists(path) #if sys && !FileSystem.exists(path) #end) {path = 'assets/$file'; }
		return path;
	}
	inline static function getModPath(file:String, mod_name:String) {
		var path = '';
		for (mod in Mods.list) {
			if (mod.name != mod_name) { continue; }
			path = '${mod.path}/assets/$file';
			break;
		}
		if (!OpenFlAssets.exists(path) #if sys && !FileSystem.exists(path) #end) {path = 'assets/$file'; }
		return path;
	}

	inline public static function exists(path:String) {
		if (OpenFlAssets.exists(path)) { return true; }
		#if sys	if (FileSystem.exists(setPath(path))) { return true; } #end
		return false;
	}

	inline public static function readDirectory(file:String):Array<String> {
		var toReturn:Array<String> = [];

		#if sys
		var _path:String = setPath(file);

		if (FileSystem.exists(_path) && FileSystem.isDirectory(_path)) {
			for (i in FileSystem.readDirectory(_path)) {
				var cur_path:String = '$_path/$i';
				if (toReturn.contains(i)) { continue; }
				toReturn.push(cur_path);
			}
		}
		
		for (mod in Mods.list) {
			var mod_path:String = setPath('${mod.path}/$file');
			if (!mod.enabled || !FileSystem.exists(mod_path) || !FileSystem.isDirectory(mod_path)) { continue; }
			for (i in FileSystem.readDirectory(mod_path)) {
				var cur_path:String = '$mod_path/$i';
				if (toReturn.contains(cur_path)) { continue; }
				toReturn.push(cur_path);
			}
			if (mod.exclusive) {break; }
		}
		#end

		return toReturn;
	}

	inline public static function readFile(file:String):Array<String> {
		var toReturn:Array<String> = [];

		#if sys
		if (FileSystem.exists(setPath(file))) {toReturn.push(setPath(file)); }
		for (mod in Mods.list) {
			var _path = setPath('${mod.path}/$file');
			if (mod.enabled && FileSystem.exists(_path)) {toReturn.push(_path);
			if (mod.exclusive) {break; }}
		}
		#end

		return toReturn;
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String, ?mod:String):String { return getPath(file, type, library, mod); }
	inline static public function sound(key:String, ?library:String, ?mod:String):String { return getPath('sounds/$key.$SOUND_EXT', SOUND, library, mod); }
	inline static public function music(key:String, ?library:String, ?mod:String):String { return getPath('music/$key.$SOUND_EXT', MUSIC, library, mod); }
	inline static public function video(key:String, ?library:String, ?mod:String):String { return getPath('videos/$key.mp4', MOVIE_CLIP, library, mod); }
	inline static public function shader(key:String, ?library:String, ?mod:String):String { return getPath('shaders/$key.frag', TEXT, library, mod); }
	inline static public function image(key:String, ?library:String, ?mod:String):String { return getPath('images/$key.png', IMAGE, library, mod); }
	inline static public function icon(key:String, ?library:String, ?mod:String):String { return getPath('images/$key.ico', IMAGE, library, mod); }
	inline static public function song(song:String, key:String, ?mod:String):String { return getPath('songs/${song}/${key}', TEXT, 'data', mod); }
	inline static public function json(key:String, ?library:String, ?mod:String):String { return getPath('data/$key.json', TEXT, library, mod); }
	inline static public function xml(key:String, ?library:String, ?mod:String):String { return getPath('images/$key.xml', TEXT, library, mod); }
	inline static public function txt(key:String, ?library:String, ?mod:String):String { return getPath('data/$key.txt', TEXT, library, mod); }
	inline static public function text(key:String, ?library:String, ?mod:String):String { return getPath('data/$key', TEXT, library, mod); }
	inline static public function script(key:String, ?mod:String):String { return getPath('scripts/$key.hx', TEXT, 'data', mod); }
	inline static public function preset(key:String, ?mod):String { return getPath('notes/${key}.json', TEXT, 'data'); }
	inline static public function font(key:String, ?mod:String):String { return getPath('$key', TEXT, 'fonts', mod); }
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String, ?mod:String):String {
		return sound(key + FlxG.random.int(min, max), library, mod);
	}
	inline static public function styleImage(key:String, style:String = "Default", ?library:String, ?mod:String):String {
		var path = getPath('images/styles/$style/$key.png', IMAGE, library, mod);
		if (!Paths.exists(path)) {path = getPath('images/styles/Default/$key.png', IMAGE, library, mod); }
		return path;
	}
	inline static public function styleSound(key:String, style:String = "Default", ?library:String, ?mod:String):String {
		var path = getPath('sounds/styles/$style/$key.$SOUND_EXT', SOUND, library, mod);
		if (!Paths.exists(path)) {path = getPath('sounds/styles/Default/$key.$SOUND_EXT', SOUND, library, mod); }
		return path;
	}
	inline static public function styleMusic(key:String, style:String = "Default", ?library:String, ?mod:String):String {
		var path = getPath('music/styles/$style/$key.$SOUND_EXT', MUSIC, library, mod);
		if (!Paths.exists(path)) {path = getPath('music/styles/Default/$key.$SOUND_EXT', SOUND, library, mod); }
		return path;
	}	
	inline static public function inst(song:String, category:String, ?mod:String):String {
		var path = getPath('${song}/Inst-${category}.$SOUND_EXT', MUSIC, 'songs', mod);
		if (!Paths.exists(path)) {path = getPath('${song}/Inst.$SOUND_EXT', MUSIC, 'songs', mod); }
		return path;
	}
	inline static public function voice(id:Int, char:String, song:String, category:String, ?mod:String):String {
		var path = getPath('${song}/${id}-${char}-${category}.$SOUND_EXT', SOUND, 'songs', mod);
		if (!Paths.exists(path)) {path = getPath('${song}/${id}-Default-${category}.$SOUND_EXT', SOUND, 'songs', mod); }
		if (!Paths.exists(path)) {path = getPath('${song}/${id}-${char}.$SOUND_EXT', SOUND, 'songs', mod); }
		if (!Paths.exists(path)) {path = getPath('${song}/${id}-Default.$SOUND_EXT', SOUND, 'songs', mod); }
		if (!Paths.exists(path) && id == 0) {path = getPath('${song}/Voices-${category}.$SOUND_EXT', SOUND, 'songs', mod); }
		if (!Paths.exists(path) && id == 0) {path = getPath('${song}/Voices.$SOUND_EXT', SOUND, 'songs', mod); }
		return path;
	}
	inline static public function chart(jsonInput:String, ?mod:String):String {
		var song_name:String = jsonInput.split('-')[0];
		var song_cat:String = jsonInput.split('-')[1];
		var song_diff:String = jsonInput.split('-')[2];

		var path = getPath('songs/${song_name}/${jsonInput}.json', TEXT, 'data', mod);
		if (!Paths.exists(path)) {path = getPath('songs/${song_name}/${song_name}-${song_diff}.json', TEXT, 'data', mod); }
		if (!Paths.exists(path)) {path = getPath('songs/${song_name}/${song_name}.json', TEXT, 'data', mod); }
		if (!Paths.exists(path)) {path = getPath('songs/Test/Test-Normal-Normal.json', TEXT, 'data', mod); }
		return path;
	}
	inline static public function events(jsonInput:String, ?mod:String):String {
		var song_name:String = jsonInput.split('-')[0];
		var song_cat:String = jsonInput.split('-')[1];

		var path = getPath('songs/${song_name}/Events-${song_cat}.json', TEXT, 'data', mod);
		if (!Paths.exists(path)) {path = getPath('songs/${song_name}/Events-Default.json', TEXT, 'data', mod); }
		if (!Paths.exists(path)) { path = getPath('songs/Test/Events-Default.json', TEXT, 'data', mod); }

		return path;
	}
	inline static public function handlers(jsonInput:String, ?mod:String):String {
		var song_name:String = jsonInput.split('-')[0];
		var song_cat:String = jsonInput.split('-')[1];

		var path = getPath('songs/${song_name}/Handlers-${song_cat}.hx', TEXT, 'data', mod);
		if (!Paths.exists(path)) {path = getPath('songs/${song_name}/Handlers-Default.hx', TEXT, 'data', mod); }

		return path;
	}
	inline static public function dialogue(song:String, ?mod:String):String {
		var language = Settings.get("Language");
		var path = getPath('songs/${song}/${language}_dialog.json', TEXT, 'data', mod);
		if (!Paths.exists(path)) {path = getPath('songs/${song}/Default_dialog.json', TEXT, 'data', mod); }
		return path;
	}
	inline static public function stage(key:String, ?mod:String):String {
		var path = getPath('stages/${key}.hx', TEXT, 'data', mod);
		if (!Paths.exists(path)) {path = getPath('stages/Stage.hx', TEXT, 'data', mod); }
		return path;
	}
	inline static public function note(image:String, style:String, ?type:String, ?mod:String):String {
		if (type == null) {type = Settings.get("NoteSkin"); }
		var path:String = getPath('images/notes/${type}/${style}/${image}.png', IMAGE, 'shared', mod);
		if (!Paths.exists(path)) {path = getPath('images/notes/${type}/Default/${image}.png', IMAGE, 'shared', mod); }
		if (!Paths.exists(path)) {path =  getPath('images/notes/Default/Default/${image}.png', IMAGE, 'shared', mod); }
		return path;
	}
	inline static public function event(key:String, stage:Null<String>, song:Null<String>, ?mod:String):String {
		var path = getPath('events/general/${key}.hx', TEXT, 'data', mod);
		if (!Paths.exists(path)) { path = getPath('events/note/${key}.hx', TEXT, 'data', mod); }
		if (!Paths.exists(path) && stage != null) { path = getPath('events/stage/${stage}/${key}.hx', TEXT, 'data', mod); }
		if (!Paths.exists(path) && song != null) { path = getPath('events/song/${song}/${key}.hx', TEXT, 'data', mod); }
		return path;
	}	
	inline static public function strum_keys(keys:Int, ?type:String):String {
		if (type == null) {type = Settings.get("NoteSkin"); }
		var path = getPath('notes/${type}/${keys}k.json', TEXT, 'data');
		if (!Paths.exists(path)) {path = getPath('notes/${type}/_k.json', TEXT, 'data'); }
		if (!Paths.exists(path)) {path = getPath('notes/Default/${keys}k.json', TEXT, 'data'); }
		if (!Paths.exists(path)) {path = getPath('notes/Default/_k.json', TEXT, 'data'); }
		return path;
	}
	inline static public function character(char:String, asp:String, ?type:String, ?mod:String):String {
		var type_char:String = ''; if (type != null) {type_char = '-${type}'; }
		var path = getPath('characters/${char}/${char}-${asp}${type_char}.json', TEXT, 'data', mod);
		if (!Paths.exists(path)) { path = getPath('characters/${char}/${char}-${asp}${type_char}.json', TEXT, 'data', mod); }
		if (!Paths.exists(path)) { path = getPath('characters/${char}/${char}-Default${type_char}.json', TEXT, 'data', mod); }
		if (!Paths.exists(path)) { path = getPath('characters/Boyfriend/Boyfriend-Default${type_char}.json', TEXT, 'data', mod); }
		return path;
	}
	inline static public function _character(char:String, key:String, type:AssetType = TEXT, ?mod:String):String {
		return getPath('characters/${char}/${key}', type, 'data', mod);
	}
	inline static public function _script(key:String, ?mod_name:String):{script:String, mod:String} {
		var path:String = ""; var cur_mod_name:String = "";

		for (mod in Mods.list) {
			if (!mod.enabled || (mod_name != null && mod.name != mod_name)) { continue; }

			path = '${mod.path}/scripts/${key}.hx';
			cur_mod_name = mod.name;
			
			if (mod.exclusive #if sys || FileSystem.exists(path) #end) { break; }
		}
		
		return { script: path, mod: cur_mod_name };
	}
}
