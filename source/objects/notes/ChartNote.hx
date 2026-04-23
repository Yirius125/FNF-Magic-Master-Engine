package objects.notes;

import objects.songs.Song.Strum_Data;
import objects.notes.Note.Note_Data;
import flixel.addons.ui.FlxUIGroup;
import objects.songs.Conductor;
import flixel.math.FlxMath;

class ChartNote extends FlxUIGroup {
    public var conductor:Conductor;
    public var strum:Strum_Data;
    public var data:Note_Data;
    public var keysize:Int;
    
    public function new(_data:Note_Data, _strum:Strum_Data, _conductor:Conductor, _keysize:Int):Void {
        conductor = _conductor;
        keysize = _keysize;
        strum = _strum;
        data = _data;
        super();

        setup();
    }

    public function setup():Void {
        while(members.length > 0) {remove(members[0], true).destroy(); }

        var note:Note = new Note(data, strum.keys, null, strum.style);
        note.setGraphicSize(keysize, keysize); note.updateHitbox();
                
        if (data.sustainLength > 0) {
            if (data.multiHits > 0) {
                var totalHits:Int = data.multiHits + 1;
                var hits:Int = data.multiHits;
                var curHits:Int = 1;
    
                note.noteHits = 0;
                data.multiHits = 0;
    
                while(hits > 0) {
                    var newStrumTime = data.strumTime + (data.sustainLength * curHits);
                    var noteHitData:Note_Data = Note.getNoteData(Note.convNoteData(data));
                    noteHitData.strumTime = newStrumTime;
    
                    var hitNote:Note = new Note(noteHitData, strum.keys, null, strum.style);
                    hitNote.setGraphicSize(keysize, keysize); hitNote.updateHitbox();
            
                    hitNote.y = Math.floor(getStrumY(hitNote.strumTime - data.strumTime));
    
                    add(hitNote);
    
                    hits--;
                    curHits++;
                }
            } else{
                var cSusNote:Int = Std.int(Math.max(Math.floor(data.sustainLength / conductor.stepCrochet), 1));
    
                var noteSustainData:Note_Data = Note.getNoteData(Note.convNoteData(data));
                noteSustainData.strumTime += (conductor.stepCrochet / 2);
    
                var sustainNote:Note = new Note(noteSustainData, strum.keys, null, strum.style);
                sustainNote.playAnim("sustain");
    
                sustainNote.setGraphicSize(keysize, (keysize * (cSusNote + 0.25))); sustainNote.updateHitbox();
                
                sustainNote.y = Math.floor(getStrumY(sustainNote.strumTime - data.strumTime));
    
                add(sustainNote);
                
                var noteEndData:Note_Data = Note.getNoteData(Note.convNoteData(data));
                noteEndData.strumTime += conductor.stepCrochet * (cSusNote + 0.75);
    
                var sustainEndNote:Note = new Note(noteEndData, strum.keys, null, strum.style);
                sustainEndNote.setGraphicSize(keysize, keysize); sustainEndNote.updateHitbox();
                sustainEndNote.playAnim("end");
                
                sustainEndNote.y = Math.floor(getStrumY(sustainEndNote.strumTime - data.strumTime));
    
                add(sustainEndNote);
            }
        }
        
        add(note);
    }

    public function getStrumY(_strumTime):Float { return FlxMath.remapToRange(_strumTime, 0, 16 * conductor.stepCrochet, 0, 16 * keysize); }
}