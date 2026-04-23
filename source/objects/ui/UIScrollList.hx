package objects.ui;

import flixel.addons.ui.FlxUIGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;

using utils.Files;
using StringTools;

class UIScrollList extends UIContainer {
    public var scroller(default, null):UISlider;
    public var list(default, null):FlxUIGroup;
    public var list_y(default, null):Float = 0;

    public var canScroll(get, never):Bool;
    public function get_canScroll():Bool { return list.height > this.height; }
    
    override public function get_display_width():Int { return Std.int(width - (list_width * 2) - 5); }

    public function new(_x:Float = 0, _y:Float = 0, _width:Float = 200, _height:Float = 200, ?_back_image:String, ?_front_image:String):Void {
        if (_front_image == null) {_front_image = Paths.image("editor_menu/tiles/outline-right"); }
        super(_x, _y, _width, _height, _back_image, _front_image);

        list = new FlxUIGroup(0, 0);
        scroller = new UISlider(0, list_height + 10, 12, Std.int(list_width), Std.int(_height - (list_height * 2) - 20), true, this, "list_y", 0, 100);
        scroller.x = list_width + display_width + 5;
        scroller.valueVisible = false;
        
        add(list);
        add(scroller);

        autoBounds = false;
    }

    override public function update(elapsed:Float):Void {
        list.y = 0 - list_y;

        super.update(elapsed);
    }

    public function addList(Object:FlxSprite, Offset:Float = 5, Scroll:Bool = true):FlxSprite {
        Object.y += list_height + current_height; Object.x += list_width;
        if (Scroll) { 
            current_height += Object.height + Offset; 
            scroller.maxValue = list.height + 10;
        }
        list.add(Object);

        return Object;
    }
    
	override public function draw():Void {
        _back.draw();
        for (m in group.members) { if (m ==_front || m == _back) { continue; } m.draw(); }
        if (visible_front) { _front.draw(); }
        front_group.draw();

        #if FLX_DEBUG if (FlxG.debugger.drawDebug) { drawDebug(); } #end
    }
}