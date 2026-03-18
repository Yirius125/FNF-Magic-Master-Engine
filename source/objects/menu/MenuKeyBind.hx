package objects.menu;

import objects.utils.Controls.Control_Input;
import flixel.group.FlxGroup.FlxTypedGroup;
import objects.utils.Controls;
import flixel.tweens.FlxTween;
import states.MusicBeatState;
import objects.game.Alphabet;
import flixel.tweens.FlxEase;
import flixel.FlxG;

using utils.Files;

class MenuKeyBind extends FlxTypedGroup<Alphabet> {
    public var curOption(default, null):Int = 0;
    public var name(default, null):String;
    private var input:Control_Input;
    public var controls:Controls;

    public var isBinding(default, null):Bool = false;
    public var isKeyNote(default, null):Bool = false;
    public var isSelected:Bool = false;

    public var x(default, set):Float = 0;
    public function set_x(_value:Float):Float {
        var _width:Float = _value;
        for (_obj in members) {_obj.x = _width; _width += _obj.width + 20; }
        return x = _value;
    }

    public var y(default, set):Float = 0;
    public function set_y(_value:Float):Float {
        for (_obj in members) {_obj.y = _value; }
        return y = _value;
    }

    public function new(_x:Float, _y:Float, _controls:Controls, _name:String, ?_key:Int):Void {
        controls = _controls;
        name = _name;
        super();
        x = _x;
        y = _y;

        if (_key != null) {
            isKeyNote = true;
            curOption = _key;
        }

        for (_input in (isKeyNote ? Controls.current_key : Controls.current)) { if (_input.name == _name) { input = _input; break; }}

        reload();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        if (!isSelected) { return; }

        if (!isBinding) {
            if (controls.check("MenuLeft", JUST_PRESSED) && !isKeyNote) { change(-1); }
            else if (controls.check("MenuRight", JUST_PRESSED) && !isKeyNote) { change(1); }
            else if (controls.check("MenuAccept", JUST_PRESSED)) { (curOption == length - 1 && !isKeyNote ? bind : reBind)(); }
            else if (controls.check("MenuDelete", JUST_PRESSED) && !isKeyNote && curOption != length - 1) { unBind(); }
        } else {
            if (FlxG.keys.firstJustPressed() != -1 && (isKeyNote || (!isKeyNote && !input.keys.contains(FlxG.keys.firstJustPressed())))) {
                if (isKeyNote) { input.keys[curOption] = FlxG.keys.firstJustPressed(); } 
                else { input.keys.push(FlxG.keys.firstJustPressed()); }
                
                reload();
                isBinding = false;

                FlxG.sound.play(Paths.sound("scrollMenu").getSound());
            }
        }
    }

    public function reload():Void {
        clear();

        var _width:Float = x;

        if (!isKeyNote) {
            for (_key in input.keys) {
                var newKey:Alphabet = new Alphabet(_width, y, {font: "easy_font", scale: 0.5, rel_position: [-10, -10], text: _key.toString().toLowerCase()});
                newKey.offsetBack = 30; newKey.setSliceBack(Paths.image("option_key"), 27, 19, 74, 61);
                _width += newKey.width + 20;
                add(newKey);
            }

            var newAddKey:Alphabet = new Alphabet(_width, y, {font: "easy_font", scale: 0.5, rel_position: [-10, -10], text: '#'});
            newAddKey.offsetBack = 30; newAddKey.setSliceBack(Paths.image("option_key"), 27, 19, 74, 61);
            add(newAddKey);

            members[curOption].color = 0xff8890ff;
        } else{
            var newKey:Alphabet = new Alphabet(_width, y, {font: "easy_font", scale: 0.5, rel_position: [-10, -10], text: input.keys[curOption].toString().toLowerCase()});
            newKey.offsetBack = 30; newKey.setSliceBack(Paths.image("option_key"), 27, 19, 74, 61);
            add(newKey);
        }
    }

    public function change(_value:Int, _force:Bool = false):Void {
        curOption = _force ? _value : curOption + _value;

		if (curOption < 0 && !_force) {curOption = length - 1; }
		if (curOption >= length && !_force) {curOption = 0; }

        for (_key in members) {_key.color = 0xffffffff; }
        if (inBounds()) {members[curOption].color = 0xff8890ff; }
        
		if (!_force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound()); }
    }

    public function reBind():Void {
        if (isBinding) { return; }
        isBinding = true;

        if (isKeyNote) {
            members[0].setText({font: "easy_font", scale: 0.5, rel_position: [-10, -10], text: '#'});
        } else{
            input.keys.remove(input.keys[curOption]);
    
            remove(members[curOption], true);
    
            var _width:Float = x;
            for (_key in members) {
                FlxTween.cancelTweensOf(_key);
                FlxTween.tween(_key, {x: _width}, 0.1, {ease: FlxEase.quadInOut});
                _width += _key.width + 20;
            }
        }

        FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }
    
    public function unBind():Void {
        input.keys.remove(input.keys[curOption]);

        remove(members[curOption], true);

        var _width:Float = x;
        for (_key in members) {
            FlxTween.cancelTweensOf(_key);
            FlxTween.tween(_key, {x: _width}, 0.1, {ease: FlxEase.quadInOut});
            _width += _key.width + 20;
        }

        members[curOption].color = 0xff8890ff;

        FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }

    public function bind():Void {
        if (isBinding) { return; } isBinding = true;

        FlxG.sound.play(Paths.sound("scrollMenu").getSound());
    }

    private function inBounds():Bool {
		if (curOption < 0) { return false; }
		if (curOption >= length) { return false; }
        return true;
    }
}