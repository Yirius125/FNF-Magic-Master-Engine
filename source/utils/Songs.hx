package utils;

import objects.songs.SongList.SongItem_Data;
import objects.songs.WeekList.WeekItem_Data;
import objects.songs.SongList.SongItem;
import objects.songs.WeekList.WeekItem;
import objects.songs.Song.Song_File;
import states.MusicBeatState;
import objects.songs.Song;

typedef WeeksFile_Data = {
	var weekData:Array<WeekItem_Data>;
	var freeplayData:Array<SongItem_Data>;
	var showArchiveSongs:Bool;
}

typedef Category_Data = {
    var name:String;
    var difficulties:Array<String>;
}

class Songs {
	public static var playlist:Array<Song_File> = [];
	public static var players:Array<Int> = [];

	public static var weekDisplay:String = "Custom Week";
	public static var weekName:String = "Custom Week";
    
	public static var isStoryMode:Bool = false;

	public static var total_score:Int = 0;

	public static function reset() {		
		Songs.weekDisplay = "Custom Week";
		Songs.weekName = "Custom Week";
		Songs.isStoryMode = false;
		Songs.total_score = 0;
		Songs.playlist = [];
		Songs.players = [];
	}

	public static function loadSong(song:SongItem_Data, category:String = "Normal", difficulty:String = "Normal"):Void {
		if (!(new SongItem(song).has_difficulty(difficulty, category))) { return; }
		var song_format:String = Song.format(song.song, category, difficulty);

		trace('Adding ${song_format} to Playlist.');
		
		Songs.reset(); 

		weekDisplay = "Freeplay";
		weekName = "Freeplay";

		var play:Song_File = Song.load(song_format);
		playlist.push(play);
	}
	public static function loadWeek(week:WeekItem_Data, category:String = "Normal", difficulty:String = "Normal"):Void {
		if (!new WeekItem(week).has_difficulty(difficulty, category)) { return; }

		trace('Adding Week ${week.name} to Playlist.');
		
		Songs.reset(); 
		
		weekDisplay = week.display;
		weekName = week.name;

		for (song in week.songs) {
			var song_format:String = Song.format(song, category, difficulty);

			trace('Adding (${week.name}) : ${song_format} to Playlist.');

			var play:Song_File = Song.load(song_format);
			playlist.push(play);
		}
	}

	public static function addSongs(songList:Array<Song_File>) { for (song in songList) { playlist.push(song); }}
	public static function addSong(song:Song_File) { playlist.push(song); }

	public static function play(_isStoryMode:Bool = true):Void {
		Songs.isStoryMode = _isStoryMode;

		MusicBeatState.loadState("states.PlayState", [], [[{ type: "SONG", instance: playlist[0] }], false]);
	}

	public static function quickPlay(song:Song_File, _isStoryMode:Bool = false):Void {
		Songs.reset(); 
		
		Songs.isStoryMode = _isStoryMode;
		
		playlist.push(song);

		MusicBeatState.loadState("states.PlayState", [], [[{ type: "SONG", instance: song }], false]);
	}
	
	public static function next(score:Int) {
		total_score += score;
		playlist.shift();
		players = [];
	}
}