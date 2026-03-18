package objects.notes;

import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.addons.ui.FlxUIGroup;
import objects.songs.Conductor;
import flixel.sound.FlxSound;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import states.PlayState;
import utils.Players;
import flixel.FlxG;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

import objects.notes.StrumNote.Note_Animation_Data;
import objects.notes.StrumNote.Note_Graphic_Data;
import objects.songs.Song.Strum_Data;
import objects.notes.Note.Note_Data;
import objects.notes.NoteSplash;
import objects.notes.StrumNote;
import objects.utils.Controls;
import objects.scripts.Script;
import objects.notes.Note;

using utils.Files;
using StringTools;

typedef StrumLine_Graphic_Data = {
    var static_notes:Strums_Data;
    var gameplay_notes:Strums_Data;
}
typedef Strums_Data = {
    var general_animations:Array<Note_Animation_Data>;
    var notes:Array<Note_Graphic_Data>;
}

class StrumLine extends FlxUIGroup {
    public static var ranks:Array<{rank:String, popup:String, score:Int, diff:Int}> = [
        { rank:"PERFECT", popup: "perfect", score: 400, diff: 0 },
        { rank:"SICK", popup: "sick", score: 350, diff: 45 },
        { rank:"GOOD", popup: "good", score: 200, diff: 90 },
        { rank:"BAD", popup: "bad", score: 100, diff: 135 },
        { rank:"._.", popup: "shit", score: 50, diff: 200 }
    ];

    public static var rating:Array<Dynamic> = [
        { percent: 1.0, rate: "MAGIC!!" },
        { percent: 0.9, rate: "Sick!!" },
        { percent: 0.8, rate: "Great" },
        { percent: 0.7, rate: "Cool" },
        { percent: 0.6, rate: "Good" },
        { percent: 0.5, rate: "Bad" },
        { percent: 0.4, rate: "Shit" },
        { percent: 0.3, rate: "._." }
	];

    // Song Properties
    public var data(default, null):Strum_Data;
    public var conductor:Conductor = null;
    public var voice:FlxSound = null;

    // Satic Notes Properties
    public var staticnotes:StaticNotes;

    public var strum_size(get, never):Int; inline function get_strum_size():Int{ return staticnotes.strum_size; }
    public var image(get, never):String; inline function get_image():String{ return staticnotes.image; }
    public var style(get, never):String; inline function get_style():String{ return staticnotes.style; }
    public var type(get, never):String; inline function get_type():String{ return staticnotes.type; }
    public var keys(get, never):Int; inline function get_keys():Int{ return staticnotes.keys; }

    // Note Variables
    public var holdNotes:Array<Note> = [];
    public var notelist:Array<Note> = [];
    public var notes:FlxUIGroup;

    // Strumline Properties
    public var scrollspeed:Float = 1;
    public var bpm:Float = 150;

    public var max_life:Float = 2;
    public var life:Float = 1;

    public var isAlive:Bool = true;
    public var isUsing:Bool = false;

    public var moveByScroll:Bool = true;

    public var botplay(get, default):Bool = false;
    public function get_botplay():Bool { return botplay || Settings.get("BotPlay"); }

    public var practice(get, default):Bool = false;
    public function get_practice():Bool { return practice || Settings.get("Practice"); }

    public var playable:Bool = false;

    public var rankList:Map<String, Int> = [];
    public var rate:String = "MAGIC";
    public var total_notes:Int = 0;
    public var max_combo:Int = 0;
    public var percent:Float = 0;
    public var misses:Int = 0;
    public var score:Int = 0;
    public var combo:Int = 0;
    public var hits:Int = 0;

    // Custom Properties
    public var destroy_notes:Bool = true;
    public var splash_notes:Bool = true;
    public var miss_sounds:Bool = true;
    public var rank_notes:Bool = true;
    public var generated:Bool = false;

    // Control Properties
    public var disableArray:Array<Bool> = [];
    public var releaseArray:Array<Bool> = [];
    public var pressArray:Array<Bool> = [];
    public var holdArray:Array<Bool> = [];
    
    public var controlsId:Int = 0;
    public var controls(get, never):Controls;
    public function get_controls() { return Players.get(controlsId).controls; }
    
    // Dynamic Methods
    public dynamic function onRANK(_note:Note, _score:Float, _rank:String, _pop_image:String):Void {}
    public dynamic function onMISS(_note:Note):Void {}
    public dynamic function onHIT(_note:Note):Void {}
    public dynamic function onGAME_OVER():Void {}
    public dynamic function onLIFE(value:Float):Void {
        if (practice || !isAlive) { return; }

        life += value;
        
        if (life > max_life) {life = max_life; }
        if (life <= 0) {  
            life = 0;
            isAlive = false;
            if (onGAME_OVER != null) { onGAME_OVER(); }
        }
    };
    
    public function new(X:Float, Y:Float, ?_keys:Int, ?_size:Int, ?_image:String, ?_style:String, ?_type:String):Void {
        super(X, Y);

        staticnotes = new StaticNotes(0, 0, _keys, _size, _image, _style, _type);
        add(staticnotes);

        notes = new FlxUIGroup();
        add(notes);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
        

        for (_rank in ranks) {rankList.set(_rank.popup, 0); }
    }

    override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		super.destroy();
	}

    private function onKeyPress(event:KeyboardEvent):Void {
        if (botplay || !isUsing || !FlxG.state.persistentUpdate || controls == null || !controls.useKeyboard) { return; }

        var eventKey:FlxKey = event.keyCode; 
        var cur_data:Int = controls.data_by_key(keys, eventKey);

        if (cur_data < 0) { return; }
        if (holdArray[cur_data]) { return; }
        if (disableArray[cur_data]) { return; }

        staticnotes.playId(cur_data, "pressed", true);
        
        pressArray[cur_data] = true;
        holdArray[cur_data] = true;
        check_input();
        pressArray[cur_data] = false;
    }

    private function onKeyRelease(event:KeyboardEvent):Void {
        if (botplay || !isUsing || !FlxG.state.persistentUpdate || controls == null || !controls.useKeyboard) { return; }
        
        var eventKey:FlxKey = event.keyCode;
        var cur_data:Int = controls.data_by_key(keys, eventKey);
    
        if (cur_data < 0) { return; }
        if (disableArray[cur_data]) { return; }
        
        staticnotes.playId(cur_data, "static", true);
        
        releaseArray[cur_data] = true;
        check_input();
        holdArray[cur_data] = false;
        releaseArray[cur_data] = false;
    }

    public function changeKeys(_keys:Int, ?_size:Int, _force:Bool = false) {
        staticnotes.changeKeys(_keys, _size, _force);

        disableArray.resize(keys);
        releaseArray.resize(keys);
        pressArray.resize(keys);
        holdArray.resize(keys);

        for (n in notelist) {
            n.setGraphicSize(strum_size);
            n.updateHitbox();
        }
    }

    public function load(data:Strum_Data) {
        this.playable = data.playable;
        this.data = data;

        this.notelist = [];
        for (i in 0...data.sections.length) {
            var sectionInfo:Array<Dynamic> = data.sections[i].notes.copy();
            
            for (n in sectionInfo) {if (n[1] < 0 || n[1] >= data.keys) {sectionInfo.remove(n); }}

            for (n in sectionInfo) {
                var noteData:Note_Data = Note.getNoteData(n);
    
                var swagNote:Note = new Note(noteData, data.keys, image, style, type);
                swagNote.setGraphicSize(strum_size, strum_size);
                swagNote.updateHitbox();

                swagNote.strumParent = this;

                notelist.push(swagNote);
        
                if (noteData.sustainLength <= 0 || noteData.multiHits > 0) { continue; }

                var susLength:Int = Std.int(Math.max(Math.floor(noteData.sustainLength / conductor.stepCrochet), 1));
        
                var prevSustain:Note = swagNote;
                for (susNote in 0...(susLength + 1)) {
                    var sustainData:Note_Data = Note.getNoteData(Note.convNoteData(noteData));
                    sustainData.strumTime = noteData.strumTime + (conductor.stepCrochet * susNote) + (conductor.stepCrochet / FlxMath.roundDecimal(getScrollSpeed(), 2));
        
                    var noteSustain:Note = new Note(sustainData, keys, image, style, type);                    
                    noteSustain.setGraphicSize(strum_size, strum_size);
                    noteSustain.updateHitbox();
        
                    noteSustain.typeNote = "Sustain";
                    noteSustain.typeHit = "Hold";
                    
                    noteSustain.strumParent = this;
                    
                    noteSustain.playAnim("end");
                    noteSustain.updateHitbox();
                    
                    if (prevSustain != swagNote) {
                        prevSustain.playAnim("sustain");
                        prevSustain.updateHitbox();

                        prevSustain.scale.y *= conductor.stepCrochet / 100 * 1.6;
                        prevSustain.scale.y *= getScrollSpeed();

                        prevSustain.updateHitbox();
                    }

                    prevSustain.nextNote = noteSustain;
                    noteSustain.prevNote = prevSustain;
                        
                    notelist.push(noteSustain);
        
                    prevSustain = noteSustain;
                }
            }
        }

        notelist.sort(function(a, b) {
            if (a.strumTime < b.strumTime) { return -1; }
            else if (a.strumTime > b.strumTime) { return 1; }
            else if (a.noteData < b.noteData) { return -1; }
            else if (a.noteData > b.noteData) { return 1; }
            else { return 0; }
        });

        var curCheck:Int = 0;
        while(curCheck < notelist.length - 1) {
            if (notelist[curCheck].noteData != notelist[curCheck + 1].noteData) { curCheck++; continue; }
            if (Math.abs(notelist[curCheck].strumTime - notelist[curCheck + 1].strumTime) > 0) { curCheck++; continue; }
            
            notelist[curCheck].destroy();
            notelist.remove(notelist[curCheck]);
        }

        this.generated = true;
    }

    public function getScroll(daNote:Note):Float { return 0.45 * (conductor.position - daNote.strumTime) * getScrollSpeed(); }
    public function getScrollSpeed():Float {
        var pre_TypeScrollSpeed:String = Settings.get("ScrollType");
        var pre_ScrollSpeed:Float = Settings.get("ScrollSpeed");
        var pre_NoteOffset:Float = Settings.get("NoteOffset");

        switch (pre_TypeScrollSpeed) {
            case "Scaled": { return (scrollspeed * pre_ScrollSpeed) + pre_NoteOffset; }
            case "Forced": { return pre_ScrollSpeed + pre_NoteOffset; }
            default: { return scrollspeed + pre_NoteOffset; }
        }
    }

    override function update(elapsed:Float) {
		super.update(elapsed);

        if (!isUsing || botplay) { for (note in staticnotes.statics) { if (note.animation.finished) { note.playAnim("static"); } } }
        
        if (!this.generated) { return; }

        if (notelist[0] != null) {
            if (notelist[0].strumTime - conductor.position < 3500) {
				notes.insert(0, notelist.shift());
            }
        }

        if (controls != null && !controls.useKeyboard && controls.hasGamepad) {
            releaseArray = controls.check_keys(keys, JUST_RELEASED);
            pressArray = controls.check_keys(keys, JUST_PRESSED);
            holdArray = controls.check_keys(keys, PRESSED);

            for (i in 0...pressArray.length) {if (!pressArray[i]) { continue; } staticnotes.playId(i, "pressed", true); }
            for (i in 0...releaseArray.length) {if (!releaseArray[i]) { continue; } staticnotes.playId(i, "static", true); }
        }

        forEachNote((daNote:Note) -> {
            if ((botplay || !isUsing) && (daNote.strumTime <= conductor.position || daNote.typeNote == "Sustain") && !daNote.hitMiss && daNote.noteStatus == "CanBeHit") { hitNOTE(daNote); return; } // Botplay Check
            if (daNote.strumTime <= conductor.position && (daNote.typeHit == "Ghost" || daNote.typeHit == "Always")) { hitNOTE(daNote); return; } // Ghost and Always Check

            if (!daNote.customInput) {
                if (daNote.strumTime < conductor.position + (Conductor.safeZoneOffset * 0.5) && daNote.noteStatus != "Pressed" && daNote.noteStatus != "Missed") { daNote.noteStatus = "CanBeHit"; }
                if (!botplay && conductor.position > daNote.strumTime + (350 / getScrollSpeed()) && daNote.noteStatus != "Pressed" && daNote.noteStatus != "Missed") { missNOTE(daNote); return; }
            }
            
            if (daNote.customChart) { return; }

            daNote.visible = false;
            var noteStrum:StrumNote = staticnotes.statics[daNote.noteData];
            if (noteStrum == null) { return; }

            if (noteStrum.affectNotes) {
                daNote.visible = noteStrum.visible;
                daNote.alpha = noteStrum.alpha;
                daNote.angle = noteStrum.angle;
            } else { daNote.visible = true; }

            if (daNote.typeNote == "Sustain") {
                daNote.alpha = noteStrum.alpha * 0.5;
                daNote.angle = 0;
            }

            var yStuff:Float = noteStrum.y - getScroll(daNote);
            if (Settings.get("DownScroll")) { yStuff = noteStrum.y + getScroll(daNote); }

            daNote.x = noteStrum.x;
            switch (daNote.noteStatus) {
                default:{ daNote.y = yStuff; }
                case "MultiTap": {
                    var radio:Float = (conductor.position - daNote.prevStrumTime) * 1 / daNote.noteLength;
                    radio = Math.min(1, radio); radio = Math.max(0, radio);
                    daNote.y = FlxMath.lerp(daNote.y, yStuff, radio);
                }
            }

            if (daNote.typeNote == "Sustain") {
                if (daNote.nextNote == null && Settings.get("DownScroll")) {
                    daNote.y += 10.5 * (conductor.crochet / 400) * 1.5 * getScrollSpeed() + (46 * (getScrollSpeed() - 1));
                    daNote.y -= 46 * (1 - (conductor.crochet / 600)) * getScrollSpeed();
                }
                daNote.y += (strum_size / 2) - (60.5 * (getScrollSpeed() - 1));
                daNote.y += 27.5 * ((bpm / 100) - 1) * (getScrollSpeed() - 1);


                if (daNote.noteStatus == "Pressed") {
                    if (daNote.clipRect != null && daNote.clipRect.height <= 0) {if (daNote.destroyOnHit) { destroyNote(daNote); } return; }
                    if (onHIT != null) {onHIT(daNote); }
    
                    if (Settings.get("DownScroll")) {
                        var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
                        swagRect.height = ((noteStrum.y + (noteStrum.height / 2)) - daNote.y) / daNote.scale.y;
                        swagRect.y = daNote.frameHeight - swagRect.height;
    
                        daNote.clipRect = swagRect;
                    } else{
                        var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
                        swagRect.y = (noteStrum.y + strum_size / 2 - daNote.y) / daNote.scale.y;
                        swagRect.height -= swagRect.y;
    
                        daNote.clipRect = swagRect;
                    }
                }
            }

            //if (daNote.typeNote == "Sustain" && daNote.nextNote == null && Settings.get("DownScroll")) {daNote.y = daNote.prevNote.y; }

        });

        for (holdnote in holdNotes) {
            if (holdnote.typeHit != "Hold") { holdNotes.remove(holdnote); continue; }
            if (!holdArray[holdnote.noteData]) { continue; }
            if (holdnote.noteStatus != "CanBeHit" || (holdnote.noteStatus == "CanBeHit" && !holdArray[holdnote.noteData])) { continue; }
            hitNOTE(holdnote);
        }

        //PERCENT = Math.min(1, Math.max(0, TNOTES / HITS));
        //for (k in rating.keys()) {if (PERCENT <= k) {RATE = rating.get(k); }}
	}

    private function check_input():Void {
        forEachNote((daNote:Dynamic) -> {
            if (daNote.noteStatus == "CanBeHit" &&
                (
                    (daNote.typeHit == "Press" && pressArray[daNote.noteData]) ||
                    (daNote.typeHit == "Release" && releaseArray[daNote.noteData])
                )
            ) {
                hitNOTE(daNote);
            }
        });
    }

    public function hitNOTE(daNote:Note) {
        daNote.noteStatus = "Pressed";

        if (daNote.hitMiss) { missNOTE(daNote, true); return; }

        staticnotes.playId(daNote.noteData, "confirm", true);
        
        if (daNote.typeNote == "Sustain") { daNote.hitHealth *= 0.25; }

        daNote.execute_events("OnHit");

        if (daNote.noteHits > 0) {
            daNote.noteStatus = "MultiTap";
            daNote.prevStrumTime = daNote.strumTime;
            daNote.strumTime += daNote.noteLength;            
            daNote.noteHits--;
        }

        if (daNote.typeHit != "Ghost") {
            onLIFE(daNote.hitHealth * Settings.get("Healing"));

            rankNote(daNote);
            if (onHIT != null) { onHIT(daNote); }
        }
        
        if (Settings.get("MuteOnMiss") && voice != null) { voice.volume = 1; }

        if (daNote.nextNote != null && daNote.nextNote.typeHit == "Hold") { holdNotes.push(daNote.nextNote); }

        if ((daNote.noteStatus != "MultiTap" && daNote.noteHits <= 0) || (daNote.noteHits < 0 && daNote.noteStatus == "MultiTap")) {
            holdNotes.remove(daNote);
            if (daNote.destroyOnHit && daNote.typeNote != "Sustain") { destroyNote(daNote); }
        }
    }

    public function missNOTE(daNote:Note, force:Bool = false) {
        if (practice || daNote.noteStatus == "Missed") { return; }
        if (daNote.ignoreMiss && !force) {
            holdNotes.remove(daNote);
            if (daNote.destroyOnMiss) { destroyNote(daNote); }   

            return;
        }

        daNote.noteStatus = "Missed";

        if (daNote.typeNote == "Sustain") { daNote.missHealth *= 0.25; }
        if (daNote.noteHits > 0) { daNote.missHealth *= daNote.noteHits + 1; }

        misses += 1 + daNote.noteHits;
        total_notes++;
        score -= 100;
        combo = 0;

        if (Settings.get("MuteOnMiss") && voice != null && playable) { voice.volume = 0; }
        if (Settings.get("MissSounds") && playable) { FlxG.sound.play(Paths.styleSound('missnote${FlxG.random.int(1,3)}', states.PlayState.song.style).getSound(), 0.4); }

        onLIFE(-daNote.missHealth * Settings.get("Damage"));
        
        daNote.execute_events("OnMiss");
        if (onMISS != null) { onMISS(daNote); }

        if (holdNotes.contains(daNote)) { holdNotes.remove(daNote); }
        if (daNote.destroyOnMiss) { destroyNote(daNote); }
    }

    public function destroyNote(daNote:Note, _allNote:Bool = false):Void {
        if (_allNote && daNote.nextNote != null) { this.destroyNote(daNote.nextNote, _allNote); }
        if (!destroy_notes) { daNote.kill(); return; }

        if (this.notes.members.contains(daNote)) { this.notes.remove(daNote, true); }

        if (this.notelist.contains(daNote)) { this.notelist.remove(daNote); }
        if (this.holdNotes.contains(daNote)) { this.holdNotes.remove(daNote); }
        
        daNote.destroy();
    }

    public function rankNote(daNote:Note) {
        if (daNote.typeNote == "Sustain" || !rank_notes) { return; }
        
        total_notes++;
        combo++;
        hits++;

        if (max_combo < combo) { max_combo = combo; }

        var diff_rate:Float = Math.abs(daNote.strumTime - conductor.position);
        
        var _score:Int = 0;
        var _rate:String = "MAGIC!!!";
        var _popImage:String = "good";

        for (rank in ranks) {
            if (diff_rate > rank.diff) { continue; }
            _popImage = rank.popup;
            _score = rank.score;
            _rate = rank.rank;
            break;
        }

        percent = hits / total_notes;
        for (cur_rate in rating) {
            if (cur_rate.percent > percent) { continue; }
            rate = cur_rate.rate;
            break;
        }

        score += _score;
        rankList[_popImage]++;

		if (!isUsing || botplay) { return; }

        if (onRANK != null) { onRANK(daNote, _score, _rate, _popImage); }

        var l_noteData:Int =  daNote.noteData % keys;
        var l_strumNote:StrumNote = staticnotes.statics[l_noteData];
        if (l_strumNote == null) { return; }

        if (Settings.get("SplashNotes") && splash_notes && l_strumNote.canSplash && daNote.canSplash && _score >= 350) { splashNote(daNote); }
    }

    public function splashNote(daNote:Note, ?_image:String, ?_style:String, ?_type:String, _forcePosition:Bool = false):Void {
        if (!daNote.isOnScreen(daNote.camera)) { return; }

        var cur_data:Int =  daNote.noteData % keys;

        var l_strumNote:StrumNote = staticnotes.statics[cur_data];
        if (l_strumNote == null) { return; }
        
        var l_splash = new NoteSplash(this).setupByNote(daNote, l_strumNote, _image, _style, _type);
        add(l_splash);
        
        l_splash.setPosition(_forcePosition ? daNote.x : l_strumNote.x, _forcePosition ? daNote.y : l_strumNote.y);
    }

    public function forEachNote(func:Note->Void):Void {
        notes.forEachAlive((note:FlxSprite) -> {
            if (!(note is Note)) { return; }
            func(cast note);
        });
    }
}