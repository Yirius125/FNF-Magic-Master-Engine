package utils;

import objects.notes.StrumLine.StrumLine_Graphic_Data;
import openfl.display3D.textures.RectangleTexture;
import objects.notes.StrumNote.Note_Graphic_Data;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.system.System;
import openfl.utils.Assets;
import flash.media.Sound;
import haxe.xml.Access;
import haxe.io.Path;
import flixel.FlxG;
import haxe.Json;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Files {
	public static var savedTempMap:Map<String, {asset_type:AssetType, asset:Dynamic}> = new Map<String, {asset_type:AssetType, asset:Dynamic}>();
	public static var savedGraphicMap:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();
	public static var savedBitMap:Map<String, BitmapData> = new Map<String, BitmapData>();
	public static var savedSoundMap:Map<String, Sound> = new Map<String, Sound>();
	public static var staticAssets:Array<String> = [];
	public static var usedAssets:Array<String> = [];

	public static function clearUnusedAssets() {
		for (key in savedGraphicMap.keys()) {
			if (staticAssets.contains(key)) { continue; }
			if (usedAssets.contains(key)) { continue; }

			var cur_asset = savedGraphicMap.get(key);
			if (cur_asset == null) { continue; }

			@:privateAccess openfl.Assets.cache.removeBitmapData(key);
			@:privateAccess FlxG.bitmap._cache.remove(key);
			
			if (Reflect.hasField(cur_asset, 'destroy')) {cur_asset.destroy(); }
			savedGraphicMap.remove(key);
		}

		for (key in savedSoundMap.keys()) {
			if (staticAssets.contains(key)) { continue; }
			if (usedAssets.contains(key)) { continue; }

			var cur_asset = savedSoundMap.get(key);
			if (cur_asset == null) { continue; }

			@:privateAccess openfl.Assets.cache.removeSound(key);
			
			savedSoundMap.remove(key);
		}

		for (key in savedTempMap.keys()) {
			if (staticAssets.contains(key)) { continue; }
			if (usedAssets.contains(key)) { continue; }

			var cur_asset = savedTempMap.get(key);
			if (cur_asset == null) { continue; }

			@:privateAccess
				switch (cur_asset.asset_type) {
					default: { }
					case FONT: { openfl.Assets.cache.removeFont(key); }
				}
			
			if (Reflect.hasField(cur_asset.asset, 'destroy')) {cur_asset.asset.destroy(); }
			savedTempMap.remove(key);
		}

		System.gc();
	}
	public static function clearMemoryAssets():Void {
		@:privateAccess
			for (key in FlxG.bitmap._cache.keys()) {
				if (FlxG.keys.pressed.CONTROL) { continue; }
				if (staticAssets.contains(key)) { continue; }

				var cur_asset = FlxG.bitmap._cache.get(key);
				if (cur_asset == null) { continue; }
				//trace('Clearing $key');
				
				savedBitMap.remove(key);
				savedGraphicMap.remove(key);
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				cur_asset.destroy();
			}

			for (key in savedSoundMap.keys()) {
				if (FlxG.keys.pressed.CONTROL) { continue; }
				if (staticAssets.contains(key)) { continue; }

				var cur_saved = savedSoundMap.get(key);
				if (cur_saved == null || usedAssets.contains(key)) { continue; }

				openfl.Assets.cache.clear(key);
				savedSoundMap.remove(key);
			}

			for (key in savedTempMap.keys()) {
				if (staticAssets.contains(key)) { continue; }

				var cur_saved = savedTempMap.get(key);
				if (cur_saved == null || usedAssets.contains(key)) { continue; }

				savedTempMap.remove(key);
				if (Reflect.hasField(cur_saved.asset, 'destroy')) {cur_saved.asset.destroy(); }
			}

		usedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function isSaved(file:String, ?asset_type:AssetType):Bool {
		switch (asset_type) {
			default:{ return savedTempMap.exists(file); }
			case SOUND, MUSIC:{ return savedSoundMap.exists(file); }
			case IMAGE:{ return savedGraphicMap.exists(file); }
		}
		return false;
	}
	public static function getSavedFile(file:String, ?asset_type:AssetType):Any {
		switch (asset_type) {
			default: { if (savedTempMap.exists(file)) { return savedTempMap.get(file).asset; }}
			case IMAGE: { if (savedGraphicMap.exists(file)) { return savedGraphicMap.get(file); }}
			case SOUND, MUSIC: { if (savedSoundMap.exists(file)) { return savedSoundMap.get(file); }}
		}

		return null;
	}
	inline static public function saveFile(file:String, instance:Any, ?asset_type:AssetType, isStatic:Bool = false):Void {
		if (isStatic) { staticAssets.push(file); }
		usedAssets.push(file);

		switch (asset_type) {
			default: { savedTempMap.set(file, {asset_type: asset_type, asset: instance}); }
			case SOUND, MUSIC: { savedSoundMap.set(file, instance); }
			case IMAGE: { savedGraphicMap.set(file, instance); }
		}
		
		//trace('Saved $file');
	}
	inline static public function unsaveFile(file:String, ?asset_type:AssetType):Void {
		if (staticAssets.contains(file)) { return; }

		switch (asset_type) {
			default: {
				var asset = savedTempMap.get(file);
				if (asset == null) { return; }
				savedTempMap.remove(file);
				if (Reflect.hasField(asset.asset, 'destroy')) {asset.asset.destroy(); }
			}
			case IMAGE: {
				var asset = savedGraphicMap.get(file);
				if (asset == null) { return; }
				savedGraphicMap.remove(file);
				asset.destroy();
			}
			case SOUND, MUSIC: {
				var asset = savedSoundMap.get(file);
				if (asset == null) { return; }
				savedSoundMap.remove(file);
			}
		}
	}

	inline public static function getSound(file:String, isStatic:Bool = false):Sound {
		if (isSaved(file, SOUND)) { return getSavedFile(file, SOUND); }
		if (!Paths.exists(file)) { return null; }

		saveFile(file, OpenFlAssets.exists(file) ? OpenFlAssets.getSound(file) : Sound.fromFile(file), SOUND, isStatic);
		
		return getSavedFile(file, SOUND);
	}
	inline public static function getBytes(file:String, isStatic:Bool = false):Any {
		if (isSaved(file, BINARY)) { return getSavedFile(file, BINARY); }
		if (!Paths.exists(file)) { return null; }
		#if sys
		saveFile(file, OpenFlAssets.exists(file) ? OpenFlAssets.getBytes(file) : File.getBytes(file), BINARY, isStatic);
		#else
		saveFile(file, OpenFlAssets.getBytes(file), BINARY, isStatic);
		#end
		return getSavedFile(file, BINARY);
	}
	public static function getBitmap(file:String, isStatic:Bool = false):BitmapData { 
		if (isSaved(file, IMAGE)) { return cast(getSavedFile(file, IMAGE), FlxGraphic).bitmap; }
		if (savedBitMap.exists(file)) { return savedBitMap.get(file); }
		if (!Paths.exists(file)) { return null; }

		var l_bitmap:BitmapData = OpenFlAssets.exists(file) ? OpenFlAssets.getBitmapData(file) : BitmapData.fromFile(file);

		savedBitMap.set(file, l_bitmap);
		return l_bitmap;
	}
	public static function getGraphic(file:String, forceCPU:Bool = false, isStatic:Bool = false):Any {
		if (isSaved(file, IMAGE)) { return getSavedFile(file, IMAGE); }
		if (!Paths.exists(file)) { return null; }
		
		var bitmap:BitmapData = Files.getBitmap(file);
		if (bitmap == null) { return null; }

		if (Settings.get("UseGpu") && !forceCPU) {
			var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, false);
			texture.uploadFromBitmapData(bitmap);
			bitmap.dispose();
			savedBitMap.remove(file);
			
			bitmap = BitmapData.fromTexture(texture);
		}

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file, true);
		graphic.destroyOnNoUse = false;
		graphic.persist = true;
		
		saveFile(file, graphic, IMAGE, isStatic);
		return getSavedFile(file, IMAGE);
	}
	inline public static function getText(file:String, isStatic:Bool = false):String {
		if (isSaved(file, TEXT)) { return getSavedFile(file, TEXT); }
		if (!Paths.exists(file)) {trace('$file no exist'); return null; }

		#if sys
		saveFile(file, OpenFlAssets.exists(file) ? OpenFlAssets.getText(file) : File.getContent(file), TEXT, isStatic);
		#else
		saveFile(file, OpenFlAssets.getText(file), TEXT, isStatic);
		#end
		return getSavedFile(file, TEXT);
	}

	inline static public function getSparrowAtlas(path:String, forceCPU:Bool = false, isStatic:Bool = false):FlxAtlasFrames {
		path = path.replace(".png", "").replace('.xml', '');

		var bit = getGraphic('$path.png', forceCPU, isStatic);
		var xml = getText('$path.xml', isStatic);

		if (bit == null || xml == null) { return null; }
		return FlxAtlasFrames.fromSparrow(bit, xml);
	}

	inline static public function getPackerAtlas(path:String, forceCPU:Bool = false, isStatic:Bool = false):FlxAtlasFrames {
		path = path.replace(".png", "").replace('.txt', '');

		var bit = getGraphic('$path.png', forceCPU, isStatic);
		var txt = getText('$path.txt', isStatic);

		if (bit == null || txt == null) { return null; }
		return FlxAtlasFrames.fromSpriteSheetPacker(bit, txt);
	}

	static public function getAtlas(path:String, forceCPU:Bool = false, isStatic:Bool = false):FlxAtlasFrames {
		path = path.replace(".png", "").replace(".xml", "").replace(".txt", "");

		if (Paths.exists('${path}.xml')) { return getSparrowAtlas('$path.xml', forceCPU, isStatic); }
		else if (Paths.exists('${path}.txt')) { return getPackerAtlas('$path.txt', forceCPU, isStatic); }

		return null;
	}
	
	inline static public function getJson(path:String, isStatic:Bool = false):Dynamic {
		var text = getText(path, isStatic);
		if (text == null) { return null; }
		return Json.parse(text.trim());
	}

	inline static public function getColorNote(key:String):String {
		var fileName:String = key.split("/").pop();
		var note_path:String = key.replace(fileName, "colors.json");
		if (!Paths.exists(note_path)) { return "None"; }

		var colorData:Dynamic = Files.getJson(note_path);

		return Reflect.hasField(colorData, fileName) ? Reflect.getProperty(colorData, fileName) : "None";
	}
	inline static public function getDataNote(data:Int, keys:Int, ?type:String, ?style:String = "Default"):Note_Graphic_Data {
		if (type == null) {type = Settings.get("NoteSkin"); }
		var j_strum:StrumLine_Graphic_Data = getJson(Paths.strum_keys(keys, type, style));
		var j_note:Note_Graphic_Data = j_strum.gameplay_notes.notes[(data % (keys)) % (j_strum.gameplay_notes.notes.length)];
		if (j_strum.gameplay_notes.general_animations == null || j_strum.gameplay_notes.general_animations.length <= 0) { return j_note; }
		for (anim in j_strum.gameplay_notes.general_animations) {j_note.animations.push(anim); }
		return j_note;
	}
	inline static public function getDataStaticNote(data:Int, keys:Int, ?type:String, ?style:String = "Default"):Note_Graphic_Data {
		if (type == null) {type = Settings.get("NoteSkin"); }
		var j_strum:StrumLine_Graphic_Data = getJson(Paths.strum_keys(keys, type, style));
		var j_note:Note_Graphic_Data = j_strum.static_notes.notes[(data % (keys)) % (j_strum.static_notes.notes.length)];
		if (j_strum == null || j_strum.gameplay_notes == null || j_strum.static_notes.general_animations == null || j_strum.static_notes.general_animations.length <= 0) { return j_note; }
		for (anim in j_strum.static_notes.general_animations) {j_note.animations.push(anim); }
		return j_note;
	}

	public static function getXMLAnimations(path:String):Array<String> {
		if (!Paths.exists(path)) { return []; }
		var toReturn:Array<String> = [];

		var data:Access = new Access(Xml.parse(Files.getText(path)).firstElement());
		for (texture in data.nodes.SubTexture) {
			if (!texture.has.name) { continue; }
			var _name = texture.att.name.substr(0, texture.att.name.length - 4);
			if (toReturn.contains(_name)) { continue; }
			toReturn.push(_name);
		}

		return toReturn;
	}
}