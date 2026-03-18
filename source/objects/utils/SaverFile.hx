package objects.utils;

import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import openfl.events.Event;

class SaverFile extends FileReference {
	public var stuff_to_save:Array<{name:String, data:String}> = [];
	public var current_calls:Array<{event:Dynamic,func:Dynamic}> = [];
	public var options:Dynamic = {};

	public function new(?_stuff_to_save:Array<{name:String, data:String}>, ?options:Dynamic):Void {
		if (_stuff_to_save != null) {this.stuff_to_save = _stuff_to_save; }
		if (options != null) {this.options = cast options; }
		super();
	}

	public function saveFile(?_):Void {
		if (_ == null) {
			this.addEventListener(Event.SELECT, saveFile);
			this.addEventListener(Event.COMPLETE, completedFiles);
			this.addEventListener(Event.CANCEL, saveFile);
			this.addEventListener(IOErrorEvent.IO_ERROR, saveFile);
		}

		if (stuff_to_save.length <= 0) {completedFiles(); return; }
		var current_file:{name:String, data:String} = stuff_to_save.shift();
		this.save(current_file.data, current_file.name);
	}

	public function completedFiles(?_) {
		if (options.onComplete != null) {options.onComplete(); }
		if (options.destroyOnComplete) {removeListeners(); }
	}

	private function removeListeners() {
		this.removeEventListener(Event.SELECT, saveFile);
		this.removeEventListener(Event.COMPLETE, completedFiles);
		this.removeEventListener(Event.CANCEL, saveFile);
		this.removeEventListener(IOErrorEvent.IO_ERROR, saveFile);
	}
}