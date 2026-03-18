package states.editors;

import substates.editors.CharacterEditorSubState;
import objects.songs.Conductor.BPMChangeEvent;
import flixel.addons.display.FlxGridOverlay;
import substates.editors.SingEditorSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUITabMenu;
import objects.songs.Song.Strum_Data;
import flixel.addons.ui.FlxUIButton;
import objects.songs.Song.Song_File;
import objects.notes.Note.Note_Data;
import objects.ui.UINumericStepper;
import flixel.addons.ui.FlxUIGroup;
import flixel.sound.FlxSoundGroup;
import objects.notes.StaticNotes;
import objects.notes.StrumEvent;
import substates.PopUpSubState;
import objects.utils.SaverFile;
import objects.ui.UIScrollList;
import objects.notes.StrumLine;
import flixel.addons.ui.FlxUI;
import objects.ui.UIContainer;
import objects.game.Character;
import flixel.tweens.FlxTween;
import objects.scripts.Script;
import objects.ui.UICheckBox;
import objects.game.Alphabet;
import flixel.sound.FlxSound;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import objects.ui.UIButton;
import flixel.text.FlxText;
import objects.songs.Song;
import objects.game.Stage;
import objects.notes.Note;
import lime.ui.FileDialog;
import objects.ui.UIList;
import flixel.FlxSprite;
import flixel.FlxObject;
import haxe.Exception;
import flixel.FlxG;
import haxe.Timer;
import haxe.Json;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class ChartEditorState extends MusicBeatState {
    public static var song:Song_File;
    
    public var stage:Stage;

    public static var lastSection:Int = 0;
    var curSection:Int = 0;
    var curStrum:Int = 0;

	var tempBpm:Float = 0;

    var strumLineEvent:FlxSprite;
    var strumLine:FlxSprite;
    var strumStatics:FlxTypedGroup<StaticNotes>;

    var eveGrid:FlxSprite;
    var curGrid:FlxSprite;
    var focusStrum:FlxSprite;
    var cursor_Arrow:FlxSprite;

    var _saved:Alphabet;

    var backGroup:FlxTypedGroup<Dynamic>;
    var gridGroup:FlxTypedGroup<FlxSprite>;
    var stuffGroup:FlxTypedGroup<Dynamic>;
    
    public static var sHitsArray:Array<Bool> = [];
    var renderedEvents:FlxTypedGroup<StrumEvent>;
    var renderedSustains:FlxTypedGroup<Note>;
    var notesCanHit:Array<Array<Note>> = [];
    var renderedNotes:FlxTypedGroup<Note>;
    var sVoicesArray:Array<Bool> = [];
    var singArray:Array<Array<Int>> = [];
    
    var selNote:Note_Data = Note.getNoteData();
    var selEvent:Event_Data = Note.getEventData();

    var genFollow:FlxObject;
    var backFollow:FlxObject;

    var voices:FlxSoundGroup;
    var inst:FlxSound = new FlxSound();

    var DEFAULT_KEYSIZE:Int = 60;
    var KEYSIZE:Int = 60;

    var curMenu:UIContainer = null;
    
    var ctnMenuSong:UIScrollList;
    var ctnMenuStrum:UIScrollList;
    var ctnMenuSection:UIScrollList;
    var ctnMenuNote:UIScrollList;
    var ctnMenuEvent:UIScrollList;
    var ctnMenuSettings:UIScrollList;
    
    var btnMenuSong:UIButton;
    var btnMenuStrum:UIButton;
    var btnMenuSection:UIButton;
    var btnMenuNote:UIButton;
    var btnMenuEvent:UIButton;
    var btnMenuSettings:UIButton;

    var arrayFocus:Array<FlxUIInputText> = [];
    var copySection:Array<Dynamic> = null;

    var lblSongInfo:FlxText;

    var saveTimer:Timer = new Timer(60000);

    override function destroy() {
        saveTimer.stop();
		super.destroy();
	}

    override function create() {
        if (FlxG.sound.music != null) { FlxG.sound.music.stop(); }

        if (song == null) { song = PlayState.song; }
        if (song == null) { song = Song.load("Test-Normal-Normal"); }

        for (l_event in Note.getEvents(true, song.stage, song.song)) {
            if (scripts.get(l_event) != null) { continue; }
            
			var script_event:Script = Scripts.quick(Paths.event(l_event, song.stage, song.song));
            if (script_event == null) { continue; }
			script_event.name = l_event;
            
            if (!script_event.getVar("loadEditor")) { script_event.destroy(); continue; }

            scripts.set(l_event, script_event);
        }

        saveTimer.run = autoSave;

		#if desktop
		// Updating Discord Rich Presence
		Discord.change('[${song.song}-${song.category}-${song.difficulty}]', '[Charting]');
		Magic.setWindowTitle('Charting [${song.song}-${song.category}-${song.difficulty}]', 1);
		#end

        curSection = lastSection;
		tempBpm = song.bpm;

        super.create();
        
        stage = new Stage(song.stage, song.characters);
        stage.cameras = [camBHUD];
        add(stage);

        backGroup = new FlxTypedGroup<Dynamic>(); backGroup.cameras = [camHUD]; add(backGroup);
        gridGroup = new FlxTypedGroup<FlxSprite>(); gridGroup.cameras = [camHUD]; add(gridGroup);
        focusStrum = new FlxSprite().makeGraphic(KEYSIZE, KEYSIZE, FlxColor.YELLOW); focusStrum.cameras = [camHUD]; focusStrum.alpha = 0.3; add(focusStrum);
        strumStatics = new FlxTypedGroup<StaticNotes>(); strumStatics.cameras = [camHUD]; add(strumStatics);
        stuffGroup = new FlxTypedGroup<Dynamic>(); stuffGroup.cameras = [camHUD]; add(stuffGroup);

        renderedSustains = new FlxTypedGroup<Note>(); renderedSustains.cameras = [camHUD]; add(renderedSustains);
        renderedNotes = new FlxTypedGroup<Note>(); renderedNotes.cameras = [camHUD]; add(renderedNotes);
        renderedEvents = new FlxTypedGroup<StrumEvent>(); renderedEvents.cameras = [camHUD]; add(renderedEvents);

        cursor_Arrow = new FlxSprite().makeGraphic(KEYSIZE,KEYSIZE);
        cursor_Arrow.cameras = [camHUD];
        add(cursor_Arrow);

        strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width), 4);
        strumLine.cameras = [camHUD];
		//strumLine.visible = false;
		add(strumLine);
        
        strumLineEvent = new FlxSprite(0, 50).makeGraphic(KEYSIZE, 4);
        strumLineEvent.cameras = [camHUD];
		add(strumLineEvent);
        
        curMenu = ctnMenuSong = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
		ctnMenuSong.x = FlxG.width - ctnMenuSong.width;
        ctnMenuSong.scrollFactor.set(0, 0);
        ctnMenuSong.cameras = [camFHUD];
        addSongMenuStuff();
        add(ctnMenuSong); 
        
        ctnMenuStrum = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnMenuStrum.scrollFactor.set(0, 0);
        ctnMenuStrum.cameras = [camFHUD];
        addStrumMenuStuff();
        add(ctnMenuStrum);  

        ctnMenuSection = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnMenuSection.scrollFactor.set(0, 0);
        ctnMenuSection.cameras = [camFHUD];
        addSectionMenuStuff();
        add(ctnMenuSection);  

        ctnMenuNote = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnMenuNote.scrollFactor.set(0, 0);
        ctnMenuNote.cameras = [camFHUD];
        addNoteMenuStuff();
        add(ctnMenuNote);  

        ctnMenuEvent = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnMenuEvent.scrollFactor.set(0, 0);
        ctnMenuEvent.cameras = [camFHUD];
        addEventMenuStuff();
        add(ctnMenuEvent);  

        ctnMenuSettings = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnMenuSettings.scrollFactor.set(0, 0);
        ctnMenuSettings.cameras = [camFHUD];
        addSettingsMenuStuff();
        add(ctnMenuSettings);  

        btnMenuSong = new UIButton(0, 10, null, null, "Song", 12, null, null, () -> { showTab(ctnMenuSong); });
        btnMenuSong.x = FlxG.width - ctnMenuSong.width - btnMenuSong.width - 10;
        btnMenuSong.camera = camHUD;
        add(btnMenuSong);

        btnMenuStrum = new UIButton(0, btnMenuSong.y + btnMenuSong.height + 10, null, null, "Strum", 12, null, null, () -> { showTab(ctnMenuStrum); });
        btnMenuStrum.x = FlxG.width - ctnMenuStrum.width - btnMenuStrum.width - 10;
        btnMenuStrum.camera = camHUD;
        add(btnMenuStrum);

        btnMenuSection = new UIButton(0, btnMenuStrum.y + btnMenuStrum.height + 10, null, null, "Section", 12, null, null, () -> { showTab(ctnMenuSection); });
        btnMenuSection.x = FlxG.width - ctnMenuSection.width - btnMenuSection.width - 10;
        btnMenuSection.camera = camHUD;
        add(btnMenuSection);

        btnMenuNote = new UIButton(0, btnMenuSection.y + btnMenuSection.height + 10, null, null, "Note", 12, null, null, () -> { showTab(ctnMenuNote); });
        btnMenuNote.x = FlxG.width - ctnMenuNote.width - btnMenuNote.width - 10;
        btnMenuNote.camera = camHUD;
        add(btnMenuNote);

        btnMenuEvent = new UIButton(0, btnMenuNote.y + btnMenuNote.height + 10, null, null, "Event", 12, null, null, () -> { showTab(ctnMenuEvent); });
        btnMenuEvent.x = FlxG.width - ctnMenuNote.width - btnMenuEvent.width - 10;
        btnMenuEvent.camera = camHUD;
        add(btnMenuEvent);

        btnMenuSettings = new UIButton(0, btnMenuEvent.y + btnMenuEvent.height + 10, null, null, "Settings", 12, null, null, () -> { showTab(ctnMenuSettings); });
        btnMenuSettings.x = FlxG.width - ctnMenuSettings.width - btnMenuSettings.width - 10;
        btnMenuSettings.camera = camHUD;
        add(btnMenuSettings);

        lblSongInfo = new FlxText(0, 50, 300, "", 16);
        lblSongInfo.scrollFactor.set();
        lblSongInfo.camera = camFHUD;
        add(lblSongInfo);

        voices = new FlxSoundGroup();
        loadAudio(song.song, song.category);
        conductor.changeBPM(song.bpm);
		conductor.mapBPMChanges(song);

        _saved = new Alphabet(0,0,[{scale:0.3,bold:true,text:"Song Saved"}]);
        _saved.alpha = 0;
        _saved.cameras = [camFHUD];
        add(_saved);
        
        //camBHUD.alpha = 0;
        camBHUD.zoom = 0.5;

        backFollow = new FlxObject(0, 0, 1, 1);
        backFollow.screenCenter();
		camBHUD.follow(backFollow, LOCKON, 0.04);

        genFollow = new FlxObject(0, 0, 1, 1);
        FlxG.camera.follow(genFollow, LOCKON);
        camHUD.follow(genFollow, LOCKON);
        camBHUD.zoom = stage.zoom;
        
		changeSection(lastSection);
        changeStrum();

        FlxG.mouse.visible = true;
    }
    
    function updateSection():Void {
        //trace(song.characters);
        sHitsArray.resize(song.strums.length);
        
		if (song.sections[curSection].changeBPM && song.sections[curSection].bpm > 0) {
			conductor.changeBPM(song.sections[curSection].bpm);
			FlxG.log.add('CHANGED BPM!');
        } else {
			// get last bpm
			var daBPM:Float = song.bpm;
			for (i in 0...curSection) {if (song.sections[i].changeBPM) {daBPM = song.sections[i].bpm; }}
			conductor.changeBPM(daBPM);
		}

        for (i in 0...song.strums.length) {
            var s = song.strums[i];
            singArray[i] = s.sections[curSection].changeCharacters ? s.sections[curSection].characters : singArray[i] = s.characters;
        }

        reloadChartGrid();
                
        renderedEvents.clear();
        var eventsInfo:Array<Dynamic> = song.events.copy();
        if (eventsInfo != null) {
            for (e in eventsInfo) {
                var eData:Event_Data = Note.getEventData(e);
                if (eData.strumTime + (conductor.stepCrochet * 0.1) < sectionStartTime()) { continue; }
                if (eData.strumTime + (conductor.stepCrochet * 0.1) > sectionStartTime(1)) { continue; }

                var isSelected:Bool = Note.compare(eData, selEvent, false);
        
                var note:StrumEvent = new StrumEvent(eData.strumTime, conductor, eData.isExternal, eData.isBroken);
                setupNote(note, -1);
                note.alpha = isSelected || inst.playing ? 1 : 0.5;
    
                renderedEvents.add(note);
            }
        }

        notesCanHit = [];
        renderedNotes.clear();
        renderedSustains.clear();
        for (ii in 0...song.strums.length) {
            notesCanHit.push([]);

            var sectionInfo:Array<Dynamic> = song.strums[ii].sections[curSection].notes.copy();
            for (n in sectionInfo) {if (n[1] < 0 || n[1] >= song.strums[ii].keys) {sectionInfo.remove(n); }}
            
            var cSection = song.strums[ii];
            for (n in sectionInfo) {
                var nData:Note_Data = Note.getNoteData(n);
                var isSelected:Bool = Note.compare(nData, selNote);
        
                var note:Note = new Note(nData, song.strums[ii].keys, null, cSection.style);
                setupNote(note, ii);
                note.alpha = isSelected || inst.playing ? 1 : 0.5;

                if (note.otherData.length > 0) {
                    var iconEvent:StrumEvent = new StrumEvent(nData.strumTime, conductor);
                    iconEvent.setPosition(note.x, note.y);
                    iconEvent.setGraphicSize(Std.int(KEYSIZE / 3), Std.int(KEYSIZE / 3));
                    iconEvent.updateHitbox();
                    iconEvent.alpha = note.alpha;
                    renderedEvents.add(iconEvent);
                }
                        
                renderedNotes.add(note);
                if (note.strumTime > conductor.position || inst.playing) {notesCanHit[ii].push(note); }
        
                if (nData.sustainLength <= 0) { continue; }
        
                if (nData.multiHits > 0) {
                    var totalHits:Int = nData.multiHits + 1;
                    var hits:Int = nData.multiHits;
                    var curHits:Int = 1;
                    note.noteHits = 0;
                    nData.multiHits = 0;
        
                    while(hits > 0) {
                        var newStrumTime = nData.strumTime + (nData.sustainLength * curHits);
                        var nSData:Note_Data = Note.getNoteData(Note.convNoteData(nData));
                        nSData.strumTime = newStrumTime;

                        var hitNote:Note = new Note(nSData, song.strums[ii].keys, null, cSection.style);
                        setupNote(hitNote, ii);
                        hitNote.alpha = isSelected || inst.playing ? 1 : 0.5;

                        renderedNotes.add(hitNote);
                        if (hitNote.strumTime > conductor.position || inst.playing) {notesCanHit[ii].push(hitNote); }

                        hits--;
                        curHits++;
                    }
                } else {
                    var cSusNote:Int = Std.int(Math.max(Math.floor(nData.sustainLength / conductor.stepCrochet), 1));

                    var nSData:Note_Data = Note.getNoteData(Note.convNoteData(nData));
                    nSData.strumTime += (conductor.stepCrochet / 2);
                    var nSustain:Note = new Note(nSData, song.strums[ii].keys, null, cSection.style);
                    nSustain.typeNote = "Sustain";
                    nSustain.typeHit = "Hold";
                    note.nextNote = nSustain;
                    nSustain.playAnim("sustain");
                    setupNote(nSustain, ii);
                    nSustain.alpha = isSelected || inst.playing ? 0.5 : 0.3;
                    nSustain.setGraphicSize(KEYSIZE, (KEYSIZE * (cSusNote + 0.25))); nSustain.updateHitbox();
                    renderedSustains.add(nSustain);
                    if (nSustain.strumTime > conductor.position || inst.playing) {notesCanHit[ii].push(nSustain); }
                    
                    var nEData:Note_Data = Note.getNoteData(Note.convNoteData(nData));
                    nEData.strumTime += conductor.stepCrochet * (cSusNote + 0.75);
                    var nSustainEnd:Note = new Note(nEData, song.strums[ii].keys, null, cSection.style);
                    nSustainEnd.typeNote = "Sustain";
                    nSustainEnd.typeHit = "Hold";
                    nSustain.nextNote = nSustainEnd;
                    setupNote(nSustainEnd, ii);
                    nSustainEnd.playAnim("end");
                    nSustainEnd.alpha = isSelected || inst.playing ? 0.5 : 0.3;
                    renderedSustains.add(nSustainEnd);
                    if (nSustainEnd.strumTime > conductor.position || inst.playing) {notesCanHit[ii].push(nSustainEnd); }
                }
            }
        }
        
        updateValues();
    }
    
    var s_Characters:Array<Dynamic> = [];
    function updateStage():Void {
        if (stage.curStage == song.stage && s_Characters == song.characters) { return; }
        s_Characters = song.characters.copy();

        stage.load(song.stage);
        stage.setCharacters(song.characters);
        camBHUD.zoom = stage.zoom;
    }

    var g_STRUMS:Int = 0; var g_KEYSIZE:Int = 0; var g_STEPSLENGTH:Int = 0; var g_STRUMKEYS:Array<Int> = [];
    function reloadChartGrid(force:Bool = false):Void {
        var toChange:Bool = force;

        g_STRUMKEYS.resize(song.strums.length);
        for (i in 0...g_STRUMKEYS.length) {if (song.strums[i].keys != g_STRUMKEYS[i]) {toChange = true; break; }}
        if (song.sections[curSection].lengthInSteps != g_STEPSLENGTH) {toChange = true; }
        if (g_STRUMS != song.strums.length) {toChange = true; }
        if (KEYSIZE != g_KEYSIZE) {toChange = true; }
        
        if (!toChange) { return; }

        while(gridGroup.members.length > song.strums.length + 1) {gridGroup.remove(gridGroup.members[gridGroup.members.length - 1], true); }
        while(gridGroup.members.length < song.strums.length + 1) {gridGroup.add(new FlxSprite()); }
        
        if (chkHideStrums.checked) {strumStatics.clear(); } else {
            while(strumStatics.members.length > song.strums.length) {strumStatics.remove(strumStatics.members[strumStatics.members.length - 1], true); }
            while(strumStatics.members.length < song.strums.length) {strumStatics.add(new StaticNotes(0,0)); }
        }

        singArray = [];
        backGroup.clear();
        stuffGroup.clear();
        
        var lastWidth:Float = 0;
        var daLehgthSteps:Int = song.sections[curSection].lengthInSteps;

        // EVENT GRID STRUFF
        var evGrid = gridGroup.members[0];
        evGrid = FlxGridOverlay.create(KEYSIZE, Std.int(KEYSIZE / 2), KEYSIZE, KEYSIZE * daLehgthSteps, true, 0xff4d4d4d, 0xff333333);
        evGrid.x -= KEYSIZE * 1.5;
        if (inst.playing) {evGrid.alpha = 0.5; } 
        gridGroup.members[0] = evGrid;

        eveGrid = gridGroup.members[0];
        strumLineEvent.makeGraphic(KEYSIZE, 4); strumLineEvent.x = eveGrid.x;

        var line_1 = new FlxSprite(evGrid.x - 1,0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_1.scrollFactor.set(1, 0); stuffGroup.add(line_1);
        var eBack = new FlxSprite(evGrid.x,0).makeGraphic(KEYSIZE, FlxG.height, FlxColor.BLACK); eBack.alpha = 0.5; eBack.scrollFactor.set(1, 0); backGroup.add(eBack);
        var line_2 = new FlxSprite(evGrid.x + KEYSIZE - 1,0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_2.scrollFactor.set(1, 0); stuffGroup.add(line_2);

        var line_3 = new FlxSprite(-1, 0).makeGraphic(2, FlxG.height, FlxColor.BLACK); line_3.scrollFactor.set(1, 0); stuffGroup.add(line_3);
        for (i in 0...song.strums.length) {
            var daGrid = gridGroup.members[i + 1];
            var daKeys:Int = song.strums[i].keys;
            singArray.push(song.strums[i].characters);

            if (daGrid != null && daGrid.width == daKeys * KEYSIZE && !toChange) { continue; }

            daGrid = FlxGridOverlay.create(KEYSIZE, KEYSIZE, KEYSIZE * daKeys, KEYSIZE * daLehgthSteps, true, 0xffe7e6e6, 0xffd9d5d5);
            if (i != curStrum || inst.playing) {daGrid.alpha = 0.5; }
            daGrid.x = lastWidth; daGrid.ID = i;

            if (!chkHideStrums.checked) {
                var curStatics = strumStatics.members[i];
                curStatics.style = song.strums[i].style;
                curStatics.changeKeys(daKeys, Std.int(KEYSIZE * daKeys), true);
                curStatics.x = lastWidth;
            }

            lastWidth += daGrid.width;

            var new_line = new FlxSprite(lastWidth - 1, 0).makeGraphic(2, FlxG.height, FlxColor.BLACK); new_line.scrollFactor.set(1, 0); stuffGroup.add(new_line);

            gridGroup.members[i + 1] = daGrid;
        }

        var genBack = new FlxSprite().makeGraphic(Std.int(lastWidth), FlxG.height, FlxColor.BLACK); genBack.alpha = 0.5; genBack.scrollFactor.set(1, 0); backGroup.add(genBack);
                
        g_STRUMS = song.strums.length; g_KEYSIZE = KEYSIZE; g_STEPSLENGTH = daLehgthSteps; for (i in 0...g_STRUMKEYS.length) {g_STRUMKEYS[i] = song.strums[i].keys; }
    }

    var pressedNotes:Array<Note_Data> = [];
    override function update(elapsed:Float) {
        curStep = recalculateSteps();
        
        if (inst.time < 0) {
			inst.pause();
			inst.time = 0;
		} else if (inst.time > inst.length) {
			inst.pause();
			inst.time = 0;
			changeSection();
		}

        conductor.position = inst.time;

        if (song.sections[curSection] != null) {strumLine.y = getYfromStrum((conductor.position - sectionStartTime())); }
        for (strums in strumStatics) {strums.y = strumLine.y; } strumLineEvent.y = strumLine.y;

        if (song.sections[curSection + 1] == null) {addGenSection(); }
        for (i in 0...song.strums.length) {if (song.strums[i].sections[curSection + 1] == null) {addSection(i, song.sections[curSection].lengthInSteps, song.strums[i].keys); }}

        if (Math.ceil(strumLine.y) >= curGrid.height) {changeSection(curSection + 1, false); }
        if (strumLine.y <= -10) {changeSection(curSection - 1, false); }
    
        FlxG.watch.addQuick('daBeat', curBeat);
        FlxG.watch.addQuick('daStep', curStep);

        lblSongInfo.text = 
        "Time: " + Std.string(FlxMath.roundDecimal(conductor.position / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(inst.length / 1000, 2)) +
		"\n\nSection: " + curSection +
		"\nBeat: " + curBeat +
		"\nStep: " + curStep;

        if (inst.playing) {
            Character.setCamera(stage.getCharacterById(Character.getFocus(song, curSection)), backFollow, stage);

            for (i in 0...notesCanHit.length) {
                for (n in notesCanHit[i]) {
                    if (n.strumTime > conductor.position) { continue; }
                    notesCanHit[i].remove(n);

                    if (n.hitMiss) { continue; }
                    if (!chkHideStrums.checked) {strumStatics.members[i].playId((n.noteData % song.strums[i].keys), "confirm", true); }
                    if (!chkMuteHitSounds.checked && sHitsArray[i] && n.typeHit != "Hold") {FlxG.sound.play(Paths.sound("CLAP").getSound()); }

                    var song_animation:String = n.singAnimation;
                    if (song.strums[i].sections[curSection].changeAlt) {song_animation += '-alt'; }

                    for (ii in singArray[i]) {
                        if (stage.getCharacterById(ii) == null) { continue; }
                        stage.getCharacterById(ii).singAnim(song_animation, true);
                    }
                }
            }
        } else { Character.setCamera(stage.getCharacterById(Character.getFocus(song, curSection, curStrum)), backFollow, stage); }

        var arrayControlle = true;
        for (item in arrayFocus) {if (item.hasFocus) {arrayControlle = false; }}

        if (canControlle && arrayControlle) {
		    song.bpm = tempBpm;

            if (!inst.playing) {
                if (!chkHideChart.checked && FlxG.mouse.overlaps(eveGrid)) {
                    cursor_Arrow.alpha = 0.5;

                    cursor_Arrow.x = eveGrid.x;
                    cursor_Arrow.y = Math.floor(FlxG.mouse.y / (KEYSIZE / 2)) * (KEYSIZE / 2);
                    if (FlxG.keys.pressed.SHIFT) {cursor_Arrow.y = FlxG.mouse.y; }
                    
                    if (FlxG.mouse.justPressed) {
                        if (FlxG.keys.pressed.CONTROL) {reloadSelectedEvent(); }
                        else {checkToAddEvent(); }
                    } else if (FlxG.mouse.justPressedRight) { reloadSelectedEvent(); }
                } else if (!chkHideChart.checked && FlxG.mouse.overlaps(curGrid)) {
                    cursor_Arrow.alpha = 0.5;
                    
                    cursor_Arrow.x = Math.floor(FlxG.mouse.x / KEYSIZE) * KEYSIZE;        
                    cursor_Arrow.y = Math.floor(FlxG.mouse.y / (KEYSIZE / 2)) * (KEYSIZE / 2);
                    if (FlxG.keys.pressed.SHIFT) {cursor_Arrow.y = FlxG.mouse.y; }
        
                    if (FlxG.mouse.justPressed) {
                        if (FlxG.keys.pressed.CONTROL) {reloadSelectedNote(); }
                        else {checkToAddNote(); }
                    } else if (FlxG.mouse.justPressedRight) { reloadSelectedNote(); }
                } else {cursor_Arrow.alpha = 0; }
            }

            if (FlxG.keys.justPressed.SPACE) {changePause(inst.playing); }
            if (FlxG.keys.anyJustPressed([UP, DOWN, W, S, R, E, Q]) || FlxG.mouse.wheel != 0 && inst.playing) {changePause(true); }

            if (FlxG.keys.justPressed.R) {
                if (FlxG.keys.pressed.CONTROL) {KEYSIZE = DEFAULT_KEYSIZE; cursor_Arrow.setGraphicSize(KEYSIZE,KEYSIZE); cursor_Arrow.updateHitbox(); updateSection(); }
                else if (FlxG.keys.pressed.SHIFT) {resetSection(true); }
                else {resetSection(); }
            }

            if (FlxG.mouse.wheel != 0) {
                if (FlxG.keys.pressed.CONTROL) {KEYSIZE += Std.int(FlxG.mouse.wheel * (KEYSIZE / 5)); cursor_Arrow.setGraphicSize(KEYSIZE,KEYSIZE); cursor_Arrow.updateHitbox(); updateSection(); }
                else if (FlxG.keys.pressed.SHIFT) {inst.time -= (FlxG.mouse.wheel * conductor.stepCrochet * 0.5); }
                else {inst.time -= (FlxG.mouse.wheel * conductor.stepCrochet * 1); }
            }
    
            if (!FlxG.keys.pressed.SHIFT) {    
                if (FlxG.keys.justPressed.E) {changeNoteSustain(1); }
                if (FlxG.keys.justPressed.Q) {changeNoteSustain(-1); }
    
                if (!inst.playing) {
                    if (FlxG.keys.anyPressed([UP, W])) {
                        var daTime:Float = conductor.stepCrochet * 0.1;
                        inst.time -= daTime;
                    }
                    if (FlxG.keys.anyPressed([DOWN, S])) {
                        var daTime:Float = conductor.stepCrochet * 0.1;
                        inst.time += daTime;
                    }
                }
        
                if (FlxG.keys.anyJustPressed([LEFT, A])) {changeSection(curSection - 1); }
                if (FlxG.keys.anyJustPressed([RIGHT, D])) {changeSection(curSection + 1); }
            } else {    
                if (FlxG.keys.justPressed.E) {changeNoteHits(1); }
                if (FlxG.keys.justPressed.Q) {changeNoteHits(-1); }
        
                if (!inst.playing) {
                    if (FlxG.keys.anyPressed([UP, W])) {
                        var daTime:Float = conductor.stepCrochet * 0.05;
                        inst.time -= daTime;
                    }
                    if (FlxG.keys.anyPressed([DOWN, S])) {
                        var daTime:Float = conductor.stepCrochet * 0.05;
                        inst.time += daTime;
                    }
                }
        
                if (FlxG.keys.anyJustPressed([LEFT, A])) {changeStrum(-1); }
                if (FlxG.keys.anyJustPressed([RIGHT, D])) {changeStrum(1); }
            }
    
            if (FlxG.mouse.justPressedRight) {
                if ( FlxG.mouse.overlaps(gridGroup) && !FlxG.mouse.overlaps(curMenu)) {
                    for (g in gridGroup) {
                        if (gridGroup.members[0] == g) { continue; }
                        if (!FlxG.mouse.overlaps(g)) { continue; }
                        if (g.ID == curStrum) { continue; }
                        changeStrum(g.ID, true);
                        break;
                    }
                }
            }
            
            if (FlxG.keys.justPressed.ENTER && onConfirm == null) {
                FlxG.save.data.autosave = song;
                lastSection = curSection;
                Songs.quickPlay(song, false);
            }
        }

        var fgrid:FlxSprite = gridGroup.members[song.sections[curSection].strum + 1];
        focusStrum.setPosition(FlxMath.lerp(focusStrum.x, fgrid.x, 0.5), fgrid.y);
        if (focusStrum.width != fgrid.width || focusStrum.height != fgrid.height) {focusStrum.makeGraphic(Std.int(FlxMath.lerp(focusStrum.width, fgrid.width, 0.5)), Std.int(FlxMath.lerp(focusStrum.height, fgrid.height, 0.5)), FlxColor.YELLOW); }

        strumLine.x = curGrid.x;
        genFollow.setPosition(FlxMath.lerp(genFollow.x, curGrid.x + (curGrid.width / 2) + 150, 0.1), strumLine.y);

        super.update(elapsed);
    }

    function changePause(toPause:Bool):Void {
        updateSection();

        if (toPause) {
            inst.pause();
            for (voice in voices.sounds) {voice.pause(); }
        } else {
            inst.play(false, inst.time);
            for (voice in voices.sounds) {voice.play(false, inst.time); }
        }
        for (voice in voices.sounds) {voice.time = inst.time; }

        if (inst.playing) {
            eveGrid.alpha = 0.5;
            cursor_Arrow.alpha = 0;
            for (grid in gridGroup) {grid.alpha = 0.5; }
        } else {
            eveGrid.alpha = 1;
            cursor_Arrow.alpha = 0.5;
            Magic.doToMember(cast gridGroup, curStrum + 1, function(grid) {grid.alpha = 1; }, function(grid) {grid.alpha = 0.5; });
        }

    }

    function updateNoteValues():Void {
        if (selNote != null) {
            stpStrumLine.value = selNote.strumTime;
            stpNoteLength.value = selNote.sustainLength;
            stpNoteHits.value = selNote.multiHits;
            clNotePressets.setLabel(selNote.preset, true);
            var event_list:Array<String> = []; for (e in selNote.eventData) {event_list.push(e[0]); } clNoteEventList.setData(event_list);
            clNoteEventList.setLabel(clNoteEventList.getSelectedLabel(), false, true);
        } else {
            stpStrumLine.value = 0;
            stpNoteLength.value = 0;
            stpNoteHits.value = 0;
            clNotePressets.setLabel("Default", true);
            clNoteEventList.setData([]); clNoteEventList.setLabel(clNoteEventList.getSelectedLabel(), false, true);
        }

        if (selEvent != null) {
            stpEventStrumLine.value = selEvent.strumTime;
            var event_list:Array<String> = []; for (e in selEvent.eventData) {event_list.push(e[0]); } clEventListEvents.setData(event_list);
            clEventListEvents.setLabel(clEventListEvents.getSelectedLabel(), false, true);
            btnChangeEventFile.label.text = selEvent.isExternal ? "Global Event" : "Local Event";
            if (selEvent.isExternal) {
                btnBrokeExternalEvent.active = true;
                btnBrokeExternalEvent.alpha = 1;
                btnBrokeExternalEvent.label.text = selEvent.isBroken ? "Event Broken" : "Event Active";
            } else {
                btnBrokeExternalEvent.active = false;
                btnBrokeExternalEvent.alpha = 0.5;
                btnBrokeExternalEvent.label.text = "Event is Local";
            }
        } else {
            stpEventStrumLine.value = 0;
            clEventListEvents.setData([]); clEventListEvents.setLabel(clEventListEvents.getSelectedLabel(), false, true);
        }
    }

    function updateValues():Void {
        var arrChars = []; for (c in song.characters) {arrChars.push(c[0]); }
        
        if (song.strums.length == 2) {stpSwapSec.value = curStrum == 1 ? 0 : 1; }

        clEventListToNote.setData(Note.getEvents(true, song.stage, song.song));
        clEventListToEvents.setData(Note.getEvents(false, song.stage, song.song));

        if (voices.sounds.length <= 1) {chkMuteVocal.kill(); } else {chkMuteVocal.revive(); }
        chkMuteVocal.checked = sVoicesArray[curStrum];
        chkDoHits.checked = sHitsArray[curStrum];
        
        if (song.strums[curStrum] != null) {
            chkPlayable.checked = song.strums[curStrum].playable;
            chkFriendly.checked = song.strums[curStrum].friendly;
            stpSrmKeys.value = song.strums[curStrum].keys;
            ulsStrumStyle.setLabel(song.strums[curStrum].style, true);
        }

        if (song.strums[curStrum].sections[curSection] != null) {
            chkALT.checked = song.strums[curStrum].sections[curSection].changeAlt;
        }

        if (song.sections[curSection] != null) {
            stpSecBPM.value = song.sections[curSection].bpm;
            chkBPM.checked = song.sections[curSection].changeBPM;
            stpLength.value = song.sections[curSection].lengthInSteps;
            stpSecStrum.value = song.sections[curSection].strum;
    
            var arrGenChars = [];
            for (c in song.strums[song.sections[curSection].strum].characters) {arrGenChars.push(arrChars[c]); }
            clGenFocusChar.setData(arrGenChars);    
        }
    }

    override function stepHit() {super.stepHit(); }
    override function beatHit() {super.beatHit(); }

    function setupNote(note:Dynamic, ?grid:Int):Void {
        note.setGraphicSize(KEYSIZE, KEYSIZE);
        note.updateHitbox();

        note.y = Math.floor(getYfromStrum((note.strumTime - sectionStartTime())));
        note.x = gridGroup.members[grid + 1].x;
        if (!(note is StrumEvent)) {note.x += Math.floor(note.noteData * KEYSIZE); }
    }

    function changeStrum(value:Int = 0, force:Bool = false):Void{
        curStrum = !force ? curStrum + value : value;

        if (curStrum >= song.strums.length) {curStrum = song.strums.length - 1; }
        if (curStrum < 0) {curStrum = 0; }

        curGrid = gridGroup.members[curStrum + 1];
        if (curGrid == null) { return; }
        
        if (!inst.playing) {
            for (g in gridGroup) {g.alpha = 0.5; }
            curGrid.alpha = 1;
        }

        if (strumLine.width != Std.int(curGrid.width)) {strumLine.makeGraphic(Std.int(curGrid.width), 4); }
        
        updateValues();
    }

    
    function loadSong(daSong:String, cat:String, diff:String) {
        resetSection(true);

		persistentUpdate = false;

        song = Song.load(Song.format(daSong, cat, diff));
		MusicBeatState.loadState("states.editors.ChartEditorState", [this.onConfirm, this.onBack], [[{type:"SONG",instance:song}], false]);
    }

    function loadAudio(daSong:String, cat:String):Void {
		if (inst != null) {inst.stop(); }

        inst = new FlxSound().loadEmbedded(Paths.inst(daSong, cat).getSound());
        FlxG.sound.list.add(inst);

        sVoicesArray = [];
        voices.sounds = [];
        if (song.voices) {
            for (i in 0...song.strums.length) {
				if (song.strums[i].characters.length <= 0) { continue; }
				if (song.characters.length <= song.strums[i].characters[0]) { continue; }
				var voice_path:String = Paths.voice(i, song.characters[song.strums[i].characters[0]][0], daSong, cat);
                if (!Paths.exists(voice_path)) { continue; }
                var voice = new FlxSound().loadEmbedded(voice_path.getSound());
                FlxG.sound.list.add(voice);
                sVoicesArray.push(false);
                voices.add(voice);
            }
        }

		inst.onComplete = function() {
			voices.pause();
			inst.pause();
			inst.time = 0;
            for (voice in voices.sounds) {voice.time = 0; }
			changeSection();
		};
	}

    function recalculateSteps():Int{
        var lastChange:BPMChangeEvent = {
            stepTime: 0,
            songTime: 0,
            bpm: 0
        }

        for (i in 0...conductor.bpmChangeMap.length) {
            if (inst.time > conductor.bpmChangeMap[i].songTime) {
                lastChange = conductor.bpmChangeMap[i];
            }
        }
    
        curStep = lastChange.stepTime + Math.floor((inst.time - lastChange.songTime) / conductor.stepCrochet);
        updateBeat();
    
        return curStep;
    }

    function resetSection(songBeginning:Bool = false):Void{
        updateSection();
    
        inst.pause();
        for (voice in voices.sounds) {voice.pause(); }
    
        // Basically old shit from changeSection???
        inst.time = sectionStartTime();
    
        if (songBeginning) {
            inst.time = 0;
            curSection = 0;
        }
    
        for (voice in voices.sounds) {voice.time = inst.time; }
        updateCurStep(); updateSection();
    }

    function changeNoteSustain(value:Int):Void{
        updateSelectedNote(function(curNote) {
            curNote.sustainLength += conductor.stepCrochet * value;
            curNote.sustainLength = Math.max(curNote.sustainLength, 0);
    
            if (curNote.sustainLength <= 0 && curNote.multiHits > 0) { curNote.multiHits = 0; }
        });
    }

    function changeNoteHits(value:Int):Void{
        updateSelectedNote(function(curNote) {
            curNote.multiHits += value;
            curNote.multiHits = Std.int(Math.max(curNote.multiHits, 0));
            
            if (curNote.multiHits > 0 && curNote.sustainLength <= 0) {changeNoteSustain(1); }
        });
    }

    function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void{
		if (song.sections[sec] == null) {trace("Null Section"); return; }
        
        curSection = sec;
        updateSection();

		if (updateMusic) {
			inst.pause();
			voices.pause();

			inst.time = sectionStartTime();
            for (voice in voices.sounds) {voice.time = inst.time; }
			updateCurStep();
		}
	}

    private function addGenSection(lengthInSteps:Int = 16):Void{
        var genSec:GeneralSection_Data = {
            bpm: song.bpm,
            changeBPM: false,
    
            lengthInSteps: lengthInSteps,
    
            strum: song.sections[Std.int(Math.min(curSection, song.sections.length - 1))].strum,
            character: song.sections[Std.int(Math.min(curSection, song.sections.length - 1))].character
        };

        song.sections.push(genSec);
    }

    private function addSection(strum:Int = 0, lengthInSteps:Int = 16, keys:Int = 4):Void{
        var sec:Section_Data = {
            characters: song.strums[strum].characters,
            changeCharacters: false,
    
            changeAlt: false,
    
            notes: []
        };

        song.strums[strum].sections.push(sec);
    }

    private function getSwagEvent(event:Array<Dynamic>):Array<Dynamic> {
        if (song.events == null) { return null; }
        for (e in song.events) {if (Note.compare(Note.getEventData(event), Note.getEventData(e), false)) { return e; }}
        return null;
    }
    private function getSwagNote(note:Array<Dynamic>, ?strum:Int):Array<Dynamic> {
        if (strum == null) {strum = curStrum; }
        if (song.strums[strum] == null || song.strums[strum].sections[curSection] == null || song.strums[strum].sections[curSection].notes == null) { return null; }
        for (n in song.strums[strum].sections[curSection].notes) {if (Note.compare(Note.getNoteData(note), Note.getNoteData(n))) { return n; }}
        return null;
    }
    
    private function updateSelectedEvent(func:Event_Data->Void, nuFunc:Void->Void = null, updateValues:Bool = true):Void {
        var e = getSwagEvent(Note.convEventData(selEvent));
        if (e == null) {
            if (nuFunc != null) {nuFunc(); }
        } else {
            var curEvent:Event_Data = Note.getEventData(e);
            func(curEvent);        
            Note.set_note(e, Note.convEventData(curEvent));
            selEvent = Note.getEventData(Note.convEventData(curEvent));
        }

        if (updateValues) {updateNoteValues(); updateSection(); }
    }
    private function updateSelectedNote(func:Note_Data->Void, nuFunc:Void->Void = null, updateValues:Bool = true):Void {
        var n = getSwagNote(Note.convNoteData(selNote));
        if (n == null) {
            if (nuFunc != null) {nuFunc(); }
        } else {
            var curNote:Note_Data = Note.getNoteData(n);    
            func(curNote);            
            Note.set_note(n, Note.convNoteData(curNote));
            selNote = curNote;
        }

        if (updateValues) {updateNoteValues(); updateSection(); }
    }

    private function reloadSelectedEvent():Void {
        selEvent.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        for (e in song.events.copy()) {if (Note.compare(selEvent, Note.getEventData(e), false)) {selEvent = Note.getEventData(e); break; }}
        updateNoteValues(); updateSection();
    }
    private function reloadSelectedNote():Void {
        selNote.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        selNote.keyData = Math.floor((FlxG.mouse.x - curGrid.x) / KEYSIZE) % song.strums[curStrum].keys;
        for (n in song.strums[curStrum].sections[curSection].notes.copy()) {if (Note.compare(selNote, Note.getNoteData(n))) {selNote = Note.getNoteData(n); break; }}
        updateNoteValues(); updateSection();
    }

    private function checkToAddEvent():Void{
        var _event:Event_Data = Note.getEventData();
        _event.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();

        for (e in song.events) {
            if (!Note.compare(_event, Note.getEventData(e), false)) { continue; }
            song.events.remove(e);
            updateNoteValues(); updateSection();
            return;
        }

        song.events.push(Note.convEventData(_event));
        selEvent = Note.getEventData(Note.convEventData(_event));
        updateNoteValues();
        updateSection();
    }
    private function checkToAddNote(isRelease:Bool = false):Void{
        var _note:Note_Data = Note.getNoteData();
        _note.strumTime = getStrumTime(cursor_Arrow.y) + sectionStartTime();
        _note.keyData = Math.floor((FlxG.mouse.x - curGrid.x) / KEYSIZE) % song.strums[curStrum].keys;
        _note.preset = '${selNote.preset}';

        for (n in song.strums[curStrum].sections[curSection].notes) {
            if (!Note.compare(_note, Note.getNoteData(n))) { continue; }
            song.strums[curStrum].sections[curSection].notes.remove(n);
            updateNoteValues(); updateSection();
            return;
        }

        song.strums[curStrum].sections[curSection].notes.push(Note.convNoteData(_note));
        selNote = _note;
        updateNoteValues();
        updateSection();
    }

    function getYfromStrum(strumTime:Float):Float {    
        if (curGrid != null) { return FlxMath.remapToRange(strumTime, 0, song.sections[curSection].lengthInSteps * conductor.stepCrochet, curGrid.y, curGrid.y + curGrid.height); }
        return 0;
    }

    function getStrumTime(yPos:Float):Float{
        if (curGrid != null) { return FlxMath.remapToRange(yPos, curGrid.y, curGrid.y + curGrid.height, 0, song.sections[curSection].lengthInSteps * conductor.stepCrochet); }
        return 0;
    }

    function sectionStartTime(newSection:Int = 0):Float {
        var daBPM:Float = song.bpm;
        var daPos:Float = 0;
        for (i in 0...(curSection + newSection)) {
            if (song.sections[i] != null && song.sections[i].changeBPM) {
                daBPM = song.sections[i].bpm;
            }
            daPos += 4 * (1000 * 60 / daBPM);
        }

        return daPos;
    }

    function copyLastSection(?sectionNum:Int = 1) {
        var daSec = FlxMath.maxInt(curSection, sectionNum);
    
        for (strum in 0...song.strums.length) {
            for (note in song.strums[strum].sections[daSec - sectionNum].notes) {
                var curNote:Note_Data = Note.getNoteData(note);
                curNote.strumTime = curNote.strumTime + conductor.stepCrochet * (song.sections[daSec].lengthInSteps * sectionNum);
                if (getSwagNote(Note.convNoteData(curNote), strum) == null) {song.strums[strum].sections[daSec].notes.push(Note.convNoteData(curNote)); }
            }
        }        
    
        updateSection();
    }

    function copyLastStrum(?sectionNum:Int = 1, ?strum:Int = 0) {
        var daSec = FlxMath.maxInt(curSection, sectionNum);
    
        for (note in song.strums[strum].sections[daSec - sectionNum].notes) {
            var curNote:Note_Data = Note.getNoteData(note);
            curNote.strumTime = curNote.strumTime + conductor.stepCrochet * (song.sections[daSec].lengthInSteps * sectionNum);
            if (getSwagNote(Note.convNoteData(curNote), curStrum) == null) {song.strums[curStrum].sections[daSec].notes.push(Note.convNoteData(curNote)); }
        }
    
        updateSection();
    }

    function mirrorNotes(?strum:Int = null) {
        if (strum == null) {strum = curStrum; }

        var secNotes:Array<Dynamic> = song.strums[strum].sections[curSection].notes;
        var keyLength:Int = song.strums[strum].keys;

        for (i in 0...secNotes.length) {
            var curNote:Note_Data = Note.getNoteData(secNotes[i]);
            curNote.keyData = keyLength - curNote.keyData - 1;
            secNotes[i] = Note.convNoteData(curNote);
        }

        song.strums[strum].sections[curSection].notes = secNotes;

        updateSection();
    }

    function syncNotes() {
        var allSection:Array<Dynamic> = [];
        for (section in song.strums) {
            for (n in section.sections[curSection].notes) {
                var hasNote:Bool = false;
                for (na in allSection) {if (Note.compare(Note.getNoteData(na), Note.getNoteData(n))) {hasNote = true; break; }}
                if (!hasNote) {allSection.push(n); }
            }
        }
        
        for (section in song.strums) {section.sections[curSection].notes = allSection.copy(); }

        updateSection();
    }

    private function getFile(_onSelect:String->Void):Void{
        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str) {_onSelect(str); });
        fDialog.browse();
	}

    var sub_menu:UIContainer;
    var txtCat:FlxUIInputText;
    var txtSong:FlxUIInputText;
    var txtDiff:FlxUIInputText;
    var txtStage:FlxUIInputText;
    var txtStyle:FlxUIInputText;
    var stpBPM:UINumericStepper;
    var stpSpeed:UINumericStepper;
    var stpPlayer:UINumericStepper;
    var chkHasVoices:FlxUICheckBox;
    function addSongMenuStuff():Void {
        var ttlSong = new FlxText(0, 5, ctnMenuSong.display_width, "< - Song - >", 20); ctnMenuSong.addList(ttlSong, 10);
        ttlSong.alignment = CENTER;

        var lblSong = new FlxText(0, 0, ctnMenuSong.display_width, "Song:", 12); ctnMenuSong.addList(lblSong, 0);
        txtSong = new FlxUIInputText(0, 0, ctnMenuSong.display_width, Paths.format(song.song), 16); ctnMenuSong.addList(txtSong, 10);
        txtSong.name = "SONG_NAME";
        arrayFocus.push(txtSong);

        var lblCat = new FlxText(0, 0, ctnMenuSong.display_width, "Category:", 12); ctnMenuSong.addList(lblCat, 0);
        txtCat = new FlxUIInputText(0, 0, ctnMenuSong.display_width, song.category, 16); ctnMenuSong.addList(txtCat, 10);
        txtCat.name = "SONG_CATEGORY";
        arrayFocus.push(txtCat);

        var lblDiff = new FlxText(0, 0, ctnMenuSong.display_width, "Difficulty:", 12); ctnMenuSong.addList(lblDiff, 0);
        txtDiff = new FlxUIInputText(0, 0, ctnMenuSong.display_width, song.difficulty, 16); ctnMenuSong.addList(txtDiff, 10);
        txtDiff.name = "SONG_DIFFICULTY";
        arrayFocus.push(txtDiff);
        
        var btnSave:FlxUIButton = new UIButton(0, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, "Save Song", 16, null, null, () -> {
            canAutoSave = false; canControlle = false;
            save_song(Song.format(song.song,song.category,song.difficulty), song, { saveAs: true, onComplete: () -> { canAutoSave = true; canControlle = true; } });
        }); ctnMenuSong.addList(btnSave, 0, false);

        var btnLoad:FlxUIButton = new UIButton(btnSave.width + 5, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, "Load Song", 16, null, null, () -> {
            loadSong(song.song, song.category, song.difficulty);
        }); ctnMenuSong.addList(btnLoad, 10);

        var btnImport:FlxUIButton = new UIButton(0, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, "Import Chart", 16, null, null, () -> {
            getFile((str) -> {
                var song_data:Song_File = cast Song.convert_song(Song.format(song.song, song.category, song.difficulty), str.getText().trim());
                Song.parse(song_data);

                song = song_data;
                
                updateSection();
            });
        }); ctnMenuSong.addList(btnImport, 0, false);

        var btnAutoSave:FlxUIButton = new UIButton(btnImport.width + 5, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, "Load AutoSave", 16, null, null, () -> {
            if (FlxG.save.data.autosave == null) { return; }
            
            song = FlxG.save.data.autosave;
            Song.parse(song);

            FlxG.switchState(new states.LoadingState(new ChartEditorState(this.onBack, this.onConfirm), [{ type:"SONG", instance: song }], false));
        }); ctnMenuSong.addList(btnAutoSave, 10);
        
        chkHasVoices = new UICheckBox(0, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), "Has Voices?", 16, song.voices); ctnMenuSong.addList(chkHasVoices, 0, false);
        
        var btnReload:FlxUIButton = new UIButton(chkHasVoices.width + 5, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, "Reload Audio", 16, null, null, () -> {
            loadAudio(song.song, song.category); 
        }); ctnMenuSong.addList(btnReload, 10);

        var lblPlayer = new FlxText(0, 0, 0, "Player: ", 16); ctnMenuSong.addList(lblPlayer, 0, false);
        stpPlayer = new UINumericStepper(lblPlayer.width + 5, 0, Std.int(ctnMenuSong.display_width - lblPlayer.width - 5), 16, song.player, 1, 0, 999); ctnMenuSong.addList(stpPlayer, 10);
        stpPlayer.name = "SONG_Player";
        
        var lblSpeed = new FlxText(0, 0, 0, "Scroll Speed: ", 16); ctnMenuSong.addList(lblSpeed, 0, false);
        stpSpeed = new UINumericStepper(lblSpeed.width + 5, 0, Std.int(ctnMenuSong.display_width - lblSpeed.width - 5), 16, song.speed, 0.1, 0.1, 10, 1); ctnMenuSong.addList(stpSpeed, 10);
        stpSpeed.name = "SONG_Speed";
        
        var lblBPM = new FlxText(0, 0, 0, "BPM: ", 16); ctnMenuSong.addList(lblBPM, 0, false);
        stpBPM = new UINumericStepper(lblBPM.width + 5, 0, Std.int(ctnMenuSong.display_width - lblBPM.width - 5), 16, song.bpm, 1, 5, 999); ctnMenuSong.addList(stpBPM, 10);
        stpBPM.name = "SONG_BPM";

        var lblStage = new FlxText(0, 0, ctnMenuSong.display_width, "Stage: ", 12); ctnMenuSong.addList(lblStage, 0);
        txtStage = new FlxUIInputText(0, 0, ctnMenuSong.display_width, song.stage, 16); ctnMenuSong.addList(txtStage, 10);
        txtStage.name = "SONG_STAGE";
        arrayFocus.push(txtStage);

        var lblStyle = new FlxText(0, 0, ctnMenuSong.display_width, "Style: ", 12);  ctnMenuSong.addList(lblStyle, 0);
        txtStyle = new FlxUIInputText(0, 0, ctnMenuSong.display_width, song.style, 16); ctnMenuSong.addList(txtStyle, 10);
        txtStyle.name = "SONG_STYLE";
        arrayFocus.push(txtStyle);

        sub_menu = new UIContainer(-ctnMenuSong.list_width, 0, ctnMenuSong.width, 170, null, Paths.image("editor_menu/tiles/outline-right-both"));
        ctnMenuSong.addList(sub_menu, 20);
        
        var lblGf = new FlxText(0, 0, sub_menu.display_width, "Girlfriend:", 12); sub_menu.addPlus(lblGf, 0);
        var txtGf = new FlxUIInputText(0, 0, sub_menu.display_width, song.characters.length >= 1 ? song.characters[0][0] : "Girlfriend", 16); sub_menu.addPlus(txtGf, 10);
        arrayFocus.push(txtGf); txtGf.name = "CHAR_GF";

        var lblOpp = new FlxText(0, 0, sub_menu.display_width, "Opponent:", 12); sub_menu.addPlus(lblOpp, 0);
        var txtOpp = new FlxUIInputText(0, 0, sub_menu.display_width, song.characters.length >= 2 ? song.characters[1][0] : "Daddy_Dearest", 16); sub_menu.addPlus(txtOpp, 10);
        arrayFocus.push(txtOpp); txtOpp.name = "CHAR_OPP";

        var lblBf = new FlxText(0, 0, sub_menu.display_width, "Boyfriend:", 12); sub_menu.addPlus(lblBf, 0);
        var txtBf = new FlxUIInputText(0, 0, sub_menu.display_width, song.characters.length >= 3 ? song.characters[2][0] : "Boyfriend", 16); sub_menu.addPlus(txtBf, 10);
        arrayFocus.push(txtBf); txtBf.name = "CHAR_BF";
        
        var btnCustomCharacters:FlxUIButton = new UIButton(0, 0, ctnMenuSong.display_width, null, "Customize your Characters", 16, null, null, () -> {
            persistentUpdate = false; 
            canControlle = false;
            
            loadSubState("substates.editors.CharacterEditorSubState", [song, stage, () -> {
                persistentUpdate = true; 
                canControlle = true;
                
                if (song.characters.length != 3) { sub_menu.kill(); }
                else {
                    sub_menu.revive();
                    txtGf.text = song.characters[0][0];
                    txtOpp.text = song.characters[1][0];
                    txtBf.text = song.characters[2][0];
                }

                for (s in song.strums) {
                    for (c in s.characters) { if (c >= song.characters.length) { s.characters.remove(c); }}
                    for (ss in s.sections) { for (c in ss.characters) { if (c >= song.characters.length) { ss.characters.remove(c); } } }
                }
            }]);
        }); ctnMenuSong.addList(btnCustomCharacters, 10);

        var btnAddStrum:FlxUIButton = new UIButton(0, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, "Add Strum", 16, null, null, () -> {
            var nStrum:Strum_Data = {
                friendly: false,
                playable: true,
                keys: 4,
                style: "Default",
                characters: [0],
                sections: [
                    {
                        characters: [0],
                        changeCharacters: false,

                        changeAlt: false,

                        notes: []
                    }
                ]
            };

            song.strums.push(nStrum);

            for (i in 0...curSection) { addSection(song.strums.length - 1, song.sections[i].lengthInSteps); }

            updateSection();
        }); ctnMenuSong.addList(btnAddStrum, 0, false);

        var btnDelStrum:FlxUIButton = new UIButton(btnAddStrum.width + 5, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, "Delete Strum", 16, null, FlxColor.RED, () -> {
            if (song.strums.length <= 1) { return; }

            persistentUpdate = false; 
            canControlle = false;
            
            loadSubState("substates.PopUpSubState", [
                "Do you want to Delete the Current Strum?", 
                () -> {
                    song.strums.remove(song.strums[curStrum]);

                    for (section in song.sections) { if (section.strum >= song.strums.length) { section.strum = song.strums.length - 1; } }

                    changeStrum(-1);            
                    updateSection();                
                }, 
                () -> {
                    Timer.delay(() -> { 
                        persistentUpdate = true; 
                        canControlle = true; 
                    }, 500); 
                }
            ]);
        }); ctnMenuSong.addList(btnDelStrum, 20); 
        btnDelStrum.label.color = FlxColor.WHITE;

        var btnClearSong:FlxUIButton = new UIButton(0, 0, ctnMenuSong.display_width, null, "Clear Song Notes", 16, null, FlxColor.RED, () -> {
            persistentUpdate = false; 
            canControlle = false;
            
            loadSubState("substates.PopUpSubState", [
                "Do you want to Delete all Notes of the Song?", 
                () -> {
                    for (i in song.strums) { for (ii in i.sections) { ii.notes = []; } }

                    updateSection();              
                }, 
                () -> {
                    Timer.delay(() -> { 
                        persistentUpdate = true; 
                        canControlle = true; 
                    }, 500); 
                }
            ]);
        }); ctnMenuSong.addList(btnClearSong, 10);

        var btnClearSongStrum:FlxUIButton = new UIButton(0, 0, ctnMenuSong.display_width, null, "Clear Current Strum Notes", 16, null, FlxColor.RED, () -> {
            if (song.strums[curStrum] == null) { return; }
            persistentUpdate = false; 
            canControlle = false;
            
            loadSubState("substates.PopUpSubState", [
                "Do you want to Delete all Notes of the Strum?", () -> {
                    for (i in song.strums[curStrum].sections) { i.notes = []; }

                    updateSection();
                }, () -> {
                    Timer.delay(() -> {
                        persistentUpdate = true; 
                        canControlle = true; 
                    }, 500); 
                }
            ]);
        }); ctnMenuSong.addList(btnClearSongStrum, 10);

        var btnClearSongEvents:FlxUIButton = new UIButton(0, 0, ctnMenuSong.display_width, null, "Clear Song Events", 16, null, FlxColor.RED, () -> {
            persistentUpdate = false; 
            canControlle = false;
            
            loadSubState("substates.PopUpSubState", [
                "Do you want to Delete all Events of the Song?", 
                () -> {
                    song.events = [];
                    updateSection();
                }, 
                () -> {
                    Timer.delay(() -> {
                        persistentUpdate = true; 
                        canControlle = true; 
                    }, 500); 
                }
            ]);
        }); ctnMenuSong.addList(btnClearSongEvents, 10);

        btnClearSong.label.color = btnClearSongStrum.label.color = btnClearSongEvents.label.color = FlxColor.WHITE;
        
        if (song.characters.length != 3) { sub_menu.kill(); }
    }

    var ulsStrumStyle:UIList;
    var chkALT:FlxUICheckBox;
    var chkDoHits:FlxUICheckBox;
    var chkFriendly:FlxUICheckBox;
    var chkPlayable:FlxUICheckBox;
    var chkMuteVocal:FlxUICheckBox;
    var stpSrmKeys:UINumericStepper;
    function addStrumMenuStuff():Void {
        var ttlStrumSettings:FlxText = new FlxText(0, 5, ctnMenuStrum.display_width, "< - Strum Settings - >", 20); ctnMenuStrum.addList(ttlStrumSettings, 20);
        ttlStrumSettings.alignment = CENTER;

        chkDoHits = new UICheckBox(0, 0, ctnMenuStrum.display_width, "Active HitSounds", 16, false); ctnMenuStrum.addList(chkDoHits, 10);
        chkMuteVocal = new UICheckBox(0, 0, ctnMenuStrum.display_width, "Mute Strum Voice", 16, false); ctnMenuStrum.addList(chkMuteVocal, 20);

        var ttlStrum:FlxText = new FlxText(0, 0, ctnMenuStrum.display_width, "< - Strum - >", 20); ctnMenuStrum.addList(ttlStrum, 20);
        ttlStrum.alignment = CENTER;

        chkPlayable = new UICheckBox(0, 0, ctnMenuStrum.display_width, "Is Playable", 16, song.strums[curStrum].playable); ctnMenuStrum.addList(chkPlayable, 10);
        chkFriendly = new UICheckBox(0, 0, ctnMenuStrum.display_width, "Is Friendly", 16, song.strums[curStrum].friendly); ctnMenuStrum.addList(chkFriendly, 15);

        var lblKeys = new FlxText(0, 0, 0, "Strum Keys: ", 12); ctnMenuStrum.addList(lblKeys, 0, false);
        stpSrmKeys = new UINumericStepper(lblKeys.width + 5, 0, Std.int(ctnMenuStrum.display_width - lblKeys.width - 5), 16, song.strums[curStrum].keys, 1, 1, 10); ctnMenuStrum.addList(stpSrmKeys, 10);
        stpSrmKeys.name = "STRUM_KEYS";

        var lblStrumStyle = new FlxText(0, 0, 0, "Strum Style: ", 12); ctnMenuStrum.addList(lblStrumStyle, 0);
        ulsStrumStyle = new UIList(0, 0, ctnMenuStrum.display_width, 16, Note.getStyles(), song.strums[curStrum].style, () -> {
            if (song.strums[curStrum] == null) { return; }

            song.strums[curStrum].style = ulsStrumStyle.getSelectedLabel();
            
            updateSection(); 
            reloadChartGrid(true);
        }); ctnMenuStrum.addList(ulsStrumStyle, 20);

        var ttlStrumSection:FlxText = new FlxText(0, 0, ctnMenuStrum.display_width, "< - Strum Section - >", 20); ctnMenuStrum.addList(ttlStrumSection, 20);
        ttlStrumSection.alignment = CENTER;

        chkALT = new UICheckBox(0, 0, ctnMenuStrum.display_width, "Change Strum Alt Animation", 16, song.strums[curStrum].sections[curSection].changeAlt); ctnMenuStrum.addList(chkALT, 10);

        var btnSingCharacters:FlxUIButton = new UIButton(0, 0, ctnMenuStrum.display_width, null, "Sing Characters", 16, null, null, () -> {
            persistentUpdate = false; 
            canControlle = false;
            
            loadSubState("substates.editors.SingEditorSubState", [song, stage, curStrum, curSection, () -> {
                persistentUpdate = true; 
                canControlle = true;
            }]);
        }); ctnMenuStrum.addList(btnSingCharacters, 10);

    }

    var chkBPM:FlxUICheckBox;
    var clGenFocusChar:UIList;
    var stpLength:UINumericStepper;
    var stpSecBPM:UINumericStepper;
    var stpSwapSec:UINumericStepper;
    var stpLastSec:UINumericStepper;
    var stpSecStrum:UINumericStepper;
    function addSectionMenuStuff():Void {
        var ttlSection:FlxText = new FlxText(0, 5, ctnMenuSection.display_width, "< - Section - >", 20); ctnMenuSection.addList(ttlSection, 20);
        ttlSection.alignment = CENTER;

        var lblStrum:FlxText = new FlxText(0, 0, ctnMenuSection.display_width, "Strum to Focus: ", 12); ctnMenuSection.addList(lblStrum, 0);
        stpSecStrum = new UINumericStepper(0, 0, ctnMenuSection.display_width, 16, song.sections[curSection].strum, 1, 0, 999); ctnMenuSection.addList(stpSecStrum, 0);
        stpSecStrum.name = "GENERALSEC_strum";
        clGenFocusChar = new UIList(0, 0, ctnMenuSection.display_width, 16, [], song.sections[curSection].character, () -> {
            song.sections[curSection].character = clGenFocusChar.getSelectedIndex();
        });  ctnMenuSection.addList(clGenFocusChar, 10);
        
        var lblBPM = new FlxText(0, 0, ctnMenuSection.display_width, "Section BPM: ", 12); ctnMenuSection.addList(lblBPM, 0);
        stpSecBPM = new UINumericStepper(0, 0, ctnMenuSection.display_width, 16, song.bpm, 1, 5, 999); ctnMenuSection.addList(stpSecBPM, 0);
        stpSecBPM.name = "GENERALSEC_BPM";
        
        chkBPM = new UICheckBox(0, 0, ctnMenuSection.display_width, "Change Section BPM", 16, song.sections[curSection].changeBPM); ctnMenuSection.addList(chkBPM, 10);
        
        var lblLength:FlxText = new FlxText(0, 0, 0, "Section Length (In steps): ", 12); ctnMenuSection.addList(lblLength, 0);
        stpLength = new UINumericStepper(0, 0, ctnMenuSection.display_width, 16, song.sections[curSection].lengthInSteps, 4, 4, 32, 0); ctnMenuSection.addList(stpLength, 20);
        stpLength.name = "GENERALSEC_LENGTH";
        
        var ttlSectionTools:FlxText = new FlxText(0, 5, ctnMenuSection.display_width, "< - Section Tools - >", 20); ctnMenuSection.addList(ttlSectionTools, 20);
        ttlSectionTools.alignment = CENTER;

        var btnCopy:FlxUIButton = new UIButton(0, 0, Std.int(ctnMenuSection.display_width / 2 - 2.5), null, "Copy Section", 16, null, null, () -> {
            copySection = [curSection, []];
            for (i in 0...song.strums.length) {
                copySection[1].push([]);

                for (n in song.strums[i].sections[curSection].notes) {
                    var curNote:Note_Data = Note.getNoteData(n);
                    curNote.strumTime -= sectionStartTime();
                    copySection[1][i].push(Note.convNoteData(curNote));
                }
            }
        }); ctnMenuSection.addList(btnCopy, 0, false);

        var btnPaste:FlxUIButton = new UIButton(btnCopy.width + 5, 0, Std.int(ctnMenuSection.display_width / 2 - 2.5), null, "Paste Section", 16, null, null, () -> {
            if (copySection == null || copySection[1] == null) { return; }

            for (i in 0...song.strums.length) {
                if (copySection[1][i] == null) { continue; }

                var secNotes:Array<Dynamic> = copySection[1][i].copy();
                for (n in secNotes) {
                    var curNote:Note_Data = Note.getNoteData(n);
                    curNote.strumTime += sectionStartTime();

                    if (getSwagNote(Note.convNoteData(curNote), i) == null) {song.strums[i].sections[curSection].notes.push(Note.convNoteData(curNote)); }
                }
            }
            updateSection();
        }); ctnMenuSection.addList(btnPaste, 10);
        
        stpLastSec = new UINumericStepper(0, 0, ctnMenuSection.display_width, 16, 0, 1, -999, 999); ctnMenuSection.addList(stpLastSec, 0);
        var btnLastSec:FlxUIButton = new UIButton(0, 0, ctnMenuSection.display_width, null, "Paste Last Section", 16, null, null, () -> {
            copyLastSection(Std.int(stpLastSec.value));
        }); ctnMenuSection.addList(btnLastSec, 10);
        
        var btnMirror:FlxUIButton = new UIButton(0, 0, Std.int(ctnMenuSection.display_width / 2 - 2.5), null, "Mirror\nSection", 16, null, null, () -> {
            for (i in 0...song.strums.length) { mirrorNotes(i); }
        }); ctnMenuSection.addList(btnMirror, 0, false);
        var btnSync:FlxUIButton = new UIButton(btnMirror.width + 5, 0, Std.int(ctnMenuSection.display_width / 2 - 2.5), null, "Synchronize Notes", 16, null, null, () -> {
            syncNotes(); 
        }); ctnMenuSection.addList(btnSync, 10);

        stpSwapSec = new UINumericStepper(0, 0, ctnMenuSection.display_width, 16, 0, 1, 0, 999); ctnMenuSection.addList(stpSwapSec, 0);
        stpSwapSec.name = "Strums_Length";
        var btnSwapStrum:FlxUIButton = new UIButton(0, 0, ctnMenuSection.display_width, null, "Swap Strum", 16, null, null, () -> {
            var sec1 = song.strums[curStrum].sections[curSection].notes;
            var sec2 = song.strums[Std.int(stpSwapSec.value)].sections[curSection].notes;

            song.strums[curStrum].sections[curSection].notes = sec2;
            song.strums[Std.int(stpSwapSec.value)].sections[curSection].notes = sec1;

            updateSection();
        }); ctnMenuSection.addList(btnSwapStrum, 10);
      
        var chkDEvents:FlxUICheckBox = new UICheckBox(0, 0, Std.int(ctnMenuSection.display_width / 3 - 2.5), "Events\n", 16); ctnMenuSection.addList(chkDEvents, 0, false);
        var chkDNotes:FlxUICheckBox = new UICheckBox(chkDEvents.width + 5, 0, Std.int(ctnMenuSection.display_width / 3 - 2.5), "Notes\n", 16); ctnMenuSection.addList(chkDNotes, 0, false);
        var chkDStrum:FlxUICheckBox = new UICheckBox(chkDEvents.width + chkDNotes.width + 10, 0, Std.int(ctnMenuSection.display_width / 3 - 2.5), "Only Strum", 16); ctnMenuSection.addList(chkDStrum, 10);

        var btnDelAllSec:FlxUIButton = new UIButton(0, 0, ctnMenuSection.display_width, null, "Clear Section", 16, null, FlxColor.RED, () -> {
            if (chkDNotes.checked) {
                if (chkDStrum.checked) { song.strums[curStrum].sections[curSection].notes = []; }
                else { for (strum in song.strums) {strum.sections[curSection].notes = []; } }
            }

            if (chkDEvents.checked) {
                for (e in song.events) {
                    var eData:Event_Data = Note.getEventData(e);
                    if (eData.strumTime < sectionStartTime()) { continue; }
                    if (eData.strumTime > sectionStartTime(1)) { continue; }

                    song.events.remove(e);
                }
            }

            updateSection();
        }); ctnMenuSection.addList(btnDelAllSec, 10); 
        btnDelAllSec.label.color = FlxColor.WHITE;        
    }

    var clNoteCondFunc:UIList;
    var clNotePressets:UIList;
    var clNoteEventList:UIList;
    var clEventListToNote:UIList;
    var stpNoteHits:UINumericStepper;
    var stpStrumLine:UINumericStepper;
    var stpNoteLength:UINumericStepper;
    var note_event_sett_group:FlxUIGroup;
    function addNoteMenuStuff():Void {
        var ttlNote:FlxText = new FlxText(0, 5, ctnMenuNote.display_width, "< - Current Note - >", 20); ctnMenuNote.addList(ttlNote, 20);
        ttlNote.alignment = CENTER;
        
        var lblStrumLine:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "StrumTime: ", 12); ctnMenuNote.addList(lblStrumLine, 0);
        stpStrumLine = new UINumericStepper(0, 0, ctnMenuNote.display_width, 16, 0, conductor.stepCrochet * 0.5, 0, 999999, 2); ctnMenuNote.addList(stpStrumLine, 10);
        stpStrumLine.name = "NOTE_STRUMTIME";

        var lblNoteLength:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "Note Length: ", 12); ctnMenuNote.addList(lblNoteLength, 0);
        stpNoteLength = new UINumericStepper(0, 0, ctnMenuNote.display_width, 16, 0, conductor.stepCrochet, 0, 999999, 2); ctnMenuNote.addList(stpNoteLength, 10);
        stpNoteLength.name = "NOTE_LENGTH";

        var lblNoteHits:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "Note Extra Hits: ", 12); ctnMenuNote.addList(lblNoteHits, 0);
        stpNoteHits = new UINumericStepper(0, 0, ctnMenuNote.display_width, 16, 0, 1, 0, 999); ctnMenuNote.addList(stpNoteHits, 10);
        stpNoteHits.name = "NOTE_HITS";

        var lblNotePresets:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "Note Preset: ", 12); ctnMenuNote.addList(lblNotePresets, 0);
        clNotePressets = new UIList(0, 0, ctnMenuNote.display_width, 16, Note.getPresets(), "Default", () -> {
            updateSelectedNote(
                (curNote) -> { curNote.preset = clNotePressets.getSelectedLabel(); },
                () -> { selNote.preset = clNotePressets.getSelectedLabel(); }
            );
        }); ctnMenuNote.addList(clNotePressets, 20);
        
        var ttlNoteEvents:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "< - Note Events - >", 20); ctnMenuNote.addList(ttlNoteEvents, 20);
        ttlNoteEvents.alignment = CENTER;

        var lblEventListToNote:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "Add Note Event: ", 12); ctnMenuNote.addList(lblEventListToNote, 0);
        clEventListToNote = new UIList(0, 0, Std.int(ctnMenuNote.display_width - 25), 16, Note.getEvents(true)); ctnMenuNote.addList(clEventListToNote, 0, false);
        var btnAddEventToNote:UIButton = new UIButton(clEventListToNote.width + 5, 0, 40, null, "+", 16, null, null, () -> {
            updateSelectedNote(
                (curNote) -> {
                    var cur_label:String = clEventListToNote.getSelectedLabel();
                    scripts.load(cur_label, Paths.event(cur_label, song.stage, song.song));
                    var default_list:Array<Dynamic> = [];
                    for (setting in cast(scripts.get(cur_label).getVar("defaultValues"), Array<Dynamic>)) { default_list.push(setting.value); }
                    curNote.eventData.push([cur_label, default_list, "OnHit"]);
                }
            );
            clNoteEventList.setIndex(selNote.eventData.length - 1);
        });
        btnAddEventToNote.resize(Std.int(clEventListToNote.height), Std.int(clEventListToNote.height)); 
        ctnMenuNote.addList(btnAddEventToNote, 10);
        
        var lblNoteEventList:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "Current Note Event: ", 12); ctnMenuNote.addList(lblNoteEventList, 0);
        clNoteEventList = new UIList(0, 0, Std.int(ctnMenuNote.display_width - 25), 16, [], null, () -> {
            updateSelectedNote(
                (curNote) -> {                
                    clNoteEventList.setSuffix(' (${clNoteEventList.getSelectedIndex() + 1}/${curNote.eventData.length})');
                    clNoteCondFunc.setLabel(curNote.eventData[clNoteEventList.getSelectedIndex()][2]);
                    loadNoteEventSettings(clNoteEventList.getSelectedLabel());
                    //try{txtNoteEventValues.text = Json.stringify(curNote.eventData[clNoteEventList.getSelectedIndex()][1]); }catch(e) {trace(e); txtNoteEventValues.text = "[]"; }
                },
                () -> {
                    clNoteEventList.setData([]);
                    clNoteEventList.setSuffix(' (0/0)');
                    loadNoteEventSettings();
                    //txtNoteEventValues.text = "[]";
                }, false
            );
        }); ctnMenuNote.addList(clNoteEventList, 0, false);        
        var btnDelEventToNote = new UIButton(clNoteEventList.width + 5, 0, 40, null, "-", 16, null, null, () -> {
            updateSelectedNote((curNote) -> {
                if (curNote.eventData.length <= 0) { return; }

                curNote.eventData.remove(curNote.eventData[clNoteEventList.getSelectedIndex()]);
            });

            clNoteEventList.setIndex(selNote.eventData.length - 1);
        }); 
        btnDelEventToNote.resize(Std.int(clNoteEventList.height), Std.int(clNoteEventList.height)); 
        ctnMenuNote.addList(btnDelEventToNote, 10);

        var lblNoteCondition:FlxText = new FlxText(0, 0, ctnMenuNote.display_width, "Note Event Condition: ", 12); ctnMenuNote.addList(lblNoteCondition, 0);
        clNoteCondFunc = new UIList(0, 0, ctnMenuNote.display_width, 16, ["OnHit", "OnMiss", "OnCreate"], () -> {
            updateSelectedNote((curNote) -> {
                if (curNote.eventData.length <= 0) { return; }

                curNote.eventData[clNoteEventList.getSelectedIndex()][2] = clNoteCondFunc.getSelectedLabel();
            }, false);
        }); ctnMenuNote.addList(clNoteCondFunc, 10);

        note_event_sett_group = new FlxUIGroup(0, 0); ctnMenuNote.addList(note_event_sett_group);
        note_event_sett_group.width = ctnMenuNote.display_width;
        note_event_sett_group.camera = camFHUD;
    }

    var clEventListEvents:UIList;
    var clEventListToEvents:UIList;
    var event_sett_group:FlxUIGroup;
    var btnChangeEventFile:FlxUIButton;
    var btnBrokeExternalEvent:FlxUIButton;
    var stpEventStrumLine:UINumericStepper;
    function addEventMenuStuff():Void {
        var ttlEvent:FlxText = new FlxText(0, 5, ctnMenuEvent.display_width, "< - Current Event - >", 20); ctnMenuEvent.addList(ttlEvent, 20);
        ttlEvent.alignment = CENTER;

        var lblEventStrumLine:FlxText = new FlxText(0, 0, 0, "StrumTime: ", 12); ctnMenuEvent.addList(lblEventStrumLine, 0);
        stpEventStrumLine = new UINumericStepper(0, 0, ctnMenuEvent.display_width, 16, 0, conductor.stepCrochet * 0.5, 0, 999999, 2); ctnMenuEvent.addList(stpEventStrumLine, 10);
        stpEventStrumLine.name = "EVENT_STRUMTIME";

        var lblEventListToEvents:FlxText = new FlxText(0, 0, 0, "Add Event: ", 12); ctnMenuEvent.addList(lblEventListToEvents, 0);
        clEventListToEvents = new UIList(0, 0, Std.int(ctnMenuEvent.display_width - 25), 16, Note.getEvents()); ctnMenuEvent.addList(clEventListToEvents, 0, false);
        var btnAddEventToEvents = new UIButton(clEventListToEvents.width + 5, 0, 40, null, "+", 12, null, null, () -> {
            updateSelectedEvent(
                (curEvent) -> {
                    var cur_label:String = clEventListToEvents.getSelectedLabel();
                    scripts.load(cur_label, Paths.event(cur_label, song.stage, song.song));
                    var default_list:Array<Dynamic> = [];
                    for (setting in cast(scripts.get(cur_label).getVar("defaultValues"), Array<Dynamic>)) {default_list.push(setting.value); }
                    curEvent.eventData.push([cur_label, default_list]);
                }
            );
        }); 
        btnAddEventToEvents.resize(Std.int(clEventListToEvents.height), Std.int(clEventListToEvents.height)); 
        ctnMenuEvent.addList(btnAddEventToEvents, 10);
        
        var lblEventListEvents:FlxText = new FlxText(0, 0, 0, "Current Event List: ", 12); ctnMenuEvent.addList(lblEventListEvents, 0);
        clEventListEvents = new UIList(0, 0, Std.int(ctnMenuEvent.display_width - 25), 16, [], null, () -> {   
            updateSelectedEvent(
                (curEvent) -> {      
                    clEventListEvents.setSuffix(' (${clEventListEvents.getSelectedIndex() + 1}/${curEvent.eventData.length})');
                    //try{txtCurEventValues.text = Json.stringify(curEvent.eventData[clEventListEvents.getSelectedIndex()][1]); }catch(e) {trace(e); txtCurEventValues.text = ""; }
                    loadEventSettings(clEventListEvents.getSelectedLabel());
                },
                () -> {     
                    clEventListEvents.setData([]);
                    clEventListEvents.setSuffix(' (0/0)');
                    //txtCurEventValues.text = "[]";
                    loadEventSettings();
                }, false
            );
        }); ctnMenuEvent.addList(clEventListEvents, 0, false);        
        var btnDelEventToNote = new UIButton(clEventListEvents.width + 5, 0, 40, null, "-", 16, null, null, () -> {
            updateSelectedEvent(
                (curEvent) -> {
                    if (curEvent.eventData.length <= 0) { return; }

                    curEvent.eventData.remove(curEvent.eventData[clEventListEvents.getSelectedIndex()]);
                }
            );
        }); 
        btnDelEventToNote.resize(Std.int(clEventListEvents.height), Std.int(clEventListEvents.height)); 
        ctnMenuEvent.addList(btnDelEventToNote, 10);

        btnChangeEventFile = new UIButton(0, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, 'Local Event', 16, null, null, () -> {
            updateSelectedEvent((curEvent) -> { curEvent.isExternal = !curEvent.isExternal; });
        }); ctnMenuEvent.addList(btnChangeEventFile, 0, false);

        btnBrokeExternalEvent = new UIButton(btnChangeEventFile.width + 5, 0, Std.int(ctnMenuSong.display_width / 2 - 2.5), null, 'Broken Event', 16, null, null, () -> {
            updateSelectedEvent((curEvent) -> { curEvent.isBroken = !curEvent.isBroken; });
        }); ctnMenuEvent.addList(btnBrokeExternalEvent, 10);

        event_sett_group = new FlxUIGroup(0, 0); ctnMenuEvent.addList(event_sett_group, 10);
        event_sett_group.width = ctnMenuEvent.display_width;
    }

    var chkMuteInst:FlxUICheckBox;
    var chkHideChart:FlxUICheckBox;
    var chkMuteVoices:FlxUICheckBox;
    var chkHideStrums:FlxUICheckBox;
    var chkMuteHitSounds:FlxUICheckBox;
    function addSettingsMenuStuff():Void {
        var ttlSettings:FlxText = new FlxText(0, 5, ctnMenuSettings.display_width, "< - Settings - >", 20); ctnMenuSettings.addList(ttlSettings, 20);
        ttlSettings.alignment = CENTER;

        chkMuteInst = new UICheckBox(0, 0, ctnMenuSong.display_width, "Mute Inst", 16); ctnMenuSettings.addList(chkMuteInst, 10);
        chkMuteVoices = new UICheckBox(0, 0, ctnMenuSong.display_width, "Mute Voices", 16); ctnMenuSettings.addList(chkMuteVoices, 10);
        chkMuteHitSounds = new UICheckBox(0, 0, ctnMenuSong.display_width, "Mute HitSounds", 16); ctnMenuSettings.addList(chkMuteHitSounds, 20);
        
        chkHideChart = new UICheckBox(0, 0, ctnMenuSong.display_width, "Hide Chart", 16); ctnMenuSettings.addList(chkHideChart, 10);
        chkHideStrums = new UICheckBox(0, 0, ctnMenuSong.display_width, "Hide Strums", 16); ctnMenuSettings.addList(chkHideStrums, 10);
    }

    function showTab(_tab:UIContainer):Void {
        if (curMenu == _tab) { return; }

        if (curMenu != null) {
            FlxTween.cancelTweensOf(curMenu);
            FlxTween.tween(curMenu, { x: FlxG.width }, 0.2, { ease: FlxEase.quadOut });
        }

        curMenu = _tab;

        FlxTween.cancelTweensOf(curMenu);
        FlxTween.tween(curMenu, { x: FlxG.width - 300 }, 0.2, { ease: FlxEase.quadOut });
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
        if (id == FlxUICheckBox.CLICK_EVENT) {
            var check:FlxUICheckBox = cast sender;
			var wname = check.getLabel().text;

            if (check.name.startsWith("note_event_arg")) {
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote) {
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = check.checked;
                    }, null, false
                );

                return;
            } else if (check.name.startsWith("event_arg")) {
                var id:Int = Std.parseInt(check.name.split(":")[1]);

                updateSelectedEvent(
                    (curEvent) -> {
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = check.checked;
                    }, null, false
                );

                return;
            }

			switch (wname) {
                case "Is Friendly": { song.strums[curStrum].friendly = check.checked; }
                case "Is Playable": { song.strums[curStrum].playable = check.checked; }
                case "Active HitSounds": { sHitsArray[curStrum] = check.checked; }
                case "Mute Strum Voice": { sVoicesArray[curStrum] = check.checked; }
                case "Mute Inst": { inst.volume = check.checked ? 0 : 1; }
                case "Hide Strums": { reloadChartGrid(true); } 
                case "Hide Chart": {
                    camHUD.visible = !check.checked;
                    camFHUD.alpha = !check.checked ? 1 : 0.5;
                }
				case 'Change BPM': {
                    song.sections[curSection].changeBPM = check.checked;
					FlxG.log.add('BPM Changed to: ' + check.checked);
                    updateSection();
                }
				case "\nChange Strum ALT": {
                    song.strums[curStrum].sections[curSection].changeAlt = check.checked;
                }
                case "Song has Voices?": {
                    inst.pause();
                    for (voice in voices.sounds) {voice.pause(); }
                    
                    song.voices = check.checked;
                    loadAudio(song.song, song.category);
                    reloadChartGrid(true);
                }
			}

            if (wname == "Mute Strum Voice" || wname == "Mute Voices") {
                for (i in 0...voices.sounds.length) { voices.sounds[i].volume = !sVoicesArray[i] && !chkMuteVoices.checked ? 1 : 0; }
            }
		} else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
            var input:FlxUIInputText = cast sender;
            var wname = input.name;

            if (wname.startsWith("note_event_arg")) {
                var id:Int = Std.parseInt(wname.split(":")[1]);
                var type:String = wname.split(":")[2];

                updateSelectedNote(
                    (curNote) -> {
                        switch (type) {
                            case "string": { curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = input.text; }
                            case "array": {
                                var pString:String = '{ "Events": ${input.text} }';
                                var rString:Array<Dynamic> = [];
                                try { rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK; } catch(e) { trace(e); input.color = FlxColor.RED; }

                                curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = rString;
                            }
                        }
                    }, null, false
                );

                return;
            } else if (wname.startsWith("event_arg")) {
                var id:Int = Std.parseInt(wname.split(":")[1]);
                var type:String = wname.split(":")[2];

                updateSelectedEvent(
                    (curEvent) -> {
                        switch (type) {
                            case "string": { curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = input.text; }
                            case "array": {
                                var pString:String = '{ "Events": ${input.text} }';
                                var rString:Array<Dynamic> = [];
                                try { rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK; } catch(e) { trace(e); input.color = FlxColor.RED; }

                                curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = rString;
                            }
                        }
                    }, null, false
                );

                return;
            }

            switch (wname) {
                case "SONG_NAME": { song.song = Paths.format(input.text, true); }
                case "SONG_CATEGORY": { song.category = input.text; }
                case "SONG_DIFFICULTY": { song.difficulty = input.text; }
                case "SONG_STYLE": { song.style = input.text; }
                case "SONG_STAGE": { song.stage = input.text; updateStage(); }
                case "NOTE_EVENT": {
                    if (getSwagNote(Note.convNoteData(selNote)) == null) { input.color = FlxColor.GRAY; return; }

                    var pString:String = '{ "Events": ${input.text} }';
                    var rString:Array<Dynamic> = [];
                    try { rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK; } catch(e) { trace(e); input.color = FlxColor.RED; }

                    updateSelectedNote((curNote) -> {
                        if (curNote.eventData[clNoteEventList.getSelectedIndex()] == null) { return; }
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1] = rString;
                    }, false);
                }
                case "EVENTS_EVENT": {
                    if (getSwagEvent(Note.convEventData(selEvent)) == null) { input.color = FlxColor.GRAY; return; }
                    
                    var pString:String = '{ "Events": ${input.text} }';
                    var rString:Array<Dynamic> = [];
                    try { rString = (cast Json.parse(pString)).Events; input.color = FlxColor.BLACK; } catch(e) { trace(e); input.color = FlxColor.RED; }

                    updateSelectedEvent((curEvent) -> {
                        if (curEvent.eventData[clEventListEvents.getSelectedIndex()] == null) { return; }
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1] = rString;
                    }, false);
                }
                case "CHAR_GF": { if (input == null || song.characters.length < 1 || song.characters[0].length < 1) { return; } song.characters[0][0] = input.text; updateStage(); }
                case "CHAR_OPP": { if (input == null || song.characters.length < 2 || song.characters[1].length < 1) { return; } song.characters[1][0] = input.text; updateStage(); }
                case "CHAR_BF": { if (input == null || song.characters.length < 3 || song.characters[2].length < 1) { return; } song.characters[2][0] = input.text; updateStage(); }
            }
        } else if (id == FlxUIDropDownMenu.CLICK_EVENT && (sender is FlxUIDropDownMenu)) {
            var drop:FlxUIDropDownMenu = cast sender;
            var wname = drop.name;

            switch (wname) {
                default:{}
            }
        } else if (id == UINumericStepper.CHANGE_EVENT && (sender is UINumericStepper)) {
            var nums:UINumericStepper = cast sender;
			var wname = nums.name;

            if (wname.startsWith("note_event_arg")) {
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote) {
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = nums.value;
                    }, null, false
                );

                return;
            } else if (wname.startsWith("event_arg")) {
                var id:Int = Std.parseInt(wname.split(":")[1]);
                var l_selected:Int = clEventListEvents.getSelectedIndex();

                updateSelectedEvent(
                    (curEvent) -> {
                        if (curEvent == null) { return; }
                        if (curEvent.eventData == null) { return; }
                        if (curEvent.eventData[l_selected] == null) { return; }
                        if (curEvent.eventData[l_selected][1] == null) { return; }

                        curEvent.eventData[l_selected][1][id] = nums.value;
                    }, null, false
                );

                return;
            }

            switch (wname) {
                case "SONG_Player": {
                    if (nums.value < 0) { nums.value = 0; }
                    if (nums.value >= song.strums.length) { nums.value = song.strums.length - 1; }

                    song.player = Std.int(nums.value);
                }
                case "NOTE_STRUMTIME": {
                    updateSelectedNote(function(curNote) {curNote.strumTime = nums.value; });
                }
                case "EVENT_STRUMTIME": {
                    updateSelectedEvent(function(curEvent) {curEvent.strumTime = nums.value; });
                }
                case "NOTE_LENGTH":{
                    updateSelectedNote(function(curNote) {
                        if (nums.value <= 0) {curNote.multiHits = 0; }
                        curNote.sustainLength = nums.value;
                    });
                }
                case "SONG_Speed":{song.speed = nums.value; }
                case "SONG_BPM":{
                    tempBpm = nums.value;
                    
				    conductor.mapBPMChanges(song);
				    conductor.changeBPM(nums.value);
                    
                    updateSection();
                }
                case "GENERALSEC_BPM":{
                    song.sections[curSection].bpm = nums.value;
                    updateSection();
                }
                case "GENERALSEC_LENGTH":{
                    song.sections[curSection].lengthInSteps = Std.int(nums.value);
                    updateSection();
                }
                case "GENERALSEC_strum":{
                    if (nums.value < 0) {nums.value = 0; }
                    if (nums.value >= song.strums.length) {nums.value = song.strums.length - 1; }

                    song.sections[curSection].strum = Std.int(nums.value);
                    updateSection();
                }
                case "NOTE_HITS":{
                    updateSelectedNote(function(curNote) {
                        curNote.multiHits = Std.int(nums.value);
                        if (curNote.sustainLength <= 0 && curNote.multiHits >= 0) {curNote.sustainLength = conductor.stepCrochet; }
                    });
                }
                case "STRUM_KEYS":{
                    song.strums[curStrum].keys = Std.int(nums.value);
                    updateSection();
                }
                case "Strums_Length":{
                    if (nums.value < 0) {nums.value = 0; }
                    if (nums.value >= song.strums.length) {nums.value = song.strums.length - 1; }
                }
            }
        } else if (id == UIList.CHANGE_EVENT && (sender is UIList)) {
            var nums:UIList = cast sender;
            var wname = nums.name;

            if (wname.startsWith("note_event_arg")) {
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedNote(
                    function(curNote) {
                        curNote.eventData[clNoteEventList.getSelectedIndex()][1][id] = nums.getSelectedLabel();
                    }, null, false
                );

                return;
            } else if (wname.startsWith("event_arg")) {
                var id:Int = Std.parseInt(wname.split(":")[1]);

                updateSelectedEvent(
                    function(curEvent) {
                        if (curEvent.eventData == null) { return; }
                        if (curEvent.eventData.length <= clEventListEvents.getSelectedIndex()) { return; }
                        curEvent.eventData[clEventListEvents.getSelectedIndex()][1][id] = nums.getSelectedLabel();
                    }, null, false
                );

                return;
            }

            switch (wname) {
                default:{}
            }
        }
    }

    var canAutoSave:Bool = true;
    private function autoSave():Void {
        if (!canAutoSave) {trace("Auto Save Disabled!"); return; }
        FlxG.save.data.autosave = song;
		FlxG.save.flush();
        trace("Auto Saved!!!");
    }

    private function loadNoteEventSettings(?event:String):Void {
        note_event_sett_group.clear();   

        if (event == null) { return; }
        
        scripts.load(event, Paths.event(event, song.stage, song.song));
        var setting_list:Array<Dynamic> = scripts.get(event).getVar("defaultValues");

        var last_height:Float = 0;

        for (i in 0...setting_list.length) {
            var setting:Dynamic = setting_list[i];
            var event_value:Dynamic = selNote.eventData[clNoteEventList.getSelectedIndex()][1][i];

            switch (setting.type) {
                default:{
                    var chkCurrent_Variable = new UICheckBox(0, last_height, ctnMenuNote.display_width, setting.name, 16, event_value == true || event_value == "true");
                    chkCurrent_Variable.name = 'note_event_arg:${i}';
                    note_event_sett_group.add(chkCurrent_Variable);
                    last_height += chkCurrent_Variable.height + 5;
                }
                case 'Float':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); note_event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var stpCurrent_Variable = new UINumericStepper(0, last_height, ctnMenuNote.display_width, 16, Std.parseFloat(event_value), 0.1, -999, 999, 3);
                    stpCurrent_Variable.name = 'note_event_arg:${i}';
                    note_event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'Int':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); note_event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var stpCurrent_Variable = new UINumericStepper(0, last_height, ctnMenuNote.display_width, 16, Std.parseFloat(event_value), 1, -999, 999);
                    stpCurrent_Variable.name = 'note_event_arg:${i}';
                    note_event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 5;
                }
                case 'String':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); note_event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var txtCurrent_Variable = new FlxUIInputText(0, last_height, ctnMenuNote.display_width, Std.string(event_value), 16);
                    txtCurrent_Variable.name = 'note_event_arg:${i}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    note_event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'Array':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); note_event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var data:String = ''; try{ data = Json.stringify(cast(event_value, Array<Dynamic>)); } catch(e) { trace(e); data = '[]'; }
                    var txtCurrent_Variable = new FlxUIInputText(0, last_height, ctnMenuNote.display_width, data, 16);
                    txtCurrent_Variable.name = 'note_event_arg:${i}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    note_event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 5;
                }
                case 'List':{
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); note_event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var clCurrent_Variable = new UIList(0, last_height, ctnMenuNote.display_width, 16, setting.list);
                    clCurrent_Variable.name = 'note_event_arg:${i}';
                    clCurrent_Variable.setLabel(event_value,true);
                    note_event_sett_group.add(clCurrent_Variable); 
                    last_height += clCurrent_Variable.height + 5;
                }
            }
        }
    }

    private function loadEventSettings(?event:String):Void {
        event_sett_group.clear();   

        if (event == null) { return; }
        
        scripts.load(event, Paths.event(event, song.stage, song.song));
        var l_scrEvent:Script = scripts.get(event);
        if (l_scrEvent == null) { return; }

        var setting_list:Array<Dynamic> = l_scrEvent.getVar("defaultValues");
        if (setting_list == null || setting_list.length <= 0) { return; }

        var last_height:Float = 0;

        for (i in 0...setting_list.length) {
            var setting:Dynamic = setting_list[i];
            var event_value:Dynamic = selEvent.eventData[clEventListEvents.getSelectedIndex()][1][i];

            switch (setting.type) {
                default: {
                    var chkCurrent_Variable = new UICheckBox(0, last_height, ctnMenuEvent.display_width, setting.name, 16, event_value == true || event_value == "true");
                    chkCurrent_Variable.name = 'event_arg:${i}';
                    event_sett_group.add(chkCurrent_Variable);
                    last_height += chkCurrent_Variable.height + 10;
                }
                case 'Float': {
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var stpCurrent_Variable = new UINumericStepper(0, last_height, ctnMenuEvent.display_width, 16, Std.parseFloat(event_value), 0.1, -999, 999, 3);
                    stpCurrent_Variable.name = 'event_arg:${i}';
                    event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 10;
                }
                case 'Int': {
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var stpCurrent_Variable = new UINumericStepper(0, last_height, ctnMenuEvent.display_width, 16, Std.parseFloat(event_value), 1, -999, 999);
                    stpCurrent_Variable.name = 'event_arg:${i}';
                    event_sett_group.add(stpCurrent_Variable);
                    last_height += lblArgName.height + 10;
                }
                case 'String': {
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var data:String = ''; try { data = Json.stringify(event_value); } catch(e) { trace(e); data = '""'; }
                    var txtCurrent_Variable = new FlxUIInputText(0, last_height, ctnMenuEvent.display_width, Std.string(event_value), 16);
                    txtCurrent_Variable.name = 'event_arg:${i}:string';
                    arrayFocus.push(txtCurrent_Variable);
                    event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 10;
                }
                case 'Array': {
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var data:String = ''; try{ data = Json.stringify(cast(event_value, Array<Dynamic>)); } catch(e) { trace(e); data = '[]'; }
                    var txtCurrent_Variable = new FlxUIInputText(0, last_height, ctnMenuEvent.display_width, data, 16);
                    txtCurrent_Variable.name = 'event_arg:${i}:array';
                    arrayFocus.push(txtCurrent_Variable);
                    event_sett_group.add(txtCurrent_Variable); 
                    last_height += lblArgName.height + 10;
                }
                case 'List': {
                    var lblArgName = new FlxText(0, last_height, 0, '${setting.name}: ', 12); event_sett_group.add(lblArgName); last_height += lblArgName.height;
                    var clCurrent_Variable = new UIList(0, last_height, ctnMenuEvent.display_width, 16, setting.list);
                    clCurrent_Variable.name = 'event_arg:${i}';
                    clCurrent_Variable.setLabel(event_value,true);
                    event_sett_group.add(clCurrent_Variable); 
                    last_height += clCurrent_Variable.height + 10;
                }
            }
        }
    }

    public static var song_file:SaverFile = null;
	public static function save_song(fileName:String, songData:Song_File, options:{?onComplete:Void->Void, ?throwFunc:Exception->Void, ?returnOnThrow:Bool, ?path:String, ?saveAs:Bool}):Void {
		if (song_file != null || songData == null) { return; }
		var _song:Song_File = songData;

		Song.parse(_song);
		var _global_events:Event_File = { events: [] };
		var init_events:Array<Dynamic> = _song.events.copy();

		var cur_ev:Int = 0;
		while(cur_ev < _song.events.length) {
			var ev = _song.events[cur_ev];
			var ev_data:Event_Data = Note.getEventData(ev);
			if (!ev_data.isExternal) {cur_ev++; continue; }
			_global_events.events.push(ev);
			if (!ev_data.isBroken) {_song.events.remove(ev); cur_ev--; }
			cur_ev++;
		}

		var song_data:String = "";
		var events_data:String = "";

		try{song_data = Json.stringify({song: _song},"\t"); }catch(e) {trace(e); if (options.throwFunc != null) {options.throwFunc(e); } if (options.returnOnThrow) { return; }}
		try{events_data = Json.stringify(_global_events,"\t"); }catch(e) {trace(e); if (options.throwFunc != null) {options.throwFunc(e); } if (options.returnOnThrow) { return; }}

		if (options.saveAs) {
			var files_to_save:Array<{name:String, data:Dynamic}> = [{name: '$fileName.json', data: song_data}];
			if (events_data.length > 0) {files_to_save.push({name: 'Events-${_song.category}.json', data: events_data}); }
			song_file = new SaverFile(files_to_save, {destroyOnComplete: true, onComplete: function() {if (options.onComplete != null) {options.onComplete(); } song_file = null; }});
			song_file.saveFile();
		} else {
			#if sys
				if ((song_data != null) && (song_data.length > 0)) {File.saveContent(options.path, song_data); }
				if ((events_data != null) && (events_data.length > 0)) {File.saveContent(options.path.replace('$fileName','Events-${_song.category}'), events_data); }
				if (options.onComplete != null) {options.onComplete(); }
			#end
		}

		_song.events = init_events;
	}
}