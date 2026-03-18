package objects.ui;

import flixel.addons.ui.interfaces.IResizable;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIGroup;
import flash.geom.Rectangle;
import flixel.FlxSprite;

using utils.Files;
using StringTools;

class UIContainer extends FlxUIGroup implements IResizable {
    public var _front(default, null):FlxSprite;
    public var _back(default, null):FlxSprite;

    public var list_height:Float = 20;
    public var list_width:Float = 20;

    public var visible_front:Bool = true;
    
    public var front_group(default, null):FlxUIGroup;
    
    public var current_height:Float = 0;

    public var display_width(get, never):Int;
    public function get_display_width():Int { return Std.int(width - (list_width * 2)); }

    public function new(_x:Float = 0, _y:Float = 0, _width:Float = 200, _height:Float = 200, ?_back_image:String, ?_front_image:String):Void {
        if (_front_image == null) {_front_image = Paths.image("editor_menu/tiles/outline"); }
        if (_back_image == null) {_back_image = Paths.image("editor_menu/tiles/dark"); }
        super(_x, _y);
        
        var front_data:Dynamic = Magic.customSliceRect(0, 0, 10, 10, _front_image);

        _back = Magic.customSliceRect(0, 0, 10, 10, _back_image).data; add(_back);
        _front = front_data.data; add(_front);
        front_group = new FlxUIGroup(); add(front_group);
        
        list_height = Std.parseInt(front_data.info[1]);

        resize(_width, _height);
    }
    
    public function addPlus(Object:FlxSprite, Offset:Float = 5, Scroll:Bool = true, Front:Bool = false):FlxSprite {
        Object.y += list_height + current_height; Object.x += list_width;
        if (Scroll) { current_height += Object.height + Offset; }
        if (Front) { front_group.add(Object); } else { add(Object); }
        return Object;
    }
    
	override public function draw():Void {
        _back.draw();

        for (m in group.members) { if (m ==_front || m == _back) { continue; } m.draw(); }

        if (visible_front) { _front.draw(); }
        
        front_group.draw();
        
        #if FLX_DEBUG if (FlxG.debugger.drawDebug) { drawDebug(); } #end
    }
    
	public function resize(_w:Float, _h:Float):Void {
        if ((_front is IResizable)) { var ir:IResizable = cast _front; ir.resize(_w, _h); }
        if ((_back is IResizable)) { var ir:IResizable = cast _back; ir.resize(_w, _h); }
    }
}