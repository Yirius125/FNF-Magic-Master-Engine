package objects.songs;

import utils.Songs.WeeksFile_Data;
import utils.Songs.Category_Data;
import utils.Mods;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

typedef SongItem_Data = {
	var song:String;
	var categories:Array<Category_Data>;
	var keyLock:String;
	var hidden:Bool;
	var color:String;
}

class SongList {
    public var list(default, null):Array<SongItem> = [];

    public function new():Void {}

	public var length(get, never):Int;
	public function get_length():Int { return list.length; }

	public function get(id:Int):SongItem_Data { return list[id] != null ? list[id].data : null; }

	public function add(new_item:SongItem):Void {
		for (cur_item in list) {
            if (cur_item.data.song != new_item.data.song) { continue; }
            cur_item.append(new_item);
            return;
        }
		list.push(new_item);
	}
	public function remove(id:Int):Bool { return list.remove(list[id]); }

    public function setup():SongList {
		list = [];

		var path_list:Array<String> = Paths.readFile('assets/data/weeks.json');
		if (Mods.hide_vanilla) {path_list.shift(); }

		for (mod_path in path_list) {
			var mod_data:WeeksFile_Data = cast mod_path.getJson();

			for (week in mod_data.weekData) {
				var categories:Array<Category_Data> = week.categories;
				var color:String = week.colorFreeplay;
				var lock:String = week.keyLock;

				for (song in week.songs) {
					var songItem:SongItem_Data = {
						song: song,
						categories: categories,
						keyLock: lock,
						color: color,
						hidden: week.hiddenOnFreeplay
					};
					add(new SongItem(songItem));
				}
			}

			for (song in mod_data.freeplayData) {
				add(new SongItem(song));
			}

			#if sys
			if (mod_data.showArchiveSongs) {
				var songsDirectory:String = mod_path;
				songsDirectory = songsDirectory.replace('weeks.json', 'songs');

				for (song in FileSystem.readDirectory(songsDirectory)) {
					if (!FileSystem.isDirectory('${songsDirectory}/${song}') || FileSystem.readDirectory('${songsDirectory}/${song}').length <= 0) { continue; }

                    var songItem:SongItem = new SongItem({
                        song: song,
                        categories: [],
                        keyLock: null,
                        color: "#fffd75",
                        hidden: false
                    });

					for (chart in FileSystem.readDirectory('${songsDirectory}/${song}')) {
						if (chart == "global_events.json") { continue; }
						if (chart.contains("_dialog.json")) { continue; }
						if (!chart.contains(".json")) { continue; }

						var chart_data:Array<String> = chart.replace(".json", "").split("-");
						if (chart_data.length < 3) { continue; }

						if (chart_data[1] == null) {chart_data[1] = "Normal"; }
						if (chart_data[2] == null) {chart_data[2] = "Normal"; }
						
                        songItem.add_category(chart_data[1], [chart_data[2]]);
					}

                    if (songItem.data.categories.length <= 0) { continue; }
                    add(songItem);
				}
			}
			#end
		}

		return this;
    }
	
	public function removeHiddens():Void {
		var count:Int = 0;

		while(count < this.length) {
			if (!get(count).hidden) { count++; continue; }

			remove(count);
		}
	}
}

class SongItem {
    public var data(default, null):SongItem_Data = null;

    public function new(_data:SongItem_Data):Void {
        this.data = _data;
    }

    public function append(other_item:SongItem):Void {
        for (new_category in other_item.data.categories) {
            add_category(new_category.name, new_category.difficulties);
        }
    }

    public function get_category(name:String):Category_Data {
        for (cur_cat in data.categories) {
            if (cur_cat.name != name) { continue; }
            return cur_cat;
        }
        return null;
    }

    public function add_category(name:String, ?difficulties:Array<String>):Void {
        if (difficulties == null) {difficulties = []; }
        
        var cur_category:Category_Data = get_category(name);
        if (cur_category == null) {
            data.categories.push({name: name, difficulties: difficulties});
            return;
        }

        for (cur_diff in difficulties) {
            if (cur_category.difficulties.contains(cur_diff)) { continue; }
            cur_category.difficulties.push(cur_diff);
        }
    }

	public function has_difficulty(difficulty:String, category:String):Bool {
		var cur_category:Category_Data = get_category(category);
		if (cur_category == null) { return false; }
		return cur_category.difficulties.contains(difficulty);
	}
}