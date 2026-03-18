package objects.songs;

import utils.Songs.WeeksFile_Data;
import utils.Songs.Category_Data;
import utils.Mods;

using utils.Files;
using StringTools;

typedef WeekItem_Data = {
	var name:String;
	var image:String;
	var display:String;
	var title:String;
	var categories:Array<Category_Data>;
	var songs:Array<String>;
	var keyLock:String;
	var hiddenOnWeeks:Bool;
	var hiddenOnFreeplay:Bool;
	var colorFreeplay:String;
}

class WeekList {
	public var list(default, null):Array<WeekItem> = [];

	public function new(_removeHiddens:Bool = true):Void {
		this.setup(_removeHiddens);
	}

	public var length(get, never):Int;
	public function get_length():Int { return list.length; }

	public function get(id:Int):WeekItem_Data { return list[id] != null ? list[id].data : null; }

	public function add(new_item:WeekItem):Void {
		for (cur_item in list) {
            if (cur_item.data.name != new_item.data.name) { continue; }
            cur_item.append(new_item);
			trace(true);
            return;
        }
		list.push(new_item);
	}
	public function remove(id:Int):Bool { return list.remove(list[id]); }

	public function removeHiddens():Void {
		var count:Int = 0;

		while(count < this.length) {
			if (!get(count).hiddenOnWeeks) { count++; continue; }

			remove(count);
		}
	}

	public function setup(_removeHiddens:Bool = true):WeekList {
		this.list = [];

		var path_list:Array<String> = Paths.readFile('assets/data/weeks.json');
		if (Mods.hide_vanilla) {path_list.shift(); }

		for (mod_path in path_list) {
			var mod_data:WeeksFile_Data = cast mod_path.getJson();

			for (week in mod_data.weekData) {
				add(new WeekItem(week));
			}
		}

		if (_removeHiddens) { this.removeHiddens(); }

		return this;
	}
}

class WeekItem {
	public var data(default, null):WeekItem_Data = null;

	public function new(_data:WeekItem_Data):Void {
        this.data = _data;
	}

	public function append(other_item:WeekItem):Void {
		for (new_song in other_item.data.songs) {
			if (data.songs.contains(new_song)) { continue; }
			add_song(new_song);
        }

		for (new_category in other_item.data.categories) {
            add_category(new_category.name, new_category.difficulties);
        }
	}

	public function add_song(name:String):Void {
		data.songs.push(name);
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