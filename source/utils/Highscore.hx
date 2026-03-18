package utils;

import flixel.util.FlxSave;
import objects.songs.Song;
import flixel.FlxG;

using StringTools;

class Highscore {
	public static var scores:Map<String, Int> = new Map<String, Int>();
	public static var _save:FlxSave;

	public static function init():Void {
		Highscore._save = new FlxSave();
		Highscore._save.bind('scores', 'Yirius125');
		
		scores = Highscore._save.data.scores;
		if (scores == null) {scores = []; }
	}

	private static function set(song:String, score:Int):Void {
		Highscore.scores.set(song, score);
		Highscore._save.data.scores = Highscore.scores;
		Highscore._save.flush();
	}
	public static function get(song:String, diff:String, cat:String):Int {
		var file_song:String = Song.format(song, cat, diff);
		if (!scores.exists(file_song)) { return 0; }
		return scores.get(file_song);
	}
	public static function getWeek(weekName:String, diff:String, cat:String):Int {
		var file_week:String = Song.format('week_$weekName', cat, diff);
		if (!scores.exists(file_week)) { return 0; }
		return scores.get(file_week);
	}

	public static function save(song:String, score:Int = 0, ?diff:String = "Hard", ?cat:String = "Normal"):Int {
		var file_song:String = Song.format(song, cat, diff);

		if (Settings.get("BotPlay")) { return score; }
		if (scores.exists(file_song) && scores.get(file_song) >= score) { return scores.get(file_song); }

		#if !switch NGio.postScore(score, file_song); #end
		Highscore.set(file_song, score);

		trace('Score Saved [${file_song}]: ${score}');
		return score;
	}
	public static function saveWeek(weekName:String, score:Int = 0, ?diff:String = "Hard", ?cat:String = "Normal"):Void {
		var file_week:String = Song.format('week_$weekName', cat, diff);

		if (Settings.get("BotPlay") || (scores.exists(file_week) && scores.get(file_week) >= score)) { return; }

		#if !switch NGio.postScore(score, "Week " + weekName); #end
		Highscore.set(file_week, score);

		trace('Week Score Saved [${file_week}]: ${score}');
	}

	public static function isLock(song:String, isWeek:Bool = false):Bool {
		var cur_key:String = isWeek ? 'week_$song' : '$song';

		for (key in scores.keys()) { if (!key.contains(cur_key)) { continue; } return false; }
		return true;
	}
}
