package objects.game;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.animation.FlxBaseAnimation;
import flixel.animation.FlxAnimation;
import objects.songs.Song.Song_File;
import flixel.group.FlxSpriteGroup;
import objects.scripts.Script;
import haxe.format.JsonParser;
import openfl.utils.AssetType;
import states.MusicBeatState;
import haxe.macro.Expr.Catch;
import flixel.util.FlxColor;
import flash.geom.Rectangle;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.FlxSort;
import openfl.utils.Assets;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import utils.Scripts;
import flixel.FlxG;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

typedef Character_File = {
	var name:String;

	var image:String;
	var icon:String;
	var color:String;

	var death:String;

	var script:String;
	
	var onRight:Bool;
	var antialiasing:Bool;

	var danceIdle:Bool;
	var singTime:Float;

	var scale:Float;

	var camera:Array<Float>;
	var position:Array<Float>;
	var animations:Array<Animation_Data>;
}

typedef Animation_Data = {
	var symbol:String;
	var key:String;
	var fps:Int;

	var loop:Bool;
	var loopTime:Int;

	var indices:Array<Int>;
}

class Character extends FlxSpriteGroup {
	public static var list(get, never):Array<String>;
	public static function get_list():Array<String> {
		var charArray = [];
		
		for (path in Paths.readDirectory('assets/characters')) { charArray.push(path.split("/").pop()); }

		return charArray;
	}

	public static function parse(charFile:Character_File):Void {
		if (charFile.icon == null) { charFile.icon = "face"; }

		if (charFile.image == null) { charFile.image = "BOYFRIEND"; }
		if (charFile.animations == null) { charFile.animations = []; }

		if (charFile.position == null) { charFile.position = [0, 0]; }		
		if (charFile.camera == null) { charFile.camera = [0, 0]; }
		
		if (charFile.color == null) { charFile.color = "#75ff73"; }

		if (charFile.death == null) { charFile.death = "fnf_loss_sfx"; }
	}

	public static function getFocus(song:Song_File, section:Int, ?strum:Int):Int {
		section = Std.int(Math.min(section, song.sections.length - 1));
		section = Std.int(Math.max(section, 0));
		
		var strum_list = song.strums;
		var focused_strum = strum != null ? strum : song.sections[section].strum;
		var focused_character = song.sections[section].character;

		if (strum_list == null || strum_list[focused_strum] == null) { return 0; }
		if (
			strum_list[focused_strum].sections[section] != null && 
			strum_list[focused_strum].sections[section].changeCharacters
		) { return strum_list[focused_strum].sections[section].characters[focused_character]; }

		return strum_list[focused_strum].characters[focused_character];
	}

	public static function setCamera(char:Character, cam:FlxObject, stage:Stage = null) {
		if (char == null) { return; } 
		if (cam == null) { return; }

		var camMoveX:Float = char.x;
		var camMoveY:Float = char.y;

		camMoveX += char.cameraPosition.x;
		camMoveY += char.cameraPosition.y;
		
		if (Settings.get("MoveCamera")) {
			if (char.curAnim.contains("UP")) { camMoveY -= 25; } 
			else if (char.curAnim.contains("DOWN")) { camMoveY += 25; } 
			else if (char.curAnim.contains("LEFT")) { camMoveX -= 25; } 
			else if (char.curAnim.contains("RIGHT")) { camMoveX += 25; }
		}

		if (stage != null) {
			if (stage.camP_1 != null) {
				camMoveX = Math.max(camMoveX, stage.camP_1[0]);
				camMoveY = Math.max(camMoveY, stage.camP_1[1]);
			}
			if (stage.camP_2 != null) {
				camMoveX = Math.min(camMoveX, stage.camP_2[0]);
				camMoveY = Math.min(camMoveY, stage.camP_2[1]);
			}
		}

		cam.setPosition(FlxMath.lerp(cam.x, camMoveX, FlxG.elapsed * 20), FlxMath.lerp(cam.y, camMoveY, FlxG.elapsed * 20));
	}

	public static function cache(list:Array<Dynamic>, character:String = 'Boyfriend', aspect:String = 'Default', ?type:String, onlyThis:Bool = false):Void {
		var char_path:String = Paths.character(character, aspect, type);
		var char_file:Character_File = cast char_path.getJson();
		Character.parse(char_file);

		list.push({type: IMAGE, instance: Paths.image('characters/${character}/${char_file.image}')});
		list.push({type: IMAGE, instance: Paths.image('icons/icon-${char_file.icon}')});
		list.push({type: SOUND, instance: Paths.styleSound('${char_file.death}')});

		var script_path:String = Paths._character(character, '${char_file.script}.hx');
		if (Paths.exists(script_path)) { Scripts.quick(script_path).call('cache', [list, aspect, type]); }
		
		if (onlyThis) { return; }

		if (Paths.exists(Paths.character(character, aspect, "Death"))) { Character.cache(list, character, aspect, "Death", true); }
		if (Paths.exists(Paths.character(character, aspect, "Result"))) { Character.cache(list, character, aspect, "Result", true); }
	}

	public static var DEFAULT_CHARACTER:String = 'Boyfriend';

	public var data:Character_File;
	public var script:Script;

	public var characterSprite:FlxSprite;
	public var defaultSprite(get, default):FlxSprite;
	public function get_defaultSprite():FlxSprite { return defaultSprite != null ? defaultSprite : characterSprite; }

	public var curCharacter:String = DEFAULT_CHARACTER;
	public var curAspect:String = "Default";
	public var curStatus:String = null;
	public var curType:String = null;
	public var curLayer:Int = 0;

	public var curAnim:String = "";
	public var curScale:Float = 1;

	public var specialAnim:Bool = false;
	public var dancedIdle:Bool = false;
	public var noDance:Bool = false;
	public var onRight:Bool = true;

	public var singTimer:Float = 4;
	public var holdTimer:Float = 0;

	public var soundDeath:String = 'fnf_loss_sfx';

	public var icon:String = 'face';
	public var barcolor:FlxColor = 0xffffff;
	public var animations:Map<String, Animation_Data> = [];

	public var defaultPosition:FlxPoint = FlxPoint.get(0, 0);
	public var cameraPosition:FlxPoint = FlxPoint.get(0, 0);

	public var image:String = '';
	public var onDebug:Bool = false;

	public function new(x:Float, y:Float, ?character:String = 'Boyfriend', ?aspect:String = 'Default', ?type:String):Void {
		this.curCharacter = character;
		this.curAspect = aspect;
		this.curType = type;
		super(x, y);

		setupByFile();
	}

	public function setupByName(?_character:String, ?_aspect:String, ?_type:String):Void {
		if (_character != null) { curCharacter = _character; }
		if (_aspect != null) { curAspect = _aspect; }
		if (_type != null) { curType = _type; }
		setupByFile();
	}

	public function setupByFile(?new_file:Character_File):Void {
		var char_path:String = Paths.character(curCharacter, curAspect, curType);
		if (new_file == null) { new_file = cast char_path.getJson(); }

		Character.parse(new_file);
		data = new_file;

		curCharacter = data.name;

		this.icon = data.icon;
		this.image = data.image;
		this.soundDeath = data.death;
		this.singTimer = data.singTime;
		this.dancedIdle = data.danceIdle;
		this.antialiasing = data.antialiasing;
		this.barcolor = FlxColor.fromString(data.color);
		this.cameraPosition.set(data.camera[0], data.camera[1]);
		this.defaultPosition.set(data.position[0], data.position[1]);
		
		animations.clear();
		for (a in data.animations) {animations.set(a.key, a); }

		if (script != null) {
			script.destroy();
			script = null;
		}

		var l_scriptPath:String = Paths._character(curCharacter, '${data.script}.hx');
		if (Paths.exists(l_scriptPath)) { 
			script = Scripts.quick(l_scriptPath); 
			script.name = '${curCharacter}-${curAspect}';
			script.parent = this;
		}

		setGraphic();

		turnLook(onRight);

		dance();
	}

	public function setGraphic(?_image:String):Void {
		if (_image != null) {this.image = _image; }
		this.clear();

		characterSprite = new FlxSprite(defaultPosition.x, defaultPosition.y);

		characterSprite.antialiasing = data.antialiasing;

		var new_path:String = Paths.image('characters/${curCharacter}/${image}');
		characterSprite.frames = new_path.getAtlas();

		if (animations != null) {
			for (anim in animations) {
				var animAnim:String = '' + anim.key;
				var animName:String = '' + anim.symbol;
				var animFps:Int = anim.fps;
				var animLoop:Bool = anim.loop; // Bruh
				var animIndices:Array<Int> = anim.indices;

				if (animIndices != null && animIndices.length > 0) {
					characterSprite.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				} else {
					characterSprite.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		}

		dance();

		scaleCharacter();

		call('preload'); 

		this.add(characterSprite);
		
		call('postload');
	}	

	public function getAnim(name:String) { return defaultSprite.animation.getByName(name); }
	public function getCurAnim() { return defaultSprite.animation.curAnim; }
	public function getCurAnimName():String {
		var l_anmCurrent:FlxAnimation = getCurAnim();
		return l_anmCurrent != null ? l_anmCurrent.name : ""; 
	}
	
	private var oldBeat:Int = -1;
	private var holdDelay:Float = 0;
	override function update(elapsed:Float) {
		if (!onDebug && !noDance) {
			if (holdTimer > 0) { holdTimer -= elapsed; } 
			else if (MusicBeatState.state.curBeat != oldBeat && !specialAnim) { dance(); }
		}

		if (
			getCurAnim() != null && 
			getCurAnim().finished && 
			getAnim('${curAnim}-loop') != null
		) { defaultSprite.animation.play('${curAnim}-loop'); }

		oldBeat = MusicBeatState.state.curBeat;
		
		if (getCurAnim() != null && getCurAnim().finished && specialAnim) { specialAnim = false; }

		super.update(elapsed);

		call('update', [elapsed]);
	}

	private var isDanceRight:Bool = false;
	public function dance():Void {
		isDanceRight = !isDanceRight;

		var l_curAnim:String = dancedIdle ? isDanceRight ? "danceRight" : "danceLeft" : "idle";
		var l_curForce:Bool = dancedIdle;

		var l_callResults:Dynamic = call('dance', [isDanceRight, l_curAnim, l_curForce]);
		l_callResults = l_callResults != null ? l_callResults : {};

		if (l_callResults == Stop || l_callResults.callback == Stop) { return; }

		isDanceRight = l_callResults.right != null ? l_callResults.right : isDanceRight;
		l_curForce = l_callResults.force != null ? l_callResults.force : l_curForce;
		l_curAnim = l_callResults.name != null ? l_callResults.name : l_curAnim;

		defaultSprite.animation.play(l_curAnim, l_curForce);

		curAnim = getCurAnimName();
	}

	public function emoteAnim(AnimName:String, Force:Bool = false, Special:Bool = false):Void {		
		playAnim(AnimName, Force, Special);
		holdTimer = getCurAnim().numFrames / getCurAnim().frameRate;
	}
	public function singAnim(AnimName:String, Force:Bool = false, Special:Bool = false):Void {		
		playAnim(AnimName, Force, Special);
		holdTimer = singTimer;
	}
	public function playAnim(AnimName:String, Force:Bool = false, Special:Bool = false):Void {
		if (specialAnim && !Special) { return; }

		var l_callResults:Dynamic = call('playAnim', [AnimName, Force]);
		l_callResults = l_callResults != null ? l_callResults : {};

		if (l_callResults == Stop || l_callResults.callback == Stop) { return; }

		AnimName = l_callResults.name != null ? l_callResults.name : AnimName;
		Force = l_callResults.force != null ? l_callResults.force : Force;
				
		specialAnim = Special;
		curAnim = '$AnimName';
		
		if (defaultSprite == null) { return; }
		
		if (defaultSprite.flipX) {
			if (AnimName.contains("LEFT")) { AnimName = AnimName.replace("LEFT", "RIGHT"); }
			else { AnimName = AnimName.replace("RIGHT", "LEFT"); }
		}
		
		if (!defaultSprite.animation.exists(AnimName)) { return; }
		
		defaultSprite.animation.play(AnimName, Force || (
			animations.exists(AnimName) && 
			getCurAnim() != null && 
			getCurAnim().curFrame >= animations[AnimName].loopTime
		));
	}

	public function turnLook(toRight:Bool = true):Void {
		onRight = toRight;
		characterSprite.flipX = onRight ? !data.onRight : data.onRight;

		call('turnLook', [toRight]);
	}

	public function scaleCharacter(_scale:Float = 1):Void {
		curScale = _scale * data.scale;

		characterSprite.scale.set(curScale, curScale);
		characterSprite.updateHitbox();
	
		call('scaleCharacter', [curScale]);
	}

	public function call(_method:String, _args:Array<Dynamic> = null):Dynamic {
		if (script == null) { return null; }
		if (_args == null) { _args = []; }

		return script.call(_method, _args);
	}

	override public function destroy():Void {
		super.destroy();

		if (script != null) {
			script.destroy();
			script = null;
		}
	}
}
