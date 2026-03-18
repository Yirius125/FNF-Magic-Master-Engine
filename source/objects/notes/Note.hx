package objects.notes;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxCustomShader;
import flixel.util.FlxDestroyUtil;
import objects.scripts.Script;
import haxe.format.JsonParser;
import flixel.tweens.FlxTween;
import states.MusicBeatState;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Json;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;
using utils.Files;

typedef Note_Data = {
    var strumTime:Float;
    var keyData:Int;
    var sustainLength:Float;
    var multiHits:Int;
    var preset:String;
    var eventData:Array<Dynamic>;
    var otherStuff:Array<Dynamic>;
}
typedef Event_Data = {
    var strumTime:Float;
    var eventData:Array<Dynamic>;
    var condition:String;
    var isExternal:Bool;
    var isBroken:Bool;
}

class Note extends StrumNote {
    //Static Methods
    public static function compare(n1:Dynamic, n2:Dynamic, checkData:Bool = true, specific:Bool = false):Bool {
        if ((n1 == null || n2 == null)) { return false; }
        if (Math.abs(n1.strumTime - n2.strumTime) > 10) { return false; }
        if (checkData && (n1.keyData != n2.keyData)) { return false; }
        if (specific && (n1 != n2)) { return false; }
        return true;
    }

    public static function getTypes():Array<String> {
        var toReturn:Array<String> = [];

        for (i in Paths.readDirectory('assets/data/notes')) {
            #if sys if (!FileSystem.isDirectory(i)) { continue; } #end

            var cur_preset:String = i.split("/").pop();
            if (toReturn.contains(cur_preset)) { continue; }

            toReturn.push(cur_preset);
        }

        return toReturn;
    }
    public static function getStyles(?type:String):Array<String> {
        if (type == null) { type = Settings.get("NoteSkin"); }

        var toReturn:Array<String> = [];

        for (i in Paths.readDirectory('assets/shared/images/notes/$type')) {
            #if sys if (!FileSystem.isDirectory(i)) { continue; } #end

            var curStyle:String = i.split("/").pop();
            if (toReturn.contains(curStyle)) { continue; }

            toReturn.push(curStyle);
        }

        return toReturn;
    }
    public static function getPresets():Array<String> {
        var toReturn:Array<String> = ["Default"];

        for (i in Paths.readDirectory('assets/data/notes')) {
            if (!i.endsWith(".json")) { continue; }
            
            var curPreset:String = i.split("/").pop().replace(".json", "");
            if (toReturn.contains(curPreset)) { continue; }
            
            toReturn.push(curPreset);
        }

        return toReturn;
    }
    public static function getEvents(isNote:Bool = false, ?stage:String, ?song:String):Array<String> {
        var toReturn:Array<String> = [];

        for (i in Paths.readDirectory('assets/data/events/general')) {
            if (!i.endsWith(".hx")) { continue; }
            
            toReturn.push(i.split("/").pop().replace(".hx",""));
        }

        if (isNote) {
            for (i in Paths.readDirectory('assets/data/events/note')) {
                if (!i.endsWith(".hx")) { continue; }

                toReturn.push(i.split("/").pop().replace(".hx",""));
            }
        }

        toReturn.sort((_a:String, _b:String) -> {
            _a = _a.toLowerCase();
            _b = _b.toLowerCase();
            
            if (_a < _b) { return -1; }
            if (_a > _b) { return 1; }
            return 0;
        });
        
        if (stage != null) {
            for (i in Paths.readDirectory('assets/data/events/stage/${stage}')) {
                if (!i.endsWith(".hx")) { continue; }

                toReturn.push(i.split("/").pop().replace(".hx", ""));
            }
        }
        
        if (song != null) {
            for (i in Paths.readDirectory('assets/data/events/song/${song}')) {
                if (!i.endsWith(".hx")) { continue; }

                toReturn.push(i.split("/").pop().replace(".hx", ""));
            }
        }

        return toReturn;
    }

    public static function set_note(n1:Array<Dynamic>, n2:Array<Dynamic>):Void {
        if (!(n1 is Array) || !(n2 is Array)) { return; }
        for (i in 0...n2.length) {
            if (n1.length <= i) {
                n1.push(n2[i]);
            } else{
                n1[i] = n2[i];
            }
        }
    }
    
    public static function convNoteData(data:Note_Data):Array<Dynamic> {
        if (data == null) { return null; }
        return [data.strumTime, data.keyData, data.sustainLength, data.multiHits, data.preset, data.eventData, data.otherStuff];
    }
    public static function convEventData(data:Event_Data):Array<Dynamic> {
        if (data == null) { return null; }
        return [data.strumTime, data.eventData, data.condition, data.isExternal, data.isBroken];
    }
    
    public static function getNoteData(?note:Array<Dynamic>):Note_Data {
        var toReturn:Note_Data = {
            strumTime: -100,
            keyData: 0,
            sustainLength: 0,
            multiHits: 0,
            preset: "Default",
            eventData: [],
            otherStuff: []
        }

        if (note == null) { return toReturn; }

        if (note.length >= 0 && Std.isOfType(note[0], Float)) {toReturn.strumTime = note[0]; }
        if (note.length >= 1 && Std.isOfType(note[1], Int)) {toReturn.keyData = note[1]; }    
        if (note.length >= 2 && Std.isOfType(note[2], Float)) {toReturn.sustainLength = note[2]; }      
        if (note.length >= 3 && Std.isOfType(note[3], Int)) {toReturn.multiHits = note[3]; }
        if (note.length >= 4 && Std.isOfType(note[4], String)) {toReturn.preset = note[4]; }
        if (note.length >= 5 && Std.isOfType(note[5], Array)) {toReturn.eventData = note[5]; }
        if (note.length >= 6 && Std.isOfType(note[6], Array)) {toReturn.otherStuff = note[6]; }
        
        return toReturn;
    }

    public static function getEventData(?event:Array<Dynamic>):Event_Data {
        var toReturn:Event_Data = {
            strumTime: -1,
            eventData: [],
            condition: "OnHit",
            isExternal: false,
            isBroken: false
        }

        if (event == null) { return toReturn; }

        if (event.length >= 0 && Std.isOfType(event[0], Float)) { toReturn.strumTime = event[0]; }
        if (event.length >= 1 && Std.isOfType(event[1], Array)) {
            for (e in cast(event[1],Array<Dynamic>)) {
                if (e.length <= 1) {e = [e[0], []]; }
                if (!Std.isOfType(e[0], String)) {e[0] = "None"; }
                if (!Std.isOfType(e[1], Array)) {
                    var new_event_data:Array<Dynamic> = [e[1]];
                    if (e.length > 2) {
                        for (i in 2...cast(e,Array<Dynamic>).length) {
                            new_event_data.push(e[i]);
                            e.remove(e[i]);
                        }
                    }
                    e[1] = new_event_data;
                }
            }
            toReturn.eventData = event[1];

        }
        if (event.length >= 2 && Std.isOfType(event[2], String)) {toReturn.condition = event[2]; }
        if (event.length >= 3 && event[3]) {toReturn.isExternal = true; }
        if (event.length >= 4 && event[4]) {toReturn.isBroken = true; }

        return toReturn;
    }
    
    public static var defaultHitHealth:Float = 0.023;
    public static var defaultMissHealth:Float = 0.0475;

    //General Variables
    public var strumParent:StrumLine = null;
    public var prevNote:Note = null;
    public var nextNote:Note = null;

    public var prevStrumTime:Float = 0;
    public var strumTime:Float = 0;
    //public var noteData:Int = 0; //Now on StrumNote
    public var noteLength:Float = 0;
    public var noteHits:Int = 0; // Determinate if MultiTap o Sustain

    public var typeNote:String = "Normal"; // [Normal, Sustain, Merge] CurNormal Types
    public var typeHit:String = "Press"; // [Press | Normal Hits] [Hold | Hold Hits] [Release | Release Hits] [Always | Just Hit] [Ghost | Just Hit Withowt Strum Anim] [None | Can't Hit]
    public var ignoreMiss:Bool = false;
    public var hitMiss:Bool = false;
    
    public var destroyOnMiss:Bool = true;
    public var destroyOnHit:Bool = true;

    public var customChart:Bool = false;
    public var customInput:Bool = false;

	public var otherData:Array<Dynamic> = [];
    public var typePreset:String = "Default";

    //Other Variables
    public var noteStatus:String = "Spawned"; //status: Spawned, CanBeHit, Pressed, Late, MultiTap
    public var hitHealth:Float = 0.023;
    public var missHealth:Float = 0.0475;

    public var singCharacters:Array<Int> = null;
        
	public function new(data:Note_Data, noteKeys:Int, ?_image:String, ?_style:String, ?_type:String) {
        if (data.eventData != null) { this.otherData = data.eventData.copy(); }
        this.noteLength = data.sustainLength;
        this.strumTime = data.strumTime;
        this.noteHits = data.multiHits;

        this.image = _image != null ? _image : this.image;
        this.style = _style != null ? _style : this.style;
        this.type = _type != null ? _type : this.type;

        loadPreset(data.preset);
        
        execute_events("OnCreate");

        super(data.keyData, noteKeys, image, style, type);
        
        execute_events("OnCreated");
	}

    public function loadPreset(preset:String):Void {
        typePreset = preset;

        var json_path:String = Paths.preset(preset);
        if (preset != "" && Paths.exists(json_path)) {
            var eventList:Dynamic = json_path.getJson();
            otherData = eventList.Events;
        }
    }

    public function execute_events(type:String) {
        for (cur_action in otherData) {
            if (cur_action[2] != type) { continue; }

            if ((cur_action[0] is String)) {
                var action_script:Script = MusicBeatState.state.scripts.get(cur_action[0]);
                if (action_script == null) { trace('Null Event: ${cur_action[0]}'); continue; }
                action_script.setVar("_note", this);
                action_script.call("execute", cast(cur_action[1], Array<Dynamic>));
            } else {
                cur_action[0](cast(cur_action[1], Array<Dynamic>));
            }
        }
    }

    override public function playAnim(anim:String, force:Bool = false) {
		animation.play(anim, force);
        flipY = typeHit == "Hold" ? Settings.get("DownScroll") : false;
	}
}