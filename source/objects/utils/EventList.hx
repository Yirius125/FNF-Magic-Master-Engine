package objects.utils;

import objects.songs.Conductor;
import flixel.FlxBasic;

typedef Event_Data = {
    var time:Float;
    var method:Void->Void;
}

class EventList extends FlxBasic {
    public static function sort(list:Array<Event_Data>):Void {
        list.sort(function(a, b) {
            if (a.time < b.time) return -1;
            else if (a.time > b.time) return 1;
            else return 0;
        });
    }

    private var list:Array<Event_Data> = [];
    private var used:Array<Event_Data> = [];
    
    public var conductor:Conductor;
    public var time:Float = 0;

    public var destroyEvents:Bool = true;

    public function new(?list:Array<Event_Data>):Void {
        if (list != null) { this.list = list; }
        super();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (list.length <= 0) { return; }

        if (conductor == null) {
            time += elapsed;
            if (time >= list[0].time) { execute(); }
        } else {
            if (conductor.position >= list[0].time) { execute(); }
        }
    }

    public function execute():Void {
        var cur_event:Event_Data = list.shift();
        if (cur_event.method == null) { return; }

        cur_event.method();

        if (destroyEvents) { used.insert(0, cur_event); }
    }

    public function push(time:Float, method:Void->Void):Void {
        list.push({ time: time, method: method });
        EventList.sort(list);
    }

    public function reload():Void {
        if (destroyEvents) { return; }

        while(used.length > 0) { list.push(used.shift()); }
        EventList.sort(list);

        while(
            conductor != null && list[0].time <= conductor.position ||
            list[0].time <= time
        ) { used.push(list.shift()); }
    }

    public function clear():Void {
        while (list.length > 0) { list.shift(); }
        while (used.length > 0) { used.shift(); }
    }
}